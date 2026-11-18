discard """
  errormsg: "field 'val' can only be accessed in a pattern matching `case` branch"
  line: 13
"""

# a `cast` section at the call site does not apply to a generic's instance
type
  Opt = object
    case
    of None: discard
    of Some: val: int

proc peek[T](x: T): int = x.val
{.cast(uncheckedAccess).}:
  echo peek(Some(val: 3))
