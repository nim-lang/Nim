#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of a `queue`:idx:, also called a FIFO or LILO buffer.
##
## The underlying implementation uses a ``seq``.
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
##     doAssert q.front == 1
##     doAssert q.back == a
##
##     while q.len > 0:  # checking if the queue is empty
##       echo q.pop()
##
## Note: For inter thread communication use
## a `Channel <channels.html>`_ instead.

from math import nextPowerOfTwo, isPowerOfTwo

{.warning: "`queues` module is deprecated - use `deques` instead".}

type
  Queue* {.deprecated.} [T] = object ## A queue.
    data: seq[T]
    rd, wr, count, mask: int

{.deprecated: [TQueue: Queue].}

proc initQueue*[T](initialSize: int = 4): Queue[T] =
  ## Create a new Queue.
  ##
  ## Optionally, the initial capacity can be reserved via ``initialSize`` as a
  ## performance optimization. The length of a newly created queue will still
  ## be 0.
  ##
  ## `Internally, the allocated size is nextPowerOfTwo(initialSize)`
  result.mask = nextPowerOfTwo(initialSize)-1
  newSeq(result.data, result.mask+1)

proc len*[T](q: Queue[T]): int {.inline.}=
  ## Return the number of elements of ``q``.
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
  ## Return the oldest element of ``q``. Equivalent to ``q.pop()`` but does not
  ## remove it from the queue.
  emptyCheck(q)
  result = q.data[q.rd]

proc back*[T](q: Queue[T]): T {.inline.} =
  ## Return the newest element of ``q`` but does not remove it from the queue.
  emptyCheck(q)
  result = q.data[q.wr - 1 and q.mask]

