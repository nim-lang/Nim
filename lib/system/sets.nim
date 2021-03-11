#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# set handling
from std/private/vmutils import forwardImpl, toUnsigned


const useBuiltins = not defined(noIntrinsicsBitOpts)
const noUndefined {.used.} = defined(noUndefinedBitOpts)
const useGCC_builtins = (defined(gcc) or defined(llvm_gcc) or
                         defined(clang)) and useBuiltins
const useICC_builtins = defined(icc) and useBuiltins
const useVCC_builtins = defined(vcc) and useBuiltins

type
  NimSet = array[0..4*2048-1, uint8]

# bitops can't be imported here, therefore the code duplication.

template countBitsImpl(n: uint32): int =
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = uint32(n)
  v = v - ((v shr 1'u32) and 0x55555555'u32)
  v = (v and 0x33333333'u32) + ((v shr 2'u32) and 0x33333333'u32)
  (((v + (v shr 4'u32) and 0xF0F0F0F'u32) * 0x1010101'u32) shr 24'u32).int

template countBitsImpl(n: uint64): int =
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = uint64(n)
  v = v - ((v shr 1'u64) and 0x5555555555555555'u64)
  v = (v and 0x3333333333333333'u64) + ((v shr 2'u64) and 0x3333333333333333'u64)
  v = (v + (v shr 4'u64) and 0x0F0F0F0F0F0F0F0F'u64)
  ((v * 0x0101010101010101'u64) shr 56'u64).int

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
  func builtin_popcnt16(a2: uint16): uint16 {.
      importc: "__popcnt16", header: "<intrin.h>".}
  func builtin_popcnt32(a2: uint32): uint32 {.
      importc: "__popcnt", header: "<intrin.h>".}
  func builtin_popcnt64(a2: uint64): uint64 {.
      importc: "__popcnt64", header: "<intrin.h>".}

  # Search the mask data from most significant bit (MSB) to least significant bit (LSB) for a set bit (1).
  func bitScanReverse(index: ptr culong, mask: culong): cuchar {.
      importc: "_BitScanReverse", header: "<intrin.h>".}
  func bitScanReverse64(index: ptr culong, mask: uint64): cuchar {.
      importc: "_BitScanReverse64", header: "<intrin.h>".}

  # Search the mask data from least significant bit (LSB) to the most significant bit (MSB) for a set bit (1).
  func bitScanForward(index: ptr culong, mask: culong): cuchar {.
      importc: "_BitScanForward", header: "<intrin.h>".}
  func bitScanForward64(index: ptr culong, mask: uint64): cuchar {.
      importc: "_BitScanForward64", header: "<intrin.h>".}

  template vcc_scan_impl(fnc: untyped; v: untyped): int =
    var index: culong
    discard fnc(index.addr, v)
    index.int

elif useICC_builtins:

  # Intel compiler intrinsics: http://fulla.fnal.gov/intel/compiler_c/main_cls/intref_cls/common/intref_allia_misc.htm
  # see also: https://software.intel.com/en-us/node/523362
  # Count the number of bits set to 1 in an integer a, and return that count in dst.
  func builtin_popcnt32(a: cint): cint {.
      importc: "_popcnt", header: "<immintrin.h>".}
  func builtin_popcnt64(a: uint64): cint {.
      importc: "_popcnt64", header: "<immintrin.h>".}

  # Returns the number of trailing 0-bits in x, starting at the least significant bit position. If x is 0, the result is undefined.
  func bitScanForward(p: ptr uint32, b: uint32): cuchar {.
      importc: "_BitScanForward", header: "<immintrin.h>".}
  func bitScanForward64(p: ptr uint32, b: uint64): cuchar {.
      importc: "_BitScanForward64", header: "<immintrin.h>".}

  # Returns the number of leading 0-bits in x, starting at the most significant bit position. If x is 0, the result is undefined.
  func bitScanReverse(p: ptr uint32, b: uint32): cuchar {.
      importc: "_BitScanReverse", header: "<immintrin.h>".}
  func bitScanReverse64(p: ptr uint32, b: uint64): cuchar {.
      importc: "_BitScanReverse64", header: "<immintrin.h>".}

  template icc_scan_impl(fnc: untyped; v: untyped): int =
    var index: uint32
    discard fnc(index.addr, v)
    index.int

func countSetBitsImpl(x: SomeInteger): int {.inline.} =
  ## Counts the set bits in an integer (also called `Hamming weight`:idx:).
  runnableExamples:
    doAssert countSetBits(0b0000_0011'u8) == 2
    doAssert countSetBits(0b1010_1010'u8) == 4

  # TODO: figure out if ICC support _popcnt32/_popcnt64 on platform without POPCNT.
  # like GCC and MSVC
  when x is SomeSignedInt:
    let x = x.toUnsigned
  when nimvm:
    result = forwardImpl(countBitsImpl, x)
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
      when sizeof(x) <= 4: result = countBitsImpl(x.uint32)
      else: result = countBitsImpl(x.uint64)

proc countBits32(n: uint32): int {.compilerproc.} =
  result = countSetBitsImpl(n)

proc countBits64(n: uint64): int {.compilerproc.} =
  result = countSetBitsImpl(n)

proc cardSet(s: NimSet, len: int): int {.compilerproc, inline.} =
  var i = 0
  result = 0
  when defined(x86) or defined(amd64):
    while i < len - 8:
      inc(result, countBits64((cast[ptr uint64](s[i].unsafeAddr))[]))
      inc(i, 8)

  while i < len:
    inc(result, countBits32(uint32(s[i])))
    inc(i, 1)
