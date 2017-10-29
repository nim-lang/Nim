#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import endians, strutils, os

type
  MetroHash64Digest* = array[0..7, uint8]
  MetroHash128Digest* = array[0..15, uint8]
  MetroHashContext* = tuple
    v: array[0..3, uint64]
    vseed: uint64
    bytes: int64
    buffer: array[0..31, uint8]

proc `$`*(d: MetroHash64Digest|MetroHash128Digest): string =
  ## converts a MetroHash128Digest value into its string representation
  const digits = "0123456789ABCDEF"
  result = ""
  for i in 0..<d.len:
    add(result, digits[(d[i] shr 4) and 0xF])
    add(result, digits[d[i] and 0xF])

proc `==`*(d1, d2: MetroHash64Digest|MetroHash128Digest): bool =
  for i in 0..<d1.len:
    if d1[i] != d2[i]: return false
  return true

template read_u8(p: ByteAddress): untyped =
  (cast[ptr uint8](p)[])

template read_u16(p: ByteAddress): untyped =
  (cast[ptr uint16](p)[])

template read_u32(p: ByteAddress): untyped =
  (cast[ptr uint32](p)[])

template read_u64(p: ByteAddress): untyped =
  (cast[ptr uint64](p)[])

template rotate_right(value: uint64; amount: uint): uint64 =
  ((value shr amount) or (value shl (64 - amount)))

template `^=`(x: var uint64, y: uint64): untyped =
  x = x xor y

template callFunc(f: untyped): untyped =
  when T is string:
    result = f(cast[ByteAddress](unsafeAddr(input[0])), input.len, seed)
  elif T is seq|openArray|varargs:
    result = f(cast[ByteAddress](unsafeAddr(input[0])), input.len * sizeof(input[0]), seed)
  else:
    result = f(cast[ByteAddress](unsafeAddr(input)), sizeof(input), seed)

template callFunc(c, f: untyped): untyped =
  when T is string:
    f(c, cast[ByteAddress](unsafeAddr(input[0])), input.len)
  elif T is seq|openArray|varargs:
    f(c, cast[ByteAddress](unsafeAddr(input[0])), input.len * sizeof(input[0]))
  else:
    f(c, cast[ByteAddress](unsafeAddr(input)), sizeof(input))

template callFileFunc(f: untyped): untyped =
  f(readFile(filename))

proc metroHash64Init*(c: var MetroHashContext, seed: uint64 = 0) =
  const 
    k0 = 0xD6D018F5'u64
    k2 = 0x62992FC1'u64

  c.vseed = (seed + k2) * k0

  c.v[0] = c.vseed
  c.v[1] = c.vseed
  c.v[2] = c.vseed
  c.v[3] = c.vseed
  c.bytes = 0
  zeroMem(addr(c.buffer), sizeof(c.buffer))

