discard """
  errormsg: "type mismatch"
  line: 12
"""

# bug #13225: used to crash the compiler with an endless recursion
type Obj[T] = void

proc f(T: typedesc[Obj]; x: T) =
  discard

f(Obj, "any value")
