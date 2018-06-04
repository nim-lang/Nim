#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements some common generic algorithms.

type
  SortOrder* = enum   ## sort order
    Descending, Ascending

proc `*`*(x: int, order: SortOrder): int {.inline.} =
  ## flips `x` if ``order == Descending``;
  ## if ``order == Ascending`` then `x` is returned.
  ## `x` is supposed to be the result of a comparator, ie ``< 0`` for
  ## *less than*, ``== 0`` for *equal*, ``> 0`` for *greater than*.
  var y = order.ord - 1
  result = (x xor y) - y

template fillImpl[T](a: var openArray[T], first, last: int, value: T) =
  var x = first
  while x <= last:
    a[x] = value
    inc(x)

proc fill*[T](a: var openArray[T], first, last: Natural, value: T) =
  ## fills the array ``a[first..last]`` with `value`.
  fillImpl(a, first, last, value)

proc fill*[T](a: var openArray[T], value: T) =
  ## fills the array `a` with `value`.
  fillImpl(a, 0, a.high, value)


proc reverse*[T](a: var openArray[T], first, last: Natural) =
  ## reverses the array ``a[first..last]``.
  var x = first
  var y = last
  while x < y:
    swap(a[x], a[y])
    dec(y)
    inc(x)

proc reverse*[T](a: var openArray[T]) =
  ## reverses the array `a`.
  reverse(a, 0, max(0, a.high))

proc reversed*[T](a: openArray[T], first: Natural, last: int): seq[T] =
  ## returns the reverse of the array `a[first..last]`.
  assert last >= first-1
  var i = last - first
  var x = first.int
  result = newSeq[T](i + 1)
  while i >= 0:
    result[i] = a[x]
    dec(i)
    inc(x)

proc reversed*[T](a: openArray[T]): seq[T] =
  ## returns the reverse of the array `a`.
  reversed(a, 0, a.high)

proc binarySearch*[T, K](a: openArray[T], key: K,
              cmp: proc (x: T, y: K): int {.closure.}): int =
  ## binary search for `key` in `a`. Returns -1 if not found.
  ##
  ## `cmp` is the comparator function to use, the expected return values are
  ## the same as that of system.cmp.
  if a.len == 0:
    return -1

  let len = a.len

  if len == 1:
    if cmp(a[0], key) == 0:
      return 0
    else:
      return -1

  if (len and (len - 1)) == 0:
    # when `len` is a power of 2, a faster shr can be used.
    var step = len shr 1
    var cmpRes: int
    while step > 0:
      let i = result or step
      cmpRes = cmp(a[i], key)
      if cmpRes == 0:
        return i

      if cmpRes < 1:
        result = i
      step = step shr 1
    if cmp(a[result], key) != 0: result = -1
  else:
    var b = len
    var cmpRes: int
    while result < b:
      var mid = (result + b) shr 1
      cmpRes = cmp(a[mid], key)
      if cmpRes == 0:
        return mid

      if cmpRes < 0:
        result = mid + 1
      else:
        b = mid
    if result >= len or cmp(a[result], key) != 0: result = -1

proc binarySearch*[T](a: openArray[T], key: T): int =
  ## binary search for `key` in `a`. Returns -1 if not found.
  binarySearch(a, key, cmp[T])

proc smartBinarySearch*[T](a: openArray[T], key: T): int {.deprecated.} =
  ## **Deprecated since version 0.18.1**; Use ``binarySearch`` instead.
  binarySearch(a, key, cmp[T])

const
  onlySafeCode = true

proc lowerBound*[T, K](a: openArray[T], key: K, cmp: proc(x: T, k: K): int {.closure.}): int =
  ## Returns a position to the first element in the `a` that is greater than `key`, or last
  ## if no such element is found. In other words if you have a sorted sequence and you call
  ## insert(thing, elm, lowerBound(thing, elm))
  ## the sequence will still be sorted.
  ##
  ## The first version uses `cmp` to compare the elements. The expected return values are
  ## the same as that of system.cmp.
  ## The second version uses the default comparison function `cmp`.
  ##
  ## example::
  ##
  ##   var arr = @[1,2,3,5,6,7,8,9]
  ##   arr.insert(4, arr.lowerBound(4))
  ##   # after running the above arr is `[1,2,3,4,5,6,7,8,9]`
  result = a.low
  var count = a.high - a.low + 1
  var step, pos: int
  while count != 0:
    step = count shr 1
    pos = result + step
    if cmp(a[pos], key) < 0:
      result = pos + 1
      count -= step + 1
    else:
      count = step

