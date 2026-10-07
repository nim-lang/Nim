discard """
  errormsg: "field 'val' can only be accessed in a pattern matching `case` branch"
  line: 13
"""

{.experimental: "sumTypes".}
type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
let a = Some(val: 42)
template get(o): untyped = o.val
echo get(a)
