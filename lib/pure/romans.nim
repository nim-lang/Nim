#
#
#            Nim's Runtime Library
#        (c) Copyright 2011 Philippe Lhoste
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module for converting an integer to a Roman numeral.
## See http://en.wikipedia.org/wiki/Roman_numerals for reference.

const
  RomanNumeralDigits* = {'I', 'i', 'V', 'v', 'X', 'x', 'L', 'l', 'C', 'c', 
    'D', 'd', 'M', 'm'} ## set of all characters a Roman numeral may consist of

proc romanToDecimal*(romanVal: string): int =
  ## Converts a Roman numeral to its int representation.
  result = 0
  var prevVal = 0
  for i in countdown(romanVal.len - 1, 0):
    var val = 0
    case romanVal[i]
    of 'I', 'i': val = 1
    of 'V', 'v': val = 5
    of 'X', 'x': val = 10
    of 'L', 'l': val = 50
    of 'C', 'c': val = 100
    of 'D', 'd': val = 500
    of 'M', 'm': val = 1000
    else: 
      raise newException(EInvalidValue, "invalid roman numeral: " & $romanVal)
    if val >= prevVal:
      inc(result, val)
    else:
      dec(result, val)
    prevVal = val

proc decimalToRoman*(number: range[1..3_999]): string =
  ## Converts a number to a Roman numeral.
  const romanComposites = [
    ("M", 1000), ("CM", 900),
    ("D", 500), ("CD", 400), ("C", 100),
    ("XC", 90), ("L", 50), ("XL", 40), ("X", 10), ("IX", 9),
    ("V", 5), ("IV", 4), ("I", 1)]
  result = ""
  var decVal = number
  for key, val in items(romanComposites):
    while decVal >= val:
      dec(decVal, val)
      result.add(key)

when isMainModule:
  import math
  randomize()
  for i in 1 .. 100:
    var rnd = 1 + random(3990)
    assert rnd == rnd.decimalToRoman.romanToDecimal

