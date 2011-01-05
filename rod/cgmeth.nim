#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements code generation for multi methods.

import 
  options, ast, astalgo, msgs, idents, rnimsyn, types, magicsys

proc methodDef*(s: PSym)
proc methodCall*(n: PNode): PNode
proc generateMethodDispatchers*(): PNode
# implementation

const 
  skipPtrs = {tyVar, tyPtr, tyRef, tyGenericInst}

proc genConv(n: PNode, d: PType, downcast: bool): PNode = 
  var 
    dest, source: PType
    diff: int
  dest = skipTypes(d, abstractPtrs)
  source = skipTypes(n.typ, abstractPtrs)
  if (source.kind == tyObject) and (dest.kind == tyObject): 
    diff = inheritanceDiff(dest, source)
    if diff == high(int): InternalError(n.info, "cgmeth.genConv")
    if diff < 0: 
      result = newNodeIT(nkObjUpConv, n.info, d)
      addSon(result, n)
      if downCast: InternalError(n.info, "cgmeth.genConv: no upcast allowed")
    elif diff > 0: 
      result = newNodeIT(nkObjDownConv, n.info, d)
      addSon(result, n)
      if not downCast: 
        InternalError(n.info, "cgmeth.genConv: no downcast allowed")
    else: 
      result = n
  else: 
    result = n
  
proc methodCall(n: PNode): PNode = 
  var disp: PSym
  result = n
  disp = lastSon(result.sons[0].sym.ast).sym
  result.sons[0].sym = disp
  for i in countup(1, sonsLen(result) - 1): 
    result.sons[i] = genConv(result.sons[i], disp.typ.sons[i], true)
  
var gMethods: seq[TSymSeq]

proc sameMethodBucket(a, b: PSym): bool = 
  var aa, bb: PType
  result = false
  if a.name.id != b.name.id: return 
  if sonsLen(a.typ) != sonsLen(b.typ): 
    return                    # check for return type:
  if not sameTypeOrNil(a.typ.sons[0], b.typ.sons[0]): return 
  for i in countup(1, sonsLen(a.typ) - 1): 
    aa = a.typ.sons[i]
    bb = b.typ.sons[i]
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
      nil
    else: 
      return 
  result = true

proc methodDef(s: PSym) = 
  var 
    L, q: int
    disp: PSym
  L = len(gMethods)
  for i in countup(0, L - 1): 
    if sameMethodBucket(gMethods[i][0], s): 
      add(gMethods[i], s)     # store a symbol to the dispatcher:
      addSon(s.ast, lastSon(gMethods[i][0].ast))
      return 
  add(gMethods, @ [s])        # create a new dispatcher:
  disp = copySym(s)
  disp.typ = copyType(disp.typ, disp.typ.owner, false)
  if disp.typ.callConv == ccInline: disp.typ.callConv = ccDefault
  disp.ast = copyTree(s.ast)
  disp.ast.sons[codePos] = nil
  if s.typ.sons[0] != nil: 
    disp.ast.sons[resultPos].sym = copySym(s.ast.sons[resultPos].sym)
  addSon(s.ast, newSymNode(disp))

proc relevantCol(methods: TSymSeq, col: int): bool = 
  var t: PType
  # returns true iff the position is relevant
  t = methods[0].typ.sons[col]
  result = false
  if skipTypes(t, skipPtrs).kind == tyObject: 
    for i in countup(1, high(methods)): 
      if not SameType(methods[i].typ.sons[col], t): 
        return true
  
proc cmpSignatures(a, b: PSym, relevantCols: TIntSet): int = 
  var 
    d: int
    aa, bb: PType
  result = 0
  for col in countup(1, sonsLen(a.typ) - 1): 
    if intSetContains(relevantCols, col): 
      aa = skipTypes(a.typ.sons[col], skipPtrs)
      bb = skipTypes(b.typ.sons[col], skipPtrs)
      d = inheritanceDiff(aa, bb)
      if (d != high(int)): 
        return d
  
proc sortBucket(a: var TSymSeq, relevantCols: TIntSet) = 
  # we use shellsort here; fast and simple
  var 
    N, j, h: int
    v: PSym
  N = len(a)
  h = 1
  while true: 
    h = 3 * h + 1
    if h > N: break 
  while true: 
    h = h div 3
    for i in countup(h, N - 1): 
      v = a[i]
      j = i
      while cmpSignatures(a[j - h], v, relevantCols) >= 0: 
        a[j] = a[j - h]
        j = j - h
        if j < h: break 
      a[j] = v
    if h == 1: break 
  
proc genDispatcher(methods: TSymSeq, relevantCols: TIntSet): PSym = 
  var 
    disp, cond, call, ret, a, isn: PNode
    base, curr, ands, iss: PSym
    paramLen: int
  base = lastSon(methods[0].ast).sym
  result = base
  paramLen = sonsLen(base.typ)
  disp = newNodeI(nkIfStmt, base.info)
  ands = getSysSym("and")
  iss = getSysSym("is")
  for meth in countup(0, high(methods)): 
    curr = methods[meth]      # generate condition:
    cond = nil
    for col in countup(1, paramLen - 1): 
      if IntSetContains(relevantCols, col): 
        isn = newNodeIT(nkCall, base.info, getSysType(tyBool))
        addSon(isn, newSymNode(iss))
        addSon(isn, newSymNode(base.typ.n.sons[col].sym))
        addSon(isn, newNodeIT(nkType, base.info, curr.typ.sons[col]))
        if cond != nil: 
          a = newNodeIT(nkCall, base.info, getSysType(tyBool))
          addSon(a, newSymNode(ands))
          addSon(a, cond)
          addSon(a, isn)
          cond = a
        else: 
          cond = isn
    call = newNodeI(nkCall, base.info)
    addSon(call, newSymNode(curr))
    for col in countup(1, paramLen - 1): 
      addSon(call, genConv(newSymNode(base.typ.n.sons[col].sym), 
                           curr.typ.sons[col], false))
    if base.typ.sons[0] != nil: 
      a = newNodeI(nkAsgn, base.info)
      addSon(a, newSymNode(base.ast.sons[resultPos].sym))
      addSon(a, call)
      ret = newNodeI(nkReturnStmt, base.info)
      addSon(ret, a)
    else: 
      ret = call
    a = newNodeI(nkElifBranch, base.info)
    addSon(a, cond)
    addSon(a, ret)
    addSon(disp, a)
  result.ast.sons[codePos] = disp

proc generateMethodDispatchers(): PNode = 
  var relevantCols: TIntSet
  result = newNode(nkStmtList)
  for bucket in countup(0, len(gMethods) - 1): 
    IntSetInit(relevantCols)
    for col in countup(1, sonsLen(gMethods[bucket][0].typ) - 1): 
      if relevantCol(gMethods[bucket], col): IntSetIncl(relevantCols, col)
    sortBucket(gMethods[bucket], relevantCols)
    addSon(result, newSymNode(genDispatcher(gMethods[bucket], relevantCols)))

gMethods = @[]
