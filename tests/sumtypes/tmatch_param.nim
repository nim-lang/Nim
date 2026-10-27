discard """
  errormsg: "'xs[0].val' cannot be assigned to"
  line: 13
"""

type
  Opt = object
    case
    of None: discard
    of Some: val: int
proc p(xs: seq[Opt]) =
  case xs[0]
  of Some(v): v = 43
  of None: discard
p(@[Some(val: 1)])
