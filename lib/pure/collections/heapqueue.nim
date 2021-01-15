#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Yuriy Glukhov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.


## The `heapqueue` module implements a
## `heap data structure<https://en.wikipedia.org/wiki/Heap_(data_structure)>`_
## that can be used as a
## `priority queue<https://en.wikipedia.org/wiki/Priority_queue>`_.
## Heaps are arrays for which `a[k] <= a[2*k+1]` and `a[k] <= a[2*k+2]` for
## all `k`, counting elements from 0. The interesting property of a heap is that
## `a[0]` is always its smallest element.
##
## Basic usage
## -----------
##

runnableExamples:
  var heap = initHeapQueue[int]()
  heap.push(8)
  heap.push(2)
  heap.push(5)
  # The first element is the lowest element
  assert heap[0] == 2
  # Remove and return the lowest element
  assert heap.pop() == 2
  # The lowest element remaining is 5
  assert heap[0] == 5

## Usage with custom object
## ------------------------
## To use a `HeapQueue` with a custom object, the `<` operator must be
## implemented.

runnableExamples:
  type Job = object
    priority: int

  proc `<`(a, b: Job): bool = a.priority < b.priority

  var jobs = initHeapQueue[Job]()
  jobs.push(Job(priority: 1))
  jobs.push(Job(priority: 2))

  assert jobs[0].priority == 1

import std/private/since

type HeapQueue*[T] = object
  ## A heap queue, commonly known as a priority queue.
  data: seq[T]

proc initHeapQueue*[T](): HeapQueue[T] =
  ## Creates a new empty heap.
  ##
  ## See also:
  ## * `toHeapQueue proc <#toHeapQueue,openArray[T]>`_
  discard

proc len*[T](heap: HeapQueue[T]): int {.inline.} =
  ## Returns the number of elements of `heap`.
  heap.data.len

proc `[]`*[T](heap: HeapQueue[T], i: Natural): lent T {.inline.} =
  ## Accesses the i-th element of `heap`.
  heap.data[i]

proc heapCmp[T](x, y: T): bool {.inline.} =
  return (x < y)

proc siftdown[T](heap: var HeapQueue[T], startpos, p: int) =
  ## 'heap' is a heap at all indices >= startpos, except possibly for `pos`. `pos`
  ## is the index of a leaf with a possibly out-of-order value. Restores the
  ## heap invariant.
  var pos = p
  var newitem = heap[pos]
  # Follow the path to the root, moving parents down until finding a place
  # newitem fits.
  while pos > startpos:
    let parentpos = (pos - 1) shr 1
    let parent = heap[parentpos]
    if heapCmp(newitem, parent):
      heap.data[pos] = parent
      pos = parentpos
    else:
      break
  heap.data[pos] = newitem

proc siftup[T](heap: var HeapQueue[T], p: int) =
  let endpos = len(heap)
  var pos = p
  let startpos = pos
  let newitem = heap[pos]
  # Bubble up the smaller child until hitting a leaf.
  var childpos = 2*pos + 1 # leftmost child position
  while childpos < endpos:
    # Set childpos to index of smaller child.
    let rightpos = childpos + 1
    if rightpos < endpos and not heapCmp(heap[childpos], heap[rightpos]):
      childpos = rightpos
    # Move the smaller child up.
    heap.data[pos] = heap[childpos]
    pos = childpos
    childpos = 2*pos + 1
  # The leaf at pos is empty now.  Put newitem there, and bubble it up
  # to its final resting place (by sifting its parents down).
  heap.data[pos] = newitem
  siftdown(heap, startpos, pos)

proc push*[T](heap: var HeapQueue[T], item: sink T) =
  ## Pushes `item` onto heap, maintaining the heap invariant.
  heap.data.add(item)
  siftdown(heap, 0, len(heap)-1)

proc toHeapQueue*[T](x: openArray[T]): HeapQueue[T] {.since: (1, 3).} =
  ## Creates a new HeapQueue that contains the elements of `x`.
  ##
  ## See also:
  ## * `initHeapQueue proc <#initHeapQueue>`_
  runnableExamples:
    var heap = toHeapQueue([9, 5, 8])
    assert heap.pop() == 5
    assert heap[0] == 8

  result = initHeapQueue[T]()
  for item in items(x):
    result.push(item)

proc pop*[T](heap: var HeapQueue[T]): T =
  ## Pops and returns the smallest item from `heap`,
  ## maintaining the heap invariant.
  runnableExamples:
    var heap = toHeapQueue([9, 5, 8])
    assert heap.pop() == 5
  let lastelt = heap.data.pop()
  if heap.len > 0:
    result = heap[0]
    heap.data[0] = lastelt
    siftup(heap, 0)
  else:
    result = lastelt

proc find*[T](heap: HeapQueue[T], x: T): int {.since: (1, 3).} =
  ## Linear scan to find index of item ``x`` or -1 if not found.
  runnableExamples:
    var heap = toHeapQueue([9, 5, 8])
    assert heap.find(5) == 0
    assert heap.find(9) == 1
    assert heap.find(777) == -1
  result = -1
  for i in 0 ..< heap.len:
    if heap[i] == x: return i

proc del*[T](heap: var HeapQueue[T], index: Natural) =
  ## Removes the element at `index` from `heap`, maintaining the heap invariant.
  runnableExamples:
    var heap = toHeapQueue([9, 5, 8])
    heap.del(1)
    assert heap[0] == 5
    assert heap[1] == 8
  swap(heap.data[^1], heap.data[index])
  let newLen = heap.len - 1
  heap.data.setLen(newLen)
  if index < newLen:
    heap.siftup(index)

proc replace*[T](heap: var HeapQueue[T], item: sink T): T =
  ## Pops and returns the current smallest value, and add the new item.
  ## This is more efficient than pop() followed by push(), and can be
  ## more appropriate when using a fixed-size heap. Note that the value
  ## returned may be larger than item! That constrains reasonable uses of
  ## this routine unless written as part of a conditional replacement:
  runnableExamples:
    var heap = initHeapQueue[int]()
    heap.push(5)
    heap.push(12)
    assert heap.replace(6) == 5
    assert heap.len == 2
    assert heap[0] == 6
    assert heap.replace(4) == 6
  result = heap[0]
  heap.data[0] = item
  siftup(heap, 0)

proc pushpop*[T](heap: var HeapQueue[T], item: sink T): T =
  ## Fast version of a push followed by a pop.
  runnableExamples:
    var heap = initHeapQueue[int]()
    heap.push(5)
    heap.push(12)
    assert heap.pushpop(6) == 5
    assert heap.len == 2
    assert heap[0] == 6
    assert heap.pushpop(4) == 4
  result = item
  if heap.len > 0 and heapCmp(heap.data[0], result):
    swap(result, heap.data[0])
    siftup(heap, 0)

proc clear*[T](heap: var HeapQueue[T]) =
  ## Removes all elements from `heap`, making it empty.
  runnableExamples:
    var heap = initHeapQueue[int]()
    heap.push(1)
    heap.clear()
    assert heap.len == 0
  heap.data.setLen(0)

proc `$`*[T](heap: HeapQueue[T]): string =
  ## Turns a heap into its string representation.
  runnableExamples:
    var heap = initHeapQueue[int]()
    heap.push(1)
    heap.push(2)
    assert $heap == "[1, 2]"
  result = "["
  for x in heap.data:
    if result.len > 1: result.add(", ")
    result.addQuoted(x)
  result.add("]")
