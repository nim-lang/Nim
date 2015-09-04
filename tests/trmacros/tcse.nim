discard """
  output: "4"
"""

template cse{f(a, a, x)}(a: expr{(nkDotExpr|call|nkBracketExpr)&noSideEffect},
                         f: expr, x: varargs[expr]): expr =
  let aa = a
  f(aa, aa, x)+4

var
  a: array[0..10, int]
  i = 3
echo a[i] + a[i]
