discard """
  targets: "c js"
"""

import std/[lists, sequtils]

const
  data = [1, 2, 3, 4, 5, 6]


template main =
  block SinglyLinkedListTest1:
    var L: SinglyLinkedList[int]
    for d in items(data): L.prepend(d)
    for d in items(data): L.append(d)
    doAssert($L == "[6, 5, 4, 3, 2, 1, 1, 2, 3, 4, 5, 6]")

    doAssert(4 in L)

  block SinglyLinkedListTest2:
    var L: SinglyLinkedList[string]
    for d in items(data): L.prepend($d)
    doAssert($L == """["6", "5", "4", "3", "2", "1"]""")

    doAssert("4" in L)


  block DoublyLinkedListTest1:
    var L: DoublyLinkedList[int]
    for d in items(data): L.prepend(d)
    for d in items(data): L.append(d)
    L.remove(L.find(1))
    doAssert($L == "[6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6]")

    doAssert(4 in L)

  block SinglyLinkedRingTest1:
    var L: SinglyLinkedRing[int]
    L.prepend(4)
    doAssert($L == "[4]")
    L.prepend(4)

    doAssert($L == "[4, 4]")
    doAssert(4 in L)


  block DoublyLinkedRingTest1:
    var L: DoublyLinkedRing[int]
    L.prepend(4)
    doAssert($L == "[4]")
    L.prepend(4)

    doAssert($L == "[4, 4]")
    doAssert(4 in L)

    L.append(3)
    L.append(5)
    doAssert($L == "[4, 4, 3, 5]")

    L.remove(L.find(3))
    L.remove(L.find(5))
    L.remove(L.find(4))
    L.remove(L.find(4))
    doAssert($L == "[]")
    doAssert(4 notin L)

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

static: main()
main()
