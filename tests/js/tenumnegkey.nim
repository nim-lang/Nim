discard """
  output: "first-12second32third64"
"""

type Holed = enum
  hFirst = (-12,"first")
  hSecond = (32,"second")
  hThird = (64,"third")
  
var x = @[-12,32,64] # This is just to avoid the compiler inlining the value of the enum

echo Holed(x[0]),ord Holed(x[0]),Holed(x[1]),ord Holed(x[1]),Holed(x[2]),ord Holed(x[2])
