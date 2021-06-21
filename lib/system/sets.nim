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
