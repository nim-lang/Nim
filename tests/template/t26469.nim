discard """
  output: '''
1
true 42
3
'''
"""

# bug #26469: template parameters in object field pragmas

import std/macros

template declare(p: untyped) =
  type U = object
    a {.p.}: int
  echo U(a: 1).a

declare(used)

template pragmaVal(p: untyped) =
  template myPrag(x: int) {.pragma.}
  type V = object
    b {.myPrag: p.}: int
  echo V(b: 2).b.hasCustomPragma(myPrag), " ", V().b.getCustomPragmaVal(myPrag)

pragmaVal(42)

template injected(p: untyped) =
  var x {.inject, p.} = 3
injected(used)
echo x

macro m(): untyped =
  let p = ident"used"
  result = quote do:
    type W = object
      a {.`p`.}: int
  let field = result[0][2][2][0][0]
  doAssert field[1][0].eqIdent"used", field.treeRepr

m()
