discard """
  action: reject
  errormsg: "expression 'echo x' is of type 'unknown' and has to be used (or discarded)"
  line: 8
"""

proc foo*[U](x: U = U(1e-6)) =
  echo x

foo[float]()
foo()
