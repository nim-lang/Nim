#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees, 
  wordrecg, strutils, options, guards

# Second semantic checking pass over the AST. Necessary because the old
# way had some inherent problems. Performs:
# 
# * effect+exception tracking
# * "usage before definition" checking
# * checks for invalid usages of compiletime magics (not implemented)
# * checks for invalid usages of PNimNode (not implemented)
# * later: will do an escape analysis for closures at least

# Predefined effects:
#   io, time (time dependent), gc (performs GC'ed allocation), exceptions,
#   side effect (accesses global), store (stores into *type*),
#   store_unkown (performs some store) --> store(any)|store(x) 
#   load (loads from *type*), recursive (recursive call), unsafe,
#   endless (has endless loops), --> user effects are defined over *patterns*
#   --> a TR macro can annotate the proc with user defined annotations
#   --> the effect system can access these

# Load&Store analysis is performed on *paths*. A path is an access like
# obj.x.y[i].z; splitting paths up causes some problems:
# 
# var x = obj.x
# var z = x.y[i].z
#
# Alias analysis is affected by this too! A good solution is *type splitting*:
# T becomes T1 and T2 if it's known that T1 and T2 can't alias. 
# 
# An aliasing problem and a race condition are effectively the same problem.
# Type based alias analysis is nice but not sufficient; especially splitting
# an array and filling it in parallel should be supported but is not easily
# done: It essentially requires a built-in 'indexSplit' operation and dependent
# typing.
  
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
"""

const trackGlobals = false ## we don't need it for now

type
  TEffects = object
    exc: PNode  # stack of exceptions
    tags: PNode # list of tags
    uses: PNode # list of used global variables
    bottom: int
    owner: PSym
    init: seq[int] # list of initialized variables
    guards: TModel # nested guards
    locked: seq[PNode] # locked locations
    gcUnsafe, isRecursive: bool
  PEffects = var TEffects

proc isLocalVar(a: PEffects, s: PSym): bool =
  s.kind in {skVar, skResult} and sfGlobal notin s.flags and s.owner == a.owner

proc initVar(a: PEffects, n: PNode) =
  if n.kind != nkSym: return
  let s = n.sym
  if isLocalVar(a, s):
    for x in a.init:
      if x == s.id: return
    a.init.add s.id

proc initVarViaNew(a: PEffects, n: PNode) =
  if n.kind != nkSym: return
  let s = n.sym
  if {tfNeedsInit, tfNotNil} * s.typ.flags <= {tfNotNil}:
    # 'x' is not nil, but that doesn't mean its "not nil" children
    # are initialized:
    initVar(a, n)

when trackGlobals: 
  proc addUse(a: PEffects, e: PNode) =
    var aa = a.uses
    for i in 0 .. <aa.len:
      if aa[i].sym.id == e.sym.id: return
    a.uses.add(e)

proc useVar(a: PEffects, n: PNode) =
  let s = n.sym
  if isLocalVar(a, s):
    if s.id notin a.init:
      if {tfNeedsInit, tfNotNil} * s.typ.flags != {}:
        message(n.info, warnProveInit, s.name.s)
      else:
        message(n.info, warnUninit, s.name.s)
      # prevent superfluous warnings about the same variable:
      a.init.add s.id
  if {sfGlobal, sfThread} * s.flags == {sfGlobal} and s.kind == skVar:
    when trackGlobals:
      a.addUse(copyNode(n))
    if (tfHasGCedMem in s.typ.flags or s.typ.isGCedMem) and 
        tfGcSafe notin s.typ.flags:
      message(n.info, warnGcUnsafe, renderTree(n))
      a.gcUnsafe = true

type
  TIntersection = seq[tuple[id, count: int]] # a simple count table

proc addToIntersection(inter: var TIntersection, s: int) =
  for j in 0.. <inter.len:
    if s == inter[j].id:
      inc inter[j].count
      return
  inter.add((id: s, count: 1))

proc throws(tracked, n: PNode) =
  if n.typ == nil or n.typ.kind != tyError: tracked.add n
  
proc excType(n: PNode): PType =
  # reraise is like raising E_Base:
  let t = if n.kind == nkEmpty: sysTypeFromName"E_Base" else: n.typ
  result = skipTypes(t, skipPtrs)

proc createRaise(n: PNode): PNode =
  result = newNode(nkType)
  result.typ = sysTypeFromName"E_Base"
  if not n.isNil: result.info = n.info

proc createTag(n: PNode): PNode =
  result = newNode(nkType)
  result.typ = sysTypeFromName"TEffect"
  if not n.isNil: result.info = n.info

proc createAnyGlobal(n: PNode): PNode =
  result = newSymNode(anyGlobal)
  result.info = n.info

proc addEffect(a: PEffects, e: PNode, useLineInfo=true) =
  assert e.kind != nkRaiseStmt
  var aa = a.exc
  for i in a.bottom .. <aa.len:
    if sameType(aa[i].excType, e.excType):
      if not useLineInfo or gCmd == cmdDoc: return
      elif aa[i].info == e.info: return
  throws(a.exc, e)

proc addTag(a: PEffects, e: PNode, useLineInfo=true) =
  var aa = a.tags
  for i in 0 .. <aa.len:
    if sameType(aa[i].typ.skipTypes(skipPtrs), e.typ.skipTypes(skipPtrs)):
      if not useLineInfo or gCmd == cmdDoc: return
      elif aa[i].info == e.info: return
  throws(a.tags, e)

proc mergeEffects(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addEffect(a, createRaise(comesFrom))
  else:
    for effect in items(b): addEffect(a, effect, useLineInfo=comesFrom != nil)

proc mergeTags(a: PEffects, b, comesFrom: PNode) =
  if b.isNil:
    addTag(a, createTag(comesFrom))
  else:
    for effect in items(b): addTag(a, effect, useLineInfo=comesFrom != nil)

when trackGlobals:
  proc mergeUses(a: PEffects, b, comesFrom: PNode) =
    if b.isNil:
      addUse(a, createAnyGlobal(comesFrom))
    else:
      for effect in items(b): addUse(a, effect)

proc listEffects(a: PEffects) =
  for e in items(a.exc):  message(e.info, hintUser, typeToString(e.typ))
  for e in items(a.tags): message(e.info, hintUser, typeToString(e.typ))
  for e in items(a.uses): message(e.info, hintUser, e.sym.name.s)

proc catches(tracked: PEffects, e: PType) =
  let e = skipTypes(e, skipPtrs)
  var L = tracked.exc.len
  var i = tracked.bottom
  while i < L:
    # r supertype of e?
    if safeInheritanceDiff(tracked.exc[i].excType, e) <= 0:
      tracked.exc.sons[i] = tracked.exc.sons[L-1]
      dec L
    else:
      inc i
  if not isNil(tracked.exc.sons):
    setLen(tracked.exc.sons, L)
  else:
    assert L == 0

proc catchesAll(tracked: PEffects) =
  if not isNil(tracked.exc.sons):
    setLen(tracked.exc.sons, tracked.bottom)

proc track(tracked: PEffects, n: PNode)
proc trackTryStmt(tracked: PEffects, n: PNode) =
  let oldBottom = tracked.bottom
  tracked.bottom = tracked.exc.len

  let oldState = tracked.init.len
  var inter: TIntersection = @[]

  track(tracked, n.sons[0])  
  for i in oldState.. <tracked.init.len:
    addToIntersection(inter, tracked.init[i])
  
  var branches = 1
  var hasFinally = false
  for i in 1 .. < n.len:
    let b = n.sons[i]
    let blen = sonsLen(b)
    if b.kind == nkExceptBranch:
      inc branches
      if blen == 1:
        catchesAll(tracked)
      else:
        for j in countup(0, blen - 2):
          assert(b.sons[j].kind == nkType)
          catches(tracked, b.sons[j].typ)

      setLen(tracked.init, oldState)
      track(tracked, b.sons[blen-1])
      for i in oldState.. <tracked.init.len:
        addToIntersection(inter, tracked.init[i])
    else:
      assert b.kind == nkFinally
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
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if whichPragma(it) == wEffects:
      # list the computed effects up to here:
      listEffects(tracked)
      
proc effectSpec(n: PNode, effectType = wRaises): PNode =
  for i in countup(0, sonsLen(n) - 1):
    var it = n.sons[i]
    if it.kind == nkExprColonExpr and whichPragma(it) == effectType:
      result = it.sons[1]
      if result.kind notin {nkCurly, nkBracket}:
        result = newNodeI(nkCurly, result.info)
        result.add(it.sons[1])
      return

proc documentEffect(n, x: PNode, effectType: TSpecialWord, idx: int) =
  var x = x
  let spec = effectSpec(x, effectType)
  if isNil(spec):
    let s = n.sons[namePos].sym
    
    let actual = s.typ.n.sons[0]
    if actual.len != effectListLen: return
    let real = actual.sons[idx]
    
    # warning: hack ahead: 
    var effects = newNodeI(nkBracket, n.info, real.len)
    for i in 0 .. <real.len:
      var t = typeToString(real[i].typ)
      if t.startsWith("ref "): t = substr(t, 4)
      effects.sons[i] = newIdentNode(getIdent(t), n.info)
      # set the type so that the following analysis doesn't screw up:
      effects.sons[i].typ = real[i].typ

    var pair = newNode(nkExprColonExpr, n.info, @[
      newIdentNode(getIdent(specialWords[effectType]), n.info), effects])
    
    if x.kind == nkEmpty:
      x = newNodeI(nkPragma, n.info)
      n.sons[pragmasPos] = x
    x.add(pair)

proc documentRaises*(n: PNode) =
  if n.sons[namePos].kind != nkSym: return
  documentEffect(n, n.sons[pragmasPos], wRaises, exceptionEffects)
  documentEffect(n, n.sons[pragmasPos], wTags, tagEffects)
  documentEffect(n, n.sons[pragmasPos], wUses, usesEffects)

template notGcSafe(t): expr = {tfGcSafe, tfNoSideEffect} * t.flags == {}

proc importedFromC(n: PNode): bool =
  # when imported from C, we assume GC-safety.
  result = n.kind == nkSym and sfImportc in n.sym.flags

proc propagateEffects(tracked: PEffects, n: PNode, s: PSym) =
  let pragma = s.ast.sons[pragmasPos]
  let spec = effectSpec(pragma, wRaises)
  mergeEffects(tracked, spec, n)
  
  let tagSpec = effectSpec(pragma, wTags)
  mergeTags(tracked, tagSpec, n)

  if notGcSafe(s.typ) and sfImportc notin s.flags:
    message(n.info, warnGcUnsafe, renderTree(n))
    tracked.gcUnsafe = true

  when trackGlobals:
    let usesSpec = effectSpec(pragma, wUses)
    mergeUses(tracked, usesSpec, n)

proc notNilCheck(tracked: PEffects, n: PNode, paramType: PType) =
  let n = n.skipConv
  if paramType != nil and tfNotNil in paramType.flags and 
      n.typ != nil and tfNotNil notin n.typ.flags:
    if n.kind == nkAddr:
      # addr(x[]) can't be proven, but addr(x) can:
      if not containsNode(n, {nkDerefExpr, nkHiddenDeref}): return
    elif n.kind == nkSym and n.sym.kind in routineKinds:
      # 'p' is not nil obviously:
      return
    case impliesNotNil(tracked.guards, n)
    of impUnknown:
      message(n.info, errGenerated, 
              "cannot prove '$1' is not nil" % n.renderTree)
    of impNo:
      message(n.info, errGenerated, "'$1' is provably nil" % n.renderTree)
    of impYes: discard

proc trackOperand(tracked: PEffects, n: PNode, paramType: PType) =
  let op = n.typ
  if op != nil and op.kind == tyProc and n.kind != nkNilLit:
    internalAssert op.n.sons[0].kind == nkEffectList
    var effectList = op.n.sons[0]
    let s = n.skipConv
    if s.kind == nkSym and s.sym.kind in routineKinds:
      propagateEffects(tracked, n, s.sym)
    elif effectList.len == 0:
      if isForwardedProc(n):
        propagateEffects(tracked, n, n.sym)
      else:
        addEffect(tracked, createRaise(n))
        addTag(tracked, createTag(n))
        when trackGlobals: addUse(tracked, createAnyGlobal(n))
      # assume GcUnsafe unless in its type:
      if notGcSafe(op): 
        message(n.info, warnGcUnsafe, renderTree(n))
        tracked.gcUnsafe = true
    else:
      mergeEffects(tracked, effectList.sons[exceptionEffects], n)
      mergeTags(tracked, effectList.sons[tagEffects], n)
      when trackGlobals: mergeUses(tracked, effectList.sons[usesEffects], n)
      if notGcSafe(op):
        message(n.info, warnGcUnsafe, renderTree(n))
        tracked.gcUnsafe = true
  notNilCheck(tracked, n, paramType)

proc breaksBlock(n: PNode): bool =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for c in n: 
      if breaksBlock(c): return true
  of nkBreakStmt, nkReturnStmt, nkRaiseStmt:
    return true
  of nkCallKinds:
    if n.sons[0].kind == nkSym and sfNoReturn in n.sons[0].sym.flags:
      return true
  else:
    discard

proc trackCase(tracked: PEffects, n: PNode) =
  track(tracked, n.sons[0])
  let oldState = tracked.init.len
  let oldFacts = tracked.guards.len
  let interesting = interestingCaseExpr(n.sons[0]) and warnProveField in gNotes
  var inter: TIntersection = @[]
  var toCover = 0
  for i in 1.. <n.len:
    let branch = n.sons[i]
    setLen(tracked.init, oldState)
    if interesting:
      setLen(tracked.guards, oldFacts)
      addCaseBranchFacts(tracked.guards, n, i)
    for i in 0 .. <branch.len:
      track(tracked, branch.sons[i])
    if not breaksBlock(branch.lastSon): inc toCover
    for i in oldState.. <tracked.init.len:
      addToIntersection(inter, tracked.init[i])
    
  let exh = case skipTypes(n.sons[0].typ, abstractVarRange-{tyTypeDesc}).kind
            of tyFloat..tyFloat128, tyString:
              lastSon(n).kind == nkElse
            else:
              true
  setLen(tracked.init, oldState)
  if exh:
    for id, count in items(inter):
      if count >= toCover: tracked.init.add id
    # else we can't merge
  setLen(tracked.guards, oldFacts)

proc trackIf(tracked: PEffects, n: PNode) =
  track(tracked, n.sons[0].sons[0])
  let oldFacts = tracked.guards.len
  addFact(tracked.guards, n.sons[0].sons[0])
  let oldState = tracked.init.len

  var inter: TIntersection = @[]
  var toCover = 0
  track(tracked, n.sons[0].sons[1])
  if not breaksBlock(n.sons[0].sons[1]): inc toCover
  for i in oldState.. <tracked.init.len:
    addToIntersection(inter, tracked.init[i])

  for i in 1.. <n.len:
    let branch = n.sons[i]
    setLen(tracked.guards, oldFacts)
    for j in 0..i-1:
      addFactNeg(tracked.guards, n.sons[j].sons[0])
    if branch.len > 1:
      addFact(tracked.guards, branch.sons[0])
    setLen(tracked.init, oldState)
    for i in 0 .. <branch.len:
      track(tracked, branch.sons[i])
    if not breaksBlock(branch.lastSon): inc toCover
    for i in oldState.. <tracked.init.len:
      addToIntersection(inter, tracked.init[i])
  setLen(tracked.init, oldState)
  if lastSon(n).len == 1:
    for id, count in items(inter):
      if count >= toCover: tracked.init.add id
    # else we can't merge as it is not exhaustive
  setLen(tracked.guards, oldFacts)
  
proc trackBlock(tracked: PEffects, n: PNode) =
  if n.kind in {nkStmtList, nkStmtListExpr}:
    var oldState = -1
    for i in 0.. <n.len:
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
    message(n.info, warnUnsafeCode, renderTree(n))

proc track(tracked: PEffects, n: PNode) =
  case n.kind
  of nkSym:
    useVar(tracked, n)
  of nkRaiseStmt:
    n.sons[0].info = n.info
    throws(tracked.exc, n.sons[0])
    for i in 0 .. <safeLen(n):
      track(tracked, n.sons[i])
  of nkCallKinds:
    # p's effects are ours too:
    let a = n.sons[0]
    let op = a.typ
    # XXX: in rare situations, templates and macros will reach here after
    # calling getAst(templateOrMacro()). Currently, templates and macros
    # are indistinguishable from normal procs (both have tyProc type) and
    # we can detect them only by checking for attached nkEffectList.
    if op != nil and op.kind == tyProc and op.n.sons[0].kind == nkEffectList:
      if a.kind == nkSym and a.sym == tracked.owner:
        tracked.isRecursive = true
      elif notGcSafe(op) and not importedFromC(a):
        message(n.info, warnGcUnsafe, renderTree(n))
        tracked.gcUnsafe = true
      var effectList = op.n.sons[0]
      if a.kind == nkSym and a.sym.kind == skMethod:
        propagateEffects(tracked, n, a.sym)
      elif effectList.len == 0:
        if isForwardedProc(a):
          propagateEffects(tracked, n, a.sym)
        elif isIndirectCall(a, tracked.owner):
          addEffect(tracked, createRaise(n))
          addTag(tracked, createTag(n))
          when trackGlobals: addUse(tracked, createAnyGlobal(n))
          # XXX handle 'gcsafe' properly for callbacks!
      else:
        mergeEffects(tracked, effectList.sons[exceptionEffects], n)
        mergeTags(tracked, effectList.sons[tagEffects], n)
        when trackGlobals: mergeUses(tracked, effectList.sons[usesEffects], n)
    for i in 1 .. <len(n): trackOperand(tracked, n.sons[i], paramType(op, i))
    if a.kind == nkSym and a.sym.magic in {mNew, mNewFinalize, mNewSeq}:
      # may not look like an assignment, but it is:
      initVarViaNew(tracked, n.sons[1])
    for i in 0 .. <safeLen(n):
      track(tracked, n.sons[i])
  of nkCheckedFieldExpr:
    track(tracked, n.sons[0])
    if warnProveField in gNotes: checkFieldAccess(tracked.guards, n)
  of nkTryStmt: trackTryStmt(tracked, n)
  of nkPragma: trackPragmaStmt(tracked, n)
  of nkAsgn, nkFastAsgn:
    track(tracked, n.sons[1])
    initVar(tracked, n.sons[0])
    invalidateFacts(tracked.guards, n.sons[0])
    track(tracked, n.sons[0])
    addAsgnFact(tracked.guards, n.sons[0], n.sons[1])
    notNilCheck(tracked, n.sons[1], n.sons[0].typ)
    when false: cstringCheck(tracked, n)
  of nkVarSection:
    for child in n:
      let last = lastSon(child)
      if child.kind == nkIdentDefs and last.kind != nkEmpty:
        track(tracked, last)
        for i in 0 .. child.len-3:
          initVar(tracked, child.sons[i])
          addAsgnFact(tracked.guards, child.sons[i], last)
          notNilCheck(tracked, last, child.sons[i].typ)
      # since 'var (a, b): T = ()' is not even allowed, there is always type
      # inference for (a, b) and thus no nil checking is necessary.
  of nkCaseStmt: trackCase(tracked, n)
  of nkIfStmt, nkIfExpr: trackIf(tracked, n)
  of nkBlockStmt, nkBlockExpr: trackBlock(tracked, n.sons[1])
  of nkWhileStmt:
    track(tracked, n.sons[0])
    # 'while true' loop?
    if isTrue(n.sons[0]):
      trackBlock(tracked, n.sons[1])
    else:
      # loop may never execute:
      let oldState = tracked.init.len
      let oldFacts = tracked.guards.len
      addFact(tracked.guards, n.sons[0])
      track(tracked, n.sons[1])
      setLen(tracked.init, oldState)
      setLen(tracked.guards, oldFacts)
  of nkForStmt, nkParForStmt:
    # we are very conservative here and assume the loop is never executed:
    let oldState = tracked.init.len
    for i in 0 .. <len(n):
      track(tracked, n.sons[i])
    setLen(tracked.init, oldState)
  of nkObjConstr:
    track(tracked, n.sons[0])
    let oldFacts = tracked.guards.len
    for i in 1 .. <len(n):
      let x = n.sons[i]
      track(tracked, x)
      if sfDiscriminant in x.sons[0].sym.flags:
        addDiscriminantFact(tracked.guards, x)
    setLen(tracked.guards, oldFacts)
  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef:
    discard
  else:
    for i in 0 .. <safeLen(n): track(tracked, n.sons[i])

proc subtypeRelation(spec, real: PNode): bool =
  result = safeInheritanceDiff(real.excType, spec.typ) <= 0

proc symbolPredicate(spec, real: PNode): bool =
  result = real.sym.id == spec.sym.id

proc checkRaisesSpec(spec, real: PNode, msg: string, hints: bool;
                     effectPredicate: proc (a, b: PNode): bool {.nimcall.}) =
  # check that any real exception is listed in 'spec'; mark those as used;
  # report any unused exception
  var used = initIntSet()
  for r in items(real):
    block search:
      for s in 0 .. <spec.len:
        if effectPredicate(spec[s], r):
          used.incl(s)
          break search
      # XXX call graph analysis would be nice here!
      pushInfoContext(spec.info)
      localError(r.info, errGenerated, msg & typeToString(r.typ))
      popInfoContext()
  # hint about unnecessarily listed exception types:
  if hints:
    for s in 0 .. <spec.len:
      if not used.contains(s):
        message(spec[s].info, hintXDeclaredButNotUsed, renderTree(spec[s]))

proc checkMethodEffects*(disp, branch: PSym) =
  ## checks for consistent effects for multi methods.
  let actual = branch.typ.n.sons[0]
  if actual.len != effectListLen: return

  let p = disp.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(raisesSpec, actual.sons[exceptionEffects],
      "can raise an unlisted exception: ", hints=off, subtypeRelation)
  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(tagsSpec, actual.sons[tagEffects],
      "can have an unlisted effect: ", hints=off, subtypeRelation)
  let usesSpec = effectSpec(p, wUses)
  if not isNil(usesSpec):
    checkRaisesSpec(usesSpec, actual.sons[usesEffects],
      "may use an unlisted global variable: ", hints=off, symbolPredicate)
  if sfThread in disp.flags and notGcSafe(branch.typ):
    localError(branch.info, "base method is GC-safe, but '$1' is not" % 
                                branch.name.s)

proc setEffectsForProcType*(t: PType, n: PNode) =
  var effects = t.n.sons[0]
  internalAssert t.kind == tyProc and effects.kind == nkEffectList

  let
    raisesSpec = effectSpec(n, wRaises)
    tagsSpec = effectSpec(n, wTags)
    usesSpec = effectSpec(n, wUses)
  if not isNil(raisesSpec) or not isNil(tagsSpec) or not isNil(usesSpec):
    internalAssert effects.len == 0
    newSeq(effects.sons, effectListLen)
    if not isNil(raisesSpec):
      effects.sons[exceptionEffects] = raisesSpec
    if not isNil(tagsSpec):
      effects.sons[tagEffects] = tagsSpec
    if not isNil(usesSpec):
      effects.sons[usesEffects] = usesSpec

proc initEffects(effects: PNode; s: PSym; t: var TEffects) =
  newSeq(effects.sons, effectListLen)
  effects.sons[exceptionEffects] = newNodeI(nkArgList, s.info)
  effects.sons[tagEffects] = newNodeI(nkArgList, s.info)
  effects.sons[usesEffects] = newNodeI(nkArgList, s.info)
  
  t.exc = effects.sons[exceptionEffects]
  t.tags = effects.sons[tagEffects]
  t.uses = effects.sons[usesEffects]
  t.owner = s
  t.init = @[]
  t.guards = @[]
  
proc trackProc*(s: PSym, body: PNode) =
  var effects = s.typ.n.sons[0]
  internalAssert effects.kind == nkEffectList
  # effects already computed?
  if sfForward in s.flags: return
  if effects.len == effectListLen: return
  
  var t: TEffects
  initEffects(effects, s, t)
  track(t, body)
  if not isEmptyType(s.typ.sons[0]) and tfNeedsInit in s.typ.sons[0].flags and
      s.kind in {skProc, skConverter, skMethod}:
    var res = s.ast.sons[resultPos].sym # get result symbol
    if res.id notin t.init:
      message(body.info, warnProveInit, "result")
  let p = s.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(raisesSpec, t.exc, "can raise an unlisted exception: ",
                    hints=on, subtypeRelation)
    # after the check, use the formal spec:
    effects.sons[exceptionEffects] = raisesSpec

  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(tagsSpec, t.tags, "can have an unlisted effect: ",
                    hints=off, subtypeRelation)
    # after the check, use the formal spec:
    effects.sons[tagEffects] = tagsSpec

  when trackGlobals:
    let usesSpec = effectSpec(p, wUses)
    if not isNil(usesSpec):
      checkRaisesSpec(usesSpec, t.uses,
        "uses an unlisted global variable: ", hints=on, symbolPredicate)
      effects.sons[usesEffects] = usesSpec
  if optThreadAnalysis in gGlobalOptions:
    if sfThread in s.flags and t.gcUnsafe:
      localError(s.info, warnGcUnsafe2, s.name.s)
      #localError(s.info, "'$1' is not GC-safe" % s.name.s)
    if not t.gcUnsafe: s.typ.flags.incl tfGcSafe

proc trackTopLevelStmt*(module: PSym; n: PNode) =
  if n.kind in {nkPragma, nkMacroDef, nkTemplateDef, nkProcDef,
                nkTypeSection, nkConverterDef, nkMethodDef, nkIteratorDef}:
    return
  var effects = newNode(nkEffectList, n.info)
  var t: TEffects
  initEffects(effects, module, t)

  track(t, n)
