## Arbitrary precision integers.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt
when not defined(js):
  {.fatal: "Module jsbigints is designed to be used with the JavaScript backend.".}

type JsBigIntImpl {.importjs: "bigint".} = int # https://github.com/nim-lang/Nim/pull/16606
type JsBigInt* = distinct JsBigIntImpl         ## Arbitrary precision integer for JavaScript target.

func big*(integer: SomeInteger): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  when nimvm: doAssert false, "JsBigInt can not be used at compile-time nor static context" else: discard
  runnableExamples:
    assert big(1234567890) == big"1234567890"
    assert 0b1111100111.big == 0o1747.big and 0o1747.big == 999.big

func big*(integer: cstring): JsBigInt {.importjs: "BigInt(#)".} =
  ## Constructor for `JsBigInt`.
  when nimvm: doAssert false, "JsBigInt can not be used at compile-time nor static context" else: discard
  runnableExamples:
    assert big"-1" == big"1" - big"2"
    # supports decimal, binary, octal, hex:
    assert big"12" == 12.big
    assert big"0b101" == 0b101.big
    assert big"0o701" == 0o701.big
    assert big"0xdeadbeaf" == 0xdeadbeaf.big
    assert big"0xffffffffffffffff" == (1.big shl 64.big) - 1.big

func toCstring*(this: JsBigInt; radix: 2..36): cstring {.importjs: "#.toString(#)".} =
  ## Converts from `JsBigInt` to `cstring` representation.
  ## * `radix` Base to use for representing numeric values.
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString
  runnableExamples:
    assert big"2147483647".toCstring(2) == "1111111111111111111111111111111".cstring

func toCstring*(this: JsBigInt): cstring {.importjs: "#.toString()".}
  ## Converts from `JsBigInt` to `cstring` representation.
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func `$`*(this: JsBigInt): string =
  ## Returns a `string` representation of `JsBigInt`.
  runnableExamples: assert $big"1024" == "1024n"
  $toCstring(this) & 'n'

func wrapToInt*(this: JsBigInt; bits: Natural): JsBigInt {.importjs:
  "(() => { const i = #, b = #; return BigInt.asIntN(b, i) })()".} =
  ## Wraps `this` to a signed `JsBigInt` of `bits` bits in `-2 ^ (bits - 1)` .. `2 ^ (bits - 1) - 1`.
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asIntN
  runnableExamples:
    assert (big("3") + big("2") ** big("66")).wrapToInt(13) == big("3")

func wrapToUint*(this: JsBigInt; bits: Natural): JsBigInt {.importjs:
  "(() => { const i = #, b = #; return BigInt.asUintN(b, i) })()".} =
  ## Wraps `this` to an unsigned `JsBigInt` of `bits` bits in 0 ..  `2 ^ bits - 1`.
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asUintN
  runnableExamples:
    assert (big("3") + big("2") ** big("66")).wrapToUint(66) == big("3")

func toNumber*(this: JsBigInt): BiggestInt {.importjs: "Number(#)".} =
  ## Does not do any bounds check and may or may not return an inexact representation.
  runnableExamples:
    assert toNumber(big"2147483647") == 2147483647.BiggestInt

func `+`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    assert (big"9" + big"1") == big"10"

func `-`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    assert (big"9" - big"1") == big"8"

func `*`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".} =
  runnableExamples:
    assert (big"42" * big"9") == big"378"

func `div`*(x, y: JsBigInt): JsBigInt {.importjs: "(# / #)".} =
  ## Same as `div` but for `JsBigInt`(uses JavaScript `BigInt() / BigInt()`).
  runnableExamples:
    assert big"13" div big"3" == big"4"
    assert big"-13" div big"3" == big"-4"
    assert big"13" div big"-3" == big"-4"
    assert big"-13" div big"-3" == big"4"

func `mod`*(x, y: JsBigInt): JsBigInt {.importjs: "(# % #)".} =
  ## Same as `mod` but for `JsBigInt` (uses JavaScript `BigInt() % BigInt()`).
  runnableExamples:
    assert big"13" mod big"3" == big"1"
    assert big"-13" mod big"3" == big"-1"
    assert big"13" mod big"-3" == big"1"
    assert big"-13" mod big"-3" == big"-1"

func `<`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".} =
  runnableExamples:
    assert big"2" < big"9"

