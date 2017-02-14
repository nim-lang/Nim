#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements code generation for multi methods.

import
  intsets, options, ast, astalgo, msgs, idents, renderer, types, magicsys,
  sempass2, strutils

proc genConv(n: PNode, d: PType, downcast: bool): PNode =
  var dest = skipTypes(d, abstractPtrs)
  var source = skipTypes(n.typ, abstractPtrs)
  if (source.kind == tyObject) and (dest.kind == tyObject):
    var diff = inheritanceDiff(dest, source)
    if diff == high(int):
      # no subtype relation, nothing to do
      result = n
    elif diff < 0:
      result = newNodeIT(nkObjUpConv, n.info, d)
      addSon(result, n)
      if downcast: internalError(n.info, "cgmeth.genConv: no upcast allowed")
    elif diff > 0:
      result = newNodeIT(nkObjDownConv, n.info, d)
      addSon(result, n)
      if not downcast:
        internalError(n.info, "cgmeth.genConv: no downcast allowed")
    else:
      result = n
  else:
    result = n

proc methodCall*(n: PNode): PNode =
  result = n
  # replace ordinary method by dispatcher method:
  var disp = lastSon(result.sons[0].sym.ast).sym
  assert sfDispatcher in disp.flags
  result.sons[0].sym = disp
  # change the arguments to up/downcasts to fit the dispatcher's parameters:
  for i in countup(1, sonsLen(result)-1):
    result.sons[i] = genConv(result.sons[i], disp.typ.sons[i], true)

# save for incremental compilation:
var
  gMethods: seq[tuple[methods: TSymSeq, dispatcher: PSym]] = @[]

type
  MethodResult = enum No, Invalid, Yes

proc sameMethodBucket(a, b: PSym): MethodResult =
  if a.name.id != b.name.id: return
  if sonsLen(a.typ) != sonsLen(b.typ):
    return                    # check for return type:
  if not sameTypeOrNil(a.typ.sons[0], b.typ.sons[0]): return
  for i in countup(1, sonsLen(a.typ) - 1):
    var aa = a.typ.sons[i]
    var bb = b.typ.sons[i]
    while true:
      aa = skipTypes(aa, {tyGenericInst, tyAlias})
      bb = skipTypes(bb, {tyGenericInst, tyAlias})
      if aa.kind == bb.kind and aa.kind in {tyVar, tyPtr, tyRef}:
        aa = aa.lastSon
        bb = bb.lastSon
      else:
        break
    if sameType(aa, bb):
      if aa.kind == tyObject and result != Invalid:
        result = Yes
    elif aa.kind == tyObject and bb.kind == tyObject:
      let diff = inheritanceDiff(bb, aa)
      if diff < 0:
        if result != Invalid:
          result = Yes
        else:
          return No
      elif diff != high(int):
        result = Invalid
      else:
        return No
    else:
      return No

proc attachDispatcher(s: PSym, dispatcher: PNode) =
  var L = s.ast.len-1
  var x = s.ast.sons[L]
  if x.kind == nkSym and sfDispatcher in x.sym.flags:
    # we've added a dispatcher already, so overwrite it
    s.ast.sons[L] = dispatcher
  else:
    s.ast.add(dispatcher)

proc createDispatcher(s: PSym): PSym =
  var disp = copySym(s)
  incl(disp.flags, sfDispatcher)
  excl(disp.flags, sfExported)
  disp.typ = copyType(disp.typ, disp.typ.owner, false)
  # we can't inline the dispatcher itself (for now):
  if disp.typ.callConv == ccInline: disp.typ.callConv = ccDefault
  disp.ast = copyTree(s.ast)
  disp.ast.sons[bodyPos] = ast.emptyNode
  disp.loc.r = nil
  if s.typ.sons[0] != nil:
    if disp.ast.sonsLen > resultPos:
      disp.ast.sons[resultPos].sym = copySym(s.ast.sons[resultPos].sym)
    else:
      # We've encountered a method prototype without a filled-in
      # resultPos slot. We put a placeholder in there that will
      # be updated in fixupDispatcher().
      disp.ast.addSon(ast.emptyNode)
  attachDispatcher(s, newSymNode(disp))
  # attach to itself to prevent bugs:
  attachDispatcher(disp, newSymNode(disp))
  return disp

proc fixupDispatcher(meth, disp: PSym) =
  # We may have constructed the dispatcher from a method prototype
  # and need to augment the incomplete dispatcher with information
  # from later definitions, particularly the resultPos slot. Also,
  # the lock level of the dispatcher needs to be updated/checked
  # against that of the method.
  if disp.ast.sonsLen > resultPos and meth.ast.sonsLen > resultPos and
     disp.ast.sons[resultPos] == ast.emptyNode:
    disp.ast.sons[resultPos] = copyTree(meth.ast.sons[resultPos])

  # The following code works only with lock levels, so we disable
  # it when they're not available.
  when declared(TLockLevel):
    proc `<`(a, b: TLockLevel): bool {.borrow.}
    proc `==`(a, b: TLockLevel): bool {.borrow.}
    if disp.typ.lockLevel == UnspecifiedLockLevel:
      disp.typ.lockLevel = meth.typ.lockLevel
    elif meth.typ.lockLevel != UnspecifiedLockLevel and
         meth.typ.lockLevel != disp.typ.lockLevel:
      message(meth.info, warnLockLevel,
        "method has lock level $1, but another method has $2" %
        [$meth.typ.lockLevel, $disp.typ.lockLevel])
      # XXX The following code silences a duplicate warning in
      # checkMethodeffects() in sempass2.nim for now.
      if disp.typ.lockLevel < meth.typ.lockLevel:
        disp.typ.lockLevel = meth.typ.lockLevel

