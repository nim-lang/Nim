#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## An implementation of a `deque`:idx: (double-ended queue).
## The underlying implementation uses a `seq`.
##
## .. note:: None of the procs that get an individual value from the deque should be used
##   on an empty deque.
##
## If compiled with the `boundChecks` option, those procs will raise an `IndexDefect`
## on such access. This should not be relied upon, as `-d:danger` or `--checks:off` will
## disable those checks and then the procs may return garbage or crash the program.
##
## As such, a check to see if the deque is empty is needed before any
## access, unless your program logic guarantees it indirectly.

runnableExamples:
  var a = [10, 20, 30, 40].toDeque

  doAssertRaises(IndexDefect, echo a[4])

  a.addLast(50)
  assert $a == "[10, 20, 30, 40, 50]"

  assert a.peekFirst == 10
  assert a.peekLast == 50
  assert len(a) == 5

  assert a.popFirst == 10
  assert a.popLast == 50
  assert len(a) == 3

  a.addFirst(11)
  a.addFirst(22)
  a.addFirst(33)
  assert $a == "[33, 22, 11, 20, 30, 40]"

  a.shrink(fromFirst = 1, fromLast = 2)
  assert $a == "[22, 11, 20]"

## See also
## ========
## * `lists module <lists.html>`_ for singly and doubly linked lists and rings

import std/private/since

import std/[assertions, hashes, math, typetraits]

type
  Deque*[T] = object
    ## A double-ended queue backed with a ringed `seq` buffer.
    ##
    ## To pre-allocate memory, use the `initDeque func <#initDeque,int>`_.
    data: seq[T]

    # `head` and `tail` are masked only when accessing an element of `data`
    # so that `tail - head == data.len` when the deque is full.
    # They are uint so that incrementing/decrementing them doesn't cause
    # over/underflow. You can get a number of items with `tail - head`
    # even if `tail` or `head` is wraps around and `tail < head`, because
    # `tail - head == (uint.high + 1 + tail) - head` when `tail < head`.
    head, tail: uint

const
  defaultInitialSize* = 4
  boundsChecks = compileOption("boundChecks")

func len*(deq: Deque): int =
  ## Returns the number of elements of `deq`.
  cast[int](deq.tail - deq.head) # cast to avoid range check

func low*(deq: Deque): int {.compileTime.} =
  ## Returns the lowest possible index of a deque
  0

func high*(deq: Deque): int {.inline.} =
  ## Returns the highest possible index of a deque
  cast[int](deq.tail - deq.head - 1) # cast to avoid range check (wrapping arith)

when boundsChecks:
  func raiseEmpty() {.noreturn.} =
    raise newException(IndexDefect, "Empty deque.")
  func raiseOverflow(i, L: int) {.noreturn.} =
    raise newException(IndexDefect, "Out of bounds: " & $i & " > " & $(L - 1))
  func raiseUnderflow(i: int) {.noreturn.} =
    raise newException(IndexDefect, "Out of bounds: " & $i & " < 0")

  template emptyCheck(deq) =
    # Bounds check for the regular deque access.
    if unlikely(deq.len < 1):
      raiseEmpty()

  template xBoundsCheck(deq, i) =
    # Bounds check for the array like accesses.
    let L = deq.len
    if unlikely(i >= L): # x < deq.low is taken care by the Natural parameter
      raiseOverflow(i, L)
    if unlikely(i < 0): # when used with BackwardsIndex
      raiseUnderflow(i)
else:
  template emptyCheck(deq) = discard
  template xBoundsCheck(deq, i) = discard

template mask[T](deq: Deque[T]): uint =
  uint(deq.data.len) - 1

{.push boundChecks: off.} # Bounds checks are done via xBoundsCheck

template uncheckedElem(deq, i): untyped =
  (deq.head + uint(i)) and deq.mask

template elem(deq, i): untyped =
  let iv = i
  xBoundsCheck(deq, iv)
  uncheckedElem(deq, iv)

template needsReset(T: type): bool =
  # For some types, `reset` is significant since it calls `=destroy` and
  # releases resources but for others, it's just wasted cycles.
  # `supportsCopyMem` is an approximation of the latter variety.
  # For refc, we also reset pointers to ensure the gc does not follow them when
  # collecting cycles.
  # Types that need reset also might have side effects in their `=destroy`.
  (not supportsCopyMem(T)) or (defined(gcRefc) and T is (pointer|ptr))

template drain(src: untyped): untyped =
  # `move` that omits resetting the source when it is safe to do so
  when needsReset(typeof(src)):
    move(src)
  else:
    src

