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

import bitops

proc countBits32(n: int32): int {.compilerproc.} =
  countSetBits(n)

proc countBits64(n: int64): int {.compilerproc.} =
  countSetBits(n)

proc cardSet(s: NimSet, len: int): int {.compilerproc, inline.} =
  for i in 0..<len:
    if likely(s[i] == 0): continue
    inc(result, countBits32(int32(s[i])))
