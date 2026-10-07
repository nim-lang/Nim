discard """
  errormsg: "ambiguous sum type branch 'None'; use a type conversion to select one of: Opt Other"
  line: 18
"""

{.experimental: "sumTypes".}
type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
  Other = object
    case
    of None: discard
    of Value: x: int
    of Pair: a, b: int

let x = None()
