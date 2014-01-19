#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements code generation for multi methods.

import 
  intsets, options, ast, astalgo, msgs, idents, renderer, types, magicsys,
  sempass2

proc genConv(n: PNode, d: PType, downcast: bool): PNode = 
  var dest = skipTypes(d, abstractPtrs)
  var source = skipTypes(n.typ, abstractPtrs)
  if (source.kind == tyObject) and (dest.kind == tyObject): 
    var diff = inheritanceDiff(dest, source)
    if diff == high(int): internalError(n.info, "cgmeth.genConv")
    if diff < 0: 
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
var gMethods: seq[TSymSeq] = @[]

proc sameMethodBucket(a, b: PSym): bool = 
  result = false
  if a.name.id != b.name.id: return 
  if sonsLen(a.typ) != sonsLen(b.typ): 
    return                    # check for return type:
  if not sameTypeOrNil(a.typ.sons[0], b.typ.sons[0]): return 
  for i in countup(1, sonsLen(a.typ) - 1): 
    var aa = a.typ.sons[i]
    var bb = b.typ.sons[i]
    while true: 
      aa = skipTypes(aa, {tyGenericInst})
      bb = skipTypes(bb, {tyGenericInst})
      if (aa.kind == bb.kind) and (aa.kind in {tyVar, tyPtr, tyRef}): 
        aa = aa.sons[0]
        bb = bb.sons[0]
      else: 
        break 
    if sameType(aa, bb) or
        (aa.kind == tyObject) and (bb.kind == tyObject) and
        (inheritanceDiff(bb, aa) < 0):
      discard
    else:
      return
  result = true

proc attachDispatcher(s: PSym, dispatcher: PNode) =
  var L = s.ast.len-1
  var x = s.ast.sons[L]
  if x.kind == nkSym and sfDispatcher in x.sym.flags:
    # we've added a dispatcher already, so overwrite it
    s.ast.sons[L] = dispatcher
  else:
    s.ast.add(dispatcher)

proc methodDef*(s: PSym, fromCache: bool) =
  var L = len(gMethods)
  for i in countup(0, L - 1):
    let disp = gMethods[i][0]
    if sameMethodBucket(disp, s):
      add(gMethods[i], s)
      attachDispatcher(s, lastSon(disp.ast))
      when useEffectSystem: checkMethodEffects(disp, s)
      return 
  add(gMethods, @[s])
  # create a new dispatcher:
  if not fromCache:
    var disp = copySym(s)
    incl(disp.flags, sfDispatcher)
    excl(disp.flags, sfExported)
    disp.typ = copyType(disp.typ, disp.typ.owner, false)
    # we can't inline the dispatcher itself (for now):
    if disp.typ.callConv == ccInline: disp.typ.callConv = ccDefault
    disp.ast = copyTree(s.ast)
    disp.ast.sons[bodyPos] = ast.emptyNode
    if s.typ.sons[0] != nil: 
      disp.ast.sons[resultPos].sym = copySym(s.ast.sons[resultPos].sym)
    attachDispatcher(s, newSymNode(disp))
    # attach to itself to prevent bugs:
    attachDispatcher(disp, newSymNode(disp))

proc relevantCol(methods: TSymSeq, col: int): bool =
  # returns true iff the position is relevant
  var t = methods[0].typ.sons[col].skipTypes(skipPtrs)
  if t.kind == tyObject:
    for i in countup(1, high(methods)):
      let t2 = skipTypes(methods[i].typ.sons[col], skipPtrs)
      if not sameType(t2, t):
        return true
  
proc cmpSignatures(a, b: PSym, relevantCols: TIntSet): int = 
  for col in countup(1, sonsLen(a.typ) - 1): 
    if contains(relevantCols, col): 
      var aa = skipTypes(a.typ.sons[col], skipPtrs)
      var bb = skipTypes(b.typ.sons[col], skipPtrs)
      var d = inheritanceDiff(aa, bb)
      if (d != high(int)): 
        return d
  
proc sortBucket(a: var TSymSeq, relevantCols: TIntSet) = 
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
  
proc genDispatcher(methods: TSymSeq, relevantCols: TIntSet): PSym =
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
      var a = newNodeI(nkAsgn, base.info)
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
    for col in countup(1, sonsLen(gMethods[bucket][0].typ) - 1): 
      if relevantCol(gMethods[bucket], col): incl(relevantCols, col)
    sortBucket(gMethods[bucket], relevantCols)
    addSon(result, newSymNode(genDispatcher(gMethods[bucket], relevantCols)))

