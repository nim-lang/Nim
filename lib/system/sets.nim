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
  NimSet8 = array[0..32-1, uint8]
  NimSet16 = array[0..8192-1, uint8]


proc cardSetImpl(s: NimSet8 | NimSet16, len: int): int {.inline.} =
  var i = 0
  result = 0
  when defined(x86) or defined(amd64):
    while i < len - 8:
      inc(result, countBits64((cast[ptr uint64](s[i].unsafeAddr))[]))
      inc(i, 8)

  while i < len:
    inc(result, countBits32(uint32(s[i])))
    inc(i, 1)

proc cardSet(s: NimSet8, len: int): int {.compilerproc, inline.} =
  result = cardSetImpl(s, len)

proc cardSet(s: NimSet16, len: int): int {.compilerproc, inline.} =
  result = cardSetImpl(s, len)
