#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements some common generic algorithms.
##
## Basic usage
## ===========
## 

runnableExamples:
  type People = tuple
    year: int
    name: string

  var a: seq[People]

  a.add((2000, "John"))
  a.add((2005, "Marie"))
  a.add((2010, "Jane"))

  # Sorting with default system.cmp
  a.sort()
  assert a == @[(year: 2000, name: "John"), (year: 2005, name: "Marie"),
                (year: 2010, name: "Jane")]

  proc myCmp(x, y: People): int =
    if x.name < y.name: -1
    elif x.name == y.name: 0
    else: 1

  # Sorting with custom proc
  a.sort(myCmp)
  assert a == @[(year: 2010, name: "Jane"), (year: 2000, name: "John"),
                (year: 2005, name: "Marie")]

## See also
## ========
## * `sequtils module<sequtils.html>`_ for working with the built-in seq type
## * `tables module<tables.html>`_ for sorting tables

type
  SortOrder* = enum
    Descending, Ascending

func `*`*(x: int, order: SortOrder): int {.inline.} =
  ## Flips ``x`` if ``order == Descending``.
  ## If ``order == Ascending`` then ``x`` is returned.
  ##
  ## ``x`` is supposed to be the result of a comparator, i.e.
  ## | ``< 0`` for *less than*,
  ## | ``== 0`` for *equal*,
  ## | ``> 0`` for *greater than*.
  runnableExamples:
    assert `*`(-123, Descending) == 123
    assert `*`(123, Descending) == -123
    assert `*`(-123, Ascending) == -123
    assert `*`(123, Ascending) == 123
  var y = order.ord - 1
  result = (x xor y) - y

template fillImpl[T](a: var openArray[T], first, last: int, value: T) =
  var x = first
  while x <= last:
    a[x] = value
    inc(x)

func fill*[T](a: var openArray[T], first, last: Natural, value: T) =
  ## Fills the slice ``a[first..last]`` with ``value``.
  ##
  ## If an invalid range is passed, it raises IndexDefect.
  runnableExamples:
    var a: array[6, int]
    a.fill(1, 3, 9)
    assert a == [0, 9, 9, 9, 0, 0]
    a.fill(3, 5, 7)
    assert a == [0, 9, 9, 7, 7, 7]
    doAssertRaises(IndexDefect, a.fill(1, 7, 9))
  fillImpl(a, first, last, value)

func fill*[T](a: var openArray[T], value: T) =
  ## Fills the container ``a`` with ``value``.
  runnableExamples:
    var a: array[6, int]
    a.fill(9)
    assert a == [9, 9, 9, 9, 9, 9]
    a.fill(4)
    assert a == [4, 4, 4, 4, 4, 4]
  fillImpl(a, 0, a.high, value)


func reverse*[T](a: var openArray[T], first, last: Natural) =
  ## Reverses the slice ``a[first..last]``.
  ##
  ## If an invalid range is passed, it raises IndexDefect.
  ##
  ## **See also:**
  ## * `reversed func<#reversed,openArray[T],Natural,int>`_ reverse a slice and returns a ``seq[T]``
  ## * `reversed func<#reversed,openArray[T]>`_ reverse and returns a ``seq[T]``
  runnableExamples:
    var a = [1, 2, 3, 4, 5, 6]
    a.reverse(1, 3)
    assert a == [1, 4, 3, 2, 5, 6]
    a.reverse(1, 3)
    assert a == [1, 2, 3, 4, 5, 6]
    doAssertRaises(IndexDefect, a.reverse(1, 7))
  var x = first
  var y = last
  while x < y:
    swap(a[x], a[y])
    dec(y)
    inc(x)