when false: # TODO no obvious way to get rid of the seq data without having it re-destroy
  proc `=destroy`*[T](deq: var Deque[T]) =
    # Prevent the auto-generated `=destroy` from running on the full capacity (the
    # empty items have already been destroyed)
    when needsReset(T):
      let L = deq.len
      for i in 0..<L:
        reset(deq.data[deq.elem(i)])
    `=dispose`(deq.data) # TODO dispose doesn't work for seq

func initDeque*[T](initialSize: int = defaultInitialSize): Deque[T] =
  ## Initialize a deque with the given pre-allocated capacity.
  ##
  ## Calling this function is optional and may be done for optimization purposes.
  ##
  ## (default: `defaultInitialSize <#defaultInitialSize>`_).
  ## The length of a newly created deque will still be 0.
  ##
  ## **See also:**
  ## * `toDeque func <#toDeque,openArray[T]>`_
  let correctSize = nextPowerOfTwo(initialSize)
  Deque[T](
    data:
      when needsReset(T):
        newSeq[T](correctSize)
      else:
        newSeqUninit[T](correctSize)
  )

func `[]`*[T](deq: Deque[T], i: Natural): lent T {.inline.} =
  ## Accesses the `i`-th element of `deq`.
  runnableExamples:
    let a = [10, 20, 30, 40, 50].toDeque
    assert a[0] == 10
    assert a[3] == 40
    doAssertRaises(IndexDefect, echo a[8])

  return deq.data[deq.elem(i)]

func `[]`*[T](deq: var Deque[T], i: Natural): var T {.inline.} =
  ## Accesses the `i`-th element of `deq` and returns a mutable
  ## reference to it.
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    inc(a[0])
    assert a[0] == 11

  return deq.data[deq.elem(i)]

proc `[]=`*[T](deq: var Deque[T], i: Natural, val: sink T) {.inline.} =
  ## Sets the `i`-th element of `deq` to `val`.
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    a[0] = 99
    a[3] = 66
    assert $a == "[99, 20, 30, 66, 50]"

  deq.data[deq.elem(i)] = val

func `[]`*[T](deq: Deque[T], i: BackwardsIndex): lent T {.inline.} =
  ## Accesses the backwards indexed `i`-th element.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    let a = [10, 20, 30, 40, 50].toDeque
    assert a[^1] == 50
    assert a[^4] == 20
    doAssertRaises(IndexDefect, echo a[^9])

  return deq.data[deq.elem(deq.len - int(i))]

func `[]`*[T](deq: var Deque[T], i: BackwardsIndex): var T {.inline.} =
  ## Accesses the backwards indexed `i`-th element and returns a mutable
  ## reference to it.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    inc(a[^1])
    assert a[^1] == 51

  return deq.data[deq.elem(deq.len - int(i))]

proc `[]=`*[T](deq: var Deque[T], i: BackwardsIndex, x: sink T) {.inline.} =
  ## Sets the backwards indexed `i`-th element of `deq` to `x`.
  ##
  ## `deq[^1]` is the last element.
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    a[^1] = 99
    a[^3] = 77
    assert $a == "[10, 20, 77, 40, 99]"

  deq.data[deq.elem(deq.len - int(i))] = x

iterator items*[T](deq: Deque[T]): lent T =
  ## Yields every element of `deq`.
  ##
  ## **See also:**
  ## * `mitems iterator <#mitems.i,Deque[T]>`_
  runnableExamples:
    from std/sequtils import toSeq

    let a = [10, 20, 30, 40, 50].toDeque
    assert toSeq(a.items) == @[10, 20, 30, 40, 50]

  let L = len(deq)
  for c in 0 ..< L:
    yield deq.data[deq.uncheckedElem(c)]
    assert(len(deq) == L, "the length of the Deque changed while iterating over it")

iterator mitems*[T](deq: var Deque[T]): var T =
  ## Yields every element of `deq`, which can be modified.
  ##
  ## **See also:**
  ## * `items iterator <#items.i,Deque[T]>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5 * x - 1
    assert $a == "[49, 99, 149, 199, 249]"

  let L = len(deq)
  for c in 0 ..< L:
    yield deq.data[deq.uncheckedElem(c)]
    assert(len(deq) == L, "the length of the Deque changed while iterating over it")

iterator pairs*[T](deq: Deque[T]): tuple[key: int, val: T] =
  ## Yields every `(position, value)`-pair of `deq`.
  runnableExamples:
    from std/sequtils import toSeq

    let a = [10, 20, 30].toDeque
    assert toSeq(a.pairs) == @[(0, 10), (1, 20), (2, 30)]

  let L = len(deq)
  for c in 0 ..< L:
    yield (c, deq.data[deq.uncheckedElem(c)])
    assert(len(deq) == L, "the length of the Deque changed while iterating over it")

