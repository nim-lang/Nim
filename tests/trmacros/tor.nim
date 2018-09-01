discard """
  output: '''true
3'''
"""

template arithOps: untyped = (`+` | `-` | `*`)
template testOr{ (arithOps{f})(a, b) }(a, b, f: untyped): untyped = f(a+1, b)

let xx = 10
let yy = 10*xx

# If you came here wondering why this assertion is failing keep in mind that the
# number of expansions done here is capped by the hlo pass and, at the time of
# writing, this limit is 300. The exact value may change as the AST changes so
# don't worry, you didn't fuck up this test :)
doAssert yy > 3000

template t{x = (~x){y} and (~x){z}}(x, y, z: bool): typed =
  x = y
  if x: x = z

var
  a = true
  b = true
  c = false
a = b and a
echo a

# bug #798
template t012{(0|1|2){x}}(x: untyped): untyped = x+1
let z = 1
# outputs 3 thanks to fixpoint iteration:
echo z
