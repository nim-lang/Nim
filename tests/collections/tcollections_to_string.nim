discard """
  exitcode: 0
  output: ""
"""
import tables
import lists

# Tests for tuples
doAssert $(1, 2, 3) == "(Field0: 1, Field1: 2, Field2: 3)"
doAssert $("1", "2", "3") == "(Field0: \"1\", Field1: \"2\", Field2: \"3\")"
doAssert $('1', '2', '3') == "(Field0: '1', Field1: '2', Field2: '3')"

# Tests for seqs
doAssert $(@[1, 2, 3]) == "@[1, 2, 3]"
doAssert $(@["1", "2", "3"]) == "@[\"1\", \"2\", \"3\"]"
doAssert $(@['1', '2', '3']) == "@['1', '2', '3']"

# Tests for tables
doAssert $({1: "1", 2: "2"}.toTable) == """{1: "1", 2: "2"}"""
doAssert $({"1": 1, "2": 2}.toTable) == """{"1": 1, "2": 2}"""

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
  doAssert $l == "[\"1\", \"2\", \"3\"]"
block:
  var l = initDoublyLinkedList[char]()
  l.append('1')
  l.append('2')
  l.append('3')
  doAssert $l == "['1', '2', '3']"

# Test escaping behavior
block:
  var s = ""
  s.addQuoted('\0')
  s.addQuoted('\31')
  s.addQuoted('\127')
  s.addQuoted('\255')
  doAssert s == "'\\x00''\\x1F''\\x7F''\\xFF'"
block:
  var s = ""
  s.addQuoted('\\')
  s.addQuoted('\'')
  s.addQuoted('\"')
  doAssert s == """'\\''\'''\"'"""

# Test customized element representation
type CustomString = object

proc addQuoted(s: var string, x: CustomString) =
  s.add("<CustomString>")

block:
  let s = @[CustomString()]
  doAssert $s == "@[<CustomString>]"

