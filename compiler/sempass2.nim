#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  wordrecg, strutils, options, guards, lineinfos, semfold, semdata,
  modulegraphs, varpartitions, typeallowed, nilcheck

when defined(useDfa):
  import dfa

import liftdestructors
include sinkparameter_inference

#[ Second semantic checking pass over the AST. Necessary because the old
   way had some inherent problems. Performs:

* effect+exception tracking
* "usage before definition" checking
* also now calls the "lift destructor logic" at strategic positions, this
  is about to be put into the spec:

We treat assignment and sinks and destruction as identical.

In the construct let/var x = expr() x's type is marked.

In x = y the type of x is marked.

For every sink parameter of type T T is marked.

For every call f() the return type of f() is marked.

]#

# ------------------------ exception and tag tracking -------------------------

discard """
  exception tracking:

  a() # raises 'x', 'e'
  try:
    b() # raises 'e'
  except e:
    # must not undo 'e' here; hrm
    c()

 --> we need a stack of scopes for this analysis

  # XXX enhance the algorithm to care about 'dirty' expressions:
  lock a[i].L:
    inc i # mark 'i' dirty
    lock a[j].L:
      access a[i], a[j]  # --> reject a[i]
"""

type
  TEffects = object
    exc: PNode  # stack of exceptions
    tags: PNode # list of tags
    bottom, inTryStmt, inExceptOrFinallyStmt, leftPartOfAsgn: int
    owner: PSym
    ownerModule: PSym
    init: seq[int] # list of initialized variables
    guards: TModel # nested guards
    locked: seq[PNode] # locked locations
    gcUnsafe, isRecursive, isTopLevel, hasSideEffect, inEnforcedGcSafe: bool
    hasDangerousAssign: bool
    inEnforcedNoSideEffects: bool
    maxLockLevel, currLockLevel: TLockLevel
    currOptions: TOptions
    config: ConfigRef
    graph: ModuleGraph
    c: PContext
  PEffects = var TEffects

proc `<`(a, b: TLockLevel): bool {.borrow.}
proc `<=`(a, b: TLockLevel): bool {.borrow.}
proc `==`(a, b: TLockLevel): bool {.borrow.}
proc max(a, b: TLockLevel): TLockLevel {.borrow.}

proc createTypeBoundOps(tracked: PEffects, typ: PType; info: TLineInfo) =
  if typ == nil: return
  when false:
    let realType = typ.skipTypes(abstractInst)
    if realType.kind == tyRef and
        optSeqDestructors in tracked.config.globalOptions:
      createTypeBoundOps(tracked.graph, tracked.c, realType.lastSon, info)

  createTypeBoundOps(tracked.graph, tracked.c, typ, info, tracked.c.idgen)
  if (tfHasAsgn in typ.flags) or
      optSeqDestructors in tracked.config.globalOptions:
    tracked.owner.flags.incl sfInjectDestructors

proc isLocalVar(a: PEffects, s: PSym): bool =
  # and (s.kind != skParam or s.typ.kind == tyOut)
  s.kind in {skVar, skResult} and sfGlobal notin s.flags and
    s.owner == a.owner and s.typ != nil

proc getLockLevel(t: PType): TLockLevel =
  var t = t
  # tyGenericInst(TLock {tyGenericBody}, tyStatic, tyObject):
  if t.kind == tyGenericInst and t.len == 3: t = t[1]
  if t.kind == tyStatic and t.n != nil and t.n.kind in {nkCharLit..nkInt64Lit}:
    result = t.n.intVal.TLockLevel

