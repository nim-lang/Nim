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

