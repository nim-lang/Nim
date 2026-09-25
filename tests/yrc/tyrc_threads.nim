discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# N threads each churn garbage cycles while maintaining one live ring that is
# verified continuously and replaced, plus explicit GC_runOrc collections from
# every thread. Corruption of live data trips a doAssert.

import std/typedthreads

type Node = ref object
  next: Node
  prev: Node
  id: int

const NThreads = 4
const Iters = 30_000

proc mkRing(n, tag: int): Node =
  result = Node(id: tag)
  var c = result
  for i in 1 ..< n:
    let x = Node(id: tag + i)
    c.next = x
    x.prev = c
    c = x
  c.next = result
  result.prev = c

proc checkRing(r: Node; n, tag: int) =
  var c = r
  for i in 0 ..< n:
    doAssert c.id == tag + i, "ring corrupted!"
    c = c.next
  doAssert c == r, "ring not closed!"

var results: array[NThreads, int]

proc worker(tid: int) {.thread.} =
  var keep = mkRing(5, tid * 1000)
  for i in 0 ..< Iters:
    discard mkRing(3 + (i and 7), 999999)   # garbage
    if (i and 255) == 0:
      checkRing(keep, 5, tid * 1000)
      keep = mkRing(5, tid * 1000)          # old keep becomes garbage
    if (i and 1023) == 0:
      GC_runOrc()                            # explicit collections from all threads
  checkRing(keep, 5, tid * 1000)
  results[tid] = 1

var th: array[NThreads, Thread[int]]
for i in 0 ..< NThreads: createThread(th[i], worker, i)
joinThreads(th)
for i in 0 ..< NThreads: doAssert results[i] == 1
GC_fullCollect()
echo "ok"
