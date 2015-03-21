
# bug #602

type
  TTest = object
  TTest2* = object
  TFoo = TTest | TTest2

proc f(src: ptr TFoo, dst: ptr TFoo) =
  echo("asd")

var x: TTest
f(addr(x), addr(x))

