discard """
  file: "tromans.nim"
  output: "success"
"""
import
  strutils

## Convert an integer to a Roman numeral
# See http://en.wikipedia.org/wiki/Roman_numerals for reference

proc raiseInvalidValue(msg: string) {.noreturn.} =
  # Yes, we really need a shorthand for this code...
  var e: ref EInvalidValue
  new(e)
  e.msg = msg
  raise e

# I should use a class, perhaps.
# --> No. Why introduce additional state into such a simple and nice
# interface? State is evil. :D

proc RomanToDecimal(romanVal: string): int =
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
    else: raiseInvalidValue("Incorrect character in roman numeral! (" & 
                            $romanVal[i] & ")")
    if val >= prevVal:
      inc(result, val)
    else:
      dec(result, val)
    prevVal = val

proc DecimalToRoman(decValParam: int): string =
  # Apparently numbers cannot be above 4000
  # Well, they can be (using overbar or parenthesis notation)
  # but I see little interest (beside coding challenge) in coding them as
  # we rarely use huge Roman numeral.
  const romanComposites = [
    ("M", 1000), ("CM", 900),
    ("D", 500), ("CD", 400), ("C", 100),
    ("XC", 90), ("L", 50), ("XL", 40), ("X", 10), ("IX", 9),
    ("V", 5), ("IV", 4), ("I", 1)]     
  if decValParam < 1 or decValParam > 3999:
    raiseInvalidValue("number not representable")
  result = ""
  var decVal = decValParam
  for key, val in items(romanComposites):
    while decVal >= val:
      dec(decVal, val)
      result.add(key)

for i in 1..100:
  if RomanToDecimal(DecimalToRoman(i)) != i: quit "BUG"

for i in items([1238, 1777, 3830, 2401, 379, 33, 940, 3973]):
  if RomanToDecimal(DecimalToRoman(i)) != i: quit "BUG"
 
echo "success" #OUT success