func reverse*[T](a: var openArray[T]) =
  ## Reverses the contents of the container ``a``.
  ##
  ## **See also:**
  ## * `reversed func<#reversed,openArray[T],Natural,int>`_ reverse a slice and returns a ``seq[T]``
  ## * `reversed func<#reversed,openArray[T]>`_ reverse and returns a ``seq[T]``
  runnableExamples:
    var a = [1, 2, 3, 4, 5, 6]
    a.reverse()
    assert a == [6, 5, 4, 3, 2, 1]
    a.reverse()
    assert a == [1, 2, 3, 4, 5, 6]
  reverse(a, 0, max(0, a.high))

func reversed*[T](a: openArray[T], first: Natural, last: int): seq[T] =
  ## Returns the reverse of the slice ``a[first..last]``.
  ##
  ## If an invalid range is passed, it raises IndexDefect.
  ##
  ## **See also:**
  ## * `reverse func<#reverse,openArray[T],Natural,Natural>`_ reverse a slice
  ## * `reverse func<#reverse,openArray[T]>`_
  runnableExamples:
    let
      a = [1, 2, 3, 4, 5, 6]
      b = a.reversed(1, 3)
    assert b == @[4, 3, 2]
  assert last >= first-1
  var i = last - first
  var x = first.int
  result = newSeq[T](i + 1)
  while i >= 0:
    result[i] = a[x]
    dec(i)
    inc(x)

func reversed*[T](a: openArray[T]): seq[T] =
  ## Returns the reverse of the container ``a``.
  ##
  ## **See also:**
  ## * `reverse func<#reverse,openArray[T],Natural,Natural>`_ reverse a slice
  ## * `reverse func<#reverse,openArray[T]>`_
  runnableExamples:
    let
      a = [1, 2, 3, 4, 5, 6]
      b = reversed(a)
    assert b == @[6, 5, 4, 3, 2, 1]
  reversed(a, 0, a.high)

func binarySearch*[T, K](a: openArray[T], key: K,
              cmp: proc (x: T, y: K): int {.closure.}): int =
  ## Binary search for ``key`` in ``a``. Returns -1 if not found.
  ##
  ## ``cmp`` is the comparator function to use, the expected return values are
  ## the same as that of system.cmp.
  runnableExamples:
    assert binarySearch(["a", "b", "c", "d"], "d", system.cmp[string]) == 3
    assert binarySearch(["a", "b", "d", "c"], "d", system.cmp[string]) == 2
  if a.len == 0:
    return -1

  let len = a.len

  if len == 1:
    if cmp(a[0], key) == 0:
      return 0
    else:
      return -1

  result = 0
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

func binarySearch*[T](a: openArray[T], key: T): int =
  ## Binary search for ``key`` in ``a``. Returns -1 if not found.
  runnableExamples:
    assert binarySearch([0, 1, 2, 3, 4], 4) == 4
    assert binarySearch([0, 1, 4, 2, 3], 4) == 2
  binarySearch(a, key, cmp[T])

const
  onlySafeCode = true

func lowerBound*[T, K](a: openArray[T], key: K, cmp: proc(x: T, k: K): int {.
    closure.}): int =
  ## Returns a position to the first element in the ``a`` that is greater than
  ## ``key``, or last if no such element is found.
  ## In other words if you have a sorted sequence and you call
  ## ``insert(thing, elm, lowerBound(thing, elm))``
  ## the sequence will still be sorted.
  ##
  ## If an invalid range is passed, it raises IndexDefect.
  ##
  ## The version uses ``cmp`` to compare the elements.
  ## The expected return values are the same as that of ``system.cmp``.
  ##
  ## **See also:**
  ## * `upperBound func<#upperBound,openArray[T],K,proc(T,K)>`_ sorted by ``cmp`` in the specified order
  ## * `upperBound func<#upperBound,openArray[T],T>`_
  runnableExamples:
    var arr = @[1, 2, 3, 5, 6, 7, 8, 9]
    assert arr.lowerBound(3, system.cmp[int]) == 2
    assert arr.lowerBound(4, system.cmp[int]) == 3
    assert arr.lowerBound(5, system.cmp[int]) == 3
    arr.insert(4, arr.lowerBound(4, system.cmp[int]))
    assert arr == [1, 2, 3, 4, 5, 6, 7, 8, 9]
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

