#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module for computing MD5 checksums.

type 
  MD5State = array[0..3, int32]
  MD5Block = array[0..15, int32]
  MD5CBits = array[0..7, int8]
  MD5Digest* = array[0..15, int8]
  MD5Buffer = array[0..63, int8]
  MD5Context* {.final.} = object 
    state: MD5State
    count: array[0..1, int32]
    buffer: MD5Buffer

const 
  padding: cstring = "\x80\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0\0\0\0\0" &
                     "\0\0\0\0"

proc F(x, y, z: int32): int32 {.inline.} = 
  result = (x and y) or ((not x) and z)

proc G(x, y, z: int32): int32 {.inline.} = 
  result = (x and z) or (y and (not z))

proc H(x, y, z: int32): int32 {.inline.} = 
  result = x xor y xor z

proc I(x, y, z: int32): int32 {.inline.} = 
  result = y xor (x or (not z))

proc rot(x: var int32, n: int8) {.inline.} = 
  x = toU32(x shl ze(n)) or (x shr toU32(32 -% ze(n)))

proc FF(a: var int32, b, c, d, x: int32, s: int8, ac: int32) = 
  a = a +% F(b, c, d) +% x +% ac
  rot(a, s)
  a = a +% b

proc GG(a: var int32, b, c, d, x: int32, s: int8, ac: int32) = 
  a = a +% G(b, c, d) +% x +% ac
  rot(a, s)
  a = a +% b

proc HH(a: var int32, b, c, d, x: int32, s: int8, ac: int32) = 
  a = a +% H(b, c, d) +% x +% ac
  rot(a, s)
  a = a +% b

proc II(a: var int32, b, c, d, x: int32, s: int8, ac: int32) = 
  a = a +% I(b, c, d) +% x +% ac
  rot(a, s)
  a = a +% b

proc encode(dest: var MD5Block, src: cstring) = 
  var j = 0
  for i in 0..high(dest):
    dest[i] = toU32(ord(src[j]) or 
                ord(src[j+1]) shl 8 or
                ord(src[j+2]) shl 16 or
                ord(src[j+3]) shl 24)
    inc(j, 4)

