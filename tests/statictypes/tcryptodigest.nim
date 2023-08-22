discard """
  output: "Digest[128]\nDigest[256]"
"""

import typetraits

type
  Digest[bits: static[int]] = object
    data: array[bits div 8, byte]

  ContextKind = enum
    A, B, C

  HashingContext[bits: static[int], kind: static[ContextKind]] = object
    ctx: array[bits div 8, byte]

  Hash128 = HashingContext[128, A]
  Hash256 = HashingContext[256, B]

  HMAC[HashType] = object
    h: HashType

proc init(c: var HashingContext) = discard
proc update(c: var HashingContext, data: ptr byte, dataLen: uint) = discard
proc finish(c: var HashingContext): Digest[c.bits] = discard

proc digest(T: typedesc, data: ptr byte, dataLen: uint): Digest[T.bits] =
  mixin init, update, finish

  var ctx: T
  ctx.init()
  ctx.update(data, dataLen)
  result = ctx.finish()

var h = Hash128.digest(nil, 0)
echo h.type.name

proc finish(hmac: var HMAC): Digest[HMAC.HashType.bits] =
  discard

var hm: HMAC[Hash256]
var d = hm.finish
echo d.type.name

