#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains helpers that deal with different byte orders
## (`endian`:idx:).

proc swapEndian64*(outp, inp: pointer) =
  ## copies `inp` to `outp` swapping bytes. Both buffers are supposed to
  ## contain at least 8 bytes.
  var i = cast[cstring](inp)
  var o = cast[cstring](outp)
  o[0] = i[7]
  o[1] = i[6]
  o[2] = i[5]
  o[3] = i[4]
  o[4] = i[3]
  o[5] = i[2]
  o[6] = i[1]
  o[7] = i[0]

proc swapEndian32*(outp, inp: pointer) = 
  ## copies `inp` to `outp` swapping bytes. Both buffers are supposed to
  ## contain at least 4 bytes.
  var i = cast[cstring](inp)
  var o = cast[cstring](outp)
  o[0] = i[3]
  o[1] = i[2]
  o[2] = i[1]
  o[3] = i[0]

proc swapEndian16*(outp, inp: pointer) = 
  ## copies `inp` to `outp` swapping bytes. Both buffers are supposed to
  ## contain at least 2 bytes.
  var
    i = cast[cstring](inp)
    o = cast[cstring](outp)
  o[0] = i[1]
  o[1] = i[0]

when system.cpuEndian == bigEndian:
  proc littleEndian64*(outp, inp: pointer) {.inline.} = swapEndian64(outp, inp)
  proc littleEndian32*(outp, inp: pointer) {.inline.} = swapEndian32(outp, inp)
  proc littleEndian16*(outp, inp: pointer) {.inline.} = swapEndian16(outp, inp)
  proc bigEndian64*(outp, inp: pointer) {.inline.} = copyMem(outp, inp, 8)
  proc bigEndian32*(outp, inp: pointer) {.inline.} = copyMem(outp, inp, 4)
  proc bigEndian16*(outp, inp: pointer) {.inline.} = copyMem(outp, inp, 2)
else: 
  proc littleEndian64*(outp, inp: pointer) {.inline.} = copyMem(outp, inp, 8)
  proc littleEndian32*(outp, inp: pointer) {.inline.} = copyMem(outp, inp, 4)
  proc littleEndian16*(outp, inp: pointer){.inline.} = copyMem(outp, inp, 2)
  proc bigEndian64*(outp, inp: pointer) {.inline.} = swapEndian64(outp, inp)
  proc bigEndian32*(outp, inp: pointer) {.inline.} = swapEndian32(outp, inp)
  proc bigEndian16*(outp, inp: pointer) {.inline.} = swapEndian16(outp, inp)