func lowerBound*[T](a: openArray[T], key: T): int = lowerBound(a, key, cmp[T])
  ## Returns a position to the first element in the ``a`` that is greater than
  ## ``key``, or last if no such element is found.
  ## In other words if you have a sorted sequence and you call
  ## ``insert(thing, elm, lowerBound(thing, elm))``
  ## the sequence will still be sorted.
  ##
  ## The version uses the default comparison function ``cmp``.
  ##
  ## **See also:**
  ## * `upperBound func<#upperBound,openArray[T],K,proc(T,K)>`_ sorted by ``cmp`` in the specified order
  ## * `upperBound func<#upperBound,openArray[T],T>`_

func upperBound*[T, K](a: openArray[T], key: K, cmp: proc(x: T, k: K): int {.
    closure.}): int =
  ## Returns a position to the first element in the ``a`` that is not less
  ## (i.e. greater or equal to) than ``key``, or last if no such element is found.
  ## In other words if you have a sorted sequence and you call
  ## ``insert(thing, elm, upperBound(thing, elm))``
  ## the sequence will still be sorted.
  ##
  ## If an invalid range is passed, it raises IndexDefect.
  ##
  ## The version uses ``cmp`` to compare the elements. The expected
  ## return values are the same as that of ``system.cmp``.
  ##
  ## **See also:**
  ## * `lowerBound func<#lowerBound,openArray[T],K,proc(T,K)>`_ sorted by ``cmp`` in the specified order
  ## * `lowerBound func<#lowerBound,openArray[T],T>`_
  runnableExamples:
    var arr = @[1, 2, 3, 5, 6, 7, 8, 9]
    assert arr.upperBound(2, system.cmp[int]) == 2
    assert arr.upperBound(3, system.cmp[int]) == 3
    assert arr.upperBound(4, system.cmp[int]) == 3
    arr.insert(4, arr.upperBound(3, system.cmp[int]))
    assert arr == [1, 2, 3, 4, 5, 6, 7, 8, 9]
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

func upperBound*[T](a: openArray[T], key: T): int = upperBound(a, key, cmp[T])
  ## Returns a position to the first element in the ``a`` that is not less
  ## (i.e. greater or equal to) than ``key``, or last if no such element is found.
  ## In other words if you have a sorted sequence and you call
  ## ``insert(thing, elm, upperBound(thing, elm))``
  ## the sequence will still be sorted.
  ##
  ## The version uses the default comparison function ``cmp``.
  ##
  ## **See also:**
  ## * `lowerBound func<#lowerBound,openArray[T],K,proc(T,K)>`_ sorted by ``cmp`` in the specified order
  ## * `lowerBound func<#lowerBound,openArray[T],T>`_

template `<-` (a, b) =
  when defined(gcDestructors):
    a = move b
  elif onlySafeCode:
    shallowCopy(a, b)
  else:
    copyMem(addr(a), addr(b), sizeof(T))

