discard """
  errormsg: "field 'val' can only be accessed in a pattern matching `case` branch"
  line: 12
"""

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
let a = Some(val: 42)
proc g[T](o: Opt[T]): T = o.val
echo g(a)
