discard """
  targets: "c cpp js"
"""

#[
BUG: D20210512T152059:here
testament/testament.nim r tests/system/tstrmantle.nim
runs c cpp js tests, not honoring a spec that has `targets: "cpp js"`
workaround: use: --targets:'cpp js'
e.g.:
XDG_CONFIG_HOME= nim r -b:cpp --lib:lib testament/testament.nim --nim:$nimb --targets:'cpp js' r $nim_prs_D/tests/system/tstrmantle.nim

# PRTEMP: add tests for addFloat
]#

template main =
  var res = newStringOfCap(24)
  template toStr(x): untyped =
    res.setLen(0)
    res.addInt x
    res

  for i in 0 .. 9:
    res.addInt int64(i)

  doAssert res == "0123456789"
  res.setLen(0)
  for i in -9 .. 0:
    res.addInt int64(i)
  doAssert res == "-9-8-7-6-5-4-3-2-10"

  doAssert high(int8).toStr == "127"
  doAssert low(int8).toStr == "-128"
  doAssert high(int16).toStr == "32767"
  doAssert low(int16).toStr == "-32768"
  doAssert high(int32).toStr == "2147483647"
  doAssert low(int32).toStr == "-2147483648"
  when not defined(js):
    doAssert high(int64).toStr == "9223372036854775807"
    doAssert low(int64).toStr == "-9223372036854775808"

static: main()
main()
