##[ Heap queue algorithm (a.k.a. priority queue). Ported from Python heapq.

Heaps are arrays for which a[k] <= a[2*k+1] and a[k] <= a[2*k+2] for
all k, counting elements from 0.  For the sake of comparison,
non-existing elements are considered to be infinite.  The interesting
property of a heap is that a[0] is always its smallest element.

]##

type HeapQueue*[T] = distinct seq[T]

proc newHeapQueue*[T](): HeapQueue[T] {.inline.} = HeapQueue[T](newSeq[T]())
proc newHeapQueue*[T](h: var HeapQueue[T]) {.inline.} = h = HeapQueue[T](newSeq[T]())

proc len*[T](h: HeapQueue[T]): int {.inline.} = seq[T](h).len
proc `[]`*[T](h: HeapQueue[T], i: int): T {.inline.} = seq[T](h)[i]
proc `[]=`[T](h: var HeapQueue[T], i: int, v: T) {.inline.} = seq[T](h)[i] = v
proc add[T](h: var HeapQueue[T], v: T) {.inline.} = seq[T](h).add(v)

proc heapCmp[T](x, y: T): bool {.inline.} =
  return (x < y)

# 'heap' is a heap at all indices >= startpos, except possibly for pos.  pos
# is the index of a leaf with a possibly out-of-order value.  Restore the
# heap invariant.
proc siftdown[T](heap: var HeapQueue[T], startpos, p: int) =
  var pos = p
  var newitem = heap[pos]
  # Follow the path to the root, moving parents down until finding a place
  # newitem fits.
  while pos > startpos:
    let parentpos = (pos - 1) shr 1
    let parent = heap[parentpos]
    if heapCmp(newitem, parent):
      heap[pos] = parent
      pos = parentpos
    else:
      break
  heap[pos] = newitem

proc siftup[T](heap: var HeapQueue[T], p: int) =
  let endpos = len(heap)
  var pos = p
  let startpos = pos
  let newitem = heap[pos]
  # Bubble up the smaller child until hitting a leaf.
  var childpos = 2*pos + 1    # leftmost child position
  while childpos < endpos:
    # Set childpos to index of smaller child.
    let rightpos = childpos + 1
    if rightpos < endpos and not heapCmp(heap[childpos], heap[rightpos]):
      childpos = rightpos
    # Move the smaller child up.
    heap[pos] = heap[childpos]
    pos = childpos
    childpos = 2*pos + 1
  # The leaf at pos is empty now.  Put newitem there, and bubble it up
  # to its final resting place (by sifting its parents down).
  heap[pos] = newitem
  siftdown(heap, startpos, pos)

proc push*[T](heap: var HeapQueue[T], item: T) =
  ## Push item onto heap, maintaining the heap invariant.
  (seq[T](heap)).add(item)
  siftdown(heap, 0, len(heap)-1)

proc pop*[T](heap: var HeapQueue[T]): T =
  ## Pop the smallest item off the heap, maintaining the heap invariant.
  let lastelt = seq[T](heap).pop()
  if heap.len > 0:
    result = heap[0]
    heap[0] = lastelt
    siftup(heap, 0)
  else:
    result = lastelt

proc del*[T](heap: var HeapQueue[T], index: int) =
  ## Removes element at `index`, maintaining the heap invariant.
  swap(seq[T](heap)[^1], seq[T](heap)[index])
  let newLen = heap.len - 1
  seq[T](heap).setLen(newLen)
  if index < newLen:
    heap.siftup(index)

proc replace*[T](heap: var HeapQueue[T], item: T): T =
  ## Pop and return the current smallest value, and add the new item.
  ## This is more efficient than pop() followed by push(), and can be
  ## more appropriate when using a fixed-size heap.  Note that the value
  ## returned may be larger than item!  That constrains reasonable uses of
  ## this routine unless written as part of a conditional replacement:

  ##    if item > heap[0]:
  ##        item = replace(heap, item)
  result = heap[0]
  heap[0] = item
  siftup(heap, 0)

proc pushpop*[T](heap: var HeapQueue[T], item: T): T =
  ## Fast version of a push followed by a pop.
  if heap.len > 0 and heapCmp(heap[0], item):
    swap(item, heap[0])
    siftup(heap, 0)
  return item

when isMainModule:
  proc toSortedSeq[T](h: HeapQueue[T]): seq[T] =
    var tmp = h
    result = @[]
    while tmp.len > 0:
      result.add(pop(tmp))

  block: # Simple sanity test
    var heap = newHeapQueue[int]()
    let data = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]
    for item in data:
      push(heap, item)
    doAssert(heap[0] == 0)
    doAssert(heap.toSortedSeq == @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

  block: # Test del
    var heap = newHeapQueue[int]()
    let data = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]
    for item in data: push(heap, item)

    heap.del(0)
    doAssert(heap[0] == 1)

    heap.del(seq[int](heap).find(7))
    doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 5, 6, 8, 9])

    heap.del(seq[int](heap).find(5))
    doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 6, 8, 9])

    heap.del(seq[int](heap).find(6))
    doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 8, 9])

    heap.del(seq[int](heap).find(2))
    doAssert(heap.toSortedSeq == @[1, 3, 4, 8, 9])

  block: # Test del last
    var heap = newHeapQueue[int]()
    let data = [1, 2, 3]
    for item in data: push(heap, item)

    heap.del(2)
    doAssert(heap.toSortedSeq == @[1, 2])

    heap.del(1)
    doAssert(heap.toSortedSeq == @[1])

    heap.del(0)
    doAssert(heap.toSortedSeq == @[])
