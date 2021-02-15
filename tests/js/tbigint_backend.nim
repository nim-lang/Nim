import std/private/jsutils


type JsBigIntImpl {.importc: "bigint".} = int
type JsBigInt = distinct JsBigIntImpl

doAssert JsBigInt isnot int
func big*(integer: SomeInteger): JsBigInt {.importjs: "BigInt(#)".}
func big*(integer: cstring): JsBigInt {.importjs: "BigInt(#)".}
func `<=`*(x, y: JsBigInt): bool {.importjs: "(# $1 #)".}
func `==`*(x, y: JsBigInt): bool {.importjs: "(# === #)".}
func inc*(x: var JsBigInt) {.importjs: "[#][0][0]++".}
func inc2*(x: var JsBigInt) {.importjs: "#++".}
func toCstring*(this: JsBigInt): cstring {.importjs: "#.toString()".}
func `$`*(this: JsBigInt): string =
  $toCstring(this)

block:
  doAssert defined(nimHasJsBigIntBackend)
  let z1 = big"10"
  let z2 = big"15"
  doAssert z1 == big"10"
  doAssert z1 == z1
  doAssert z1 != z2
  var s: seq[cstring]
  for i in z1 .. z2:
    s.add $i
  doAssert s == @["10".cstring, "11", "12", "13", "14", "15"]
  block:
    var a=big"3"
    a.inc
    doAssert a == big"4"
  block:
    var z: JsBigInt
    doAssert $z == "0"
    doAssert z.jsTypeOf == "bigint" # would fail without codegen change
    doAssert z != big(1)
    doAssert z == big"0" # ditto

  # ditto below
  block:
    let z: JsBigInt = big"1"
    doAssert $z == "1"
    doAssert z.jsTypeOf == "bigint"
    doAssert z == big"1"

  block:
    let z = JsBigInt.default
    doAssert $z == "0"
    doAssert z.jsTypeOf == "bigint"
    doAssert z == big"0"

  block:
    var a: seq[JsBigInt]
    a.setLen 3
    doAssert a[^1].jsTypeOf == "bigint"
    doAssert a[^1] == big"0"
