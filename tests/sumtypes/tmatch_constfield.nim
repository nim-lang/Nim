discard """
  errormsg: "'arr[0].val' cannot be assigned to"
  line: 14
"""

type
  Opt = object
    case
    of None: discard
    of Some: val: int
const arr = [Some(val: 1), None()]
case arr[0]
of Some(v):
  v = 42
of None: discard
