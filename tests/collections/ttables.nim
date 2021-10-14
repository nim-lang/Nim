discard """
output: '''
done tableadds
And we get here
1
2
3
'''
joinable: false
targets: "c cpp js"
"""

# xxx wrap in a template to test in VM, see https://github.com/timotheecour/Nim/issues/534#issuecomment-769565033

import hashes, sequtils, tables, algorithm

proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

block tableDollar:
  # other tests should use `sortedPairs` to be robust to future table/hash
  # implementation changes
  doAssert ${1: 'a', 2: 'b'}.toTable in ["{1: 'a', 2: 'b'}", "{2: 'b', 1: 'a'}"]

# test should not be joined because it takes too long.
block tableadds:
  proc main =
    var tab = newTable[string, string]()
    for i in 0..1000:
      tab["key"] = "value " & $i

  main()
  echo "done tableadds"


block tcounttable:
  # bug #2625
  const s_len = 32
  var substr_counts: CountTable[string] = initCountTable[string]()
  var my_string = "Hello, this is sadly broken for strings over 64 characters. Note that it *does* appear to work for short strings."
  for i in 0..(my_string.len - s_len):
    let s = my_string[i..i+s_len-1]
    substr_counts[s] = 1
    # substr_counts[s] = substr_counts[s] + 1  # Also breaks, + 2 as well, etc.
    # substr_counts.inc(s)  # This works
    #echo "Iteration ", i

  echo "And we get here"


block thashes:
  # Test with int
  block:
    var t = initTable[int,int]()
    t[0] = 42
    t[1] = t[0] + 1
    doAssert(t[0] == 42)
    doAssert(t[1] == 43)
    let t2 = {1: 1, 2: 2}.toTable
    doAssert(t2[2] == 2)

  # Test with char
  block:
    var t = initTable[char,int]()
    t['0'] = 42
    t['1'] = t['0'] + 1
    doAssert(t['0'] == 42)
    doAssert(t['1'] == 43)
    let t2 = {'1': 1, '2': 2}.toTable
    doAssert(t2['2'] == 2)

  # Test with enum
  block:
    type
      E = enum eA, eB, eC
    var t = initTable[E,int]()
    t[eA] = 42
    t[eB] = t[eA] + 1
    doAssert(t[eA] == 42)
    doAssert(t[eB] == 43)
    let t2 = {eA: 1, eB: 2}.toTable
    doAssert(t2[eB] == 2)

  # Test with range
  block:
    type
      R = range[0..9]
    var t = initTable[R,int]() # causes warning, why?
    t[1] = 42 # causes warning, why?
    t[2] = t[1] + 1
    doAssert(t[1] == 42)
    doAssert(t[2] == 43)
    let t2 = {1.R: 1, 2.R: 2}.toTable
    doAssert(t2[2.R] == 2)

  # Test which combines the generics for tuples + ordinals
  block:
    type
      E = enum eA, eB, eC
    var t = initTable[(string, E, int, char), int]()
    t[("a", eA, 0, '0')] = 42
    t[("b", eB, 1, '1')] = t[("a", eA, 0, '0')] + 1
    doAssert(t[("a", eA, 0, '0')] == 42)
    doAssert(t[("b", eB, 1, '1')] == 43)
    let t2 = {("a", eA, 0, '0'): 1, ("b", eB, 1, '1'): 2}.toTable
    doAssert(t2[("b", eB, 1, '1')] == 2)

  # Test to check if overloading is possible
  # Unfortunately, this does not seem to work for int
  # The same test with a custom hash(s: string) does
  # work though.
  block:
    proc hash(x: int): Hash {.inline.} =
      echo "overloaded hash"
      result = x
    var t = initTable[int, int]()
    t[0] = 0

  # Check hashability of all integer types (issue #5429)
  block:
    let intTables = (
      newTable[int, string](),
      newTable[int8, string](),
      newTable[int16, string](),
      newTable[int32, string](),
      newTable[int64, string](),
      newTable[uint, string](),
      newTable[uint8, string](),
      newTable[uint16, string](),
      newTable[uint32, string](),
      newTable[uint64, string](),
    )
  echo "1"


block tindexby:
  doAssert indexBy(newSeq[int](), proc(x: int):int = x) == initTable[int, int](), "empty int table"

  var tbl1 = initTable[int, int]()
  tbl1[1] = 1
  tbl1[2] = 2
  doAssert indexBy(@[1,2], proc(x: int):int = x) == tbl1, "int table"

  type
    TElem = object
      foo: int
      bar: string

  let
    elem1 = TElem(foo: 1, bar: "bar")
    elem2 = TElem(foo: 2, bar: "baz")

  var tbl2 = initTable[string, TElem]()
  tbl2["bar"] = elem1
  tbl2["baz"] = elem2
  doAssert indexBy(@[elem1,elem2], proc(x: TElem): string = x.bar) == tbl2, "element table"


