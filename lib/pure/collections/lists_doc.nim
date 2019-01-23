## Implementation of:
## * `singly linked lists <#SinglyLinkedList>`_
## * `doubly linked lists <#DoublyLinkedList>`_
## * `singly linked rings <#SinglyLinkedRing>`_ (circular lists)
## * `doubly linked rings <#DoublyLinkedRing>`_ (circular lists)
##
##
## # Basic Usage
##
## Because it makes no sense to do otherwise, the `next` and `prev` pointers
## are not hidden from you and can be manipulated directly for efficiency.


## ## Lists

runnableExamples:
  import lists

  var
    l = initDoublyLinkedList[int]()
    a = newDoublyLinkedNode[int](3)
    b = newDoublyLinkedNode[int](7)
    c = newDoublyLinkedNode[int](9)

  l.append(a)
  l.append(b)
  l.prepend(c)

  assert a.next == b
  assert a.prev == c
  assert c.next == a
  assert c.next.next == b
  assert c.prev == nil
  assert b.next == nil


## ## Rings

runnableExamples:
  import lists

  var
    l = initSinglyLinkedRing[int]()
    a = newSinglyLinkedNode[int](3)
    b = newSinglyLinkedNode[int](7)
    c = newSinglyLinkedNode[int](9)

  l.append(a)
  l.append(b)
  l.prepend(c)

  assert c.next == a
  assert a.next == b
  assert c.next.next == b
  assert b.next == c
  assert c.next.next.next == c



## # See also
##
## * `deques module <#deques.html>`_ for double-ended queues
## * `sharedlist module <#sharedlist.html>`_ for shared singly-linked lists
