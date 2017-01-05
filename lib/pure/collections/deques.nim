#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of a `deque`:idx: (double-ended queue).
## The underlying implementation uses a ``seq``.
##
## None of the procs that get an individual value from the deque can be used
## on an empty deque.
## If compiled with `boundChecks` option, those procs will raise an `IndexError`
## on such access. This should not be relied upon, as `-d:release` will
## disable those checks and may return garbage or crash the program.
##
## As such, a check to see if the deque is empty is needed before any
## access, unless your program logic guarantees it indirectly.
##
## .. code-block:: Nim
##   proc foo(a, b: Positive) =  # assume random positive values for `a` and `b`
##     var deq = initDeque[int]()  # initializes the object
##     for i in 1 ..< a: deq.addLast i  # populates the deque
##
##     if b < deq.len:  # checking before indexed access
##       echo "The element at index position ", b, " is ", deq[b]
##
##     # The following two lines don't need any checking on access due to the
##     # logic of the program, but that would not be the case if `a` could be 0.
##     assert deq.peekFirst == 1
##     assert deq.peekLast == a
##
##     while deq.len > 0:  # checking if the deque is empty
##       echo deq.removeLast()
##
## Note: For inter thread communication use
## a `Channel <channels.html>`_ instead.

import math

type
  Deque*[T] = object
    ## A double-ended queue backed with a ringed seq buffer.
    data: seq[T]
    head, tail, count, mask: int

proc initDeque*[T](initialSize: int = 4): Deque[T] =
  ## Create a new deque.
  ## Optionally, the initial capacity can be reserved via `initialSize` as a
  ## performance optimization. The length of a newly created deque will still
  ## be 0.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module.
  assert isPowerOfTwo(initialSize)
  result.mask = initialSize-1
  newSeq(result.data, initialSize)

proc len*[T](deq: Deque[T]): int {.inline.} =
  ## Return the number of elements of `deq`.
  result = deq.count

template emptyCheck(deq) =
  # Bounds check for the regular deque access.
  when compileOption("boundChecks"):
    if unlikely(deq.count < 1):
      raise newException(IndexError, "Empty deque.")

template xBoundsCheck(deq, i) =
  # Bounds check for the array like accesses.
  when compileOption("boundChecks"):  # d:release should disable this.
    if unlikely(i >= deq.count):  # x < deq.low is taken care by the Natural parameter
      raise newException(IndexError,
                         "Out of bounds: " & $i & " > " & $(deq.count - 1))

proc `[]`*[T](deq: Deque[T], i: Natural) : T {.inline.} =
  ## Access the i-th element of `deq` by order from first to last.
  ## deq[0] is the first, deq[^1] is the last.
  xBoundsCheck(deq, i)
  return deq.data[(deq.first + i) and deq.mask]

proc `[]`*[T](deq: var Deque[T], i: Natural): var T {.inline.} =
  ## Access the i-th element of `deq` and returns a mutable
  ## reference to it.
  xBoundsCheck(deq, i)
  return deq.data[(deq.head + i) and deq.mask]

proc `[]=`* [T] (deq: var Deque[T], i: Natural, val : T) {.inline.} =
  ## Change the i-th element of `deq`.
  xBoundsCheck(deq, i)
  deq.data[(deq.head + i) and deq.mask] = val

iterator items*[T](deq: Deque[T]): T =
  ## Yield every element of `deq`.
  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

iterator mitems*[T](deq: var Deque[T]): var T =
  ## Yield every element of `deq`.
  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

iterator pairs*[T](deq: Deque[T]): tuple[key: int, val: T] =
  ## Yield every (position, value) of `deq`.
  var i = deq.head
  for c in 0 ..< deq.count:
    yield (c, deq.data[i])
    i = (i + 1) and deq.mask

proc contains*[T](deq: Deque[T], item: T): bool {.inline.} =
  ## Return true if `item` is in `deq` or false if not found. Usually used
  ## via the ``in`` operator. It is the equivalent of ``deq.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains x
  for e in deq:
    if e == item: return true
  return false

