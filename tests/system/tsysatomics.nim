discard """
  targets: "c cpp"
  matrix: "--threads:on --mm:refc; --threads:on --mm:orc"
"""

import std/[sysatomics, typedthreads]

proc checkInteger[T: SomeInteger]() =
  var value: T
  atomicStoreN(addr value, T(12), ATOMIC_RELEASE)
  doAssert atomicLoadN(addr value, ATOMIC_ACQUIRE) == T(12)
  doAssert atomicExchangeN(addr value, T(7), ATOMIC_ACQ_REL) == T(12)
  var expected = T(7)
  doAssert atomicCompareExchangeN(addr value, addr expected, T(9), false,
    ATOMIC_SEQ_CST, ATOMIC_ACQUIRE)
  doAssert expected == T(7)
  doAssert not atomicCompareExchangeN(addr value, addr expected, T(10), false,
    ATOMIC_SEQ_CST, ATOMIC_ACQUIRE)
  doAssert expected == T(9)

  var desired = T(10)
  doAssert atomicCompareExchange(addr value, addr expected, addr desired, false,
    ATOMIC_SEQ_CST, ATOMIC_ACQUIRE)
  doAssert not atomicCompareExchange(addr value, addr expected, addr desired, true,
    ATOMIC_SEQ_CST, ATOMIC_ACQUIRE)
  doAssert expected == T(10)
  var loaded: T
  atomicLoad(addr value, addr loaded, ATOMIC_RELAXED)
  doAssert loaded == T(10)
  desired = T(12)
  atomicStore(addr value, addr desired, ATOMIC_RELEASE)
  desired = T(10)
  atomicExchange(addr value, addr desired, addr loaded, ATOMIC_ACQ_REL)
  doAssert loaded == T(12)
  doAssert value == T(10)

  doAssert atomicAddFetch(addr value, T(2), ATOMIC_RELAXED) == T(12)
  doAssert atomicSubFetch(addr value, T(2), ATOMIC_RELAXED) == T(10)
  doAssert atomicOrFetch(addr value, T(1), ATOMIC_RELAXED) == T(11)
  doAssert atomicAndFetch(addr value, T(6), ATOMIC_RELAXED) == T(2)
  doAssert atomicXorFetch(addr value, T(7), ATOMIC_RELAXED) == T(5)
  doAssert atomicNandFetch(addr value, T(3), ATOMIC_RELAXED) == not T(1)
  atomicStoreN(addr value, T(12), ATOMIC_RELAXED)
  doAssert atomicFetchAdd(addr value, T(2), ATOMIC_RELAXED) == T(12)
  doAssert atomicFetchSub(addr value, T(3), ATOMIC_RELAXED) == T(14)
  doAssert atomicFetchOr(addr value, T(4), ATOMIC_RELAXED) == T(11)
  doAssert atomicFetchAnd(addr value, T(7), ATOMIC_RELAXED) == T(15)
  doAssert atomicFetchXor(addr value, T(3), ATOMIC_RELAXED) == T(7)
  doAssert atomicFetchNand(addr value, T(3), ATOMIC_RELAXED) == T(4)
  doAssert atomicLoadN(addr value, ATOMIC_RELAXED) == not T(0)

checkInteger[int8]()
checkInteger[uint8]()
checkInteger[int16]()
checkInteger[uint16]()
checkInteger[int32]()
checkInteger[uint32]()
checkInteger[int64]()
checkInteger[uint64]()
checkInteger[int]()
checkInteger[uint]()

block:
  var guarded: tuple[value: bool, guard: array[8, byte]]
  for item in guarded.guard.mitems: item = 0x5a
  doAssert sysatomics.cas(addr guarded.value, false, true)
  doAssert not sysatomics.cas(addr guarded.value, false, true)
  doAssert sysatomics.cas(addr guarded.value, true, false)
  for item in guarded.guard: doAssert item == 0x5a
  doAssert not atomicTestAndSet(addr guarded.value, ATOMIC_ACQUIRE)
  doAssert atomicTestAndSet(addr guarded.value, ATOMIC_ACQUIRE)
  atomicClear(addr guarded.value, ATOMIC_RELEASE)
  doAssert not guarded.value
  for item in guarded.guard: doAssert item == 0x5a

block:
  var first, second: int
  var value = addr first
  doAssert sysatomics.cas(addr value, addr first, addr second)
  doAssert not sysatomics.cas(addr value, addr first, nil)
  var expected = addr first
  doAssert not atomicCompareExchangeN(addr value, addr expected, nil, false,
    ATOMIC_SEQ_CST, ATOMIC_ACQUIRE)
  doAssert expected == addr second
  atomicStoreN(addr value, addr first, ATOMIC_RELEASE)
  doAssert atomicLoadN(addr value, ATOMIC_ACQUIRE) == addr first
  doAssert atomicExchangeN(addr value, nil, ATOMIC_ACQ_REL) == addr first
  doAssert value == nil

when sizeof(int) == 8:
  var wide = int(0x123456789abcdef0'i64)
  doAssert sysatomics.cas(addr wide, int(0x123456789abcdef0'i64),
    int(0x23456789abcdef01'i64))
  doAssert wide == int(0x23456789abcdef01'i64)

atomicThreadFence(ATOMIC_SEQ_CST)
atomicSignalFence(ATOMIC_ACQ_REL)
sysatomics.fence()
doAssert atomicAlwaysLockFree(1, nil)
doAssert atomicIsLockFree(1, nil)

var counter: int
proc increment() {.thread.} =
  for i in 0 ..< 10000:
    sysatomics.atomicInc(counter)

proc decrement() {.thread.} =
  for i in 0 ..< 10000:
    sysatomics.atomicDec(counter)

var workers: array[4, Thread[void]]
for worker in workers.mitems: createThread(worker, increment)
joinThreads(workers)
doAssert counter == 40000
for worker in workers.mitems: createThread(worker, decrement)
joinThreads(workers)
doAssert counter == 0
