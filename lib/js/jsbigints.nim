## Arbitrary precision integers.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt

type JsBigInt* = ref object of JsRoot ## Arbitrary precision integer for JavaScript target.

func newBigInt*(integer: cint): JsBigInt {.importjs: "BigInt(#)".}
  ## Constructor for `JsBigInt`.

func newBigInt*(integer: cstring): JsBigInt {.importjs: "BigInt(#)".}
  ## Constructor for `JsBigInt`.

func toLocaleString*(this: JsBigInt): cstring {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toLocaleString*(this: JsBigInt; locales: cstring): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toLocaleString*(this: JsBigInt; locales: openArray[cstring]): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toLocaleString

func toString*(this: JsBigInt; radix: cint): cstring {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func toString*(this: JsBigInt): cstring {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/toString

func asIntN*(width: cint; bigInteger: JsBigInt): cint {.importjs: "BigInt.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asIntN

func asUintN*(width: cint; bigInteger: JsBigInt): cint {.importjs: "BigInt.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt/asUintN

func `+`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `-`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `*`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `/`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `%`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `+=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `-=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `*=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `/=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `%=`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)", discardable.}

func `++`*(x: JsBigInt): JsBigInt {.importjs: "($1#)".}

func `--`*(x: JsBigInt): JsBigInt {.importjs: "($1#)".}

func `>`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `<`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `>=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `<=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}

func `==`*(x, y: JsBigInt): bool {.importjs: "(# $1= #)".}

func `**`*(x, y: JsBigInt): JsBigInt {.importjs: "((#) $1 #)".}

func `and`*(x, y: JsBigInt): JsBigInt {.importjs: "(# && #)".}

func `or`*(x, y: JsBigInt): JsBigInt {.importjs: "(# || #)".}

func `not`*(x: JsBigInt): JsBigInt {.importjs: "(!#)".}

func `in`*(x, y: JsBigInt): JsBigInt {.importjs: "(# $1 #)".}

func `-`*(a: JsBigInt): JsBigInt {.importjs: "($1#)".}

func `xor`*(x, y: JsBigInt): JsBigInt {.importjs: "(# ^ #)".}

func `shl`*(a, b: JsBigInt): JsBigInt {.importjs: "(# << #)".}

func `shr`*(a, b: JsBigInt): JsBigInt {.importjs: "(# >> #)".}

func inc*(a: JsBigInt): JsBigInt {.importjs: "(# += BigInt(1))", discardable.}

func dec*(a: JsBigInt): JsBigInt {.importjs: "(# -= BigInt(1))", discardable.}

func inc*(a, b: JsBigInt): JsBigInt {.importjs: "(# += #)", discardable.}

func dec*(a, b: JsBigInt): JsBigInt {.importjs: "(# -= #)", discardable.}

func `+`*(a: JsBigInt): JsBigInt {.error.} # Can not be used by design.
  ## https://github.com/tc39/proposal-bigint/blob/master/ADVANCED.md#dont-break-asmjs


runnableExamples:
  let big1: JsBigInt = newBigInt(2147483647.cint)
  let big2: JsBigInt = newBigInt("666".cstring)
  var big3: JsBigInt = newBigInt("2".cstring)
  doAssert big1 != big2
  doAssert big1 > big2
  doAssert big1 >= big2
  doAssert big2 < big1
  doAssert big2 <= big1
  doAssert not(big1 == big2)
  inc big3
  doAssert big3 == newBigInt(3.cint)
  dec big3
  doAssert big3 == newBigInt(2.cint)
  inc big3, newBigInt(420.cint)
  doAssert big3 == newBigInt(422.cint)
  dec big3, newBigInt(420.cint)
  doAssert big3 == newBigInt(2.cint)
  doAssert (big3 xor big2) == newBigInt(664.cint)
  doAssert big1 % big2 == newBigInt("613".cstring)
  doAssert -big1 == newBigInt("-2147483647".cstring)
  doAssert big1 / big2 == newBigInt("3224449".cstring)
  doAssert big1 + big2 == newBigInt("2147484313".cstring)
  doAssert big1 - big2 == newBigInt("2147482981".cstring)
  doAssert big1 shl big3 == newBigInt("8589934588".cstring)
  doAssert big1 shr big3 == newBigInt("536870911".cstring)
  doAssert big1 * big2 == newBigInt("1430224108902".cstring)
  doAssert big1.toLocaleString("EN".cstring) == "2,147,483,647".cstring
  doAssert big1.toLocaleString(["EN".cstring, "ES".cstring]) == "2,147,483,647".cstring
  doAssert big1.toString() == "2147483647".cstring
  doAssert big1.toString(10.cint) == "2147483647".cstring
  doAssert big1.toString(2.cint) == "1111111111111111111111111111111".cstring
  doAssert big2 ** big3 == newBigInt(443556.cint)
  discard newBigInt("999999999999999999999999999999999999999999999999999999999999999999999999999999999999999".cstring)
  discard newBigInt("0".cstring)
  discard newBigInt("-999999999999999999999999999999999999999999999999999999999999999999999999999999999999999".cstring)