func `<=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".} =
  runnableExamples:
    assert big"1" <= big"5"

func `==`*(x, y: JsBigInt): bool {.importjs: "(# == #)".} =
  runnableExamples:
    assert big"42" == big"42"

func `**`*(x, y: JsBigInt): JsBigInt {.importjs: "((#) $1 #)".} =
  # (#) needed, refs https://github.com/nim-lang/Nim/pull/16409#issuecomment-760550812
  runnableExamples:
    assert big"2" ** big"64" == big"18446744073709551616"
    assert big"-2" ** big"3" == big"-8"
    assert -big"2" ** big"2" == big"4" # parsed as: (-2n) ** 2n
    assert big"0" ** big"0" == big"1" # edge case
    var ok = false
    try: discard big"2" ** big"-1" # raises foreign `RangeError`
    except: ok = true
    assert ok
  # pending https://github.com/nim-lang/Nim/pull/15940, simplify to:
  # doAssertRaises: discard big"2" ** big"-1" # raises foreign `RangeError`

func `and`*(x, y: JsBigInt): JsBigInt {.importjs: "(# & #)".} =
  runnableExamples:
    assert (big"555" and big"2") == big"2"

func `or`*(x, y: JsBigInt): JsBigInt {.importjs: "(# | #)".} =
  runnableExamples:
    assert (big"555" or big"2") == big"555"

func `xor`*(x, y: JsBigInt): JsBigInt {.importjs: "(# ^ #)".} =
  runnableExamples:
    assert (big"555" xor big"2") == big"553"

func `shl`*(a, b: JsBigInt): JsBigInt {.importjs: "(# << #)".} =
  runnableExamples:
    assert (big"999" shl big"2") == big"3996"

func `shr`*(a, b: JsBigInt): JsBigInt {.importjs: "(# >> #)".} =
  runnableExamples:
    assert (big"999" shr big"2") == big"249"

func `-`*(this: JsBigInt): JsBigInt {.importjs: "($1#)".} =
  runnableExamples:
    assert -(big"10101010101") == big"-10101010101"

func inc*(this: var JsBigInt) {.importjs: "(++[#][0][0])".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    inc big1
    assert big1 == big"2"

func dec*(this: var JsBigInt) {.importjs: "(--[#][0][0])".} =
  runnableExamples:
    var big1: JsBigInt = big"2"
    dec big1
    assert big1 == big"1"

func inc*(this: var JsBigInt; amount: JsBigInt) {.importjs: "([#][0][0] += #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    inc big1, big"2"
    assert big1 == big"3"

func dec*(this: var JsBigInt; amount: JsBigInt) {.importjs: "([#][0][0] -= #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    dec big1, big"2"
    assert big1 == big"-1"

func `+=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    big1 += big"2"
    assert big1 == big"3"

func `-=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"1"
    big1 -= big"2"
    assert big1 == big"-1"

func `*=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  runnableExamples:
    var big1: JsBigInt = big"2"
    big1 *= big"4"
    assert big1 == big"8"

func `/=`*(x: var JsBigInt; y: JsBigInt) {.importjs: "([#][0][0] $1 #)".} =
  ## Same as `x = x div y`.
  runnableExamples:
    var big1: JsBigInt = big"11"
    big1 /= big"2"
    assert big1 == big"5"

proc `+`*(_: JsBigInt): JsBigInt {.error:
  "See https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs".} # Can not be used by design
  ## **Do NOT use.** https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs

proc low*(_: typedesc[JsBigInt]): JsBigInt {.error:
  "Arbitrary precision integers do not have a known low.".} ## **Do NOT use.**

proc high*(_: typedesc[JsBigInt]): JsBigInt {.error:
  "Arbitrary precision integers do not have a known high.".} ## **Do NOT use.**


runnableExamples:
  block:
    let big1: JsBigInt = big"2147483647"
    let big2: JsBigInt = big"666"
    assert JsBigInt isnot int
    assert big1 != big2
    assert big1 > big2
    assert big1 >= big2
    assert big2 < big1
    assert big2 <= big1
    assert not(big1 == big2)
    let z = JsBigInt.default
    assert $z == "0n"
  block:
    var a: seq[JsBigInt]
    a.setLen 2
    assert a == @[big"0", big"0"]
    assert a[^1] == big"0"
    var b: JsBigInt
    assert b == big"0"
    assert b == JsBigInt.default
