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
  modulegraphs, lowerings, sigmatch, tables

when not defined(leanCompiler):
  import writetracking

when defined(useDfa):
  import dfa

include liftdestructors

#[ Second semantic checking pass over the AST. Necessary because the old
   way had some inherent problems. Performs:

* effect+exception tracking
* "usage before definition" checking
* also now calls the "lift destructor logic" at strategic positions, this
  is about to be put into the spec:

We treat assignment and sinks and destruction as identical.

In the construct let/var x = expr() x's type is marked.

In x = y the type of x is marked.

For every sink parameter of type T T is marked. TODO!

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
    bottom, inTryStmt: int
    owner: PSym
    ownerModule: PSym
    init: seq[int] # list of initialized variables
    guards: TModel # nested guards
    locked: seq[PNode] # locked locations
    gcUnsafe, isRecursive, isToplevel, hasSideEffect, inEnforcedGcSafe: bool
    inEnforcedNoSideEffects: bool
    maxLockLevel, currLockLevel: TLockLevel
    config: ConfigRef
    graph: ModuleGraph
    c: PContext
  PEffects = var TEffects

proc `<`(a, b: TLockLevel): bool {.borrow.}
proc `<=`(a, b: TLockLevel): bool {.borrow.}
proc `==`(a, b: TLockLevel): bool {.borrow.}
proc max(a, b: TLockLevel): TLockLevel {.borrow.}

proc isLocalVar(a: PEffects, s: PSym): bool =
  s.kind in {skVar, skResult} and sfGlobal notin s.flags and
    s.owner == a.owner and s.typ != nil

proc getLockLevel(t: PType): TLockLevel =
  var t = t
  # tyGenericInst(TLock {tyGenericBody}, tyStatic, tyObject):
  if t.kind == tyGenericInst and t.len == 3: t = t.sons[1]
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
  let ri = n.sons[1]
  if ri.kind != nkSym or ri.sym.kind != skField: return
  var g = ri.sym.guard
  if g.isNil or a.isTopLevel: return
  # fixup guard:
  if g.kind == skUnknown:
    var field: PSym = nil
    var ty = n.sons[0].typ.skipTypes(abstractPtrs)
    if ty.kind == tyTuple and not ty.n.isNil:
      field = lookupInRecord(ty.n, g.name)
    else:
      while ty != nil and ty.kind == tyObject:
        field = lookupInRecord(ty.n, g.name)
        if field != nil: break
        ty = ty.sons[0]
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
    dot.sons[0] = n.sons[0]
    dot.sons[1] = newSymNode(g)
    dot.typ = g.typ
    for L in a.locked:
      #if a.guards.sameSubexprs(dot, L): return
      if guards.sameTree(dot, L): return
    localError(a.config, n.info, "unguarded access: " & renderTree(n))
  else:
    guardGlobal(a, n, g)

