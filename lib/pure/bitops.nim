#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim Authors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a series of low level methods for bit manipulation.

## By default, this module use compiler intrinsics where possible to improve performance
## on supported compilers: ``GCC``, ``LLVM_GCC``, ``CLANG``, ``VCC``, ``ICC``.
##
## The module will fallback to pure nim procs incase the backend is not supported.
## You can also use the flag `noIntrinsicsBitOpts` to disable compiler intrinsics.
##
## This module is also compatible with other backends: ``Javascript``, ``Nimscript``
## as well as the ``compiletime VM``.
##
## As a result of using optimized function/intrinsics some functions can return
## undefined results if the input is invalid. You can use the flag `noUndefinedBitOpts`
## to force predictable behaviour for all input, causing a small performance hit.
##
## At this time only `fastLog2`, `firstSetBit, `countLeadingZeroBits`, `countTrailingZeroBits`
## may return undefined and/or platform dependent value if given invalid input.

import macros
import std/private/since

proc bitnot*[T: SomeInteger](x: T): T {.magic: "BitnotI", noSideEffect.}
  ## Computes the `bitwise complement` of the integer `x`.

func internalBitand[T: SomeInteger](x, y: T): T {.magic: "BitandI".}

func internalBitor[T: SomeInteger](x, y: T): T {.magic: "BitorI".}

func internalBitxor[T: SomeInteger](x, y: T): T {.magic: "BitxorI".}

macro bitand*[T: SomeInteger](x, y: T; z: varargs[T]): T =
  ## Computes the `bitwise and` of all arguments collectively.
  let fn = bindSym("internalBitand")
  result = newCall(fn, x, y)
  for extra in z:
    result = newCall(fn, result, extra)

macro bitor*[T: SomeInteger](x, y: T; z: varargs[T]): T =
  ## Computes the `bitwise or` of all arguments collectively.
  let fn = bindSym("internalBitor")
  result = newCall(fn, x, y)
  for extra in z:
    result = newCall(fn, result, extra)

macro bitxor*[T: SomeInteger](x, y: T; z: varargs[T]): T =
  ## Computes the `bitwise xor` of all arguments collectively.
  let fn = bindSym("internalBitxor")
  result = newCall(fn, x, y)
  for extra in z:
    result = newCall(fn, result, extra)

const useBuiltins = not defined(noIntrinsicsBitOpts)
const noUndefined = defined(noUndefinedBitOpts)
const useGCC_builtins = (defined(gcc) or defined(llvm_gcc) or
                         defined(clang)) and useBuiltins
const useICC_builtins = defined(icc) and useBuiltins
const useVCC_builtins = defined(vcc) and useBuiltins
const arch64 = sizeof(int) == 8

template toUnsigned(x: int8): uint8 = cast[uint8](x)
template toUnsigned(x: int16): uint16 = cast[uint16](x)
template toUnsigned(x: int32): uint32 = cast[uint32](x)
template toUnsigned(x: int64): uint64 = cast[uint64](x)
template toUnsigned(x: int): uint = cast[uint](x)

template forwardImpl(impl, arg) {.dirty.} =
  when sizeof(x) <= 4:
    when x is SomeSignedInt:
      impl(cast[uint32](x.int32))
    else:
      impl(x.uint32)
  else:
    when x is SomeSignedInt:
      impl(cast[uint64](x.int64))
    else:
      impl(x.uint64)

