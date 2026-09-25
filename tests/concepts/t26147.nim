discard """
  action: run
"""

type Indexable[T] = concept
  proc `[]`(a: Self; index: int): T
  proc len(a: Self): int

iterator items[T; I: Indexable[T]](indexable: I): T =
  for index in 0 ..< indexable.len:
    yield indexable[index]

type Dummy[T] = distinct seq[T]

proc `[]`[T](d: Dummy[T], i: int): T = seq[T](d)[i]
proc len[T](d: Dummy[T]): int = seq[T](d).len

var acc = 0
for x in Dummy(@[1, 2, 3]):
  acc += x
doAssert acc == 6

# Inferred concept parameters are resolved through the implementation's own
# generic bindings before being exported to the surrounding routine.
type
  Elem[T] = object
    value: T
  NestedDummy[T] = ref object
    data: seq[T]

proc `[]`[T](d: NestedDummy[T], i: int): Elem[T] =
  Elem[T](value: d.data[i])
proc len[T](d: NestedDummy[T]): int = d.data.len

iterator directItems[T](indexable: Indexable[T]): T =
  for index in 0 ..< indexable.len:
    yield indexable[index]

var nestedAcc = 0
for x in NestedDummy[int](data: @[4, 5, 6]):
  nestedAcc += x.value
doAssert nestedAcc == 15

var directNestedAcc = 0
for x in directItems(NestedDummy[int](data: @[7, 8, 9])):
  directNestedAcc += x.value
doAssert directNestedAcc == 24

# All dependent parameters inferred while checking a concept constraint must
# be propagated to the constrained routine.
type
  KeyValue[K, V] = concept
    proc key(x: Self): K
    proc value(x: Self): V
  Pair[K, V] = object
    k: K
    v: V

proc key[K, V](x: Pair[K, V]): K = x.k
proc value[K, V](x: Pair[K, V]): V = x.v

proc unpack[K, V; P: KeyValue[K, V]](x: P): (K, V) =
  (x.key, x.value)

let pair = Pair[int, string](k: 7, v: "seven")
doAssert unpack(pair) == (7, "seven")
doAssert not compiles(unpack[string, int](pair))

proc unpackBoth[K1, V1, K2, V2;
                P1: KeyValue[K1, V1]; P2: KeyValue[K2, V2]](
    x: P1; y: P2): ((K1, V1), (K2, V2)) =
  (unpack(x), unpack(y))

let otherPair = Pair[string, float](k: "eight", v: 8.0)
doAssert unpackBoth(pair, otherPair) == ((7, "seven"), ("eight", 8.0))

# A concrete `items` overload must win over one declared over a concept that
# the type happens to satisfy, and not generate an "ambiguous call".
type OverloadDummy[T] = ref object
  data: seq[T]

proc `[]`[T](d: OverloadDummy[T], i: int): T = d.data[i]
proc len[T](d: OverloadDummy[T]): int = d.data.len

iterator items[T](d: OverloadDummy[T]): T =
  # deliberately distinguishable from the concept-provided iterator
  for i in 0 ..< d.len:
    yield d.data[i] * 10

var overloadAcc: seq[int] = @[]
for x in OverloadDummy[int](data: @[1, 2, 3]):
  overloadAcc.add x
doAssert overloadAcc == @[10, 20, 30]
