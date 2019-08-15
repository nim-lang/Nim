discard """
  errormsg: "type mismatch: got <typedesc[int]> but expected 'int'"
  file: "ttypenoval.nim"
  line: 38
"""

# A min-heap.
type
  TNode[T] = tuple[priority: int, data: T]

  TBinHeap[T] = object
    heap: seq[TNode[T]]
    last: int

  PBinHeap[T] = ref TBinHeap[T]

proc newBinHeap*[T](heap: var PBinHeap[T], size: int) =
  new(heap)
  heap.last = 0
  newSeq(heap.heap, size)
  #newSeq(heap.seq, size)

proc parent(elem: int): int {.inline.} =
  return (elem-1) div 2

proc siftUp[T](heap: PBinHeap[T], elem: int) =
  var idx = elem
  while idx != 0:
    var p = parent(idx)
    if heap.heap[idx] < heap.heap[p]:
      swap(heap.heap[idx], heap.heap[p])
      idx = p
    else:
      break

proc add*[T](heap: PBinHeap[T], priority: int, data: T) =
  var node: TNode[T]
  node.priority = int
  node.data = data
  heap.heap[heap.last] = node
  siftUp(heap, heap.last)
  inc(heap.last)

proc print*[T](heap: PBinHeap[T]) =
  for i in countup(0, heap.last):
    echo($heap.heap[i])

var
  heap: PBinHeap[int]

newBinHeap(heap, 256)
add(heap, 1, 100)
print(heap)
