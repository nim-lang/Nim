#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains helpers that deal with different byte orders
## (`endian`:idx:).
##
## Unstable API.

when defined(gcc) or defined(llvm_gcc) or defined(clang):
  const useBuiltinSwap = true
  proc builtin_bswap16(a: uint16): uint16 {.
      importc: "__builtin_bswap16", nodecl, noSideEffect.}

  proc builtin_bswap32(a: uint32): uint32 {.
      importc: "__builtin_bswap32", nodecl, noSideEffect.}

  proc builtin_bswap64(a: uint64): uint64 {.
      importc: "__builtin_bswap64", nodecl, noSideEffect.}
elif defined(icc):
  const useBuiltinSwap = true
  proc builtin_bswap16(a: uint16): uint16 {.
      importc: "_bswap16", nodecl, noSideEffect.}

  proc builtin_bswap32(a: uint32): uint32 {.
      importc: "_bswap", nodecl, noSideEffect.}

  proc builtin_bswap64(a: uint64): uint64 {.
      importc: "_bswap64", nodecl, noSideEffect.}
elif defined(vcc):
  const useBuiltinSwap = true
  proc builtin_bswap16(a: uint16): uint16 {.
      importc: "_byteswap_ushort", nodecl, header: "<intrin.h>", noSideEffect.}

  proc builtin_bswap32(a: uint32): uint32 {.
      importc: "_byteswap_ulong", nodecl, header: "<intrin.h>", noSideEffect.}

  proc builtin_bswap64(a: uint64): uint64 {.
      importc: "_byteswap_uint64", nodecl, header: "<intrin.h>", noSideEffect.}
else:
  const useBuiltinSwap = false

when useBuiltinSwap:
  template swapOpImpl(T: typedesc, op: untyped) =
    ## We have to use `copyMem` here instead of a simple deference because they
    ## may point to a unaligned address. A sufficiently smart compiler _should_
    ## be able to elide them when they're not necessary.
    var tmp: T
    copyMem(addr tmp, inp, sizeof(T))
    tmp = op(tmp)
    copyMem(outp, addr tmp, sizeof(T))

  proc swapEndian64*(outp, inp: pointer) {.inline, noSideEffect.} =
    swapOpImpl(uint64, builtin_bswap64)

  proc swapEndian32*(outp, inp: pointer) {.inline, noSideEffect.} =
    swapOpImpl(uint32, builtin_bswap32)

  proc swapEndian16*(outp, inp: pointer) {.inline, noSideEffect.} =
    swapOpImpl(uint16, builtin_bswap16)

else:
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
    var i = cast[cstring](inp)
    var o = cast[cstring](outp)
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
