discard """
  errormsg: "The fields 'x' and 'a' cannot be initialized together, because they are from conflicting branches in the case object."
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

let x = Pair(a: 1, x: 2)
