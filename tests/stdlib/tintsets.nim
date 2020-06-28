import intsets
import std/sets

from sequtils import toSeq
from algorithm import sorted

proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

block: # we use HashSet as groundtruth, it's well tested elsewhere
  template testDel(t, t0) =

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

    block:
      var expected: seq[int]
      let n = 100
      let n2 = n*2
      for i in 0..<n:
        incl2(i)
      checkEquals()
      for i in 0..<n:
        if i mod 3 == 0:
          if i < n div 2:
            excl2(i)
          else:
            t0.excl i
            doAssert i in t
            doAssert not t.missingOrExcl(i)

      checkEquals()
      for i in n..<n2:
        incl2(i)
      checkEquals()
      for i in 0..<n2:
        if i mod 7 == 0:
          excl2(i)
      checkEquals()

      # notin check
      for i in 0..<t.len:
        if i mod 7 == 0:
          doAssert i notin t0
          doAssert i notin t
          # issue #13505
          doAssert t.missingOrExcl(i)

  var t: IntSet
  var t0: HashSet[int]
  testDel(t, t0)
