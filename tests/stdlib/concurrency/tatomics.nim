discard """
  matrix: "--mm:refc; --mm:orc; --mm:refc -d:nimUseCppAtomics; --mm:orc -d:nimUseCppAtomics"
  targets: "c cpp"
"""

# Tests for std/atomics
# Covers: API operations, lock-free eligibility matrix, architecture detection

import std/atomics
import std/assertions


# =============================================================================
# API Tests - Basic atomic operations
# =============================================================================

block loadWithMemoryOrders:
  var a: Atomic[int]
  a.store(1)
  doAssert a.load == 1
  a.store(2)
  doAssert a.load(moRelaxed) == 2
  a.store(3)
  doAssert a.load(moAcquire) == 3

block storeWithMemoryOrders:
  var a: Atomic[int]
  a.store(1)
  doAssert a.load == 1
  a.store(2, moRelaxed)
  doAssert a.load == 2
  a.store(3, moRelease)
  doAssert a.load == 3

block exchangeWithMemoryOrders:
  var a: Atomic[int]
  a.store(1)
  doAssert a.exchange(2) == 1
  doAssert a.exchange(3, moRelaxed) == 2
  doAssert a.exchange(4, moAcquire) == 3
  doAssert a.exchange(5, moRelease) == 4
  doAssert a.exchange(6, moAcquireRelease) == 5
  doAssert a.load == 6

block compareExchangeSuccess:
  var a: Atomic[int]
  var expected = 1
  a.store(1)
  doAssert a.compareExchange(expected, 2)
  doAssert expected == 1
  doAssert a.load == 2

  expected = 2
  doAssert a.compareExchange(expected, 3, moRelaxed)
  expected = 3
  doAssert a.compareExchange(expected, 4, moAcquire)
  expected = 4
  doAssert a.compareExchange(expected, 5, moRelease)
  expected = 5
  doAssert a.compareExchange(expected, 6, moAcquireRelease)
  doAssert a.load == 6

block compareExchangeFailure:
  var a: Atomic[int]
  var expected = 999
  a.store(1)
  doAssert not a.compareExchange(expected, 2)
  doAssert expected == 1  # Updated to actual value
  doAssert a.load == 1

block compareExchangeWithSuccessFailureOrders:
  var a: Atomic[int]
  var expected = 1
  a.store(1)
  doAssert a.compareExchange(expected, 2, moSequentiallyConsistent, moSequentiallyConsistent)
  expected = 2
  doAssert a.compareExchange(expected, 3, moRelaxed, moRelaxed)
  expected = 3
  doAssert a.compareExchange(expected, 4, moAcquire, moAcquire)
  expected = 4
  doAssert a.compareExchange(expected, 5, moRelease, moRelease)
  expected = 5
  doAssert a.compareExchange(expected, 6, moAcquireRelease, moAcquireRelease)
  doAssert a.load == 6

block compareExchangeWeak:
  var a: Atomic[int]
  var expected = 1
  a.store(1)
  doAssert a.compareExchangeWeak(expected, 2)
  expected = 2
  doAssert a.compareExchangeWeak(expected, 3, moRelaxed)
  expected = 3
  doAssert a.compareExchangeWeak(expected, 4, moAcquire)
  expected = 4
  doAssert a.compareExchangeWeak(expected, 5, moRelease)
  expected = 5
  doAssert a.compareExchangeWeak(expected, 6, moAcquireRelease)
  doAssert a.load == 6

block fetchAddSub:
  var a: Atomic[int]
  doAssert a.fetchAdd(1) == 0
  doAssert a.fetchAdd(1, moRelaxed) == 1
  doAssert a.fetchAdd(1, moRelease) == 2
  doAssert a.load == 3

  a.store(0)
  doAssert a.fetchSub(1) == 0
  doAssert a.fetchSub(1, moRelaxed) == -1
  doAssert a.fetchSub(1, moRelease) == -2
  doAssert a.load == -3

