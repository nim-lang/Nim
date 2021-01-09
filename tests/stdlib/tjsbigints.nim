discard """
  targets: "js"
"""

import std/jsbigints


let big1: JsBigInt = newJsBigInt"2147483647"
let big2: JsBigInt = newJsBigInt"666"
var big3: JsBigInt = newJsBigInt"2"

doAssert big3 == newJsBigInt"2"
doAssert (big3 xor big2) == newJsBigInt"664"
doAssert (big1 mod big2) == newJsBigInt"613"
doAssert -big1 == newJsBigInt"-2147483647"
doAssert big1 div big2 == newJsBigInt"3224449"
doAssert big1 + big2 == newJsBigInt"2147484313"
doAssert big1 - big2 == newJsBigInt"2147482981"
doAssert big1 shl big3 == newJsBigInt"8589934588"
doAssert big1 shr big3 == newJsBigInt"536870911"
doAssert big1 * big2 == newJsBigInt"1430224108902"
doAssert $big1 == "2147483647n"
doAssert big1.toCstring(10) == "2147483647".cstring
doAssert big2 ** big3 == newJsBigInt(443556)
var huge = newJsBigInt"999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
huge.inc
huge = huge + newJsBigInt"-999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
doAssert huge == newJsBigInt"1"
var list: seq[JsBigInt]
for i in newJsBigInt"0" .. newJsBigInt"5":
  doAssert i is JsBigInt
  list.add i
doAssert list == @[newJsBigInt"0", newJsBigInt"1", newJsBigInt"2", newJsBigInt"3", newJsBigInt"4", newJsBigInt"5"]
list = @[]
for i in newJsBigInt"0" ..< newJsBigInt"5":
  doAssert i is JsBigInt
  list.add i
doAssert list == @[newJsBigInt"0", newJsBigInt"1", newJsBigInt"2", newJsBigInt"3", newJsBigInt"4"]
