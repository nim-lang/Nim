discard """
  targets: "cpp"
  matrix: "-d:nimUseCppAtomics"
  ccodecheck: "'.store(' (!'memory_order) 3)' !\\n .)* 'memory_order) 3)'"
"""

# bug #26246: with `std::atomic` the memory order is a `static` parameter too.
import std/atomics
import std/assertions

var x: Atomic[int]
x.store(1, moRelease)
doAssert x.load(moAcquire) == 1
doAssert x.fetchAdd(3, moRelaxed) == 1
doAssert x.exchange(7, moAcquireRelease) == 4

var expected = 7
doAssert x.compareExchange(expected, 8, moAcquireRelease)
expected = 1
doAssert not x.compareExchange(expected, 10, moRelease, moRelaxed)
doAssert expected == 8
while not x.compareExchangeWeak(expected, 11, moAcquireRelease, moAcquire): discard
doAssert x.load == 11

var flag: AtomicFlag
doAssert not flag.testAndSet(moAcquire)
flag.clear(moRelease)
fence(moAcquireRelease)
signalFence(moSequentiallyConsistent)

var o = moRelaxed
doAssert not compiles(x.load(o))
doAssert not compiles(x.compareExchange(expected, 1, moRelease, o))
doAssert not compiles(flag.clear(o))
doAssert not compiles(fence(o))
