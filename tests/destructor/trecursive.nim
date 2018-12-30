 
discard """
   output: 1
"""
import smart_ptr

type
  Node[T] = object
    value: T
    next: SharedPtr[Node[T]]

  ForwardList[T] = object
    first: SharedPtr[Node[T]]
    len: Natural

proc pushFront*[T] (list: var ForwardList[T], val: sink T) =
  var newNode = newSharedPtr(Node[T](value: val))
  var result = false
  while not result:
    var head = list.first
    newNode.get.next = head
    result = list.first.cas(head, newNode)
  list.len.atomicInc()

proc test = 
  var list: ForwardList[int]
  list.pushFront(1)
  echo list.len

test()