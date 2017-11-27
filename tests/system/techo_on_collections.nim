discard """
  output: '''Hello world
(Field0: 1, Field1: 2, Field2: 3)
(Field0: "1", Field1: "2", Field2: "3")
(Field0: '1', Field1: '2', Field2: '3')
@[1, 2, 3]
@["1", "2", "3"]
@['1', '2', '3']
{1: "1", 2: "2"}
{"1": 1, "2": 2}
[1, 2, 3]
["1", "2", "3"]
['1', '2', '3']
'''
"""
import tables
import lists

# Tests that plain strings are not quoted
echo "Hello world"

# Tests for tuples
echo((1, 2, 3))
echo(("1", "2", "3"))
echo(('1', '2', '3'))

# Tests for seqs
echo @[1, 2, 3]
echo @["1", "2", "3"]
echo @['1', '2', '3']

# Tests for tables
echo {1: "1", 2: "2"}.toTable
echo {"1": 1, "2": 2}.toTable

# Tests for lists
block:
  var l = initDoublyLinkedList[int]()
  l.append(1)
  l.append(2)
  l.append(3)
  echo l
block:
  var l = initDoublyLinkedList[string]()
  l.append("1")
  l.append("2")
  l.append("3")
  echo l
block:
  var l = initDoublyLinkedList[char]()
  l.append('1')
  l.append('2')
  l.append('3')
  echo l