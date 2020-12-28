## Arbitrary precision integers.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt
when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsbigints is designed to be used with the JavaScript backend.".}

type JsBigInt* = ref object of JsRoot ## Arbitrary precision integer for JavaScript target.

func big*(integer: SomeInteger): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  runnableExamples:
    doAssert big(1234567890) == big"1234567890"

func big*(integer: cstring): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  runnableExamples:
    doAssert big"-1" == big"1" - big"2"

func toCstring*(this: JsBigInt; radix: int): cstring {.importjs: "#.toString(#)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString
  runnableExamples:
    doAssert big"2147483647".toCstring(2) == "1111111111111111111111111111111".cstring

func toCstring*(this: JsBigInt): cstring {.importjs: "#.toString()".} # asserted on $
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func `$`*(this: JsBigInt): string =
  ## Return a string representation of `JsBigInt`.
  runnableExamples: doAssert $big"1024" == "1024"
  $toCstring(this)

func toInt*(bits: int; a: JsBigInt): JsBigInt {.importjs: "BigInt.asIntN(#, #)".} =
  ## Wrap `a` to a signed `JsBigInt` of `bits` bits, ie between `-2 ^ (bits - 1)` and `2 ^ (bits - 1) - 1`.
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asIntN
  runnableExamples:
    doAssert toInt(32, big"2147483647") == big"2147483647"

func toUint*(bits: int; a: JsBigInt): JsBigInt {.importjs: "BigInt.asUintN(#, #)".} =
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asUintN
  runnableExamples:
    doAssert toUint(32, big"2147483647") == big"2147483647"

func toInt*(a: JsBigInt): int {.importjs: "Number(#)".} =
  runnableExamples:
    doAssert toInt(big"2147483647") == 2147483647

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
    doAssert big"13" div big"3" == big"4"
    doAssert big"-13" div big"3" == big"-4"
    doAssert big"13" div big"-3" == big"-4"
    doAssert big"-13" div big"-3" == big"4"

func `mod`*(x, y: JsBigInt): JsBigInt {.importjs: "(# % #)".} =
  ## Same as `mod` but for `JsBigInt` (uses JavaScript `BigInt() % BigInt()`).
  runnableExamples:
    doAssert big"13" mod big"3" == big"1"
    doAssert big"-13" mod big"3" == big"-1"
    doAssert big"13" mod big"-3" == big"1"
    doAssert big"-13" mod big"-3" == big"-1"

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

func inc*(a: var JsBigInt; b = 1) {.importjs: "([#][0][0] += BigInt(#))".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    inc big1, 2
    doAssert big1 == big"3"

func dec*(a: var JsBigInt; b = 1) {.importjs: "([#][0][0] -= BigInt(#))".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    dec big1, 2
    doAssert big1 == big"-1"

func `+=`*(x: var JsBigInt; y: int) {.importjs: "([#][0][0] $1 BigInt(#))".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    big1 += 2
    doAssert big1 == big"3"

func `-=`*(x: var JsBigInt; y: int) {.importjs: "([#][0][0] $1 BigInt(#))".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    big1 -= 2
    doAssert big1 == big"-1"

func `*=`*(x: var JsBigInt; y: int) {.importjs: "([#][0][0] $1 BigInt(#))".} =
  runnableExamples:
    var big1: JsBigInt = big"2"
    big1 *= 4
    doAssert big1 == big"8"

func `/=`*(x: var JsBigInt; y: int) {.importjs: "([#][0][0] /= BigInt(#))".} =
  ## Same as `x = x div y`.
  runnableExamples:
    var big1: JsBigInt = big"11"
    big1 /= 2
    doAssert big1 == big"5"

proc `+`*(_: JsBigInt): JsBigInt {.error.} # Can not be used by design.
  ## **Do NOT use.** https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs

proc low*(_: typedesc[JsBigInt]): JsBigInt {.error.} ## **Do NOT use.**

proc high*(_: typedesc[JsBigInt]): JsBigInt {.error.} ## **Do NOT use.**


runnableExamples:
  let big1: JsBigInt = big"2147483647"
  let big2: JsBigInt = big"666"
  doAssert big1 != big2
  doAssert big1 > big2
  doAssert big1 >= big2
  doAssert big2 < big1
  doAssert big2 <= big1
  doAssert not(big1 == big2)
