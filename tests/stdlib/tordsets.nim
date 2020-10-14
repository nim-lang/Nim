import std/ordsets
import std/sets

from sequtils import toSeq
from algorithm import sorted

proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

type id = distinct int
proc cmp(a: id, b: id): int {.borrow.}
proc `==`(a: id, b: id): bool {.borrow.}
proc `<`(a: id, b: id): bool {.borrow.}

block: # we use HashSet as groundtruth, it's well tested elsewhere
  template testDel(A: typedesc, t: typed, t0: typed) =

    block:
      template checkEquals() =
        doAssert t.len == t0.len
        for k in t0:
          doAssert k in t
        for k in t:
          doAssert k in t0

        doAssert sortedItems(t) == sortedItems(t0)

      template incl2(i) =
        t.incl i
        t0.incl i

      template excl2(i) =
        t.excl i
        t0.excl i

      var expected: seq[`A`]
      let n = 100
      let n2 = n*2
      for i in 0..<n:
        incl2(`A`(i))
      checkEquals()
      for i in 0..<n:
        if i mod 3 == 0:
          if i < n div 2:
            excl2(`A`(i))
          else:
            t0.excl `A`(i)
            doAssert `A`(i) in t
            doAssert not t.missingOrExcl `A`(i)

      checkEquals()
      for i in n..<n2:
        incl2(`A`(i))
      checkEquals()
      for i in 0..<n2:
        if i mod 7 == 0:
          excl2(`A`(i))
      checkEquals()

      # notin check
      for i in 0..<t.len:
        if i mod 7 == 0:
          doAssert `A`(i) notin t0
          doAssert `A`(i) notin t
          # issue #13505
          doAssert t.missingOrExcl(`A`(i))

  var t: OrdSet[int]
  var t0: HashSet[int]
  testDel(int, t, t0)

  # Test distincts
  var distT: OrdSet[id]
  var distT0: HashSet[id]
  testDel(id, distT, distT0)

  assert union(distT, initOrdSet[id]()) == distT

  # mixing sets of different types shouldn't compile
  #assert union(distT, initOrdSet[int]()) == distT # KO! typesafe

  #Should fail
  type nonIntDistinct = distinct string
  #initOrdSet[nonIntDistinct]().incl("not typesafe") #KO!

  # Test enums
  type enumABCD = enum A, B, C, D
  var letterSet = initOrdSet[enumABCD]()

  for x in [A, C]:
    letterSet.incl(x)

  assert A in letterSet
  assert B notin letterSet
  assert C in letterSet
  assert D notin letterSet

