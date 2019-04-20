discard """
output: '''
done tableadds
And we get here
1
2
3
'''
joinable: false
"""
import hashes, sequtils, tables, algorithm

# test should not be joined because it takes too long.
block tableadds:
  proc main =
    var tab = newTable[string, string]()
    for i in 0..1000:
      tab.add "key", "value " & $i

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
    assert(t[0] == 42)
    assert(t[1] == 43)
    let t2 = {1: 1, 2: 2}.toTable
    assert(t2[2] == 2)

  # Test with char
  block:
    var t = initTable[char,int]()
    t['0'] = 42
    t['1'] = t['0'] + 1
    assert(t['0'] == 42)
    assert(t['1'] == 43)
    let t2 = {'1': 1, '2': 2}.toTable
    assert(t2['2'] == 2)

  # Test with enum
  block:
    type
      E = enum eA, eB, eC
    var t = initTable[E,int]()
    t[eA] = 42
    t[eB] = t[eA] + 1
    assert(t[eA] == 42)
    assert(t[eB] == 43)
    let t2 = {eA: 1, eB: 2}.toTable
    assert(t2[eB] == 2)

  # Test with range
  block:
    type
      R = range[1..10]
    var t = initTable[R,int]() # causes warning, why?
    t[1] = 42 # causes warning, why?
    t[2] = t[1] + 1
    assert(t[1] == 42)
    assert(t[2] == 43)
    let t2 = {1.R: 1, 2.R: 2}.toTable
    assert(t2[2.R] == 2)

  # Test which combines the generics for tuples + ordinals
  block:
    type
      E = enum eA, eB, eC
    var t = initTable[(string, E, int, char), int]()
    t[("a", eA, 0, '0')] = 42
    t[("b", eB, 1, '1')] = t[("a", eA, 0, '0')] + 1
    assert(t[("a", eA, 0, '0')] == 42)
    assert(t[("b", eB, 1, '1')] == 43)
    let t2 = {("a", eA, 0, '0'): 1, ("b", eB, 1, '1'): 2}.toTable
    assert(t2[("b", eB, 1, '1')] == 2)

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
  tbl1.add(1,1)
  tbl1.add(2,2)
  doAssert indexBy(@[1,2], proc(x: int):int = x) == tbl1, "int table"

  type
    TElem = object
      foo: int
      bar: string

  let
    elem1 = TElem(foo: 1, bar: "bar")
    elem2 = TElem(foo: 2, bar: "baz")

  var tbl2 = initTable[string, TElem]()
  tbl2.add("bar", elem1)
  tbl2.add("baz", elem2)
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
  assert 56 in 50..100

  assert 56 in ..60


block ttables2:
  proc TestHashIntInt() =
    var tab = initTable[int,int]()
    for i in 1..1_000_000:
      tab[i] = i
    for i in 1..1_000_000:
      var x = tab[i]
      if x != i : echo "not found ", i

  proc run1() =         # occupied Memory stays constant, but
    for i in 1 .. 50:   # aborts at run: 44 on win32 with 3.2GB with out of memory
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
        assert t[(x,y)] == $x & $y
    assert($t ==
      "{(x: 0, y: 1): \"01\", (x: 0, y: 0): \"00\", (x: 1, y: 0): \"10\", (x: 1, y: 1): \"11\"}")

  block tableTest2:
    var t = newTable[string, float]()
    t["test"] = 1.2345
    t["111"] = 1.000043
    t["123"] = 1.23
    t.del("111")

    t["012"] = 67.9
    t["123"] = 1.5 # test overwriting

    assert t["123"] == 1.5
    try:
      echo t["111"] # deleted
    except KeyError:
      discard
    assert(not hasKey(t, "111"))
    assert "111" notin t

    for key, val in items(data): t[key] = val.toFloat
    for key, val in items(data): assert t[key] == val.toFloat


  block orderedTableTest1:
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    for key, val in items(data): assert t[key] == val
    var i = 0
    # `pairs` needs to yield in insertion order:
    for key, val in pairs(t):
      assert key == data[i][0]
      assert val == data[i][1]
      inc(i)

    for key, val in mpairs(t): val = 99
    for val in mvalues(t): assert val == 99

  block countTableTest1:
    var s = data.toTable
    var t = newCountTable[string]()
    var r = newCountTable[string]()
    for x in [t, r]:
      for k in s.keys:
        x.inc(k)
        assert x[k] == 1
      x.inc("90", 3)
      x.inc("12", 2)
      x.inc("34", 1)
    assert t.largest()[0] == "90"

    t.sort()
    r.sort(SortOrder.Ascending)
    var ps1 = toSeq t.pairs
    var ps2 = toSeq r.pairs
    ps2.reverse()
    for ps in [ps1, ps2]:
      var i = 0
      for (k, v) in ps:
        case i
        of 0: assert k == "90" and v == 4
        of 1: assert k == "12" and v == 3
        of 2: assert k == "34" and v == 2
        else: break
        inc i

  block SyntaxTest:
    var x = newTable[int, string]({:})
    discard x

  block nilTest:
    var i, j: TableRef[int, int] = nil
    assert i == j
    j = newTable[int, int]()
    assert i != j
    assert j != i
    i = newTable[int, int]()
    assert i == j

  proc orderedTableSortTest() =
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    for key, val in items(data): assert t[key] == val
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
    doAssert "{'a': 1, 'b': 2, 'c': 3}" == $ toTable zip(keys, values)

  block clearTableTest:
    var t = newTable[string, float]()
    t["test"] = 1.2345
    t["111"] = 1.000043
    t["123"] = 1.23
    assert t.len() != 0
    t.clear()
    assert t.len() == 0

  block clearOrderedTableTest:
    var t = newOrderedTable[string, int](2)
    for key, val in items(data): t[key] = val
    assert t.len() != 0
    t.clear()
    assert t.len() == 0

  block clearCountTableTest:
    var t = newCountTable[string]()
    t.inc("90", 3)
    t.inc("12", 2)
    t.inc("34", 1)
    assert t.len() != 0
    t.clear()
    assert t.len() == 0

  orderedTableSortTest()
  echo "3"
