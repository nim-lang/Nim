import btreetables, sequtils, unittest


# smaller tables
test "init":
  var t = initOrderedTable[int, int]()
  t[1] = 10
  t[2] = 20
  t[3] = 30
  doAssert t.len == 3
  doAssert toSeq(keys(t)) == @[1, 2, 3]
  doAssert toSeq(values(t)) == @[10, 20, 30]
  doAssert toSeq(pairs(t)) == @[(1, 10), (2, 20), (3, 30)]

test "to ordered":
  var a = [(1, 10), (2, 20), (3, 30)]
  var t = toOrderedTable(a)
  doAssert t.len == 3
  doAssert toSeq(keys(t)) == @[1, 2, 3]
  doAssert toSeq(values(t)) == @[10, 20, 30]
  doAssert toSeq(pairs(t)) == @[(1, 10), (2, 20), (3, 30)]

test "getters":
  var t = {'a': "bc", 'd': "ef", 'g': "hi"}.toOrderedTable
  doAssert t['a'] == "bc"
  doAssertRaises(KeyError): discard t['j']
  doAssert t.hasKey('d')
  doAssert not t.hasKey('b')
  doAssert 'g' in t
  doAssert 'h' notin t
  doAssert t.getOrDefault('a') == "bc"
  doAssert t.getOrDefault('b') == ""
  doAssert t.getOrDefault('a', "xy") == "bc"
  doAssert t.getOrDefault('b', "xy") == "xy"
  doAssert 'b' notin t

test "repeating keys":
  var t: OrderedTable[char, int]
  for i, c in "abracadabra":
    t[c] = 10*i
  doAssert t.len == 5
  doAssert t['a'] == 100
  doAssert t['r'] == 90
  doAssert t['b'] == 80
  doAssert toSeq(keys(t)) == @['a', 'b', 'r', 'c', 'd']

test "put":
  var t: OrderedTable[int, char]
  doAssert not t.hasKeyOrPut(1, 'a')
  doAssert t.hasKeyOrPut(1, 'b')
  doAssert t[1] == 'a'
  doAssert t.mgetOrPut(1, 'z') == 'a'
  doAssert t.mgetOrPut(2, 'z') == 'z'
  doAssert t.len == 2

test "remove":
  var t = {"a": 99, "b": 88, "c": 77}.toOrderedTable
  t.delete("zz")
  doAssert t.len == 3
  t.delete("b")
  doAssert t.len == 2
  t.delete("b")
  doAssert t.len == 2
  t.del("b")
  doAssert t.len == 2
  var v = 1234
  doAssert not t.pop("b", v)
  doAssert v == 1234
  doAssert t.pop("a", v)
  doAssert v == 99
  doAssert t.len == 1
  t.clear()
  doAssert t.len == 0
  doAssert $t == "{:}"
  t.delete("zz")
  t.clear()

test "equality":
  var t1 = {1: 10, 2: 20, 3: 30}.toOrderedTable
  var t2 = {1: 10, 2: 20, 3: 30}.toOrderedTable
  var t3 = {1: 11, 2: 21, 3: 31}.toOrderedTable
  var t4 = {1: 10, 3: 30, 2: 20}.toOrderedTable
  var t5 = {1: 10, 2: 20, 3: 30, 4: 40}.toOrderedTable
  doAssert t1 == t2
  doAssert t1 != t3
  doAssert t2 != t4
  t4.delete(3)
  t4[3] = 30
  doAssert t1 == t4
  t1[4] = 40
  doAssert t1 == t5
  t5.del(4)
  doAssert t2 == t5

test "mvalues and mpairs":
  var a = {'c': 1, 'b': 2, 'a': 3}.toOrderedTable
  for k, v in mpairs(a):
    v += 10
  doAssert a['a'] == 13
  doAssert a['b'] == 12
  doAssert a['c'] == 11
  for v in mvalues(a):
    v += 10
  doAssert a['a'] == 23
  doAssert a['b'] == 22
  doAssert a['c'] == 21




