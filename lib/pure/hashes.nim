#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dmitry Atamanov
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements efficient computations of hash values for diverse
## Nim types. All the procs are based on these two building blocks:
## - `!& proc <#!&>`_ used to start or mix a hash value, and
## - `!$ proc <#!$>`_ used to *finish* the hash value.
## If you want to implement hash procs for
## your custom types you will end up writing the following kind of skeleton of
## code:
##
## .. code-block:: Nim
##  proc hash(x: Something): Hash =
##    ## Computes a Hash from `x`.
##    var h: Hash = 0
##    # Iterate over parts of `x`.
##    for xAtom in x:
##      # Mix the atom with the partial hash.
##      h = h !& xAtom
##    # Finish the hash.
##    result = !$h
##
## If your custom types contain fields for which there already is a hash proc,
## like for example objects made up of ``strings``, you can simply hash
## together the hash value of the individual fields:
##
## .. code-block:: Nim
##  proc hash(x: Something): Hash =
##    ## Computes a Hash from `x`.
##    var h: Hash = 0
##    h = h !& hash(x.foo)
##    h = h !& hash(x.bar)
##    result = !$h

import
  strutils

type
  Hash* = int ## a hash value; hash tables using these values should
               ## always have a size of a power of two and can use the ``and``
               ## operator instead of ``mod`` for truncation of the hash value.
{.deprecated: [THash: Hash].}

proc `!&`*(h: Hash, val: int): Hash {.inline, noSideEffect.} =
  ## mixes a hash value `h` with `val` to produce a new hash value. This is
  ## only needed if you need to implement a hash proc for a new datatype.
  result = h +% val
  result = result +% result shl 10
  result = result xor (result shr 6)

proc `!$`*(h: Hash): Hash {.inline, noSideEffect.} =
  ## finishes the computation of the hash value. This is
  ## only needed if you need to implement a hash proc for a new datatype.
  result = h +% h shl 3
  result = result xor (result shr 11)
  result = result +% result shl 15

template read_u8(p: ByteAddress): untyped =
  (cast[ptr uint8](p)[])

template read_u16(p: ByteAddress): untyped =
  (cast[ptr uint16](p)[])

template read_u32(p: ByteAddress): untyped =
  (cast[ptr uint32](p)[])

template read_u64(p: ByteAddress): untyped =
  (cast[ptr uint64](p)[])

template rotate_right(value: uint32; amount: uint): uint32 =
  ((value shr amount) or (value shl (32 - amount)))

template rotate_right(value: uint64; amount: uint): uint64 =
  ((value shr amount) or (value shl (64 - amount)))

template `^=`(x: var uint32, y: uint32): untyped =
  x = x xor y

template `^=`(x: var uint64, y: uint64): untyped =
  x = x xor y

when sizeof(Hash) > 4:
  # This is a Nim port of C++ implementation the MetroHash
  # https://github.com/jandrewrogers/MetroHash
  # Copyright (c) 2015 J. Andrew Rogers
  proc hashData*(data: pointer, size: int, seed: Hash = 0): Hash {.noSideEffect.} =
    ## hashes an array of bytes of size `size`
    const 
      k0 = 0xD6D018F5'u64
      k1 = 0xA2AA033B'u64
      k2 = 0x62992FC1'u64
      k3 = 0x30BC5B29'u64

    var 
      p = cast[ByteAddress](data)
      e = p + size
      hash: uint64 = (seed.uint64 + k2) * k0

    if size >= 32:
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

    result = cast[Hash](hash)