proc lowerBound*[T](a: openArray[T], key: T): int = lowerBound(a, key, cmp[T])

proc upperBound*[T, K](a: openArray[T], key: K, cmp: proc(x: T, k: K): int {.closure.}): int =
  ## Returns a position to the first element in the `a` that is not less
  ## (i.e. greater or equal to) than `key`, or last if no such element is found.
  ## In other words if you have a sorted sequence and you call
  ## insert(thing, elm, upperBound(thing, elm))
  ## the sequence will still be sorted.
  ##
  ## The first version uses `cmp` to compare the elements. The expected return values are
  ## the same as that of system.cmp.
  ## The second version uses the default comparison function `cmp`.
  ##
  ## example::
  ##
  ##   var arr = @[1,2,3,4,6,7,8,9]
  ##   arr.insert(5, arr.upperBound(4))
  ##   # after running the above arr is `[1,2,3,4,5,6,7,8,9]`
  result = a.low
  var count = a.high - a.low + 1
  var step, pos: int
  while count != 0:
    step = count shr 1
    pos = result + step
    if cmp(a[pos], key) <= 0:
      result = pos + 1
      count -= step + 1
    else:
      count = step

proc upperBound*[T](a: openArray[T], key: T): int = upperBound(a, key, cmp[T])

template `<-` (a, b) =
  when false:
    a = b
  elif onlySafeCode:
    shallowCopy(a, b)
  else:
    copyMem(addr(a), addr(b), sizeof(T))

proc merge[T](a, b: var openArray[T], lo, m, hi: int,
              cmp: proc (x, y: T): int {.closure.}, order: SortOrder) =
  # optimization: If max(left) <= min(right) there is nothing to do!
  # 1 2 3 4  ## 5 6 7 8
  # -> O(n) for sorted arrays.
  # On random data this safes up to 40% of merge calls
  if cmp(a[m], a[m+1]) * order <= 0: return
  var j = lo
  # copy a[j..m] into b:
  assert j <= m
  when onlySafeCode:
    var bb = 0
    while j <= m:
      b[bb] <- a[j]
      inc(bb)
      inc(j)
  else:
    copyMem(addr(b[0]), addr(a[j]), sizeof(T)*(m-j+1))
    j = m+1
  var i = 0
  var k = lo
  # copy proper element back:
  while k < j and j <= hi:
    if cmp(b[i], a[j]) * order <= 0:
      a[k] <- b[i]
      inc(i)
    else:
      a[k] <- a[j]
      inc(j)
    inc(k)
  # copy rest of b:
  when onlySafeCode:
    while k < j:
      a[k] <- b[i]
      inc(k)
      inc(i)
  else:
    if k < j: copyMem(addr(a[k]), addr(b[i]), sizeof(T)*(j-k))

proc sort*[T](a: var openArray[T],
              cmp: proc (x, y: T): int {.closure.},
              order = SortOrder.Ascending) =
  ## Default Nim sort (an implementation of merge sort). The sorting
  ## is guaranteed to be stable and the worst case is guaranteed to
  ## be O(n log n).
  ## The current implementation uses an iterative
  ## mergesort to achieve this. It uses a temporary sequence of
  ## length ``a.len div 2``. Currently Nim does not support a
  ## sensible default argument for ``cmp``, so you have to provide one
  ## of your own. However, the ``system.cmp`` procs can be used:
  ##
  ## .. code-block:: nim
  ##
  ##    sort(myIntArray, system.cmp[int])
  ##
  ##    # do not use cmp[string] here as we want to use the specialized
  ##    # overload:
  ##    sort(myStrArray, system.cmp)
  ##
  ## You can inline adhoc comparison procs with the `do notation
  ## <manual.html#procedures-do-notation>`_. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   people.sort do (x, y: Person) -> int:
  ##     result = cmp(x.surname, y.surname)
  ##     if result == 0:
  ##       result = cmp(x.name, y.name)
  var n = a.len
  var b: seq[T]
  newSeq(b, n div 2)
  var s = 1
  while s < n:
    var m = n-1-s
    while m >= 0:
      merge(a, b, max(m-s+1, 0), m, m+s, cmp, order)
      dec(m, s*2)
    s = s*2

