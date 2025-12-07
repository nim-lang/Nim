#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# set handling


# IC: compilerprocs now must be defined in system.nim or threadpool.nim!
proc countBits32*(n: uint32): int {.compilerproc, inline.} =
  result = countSetBitsImpl(n)

proc countBits64*(n: uint64): int {.compilerproc, inline.} =
  result = countSetBitsImpl(n)

proc cardSetImpl(s: ptr UncheckedArray[uint8], len: int): int {.inline.} =
  var i = 0
  result = 0
  var num = 0'u64
  when defined(x86) or defined(amd64):
    while i < len - 8:
      copyMem(addr num, addr s[i], 8)
      inc(result, countBits64(num))
      inc(i, 8)

  while i < len:
    inc(result, countBits32(uint32(s[i])))
    inc(i, 1)

proc cardSet(s: ptr UncheckedArray[uint8], len: int): int {.compilerproc, inline.} =
  result = cardSetImpl(s, len)
