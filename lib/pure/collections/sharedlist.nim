#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Shared list support.
##
## Unstable API.

{.push stackTrace: off.}

import
  locks

const
  ElemsPerNode = 100

type
  SharedListNode[A] = ptr object
    next: SharedListNode[A]
    dataLen: int
    d: array[ElemsPerNode, A]

  SharedList*[A] = object ## generic shared list
    head, tail: SharedListNode[A]
    lock*: Lock

template withLock(t, x: untyped) =
  acquire(t.lock)
  x
  release(t.lock)

proc iterAndMutate*[A](x: var SharedList[A]; action: proc(x: A): bool) =
  ## Iterates over the list. If `action` returns true, the
  ## current item is removed from the list.
  ##
  ## .. warning:: It may not preserve the element order after some modifications.
  withLock(x):
    var n = x.head
    while n != nil:
      var i = 0
      while i < n.dataLen:
        # action can add new items at the end, so release the lock:
        release(x.lock)
        if action(n.d[i]):
          acquire(x.lock)
          let t = x.tail
          dec t.dataLen # TODO considering t.dataLen == 0,
                        # probably the module should be refactored using doubly linked lists
          n.d[i] = t.d[t.dataLen]
        else:
          acquire(x.lock)
          inc i
      n = n.next

iterator items*[A](x: var SharedList[A]): A =
  withLock(x):
    var it = x.head
    while it != nil:
      for i in 0..it.dataLen-1:
        yield it.d[i]
      it = it.next

proc add*[A](x: var SharedList[A]; y: A) =
  withLock(x):
    var node: SharedListNode[A]
    if x.tail == nil:
      node = cast[typeof node](allocShared0(sizeof(node[])))
      x.tail = node
      x.head = node
    elif x.tail.dataLen == ElemsPerNode:
      node = cast[typeof node](allocShared0(sizeof(node[])))
      x.tail.next = node
      x.tail = node
    else:
      node = x.tail
    node.d[node.dataLen] = y
    inc(node.dataLen)

proc init*[A](t: var SharedList[A]) =
  initLock t.lock
  t.head = nil
  t.tail = nil

proc clear*[A](t: var SharedList[A]) =
  withLock(t):
    var it = t.head
    while it != nil:
      let nxt = it.next
      deallocShared(it)
      it = nxt
    t.head = nil
    t.tail = nil

proc deinitSharedList*[A](t: var SharedList[A]) =
  clear(t)
  deinitLock t.lock

{.pop.}
