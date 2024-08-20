discard """
  errormsg: "type mismatch: got <float, untyped>" # `untyped` here is arbitrary
  line: 9
"""

template foo(x: var int, y: untyped) = discard

var a: float
foo(a, undeclared) # previous error: undeclared identifier: 'undeclared'
