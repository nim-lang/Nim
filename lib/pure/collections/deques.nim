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
## If compiled with `boundChecks` option, those procs will raise an `IndexDefect`
## on such access. This should not be relied upon, as `-d:release` will
## disable those checks and may return garbage or crash the program.
##
## As such, a check to see if the deque is empty is needed before any
## access, unless your program logic guarantees it indirectly.
##
## .. code-block:: Nim
##   import deques
##
##   var a = initDeque[int]()
##
##   doAssertRaises(IndexDefect, echo a[0])
##
##   for i in 1 .. 5:
##     a.addLast(10*i)
##   assert $a == "[10, 20, 30, 40, 50]"
##
##   assert a.peekFirst == 10
##   assert a.peekLast == 50
##   assert len(a) == 5
##
##   assert a.popFirst == 10
##   assert a.popLast == 50
##   assert len(a) == 3
##
##   a.addFirst(11)
##   a.addFirst(22)
##   a.addFirst(33)
##   assert $a == "[33, 22, 11, 20, 30, 40]"
##
##   a.shrink(fromFirst = 1, fromLast = 2)
##   assert $a == "[22, 11, 20]"
##
##
## **See also:**
## * `lists module <lists.html>`_ for singly and doubly linked lists and rings
## * `channels module <channels.html>`_ for inter-thread communication

import std/private/since

import math

type
  Deque*[T] = object
    ## A double-ended queue backed with a ringed seq buffer.
    ##
    ## To initialize an empty deque use `initDeque proc <#initDeque,int>`_.
    data: seq[T]
    head, tail, count, mask: int

const
  defaultInitialSize* = 4

template initImpl(result: typed, initialSize: int) =
  let correctSize = nextPowerOfTwo(initialSize)
  result.mask = correctSize-1
  newSeq(result.data, correctSize)

template checkIfInitialized(deq: typed) =
  when compiles(defaultInitialSize):
    if deq.mask == 0:
      initImpl(deq, defaultInitialSize)

proc initDeque*[T](initialSize: int = 4): Deque[T] =
  ## Create a new empty deque.
  ##
  ## Optionally, the initial capacity can be reserved via `initialSize`
  ## as a performance optimization.
  ## The length of a newly created deque will still be 0.
  ##
  ## See also:
  ## * `toDeque proc <#toDeque,openArray[T]>`_
  result.initImpl(initialSize)

proc toDeque*[T](x: openArray[T]): Deque[T] {.since: (1, 3).} =
  ## Creates a new deque that contains the elements of `x` (in the same order).
  ##
  ## See also:
  ## * `initDeque proc <#initDeque,int>`_
  runnableExamples:
    var a = toDeque([7, 8, 9])
    assert len(a) == 3
    assert a.popFirst == 7
    assert len(a) == 2

  result.initImpl(x.len)
  for item in items(x):
    result.addLast(item)

proc len*[T](deq: Deque[T]): int {.inline.} =
  ## Return the number of elements of `deq`.
  result = deq.count

template emptyCheck(deq) =
  # Bounds check for the regular deque access.
  when compileOption("boundChecks"):
    if unlikely(deq.count < 1):
      raise newException(IndexDefect, "Empty deque.")

template xBoundsCheck(deq, i) =
  # Bounds check for the array like accesses.
  when compileOption("boundChecks"): # d:release should disable this.
    if unlikely(i >= deq.count): # x < deq.low is taken care by the Natural parameter
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " > " & $(deq.count - 1))
    if unlikely(i < 0): # when used with BackwardsIndex
      raise newException(IndexDefect,
                         "Out of bounds: " & $i & " < 0")

proc `[]`*[T](deq: Deque[T], i: Natural): T {.inline.} =
  ## Access the i-th element of `deq`.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert a[0] == 10
    assert a[3] == 40
    doAssertRaises(IndexDefect, echo a[8])

  xBoundsCheck(deq, i)
  return deq.data[(deq.head + i) and deq.mask]

proc `[]`*[T](deq: var Deque[T], i: Natural): var T {.inline.} =
  ## Access the i-th element of `deq` and return a mutable
  ## reference to it.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert a[0] == 10
    assert a[3] == 40
    doAssertRaises(IndexDefect, echo a[8])

  xBoundsCheck(deq, i)
  return deq.data[(deq.head + i) and deq.mask]

proc `[]=`*[T](deq: var Deque[T], i: Natural, val: T) {.inline.} =
  ## Change the i-th element of `deq`.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    a[0] = 99
    a[3] = 66
    assert $a == "[99, 20, 30, 66, 50]"

  checkIfInitialized(deq)
  xBoundsCheck(deq, i)
  deq.data[(deq.head + i) and deq.mask] = val

