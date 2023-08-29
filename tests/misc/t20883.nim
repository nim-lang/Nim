discard """
  action: reject
  errormsg: "type mismatch: got <float64> but expected 'typeof(U(0.000001))'"
  line: 8
  column: 22
"""

proc foo*[U](x: U = U(1e-6)) =
  echo x

foo[float]()
foo()
