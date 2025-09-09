# issue #24875

type
  MyEnum = enum
    One = 1

var x = cast[MyEnum](0)
let s = $x
doAssert s == ""
