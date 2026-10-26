discard """
  errormsg: "'xs[0]' escapes its stack frame"
  line: 14
"""

type
  Opt = object
    case
    of None: discard
    of Some: val: string
proc local(): lent string =
  var xs = @[Some(val: "x")]
  case xs[0]
  of Some(v): return v
  of None: discard
discard local()
