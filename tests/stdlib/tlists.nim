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
    for d in items(data): L.add(d)
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
    for d in items(data): L.add(d)
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

    L.add(3)
    L.add(5)
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
      l.add(1)
      l.add(2)
      l.add(3)
      doAssert $l == "[1, 2, 3]"
    block:
      var l = initDoublyLinkedList[string]()
      l.add("1")
      l.add("2")
      l.add("3")
      doAssert $l == """["1", "2", "3"]"""
    block:
      var l = initDoublyLinkedList[char]()
      l.add('1')
      l.add('2')
      l.add('3')
      doAssert $l == """['1', '2', '3']"""

  # Copied here until it is merged into sequtils
  template take(a: untyped, max: int): untyped =
    type T = typeof(block: (for ai in a: ai))
    var ret: seq[T]
    var i = 0
    if max > 0:
      for ai in a:
        ret.add ai
        i.inc
        if i >= max: break
    ret

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
      var f0 = Foo(x: 0)
      let f1 = Foo(x: 1)
      var a = [f0].toList
      var b = a.copy
      b.add f1
      doAssert a.toSeq == [f0]
      doAssert b.toSeq == [f0, f1]
      f0.x = 42
      doAssert a.head.value.x == 42
      doAssert b.head.value.x == 42

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
      block:
        var c = [0, 1].toList
        c.addMoved c
        doAssert c.take(6) == [0, 1, 0, 1, 0, 1]

    block: # prepend, prependMoved
      block:
        var
          l0 = initList[int]()
          l1 = [1].toList
          l2 = [2, 3].toList
          l3 = [4, 5, 6].toList
        l0.prepend l3
        l1.prepend l3
        doAssert l3.toSeq == [4, 5, 6]
        l2.prependMoved l3
        doAssert l0.toSeq == [4, 5, 6]
        doAssert l1.toSeq == [4, 5, 6, 1]
        doAssert l2.toSeq == [4, 5, 6, 2, 3]
        doAssert l3.toSeq == []
        l2.prepend l3 # re-prepending l3 that was destroyed is now a no-op
        doAssert l2.toSeq == [4, 5, 6, 2, 3]
        doAssert l3.toSeq == []
      block:
        var
          l0 = initList[int]()
          l1 = [1].toList
          l2 = [2, 3].toList
          l3 = [4, 5, 6].toList
        l3.prependMoved l0
        l2.prependMoved l1
        doAssert l3.toSeq == [4, 5, 6]
        doAssert l2.toSeq == [1, 2, 3]
        l3.prepend l0
        doAssert l3.toSeq == [4, 5, 6]
      block:
        var c = [0, 1].toList
        c.prependMoved c
        doAssert c.take(6) == [0, 1, 0, 1, 0, 1]

    block remove:
      var l = [0, 1, 2, 3].toList
      let
        l0 = l.head
        l1 = l0.next
        l2 = l1.next
        l3 = l2.next
      l.remove l0
      doAssert l.toSeq == [1, 2, 3]
      l.remove l2
      doAssert l.toSeq == [1, 3]
      l.remove l2
      doAssert l.toSeq == [1, 3]
      l.remove l3
      doAssert l.toSeq == [1]
      l.remove l1
      doAssert l.toSeq == []
      # Cycle preservation
      var a = [10, 11, 12].toList
      a.addMoved a
      doAssert a.take(6) == @[10, 11, 12, 10, 11, 12]
      a.remove a.head.next
      doAssert a.take(6) == @[10, 12, 10, 12, 10, 12]
      a.remove a.head
      doAssert a.take(6) == @[12, 12, 12, 12, 12, 12]

  testCommon initSinglyLinkedList, toSinglyLinkedList
  testCommon initDoublyLinkedList, toDoublyLinkedList

  block remove: # return value check
    var l = [0, 1, 2, 3].toSinglyLinkedList
    let n = l.head.next.next
    doAssert l.remove(n) == true
    doAssert l.toSeq == [0, 1, 3]
    doAssert l.remove(n) == false
    doAssert l.toSeq == [0, 1, 3]
    doAssert l.remove(l.head) == true
    doAssert l.toSeq == [1, 3]
    doAssert l.remove(l.head.next) == true
    doAssert l.toSeq == [1]
    doAssert l.remove(l.head) == true
    doAssert l.toSeq == []
  
  block issue19297: # add (appends a shallow copy)
    var a: SinglyLinkedList[int]
    var b: SinglyLinkedList[int]

    doAssert a.toSeq == @[]
    a.add(1)
    doAssert a.toSeq == @[1]
    a.add(b)
    doAssert a.toSeq == @[1]
    a.add(2)
    doAssert a.toSeq == @[1, 2]
  
  block issue19314: # add (appends a shallow copy)
    var a: DoublyLinkedList[int]
    var b: DoublyLinkedList[int]

    doAssert a.toSeq == @[]
    a.add(1)
    doAssert a.toSeq == @[1]
    a.add(b)
    doAssert a.toSeq == @[1]
    a.add(2)
    doAssert a.toSeq == @[1, 2]

  block RemoveLastNodeFromSinglyLinkedList:
    var list = initSinglyLinkedList[string]()
    let n1 = newSinglyLinkedNode("sonic")
    let n2 = newSinglyLinkedNode("the")
    let n3 = newSinglyLinkedNode("tiger")
    let n4 = newSinglyLinkedNode("hedgehog")
    list.add(n1)
    list.add(n2)
    list.add(n3)
    list.remove(n3)
    list.add(n4)
    doAssert list.toSeq == @["sonic", "the", "hedgehog"]

static: main()
main()
