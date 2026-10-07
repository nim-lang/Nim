discard """
  errormsg: "type mismatch: got 'string' for field 'v' but expected 'T: Addable'"
  line: 14
"""

{.experimental: "sumTypes".}
type
  Addable = concept
    proc `+`(a, b: Self): Self
  Expr[T: Addable] = object
    case
    of Lit: v: T
    of Neg: discard
let x = Lit(v: "s")
