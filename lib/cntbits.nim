#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


proc population16(a: int): int {.inline.} =
  var x = a
  x = ((x and 0xAAAA) shr 1) + (x and 0x5555)
  x = ((x and 0xCCCC) shr 2) + (x and 0x3333)
  x = ((x and 0xF0F0) shr 4) + (x and 0x0F0F)
  x = ((x and 0xFF00) shr 8) + (x and 0x00FF)
  return x

proc countBits(n: int32): int =
  result = population16(n and 0xffff) + population16(n shr 16)