block tableconstr:
  # Test if the new table constructor syntax works:

  template ignoreExpr(e) =
    discard

  # test first class '..' syntactical citizen:
  ignoreExpr x <> 2..4
  # test table constructor:
  ignoreExpr({:})
  ignoreExpr({2: 3, "key": "value"})

  # NEW:
  doAssert 56 in 50..100

  doAssert 56 in 0..60


block ttables2:
  proc TestHashIntInt() =
    var tab = initTable[int,int]()
    let n = 100_000
    for i in 1..n:
      tab[i] = i
    for i in 1..n:
      var x = tab[i]
      if x != i : echo "not found ", i

  proc run1() =
    for i in 1 .. 50:
      TestHashIntInt()

  # bug #2107

  var delTab = initTable[int,int](4)

  for i in 1..4:
    delTab[i] = i
    delTab.del(i)
  delTab[5] = 5


  run1()
  echo "2"

block tablesref:
  const
    data = {
      "34": 123456, "12": 789,
      "90": 343, "0": 34404,
      "1": 344004, "2": 344774,
      "3": 342244, "4": 3412344,
      "5": 341232144, "6": 34214544,
      "7": 3434544, "8": 344544,
      "9": 34435644, "---00": 346677844,
      "10": 34484, "11": 34474, "19": 34464,
      "20": 34454, "30": 34141244, "40": 344114,
      "50": 344490, "60": 344491, "70": 344492,
      "80": 344497}

    sorteddata = {
      "---00": 346677844,
      "0": 34404,
      "1": 344004,
      "10": 34484,
      "11": 34474,
      "12": 789,
      "19": 34464,
      "2": 344774, "20": 34454,
      "3": 342244, "30": 34141244,
      "34": 123456,
      "4": 3412344, "40": 344114,
      "5": 341232144, "50": 344490,
      "6": 34214544, "60": 344491,
      "7": 3434544, "70": 344492,
      "8": 344544, "80": 344497,
      "9": 34435644,
      "90": 343}

  block tableTest1:
    var t = newTable[tuple[x, y: int], string]()
    t[(0,0)] = "00"
    t[(1,0)] = "10"
    t[(0,1)] = "01"
    t[(1,1)] = "11"
    for x in 0..1:
      for y in 0..1:
        doAssert t[(x,y)] == $x & $y
    doAssert t.sortedPairs ==
      @[((x: 0, y: 0), "00"), ((x: 0, y: 1), "01"), ((x: 1, y: 0), "10"), ((x: 1, y: 1), "11")]

  block tableTest2:
    var t = newTable[string, float]()
    t["test"] = 1.2345
    t["111"] = 1.000043
    t["123"] = 1.23
    t.del("111")

    t["012"] = 67.9
    t["123"] = 1.5 # test overwriting

    doAssert t["123"] == 1.5
    try:
      echo t["111"] # deleted
    except KeyError:
      discard
    doAssert(not hasKey(t, "111"))
    doAssert "111" notin t

    for key, val in items(data): t[key] = val.toFloat
    for key, val in items(data): doAssert t[key] == val.toFloat


  block orderedTableTest1:
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    for key, val in items(data): doAssert t[key] == val
    var i = 0
    # `pairs` needs to yield in insertion order:
    for key, val in pairs(t):
      doAssert key == data[i][0]
      doAssert val == data[i][1]
      inc(i)

    for key, val in mpairs(t): val = 99
    for val in mvalues(t): doAssert val == 99

  block countTableTest1:
    var s = data.toTable
    var t = newCountTable[string]()
    var r = newCountTable[string]()
    for x in [t, r]:
      for k in s.keys:
        x.inc(k)
        doAssert x[k] == 1
      x.inc("90", 3)
      x.inc("12", 2)
      x.inc("34", 1)
    doAssert t.largest()[0] == "90"

    t.sort()
    r.sort(SortOrder.Ascending)
    var ps1 = toSeq t.pairs
    var ps2 = toSeq r.pairs
    ps2.reverse()
    for ps in [ps1, ps2]:
      var i = 0
      for (k, v) in ps:
        case i
        of 0: doAssert k == "90" and v == 4
        of 1: doAssert k == "12" and v == 3
        of 2: doAssert k == "34" and v == 2
        else: break
        inc i

  block smallestLargestNamedFieldsTest: # bug #14918
    const a = [7, 8, 8]

    proc testNamedFields(t: CountTable | CountTableRef) =
      doAssert t.smallest.key == 7
      doAssert t.smallest.val == 1
      doAssert t.largest.key == 8
      doAssert t.largest.val == 2

    let t1 = toCountTable(a)
    testNamedFields(t1)
    let t2 = newCountTable(a)
    testNamedFields(t2)

  block SyntaxTest:
    var x = newTable[int, string]({:})
    discard x

  block nilTest:
    var i, j: TableRef[int, int] = nil
    doAssert i == j
    j = newTable[int, int]()
    doAssert i != j
    doAssert j != i
    i = newTable[int, int]()
    doAssert i == j

  proc orderedTableSortTest() =
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    for key, val in items(data): doAssert t[key] == val
    proc cmper(x, y: tuple[key: string, val: int]): int = cmp(x.key, y.key)
    t.sort(cmper)
    var i = 0
    # `pairs` needs to yield in sorted order:
    for key, val in pairs(t):
      doAssert key == sorteddata[i][0]
      doAssert val == sorteddata[i][1]
      inc(i)
    t.sort(cmper, order=SortOrder.Descending)
    i = 0
    for key, val in pairs(t):
      doAssert key == sorteddata[high(data)-i][0]
      doAssert val == sorteddata[high(data)-i][1]
      inc(i)

    # check that lookup still works:
    for key, val in pairs(t):
      doAssert val == t[key]
    # check that insert still works:
    t["newKeyHere"] = 80

  block anonZipTest:
    let keys = @['a','b','c']
    let values = @[1, 2, 3]
    doAssert zip(keys, values).toTable.sortedPairs == @[('a', 1), ('b', 2), ('c', 3)]

  block clearTableTest:
    var t = newTable[string, float]()
    t["test"] = 1.2345
    t["111"] = 1.000043
    t["123"] = 1.23
    doAssert t.len() != 0
    t.clear()
    doAssert t.len() == 0

  block clearOrderedTableTest:
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    doAssert t.len() != 0
    t.clear()
    doAssert t.len() == 0

  block clearCountTableTest:
    var t = newCountTable[string]()
    t.inc("90", 3)
    t.inc("12", 2)
    t.inc("34", 1)
    doAssert t.len() != 0
    t.clear()
    doAssert t.len() == 0

  orderedTableSortTest()
  echo "3"


