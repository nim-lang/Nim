discard """
  errormsg: "ambiguous sum type branch 'None'; use a type conversion to select one of: tconstr_ambiguous.Opt tconstr_ambiguous.Other"
  line: 17
"""

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
