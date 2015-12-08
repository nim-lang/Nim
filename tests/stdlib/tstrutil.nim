discard """
  file: "tstrutil.nim"
  output: "ha/home/a1xyz/usr/bin"
"""
# test the new strutils module

import
  strutils

proc testStrip() =
  write(stdout, strip("  ha  "))

proc testRemoveSuffix =
  var s = "hello\n\r"
  s.removeSuffix
  doAssert s == "hello\n"
  s.removeSuffix
  doAssert s == "hello"
  s.removeSuffix
  doAssert s == "hello"

  s = "hello\n\n"
  s.removeSuffix
  doAssert s == "hello\n"

  s = "hello\r"
  s.removeSuffix
  doAssert s == "hello"

  s = "hello \n there"
  s.removeSuffix
  doAssert s == "hello \n there"

  s = "hello"
  s.removeSuffix("llo")
  doAssert s == "he"
  s.removeSuffix('e')
  doAssert s == "h"

  s = "hellos"
  s.removeSuffix({'s','z'})
  doAssert s == "hello"
  s.removeSuffix({'l','o'})
  doAssert s == "hell"

  # Contrary to Chomp in other languages
  # empty string does not change behaviour
  s = "hello\r\n\r\n"
  s.removeSuffix("")
  doAssert s == "hello\r\n\r\n"

proc main() =
  testStrip()
  testRemoveSuffix()
  for p in split("/home/a1:xyz:/usr/bin", {':'}):
    write(stdout, p)

proc testDelete =
  var s = "0123456789ABCDEFGH"
  delete(s, 4, 5)
  doAssert s == "01236789ABCDEFGH"
  delete(s, s.len-1, s.len-1)
  doAssert s == "01236789ABCDEFG"
  delete(s, 0, 0)
  doAssert s == "1236789ABCDEFG"

testDelete()

doAssert(insertSep($1000_000) == "1_000_000")
doAssert(insertSep($232) == "232")
doAssert(insertSep($12345, ',') == "12,345")
doAssert(insertSep($0) == "0")

doAssert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffix") == 0)
doAssert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffi1") == 1)
doAssert(editDistance("prefix__hallo_suffix", "prefix__HALLO_suffix") == 5)
doAssert(editDistance("prefix__hallo_suffix", "prefix__ha_suffix") == 3)
doAssert(editDistance("prefix__hallo_suffix", "prefix") == 14)
doAssert(editDistance("prefix__hallo_suffix", "suffix") == 14)
doAssert(editDistance("prefix__hallo_suffix", "prefix__hao_suffix") == 2)
doAssert(editDistance("main", "malign") == 2)

doAssert "/1/2/3".rfind('/') == 4
doAssert "/1/2/3".rfind('/', 1) == 0
doAssert "/1/2/3".rfind('0') == -1

doAssert(toHex(100i16, 32) == "00000000000000000000000000000064")
doAssert(toHex(-100i16, 32) == "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9C")

doAssert(' '.repeat(8)== "        ")
doAssert(" ".repeat(8) == "        ")
doAssert(spaces(8) == "        ")

doAssert(' '.repeat(0) == "")
doAssert(" ".repeat(0) == "")
doAssert(spaces(0) == "")

main()
#OUT ha/home/a1xyz/usr/bin
