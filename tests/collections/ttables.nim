discard """
  output: '''true'''
"""

import hashes, tables

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
  var t = initTable[tuple[x, y: int], string]()
  t[(0,0)] = "00"
  t[(1,0)] = "10"
  t[(0,1)] = "01"
  t[(1,1)] = "11"
  for x in 0..1:
    for y in 0..1:
      assert t[(x,y)] == $x & $y
  assert($t == 
    "{(x: 0, y: 1): 01, (x: 0, y: 0): 00, (x: 1, y: 0): 10, (x: 1, y: 1): 11}")

block tableTest2:
  var t = initTable[string, float]()
  t["test"] = 1.2345
  t["111"] = 1.000043
  t["123"] = 1.23
  t.del("111")
  
  t["012"] = 67.9
  t["123"] = 1.5 # test overwriting
  
  assert t["123"] == 1.5
  assert t["111"] == 0.0 # deleted
  assert(not hasKey(t, "111"))
  
  for key, val in items(data): t[key] = val.toFloat
  for key, val in items(data): assert t[key] == val.toFloat

  assert(not t.hasKeyOrPut("456", 4.0))     # test absent key
  assert t.hasKeyOrPut("012", 3.0)          # test present key
  var x = t.mgetOrPut("111", 1.5)           # test absent key
  x = x * 2
  assert x == 3.0
  x = t.mgetOrPut("test", 1.5)              # test present key
  x = x * 2
  assert x == 2 * 1.2345

block orderedTableTest1:
  var t = initOrderedTable[string, int](2)
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
  var t = initCountTable[string]()
  for k in s.keys: t.inc(k)
  for k in t.keys: assert t[k] == 1
  t.inc("90", 3)
  t.inc("12", 2)
  t.inc("34", 1)
  assert t.largest()[0] == "90"

  t.sort()
  var i = 0
  for k, v in t.pairs:
    case i
    of 0: assert k == "90" and v == 4
    of 1: assert k == "12" and v == 3
    of 2: assert k == "34" and v == 2
    else: break
    inc i

block mpairsTableTest1:
  var t = initTable[string, int]()
  t["a"] = 1
  t["b"] = 2
  t["c"] = 3
  t["d"] = 4
  for k, v in t.mpairs:
    if k == "a" or k == "c":
      v = 9

  for k, v in t.pairs:
    if k == "a" or k == "c":
      assert v == 9
    else:
      assert v != 1 and v != 3

block SyntaxTest:
  var x = toTable[int, string]({:})

proc orderedTableSortTest() =
  var t = initOrderedTable[string, int](2)
  for key, val in items(data): t[key] = val
  for key, val in items(data): assert t[key] == val
  t.sort(proc (x, y: tuple[key: string, val: int]): int = cmp(x.key, y.key))
  var i = 0
  # `pairs` needs to yield in sorted order:
  for key, val in pairs(t):
    doAssert key == sorteddata[i][0]
    doAssert val == sorteddata[i][1]
    inc(i)

  # check that lookup still works:
  for key, val in pairs(t):
    doAssert val == t[key]
  # check that insert still works:
  t["newKeyHere"] = 80


orderedTableSortTest()
echo "true"

