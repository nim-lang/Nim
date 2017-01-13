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
##   import random
##   var
##     aDeq = @[1,2,3,4,5].toDeque
##     randDeq = newDequeWith(10, random(100))  # deque of 10 random numbers
##
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
  ## Create a new Deque.
  ##
  ## Optionally, the initial capacity can be reserved via ``initialSize`` as a
  ## performance optimization. The length of a newly created deque will still
  ## be 0.
  ##
  ## For initialisation with multiple values, use
  ## `toDeque() <#toDeque>`_
  ## or `newDequeWith() <#newDequeWith>`_
  let sz = nextPowerOfTwo(initialSize)
  result.mask = sz-1
  newSeq(result.data, sz)

proc len*[T](deq: Deque[T]): int {.inline.} =
  ## Return the number of elements of ``deq``.
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
  ## Access the ``i``-th element of ``deq`` by order from first to last.
  ## ``deq[0]`` is the first, ``deq[^1]`` is the last.
  xBoundsCheck(deq, i)
  return deq.data[(deq.head + i) and deq.mask]

proc `[]`*[T](deq: var Deque[T], i: Natural): var T {.inline.} =
  ## Access the ``i``-th element of ``deq`` and returns a mutable
  ## reference to it.
  xBoundsCheck(deq, i)
  return deq.data[(deq.head + i) and deq.mask]

proc `[]=`* [T] (deq: var Deque[T], i: Natural, val : T) {.inline.} =
  ## Change the ``i``-th element of ``deq``.
  xBoundsCheck(deq, i)
  deq.data[(deq.head + i) and deq.mask] = val

iterator items*[T](deq: Deque[T]): T =
  ## Yield every element of ``deq`` (immutable).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @[1,2,3,4,5].toDeque
  ##   for v in deq.items:
  ##     echo v
  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

iterator mitems*[T](deq: var Deque[T]): var T =
  ## Yield every element of ``deq`` (can be modified).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @[1,2,3,4,5].toDeque
  ##   for v in deq.mitems:
  ##     v += 2
  ##   # deq -> [3,4,5,6,7]
  var i = deq.head
  for c in 0 ..< deq.count:
    yield deq.data[i]
    i = (i + 1) and deq.mask

template pairImpl() {.dirty.} =
  var i = deq.head
  for c in 0 ..< deq.count:
    yield (c, deq.data[i])
    i = (i + 1) and deq.mask

iterator pairs*[T](deq: Deque[T]): tuple[key: int, val: T] =
  ## Yield every ``(position, value)`` of ``deq`` (immutable).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @[1,2,3,4,5].toDeque
  ##   for i, v in deq.paris:
  ##     echo "Index: ", i, " value: ", v
  pairImpl()

iterator mpairs*[T](deq: var Deque[T]): tuple[key: int, val: var T] =
  ## Yield every ``(position, value)`` of ``deq``, where value
  ## can be modified.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @[1,2,3,4,5].toDeque
  ##   for i, v in deq.mpairs:
  ##     if i == 2:
  ##       v += 2
  ##   # deq -> [1,2,5,4,5]
  pairImpl()

proc contains*[T](deq: Deque[T], item: T): bool {.inline.} =
  ## Return ``true`` if ``item`` is in ``deq`` or ``false`` if not found.
  ## Usually used via the ``in`` operator. It is the equivalent
  ## of ``deq.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains x
  for e in deq:
    if e == item: return true
  return false

iterator findAll*[T](deq: Deque[T], item: T): int =
  ## Iterate over ``deq``, yielding the index of
  ## each element that matches ``item``.
  for i, v in pairs(deq):
    if v == item: yield(i)

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
  ## Add an ``item`` to the beginning of the ``deq``.
  expandIfNeeded(deq)
  inc deq.count
  deq.head = (deq.head - 1) and deq.mask
  deq.data[deq.head] = item

proc addLast*[T](deq: var Deque[T], item: T) =
  ## Add an ``item`` to the end of the ``deq``.
  expandIfNeeded(deq)
  inc deq.count
  deq.data[deq.tail] = item
  deq.tail = (deq.tail + 1) and deq.mask

proc peekFirst*[T](deq: Deque[T]): T {.inline.}=
  ## Returns the first element of ``deq``, but does not remove it
  ## from the deque.
  emptyCheck(deq)
  result = deq.data[deq.head]

