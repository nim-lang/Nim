discard """
  output: '''true peak memory: true'''
  cmd: "nim c --mm:orc -d:release --threads:on $file"
"""

## torcbench (tests/arc/torcbench.nim), threaded — plus the smallest changes
## that let the generational scheme show up in the number.
##
## Each thread runs its own private copy of the torcbench workload: one long
## doubly-linked list of strings, and a stream of short-lived cyclic trees
## whose every node embeds a copy of the list header — that is a reference
## into the list per tree node. Nothing is shared between threads, so the same
## program is a fair measurement under --mm:orc and --mm:yrc.
##
## Two changes vs torcbench, each needed to make the young -> old pattern
## measurable rather than incidental:
##
## 1. The list is built once per THREAD, not once per outer iteration, so it
##    survives long enough to be promoted. It is the old generation; the trees
##    are the young one.
## 2. Collection runs at a fixed cadence (GC_partialCollect per outer
##    iteration) instead of being left to each collector's threshold
##    heuristic. Without this the benchmark measures how often each collector
##    decides to collect rather than what a collection over this heap costs —
##    and ORC's threshold scales with heap size, so a bigger list makes it
##    collect LESS and the re-trace it is supposed to be paying never appears.
##
## Nothing seeds the promotion: the tree stream itself is what ages the list,
## which is why the workload can stay an ordinary one. `DoublyLinkedNode.prev`
## and `DoublyLinkedList.tail` are `{.cursor.}`, so copying a `parent` header
## incRefs `head` alone, and the list is a chain of one-node SCCs rather than
## a single big one. Dirtiness is per-SCC, so the churn only ever dirties
## `head`; every node behind it is traced clean by the collections the trees
## trigger anyway and promotes after YrcPromoteAge of them. The capture then
## prunes one edge in — at `head.next` — instead of walking 60000 nodes.
##
##   --mm:orc  every collection follows `parent` into the list and re-traces
##             all ListLen nodes of it.
##   --mm:yrc  once the list is promoted, capture prunes at the epoch-stamp
##             boundary and walks only the young frontier.
##
## Sizing matters: the win is the ratio of old-generation size to young work
## per collection, so ListLen is large and TreeIters small. Total young work
## is about the same as torcbench's (200x51 trees vs 25x401). NumThreads=4 is
## the default because 8 threads on a 4-performance-core machine dilutes the
## result (1.15x vs 1.69x measured on an M1).
##
##   nim c -r --mm:orc -d:release --threads:on yrcbech.nim
##   nim c -r --mm:yrc -d:release --threads:on yrcbech.nim
##
## Add -d:yrcBenchTime for a wall-clock line, -d:nimOrcStats for capture and
## prune counts (YRC only).

import std/[lists, monotimes, times]

const
  NumThreads {.intdefine.} = 4
  OuterIters {.intdefine.} = 200    ## per thread; also the collection count
  ListLen    {.intdefine.} = 60000  ## the old generation
  TreeIters  {.intdefine.} = 50     ## young trees per collection
  TreeDepth  {.intdefine.} = 8

type
  Node = ref object
    parent: DoublyLinkedList[string]  ## copy of the header: a ref into the list
    le, ri: Node
    self: Node                        ## self-cycle, forces cycle detection

proc buildTree(parent: DoublyLinkedList[string]; depth: int): Node =
  if depth == 0:
    result = nil
  elif depth == 1:
    result = Node(parent: parent)
    result.self = result
  else:
    result = Node(parent: parent,
                  le: buildTree(parent, depth - 1),
                  ri: buildTree(parent, depth - 2))
    result.self = result

proc threadWork() {.thread.} =
  # (1) built once per thread: the old generation
  var leakList = initDoublyLinkedList[string]()
  for j in 1 .. ListLen:
    leakList.append(newString(200))

  for i in 1 .. OuterIters:
    for k in 0 .. TreeIters:
      discard buildTree(leakList, TreeDepth)   # young: dead the moment it returns
    GC_partialCollect(0)                       # (2) fixed cadence

var threads: array[NumThreads, Thread[void]]

let t0 = getMonoTime()
for i in 0 ..< NumThreads:
  createThread(threads[i], threadWork)
joinThreads(threads)
GC_fullCollect()
let dtMs = inMilliseconds(getMonoTime() - t0)

when defined(yrcBenchTime):
  echo "wall_ms ", dtMs

when not defined(useMalloc):
  echo getOccupiedMem() < 10 * 1024 * 1024, " peak memory: ",
       getMaxMem() < 256 * 1024 * 1024
else:
  echo "true peak memory: true"

when defined(nimOrcStats) and defined(gcYrc):
  let s = GC_orcStats()
  echo "capTotal ", s.capTotal, " capPruned ", s.capPruned,
       " capRepeat ", s.capRepeat