func contains*[T](deq: Deque[T], item: T): bool {.inline.} =
  ## Returns true if `item` is in `deq` or false if not found.
  ##
  ## Usually used via the `in` operator.
  ## It is the equivalent of `deq.find(item) >= 0`.
  runnableExamples:
    let q = [7, 9].toDeque
    assert 7 in q
    assert q.contains(7)
    assert 8 notin q

  for e in deq:
    if e == item: return true
  return false

proc bulkCopy[T](tgt: var openArray[T], src: openArray[T]) =
  when nimvm:
    for i in 0..<src.len():
      tgt[i] = src[i]
  else:
    when needsReset(T):
      for i in 0..<src.len():
        tgt[i] = src[i]
    else:
      copyMem(addr tgt[0], addr src[0], src.len() * sizeof(T))

proc bulkDrain[T](tgt, src: var openArray[T]) =
  when nimvm:
    for i in 0..<src.len():
      tgt[i] = drain src[i]
  else:
    when needsReset(T):
      for i in 0..<src.len():
        tgt[i] = drain src[i]
    else:
      copyMem(addr tgt[0], addr src[0], src.len() * sizeof(T))

proc expandIfNeeded[T](deq: var Deque[T]) =
  let
    cap = deq.data.len
    L = deq.len
  assert L <= cap
  if unlikely(L == cap):
    let
      head = cast[int](deq.head and deq.mask)
      toCap = cap - head

    var n =
      when needsReset(T):
        newSeq[T](max(cap * 2, defaultInitialSize))
      else:
        newSeqUninit[T](max(cap * 2, defaultInitialSize))

    bulkDrain(n, deq.data.toOpenArray(head, deq.data.high()))
    if head > 0:
      bulkDrain(n.toOpenArray(toCap, n.high()), deq.data.toOpenArray(0, head - 1))
    deq.data = move n
    deq.tail = cap.uint
    deq.head = 0

proc addFirst*[T](deq: var Deque[T], item: sink T) =
  ## Adds an `item` to the beginning of `deq`.
  ##
  ## **See also:**
  ## * `addLast proc <#addLast,Deque[T],sinkT>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addFirst(10 * i)
    assert $a == "[50, 40, 30, 20, 10]"

  expandIfNeeded(deq)
  dec deq.head
  deq.data[deq.head and deq.mask] = item

proc addLast*[T](deq: var Deque[T], item: sink T) =
  ## Adds an `item` to the end of `deq`.
  ##
  ## **See also:**
  ## * `addFirst proc <#addFirst,Deque[T],sinkT>`_
  runnableExamples:
    var a = initDeque[int]()
    for i in 1 .. 5:
      a.addLast(10 * i)
    assert $a == "[10, 20, 30, 40, 50]"

  expandIfNeeded(deq)
  deq.data[deq.tail and deq.mask] = item
  inc deq.tail

func toDeque*[T](x: openArray[T]): Deque[T] {.since: (1, 3).} =
  ## Creates a new deque that contains the elements of `x` (in the same order).
  ##
  ## **See also:**
  ## * `initDeque func <#initDeque,int>`_
  runnableExamples:
    let a = toDeque([7, 8, 9])
    assert len(a) == 3
    assert $a == "[7, 8, 9]"
  result = initDeque[T](x.len)
  bulkCopy(result.data, x)
  result.tail = uint x.len

proc toDequeSink*[T](x: sink seq[T]): Deque[T] {.since: (2, 3).} =
  ## Creates a new deque that moves the elements of `x` (in the same order).
  ##
  ## **See also:**
  ## * `initDeque func <#initDeque,int>`_
  runnableExamples:
    let a = toDeque(@[7, 8, 9])
    assert len(a) == 3
    assert $a == "[7, 8, 9]"
  result = initDeque[T](x.len)
  bulkDrain(result.data, x)
  result.tail = uint x.len

func peekFirst*[T](deq: Deque[T]): lent T {.inline.} =
  ## Returns the first element of `deq`, but does not remove it from the deque.
  ##
  ## **See also:**
  ## * `peekFirst func <#peekFirst,Deque[T]_2>`_ which returns a mutable reference
  ## * `peekLast func <#peekLast,Deque[T]>`_
  runnableExamples:
    let a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekFirst == 10
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[deq.head and deq.mask]

func peekLast*[T](deq: Deque[T]): lent T {.inline.} =
  ## Returns the last element of `deq`, but does not remove it from the deque.
  ##
  ## **See also:**
  ## * `peekLast func <#peekLast,Deque[T]_2>`_ which returns a mutable reference
  ## * `peekFirst func <#peekFirst,Deque[T]>`_
  runnableExamples:
    let a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.peekLast == 50
    assert len(a) == 5

  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