proc peekLast*[T](deq: Deque[T]): T {.inline.} =
  ## Returns the last element of ``deq``,
  ## but does not remove it from the deque.
  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc popFirst*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the first element of the ``deq``.
  emptyCheck(deq)
  dec deq.count
  result = deq.data[deq.head]
  deq.data[deq.head] = default(type(result))
  deq.head = (deq.head + 1) and deq.mask

proc popLast*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Remove and returns the last element of the ``deq``.
  emptyCheck(deq)
  dec deq.count
  deq.tail = (deq.tail - 1) and deq.mask
  result = deq.data[deq.tail]
  deq.data[deq.tail] = default(type(result))

proc `$`*[T](deq: Deque[T]): string =
  ## Return the string representation of ``deq``,
  ## with the elements enclosed in square brackets ``[]``
  result = "["
  for x in deq:
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

proc `==`*[T](a, b: Deque[T]): bool {.inline.} =
  ## Return ``true`` if the elements and their order match.
  if a.count != b.count: return false
  for i in 0..<a.len:
    if a[i] != b[i]: return false
  result = true


proc toSeq*[T](deq: Deque[T]): seq[T] {.inline.} =
  ## Return a the elements of ``deq`` as a sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var
  ##     deq = @[1,2,3,4,5].toDeque
  ##     sq = deq.toSeq
  result = newSeq[T](deq.count)
  var i = deq.head
  for c in 0 ..< deq.count:
    result[c] = deq.data[i]
    i = (i + 1) and deq.mask

proc toDeque*[T](s: seq[T]): Deque[T] {.inline.} =
  ## Return the elements of sequence ``s`` as a ``Dequeu``.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var
  ##     deq = @[1,2,3,4,5].toDeque
  let slen = s.len
  result = initDeque[T](slen)
  result.data.setLen(nextPowerOfTwo(slen))
  for i,x in s.pairs:
    result.data[i] = x
  result.count = slen
  result.tail = slen

template newDequeWith*(len: int, init: untyped): untyped =
  ## Creates a new ``Deque``, calling ``init`` to initialize each value.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   import random
  ##   var deq = newDequeWith(20, random(10))
  ##   echo deq
  var result = initDeque[type(init)]()
  for i in 0 .. <len:
    result.addLast(init)
  result

proc map*[T, S](deq: Deque[T], op: proc (x: T): S {.closure.}): Deque[S]
               {.inline.} =
  ## Returns a new ``Deque[S]`` with the results of ``op`` applied
  ## to every item in ``deq[T]``.
  ##
  ## Since the input is not modified, you can use this version of ``map`` to
  ## transform the type of the elements in the input sequence.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     deq1 = @[1, 2, 3, 4].toDeque()
  ##     deq2 = deq1.map(proc(x: int): string = $x)
  ##   assert deq2 == @["1", "2", "3", "4"].toDeque()
  result = initDeque[S]()
  for x in deq.items:
    result.addLast(op(x))

proc apply*[T](deq: var Deque[T],
               op: proc (x: var T) {.closure.}
               ) {.inline.} =
  ## Applies ``op`` to every item in ``deq`` by modifying ``deq`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @["1", "2", "3", "4"].toDeque
  ##   deq.apply(proc(x: var string) = x &= "42")
  ##   # deq --> ["142", "242", "342", "442"]
  ##
  for v in deq.mitems: op(v)

proc apply*[T](deq: var Deque[T],
               op: proc (x: T): T {.closure.}
               ) {.inline.} =
  ## Applies ``op`` to every item in ``deq`` by modifying ``deq`` directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``T`` type parameter.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var deq = @["1", "2", "3", "4"].toDeque
  ##   deq.apply(proc(x: string): string = x & "42")
  ##   # deq --> ["142", "242", "342", "442"]
  ##
  for v in deq.mitems: v = op(v)