block fetchBitwise:
  var a: Atomic[int]

  # fetchAnd
  a.store(0b1111)
  doAssert a.fetchAnd(0b1010) == 0b1111
  doAssert a.load == 0b1010
  a.store(0b1111)
  doAssert a.fetchAnd(0b1010, moRelaxed) == 0b1111
  a.store(0b1111)
  doAssert a.fetchAnd(0b1010, moRelease) == 0b1111

  # fetchOr
  a.store(0b1010)
  doAssert a.fetchOr(0b0101) == 0b1010
  doAssert a.load == 0b1111
  a.store(0b1010)
  doAssert a.fetchOr(0b0101, moRelaxed) == 0b1010
  a.store(0b1010)
  doAssert a.fetchOr(0b0101, moRelease) == 0b1010

  # fetchXor
  a.store(0b1111)
  doAssert a.fetchXor(0b1010) == 0b1111
  doAssert a.load == 0b0101
  a.store(0b1111)
  doAssert a.fetchXor(0b1010, moRelaxed) == 0b1111
  a.store(0b1111)
  doAssert a.fetchXor(0b1010, moRelease) == 0b1111

block atomicIncDec:
  var a: Atomic[int]
  a.atomicInc
  doAssert a.load == 1
  a.atomicInc(2)
  doAssert a.load == 3
  a.atomicDec
  doAssert a.load == 2
  a.atomicDec(2)
  doAssert a.load == 0

  # += and -=
  a += 10
  doAssert a.load == 10
  a -= 3
  doAssert a.load == 7

block atomicFlag:
  var flag: AtomicFlag
  doAssert not flag.testAndSet
  doAssert flag.testAndSet
  flag.clear
  doAssert not flag.testAndSet

  # With memory orders
  flag.clear
  doAssert not flag.testAndSet(moRelaxed)
  doAssert flag.testAndSet(moRelaxed)
  flag.clear(moRelaxed)
  doAssert not flag.testAndSet(moRelease)
  doAssert flag.testAndSet(moRelease)
  flag.clear(moRelease)

block objectAtomics:
  type Point = object
    x, y: int32

  var p: Atomic[Point]
  p.store(Point(x: 10, y: 20))
  doAssert p.load.x == 10
  doAssert p.load.y == 20

  let old = p.exchange(Point(x: 30, y: 40))
  doAssert old.x == 10
  doAssert p.load.x == 30

  var expected = Point(x: 30, y: 40)
  doAssert p.compareExchange(expected, Point(x: 50, y: 60))
  doAssert p.load.x == 50


# =============================================================================
# Lock-Free Eligibility Tests
# =============================================================================

block primitiveTypes:
  # int (pointer-sized, always lock-free)
  doAssert isLockFree(int)
  var i: Atomic[int]
  i.store(42)
  doAssert i.load == 42

  # bool (1 byte)
  doAssert isLockFree(bool)
  var b: Atomic[bool]
  b.store(true)
  doAssert b.load == true
  doAssert b.exchange(false) == true

  # char (1 byte)
  doAssert isLockFree(char)
  var c: Atomic[char]
  c.store('A')
  doAssert c.load == 'A'
  doAssert c.exchange('B') == 'A'

  # ptr (pointer-sized)
  doAssert isLockFree(ptr int)
  var x = 42
  var p: Atomic[ptr int]
  p.store(addr x)
  doAssert p.load[] == 42

block enumAndDistinct:
  # enum
  type Color = enum red, green, blue
  doAssert isLockFree(Color)
  var col: Atomic[Color]
  col.store(green)
  doAssert col.load == green

  # distinct
  type MyInt = distinct int
  doAssert isLockFree(MyInt)
  var d: Atomic[MyInt]
  d.store(MyInt(100))
  doAssert int(d.load) == 100

block smallObjects:
  # 1 byte
  type Size1 = object
    a: int8
  doAssert sizeof(Size1) == 1
  doAssert isLockFree(Size1)

  # 2 bytes
  type Size2 = object
    a: int16
  doAssert sizeof(Size2) == 2
  doAssert isLockFree(Size2)

  # 4 bytes
  type Size4 = object
    a: int32
  doAssert sizeof(Size4) == 4
  doAssert isLockFree(Size4)

