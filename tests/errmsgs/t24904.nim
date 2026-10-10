discard """
  errormsg: "type mismatch"
  line: 10
"""

# bug #24904: used to crash the compiler while reporting the error
proc p*[T](a: T) = discard
type
  A*[B] = object
    x = p[A[B]]
proc s(x: A) = discard