proc metroHash64Update*(c: var MetroHashContext, input: ByteAddress, inputLen: int) =
  const 
    k0 = 0xD6D018F5'u64
    k1 = 0xA2AA033B'u64
    k2 = 0x62992FC1'u64
    k3 = 0x30BC5B29'u64

  var 
    p = input
    e = input + inputLen
    rem = c.bytes %% 32'i64

  if rem > 0:
    var 
      fill: int

    fill = 32 - rem
    if (fill > inputLen):
      fill = inputLen
    copymem(cast[pointer](cast[ByteAddress](addr(c.buffer)) + rem), cast[pointer](p), fill)
    p += fill
    c.bytes += fill

    if ((c.bytes %% 32'i64) != 0): return

    c.v[0] += read_u64(cast[ByteAddress](addr(c.buffer[0]))) * k0
    c.v[0] = rotate_right(c.v[0], 29) + c.v[2]

    c.v[1] += read_u64(cast[ByteAddress](addr(c.buffer[8]))) * k1
    c.v[1] = rotate_right(c.v[1], 29) + c.v[3]

    c.v[2] += read_u64(cast[ByteAddress](addr(c.buffer[16]))) * k2
    c.v[2] = rotate_right(c.v[2], 29) + c.v[0]

    c.v[3] += read_u64(cast[ByteAddress](addr(c.buffer[24]))) * k3
    c.v[3] = rotate_right(c.v[3], 29) + c.v[1]

  c.bytes += (e - p)

  while p <= (e - 32):
    c.v[0] += read_u64(p) * k0
    c.v[0] = rotate_right(c.v[0], 29) + c.v[2]
    p += 8

    c.v[1] += read_u64(p) * k1
    c.v[1] = rotate_right(c.v[1], 29) + c.v[3]
    p += 8

    c.v[2] += read_u64(p) * k2
    c.v[2] = rotate_right(c.v[2], 29) + c.v[0]
    p += 8

    c.v[3] += read_u64(p) * k3
    c.v[3] = rotate_right(c.v[3], 29) + c.v[1]
    p += 8

  if (p < e):
    copymem(cast[pointer](cast[ByteAddress](addr(c.buffer))), cast[pointer](p), e - p)

proc metroHash64Final*(c: var MetroHashContext, digest: var MetroHash64Digest) =
  const 
    k0 = 0xD6D018F5'u64
    k1 = 0xA2AA033B'u64
    k2 = 0x62992FC1'u64
    k3 = 0x30BC5B29'u64

  if (c.bytes >= 32):
    c.v[2] ^= rotate_right(((c.v[0] + c.v[3]) * k0) + c.v[1], 37) * k1
    c.v[3] ^= rotate_right(((c.v[1] + c.v[2]) * k1) + c.v[0], 37) * k0
    c.v[0] ^= rotate_right(((c.v[0] + c.v[2]) * k0) + c.v[3], 37) * k1
    c.v[1] ^= rotate_right(((c.v[1] + c.v[3]) * k1) + c.v[2], 37) * k0

    c.v[0] = c.vseed + (c.v[0] xor c.v[1])

  var
    p = cast[ByteAddress](addr(c.buffer))
    e = p + (c.bytes %% 32'i64)

  if ((e - p) >= 16):
    c.v[1] = c.v[0] + read_u64(p) * k2
    c.v[1] = rotate_right(c.v[1], 29) * k3
    p += 8

    c.v[2] = c.v[0] + read_u64(p) * k2
    c.v[2] = rotate_right(c.v[2], 29) * k3

    c.v[1] ^= rotate_right(c.v[1] * k0, 21) + c.v[2]
    c.v[2] ^= rotate_right(c.v[2] * k3, 21) + c.v[1]

    c.v[0] += c.v[2]

    p += 8

  if ((e - p) >= 8):
    c.v[0] += read_u64(p) * k3
    c.v[0] ^= rotate_right(c.v[0], 55) * k1
    p += 8

  if ((e - p) >= 4):
    c.v[0] += cast[uint64](read_u32(p)) * k3
    c.v[0] ^= rotate_right(c.v[0], 26) * k1
    p += 4

  if ((e - p) >= 2):
    c.v[0] += cast[uint64](read_u16(p)) * k3
    c.v[0] ^= rotate_right(c.v[0], 48) * k1
    p += 2

  if ((e - p) >= 1):
    c.v[0] += cast[uint64](read_u8(p)) * k3
    c.v[0] ^= rotate_right(c.v[0], 37) * k1

  c.v[0] ^= rotate_right(c.v[0], 28)
  c.v[0] *= k0
  c.v[0] ^= rotate_right(c.v[0], 29)

  c.bytes = 0
 
  littleEndian64(addr(digest), addr(c.v))

proc metroHash64Update*[T](c: var MetroHashContext, input: T) {.inline.} =
  callFunc(c, metroHash64Update)

proc metroHash64*(input: ByteAddress, inputLen: int, seed: uint64 = 0): MetroHash64Digest =
  const 
    k0 = 0xD6D018F5'u64
    k1 = 0xA2AA033B'u64
    k2 = 0x62992FC1'u64
    k3 = 0x30BC5B29'u64

  var 
    p = input
    e = p + inputLen
    hash: uint64 = (seed + k2) * k0

  if inputLen >= 32:
    var
      v0 = hash
      v1 = hash
      v2 = hash
      v3 = hash

    while p < (e - 32):
      v0 += read_u64(p) * k0
      v0 = rotate_right(v0, 29) + v2
      p += 8

      v1 += read_u64(p) * k1
      v1 = rotate_right(v1, 29) + v3
      p += 8

      v2 += read_u64(p) * k2
      v2 = rotate_right(v2, 29) + v0
      p += 8

      v3 += read_u64(p) * k3
      p += 8
      v3 = rotate_right(v3, 29) + v1

    v2 ^= rotate_right(((v0 + v3) * k0) + v1, 37) * k1
    v3 ^= rotate_right(((v1 + v2) * k1) + v0, 37) * k0
    v0 ^= rotate_right(((v0 + v2) * k0) + v3, 37) * k1
    v1 ^= rotate_right(((v1 + v3) * k1) + v2, 37) * k0
    hash += (v0 xor v1)

  if (e - p) >= 16:
    var
      v0: uint64
      v1: uint64

    v0 = hash + read_u64(p) * k2
    v0 = rotate_right(v0, 29) * k3
    p += 8

    v1 = hash + read_u64(p) * k2
    v1 = rotate_right(v1, 29) * k3
    p += 8

    v0 ^= rotate_right(v0 * k0, 21) + v1
    v1 ^= rotate_right(v1 * k3, 21) + v0
    hash += v1

  if (e - p) >= 8:
    hash += read_u64(p) * k3
    hash ^= rotate_right(hash, 55) * k1
    p += 8

  if (e - p) >= 4:
    hash += cast[uint64](read_u32(p)) * k3
    hash ^= rotate_right(hash, 26) * k1
    p += 4

  if (e - p) >= 2:
    hash += cast[uint64](read_u16(p)) * k3
    hash ^= rotate_right(hash, 48) * k1
    p += 2

  if (e - p) >= 1:
    hash += cast[uint64](read_u8(p)) * k3
    hash ^= rotate_right(hash, 37) * k1

  hash ^= rotate_right(hash, 28)
  hash *= k0
  hash ^= rotate_right(hash, 29)

  littleEndian64(addr(result), addr(hash))

proc metroHash128Init*(c: var MetroHashContext, seed: uint64 = 0) =
  const 
    k0 = 0xC83A91E1'u64
    k1 = 0x8648DBDB'u64
    k2 = 0x7BDEC03B'u64
    k3 = 0x2F5870A5'u64

  c.v[0] = (seed - k0) * k3
  c.v[1] = (seed + k1) * k2
  c.v[2] = (seed + k0) * k2
  c.v[3] = (seed - k1) * k3
  c.bytes = 0
  zeroMem(addr(c.buffer), sizeof(c.buffer))

proc metroHash128Update*(c: var MetroHashContext, input: ByteAddress, inputLen: int) =
  const 
    k0 = 0xC83A91E1'u64
    k1 = 0x8648DBDB'u64
    k2 = 0x7BDEC03B'u64
    k3 = 0x2F5870A5'u64

  var 
    p = input
    e = input + inputLen
    rem = c.bytes %% 32'i64

  if rem > 0:
    var 
      fill: int

    fill = 32 - rem
    if (fill > inputLen):
      fill = inputLen

    copymem(cast[pointer](cast[ByteAddress](addr(c.buffer)) + rem), cast[pointer](p), fill)

    p += fill
    c.bytes += fill

    if ((c.bytes %% 32'i64) != 0): return

    c.v[0] += read_u64(cast[ByteAddress](addr(c.buffer[0]))) * k0
    c.v[0] = rotate_right(c.v[0], 29) + c.v[2]

    c.v[1] += read_u64(cast[ByteAddress](addr(c.buffer[8]))) * k1
    c.v[1] = rotate_right(c.v[1], 29) + c.v[3]

    c.v[2] += read_u64(cast[ByteAddress](addr(c.buffer[16]))) * k2
    c.v[2] = rotate_right(c.v[2], 29) + c.v[0]

    c.v[3] += read_u64(cast[ByteAddress](addr(c.buffer[24]))) * k3
    c.v[3] = rotate_right(c.v[3], 29) + c.v[1]

  c.bytes += (e - p)

  while p <= (e - 32):
    c.v[0] += read_u64(p) * k0
    c.v[0] = rotate_right(c.v[0], 29) + c.v[2]
    p += 8

    c.v[1] += read_u64(p) * k1
    c.v[1] = rotate_right(c.v[1], 29) + c.v[3]
    p += 8

    c.v[2] += read_u64(p) * k2
    c.v[2] = rotate_right(c.v[2], 29) + c.v[0]
    p += 8

    c.v[3] += read_u64(p) * k3
    c.v[3] = rotate_right(c.v[3], 29) + c.v[1]
    p += 8

  if (p < e):
    copymem(cast[pointer](cast[ByteAddress](addr(c.buffer))), cast[pointer](p), e - p)

proc metroHash128Final*(c: var MetroHashContext, digest: var MetroHash128Digest) =
  const 
    k0 = 0xC83A91E1'u64
    k1 = 0x8648DBDB'u64
    k2 = 0x7BDEC03B'u64
    k3 = 0x2F5870A5'u64

  if (c.bytes >= 32):
    c.v[2] ^= (rotate_right(((c.v[0] + c.v[3]) * k0) + c.v[1], 21) * k1)
    c.v[3] ^= (rotate_right(((c.v[1] + c.v[2]) * k1) + c.v[0], 21) * k0)
    c.v[0] ^= (rotate_right(((c.v[0] + c.v[2]) * k0) + c.v[3], 21) * k1)
    c.v[1] ^= (rotate_right(((c.v[1] + c.v[3]) * k1) + c.v[2], 21) * k0)

  var
    p = cast[ByteAddress](addr(c.buffer))
    e = p + (c.bytes %% 32'i64)

  if ((e - p) >= 16):
    c.v[0] += read_u64(p) * k2
    c.v[0] = rotate_right(c.v[0], 33) * k3
    p += 8

    c.v[1] += read_u64(p) * k2
    c.v[1] = rotate_right(c.v[1], 33) * k3

    c.v[0] ^= (rotate_right((c.v[0] * k2) + c.v[1], 45) * k1)
    c.v[1] ^= (rotate_right((c.v[1] * k3) + c.v[0], 45) * k0)
    p += 8

  if ((e - p) >= 8):
    c.v[0] += read_u64(p) * k2
    c.v[0] = rotate_right(c.v[0], 33) * k3
    c.v[0] ^= (rotate_right((c.v[0] * k2) + c.v[1], 27) * k1)
    p += 8

  if ((e - p) >= 4):
    c.v[1] += cast[uint64](read_u32(p)) * k2
    c.v[1] = rotate_right(c.v[1], 33) * k3
    c.v[1] ^= (rotate_right((c.v[1] * k3) + c.v[0], 46) * k0)
    p += 4

  if ((e - p) >= 2):
    c.v[0] += cast[uint64](read_u16(p)) * k2
    c.v[0] = rotate_right(c.v[0], 33) * k3
    c.v[0] ^= (rotate_right((c.v[0] * k2) + c.v[1], 22) * k1)
    p += 2

  if ((e - p) >= 1):
    c.v[1] += cast[uint64](read_u8(p)) * k2
    c.v[1] = rotate_right(c.v[1], 33) * k3
    c.v[1] ^= (rotate_right((c.v[1] * k3) + c.v[0], 58) * k0)

  c.v[0] += rotate_right((c.v[0] * k0) + c.v[1], 13)
  c.v[1] += rotate_right((c.v[1] * k1) + c.v[0], 37)
  c.v[0] += rotate_right((c.v[0] * k2) + c.v[1], 13)
  c.v[1] += rotate_right((c.v[1] * k3) + c.v[0], 37)

  c.bytes = 0

  littleEndian64(addr(digest[0]), addr(c.v[0]))
  littleEndian64(addr(digest[8]), addr(c.v[1]))

proc metroHash128Update*[T](c: var MetroHashContext, input: T) {.inline.} =
  callFunc(c, metroHash128Update)

proc metroHash128*(input: ByteAddress, inputLen: int, seed: uint64 = 0): MetroHash128Digest =
  const 
    k0 = 0xC83A91E1'u64
    k1 = 0x8648DBDB'u64
    k2 = 0x7BDEC03B'u64
    k3 = 0x2F5870A5'u64

  var 
    p = input
    e = p + inputLen
    v: array[0..3, uint64]

  v[0] = (seed - k0) * k3
  v[1] = (seed + k1) * k2

  if inputLen >= 32:
    v[2] = (seed + k0) * k2
    v[3] = (seed - k1) * k3

    while p <= (e - 32):
      v[0] += read_u64(p) * k0
      v[0] = rotate_right(v[0], 29) + v[2]
      p += 8

      v[1] += read_u64(p) * k1
      v[1] = rotate_right(v[1], 29) + v[3]
      p += 8

      v[2] += read_u64(p) * k2
      v[2] = rotate_right(v[2], 29) + v[0]
      p += 8

      v[3] += read_u64(p) * k3
      v[3] = rotate_right(v[3], 29) + v[1]
      p += 8

    v[2] ^= (rotate_right(((v[0] + v[3]) * k0) + v[1], 21) * k1)
    v[3] ^= (rotate_right(((v[1] + v[2]) * k1) + v[0], 21) * k0)
    v[0] ^= (rotate_right(((v[0] + v[2]) * k0) + v[3], 21) * k1)
    v[1] ^= (rotate_right(((v[1] + v[3]) * k1) + v[2], 21) * k0)

  if ((e - p) >= 16):
    v[0] += read_u64(p) * k2
    v[0] = rotate_right(v[0], 33) * k3
    p += 8

    v[1] += read_u64(p) * k2
    v[1] = rotate_right(v[1], 33) * k3

    v[0] ^= (rotate_right((v[0] * k2) + v[1], 45) * k1)
    v[1] ^= (rotate_right((v[1] * k3) + v[0], 45) * k0)
    p += 8

  if ((e - p) >= 8):
    v[0] += read_u64(p) * k2
    v[0] = rotate_right(v[0], 33) * k3
    v[0] ^= (rotate_right((v[0] * k2) + v[1], 27) * k1)
    p += 8

  if ((e - p) >= 4):
    v[1] += cast[uint64](read_u32(p)) * k2
    v[1] = rotate_right(v[1], 33) * k3
    v[1] ^= (rotate_right((v[1] * k3) + v[0], 46) * k0)
    p += 4

  if ((e - p) >= 2):
    v[0] += cast[uint64](read_u16(p)) * k2
    v[0] = rotate_right(v[0], 33) * k3
    v[0] ^= (rotate_right((v[0] * k2) + v[1], 22) * k1)
    p += 2

  if ((e - p) >= 1):
    v[1] += cast[uint64](read_u8(p)) * k2
    v[1] = rotate_right(v[1], 33) * k3
    v[1] ^= (rotate_right((v[1] * k3) + v[0], 58) * k0)

  v[0] += rotate_right((v[0] * k0) + v[1], 13)
  v[1] += rotate_right((v[1] * k1) + v[0], 37)
  v[0] += rotate_right((v[0] * k2) + v[1], 13)
  v[1] += rotate_right((v[1] * k3) + v[0], 37)

  littleEndian64(addr(result[0]), addr(v[0]))
  littleEndian64(addr(result[8]), addr(v[1]))

proc metroHash64*[T](input: T, seed: uint64 = 0): MetroHash64Digest =
  callFunc(metroHash64)

proc metroHash64File*(filename: string, seed: uint64 = 0): MetroHash64Digest =
  callFileFunc(metroHash64)

proc metroHash128*[T](input: T, seed: uint64 = 0): MetroHash128Digest =
  callFunc(metroHash128)

proc metroHash128File*(filename: string, seed: uint64 = 0): MetroHash128Digest =
  callFileFunc(metroHash128)

proc parseMetroHash64*(hash: string): MetroHash64Digest =
  for i in 0.. <result.len:
    result[i] = uint8(parseHexInt(hash[i*2] & hash[i*2 + 1]))

proc parseMetroHash128*(hash: string): MetroHash128Digest =
  for i in 0.. <result.len:
    result[i] = uint8(parseHexInt(hash[i*2] & hash[i*2 + 1]))