proc makeVolatile(a: PEffects; s: PSym) {.inline.} =
  template compileToCpp(a): untyped =
    a.config.cmd == cmdCompileToCpp or sfCompileToCpp in getModule(a.owner).flags
  if a.inTryStmt > 0 and not compileToCpp(a):
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
  if {tfNeedsInit, tfNotNil} * s.typ.flags <= {tfNotNil}:
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
        a.owner.gcUnsafetyReason = newSym(skUnknown, a.owner.name,
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

proc useVar(a: PEffects, n: PNode) =
  let s = n.sym
  if isLocalVar(a, s):
    if sfNoInit in s.flags:
      # If the variable is explicitly marked as .noinit. do not emit any error
      a.init.add s.id
    elif s.id notin a.init:
      if {tfNeedsInit, tfNotNil} * s.typ.flags != {}:
        message(a.config, n.info, warnProveInit, s.name.s)
      else:
        message(a.config, n.info, warnUninit, s.name.s)
      # prevent superfluous warnings about the same variable:
      a.init.add s.id
  if {sfGlobal, sfThread} * s.flags != {} and s.kind in {skVar, skLet} and
      s.magic != mNimVm:
    if s.guard != nil: guardGlobal(a, n, s.guard)
    if {sfGlobal, sfThread} * s.flags == {sfGlobal} and
        (tfHasGCedMem in s.typ.flags or s.typ.isGCedMem):
      #if warnGcUnsafe in gNotes: warnAboutGcUnsafe(n)
      markGcUnsafe(a, s)
      markSideEffect(a, s)
    else:
      markSideEffect(a, s)


type
  TIntersection = seq[tuple[id, count: int]] # a simple count table

proc addToIntersection(inter: var TIntersection, s: int) =
  for j in 0..<inter.len:
    if s == inter[j].id:
      inc inter[j].count
      return
  inter.add((id: s, count: 1))

proc throws(tracked, n: PNode) =
  if n.typ == nil or n.typ.kind != tyError: tracked.add n

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

proc addEffect(a: PEffects, e: PNode, useLineInfo=true) =
  assert e.kind != nkRaiseStmt
  var aa = a.exc
  for i in a.bottom ..< aa.len:
    if sameType(a.graph.excType(aa[i]), a.graph.excType(e)):
      if not useLineInfo or a.config.cmd == cmdDoc: return
      elif aa[i].info == e.info: return
  throws(a.exc, e)

proc addTag(a: PEffects, e: PNode, useLineInfo=true) =
  var aa = a.tags
  for i in 0 ..< aa.len:
    if sameType(aa[i].typ.skipTypes(skipPtrs), e.typ.skipTypes(skipPtrs)):
      if not useLineInfo or a.config.cmd == cmdDoc: return
      elif aa[i].info == e.info: return
  throws(a.tags, e)

proc mergeEffects(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addEffect(a, createRaise(a.graph, comesFrom))
  else:
    for effect in items(b): addEffect(a, effect, useLineInfo=comesFrom != nil)

proc mergeTags(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addTag(a, createTag(a.graph, comesFrom))
  else:
    for effect in items(b): addTag(a, effect, useLineInfo=comesFrom != nil)

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
      tracked.exc.sons[i] = tracked.exc.sons[L-1]
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
  track(tracked, n.sons[0])
  dec tracked.inTryStmt
  for i in oldState..<tracked.init.len:
    addToIntersection(inter, tracked.init[i])

  var branches = 1
  var hasFinally = false

  # Collect the exceptions caught by the except branches
  for i in 1 ..< n.len:
    let b = n.sons[i]
    let blen = sonsLen(b)
    if b.kind == nkExceptBranch:
      inc branches
      if blen == 1:
        catchesAll(tracked)
      else:
        for j in 0 .. blen - 2:
          if b.sons[j].isInfixAs():
            assert(b.sons[j][1].kind == nkType)
            catches(tracked, b.sons[j][1].typ)
          else:
            assert(b.sons[j].kind == nkType)
            catches(tracked, b.sons[j].typ)
    else:
      assert b.kind == nkFinally
  # Add any other exception raised in the except bodies
  for i in 1 ..< n.len:
    let b = n.sons[i]
    let blen = sonsLen(b)
    if b.kind == nkExceptBranch:
      setLen(tracked.init, oldState)
      track(tracked, b.sons[blen-1])
      for i in oldState..<tracked.init.len:
        addToIntersection(inter, tracked.init[i])
    else:
      setLen(tracked.init, oldState)
      track(tracked, b.sons[blen-1])
      hasFinally = true

  tracked.bottom = oldBottom
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
  for i in 0 ..< sonsLen(n):
    var it = n.sons[i]
    if whichPragma(it) == wEffects:
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
  let pragma = s.ast.sons[pragmasPos]
  let spec = effectSpec(pragma, wRaises)
  mergeEffects(tracked, spec, n)

  let tagSpec = effectSpec(pragma, wTags)
  mergeTags(tracked, tagSpec, n)

  if notGcSafe(s.typ) and sfImportc notin s.flags:
    if warnGcUnsafe in tracked.config.notes: warnAboutGcUnsafe(n, tracked.config)
    markGcUnsafe(tracked, s)
  if tfNoSideEffect notin s.typ.flags:
    markSideEffect(tracked, s)
  mergeLockLevels(tracked, n, s.getLockLevel)

proc procVarcheck(n: PNode; conf: ConfigRef) =
  if n.kind in nkSymChoices:
    for x in n: procVarCheck(x, conf)
  elif n.kind == nkSym and n.sym.magic != mNone and n.sym.kind in routineKinds:
    localError(conf, n.info, "'$1' cannot be passed to a procvar" % n.sym.name.s)

proc notNilCheck(tracked: PEffects, n: PNode, paramType: PType) =
  let n = n.skipConv
  if paramType.isNil or paramType.kind != tyTypeDesc:
    procVarcheck skipConvAndClosure(n), tracked.config
  #elif n.kind in nkSymChoices:
  #  echo "came here"
  let paramType = paramType.skipTypesOrNil(abstractInst)
  if paramType != nil and tfNotNil in paramType.flags and
      n.typ != nil and tfNotNil notin n.typ.flags:
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
  addEffect(tracked, createRaise(tracked.graph, n))
  addTag(tracked, createTag(tracked.graph, n))
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
  result = caller.kind == nkSym and caller.sym.magic in {mEqProc, mIsNil, mMove, mWasMoved}

proc trackOperand(tracked: PEffects, n: PNode, paramType: PType; caller: PNode) =
  let a = skipConvAndClosure(n)
  let op = a.typ
  # assume indirect calls are taken here:
  if op != nil and op.kind == tyProc and n.skipConv.kind != nkNilLit and not isTrival(caller):
    internalAssert tracked.config, op.n.sons[0].kind == nkEffectList
    var effectList = op.n.sons[0]
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
        if warnGcUnsafe in tracked.config.notes: warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
      elif tfNoSideEffect notin op.flags and not isOwnedProcVar(a, tracked.owner):
        markSideEffect(tracked, a)
    else:
      mergeEffects(tracked, effectList.sons[exceptionEffects], n)
      mergeTags(tracked, effectList.sons[tagEffects], n)
      if notGcSafe(op):
        if warnGcUnsafe in tracked.config.notes: warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
      elif tfNoSideEffect notin op.flags:
        markSideEffect(tracked, a)
  if paramType != nil and paramType.kind == tyVar:
    if n.kind == nkSym and isLocalVar(tracked, n.sym):
      makeVolatile(tracked, n.sym)
  if paramType != nil and paramType.kind == tyProc and tfGcSafe in paramType.flags:
    let argtype = skipTypes(a.typ, abstractInst)
    # XXX figure out why this can be a non tyProc here. See httpclient.nim for an
    # example that triggers it.
    if argtype.kind == tyProc and notGcSafe(argtype) and not tracked.inEnforcedGcSafe:
      localError(tracked.config, n.info, $n & " is not GC safe")
  notNilCheck(tracked, n, paramType)

proc breaksBlock(n: PNode): bool =
  # sematic check doesn't allow statements after raise, break, return or
  # call to noreturn proc, so it is safe to check just the last statements
  var it = n
  while it.kind in {nkStmtList, nkStmtListExpr} and it.len > 0:
    it = it.lastSon

  result = it.kind in {nkBreakStmt, nkReturnStmt, nkRaiseStmt} or
    it.kind in nkCallKinds and it[0].kind == nkSym and sfNoReturn in it[0].sym.flags

proc trackCase(tracked: PEffects, n: PNode) =
  track(tracked, n.sons[0])
  let oldState = tracked.init.len
  let oldFacts = tracked.guards.s.len
  let stringCase = skipTypes(n.sons[0].typ,
        abstractVarRange-{tyTypeDesc}).kind in {tyFloat..tyFloat128, tyString}
  let interesting = not stringCase and interestingCaseExpr(n.sons[0]) and
        warnProveField in tracked.config.notes
  var inter: TIntersection = @[]
  var toCover = 0
  for i in 1..<n.len:
    let branch = n.sons[i]
    setLen(tracked.init, oldState)
    if interesting:
      setLen(tracked.guards.s, oldFacts)
      addCaseBranchFacts(tracked.guards, n, i)
    for i in 0 ..< branch.len:
      track(tracked, branch.sons[i])
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
  track(tracked, n.sons[0].sons[0])
  let oldFacts = tracked.guards.s.len
  addFact(tracked.guards, n.sons[0].sons[0])
  let oldState = tracked.init.len

  var inter: TIntersection = @[]
  var toCover = 0
  track(tracked, n.sons[0].sons[1])
  if not breaksBlock(n.sons[0].sons[1]): inc toCover
  for i in oldState..<tracked.init.len:
    addToIntersection(inter, tracked.init[i])

  for i in 1..<n.len:
    let branch = n.sons[i]
    setLen(tracked.guards.s, oldFacts)
    for j in 0..i-1:
      addFactNeg(tracked.guards, n.sons[j].sons[0])
    if branch.len > 1:
      addFact(tracked.guards, branch.sons[0])
    setLen(tracked.init, oldState)
    for i in 0 ..< branch.len:
      track(tracked, branch.sons[i])
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
      if hasSubnodeWith(n.sons[i], nkBreakStmt):
        # block:
        #   x = def
        #   if ...: ... break # some nested break
        #   y = def
        # --> 'y' not defined after block!
        if oldState < 0: oldState = tracked.init.len
      track(tracked, n.sons[i])
    if oldState > 0: setLen(tracked.init, oldState)
  else:
    track(tracked, n)

proc isTrue*(n: PNode): bool =
  n.kind == nkSym and n.sym.kind == skEnumField and n.sym.position != 0 or
    n.kind == nkIntLit and n.intVal != 0

proc paramType(op: PType, i: int): PType =
  if op != nil and i < op.len: result = op.sons[i]

proc cstringCheck(tracked: PEffects; n: PNode) =
  if n.sons[0].typ.kind == tyCString and (let a = skipConv(n[1]);
      a.typ.kind == tyString and a.kind notin {nkStrLit..nkTripleStrLit}):
    message(tracked.config, n.info, warnUnsafeCode, renderTree(n))

proc track(tracked: PEffects, n: PNode) =
  template gcsafeAndSideeffectCheck() =
    if notGcSafe(op) and not importedFromC(a):
      # and it's not a recursive call:
      if not (a.kind == nkSym and a.sym == tracked.owner):
        if warnGcUnsafe in tracked.config.notes: warnAboutGcUnsafe(n, tracked.config)
        markGcUnsafe(tracked, a)
    if tfNoSideEffect notin op.flags and not importedFromC(a):
      # and it's not a recursive call:
      if not (a.kind == nkSym and a.sym == tracked.owner):
        markSideEffect(tracked, a)

  case n.kind
  of nkSym:
    useVar(tracked, n)
  of nkRaiseStmt:
    if n[0].kind != nkEmpty:
      n.sons[0].info = n.info
      #throws(tracked.exc, n.sons[0])
      addEffect(tracked, n.sons[0], useLineInfo=false)
      for i in 0 ..< safeLen(n):
        track(tracked, n.sons[i])
    else:
      # A `raise` with no arguments means we're going to re-raise the exception
      # being handled or, if outside of an `except` block, a `ReraiseError`.
      # Here we add a `Exception` tag in order to cover both the cases.
      addEffect(tracked, createRaise(tracked.graph, n))
  of nkCallKinds:
    # p's effects are ours too:
    var a = n.sons[0]
    let op = a.typ
    if getConstExpr(tracked.ownerModule, n, tracked.graph) != nil:
      return
    if n.typ != nil:
      if tracked.owner.kind != skMacro and n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        createTypeBoundOps(tracked.c, n.typ, n.info)
    if a.kind == nkCast and a[1].typ.kind == tyProc:
      a = a[1]
    # XXX: in rare situations, templates and macros will reach here after
    # calling getAst(templateOrMacro()). Currently, templates and macros
    # are indistinguishable from normal procs (both have tyProc type) and
    # we can detect them only by checking for attached nkEffectList.
    if op != nil and op.kind == tyProc and op.n.sons[0].kind == nkEffectList:
      if a.kind == nkSym:
        if a.sym == tracked.owner: tracked.isRecursive = true
        # even for recursive calls we need to check the lock levels (!):
        mergeLockLevels(tracked, n, a.sym.getLockLevel)
        if sfSideEffect in a.sym.flags: markSideEffect(tracked, a)
      else:
        mergeLockLevels(tracked, n, op.lockLevel)
      var effectList = op.n.sons[0]
      if a.kind == nkSym and a.sym.kind == skMethod:
        propagateEffects(tracked, n, a.sym)
      elif isNoEffectList(effectList):
        if isForwardedProc(a):
          propagateEffects(tracked, n, a.sym)
        elif isIndirectCall(a, tracked.owner):
          assumeTheWorst(tracked, n, op)
          gcsafeAndSideeffectCheck()
      else:
        mergeEffects(tracked, effectList.sons[exceptionEffects], n)
        mergeTags(tracked, effectList.sons[tagEffects], n)
        gcsafeAndSideeffectCheck()
    if a.kind != nkSym or a.sym.magic != mNBindSym:
      for i in 1 ..< n.len: trackOperand(tracked, n.sons[i], paramType(op, i), a)
    if a.kind == nkSym and a.sym.magic in {mNew, mNewFinalize, mNewSeq}:
      # may not look like an assignment, but it is:
      let arg = n.sons[1]
      initVarViaNew(tracked, arg)
      if arg.typ.len != 0 and {tfNeedsInit} * arg.typ.lastSon.flags != {}:
        if a.sym.magic == mNewSeq and n[2].kind in {nkCharLit..nkUInt64Lit} and
            n[2].intVal == 0:
          # var s: seq[notnil];  newSeq(s, 0)  is a special case!
          discard
        else:
          message(tracked.config, arg.info, warnProveInit, $arg)
    for i in 0 ..< safeLen(n):
      track(tracked, n.sons[i])
  of nkDotExpr:
    guardDotAccess(tracked, n)
    for i in 0 ..< n.len: track(tracked, n.sons[i])
  of nkCheckedFieldExpr:
    track(tracked, n.sons[0])
    if warnProveField in tracked.config.notes:
      checkFieldAccess(tracked.guards, n, tracked.config)
  of nkTryStmt: trackTryStmt(tracked, n)
  of nkPragma: trackPragmaStmt(tracked, n)
  of nkAsgn, nkFastAsgn:
    track(tracked, n.sons[1])
    initVar(tracked, n.sons[0], volatileCheck=true)
    invalidateFacts(tracked.guards, n.sons[0])
    track(tracked, n.sons[0])
    addAsgnFact(tracked.guards, n.sons[0], n.sons[1])
    notNilCheck(tracked, n.sons[1], n.sons[0].typ)
    when false: cstringCheck(tracked, n)
    if tracked.owner.kind != skMacro:
      createTypeBoundOps(tracked.c, n[0].typ, n.info)
  of nkVarSection, nkLetSection:
    for child in n:
      let last = lastSon(child)
      if last.kind != nkEmpty: track(tracked, last)
      if tracked.owner.kind != skMacro:
        if child.kind == nkVarTuple:
          createTypeBoundOps(tracked.c, child[^1].typ, child.info)
          for i in 0..child.len-3:
            createTypeBoundOps(tracked.c, child[i].typ, child.info)
        else:
          createTypeBoundOps(tracked.c, child[0].typ, child.info)
      if child.kind == nkIdentDefs and last.kind != nkEmpty:
        for i in 0 .. child.len-3:
          initVar(tracked, child.sons[i], volatileCheck=false)
          addAsgnFact(tracked.guards, child.sons[i], last)
          notNilCheck(tracked, last, child.sons[i].typ)
      elif child.kind == nkVarTuple and last.kind != nkEmpty:
        for i in 0 .. child.len-2:
          if child[i].kind == nkEmpty or
            child[i].kind == nkSym and child[i].sym.name.s == "_":
            continue
          initVar(tracked, child[i], volatileCheck=false)
          if last.kind in {nkPar, nkTupleConstr}:
            addAsgnFact(tracked.guards, child[i], last[i])
            notNilCheck(tracked, last[i], child[i].typ)
      # since 'var (a, b): T = ()' is not even allowed, there is always type
      # inference for (a, b) and thus no nil checking is necessary.
  of nkConstSection:
    for child in n:
      let last = lastSon(child)
      track(tracked, last)
  of nkCaseStmt: trackCase(tracked, n)
  of nkWhen, nkIfStmt, nkIfExpr: trackIf(tracked, n)
  of nkBlockStmt, nkBlockExpr: trackBlock(tracked, n.sons[1])
  of nkWhileStmt:
    track(tracked, n.sons[0])
    # 'while true' loop?
    if isTrue(n.sons[0]):
      trackBlock(tracked, n.sons[1])
    else:
      # loop may never execute:
      let oldState = tracked.init.len
      let oldFacts = tracked.guards.s.len
      addFact(tracked.guards, n.sons[0])
      track(tracked, n.sons[1])
      setLen(tracked.init, oldState)
      setLen(tracked.guards.s, oldFacts)
  of nkForStmt, nkParForStmt:
    # we are very conservative here and assume the loop is never executed:
    let oldState = tracked.init.len
    for i in 0 .. n.len-3:
      let it = n[i]
      track(tracked, it)
      if tracked.owner.kind != skMacro:
        if it.kind == nkVarTuple:
          for x in it:
            createTypeBoundOps(tracked.c, x.typ, x.info)
        else:
          createTypeBoundOps(tracked.c, it.typ, it.info)
    let iterCall = n[n.len-2]
    let loopBody = n[n.len-1]
    if tracked.owner.kind != skMacro and iterCall.safelen > 1:
      # XXX this is a bit hacky:
      if iterCall[1].typ != nil and iterCall[1].typ.skipTypes(abstractVar).kind notin {tyVarargs, tyOpenArray}:
        createTypeBoundOps(tracked.c, iterCall[1].typ, iterCall[1].info)
    track(tracked, iterCall)
    track(tracked, loopBody)
    setLen(tracked.init, oldState)
  of nkObjConstr:
    when false: track(tracked, n.sons[0])
    let oldFacts = tracked.guards.s.len
    for i in 1 ..< n.len:
      let x = n.sons[i]
      track(tracked, x)
      if x.sons[0].kind == nkSym and sfDiscriminant in x.sons[0].sym.flags:
        addDiscriminantFact(tracked.guards, x)
    setLen(tracked.guards.s, oldFacts)
  of nkPragmaBlock:
    let pragmaList = n.sons[0]
    let oldLocked = tracked.locked.len
    let oldLockLevel = tracked.currLockLevel
    var enforcedGcSafety = false
    var enforceNoSideEffects = false
    for i in 0 ..< pragmaList.len:
      let pragma = whichPragma(pragmaList.sons[i])
      if pragma == wLocks:
        lockLocations(tracked, pragmaList.sons[i])
      elif pragma == wGcSafe:
        enforcedGcSafety = true
      elif pragma == wNosideeffect:
        enforceNoSideEffects = true
    if enforcedGcSafety: tracked.inEnforcedGcSafe = true
    if enforceNoSideEffects: tracked.inEnforcedNoSideEffects = true
    track(tracked, n.lastSon)
    if enforcedGcSafety: tracked.inEnforcedGcSafe = false
    if enforceNoSideEffects: tracked.inEnforcedNoSideEffects = false
    setLen(tracked.locked, oldLocked)
    tracked.currLockLevel = oldLockLevel
  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    discard
  of nkCast, nkHiddenStdConv, nkHiddenSubConv, nkConv:
    if n.len == 2: track(tracked, n.sons[1])
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    if n.len == 1: track(tracked, n.sons[0])
  else:
    for i in 0 ..< safeLen(n): track(tracked, n.sons[i])

proc subtypeRelation(g: ModuleGraph; spec, real: PNode): bool =
  result = safeInheritanceDiff(g.excType(real), spec.typ) <= 0

proc checkRaisesSpec(g: ModuleGraph; spec, real: PNode, msg: string, hints: bool;
                     effectPredicate: proc (g: ModuleGraph; a, b: PNode): bool {.nimcall.}) =
  # check that any real exception is listed in 'spec'; mark those as used;
  # report any unused exception
  var used = initIntSet()
  for r in items(real):
    block search:
      for s in 0 ..< spec.len:
        if effectPredicate(g, spec[s], r):
          used.incl(s)
          break search
      # XXX call graph analysis would be nice here!
      pushInfoContext(g.config, spec.info)
      localError(g.config, r.info, errGenerated, msg & typeToString(r.typ))
      popInfoContext(g.config)
  # hint about unnecessarily listed exception types:
  if hints:
    for s in 0 ..< spec.len:
      if not used.contains(s):
        message(g.config, spec[s].info, hintXDeclaredButNotUsed, renderTree(spec[s]))

proc checkMethodEffects*(g: ModuleGraph; disp, branch: PSym) =
  ## checks for consistent effects for multi methods.
  let actual = branch.typ.n.sons[0]
  if actual.len != effectListLen: return

  let p = disp.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(g, raisesSpec, actual.sons[exceptionEffects],
      "can raise an unlisted exception: ", hints=off, subtypeRelation)
  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(g, tagsSpec, actual.sons[tagEffects],
      "can have an unlisted effect: ", hints=off, subtypeRelation)
  if sfThread in disp.flags and notGcSafe(branch.typ):
    localError(g.config, branch.info, "base method is GC-safe, but '$1' is not" %
                                branch.name.s)
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
    effects[pragmasEffects] = n

proc initEffects(g: ModuleGraph; effects: PNode; s: PSym; t: var TEffects; c: PContext) =
  newSeq(effects.sons, effectListLen)
  effects.sons[exceptionEffects] = newNodeI(nkArgList, s.info)
  effects.sons[tagEffects] = newNodeI(nkArgList, s.info)
  effects.sons[usesEffects] = g.emptyNode
  effects.sons[writeEffects] = g.emptyNode
  effects.sons[pragmasEffects] = g.emptyNode

  t.exc = effects.sons[exceptionEffects]
  t.tags = effects.sons[tagEffects]
  t.owner = s
  t.ownerModule = s.getModule
  t.init = @[]
  t.guards.s = @[]
  t.guards.o = initOperators(g)
  t.locked = @[]
  t.graph = g
  t.config = g.config
  t.c = c

proc trackProc*(c: PContext; s: PSym, body: PNode) =
  let g = c.graph
  var effects = s.typ.n.sons[0]
  if effects.kind != nkEffectList: return
  # effects already computed?
  if sfForward in s.flags: return
  if effects.len == effectListLen: return

  var t: TEffects
  initEffects(g, effects, s, t, c)
  track(t, body)
  if not isEmptyType(s.typ.sons[0]) and
      ({tfNeedsInit, tfNotNil} * s.typ.sons[0].flags != {} or
      s.typ.sons[0].skipTypes(abstractInst).kind == tyVar) and
      s.kind in {skProc, skFunc, skConverter, skMethod}:
    var res = s.ast.sons[resultPos].sym # get result symbol
    if res.id notin t.init:
      message(g.config, body.info, warnProveInit, "result")
  let p = s.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(g, raisesSpec, t.exc, "can raise an unlisted exception: ",
                    hints=on, subtypeRelation)
    # after the check, use the formal spec:
    effects.sons[exceptionEffects] = raisesSpec

  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(g, tagsSpec, t.tags, "can have an unlisted effect: ",
                    hints=off, subtypeRelation)
    # after the check, use the formal spec:
    effects.sons[tagEffects] = tagsSpec

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
      localError(g.config, s.info, "'$1' can have side effects" % s.name.s)
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
  when defined(useDfa):
    if s.name.s == "testp":
      dataflowAnalysis(s, body)
      when false: trackWrites(s, body)

proc trackTopLevelStmt*(c: PContext; module: PSym; n: PNode) =
  if n.kind in {nkPragma, nkMacroDef, nkTemplateDef, nkProcDef, nkFuncDef,
                nkTypeSection, nkConverterDef, nkMethodDef, nkIteratorDef}:
    return
  let g = c.graph
  var effects = newNode(nkEffectList, n.info)
  var t: TEffects
  initEffects(g, effects, module, t, c)
  t.isToplevel = true
  track(t, n)
