discard """
  targets: "c cpp"
  output: '''
13
24
6
'''
"""

# bug #5972: `cast[var T](x)` reinterprets the location of `x`
proc modifyInt(x: var int) =
  x += 1

proc modify[T](x: var T) =
  when T is int:
    modifyInt(cast[var int](x))

proc modifyUint(x: var uint) =
  x += 1

proc modify2(x: var int) =
  modifyUint(cast[var uint](x))
  cast[var uint](x) = cast[var uint](x) + 10

var x = 12
modify(x)
echo x
modify2(x)
echo x

var y = 5
modifyUint(cast[var uint](y))
echo y