else:
  proc hashData*(data: pointer, size: int, seed: Hash = 0): Hash {.noSideEffect.} =
    ## hashes an array of bytes of size `size`
    const 
      k0 = 0xD6D018F5'u32
      k1 = 0xA2AA033B'u32
      k2 = 0x62992FC1'u32
      k3 = 0x30BC5B29'u32

    var 
      p = cast[ByteAddress](data)
      e = p + size
      hash: uint32 = (seed.uint32 + k2) * k0

    if size >= 16:
      var
        v0 = hash
        v1 = hash
        v2 = hash
        v3 = hash

      while p < (e - 16):
        v0 += read_u32(p) * k0
        v0 = rotate_right(v0, 29) + v2
        p += 4

        v1 += read_u32(p) * k1
        v1 = rotate_right(v1, 29) + v3
        p += 4

        v2 += read_u32(p) * k2
        v2 = rotate_right(v2, 29) + v0
        p += 4

        v3 += read_u32(p) * k3
        p += 4
        v3 = rotate_right(v3, 29) + v1

      v2 ^= rotate_right(((v0 + v3) * k0) + v1, 37) * k1
      v3 ^= rotate_right(((v1 + v2) * k1) + v0, 37) * k0
      v0 ^= rotate_right(((v0 + v2) * k0) + v3, 37) * k1
      v1 ^= rotate_right(((v1 + v3) * k1) + v2, 37) * k0
      hash += (v0 xor v1)

    if (e - p) >= 8:
      var
        v0: uint32
        v1: uint32

      v0 = hash + read_u32(p) * k2
      v0 = rotate_right(v0, 29) * k3
      p += 4

      v1 = hash + read_u32(p) * k2
      v1 = rotate_right(v1, 29) * k3
      p += 4

      v0 ^= rotate_right(v0 * k0, 21) + v1
      v1 ^= rotate_right(v1 * k3, 21) + v0
      hash += v1

    if (e - p) >= 4:
      hash += cast[uint32](read_u32(p)) * k3
      hash ^= rotate_right(hash, 26) * k1
      p += 4

    if (e - p) >= 2:
      hash += cast[uint32](read_u16(p)) * k3
      hash ^= rotate_right(hash, 48) * k1
      p += 2

    if (e - p) >= 1:
      hash += cast[uint32](read_u8(p)) * k3
      hash ^= rotate_right(hash, 37) * k1

    hash ^= rotate_right(hash, 28)
    hash *= k0
    hash ^= rotate_right(hash, 29)

    result = cast[Hash](hash)

when defined(js):
  var objectID = 0

proc hash*(x: pointer): Hash {.inline, noSideEffect.} =
  ## efficient hashing of pointers
  when defined(js):
    asm """
      if (typeof `x` == "object") {
        if ("_NimID" in `x`)
          `result` = `x`["_NimID"];
        else {
          `result` = ++`objectID`;
          `x`["_NimID"] = `result`;
        }
      }
    """
  else:
    result = (cast[Hash](x)) shr 3 # skip the alignment

when not defined(booting):
  proc hash*[T: proc](x: T): Hash {.inline, noSideEffect.} =
    ## efficient hashing of proc vars; closures are supported too.
    when T is "closure":
      result = hash(rawProc(x)) !& hash(rawEnv(x))
    else:
      result = hash(pointer(x))

proc hash*(x: int): Hash {.inline, noSideEffect.} =
  ## efficient hashing of integers
  result = x

proc hash*(x: int64): Hash {.inline, noSideEffect.} =
  ## efficient hashing of int64 integers
  when sizeof(Hash) == sizeof(int64):
    result = cast[Hash](x)
  else:
    result = toU32(x)

proc hash*(x: uint): Hash {.inline, noSideEffect.} =
  ## efficient hashing of unsigned integers
  result = cast[Hash](x)

proc hash*(x: uint64): Hash {.inline, noSideEffect.} =
  ## efficient hashing of uint64 integers
  when sizeof(Hash) == sizeof(uint64):
    result = cast[Hash](x)
  else:
    result = toU32(cast[int](x))

proc hash*(x: char): Hash {.inline, noSideEffect.} =
  ## efficient hashing of characters
  result = ord(x)

proc hash*[T: Ordinal](x: T): Hash {.inline, noSideEffect.} =
  ## efficient hashing of other ordinal types (e.g., enums)
  result = ord(x)

proc hash*(x: string): Hash {.noSideEffect.} =
  ## efficient hashing of strings
  result = hashData(unsafeAddr(x[0]), x.len)

proc hash*(x: cstring): Hash {.noSideEffect.} =
  ## efficient hashing of null-terminated strings
  result = hashData(cast[pointer](x), x.len)

