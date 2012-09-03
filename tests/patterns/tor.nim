discard """
  output: "110"
"""

template arithOps: expr = (`+` | `-` | `*`)
template testOr{ (arithOps{f})(a, b) }(a, b, f: expr): expr = f(a+1, b)

let xx = 10
echo 10*xx