block eightByteTypes:
  # 8-byte object - lock-free depends on hasLockFree8
  type Size8 = object
    a, b: int32
  doAssert sizeof(Size8) == 8
  doAssert isLockFree(Size8) == hasLockFree8

  var s: Atomic[Size8]
  s.store(Size8(a: 1, b: 2))
  doAssert s.load.a == 1

  # tuple[a, b: int32] = 8 bytes
  type Tup2 = tuple[a, b: int32]
  doAssert sizeof(Tup2) == 8
  doAssert isLockFree(Tup2) == hasLockFree8

  # array[2, int32] = 8 bytes (skip with nimUseCppAtomics - C++ doesn't support)
  when not defined(nimUseCppAtomics):
    type Arr2 = array[2, int32]
    doAssert sizeof(Arr2) == 8
    doAssert isLockFree(Arr2) == hasLockFree8

block sixteenByteTypes:
  # 16-byte object - lock-free depends on hasLockFree16
  type Size16 = object
    a, b: int64
  doAssert sizeof(Size16) == 16
  doAssert isLockFree(Size16) == hasLockFree16

  var s: Atomic[Size16]
  s.store(Size16(a: 100, b: 200))
  doAssert s.load.a == 100
  doAssert s.load.b == 200

block bigObjects:
  # >16 bytes - never lock-free, uses spinlock fallback
  type Size32 = object
    a, b, c, d: int64
  doAssert sizeof(Size32) == 32
  doAssert not isLockFree(Size32)

  # But it still works (via spinlock)
  var big: Atomic[Size32]
  big.store(Size32(a: 1, b: 2, c: 3, d: 4))
  doAssert big.load.a == 1
  doAssert big.load.d == 4

block invalidSizes:
  # Sizes 3, 5, 6, 7 are NOT lock-free
  type Size3 {.packed.} = object
    a: int16
    b: int8
  doAssert sizeof(Size3) == 3
  doAssert not isLockFree(Size3)

  type Size5 {.packed.} = object
    a: int32
    b: int8
  doAssert sizeof(Size5) == 5
  doAssert not isLockFree(Size5)

  type Size6 {.packed.} = object
    a: int32
    b: int16
  doAssert sizeof(Size6) == 6
  doAssert not isLockFree(Size6)

  type Size7 {.packed.} = object
    a: int32
    b: int16
    c: int8
  doAssert sizeof(Size7) == 7
  doAssert not isLockFree(Size7)

block managedTypes:
  # ref, string, seq: lock-free with refc, NOT with arc/orc
  when defined(gcdestructors):
    doAssert not isLockFree(ref int)
    doAssert not isLockFree(string)
    doAssert not isLockFree(seq[int])
  else:
    doAssert isLockFree(ref int)
    doAssert isLockFree(string)
    doAssert isLockFree(seq[int])

block fieldAlignmentPragmas:
  # Field-level alignment affects struct size
  type WithAlignedField = object
    a: int8
    b {.align(8).}: int32  # Field aligned to 8 bytes, struct padded to 16
  doAssert sizeof(WithAlignedField) == 16  # 1 + 7 padding + 4 + 4 padding = 16
  doAssert isLockFree(WithAlignedField) == hasLockFree16

  # bycopy pragma (C interop) - should work like normal structs
  type CStruct {.bycopy.} = object
    x, y: int32
  doAssert sizeof(CStruct) == 8
  doAssert isLockFree(CStruct) == hasLockFree8

  var cs: Atomic[CStruct]
  cs.store(CStruct(x: 1, y: 2))
  doAssert cs.load.x == 1

  # packed pragma - removes padding
  type Packed {.packed.} = object
    a: int8
    b: int32
  doAssert sizeof(Packed) == 5  # No padding, so 1 + 4 = 5 bytes
  # 5-byte types are NOT lock-free (must be 1, 2, 4, 8, or 16)
  doAssert not isLockFree(Packed)