proc `[]`*[T](q: Queue[T], i: Natural) : T {.inline.} =
  ## Access the i-th element of ``q`` by order of insertion.
  ## ``q[0]`` is the oldest (the next one ``q.pop()`` will extract),
  ## ``q[^1]`` is the newest (last one added to the queue).
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]`*[T](q: var Queue[T], i: Natural): var T {.inline.} =
  ## Access the i-th element of ``q`` and returns a mutable
  ## reference to it.
  xBoundsCheck(q, i)
  return q.data[q.rd + i and q.mask]

proc `[]=`* [T] (q: var Queue[T], i: Natural, val : T) {.inline.} =
  ## Change the i-th element of ``q``.
  xBoundsCheck(q, i)
  q.data[q.rd + i and q.mask] = val

iterator items*[T](q: Queue[T]): T =
  ## Yield every element of ``q``.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator mitems*[T](q: var Queue[T]): var T =
  ## Yield every element of ``q``.
  var i = q.rd
  for c in 0 ..< q.count:
    yield q.data[i]
    i = (i + 1) and q.mask

iterator pairs*[T](q: Queue[T]): tuple[key: int, val: T] =
  ## Yield every (position, value) of ``q``.
  var i = q.rd
  for c in 0 ..< q.count:
    yield (c, q.data[i])
    i = (i + 1) and q.mask

proc contains*[T](q: Queue[T], item: T): bool {.inline.} =
  ## Return true if ``item`` is in ``q`` or false if not found. Usually used
  ## via the ``in`` operator. It is the equivalent of ``q.find(item) >= 0``.
  ##
  ## .. code-block:: Nim
  ##   if x in q:
  ##     assert q.contains x
  for e in q:
    if e == item: return true
  return false

proc add*[T](q: var Queue[T], item: T) =
  ## Add an ``item`` to the end of the Queue ``q``.
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

proc default[T](t: typedesc[T]): T {.inline.} = discard
proc pop*[T](q: var Queue[T]): T {.discardable.} =
  ## Remove and returns the first (oldest) element of the Queue ``q``.
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
  ## Return the string representation of the elements of ``q``
  ## (enclosed by ``[`` ``]``)
  result = "["
  for x in items(q):  # Don't remove the items here for reasons that don't fit in this margin.
    if result.len > 1: result.add(", ")
    result.add($x)
  result.add("]")

proc `==`*[T](a, b: Queue[T]): bool {.inline} =
  ## Returns ``true`` if Queues ``a`` and ``b`` contain equivalent data
  result = (a.data == b.data) and (a.rd == b.rd) and (a.count == b.count)

proc toSeq*[T](q: Queue[T]): seq[T] {.inline.} =
  ## Returns a copy of the elements of ``q`` as a sequence
  if q.count == 0: return @[]
  let wr = (q.wr - 1) and q.mask
  var i = 0
  if wr < q.rd:
    result = newSeq[T](q.len)
    for j in q.rd .. q.mask:
      result[i] = q.data[j]
      inc i
    for j in 0 .. wr:
      result[i] = q.data[j]
      inc i
  else:
    result = q.data[q.rd..wr]

proc toQueue*[T](s: seq[T]): Queue[T] {.inline.} =
  ## Returns the Queue containing a copy of the elements of sequence or array ``s``
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toQueue()
  ##   echo a
  ##   # --> [1, 2, 3, 4]
  let cap = nextPowerOfTwo(s.len)
  result.count = s.len    # set this first to avoid bounds checks
  result.data = s
  result.mask = cap - 1
  result.rd = 0
  result.wr = s.len and result.mask

proc map*[T, S](q: Queue[T], op: proc (x: T): S {.closure.}):
                                                            Queue[S]{.inline.} =
  ## Returns a new Queue with the results of ``op`` applied to every item in
  ## ``q``.
  ##
  ## Since the input is not modified, use this ``map`` to
  ## transform the type of the elements in the input sequence.
  ##
  ## Use ``apply`` to directly modify ``q``.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   let
  ##     a = @[1, 2, 3, 4].toQueue()
  ##     b = map(a, proc(x: int): string = $x)
  ##   assert b == @["1", "2", "3", "4"]
  result = initQueue[S](q.mask + 1)
  result.count = q.count
  result.rd = q.rd
  result.wr = q.wr
  result.mask = q.mask
  for i in 0..<q.len: result[i] = op(q[i])

proc apply*[T](q: var Queue[T], op: proc (x: var T) {.closure.})
                                                              {.inline.} =
  ## Applies ``op`` to every item in ``data`` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes a ``var T`` type parameter.
  ##
  ## Use ``map`` to leave ``q`` unmodified.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"].toQueue()
  ##   apply(a, proc(x: var string) = x &= "42")
  ##   echo a
  ##   # --> ["142", "242", "342", "442"]
  ##
  for i in 0..<q.len: op(q.data[i])

proc apply*[T](q: var Queue[T], op: proc (x: T): T {.closure.})
                                                              {.inline.} =
  ## Applies `op` to every item in `data` modifying it directly.
  ##
  ## Note that this requires your input and output types to
  ## be the same, since they are modified in-place.
  ## The parameter function takes and returns a ``T`` type variable.
  ##
  ## Use ``map`` to leave ``q`` unmodified.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var a = @["1", "2", "3", "4"]
  ##   apply(a, proc(x: string): string = x & "42")
  ##   echo a
  ##   # --> ["142", "242", "342", "442"]
  ##
  for i in 0..<q.len: q.data[i] = op(q.data[i])

template newQueueWith*(len: int, init: untyped): untyped =
  ## creates a new Queue, calling ``init`` to initialize each value.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var q2D = newQueueWith(10, newSeq[bool](5))
  ##   q2D[0][0] = true
  ##   q2D[1][0] = true
  ##   q2D[0][1] = true
  ##
  ##   import random
  ##   var qRand = newQueueWith(20, random(10))
  ##   echo qRand
  var result = initQueue[type(init)](nextPowerOfTwo(len))
  result.count = len      # set this first to avoid bounds checks
  for i in 0 .. <len:
    result.data[i] = init
  result.wr = result.count and result.mask
  result

when isMainModule:
  when defined(doc) or defined(doc2): discard
  else:
    from random import random

  var q = initQueue[int](1)
  q.add(123)
  q.add(9)
  q.enqueue(4)
  var first = q.dequeue()
  q.add(56)
  q.add(6)
  var second = q.pop()
  q.add(789)

  doAssert first == 123
  doAssert second == 9
  doAssert($q == "[4, 56, 6, 789]")

  doAssert q[0] == q.front and q.front == 4
  doAssert q[^1] == q.back and q.back == 789
  q[0] = 42
  q[^1] = 7

  doAssert 6 in q and 789 notin q
  doAssert q.find(6) >= 0
  doAssert q.find(789) < 0

  for i in -2 .. 10:
    if i in q:
      doAssert q.contains(i) and q.find(i) >= 0
    else:
      doAssert(not q.contains(i) and q.find(i) < 0)

  when compileOption("boundChecks"):
    try:
      echo q[99]
      doAssert false
    except IndexError:
      discard

    try:
      doAssert q.len == 4
      for i in 0 ..< 5: q.pop()
      doAssert false
    except IndexError:
      discard

  # grabs some types of resize error.
  q = initQueue[int]()
  for i in 1 .. 4: q.add i
  q.pop()
  q.pop()
  for i in 5 .. 8: q.add i
  doAssert $q == "[3, 4, 5, 6, 7, 8]"

  # Similar to proc from the documentation example
  proc foo(a, b: Positive) = # assume random positive values for `a` and `b`.
    var q = initQueue[int]()
    doAssert q.len == 0
    for i in 1 .. a: q.add i

    if b < q.len: # checking before indexed access.
      doAssert q[b] == b + 1

    # The following two lines don't need any checking on access due to the logic
    # of the program, but that would not be the case if `a` could be 0.
    doAssert q.front == 1
    doAssert q.back == a

    while q.len > 0: # checking if the queue is empty
      doAssert q.pop() > 0

  #foo(0,0)
  foo(8,5)
  foo(10,9)
  foo(1,1)
  foo(2,1)
  foo(1,5)
  foo(3,2)

  block:  #  toSeq() & toQueue()
    var a = @["1", "2", "3", "4"].toQueue()
    doAssert a.toSeq() == @["1", "2", "3", "4"]

  block:  #  toSeq() for empty queue
    var
      s: seq[string] = @[]
      a = s.toQueue()
    doAssert a.toSeq() == s

  block:  #  map()
    var a = @["1", "2", "3", "4"].toQueue()
    let b = map(a, proc(x: string): string = (x & "42"))
    doAssert b == @["142", "242", "342", "442"].toQueue()

  block:  #  apply()
    var a = @["1", "2", "3", "4"].toQueue()
    apply(a, proc(x: var string) = x &= "42")
    doAssert a == @["142", "242", "342", "442"].toQueue()

    a = @["1", "2", "3", "4"].toQueue()
    apply(a, proc(x: string): string = (x & "42"))
    doAssert a == @["142", "242", "342", "442"].toQueue()

  block:  #  `==`
    var
      a = @["1", "2", "3", "4"].toQueue()
      b = @["1", "2", "3", "4"].toQueue()
    doAssert a == b
    b.enqueue("23")
    doAssert a != b
    b = @["2", "1", "3", "4"].toQueue()
    doAssert a != b

  block:  #  newQueueWith()
    var
      qRand = newQueueWith(10, random(10))
      c = 0
    doAssert qRand.toSeq().len == 10
    for v in qRand.items(): c += v
    doAssert c != 0

  block:  #  toSeq()  for wrapped queue
    var x = initQueue[int](4)
    x.add(1); x.add(2); x.add(3); x.add(4);   # -> [1,2,3,4]
    x.pop(); x.pop()                          # -> [-,-,3,4]
    doAssert x.toSeq() == @[3,4]
    x.add(5)                                  # -> [5,-,3,4]
    doAssert x.toSeq() == @[3,4,5]
    x.add(6)                                  # -> [5,6,3,4]
    doAssert x.toSeq() == @[3,4,5,6]
    x.add(7)                                  # -> [3,4,5,6,7,-,-,-]
    doAssert x.toSeq() == @[3,4,5,6,7]
