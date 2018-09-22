#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim Authors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a series of low level methods for bit manipulation.
## By default, this module use compiler intrinsics to improve performance
## on supported compilers: ``GCC``, ``LLVM_GCC``, ``CLANG``, ``VCC``, ``ICC``.
##
## The module will fallback to pure nim procs incase the backend is not supported.
## You can also use the flag `noIntrinsicsBitOpts` to disable compiler intrinsics.
##
## This module is also compatible with other backends: ``Javascript``, ``Nimscript``
## as well as the ``compiletime VM``.
##
## As a result of using optimized function/intrinsics some functions can return
## undefined results if the input is invalid. You can use the ``maybe*`` flags to
## disable the extra checking.


const useBuiltins = not defined(noIntrinsicsBitOpts)
const noUndefined = defined(noUndefinedBitOpts)
const useGCC_builtins = (defined(gcc) or defined(llvm_gcc) or defined(clang)) and useBuiltins
const useICC_builtins = defined(icc) and useBuiltins
const useVCC_builtins = defined(vcc) and useBuiltins
const arch64 = sizeof(int) == 8

when defined(noUndefinedBitOpts):
  {.deprecated: "no undefined bitops deprecated, use parameter instead" .}

template toUnsigned(x: int8): uint8 = x.uint8
template toUnsigned(x: int16): uint16 = x.uint16
template toUnsigned(x: int32): uint32 = x.uint32
template toUnsigned(x: int64): uint64 = x.uint64
template toUnsigned(x: int): uint = x.uint

# #### Pure Nim version ####