block: # https://github.com/nim-lang/Nim/issues/13496
  template testDel(body) =
    block:
      body
      when t is CountTable|CountTableRef:
        t.inc(15, 1)
        t.inc(19, 2)
        t.inc(17, 3)
        t.inc(150, 4)
        t.del(150)
      else:
        t[15] = 1
        t[19] = 2
        t[17] = 3
        t[150] = 4
        t.del(150)
      doAssert t.len == 3
      doAssert sortedItems(t.values) == @[1, 2, 3]
      doAssert sortedItems(t.keys) == @[15, 17, 19]
      doAssert sortedPairs(t) == @[(15, 1), (17, 3), (19, 2)]
      var s = newSeq[int]()
      for v in t.values: s.add(v)
      doAssert s.len == 3
      doAssert sortedItems(s) == @[1, 2, 3]
      when t is OrderedTable|OrderedTableRef:
        doAssert toSeq(t.keys) == @[15, 19, 17]
        doAssert toSeq(t.values) == @[1,2,3]
        doAssert toSeq(t.pairs) == @[(15, 1), (19, 2), (17, 3)]

  testDel(): (var t: Table[int, int])
  testDel(): (let t = newTable[int, int]())
  testDel(): (var t: OrderedTable[int, int])
  testDel(): (let t = newOrderedTable[int, int]())
  testDel(): (var t: CountTable[int])
  testDel(): (let t = newCountTable[int]())


block testNonPowerOf2:
  var a = initTable[int, int](7)
  a[1] = 10
  doAssert a[1] == 10

  var b = initTable[int, int](9)
  b[1] = 10
  doAssert b[1] == 10

block emptyOrdered:
  var t1: OrderedTable[int, string]
  var t2: OrderedTable[int, string]
  doAssert t1 == t2

block: # Table[ref, int]
  type A = ref object
    x: int
  var t: OrderedTable[A, int]
  let a1 = A(x: 3)
  let a2 = A(x: 3)
  t[a1] = 10
  t[a2] = 11
  doAssert t[a1] == 10
  doAssert t[a2] == 11
