discard """
  errormsg: "cannot infer generic type for sum type constructor; use a type conversion: Opt[...](...)"
  line: 19
"""

{.experimental: "sumTypes".}
type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
  Other = object
    case
    of None: discard
    of Value: x: int
    of Pair: a, b: int

let x = Opt[int](Some(val: 1))
let y = Some()
