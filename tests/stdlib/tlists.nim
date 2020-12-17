discard """
  targets: "c js"
"""

import lists, sequtils

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

template testCommon(initList, toList) =

  block: # toSinglyLinkedList, toDoublyLinkedList
    let l = seq[int].default
    doAssert l.toList.toSeq == []
    doAssert [1].toList.toSeq == [1]
    doAssert [1, 2, 3].toList.toSeq == [1, 2, 3]

  block copy:
    doAssert array[0, int].default.toList.copy.toSeq == []
    doAssert [1].toList.copy.toSeq == [1]
    doAssert [1, 2].toList.copy.toSeq == [1, 2]
    doAssert [1, 2, 3].toList.copy.toSeq == [1, 2, 3]
    type Foo = ref object
      x: int
    var f = Foo(x: 1)
    let a = [f, f].toList
    f.x = 42
    assert a.head.value == f
    assert a.head.next.value == f

  block: # add, addMoved
    block:
      var
        l0 = initList[int]()
        l1 = [1].toList
        l2 = [2, 3].toList
        l3 = [4, 5, 6].toList
      l0.add l3
      l1.add l3
      l2.addMoved l3
      doAssert l0.toSeq == [4, 5, 6]
      doAssert l1.toSeq == [1, 4, 5, 6]
      doAssert l2.toSeq == [2, 3, 4, 5, 6]
      doAssert l3.toSeq == []
      l2.add l3 # re-adding l3 that was destroyed is now a no-op
      doAssert l2.toSeq == [2, 3, 4, 5, 6]
      doAssert l3.toSeq == []
      l2.add(l3) # re-adding l3 that was destroyed is now a no-op
      doAssert l2.toSeq == [2, 3, 4, 5, 6]
      doAssert l3.toSeq == []
      l2.add(l3) # re-adding l3 that was destroyed is now a no-op
      doAssert l2.toSeq == [2, 3, 4, 5, 6]
      doAssert l3.toSeq == []
    block:
      var
        l0 = initList[int]()
        l1 = [1].toList
        l2 = [2, 3].toList
        l3 = [4, 5, 6].toList
      l3.addMoved l0
      l2.addMoved l1
      doAssert l3.toSeq == [4, 5, 6]
      doAssert l2.toSeq == [2, 3, 1]
      l3.add l0
      doAssert l3.toSeq == [4, 5, 6]

testCommon initSinglyLinkedList, toSinglyLinkedList
testCommon initDoublyLinkedList, toDoublyLinkedList
