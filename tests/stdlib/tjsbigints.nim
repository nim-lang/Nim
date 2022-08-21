discard """
  targets: "js"
"""

import std/jsbigints


let big1: JsBigInt = big"2147483647"
let big2: JsBigInt = big"666"
var big3: JsBigInt = big"2"

doAssert big3 == big"2"
doAssert (big3 xor big2) == big"664"
doAssert (big"555" and big"2") == big"2"
doAssert (big"555" or big"2") == big"555"
doAssert (big1 mod big2) == big"613"
doAssert -big1 == big"-2147483647"
doAssert big1 div big2 == big"3224449"
doAssert big1 + big2 == big"2147484313"
doAssert big1 - big2 == big"2147482981"
doAssert big1 shl big3 == big"8589934588"
doAssert big1 shr big3 == big"536870911"
doAssert big1 * big2 == big"1430224108902"
doAssert $big1 == "2147483647n"
doAssert big1.toCstring(10) == "2147483647".cstring
doAssert big2 ** big3 == big(443556)
var huge = big"999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
huge.inc
huge = huge + -999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'big
doAssert huge == big"1"
var list: seq[JsBigInt]
for i in big"0" .. big"5":
  doAssert i is JsBigInt
  list.add i
doAssert list == @[big"0", big"1", big"2", big"3", big"4", big"5"]
list = @[]
for i in big"0" ..< big"5":
  doAssert i is JsBigInt
  list.add i
doAssert list == @[big"0", big"1", big"2", big"3", big"4"]

block:
  let b = 2'big
  doAssert -b ** 3'big == -8'big
  doAssert -b ** big"2" == big"4" # not -4 because of precedence
  doAssert -big"3" == big"-3"
