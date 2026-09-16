discard """
  matrix: "--threads:on; --threads:on --mm:atomicArc; --threads:off"
  output: "ok"
"""

# Stage-0 foundations of doc/parallel_compiler.md. The primitives have no user
# in the compiler yet, so without this test nothing would compile them and they
# would rot before stage 1 arrives. The `--threads:off` column matters as much
# as the other two: nimsuggest and the bootstrap stage still build that way and
# must keep seeing a working single-worker implementation.

import compiler/concurrency
when hasThreads:
  import std/typedthreads

type
  Narrow = enum          # 4 values -> the set is one byte
    nA, nB, nC, nD
  Wide = enum            # 64 values -> the set is a full machine word
    w00, w01, w02, w03, w04, w05, w06, w07, w08, w09, w10, w11, w12, w13, w14,
    w15, w16, w17, w18, w19, w20, w21, w22, w23, w24, w25, w26, w27, w28, w29,
    w30, w31, w32, w33, w34, w35, w36, w37, w38, w39, w40, w41, w42, w43, w44,
    w45, w46, w47, w48, w49, w50, w51, w52, w53, w54, w55, w56, w57, w58, w59,
    w60, w61, w62, w63
  Based = enum           # does not start at zero: the mask must not be `1 shl ord`
    bX = 5, bY = 6, bZ = 7

block flagWidths:
  var n: set[Narrow] = {}
  atomicIncl(n, nB)
  atomicIncl(n, nD)
  doAssert atomicRead(n) == {nB, nD}
  atomicExcl(n, nB)
  doAssert atomicRead(n) == {nD}

  var w: set[Wide] = {}
  atomicIncl(w, w00)
  atomicIncl(w, w63)
  doAssert atomicRead(w) == {w00, w63}
  atomicExcl(w, w00)
  doAssert atomicRead(w) == {w63}

  var b: set[Based] = {}
  atomicIncl(b, bX)
  atomicIncl(b, bZ)
  doAssert atomicRead(b) == {bX, bZ}
  atomicExcl(b, bZ)
  doAssert atomicRead(b) == {bX}

block queueYieldsSmallestKeyFirst:
  # The point of the heap: dispatch order is a function of the keys, not of
  # the order the tasks were enqueued in.
  var q: TaskQueue[string]
  initTaskQueue q
  for (k, v) in [(40'u64, "e"), (10'u64, "b"), (50'u64, "f"), (1'u64, "a"),
                 (30'u64, "d"), (20'u64, "c")]:
    q.push(k, v)
  doAssert q.len == 6
  var got = ""
  var one: string
  while q.tryPop(one):
    got.add one
  doAssert got == "abcdef", got
  doAssert not q.tryPop(one)
  deinitTaskQueue q

when hasThreads:
  # 8 workers, each setting a disjoint eighth of the flags of one shared word:
  # with a plain `incl` this loses updates, which is the bug atomicIncl exists
  # to prevent (§4.4: a lost `tfHasAsgn` is wrong code, not a cosmetic race).
  var sharedFlags: set[Wide] = {}
  var drainedTasks: set[Wide] = {}
  var contended: RwLock
  var guarded = 0
  var latch: Latch
  var pool: TaskQueue[int]

  proc worker(id: int) {.thread.} =
    for i in 0 ..< 8:
      atomicIncl(sharedFlags, Wide(id * 8 + i))
    for _ in 0 ..< 200:
      withWriteLock contended:
        inc guarded
      withReadLock contended:
        doAssert guarded > 0
    # The task runner is the one place the plan says legitimately needs the
    # cast (§4.9): the queue is shared by construction and its ownership is
    # what the lock inside it establishes, not what the effect system can see.
    {.cast(gcsafe).}:
      var task: int
      while pool.pop(task):
        atomicIncl(drainedTasks, Wide(task))
        latch.countDown()

  block:
    initRwLock contended
    initTaskQueue pool
    initLatch latch
    latch.arm 64
    for k in countdown(63, 0):
      pool.push(uint64(k), k)

    var threads: array[8, Thread[int]]
    for i in 0 ..< 8:
      createThread(threads[i], worker, i)
    latch.wait()
    doAssert latch.outstanding == 0
    pool.close()
    joinThreads threads

    doAssert sharedFlags == {low(Wide) .. high(Wide)}
    doAssert drainedTasks == {low(Wide) .. high(Wide)}
    doAssert guarded == 8 * 200
    doAssert pool.len == 0

    deinitTaskQueue pool
    deinitLatch latch
    deinitRwLock contended

echo "ok"
