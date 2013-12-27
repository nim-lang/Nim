#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this unit handles Nimrod sets; it implements symbolic sets

import 
  ast, astalgo, trees, nversion, msgs, platform, bitsets, types, renderer

proc toBitSet*(s: PNode, b: var TBitSet)
  # this function is used for case statement checking:
proc overlap*(a, b: PNode): bool
proc inSet*(s: PNode, elem: PNode): bool
proc someInSet*(s: PNode, a, b: PNode): bool
proc emptyRange*(a, b: PNode): bool
proc setHasRange*(s: PNode): bool
  # returns true if set contains a range (needed by the code generator)
  # these are used for constant folding:
proc unionSets*(a, b: PNode): PNode
proc diffSets*(a, b: PNode): PNode
proc intersectSets*(a, b: PNode): PNode
proc symdiffSets*(a, b: PNode): PNode
proc containsSets*(a, b: PNode): bool
proc equalSets*(a, b: PNode): bool
proc cardSet*(s: PNode): BiggestInt
# implementation

proc inSet(s: PNode, elem: PNode): bool = 
  if s.kind != nkCurly: 
    internalError(s.info, "inSet")
    return false
  for i in countup(0, sonsLen(s) - 1): 
    if s.sons[i].kind == nkRange: 
      if leValue(s.sons[i].sons[0], elem) and
          leValue(elem, s.sons[i].sons[1]): 
        return true
    else: 
      if sameValue(s.sons[i], elem): 
        return true
  result = false

proc overlap(a, b: PNode): bool =
  if a.kind == nkRange:
    if b.kind == nkRange:
      # X..Y and C..D overlap iff (X <= D and C <= Y)
      result = leValue(a.sons[0], b.sons[1]) and
               leValue(b.sons[0], a.sons[1])
    else:
      result = leValue(a.sons[0], b) and leValue(b, a.sons[1])
  else:
    if b.kind == nkRange:
      result = leValue(b.sons[0], a) and leValue(a, b.sons[1])
    else:
      result = sameValue(a, b)

proc SomeInSet(s: PNode, a, b: PNode): bool = 
  # checks if some element of a..b is in the set s
  if s.kind != nkCurly:
    internalError(s.info, "SomeInSet")
    return false
  for i in countup(0, sonsLen(s) - 1): 
    if s.sons[i].kind == nkRange: 
      if leValue(s.sons[i].sons[0], b) and leValue(b, s.sons[i].sons[1]) or
          leValue(s.sons[i].sons[0], a) and leValue(a, s.sons[i].sons[1]): 
        return true
    else: 
      # a <= elem <= b
      if leValue(a, s.sons[i]) and leValue(s.sons[i], b): 
        return true
  result = false

proc toBitSet(s: PNode, b: var TBitSet) = 
  var first, j: BiggestInt
  first = firstOrd(s.typ.sons[0])
  bitSetInit(b, int(getSize(s.typ)))
  for i in countup(0, sonsLen(s) - 1): 
    if s.sons[i].kind == nkRange: 
      j = getOrdValue(s.sons[i].sons[0])
      while j <= getOrdValue(s.sons[i].sons[1]): 
        bitSetIncl(b, j - first)
        inc(j)
    else: 
      bitSetIncl(b, getOrdValue(s.sons[i]) - first)
  
proc toTreeSet(s: TBitSet, settype: PType, info: TLineInfo): PNode = 
  var 
    a, b, e, first: BiggestInt # a, b are interval borders
    elemType: PType
    n: PNode
  elemType = settype.sons[0]
  first = firstOrd(elemType)
  result = newNodeI(nkCurly, info)
  result.typ = settype
  result.info = info
  e = 0
  while e < len(s) * elemSize: 
    if bitSetIn(s, e): 
      a = e
      b = e
      while true: 
        inc(b)
        if (b >= len(s) * elemSize) or not bitSetIn(s, b): break 
      dec(b)
      if a == b: 
        addSon(result, newIntTypeNode(nkIntLit, a + first, elemType))
      else: 
        n = newNodeI(nkRange, info)
        n.typ = elemType
        addSon(n, newIntTypeNode(nkIntLit, a + first, elemType))
        addSon(n, newIntTypeNode(nkIntLit, b + first, elemType))
        addSon(result, n)
      e = b
    inc(e)

template nodeSetOp(a, b: PNode, op: expr) {.dirty.} = 
  var x, y: TBitSet
  toBitSet(a, x)
  toBitSet(b, y)
  op(x, y)
  result = toTreeSet(x, a.typ, a.info)

proc unionSets(a, b: PNode): PNode = nodeSetOp(a, b, bitSetUnion)
proc diffSets(a, b: PNode): PNode = nodeSetOp(a, b, bitSetDiff)
proc intersectSets(a, b: PNode): PNode = nodeSetOp(a, b, bitSetIntersect)
proc symdiffSets(a, b: PNode): PNode = nodeSetOp(a, b, bitSetSymDiff)

proc containsSets(a, b: PNode): bool = 
  var x, y: TBitSet
  toBitSet(a, x)
  toBitSet(b, y)
  result = bitSetContains(x, y)

proc equalSets(a, b: PNode): bool = 
  var x, y: TBitSet
  toBitSet(a, x)
  toBitSet(b, y)
  result = bitSetEquals(x, y)

proc complement*(a: PNode): PNode =
  var x: TBitSet
  toBitSet(a, x)
  for i in countup(0, high(x)): x[i] = not x[i]
  result = toTreeSet(x, a.typ, a.info)

proc cardSet(s: PNode): BiggestInt = 
  # here we can do better than converting it into a compact set
  # we just count the elements directly
  result = 0
  for i in countup(0, sonsLen(s) - 1): 
    if s.sons[i].kind == nkRange: 
      result = result + getOrdValue(s.sons[i].sons[1]) -
          getOrdValue(s.sons[i].sons[0]) + 1
    else: 
      inc(result)
  
proc setHasRange(s: PNode): bool = 
  if s.kind != nkCurly:
    internalError(s.info, "SetHasRange")
    return false
  for i in countup(0, sonsLen(s) - 1): 
    if s.sons[i].kind == nkRange: 
      return true
  result = false

proc emptyRange(a, b: PNode): bool = 
  result = not leValue(a, b)  # a > b iff not (a <= b)
  
