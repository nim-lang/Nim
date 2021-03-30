import std/heapqueue


proc toSortedSeq[T](h: HeapQueue[T]): seq[T] =
  var tmp = h
  result = @[]
  while tmp.len > 0:
    result.add(pop(tmp))

proc heapProperty[T](h: HeapQueue[T]): bool =
  for k in 0 .. h.len - 2: # the last element is always a leaf
    let left = 2 * k + 1
    if left < h.len and h[left] < h[k]:
      return false
    let right = left + 1
    if right < h.len and h[right] < h[k]:
      return false
  true

template main() =
  block: # simple sanity test
    var heap = initHeapQueue[int]()
    let data = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]
    for item in data:
      push(heap, item)
    doAssert(heap == data.toHeapQueue)
    doAssert(heap[0] == 0)
    doAssert(heap.toSortedSeq == @[0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

  block: # test del
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

  block: # test del last
    var heap = initHeapQueue[int]()
    let data = [1, 2, 3]
    for item in data: push(heap, item)

    heap.del(2)
    doAssert(heap.toSortedSeq == @[1, 2])

    heap.del(1)
    doAssert(heap.toSortedSeq == @[1])

    heap.del(0)
    doAssert(heap.toSortedSeq == @[])

  block: # testing the heap proeprty
    var heap = [1, 4, 2, 5].toHeapQueue
    doAssert heapProperty(heap)

    heap.push(42)
    doAssert heapProperty(heap)
    heap.push(0)
    doAssert heapProperty(heap)
    heap.push(3)
    doAssert heapProperty(heap)
    heap.push(3)
    doAssert heapProperty(heap)

    # [0, 3, 1, 4, 42, 2, 3, 5]

    discard heap.pop()
    doAssert heapProperty(heap)
    discard heap.pop()
    doAssert heapProperty(heap)

    heap.del(2)
    doAssert heapProperty(heap)

    # [2, 3, 5, 4, 42]

    discard heap.replace(12)
    doAssert heapProperty(heap)
    discard heap.replace(1)
    doAssert heapProperty(heap)

    discard heap.pushpop(2)
    doAssert heapProperty(heap)
    discard heap.pushpop(0)
    doAssert heapProperty(heap)

static: main()
main()
