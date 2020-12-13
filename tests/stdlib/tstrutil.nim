# test the new strutils module

import
  strutils

template rejectParse(e) =
  try:
    discard e
    raise newException(AssertionDefect, "This was supposed to fail: $#!" % astToStr(e))
  except ValueError: discard

proc testStrip() =
  doAssert strip("  ha  ") == "ha"

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
  var ret: seq[string] # or use `toSeq`
  for p in split("/home/a1:xyz:/usr/bin", {':'}): ret.add p
  doAssert ret == @["/home/a1", "xyz", "/usr/bin"]

proc testDelete =
  var s = "0123456789ABCDEFGH"
  delete(s, 4, 5)
  assert s == "01236789ABCDEFGH"
  delete(s, s.len-1, s.len-1)
  assert s == "01236789ABCDEFG"
  delete(s, 0, 0)
  assert s == "1236789ABCDEFG"

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
  assert "0123456789ABCDEFGAH".rfind('A', last=13) == 10
  assert "0123456789ABCDEFGAH".rfind('H', last=13) == -1
  assert "0123456789ABCDEFGAH".rfind("A") == 17
  assert "0123456789ABCDEFGAH".rfind("A", last=13) == 10
  assert "0123456789ABCDEFGAH".rfind("H", last=13) == -1
  assert "0123456789ABCDEFGAH".rfind({'A'..'C'}) == 17
  assert "0123456789ABCDEFGAH".rfind({'A'..'C'}, last=13) == 12
  assert "0123456789ABCDEFGAH".rfind({'G'..'H'}, last=13) == -1
  assert "0123456789ABCDEFGAH".rfind('A', start=18) == -1
  assert "0123456789ABCDEFGAH".rfind('A', start=11, last=17) == 17
  assert "0123456789ABCDEFGAH".rfind("0", start=0) == 0
  assert "0123456789ABCDEFGAH".rfind("0", start=1) == -1
  assert "0123456789ABCDEFGAH".rfind("H", start=11) == 18
  assert "0123456789ABCDEFGAH".rfind({'0'..'9'}, start=5) == 9
  assert "0123456789ABCDEFGAH".rfind({'0'..'9'}, start=10) == -1

proc testTrimZeros() =
  var x = "1200"
  x.trimZeros()
  assert x == "1200"
  x = "120.0"
  x.trimZeros()
  assert x == "120"
  x = "0."
  x.trimZeros()
  assert x == "0"
  x = "1.0e2"
  x.trimZeros()
  assert x == "1e2"
  x = "78.90"
  x.trimZeros()
  assert x == "78.9"
  x = "1.23e4"
  x.trimZeros()
  assert x == "1.23e4"
  x = "1.01"
  x.trimZeros()
  assert x == "1.01"
  x = "1.1001"
  x.trimZeros()
  assert x == "1.1001"
  x = "0.0"
  x.trimZeros()
  assert x == "0"
  x = "0.01"
  x.trimZeros()
  assert x == "0.01"
  x = "1e0"
  x.trimZeros()
  assert x == "1e0"

proc testSplitLines() =
  let fixture = "a\nb\rc\r\nd"
  assert len(fixture.splitLines) == 4
  assert splitLines(fixture) == @["a", "b", "c", "d"]
  assert splitLines(fixture, keepEol=true) == @["a\n", "b\r", "c\r\n", "d"]

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
testTrimZeros()
testSplitLines()
testCountLines()
testParseInts()

assert(insertSep($1000_000) == "1_000_000")
assert(insertSep($232) == "232")
assert(insertSep($12345, ',') == "12,345")
assert(insertSep($0) == "0")

assert "/1/2/3".rfind('/') == 4
assert "/1/2/3".rfind('/', last=1) == 0
assert "/1/2/3".rfind('0') == -1

assert(toHex(100i16, 32) == "00000000000000000000000000000064")
assert(toHex(-100i16, 32) == "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9C")

assert(toHex(high(uint64)) == "FFFFFFFFFFFFFFFF")
assert(toHex(high(uint64), 16) == "FFFFFFFFFFFFFFFF")
assert(toHex(high(uint64), 32) == "0000000000000000FFFFFFFFFFFFFFFF")

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

assert(' '.repeat(8) == "        ")
assert(" ".repeat(8) == "        ")
assert(spaces(8) == "        ")

assert(' '.repeat(0) == "")
assert(" ".repeat(0) == "")
assert(spaces(0) == "")

# bug #11369

var num: int64 = -1
assert num.toBin(64) == "1111111111111111111111111111111111111111111111111111111111111111"
assert num.toOct(24) == "001777777777777777777777"


