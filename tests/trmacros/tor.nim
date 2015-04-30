discard """
  output: '''3030
true
3'''
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

# bug #798
template t012{(0|1|2){x}}(x: expr): expr = x+1
let z = 1
# outputs 3 thanks to fixpoint iteration:
echo z
