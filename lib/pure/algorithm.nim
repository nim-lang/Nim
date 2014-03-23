#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements some common generic algorithms.

type
  TSortOrder* = enum   ## sort order
    Descending, Ascending 

proc `*`*(x: int, order: TSortOrder): int {.inline.} = 
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

proc lowerBound*[T](a: openarray[T], key: T, cmp: proc(x,y: T): int {.closure.}): int =
  ## same as binarySearch except that if key is not in `a` then this 
  ## returns the location where `key` would be if it were. In other
  ## words if you have a sorted sequence and you call insert(thing, elm, lowerBound(thing, elm))
  ## the sequence will still be sorted
  ##
  ## `cmp` is the comparator function to use, the expected return values are the same as
  ## that of system.cmp
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

proc lowerBound*[T](a: openarray[T], key: T): int = lowerBound(a, key, system.cmp[T])
proc merge[T](a, b: var openArray[T], lo, m, hi: int, 
              cmp: proc (x, y: T): int {.closure.}, order: TSortOrder) =
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
              order = TSortOrder.Ascending) =
  ## Default Nimrod sort. The sorting is guaranteed to be stable and 
  ## the worst case is guaranteed to be O(n log n).
  ## The current implementation uses an iterative
  ## mergesort to achieve this. It uses a temporary sequence of 
  ## length ``a.len div 2``. Currently Nimrod does not support a
  ## sensible default argument for ``cmp``, so you have to provide one
  ## of your own. However, the ``system.cmp`` procs can be used:
  ##
  ## .. code-block:: nimrod
  ##
  ##    sort(myIntArray, system.cmp[int])
  ##
  ##    # do not use cmp[string] here as we want to use the specialized
  ##    # overload:
  ##    sort(myStrArray, system.cmp)
  ##
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

proc product*[T](x: openarray[seq[T]]): seq[seq[T]] =
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
