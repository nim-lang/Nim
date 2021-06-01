discard """
  targets: "c cpp js"
"""

import std/[sets, hashes]

from std/sequtils import toSeq
from std/algorithm import sorted
from stdtest/testutils import whenVMorJs

proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

block tsetpop:
  var a = initHashSet[int]()
  for i in 1..1000:
    a.incl(i)
  doAssert len(a) == 1000
  for i in 1..1000:
    discard a.pop()
  doAssert len(a) == 0

  var msg = ""
  try:
    echo a.pop()
  except KeyError as e:
    msg = e.msg
  doAssert msg == "set is empty"



block tsets_lt:
  var s, s1: set[char]
  s = {'a'..'d'}
  s1 = {'a'..'c'}
  doAssert s1 < s
  doAssert s1 * s == {'a'..'c'}
  doAssert s1 <= s



block tsets2:
  const
    data = [
      "34", "12",
      "90", "0",
      "1", "2",
      "3", "4",
      "5", "6",
      "7", "8",
      "9", "---00",
      "10", "11", "19",
      "20", "30", "40",
      "50", "60", "70",
      "80"]

  block tableTest1:
    var t = initHashSet[tuple[x, y: int]]()
    t.incl((0,0))
    t.incl((1,0))
    doAssert(not t.containsOrIncl((0,1)))
    t.incl((1,1))

    for x in 0..1:
      for y in 0..1:
        doAssert((x,y) in t)
    #doAssert($t ==
    #  "{(x: 0, y: 0), (x: 0, y: 1), (x: 1, y: 0), (x: 1, y: 1)}")

  block setTest2:
    var t = initHashSet[string]()
    t.incl("test")
    t.incl("111")
    t.incl("123")
    t.excl("111")
    t.incl("012")
    t.incl("123") # test duplicates

    doAssert "123" in t
    doAssert "111" notin t # deleted

    doAssert t.missingOrExcl("000")
    doAssert "000" notin t
    doAssert t.missingOrExcl("012") == false
    doAssert "012" notin t

    doAssert t.containsOrIncl("012") == false
    doAssert t.containsOrIncl("012")
    doAssert "012" in t # added back

    for key in items(data): t.incl(key)
    for key in items(data): doAssert key in t

    for key in items(data): t.excl(key)
    for key in items(data): doAssert key notin t

  block orderedSetTest1:
    var t = data.toOrderedSet
    for key in items(data): doAssert key in t
    var i = 0
    # `items` needs to yield in insertion order:
    for key in items(t):
      doAssert key == data[i]
      inc(i)