# bug #8911
when true:
  static:
    let a = ""
    let a2 = a.replace("\n", "\\n")

when true:
  static:
    let b = "b"
    let b2 = b.replace("\n", "\\n")

when true:
  let c = ""
  let c2 = c.replace("\n", "\\n")

main()
#OUT ha/home/a1xyz/usr/bin


# `parseEnum`, ref issue #14030
# check enum defined at top level
type
  Foo = enum
    A = -10
    B = "bb"
    C = (-5, "ccc")
    D = 15
    E = "ee" # check that we count enum fields correctly

block:
  let a = parseEnum[Foo]("A")
  let b = parseEnum[Foo]("bb")
  let c = parseEnum[Foo]("ccc")
  let d = parseEnum[Foo]("D")
  let e = parseEnum[Foo]("ee")
  doAssert a == A
  doAssert b == B
  doAssert c == C
  doAssert d == D
  doAssert e == E
  try:
    let f = parseEnum[Foo]("Bar")
    doAssert false
  except ValueError:
    discard

  # finally using default
  let g = parseEnum[Foo]("Bar", A)
  doAssert g == A

block:
  # check enum defined in block
  type
    Bar = enum
      V
      W = "ww"
      X = (3, "xx")
      Y = 10
      Z = "zz" # check that we count enum fields correctly

  let a = parseEnum[Bar]("V")
  let b = parseEnum[Bar]("ww")
  let c = parseEnum[Bar]("xx")
  let d = parseEnum[Bar]("Y")
  let e = parseEnum[Bar]("zz")
  doAssert a == V
  doAssert b == W
  doAssert c == X
  doAssert d == Y
  doAssert e == Z
  try:
    let f = parseEnum[Bar]("Baz")
    doAssert false
  except ValueError:
    discard

  # finally using default
  let g = parseEnum[Bar]("Baz", V)
  doAssert g == V

block:
  # check ambiguous enum fails to parse
  type
    Ambig = enum
      f1 = "A"
      f2 = "B"
      f3 = "A"

  doAssert not compiles((let a = parseEnum[Ambig]("A")))

block:
  # check almost ambiguous enum
  type
    AlmostAmbig = enum
      f1 = "someA"
      f2 = "someB"
      f3 = "SomeA"

  let a = parseEnum[AlmostAmbig]("someA")
  let b = parseEnum[AlmostAmbig]("someB")
  let c = parseEnum[AlmostAmbig]("SomeA")
  doAssert a == f1
  doAssert b == f2
  doAssert c == f3

block:
  assert 0 == indentation """
hey
  low
    there
"""
  assert 2 == indentation """
  hey
    low
      there
"""
  assert 2 == indentation """  hey
    low
      there
"""
  assert 2 == indentation """  hey
    low
      there"""
  assert 0 == indentation ""
  assert 0 == indentation "  \n  \n"
  assert 0 == indentation "    "


