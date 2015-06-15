discard """
  output: '''success'''
"""
var s = "HI"

proc x (zz: openarray[char]) =
  discard

x s

proc z [T] (zz: openarray[T]) =
  discard

z s
z([s,s,s])

proc y [T] (arg: var openarray[T]) =
  arg[0] = 'X'
y s
doAssert s == "XI"

echo "success"
