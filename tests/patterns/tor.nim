discard """
  output: '''3060
true'''
"""

template arithOps: expr = (`+` | `-` | `*`)
template testOr{ (arithOps{f})(a, b) }(a, b, f: expr): expr = f(a+1, b)

let xx = 10
echo 10*xx

template t{x = (~x){y} and (~x){z}}(x, y, z: bool): stmt =
  x = y
  if x: x = z

var
  a = true
  b = true
  c = false
a = b and a
echo a