proc hash*(sBuf: string, sPos, ePos: int): Hash {.noSideEffect.} =
  ## efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos`
  ##
  ## ``hash(myStr, 0, myStr.high)`` is equivalent to ``hash(myStr)``
  result = hashData(unsafeAddr(sBuf[sPos]), ePos - sPos + 1)

proc hashIgnoreStyle*(x: string): Hash =
  ## efficient hashing of strings; style is ignored
  var h: Hash = 0
  var i = 0
  let xLen = x.len
  while i < xLen:
    var c = x[i]
    if c == '_':
      inc(i)
    else:
      if c in {'A'..'Z'}:
        c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(i)

  result = !$h

proc hashIgnoreStyle*(sBuf: string, sPos, ePos: int): Hash =
  ## efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos`; style is ignored
  ##
  ## ``hashIgnoreStyle(myBuf, 0, myBuf.high)`` is equivalent
  ## to ``hashIgnoreStyle(myBuf)``
  var h: Hash = 0
  var i = sPos
  while i <= ePos:
    var c = sBuf[i]
    if c == '_':
      inc(i)
    else:
      if c in {'A'..'Z'}:
        c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(i)
  result = !$h

proc hashIgnoreCase*(x: string): Hash =
  ## efficient hashing of strings; case is ignored
  var h: Hash = 0
  for i in 0..x.len-1:
    var c = x[i]
    if c in {'A'..'Z'}:
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h

proc hashIgnoreCase*(sBuf: string, sPos, ePos: int): Hash =
  ## efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos`; case is ignored
  ##
  ## ``hashIgnoreCase(myBuf, 0, myBuf.high)`` is equivalent
  ## to ``hashIgnoreCase(myBuf)``
  var h: Hash = 0
  for i in sPos..ePos:
    var c = sBuf[i]
    if c in {'A'..'Z'}:
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h

proc hash*(x: float): Hash {.inline, noSideEffect.} =
  ## efficient hashing of floats.
  var y = x + 1.0
  result = cast[ptr Hash](addr(y))[]

proc hash*[T: tuple](x: T): Hash {.noSideEffect.} =
  ## efficient hashing of tuples.
  result = hashData(unsafeAddr(x), x.sizeof)

proc hash*[A](x: openArray[A]): Hash {.noSideEffect.} =
  ## efficient hashing of arrays and sequences.
  result = hashData(unsafeAddr(x[0]), x.len * A.sizeof)

proc hash*[A](aBuf: openArray[A], sPos, ePos: int): Hash {.noSideEffect.} =
  ## efficient hashing of portions of arrays and sequences.
  ##
  ## ``hash(myBuf, 0, myBuf.high)`` is equivalent to ``hash(myBuf)``
  result = hashData(unsafeAddr(aBuf[sPos]), (ePos - sPos + 1) * A.sizeof)

proc hash*[A](x: set[A]): Hash {.noSideEffect.} =
  ## efficient hashing of sets.
  result = hashData(unsafeAddr(x), x.sizeof)

when isMainModule:
  doAssert( hash("aa bb aaaa1234") == hash("aa bb aaaa1234", 0, 13) )
  doAssert( hash("aa bb aaaa1234") == hash(cstring("aa bb aaaa1234")) )
  doAssert( hashIgnoreCase("aa bb aaaa1234") == hash("aa bb aaaa1234") )
  doAssert( hashIgnoreCase("aa bb aaaa1234") == hashIgnoreCase("aa bb aaaa1234", 0, 13) )
  doAssert( hashIgnoreStyle("aa bb aaaa1234") == hashIgnoreCase("aa bb aaaa1234") )
  doAssert( hashIgnoreStyle("aa bb aaaa1234") == hashIgnoreStyle("aa bb aaaa1234", 0, 13) )
  let xx = @['H','e','l','l','o']
  let ss = "Hello"
  doAssert( hash(xx) == hash(ss) )
  doAssert( hash(xx) == hash(xx, 0, xx.high) )
  doAssert( hash(ss) == hash(ss, 0, ss.high) )
  doAssert( hash(xx, 2, 3) == hash(ss, 2, 3) )