proc sorted*[T](a: openArray[T], cmp: proc(x, y: T): int {.closure.},
                order = SortOrder.Ascending): seq[T] =
  ## returns `a` sorted by `cmp` in the specified `order`.
  result = newSeq[T](a.len)
  for i in 0 .. a.high:
    result[i] = a[i]
  sort(result, cmp, order)

template sortedByIt*(seq1, op: untyped): untyped =
  ## Convenience template around the ``sorted`` proc to reduce typing.
  ##
  ## The template injects the ``it`` variable which you can use directly in an
  ## expression. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   type Person = tuple[name: string, age: int]
  ##   var
  ##     p1: Person = (name: "p1", age: 60)
  ##     p2: Person = (name: "p2", age: 20)
  ##     p3: Person = (name: "p3", age: 30)
  ##     p4: Person = (name: "p4", age: 30)
  ##     people = @[p1,p2,p4,p3]
  ##
  ##   echo people.sortedByIt(it.name)
  ##
  ## Because the underlying ``cmp()`` is defined for tuples you can do
  ## a nested sort like in the following example:
  ##
  ## .. code-block:: nim
  ##
  ##   echo people.sortedByIt((it.age, it.name))
  ##
  var result = sorted(seq1, proc(x, y: type(seq1[0])): int =
    var it {.inject.} = x
    let a = op
    it = y
    let b = op
    result = cmp(a, b))
  result

proc isSorted*[T](a: openarray[T],
                 cmp: proc(x, y: T): int {.closure.},
                 order = SortOrder.Ascending): bool =
  ## Checks to see whether `a` is already sorted in `order`
  ## using `cmp` for the comparison. Parameters identical
  ## to `sort`
  result = true
  for i in 0..<len(a)-1:
    if cmp(a[i],a[i+1]) * order > 0:
      return false

proc product*[T](x: openArray[seq[T]]): seq[seq[T]] =
  ## produces the Cartesian product of the array. Warning: complexity
  ## may explode.
  result = newSeq[seq[T]]()
  if x.len == 0:
    return
  if x.len == 1:
    result = @x
    return
  var
    indexes = newSeq[int](x.len)
    initial = newSeq[int](x.len)
    index = 0
  var next = newSeq[T]()
  next.setLen(x.len)
  for i in 0..(x.len-1):
    if len(x[i]) == 0: return
    initial[i] = len(x[i])-1
  indexes = initial
  while true:
    while indexes[index] == -1:
      indexes[index] = initial[index]
      index += 1
      if index == x.len: return
      indexes[index] -= 1
    for ni, i in indexes:
      next[ni] = x[ni][i]
    var res: seq[T]
    shallowCopy(res, next)
    result.add(res)
    index = 0
    indexes[index] -= 1

proc nextPermutation*[T](x: var openarray[T]): bool {.discardable.} =
  ## Calculates the next lexicographic permutation, directly modifying ``x``.
  ## The result is whether a permutation happened, otherwise we have reached
  ## the last-ordered permutation.
  ##
  ## .. code-block:: nim
  ##
  ##     var v = @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  ##     v.nextPermutation()
  ##     echo v # @[0, 1, 2, 3, 4, 5, 6, 7, 9, 8]
  if x.len < 2:
    return false

  var i = x.high
  while i > 0 and x[i-1] >= x[i]:
    dec i

  if i == 0:
    return false

  var j = x.high
  while j >= i and x[j] <= x[i-1]:
    dec j

  swap x[j], x[i-1]
  x.reverse(i, x.high)

  result = true

proc prevPermutation*[T](x: var openarray[T]): bool {.discardable.} =
  ## Calculates the previous lexicographic permutation, directly modifying
  ## ``x``.  The result is whether a permutation happened, otherwise we have
  ## reached the first-ordered permutation.
  ##
  ## .. code-block:: nim
  ##
  ##     var v = @[0, 1, 2, 3, 4, 5, 6, 7, 9, 8]
  ##     v.prevPermutation()
  ##     echo v # @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  if x.len < 2:
    return false

  var i = x.high
  while i > 0 and x[i-1] <= x[i]:
    dec i

  if i == 0:
    return false

  x.reverse(i, x.high)

  var j = x.high
  while j >= i and x[j-1] < x[i-1]:
    dec j

  swap x[i-1], x[j]

  result = true

