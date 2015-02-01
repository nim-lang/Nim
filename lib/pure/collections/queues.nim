#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of a `queue`:idx:. The underlying implementation uses a ``seq``.
## Note: For inter thread communication use
## a `TChannel <channels.html>`_ instead.

import math

type
  Queue*[T] = object ## a queue
    data: seq[T]
    rd, wr, count, mask: int

{.deprecated: [TQueue: Queue].}

proc initQueue*[T](initialSize=4): Queue[T] =
  ## creates a new queue. `initialSize` needs to be a power of 2.
  assert isPowerOfTwo(initialSize)
  result.mask = initialSize-1
  newSeq(result.data, initialSize)

proc len*[T](q: Queue[T]): int =
  ## returns the number of elements of `q`.
  result = q.count

iterator items*[T](q: Queue[T]): T =
  ## yields every element of `q`.
  var i = q.rd
  var c = q.count
  while c > 0:
    dec c
    yield q.data[i]
    i = (i + 1) and q.mask

iterator mitems*[T](q: var Queue[T]): var T =
  ## yields every element of `q`.
  var i = q.rd
  var c = q.count
  while c > 0:
    dec c
    yield q.data[i]
    i = (i + 1) and q.mask

proc add*[T](q: var Queue[T], item: T) =
  ## adds an `item` to the end of the queue `q`.
  var cap = q.mask+1
  if q.count >= cap:
    var n: seq[T]
    newSeq(n, cap*2)
    var i = 0
    for x in items(q):
      shallowCopy(n[i], x)
      inc i
    shallowCopy(q.data, n)
    q.mask = cap*2 - 1
    q.wr = q.count
    q.rd = 0
  inc q.count
  q.data[q.wr] = item
  q.wr = (q.wr + 1) and q.mask

proc enqueue*[T](q: var Queue[T], item: T) =
  ## alias for the ``add`` operation.
  add(q, item)

proc dequeue*[T](q: var Queue[T]): T =
  ## removes and returns the first element of the queue `q`.
  assert q.count > 0
  dec q.count
  result = q.data[q.rd]
  q.rd = (q.rd + 1) and q.mask

proc `$`*[T](q: Queue[T]): string = 
  ## turns a queue into its string representation.
  result = "["
  for x in items(q):
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

when isMainModule:
  var q = initQueue[int]()
  q.add(123)
  q.add(9)
  q.add(4)
  var first = q.dequeue
  q.add(56)
  q.add(6)
  var second = q.dequeue
  q.add(789)
  
  assert first == 123
  assert second == 9
  assert($q == "[4, 56, 6, 789]")

