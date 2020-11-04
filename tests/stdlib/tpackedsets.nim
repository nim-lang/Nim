import std/packedsets
import std/sets

import sequtils
import algorithm

block basicIntSetTests:
  var y = initPackedSet[int]()
  y.incl(1)
  y.incl(2)
  y.incl(7)
  y.incl(1056)

  y.incl(1044)
  y.excl(1044)

  doAssert y == [1, 2, 7, 1056].toPackedSet
  doAssert toSeq(y.items) == [1, 2, 7, 1056]

  doAssert y.containsOrIncl(888) == false
  doAssert 888 in y
  doAssert y.containsOrIncl(888) == true

  doAssert y.missingOrExcl(888) == false
  doAssert 888 notin y
  doAssert y.missingOrExcl(888) == true

proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

type Id = distinct int
proc `$`(x: Id): string {.borrow.}
proc cmp(a: Id, b: Id): int {.borrow.}
proc `==`(a: Id, b: Id): bool {.borrow.}
proc `<`(a: Id, b: Id): bool {.borrow.}

block genericTests: 
  # we use HashSet as groundtruth, it's well tested elsewhere
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

      var expected: seq[A]
      let n = 100
      let n2 = n*2
      for i in 0..<n:
        incl2(A(i))
      checkEquals()
      for i in 0..<n:
        if i mod 3 == 0:
          if i < n div 2:
            excl2(A(i))
          else:
            t0.excl A(i)
            doAssert A(i) in t
            doAssert not t.missingOrExcl A(i)

      checkEquals()
      for i in n..<n2:
        incl2(A(i))
      checkEquals()
      for i in 0..<n2:
        if i mod 7 == 0:
          excl2(A(i))
      checkEquals()

      # notin check
      for i in 0..<t.len:
        if i mod 7 == 0:
          doAssert A(i) notin t0
          doAssert A(i) notin t
          # issue #13505
          doAssert t.missingOrExcl(A(i))

  var t: PackedSet[int]
  var t0: HashSet[int]
  testDel(int, t, t0)

  var distT: PackedSet[Id]
  var distT0: HashSet[Id]
  testDel(Id, distT, distT0)

  doAssert union(distT, initPackedSet[Id]()) == distT

  var charT: PackedSet[char]
  var charT0: HashSet[char]
  testDel(char, charT, charT0)


block typeSafetyTest:
  # mixing sets of different types shouldn't compile
  doAssert not compiles( union(initPackedSet[Id](), initPackedSet[int]()) )
  doAssert     compiles( union(initPackedSet[Id](), initPackedSet[Id]()))

  var ids: PackedSet[Id]
  doAssert not compiles( ids.incl(3) )
  doAssert     compiles( ids.incl(Id(3)) )

  type NonOrdinal = string
  doAssert not compiles( initPackedSet[NonOrdinal]() )

type EnumABCD = enum A, B, C, D

block enumTest:
  var letterSet = initPackedSet[EnumABCD]()

  for x in [A, C]:
    letterSet.incl(x)

  doAssert A in letterSet
  doAssert B notin letterSet
  doAssert C in letterSet
  doAssert D notin letterSet

type Foo = distinct int16
proc `$`(a: Foo): string {.borrow.} # `echo a` below won't work without `$` defined, as expected

block printTest:
  var a = initPackedSet[EnumABCD]()
  a.incl A
  a.incl C 
  doAssert $a == "{A, C}"

import intsets

block legacyMainModuleTests:
  template genericTests(A: typedesc[Ordinal], x: typed) =
    block:
      proc typSeq(s: seq[int]): seq[A] = s.map(proc (i: int): A = A(i))
      x.incl(A(1))
      x.incl(A(2))
      x.incl(A(7))
      x.incl(A(1056))

      x.incl(A(1044))
      x.excl(A(1044))

      doAssert x == typSeq(@[1, 2, 7, 1056]).toPackedSet

      doAssert x.containsOrIncl(A(888)) == false
      doAssert A(888) in x
      doAssert x.containsOrIncl(A(888)) == true

      doAssert x.missingOrExcl(A(888)) == false
      doAssert A(888) notin x
      doAssert x.missingOrExcl(A(888)) == true

      var xs = toSeq(items(x))
      xs.sort(cmp[A])
      doAssert xs == typSeq(@[1, 2, 7, 1056])

      var y: PackedSet[A]
      assign(y, x)
      var ys = toSeq(items(y))
      ys.sort(cmp[A])
      doAssert ys == typSeq(@[1, 2, 7, 1056])

      doAssert x == y

      var z: PackedSet[A]
      for i in 0..1000:
        incl z, A(i)
        doAssert z.len() == i+1
      for i in 0..1000:
        doAssert z.contains(A(i))

      var w = initPackedSet[A]()
      w.incl(A(1))
      w.incl(A(4))
      w.incl(A(50))
      w.incl(A(1001))
      w.incl(A(1056))

      var xuw = x.union(w)
      var xuws = toSeq(items(xuw))
      xuws.sort(cmp)
      doAssert xuws == typSeq(@[1, 2, 4, 7, 50, 1001, 1056])

      var xiw = x.intersection(w)
      var xiws = toSeq(items(xiw))
      xiws.sort(cmp)
      doAssert xiws == @[A(1), A(1056)]

      var xdw = x.difference(w)
      var xdws = toSeq(items(xdw))
      xdws.sort(cmp[A])
      doAssert xdws == @[A(2), A(7)]

      var xsw = x.symmetricDifference(w)
      var xsws = toSeq(items(xsw))
      xsws.sort(cmp[A])
      doAssert xsws == typSeq(@[2, 4, 7, 50, 1001])

      x.incl(w)
      xs = toSeq(items(x))
      xs.sort(cmp[A])
      doAssert xs == typSeq(@[1, 2, 4, 7, 50, 1001, 1056])

      doAssert w <= x

      doAssert w < x

      doAssert(not disjoint(w, x))

      var u = initPackedSet[A]()
      u.incl(A(3))
      u.incl(A(5))
      u.incl(A(500))
      doAssert disjoint(u, x)

      var v = initPackedSet[A]()
      v.incl(A(2))
      v.incl(A(50))

      x.excl(v)
      xs = toSeq(items(x))
      xs.sort(cmp[A])
      doAssert xs == typSeq(@[1, 4, 7, 1001, 1056])

      proc bug12366 =
        var
          x = initPackedSet[A]()
          y = initPackedSet[A]()
          n = 3584

        for i in 0..n:
          x.incl(A(i))
          y.incl(A(i))

        let z = symmetricDifference(x, y)
        doAssert z.len == 0
        doAssert $z == "{}"

      bug12366()

  var legacyInit = initIntSet()
  genericTests(int, legacyInit)

  var intGenericInit = initPackedSet[int]()
  genericTests(int, intGenericInit)

  var intDistinct = initPackedSet[Id]()
  genericTests(Id, intDistinct)
