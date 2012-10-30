#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  ast, astalgo, msgs, semdata

# Second semantic checking pass over the AST. Necessary because the old
# way had some inherent problems. Performs:
# 
# * procvar checks
# * effect+exception tracking
# * closure analysis
# * checks for invalid usages of compiletime magics (not implemented)
# * checks for invalid usages of PNimNode (not implemented)
# * later: will do an escape analysis for closures at least

# Predefined effects:
#   io, time (time dependent), gc (performs GC'ed allocation), exceptions,
#   side effect (accesses global), store (stores into *type*),
#   store_unkown (performs some store) --> store(any)|store(x) 
#   load (loads from *type*), recursive (recursive call),
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

proc sem2call(c: PContext, n: PNode): PNode =
  assert n.kind in nkCallKinds
  
  

proc sem2sym(c: PContext, n: PNode): PNode =
  assert n.kind == nkSym
  
  
# ------------------------ exception tracking -------------------------------

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
    bottom: int
  
  PEffects = var TEffects

proc throws(tracked: PEffects, n: PNode) =
  # since a 'raise' statement occurs rarely and we need distinct reasons;
  # we simply do not merge anything here, this would be problematic for the
  # stack of exceptions anyway:
  tracked.exc.add n
  
proc excType(n: PNode): PType =
  assert n.kind == nkRaiseStmt
  # reraise is like raising E_Base:
  let t = if n.sons[0].kind == nkEmpty: sysTypeFromName"E_Base"
          else: n.sons[0].typ
  result = skipTypes(t, skipPtrs)

proc mergeEffects(a: PEffects, b: PNode) =
  var aa = a.exc
  for effect in items(b):
    block search
      for i in a.bottom .. <aa.len:
        if sameType(aa[i].excType, b.excType): break search
      throws(a, effect)

proc listEffects(a: PEffects) =
  var aa = a.exc
  for e in items(aa):
    Message(e.info, hintUser, renderTree(e))

proc catches(tracked: PEffects, e: PType) =
  let e = skipTypes(e, skipPtrs)
  let L = tracked.exc.len
  var i = tracked.bottom
  while i < L:
    # e supertype of r?
    if inheritanceDiff(e, tracked.exc[i].excType) <= 0:
      tracked.exc.sons[i] = tracked.exc.sons[L-1]
      dec L
    else:
      inc i
  
proc catchesAll(tracked: PEffects) =
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
  result = n.kind != nkSym or n.sym.kind notin routineKinds

proc isForwardedProc(n: PNode): bool =
  result = n.kind == nkSym and sfForward in n.sym.flags

proc trackPragmaStmt(tracked: PEffects, n: PNode) = 
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if whichPragma(it) == wEffects:
      # list the computed effects up to here:
      listEffects(tracked)

proc track(tracked: PEffects, n: PNode) =
  case n.kind
  of nkRaiseStmt: throws(tracked, n)
  of nkCallNode:
    # p's effects are ours too:
    let op = n.sons[0].typ
    InternalAssert op.kind == tyProc and op.n.sons[0].kind == nkEffectList
    var effectList = op.n.sons[0]
    if effectList.len == 0:
      if isIndirectCall(n.sons[0]) or isForwardedProc(n.sons[0]):
        # assume the worst: raise of exception 'E_Base':
        var rs = newNodeI(nkRaiseStmt, n.info)
        var re = newNodeIT(nkType, n.info, sysTypeFromName"E_Base")
        rs.add(re)
        effectList.add(rs)
    mergeEffects(tracked, effectList)
  of nkTryStmt:
    trackTryStmt(tracked, n)
    return
  of nkPragma:
    trackPragmaStmt(tracked, n)
    return
  else: nil
  for i in 0 .. <safeLen(n):
    track(tracked, n.sons[i])

proc trackProc*(s: PSym, body: PNode) =
  var effects = s.typ.n.sons[0]
  InternalAssert effects.kind == nkEffectList
  # effects already computed?
  if effects.len == effectListLen: return
  newSeq(effects.sons, effectListLen)
  
  var t: TEffects
  t.exc = effects.sons[exceptionEffects]
  track(t, body)
  
