discard """
  output: "3"
"""

# a generic declared in a `cast` section keeps it for its instances
type
  Opt = object
    case
    of None: discard
    of Some: val: int

{.cast(uncheckedAccess).}:
  proc peek[T](x: T): int = x.val
echo peek(Some(val: 3))
