import heapqueue


proc toSortedSeq[T](h: HeapQueue[T]): seq[T] =
  var tmp = h
  result = @[]
  while tmp.len > 0:
    result.add(pop(tmp))

block: # Simple sanity test
  var heap = initHeapQueue[int]()
  let data = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]
  for item in data:
    push(heap, item)
  doAssert(heap == data.toHeapQueue)
  doAssert(heap[0] == 0)
  doAssert(heap.toSortedSeq == @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

block: # Test del
  var heap = initHeapQueue[int]()
  let data = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]
  for item in data: push(heap, item)

  heap.del(0)
  doAssert(heap[0] == 1)

  heap.del(heap.find(7))
  doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 5, 6, 8, 9])

  heap.del(heap.find(5))
  doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 6, 8, 9])

  heap.del(heap.find(6))
  doAssert(heap.toSortedSeq == @[1, 2, 3, 4, 8, 9])

  heap.del(heap.find(2))
  doAssert(heap.toSortedSeq == @[1, 3, 4, 8, 9])

  doAssert(heap.find(2) == -1)

block: # Test del last
  var heap = initHeapQueue[int]()
  let data = [1, 2, 3]
  for item in data: push(heap, item)

  heap.del(2)
  doAssert(heap.toSortedSeq == @[1, 2])

  heap.del(1)
  doAssert(heap.toSortedSeq == @[1])

  heap.del(0)
  doAssert(heap.toSortedSeq == @[])
