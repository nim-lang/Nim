#                Nim's Runtime Library
#    (c) Copyright 2012 Andreas Rumpf, 2020 John Novak
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains functions to deal with numbers in different byte
## orders.
##
## By default, the module uses compiler intrinsics where possible to improve
## performance on supported compilers: ``GCC``, ``LLVM_GCC``, ``CLANG``,
## ``VCC`` and ``ICC``.
##
## It will fall back to pure nim procs in case the backend is not supported.
## You can also use the flag `noIntrinsicsEndians` to disable compiler
## intrinsics.
##
## Most of the API is compatible with NimVM, except the procs that take
## `pointer` arguments.
##

include "system/inclrtl"

when defined(noIntrinsicsEndians):
  const useBuiltinSwap = false

elif defined(gcc) or defined(llvm_gcc) or defined(clang):
  const useBuiltinSwap = true

  func builtinSwap16(a: uint16): uint16 {.
      importc: "__builtin_bswap16", nodecl.}

  func builtinSwap32(a: uint32): uint32 {.
      importc: "__builtin_bswap32", nodecl.}

  func builtinSwap64(a: uint64): uint64 {.
      importc: "__builtin_bswap64", nodecl.}

elif defined(icc):
  const useBuiltinSwap = true
  func builtinSwap16(a: uint16): uint16 {.
      importc: "_bswap16", nodecl.}

  func builtinSwap32(a: uint32): uint32 {.
      importc: "_bswap", nodecl.}

  func builtinSwap64(a: uint64): uint64 {.
      importc: "_bswap64", nodecl.}

elif defined(vcc):
  const useBuiltinSwap = true
  func builtinSwap16(a: uint16): uint16 {.
      importc: "_byteswap_ushort", nodecl, header: "<intrin.h>".}

  func builtinSwap32(a: uint32): uint32 {.
      importc: "_byteswap_ulong", nodecl, header: "<intrin.h>".}

  func builtinSwap64(a: uint64): uint64 {.
      importc: "_byteswap_uint64", nodecl, header: "<intrin.h>".}

else:
  const useBuiltinSwap = false


# Deprecated API

