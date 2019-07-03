#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this unit handles Nim sets; it implements symbolic sets

import
  ast, astalgo, trees, nversion, lineinfos, platform, bitsets, types, renderer,
  options

proc inSet*(s: PNode, elem: PNode): bool =
  assert s.kind == nkCurly
  if s.kind != nkCurly:
    #internalError(s.info, "inSet")
    return false
  for i in 0 ..< sonsLen(s):
    if s.sons[i].kind == nkRange:
      if leValue(s.sons[i].sons[0], elem) and
          leValue(elem, s.sons[i].sons[1]):
        return true
    else:
      if sameValue(s.sons[i], elem):
        return true
  result = false

proc overlap*(a, b: PNode): bool =
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

proc someInSet*(s: PNode, a, b: PNode): bool =
  # checks if some element of a..b is in the set s
  assert s.kind == nkCurly
  if s.kind != nkCurly:
    #internalError(s.info, "SomeInSet")
    return false
  for i in 0 ..< sonsLen(s):
    if s.sons[i].kind == nkRange:
      if leValue(s.sons[i].sons[0], b) and leValue(b, s.sons[i].sons[1]) or
          leValue(s.sons[i].sons[0], a) and leValue(a, s.sons[i].sons[1]):
        return true
    else:
      # a <= elem <= b
      if leValue(a, s.sons[i]) and leValue(s.sons[i], b):
        return true
  result = false

proc toBitSet*(conf: ConfigRef; s: PNode, b: var TBitSet) =
  var first, j: BiggestInt
  first = firstOrd(conf, s.typ.sons[0])
  bitSetInit(b, int(getSize(conf, s.typ)))
  for i in 0 ..< sonsLen(s):
    if s.sons[i].kind == nkRange:
      j = getOrdValue(s.sons[i].sons[0])
      while j <= getOrdValue(s.sons[i].sons[1]):
        bitSetIncl(b, j - first)
        inc(j)
    else:
      bitSetIncl(b, getOrdValue(s.sons[i]) - first)

proc toTreeSet*(conf: ConfigRef; s: TBitSet, settype: PType, info: TLineInfo): PNode =
  var
    a, b, e, first: BiggestInt # a, b are interval borders
    elemType: PType
    n: PNode
  elemType = settype.sons[0]
  first = firstOrd(conf, elemType)
  result = newNodeI(nkCurly, info)
  result.typ = settype
  result.info = info
  e = 0
  while e < len(s) * ElemSize:
    if bitSetIn(s, e):
      a = e
      b = e
      while true:
        inc(b)
        if (b >= len(s) * ElemSize) or not bitSetIn(s, b): break
      dec(b)
      let aa = newIntTypeNode(nkIntLit, a + first, elemType)
      aa.info = info
      if a == b:
        addSon(result, aa)
      else:
        n = newNodeI(nkRange, info)
        n.typ = elemType
        addSon(n, aa)
        let bb = newIntTypeNode(nkIntLit, b + first, elemType)
        bb.info = info
        addSon(n, bb)
        addSon(result, n)
      e = b
    inc(e)

template nodeSetOp(a, b: PNode, op: untyped) {.dirty.} =
  var x, y: TBitSet
  toBitSet(conf, a, x)
  toBitSet(conf, b, y)
  op(x, y)
  result = toTreeSet(conf, x, a.typ, a.info)

proc unionSets*(conf: ConfigRef; a, b: PNode): PNode = nodeSetOp(a, b, bitSetUnion)
proc diffSets*(conf: ConfigRef; a, b: PNode): PNode = nodeSetOp(a, b, bitSetDiff)
proc intersectSets*(conf: ConfigRef; a, b: PNode): PNode = nodeSetOp(a, b, bitSetIntersect)
proc symdiffSets*(conf: ConfigRef; a, b: PNode): PNode = nodeSetOp(a, b, bitSetSymDiff)

proc containsSets*(conf: ConfigRef; a, b: PNode): bool =
  var x, y: TBitSet
  toBitSet(conf, a, x)
  toBitSet(conf, b, y)
  result = bitSetContains(x, y)

proc equalSets*(conf: ConfigRef; a, b: PNode): bool =
  var x, y: TBitSet
  toBitSet(conf, a, x)
  toBitSet(conf, b, y)
  result = bitSetEquals(x, y)

proc complement*(conf: ConfigRef; a: PNode): PNode =
  var x: TBitSet
  toBitSet(conf, a, x)
  for i in 0 .. high(x): x[i] = not x[i]
  result = toTreeSet(conf, x, a.typ, a.info)

proc deduplicate*(conf: ConfigRef; a: PNode): PNode =
  var x: TBitSet
  toBitSet(conf, a, x)
  result = toTreeSet(conf, x, a.typ, a.info)

proc cardSet*(conf: ConfigRef; a: PNode): BiggestInt =
  var x: TBitSet
  toBitSet(conf, a, x)
  result = bitSetCard(x)

proc setHasRange*(s: PNode): bool =
  assert s.kind == nkCurly
  if s.kind != nkCurly:
    return false
  for i in 0 ..< sonsLen(s):
    if s.sons[i].kind == nkRange:
      return true
  result = false

proc emptyRange*(a, b: PNode): bool =
  result = not leValue(a, b)  # a > b iff not (a <= b)