proc lockLocations(a: PEffects; pragma: PNode) =
  if pragma.kind != nkExprColonExpr:
    localError(a.config, pragma.info, "locks pragma without argument")
    return
  var firstLL = TLockLevel(-1'i16)
  for x in pragma[1]:
    let thisLL = getLockLevel(x.typ)
    if thisLL != 0.TLockLevel:
      if thisLL < 0.TLockLevel or thisLL > MaxLockLevel.TLockLevel:
        localError(a.config, x.info, "invalid lock level: " & $thisLL)
      elif firstLL < 0.TLockLevel: firstLL = thisLL
      elif firstLL != thisLL:
        localError(a.config, x.info,
          "multi-lock requires the same static lock level for every operand")
      a.maxLockLevel = max(a.maxLockLevel, firstLL)
    a.locked.add x
  if firstLL >= 0.TLockLevel and firstLL != a.currLockLevel:
    if a.currLockLevel > 0.TLockLevel and a.currLockLevel <= firstLL:
      localError(a.config, pragma.info, "invalid nested locking")
    a.currLockLevel = firstLL

proc guardGlobal(a: PEffects; n: PNode; guard: PSym) =
  # check whether the corresponding lock is held:
  for L in a.locked:
    if L.kind == nkSym and L.sym == guard: return
  # we allow accesses nevertheless in top level statements for
  # easier initialization:
  #if a.isTopLevel:
  #  message(n.info, warnUnguardedAccess, renderTree(n))
  #else:
  if not a.isTopLevel:
    localError(a.config, n.info, "unguarded access: " & renderTree(n))

# 'guard*' are checks which are concerned with 'guard' annotations
# (var x{.guard: y.}: int)
proc guardDotAccess(a: PEffects; n: PNode) =
  let ri = n[1]
  if ri.kind != nkSym or ri.sym.kind != skField: return
  var g = ri.sym.guard
  if g.isNil or a.isTopLevel: return
  # fixup guard:
  if g.kind == skUnknown:
    var field: PSym = nil
    var ty = n[0].typ.skipTypes(abstractPtrs)
    if ty.kind == tyTuple and not ty.n.isNil:
      field = lookupInRecord(ty.n, g.name)
    else:
      while ty != nil and ty.kind == tyObject:
        field = lookupInRecord(ty.n, g.name)
        if field != nil: break
        ty = ty[0]
        if ty == nil: break
        ty = ty.skipTypes(skipPtrs)
    if field == nil:
      localError(a.config, n.info, "invalid guard field: " & g.name.s)
      return
    g = field
    #ri.sym.guard = field
    # XXX unfortunately this is not correct for generic instantiations!
  if g.kind == skField:
    let dot = newNodeI(nkDotExpr, n.info, 2)
    dot[0] = n[0]
    dot[1] = newSymNode(g)
    dot.typ = g.typ
    for L in a.locked:
      #if a.guards.sameSubexprs(dot, L): return
      if guards.sameTree(dot, L): return
    localError(a.config, n.info, "unguarded access: " & renderTree(n))
  else:
    guardGlobal(a, n, g)

proc makeVolatile(a: PEffects; s: PSym) {.inline.} =
  if a.inTryStmt > 0 and a.config.exc == excSetjmp:
    incl(s.flags, sfVolatile)

proc initVar(a: PEffects, n: PNode; volatileCheck: bool) =
  if n.kind != nkSym: return
  let s = n.sym
  if isLocalVar(a, s):
    if volatileCheck: makeVolatile(a, s)
    for x in a.init:
      if x == s.id: return
    a.init.add s.id

proc initVarViaNew(a: PEffects, n: PNode) =
  if n.kind != nkSym: return
  let s = n.sym
  if {tfRequiresInit, tfNotNil} * s.typ.flags <= {tfNotNil}:
    # 'x' is not nil, but that doesn't mean its "not nil" children
    # are initialized:
    initVar(a, n, volatileCheck=true)
  elif isLocalVar(a, s):
    makeVolatile(a, s)

proc warnAboutGcUnsafe(n: PNode; conf: ConfigRef) =
  #assert false
  message(conf, n.info, warnGcUnsafe, renderTree(n))

proc markGcUnsafe(a: PEffects; reason: PSym) =
  if not a.inEnforcedGcSafe:
    a.gcUnsafe = true
    if a.owner.kind in routineKinds: a.owner.gcUnsafetyReason = reason

proc markGcUnsafe(a: PEffects; reason: PNode) =
  if not a.inEnforcedGcSafe:
    a.gcUnsafe = true
    if a.owner.kind in routineKinds:
      if reason.kind == nkSym:
        a.owner.gcUnsafetyReason = reason.sym
      else:
        a.owner.gcUnsafetyReason = newSym(skUnknown, a.owner.name, nextId a.c.idgen,
                                          a.owner, reason.info, {})

when true:
  template markSideEffect(a: PEffects; reason: typed) =
    if not a.inEnforcedNoSideEffects: a.hasSideEffect = true
else:
  template markSideEffect(a: PEffects; reason: typed) =
    if not a.inEnforcedNoSideEffects: a.hasSideEffect = true
    markGcUnsafe(a, reason)

proc listGcUnsafety(s: PSym; onlyWarning: bool; cycleCheck: var IntSet; conf: ConfigRef) =
  let u = s.gcUnsafetyReason
  if u != nil and not cycleCheck.containsOrIncl(u.id):
    let msgKind = if onlyWarning: warnGcUnsafe2 else: errGenerated
    case u.kind
    of skLet, skVar:
      message(conf, s.info, msgKind,
        ("'$#' is not GC-safe as it accesses '$#'" &
        " which is a global using GC'ed memory") % [s.name.s, u.name.s])
    of routineKinds:
      # recursive call *always* produces only a warning so the full error
      # message is printed:
      listGcUnsafety(u, true, cycleCheck, conf)
      message(conf, s.info, msgKind,
        "'$#' is not GC-safe as it calls '$#'" %
        [s.name.s, u.name.s])
    of skParam, skForVar:
      message(conf, s.info, msgKind,
        "'$#' is not GC-safe as it performs an indirect call via '$#'" %
        [s.name.s, u.name.s])
    else:
      message(conf, u.info, msgKind,
        "'$#' is not GC-safe as it performs an indirect call here" % s.name.s)

proc listGcUnsafety(s: PSym; onlyWarning: bool; conf: ConfigRef) =
  var cycleCheck = initIntSet()
  listGcUnsafety(s, onlyWarning, cycleCheck, conf)

proc useVarNoInitCheck(a: PEffects; n: PNode; s: PSym) =
  if {sfGlobal, sfThread} * s.flags != {} and s.kind in {skVar, skLet} and
      s.magic != mNimvm:
    if s.guard != nil: guardGlobal(a, n, s.guard)
    if {sfGlobal, sfThread} * s.flags == {sfGlobal} and
        (tfHasGCedMem in s.typ.flags or s.typ.isGCedMem):
      #if a.config.hasWarn(warnGcUnsafe): warnAboutGcUnsafe(n)
      markGcUnsafe(a, s)
      markSideEffect(a, s)
    else:
      markSideEffect(a, s)

proc useVar(a: PEffects, n: PNode) =
  let s = n.sym
  if a.inExceptOrFinallyStmt > 0:
    incl s.flags, sfUsedInFinallyOrExcept
  if isLocalVar(a, s):
    if sfNoInit in s.flags:
      # If the variable is explicitly marked as .noinit. do not emit any error
      a.init.add s.id
    elif s.id notin a.init:
      if s.typ.requiresInit:
        message(a.config, n.info, warnProveInit, s.name.s)
      elif a.leftPartOfAsgn <= 0:
        message(a.config, n.info, warnUninit, s.name.s)
      # prevent superfluous warnings about the same variable:
      a.init.add s.id
  useVarNoInitCheck(a, n, s)


type
  TIntersection = seq[tuple[id, count: int]] # a simple count table

proc addToIntersection(inter: var TIntersection, s: int) =
  for j in 0..<inter.len:
    if s == inter[j].id:
      inc inter[j].count
      return
  inter.add((id: s, count: 1))

proc throws(tracked, n, orig: PNode) =
  if n.typ == nil or n.typ.kind != tyError:
    if orig != nil:
      let x = copyNode(n)
      x.info = orig.info
      tracked.add x
    else:
      tracked.add n

proc getEbase(g: ModuleGraph; info: TLineInfo): PType =
  result = g.sysTypeFromName(info, "Exception")

proc excType(g: ModuleGraph; n: PNode): PType =
  # reraise is like raising E_Base:
  let t = if n.kind == nkEmpty or n.typ.isNil: getEbase(g, n.info) else: n.typ
  result = skipTypes(t, skipPtrs)

proc createRaise(g: ModuleGraph; n: PNode): PNode =
  result = newNode(nkType)
  result.typ = getEbase(g, n.info)
  if not n.isNil: result.info = n.info

proc createTag(g: ModuleGraph; n: PNode): PNode =
  result = newNode(nkType)
  result.typ = g.sysTypeFromName(n.info, "RootEffect")
  if not n.isNil: result.info = n.info

proc addRaiseEffect(a: PEffects, e, comesFrom: PNode) =
  assert e.kind != nkRaiseStmt
  var aa = a.exc
  for i in a.bottom..<aa.len:
    # we only track the first node that can have the effect E in order
    # to safe space and time.
    if sameType(a.graph.excType(aa[i]), a.graph.excType(e)): return

  if e.typ != nil:
    if optNimV1Emulation in a.config.globalOptions or not isDefectException(e.typ):
      throws(a.exc, e, comesFrom)

proc addTag(a: PEffects, e, comesFrom: PNode) =
  var aa = a.tags
  for i in 0..<aa.len:
    # we only track the first node that can have the effect E in order
    # to safe space and time.
    if sameType(aa[i].typ.skipTypes(skipPtrs), e.typ.skipTypes(skipPtrs)): return
  throws(a.tags, e, comesFrom)

proc mergeRaises(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addRaiseEffect(a, createRaise(a.graph, comesFrom), comesFrom)
  else:
    for effect in items(b): addRaiseEffect(a, effect, comesFrom)

proc mergeTags(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addTag(a, createTag(a.graph, comesFrom), comesFrom)
  else:
    for effect in items(b): addTag(a, effect, comesFrom)

proc listEffects(a: PEffects) =
  for e in items(a.exc):  message(a.config, e.info, hintUser, typeToString(e.typ))
  for e in items(a.tags): message(a.config, e.info, hintUser, typeToString(e.typ))
  #if a.maxLockLevel != 0:
  #  message(e.info, hintUser, "lockLevel: " & a.maxLockLevel)

proc catches(tracked: PEffects, e: PType) =
  let e = skipTypes(e, skipPtrs)
  var L = tracked.exc.len
  var i = tracked.bottom
  while i < L:
    # r supertype of e?
    if safeInheritanceDiff(tracked.graph.excType(tracked.exc[i]), e) <= 0:
      tracked.exc[i] = tracked.exc[L-1]
      dec L
    else:
      inc i
  if tracked.exc.len > 0:
    setLen(tracked.exc.sons, L)
  else:
    assert L == 0

proc catchesAll(tracked: PEffects) =
  if tracked.exc.len > 0:
    setLen(tracked.exc.sons, tracked.bottom)

proc track(tracked: PEffects, n: PNode)
proc trackTryStmt(tracked: PEffects, n: PNode) =
  let oldBottom = tracked.bottom
  tracked.bottom = tracked.exc.len

  let oldState = tracked.init.len
  var inter: TIntersection = @[]

  inc tracked.inTryStmt
  track(tracked, n[0])
  dec tracked.inTryStmt
  for i in oldState..<tracked.init.len:
    addToIntersection(inter, tracked.init[i])

  var branches = 1
  var hasFinally = false
  inc tracked.inExceptOrFinallyStmt

  # Collect the exceptions caught by the except branches
  for i in 1..<n.len:
    let b = n[i]
    if b.kind == nkExceptBranch:
      inc branches
      if b.len == 1:
        catchesAll(tracked)
      else:
        for j in 0..<b.len - 1:
          if b[j].isInfixAs():
            assert(b[j][1].kind == nkType)
            catches(tracked, b[j][1].typ)
            createTypeBoundOps(tracked, b[j][2].typ, b[j][2].info)
          else:
            assert(b[j].kind == nkType)
            catches(tracked, b[j].typ)
    else:
      assert b.kind == nkFinally
  # Add any other exception raised in the except bodies
  for i in 1..<n.len:
    let b = n[i]
    if b.kind == nkExceptBranch:
      setLen(tracked.init, oldState)
      track(tracked, b[^1])
      for i in oldState..<tracked.init.len:
        addToIntersection(inter, tracked.init[i])
    else:
      setLen(tracked.init, oldState)
      track(tracked, b[^1])
      hasFinally = true

  tracked.bottom = oldBottom
  dec tracked.inExceptOrFinallyStmt
  if not hasFinally:
    setLen(tracked.init, oldState)
  for id, count in items(inter):
    if count == branches: tracked.init.add id

proc isIndirectCall(n: PNode, owner: PSym): bool =
  # we don't count f(...) as an indirect call if 'f' is an parameter.
  # Instead we track expressions of type tyProc too. See the manual for
  # details:
  if n.kind != nkSym:
    result = true
  elif n.sym.kind == skParam:
    result = owner != n.sym.owner or owner == nil
  elif n.sym.kind notin routineKinds:
    result = true

proc isForwardedProc(n: PNode): bool =
  result = n.kind == nkSym and sfForward in n.sym.flags

proc trackPragmaStmt(tracked: PEffects, n: PNode) =
  for i in 0..<n.len:
    var it = n[i]
    let pragma = whichPragma(it)
    if pragma == wEffects:
      # list the computed effects up to here:
      listEffects(tracked)

template notGcSafe(t): untyped = {tfGcSafe, tfNoSideEffect} * t.flags == {}

proc importedFromC(n: PNode): bool =
  # when imported from C, we assume GC-safety.
  result = n.kind == nkSym and sfImportc in n.sym.flags

proc getLockLevel(s: PSym): TLockLevel =
  result = s.typ.lockLevel
  if result == UnspecifiedLockLevel:
    if {sfImportc, sfNoSideEffect} * s.flags != {} or
       tfNoSideEffect in s.typ.flags:
      result = 0.TLockLevel
    else:
      result = UnknownLockLevel
      #message(s.info, warnUser, "FOR THIS " & s.name.s)

proc mergeLockLevels(tracked: PEffects, n: PNode, lockLevel: TLockLevel) =
  if lockLevel >= tracked.currLockLevel:
    # if in lock section:
    if tracked.currLockLevel > 0.TLockLevel:
      localError tracked.config, n.info, errGenerated,
        "expected lock level < " & $tracked.currLockLevel &
        " but got lock level " & $lockLevel
    tracked.maxLockLevel = max(tracked.maxLockLevel, lockLevel)

proc propagateEffects(tracked: PEffects, n: PNode, s: PSym) =
  let pragma = s.ast[pragmasPos]
  let spec = effectSpec(pragma, wRaises)
  mergeRaises(tracked, spec, n)

  let tagSpec = effectSpec(pragma, wTags)
  mergeTags(tracked, tagSpec, n)

  if notGcSafe(s.typ) and sfImportc notin s.flags:
    if tracked.config.hasWarn(warnGcUnsafe): warnAboutGcUnsafe(n, tracked.config)
    markGcUnsafe(tracked, s)
  if tfNoSideEffect notin s.typ.flags:
    markSideEffect(tracked, s)
  mergeLockLevels(tracked, n, s.getLockLevel)

proc procVarCheck(n: PNode; conf: ConfigRef) =
  if n.kind in nkSymChoices:
    for x in n: procVarCheck(x, conf)
  elif n.kind == nkSym and n.sym.magic != mNone and n.sym.kind in routineKinds:
    localError(conf, n.info, "'$1' cannot be passed to a procvar" % n.sym.name.s)

proc notNilCheck(tracked: PEffects, n: PNode, paramType: PType) =
  let n = n.skipConv
  if paramType.isNil or paramType.kind != tyTypeDesc:
    procVarCheck skipConvCastAndClosure(n), tracked.config
  #elif n.kind in nkSymChoices:
  #  echo "came here"
  let paramType = paramType.skipTypesOrNil(abstractInst)
  if paramType != nil and tfNotNil in paramType.flags and n.typ != nil:
    let ntyp = n.typ.skipTypesOrNil({tyVar, tyLent, tySink})
    if ntyp != nil and tfNotNil notin ntyp.flags:
      if isAddrNode(n):
        # addr(x[]) can't be proven, but addr(x) can:
        if not containsNode(n, {nkDerefExpr, nkHiddenDeref}): return
      elif (n.kind == nkSym and n.sym.kind in routineKinds) or
          (n.kind in procDefs+{nkObjConstr, nkBracket, nkClosure, nkStrLit..nkTripleStrLit}) or
          (n.kind in nkCallKinds and n[0].kind == nkSym and n[0].sym.magic == mArrToSeq) or
          n.typ.kind == tyTypeDesc:
        # 'p' is not nil obviously:
        return
      case impliesNotNil(tracked.guards, n)
      of impUnknown:
        message(tracked.config, n.info, errGenerated,
                "cannot prove '$1' is not nil" % n.renderTree)
      of impNo:
        message(tracked.config, n.info, errGenerated,
                "'$1' is provably nil" % n.renderTree)
      of impYes: discard

proc assumeTheWorst(tracked: PEffects; n: PNode; op: PType) =
  addRaiseEffect(tracked, createRaise(tracked.graph, n), nil)
  addTag(tracked, createTag(tracked.graph, n), nil)
  let lockLevel = if op.lockLevel == UnspecifiedLockLevel: UnknownLockLevel
                  else: op.lockLevel
  #if lockLevel == UnknownLockLevel:
  #  message(n.info, warnUser, "had to assume the worst here")
  mergeLockLevels(tracked, n, lockLevel)

proc isOwnedProcVar(n: PNode; owner: PSym): bool =
  # XXX prove the soundness of this effect system rule
  result = n.kind == nkSym and n.sym.kind == skParam and owner == n.sym.owner

proc isNoEffectList(n: PNode): bool {.inline.} =
  assert n.kind == nkEffectList
  n.len == 0 or (n[tagEffects] == nil and n[exceptionEffects] == nil)

proc isTrival(caller: PNode): bool {.inline.} =
  result = caller.kind == nkSym and caller.sym.magic in {mEqProc, mIsNil, mMove, mWasMoved, mSwap}

proc trackOperandForIndirectCall(tracked: PEffects, n: PNode, paramType: PType; caller: PNode) =
  let a = skipConvCastAndClosure(n)
  let op = a.typ
  # assume indirect calls are taken here:
  if op != nil and op.kind == tyProc and n.skipConv.kind != nkNilLit and not isTrival(caller):
    internalAssert tracked.config, op.n[0].kind == nkEffectList
    var effectList = op.n[0]
    var s = n.skipConv
    if s.kind == nkCast and s[1].typ.kind == tyProc:
      s = s[1]
    if s.kind == nkSym and s.sym.kind in routineKinds and isNoEffectList(effectList):
      propagateEffects(tracked, n, s.sym)
    elif isNoEffectList(effectList):
      if isForwardedProc(n):
        # we have no explicit effects but it's a forward declaration and so it's
        # stated there are no additional effects, so simply propagate them:
        propagateEffects(tracked, n, n.sym)
      elif not isOwnedProcVar(a, tracked.owner):
        # we have no explicit effects so assume the worst:
        assumeTheWorst(tracked, n, op)
      # assume GcUnsafe unless in its type; 'forward' does not matter:
      if notGcSafe(op) and not isOwnedProcVar(a, tracked.owner):
        if tracked.config.hasWarn(warnGcUnsafe): warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
      elif tfNoSideEffect notin op.flags and not isOwnedProcVar(a, tracked.owner):
        markSideEffect(tracked, a)
    else:
      mergeRaises(tracked, effectList[exceptionEffects], n)
      mergeTags(tracked, effectList[tagEffects], n)
      if notGcSafe(op):
        if tracked.config.hasWarn(warnGcUnsafe): warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
      elif tfNoSideEffect notin op.flags:
        markSideEffect(tracked, a)
  if paramType != nil and paramType.kind in {tyVar}:
    invalidateFacts(tracked.guards, n)
    if n.kind == nkSym and isLocalVar(tracked, n.sym):
      makeVolatile(tracked, n.sym)
  if paramType != nil and paramType.kind == tyProc and tfGcSafe in paramType.flags:
    let argtype = skipTypes(a.typ, abstractInst)
    # XXX figure out why this can be a non tyProc here. See httpclient.nim for an
    # example that triggers it.
    if argtype.kind == tyProc and notGcSafe(argtype) and not tracked.inEnforcedGcSafe:
      localError(tracked.config, n.info, $n & " is not GC safe")
  # notNilCheck(tracked, n, paramType)

proc breaksBlock(n: PNode): bool =
  # semantic check doesn't allow statements after raise, break, return or
  # call to noreturn proc, so it is safe to check just the last statements
  var it = n
  while it.kind in {nkStmtList, nkStmtListExpr} and it.len > 0:
    it = it.lastSon

  result = it.kind in {nkBreakStmt, nkReturnStmt, nkRaiseStmt} or
    it.kind in nkCallKinds and it[0].kind == nkSym and sfNoReturn in it[0].sym.flags

proc trackCase(tracked: PEffects, n: PNode) =
  track(tracked, n[0])
  let oldState = tracked.init.len
  let oldFacts = tracked.guards.s.len
  let stringCase = n[0].typ != nil and skipTypes(n[0].typ,
        abstractVarRange-{tyTypeDesc}).kind in {tyFloat..tyFloat128, tyString}
  let interesting = not stringCase and interestingCaseExpr(n[0]) and
        tracked.config.hasWarn(warnProveField)
  var inter: TIntersection = @[]
  var toCover = 0
  for i in 1..<n.len:
    let branch = n[i]
    setLen(tracked.init, oldState)
    if interesting:
      setLen(tracked.guards.s, oldFacts)
      addCaseBranchFacts(tracked.guards, n, i)
    for i in 0..<branch.len:
      track(tracked, branch[i])
    if not breaksBlock(branch.lastSon): inc toCover
    for i in oldState..<tracked.init.len:
      addToIntersection(inter, tracked.init[i])

  setLen(tracked.init, oldState)
  if not stringCase or lastSon(n).kind == nkElse:
    for id, count in items(inter):
      if count >= toCover: tracked.init.add id
    # else we can't merge
  setLen(tracked.guards.s, oldFacts)

proc trackIf(tracked: PEffects, n: PNode) =
  track(tracked, n[0][0])
  let oldFacts = tracked.guards.s.len
  addFact(tracked.guards, n[0][0])
  let oldState = tracked.init.len

  var inter: TIntersection = @[]
  var toCover = 0
  track(tracked, n[0][1])
  if not breaksBlock(n[0][1]): inc toCover
  for i in oldState..<tracked.init.len:
    addToIntersection(inter, tracked.init[i])

  for i in 1..<n.len:
    let branch = n[i]
    setLen(tracked.guards.s, oldFacts)
    for j in 0..i-1:
      addFactNeg(tracked.guards, n[j][0])
    if branch.len > 1:
      addFact(tracked.guards, branch[0])
    setLen(tracked.init, oldState)
    for i in 0..<branch.len:
      track(tracked, branch[i])
    if not breaksBlock(branch.lastSon): inc toCover
    for i in oldState..<tracked.init.len:
      addToIntersection(inter, tracked.init[i])
  setLen(tracked.init, oldState)
  if lastSon(n).len == 1:
    for id, count in items(inter):
      if count >= toCover: tracked.init.add id
    # else we can't merge as it is not exhaustive
  setLen(tracked.guards.s, oldFacts)

proc trackBlock(tracked: PEffects, n: PNode) =
  if n.kind in {nkStmtList, nkStmtListExpr}:
    var oldState = -1
    for i in 0..<n.len:
      if hasSubnodeWith(n[i], nkBreakStmt):
        # block:
        #   x = def
        #   if ...: ... break # some nested break
        #   y = def
        # --> 'y' not defined after block!
        if oldState < 0: oldState = tracked.init.len
      track(tracked, n[i])
    if oldState > 0: setLen(tracked.init, oldState)
  else:
    track(tracked, n)

proc paramType(op: PType, i: int): PType =
  if op != nil and i < op.len: result = op[i]

proc cstringCheck(tracked: PEffects; n: PNode) =
  if n[0].typ.kind == tyCString and (let a = skipConv(n[1]);
      a.typ.kind == tyString and a.kind notin {nkStrLit..nkTripleStrLit}):
    message(tracked.config, n.info, warnUnsafeCode, renderTree(n))

proc patchResult(c: PEffects; n: PNode) =
  if n.kind == nkSym and n.sym.kind == skResult:
    let fn = c.owner
    if fn != nil and fn.kind in routineKinds and fn.ast != nil and resultPos < fn.ast.len:
      n.sym = fn.ast[resultPos].sym
    else:
      localError(c.config, n.info, "routine has no return type, but .requires contains 'result'")
  else:
    for i in 0..<safeLen(n):
      patchResult(c, n[i])

proc checkLe(c: PEffects; a, b: PNode) =
  case proveLe(c.guards, a, b)
  of impUnknown:
    #for g in c.guards.s:
    #  if g != nil: echo "I Know ", g
    message(c.config, a.info, warnStaticIndexCheck,
      "cannot prove: " & $a & " <= " & $b)
  of impYes:
    discard
  of impNo:
    message(c.config, a.info, warnStaticIndexCheck,
      "can prove: " & $a & " > " & $b)

proc checkBounds(c: PEffects; arr, idx: PNode) =
  checkLe(c, lowBound(c.config, arr), idx)
  checkLe(c, idx, highBound(c.config, arr, c.guards.o))

proc checkRange(c: PEffects; value: PNode; typ: PType) =
  let t = typ.skipTypes(abstractInst - {tyRange})
  if t.kind == tyRange:
    let lowBound = copyTree(t.n[0])
    lowBound.info = value.info
    let highBound = copyTree(t.n[1])
    highBound.info = value.info
    checkLe(c, lowBound, value)
    checkLe(c, value, highBound)

proc trackCall(tracked: PEffects; n: PNode) =
  template gcsafeAndSideeffectCheck() =
    if notGcSafe(op) and not importedFromC(a):
      # and it's not a recursive call:
      if not (a.kind == nkSym and a.sym == tracked.owner):
        if tracked.config.hasWarn(warnGcUnsafe): warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
    if tfNoSideEffect notin op.flags and not importedFromC(a):
      # and it's not a recursive call:
      if not (a.kind == nkSym and a.sym == tracked.owner):
        markSideEffect(tracked, a)

  # p's effects are ours too:
  var a = n[0]
  #if canRaise(a):
  #  echo "this can raise ", tracked.config $ n.info
  let op = a.typ
  if n.typ != nil:
    if tracked.owner.kind != skMacro and n.typ.skipTypes(abstractVar).kind != tyOpenArray:
      createTypeBoundOps(tracked, n.typ, n.info)
  if getConstExpr(tracked.ownerModule, n, tracked.c.idgen, tracked.graph) != nil:
    return
  if a.kind == nkCast and a[1].typ.kind == tyProc:
    a = a[1]
  # XXX: in rare situations, templates and macros will reach here after
  # calling getAst(templateOrMacro()). Currently, templates and macros
  # are indistinguishable from normal procs (both have tyProc type) and
  # we can detect them only by checking for attached nkEffectList.
  if op != nil and op.kind == tyProc and op.n[0].kind == nkEffectList:
    if a.kind == nkSym:
      if a.sym == tracked.owner: tracked.isRecursive = true
      # even for recursive calls we need to check the lock levels (!):
      mergeLockLevels(tracked, n, a.sym.getLockLevel)
      if sfSideEffect in a.sym.flags: markSideEffect(tracked, a)
    else:
      mergeLockLevels(tracked, n, op.lockLevel)
    var effectList = op.n[0]
    if a.kind == nkSym and a.sym.kind == skMethod:
      propagateEffects(tracked, n, a.sym)
    elif isNoEffectList(effectList):
      if isForwardedProc(a):
        propagateEffects(tracked, n, a.sym)
      elif isIndirectCall(a, tracked.owner):
        assumeTheWorst(tracked, n, op)
        gcsafeAndSideeffectCheck()
    else:
      mergeRaises(tracked, effectList[exceptionEffects], n)
      mergeTags(tracked, effectList[tagEffects], n)
      gcsafeAndSideeffectCheck()
  if a.kind != nkSym or a.sym.magic != mNBindSym:
    for i in 1..<n.len: trackOperandForIndirectCall(tracked, n[i], paramType(op, i), a)
  if a.kind == nkSym and a.sym.magic in {mNew, mNewFinalize, mNewSeq}:
    # may not look like an assignment, but it is:
    let arg = n[1]
    initVarViaNew(tracked, arg)
    if arg.typ.len != 0 and {tfRequiresInit} * arg.typ.lastSon.flags != {}:
      if a.sym.magic == mNewSeq and n[2].kind in {nkCharLit..nkUInt64Lit} and
          n[2].intVal == 0:
        # var s: seq[notnil];  newSeq(s, 0)  is a special case!
        discard
      else:
        message(tracked.config, arg.info, warnProveInit, $arg)

    # check required for 'nim check':
    if n[1].typ.len > 0:
      createTypeBoundOps(tracked, n[1].typ.lastSon, n.info)
      createTypeBoundOps(tracked, n[1].typ, n.info)
      # new(x, finalizer): Problem: how to move finalizer into 'createTypeBoundOps'?

  elif a.kind == nkSym and a.sym.magic in {mArrGet, mArrPut} and
      optStaticBoundsCheck in tracked.currOptions:
    checkBounds(tracked, n[1], n[2])

  if a.kind == nkSym and a.sym.name.s.len > 0 and a.sym.name.s[0] == '=' and
        tracked.owner.kind != skMacro:
    var opKind = find(AttachedOpToStr, a.sym.name.s.normalize)
    if a.sym.name.s.normalize == "=": opKind = attachedAsgn.int
    if opKind != -1:
      # rebind type bounds operations after createTypeBoundOps call
      let t = n[1].typ.skipTypes({tyAlias, tyVar})
      if a.sym != t.attachedOps[TTypeAttachedOp(opKind)]:
        createTypeBoundOps(tracked, t, n.info)
        let op = t.attachedOps[TTypeAttachedOp(opKind)]
        if op != nil:
          n[0].sym = op

  if a.kind != nkSym or a.sym.magic != mRunnableExamples:
    for i in 0..<n.safeLen:
      track(tracked, n[i])
  if op != nil and op.kind == tyProc:
    for i in 1..<min(n.safeLen, op.len):
      case op[i].kind
      of tySink:
        createTypeBoundOps(tracked,  op[i][0], n.info)
        checkForSink(tracked.config, tracked.c.idgen, tracked.owner, n[i])
      of tyVar:
        tracked.hasDangerousAssign = true
      #of tyOut:
      # consider this case: p(out x, x); we want to remark that 'x' is not
      # initialized until after the call. Since we do this after we analysed the
      # call, this is fine.
      # initVar(tracked, n[i].skipAddr, false)
      else: discard

type
  PragmaBlockContext = object
    oldLocked: int
    oldLockLevel: TLockLevel
    enforcedGcSafety, enforceNoSideEffects: bool
    oldExc, oldTags: int
    exc, tags: PNode

proc createBlockContext(tracked: PEffects): PragmaBlockContext =
  result = PragmaBlockContext(oldLocked: tracked.locked.len,
    oldLockLevel: tracked.currLockLevel,
    enforcedGcSafety: false, enforceNoSideEffects: false,
    oldExc: tracked.exc.len, oldTags: tracked.tags.len)

proc applyBlockContext(tracked: PEffects, bc: PragmaBlockContext) =
  if bc.enforcedGcSafety: tracked.inEnforcedGcSafe = true
  if bc.enforceNoSideEffects: tracked.inEnforcedNoSideEffects = true

proc unapplyBlockContext(tracked: PEffects; bc: PragmaBlockContext) =
  if bc.enforcedGcSafety: tracked.inEnforcedGcSafe = false
  if bc.enforceNoSideEffects: tracked.inEnforcedNoSideEffects = false
  setLen(tracked.locked, bc.oldLocked)
  tracked.currLockLevel = bc.oldLockLevel
  if bc.exc != nil:
    # beware that 'raises: []' is very different from not saying
    # anything about 'raises' in the 'cast' at all. Same applies for 'tags'.
    setLen(tracked.exc.sons, bc.oldExc)
    for e in bc.exc:
      addRaiseEffect(tracked, e, e)
  if bc.tags != nil:
    setLen(tracked.tags.sons, bc.oldTags)
    for t in bc.tags:
      addTag(tracked, t, t)

proc castBlock(tracked: PEffects, pragma: PNode, bc: var PragmaBlockContext) =
  case whichPragma(pragma)
  of wGcSafe:
    bc.enforcedGcSafety = true
  of wNoSideEffect:
    bc.enforceNoSideEffects = true
  of wTags:
    let n = pragma[1]
    if n.kind in {nkCurly, nkBracket}:
      bc.tags = n
    else:
      bc.tags = newNodeI(nkArgList, pragma.info)
      bc.tags.add n
  of wRaises:
    let n = pragma[1]
    if n.kind in {nkCurly, nkBracket}:
      bc.exc = n
    else:
      bc.exc = newNodeI(nkArgList, pragma.info)
      bc.exc.add n
  else:
    localError(tracked.config, pragma.info,
        "invalid pragma block: " & $pragma)

proc track(tracked: PEffects, n: PNode) =
  case n.kind
  of nkSym:
    useVar(tracked, n)
    if n.sym.typ != nil and tfHasAsgn in n.sym.typ.flags:
      tracked.owner.flags.incl sfInjectDestructors
      # bug #15038: ensure consistency
      if not hasDestructor(n.typ) and sameType(n.typ, n.sym.typ): n.typ = n.sym.typ
  of nkHiddenAddr, nkAddr:
    if n[0].kind == nkSym and isLocalVar(tracked, n[0].sym):
      useVarNoInitCheck(tracked, n[0], n[0].sym)
    else:
      track(tracked, n[0])
  of nkRaiseStmt:
    if n[0].kind != nkEmpty:
      n[0].info = n.info
      #throws(tracked.exc, n[0])
      addRaiseEffect(tracked, n[0], nil)
      for i in 0..<n.safeLen:
        track(tracked, n[i])
      createTypeBoundOps(tracked, n[0].typ, n.info)
    else:
      # A `raise` with no arguments means we're going to re-raise the exception
      # being handled or, if outside of an `except` block, a `ReraiseDefect`.
      # Here we add a `Exception` tag in order to cover both the cases.
      addRaiseEffect(tracked, createRaise(tracked.graph, n), nil)
  of nkCallKinds:
    trackCall(tracked, n)
  of nkDotExpr:
    guardDotAccess(tracked, n)
    for i in 0..<n.len: track(tracked, n[i])
  of nkCheckedFieldExpr:
    track(tracked, n[0])
    if tracked.config.hasWarn(warnProveField):
      checkFieldAccess(tracked.guards, n, tracked.config)
  of nkTryStmt: trackTryStmt(tracked, n)
  of nkPragma: trackPragmaStmt(tracked, n)
  of nkAsgn, nkFastAsgn:
    track(tracked, n[1])
    initVar(tracked, n[0], volatileCheck=true)
    invalidateFacts(tracked.guards, n[0])
    inc tracked.leftPartOfAsgn
    track(tracked, n[0])
    dec tracked.leftPartOfAsgn
    addAsgnFact(tracked.guards, n[0], n[1])
#    notNilCheck(tracked, n[1], n[0].typ)
    when false: cstringCheck(tracked, n)
    if tracked.owner.kind != skMacro:
      createTypeBoundOps(tracked, n[0].typ, n.info)
    if n[0].kind != nkSym or not isLocalVar(tracked, n[0].sym):
      checkForSink(tracked.config, tracked.c.idgen, tracked.owner, n[1])
      if not tracked.hasDangerousAssign and n[0].kind != nkSym:
        tracked.hasDangerousAssign = true
  of nkVarSection, nkLetSection:
    for child in n:
      let last = lastSon(child)
      if last.kind != nkEmpty: track(tracked, last)
      if tracked.owner.kind != skMacro:
        if child.kind == nkVarTuple:
          createTypeBoundOps(tracked, child[^1].typ, child.info)
          for i in 0..<child.len-2:
            createTypeBoundOps(tracked, child[i].typ, child.info)
        else:
          createTypeBoundOps(tracked, child[0].typ, child.info)
      if child.kind == nkIdentDefs and last.kind != nkEmpty:
        for i in 0..<child.len-2:
          initVar(tracked, child[i], volatileCheck=false)
          addAsgnFact(tracked.guards, child[i], last)
#          notNilCheck(tracked, last, child[i].typ)
      elif child.kind == nkVarTuple and last.kind != nkEmpty:
        for i in 0..<child.len-1:
          if child[i].kind == nkEmpty or
            child[i].kind == nkSym and child[i].sym.name.s == "_":
            continue
          initVar(tracked, child[i], volatileCheck=false)
          if last.kind in {nkPar, nkTupleConstr}:
            addAsgnFact(tracked.guards, child[i], last[i])
            # notNilCheck(tracked, last[i], child[i].typ)
      # since 'var (a, b): T = ()' is not even allowed, there is always type
      # inference for (a, b) and thus no nil checking is necessary.
  of nkConstSection:
    for child in n:
      let last = lastSon(child)
      track(tracked, last)
  of nkCaseStmt: trackCase(tracked, n)
  of nkWhen, nkIfStmt, nkIfExpr: trackIf(tracked, n)
  of nkBlockStmt, nkBlockExpr: trackBlock(tracked, n[1])
  of nkWhileStmt:
    # 'while true' loop?
    if isTrue(n[0]):
      trackBlock(tracked, n[1])
    else:
      # loop may never execute:
      let oldState = tracked.init.len
      let oldFacts = tracked.guards.s.len
      addFact(tracked.guards, n[0])
      track(tracked, n[0])
      track(tracked, n[1])
      setLen(tracked.init, oldState)
      setLen(tracked.guards.s, oldFacts)
  of nkForStmt, nkParForStmt:
    # we are very conservative here and assume the loop is never executed:
    let oldState = tracked.init.len

    let oldFacts = tracked.guards.s.len
    let iterCall = n[n.len-2]
    if optStaticBoundsCheck in tracked.currOptions and iterCall.kind in nkCallKinds:
      let op = iterCall[0]
      if op.kind == nkSym and fromSystem(op.sym):
        let iterVar = n[0]
        case op.sym.name.s
        of "..", "countup", "countdown":
          let lower = iterCall[1]
          let upper = iterCall[2]
          # for i in 0..n   means  0 <= i and i <= n. Countdown is
          # the same since only the iteration direction changes.
          addFactLe(tracked.guards, lower, iterVar)
          addFactLe(tracked.guards, iterVar, upper)
        of "..<":
          let lower = iterCall[1]
          let upper = iterCall[2]
          addFactLe(tracked.guards, lower, iterVar)
          addFactLt(tracked.guards, iterVar, upper)
        else: discard

    for i in 0..<n.len-2:
      let it = n[i]
      track(tracked, it)
      if tracked.owner.kind != skMacro:
        if it.kind == nkVarTuple:
          for x in it:
            createTypeBoundOps(tracked, x.typ, x.info)
        else:
          createTypeBoundOps(tracked, it.typ, it.info)
    let loopBody = n[^1]
    if tracked.owner.kind != skMacro and iterCall.safeLen > 1:
      # XXX this is a bit hacky:
      if iterCall[1].typ != nil and iterCall[1].typ.skipTypes(abstractVar).kind notin {tyVarargs, tyOpenArray}:
        createTypeBoundOps(tracked, iterCall[1].typ, iterCall[1].info)
    track(tracked, iterCall)
    track(tracked, loopBody)
    setLen(tracked.init, oldState)
    setLen(tracked.guards.s, oldFacts)
  of nkObjConstr:
    when false: track(tracked, n[0])
    let oldFacts = tracked.guards.s.len
    for i in 1..<n.len:
      let x = n[i]
      track(tracked, x)
      if x[0].kind == nkSym and sfDiscriminant in x[0].sym.flags:
        addDiscriminantFact(tracked.guards, x)
      if tracked.owner.kind != skMacro:
        createTypeBoundOps(tracked, x[1].typ, n.info)

      if x.kind == nkExprColonExpr:
        if x[0].kind == nkSym:
          notNilCheck(tracked, x[1], x[0].sym.typ)
        checkForSink(tracked.config, tracked.c.idgen, tracked.owner, x[1])
      else:
        checkForSink(tracked.config, tracked.c.idgen, tracked.owner, x)
    setLen(tracked.guards.s, oldFacts)
    if tracked.owner.kind != skMacro:
      # XXX n.typ can be nil in runnableExamples, we need to do something about it.
      if n.typ != nil and n.typ.skipTypes(abstractInst).kind == tyRef:
        createTypeBoundOps(tracked, n.typ.lastSon, n.info)
      createTypeBoundOps(tracked, n.typ, n.info)
  of nkTupleConstr:
    for i in 0..<n.len:
      track(tracked, n[i])
      if tracked.owner.kind != skMacro:
        if n[i].kind == nkExprColonExpr:
          createTypeBoundOps(tracked, n[i][0].typ, n.info)
        else:
          createTypeBoundOps(tracked, n[i].typ, n.info)
      checkForSink(tracked.config, tracked.c.idgen, tracked.owner, n[i])
  of nkPragmaBlock:
    let pragmaList = n[0]
    var bc = createBlockContext(tracked)
    for i in 0..<pragmaList.len:
      let pragma = whichPragma(pragmaList[i])
      case pragma
      of wLocks:
        lockLocations(tracked, pragmaList[i])
      of wGcSafe:
        bc.enforcedGcSafety = true
      of wNoSideEffect:
        bc.enforceNoSideEffects = true
      of wCast:
        castBlock(tracked, pragmaList[i][1], bc)
      else:
        discard
    applyBlockContext(tracked, bc)
    track(tracked, n.lastSon)
    unapplyBlockContext(tracked, bc)

  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    discard
  of nkCast:
    if n.len == 2:
      track(tracked, n[1])
      if tracked.owner.kind != skMacro:
        createTypeBoundOps(tracked, n.typ, n.info)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    if n.len == 2:
      track(tracked, n[1])
      if tracked.owner.kind != skMacro:
        createTypeBoundOps(tracked, n.typ, n.info)
        # This is a hacky solution in order to fix bug #13110. Hopefully
        # a better solution will come up eventually.
        if n[1].typ.kind != tyString:
          createTypeBoundOps(tracked, n[1].typ, n[1].info)
      if optStaticBoundsCheck in tracked.currOptions:
        checkRange(tracked, n[1], n.typ)
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    if n.len == 1:
      track(tracked, n[0])
      if tracked.owner.kind != skMacro:
        createTypeBoundOps(tracked, n.typ, n.info)
        createTypeBoundOps(tracked, n[0].typ, n[0].info)
      if optStaticBoundsCheck in tracked.currOptions:
        checkRange(tracked, n[0], n.typ)
  of nkBracket:
    for i in 0..<n.safeLen:
      track(tracked, n[i])
      checkForSink(tracked.config, tracked.c.idgen, tracked.owner, n[i])
    if tracked.owner.kind != skMacro:
      createTypeBoundOps(tracked, n.typ, n.info)
  of nkBracketExpr:
    if optStaticBoundsCheck in tracked.currOptions and n.len == 2:
      if n[0].typ != nil and skipTypes(n[0].typ, abstractVar).kind != tyTuple:
        checkBounds(tracked, n[0], n[1])
    track(tracked, n[0])
    dec tracked.leftPartOfAsgn
    for i in 1 ..< n.len: track(tracked, n[i])
    inc tracked.leftPartOfAsgn
  else:
    for i in 0..<n.safeLen: track(tracked, n[i])

proc subtypeRelation(g: ModuleGraph; spec, real: PNode): bool =
  if spec.typ.kind == tyOr:
    for t in spec.typ.sons:
      if safeInheritanceDiff(g.excType(real), t) <= 0:
        return true
  else:
    return safeInheritanceDiff(g.excType(real), spec.typ) <= 0

proc checkRaisesSpec(g: ModuleGraph; spec, real: PNode, msg: string, hints: bool;
                     effectPredicate: proc (g: ModuleGraph; a, b: PNode): bool {.nimcall.};
                     hintsArg: PNode = nil) =
  # check that any real exception is listed in 'spec'; mark those as used;
  # report any unused exception
  var used = initIntSet()
  for r in items(real):
    block search:
      for s in 0..<spec.len:
        if effectPredicate(g, spec[s], r):
          used.incl(s)
          break search
      # XXX call graph analysis would be nice here!
      pushInfoContext(g.config, spec.info)
      localError(g.config, r.info, errGenerated, msg & typeToString(r.typ))
      popInfoContext(g.config)
  # hint about unnecessarily listed exception types:
  if hints:
    for s in 0..<spec.len:
      if not used.contains(s):
        message(g.config, spec[s].info, hintXCannotRaiseY,
                "'$1' cannot raise '$2'" % [renderTree(hintsArg), renderTree(spec[s])])

proc checkMethodEffects*(g: ModuleGraph; disp, branch: PSym) =
  ## checks for consistent effects for multi methods.
  let actual = branch.typ.n[0]
  if actual.len != effectListLen: return

  let p = disp.ast[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(g, raisesSpec, actual[exceptionEffects],
      "can raise an unlisted exception: ", hints=off, subtypeRelation)
  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(g, tagsSpec, actual[tagEffects],
      "can have an unlisted effect: ", hints=off, subtypeRelation)
  if sfThread in disp.flags and notGcSafe(branch.typ):
    localError(g.config, branch.info, "base method is GC-safe, but '$1' is not" %
                                branch.name.s)
  when defined(drnim):
    if not g.compatibleProps(g, disp.typ, branch.typ):
      localError(g.config, branch.info, "for method '" & branch.name.s &
        "' the `.requires` or `.ensures` properties are incompatible.")

  if branch.typ.lockLevel > disp.typ.lockLevel:
    when true:
      message(g.config, branch.info, warnLockLevel,
        "base method has lock level $1, but dispatcher has $2" %
          [$branch.typ.lockLevel, $disp.typ.lockLevel])
    else:
      # XXX make this an error after bigbreak has been released:
      localError(g.config, branch.info,
        "base method has lock level $1, but dispatcher has $2" %
          [$branch.typ.lockLevel, $disp.typ.lockLevel])

proc setEffectsForProcType*(g: ModuleGraph; t: PType, n: PNode) =
  var effects = t.n[0]
  if t.kind != tyProc or effects.kind != nkEffectList: return
  if n.kind != nkEmpty:
    internalAssert g.config, effects.len == 0
    newSeq(effects.sons, effectListLen)
    let raisesSpec = effectSpec(n, wRaises)
    if not isNil(raisesSpec):
      effects[exceptionEffects] = raisesSpec
    let tagsSpec = effectSpec(n, wTags)
    if not isNil(tagsSpec):
      effects[tagEffects] = tagsSpec

    let requiresSpec = propSpec(n, wRequires)
    if not isNil(requiresSpec):
      effects[requiresEffects] = requiresSpec
    let ensuresSpec = propSpec(n, wEnsures)
    if not isNil(ensuresSpec):
      effects[ensuresEffects] = ensuresSpec

    effects[pragmasEffects] = n

proc initEffects(g: ModuleGraph; effects: PNode; s: PSym; t: var TEffects; c: PContext) =
  newSeq(effects.sons, effectListLen)
  effects[exceptionEffects] = newNodeI(nkArgList, s.info)
  effects[tagEffects] = newNodeI(nkArgList, s.info)
  effects[requiresEffects] = g.emptyNode
  effects[ensuresEffects] = g.emptyNode
  effects[pragmasEffects] = g.emptyNode

  t.exc = effects[exceptionEffects]
  t.tags = effects[tagEffects]
  t.owner = s
  t.ownerModule = s.getModule
  t.init = @[]
  t.guards.s = @[]
  t.guards.o = initOperators(g)
  when defined(drnim):
    t.currOptions = g.config.options + s.options - {optStaticBoundsCheck}
  else:
    t.currOptions = g.config.options + s.options
  t.guards.beSmart = optStaticBoundsCheck in t.currOptions
  t.locked = @[]
  t.graph = g
  t.config = g.config
  t.c = c

proc hasRealBody(s: PSym): bool =
  ## also handles importc procs with runnableExamples, which requires `=`,
  ## which is not a real implementation, refs #14314
  result = {sfForward, sfImportc} * s.flags == {}

proc trackProc*(c: PContext; s: PSym, body: PNode) =
  let g = c.graph
  var effects = s.typ.n[0]
  if effects.kind != nkEffectList: return
  # effects already computed?
  if not s.hasRealBody: return
  if effects.len == effectListLen: return

  var t: TEffects
  initEffects(g, effects, s, t, c)
  track(t, body)

  if s.kind != skMacro:
    let params = s.typ.n
    for i in 1..<params.len:
      let param = params[i].sym
      let typ = param.typ
      if isSinkTypeForParam(typ) or
          (t.config.selectedGC in {gcArc, gcOrc} and isClosure(typ.skipTypes(abstractInst))):
        createTypeBoundOps(t, typ, param.info)
      when false:
        if typ.kind == tyOut and param.id notin t.init:
          message(g.config, param.info, warnProveInit, param.name.s)

  if not isEmptyType(s.typ[0]) and
     (s.typ[0].requiresInit or s.typ[0].skipTypes(abstractInst).kind == tyVar) and
     s.kind in {skProc, skFunc, skConverter, skMethod}:
    var res = s.ast[resultPos].sym # get result symbol
    if res.id notin t.init:
      message(g.config, body.info, warnProveInit, "result")
  let p = s.ast[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(g, raisesSpec, t.exc, "can raise an unlisted exception: ",
                    hints=on, subtypeRelation, hintsArg=s.ast[0])
    # after the check, use the formal spec:
    effects[exceptionEffects] = raisesSpec

  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(g, tagsSpec, t.tags, "can have an unlisted effect: ",
                    hints=off, subtypeRelation)
    # after the check, use the formal spec:
    effects[tagEffects] = tagsSpec

  let requiresSpec = propSpec(p, wRequires)
  if not isNil(requiresSpec):
    effects[requiresEffects] = requiresSpec
  let ensuresSpec = propSpec(p, wEnsures)
  if not isNil(ensuresSpec):
    patchResult(t, ensuresSpec)
    effects[ensuresEffects] = ensuresSpec

  var mutationInfo = MutationInfo()
  if {strictFuncs, views} * c.features != {}:
    var goals: set[Goal] = {}
    if strictFuncs in c.features: goals.incl constParameters
    if views in c.features: goals.incl borrowChecking
    var partitions = computeGraphPartitions(s, body, g.config, goals)
    if not t.hasSideEffect and t.hasDangerousAssign:
      t.hasSideEffect = varpartitions.hasSideEffect(partitions, mutationInfo)
    if views in c.features:
      checkBorrowedLocations(partitions, body, g.config)

  if sfThread in s.flags and t.gcUnsafe:
    if optThreads in g.config.globalOptions and optThreadAnalysis in g.config.globalOptions:
      #localError(s.info, "'$1' is not GC-safe" % s.name.s)
      listGcUnsafety(s, onlyWarning=false, g.config)
    else:
      listGcUnsafety(s, onlyWarning=true, g.config)
      #localError(s.info, warnGcUnsafe2, s.name.s)
  if sfNoSideEffect in s.flags and t.hasSideEffect:
    when false:
      listGcUnsafety(s, onlyWarning=false, g.config)
    else:
      localError(g.config, s.info, ("'$1' can have side effects" % s.name.s) & (g.config $ mutationInfo))
  if not t.gcUnsafe:
    s.typ.flags.incl tfGcSafe
  if not t.hasSideEffect and sfSideEffect notin s.flags:
    s.typ.flags.incl tfNoSideEffect
  if s.typ.lockLevel == UnspecifiedLockLevel:
    s.typ.lockLevel = t.maxLockLevel
  elif t.maxLockLevel > s.typ.lockLevel:
    #localError(s.info,
    message(g.config, s.info, warnLockLevel,
      "declared lock level is $1, but real lock level is $2" %
        [$s.typ.lockLevel, $t.maxLockLevel])
  when defined(drnim):
    if c.graph.strongSemCheck != nil: c.graph.strongSemCheck(c.graph, s, body)
  when defined(useDfa):
    if s.name.s == "testp":
      dataflowAnalysis(s, body)
                                                                                                                   
      when false: trackWrites(s, body)
  if s.kind == skProc:
    checkNil(s, body, g.config)

proc trackStmt*(c: PContext; module: PSym; n: PNode, isTopLevel: bool) =
  if n.kind in {nkPragma, nkMacroDef, nkTemplateDef, nkProcDef, nkFuncDef,
                nkTypeSection, nkConverterDef, nkMethodDef, nkIteratorDef}:
    return
  let g = c.graph
  var effects = newNodeI(nkEffectList, n.info)
  var t: TEffects
  initEffects(g, effects, module, t, c)
  t.isTopLevel = isTopLevel
  track(t, n)
  when defined(drnim):
    if c.graph.strongSemCheck != nil: c.graph.strongSemCheck(c.graph, module, n)
