discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp"
  ccodecheck: "'atomic_store_explicit(' (!'memory_order) 3)' !\\n .)* 'memory_order) 3)'"
"""

# bug #26246: a constant memory order must reach the C11 atomic builtin as a
# constant expression, even when the wrapper proc is not inlined; otherwise
# GCC silently uses `seq_cst` and Clang switches over the order at runtime.
import std/atomics
import std/assertions

var x: Atomic[int]
x.store(1, moRelease)
doAssert x.load(moAcquire) == 1

# runtime orders keep working:
proc wrappedStore(loc: var Atomic[int]; v: int; order: MemoryOrder) =
  loc.store(v, order)

proc wrappedLoad(loc: var Atomic[int]; order: MemoryOrder): int =
  loc.load(order)

var o = moRelaxed
wrappedStore(x, 2, o)
doAssert wrappedLoad(x, moSequentiallyConsistent) == 2
doAssert x.fetchAdd(3, o) == 2
doAssert x.exchange(7, moAcquireRelease) == 5

var expected = 7
doAssert x.compareExchange(expected, 8, moAcquireRelease)
expected = 8
doAssert x.compareExchange(expected, 9, o)
expected = 1
doAssert not x.compareExchange(expected, 10, moRelease, moRelaxed)
doAssert expected == 9
while not x.compareExchangeWeak(expected, 10, moRelease): discard
while not x.compareExchangeWeak(expected, 11, moAcquireRelease, moAcquire): discard
doAssert x.load == 11

# not trivial types go through the spin lock:
type Big = object
  a, b, c: int
var y: Atomic[Big]
y.store(Big(a: 1, b: 2, c: 3), moRelease)
doAssert y.load(moAcquire).c == 3
var bigExpected = Big(a: 1, b: 2, c: 3)
doAssert y.compareExchange(bigExpected, Big(a: 4), moAcquireRelease)
doAssert y.load(o).a == 4
