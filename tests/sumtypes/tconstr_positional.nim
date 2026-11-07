discard """
  errormsg: "attempting to call routine: 'Value'"
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

let x = Value(42)