proc methodDef*(s: PSym, fromCache: bool) =
  let L = len(gMethods)
  var witness: PSym
  for i in countup(0, L - 1):
    let disp = gMethods[i].dispatcher
    case sameMethodBucket(disp, s)
    of Yes:
      add(gMethods[i].methods, s)
      attachDispatcher(s, lastSon(disp.ast))
      fixupDispatcher(s, disp)
      #echo "fixup ", disp.name.s, " ", disp.id
      when useEffectSystem: checkMethodEffects(disp, s)
      if sfBase in s.flags and gMethods[i].methods[0] != s:
        # already exists due to forwarding definition?
        localError(s.info, "method is not a base")
      return
    of No: discard
    of Invalid:
      if witness.isNil: witness = gMethods[i].methods[0]
  # create a new dispatcher:
  add(gMethods, (methods: @[s], dispatcher: createDispatcher(s)))
  #echo "adding ", s.info
  #if fromCache:
  #  internalError(s.info, "no method dispatcher found")
  if witness != nil:
    localError(s.info, "invalid declaration order; cannot attach '" & s.name.s &
                       "' to method defined here: " & $witness.info)
  elif sfBase notin s.flags:
    message(s.info, warnUseBase)

proc relevantCol(methods: TSymSeq, col: int): bool =
  # returns true iff the position is relevant
  var t = methods[0].typ.sons[col].skipTypes(skipPtrs)
  if t.kind == tyObject:
    for i in countup(1, high(methods)):
      let t2 = skipTypes(methods[i].typ.sons[col], skipPtrs)
      if not sameType(t2, t):
        return true

proc cmpSignatures(a, b: PSym, relevantCols: IntSet): int =
  for col in countup(1, sonsLen(a.typ) - 1):
    if contains(relevantCols, col):
      var aa = skipTypes(a.typ.sons[col], skipPtrs)
      var bb = skipTypes(b.typ.sons[col], skipPtrs)
      var d = inheritanceDiff(aa, bb)
      if (d != high(int)) and d != 0:
        return d

proc sortBucket(a: var TSymSeq, relevantCols: IntSet) =
  # we use shellsort here; fast and simple
  var n = len(a)
  var h = 1
  while true:
    h = 3 * h + 1
    if h > n: break
  while true:
    h = h div 3
    for i in countup(h, n - 1):
      var v = a[i]
      var j = i
      while cmpSignatures(a[j - h], v, relevantCols) >= 0:
        a[j] = a[j - h]
        j = j - h
        if j < h: break
      a[j] = v
    if h == 1: break

proc genDispatcher(methods: TSymSeq, relevantCols: IntSet): PSym =
  var base = lastSon(methods[0].ast).sym
  result = base
  var paramLen = sonsLen(base.typ)
  var disp = newNodeI(nkIfStmt, base.info)
  var ands = getSysSym("and")
  var iss = getSysSym("of")
  for meth in countup(0, high(methods)):
    var curr = methods[meth]      # generate condition:
    var cond: PNode = nil
    for col in countup(1, paramLen - 1):
      if contains(relevantCols, col):
        var isn = newNodeIT(nkCall, base.info, getSysType(tyBool))
        addSon(isn, newSymNode(iss))
        addSon(isn, newSymNode(base.typ.n.sons[col].sym))
        addSon(isn, newNodeIT(nkType, base.info, curr.typ.sons[col]))
        if cond != nil:
          var a = newNodeIT(nkCall, base.info, getSysType(tyBool))
          addSon(a, newSymNode(ands))
          addSon(a, cond)
          addSon(a, isn)
          cond = a
        else:
          cond = isn
    var call = newNodeI(nkCall, base.info)
    addSon(call, newSymNode(curr))
    for col in countup(1, paramLen - 1):
      addSon(call, genConv(newSymNode(base.typ.n.sons[col].sym),
                           curr.typ.sons[col], false))
    var ret: PNode
    if base.typ.sons[0] != nil:
      var a = newNodeI(nkFastAsgn, base.info)
      addSon(a, newSymNode(base.ast.sons[resultPos].sym))
      addSon(a, call)
      ret = newNodeI(nkReturnStmt, base.info)
      addSon(ret, a)
    else:
      ret = call
    if cond != nil:
      var a = newNodeI(nkElifBranch, base.info)
      addSon(a, cond)
      addSon(a, ret)
      addSon(disp, a)
    else:
      disp = ret
  result.ast.sons[bodyPos] = disp

proc generateMethodDispatchers*(): PNode =
  result = newNode(nkStmtList)
  for bucket in countup(0, len(gMethods) - 1):
    var relevantCols = initIntSet()
    for col in countup(1, sonsLen(gMethods[bucket].methods[0].typ) - 1):
      if relevantCol(gMethods[bucket].methods, col): incl(relevantCols, col)
    sortBucket(gMethods[bucket].methods, relevantCols)
    addSon(result,
           newSymNode(genDispatcher(gMethods[bucket].methods, relevantCols)))