proc `[]`*[T](deq: Deque[T], i: BackwardsIndex): T {.inline.} =
  ## Access the backwards indexed i-th element.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert a[^1] == 50
    assert a[^4] == 20
    doAssertRaises(IndexDefect, echo a[^9])

  xBoundsCheck(deq, deq.len - int(i))
  return deq[deq.len - int(i)]

proc `[]`*[T](deq: var Deque[T], i: BackwardsIndex): var T {.inline.} =
  ## Access the backwards indexed i-th element.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert a[^1] == 50
    assert a[^4] == 20
    doAssertRaises(IndexDefect, echo a[^9])

  xBoundsCheck(deq, deq.len - int(i))
  return deq[deq.len - int(i)]

proc `[]=`*[T](deq: var Deque[T], i: BackwardsIndex, x: T) {.inline.} =
  ## Change the backwards indexed i-th element.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    a[^1] = 99
    a[^3] = 77
    assert $a == "[10, 20, 77, 40, 99]"

  checkIfInitialized(deq)
  xBoundsCheck(deq, deq.len - int(i))
  deq[deq.len - int(i)] = x

iterator items*[T](deq: Deque[T]): T =
  ## Yield every element of `deq`.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   var a = initDeque[int]()
  ##   for i in 1 .. 3:
  ##     a.addLast(10*i)
  ##
  ##   for x in a:  # the same as: for x in items(a):
  ##     echo x
  ##
  ##   # 10
  ##   # 20
  ##   # 30
  ##
  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

iterator mitems*[T](deq: var Deque[T]): var T =
  ## Yield every element of `deq`, which can be modified.
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5*x - 1
    assert $a == "[49, 99, 149, 199, 249]"

  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

iterator pairs*[T](deq: Deque[T]): tuple[key: int, val: T] =
  ## Yield every (position, value) of `deq`.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   var a = initDeque[int]()
  ##   for i in 1 .. 3:
  ##     a.addLast(10*i)
  ##
  ##   for k, v in pairs(a):
  ##     echo "key: ", k, ", value: ", v
  ##
  ##   # key: 0, value: 10
  ##   # key: 1, value: 20
  ##   # key: 2, value: 30
  ##
  var i = deq.head
  for c in 0 ..< deq.count:
    yield (c, deq.data[i])
    i = (i + 1) and deq.mask

proc contains*[T](deq: Deque[T], item: T): bool {.inline.} =
  ## Return true if `item` is in `deq` or false if not found.
  ##
  ## Usually used via the ``in`` operator.
  ## It is the equivalent of ``deq.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains(x)
  for e in deq:
    if e == item: return true
  return false

proc expandIfNeeded[T](deq: var Deque[T]) =
  checkIfInitialized(deq)
  var cap = deq.mask + 1
  if unlikely(deq.count >= cap):
    var n = newSeq[T](cap * 2)
    var i = 0
    for x in mitems(deq):
      when nimVM: n[i] = x # workaround for VM bug
      else: n[i] = move(x)
      inc i
    deq.data = move(n)
    deq.mask = cap * 2 - 1
    deq.tail = deq.count
    deq.head = 0

proc addFirst*[T](deq: var Deque[T], item: T) =
  ## Add an `item` to the beginning of the `deq`.
  ##
  ## See also:
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addFirst(10*i)
    assert $a == "[50, 40, 30, 20, 10]"

  expandIfNeeded(deq)
  inc deq.count
  deq.head = (deq.head - 1) and deq.mask
  deq.data[deq.head] = item

proc addLast*[T](deq: var Deque[T], item: T) =
  ## Add an `item` to the end of the `deq`.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"

  expandIfNeeded(deq)
  inc deq.count
  deq.data[deq.tail] = item
  deq.tail = (deq.tail + 1) and deq.mask

proc peekFirst*[T](deq: Deque[T]): T {.inline.} =
  ## Returns the first element of `deq`, but does not remove it from the deque.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekFirst == 10
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[deq.head]

proc peekLast*[T](deq: Deque[T]): T {.inline.} =
  ## Returns the last element of `deq`, but does not remove it from the deque.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekLast == 50
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

proc peekFirst*[T](deq: var Deque[T]): var T {.inline, since: (1, 3).} =
  ## Returns the first element of `deq`, but does not remove it from the deque.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekFirst == 10
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[deq.head]

