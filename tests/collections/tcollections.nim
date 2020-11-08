discard """
  output: ""
"""

import sets, tables, deques, lists, critbits, sequtils


block tapply:
  var x = @[1, 2, 3]
  x.apply(proc(x: var int) = x = x+10)
  x.apply(proc(x: int): int = x+100)
  x.applyIt(it+5000)
  doAssert x == @[5111, 5112, 5113]


block tdeques:
  proc index(self: Deque[int], idx: Natural): int =
    self[idx]

  proc main =
    var testDeque = initDeque[int]()
    testDeque.addFirst(1)
    assert testDeque.index(0) == 1

  main()


block tmapit:
  var x = @[1, 2, 3]
  # This mapIt call will run with preallocation because ``len`` is available.
  var y = x.mapIt($(it+10))
  doAssert y == @["11", "12", "13"]

  type structureWithoutLen = object
    a: array[5, int]

  iterator items(s: structureWithoutLen): int {.inline.} =
    yield s.a[0]
    yield s.a[1]
    yield s.a[2]
    yield s.a[3]
    yield s.a[4]

  var st: structureWithoutLen
  st.a[0] = 0
  st.a[1] = 1
  st.a[2] = 2
  st.a[3] = 3
  st.a[4] = 4

  # this will run without preallocating the result
  # since ``len`` is not available
  var r = st.mapIt($(it+10))
  doAssert r == @["10", "11", "12", "13", "14"]



# Collections to string:

# Tests for tuples
doAssert $(1, 2, 3) == "(1, 2, 3)"
doAssert $("1", "2", "3") == """("1", "2", "3")"""
doAssert $('1', '2', '3') == """('1', '2', '3')"""

# Tests for seqs
doAssert $(@[1, 2, 3]) == "@[1, 2, 3]"
doAssert $(@["1", "2", "3"]) == """@["1", "2", "3"]"""
doAssert $(@['1', '2', '3']) == """@['1', '2', '3']"""

# Tests for sets
doAssert $(toHashSet([1])) == "{1}"
doAssert $(toHashSet(["1"])) == """{"1"}"""
doAssert $(toHashSet(['1'])) == """{'1'}"""
doAssert $(toOrderedSet([1, 2, 3])) == "{1, 2, 3}"
doAssert $(toOrderedSet(["1", "2", "3"])) == """{"1", "2", "3"}"""
doAssert $(toOrderedSet(['1', '2', '3'])) == """{'1', '2', '3'}"""

# Tests for tables
when defined(nimIntHash1):
  doAssert $({1: "1", 2: "2"}.toTable) == """{1: "1", 2: "2"}"""
else:
  doAssert $({1: "1", 2: "2"}.toTable) == """{2: "2", 1: "1"}"""
let tabStr = $({"1": 1, "2": 2}.toTable)
doAssert (tabStr == """{"2": 2, "1": 1}""" or tabStr == """{"1": 1, "2": 2}""")

# Tests for deques
block:
  var d = initDeque[int]()
  d.addLast(1)
  doAssert $d == "[1]"
block:
  var d = initDeque[string]()
  d.addLast("1")
  doAssert $d == """["1"]"""
block:
  var d = initDeque[char]()
  d.addLast('1')
  doAssert $d == "['1']"

# Tests for lists
block:
  var l = initDoublyLinkedList[int]()
  l.append(1)
  l.append(2)
  l.append(3)
  doAssert $l == "[1, 2, 3]"
block:
  var l = initDoublyLinkedList[string]()
  l.append("1")
  l.append("2")
  l.append("3")
  doAssert $l == """["1", "2", "3"]"""
block:
  var l = initDoublyLinkedList[char]()
  l.append('1')
  l.append('2')
  l.append('3')
  doAssert $l == """['1', '2', '3']"""

# Tests for critbits
block:
  var t: CritBitTree[int]
  t["a"] = 1
  doAssert $t == """{"a": 1}"""
block:
  var t: CritBitTree[string]
  t["a"] = "1"
  doAssert $t == """{"a": "1"}"""
block:
  var t: CritBitTree[char]
  t["a"] = '1'
  doAssert $t == """{"a": '1'}"""


# Test escaping behavior
block:
  var s = ""
  s.addQuoted('\0')
  s.addQuoted('\31')
  s.addQuoted('\127')
  doAssert s == "'\\x00''\\x1F''\\x7F'"
block:
  var s = ""
  s.addQuoted('\\')
  s.addQuoted('\'')
  s.addQuoted('\"')
  doAssert s == """'\\''\'''\"'"""
block:
  var s = ""
  s.addQuoted("å")
  s.addQuoted("ä")
  s.addQuoted("ö")
  s.addEscapedChar('\xFF')
  doAssert s == """"å""ä""ö"\xFF"""

# Test customized element representation
type CustomString = object

proc addQuoted(s: var string, x: CustomString) =
  s.add("<CustomString>")

block:
  let s = @[CustomString()]
  doAssert $s == "@[<CustomString>]"
