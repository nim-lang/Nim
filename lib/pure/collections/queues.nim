#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of a `queue`:idx:. The underlying implementation uses a ``seq``.
##
## None of the procs that get an individual value from the queue can be used
## on an empty queue.
## If compiled with `boundChecks` option, those procs will raise an `IndexError`
## on such access. This should not be relied upon, as `-d:release` will
## disable those checks and may return garbage or crash the program.
##
## As such, a check to see if the queue is empty is needed before any
## access, unless your program logic guarantees it indirectly.
##
## .. code-block:: Nim
##   proc foo(a, b: Positive) =  # assume random positive values for `a` and `b`
##     var q = initQueue[int]()  # initializes the object
##     for i in 1 ..< a: q.add i  # populates the queue
##
##     if b < q.len:  # checking before indexed access
##       echo "The element at index position ", b, " is ", q[b]
##
##     # The following two lines don't need any checking on access due to the
##     # logic of the program, but that would not be the case if `a` could be 0.
##     assert q.front == 1
##     assert q.back == a
##
##     while q.len > 0:  # checking if the queue is empty
##       echo q.pop()
##
## Note: For inter thread communication use
## a `Channel <channels.html>`_ instead.

import math

{.warning: "`queues` module is deprecated - use `deques` instead".}

type
  Queue* {.deprecated.} [T] = object ## A queue.
    data: seq[T]
    rd, wr, count, mask: int

{.deprecated: [TQueue: Queue].}

proc initQueue*[T](initialSize: int = 4): Queue[T] =
  ## Create a new queue.
  ## Optionally, the initial capacity can be reserved via `initialSize` as a
  ## performance optimization. The length of a newly created queue will still
  ## be 0.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module.
  assert isPowerOfTwo(initialSize)
  result.mask = initialSize-1
  newSeq(result.data, initialSize)

proc len*[T](q: Queue[T]): int {.inline.}=
  ## Return the number of elements of `q`.
  result = q.count

template emptyCheck(q) =
  # Bounds check for the regular queue access.
  when compileOption("boundChecks"):
    if unlikely(q.count < 1):
      raise newException(IndexError, "Empty queue.")

template xBoundsCheck(q, i) =
  # Bounds check for the array like accesses.
  when compileOption("boundChecks"):  # d:release should disable this.
    if unlikely(i >= q.count):  # x < q.low is taken care by the Natural parameter
      raise newException(IndexError,
                         "Out of bounds: " & $i & " > " & $(q.count - 1))

proc front*[T](q: Queue[T]): T {.inline.}=
  ## Return the oldest element of `q`. Equivalent to `q.pop()` but does not
  ## remove it from the queue.
  emptyCheck(q)
  result = q.data[q.rd]

proc back*[T](q: Queue[T]): T {.inline.} =
  ## Return the newest element of `q` but does not remove it from the queue.
  emptyCheck(q)
  result = q.data[q.wr - 1 and q.mask]

proc `[]`*[T](q: Queue[T], i: Natural) : T {.inline.} =
  ## Access the i-th element of `q` by order of insertion.
  ## q[0] is the oldest (the next one q.pop() will extract),
  ## q[^1] is the newest (last one added to the queue).
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]`*[T](q: var Queue[T], i: Natural): var T {.inline.} =
  ## Access the i-th element of `q` and returns a mutable
  ## reference to it.
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]=`* [T] (q: var Queue[T], i: Natural, val : T) {.inline.} =
  ## Change the i-th element of `q`.
  xBoundsCheck(q, i)
  q.data[q.rd + i and q.mask] = val

iterator items*[T](q: Queue[T]): T =
  ## Yield every element of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator mitems*[T](q: var Queue[T]): var T =
  ## Yield every element of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator pairs*[T](q: Queue[T]): tuple[key: int, val: T] =
  ## Yield every (position, value) of `q`.
  var i = q.rd
  for c in 0 ..< q.count:
    yield (c, q.data[i])
    i = (i + 1) and q.mask

proc contains*[T](q: Queue[T], item: T): bool {.inline.} =
  ## Return true if `item` is in `q` or false if not found. Usually used
  ## via the ``in`` operator. It is the equivalent of ``q.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains x
  for e in q:
    if e == item: return true
  return false

proc add*[T](q: var Queue[T], item: T) =
  ## Add an `item` to the end of the queue `q`.
  var cap = q.mask+1
  if unlikely(q.count >= cap):
    var n = newSeq[T](cap*2)
    for i, x in q:  # don't use copyMem because the GC and because it's slower.
      shallowCopy(n[i], x)
    shallowCopy(q.data, n)
    q.mask = cap*2 - 1
    q.wr = q.count
    q.rd = 0
  inc q.count
  q.data[q.wr] = item
  q.wr = (q.wr + 1) and q.mask

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc pop*[T](q: var Queue[T]): T {.inline, discardable.} =
  ## Remove and returns the first (oldest) element of the queue `q`.
  emptyCheck(q)
  dec q.count
  result = q.data[q.rd]
  q.data[q.rd] = default(type(result))
  q.rd = (q.rd + 1) and q.mask

proc enqueue*[T](q: var Queue[T], item: T) =
  ## Alias for the ``add`` operation.
  q.add(item)

proc dequeue*[T](q: var Queue[T]): T =
  ## Alias for the ``pop`` operation.
  q.pop()

proc `$`*[T](q: Queue[T]): string =
  ## Turn a queue into its string representation.
  result = "["
  for x in items(q):  # Don't remove the items here for reasons that don't fit in this margin.
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

when isMainModule:
  var q = initQueue[int](1)
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

    try:
      assert q.len == 4
      for i in 0 ..< 5: q.pop()
      assert false
    except IndexError:
      discard

  # grabs some types of resize error.
  q = initQueue[int]()
  for i in 1 .. 4: q.add i
  q.pop()
  q.pop()
  for i in 5 .. 8: q.add i
  assert $q == "[3, 4, 5, 6, 7, 8]"

  # Similar to proc from the documentation example
  proc foo(a, b: Positive) = # assume random positive values for `a` and `b`.
    var q = initQueue[int]()
    assert q.len == 0
    for i in 1 .. a: q.add i

    if b < q.len: # checking before indexed access.
      assert q[b] == b + 1

    # The following two lines don't need any checking on access due to the logic
    # of the program, but that would not be the case if `a` could be 0.
    assert q.front == 1
    assert q.back == a

    while q.len > 0: # checking if the queue is empty
      assert q.pop() > 0

  #foo(0,0)
  foo(8,5)
  foo(10,9)
  foo(1,1)
  foo(2,1)
  foo(1,5)
  foo(3,2)