func merge[T](a, b: var openArray[T], lo, m, hi: int,
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

func sort*[T](a: var openArray[T],
              cmp: proc (x, y: T): int {.closure.},
              order = SortOrder.Ascending) =
  ## Default Nim sort (an implementation of merge sort). The sorting
  ## is guaranteed to be stable and the worst case is guaranteed to
  ## be O(n log n).
  ##
  ## The current implementation uses an iterative
  ## mergesort to achieve this. It uses a temporary sequence of
  ## length ``a.len div 2``. If you do not wish to provide your own
  ## ``cmp``, you may use ``system.cmp`` or instead call the overloaded
  ## version of ``sort``, which uses ``system.cmp``.
  ##
  ## .. code-block:: nim
  ##
  ##    sort(myIntArray, system.cmp[int])
  ##    # do not use cmp[string] here as we want to use the specialized
  ##    # overload:
  ##    sort(myStrArray, system.cmp)
  ##
  ## You can inline adhoc comparison procs with the `do notation
  ## <manual_experimental.html#do-notation>`_. Example:
  ##
  ## .. code-block:: nim
  ##
  ##   people.sort do (x, y: Person) -> int:
  ##     result = cmp(x.surname, y.surname)
  ##     if result == 0:
  ##       result = cmp(x.name, y.name)
  ##
  ## **See also:**
  ## * `sort func<#sort,openArray[T]>`_
  ## * `sorted func<#sorted,openArray[T],proc(T,T)>`_ sorted by ``cmp`` in the specified order
  ## * `sorted func<#sorted,openArray[T]>`_
  ## * `sortedByIt template<#sortedByIt.t,untyped,untyped>`_
  runnableExamples:
    var d = ["boo", "fo", "barr", "qux"]
    proc myCmp(x, y: string): int =
      if x.len() > y.len() or x.len() == y.len(): 1
      else: -1
    sort(d, myCmp)
    assert d == ["fo", "qux", "boo", "barr"]
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

func sort*[T](a: var openArray[T], order = SortOrder.Ascending) = sort[T](a,
    system.cmp[T], order)
  ## Shortcut version of ``sort`` that uses ``system.cmp[T]`` as the comparison function.
  ##
  ## **See also:**
  ## * `sort func<#sort,openArray[T],proc(T,T)>`_
  ## * `sorted func<#sorted,openArray[T],proc(T,T)>`_ sorted by ``cmp`` in the specified order
  ## * `sorted func<#sorted,openArray[T]>`_
  ## * `sortedByIt template<#sortedByIt.t,untyped,untyped>`_

func sorted*[T](a: openArray[T], cmp: proc(x, y: T): int {.closure.},
                order = SortOrder.Ascending): seq[T] =
  ## Returns ``a`` sorted by ``cmp`` in the specified ``order``.
  ##
  ## **See also:**
  ## * `sort func<#sort,openArray[T],proc(T,T)>`_
  ## * `sort func<#sort,openArray[T]>`_
  ## * `sortedByIt template<#sortedByIt.t,untyped,untyped>`_
  runnableExamples:
    let
      a = [2, 3, 1, 5, 4]
      b = sorted(a, system.cmp[int])
      c = sorted(a, system.cmp[int], Descending)
      d = sorted(["adam", "dande", "brian", "cat"], system.cmp[string])
    assert b == @[1, 2, 3, 4, 5]
    assert c == @[5, 4, 3, 2, 1]
    assert d == @["adam", "brian", "cat", "dande"]
  result = newSeq[T](a.len)
  for i in 0 .. a.high:
    result[i] = a[i]
  sort(result, cmp, order)

func sorted*[T](a: openArray[T], order = SortOrder.Ascending): seq[T] =
  ## Shortcut version of ``sorted`` that uses ``system.cmp[T]`` as the comparison function.
  ##
  ## **See also:**
  ## * `sort func<#sort,openArray[T],proc(T,T)>`_
  ## * `sort func<#sort,openArray[T]>`_
  ## * `sortedByIt template<#sortedByIt.t,untyped,untyped>`_
  runnableExamples:
    let
      a = [2, 3, 1, 5, 4]
      b = sorted(a)
      c = sorted(a, Descending)
      d = sorted(["adam", "dande", "brian", "cat"])
    assert b == @[1, 2, 3, 4, 5]
    assert c == @[5, 4, 3, 2, 1]
    assert d == @["adam", "brian", "cat", "dande"]
  sorted[T](a, system.cmp[T], order)

template sortedByIt*(seq1, op: untyped): untyped =
  ## Convenience template around the ``sorted`` proc to reduce typing.
  ##
  ## The template injects the ``it`` variable which you can use directly in an
  ## expression.
  ##
  ## Because the underlying ``cmp()`` is defined for tuples you can do
  ## a nested sort.
  ##
  ## **See also:**
  ## * `sort func<#sort,openArray[T],proc(T,T)>`_
  ## * `sort func<#sort,openArray[T]>`_
  ## * `sorted func<#sorted,openArray[T],proc(T,T)>`_ sorted by ``cmp`` in the specified order
  ## * `sorted func<#sorted,openArray[T]>`_
  runnableExamples:
    type Person = tuple[name: string, age: int]
    var
      p1: Person = (name: "p1", age: 60)
      p2: Person = (name: "p2", age: 20)
      p3: Person = (name: "p3", age: 30)
      p4: Person = (name: "p4", age: 30)
      people = @[p1, p2, p4, p3]

    assert people.sortedByIt(it.name) == @[(name: "p1", age: 60), (name: "p2",
        age: 20), (name: "p3", age: 30), (name: "p4", age: 30)]
    # Nested sort
    assert people.sortedByIt((it.age, it.name)) == @[(name: "p2", age: 20),
       (name: "p3", age: 30), (name: "p4", age: 30), (name: "p1", age: 60)]
  var result = sorted(seq1, proc(x, y: typeof(items(seq1), typeOfIter)): int =
    var it {.inject.} = x
    let a = op
    it = y
    let b = op
    result = cmp(a, b))
  result

func isSorted*[T](a: openArray[T],
                 cmp: proc(x, y: T): int {.closure.},
                 order = SortOrder.Ascending): bool =
  ## Checks to see whether ``a`` is already sorted in ``order``
  ## using ``cmp`` for the comparison. Parameters identical
  ## to ``sort``. Requires O(n) time.
  ##
  ## **See also:**
  ## * `isSorted func<#isSorted,openArray[T]>`_
  runnableExamples:
    let
      a = [2, 3, 1, 5, 4]
      b = [1, 2, 3, 4, 5]
      c = [5, 4, 3, 2, 1]
      d = ["adam", "brian", "cat", "dande"]
      e = ["adam", "dande", "brian", "cat"]
    assert isSorted(a) == false
    assert isSorted(b) == true
    assert isSorted(c) == false
    assert isSorted(c, Descending) == true
    assert isSorted(d) == true
    assert isSorted(e) == false
  result = true
  for i in 0..<len(a)-1:
    if cmp(a[i], a[i+1]) * order > 0:
      return false

func isSorted*[T](a: openArray[T], order = SortOrder.Ascending): bool =
  ## Shortcut version of ``isSorted`` that uses ``system.cmp[T]`` as the comparison function.
  ##
  ## **See also:**
  ## * `isSorted func<#isSorted,openArray[T],proc(T,T)>`_
  runnableExamples:
    let
      a = [2, 3, 1, 5, 4]
      b = [1, 2, 3, 4, 5]
      c = [5, 4, 3, 2, 1]
      d = ["adam", "brian", "cat", "dande"]
      e = ["adam", "dande", "brian", "cat"]
    assert isSorted(a) == false
    assert isSorted(b) == true
    assert isSorted(c) == false
    assert isSorted(c, Descending) == true
    assert isSorted(d) == true
    assert isSorted(e) == false
  isSorted(a, system.cmp[T], order)

func product*[T](x: openArray[seq[T]]): seq[seq[T]] =
  ## Produces the Cartesian product of the array. Warning: complexity
  ## may explode.
  runnableExamples:
    assert product(@[@[1], @[2]]) == @[@[1, 2]]
    assert product(@[@["A", "K"], @["Q"]]) == @[@["K", "Q"], @["A", "Q"]]
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
    result.add(next)
    index = 0
    indexes[index] -= 1

func nextPermutation*[T](x: var openArray[T]): bool {.discardable.} =
  ## Calculates the next lexicographic permutation, directly modifying ``x``.
  ## The result is whether a permutation happened, otherwise we have reached
  ## the last-ordered permutation.
  ##
  ## If you start with an unsorted array/seq, the repeated permutations
  ## will **not** give you all permutations but stop with last.
  ##
  ## **See also:**
  ## * `prevPermutation func<#prevPermutation,openArray[T]>`_
  runnableExamples:
    var v = @[0, 1, 2, 3]
    assert v.nextPermutation() == true
    assert v == @[0, 1, 3, 2]
    assert v.nextPermutation() == true
    assert v == @[0, 2, 1, 3]
    assert v.prevPermutation() == true
    assert v == @[0, 1, 3, 2]
    v = @[3, 2, 1, 0]
    assert v.nextPermutation() == false
    assert v == @[3, 2, 1, 0]
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

func prevPermutation*[T](x: var openArray[T]): bool {.discardable.} =
  ## Calculates the previous lexicographic permutation, directly modifying
  ## ``x``. The result is whether a permutation happened, otherwise we have
  ## reached the first-ordered permutation.
  ##
  ## **See also:**
  ## * `nextPermutation func<#nextPermutation,openArray[T]>`_
  runnableExamples:
    var v = @[0, 1, 2, 3]
    assert v.prevPermutation() == false
    assert v == @[0, 1, 2, 3]
    assert v.nextPermutation() == true
    assert v == @[0, 1, 3, 2]
    assert v.prevPermutation() == true
    assert v == @[0, 1, 2, 3]
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

func rotateInternal[T](arg: var openArray[T]; first, middle, last: int): int =
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

func rotatedInternal[T](arg: openArray[T]; first, middle, last: int): seq[T] =
  result = newSeq[T](arg.len)
  for i in 0 ..< first:
    result[i] = arg[i]
  let n = last - middle
  let m = middle - first
  for i in 0 ..< n:
    result[first+i] = arg[middle+i]
  for i in 0 ..< m:
    result[first+n+i] = arg[first+i]
  for i in last ..< arg.len:
    result[i] = arg[i]

func rotateLeft*[T](arg: var openArray[T]; slice: HSlice[int, int];
    dist: int): int {.discardable.} =
  ## Performs a left rotation on a range of elements. If you want to rotate
  ## right, use a negative ``dist``. Specifically, ``rotateLeft`` rotates
  ## the elements at ``slice`` by ``dist`` positions.
  ##
  ## | The element at index ``slice.a + dist`` will be at index ``slice.a``.
  ## | The element at index ``slice.b`` will be at ``slice.a + dist -1``.
  ## | The element at index ``slice.a`` will be at ``slice.b + 1 - dist``.
  ## | The element at index ``slice.a + dist - 1`` will be at ``slice.b``.
  ##
  ## Elements outside of ``slice`` will be left unchanged.
  ## The time complexity is linear to ``slice.b - slice.a + 1``.
  ## If an invalid range (``HSlice``) is passed, it raises IndexDefect.
  ##
  ## ``slice``
  ##   The indices of the element range that should be rotated.
  ##
  ## ``dist``
  ##   The distance in amount of elements that the data should be rotated.
  ##   Can be negative, can be any number.
  ##
  ## **See also:**
  ## * `rotateLeft func<#rotateLeft,openArray[T],int>`_ for a version which rotates the whole container
  ## * `rotatedLeft func<#rotatedLeft,openArray[T],HSlice[int,int],int>`_ for a version which returns a ``seq[T]``
  runnableExamples:
    var a = [0, 1, 2, 3, 4, 5]
    a.rotateLeft(1 .. 4, 3)
    assert a == [0, 4, 1, 2, 3, 5]
    a.rotateLeft(1 .. 4, 3)
    assert a == [0, 3, 4, 1, 2, 5]
    a.rotateLeft(1 .. 4, -3)
    assert a == [0, 4, 1, 2, 3, 5]
    doAssertRaises(IndexDefect, a.rotateLeft(1 .. 7, 2))
  let sliceLen = slice.b + 1 - slice.a
  let distLeft = ((dist mod sliceLen) + sliceLen) mod sliceLen
  arg.rotateInternal(slice.a, slice.a+distLeft, slice.b + 1)

func rotateLeft*[T](arg: var openArray[T]; dist: int): int {.discardable.} =
  ## Default arguments for slice, so that this procedure operates on the entire
  ## ``arg``, and not just on a part of it.
  ##
  ## **See also:**
  ## * `rotateLeft func<#rotateLeft,openArray[T],HSlice[int,int],int>`_ for a version which rotates a range
  ## * `rotatedLeft func<#rotatedLeft,openArray[T],int>`_ for a version which returns a ``seq[T]``
  runnableExamples:
    var a = [1, 2, 3, 4, 5]
    a.rotateLeft(2)
    assert a == [3, 4, 5, 1, 2]
    a.rotateLeft(4)
    assert a == [2, 3, 4, 5, 1]
    a.rotateLeft(-6)
    assert a == [1, 2, 3, 4, 5]
  let arglen = arg.len
  let distLeft = ((dist mod arglen) + arglen) mod arglen
  arg.rotateInternal(0, distLeft, arglen)

func rotatedLeft*[T](arg: openArray[T]; slice: HSlice[int, int],
    dist: int): seq[T] =
  ## Same as ``rotateLeft``, just with the difference that it does
  ## not modify the argument. It creates a new ``seq`` instead.
  ##
  ## Elements outside of ``slice`` will be left unchanged.
  ## If an invalid range (``HSlice``) is passed, it raises IndexDefect.
  ##
  ## ``slice``
  ##   The indices of the element range that should be rotated.
  ##
  ## ``dist``
  ##   The distance in amount of elements that the data should be rotated.
  ##   Can be negative, can be any number.
  ##
  ## **See also:**
  ## * `rotateLeft func<#rotateLeft,openArray[T],HSlice[int,int],int>`_ for the in-place version of this proc
  ## * `rotatedLeft func<#rotatedLeft,openArray[T],int>`_ for a version which rotates the whole container
  runnableExamples:
    var a = @[1, 2, 3, 4, 5]
    a = rotatedLeft(a, 1 .. 4, 3)
    assert a == @[1, 5, 2, 3, 4]
    a = rotatedLeft(a, 1 .. 3, 2)
    assert a == @[1, 3, 5, 2, 4]
    a = rotatedLeft(a, 1 .. 3, -2)
    assert a == @[1, 5, 2, 3, 4]
  let sliceLen = slice.b + 1 - slice.a
  let distLeft = ((dist mod sliceLen) + sliceLen) mod sliceLen
  arg.rotatedInternal(slice.a, slice.a+distLeft, slice.b+1)

func rotatedLeft*[T](arg: openArray[T]; dist: int): seq[T] =
  ## Same as ``rotateLeft``, just with the difference that it does
  ## not modify the argument. It creates a new ``seq`` instead.
  ##
  ## **See also:**
  ## * `rotateLeft func<#rotateLeft,openArray[T],int>`_ for the in-place version of this proc
  ## * `rotatedLeft func<#rotatedLeft,openArray[T],HSlice[int,int],int>`_ for a version which rotates a range
  runnableExamples:
    var a = @[1, 2, 3, 4, 5]
    a = rotatedLeft(a, 2)
    assert a == @[3, 4, 5, 1, 2]
    a = rotatedLeft(a, 4)
    assert a == @[2, 3, 4, 5, 1]
    a = rotatedLeft(a, -6)
    assert a == @[1, 2, 3, 4, 5]
  let arglen = arg.len
  let distLeft = ((dist mod arglen) + arglen) mod arglen
  arg.rotatedInternal(0, distLeft, arg.len)
