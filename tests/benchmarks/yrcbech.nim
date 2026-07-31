discard """
  output: '''true peak memory: true'''
  cmd: "nim c --mm:orc -d:release --threads:on $file"
"""

## torcbench (tests/arc/torcbench.nim), threaded — plus the smallest changes
## that let the generational scheme show up in the number.
##
## Each thread runs its own private copy of the torcbench workload: one long
## doubly-linked list of strings, and a stream of short-lived cyclic trees
## whose every node embeds a copy of the list header — that is two references
## into the list per tree node. Nothing is shared between threads, so the same
## program is a fair measurement under --mm:orc and --mm:yrc.
##
## Three changes vs torcbench, each needed to make the young -> old pattern
## measurable rather than incidental:
##
## 1. The list is built once per THREAD, not once per outer iteration, so it
##    survives long enough to be promoted. It is the old generation; the trees
##    are the young one.
## 2. A seed phase traces and stamps the list before the tree traffic starts.
##    Needed because `flagDirty` is per-SCC and the list is ONE SCC: once trees
##    are churning, every `parent` copy touches head and tail, so the SCC is
##    permanently dirty and would never get stamped. Promoting it first makes
##    the stamp carry it through the young phase.
## 3. Collection runs at a fixed cadence (GC_partialCollect per outer
##    iteration) instead of being left to each collector's threshold
##    heuristic. Without this the benchmark measures how often each collector
##    decides to collect rather than what a collection over this heap costs —
##    and ORC's threshold scales with heap size, so a bigger list makes it
##    collect LESS and the re-trace it is supposed to be paying never appears.
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
##   nim c -r --mm:orc -d:release --threads:on yrcbench.nim
##   nim c -r --mm:yrc -d:release --threads:on yrcbench.nim
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
  SeedProbes {.intdefine.} = 6      ## must exceed YrcPromoteAge (default 3)

type
  Node = ref object
    parent: DoublyLinkedList[string]  ## copy of the header: 2 refs into the list
    le, ri: Node
    self: Node                        ## self-cycle, forces cycle detection

  Holder = ref object
    ## Cyclic handle on the list, used only to get the list traced during the
    ## seed phase. A plain reference would never be registered as a cycle
    ## candidate; the self-edge is what makes it one.
    list: DoublyLinkedList[string]
    self: Holder

var probeSlot {.threadvar.}: Holder

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

  # (2) seed phase: age the list past the promotion threshold while nothing
  # else is churning. GC_partialCollect, not GC_fullCollect — the latter
  # advances the epoch and wipes the stamps this depends on.
  block:
    let holder = Holder(list: leakList)
    holder.self = holder
    for _ in 1 .. SeedProbes:
      probeSlot = holder
      probeSlot = nil
      GC_partialCollect(0)

  for i in 1 .. OuterIters:
    for k in 0 .. TreeIters:
      discard buildTree(leakList, TreeDepth)   # young: dead the moment it returns
    GC_partialCollect(0)                       # (3) fixed cadence

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
