discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp"
  ccodecheck: "'atomic_store_explicit(' (!'memory_order) 3)' !\\n .)* 'memory_order) 3)'"
"""

# bug #26246: the memory order must reach the atomic builtin as a constant
# expression, even when the wrapper proc is not inlined; otherwise GCC
# silently uses `seq_cst` and Clang switches over the order at runtime.
# So the order is a `static` parameter.
import std/atomics
import std/assertions

var x: Atomic[int]
x.store(1, moRelease)
doAssert x.load(moAcquire) == 1
doAssert x.fetchAdd(3, moRelaxed) == 1
doAssert x.exchange(7, moAcquireRelease) == 4
doAssert x.load == 7

var expected = 7
doAssert x.compareExchange(expected, 8, moAcquireRelease)
expected = 1
doAssert not x.compareExchange(expected, 10, moRelease, moRelaxed)
doAssert expected == 8
while not x.compareExchangeWeak(expected, 10, moRelease): discard
while not x.compareExchangeWeak(expected, 11, moAcquireRelease, moAcquire): discard
doAssert x.load == 11

var flag: AtomicFlag
doAssert not flag.testAndSet(moAcquire)
flag.clear(moRelease)
fence(moAcquireRelease)
signalFence(moSequentiallyConsistent)

# a runtime order is rejected:
var o = moRelaxed
doAssert not compiles(x.load(o))
doAssert not compiles(x.store(1, o))
doAssert not compiles(x.compareExchange(expected, 1, moRelease, o))
doAssert not compiles(flag.clear(o))
doAssert not compiles(fence(o))

# not trivial types go through the spin lock:
type Big = object
  a, b, c: int
var y: Atomic[Big]
y.store(Big(a: 1, b: 2, c: 3), moRelease)
doAssert y.load(moAcquire).c == 3
var bigExpected = Big(a: 1, b: 2, c: 3)
doAssert y.compareExchange(bigExpected, Big(a: 4), moAcquireRelease)
doAssert y.load.a == 4