when isMainModule:
  # Tests for lowerBound
  var arr = @[1,2,3,5,6,7,8,9]
  assert arr.lowerBound(0) == 0
  assert arr.lowerBound(4) == 3
  assert arr.lowerBound(5) == 3
  assert arr.lowerBound(10) == 8
  arr = @[1,5,10]
  assert arr.lowerBound(4) == 1
  assert arr.lowerBound(5) == 1
  assert arr.lowerBound(6) == 2
  # Tests for isSorted
  var srt1 = [1,2,3,4,4,4,4,5]
  var srt2 = ["iello","hello"]
  var srt3 = [1.0,1.0,1.0]
  var srt4: seq[int]
  assert srt1.isSorted(cmp) == true
  assert srt2.isSorted(cmp) == false
  assert srt3.isSorted(cmp) == true
  assert srt4.isSorted(cmp) == true
  var srtseq = newSeq[int]()
  assert srtseq.isSorted(cmp) == true
  # Tests for reversed
  var arr1 = @[0,1,2,3,4]
  assert arr1.reversed() == @[4,3,2,1,0]
  for i in 0 .. high(arr1):
    assert arr1.reversed(0, i) == arr1.reversed()[high(arr1) - i .. high(arr1)]
    assert arr1.reversed(i, high(arr1)) == arr1.reversed()[0 .. high(arr1) - i]


proc rotateInternal[T](arg: var openarray[T]; first, middle, last: int): int =
  ## A port of std::rotate from c++. Ported from `this reference <http://www.cplusplus.com/reference/algorithm/rotate/>`_.
  result = first + last - middle

  if first == middle or middle == last:
    return

  assert first < middle
  assert middle < last

  # m prefix for mutable
  var
    mFirst = first
    mMiddle = middle
    next = middle

  swap(arg[mFirst], arg[next])
  mFirst += 1
  next += 1
  if mFirst == mMiddle:
    mMiddle = next

  while next != last:
    swap(arg[mFirst], arg[next])
    mFirst += 1
    next += 1
    if mFirst == mMiddle:
      mMiddle = next

  next = mMiddle
  while next != last:
    swap(arg[mFirst], arg[next])
    mFirst += 1
    next += 1
    if mFirst == mMiddle:
      mMiddle = next
    elif next == last:
      next = mMiddle

proc rotatedInternal[T](arg: openarray[T]; first, middle, last: int): seq[T] =
  result = newSeq[T](arg.len)
  for i in 0 ..< first:
    result[i] = arg[i]
  let N = last - middle
  let M = middle - first
  for i in 0 ..< N:
    result[first+i] = arg[middle+i]
  for i in 0 ..< M:
    result[first+N+i] = arg[first+i]
  for i in last ..< arg.len:
    result[i] = arg[i]

proc rotateLeft*[T](arg: var openarray[T]; slice: HSlice[int, int]; dist: int): int =
  ## Performs a left rotation on a range of elements. If you want to rotate right, use a negative ``dist``.
  ## Specifically, ``rotateLeft`` rotates the elements at ``slice`` by ``dist`` positions.
  ## The element at index ``slice.a + dist`` will be at index ``slice.a``.
  ## The element at index ``slice.b`` will be at ``slice.a + dist -1``.
  ## The element at index ``slice.a`` will be at ``slice.b + 1 - dist``.
  ## The element at index ``slice.a + dist - 1`` will be at ``slice.b``.
  #
  ## Elements outsize of ``slice`` will be left unchanged.
  ## The time complexity is linear to ``slice.b - slice.a + 1``.
  ##
  ## ``slice``
  ##   the indices of the element range that should be rotated.
  ##
  ## ``dist``
  ##   the distance in amount of elements that the data should be rotated. Can be negative, can be any number.
  ##
  ## .. code-block:: nim
  ##     var list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  ##     list.rotateLeft(1 .. 8, 3)
  ##     doAssert list == [0, 4, 5, 6, 7, 8, 1, 2, 3, 9, 10]
  let sliceLen = slice.b + 1 - slice.a
  let distLeft = ((dist mod sliceLen) + sliceLen) mod sliceLen
  arg.rotateInternal(slice.a, slice.a+distLeft, slice.b + 1)

proc rotateLeft*[T](arg: var openarray[T]; dist: int): int =
  ## default arguments for slice, so that this procedure operates on the entire
  ## ``arg``, and not just on a part of it.
  let arglen = arg.len
  let distLeft = ((dist mod arglen) + arglen) mod arglen
  arg.rotateInternal(0, distLeft, arglen)

