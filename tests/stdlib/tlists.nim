discard """
  targets: "c js"
"""

import lists

const
  data = [1, 2, 3, 4, 5, 6]

block SinglyLinkedListTest1:
  var L: SinglyLinkedList[int]
  for d in items(data): L.prepend(d)
  for d in items(data): L.append(d)
  assert($L == "[6, 5, 4, 3, 2, 1, 1, 2, 3, 4, 5, 6]")

  assert(4 in L)

block SinglyLinkedListTest2:
  var L: SinglyLinkedList[string]
  for d in items(data): L.prepend($d)
  assert($L == """["6", "5", "4", "3", "2", "1"]""")

  assert("4" in L)


block DoublyLinkedListTest1:
  var L: DoublyLinkedList[int]
  for d in items(data): L.prepend(d)
  for d in items(data): L.append(d)
  L.remove(L.find(1))
  assert($L == "[6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6]")

  assert(4 in L)

block SinglyLinkedRingTest1:
  var L: SinglyLinkedRing[int]
  L.prepend(4)
  assert($L == "[4]")
  L.prepend(4)

  assert($L == "[4, 4]")
  assert(4 in L)


block DoublyLinkedRingTest1:
  var L: DoublyLinkedRing[int]
  L.prepend(4)
  assert($L == "[4]")
  L.prepend(4)

  assert($L == "[4, 4]")
  assert(4 in L)

  L.append(3)
  L.append(5)
  assert($L == "[4, 4, 3, 5]")

  L.remove(L.find(3))
  L.remove(L.find(5))
  L.remove(L.find(4))
  L.remove(L.find(4))
  assert($L == "[]")
  assert(4 notin L)

block tlistsToString:
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

block SinglyLinkedListConversion:
  let l: seq[int] = @[]
  doAssert $l.toSinglyLinkedList == "[]"
  doAssert $[1].toSinglyLinkedList == "[1]"
  doAssert $[1, 2, 3].toSinglyLinkedList == "[1, 2, 3]"

block DoublyLinkedListConversion:
  let l: seq[int] = @[]
  doAssert $l.toDoublyLinkedList == "[]"
  doAssert $[1].toDoublyLinkedList == "[1]"
  doAssert $[1, 2, 3].toDoublyLinkedList == "[1, 2, 3]"

block AddingSinglyLinkedLists:
  block:
    var
      l0 = initSinglyLinkedList[int]()
      l1 = [1].toSinglyLinkedList
      l2 = [2, 3].toSinglyLinkedList
      l3 = [4, 5, 6].toSinglyLinkedList
    l0.add(l3)
    l1.add(l3)
    l2.add(l3)
    doAssert $l0 == "[4, 5, 6]"
    doAssert $l1 == "[1, 4, 5, 6]"
    doAssert $l2 == "[2, 3, 4, 5, 6]"
  block:
    var
      l0 = initSinglyLinkedList[int]()
      l1 = [1].toSinglyLinkedList
      l2 = [2, 3].toSinglyLinkedList
      l3 = [4, 5, 6].toSinglyLinkedList
    l3.add(l0)
    l2.add(l1)
    doAssert $l3 == "[4, 5, 6]"
    doAssert $l2 == "[2, 3, 1]"
