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

proc countBits32(n: int32): int {.compilerproc.} =
  var v = n
  v = v -% ((v shr 1'i32) and 0x55555555'i32)
  v = (v and 0x33333333'i32) +% ((v shr 2'i32) and 0x33333333'i32)
  result = ((v +% (v shr 4'i32) and 0xF0F0F0F'i32) *% 0x1010101'i32) shr 24'i32

proc countBits64(n: int64): int {.compilerproc.} =
  result = countBits32(toU32(n and 0xffffffff'i64)) +
           countBits32(toU32(n shr 32'i64))

proc cardSet(s: NimSet, len: int): int {.compilerproc, inline.} =
  for i in 0..<len:
    if likely(s[i] == 0): continue
    inc(result, countBits32(int32(s[i])))
