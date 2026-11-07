discard """
  errormsg: "type mismatch: got <int literal(42)>"
  line: 9
"""

# bug #13906: a value is not accepted as a type parameter
proc test[T](x: T) = discard
test[int](42)
test[12](42)