when useBuiltinSwap:
  template swapOpImpl(T: typedesc, op: untyped) =
    ## We have to use `copyMem` here instead of a simple deference because they
    ## may point to a unaligned address. A sufficiently smart compiler _should_
    ## be able to elide them when they're not necessary.
    var tmp: T
    copyMem(addr tmp, inp, sizeof(T))
    tmp = op(tmp)
    copyMem(outp, addr tmp, sizeof(T))

  proc swapEndian64*(outp, inp: pointer) {.inline, noSideEffect, deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
    swapOpImpl(uint64, builtinSwap64)

  proc swapEndian32*(outp, inp: pointer) {.inline, noSideEffect, deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
    swapOpImpl(uint32, builtinSwap32)

  proc swapEndian16*(outp, inp: pointer) {.inline, noSideEffect, deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
    swapOpImpl(uint16, builtinSwap16)

else:
  proc swapEndian64*(outp, inp: pointer) {.deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
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

  proc swapEndian32*(outp, inp: pointer) {.deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
    ## copies `inp` to `outp` swapping bytes. Both buffers are supposed to
    ## contain at least 4 bytes.
    var i = cast[cstring](inp)
    var o = cast[cstring](outp)
    o[0] = i[3]
    o[1] = i[2]
    o[2] = i[1]
    o[3] = i[0]

  proc swapEndian16*(outp, inp: pointer) {.deprecated:
      "Deprecated since v1.1.0; use `swapEndian` instead".} =
    ## copies `inp` to `outp` swapping bytes. Both buffers are supposed to
    ## contain at least 2 bytes.
    var i = cast[cstring](inp)
    var o = cast[cstring](outp)
    o[0] = i[1]
    o[1] = i[0]

when system.cpuEndian == bigEndian:
  proc littleEndian64*(outp, inp: pointer){.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian64(outp, inp)

  proc littleEndian32*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian32(outp, inp)

  proc littleEndian16*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian16(outp, inp)

  proc bigEndian64*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 8)

  proc bigEndian32*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 4)

  proc bigEndian16*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 2)
else:
  proc littleEndian64*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 8)

  proc littleEndian32*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 4)

  proc littleEndian16*(outp, inp: pointer){.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    copyMem(outp, inp, 2)

  proc bigEndian64*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian64(outp, inp)

  proc bigEndian32*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian32(outp, inp)

  proc bigEndian16*(outp, inp: pointer) {.inline, deprecated:
      "Deprecated since v1.1.0; use `fromBytesXX/toBytesXX` instead".} =
    swapEndian16(outp, inp)


# New API starts here

func slowSwap16(a: uint16): uint16 {.inline.} =
  result = (a shl 8) or (a shr 8)

func slowSwap32(a: uint32): uint32 {.inline.} =
  var a = ((a shl  8) and 0xff00ff00'u32) or
          ((a shr  8) and 0x00ff00ff'u32)
  result = (a shl 16) or (a shr 16)

func slowSwap64(a: uint64): uint64 {.inline.} =
  var a = ((a shl 8) and 0xff00ff00ff00ff00'u64) or
          ((a shr 8) and 0x00ff00ff00ff00ff'u64)
  a = ((a shl 16) and 0xffff0000ffff0000'u64) or
      ((a shr 16) and 0x0000ffff0000ffff'u64)
  result = (a shl 32) or (a shr 32)

when useBuiltinSwap:
  template swap16(a: uint16): uint16 = builtinSwap16(a)
  template swap32(a: uint32): uint32 = builtinSwap32(a)
  template swap64(a: uint64): uint64 = builtinSwap64(a)
else:
  template swap16(a: uint16): uint16 = slowSwap16(a)
  template swap32(a: uint32): uint32 = slowSwap32(a)
  template swap64(a: uint64): uint64 = slowSwap64(a)


# TODO had to remove {.since: (1,1).} because it broke `koch runCI`
func swapEndian*[T: SomeNumber](value: T): T {.inline.} =
  ## Swaps the byte order of a number.
  runnableExamples:
    doAssert swapEndian(0xdeadbeef'i32) == 0xefbeadde'i32
    doAssert swapEndian(0xcafe'u16) == 0xfeca'u16
    doAssert swapEndian(0x42'u8) == 0x42'u8

  when sizeof(T) == 1:
    value
  elif sizeof(T) == 2:
    when nimvm: cast[T](slowSwap16(cast[uint16](value)))
    else:       cast[T](    swap16(cast[uint16](value)))
  elif sizeof(T) == 4:
    when nimvm: cast[T](slowSwap32(cast[uint32](value)))
    else:       cast[T](    swap32(cast[uint32](value)))
  elif sizeof(T) == 8:
    when nimvm: cast[T](slowSwap64(cast[uint64](value)))
    else:       cast[T](    swap64(cast[uint64](value)))


func swapEndian*(T: typedesc[SomeNumber],
                 buf: pointer) {.inline, since: (1,1).} =
  ## Swaps the byte order of a number at a memory location in-place. The type
  ## of the number must be passed in as an argument.
  runnableExamples:
    var i = 0xdeadbeef'i32
    swapEndian(int32, i.addr)
    doAssert i == 0xefbeadde'i32

  var value = cast[ptr T](buf)[]
  cast[ptr T](buf)[] = swapEndian(value)


func swapEndian*(T: typedesc[SomeNumber], buf: var openArray[byte],
                 startIndex: Natural) {.inline, since: (1,1).} =
  ## Swaps the byte order of a number stored as a byte sequence in `buf`
  ## starting at `startIndex`. The type of the number must be passed in as an
  ## argument.
  runnableExamples:
    var buf: array[6, byte]
    buf[0] = 0xff
    buf[1] = 0xca
    buf[2] = 0xfe
    buf[3] = 0x42
    swapEndian(uint16, buf, 1)
    doAssert buf[0] == 0xff
    doAssert buf[1] == 0xfe
    doAssert buf[2] == 0xca
    doAssert buf[3] == 0x42

  let i = startIndex
  when nimvm:
    when sizeof(T) == 1:
      discard

    elif sizeof(T) == 2:
      swap(buf[i],   buf[i+1])

    elif sizeof(T) == 4:
      swap(buf[i],   buf[i+3])
      swap(buf[i+1], buf[i+2])

    elif sizeof(T) == 8:
      swap(buf[i],   buf[i+7])
      swap(buf[i+1], buf[i+6])
      swap(buf[i+2], buf[i+5])
      swap(buf[i+3], buf[i+4])
  else:
    assert i < buf.len
    assert i + sizeof(T) <= buf.len
    swapEndian(T, buf[startIndex].addr)


func toBE*[T: SomeNumber](value: T): T {.inline, since: (1,1).} =
  ## Converts a number so when it's written to a file or a stream as a byte
  ## sequence using endianness unaware I/O, the resulting byte sequence will
  ## be in big-endian byte order.
  ##
  ## Consider using `toBytesBE` instead to make the intent clearer.
  when system.cpuEndian == bigEndian: value
  else: swapEndian(value)

func toLE*[T: SomeNumber](value: T): T {.inline, since: (1,1).} =
  ## Converts a number so when it's written to a file or a stream as a byte
  ## sequence using endianness unaware I/O, the resulting byte sequence will
  ## be in little-endian byte order.
  ##
  ## Consider using `toBytesLE` instead to make the intent clearer.
  when system.cpuEndian == littleEndian: value
  else: swapEndian(value)

func fromBE*[T: SomeNumber](value: T): T {.inline, since: (1,1).} =
  ## Converts a big-endian number read from a file or a stream using
  ## endianness unaware I/O to native byte order, so it can be used for
  ## arithmetic calculations in a program. This is equivalent to `toBE`,
  ## it's only included for readability.
  ##
  ## Consider using `fromBytesBE` instead to make the intent clearer.
  toBE(value)

func fromLE*[T: SomeNumber](value: T): T {.inline, since: (1,1).} =
  ## Converts a little-endian number read from a file or a stream using
  ## endiannes unaware I/O to native byte order, so it can be used for
  ## arithmetic calculations in a program. This is equivalent to `toLE`,
  ## it's only included for readability.
  ##
  ## Consider using `fromBytesLE` instead to make the intent clearer.
  toLE(value)

func toBytesBE*[T: SomeNumber](value: T, buf: pointer)
    {.inline, since: (1,1).} =
  ## Writes a number to a memory location as a big-endian byte sequence.
  runnableExamples:
    var buf: array[6, byte]
    toBytesBE(0xdead'i16, buf[2].addr)
    doAssert buf[2] == 0xde
    doAssert buf[3] == 0xad

  when system.cpuEndian == bigEndian: cast[ptr T](buf)[] = value
  else: cast[ptr T](buf)[] = swapEndian(value)


func slowToBytes[T: SomeNumber](destEndian: Endianness,
                                value: T, buf: var openArray[byte],
                                startIndex: Natural) =
  template toBytes(S: typedesc[SomeInteger]) =
    let a = if destEndian == littleEndian: cast[S](value)
            else: cast[S](swapEndian(value))
    for i in 0..<sizeof(T):
      buf[startIndex + i] = byte((a shr (i * 8)) and 0xff)

  when sizeof(T) == 1: toBytes(uint8)
  elif sizeof(T) == 2: toBytes(uint16)
  elif sizeof(T) == 4: toBytes(uint32)
  elif sizeof(T) == 8: toBytes(uint64)


func toBytesBE*[T: SomeNumber](value: T, buf: var openArray[byte],
                               startIndex: Natural)
    {.inline, since: (1,1).} =
  ## Writes a number to `buf` starting at index `startIndex` as a big-endian
  ## byte sequence.
  runnableExamples:
    var buf: array[6, byte]
    toBytesBE(0xdead'i16, buf, 2)
    doAssert buf[2] == 0xde
    doAssert buf[3] == 0xad

  when nimvm: slowToBytes(bigEndian, value, buf, startIndex)
  else:
    assert startIndex < buf.len
    assert startIndex + sizeof(T) <= buf.len
    toBytesBE(value, buf[startIndex].addr)


func toBytesLE*[T: SomeNumber](value: T,
                               buf: pointer) {.inline, since: (1,1).} =
  ## Writes a number to a memory location as a little-endian byte sequence.
  runnableExamples:
    var buf: array[6, byte]
    toBytesLE(0xdead'i16, buf[2].addr)
    doAssert buf[2] == 0xad
    doAssert buf[3] == 0xde

  when system.cpuEndian == littleEndian: cast[ptr T](buf)[] = value
  else: cast[ptr T](buf)[] = swapEndian(value)

func toBytesLE*[T: SomeNumber](value: T, buf: var openArray[byte],
                               startIndex: Natural)
    {.inline, since: (1,1).} =
  ## Writes a number to `buf` at index `startIndex` as a little-endian byte
  ## sequence.
  runnableExamples:
    var buf: array[6, byte]
    toBytesLE(0xdead'i16, buf, 2)
    doAssert buf[2] == 0xad
    doAssert buf[3] == 0xde

  when nimvm: slowToBytes(littleEndian, value, buf, startIndex)
  else:
    assert startIndex < buf.len
    assert startIndex + sizeof(T) <= buf.len
    toBytesLE(value, buf[startIndex].addr)


func fromBytesBE*(T: typedesc[SomeNumber],
                  buf: pointer): T {.inline, since: (1,1).} =
  ## Reads a number represented as a big-endian byte sequence from a memory
  ## location. The type of the number must be passed in as an argument.
  runnableExamples:
    var buf: array[4, byte]
    buf[0] = 0xde
    buf[1] = 0xad
    buf[2] = 0xbe
    buf[3] = 0xef
    doAssert fromBytesBE(int32, buf[0].addr) == 0xdeadbeef'i32

  let a = cast[ptr T](buf)[]
  when system.cpuEndian == bigEndian: a
  else: swapEndian(a)


func slowFromBytes(T: typedesc[SomeNumber], srcEndian: Endianness,
                   buf: openArray[byte], startIndex: Natural): T =
  template fromBytes(S: typedesc[SomeInteger]): T =
    var a = S(0)
    for i in 0..<sizeof(T):
      let s = if srcEndian == bigEndian: (sizeof(T) - i - 1) * 8
              else: i * 8
      a = a or (S(buf[startIndex + i]) shl s)
    cast[T](a)

  when sizeof(T) == 1: result = fromBytes(uint8)
  elif sizeof(T) == 2: result = fromBytes(uint16)
  elif sizeof(T) == 4: result = fromBytes(uint32)
  elif sizeof(T) == 8: result = fromBytes(uint64)


func fromBytesBE*(T: typedesc[SomeNumber], buf: openArray[byte],
                  startIndex: Natural): T {.inline, since: (1,1).} =
  ## Reads a number represented as a big-endian byte sequence from `buf`
  ## starting at `startIndex`. The type of the number must be passed in as an
  ## argument.
  runnableExamples:
    var buf: array[6, byte]
    buf[1] = 0xde
    buf[2] = 0xad
    buf[3] = 0xbe
    buf[4] = 0xef
    doAssert fromBytesBE(int32, buf, 1) == 0xdeadbeef'i32

  when nimvm: slowFromBytes(T, bigEndian, buf, startIndex)
  else:
    assert startIndex < buf.len
    assert startIndex + sizeof(T) <= buf.len
    fromBytesBE(T, buf[startIndex].unsafeAddr)

func fromBytesLE*(T: typedesc[SomeNumber],
                  buf: pointer): T {.inline, since: (1,1).} =
  ## Reads a number represented as a little-endian byte sequence from a memory
  ## buffer. The type of the number must be passed in as an argument.
  runnableExamples:
    var buf: array[6, uint8]
    buf[1] = 0xef
    buf[2] = 0xbe
    buf[3] = 0xad
    buf[4] = 0xde
    doAssert fromBytesLE(int32, buf[1].addr) == 0xdeadbeef'i32

  let a = cast[ptr T](buf)[]
  when system.cpuEndian == littleEndian: a
  else: swapEndian(a)


func fromBytesLE*(T: typedesc[SomeNumber], buf: openArray[byte],
                  startIndex: Natural): T {.inline, since: (1,1).} =
  ## Reads a number represented as a little-endian byte sequence from `buf`
  ## starting at `startIndex`. The type of the number must be passed in as an
  ## argument.
  runnableExamples:
    var buf: array[6, byte]
    buf[1] = 0xef
    buf[2] = 0xbe
    buf[3] = 0xad
    buf[4] = 0xde
    doAssert fromBytesLE(int32, buf, 1) == 0xdeadbeef'i32

  when nimvm: slowFromBytes(T, littleEndian, buf, startIndex)
  else:
    assert startIndex < buf.len
    assert startIndex + sizeof(T) <= buf.len
    fromBytesLE(T, buf[startIndex].unsafeAddr)


when isMainModule:
  const
    i8 = 0xf2'i8
    u8 = 0xf2'u8
    i16 = 0xf1b2'i16
    u16 = 0xf1b2'u16
    i32 = 0xf4c3b2a1'i32
    u32 = 0xf4c3b2a1'u32
    i64 = 0xf8f7f6e5d4c3b2a1'i64
    u64 = 0xf8f7f6e5d4c3b2a1'u64
    f32 = 0xd4c3b2a1'f32
    f64 = 0xf8f7f6e5d4c3b2a1'f64

    i16_rev = 0xb2f1'i16
    u16_rev = 0xb2f1'u16
    i32_rev = 0xa1b2c3f4'i32
    u32_rev = 0xa1b2c3f4'u32
    i64_rev = 0xa1b2c3d4e5f6f7f8'i64
    u64_rev = 0xa1b2c3d4e5f6f7f8'u64
    f32_rev = 0xa1b2c3d4'f32
    f64_rev = 0xa1b2c3d4e5f6f7f8'f64

  template nimVMTests() =
    assert slowSwap16(u16) == u16_rev
    assert slowSwap32(u32) == u32_rev
    assert slowSwap64(u64) == u64_rev

    assert swapEndian(i8)  == i8
    assert swapEndian(u8)  == u8
    assert swapEndian(i16) == i16_rev
    assert swapEndian(u16) == u16_rev

    assert swapEndian(i32) == i32_rev
    assert swapEndian(u32) == u32_rev
    assert swapEndian(i64) == i64_rev
    assert swapEndian(u64) == u64_rev
    assert swapEndian(f32) == f32_rev
    assert swapEndian(f64) == f64_rev

    var buf: array[11, byte]
    buf[3] = 0xde
    buf[4] = 0xad
    buf[5] = 0xbe
    buf[6] = 0xef
    buf[7] = 0xca
    buf[8] = 0xfe
    buf[9] = 0xba
    buf[10] = 0xbe

    const magicValue64 = 0xdeadbeefcafebabe'u64
    swapEndian(int8, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == magicValue64
    swapEndian(uint8, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == magicValue64

    swapEndian(int16, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == 0xaddebeefcafebabe'u64
    swapEndian(uint16, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == magicValue64

    swapEndian(int32, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == 0xefbeaddecafebabe'u64
    swapEndian(uint32, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == magicValue64

    swapEndian(int64, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == 0xbebafecaefbeadde'u64
    swapEndian(uint64, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == magicValue64

    swapEndian(float32, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == 0xefbeaddecafebabe'u64
    swapEndian(float32, buf, 3)

    swapEndian(float64, buf, 3)
    assert fromBytesBE(uint64, buf, 3) == 0xbebafecaefbeadde'u64
    swapEndian(float64, buf, 3)

    when system.cpuEndian == bigEndian:
      assert toBE( i8) == i8
      assert toBE( u8) == u8
      assert toBE(i16) == i16
      assert toBE(u16) == u16
      assert toBE(i32) == i32
      assert toBE(u32) == u32
      assert toBE(i64) == i64
      assert toBE(u64) == u64
      assert toBE(f32) == f32
      assert toBE(f64) == f64

      assert toLE( i8) == i8
      assert toLE( u8) == u8
      assert toLE(i16) == i16_rev
      assert toLE(u16) == u16_rev
      assert toLE(i32) == i32_rev
      assert toLE(u32) == u32_rev
      assert toLE(i64) == i64_rev
      assert toLE(u64) == u64_rev
      assert toLE(f32) == f32_rev
      assert toLE(f64) == f64_rev

      assert fromBytesBE(   int8, buf, 3) == 0xde'i8
      assert fromBytesBE(  uint8, buf, 3) == 0xde'u8
      assert fromBytesBE(  int16, buf, 3) == 0xdead'i16
      assert fromBytesBE( uint16, buf, 3) == 0xdead'u16
      assert fromBytesBE(  int32, buf, 3) == 0xdeadbeef'i32
      assert fromBytesBE( uint32, buf, 3) == 0xdeadbeef'u32
      assert fromBytesBE(  int64, buf, 3) == 0xdeadbeefcafebabe'i64
      assert fromBytesBE( uint64, buf, 3) == 0xdeadbeefcafebabe'u64
      assert fromBytesBE(float32, buf, 3) == 0xdeadbeef'f32
      assert fromBytesBE(float64, buf, 3) == 0xdeadbeefcafebabe'f64

      swapEndian(int64, buf, 3)

      assert fromBytesLE(   int8, buf, 3) == 0xbe'i8
      assert fromBytesLE(  uint8, buf, 3) == 0xbe'u8
      assert fromBytesLE(  int16, buf, 3) == 0xbabe'i16
      assert fromBytesLE( uint16, buf, 3) == 0xbabe'u16
      assert fromBytesLE(  int32, buf, 3) == 0xcafebabe'i32
      assert fromBytesLE( uint32, buf, 3) == 0xcafebabe'u32
      assert fromBytesLE(  int64, buf, 3) == 0xdeadbeefcafebabe'i64
      assert fromBytesLE( uint64, buf, 3) == 0xdeadbeefcafebabe'u64
      assert fromBytesLE(float32, buf, 3) == 0xcafebabe'f32
      assert fromBytesLE(float64, buf, 3) == 0xdeadbeefcafebabe'f64

      toBytesBE(i8 , buf, 3); assert fromBytesBE(   int8, buf, 3) == i8
      toBytesBE(u8 , buf, 3); assert fromBytesBE(  uint8, buf, 3) == u8
      toBytesBE(i16, buf, 3); assert fromBytesBE(  int16, buf, 3) == i16
      toBytesBE(u16, buf, 3); assert fromBytesBE( uint16, buf, 3) == u16
      toBytesBE(i32, buf, 3); assert fromBytesBE(  int32, buf, 3) == i32
      toBytesBE(u32, buf, 3); assert fromBytesBE( uint32, buf, 3) == u32
      toBytesBE(i64, buf, 3); assert fromBytesBE(  int64, buf, 3) == i64
      toBytesBE(u64, buf, 3); assert fromBytesBE( uint64, buf, 3) == u64
      toBytesBE(f32, buf, 3); assert fromBytesBE(float32, buf, 3) == f32
      toBytesBE(f64, buf, 3); assert fromBytesBE(float64, buf, 3) == f64

      toBytesLE(i8 , buf, 3); assert fromBytesLE(   int8, buf, 3) == i8
      toBytesLE(u8 , buf, 3); assert fromBytesLE(  uint8, buf, 3) == u8
      toBytesLE(i16, buf, 3); assert fromBytesLE(  int16, buf, 3) == i16
      toBytesLE(u16, buf, 3); assert fromBytesLE( uint16, buf, 3) == u16
      toBytesLE(i32, buf, 3); assert fromBytesLE(  int32, buf, 3) == i32
      toBytesLE(u32, buf, 3); assert fromBytesLE( uint32, buf, 3) == u32
      toBytesLE(i64, buf, 3); assert fromBytesLE(  int64, buf, 3) == i64
      toBytesLE(u64, buf, 3); assert fromBytesLE( uint64, buf, 3) == u64
      toBytesLE(f32, buf, 3); assert fromBytesLE(float32, buf, 3) == f32
      toBytesLE(f64, buf, 3); assert fromBytesLE(float64, buf, 3) == f64

    else:  # little-endian
      assert toBE( i8) == i8
      assert toBE( u8) == u8
      assert toBE(i16) == i16_rev
      assert toBE(u16) == u16_rev
      assert toBE(i32) == i32_rev
      assert toBE(u32) == u32_rev
      assert toBE(i64) == i64_rev
      assert toBE(u64) == u64_rev
      assert toBE(f32) == f32_rev
      assert toBE(f64) == f64_rev

      assert toLE( i8) == i8
      assert toLE( u8) == u8
      assert toLE(i16) == i16
      assert toLE(u16) == u16
      assert toLE(i32) == i32
      assert toLE(u32) == u32
      assert toLE(i64) == i64
      assert toLE(u64) == u64
      assert toLE(f32) == f32
      assert toLE(f64) == f64

      assert fromBytesBE(   int8, buf, 3) == 0xde'i8
      assert fromBytesBE(  uint8, buf, 3) == 0xde'u8
      assert fromBytesBE(  int16, buf, 3) == 0xdead'i16
      assert fromBytesBE( uint16, buf, 3) == 0xdead'u16
      assert fromBytesBE(  int32, buf, 3) == 0xdeadbeef'i32
      assert fromBytesBE( uint32, buf, 3) == 0xdeadbeef'u32
      assert fromBytesBE(  int64, buf, 3) == 0xdeadbeefcafebabe'i64
      assert fromBytesBE( uint64, buf, 3) == 0xdeadbeefcafebabe'u64
      assert fromBytesBE(float32, buf, 3) == 0xdeadbeef'f32
      assert fromBytesBE(float64, buf, 3) == 0xdeadbeefcafebabe'f64

      swapEndian(int64, buf, 3)

      assert fromBytesLE(   int8, buf, 3) == 0xbe'i8
      assert fromBytesLE(  uint8, buf, 3) == 0xbe'u8
      assert fromBytesLE(  int16, buf, 3) == 0xbabe'i16
      assert fromBytesLE( uint16, buf, 3) == 0xbabe'u16
      assert fromBytesLE(  int32, buf, 3) == 0xcafebabe'i32
      assert fromBytesLE( uint32, buf, 3) == 0xcafebabe'u32
      assert fromBytesLE(  int64, buf, 3) == 0xdeadbeefcafebabe'i64
      assert fromBytesLE( uint64, buf, 3) == 0xdeadbeefcafebabe'u64
      assert fromBytesLE(float32, buf, 3) == 0xcafebabe'f32
      assert fromBytesLE(float64, buf, 3) == 0xdeadbeefcafebabe'f64

      toBytesBE(i8 , buf, 3); assert fromBytesBE(   int8, buf, 3) == i8
      toBytesBE(u8 , buf, 3); assert fromBytesBE(  uint8, buf, 3) == u8
      toBytesBE(i16, buf, 3); assert fromBytesBE(  int16, buf, 3) == i16
      toBytesBE(u16, buf, 3); assert fromBytesBE( uint16, buf, 3) == u16
      toBytesBE(i32, buf, 3); assert fromBytesBE(  int32, buf, 3) == i32
      toBytesBE(u32, buf, 3); assert fromBytesBE( uint32, buf, 3) == u32
      toBytesBE(i64, buf, 3); assert fromBytesBE(  int64, buf, 3) == i64
      toBytesBE(u64, buf, 3); assert fromBytesBE( uint64, buf, 3) == u64
      toBytesBE(f32, buf, 3); assert fromBytesBE(float32, buf, 3) == f32
      toBytesBE(f64, buf, 3); assert fromBytesBE(float64, buf, 3) == f64

      toBytesLE(i8 , buf, 3); assert fromBytesLE(   int8, buf, 3) == i8
      toBytesLE(u8 , buf, 3); assert fromBytesLE(  uint8, buf, 3) == u8
      toBytesLE(i16, buf, 3); assert fromBytesLE(  int16, buf, 3) == i16
      toBytesLE(u16, buf, 3); assert fromBytesLE( uint16, buf, 3) == u16
      toBytesLE(i32, buf, 3); assert fromBytesLE(  int32, buf, 3) == i32
      toBytesLE(u32, buf, 3); assert fromBytesLE( uint32, buf, 3) == u32
      toBytesLE(i64, buf, 3); assert fromBytesLE(  int64, buf, 3) == i64
      toBytesLE(u64, buf, 3); assert fromBytesLE( uint64, buf, 3) == u64
      toBytesLE(f32, buf, 3); assert fromBytesLE(float32, buf, 3) == f32
      toBytesLE(f64, buf, 3); assert fromBytesLE(float64, buf, 3) == f64

  static:
    nimVmTests()

  # Runtime tests
  nimVmTests()

  var buf: array[11, byte]
  buf[3] = 0xde
  buf[4] = 0xad
  buf[5] = 0xbe
  buf[6] = 0xef
  buf[7] = 0xca
  buf[8] = 0xfe
  buf[9] = 0xba
  buf[10] = 0xbe

  const magicValue64 = 0xdeadbeefcafebabe'u64
  swapEndian(int8, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == magicValue64
  swapEndian(uint8, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == magicValue64

  swapEndian(int16, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == 0xaddebeefcafebabe'u64
  swapEndian(uint16, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == magicValue64

  swapEndian(int32, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == 0xefbeaddecafebabe'u64
  swapEndian(uint32, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == magicValue64

  swapEndian(int64, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == 0xbebafecaefbeadde'u64
  swapEndian(uint64, buf[3].addr)
  assert fromBytesBE(uint64, buf, 3) == magicValue64

  swapEndian(float32, buf, 3)
  assert fromBytesBE(uint64, buf[3].addr) == 0xefbeaddecafebabe'u64
  swapEndian(float32, buf, 3)
  assert fromBytesBE(uint64, buf[3].addr) == magicValue64

  swapEndian(float64, buf, 3)
  assert fromBytesBE(uint64, buf, 3) == 0xbebafecaefbeadde'u64
  swapEndian(float64, buf, 3)
  assert fromBytesBE(uint64, buf[3].addr) == magicValue64

  var
    i8_var = 0xf2'i8
    u8_var = 0xf2'u8
    i16_var = 0xf1b2'i16
    u16_var = 0xf1b2'u16
    i32_var = 0xf4c3b2a1'i32
    u32_var = 0xf4c3b2a1'u32
    i64_var = 0xf8f7f6e5d4c3b2a1'i64
    u64_var = 0xf8f7f6e5d4c3b2a1'u64
    f32_var = 0xd4c3b2a1'f32
    f64_var = 0xf8f7f6e5d4c3b2a1'f64

    i8_out: int8
    u8_out: uint8
    i16_out: int16
    u16_out: uint16
    i32_out: int32
    u32_out: uint32
    i64_out: int64
    u64_out: uint64
    f32_out: float32
    f64_out: float64

  when system.cpuEndian == bigEndian:
    assert fromBytesBE(   int8,  i8_var.addr) == i8
    assert fromBytesBE(  uint8,  u8_var.addr) == u8
    assert fromBytesBE(  int16, i16_var.addr) == i16
    assert fromBytesBE( uint16, u16_var.addr) == u16
    assert fromBytesBE(  int32, i32_var.addr) == i32
    assert fromBytesBE( uint32, u32_var.addr) == u32
    assert fromBytesBE(  int64, i64_var.addr) == i64
    assert fromBytesBE( uint64, u64_var.addr) == u64
    assert fromBytesBE(float32, f32_var.addr) == f32
    assert fromBytesBE(float64, f64_var.addr) == f64

    assert fromBytesLE(   int8,  i8_var.addr) == i8
    assert fromBytesLE(  uint8,  u8_var.addr) == u8
    assert fromBytesLE(  int16, i16_var.addr) == i16_rev
    assert fromBytesLE( uint16, u16_var.addr) == u16_rev
    assert fromBytesLE(  int32, i32_var.addr) == i32_rev
    assert fromBytesLE( uint32, u32_var.addr) == u32_rev
    assert fromBytesLE(  int64, i64_var.addr) == i64_rev
    assert fromBytesLE( uint64, u64_var.addr) == u64_rev
    assert fromBytesLE(float32, f32_var.addr) == f32_rev
    assert fromBytesLE(float64, f64_var.addr) == f64_rev

    swapEndian(int64, buf, 3)

    toBytesBE(i8 ,  i8_out.addr); assert  i8_out == i8
    toBytesBE(u8 ,  u8_out.addr); assert  u8_out == u8
    toBytesBE(i16, i16_out.addr); assert i16_out == i16
    toBytesBE(u16, u16_out.addr); assert u16_out == u16
    toBytesBE(i32, i32_out.addr); assert i32_out == i32
    toBytesBE(u32, u32_out.addr); assert u32_out == u32
    toBytesBE(i64, i64_out.addr); assert i64_out == i64
    toBytesBE(u64, u64_out.addr); assert u64_out == u64
    toBytesBE(f32, f32_out.addr); assert f32_out == f32
    toBytesBE(f64, f64_out.addr); assert f64_out == f64

    toBytesLE(i8,   i8_out.addr); assert  i8_out == i8
    toBytesLE(u8,   u8_out.addr); assert  u8_out == u8
    toBytesLE(i16, i16_out.addr); assert i16_out == i16_rev
    toBytesLE(u16, u16_out.addr); assert u16_out == u16_rev
    toBytesLE(i32, i32_out.addr); assert i32_out == i32_rev
    toBytesLE(u32, u32_out.addr); assert u32_out == u32_rev
    toBytesLE(i64, i64_out.addr); assert i64_out == i64_rev
    toBytesLE(u64, u64_out.addr); assert u64_out == u64_rev
    toBytesLE(f32, f32_out.addr); assert f32_out == f32_rev
    toBytesLE(f64, f64_out.addr); assert f64_out == f64_rev

  else:  # little-endian
    assert fromBytesBE(   int8,  i8_var.addr) == i8
    assert fromBytesBE(  uint8,  u8_var.addr) == u8
    assert fromBytesBE(  int16, i16_var.addr) == i16_rev
    assert fromBytesBE( uint16, u16_var.addr) == u16_rev
    assert fromBytesBE(  int32, i32_var.addr) == i32_rev
    assert fromBytesBE( uint32, u32_var.addr) == u32_rev
    assert fromBytesBE(  int64, i64_var.addr) == i64_rev
    assert fromBytesBE( uint64, u64_var.addr) == u64_rev
    assert fromBytesBE(float32, f32_var.addr) == f32_rev
    assert fromBytesBE(float64, f64_var.addr) == f64_rev

    assert fromBytesLE(   int8,  i8_var.addr) == i8
    assert fromBytesLE(  uint8,  u8_var.addr) == u8
    assert fromBytesLE(  int16, i16_var.addr) == i16
    assert fromBytesLE( uint16, u16_var.addr) == u16
    assert fromBytesLE(  int32, i32_var.addr) == i32
    assert fromBytesLE( uint32, u32_var.addr) == u32
    assert fromBytesLE(  int64, i64_var.addr) == i64
    assert fromBytesLE( uint64, u64_var.addr) == u64
    assert fromBytesLE(float32, f32_var.addr) == f32
    assert fromBytesLE(float64, f64_var.addr) == f64

    swapEndian(int64, buf, 3)

    toBytesBE(i8,   i8_out.addr); assert  i8_out == i8
    toBytesBE(u8,   u8_out.addr); assert  u8_out == u8
    toBytesBE(i16, i16_out.addr); assert i16_out == i16_rev
    toBytesBE(u16, u16_out.addr); assert u16_out == u16_rev
    toBytesBE(i32, i32_out.addr); assert i32_out == i32_rev
    toBytesBE(u32, u32_out.addr); assert u32_out == u32_rev
    toBytesBE(i64, i64_out.addr); assert i64_out == i64_rev
    toBytesBE(u64, u64_out.addr); assert u64_out == u64_rev
    toBytesBE(f32, f32_out.addr); assert f32_out == f32_rev
    toBytesBE(f64, f64_out.addr); assert f64_out == f64_rev

    toBytesLE(i8,   i8_out.addr); assert  i8_out == i8
    toBytesLE(u8,   u8_out.addr); assert  u8_out == u8
    toBytesLE(i16, i16_out.addr); assert i16_out == i16
    toBytesLE(u16, u16_out.addr); assert u16_out == u16
    toBytesLE(i32, i32_out.addr); assert i32_out == i32
    toBytesLE(u32, u32_out.addr); assert u32_out == u32
    toBytesLE(i64, i64_out.addr); assert i64_out == i64
    toBytesLE(u64, u64_out.addr); assert u64_out == u64
    toBytesLE(f32, f32_out.addr); assert f32_out == f32
    toBytesLE(f64, f64_out.addr); assert f64_out == f64

