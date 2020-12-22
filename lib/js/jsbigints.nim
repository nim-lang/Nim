## Arbitrary precision integers.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt
when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsbigints is designed to be used with the JavaScript backend.".}

type JsBigInt* = ref object of JsRoot ## Arbitrary precision integer for JavaScript target.

func newBigInt*(integer: SomeInteger): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  runnableExamples:
    doAssert newBigInt(1234567890) == big"1234567890"

func big*(integer: cstring): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  runnableExamples:
    doAssert big"-1" == big"1" - big"2"

func toLocaleString*(this: JsBigInt): cstring {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toLocaleString*(this: JsBigInt; locales: cstring): cstring {.importjs: "#.$1(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString
  # TODO: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString#Using_options
  runnableExamples:
    doAssert big"2147483647".toLocaleString("EN".cstring) == "2,147,483,647".cstring

func toLocaleString*(this: JsBigInt; locales: openArray[cstring]): cstring {.importjs: "#.$1(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString
  ## When requesting a language that may not be supported, include a fallback language.
  runnableExamples:
    doAssert big"2147483647".toLocaleString(["EN".cstring, "ES".cstring]) == "2,147,483,647".cstring

func toString*(this: JsBigInt; radix: int): cstring {.importjs: "#.$1(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString
  runnableExamples:
    doAssert big"2147483647".toString(2) == "1111111111111111111111111111111".cstring

func toString*(this: JsBigInt): cstring {.importjs: "#.toString()".} # asserted on $
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func `$`*(this: JsBigInt): string =
  ## Return a string representation of `JsBigInt`.
  runnableExamples: doAssert $big"1024" == "1024"
  $toString(this)

func asIntN*(width: int; bigInteger: JsBigInt): int {.importjs: "BigInt.$1(#, #)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asIntN
  runnableExamples:
    doAssert asIntN(32, big"2147483647") == 2147483647.int32

func asUintN*(width: int; bigInteger: JsBigInt): uint {.importjs: "BigInt.$1(#, #)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asUintN
  runnableExamples:
    doAssert asUintN(32, big"2147483647") == 2147483647.uint32

func `+`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    doAssert (big"9" + big"1") == big"10"

func `-`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    doAssert (big"9" - big"1") == big"8"

func `*`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    doAssert (big"42" * big"9") == big"378"

func `div`*(x, y: JsBigInt): JsBigInt {.importjs: "(# / #)".} =
  ## Same as `div` but for `JsBigInt`(uses JavaScript `BigInt() / BigInt()`).
  runnableExamples:
    doAssert (big"512" div big"2") == big"256"
    doAssert (big"4" div big"2") == big"2"
    doAssert (big"42" div big"10") == big"4"
    doAssert (big"420" div big"5") == big"84"
    doAssert (big"100" div big"4") == big"25"

func `mod`*(x, y: JsBigInt): JsBigInt {.importjs: "(# % #)".} =
  ## Same as `mod` but for `JsBigInt` (uses JavaScript `BigInt() % BigInt()`).
  runnableExamples:
    doAssert (big"5" mod big"2") == big"1"
    doAssert (big"421" mod big"5") == big"1"
    doAssert (big"420" mod big"5") == big"0"
    doAssert (big"100" mod big"4") == big"0"

func `<`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".} =
  runnableExamples:
    doAssert big"2" < big"9"

func `<=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".} =
  runnableExamples:
    doAssert big"1" <= big"5"

func `==`*(x, y: JsBigInt): bool {.importjs: "(# === #)".} =
  runnableExamples:
    doAssert big"42" == big"42"

func `**`*(x, y: JsBigInt): JsBigInt {.importjs: "((#) $1 #)".} =
  runnableExamples:
    doAssert (big"9" ** big"5") == big"59049"

func `xor`*(x, y: JsBigInt): JsBigInt {.importjs: "(# ^ #)".} =
  runnableExamples:
    doAssert (big"555" xor big"2") == big"553"

func `shl`*(a, b: JsBigInt): JsBigInt {.importjs: "(# << #)".} =
  runnableExamples:
    doAssert (big"999" shl big"2") == big"3996"

func `shr`*(a, b: JsBigInt): JsBigInt {.importjs: "(# >> #)".} =
  runnableExamples:
    doAssert (big"999" shr big"2") == big"249"

func `-`*(a: JsBigInt): JsBigInt {.importjs: "($1#)".} =
  runnableExamples:
    doAssert -(big"10101010101") == big"-10101010101"

func inc*(a: var JsBigInt; b: JsBigInt) {.importjs: "([#][0][0] += #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    let big2: JsBigInt = big"2"
    inc big1, big2
    doAssert big1 == big"3"

func dec*(a: var JsBigInt; b: JsBigInt) {.importjs: "([#][0][0] -= #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    let big2: JsBigInt = big"2"
    dec big1, big2
    doAssert big1 == big"-1"

func `+=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    let big2: JsBigInt = big"2"
    big1 += big2
    doAssert big1 == big"3"

func `-=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    let big2: JsBigInt = big"2"
    big1 -= big2
    doAssert big1 == big"-1"

func `*=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"2"
    let big2: JsBigInt = big"4"
    big1 *= big2
    doAssert big1 == big"8"

func inc*(x: var JsBigInt) {.importjs: "(++[#][0][0])".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    inc big1
    doAssert big1 == big"2"

func dec*(x: var JsBigInt) {.importjs: "(--[#][0][0])".} =
  runnableExamples:
    var big1: JsBigInt = big"3"
    dec big1
    doAssert big1 == big"2"

func `%=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] %= #)".} =
  runnableExamples:
    var big1: JsBigInt = big"10"
    big1 %= big"2"
    doAssert big1 == big"0"

func `/=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] /= #)".} =
  runnableExamples:
    var big1: JsBigInt = big"10"
    big1 /= big"2"
    doAssert big1 == big"5"

func `+`*(_: JsBigInt): JsBigInt {.error.} # Can not be used by design.
  ## **Do NOT use.** https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs

func low*(_: JsBigInt): JsBigInt {.error.} ## **Do NOT use.**

func high*(_: JsBigInt): JsBigInt {.error.} ## **Do NOT use.**


runnableExamples:
  let big1: JsBigInt = big"2147483647"
  let big2: JsBigInt = big"666"
  var big3: JsBigInt = big"2"
  doAssert big1 != big2
  doAssert big1 > big2
  doAssert big1 >= big2
  doAssert big2 < big1
  doAssert big2 <= big1
  doAssert not(big1 == big2)
  doAssert big3 == big"2"
  doAssert (big3 xor big2) == big"664"
  doAssert (big1 mod big2) == big"613"
  doAssert -big1 == big"-2147483647"
  doAssert big1 div big2 == big"3224449"
  doAssert big1 + big2 == big"2147484313"
  doAssert big1 - big2 == big"2147482981"
  doAssert big1 shl big3 == big"8589934588"
  doAssert big1 shr big3 == big"536870911"
  doAssert big1 * big2 == big"1430224108902"
  doAssert $big1 == "2147483647".cstring
  doAssert big1.toString(10) == "2147483647".cstring
  doAssert big2 ** big3 == newBigInt(443556)
  var huge = big"999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
  huge.inc
  huge += big"-999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
  doAssert huge == big"1"
