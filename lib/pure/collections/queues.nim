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
## a `Channel <channels.html>`_ instead.

proc englishOrdinal(n: SomeInteger): string =
  # Temporary proc. Needs to be moved somewhere else as it can be reused in
  # other places too.
  # If this accepted number strings instead and only gave out the letters it
  # would be more flexible, permitting things like 1.100.000th, 34,545,321st
  # but it would be harder and more error prone to use.
  let num = $n
  if num.len > 1 and num[^2] == '1':
    return num & "th"
  else:
    case num[^1]
    of '1': return num & "st"
    of '2': return num & "nd"
    of '3': return num & "rd"
    else: return num & "th"

import math

type
  Queue*[T] = object ## a queue
    data: seq[T]
    rd, wr, count, mask: int

{.deprecated: [TQueue: Queue].}

proc initQueue*[T](initialSize: int = 4): Queue[T] =
  ## creates a new queue. `initialSize` needs to be a power of 2.
  assert isPowerOfTwo(initialSize)
  result.mask = initialSize-1
  newSeq(result.data, initialSize)

proc len*[T](q: Queue[T]): int {.inline.}=
  ## returns the number of elements of `q`.
  result = q.count

proc low*[T](q: Queue[T]): int {.inline.}=
  ## returns the index of the oldest element of `q` (always 0).
  result = 0

proc high*[T](q: Queue[T]): int {.inline.}=
  ## returns the index of the last element inserted on `q` (equivalent to
  ## `q.len - 1`).
  result = q.count - 1

proc front*[T](q: Queue[T]): T {.inline.}=
  ## returns the oldest element of `q`. Equivalent to `q.pop()` but does not
  ## remove it from the queue.
  assert q.count > 0
  result = q.data[q.rd]

proc back*[T](q: Queue[T]): T {.inline.} =
  ## returns the newest element of `q` but does not remove it from the queue.
  assert q.count > 0
  result = q.data[q.wr - 1]

template xBoundsCheck(q, i) =
  # Bounds check for the array like acceses.
  when compileOption("boundChecks"):  # d:release should disable this.
    if i > q.high:  # x < q.low is taken care by the Natural parameter
      raise newException(IndexError,
                         "You tried to access the " & englishOrdinal(i+1) &
                         " element of the queue but it has only " &
                         $q.len &  " elements.")
  discard

proc `[]`*[T](q: Queue[T], i: Natural) : T {.inline.} =
  ## Acess the i-th element of `q` by order of insertion.
  ## q[0] is the oldest (the next one q.pop() will extract),
  ## q[^1] is the newest (last one added to the queue).
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]`*[T](q: var Queue[T], i: Natural): var T {.inline.} =
  ## Acess the i-th element of `q` and returns a mutable
  ## reference to it.
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]=`* [T] (q: var Queue[T], i: Natural, val : T) {.inline.} =
  ## Change the i-th element of `q`.
  xBoundsCheck(q, i)
  q.data[q.rd + i and q.mask] = val

iterator items*[T](q: Queue[T]): T =
  ## yields every element of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator mitems*[T](q: var Queue[T]): var T =
  ## yields every element of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator pairs*[T](q: Queue[T]): tuple[key: int, val: T] =
  ## yields every (position, value) of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield (c, q.data[i])
    i = (i + 1) and q.mask

proc contains*[T](q: Queue[T], item: T): bool {.inline.} =
  ## Returns true if `item` is in `q` or false if not found. Usually used
  ## via the ``in`` operator. It is the equivalent of ``q.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains x
  for e in q:
    if e == item: return true
  return false

proc add*[T](q: var Queue[T], item: T) =
  ## adds an `item` to the end of the queue `q`.
  var cap = q.mask+1
  if q.count >= cap:
    var n {.noinit.} = newSeq[T](cap*2)
    for i, x in q:
      shallowCopy(n[i], x)  # does not use copyMem because the GC.
    shallowCopy(q.data, n)
    q.mask = cap*2 - 1
    q.wr = q.count
    q.rd = 0
  inc q.count
  q.data[q.wr] = item
  q.wr = (q.wr + 1) and q.mask

proc pop*[T](q: var Queue[T]): T =
  ## removes and returns the first (oldest) element of the queue `q`.
  assert q.count > 0
  dec q.count
  result = q.data[q.rd]
  q.rd = (q.rd + 1) and q.mask

proc enqueue*[T](q: var Queue[T], item: T) =
  ## alias for the ``add`` operation.
  q.add(item)

proc dequeue*[T](q: var Queue[T]): T =
  ## alias for the ``pop`` operation.
  q.pop()

proc `$`*[T](q: Queue[T]): string =
  ## turns a queue into its string representation.
  result = "["
  for x in q:
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

when isMainModule:
  var q = initQueue[int]()
  q.add(123)
  q.add(9)
  q.enqueue(4)
  var first = q.dequeue()
  q.add(56)
  q.add(6)
  var second = q.pop()
  q.add(789)

  assert first == 123
  assert second == 9
  assert($q == "[4, 56, 6, 789]")

  assert q[0] == q.front and q.front == 4
  assert q[^1] == q.back and q.back == 789
  q[0] = 42
  q[^1] = 7
  assert q[q.low] == 42
  assert q[q.high] == 7

  assert 6 in q and 789 notin q
  assert q.find(6) >= 0
  assert q.find(789) < 0

  for i in -2 .. 10:
    if i in q:
      assert q.contains(i) and q.find(i) >= 0
    else:
      assert(not q.contains(i) and q.find(i) < 0)

  when compileOption("boundChecks"):
    try:
      echo q[99]
      assert false
    except IndexError:
      discard
