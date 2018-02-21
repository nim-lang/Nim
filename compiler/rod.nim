#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import ast, idgen

when not defined(nimSymbolfiles):
  template setupModuleCache* = discard
  template storeNode*(module: PSym; n: PNode) = discard
  template loadNode*(module: PSym; index: var int): PNode = PNode(nil)

  template getModuleId*(fileIdx: int32; fullpath: string): int = getID()

  template addModuleDep*(module, fileIdx: int32; isIncludeFile: bool) = discard

  template storeRemaining*(module: PSym) = discard

else:
  include rodimpl

when false:
  type
    BlobWriter* = object
      buf: string
      pos: int

    SerializationAction = enum acRead, acWrite

  # Varint implementation inspired by SQLite.
  proc rdVaruint64(z: ptr UncheckedArray[byte]; n: int; pResult: var uint64): int =
    if z[0] <= 240:
      pResult = z[0]
      return 1
    if z[0] <= 248:
      if n < 2: return 0
      pResult = (z[0] - 241) * 256 + z[1] + 240
      return 2
    if n < z[0]-246: return 0
    if z[0] == 249:
      pResult = 2288 + 256*z[1] + z[2]
      return 3
    if z[0] == 250:
      pResult = (z[1] shl 16u64) + (z[2] shl 8u64) + z[3]
      return 4
    let x = (z[1] shl 24) + (z[2] shl 16) + (z[3] shl 8) + z[4]
    if z[0] == 251:
      pResult = x
      return 5
    if z[0] == 252:
      pResult = (((uint64)x) shl 8) + z[5]
      return 6
    if z[0] == 253:
      pResult = (((uint64)x) shl 16) + (z[5] shl 8) + z[6]
      return 7
    if z[0] == 254:
      pResult = (((uint64)x) shl 24) + (z[5] shl 16) + (z[6] shl 8) + z[7]
      return 8
    pResult = (((uint64)x) shl 32) +
                (0xffffffff & ((z[5] shl 24) + (z[6] shl 16) + (z[7] shl 8) + z[8]))
    return 9

  proc varintWrite32(z: ptr UncheckedArray[byte]; y: uint32) =
    z[0] = uint8(y shr 24)
    z[1] = uint8(y shr 16)
    z[2] = uint8(y shr 8)
    z[3] = uint8(y)

  proc sqlite4PutVarint64(z: ptr UncheckedArray[byte], x: uint64): int =
    ## Write a varint into z. The buffer z must be at least 9 characters
    ## long to accommodate the largest possible varint. Returns the number of
    ## bytes used.
    if x <= 240:
      z[0] = uint8 x
      return 1
    if x <= 2287:
      y = uint32(x - 240)
      z[0] = uint8(y shr 8 + 241)
      z[1] = uint8(y and 255)
      return 2
    if x <= 67823:
      y = uint32(x - 2288)
      z[0] = 249
      z[1] = uint8(y shr 8)
      z[2] = uint8(y and 255)
      return 3
    let y = uint32 x
    let w = uint32(x shr 32)
    if w == 0:
      if y <= 16777215:
        z[0] = 250
        z[1] = uint8(y shr 16)
        z[2] = uint8(y shr 8)
        z[3] = uint8(y)
        return 4
      z[0] = 251
      varintWrite32(z+1, y)
      return 5
    if w <= 255:
      z[0] = 252
      z[1] = uint8 w
      varintWrite32(z+2, y)
      return 6
    if w <= 65535:
      z[0] = 253
      z[1] = uint8(w shr 8)
      z[2] = uint8 w
      varintWrite32(z+3, y)
      return 7
    if w <= 16777215:
      z[0] = 254
      z[1] = uint8(w shr 16)
      z[2] = uint8(w shr 8)
      z[3] = uint8 w
      varintWrite32(z+4, y)
      return 8
    z[0] = 255
    varintWrite32(z+1, w)
    varintWrite32(z+5, y)
    return 9

  template field(x: BiggestInt; action: SerializationAction) =
    when action == acRead:
      readBiggestInt(x)
    else:
      writeBiggestInt()
