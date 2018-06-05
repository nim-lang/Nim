#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a base16 (hexadecimal) encoder and decoder.
##
## Encoding data
## -------------
##
## In order to encode some text simply call the ``encode`` procedure:
##
##   .. code-block::nim
##      import base16
##      let encoded = encode("Hello World")
##      echo(encoded) # 48656c6c6f20576f726c64
##
## The ``encode`` procedure takes an ``openarray`` so both arrays and sequences
## can be passed as parameters.
##
## Decoding data
## -------------
##
## To decode a base16 encoded data string simply call the ``decode``
## procedure:
##
##   .. code-block::nim
##      import base16
##      echo(decode("48656c6c6f20576f726c64")) # Hello World

const
  b16 = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

template encodeInternal(bin: typed; hex: var string) =
  ## encodes `bin` into base16 representation.
  assert(hex.len == bin.len shl 1)
  for i in countup(0, hex.high, 2):
    {.unroll.}
    hex[i+0] = b16[0x0f and (bin[i shr 1].ord shr 4)]
    hex[i+1] = b16[0x0f and (bin[i shr 1].ord)]

proc encode*[T:byte|char](bin: openarray[T]; result: var string) =
  ## encodes `bin` into base16 representation.
  encodeInternal(bin, result)

proc encode*[T:byte|char](bin: openarray[T]): string =
  ## encodes `bin` into base16 representation.
  result = newString(bin.len shl 1)
  encodeInternal(bin, result)

proc encode*(bin: string): string =
  ## encodes `bin` into base16 representation.
  result = newString(bin.len shl 1)
  encodeInternal(bin, result)

proc nibble(c: char): uint8 {.inline.} =
  case c
  of '0'..'9': uint8(c) - uint8('0')
  of 'a'..'f': uint8(c) - uint8('a') + 10
  of 'A'..'F': uint8(c) - uint8('A') + 10
  else:
    raiseAssert("invalid base16 character")
    255

proc decode*[T:byte|char](hex: string; result: var openarray[T]) =
  ##  decodes `hex` into binary form.
  assert((hex.len and 1) == 0 and result.len == (hex.len shr 1))
  for i in 0..result.high:
    {.unroll.}
    result[i] = (T)((hex[(i shl 1)+0].nibble shl 4) or (hex[(i shl 1)+1].nibble))

proc decode*(hex: string): string =
  ##  decodes `hex` into binary form.
  assert((hex.len and 1) == 0)
  result = newString(hex.len shr 1)
  decode(hex, result)

when isMainModule:
  assert encode("leasure.") == "6c6561737572652e"
  assert encode("easure.") == "6561737572652e"
  assert encode("asure.") == "61737572652e"
  assert encode("sure.") == "737572652e"
  assert encode("Hello World") == "48656c6c6f20576f726c64"

  const
    testInputExpandsTo76 = "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    testInputExpands = "++++++++++++++++++++++++++++++"
    shortText = """Do not call up what you cannot put down"""
    longText = """Man is distinguished, not only by his reason, but by this
      singular passion from other animals, which is a lust of the mind,
      that by a perseverance of delight in the continued and indefatigable
      generation of knowledge, exceeds the short vehemence of any carnal
      pleasure."""
    tests = ["", "abc", "xyz", "man", "leasure.", "sure.", "easure.",
                 "asure.", shortText, longText, testInputExpandsTo76, testInputExpands]

  for t in items(tests):
    assert decode(encode(t)) == t
