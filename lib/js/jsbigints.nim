## Arbitrary precision integers.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt
when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsbigints is designed to be used with the JavaScript backend.".}

type JsBigInt* = ref object of JsRoot ## Arbitrary precision integer for JavaScript target.

func newBigInt*(integer: cstring or SomeInteger): JsBigInt {.importjs: "BigInt(#)".}
  ## Constructor for `JsBigInt`.

func toLocaleString*(this: JsBigInt): cstring {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toLocaleString*(this: JsBigInt; locales: cstring): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toLocaleString*(this: JsBigInt; locales: openArray[cstring]): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toString*(this: JsBigInt; radix: int): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func `$`*(this: JsBigInt): cstring {.importjs: "#.toString()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func asIntN*(width: int; bigInteger: JsBigInt): int {.importjs: "BigInt.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asIntN

func asUintN*(width: int; bigInteger: JsBigInt): int {.importjs: "BigInt.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asUintN

func `+`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `-`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `*`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `div`*(x, y: JsBigInt): JsBigInt {.importjs: "(# / #)".}
   ## Same as `div` but for `JsBigInt`.

func `mod`*(x, y: JsBigInt): JsBigInt {.importjs: "(# % #)".}
  ## Same as `mod` but for `JsBigInt` (uses JavaScript `BigInt() % BigInt()`).

func `+=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `-=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `*=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `/=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `mod=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `inc`*(x: JsBigInt): JsBigInt {.importjs: "(++#)", discardable.}
  ## Same as `inc` but for `JsBigInt` (uses JavaScript `++BigInt()`).

func `dec`*(x: JsBigInt): JsBigInt {.importjs: "(--#)", discardable.}
  ## Same as `dec` but for `JsBigInt` (uses JavaScript `--BigInt()`).

func `<`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `<=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `==`*(x, y: JsBigInt): bool {.importjs: "(# === #)".}

func `**`*(x, y: JsBigInt): JsBigInt {.importjs: "((#) $1 #)".}

func `and`*(x, y: JsBigInt): JsBigInt {.importjs: "(# && #)".}

func `or`*(x, y: JsBigInt): JsBigInt {.importjs: "(# || #)".}

func `not`*(x: JsBigInt): JsBigInt {.importjs: "(!#)".}

func `in`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `-`*(a: JsBigInt): JsBigInt {.importjs: "($1#)".}

func `xor`*(x, y: JsBigInt): JsBigInt {.importjs: "(# ^ #)".}

func `shl`*(a, b: JsBigInt): JsBigInt {.importjs: "(# << #)".}

func `shr`*(a, b: JsBigInt): JsBigInt {.importjs: "(# >> #)".}

func inc*(a, b: JsBigInt): JsBigInt {.importjs: "(# += #)", discardable.}

func dec*(a, b: JsBigInt): JsBigInt {.importjs: "(# -= #)", discardable.}

func `+`*(a: JsBigInt): JsBigInt {.error.} # Can not be used by design.
  ## https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs


runnableExamples:
  let big1: JsBigInt = newBigInt(2147483647)
  let big2: JsBigInt = newBigInt("666".cstring)
  var big3: JsBigInt = newBigInt("2".cstring)
  doAssert big1 != big2
  doAssert big1 > big2
  doAssert big1 >= big2
  doAssert big2 < big1
  doAssert big2 <= big1
  doAssert not(big1 == big2)
  inc big3
  doAssert big3 == newBigInt(3)
  dec big3
  doAssert big3 == newBigInt(2)
  inc big3, newBigInt(420)
  doAssert big3 == newBigInt(422)
  dec big3, newBigInt(420)
  doAssert big3 == newBigInt(2)
  doAssert (big3 xor big2) == newBigInt(664)
  doAssert (big1 mod big2) == newBigInt("613".cstring)
  doAssert -big1 == newBigInt("-2147483647".cstring)
  doAssert big1 div big2 == newBigInt("3224449".cstring)
  doAssert big1 + big2 == newBigInt("2147484313".cstring)
  doAssert big1 - big2 == newBigInt("2147482981".cstring)
  doAssert big1 shl big3 == newBigInt("8589934588".cstring)
  doAssert big1 shr big3 == newBigInt("536870911".cstring)
  doAssert big1 * big2 == newBigInt("1430224108902".cstring)
  doAssert big1.toLocaleString("EN".cstring) == "2,147,483,647".cstring
  doAssert big1.toLocaleString(["EN".cstring, "ES".cstring]) == "2,147,483,647".cstring
  doAssert $big1 == "2147483647".cstring
  doAssert big1.toString(10) == "2147483647".cstring
  doAssert big1.toString(2) == "1111111111111111111111111111111".cstring
  doAssert big2 ** big3 == newBigInt(443556)
  discard newBigInt("999999999999999999999999999999999999999999999999999999999999999999999999999999999999999".cstring)
  discard newBigInt("0".cstring)
  discard newBigInt("-999999999999999999999999999999999999999999999999999999999999999999999999999999999999999".cstring)
