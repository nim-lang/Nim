discard """
  errormsg: "cannot infer generic type for sum type constructor"
  line: 11
"""

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
echo Some(val: nil)
