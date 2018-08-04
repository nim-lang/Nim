discard """
  file: "tstrutil.nim"
  output: "ha/home/a1xyz/usr/bin"
"""
# test the new strutils module

import
  strutils

import macros

template rejectParse(e) =
  try:
    discard e
    raise newException(AssertionError, "This was supposed to fail: $#!" % astToStr(e))
  except ValueError: discard

proc testStrip() =
  write(stdout, strip("  ha  "))

proc testRemoveSuffix =
  var s = "hello\n\r"
  s.removeSuffix
  assert s == "hello"
  s.removeSuffix
  assert s == "hello"

  s = "hello\n\n"
  s.removeSuffix
  assert s == "hello"

  s = "hello\r"
  s.removeSuffix
  assert s == "hello"

  s = "hello \n there"
  s.removeSuffix
  assert s == "hello \n there"

  s = "hello"
  s.removeSuffix("llo")
  assert s == "he"
  s.removeSuffix('e')
  assert s == "h"

  s = "hellos"
  s.removeSuffix({'s','z'})
  assert s == "hello"
  s.removeSuffix({'l','o'})
  assert s == "he"

  s = "aeiou"
  s.removeSuffix("")
  assert s == "aeiou"

  s = ""
  s.removeSuffix("")
  assert s == ""

  s = "  "
  s.removeSuffix
  assert s == "  "

  s = "  "
  s.removeSuffix("")
  assert s == "  "

  s = "    "
  s.removeSuffix(" ")
  assert s == "   "

  s = "    "
  s.removeSuffix(' ')
  assert s == ""

  # Contrary to Chomp in other languages
  # empty string does not change behaviour
  s = "hello\r\n\r\n"
  s.removeSuffix("")
  assert s == "hello\r\n\r\n"

proc testRemovePrefix =
  var s = "\n\rhello"
  s.removePrefix
  assert s == "hello"
  s.removePrefix
  assert s == "hello"

  s = "\n\nhello"
  s.removePrefix
  assert s == "hello"

  s = "\rhello"
  s.removePrefix
  assert s == "hello"

  s = "hello \n there"
  s.removePrefix
  assert s == "hello \n there"

  s = "hello"
  s.removePrefix("hel")
  assert s == "lo"
  s.removePrefix('l')
  assert s == "o"

  s = "hellos"
  s.removePrefix({'h','e'})
  assert s == "llos"
  s.removePrefix({'l','o'})
  assert s == "s"

  s = "aeiou"
  s.removePrefix("")
  assert s == "aeiou"

  s = ""
  s.removePrefix("")
  assert s == ""

  s = "  "
  s.removePrefix
  assert s == "  "

  s = "  "
  s.removePrefix("")
  assert s == "  "

  s = "    "
  s.removePrefix(" ")
  assert s == "   "

  s = "    "
  s.removePrefix(' ')
  assert s == ""

  # Contrary to Chomp in other languages
  # empty string does not change behaviour
  s = "\r\n\r\nhello"
  s.removePrefix("")
  assert s == "\r\n\r\nhello"

proc main() =
  testStrip()
  testRemoveSuffix()
  testRemovePrefix()
  for p in split("/home/a1:xyz:/usr/bin", {':'}):
    write(stdout, p)

proc testDelete =
  var s = "0123456789ABCDEFGH"
  delete(s, 4, 5)
  assert s == "01236789ABCDEFGH"
  delete(s, s.len-1, s.len-1)
  assert s == "01236789ABCDEFG"
  delete(s, 0, 0)
  assert s == "1236789ABCDEFG"

proc testIsAlphaNumeric =
  assert isAlphaNumeric("abcdABC1234") == true
  assert isAlphaNumeric("a") == true
  assert isAlphaNumeric("abcABC?1234") == false
  assert isAlphaNumeric("abcABC 1234") == false
  assert isAlphaNumeric(".") == false

testIsAlphaNumeric()

proc testIsDigit =
  assert isDigit("1") == true
  assert isDigit("1234") == true
  assert isDigit("abcABC?1234") == false
  assert isDigit(".") == false
  assert isDigit(":") == false

testIsDigit()

proc testFind =
  assert "0123456789ABCDEFGH".find('A') == 10
  assert "0123456789ABCDEFGH".find('A', 5) == 10
  assert "0123456789ABCDEFGH".find('A', 5, 10) == 10
  assert "0123456789ABCDEFGH".find('A', 5, 9) == -1
  assert "0123456789ABCDEFGH".find("A") == 10
  assert "0123456789ABCDEFGH".find("A", 5) == 10
  assert "0123456789ABCDEFGH".find("A", 5, 10) == 10
  assert "0123456789ABCDEFGH".find("A", 5, 9) == -1
  assert "0123456789ABCDEFGH".find({'A'..'C'}) == 10
  assert "0123456789ABCDEFGH".find({'A'..'C'}, 5) == 10
  assert "0123456789ABCDEFGH".find({'A'..'C'}, 5, 10) == 10
  assert "0123456789ABCDEFGH".find({'A'..'C'}, 5, 9) == -1