when defined(nimHasalignOf):
  type BitsRange*[T] = range[0..sizeof(T)*8-1]
    ## A range with all bit positions for type ``T``

  func bitsliced*[T: SomeInteger](v: T; slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Returns an extracted (and shifted) slice of bits from ``v``.
    runnableExamples:
      doAssert 0b10111.bitsliced(2 .. 4) == 0b101
      doAssert 0b11100.bitsliced(0 .. 2) == 0b100
      doAssert 0b11100.bitsliced(0 ..< 3) == 0b100

    let
      upmost = sizeof(T) * 8 - 1
      uv     = when v is SomeUnsignedInt: v else: v.toUnsigned
    (uv shl (upmost - slice.b) shr (upmost - slice.b + slice.a)).T

  proc bitslice*[T: SomeInteger](v: var T; slice: Slice[int]) {.inline, since: (1, 3).} =
    ## Mutates ``v`` into an extracted (and shifted) slice of bits from ``v``.
    runnableExamples:
      var x = 0b101110
      x.bitslice(2 .. 4)
      doAssert x == 0b011

    let
      upmost = sizeof(T) * 8 - 1
      uv     = when v is SomeUnsignedInt: v else: v.toUnsigned
    v = (uv shl (upmost - slice.b) shr (upmost - slice.b + slice.a)).T

  func toMask*[T: SomeInteger](slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Creates a bitmask based on a slice of bits.
    runnableExamples:
      doAssert toMask[int32](1 .. 3) == 0b1110'i32
      doAssert toMask[int32](0 .. 3) == 0b1111'i32

    let
      upmost = sizeof(T) * 8 - 1
      bitmask = when T is SomeUnsignedInt:
                  bitnot(0.T)
                else:
                  bitnot(0.T).toUnsigned
    (bitmask shl (upmost - slice.b + slice.a) shr (upmost - slice.b)).T

  proc masked*[T: SomeInteger](v, mask :T): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with only the ``1`` bits from ``mask`` matching those of
    ## ``v`` set to 1.
    ##
    ## Effectively maps to a `bitand` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.masked(0b0000_1010'u8) == 0b0000_0010'u8

    bitand(v, mask)

  func masked*[T: SomeInteger](v: T; slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Mutates ``v``, with only the ``1`` bits in the range of ``slice``
    ## matching those of ``v`` set to 1.
    ##
    ## Effectively maps to a `bitand` operation.
    runnableExamples:
      var v = 0b0000_1011'u8
      doAssert v.masked(1 .. 3) == 0b0000_1010'u8

    bitand(v, toMask[T](slice))

  proc mask*[T: SomeInteger](v: var T; mask: T) {.inline, since: (1, 3).} =
    ## Mutates ``v``, with only the ``1`` bits from ``mask`` matching those of
    ## ``v`` set to 1.
    ##
    ## Effectively maps to a `bitand` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      v.mask(0b0000_1010'u8)
      doAssert v == 0b0000_0010'u8

    v = bitand(v, mask)

  proc mask*[T: SomeInteger](v: var T; slice: Slice[int]) {.inline, since: (1, 3).} =
    ## Mutates ``v``, with only the ``1`` bits in the range of ``slice``
    ## matching those of ``v`` set to 1.
    ##
    ## Effectively maps to a `bitand` operation.
    runnableExamples:
      var v = 0b0000_1011'u8
      v.mask(1 .. 3)
      doAssert v == 0b0000_1010'u8

    v = bitand(v, toMask[T](slice))

  func setMasked*[T: SomeInteger](v, mask :T): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` set to 1.
    ##
    ## Effectively maps to a `bitor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.setMasked(0b0000_1010'u8) == 0b0000_1011'u8

    bitor(v, mask)

  func setMasked*[T: SomeInteger](v: T; slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits in the range of ``slice`` set to 1.
    ##
    ## Effectively maps to a `bitor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.setMasked(2 .. 3) == 0b0000_1111'u8

    bitor(v, toMask[T](slice))

  proc setMask*[T: SomeInteger](v: var T; mask: T) {.inline.} =
    ## Mutates ``v``, with all the ``1`` bits from ``mask`` set to 1.
    ##
    ## Effectively maps to a `bitor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      v.setMask(0b0000_1010'u8)
      doAssert v == 0b0000_1011'u8

    v = bitor(v, mask)

  proc setMask*[T: SomeInteger](v: var T; slice: Slice[int]) {.inline, since: (1, 3).} =
    ## Mutates ``v``, with all the ``1`` bits in the range of ``slice`` set to 1.
    ##
    ## Effectively maps to a `bitor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      v.setMask(2 .. 3)
      doAssert v == 0b0000_1111'u8

    v = bitor(v, toMask[T](slice))

  func clearMasked*[T: SomeInteger](v, mask :T): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` set to 0.
    ##
    ## Effectively maps to a `bitand` operation with an *inverted mask.*
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.clearMasked(0b0000_1010'u8) == 0b0000_0001'u8

    bitand(v, bitnot(mask))

  func clearMasked*[T: SomeInteger](v: T; slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits in the range of ``slice`` set to 0.
    ##
    ## Effectively maps to a `bitand` operation with an *inverted mask.*
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.clearMasked(1 .. 3) == 0b0000_0001'u8

    bitand(v, bitnot(toMask[T](slice)))

  proc clearMask*[T: SomeInteger](v: var T; mask: T) {.inline.} =
    ## Mutates ``v``, with all the ``1`` bits from ``mask`` set to 0.
    ##
    ## Effectively maps to a `bitand` operation with an *inverted mask.*
    runnableExamples:
      var v = 0b0000_0011'u8
      v.clearMask(0b0000_1010'u8)
      doAssert v == 0b0000_0001'u8

    v = bitand(v, bitnot(mask))

  proc clearMask*[T: SomeInteger](v: var T; slice: Slice[int]) {.inline, since: (1, 3).} =
    ## Mutates ``v``, with all the ``1`` bits in the range of ``slice`` set to 0.
    ##
    ## Effectively maps to a `bitand` operation with an *inverted mask.*
    runnableExamples:
      var v = 0b0000_0011'u8
      v.clearMask(1 .. 3)
      doAssert v == 0b0000_0001'u8

    v = bitand(v, bitnot(toMask[T](slice)))

  func flipMasked*[T: SomeInteger](v, mask :T): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` flipped.
    ##
    ## Effectively maps to a `bitxor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.flipMasked(0b0000_1010'u8) == 0b0000_1001'u8

    bitxor(v, mask)

  func flipMasked*[T: SomeInteger](v: T; slice: Slice[int]): T {.inline, since: (1, 3).} =
    ## Returns ``v``, with all the ``1`` bits in the range of ``slice`` flipped.
    ##
    ## Effectively maps to a `bitxor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      doAssert v.flipMasked(1 .. 3) == 0b0000_1101'u8

    bitxor(v, toMask[T](slice))

  proc flipMask*[T: SomeInteger](v: var T; mask: T) {.inline.} =
    ## Mutates ``v``, with all the ``1`` bits from ``mask`` flipped.
    ##
    ## Effectively maps to a `bitxor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      v.flipMask(0b0000_1010'u8)
      doAssert v == 0b0000_1001'u8

    v = bitxor(v, mask)

  proc flipMask*[T: SomeInteger](v: var T; slice: Slice[int]) {.inline, since: (1, 3).} =
    ## Mutates ``v``, with all the ``1`` bits in the range of ``slice`` flipped.
    ##
    ## Effectively maps to a `bitxor` operation.
    runnableExamples:
      var v = 0b0000_0011'u8
      v.flipMask(1 .. 3)
      doAssert v == 0b0000_1101'u8

    v = bitxor(v, toMask[T](slice))

  proc setBit*[T: SomeInteger](v: var T; bit: BitsRange[T]) {.inline.} =
    ## Mutates ``v``, with the bit at position ``bit`` set to 1
    runnableExamples:
      var v = 0b0000_0011'u8
      v.setBit(5'u8)
      doAssert v == 0b0010_0011'u8

    v.setMask(1.T shl bit)

  proc clearBit*[T: SomeInteger](v: var T; bit: BitsRange[T]) {.inline.} =
    ## Mutates ``v``, with the bit at position ``bit`` set to 0
    runnableExamples:
      var v = 0b0000_0011'u8
      v.clearBit(1'u8)
      doAssert v == 0b0000_0001'u8

    v.clearMask(1.T shl bit)

  proc flipBit*[T: SomeInteger](v: var T; bit: BitsRange[T]) {.inline.} =
    ## Mutates ``v``, with the bit at position ``bit`` flipped
    runnableExamples:
      var v = 0b0000_0011'u8
      v.flipBit(1'u8)
      doAssert v == 0b0000_0001'u8

      v = 0b0000_0011'u8
      v.flipBit(2'u8)
      doAssert v == 0b0000_0111'u8

    v.flipMask(1.T shl bit)

  macro setBits*(v: typed; bits: varargs[typed]): untyped =
    ## Mutates ``v``, with the bits at positions ``bits`` set to 1
    runnableExamples:
      var v = 0b0000_0011'u8
      v.setBits(3, 5, 7)
      doAssert v == 0b1010_1011'u8

    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("setBit", v, bit)

  macro clearBits*(v: typed; bits: varargs[typed]): untyped =
    ## Mutates ``v``, with the bits at positions ``bits`` set to 0
    runnableExamples:
      var v = 0b1111_1111'u8
      v.clearBits(1, 3, 5, 7)
      doAssert v == 0b0101_0101'u8

    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("clearBit", v, bit)

  macro flipBits*(v: typed; bits: varargs[typed]): untyped =
    ## Mutates ``v``, with the bits at positions ``bits`` set to 0
    runnableExamples:
      var v = 0b0000_1111'u8
      v.flipBits(1, 3, 5, 7)
      doAssert v == 0b1010_0101'u8

    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("flipBit", v, bit)


  proc testBit*[T: SomeInteger](v: T; bit: BitsRange[T]): bool {.inline.} =
    ## Returns true if the bit in ``v`` at positions ``bit`` is set to 1
    runnableExamples:
      var v = 0b0000_1111'u8
      doAssert v.testBit(0)
      doAssert not v.testBit(7)

    let mask = 1.T shl bit
    return (v and mask) == mask

# #### Pure Nim version ####

proc firstSetBitNim(x: uint32): int {.inline, noSideEffect.} =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  const lookup: array[32, uint8] = [0'u8, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15,
    25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9]
  var v = x.uint32
  var k = not v + 1 # get two's complement # cast[uint32](-cast[int32](v))
  result = 1 + lookup[uint32((v and k) * 0x077CB531'u32) shr 27].int

proc firstSetBitNim(x: uint64): int {.inline, noSideEffect.} =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  var v = uint64(x)
  var k = uint32(v and 0xFFFFFFFF'u32)
  if k == 0:
    k = uint32(v shr 32'u32) and 0xFFFFFFFF'u32
    result = 32
  else:
    result = 0
  result += firstSetBitNim(k)

proc fastlog2Nim(x: uint32): int {.inline, noSideEffect.} =
  ## Quickly find the log base 2 of a 32-bit or less integer.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#IntegerLogDeBruijn
  # https://stackoverflow.com/questions/11376288/fast-computing-of-log2-for-64-bit-integers
  const lookup: array[32, uint8] = [0'u8, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18,
    22, 25, 3, 30, 8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31]
  var v = x.uint32
  v = v or v shr 1 # first round down to one less than a power of 2
  v = v or v shr 2
  v = v or v shr 4
  v = v or v shr 8
  v = v or v shr 16
  result = lookup[uint32(v * 0x07C4ACDD'u32) shr 27].int

proc fastlog2Nim(x: uint64): int {.inline, noSideEffect.} =
  ## Quickly find the log base 2 of a 64-bit integer.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#IntegerLogDeBruijn
  # https://stackoverflow.com/questions/11376288/fast-computing-of-log2-for-64-bit-integers
  const lookup: array[64, uint8] = [0'u8, 58, 1, 59, 47, 53, 2, 60, 39, 48, 27, 54,
    33, 42, 3, 61, 51, 37, 40, 49, 18, 28, 20, 55, 30, 34, 11, 43, 14, 22, 4, 62,
    57, 46, 52, 38, 26, 32, 41, 50, 36, 17, 19, 29, 10, 13, 21, 56, 45, 25, 31,
    35, 16, 9, 12, 44, 24, 15, 8, 23, 7, 6, 5, 63]
  var v = x.uint64
  v = v or v shr 1 # first round down to one less than a power of 2
  v = v or v shr 2
  v = v or v shr 4
  v = v or v shr 8
  v = v or v shr 16
  v = v or v shr 32
  result = lookup[(v * 0x03F6EAF2CD271461'u64) shr 58].int

# sets.nim cannot import bitops, but bitops can use include
# system/sets to eliminate code duplication. sets.nim defines
# countBits32 and countBits64.
include system/sets

template countSetBitsNim(n: uint32): int = countBits32(n)
template countSetBitsNim(n: uint64): int = countBits64(n)

template parityImpl[T](value: T): int =
  # formula id from: https://graphics.stanford.edu/%7Eseander/bithacks.html#ParityParallel
  var v = value
  when sizeof(T) == 8:
    v = v xor (v shr 32)
  when sizeof(T) >= 4:
    v = v xor (v shr 16)
  when sizeof(T) >= 2:
    v = v xor (v shr 8)
  v = v xor (v shr 4)
  v = v and 0xf
  ((0x6996'u shr v) and 1).int


when useGCC_builtins:
  # Returns the number of set 1-bits in value.
  proc builtin_popcount(x: cuint): cint {.importc: "__builtin_popcount", cdecl.}
  proc builtin_popcountll(x: culonglong): cint {.
      importc: "__builtin_popcountll", cdecl.}

  # Returns the bit parity in value
  proc builtin_parity(x: cuint): cint {.importc: "__builtin_parity", cdecl.}
  proc builtin_parityll(x: culonglong): cint {.importc: "__builtin_parityll", cdecl.}

  # Returns one plus the index of the least significant 1-bit of x, or if x is zero, returns zero.
  proc builtin_ffs(x: cint): cint {.importc: "__builtin_ffs", cdecl.}
  proc builtin_ffsll(x: clonglong): cint {.importc: "__builtin_ffsll", cdecl.}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  proc builtin_clz(x: cuint): cint {.importc: "__builtin_clz", cdecl.}
  proc builtin_clzll(x: culonglong): cint {.importc: "__builtin_clzll", cdecl.}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  proc builtin_ctz(x: cuint): cint {.importc: "__builtin_ctz", cdecl.}
  proc builtin_ctzll(x: culonglong): cint {.importc: "__builtin_ctzll", cdecl.}

elif useVCC_builtins:
  # Counts the number of one bits (population count) in a 16-, 32-, or 64-byte unsigned integer.
  proc builtin_popcnt16(a2: uint16): uint16 {.
      importc: "__popcnt16"header: "<intrin.h>", noSideEffect.}
  proc builtin_popcnt32(a2: uint32): uint32 {.
      importc: "__popcnt"header: "<intrin.h>", noSideEffect.}
  proc builtin_popcnt64(a2: uint64): uint64 {.
      importc: "__popcnt64"header: "<intrin.h>", noSideEffect.}

  # Search the mask data from most significant bit (MSB) to least significant bit (LSB) for a set bit (1).
  proc bitScanReverse(index: ptr culong, mask: culong): cuchar {.
      importc: "_BitScanReverse", header: "<intrin.h>", noSideEffect.}
  proc bitScanReverse64(index: ptr culong, mask: uint64): cuchar {.
      importc: "_BitScanReverse64", header: "<intrin.h>", noSideEffect.}

  # Search the mask data from least significant bit (LSB) to the most significant bit (MSB) for a set bit (1).
  proc bitScanForward(index: ptr culong, mask: culong): cuchar {.
      importc: "_BitScanForward", header: "<intrin.h>", noSideEffect.}
  proc bitScanForward64(index: ptr culong, mask: uint64): cuchar {.
      importc: "_BitScanForward64", header: "<intrin.h>", noSideEffect.}

  template vcc_scan_impl(fnc: untyped; v: untyped): int =
    var index: culong
    discard fnc(index.addr, v)
    index.int

elif useICC_builtins:

  # Intel compiler intrinsics: http://fulla.fnal.gov/intel/compiler_c/main_cls/intref_cls/common/intref_allia_misc.htm
  # see also: https://software.intel.com/en-us/node/523362
  # Count the number of bits set to 1 in an integer a, and return that count in dst.
  proc builtin_popcnt32(a: cint): cint {.
      importc: "_popcnt"header: "<immintrin.h>", noSideEffect.}
  proc builtin_popcnt64(a: uint64): cint {.
      importc: "_popcnt64"header: "<immintrin.h>", noSideEffect.}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  proc bitScanForward(p: ptr uint32, b: uint32): cuchar {.
      importc: "_BitScanForward", header: "<immintrin.h>", noSideEffect.}
  proc bitScanForward64(p: ptr uint32, b: uint64): cuchar {.
      importc: "_BitScanForward64", header: "<immintrin.h>", noSideEffect.}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  proc bitScanReverse(p: ptr uint32, b: uint32): cuchar {.
      importc: "_BitScanReverse", header: "<immintrin.h>", noSideEffect.}
  proc bitScanReverse64(p: ptr uint32, b: uint64): cuchar {.
      importc: "_BitScanReverse64", header: "<immintrin.h>", noSideEffect.}

  template icc_scan_impl(fnc: untyped; v: untyped): int =
    var index: uint32
    discard fnc(index.addr, v)
    index.int


proc countSetBits*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Counts the set bits in integer. (also called `Hamming weight`:idx:.)
  runnableExamples:
    doAssert countSetBits(0b0000_0011'u8) == 2
    doAssert countSetBits(0b1010_1010'u8) == 4

  # TODO: figure out if ICC support _popcnt32/_popcnt64 on platform without POPCNT.
  # like GCC and MSVC
  when x is SomeSignedInt:
    let x = x.toUnsigned
  when nimvm:
    result = forwardImpl(countSetBitsNim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_popcount(x.cuint).int
      else: result = builtin_popcountll(x.culonglong).int
    elif useVCC_builtins:
      when sizeof(x) <= 2: result = builtin_popcnt16(x.uint16).int
      elif sizeof(x) <= 4: result = builtin_popcnt32(x.uint32).int
      elif arch64: result = builtin_popcnt64(x.uint64).int
      else: result = builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).uint32).int +
                     builtin_popcnt32((x.uint64 shr 32'u64).uint32).int
    elif useICC_builtins:
      when sizeof(x) <= 4: result = builtin_popcnt32(x.cint).int
      elif arch64: result = builtin_popcnt64(x.uint64).int
      else: result = builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).cint).int +
                     builtin_popcnt32((x.uint64 shr 32'u64).cint).int
    else:
      when sizeof(x) <= 4: result = countSetBitsNim(x.uint32)
      else: result = countSetBitsNim(x.uint64)

proc popcount*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Alias for for `countSetBits <#countSetBits,SomeInteger>`_. (Hamming weight.)
  result = countSetBits(x)

proc parityBits*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Calculate the bit parity in integer. If number of 1-bit
  ## is odd parity is 1, otherwise 0.
  runnableExamples:
    doAssert parityBits(0b0000_0000'u8) == 0
    doAssert parityBits(0b0101_0001'u8) == 1
    doAssert parityBits(0b0110_1001'u8) == 0
    doAssert parityBits(0b0111_1111'u8) == 1

  # Can be used a base if creating ASM version.
  # https://stackoverflow.com/questions/21617970/how-to-check-if-value-has-even-parity-of-bits-or-odd
  when x is SomeSignedInt:
    let x = x.toUnsigned
  when nimvm:
    result = forwardImpl(parityImpl, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_parity(x.uint32).int
      else: result = builtin_parityll(x.uint64).int
    else:
      when sizeof(x) <= 4: result = parityImpl(x.uint32)
      else: result = parityImpl(x.uint64)

proc firstSetBit*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Returns the 1-based index of the least significant set bit of x.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  runnableExamples:
    doAssert firstSetBit(0b0000_0001'u8) == 1
    doAssert firstSetBit(0b0000_0010'u8) == 2
    doAssert firstSetBit(0b0000_0100'u8) == 3
    doAssert firstSetBit(0b0000_1000'u8) == 4
    doAssert firstSetBit(0b0000_1111'u8) == 1

  # GCC builtin 'builtin_ffs' already handle zero input.
  when x is SomeSignedInt:
    let x = x.toUnsigned
  when nimvm:
    when noUndefined:
      if x == 0:
        return 0
    result = forwardImpl(firstSetBitNim, x)
  else:
    when noUndefined and not useGCC_builtins:
      if x == 0:
        return 0
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_ffs(cast[cint](x.cuint)).int
      else: result = builtin_ffsll(cast[clonglong](x.culonglong)).int
    elif useVCC_builtins:
      when sizeof(x) <= 4:
        result = 1 + vcc_scan_impl(bitScanForward, x.culong)
      elif arch64:
        result = 1 + vcc_scan_impl(bitScanForward64, x.uint64)
      else:
        result = firstSetBitNim(x.uint64)
    elif useICC_builtins:
      when sizeof(x) <= 4:
        result = 1 + icc_scan_impl(bitScanForward, x.uint32)
      elif arch64:
        result = 1 + icc_scan_impl(bitScanForward64, x.uint64)
      else:
        result = firstSetBitNim(x.uint64)
    else:
      when sizeof(x) <= 4: result = firstSetBitNim(x.uint32)
      else: result = firstSetBitNim(x.uint64)

proc fastLog2*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Quickly find the log base 2 of an integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is -1,
  ## otherwise result is undefined.
  runnableExamples:
    doAssert fastLog2(0b0000_0001'u8) == 0
    doAssert fastLog2(0b0000_0010'u8) == 1
    doAssert fastLog2(0b0000_0100'u8) == 2
    doAssert fastLog2(0b0000_1000'u8) == 3
    doAssert fastLog2(0b0000_1111'u8) == 3

  when x is SomeSignedInt:
    let x = x.toUnsigned
  when noUndefined:
    if x == 0:
      return -1
  when nimvm:
    result = forwardImpl(fastlog2Nim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = 31 - builtin_clz(x.uint32).int
      else: result = 63 - builtin_clzll(x.uint64).int
    elif useVCC_builtins:
      when sizeof(x) <= 4:
        result = vcc_scan_impl(bitScanReverse, x.culong)
      elif arch64:
        result = vcc_scan_impl(bitScanReverse64, x.uint64)
      else:
        result = fastlog2Nim(x.uint64)
    elif useICC_builtins:
      when sizeof(x) <= 4:
        result = icc_scan_impl(bitScanReverse, x.uint32)
      elif arch64:
        result = icc_scan_impl(bitScanReverse64, x.uint64)
      else:
        result = fastlog2Nim(x.uint64)
    else:
      when sizeof(x) <= 4: result = fastlog2Nim(x.uint32)
      else: result = fastlog2Nim(x.uint64)

proc countLeadingZeroBits*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Returns the number of leading zero bits in integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  ##
  ## See also:
  ## * `countTrailingZeroBits proc <#countTrailingZeroBits,SomeInteger>`_
  runnableExamples:
    doAssert countLeadingZeroBits(0b0000_0001'u8) == 7
    doAssert countLeadingZeroBits(0b0000_0010'u8) == 6
    doAssert countLeadingZeroBits(0b0000_0100'u8) == 5
    doAssert countLeadingZeroBits(0b0000_1000'u8) == 4
    doAssert countLeadingZeroBits(0b0000_1111'u8) == 4

  when x is SomeSignedInt:
    let x = x.toUnsigned
  when noUndefined:
    if x == 0:
      return 0
  when nimvm:
    result = sizeof(x)*8 - 1 - forwardImpl(fastlog2Nim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_clz(x.uint32).int - (32 - sizeof(x)*8)
      else: result = builtin_clzll(x.uint64).int
    else:
      when sizeof(x) <= 4: result = sizeof(x)*8 - 1 - fastlog2Nim(x.uint32)
      else: result = sizeof(x)*8 - 1 - fastlog2Nim(x.uint64)

proc countTrailingZeroBits*(x: SomeInteger): int {.inline, noSideEffect.} =
  ## Returns the number of trailing zeros in integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  ##
  ## See also:
  ## * `countLeadingZeroBits proc <#countLeadingZeroBits,SomeInteger>`_
  runnableExamples:
    doAssert countTrailingZeroBits(0b0000_0001'u8) == 0
    doAssert countTrailingZeroBits(0b0000_0010'u8) == 1
    doAssert countTrailingZeroBits(0b0000_0100'u8) == 2
    doAssert countTrailingZeroBits(0b0000_1000'u8) == 3
    doAssert countTrailingZeroBits(0b0000_1111'u8) == 0

  when x is SomeSignedInt:
    let x = x.toUnsigned
  when noUndefined:
    if x == 0:
      return 0
  when nimvm:
    result = firstSetBit(x) - 1
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_ctz(x.uint32).int
      else: result = builtin_ctzll(x.uint64).int
    else:
      result = firstSetBit(x) - 1


proc rotateLeftBits*(value: uint8;
           amount: range[0..8]): uint8 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 8-bits value.
  runnableExamples:
    doAssert rotateLeftBits(0b0000_0001'u8, 1) == 0b0000_0010'u8
    doAssert rotateLeftBits(0b0000_0001'u8, 2) == 0b0000_0100'u8
    doAssert rotateLeftBits(0b0100_0001'u8, 1) == 0b1000_0010'u8
    doAssert rotateLeftBits(0b0100_0001'u8, 2) == 0b0000_0101'u8

  # using this form instead of the one below should handle any value
  # out of range as well as negative values.
  # result = (value shl amount) or (value shr (8 - amount))
  # taken from: https://en.wikipedia.org/wiki/Circular_shift#Implementing_circular_shifts
  let amount = amount and 7
  result = (value shl amount) or (value shr ( (-amount) and 7))

proc rotateLeftBits*(value: uint16;
           amount: range[0..16]): uint16 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 16-bits value.
  ##
  ## See also:
  ## * `rotateLeftBits proc <#rotateLeftBits,uint8,range[]>`_
  let amount = amount and 15
  result = (value shl amount) or (value shr ( (-amount) and 15))

proc rotateLeftBits*(value: uint32;
           amount: range[0..32]): uint32 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 32-bits value.
  ##
  ## See also:
  ## * `rotateLeftBits proc <#rotateLeftBits,uint8,range[]>`_
  let amount = amount and 31
  result = (value shl amount) or (value shr ( (-amount) and 31))

proc rotateLeftBits*(value: uint64;
           amount: range[0..64]): uint64 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 64-bits value.
  ##
  ## See also:
  ## * `rotateLeftBits proc <#rotateLeftBits,uint8,range[]>`_
  let amount = amount and 63
  result = (value shl amount) or (value shr ( (-amount) and 63))


proc rotateRightBits*(value: uint8;
            amount: range[0..8]): uint8 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 8-bits value.
  runnableExamples:
    doAssert rotateRightBits(0b0000_0001'u8, 1) == 0b1000_0000'u8
    doAssert rotateRightBits(0b0000_0001'u8, 2) == 0b0100_0000'u8
    doAssert rotateRightBits(0b0100_0001'u8, 1) == 0b1010_0000'u8
    doAssert rotateRightBits(0b0100_0001'u8, 2) == 0b0101_0000'u8

  let amount = amount and 7
  result = (value shr amount) or (value shl ( (-amount) and 7))

proc rotateRightBits*(value: uint16;
            amount: range[0..16]): uint16 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 16-bits value.
  ##
  ## See also:
  ## * `rotateRightBits proc <#rotateRightBits,uint8,range[]>`_
  let amount = amount and 15
  result = (value shr amount) or (value shl ( (-amount) and 15))

proc rotateRightBits*(value: uint32;
            amount: range[0..32]): uint32 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 32-bits value.
  ##
  ## See also:
  ## * `rotateRightBits proc <#rotateRightBits,uint8,range[]>`_
  let amount = amount and 31
  result = (value shr amount) or (value shl ( (-amount) and 31))

proc rotateRightBits*(value: uint64;
            amount: range[0..64]): uint64 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 64-bits value.
  ##
  ## See also:
  ## * `rotateRightBits proc <#rotateRightBits,uint8,range[]>`_
  let amount = amount and 63
  result = (value shr amount) or (value shl ( (-amount) and 63))

proc repeatBits[T: SomeUnsignedInt](x: SomeUnsignedInt; retType: type[T]): T {.
  noSideEffect.} =
  result = x
  var i = 1
  while i != (sizeof(T) div sizeof(x)):
    result = (result shl (sizeof(x)*8*i)) or result
    i *= 2

proc reverseBits*[T: SomeUnsignedInt](x: T): T {.noSideEffect.} =
  ## Return the bit reversal of x.
  runnableExamples:
    doAssert reverseBits(0b10100100'u8) == 0b00100101'u8
    doAssert reverseBits(0xdd'u8) == 0xbb'u8
    doAssert reverseBits(0xddbb'u16) == 0xddbb'u16
    doAssert reverseBits(0xdeadbeef'u32) == 0xf77db57b'u32

  template repeat(x: SomeUnsignedInt): T = repeatBits(x, T)

  result = x
  result =
    ((repeat(0x55u8) and result) shl 1) or
    ((repeat(0xaau8) and result) shr 1)
  result =
    ((repeat(0x33u8) and result) shl 2) or
    ((repeat(0xccu8) and result) shr 2)
  when sizeof(T) == 1:
    result = (result shl 4) or (result shr 4)
  when sizeof(T) >= 2:
    result =
      ((repeat(0x0fu8) and result) shl 4) or
      ((repeat(0xf0u8) and result) shr 4)
  when sizeof(T) == 2:
    result = (result shl 8) or (result shr 8)
  when sizeof(T) >= 4:
    result =
      ((repeat(0x00ffu16) and result) shl 8) or
      ((repeat(0xff00u16) and result) shr 8)
  when sizeof(T) == 4:
    result = (result shl 16) or (result shr 16)
  when sizeof(T) == 8:
    result =
      ((repeat(0x0000ffffu32) and result) shl 16) or
      ((repeat(0xffff0000u32) and result) shr 16)
    result = (result shl 32) or (result shr 32)
