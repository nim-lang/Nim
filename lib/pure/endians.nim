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
when not defined(js):
  when defined(gcc) or defined(llvm_gcc) or defined(clang):
    const useBuiltinSwap = true
    func builtin_bswap16(a: uint16): uint16 {.
        importc: "__builtin_bswap16", nodecl.}

    func builtin_bswap32(a: uint32): uint32 {.
        importc: "__builtin_bswap32", nodecl.}

    func builtin_bswap64(a: uint64): uint64 {.
        importc: "__builtin_bswap64", nodecl.}
  elif defined(icc):
    const useBuiltinSwap = true
    func builtin_bswap16(a: uint16): uint16 {.
        importc: "_bswap16", nodecl.}

    func builtin_bswap32(a: uint32): uint32 {.
        importc: "_bswap", nodecl.}

    func builtin_bswap64(a: uint64): uint64 {.
        importc: "_bswap64", nodecl.}
  elif defined(vcc):
    const useBuiltinSwap = true
    func builtin_bswap16(a: uint16): uint16 {.
        importc: "_byteswap_ushort", nodecl, header: "<intrin.h>".}

    func builtin_bswap32(a: uint32): uint32 {.
        importc: "_byteswap_ulong", nodecl, header: "<intrin.h>".}

    func builtin_bswap64(a: uint64): uint64 {.
        importc: "_byteswap_uint64", nodecl, header: "<intrin.h>".}
else:
  const useBuiltinSwap = false
  func builtin_bswap16(a: uint16): uint16 {.inline.} =
    result = (a shl 8) or (a shr 8)

  func builtin_bswap32(a: uint32): uint32 {.inline.} =
    result = ((a shl 24) and 0xff000000'u32) or
             ((a shl 8) and 0x00ff0000'u32) or
             ((a shr 8) and 0x0000ff00'u32) or
             ((a shr 24) and 0x000000ff'u32)

  func builtin_bswap64(a: uint64): uint64 {.inline.} =
    var a = (a shl 32) or (a shr 32)
    a = ((a and 0x0000ffff0000ffff'u64) shl 16) or
        ((a and 0xffff0000ffff0000'u64) shr 16)

    result = ((a and 0x00ff00ff00ff00ff'u64) shl 8) or
             ((a and 0xff00ff00ff00ff00'u64) shr 8)

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
elif defined(js):
  func swapEndian64*(outp, inp: pointer) {.inline.} =
    cast[ptr uint64](outp)[] = builtin_bswap64(cast[uint64](inp))

  func swapEndian32*(outp, inp: pointer) {.inline.} =
    cast[ptr uint32](outp)[] = builtin_bswap32(cast[uint32](inp))

  func swapEndian16*(outp, inp: pointer) {.inline.} =
    cast[ptr uint16](outp)[] = builtin_bswap16(cast[uint16](inp))
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

when useBuiltinSwap:
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
elif defined(js):
  ## JS backend is always bigEndian
  ## TODO nodejs backend is wrong
  when system.cpuEndian == bigEndian:
    proc littleEndian64*(outp, inp: pointer) {.inline.} = swapEndian64(outp, inp)
    proc littleEndian32*(outp, inp: pointer) {.inline.} = swapEndian32(outp, inp)
    proc littleEndian16*(outp, inp: pointer) {.inline.} = swapEndian16(outp, inp)
    proc bigEndian64*(outp, inp: pointer) {.inline.} = cast[ptr uint64](outp)[] = cast[ptr uint64](inp)[]
    proc bigEndian32*(outp, inp: pointer) {.inline.} = cast[ptr uint32](outp)[] = cast[ptr uint32](inp)[]
    proc bigEndian16*(outp, inp: pointer) {.inline.} = cast[ptr uint16](outp)[] = cast[ptr uint16](inp)[]
  else:
    proc littleEndian64*(outp, inp: pointer) {.inline.} =  cast[ptr uint64](outp)[] = cast[ptr uint64](inp)[]
    proc littleEndian32*(outp, inp: pointer) {.inline.} = cast[ptr uint32](outp)[] = cast[ptr uint32](inp)[]
    proc littleEndian16*(outp, inp: pointer) {.inline.} = cast[ptr uint16](outp)[] = cast[ptr uint16](inp)[]
    proc bigEndian64*(outp, inp: pointer) {.inline.} = swapEndian64(outp, inp)
    proc bigEndian32*(outp, inp: pointer) {.inline.} = swapEndian32(outp, inp)
    proc bigEndian16*(outp, inp: pointer) {.inline.} = swapEndian16(outp, inp)