proc peekLast*[T](deq: var Deque[T]): var T {.inline, since: (1, 3).} =
  ## Returns the last element of `deq`, but does not remove it from the deque.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekLast == 50
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

template destroy(x: untyped) =
  reset(x)

proc popFirst*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the first element of the `deq`.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  ## * `clear proc <#clear,Deque[T]>`_
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.popFirst == 10
    assert $a == "[20, 30, 40, 50]"

  emptyCheck(deq)
  dec deq.count
  result = deq.data[deq.head]
  destroy(deq.data[deq.head])
  deq.head = (deq.head + 1) and deq.mask

proc popLast*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the last element of the `deq`.
  ##
  ## See also:
  ## * `addFirst proc <#addFirst,Deque[T],T>`_
  ## * `addLast proc <#addLast,Deque[T],T>`_
  ## * `peekFirst proc <#peekFirst,Deque[T]>`_
  ## * `peekLast proc <#peekLast,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `clear proc <#clear,Deque[T]>`_
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10*i)
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.popLast == 50
    assert $a == "[10, 20, 30, 40]"

  emptyCheck(deq)
  dec deq.count
  deq.tail = (deq.tail - 1) and deq.mask
  result = deq.data[deq.tail]
  destroy(deq.data[deq.tail])

proc clear*[T](deq: var Deque[T]) {.inline.} =
  ## Resets the deque so that it is empty.
  ##
  ## See also:
  ## * `clear proc <#clear,Deque[T]>`_
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addFirst(10*i)
    assert $a == "[50, 40, 30, 20, 10]"
    clear(a)
    assert len(a) == 0

  for el in mitems(deq): destroy(el)
  deq.count = 0
  deq.tail = deq.head

proc shrink*[T](deq: var Deque[T], fromFirst = 0, fromLast = 0) =
  ## Remove `fromFirst` elements from the front of the deque and
  ## `fromLast` elements from the back.
  ##
  ## If the supplied number of elements exceeds the total number of elements
  ## in the deque, the deque will remain empty.
  ##
  ## See also:
  ## * `clear proc <#clear,Deque[T]>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addFirst(10*i)
    assert $a == "[50, 40, 30, 20, 10]"
    a.shrink(fromFirst = 2, fromLast = 1)
    assert $a == "[30, 20]"

  if fromFirst + fromLast > deq.count:
    clear(deq)
    return

  for i in 0 ..< fromFirst:
    destroy(deq.data[deq.head])
    deq.head = (deq.head + 1) and deq.mask

  for i in 0 ..< fromLast:
    destroy(deq.data[deq.tail])
    deq.tail = (deq.tail - 1) and deq.mask

  dec deq.count, fromFirst + fromLast

proc `$`*[T](deq: Deque[T]): string =
  ## Turn a deque into its string representation.
  result = "["
  for x in deq:
    if result.len > 1: result.add(", ")
    result.addQuoted(x)
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
  assert deq == [4, 56, 6, 789].toDeque

  assert deq[0] == deq.peekFirst and deq.peekFirst == 4
  #assert deq[^1] == deq.peekLast and deq.peekLast == 789
  deq[0] = 42
  deq[deq.len - 1] = 7

  assert 6 in deq and 789 notin deq
  assert deq.find(6) >= 0
  assert deq.find(789) < 0

  block:
    var d = initDeque[int](1)
    d.addLast 7
    d.addLast 8
    d.addLast 10
    d.addFirst 5
    d.addFirst 2
    d.addFirst 1
    d.addLast 20
    d.shrink(fromLast = 2)
    doAssert($d == "[1, 2, 5, 7, 8]")
    d.shrink(2, 1)
    doAssert($d == "[5, 7]")
    d.shrink(2, 2)
    doAssert d.len == 0

  for i in -2 .. 10:
    if i in deq:
      assert deq.contains(i) and deq.find(i) >= 0
    else:
      assert(not deq.contains(i) and deq.find(i) < 0)

  when compileOption("boundChecks"):
    try:
      echo deq[99]
      assert false
    except IndexDefect:
      discard

    try:
      assert deq.len == 4
      for i in 0 ..< 5: deq.popFirst()
      assert false
    except IndexDefect:
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
  foo(8, 5)
  foo(10, 9)
  foo(1, 1)
  foo(2, 1)
  foo(1, 5)
  foo(3, 2)

  import sets
  block t13310:
    proc main() =
      var q = initDeque[HashSet[int16]](2)
      q.addFirst([1'i16].toHashSet)
      q.addFirst([2'i16].toHashSet)
      q.addFirst([3'i16].toHashSet)
      assert $q == "[{3}, {2}, {1}]"

    static:
      main()