block:
  proc nonStaticTests =
    doAssert formatBiggestFloat(1234.567, ffDecimal, -1) == "1234.567000"
    when not defined(js):
      doAssert formatBiggestFloat(1234.567, ffDecimal, 0) == "1235." # bugs 8242, 12586
    doAssert formatBiggestFloat(1234.567, ffDecimal, 1) == "1234.6"
    doAssert formatBiggestFloat(0.00000000001, ffDecimal, 11) == "0.00000000001"
    doAssert formatBiggestFloat(0.00000000001, ffScientific, 1, ',') in
                                                      ["1,0e-11", "1,0e-011"]
    # bug #6589
    when not defined(js):
      doAssert formatFloat(123.456, ffScientific, precision = -1) == "1.234560e+02"

    doAssert "$# $3 $# $#" % ["a", "b", "c"] == "a c b c"
    doAssert "${1}12 ${-1}$2" % ["a", "b"] == "a12 bb"

    block: # formatSize tests
      when not defined(js):
        doAssert formatSize((1'i64 shl 31) + (300'i64 shl 20)) == "2.293GiB" # <=== bug #8231
      doAssert formatSize((2.234*1024*1024).int) == "2.234MiB"
      doAssert formatSize(4096) == "4KiB"
      doAssert formatSize(4096, prefix = bpColloquial, includeSpace = true) == "4 kB"
      doAssert formatSize(4096, includeSpace = true) == "4 KiB"
      doAssert formatSize(5_378_934, prefix = bpColloquial, decimalSep = ',') == "5,13MB"

    block: # formatEng tests
      doAssert formatEng(0, 2, trim = false) == "0.00"
      doAssert formatEng(0, 2) == "0"
      doAssert formatEng(53, 2, trim = false) == "53.00"
      doAssert formatEng(0.053, 2, trim = false) == "53.00e-3"
      doAssert formatEng(0.053, 4, trim = false) == "53.0000e-3"
      doAssert formatEng(0.053, 4, trim = true) == "53e-3"
      doAssert formatEng(0.053, 0) == "53e-3"
      doAssert formatEng(52731234) == "52.731234e6"
      doAssert formatEng(-52731234) == "-52.731234e6"
      doAssert formatEng(52731234, 1) == "52.7e6"
      doAssert formatEng(-52731234, 1) == "-52.7e6"
      doAssert formatEng(52731234, 1, decimalSep = ',') == "52,7e6"
      doAssert formatEng(-52731234, 1, decimalSep = ',') == "-52,7e6"

      doAssert formatEng(4100, siPrefix = true, unit = "V") == "4.1 kV"
      doAssert formatEng(4.1, siPrefix = true, unit = "V",
          useUnitSpace = true) == "4.1 V"
      doAssert formatEng(4.1, siPrefix = true) == "4.1" # Note lack of space
      doAssert formatEng(4100, siPrefix = true) == "4.1 k"
      doAssert formatEng(4.1, siPrefix = true, unit = "",
          useUnitSpace = true) == "4.1 " # Includes space
      doAssert formatEng(4100, siPrefix = true, unit = "") == "4.1 k"
      doAssert formatEng(4100) == "4.1e3"
      doAssert formatEng(4100, unit = "V", useUnitSpace = true) == "4.1e3 V"
      doAssert formatEng(4100, unit = "", useUnitSpace = true) == "4.1e3 "
      # Don't use SI prefix as number is too big
      doAssert formatEng(3.1e22, siPrefix = true, unit = "a",
          useUnitSpace = true) == "31e21 a"
      # Don't use SI prefix as number is too small
      doAssert formatEng(3.1e-25, siPrefix = true, unit = "A",
          useUnitSpace = true) == "310e-27 A"

  proc staticTests =
    doAssert align("abc", 4) == " abc"
    doAssert align("a", 0) == "a"
    doAssert align("1232", 6) == "  1232"
    doAssert align("1232", 6, '#') == "##1232"

    doAssert alignLeft("abc", 4) == "abc "
    doAssert alignLeft("a", 0) == "a"
    doAssert alignLeft("1232", 6) == "1232  "
    doAssert alignLeft("1232", 6, '#') == "1232##"

    doAssert "$animal eats $food." % ["animal", "The cat", "food", "fish"] ==
             "The cat eats fish."

    doAssert "-ld a-ldz -ld".replaceWord("-ld") == " a-ldz "
    doAssert "-lda-ldz -ld abc".replaceWord("-ld") == "-lda-ldz  abc"

    doAssert "-lda-ldz -ld abc".replaceWord("") == "-lda-ldz -ld abc"
    doAssert "oo".replace("", "abc") == "oo"

    type MyEnum = enum enA, enB, enC, enuD, enE
    doAssert parseEnum[MyEnum]("enu_D") == enuD

    doAssert parseEnum("invalid enum value", enC) == enC

    doAssert center("foo", 13) == "     foo     "
    doAssert center("foo", 0) == "foo"
    doAssert center("foo", 3, fillChar = 'a') == "foo"
    doAssert center("foo", 10, fillChar = '\t') == "\t\t\tfoo\t\t\t\t"

    doAssert count("foofoofoo", "foofoo") == 1
    doAssert count("foofoofoo", "foofoo", overlapping = true) == 2
    doAssert count("foofoofoo", 'f') == 3
    doAssert count("foofoofoobar", {'f', 'b'}) == 4

    doAssert strip("  foofoofoo  ") == "foofoofoo"
    doAssert strip("sfoofoofoos", chars = {'s'}) == "foofoofoo"
    doAssert strip("barfoofoofoobar", chars = {'b', 'a', 'r'}) == "foofoofoo"
    doAssert strip("stripme but don't strip this stripme",
                   chars = {'s', 't', 'r', 'i', 'p', 'm', 'e'}) ==
                   " but don't strip this "
    doAssert strip("sfoofoofoos", leading = false, chars = {'s'}) == "sfoofoofoo"
    doAssert strip("sfoofoofoos", trailing = false, chars = {'s'}) == "foofoofoos"

    doAssert "  foo\n  bar".indent(4, "Q") == "QQQQ  foo\nQQQQ  bar"

    doAssert "abba".multiReplace(("a", "b"), ("b", "a")) == "baab"
    doAssert "Hello World.".multiReplace(("ello", "ELLO"), ("World.",
        "PEOPLE!")) == "HELLO PEOPLE!"
    doAssert "aaaa".multiReplace(("a", "aa"), ("aa", "bb")) == "aaaaaaaa"

    doAssert isAlphaAscii('r')
    doAssert isAlphaAscii('A')
    doAssert(not isAlphaAscii('$'))

    doAssert isAlphaNumeric('3')
    doAssert isAlphaNumeric('R')
    doAssert(not isAlphaNumeric('!'))

    doAssert isDigit('3')
    doAssert(not isDigit('a'))
    doAssert(not isDigit('%'))

    doAssert isSpaceAscii('\t')
    doAssert isSpaceAscii('\l')
    doAssert(not isSpaceAscii('A'))

    doAssert(isEmptyOrWhitespace(""))
    doAssert(isEmptyOrWhitespace("       "))
    doAssert(isEmptyOrWhitespace("\t\l \v\r\f"))
    doAssert(not isEmptyOrWhitespace("ABc   \td"))

    doAssert isLowerAscii('a')
    doAssert isLowerAscii('z')
    doAssert(not isLowerAscii('A'))
    doAssert(not isLowerAscii('5'))
    doAssert(not isLowerAscii('&'))
    doAssert(not isLowerAscii(' '))

    doAssert isUpperAscii('A')
    doAssert(not isUpperAscii('b'))
    doAssert(not isUpperAscii('5'))
    doAssert(not isUpperAscii('%'))

    doAssert rsplit("foo bar", seps = Whitespace) == @["foo", "bar"]
    doAssert rsplit(" foo bar", seps = Whitespace, maxsplit = 1) == @[" foo", "bar"]
    doAssert rsplit(" foo bar ", seps = Whitespace, maxsplit = 1) == @[
        " foo bar", ""]
    doAssert rsplit(":foo:bar", sep = ':') == @["", "foo", "bar"]
    doAssert rsplit(":foo:bar", sep = ':', maxsplit = 2) == @["", "foo", "bar"]
    doAssert rsplit(":foo:bar", sep = ':', maxsplit = 3) == @["", "foo", "bar"]
    doAssert rsplit("foothebar", sep = "the") == @["foo", "bar"]

    doAssert(unescape(r"\x013", "", "") == "\x013")

    doAssert join(["foo", "bar", "baz"]) == "foobarbaz"
    doAssert join(@["foo", "bar", "baz"], ", ") == "foo, bar, baz"
    doAssert join([1, 2, 3]) == "123"
    doAssert join(@[1, 2, 3], ", ") == "1, 2, 3"

    doAssert """~~!!foo
~~!!bar
~~!!baz""".unindent(2, "~~!!") == "foo\nbar\nbaz"

    doAssert """~~!!foo
~~!!bar
~~!!baz""".unindent(2, "~~!!aa") == "~~!!foo\n~~!!bar\n~~!!baz"
    doAssert """~~foo
~~  bar
~~  baz""".unindent(4, "~") == "foo\n  bar\n  baz"
    doAssert """foo
bar
    baz
  """.unindent(4) == "foo\nbar\nbaz\n"
    doAssert """foo
    bar
    baz
  """.unindent(2) == "foo\n  bar\n  baz\n"
    doAssert """foo
    bar
    baz
  """.unindent(100) == "foo\nbar\nbaz\n"

    doAssert """foo
    foo
    bar
  """.unindent() == "foo\nfoo\nbar\n"

    let s = " this is an example  "
    let s2 = ":this;is;an:example;;"

    doAssert s.split() == @["", "this", "is", "an", "example", "", ""]
    doAssert s2.split(seps = {':', ';'}) == @["", "this", "is", "an", "example",
        "", ""]
    doAssert s.split(maxsplit = 4) == @["", "this", "is", "an", "example  "]
    doAssert s.split(' ', maxsplit = 1) == @["", "this is an example  "]
    doAssert s.split(" ", maxsplit = 4) == @["", "this", "is", "an", "example  "]

    doAssert s.splitWhitespace() == @["this", "is", "an", "example"]
    doAssert s.splitWhitespace(maxsplit = 1) == @["this", "is an example  "]
    doAssert s.splitWhitespace(maxsplit = 2) == @["this", "is", "an example  "]
    doAssert s.splitWhitespace(maxsplit = 3) == @["this", "is", "an", "example  "]
    doAssert s.splitWhitespace(maxsplit = 4) == @["this", "is", "an", "example"]

    block: # startsWith / endsWith char tests
      var s = "abcdef"
      doAssert s.startsWith('a')
      doAssert s.startsWith('b') == false
      doAssert s.endsWith('f')
      doAssert s.endsWith('a') == false
      doAssert s.endsWith('\0') == false

    #echo("strutils tests passed")

  nonStaticTests()
  staticTests()
  static: staticTests()