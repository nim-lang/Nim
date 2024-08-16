discard """
  output: '''success'''
"""
var s = "HI"

proc x (zz: openArray[char]) =
  discard

x s

proc z [T] (zz: openArray[T]) =
  discard

z s
z([s,s,s])

proc y [T] (arg: var openArray[T]) =
  arg[0] = 'X'
y s
doAssert s == "XI"

echo "success"
