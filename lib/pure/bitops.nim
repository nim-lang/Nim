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
## may return undefined and/or platform dependant value if given invalid input.


const useBuiltins = not defined(noIntrinsicsBitOpts)
const noUndefined = defined(noUndefinedBitOpts)
const useGCC_builtins = (defined(gcc) or defined(llvm_gcc) or defined(clang)) and useBuiltins
const useICC_builtins = defined(icc) and useBuiltins
const useVCC_builtins = defined(vcc) and useBuiltins
const arch64 = sizeof(int) == 8

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

  import macros

  type BitsRange*[T] = range[0..sizeof(T)*8-1]
    ## Returns a range with all bit positions for type ``T``

  proc setMask*[T: SomeInteger](v: var T, mask: T) {.inline.} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` set to 1
    v = v or mask

  proc clearMask*[T: SomeInteger](v: var T, mask: T) {.inline.} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` set to 0
    v = v and not mask

  proc flipMask*[T: SomeInteger](v: var T, mask: T) {.inline.} =
    ## Returns ``v``, with all the ``1`` bits from ``mask`` flipped
    v = v xor mask

  proc setBit*[T: SomeInteger](v: var T, bit: BitsRange[T]) {.inline.} =
    ## Returns ``v``, with the bit at position ``bit`` set to 1
    v.setMask(1.T shl bit)

  proc clearBit*[T: SomeInteger](v: var T, bit: BitsRange[T]) {.inline.} =
    ## Returns ``v``, with the bit at position ``bit`` set to 0
    v.clearMask(1.T shl bit)

  proc flipBit*[T: SomeInteger](v: var T, bit: BitsRange[T]) {.inline.} =
    ## Returns ``v``, with the bit at position ``bit`` flipped
    v.flipMask(1.T shl bit)

  macro setBits*(v: typed, bits: varargs[typed]): untyped =
    ## Returns ``v``, with the bits at positions ``bits`` set to 1
    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("setBit", v, bit)

  macro clearBits*(v: typed, bits: varargs[typed]): untyped =
    ## Returns ``v``, with the bits at positions ``bits`` set to 0
    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("clearBit", v, bit)

  macro flipBits*(v: typed, bits: varargs[typed]): untyped =
    ## Returns ``v``, with the bits at positions ``bits`` set to 0
    bits.expectKind(nnkBracket)
    result = newStmtList()
    for bit in bits:
      result.add newCall("flipBit", v, bit)

  proc testBit*[T: SomeInteger](v: T, bit: BitsRange[T]): bool {.inline.} =
    ## Returns true if the bit in ``v`` at positions ``bit`` is set to 1
    let mask = 1.T shl bit
    return (v and mask) == mask

# #### Pure Nim version ####