when isMainModule:
  var deq = initDeque[int](1)
  deq.addLast(4)
  deq.addFirst(9)
  deq.addFirst(123)
  deq.addLast(8)
  doAssert(deq.toSeq == @[123,9,4,8])
  discard deq.popLast()
  var first = deq.popFirst()
  deq.addLast(56)
  doAssert(deq.peekLast() == 56)
  deq.addLast(6)
  doAssert(deq.peekLast() == 6)
  var second = deq.popFirst()
  deq.addLast(789)
  doAssert(deq.peekLast() == 789)

  doAssert first == 123
  doAssert second == 9
  doAssert($deq == "[4, 56, 6, 789]")

  doAssert deq[0] == deq.peekFirst and deq.peekFirst == 4
  doAssert deq[^1] == deq.peekLast and deq.peekLast == 789
  deq[0] = 42
  deq[^1] = 7

  doAssert 6 in deq and 789 notin deq
  doAssert deq.find(6) >= 0
  doAssert deq.find(789) < 0

  for i in -2 .. 10:
    if i in deq:
      doAssert deq.contains(i) and deq.find(i) >= 0
    else:
      doAssert(not deq.contains(i) and deq.find(i) < 0)

  when compileOption("boundChecks"):
    try:
      echo deq[99]
      doAssert false
    except IndexError:
      discard

    try:
      doAssert deq.len == 4
      for i in 0 ..< 5: deq.popFirst()
      doAssert false
    except IndexError:
      discard

  # grabs some types of resize error.
  deq = initDeque[int]()
  for i in 1 .. 4: deq.addLast i
  deq.popFirst()
  deq.popLast()
  for i in 5 .. 8: deq.addFirst i
  doAssert $deq == "[8, 7, 6, 5, 2, 3]"

  # Similar to proc from the documentation example
  proc foo(a, b: Positive) = # assume random positive values for `a` and `b`.
    var deq = initDeque[int]()
    doAssert deq.len == 0
    for i in 1 .. a: deq.addLast i

    if b < deq.len: # checking before indexed access.
      doAssert deq[b] == b + 1

    # The following two lines don't need any checking on access due to the logic
    # of the program, but that would not be the case if `a` could be 0.
    doAssert deq.peekFirst == 1
    doAssert deq.peekLast == a

    while deq.len > 0: # checking if the deque is empty
      doAssert deq.popFirst() > 0

  #foo(0,0)
  foo(8,5)
  foo(10,9)
  foo(1,1)
  foo(2,1)
  foo(1,5)
  foo(3,2)

  # toSeq/toDeque/newDequeWith
  from random import random
  var
    d1 = newDequeWith(10, random(10))
    d2 = @[5,4,3,2,1].toDeque
    cnt = 0
  doAssert(d1.len == 10)
  for val in d1.items:
    cnt += val
  doAssert(cnt < 100)
  doAssert(d2.toSeq == @[5,4,3,2,1])
  doAssert(d2 == @[5,4,3,2,1].toDeque)
  cnt = 0
  for val in d2.items:
    cnt += val
  doAssert(cnt == 15)

  # pairs/mpairs
  cnt = 0
  for i,val in d1.pairs:
    cnt += i
  doAssert(cnt == 45)
  cnt = 0
  for i,val in d2.pairs:
    cnt += val
  doAssert(cnt == 15)
  cnt = 0
  for i,val in d2.mpairs:
    cnt += i+1
    val = 2
  doAssert(cnt == 15)
  doAssert(d2.toSeq == @[2,2,2,2,2])

  # apply
  var deq1 = @["1", "2", "3", "4"].toDeque
  deq1.apply(proc(x: var string) = x &= "42")
  doAssert(deq1.toSeq == @["142", "242", "342", "442"])

  deq1 = @["1", "2", "3", "4"].toDeque()
  deq1.apply(proc(x: string): string = x & "42")
  doAssert(deq1.toSeq == @["142", "242", "342", "442"])

  let
    deq2 = @[1, 2, 3, 4].toDeque()
    deq3 = deq2.map(proc(x: int): string = $x)
  doAssert(deq3 == @["1", "2", "3", "4"].toDeque)

  # ==
  discard d2.popFirst()
  d2.addLast(2)
  doAssert(d2 == @[2,2,2,2,2].toDeque)
  doAssert(deq == @[8,7,6,5,2,3].toDeque)
  doAssert(deq != @[8,0,6,5,2,3].toDeque)

  var res: seq[int] = @[]
  for v in (@[12,13,11,12,11].toDeque).findAll(11):
    res.add(v)
  doAssert(res == @[2,4])
