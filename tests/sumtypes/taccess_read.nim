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
echo a.val
