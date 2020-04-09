discard """
  exitcode: 0
  output: ""
"""
import sets
import tables
import deques
import lists
import critbits

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
doAssert $({"1": 1, "2": 2}.toTable) == """{"1": 1, "2": 2}"""

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

