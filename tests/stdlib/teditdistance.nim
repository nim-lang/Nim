import std/editdistance

doAssert editDistance("", "") == 0
doAssert editDistance("kitten", "sitting") == 3 # from Wikipedia
doAssert editDistance("flaw", "lawn") == 2 # from Wikipedia

doAssert editDistance("привет", "превет") == 1
doAssert editDistance("Åge", "Age") == 1
# editDistance, one string is longer in bytes, but shorter in rune length
# first string: 4 bytes, second: 6 bytes, but only 3 runes
doAssert editDistance("aaaa", "×××") == 4

block veryLongStringEditDistanceTest:
  const cap = 256
  var
    s1 = newStringOfCap(cap)
    s2 = newStringOfCap(cap)
  while len(s1) < cap:
    s1.add 'a'
  while len(s2) < cap:
    s2.add 'b'
  doAssert editDistance(s1, s2) == cap

block combiningCodePointsEditDistanceTest:
  const s = "A\xCC\x8Age"
  doAssert editDistance(s, "Age") == 1

doAssert editDistanceAscii("", "") == 0
doAssert editDistanceAscii("kitten", "sitting") == 3 # from Wikipedia
doAssert editDistanceAscii("flaw", "lawn") == 2 # from Wikipedia


doAssert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffix") == 0)
doAssert(editDistance("prefix__hallo_suffix", "prefix__hallo_suffi1") == 1)
doAssert(editDistance("prefix__hallo_suffix", "prefix__HALLO_suffix") == 5)
doAssert(editDistance("prefix__hallo_suffix", "prefix__ha_suffix") == 3)
doAssert(editDistance("prefix__hallo_suffix", "prefix") == 14)
doAssert(editDistance("prefix__hallo_suffix", "suffix") == 14)
doAssert(editDistance("prefix__hallo_suffix", "prefix__hao_suffix") == 2)
doAssert(editDistance("main", "malign") == 2)