#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees, 
  wordrecg, strutils, options

# Second semantic checking pass over the AST. Necessary because the old
# way had some inherent problems. Performs:
# 
# * effect+exception tracking
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

when false:
  proc sem2call(c: PContext, n: PNode): PNode =
    assert n.kind in nkCallKinds
    
  proc sem2sym(c: PContext, n: PNode): PNode =
    assert n.kind == nkSym
  
  
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
 
 
  Effect tracking:
  
  We track the effects per proc; forward declarations and indirect calls cause
  problems: Forward declarations are computed lazily (we do this pass after
  a whole module) and indirect calls are assumed the worst, unless they have
  an effect annotation.
"""

type
  TEffects = object
    exc: PNode  # stack of exceptions
    tags: PNode # list of tags
    bottom: int
  
  PEffects = var TEffects

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

proc listEffects(a: PEffects) =
  for e in items(a.exc):  Message(e.info, hintUser, typeToString(e.typ))
  for e in items(a.tags): Message(e.info, hintUser, typeToString(e.typ))

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
  track(tracked, n.sons[0])
  for i in 1 .. < n.len:
    let b = n.sons[i]
    let blen = sonsLen(b)
    if b.kind == nkExceptBranch:
      if blen == 1:
        catchesAll(tracked)
      else:
        for j in countup(0, blen - 2):
          assert(b.sons[j].kind == nkType)
          catches(tracked, b.sons[j].typ)
    else:
      assert b.kind == nkFinally
    track(tracked, b.sons[blen-1])
  tracked.bottom = oldBottom

proc isIndirectCall(n: PNode): bool =
  # we don't count f(...) as an indirect call if 'f' is an parameter.
  # Instead we track expressions of type tyProc too. See the manual for
  # details:
  result = n.kind != nkSym or n.sym.kind notin (routineKinds+{skParam})

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

proc propagateEffects(tracked: PEffects, n: PNode, s: PSym) =
  let pragma = s.ast.sons[pragmasPos]
  let spec = effectSpec(pragma, wRaises)
  mergeEffects(tracked, spec, n)
  
  let tagSpec = effectSpec(pragma, wTags)
  mergeTags(tracked, tagSpec, n)

proc trackOperand(tracked: PEffects, n: PNode) =
  let op = n.typ
  if op != nil and op.kind == tyProc and n.kind != nkNilLit:
    InternalAssert op.n.sons[0].kind == nkEffectList
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
    else:
      mergeEffects(tracked, effectList.sons[exceptionEffects], n)
      mergeTags(tracked, effectList.sons[tagEffects], n)

proc track(tracked: PEffects, n: PNode) =
  case n.kind
  of nkRaiseStmt:
    n.sons[0].info = n.info
    throws(tracked.exc, n.sons[0])
  of nkCallKinds:
    # p's effects are ours too:
    let a = n.sons[0]
    let op = a.typ
    if op != nil and op.kind == tyProc:
      InternalAssert op.n.sons[0].kind == nkEffectList
      var effectList = op.n.sons[0]
      if a.kind == nkSym and a.sym.kind == skMethod:
        propagateEffects(tracked, n, a.sym)
      elif effectList.len == 0:
        if isForwardedProc(a):
          propagateEffects(tracked, n, a.sym)
        elif isIndirectCall(a):
          addEffect(tracked, createRaise(n))
          addTag(tracked, createTag(n))
      else:
        mergeEffects(tracked, effectList.sons[exceptionEffects], n)
        mergeTags(tracked, effectList.sons[tagEffects], n)
    for i in 1 .. <len(n): trackOperand(tracked, n.sons[i])
  of nkTryStmt:
    trackTryStmt(tracked, n)
    return
  of nkPragma:
    trackPragmaStmt(tracked, n)
    return
  of nkMacroDef, nkTemplateDef: return
  else: nil
  for i in 0 .. <safeLen(n):
    track(tracked, n.sons[i])

proc checkRaisesSpec(spec, real: PNode, msg: string, hints: bool) =
  # check that any real exception is listed in 'spec'; mark those as used;
  # report any unused exception
  var used = initIntSet()
  for r in items(real):
    block search:
      for s in 0 .. <spec.len:
        if safeInheritanceDiff(r.excType, spec[s].typ) <= 0:
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
        Message(spec[s].info, hintXDeclaredButNotUsed, renderTree(spec[s]))

proc checkMethodEffects*(disp, branch: PSym) =
  ## checks for consistent effects for multi methods.
  let actual = branch.typ.n.sons[0]
  if actual.len != effectListLen: return

  let p = disp.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(raisesSpec, actual.sons[exceptionEffects],
      "can raise an unlisted exception: ", hints=off)
  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(tagsSpec, actual.sons[tagEffects],
      "can have an unlisted effect: ", hints=off)

proc setEffectsForProcType*(t: PType, n: PNode) =
  var effects = t.n.sons[0]
  InternalAssert t.kind == tyProc and effects.kind == nkEffectList

  let
    raisesSpec = effectSpec(n, wRaises)
    tagsSpec = effectSpec(n, wTags)
  if not isNil(raisesSpec) or not isNil(tagsSpec):
    InternalAssert effects.len == 0
    newSeq(effects.sons, effectListLen)
    if not isNil(raisesSpec):
      effects.sons[exceptionEffects] = raisesSpec
    if not isNil(tagsSpec):
      effects.sons[tagEffects] = tagsSpec

proc trackProc*(s: PSym, body: PNode) =
  var effects = s.typ.n.sons[0]
  InternalAssert effects.kind == nkEffectList
  # effects already computed?
  if sfForward in s.flags: return
  if effects.len == effectListLen: return
  newSeq(effects.sons, effectListLen)
  effects.sons[exceptionEffects] = newNodeI(nkArgList, body.info)
  effects.sons[tagEffects] = newNodeI(nkArgList, body.info)
  
  var t: TEffects
  t.exc = effects.sons[exceptionEffects]
  t.tags = effects.sons[tagEffects]
  track(t, body)
  
  let p = s.ast.sons[pragmasPos]
  let raisesSpec = effectSpec(p, wRaises)
  if not isNil(raisesSpec):
    checkRaisesSpec(raisesSpec, t.exc, "can raise an unlisted exception: ",
                    hints=on)
    # after the check, use the formal spec:
    effects.sons[exceptionEffects] = raisesSpec

  let tagsSpec = effectSpec(p, wTags)
  if not isNil(tagsSpec):
    checkRaisesSpec(tagsSpec, t.tags, "can have an unlisted effect: ",
                    hints=off)
    # after the check, use the formal spec:
    effects.sons[tagEffects] = tagsSpec
    