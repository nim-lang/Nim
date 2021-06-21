discard """
output: '''10
10

1'''
nimout: '''
K=string V=int
K=int64 V=string
K=int V=int
'''
"""

import tables, typetraits

template ok(check) = assert check
template no(check) = assert(not check)

type
  Enumerable[T] = concept e
    for v in e:
      v is T

  Map[K, V] = concept m, var mvar
    m[K] is V
    mvar[K] = V
    m.contains(K) is bool
    m.valuesSeq is Enumerable[V]

  TreeMap[K, V] = object
    root: int

  SparseSeq = object
    data: seq[int]

  JudyArray = object
    data: SparseSeq

static:
  ok seq[int] is Enumerable[int]
  ok seq[string] is Enumerable
  ok seq[int] is Enumerable[SomeNumber]
  ok SparseSeq.data is Enumerable
  no seq[string] is Enumerable[int]
  no int is Enumerable
  no int is Enumerable[int]

# Complete the map concept implementation for the Table type
proc valuesSeq[K, V](t: Table[K, V]): seq[V]  =
  result = @[]
  for k, v in t:
    result.add v

# Map concept inplementation for TreeMap
proc valuesSeq(t: TreeMap): array[1, TreeMap.V] =
  var v: t.V
  result = [v]

proc contains[K, V](t: TreeMap[K, V], key: K): bool = true

proc `[]=`[K, V](t: var TreeMap[K, V], key: K, val: V) = discard
proc `[]`(t: TreeMap, key: t.K): TreeMap.V = discard

# Map concept implementation for the non-generic JudyArray
proc valuesSeq(j: JudyArray): SparseSeq = j.data

proc contains(t: JudyArray, key: int): bool = true

proc `[]=`(t: var JudyArray, key, val: int) = discard
proc `[]`(t: JudyArray, key: int): int = discard

iterator items(s: SparseSeq): int =
  for i in s.data: yield i

# Generic proc defined over map
proc getFirstValue[K,V](m : Map[K,V]): V =
  static: echo "K=", K.name, " V=", V.name

  for i in m.valuesSeq:
    return i

  raise newException(RangeDefect, "no values")

proc useConceptProcInGeneric[K, V](t: Table[K, V]): V =
  return t.getFirstValue

var t = initTable[string, int]()
t["test"] = 10

echo t.getFirstValue
echo t.useConceptProcInGeneric

var tm = TreeMap[int64, string](root: 0)
echo getFirstValue(tm)

var j = JudyArray(data: SparseSeq(data: @[1, 2, 3]))
echo getFirstValue(j)

static:
  ok Table[int, float] is Map
  ok Table[int, string] is Map[SomeNumber, string]
  no JudyArray is Map[string, int]

