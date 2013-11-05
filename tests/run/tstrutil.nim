discard """
  file: "tstrutil.nim"
  output: "ha/home/a1xyz/usr/bin"
"""
# test the new strutils module

import
  strutils

proc testStrip() =
  write(stdout, strip("  ha  "))

proc main() = 
  testStrip()
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

proc testSplit() =
  let s = "something:something:something:something"

  assert(split(s, ':') == @["something", "something", "something", "something"])
  assert(split(s, ';') == @[s])
  assert(split(s, ':', maxSplit=1) == @["something", "something:something:something"])
  assert(split(s, ':', maxSplit=2) == @["something", "something", "something:something"])

  assert(split(";;this;is;an;;example;;;", ';') == @["", "", "this", "is", "an", "", "example", "", "", ""])

proc testPartition() =
  let s = "something:something:something"

  assert(partition(s, ':') == ("something", ":", "something:something"))
  assert(partition(s, ';') == ("something", "", ""))

  assert(split(";;this;is;an;;example;;;", ';') == @["this", "is", "an", "example"])

testDelete()
testSplit()
testPartition()


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

main()
#OUT ha/home/a1xyz/usr/bin