proc rotatedLeft*[T](arg: openarray[T]; slice: HSlice[int, int], dist: int): seq[T] =
  ## same as ``rotateLeft``, just with the difference that it does
  ## not modify the argument. It creates a new ``seq`` instead
  let sliceLen = slice.b + 1 - slice.a
  let distLeft = ((dist mod sliceLen) + sliceLen) mod sliceLen
  arg.rotatedInternal(slice.a, slice.a+distLeft, slice.b+1)

proc rotatedLeft*[T](arg: openarray[T]; dist: int): seq[T] =
  ## same as ``rotateLeft``, just with the difference that it does
  ## not modify the argument. It creates a new ``seq`` instead
  let arglen = arg.len
  let distLeft = ((dist mod arglen) + arglen) mod arglen
  arg.rotatedInternal(0, distLeft, arg.len)

when isMainModule:
  var list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  let list2 = list.rotatedLeft(1 ..< 9, 3)
  let expected = [0, 4, 5, 6, 7, 8, 1, 2, 3, 9, 10]

  doAssert list.rotateLeft(1 ..< 9, 3) == 6
  doAssert list == expected
  doAssert list2 == @expected

  var s0,s1,s2,s3,s4,s5 = "xxxabcdefgxxx"

  doAssert s0.rotateLeft(3 ..< 10, 3) == 7
  doAssert s0 == "xxxdefgabcxxx"
  doAssert s1.rotateLeft(3 ..< 10, 2) == 8
  doAssert s1 == "xxxcdefgabxxx"
  doAssert s2.rotateLeft(3 ..< 10, 4) == 6
  doAssert s2 == "xxxefgabcdxxx"
  doAssert s3.rotateLeft(3 ..< 10, -3) == 6
  doAssert s3 == "xxxefgabcdxxx"
  doAssert s4.rotateLeft(3 ..< 10, -10) == 6
  doAssert s4 == "xxxefgabcdxxx"
  doAssert s5.rotateLeft(3 ..< 10, 11) == 6
  doAssert s5 == "xxxefgabcdxxx"

  block product:
    doAssert product(newSeq[seq[int]]()) == newSeq[seq[int]](), "empty input"
    doAssert product(@[newSeq[int](), @[], @[]]) == newSeq[seq[int]](), "bit more empty input"
    doAssert product(@[@[1,2]]) == @[@[1,2]], "a simple case of one element"
    doAssert product(@[@[1,2], @[3,4]]) == @[@[2,4],@[1,4],@[2,3],@[1,3]], "two elements"
    doAssert product(@[@[1,2], @[3,4], @[5,6]]) == @[@[2,4,6],@[1,4,6],@[2,3,6],@[1,3,6], @[2,4,5],@[1,4,5],@[2,3,5],@[1,3,5]], "three elements"
    doAssert product(@[@[1,2], @[]]) == newSeq[seq[int]](), "two elements, but one empty"

  block lowerBound:
    doAssert lowerBound([1,2,4], 3, system.cmp[int]) == 2
    doAssert lowerBound([1,2,2,3], 4, system.cmp[int]) == 4
    doAssert lowerBound([1,2,3,10], 11) == 4

  block upperBound:
    doAssert upperBound([1,2,4], 3, system.cmp[int]) == 2
    doAssert upperBound([1,2,2,3], 3, system.cmp[int]) == 4
    doAssert upperBound([1,2,3,5], 3) == 3

  block fillEmptySeq:
    var s = newSeq[int]()
    s.fill(0)

  block testBinarySearch:
    var noData: seq[int]
    doAssert binarySearch(noData, 7) == -1
    let oneData = @[1]
    doAssert binarySearch(oneData, 1) == 0
    doAssert binarySearch(onedata, 7) == -1
    let someData = @[1,3,4,7]
    doAssert binarySearch(someData, 1) == 0
    doAssert binarySearch(somedata, 7) == 3
    doAssert binarySearch(someData, -1) == -1
    doAssert binarySearch(someData, 5) == -1
    doAssert binarySearch(someData, 13) == -1
    let moreData = @[1,3,5,7,4711]
    doAssert binarySearch(moreData, -1) == -1
    doAssert binarySearch(moreData,  1) == 0
    doAssert binarySearch(moreData,  5) == 2
    doAssert binarySearch(moreData,  6) == -1
    doAssert binarySearch(moreData,  4711) == 4
    doAssert binarySearch(moreData,  4712) == -1