func firstOneBitNim(x: uint32): int =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  const lookup: array[32, uint8] = [0'u8, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15,
    25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9]
  var v = x.uint32
  var k = not v + 1 # get two's complement # cast[uint32](-cast[int32](v))
  result = 1 + lookup[uint32((v and k) * 0x077CB531'u32) shr 27].int

func firstOneBitNim(x: uint64): int =
  ## Returns the 1-based index of the least significant set bit of x, or if x is zero, returns zero.
  # https://graphics.stanford.edu/%7Eseander/bithacks.html#ZerosOnRightMultLookup
  var v = uint64(x)
  var k = uint32(v and 0xFFFFFFFF'u32)
  if k == 0:
    k = uint32(v shr 32'u32) and 0xFFFFFFFF'u32
    result = 32
  result += firstOneBitNim(k)

func fastLog2Nim(x: uint32): int =
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

func fastLog2Nim(x: uint64): int =
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

func oneBitsNim(n: uint32): int =
  ## Counts the set bits in integer. (also called Hamming weight.)
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel

  var v = n
  v = v - ((v shr 1) and 0x55555555)
  v = (v and 0x33333333) + ((v shr 2) and 0x33333333)
  result = (((v + (v shr 4) and 0xF0F0F0F) * 0x1010101) shr 24).int

func oneBitsNim(n: uint64): int =
  ## Counts the set bits in integer. (also called Hamming weight.)
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = n
  v = v - ((v shr 1'u64) and 0x5555555555555555'u64)
  v = (v and 0x3333333333333333'u64) + ((v shr 2'u64) and 0x3333333333333333'u64)
  v = (v + (v shr 4'u64) and 0x0F0F0F0F0F0F0F0F'u64)
  result = ((v * 0x0101010101010101'u64) shr 56'u64).int

func parityBitsNim[T](value: T): int =
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
  func builtin_popcount(x: cuint): cint {.importc: "__builtin_popcount", cdecl.}
  func builtin_popcountll(x: culonglong): cint {.importc: "__builtin_popcountll", cdecl.}

  # Returns the bit parity in value
  func builtin_parity(x: cuint): cint {.importc: "__builtin_parity", cdecl.}
  func builtin_parityll(x: culonglong): cint {.importc: "__builtin_parityll", cdecl.}

  # Returns one plus the index of the least significant 1-bit of x, or if x is zero, returns zero.
  func builtin_ffs(x: cint): cint {.importc: "__builtin_ffs", cdecl.}
  func builtin_ffsll(x: clonglong): cint {.importc: "__builtin_ffsll", cdecl.}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  func builtin_clz(x: cuint): cint {.importc: "__builtin_clz", cdecl.}
  func builtin_clzll(x: culonglong): cint {.importc: "__builtin_clzll", cdecl.}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  func builtin_ctz(x: cuint): cint {.importc: "__builtin_ctz", cdecl.}
  func builtin_ctzll(x: culonglong): cint {.importc: "__builtin_ctzll", cdecl.}

elif useVCC_builtins:

  # Counts the number of one bits (population count) in a 16-, 32-, or 64-byte unsigned integer.
  func builtin_popcnt16(a2: uint16): uint16 {.importc: "__popcnt16" header: "<intrin.h>".}
  func builtin_popcnt32(a2: uint32): uint32 {.importc: "__popcnt" header: "<intrin.h>".}
  func builtin_popcnt64(a2: uint64): uint64 {.importc: "__popcnt64" header: "<intrin.h>".}

  # Search the mask data from most significant bit (MSB) to least significant bit (LSB) for a set bit (1).
  func bitScanReverse(index: ptr culong, mask: culong): cuchar {.importc: "_BitScanReverse", header: "<intrin.h>".}
  func bitScanReverse64(index: ptr culong, mask: uint64): cuchar {.importc: "_BitScanReverse64", header: "<intrin.h>".}

  # Search the mask data from least significant bit (LSB) to the most significant bit (MSB) for a set bit (1).
  func bitScanForward(index: ptr culong, mask: culong): cuchar {.importc: "_BitScanForward", header: "<intrin.h>".}
  func bitScanForward64(index: ptr culong, mask: uint64): cuchar {.importc: "_BitScanForward64", header: "<intrin.h>".}

  template vcc_scan_impl(fnc: untyped, v: untyped): int =
    var index: culong
    discard fnc(index.addr, v)
    index.int

elif useICC_builtins:

  # Intel compiler intrinsics: http://fulla.fnal.gov/intel/compiler_c/main_cls/intref_cls/common/intref_allia_misc.htm
  # see also: https://software.intel.com/en-us/node/523362
  # Count the number of bits set to 1 in an integer a, and return that count in dst.
  func builtin_popcnt32(a: cint): cint {.importc: "_popcnt" header: "<immintrin.h>".}
  func builtin_popcnt64(a: uint64): cint {.importc: "_popcnt64" header: "<immintrin.h>".}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  func bitScanForward(p: ptr uint32, b: uint32): cuchar {.importc: "_BitScanForward", header: "<immintrin.h>".}
  func bitScanForward64(p: ptr uint32, b: uint64): cuchar {.importc: "_BitScanForward64", header: "<immintrin.h>".}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  func bitScanReverse(p: ptr uint32, b: uint32): cuchar {.importc: "_BitScanReverse", header: "<immintrin.h>".}
  func bitScanReverse64(p: ptr uint32, b: uint64): cuchar {.importc: "_BitScanReverse64", header: "<immintrin.h>".}

  template icc_scan_impl(fnc: untyped, v: untyped): int =
    var index: uint32
    discard fnc(index.addr, v)
    index.int


func oneBits*(x: SomeUnsignedInt): int {.inline.} =
  ## Counts the set bits in integer. (also called `Hamming weight`:idx:.)
  ##
  ## Example:
  ## doAssert oneBits(0b01000100'u8) == 2
  # TODO: figure out if ICC support _popcnt32/_popcnt64 on platform without POPCNT.
  # like GCC and MSVC
  when nimvm:
    when sizeof(x) <= 4: oneBitsNim(x.uint32)
    else:                oneBitsNim(x.uint64)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: builtin_popcount(x.cuint).int
      else:                builtin_popcountll(x.culonglong).int
    elif useVCC_builtins:
      when sizeof(x) <= 2: builtin_popcnt16(x.uint16).int
      elif sizeof(x) <= 4: builtin_popcnt32(x.uint32).int
      elif arch64:         builtin_popcnt64(x.uint64).int
      else:                builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).uint32 ).int +
                          builtin_popcnt32((x.uint64 shr 32'u64).uint32 ).int
    elif useICC_builtins:
      when sizeof(x) <= 4: builtin_popcnt32(x.cint).int
      elif arch64:         builtin_popcnt64(x.uint64).int
      else:                builtin_popcnt32((x.uint64 and 0xFFFFFFFF'u64).cint ).int +
                          builtin_popcnt32((x.uint64 shr 32'u64).cint ).int
    else:
      when sizeof(x) <= 4: oneBitsNim(x.uint32)
      else:                oneBitsNim(x.uint64)

func countSetBits*(x: SomeUnsignedInt): int {.inline, deprecated: "oneBits".}=
  oneBits(x)
func countSetBits*(x: SomeSignedInt): int {.inline, deprecated: "oneBits".}=
  oneBits(x.toUnsigned)

func popcount*(x: SomeUnsignedInt): int {.inline, deprecated: "oneBits".}=
  oneBits(x)
func popcount*(x: SomeSignedInt): int {.inline, deprecated: "oneBits".}=
  oneBits(x.toUnsigned)

func parityBits*(x: SomeUnsignedInt): int {.inline.} =
  ## Calculate the bit parity in integer. If number of 1-bit
  ## is odd parity is 1, otherwise 0.
  ##
  ## Example:
  ## doAssert parityBits(0b00000001'u8) == 1
  # Can be used a base if creating ASM version.
  # https://stackoverflow.com/questions/21617970/how-to-check-if-value-has-even-parity-of-bits-or-odd
  when nimvm:
    when sizeof(x) <= 4: parityBitsNim(x.uint32)
    else:                parityBitsNim(x.uint64)
  else:
    when useGCC_builtins:
      when sizeof(x) <= 4: builtin_parity(x.uint32).int
      else:                builtin_parityll(x.uint64).int
    else:
      when sizeof(x) <= 4: parityBitsNim(x.uint32)
      else:                parityBitsNim(x.uint64)

func parityBits*(x: SomeSignedInt): int {.inline, deprecated.} =
  parityBits(x.toUnsigned)

func firstOneBit*(x: SomeUnsignedInt, maybeZero = true): int {.inline.} =
  ## Returns the 1-based index of the least significant set bit of x.
  ## If `x` is zero and `maybeZero` is true, result is 0
  ## If `x` is zero and `maybeZero` is false, result is undefined
  ##
  ## Example:
  ## doAssert firstOneBit(0b00000010'u8) == 2
  ##
  when nimvm:
    if maybeZero and x == 0: 0
    elif sizeof(x) <= 4: firstOneBitNim(x.uint32)
    else:                firstOneBitNim(x.uint64)
  else:
    when useGCC_builtins:
      # GCC builtin 'builtin_ffs' already handle zero input.
      when sizeof(x) <= 4: builtin_ffs(cast[cint](x.cuint)).int
      else:                builtin_ffsll(cast[clonglong](x.culonglong)).int
    elif useVCC_builtins:
      if maybeZero and x == 0: 0
      elif sizeof(x) <= 4: 1 + vcc_scan_impl(bitScanForward, x.culong)
      elif arch64:         1 + vcc_scan_impl(bitScanForward64, x.uint64)
      else:                firstOneBitNim(x.uint64)
    elif useICC_builtins:
      if maybeZero and x == 0: 0
      elif sizeof(x) <= 4: 1 + icc_scan_impl(bitScanForward, x.uint32)
      elif arch64:         1 + icc_scan_impl(bitScanForward64, x.uint64)
      else:                firstOneBitNim(x.uint64)
    else:
      if maybeZero and x == 0: 0
      elif sizeof(x) <= 4: firstOneBitNim(x.uint32)
      else:                firstOneBitNim(x.uint64)

func firstSetBit*(x: SomeUnsignedInt): int {.inline, deprecated: "firstOneBit".} =
  firstOneBit(x, noUndefined)
func firstSetBit*(x: SomeSignedInt): int {.inline, deprecated: "firstOneBit".} =
  firstOneBit(x.toUnsigned, noUndefined)

func fastLog2Bit*(x: SomeUnsignedInt, maybeZero = true): int {.inline.} =
  ## Return the truncated base 2 logarithm of `x`
  ## If `x` is zero and `maybeZero` is true, result is -1
  ## If `x` is zero and `maybeZero` is false, result is undefined
  ##
  ## Example:
  ## doAssert fastLog2Bit(0b01000000'u8) == 6
  if maybeZero and x == 0: -1
  else:
    when nimvm:
      when sizeof(x) <= 4: fastLog2Nim(x.uint32)
      else:                fastLog2Nim(x.uint64)
    else:
      when useGCC_builtins:
        when sizeof(x) <= 4: 31 - builtin_clz(x.uint32).int
        else:                63 - builtin_clzll(x.uint64).int
      elif useVCC_builtins:
        when sizeof(x) <= 4: vcc_scan_impl(bitScanReverse, x.culong)
        elif arch64:         vcc_scan_impl(bitScanReverse64, x.uint64)
        else:                fastLog2Nim(x.uint64)
      elif useICC_builtins:
        when sizeof(x) <= 4: icc_scan_impl(bitScanReverse, x.uint32)
        elif arch64:         icc_scan_impl(bitScanReverse64, x.uint64)
        else:                fastLog2Nim(x.uint64)
      else:
        when sizeof(x) <= 4: fastLog2Nim(x.uint32)
        else:                fastLog2Nim(x.uint64)

func fastLog2*(x: SomeUnsignedInt): int {.inline, deprecated: "fastLog2Bit".} =
  fastLog2Bit(x, noUndefined)
func fastLog2*(x: SomeSignedInt): int {.inline, deprecated: "fastLog2Bit".} =
  fastLog2Bit(x.toUnsigned, noUndefined)

func leadingZeroBits*(x: SomeInteger, maybeZero = true): int {.inline.} =
  ## Returns the number of leading zero bits in integer.
  ## If `x` is zero and maybeZero is true, result is sizeof(x) * 8
  ## If `x` is zero and maybeZero is false, result is undefined
  ##
  ## Example:
  ## doAssert leadingZeroBits(0b00100000'u8) == 2
  ##
  ## Performance note:
  ## On recent x86_64 cpu's, this translates to the LZCNT instruction
  if maybeZero and x == 0: sizeof(x) * 8
  else:
    when nimvm:
      when sizeof(x) <= 4: sizeof(x)*8 - 1 - fastLog2Nim(x.uint32)
      else:                sizeof(x)*8 - 1 - fastLog2Nim(x.uint64)
    else:
      when useGCC_builtins:
        when sizeof(x) <= sizeof(cuint):
          builtin_clz(x.cuint).int - (sizeof(cuint) - sizeof(x)) * 8
        else:
          builtin_clzll(x.culonglong).int
      else:
        when sizeof(x) <= 4: sizeof(x)*8 - 1 - fastLog2Nim(x.uint32)
        else:                sizeof(x)*8 - 1 - fastLog2Nim(x.uint64)

func countLeadingZeroBits*(x: SomeUnsignedInt): int {.inline, deprecated: "leadingZeroBits".} =
  leadingZeroBits(x, noUndefined)
func countLeadingZeroBits*(x: SomeSignedInt): int {.inline, deprecated: "leadingZeroBits".} =
  leadingZeroBits(x.toUnsigned, noUndefined)

func trailingZeroBits*(x: SomeUnsignedInt, maybeZero = true): int =
  ## Returns the number of trailing zeros in integer.
  ## If `x` is zero and maybeZero is true, result is sizeof(x) * 8
  ## If `x` is zero and maybeZero is false, result is undefined
  ##
  ## Example:
  ## doAssert trailingZeroBits(0b00000010'u8) == 1
  ##
  ## Performance note:
  ## On recent x86_64 cpu's, this translates to the TZCNT instruction
  if maybeZero and x == 0: sizeof(x) * 8
  else:
    when nimvm:
      firstOneBit(x) - 1
    else:
      when useGCC_builtins:
        when sizeof(x) <= sizeof(cuint): builtin_ctz(x.cuint).int
        else:                            builtin_ctzll(x.culonglong).int
      else: firstOneBit(x) - 1

func countTrailingZeroBits*(x: SomeUnsignedInt): int {.inline, deprecated: "trailingZeroBits".} =
  trailingZeroBits(x, noUndefined)
func countTrailingZeroBits*(x: SomeSignedInt): int {.inline, deprecated: "trailingZeroBits".} =
  trailingZeroBits(x.toUnsigned, noUndefined)

func rotateLeftBits*(value: uint8, amount: range[0..8]): uint8 =
  ## Left-rotate bits in a 8-bits value.
  # using this form instead of the one below should handle any value
  # out of range as well as negative values.
  # result = (value shl amount) or (value shr (8 - amount))
  # taken from: https://en.wikipedia.org/wiki/Circular_shift#Implementing_circular_shifts
  let amount = amount and 7
  result = (value shl amount) or (value shr ( (-amount) and 7))

func rotateLeftBits*(value: uint16, amount: range[0..16]): uint16  =
  ## Left-rotate bits in a 16-bits value.
  let amount = amount and 15
  result = (value shl amount) or (value shr ( (-amount) and 15))

func rotateLeftBits*(value: uint32, amount: range[0..32]): uint32  =
  ## Left-rotate bits in a 32-bits value.
  let amount = amount and 31
  result = (value shl amount) or (value shr ( (-amount) and 31))

func rotateLeftBits*(value: uint64, amount: range[0..64]): uint64  =
  ## Left-rotate bits in a 64-bits value.
  let amount = amount and 63
  result = (value shl amount) or (value shr ( (-amount) and 63))

func rotateRightBits*(value: uint8, amount: range[0..8]): uint8  =
  ## Right-rotate bits in a 8-bits value.
  let amount = amount and 7
  result = (value shr amount) or (value shl ( (-amount) and 7))

func rotateRightBits*(value: uint16, amount: range[0..16]): uint16  =
  ## Right-rotate bits in a 16-bits value.
  let amount = amount and 15
  result = (value shr amount) or (value shl ( (-amount) and 15))

func rotateRightBits*(value: uint32, amount: range[0..32]): uint32  =
  ## Right-rotate bits in a 32-bits value.
  let amount = amount and 31
  result = (value shr amount) or (value shl ( (-amount) and 31))

func rotateRightBits*(value: uint64, amount: range[0..64]): uint64  =
  ## Right-rotate bits in a 64-bits value.
  let amount = amount and 63
  result = (value shr amount) or (value shl ( (-amount) and 63))

when isMainModule:
  static:
    doAssert oneBits(0b01000100'u8) == 2
    doAssert parityBits(0b00000001'u8) == 1
    doAssert firstOneBit(0b00000010'u8) == 2
    doAssert fastLog2Bit(0b01000000'u8) == 6
    doAssert oneBits(0b01000100'u8) == 2
    doAssert leadingZeroBits(0b00100000'u8) == 2
    doAssert trailingZeroBits(0b00000010'u8) == 1
