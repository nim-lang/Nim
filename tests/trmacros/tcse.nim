discard """
  output: "4"
"""

template cse{f(a, a, x)}(a: typed{(nkDotExpr|call|nkBracketExpr)&noSideEffect},
                         f: typed, x: varargs[typed]): untyped =
  let aa = a
  f(aa, aa, x)+4

var
  a: array[0..10, int]
  i = 3
echo a[i] + a[i]
