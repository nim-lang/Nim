discard """
  errormsg: "cannot infer generic type for sum type constructor"
  line: 13
"""

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
let a: Opt[seq[int]] = Some(val: @[])
echo Opt[array[0, int]](Some(val: []))
echo Some(val: [])
