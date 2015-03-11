#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements some common generic algorithms.

type
  SortOrder* = enum   ## sort order
    Descending, Ascending

{.deprecated: [TSortOrder: SortOrder].}


proc `*`*(x: int, order: SortOrder): int {.inline.} =
  ## flips `x` if ``order == Descending``;
  ## if ``order == Ascending`` then `x` is returned.
  ## `x` is supposed to be the result of a comparator, ie ``< 0`` for
  ## *less than*, ``== 0`` for *equal*, ``> 0`` for *greater than*.
  var y = order.ord - 1
  result = (x xor y) - y

proc reverse*[T](a: var openArray[T], first, last: int) =
  ## reverses the array ``a[first..last]``.
  var x = first
  var y = last
  while x < y:
    swap(a[x], a[y])
    dec(y)
    inc(x)

proc reverse*[T](a: var openArray[T]) =
  ## reverses the array `a`.
  reverse(a, 0, a.high)

proc reversed*[T](a: openArray[T], first, last: int): seq[T] =
  ## returns the reverse of the array `a[first..last]`.
  result = newSeq[T](last - first + 1)
  var x = first
  var y = last
  while x <= last:
    result[x] = a[y]
    dec(y)
    inc(x)

proc reversed*[T](a: openArray[T]): seq[T] =
  ## returns the reverse of the array `a`.
  reversed(a, 0, a.high)

proc binarySearch*[T](a: openArray[T], key: T): int =
  ## binary search for `key` in `a`. Returns -1 if not found.
  var b = len(a)
  while result < b:
    var mid = (result + b) div 2
    if a[mid] < key: result = mid + 1
    else: b = mid
  if result >= len(a) or a[result] != key: result = -1

proc smartBinarySearch*[T](a: openArray[T], key: T): int =
  ## ``a.len`` must be a power of 2 for this to work.
  var step = a.len div 2
  while step > 0:
    if a[result or step] <= key:
      result = result or step
    step = step shr 1
  if a[result] != key: result = -1

const
  onlySafeCode = true

proc lowerBound*[T](a: openArray[T], key: T, cmp: proc(x,y: T): int {.closure.}): int =
  ## same as binarySearch except that if key is not in `a` then this
  ## returns the location where `key` would be if it were. In other
  ## words if you have a sorted sequence and you call
  ## insert(thing, elm, lowerBound(thing, elm))
  ## the sequence will still be sorted.
  ##
  ## `cmp` is the comparator function to use, the expected return values are
  ## the same as that of system.cmp.
  ##
  ## example::
  ##
  ##   var arr = @[1,2,3,5,6,7,8,9]
  ##   arr.insert(4, arr.lowerBound(4))
  ## `after running the above arr is `[1,2,3,4,5,6,7,8,9]`
  result = a.low
  var pos = result
  var count, step: int
  count = a.high - a.low + 1
  while count != 0:
    pos = result
    step = count div 2
    pos += step
    if cmp(a[pos], key) < 0:
      pos.inc
      result = pos
      count -= step + 1
    else:
      count = step

proc lowerBound*[T](a: openArray[T], key: T): int = lowerBound(a, key, cmp[T])
proc merge[T](a, b: var openArray[T], lo, m, hi: int,
              cmp: proc (x, y: T): int {.closure.}, order: SortOrder) =
  template `<-` (a, b: expr) =
    when false:
      a = b
    elif onlySafeCode:
      shallowCopy(a, b)
    else:
      copyMem(addr(a), addr(b), sizeof(T))
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
  ## Default Nim sort. The sorting is guaranteed to be stable and
  ## the worst case is guaranteed to be O(n log n).
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
  ## <manual.html#do-notation>`_. Example:
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

template sortedByIt*(seq1, op: expr): expr =
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
  ##
  ##   people = @[p1,p2,p4,p3]
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
  var result {.gensym.} = sorted(seq1, proc(x, y: type(seq1[0])): int =
    var it {.inject.} = x
    let a = op
    it = y
    let b = op
    result = cmp(a, b))
  result

proc product*[T](x: openArray[seq[T]]): seq[seq[T]] =
  ## produces the Cartesian product of the array. Warning: complexity
  ## may explode.
  result = @[]
  if x.len == 0:
    return
  if x.len == 1:
    result = @x
    return
  var
    indexes = newSeq[int](x.len)
    initial = newSeq[int](x.len)
    index = 0
  # replace with newSeq as soon as #853 is fixed
  var next: seq[T] = @[]
  next.setLen(x.len)
  for i in 0..(x.len-1):
    if len(x[i]) == 0: return
    initial[i] = len(x[i])-1
  indexes = initial
  while true:
    while indexes[index] == -1:
      indexes[index] = initial[index]
      index +=1
      if index == x.len: return
      indexes[index] -=1
    for ni, i in indexes:
      next[ni] = x[ni][i]
    var res: seq[T]
    shallowCopy(res, next)
    result.add(res)
    index = 0
    indexes[index] -=1

proc nextPermutation*[T](x: var openarray[T]): bool {.discardable.} =
  ## Calculates the next lexicographic permutation, directly modifying ``x``.
  ## The result is whether a permutation happened, otherwise we have reached
  ## the last-ordered permutation.
  ##
  ## .. code-block:: nim
  ##
  ##     var v = @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  ##     v.nextPermutation()
  ##     echo v
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
  ##     echo v
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