proc testRFind =
  assert "0123456789ABCDEFGAH".rfind('A') == 17
  assert "0123456789ABCDEFGAH".rfind('A', 13) == 10
  assert "0123456789ABCDEFGAH".rfind('H', 13) == -1
  assert "0123456789ABCDEFGAH".rfind("A") == 17
  assert "0123456789ABCDEFGAH".rfind("A", 13) == 10
  assert "0123456789ABCDEFGAH".rfind("H", 13) == -1
  assert "0123456789ABCDEFGAH".rfind({'A'..'C'}) == 17
  assert "0123456789ABCDEFGAH".rfind({'A'..'C'}, 13) == 12
  assert "0123456789ABCDEFGAH".rfind({'G'..'H'}, 13) == -1

proc testCountLines =
  proc assertCountLines(s: string) = assert s.countLines == s.splitLines.len
  assertCountLines("")
  assertCountLines("\n")
  assertCountLines("\n\n")
  assertCountLines("abc")
  assertCountLines("abc\n123")
  assertCountLines("abc\n123\n")
  assertCountLines("\nabc\n123")
  assertCountLines("\nabc\n123\n")

proc testParseInts =
  # binary
  assert "0b1111".parseBinInt == 15
  assert "0B1111".parseBinInt == 15
  assert "1111".parseBinInt == 15
  assert "1110".parseBinInt == 14
  assert "1_1_1_1".parseBinInt == 15
  assert "0b1_1_1_1".parseBinInt == 15
  rejectParse "".parseBinInt
  rejectParse "_".parseBinInt
  rejectParse "0b".parseBinInt
  rejectParse "0b1234".parseBinInt
  # hex
  assert "0x72".parseHexInt == 114
  assert "0X72".parseHexInt == 114
  assert "#72".parseHexInt == 114
  assert "72".parseHexInt == 114
  assert "FF".parseHexInt == 255
  assert "ff".parseHexInt == 255
  assert "fF".parseHexInt == 255  
  assert "0x7_2".parseHexInt == 114
  rejectParse "".parseHexInt
  rejectParse "_".parseHexInt
  rejectParse "0x".parseHexInt
  rejectParse "0xFFG".parseHexInt
  rejectParse "reject".parseHexInt
  # octal
  assert "0o17".parseOctInt == 15
  assert "0O17".parseOctInt == 15
  assert "17".parseOctInt == 15
  assert "10".parseOctInt == 8
  assert "0o1_0_0".parseOctInt == 64
  rejectParse "".parseOctInt
  rejectParse "_".parseOctInt
  rejectParse "0o".parseOctInt
  rejectParse "9".parseOctInt
  rejectParse "0o9".parseOctInt
  rejectParse "reject".parseOctInt

testDelete()
testFind()
testRFind()
testCountLines()
testParseInts()

assert(insertSep($1000_000) == "1_000_000")
assert(insertSep($232) == "232")
assert(insertSep($12345, ',') == "12,345")
assert(insertSep($0) == "0")

assert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffix") == 0)
assert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffi1") == 1)
assert(editDistance("prefix__hallo_suffix", "prefix__HALLO_suffix") == 5)
assert(editDistance("prefix__hallo_suffix", "prefix__ha_suffix") == 3)
assert(editDistance("prefix__hallo_suffix", "prefix") == 14)
assert(editDistance("prefix__hallo_suffix", "suffix") == 14)
assert(editDistance("prefix__hallo_suffix", "prefix__hao_suffix") == 2)
assert(editDistance("main", "malign") == 2)

assert "/1/2/3".rfind('/') == 4
assert "/1/2/3".rfind('/', 1) == 0
assert "/1/2/3".rfind('0') == -1

assert(toHex(100i16, 32) == "00000000000000000000000000000064")
assert(toHex(-100i16, 32) == "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9C")

assert "".parseHexStr == ""
assert "00Ff80".parseHexStr == "\0\xFF\x80"
try:
  discard "00Ff8".parseHexStr
  assert false, "Should raise ValueError"
except ValueError:
  discard

try:
  discard "0k".parseHexStr
  assert false, "Should raise ValueError"
except ValueError:
  discard

assert "".toHex == ""
assert "\x00\xFF\x80".toHex == "00FF80"
assert "0123456789abcdef".parseHexStr.toHex == "0123456789ABCDEF"

assert(' '.repeat(8)== "        ")
assert(" ".repeat(8) == "        ")
assert(spaces(8) == "        ")

assert(' '.repeat(0) == "")
assert(" ".repeat(0) == "")
assert(spaces(0) == "")

main()
#OUT ha/home/a1xyz/usr/bin
