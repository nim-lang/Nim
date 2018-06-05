#
#
#           The Nim Compiler
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Note: Import ``std/sha1`` to use this module

import strutils

const Sha1DigestSize = 20

type
  Sha1Digest = array[0 .. Sha1DigestSize-1, uint8]
  SecureHash* = distinct Sha1Digest

# Copyright (c) 2011, Micael Hildenborg
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# * Neither the name of Micael Hildenborg nor the
#   names of its contributors may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY Micael Hildenborg ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Micael Hildenborg BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Ported to Nim by Erik O'Leary

type
  Sha1State* = array[0 .. 5-1, uint32]
  Sha1Buffer = array[0 .. 80-1, uint32]

template clearBuffer(w: Sha1Buffer, len = 16) =
  zeroMem(addr(w), len * sizeof(uint32))

proc init*(result: var Sha1State) =
  result[0] = 0x67452301'u32
  result[1] = 0xefcdab89'u32
  result[2] = 0x98badcfe'u32
  result[3] = 0x10325476'u32
  result[4] = 0xc3d2e1f0'u32

proc innerHash(state: var Sha1State, w: var Sha1Buffer) =
  var
    a = state[0]
    b = state[1]
    c = state[2]
    d = state[3]
    e = state[4]

  var round = 0

  template rot(value, bits: uint32): uint32 =
    (value shl bits) or (value shr (32u32 - bits))

  template sha1(fun, val: uint32) =
    let t = rot(a, 5) + fun + e + val + w[round]
    e = d
    d = c
    c = rot(b, 30)
    b = a
    a = t

  template process(body: untyped) =
    w[round] = rot(w[round - 3] xor w[round - 8] xor w[round - 14] xor w[round - 16], 1)
    body
    inc(round)

  template wrap(dest, value: untyped) =
    let v = dest + value
    dest = v

  while round < 16:
    sha1((b and c) or (not b and d), 0x5a827999'u32)
    inc(round)

  while round < 20:
    process:
      sha1((b and c) or (not b and d), 0x5a827999'u32)

  while round < 40:
    process:
      sha1(b xor c xor d, 0x6ed9eba1'u32)

  while round < 60:
    process:
      sha1((b and c) or (b and d) or (c and d), 0x8f1bbcdc'u32)

  while round < 80:
    process:
      sha1(b xor c xor d, 0xca62c1d6'u32)

  wrap state[0], a
  wrap state[1], b
  wrap state[2], c
  wrap state[3], d
  wrap state[4], e

proc sha1(src: cstring; len: int): Sha1Digest =
  #Initialize state
  var state: Sha1State
  init(state)

  #Create w buffer
  var w: Sha1Buffer

  #Loop through all complete 64byte blocks.
  let byteLen = len
  let endOfFullBlocks = byteLen - 64
  var endCurrentBlock = 0
  var currentBlock = 0

  while currentBlock <= endOfFullBlocks:
    endCurrentBlock = currentBlock + 64

    var i = 0
    while currentBlock < endCurrentBlock:
      w[i] = uint32(src[currentBlock+3]) or
             uint32(src[currentBlock+2]) shl 8'u32 or
             uint32(src[currentBlock+1]) shl 16'u32 or
             uint32(src[currentBlock])   shl 24'u32
      currentBlock += 4
      inc(i)

    innerHash(state, w)

  #Handle last and not full 64 byte block if existing
  endCurrentBlock = byteLen - currentBlock
  clearBuffer(w)
  var lastBlockBytes = 0

  while lastBlockBytes < endCurrentBlock:

    var value = uint32(src[lastBlockBytes + currentBlock]) shl
                ((3'u32 - uint32(lastBlockBytes and 3)) shl 3)

    w[lastBlockBytes shr 2] = w[lastBlockBytes shr 2] or value
    inc(lastBlockBytes)

  w[lastBlockBytes shr 2] = w[lastBlockBytes shr 2] or (
    0x80'u32 shl ((3'u32 - uint32(lastBlockBytes and 3)) shl 3)
  )

  if endCurrentBlock >= 56:
    innerHash(state, w)
    clearBuffer(w)

  w[15] = uint32(byteLen) shl 3
  innerHash(state, w)

  # Store hash in result pointer, and make sure we get in in the correct order
  # on both endian models.
  for i in 0 .. Sha1DigestSize-1:
    result[i] = uint8((int(state[i shr 2]) shr ((3-(i and 3)) * 8)) and 255)

proc sha1(src: string): Sha1Digest =
  ## Calculate SHA1 from input string
  sha1(src, src.len)

proc secureHash*(str: string): SecureHash = SecureHash(sha1(str))
proc secureHashFile*(filename: string): SecureHash = secureHash(readFile(filename))
proc `$`*(self: SecureHash): string =
  result = ""
  for v in Sha1Digest(self):
    result.add(toHex(int(v), 2))

proc parseSecureHash*(hash: string): SecureHash =
  for i in 0 ..< Sha1DigestSize:
    Sha1Digest(result)[i] = uint8(parseHexInt(hash[i*2] & hash[i*2 + 1]))

proc `==`*(a, b: SecureHash): bool =
  # Not a constant-time comparison, but that's acceptable in this context
  Sha1Digest(a) == Sha1Digest(b)


when isMainModule:
  let hash1 = secureHash("a93tgj0p34jagp9[agjp98ajrhp9aej]")
  doAssert hash1 == hash1
  doAssert parseSecureHash($hash1) == hash1
