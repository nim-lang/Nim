#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# set handling

type
  NimSet = array[0..4*2048-1, uint8]

proc countBits32(n: uint32): int {.compilerproc.} =
  var v = n
  v = v - ((v shr 1'u32) and 0x55555555'u32)
  v = (v and 0x33333333'u32) + ((v shr 2'u32) and 0x33333333'u32)
  result = int(((v + (v shr 4'u32) and 0xF0F0F0F'u32) * 0x1010101'u32) shr 24'u32)

proc countBits64(n: uint64): int {.compilerproc.} =
  result = countBits32(uint32(n and 0xffffffff'u64)) +
           countBits32(uint32(n shr 32))

proc cardSet(s: NimSet, len: int): int {.compilerproc, inline.} =
  for i in 0..<len:
    if likely(s[i] == 0): continue
    inc(result, countBits32(s[i]))
