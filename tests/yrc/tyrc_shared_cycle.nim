discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Test sharing a cyclic list between threads under YRC.

type
  Node = ref object
    value: int
    next: Node

proc newCycle(start, count: int): Node =
  ## Create a cyclic linked list: start -> start+1 -> ... -> start+count-1 -> start
  result = Node(value: start)
  var cur = result
  for i in 1..<count:
    cur.next = Node(value: start + i)
    cur = cur.next
  cur.next = result  # close the cycle

proc sumCycle(head: Node; count: int): int =
  var cur = head
  for i in 0..<count:
    result += cur.value
    cur = cur.next

const
  NumThreads = 4
  NodesPerCycle = 5

var
  shared: Node
  threads: array[NumThreads, Thread[int]]
  results: array[NumThreads, int]

proc worker(id: int) {.thread.} =
  # Each thread reads the shared cycle and computes a sum.
  # Also creates its own local cycle to exercise the collector.
  {.cast(gcsafe).}:
    let local = newCycle(id * 100, NodesPerCycle)
    let localSum = sumCycle(local, NodesPerCycle)

    let sharedSum = sumCycle(shared, NodesPerCycle)
    results[id] = sharedSum + localSum

# Create a shared cyclic list: 0 -> 1 -> 2 -> 3 -> 4 -> 0
shared = newCycle(0, NodesPerCycle)
let expectedSharedSum = 0 + 1 + 2 + 3 + 4  # = 10

for i in 0..<NumThreads:
  createThread(threads[i], worker, i)

for i in 0..<NumThreads:
  joinThread(threads[i])

var allOk = true
for i in 0..<NumThreads:
  let expectedLocal = i * 100 * NodesPerCycle + (NodesPerCycle * (NodesPerCycle - 1) div 2)
    # sum of id*100, id*100+1, ..., id*100+4
  let expected = expectedSharedSum + expectedLocal
  if results[i] != expected:
    echo "FAIL thread ", i, ": got ", results[i], " expected ", expected
    allOk = false

shared = nil  # drop the shared cycle, collector should reclaim it
GC_fullCollect()

if allOk:
  echo "ok"
