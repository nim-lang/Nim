static: echo "\n #################"

proc xx(x: int) : float =
  result = cast[float](x)

proc yy() {.memSafe.} =
  var x = 123456789
  echo xx(x)

yy()