proc decode(dest: var openArray[int8], src: openArray[int32]) = 
  var i = 0
  for j in 0..high(src):
    dest[i] = toU8(src[j] and 0xff'i32)
    dest[i+1] = toU8(src[j] shr 8'i32 and 0xff'i32)
    dest[i+2] = toU8(src[j] shr 16'i32 and 0xff'i32)
    dest[i+3] = toU8(src[j] shr 24'i32 and 0xff'i32)
    inc(i, 4)

proc transform(buffer: pointer, state: var MD5State) = 
  var
    myBlock: MD5Block
  encode(myBlock, cast[cstring](buffer))
  var a = state[0]
  var b = state[1]
  var c = state[2]
  var d = state[3]
  FF(a, b, c, d, myBlock[0], 7'i8, 0xD76AA478'i32)
  FF(d, a, b, c, myBlock[1], 12'i8, 0xE8C7B756'i32)
  FF(c, d, a, b, myBlock[2], 17'i8, 0x242070DB'i32)
  FF(b, c, d, a, myBlock[3], 22'i8, 0xC1BDCEEE'i32)
  FF(a, b, c, d, myBlock[4], 7'i8, 0xF57C0FAF'i32)
  FF(d, a, b, c, myBlock[5], 12'i8, 0x4787C62A'i32)
  FF(c, d, a, b, myBlock[6], 17'i8, 0xA8304613'i32)
  FF(b, c, d, a, myBlock[7], 22'i8, 0xFD469501'i32)
  FF(a, b, c, d, myBlock[8], 7'i8, 0x698098D8'i32)
  FF(d, a, b, c, myBlock[9], 12'i8, 0x8B44F7AF'i32)
  FF(c, d, a, b, myBlock[10], 17'i8, 0xFFFF5BB1'i32)
  FF(b, c, d, a, myBlock[11], 22'i8, 0x895CD7BE'i32)
  FF(a, b, c, d, myBlock[12], 7'i8, 0x6B901122'i32)
  FF(d, a, b, c, myBlock[13], 12'i8, 0xFD987193'i32)
  FF(c, d, a, b, myBlock[14], 17'i8, 0xA679438E'i32)
  FF(b, c, d, a, myBlock[15], 22'i8, 0x49B40821'i32)
  GG(a, b, c, d, myBlock[1], 5'i8, 0xF61E2562'i32)
  GG(d, a, b, c, myBlock[6], 9'i8, 0xC040B340'i32)
  GG(c, d, a, b, myBlock[11], 14'i8, 0x265E5A51'i32)
  GG(b, c, d, a, myBlock[0], 20'i8, 0xE9B6C7AA'i32)
  GG(a, b, c, d, myBlock[5], 5'i8, 0xD62F105D'i32)
  GG(d, a, b, c, myBlock[10], 9'i8, 0x02441453'i32)
  GG(c, d, a, b, myBlock[15], 14'i8, 0xD8A1E681'i32)
  GG(b, c, d, a, myBlock[4], 20'i8, 0xE7D3FBC8'i32)
  GG(a, b, c, d, myBlock[9], 5'i8, 0x21E1CDE6'i32)
  GG(d, a, b, c, myBlock[14], 9'i8, 0xC33707D6'i32)
  GG(c, d, a, b, myBlock[3], 14'i8, 0xF4D50D87'i32)
  GG(b, c, d, a, myBlock[8], 20'i8, 0x455A14ED'i32)
  GG(a, b, c, d, myBlock[13], 5'i8, 0xA9E3E905'i32)
  GG(d, a, b, c, myBlock[2], 9'i8, 0xFCEFA3F8'i32)
  GG(c, d, a, b, myBlock[7], 14'i8, 0x676F02D9'i32)
  GG(b, c, d, a, myBlock[12], 20'i8, 0x8D2A4C8A'i32)
  HH(a, b, c, d, myBlock[5], 4'i8, 0xFFFA3942'i32)
  HH(d, a, b, c, myBlock[8], 11'i8, 0x8771F681'i32)
  HH(c, d, a, b, myBlock[11], 16'i8, 0x6D9D6122'i32)
  HH(b, c, d, a, myBlock[14], 23'i8, 0xFDE5380C'i32)
  HH(a, b, c, d, myBlock[1], 4'i8, 0xA4BEEA44'i32)
  HH(d, a, b, c, myBlock[4], 11'i8, 0x4BDECFA9'i32)
  HH(c, d, a, b, myBlock[7], 16'i8, 0xF6BB4B60'i32)
  HH(b, c, d, a, myBlock[10], 23'i8, 0xBEBFBC70'i32)
  HH(a, b, c, d, myBlock[13], 4'i8, 0x289B7EC6'i32)
  HH(d, a, b, c, myBlock[0], 11'i8, 0xEAA127FA'i32)
  HH(c, d, a, b, myBlock[3], 16'i8, 0xD4EF3085'i32)
  HH(b, c, d, a, myBlock[6], 23'i8, 0x04881D05'i32)
  HH(a, b, c, d, myBlock[9], 4'i8, 0xD9D4D039'i32)
  HH(d, a, b, c, myBlock[12], 11'i8, 0xE6DB99E5'i32)
  HH(c, d, a, b, myBlock[15], 16'i8, 0x1FA27CF8'i32)
  HH(b, c, d, a, myBlock[2], 23'i8, 0xC4AC5665'i32)
  II(a, b, c, d, myBlock[0], 6'i8, 0xF4292244'i32)
  II(d, a, b, c, myBlock[7], 10'i8, 0x432AFF97'i32)
  II(c, d, a, b, myBlock[14], 15'i8, 0xAB9423A7'i32)
  II(b, c, d, a, myBlock[5], 21'i8, 0xFC93A039'i32)
  II(a, b, c, d, myBlock[12], 6'i8, 0x655B59C3'i32)
  II(d, a, b, c, myBlock[3], 10'i8, 0x8F0CCC92'i32)
  II(c, d, a, b, myBlock[10], 15'i8, 0xFFEFF47D'i32)
  II(b, c, d, a, myBlock[1], 21'i8, 0x85845DD1'i32)
  II(a, b, c, d, myBlock[8], 6'i8, 0x6FA87E4F'i32)
  II(d, a, b, c, myBlock[15], 10'i8, 0xFE2CE6E0'i32)
  II(c, d, a, b, myBlock[6], 15'i8, 0xA3014314'i32)
  II(b, c, d, a, myBlock[13], 21'i8, 0x4E0811A1'i32)
  II(a, b, c, d, myBlock[4], 6'i8, 0xF7537E82'i32)
  II(d, a, b, c, myBlock[11], 10'i8, 0xBD3AF235'i32)
  II(c, d, a, b, myBlock[2], 15'i8, 0x2AD7D2BB'i32)
  II(b, c, d, a, myBlock[9], 21'i8, 0xEB86D391'i32)
  state[0] = state[0] +% a
  state[1] = state[1] +% b
  state[2] = state[2] +% c
  state[3] = state[3] +% d
  
proc md5Init*(c: var MD5Context) = 
  ## initializes a MD5Context  
  c.state[0] = 0x67452301'i32
  c.state[1] = 0xEFCDAB89'i32
  c.state[2] = 0x98BADCFE'i32
  c.state[3] = 0x10325476'i32
  c.count[0] = 0'i32
  c.count[1] = 0'i32
  zeroMem(addr(c.buffer), sizeof(MD5buffer))

proc md5Update*(c: var MD5Context, input: cstring, len: int) = 
  ## updates the MD5Context with the `input` data of length `len`
  var input = input
  var Index = (c.count[0] shr 3) and 0x3F
  c.count[0] = c.count[0] +% toU32(len shl 3)
  if c.count[0] < (len shl 3): c.count[1] = c.count[1] +% 1'i32
  c.count[1] = c.count[1] +% toU32(len shr 29)
  var PartLen = 64 - Index
  if len >= PartLen: 
    copyMem(addr(c.buffer[Index]), input, PartLen)
    transform(addr(c.buffer), c.state)
    var i = PartLen
    while i + 63 < len: 
      transform(addr(input[i]), c.state)
      inc(i, 64)
    copyMem(addr(c.buffer[0]), addr(input[i]), len-i)
  else:
    copyMem(addr(c.buffer[Index]), addr(input[0]), len)

proc md5Final*(c: var MD5Context, digest: var MD5Digest) = 
  ## finishes the MD5Context and stores the result in `digest`
  var
    Bits: MD5CBits
    PadLen: int
  decode(Bits, c.count)
  var Index = (c.count[0] shr 3) and 0x3F
  if Index < 56: PadLen = 56 - Index
  else: PadLen = 120 - Index
  md5Update(c, padding, PadLen)
  md5Update(c, cast[cstring](addr(Bits)), 8)
  decode(digest, c.state)
  zeroMem(addr(c), sizeof(MD5Context))

proc toMD5*(s: string): MD5Digest = 
  ## computes the MD5Digest value for a string `s`
  var c: MD5Context
  md5Init(c)
  md5Update(c, cstring(s), len(s))
  md5Final(c, result)
  
proc `$`*(D: MD5Digest): string = 
  ## converts a MD5Digest value into its string representation
  const digits = "0123456789abcdef"
  result = ""
  for i in 0..15: 
    add(result, digits[(D[i] shr 4) and 0xF])
    add(result, digits[D[i] and 0xF])

proc getMD5*(s: string): string =  
  ## computes an MD5 value of `s` and returns its string representation
  var 
    c: MD5Context
    d: MD5Digest
  md5Init(c)
  md5Update(c, cstring(s), len(s))
  md5Final(c, d)
  result = $d
  
proc `==`*(D1, D2: MD5Digest): bool =  
  ## checks if two MD5Digest values are identical
  for i in 0..15: 
    if D1[i] != D2[i]: return false
  return true

when isMainModule:
  assert(getMD5("Franz jagt im komplett verwahrlosten Taxi quer durch Bayern") ==
    "a3cca2b2aa1e3b5b3b5aad99a8529074")
  assert(getMD5("Frank jagt im komplett verwahrlosten Taxi quer durch Bayern") ==
    "7e716d0e702df0505fc72e2b89467910")
  assert($toMD5("") == "d41d8cd98f00b204e9800998ecf8427e")


