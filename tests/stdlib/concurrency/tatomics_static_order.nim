discard """
  matrix: "--mm:orc; --mm:orc -d:nimUseCppAtomics"
  targets: "c cpp"
"""

# `MemoryOrder` is `static[MemoryOrderKind]`, so a wrapper that declares its
# own parameter as `MemoryOrder` forwards the constant order to the atomic
# operation - this is how taskpools writes its futexes. An order that is only
# known at run time is rejected; `MemoryOrderKind` is the enum itself for the
# places that need a concrete type.

import std/atomics
import std/assertions

type Futex = object
  value: Atomic[uint32]

proc load(f: var Futex; order: MemoryOrder): uint32 {.inline.} =
  f.value.load(order)
proc store(f: var Futex; desired: uint32; order: MemoryOrder) {.inline.} =
  f.value.store(desired, order)
proc exchange(f: var Futex; desired: uint32; order: MemoryOrder): uint32 {.inline.} =
  f.value.exchange(desired, order)
proc increment(f: var Futex; value: uint32; order: MemoryOrder): uint32 {.inline.} =
  f.value.fetchAdd(value, order)
proc compareExchange(f: var Futex; expected: var uint32; desired: uint32;
                     order: MemoryOrder): bool {.inline.} =
  f.value.compareExchange(expected, desired, order)
proc compareExchange(f: var Futex; expected: var uint32; desired: uint32;
                     success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
  f.value.compareExchange(expected, desired, success, failure)
proc compareExchangeWeak(f: var Futex; expected: var uint32; desired: uint32;
                         success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
  f.value.compareExchangeWeak(expected, desired, success, failure)
proc barrier(order: MemoryOrder) {.inline.} = fence(order)
proc acquire(flag: var AtomicFlag; order: MemoryOrder): bool {.inline.} =
  flag.testAndSet(order)
proc release(flag: var AtomicFlag; order: MemoryOrder) {.inline.} =
  flag.clear(order)

var f: Futex
f.store(1'u32, moRelease)
doAssert f.load(moAcquire) == 1'u32
doAssert f.exchange(4'u32, moAcquireRelease) == 1'u32
doAssert f.increment(1'u32, moRelaxed) == 4'u32

var expected = 5'u32
doAssert f.compareExchange(expected, 6'u32, moAcquireRelease)
expected = 1'u32
doAssert not f.compareExchange(expected, 7'u32, moRelease, moRelaxed)
doAssert expected == 6'u32
while not f.compareExchangeWeak(expected, 8'u32, moAcquireRelease, moAcquire): discard
doAssert f.load(moSequentiallyConsistent) == 8'u32

barrier(moAcquireRelease)
var flag: AtomicFlag
doAssert not flag.acquire(moAcquire)
flag.release(moRelease)

# the order is forwarded through generics and through the lock based path for
# non trivial types as well:
proc genericLoad[T](location: var Atomic[T]; order: MemoryOrder): T {.inline.} =
  location.load(order)
proc genericStore[T](location: var Atomic[T]; desired: T; order: MemoryOrder) {.inline.} =
  location.store(desired, order)

var i: Atomic[int]
i.genericStore(12, moRelease)
doAssert i.genericLoad(moAcquire) == 12

type Big = object
  a, b, c: int
var y: Atomic[Big]
y.genericStore(Big(a: 1, b: 2, c: 3), moRelease)
doAssert y.genericLoad(moAcquire).c == 3

# an order that is not a constant expression is rejected, in a wrapper too:
var runtimeOrder = moRelaxed
doAssert not compiles(i.load(runtimeOrder))
doAssert not compiles(f.load(runtimeOrder))
doAssert not compiles(fence(runtimeOrder))
doAssert not compiles(f.compareExchange(expected, 1'u32, moRelease, runtimeOrder))

# `MemoryOrderKind` is the concrete enum:
var kind: MemoryOrderKind = moAcquire
doAssert $kind == "moAcquire"
var kinds: seq[MemoryOrderKind] = @[moRelaxed, moAcquire]
doAssert kinds.len == 2
type Config = object
  order: MemoryOrderKind
doAssert Config(order: moRelease).order == moRelease
var seen = 0
for k in MemoryOrderKind:
  inc seen
doAssert seen == 6

# and it is what an operation that really has to pick at run time dispatches on:
proc dynamicLoad(location: var Atomic[int]; order: MemoryOrderKind): int =
  case order
  of moRelaxed: location.load(moRelaxed)
  of moConsume: location.load(moConsume)
  of moAcquire: location.load(moAcquire)
  else: location.load(moSequentiallyConsistent)

doAssert i.dynamicLoad(kind) == 12
doAssert i.dynamicLoad(moRelaxed) == 12