proc firstSetBit_nim(x: uint32): int {.inline, nosideeffect.} =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  const lookup: array[32, uint8] = [0'u8, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15,
    25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9]
  var v = x.uint32
  var k = not v + 1 # get two's complement # cast[uint32](-cast[int32](v))
  result = 1 + lookup[uint32((v and k) * 0x077CB531'u32) shr 27].int

proc firstSetBit_nim(x: uint64): int {.inline, nosideeffect.} =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  var v = uint64(x)
  var k = uint32(v and 0xFFFFFFFF'u32)
  if k == 0:
    k = uint32(v shr 32'u32) and 0xFFFFFFFF'u32
    result = 32
  result += firstSetBit_nim(k)

proc fastlog2_nim(x: uint32): int {.inline, nosideeffect.} =
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

proc fastlog2_nim(x: uint64): int {.inline, nosideeffect.} =
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


proc countSetBits_nim(n: uint32): int {.inline, noSideEffect.} =
  ## Counts the set bits in integer. (also called Hamming weight.)
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel

  var v = uint32(n)
  v = v - ((v shr 1) and 0x55555555)
  v = (v and 0x33333333) + ((v shr 2) and 0x33333333)
  result = (((v + (v shr 4) and 0xF0F0F0F) * 0x1010101) shr 24).int

proc countSetBits_nim(n: uint64): int {.inline, noSideEffect.} =
  ## Counts the set bits in integer. (also called Hamming weight.)
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = uint64(n)
  v = v - ((v shr 1'u64) and 0x5555555555555555'u64)
  v = (v and 0x3333333333333333'u64) + ((v shr 2'u64) and 0x3333333333333333'u64)
  v = (v + (v shr 4'u64) and 0x0F0F0F0F0F0F0F0F'u64)
  result = ((v * 0x0101010101010101'u64) shr 56'u64).int


template parity_impl[T](value: T): int =
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
  proc builtin_popcountll(x: culonglong): cint {.importc: "__builtin_popcountll", cdecl.}

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
  proc builtin_popcnt16(a2: uint16): uint16 {.importc: "__popcnt16" header: "<intrin.h>", nosideeffect.}
  proc builtin_popcnt32(a2: uint32): uint32 {.importc: "__popcnt" header: "<intrin.h>", nosideeffect.}
  proc builtin_popcnt64(a2: uint64): uint64 {.importc: "__popcnt64" header: "<intrin.h>", nosideeffect.}

  # Search the mask data from most significant bit (MSB) to least significant bit (LSB) for a set bit (1).
  proc bitScanReverse(index: ptr culong, mask: culong): cuchar {.importc: "_BitScanReverse", header: "<intrin.h>", nosideeffect.}
  proc bitScanReverse64(index: ptr culong, mask: uint64): cuchar {.importc: "_BitScanReverse64", header: "<intrin.h>", nosideeffect.}

  # Search the mask data from least significant bit (LSB) to the most significant bit (MSB) for a set bit (1).
  proc bitScanForward(index: ptr culong, mask: culong): cuchar {.importc: "_BitScanForward", header: "<intrin.h>", nosideeffect.}
  proc bitScanForward64(index: ptr culong, mask: uint64): cuchar {.importc: "_BitScanForward64", header: "<intrin.h>", nosideeffect.}

  template vcc_scan_impl(fnc: untyped; v: untyped): int =
    var index: culong
    discard fnc(index.addr, v)
    index.int

elif useICC_builtins:

  # Intel compiler intrinsics: http://fulla.fnal.gov/intel/compiler_c/main_cls/intref_cls/common/intref_allia_misc.htm
  # see also: https://software.intel.com/en-us/node/523362
  # Count the number of bits set to 1 in an integer a, and return that count in dst.
  proc builtin_popcnt32(a: cint): cint {.importc: "_popcnt" header: "<immintrin.h>", nosideeffect.}
  proc builtin_popcnt64(a: uint64): cint {.importc: "_popcnt64" header: "<immintrin.h>", nosideeffect.}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  proc bitScanForward(p: ptr uint32, b: uint32): cuchar {.importc: "_BitScanForward", header: "<immintrin.h>", nosideeffect.}
  proc bitScanForward64(p: ptr uint32, b: uint64): cuchar {.importc: "_BitScanForward64", header: "<immintrin.h>", nosideeffect.}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  proc bitScanReverse(p: ptr uint32, b: uint32): cuchar {.importc: "_BitScanReverse", header: "<immintrin.h>", nosideeffect.}
  proc bitScanReverse64(p: ptr uint32, b: uint64): cuchar {.importc: "_BitScanReverse64", header: "<immintrin.h>", nosideeffect.}

  template icc_scan_impl(fnc: untyped; v: untyped): int =
    var index: uint32
    discard fnc(index.addr, v)
    index.int


proc countSetBits*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Counts the set bits in integer. (also called `Hamming weight`:idx:.)
  # TODO: figure out if ICC support _popcnt32/_popcnt64 on platform without POPCNT.
  # like GCC and MSVC
  when nimvm:
    result = forwardImpl(countSetBits_nim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_popcount(x.cuint).int
      else:                result = builtin_popcountll(x.culonglong).int
    elif useVCC_builtins:
      when sizeof(x) <= 2: result = builtin_popcnt16(x.uint16).int
      elif sizeof(x) <= 4: result = builtin_popcnt32(x.uint32).int
      elif arch64:         result = builtin_popcnt64(x.uint64).int
      else:                result = builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).uint32 ).int +
                                    builtin_popcnt32((x.uint64 shr 32'u64).uint32 ).int
    elif useICC_builtins:
      when sizeof(x) <= 4: result = builtin_popcnt32(x.cint).int
      elif arch64:         result = builtin_popcnt64(x.uint64).int
      else:                result = builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).cint ).int +
                                    builtin_popcnt32((x.uint64 shr 32'u64).cint ).int
    else:
      when sizeof(x) <= 4: result = countSetBits_nim(x.uint32)
      else:                result = countSetBits_nim(x.uint64)

proc popcount*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Alias for for countSetBits (Hamming weight.)
  result = countSetBits(x)

proc parityBits*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Calculate the bit parity in integer. If number of 1-bit
  ## is odd parity is 1, otherwise 0.
  # Can be used a base if creating ASM version.
  # https://stackoverflow.com/questions/21617970/how-to-check-if-value-has-even-parity-of-bits-or-odd
  when nimvm:
    result = forwardImpl(parity_impl, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_parity(x.uint32).int
      else:                result = builtin_parityll(x.uint64).int
    else:
      when sizeof(x) <= 4: result = parity_impl(x.uint32)
      else:                result = parity_impl(x.uint64)

proc firstSetBit*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Returns the 1-based index of the least significant set bit of x.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  # GCC builtin 'builtin_ffs' already handle zero input.
  when nimvm:
    when noUndefined:
      if x == 0:
        return 0
    result = forwardImpl(firstSetBit_nim, x)
  else:
    when noUndefined and not useGCC_builtins:
      if x == 0:
        return 0
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_ffs(cast[cint](x.cuint)).int
      else:                result = builtin_ffsll(cast[clonglong](x.culonglong)).int
    elif useVCC_builtins:
      when sizeof(x) <= 4:
        result = 1 + vcc_scan_impl(bitScanForward, x.culong)
      elif arch64:
        result = 1 + vcc_scan_impl(bitScanForward64, x.uint64)
      else:
        result = firstSetBit_nim(x.uint64)
    elif useICC_builtins:
      when sizeof(x) <= 4:
        result = 1 + icc_scan_impl(bitScanForward, x.uint32)
      elif arch64:
        result = 1 + icc_scan_impl(bitScanForward64, x.uint64)
      else:
        result = firstSetBit_nim(x.uint64)
    else:
      when sizeof(x) <= 4: result = firstSetBit_nim(x.uint32)
      else:                result = firstSetBit_nim(x.uint64)

proc fastLog2*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Quickly find the log base 2 of an integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is -1,
  ## otherwise result is undefined.
  when noUndefined:
    if x == 0:
      return -1
  when nimvm:
    result = forwardImpl(fastlog2_nim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = 31 - builtin_clz(x.uint32).int
      else:                result = 63 - builtin_clzll(x.uint64).int
    elif useVCC_builtins:
      when sizeof(x) <= 4:
        result = vcc_scan_impl(bitScanReverse, x.culong)
      elif arch64:
        result = vcc_scan_impl(bitScanReverse64, x.uint64)
      else:
        result = fastlog2_nim(x.uint64)
    elif useICC_builtins:
      when sizeof(x) <= 4:
        result = icc_scan_impl(bitScanReverse, x.uint32)
      elif arch64:
        result = icc_scan_impl(bitScanReverse64, x.uint64)
      else:
        result = fastlog2_nim(x.uint64)
    else:
      when sizeof(x) <= 4: result = fastlog2_nim(x.uint32)
      else:                result = fastlog2_nim(x.uint64)

proc countLeadingZeroBits*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Returns the number of leading zero bits in integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  when noUndefined:
    if x == 0:
      return 0
  when nimvm:
    result = sizeof(x)*8 - 1 - forwardImpl(fastlog2_nim, x)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_clz(x.uint32).int - (32 - sizeof(x)*8)
      else:                result = builtin_clzll(x.uint64).int
    else:
      when sizeof(x) <= 4: result = sizeof(x)*8 - 1 - fastlog2_nim(x.uint32)
      else:                result = sizeof(x)*8 - 1 - fastlog2_nim(x.uint64)

proc countTrailingZeroBits*(x: SomeInteger): int {.inline, nosideeffect.} =
  ## Returns the number of trailing zeros in integer.
  ## If `x` is zero, when ``noUndefinedBitOpts`` is set, result is 0,
  ## otherwise result is undefined.
  when noUndefined:
    if x == 0:
      return 0
  when nimvm:
    result = firstSetBit(x) - 1
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: result = builtin_ctz(x.uint32).int
      else:                result = builtin_ctzll(x.uint64).int
    else:
      result = firstSetBit(x) - 1


proc rotateLeftBits*(value: uint8;
           amount: range[0..8]): uint8 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 8-bits value.
  # using this form instead of the one below should handle any value
  # out of range as well as negative values.
  # result = (value shl amount) or (value shr (8 - amount))
  # taken from: https://en.wikipedia.org/wiki/Circular_shift#Implementing_circular_shifts
  let amount = amount and 7
  result = (value shl amount) or (value shr ( (-amount) and 7))

proc rotateLeftBits*(value: uint16;
           amount: range[0..16]): uint16 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 16-bits value.
  let amount = amount and 15
  result = (value shl amount) or (value shr ( (-amount) and 15))

proc rotateLeftBits*(value: uint32;
           amount: range[0..32]): uint32 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 32-bits value.
  let amount = amount and 31
  result = (value shl amount) or (value shr ( (-amount) and 31))

proc rotateLeftBits*(value: uint64;
           amount: range[0..64]): uint64 {.inline, noSideEffect.} =
  ## Left-rotate bits in a 64-bits value.
  let amount = amount and 63
  result = (value shl amount) or (value shr ( (-amount) and 63))


proc rotateRightBits*(value: uint8;
            amount: range[0..8]): uint8 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 8-bits value.
  let amount = amount and 7
  result = (value shr amount) or (value shl ( (-amount) and 7))

proc rotateRightBits*(value: uint16;
            amount: range[0..16]): uint16 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 16-bits value.
  let amount = amount and 15
  result = (value shr amount) or (value shl ( (-amount) and 15))

proc rotateRightBits*(value: uint32;
            amount: range[0..32]): uint32 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 32-bits value.
  let amount = amount and 31
  result = (value shr amount) or (value shl ( (-amount) and 31))

proc rotateRightBits*(value: uint64;
            amount: range[0..64]): uint64 {.inline, noSideEffect.} =
  ## Right-rotate bits in a 64-bits value.
  let amount = amount and 63
  result = (value shr amount) or (value shl ( (-amount) and 63))
