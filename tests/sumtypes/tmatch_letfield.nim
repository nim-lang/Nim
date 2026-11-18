discard """
  errormsg: "'b.o.val' cannot be assigned to"
  line: 16
"""

# a binding of an immutable location is bound by value
type
  Opt = object
    case
    of None: discard
    of Some: val: int
  Box = object
    o: Opt
let b = Box(o: Some(val: 1))
case b.o
of Some(v): v = 100
of None: discard