proc expandIfNeeded[T](deq: var Deque[T]) =
  var cap = deq.mask + 1
  if unlikely(deq.count >= cap):
    var n = newSeq[T](cap * 2)
    for i, x in deq:  # don't use copyMem because the GC and because it's slower.
      shallowCopy(n[i], x)
    shallowCopy(deq.data, n)
    deq.mask = cap * 2 - 1
    deq.tail = deq.count
    deq.head = 0

proc addFirst*[T](deq: var Deque[T], item: T) =
  ## Add an `item` to the beginning of the `deq`.
  expandIfNeeded(deq)
  inc deq.count
  deq.head = (deq.head - 1) and deq.mask
  deq.data[deq.head] = item

proc addLast*[T](deq: var Deque[T], item: T) =
  ## Add an `item` to the end of the `deq`.
  expandIfNeeded(deq)
  inc deq.count
  deq.data[deq.tail] = item
  deq.tail = (deq.tail + 1) and deq.mask

proc peekFirst*[T](deq: Deque[T]): T {.inline.}=
  ## Returns the first element of `deq`, but does not remove it from the deque.
  emptyCheck(deq)
  result = deq.data[deq.head]

proc peekLast*[T](deq: Deque[T]): T {.inline.} =
  ## Returns the last element of `deq`, but does not remove it from the deque.
  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc popFirst*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the first element of the `deq`.
  emptyCheck(deq)
  dec deq.count
  result = deq.data[deq.head]
  deq.data[deq.head] = default(type(result))
  deq.head = (deq.head + 1) and deq.mask

proc popLast*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the last element of the `deq`.
  emptyCheck(deq)
  dec deq.count
  deq.tail = (deq.tail - 1) and deq.mask
  result = deq.data[deq.tail]
  deq.data[deq.tail] = default(type(result))

proc `$`*[T](deq: Deque[T]): string =
  ## Turn a deque into its string representation.
  result = "["
  for x in deq:
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

when isMainModule:
  var deq = initDeque[int](1)
  deq.addLast(4)
  deq.addFirst(9)
  deq.addFirst(123)
  var first = deq.popFirst()
  deq.addLast(56)
  assert(deq.peekLast() == 56)
  deq.addLast(6)
  assert(deq.peekLast() == 6)
  var second = deq.popFirst()
  deq.addLast(789)
  assert(deq.peekLast() == 789)

  assert first == 123
  assert second == 9
  assert($deq == "[4, 56, 6, 789]")

  assert deq[0] == deq.peekFirst and deq.peekFirst == 4
  assert deq[^1] == deq.peekLast and deq.peekLast == 789
  deq[0] = 42
  deq[^1] = 7

  assert 6 in deq and 789 notin deq
  assert deq.find(6) >= 0
  assert deq.find(789) < 0

  for i in -2 .. 10:
    if i in deq:
      assert deq.contains(i) and deq.find(i) >= 0
    else:
      assert(not deq.contains(i) and deq.find(i) < 0)

  when compileOption("boundChecks"):
    try:
      echo deq[99]
      assert false
    except IndexError:
      discard

    try:
      assert deq.len == 4
      for i in 0 ..< 5: deq.popFirst()
      assert false
    except IndexError:
      discard

  # grabs some types of resize error.
  deq = initDeque[int]()
  for i in 1 .. 4: deq.addLast i
  deq.popFirst()
  deq.popLast()
  for i in 5 .. 8: deq.addFirst i
  assert $deq == "[8, 7, 6, 5, 2, 3]"

  # Similar to proc from the documentation example
  proc foo(a, b: Positive) = # assume random positive values for `a` and `b`.
    var deq = initDeque[int]()
    assert deq.len == 0
    for i in 1 .. a: deq.addLast i

    if b < deq.len: # checking before indexed access.
      assert deq[b] == b + 1

    # The following two lines don't need any checking on access due to the logic
    # of the program, but that would not be the case if `a` could be 0.
    assert deq.peekFirst == 1
    assert deq.peekLast == a

    while deq.len > 0: # checking if the deque is empty
      assert deq.popFirst() > 0

  #foo(0,0)
  foo(8,5)
  foo(10,9)
  foo(1,1)
  foo(2,1)
  foo(1,5)
  foo(3,2)