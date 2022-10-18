type intorfloat = int or float

proc x(a: intorfloat; b: intorfloat): string =
  result = $a & " " & $b

var c: float = 2.0
var d: int = 3
doAssert x(c, d) == "2.0 3"
