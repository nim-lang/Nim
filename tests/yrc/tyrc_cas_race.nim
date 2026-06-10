discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  valgrind: "leaks"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Test concurrent traversal and mutation of a shared cyclic list under YRC.
# Multiple threads race to replace nodes using a lock for synchronization.
# This exercises YRC's write barrier and cycle collection under contention.

import std/locks

type
  Node = ref object
    value: int
    next: Node

proc newCycle(start, count: int): Node =
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
  CycleLen = 6
  Iterations = 50

var
  shared: Node
  sharedLock: Lock
  threads: array[NumThreads, Thread[int]]
  wins: array[NumThreads, int]

proc worker(id: int) {.thread.} =
  {.cast(gcsafe).}:
    for iter in 0..<Iterations:
      # Under the lock, walk the shared list and replace a node's next pointer
      withLock sharedLock:
        var cur = shared
        if cur == nil: continue
        for step in 0..<CycleLen:
          let nxt = cur.next
          if nxt == nil: break
          # Replace cur.next with a fresh node that points to nxt.next
          let replacement = Node(value: id * 1000 + iter, next: nxt.next)
          cur.next = replacement
          wins[id] += 1
          cur = cur.next
          if cur == nil: break

      # Outside the lock, create a local cycle to exercise the collector
      let local = newCycle(id * 100 + iter, 3)
      discard sumCycle(local, 3)

# Create initial shared cyclic list: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 0
initLock(sharedLock)
shared = newCycle(0, CycleLen)

for i in 0..<NumThreads:
  createThread(threads[i], worker, i)

for i in 0..<NumThreads:
  joinThread(threads[i])

# Verify: the list is still traversable (no crashes, no dangling pointers).
var totalWins = 0
for i in 0..<NumThreads:
  totalWins += wins[i]

# Walk the list to verify it's still a valid cycle (or chain)
var cur = shared
var seen = 0
var maxSteps = CycleLen * 3  # generous bound
while cur != nil and seen < maxSteps:
  seen += 1
  cur = cur.next
  if cur == shared: break  # completed the cycle

shared = nil
GC_fullCollect()
deinitLock(sharedLock)

if totalWins > 0 and seen > 0:
  echo "ok"
else:
  echo "FAIL: wins=", totalWins, " seen=", seen