func peekFirst*[T](deq: var Deque[T]): var T {.inline, since: (1, 3).} =
  ## Returns a mutable reference to the first element of `deq`,
  ## but does not remove it from the deque.
  ##
  ## **See also:**
  ## * `peekFirst func <#peekFirst,Deque[T]>`_
  ## * `peekLast func <#peekLast,Deque[T]_2>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    a.peekFirst() = 99
    assert $a == "[99, 20, 30, 40, 50]"

  emptyCheck(deq)
  result = deq.data[deq.head and deq.mask]

func peekLast*[T](deq: var Deque[T]): var T {.inline, since: (1, 3).} =
  ## Returns a mutable reference to the last element of `deq`,
  ## but does not remove it from the deque.
  ##
  ## **See also:**
  ## * `peekFirst func <#peekFirst,Deque[T]_2>`_
  ## * `peekLast func <#peekLast,Deque[T]>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    a.peekLast() = 99
    assert $a == "[10, 20, 30, 40, 99]"

  emptyCheck(deq)
  result = deq.data[(deq.tail - 1) and deq.mask]

proc popFirst*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Removes and returns the first element of the `deq`.
  ##
  ## See also:
  ## * `popLast proc <#popLast,Deque[T]>`_
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.popFirst == 10
    assert $a == "[20, 30, 40, 50]"

  emptyCheck(deq)
  result = drain deq.data[deq.head and deq.mask]
  inc deq.head

proc popLast*[T](deq: var Deque[T]): T {.inline, discardable.} =
  ## Removes and returns the last element of the `deq`.
  ##
  ## **See also:**
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    assert a.popLast == 50
    assert $a == "[10, 20, 30, 40]"

  emptyCheck(deq)
  dec deq.tail
  result = drain deq.data[deq.tail and deq.mask]

proc clear*[T](deq: var Deque[T]) {.inline.} =
  ## Resets the deque so that it is empty without releasing its buffer.
  ##
  ## **See also:**
  ## * `shrink proc <#shrink,Deque[T],int,int>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    clear(a)
    assert len(a) == 0

  when needsReset(T):
    for el in mitems(deq): reset(el)
  deq.tail = deq.head

proc shrink*[T](deq: var Deque[T], fromFirst = 0, fromLast = 0) =
  ## Removes `fromFirst` elements from the front of the deque and
  ## `fromLast` elements from the back.
  ##
  ## If the supplied number of elements exceeds the total number of elements
  ## in the deque, the deque will remain empty.
  ##
  ## **See also:**
  ## * `clear proc <#clear,Deque[T]>`_
  ## * `popFirst proc <#popFirst,Deque[T]>`_
  ## * `popLast proc <#popLast,Deque[T]>`_
  runnableExamples:
    var a = [10, 20, 30, 40, 50].toDeque
    assert $a == "[10, 20, 30, 40, 50]"
    a.shrink(fromFirst = 2, fromLast = 1)
    assert $a == "[30, 40]"

  if fromFirst + fromLast > deq.len:
    clear(deq)
    return

  when needsReset(T):
    for i in 0 ..< fromFirst:
      reset(deq.data[deq.head and deq.mask])
      inc deq.head

    for i in 0 ..< fromLast:
      dec deq.tail
      reset(deq.data[deq.tail and deq.mask])
  else:
    deq.head += uint(fromFirst)
    deq.tail -= uint(fromLast)

proc `$`*[T](deq: Deque[T]): string =
  ## Turns a deque into its string representation.
  runnableExamples:
    let a = [10, 20, 30].toDeque
    assert $a == "[10, 20, 30]"

  result = "["
  var first = true
  for x in deq:
    if first: first = false
    else: result.add(", ")
    result.addQuoted(x)
  result.add("]")

func `==`*[T](deq1, deq2: Deque[T]): bool =
  ## The `==` operator for Deque.
  ## Returns `true` if both deques contains the same values in the same order.
  runnableExamples:
    var a, b = initDeque[int]()
    a.addFirst(2)
    a.addFirst(1)
    b.addLast(1)
    b.addLast(2)
    doAssert a == b

  if deq1.len != deq2.len:
    return false

  for i in 0 ..< deq1.len:
    if deq1.data[deq1.uncheckedElem(i)] != deq2.data[deq2.uncheckedElem(i)]:
      return false

  true

func hash*[T](deq: Deque[T]): Hash =
  ## Hashing of Deque.
  var h: Hash = 0
  for x in deq:
    h = h !& hash(x)
  !$h
