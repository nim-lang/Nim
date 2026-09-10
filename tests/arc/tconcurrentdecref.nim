discard """
  matrix: "--mm:atomicArc --threads:on"
  output: "ok"
"""

# Every thread here holds its OWN counted reference to the same cell and drops
# it concurrently with the others. Exactly one free per object must happen: a
# leak (nobody frees) and a double free (two threads free) are both caught.
#
# This is the shape that went wrong in nim-lang/threading#45, where the
# destructor decided who frees from a separate load and discarded the result
# of the read-modify-write, so the role could be dropped by every participant
# at once. `nimDecRefIsLast` must always decide on the value its own RMW
# returned. The uniquely-referenced fast path added on top of it may only
# skip the RMW when the load proves no other thread holds a reference.

import std/atomics

type
  Payload = object
    id: int
  Obj = ref Payload

var freeCount: Atomic[int]

proc `=destroy`(p: Payload) =
  discard freeCount.fetchAdd(1, moRelease)

const
  NumObjects = 2000
  NumThreads = 6
  Rounds = 3

type
  Arg = object
    refs: seq[Obj]

var
  go: Atomic[bool]
  threads: array[NumThreads, Thread[ptr Arg]]
  args: array[NumThreads, Arg]

proc worker(a: ptr Arg) {.thread.} =
  while not go.load(moAcquire): cpuRelax()
  a.refs.setLen(0)          # drop them all, as fast as possible

proc main =
  var expected = 0
  for round in 1..Rounds:
    var mine = newSeq[Obj](NumObjects)
    for i in 0 ..< NumObjects:
      mine[i] = Obj(id: i)
    for t in 0 ..< NumThreads:
      args[t].refs = newSeq[Obj](NumObjects)
      for i in 0 ..< NumObjects:
        args[t].refs[i] = mine[i]     # counted copy
    go.store(false, moRelease)
    for t in 0 ..< NumThreads:
      createThread(threads[t], worker, addr args[t])
    go.store(true, moRelease)         # everybody drops at once...
    mine.setLen(0)                    # ...including this thread
    joinThreads(threads)
    expected += NumObjects
    let got = freeCount.load(moAcquire)
    if got != expected:
      echo "round ", round, ": got ", got, " frees, expected ", expected,
           (if got < expected: " (leak)" else: " (double free)")
      quit 1
  echo "ok"

main()
