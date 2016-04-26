#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Nim Developers
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of a `queue`:idx:. The underlying implementation uses a single
## linked list and array of `elementsPerBucket` elements. 
## In multithreaded environment uses two-lock concurrent queue algorithm
## described in the
## `article <http://www.cs.rochester.edu/u/scott/papers/1996_PODC_queues.pdf>`_.

const MultiThreaded = compileOption("threads")

const arrayLimit = 100_000_000

when MultiThreaded:
  import locks

  template rptr(untyped): untyped = 
    ptr untyped

  template withLock(lock: Lock, body: untyped): untyped =
    acquire lock
    try:
      body
    finally:
      release lock

  template with2Lock(lock1: Lock, lock2: Lock, body: untyped): untyped =
    acquire lock1
    acquire lock2
    try:
      body
    finally:
      release lock2
      release lock1
else:
  template rptr(untyped): untyped = 
    ref untyped

  template withLock(lock: untyped, body: untyped): untyped =
    body

  template with2Lock(lock1: untyped, lock2: untyped, body: untyped): untyped =
    body
type
  ListNodeObj[T] = object
    next: ListNode[T]
    d: array[0..arrayLimit, T]

  ListNode[T] = rptr ListNodeObj[T]

when MultiThreaded:
  type QueueObj[T] = object
    head, tail: ListNode[T]
    hindex, tindex, count, length: int
    hlock, tlock: Lock
else:
  type QueueObj[T] = object
    head, tail: ListNode[T]
    hindex, tindex, count, length: int

when defined(nimdoc):
  type
    Queue*[T] = ptr QueueObj[T]
else:
  type
    Queue*[T] = rptr QueueObj[T]

{.deprecated: [TQueue: Queue].}

proc newListNode[T](count: int): ListNode[T] =
  when MultiThreaded:
    result = cast[ListNode[T]](allocShared0(sizeof(ListNode[T]) +
                                            sizeof(T) * count))
  else:
    result = cast[ListNode[T]](alloc0(sizeof(ListNode[T]) +
                                      sizeof(T) * count))

proc freeListNode[T](n: ListNode[T]) =
  when MultiThreaded:
    deallocShared(n)
  else:
    dealloc(cast[pointer](n))

proc initQueue*[T](elementsPerBucket: int = 64): Queue[T] =
  ## creates a new queue that is empty.

  assert elementsPerBucket <= arrayLimit

  when MultiThreaded:
    result = cast[Queue[T]](allocShared0(sizeof(QueueObj[T])))
  else:
    result = cast[Queue[T]](alloc0(sizeof(QueueObj[T])))

  result.head = newListNode[T](elementsPerBucket)
  result.count = elementsPerBucket
  result.tail = result.head

  when MultiThreaded:
    initLock result.hLock
    initLock result.tLock

proc deinitQueue*[T](q: Queue[T]) =
  ## frees memory allocated by queue.
  with2Lock(q.hLock, q.tLock) do:
    var s = q.head
    while s != nil:
      var t = s
      s = s.next
      freeListNode(t)
  when MultiThreaded:
    deallocShared(cast[pointer](q))
  else:
    dealloc(cast[pointer](q))

proc add*[T](q: Queue[T], v: T) =
  ## adds an ``v`` to the end of the queue ``q``.
  withLock(q.tLock) do:
    if q.tindex == q.count:
      q.tail.next = newListNode[T](q.count)
      q.tail = q.tail.next
      q.tindex = 0
    q.tail.d[q.tindex] = v
    inc(q.tindex)
    inc(q.length)

proc get*[T](q: Queue[T], v: var T): bool =
  ## removes and set ``v`` to the first element of the queue ``q``
  ## returns `true` if element was set and `false` otherwise.
  result = false
  withLock(q.hLock) do:
    if q.head == q.tail:
      if q.hindex < q.tindex:
        v = q.head.d[q.hindex]
        inc(q.hindex)
        dec(q.length)
        result = true
    else:
      if q.hindex == q.count:
        var s = q.head.next
        freeListNode(q.head)
        q.head = s
        q.hindex = 0
      v = q.head.d[q.hindex]
      inc(q.hindex)
      dec(q.length)
      result = true

proc enqueue*[T](q: Queue[T], v: T) =
  ## adds an ``v`` to the end of the queue ``q``.
  add(q, v)

proc dequeue*[T](q: Queue[T]): T =
  ## removes and returns the first element of the queue ``q``.
  ## If queue is empty, assert exception is raised
  assert q.length > 0
  discard get(q, result)

proc push*[T](q: Queue[T], v: T) =
  ## adds an ``v`` to the end of the queue ``q``.
  enqueue(q, T)

proc pop*[T](q: Queue[T]): T =
  ## removes and returns the first element of the queue ``q``.
  ## If queue is empty, the ``ValueError`` exception is raised.
  if not get(q, result):
    raise newException(ValueError, "Queue is empty")

proc len*[T](q: Queue[T]): int =
  ## returns the number of elements of ``q``.
  result = q.length

iterator items*[T](q: Queue[T]): T =
  ## yields every element of ``q``.
  withLock(q.hLock) do:
    var s = q.head
    while s != nil:
      var c = q.hindex
      if s == q.tail:
        while c < q.tindex:
          yield s.d[c]
          inc(c)
      else:
        while c < q.count:
          yield s.d[c]
          inc(c)
      s = s.next

iterator mitems*[T](q: Queue[T]): var T =
  ## yields every element of ``q``.
  withLock(q.hLock) do:
    var s = q.head
    while s != nil:
      var c = q.hindex
      if s == q.tail:
        while c < q.tindex:
          yield s.d[c]
          inc(c)
      else:
        while c < q.count:
          yield s.d[c]
          inc(c)
      s = s.next

proc `$`*[T](q: Queue[T]): string =
  ## turns a queue into its string representation.
  result = "["
  for x in items(q):
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

when isMainModule:
  var nq = initQueue[int](2)
  nq.enqueue(1)
  nq.enqueue(2)
  nq.enqueue(3)
  nq.enqueue(4)
  nq.enqueue(5)

  assert($nq == "[1, 2, 3, 4, 5]")

  var r = false
  var a = nq.pop()
  a = nq.pop()
  a = nq.pop()
  a = nq.pop()
  a = nq.pop()
  try:
    a = nq.pop()
  except ValueError:
    r = true
  deinitQueue(nq)

  var oq = initQueue[int]()
  oq.add(123)
  oq.add(9)
  oq.add(4)
  var first = oq.dequeue
  oq.add(56)
  oq.add(6)
  var second = oq.dequeue
  oq.add(789)

  assert first == 123
  assert second == 9
  assert($oq == "[4, 56, 6, 789]")

  deinitQueue(oq)

  r = false
  try:
    var tq = initQueue[int](arrayLimit + 1)
    deinitQueue(tq)
  except AssertionError:
    r = true
  assert r

