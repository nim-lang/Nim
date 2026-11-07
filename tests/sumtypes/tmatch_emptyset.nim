discard """
  errormsg: "a set pattern needs at least one branch"
  line: 12
"""

type
  Opt = object
    case
    of None: discard
    of Some: val: int
case Some(val: 1)
of {}(v): discard
else: discard
