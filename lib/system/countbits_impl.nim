#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Contains the used algorithms for counting bits.

proc countBits32*(n: uint32): int {.compilerproc.} =
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = uint32(n)
  v = v - ((v shr 1'u32) and 0x55555555'u32)
  v = (v and 0x33333333'u32) + ((v shr 2'u32) and 0x33333333'u32)
  result = (((v + (v shr 4'u32) and 0xF0F0F0F'u32) * 0x1010101'u32) shr 24'u32).int

proc countBits64*(n: uint64): int {.compilerproc, inline.} =
  # generic formula is from: https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
  var v = uint64(n)
  v = v - ((v shr 1'u64) and 0x5555555555555555'u64)
  v = (v and 0x3333333333333333'u64) + ((v shr 2'u64) and 0x3333333333333333'u64)
  v = (v + (v shr 4'u64) and 0x0F0F0F0F0F0F0F0F'u64)
  result = ((v * 0x0101010101010101'u64) shr 56'u64).int
