
# design criteria:
# Generic code is expenisve wrt code size!
# So the implementation should be small.
# The sort should be stable.
# 

proc sort[T](arr: var openArray[T], lo, hi: natural) =
  var k = 0
  if lo < hi:
    var mid = (lo + hi) div 2
    sort(arr, lo, mid)
    inc(mid)
    sort(arr, mid, hi)
    while lo < mid and mid <= hi:
      if arr[lo] < arr[mid]:
        inc(lo)
      else:
        when swapIsExpensive(T):
          var help = arr[mid]
          for k in countdown(mid, succ(lo)):
            arr[k] = arr[pred(k)]
          arr[lo] = help
        else:
          for k in countdown(mid, succ(lo)):
            swap(arr[k], arr[pred(k)])
        inc(lo)
        inc(mid)
  
type
  TSortOrder* = enum
    Descending = -1,
    Ascending = 0

proc flip(x: int, order: TSortOrder): int {.inline.} = 
  result = x xor ord(order) - ord(order)

# We use a fixed size stack. This size is larger
# than can be overflowed on a 64-bit machine
const
  stackSize = 66
  minRunSize = 7

type
  TRun = tuple[index, length: int]
  TSortState[T] {.pure, final.} = object
    storage: seq[T]
    runs: array[0..stackSize-1, TRun]
    stackHeight: int # The index of the first unwritten element of the stack.
    partitionedUpTo, length: int

# We keep track of how far we've partitioned up 
# to so we know where to start the next partition.
# The idea is that everything < partionedUpTo 
# is on the stack, everything >= partionedUpTo
# is not yet on the stack. When partitionedUpTo == length
# we'll have put everything on the stack.
  
proc reverse[T](a: var openArray[T], first, last: int) =
  for j in first .. < first+length div 2: swap(a[j], a[length-j-1])

proc insertionSort[T]( int xs[], int length) =
  for i in 1.. < length:
    # The array before i is sorted. Now insert xs[i] into it
    var x = xs[i]
    var j = i-1
    # Move j down until it's either at the beginning or on
    # something <= x, and everything to the right of it has
    # been moved up one.
    while j >= 0 and xs[j] > x:
      xs[j+1] = xs[j]
      dec j
    xs[j+1] = x

proc boostRunLength(s: TSortState, run: var TRun) =
  # Need to make sure we don't overshoot the end of the array
  var length = min(s.length - run.index, minRunSize)
  insertionSort(run.index, length)
  run.length = length

proc nextPartition[T](a: var openarray[T], s: var TSortState): bool =
  if s.partitionedUpTo >= s.length: return false
  var startIndex = s.partitionedUpTo
  # Find an increasing run starting from startIndex
  var nextStartIndex = startIndex + 1

  if nextStartIndex < s.length:
    if a[nextStartIndex] < a[startIndex]:
      # We have a decreasing sequence starting here.
      while nextStartIndex < s.length:
        if a[nextStartIndex] < a[nextStartIndex-1]: inc(nextStartIndex)
        else: break
      # Now reverse it in place.
      reverse(a, startIndex, nextStartIndex)
    else:
      # We have an increasing sequence starting here.
      while nextStartIndex < s.length:
        if a[nextStartIndex] >= a[nextStartIndex-1]: inc(nextStartIndex)
        else: break

  # So now [startIndex, nextStartIndex) is an increasing run.
  # Push it onto the stack.
  var runToAdd: TRun = (startIndex, nextStartIndex - startIndex)
  if runToAdd.length < minRunSize:
    boostRunLength(s, runToAdd)
  s.partitionedUpTo = startIndex + runToAdd.length

  s.runs[s.stackHeight] = runToAdd
  inc s.stackHeight
  result = true

proc shouldCollapse(s: TSortState): bool =
  if s.stackHeight > 2: 
    var h = s.stackHeight-1
    var headLength = s.runs[h].length
    var nextLength = s.runs[h-1].length
    result = 2 * headLength > nextLength

proc merge(int target[], int p1[], int l1, int p2[], int l2, int storage[]) =
  # Merge the sorted arrays p1, p2 of length l1, l2 into a single
  # sorted array starting at target. target may overlap with either
  # of p1 or p2 but must have enough space to store the array.
  # Use the storage argument for temporary storage. It must have room for
  # l1 + l2 ints.
  int *merge_to = storage

  # Current index into each of the two arrays we're writing
  # from.
  int i1, i2;
  i1 = i2 = 0;

  # The address to which we write the next element in the merge
  int *next_merge_element = merge_to;

  # Iterate over the two arrays, writing the least element at the
  # current position to merge_to. When the two are equal we prefer
  # the left one, because if we're merging left, right we want to
  # ensure stability.
  # Of course this doesn't matter for integers, but it's the thought
  # that counts.
  while i1 < l1 and i2 < l2:
    if p1[i1] <= p2[i2]:
      *next_merge_element = p1[i1];
      i1++
    else:
      *next_merge_element = p2[i2];
      i2++
    next_merge_element++

  # If we stopped short before the end of one of the arrays
  # we now copy the rest over.
  memcpy(next_merge_element, p1 + i1, sizeof(int) * (l1 - i1));
  memcpy(next_merge_element, p2 + i2, sizeof(int) * (l2 - i2));

  # We've now merged into our additional working space. Time
  # to copy to the target.
  memcpy(target, merge_to, sizeof(int) * (l1 + l2));


proc mergeCollapse(a:  s: var TSortState) =
  var X = s.runs[s.stackHeight-2]
  var Y = s.runs[s.stackHeight-1]

  merge(X.index, X.index, X.length, Y.index, Y.length, s.storage)

  dec s.stackHeight
  inc X.length, Y.length
  s.runs[s.stackHeight-1] = X

proc sort[T](arr: var openArray[T], first, last: natural, 
             cmp: proc (x,y: T): int, order = TSortOrder.ascending) =
  var s: TSortState
  newSeq(s.storage, arr.len)
  s.stackHeight = 0
  s.partitionedUpTo = 0
  s.length = arr.len

  while nextPartition(s):
    while shouldCollapse(s): mergeCollapse(s)
  while s.stackHeight > 1: mergeCollapse(s)

proc sort[T](arr: var openArray[T], cmp: proc (x, y: T): int = cmp, 
             order = TSortOrder.ascending) = 
  sort(arr, 0, high(arr), order)