block tsets3:
  let
    s1: HashSet[int] = toHashSet([1, 2, 4, 8, 16])
    s2: HashSet[int] = toHashSet([1, 2, 3, 5, 8])
    s3: HashSet[int] = toHashSet([3, 5, 7])

  block union:
    let
      s1_s2 = union(s1, s2)
      s1_s3 = s1 + s3
      s2_s3 = s2 + s3

    doAssert s1_s2.len == 7
    doAssert s1_s3.len == 8
    doAssert s2_s3.len == 6

    for i in s1:
      doAssert i in s1_s2
      doAssert i in s1_s3
    for i in s2:
      doAssert i in s1_s2
      doAssert i in s2_s3
    for i in s3:
      doAssert i in s1_s3
      doAssert i in s2_s3

    doAssert((s1 + s1) == s1)
    doAssert((s2 + s1) == s1_s2)

  block intersection:
    let
      s1_s2 = intersection(s1, s2)
      s1_s3 = intersection(s1, s3)
      s2_s3 = s2 * s3

    doAssert s1_s2.len == 3
    doAssert s1_s3.len == 0
    doAssert s2_s3.len == 2

    for i in s1_s2:
      doAssert i in s1
      doAssert i in s2
    for i in s1_s3:
      doAssert i in s1
      doAssert i in s3
    for i in s2_s3:
      doAssert i in s2
      doAssert i in s3

    doAssert((s2 * s2) == s2)
    doAssert((s3 * s2) == s2_s3)

  block symmetricDifference:
    let
      s1_s2 = symmetricDifference(s1, s2)
      s1_s3 = s1 -+- s3
      s2_s3 = s2 -+- s3

    doAssert s1_s2.len == 4
    doAssert s1_s3.len == 8
    doAssert s2_s3.len == 4

    for i in s1:
      doAssert i in s1_s2 xor i in s2
      doAssert i in s1_s3 xor i in s3
    for i in s2:
      doAssert i in s1_s2 xor i in s1
      doAssert i in s2_s3 xor i in s3
    for i in s3:
      doAssert i in s1_s3 xor i in s1
      doAssert i in s2_s3 xor i in s2

    doAssert((s3 -+- s3) == initHashSet[int]())
    doAssert((s3 -+- s1) == s1_s3)

  block difference:
    let
      s1_s2 = difference(s1, s2)
      s1_s3 = difference(s1, s3)
      s2_s3 = s2 - s3

    doAssert s1_s2.len == 2
    doAssert s1_s3.len == 5
    doAssert s2_s3.len == 3

    for i in s1:
      doAssert i in s1_s2 xor i in s2
      doAssert i in s1_s3 xor i in s3
    for i in s2:
      doAssert i in s2_s3 xor i in s3

    doAssert((s2 - s2) == initHashSet[int]())

  block disjoint:
    doAssert(not disjoint(s1, s2))
    doAssert disjoint(s1, s3)
    doAssert(not disjoint(s2, s3))
    doAssert(not disjoint(s2, s2))

block: # https://github.com/nim-lang/Nim/issues/13496
  template testDel(body) =
    block:
      body
      t.incl(15)
      t.incl(19)
      t.incl(17)
      t.incl(150)
      t.excl(150)
      doAssert t.len == 3
      doAssert sortedItems(t) == @[15, 17, 19]
      var s = newSeq[int]()
      for v in t: s.add(v)
      doAssert s.len == 3
      doAssert sortedItems(s) == @[15, 17, 19]
      when t is OrderedSet:
        doAssert sortedPairs(t) == @[(a: 0, b: 15), (a: 1, b: 19), (a: 2, b: 17)]
        doAssert toSeq(t) == @[15, 19, 17]

  testDel(): (var t: HashSet[int])
  testDel(): (var t: OrderedSet[int])

block: # test correctness after a number of inserts/deletes
  template testDel(body) =
    block:
      body
      var expected: seq[int]
      let n = 100
      let n2 = n*2
      for i in 0..<n:
        t.incl(i)
      for i in 0..<n:
        if i mod 3 == 0:
          t.excl(i)
      for i in n..<n2:
        t.incl(i)
      for i in 0..<n2:
        if i mod 7 == 0:
          t.excl(i)

      for i in 0..<n2:
        if (i>=n or i mod 3 != 0) and i mod 7 != 0:
          expected.add i

      for i in expected: doAssert i in t
      doAssert t.len == expected.len
      doAssert sortedItems(t) == expected

  testDel(): (var t: HashSet[int])
  testDel(): (var t: OrderedSet[int])


template main() =
  # xxx move all tests inside this
  block:
    let a = {true, false}
    doAssert $a == "{false, true}"
    doAssert a.len == 2

  block:
    let a = {false .. true}
    doAssert $a == "{false, true}"
    doAssert a.len == 2

  block:
    let a = {false .. false}
    doAssert $a == "{false}"
    doAssert a.len == 1

  block: # bug #16123
    whenVMorJs: discard
    do:
      type CallType = proc() {.closure.}
      var setA = initHashSet[CallType]()
      let foo = proc() = discard
      setA.incl(foo)
      doAssert setA.contains(foo)

static: main()
main()