# larger tables
test "without init":
  var t: OrderedTable[int, int]
  for i in 1..10:
    t[i] = 10*i
  doAssert t.len == 10
  t[11] = 1
  t[12] = 2
  t[-1] = 99
  doAssert t.len == 13
  doAssert toSeq(keys(t)) == @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, -1]

test "to ordered":
  var a = {9: 99, 8: 88, 7: 77, 6: 66, 5: 55, 4: 44, 3: 33, 2: 22, 1: 11,
           10: 0, 11: 1, 12: 2, 13: 3, 14: 4, 15: 5, 16: 6, 17: 7, 18: 8}
  var t = toOrderedTable(a)
  doAssert t.len == 18

test "getters":
  var t = {9: 99, 8: 88, 7: 77, 6: 66, 5: 55, 4: 44, 3: 33, 2: 22, 1: 11,
           10: 0, 11: 1, 12: 2, 13: 3, 14: 4, 15: 5, 16: 6}.toOrderedTable
  doAssert t[9] == 99
  doAssertRaises(KeyError): discard t[29]
  doAssert t.hasKey(8)
  doAssert not t.hasKey(28)
  doAssert 15 in t
  doAssert 25 notin t
  doAssert t.getOrDefault(9) == 99
  doAssert t.getOrDefault(29) == 0
  doAssert t.getOrDefault(9, 1234) == 99
  doAssert t.getOrDefault(29, 1234) == 1234
  doAssert 29 notin t

test "repeating keys":
  var t: OrderedTable[char, int]
  for i, c in "abracadabra popocatepetl minimum":
    t[c] = 10*i
  doAssert t.len == 15
  doAssert t['a'] == 170
  doAssert t['m'] == 310
  doAssert toSeq(keys(t)) == toSeq("abrcd potelminu")

test "put":
  var t = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44,
           'g': 33, 'h': 22, 'i': 11}.toOrderedTable
  doAssert not t.hasKeyOrPut('j', 12)
  doAssert t.hasKeyOrPut('j', 34)
  doAssert t['j'] == 12
  doAssert t.mgetOrput('k', 56) == 56
  doAssert t.mgetOrput('k', 78) == 56
  doAssert t.len == 11

test "remove":
  var t = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44,
           'g': 33, 'h': 22, 'i': 11}.toOrderedTable
  t.delete('j')
  doAssert t.len == 9
  t.delete('b')
  doAssert t.len == 8
  t.delete('b')
  t.delete('b')
  doAssert t.len == 8
  t.del('b')
  doAssert t.len == 8

test "equality":
  var t1 = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44}.toOrderedTable
  var t2 = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44}.toOrderedTable
  var t3 = {'a': 94, 'b': 83, 'c': 72, 'd': 61, 'e': 50, 'f': 39}.toOrderedTable
  var t4 = {'a': 99, 'f': 44, 'b': 88, 'c': 77, 'd': 66, 'e': 55}.toOrderedTable
  var t5 = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44, 'g': 33}.toOrderedTable
  doAssert t1 == t2
  doAssert t1 != t3
  doAssert t2 != t4
  t4.delete('f')
  t4['f'] = 44
  doAssert t1 == t4
  t1['g'] = 33
  doAssert t1 == t5
  t5.del('g')
  doAssert t2 == t5
  t2.del('b')
  t5.delete('b')
  doAssert t2 != t5

test "mvalues and mpairs":
  var a = {'a': 99, 'b': 88, 'c': 77, 'd': 66, 'e': 55, 'f': 44}.toOrderedTable
  for k, v in mpairs(a):
    v = v div 11
  doAssert a['a'] == 9
  doAssert a['b'] == 8
  doAssert a['f'] == 4
  for v in mvalues(a):
    v += 10
  doAssert a['a'] == 19
  doAssert a['b'] == 18
  doAssert a['f'] == 14