block unionTypes:
  # Union-like types via {.union.} pragma
  type IntOrFloat {.union.} = object
    i: int32
    f: float32
  doAssert sizeof(IntOrFloat) == 4
  doAssert isLockFree(IntOrFloat)

  var u: Atomic[IntOrFloat]
  u.store(IntOrFloat(i: 42))
  doAssert u.load.i == 42

block nestedTypes:
  # Nested objects
  type Inner = object
    a, b: int16
  type Outer = object
    inner: Inner
  doAssert sizeof(Outer) == 4
  doAssert isLockFree(Outer)

  var nested: Atomic[Outer]
  nested.store(Outer(inner: Inner(a: 1, b: 2)))
  doAssert nested.load.inner.a == 1

  # Nested with padding
  type InnerPadded = object
    a: int8
    b: int32  # Creates padding
  type OuterPadded = object
    inner: InnerPadded
  doAssert sizeof(OuterPadded) == 8
  doAssert isLockFree(OuterPadded) == hasLockFree8

block importcTypes:
  # Types marked for C interop
  type CInt {.importc: "int", nodecl.} = cint
  doAssert isLockFree(CInt)

block caseObjects:
  # Case objects - size depends on largest variant
  type Tagged = object
    case kind: bool
    of true: a: int32
    of false: b: int16
  # Size includes discriminant + largest variant + padding
  doAssert isLockFree(Tagged) == (sizeof(Tagged) in [1, 2, 4, 8, 16] and
    (sizeof(Tagged) < 8 or (sizeof(Tagged) == 8 and hasLockFree8) or
     (sizeof(Tagged) == 16 and hasLockFree16)))

# =============================================================================
# Architecture-Specific Tests
# =============================================================================

block hasLockFree8Tests:
  # hasLockFree8 = true:  64-bit, i386 (CMPXCHG8B), ARM32 (LDREXD)
  # hasLockFree8 = false: MIPS32, PowerPC32, SPARC32, RISC-V 32
  when sizeof(pointer) >= 8:
    doAssert hasLockFree8, "64-bit must have hasLockFree8"
  elif defined(i386):
    doAssert hasLockFree8, "i386 must have hasLockFree8 (CMPXCHG8B)"
  elif defined(arm):
    doAssert hasLockFree8, "ARM32 must have hasLockFree8 (LDREXD)"
  elif defined(mips) or defined(mipsel):
    doAssert not hasLockFree8, "MIPS32 must not have hasLockFree8"
  elif defined(powerpc) and sizeof(pointer) == 4:
    doAssert not hasLockFree8, "PowerPC32 must not have hasLockFree8"
  elif defined(sparc) and sizeof(pointer) == 4:
    doAssert not hasLockFree8, "SPARC32 must not have hasLockFree8"
  elif defined(riscv32):
    doAssert not hasLockFree8, "RISC-V 32 must not have hasLockFree8"

block hasLockFree16Tests:
  # hasLockFree16 = true:  amd64 (CMPXCHG16B), arm64 (LDXP/STXP)
  # hasLockFree16 = false: all 32-bit, other 64-bit architectures
  when defined(amd64):
    doAssert hasLockFree16, "amd64 must have hasLockFree16 (CMPXCHG16B)"
  elif defined(arm64):
    doAssert hasLockFree16, "arm64 must have hasLockFree16 (LDXP/STXP)"
  else:
    doAssert not hasLockFree16, "other architectures must not have hasLockFree16"


# =============================================================================
# Regression Tests
# =============================================================================

block bug18844:
  # Atomic field in object inheriting from RootObj
  when not defined(cpp):
    type
      Deprivation = object of RootObj
        memes: Atomic[int]
      Zoomer = object
        dopamine: Deprivation

    var x = Deprivation()
    var y = Zoomer()
    doAssert x.memes.load == 0
    doAssert y.dopamine.memes.load == 0
