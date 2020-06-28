
discard """
   output: '''
test1 OK
'''
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

proc test1() =
  var list: ForwardList[int]
  list.pushFront(1)
  doAssert list.len == 1
  echo "test1 OK"

test1()

#------------------------------------------------------------------------------
# issue #14217

type
  MyObject = object
    p: ptr int

proc `=destroy`(x: var MyObject) =
  if x.p != nil:
    deallocShared(x.p)

proc `=`(x: var MyObject, y: MyObject) {.error.}

proc newMyObject(i: int): MyObject = 
  result.p = create(int)
  result.p[] = i

proc test: seq[MyObject] = 
  for i in 0..3:
    let x = newMyObject(i)
    result.add x

var x = test()
for i in 0..3:
  doAssert(x[i].p[] == i)
