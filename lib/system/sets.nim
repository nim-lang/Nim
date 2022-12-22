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
  NimSet16 = array[0..16-1, uint8]
  NimSet32 = array[0..32-1, uint8]
  NimSet64 = array[0..64-1, uint8]
  NimSet128 = array[0..128-1, uint8]
  NimSet256 = array[0..256-1, uint8]
  NimSet512 = array[0..512-1, uint8]
  NimSet1024 = array[0..1024-1, uint8]
  NimSet2048 = array[0..2048-1, uint8]
  NimSet4096 = array[0..4096-1, uint8]
  NimSet8192 = array[0..8192-1, uint8]
  NimSet = NimSet16 | NimSet32 | NimSet64 | NimSet128 | NimSet256 |
    NimSet512 | NimSet1024 | NimSet2048 | NimSet4096 | NimSet8192

proc cardSetImpl(s: NimSet, len: int): int {.inline.} =
  var i = 0
  result = 0
  when defined(x86) or defined(amd64):
    while i < len - 8:
      inc(result, countBits64((cast[ptr uint64](s[i].unsafeAddr))[]))
      inc(i, 8)

  while i < len:
    inc(result, countBits32(uint32(s[i])))
    inc(i, 1)

template cardSetDef(t) = 
  proc `cardSet t`(s: t, len: int): int {.inject, inline.} =
    result = cardSetImpl(s, len)

cardSetDef(NimSet16)
cardSetDef(NimSet32)
cardSetDef(NimSet64)
cardSetDef(NimSet128)
cardSetDef(NimSet256)
cardSetDef(NimSet512)
cardSetDef(NimSet1024)
cardSetDef(NimSet2048)
cardSetDef(NimSet4096)
cardSetDef(NimSet8192)

proc cardSet(s: NimSet8192, len: int): int {.compilerproc, inline.} =
  case len
  of 16:
    result = cardSetNimSet16(cast[ptr NimSet16](s.addr)[], len)
  of 32:
    result = cardSetNimSet32(cast[ptr NimSet32](s.addr)[], len)
  of 64:
    result = cardSetNimSet64(cast[ptr NimSet64](s.addr)[], len)
  of 128:
    result = cardSetNimSet128(cast[ptr NimSet128](s.addr)[], len)
  of 256:
    result = cardSetNimSet256(cast[ptr NimSet256](s.addr)[], len)
  of 512:
    result = cardSetNimSet512(cast[ptr NimSet512](s.addr)[], len)
  of 1024:
    result = cardSetNimSet1024(cast[ptr NimSet1024](s.addr)[], len)
  of 2048:
    result = cardSetNimSet2048(cast[ptr NimSet2048](s.addr)[], len)
  of 4096:
    result = cardSetNimSet4096(cast[ptr NimSet4096](s.addr)[], len)
  of 8192:
    result = cardSetNimSet8192(cast[ptr NimSet8192](s.addr)[], len)
  else:
    discard
