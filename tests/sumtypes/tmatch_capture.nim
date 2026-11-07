discard """
  errormsg: "'arr[0]' is of type <V> which cannot be captured"
  line: 14
"""

# a binding of a mutable location is a view; views cannot be captured
type
  V = object
    case
    of S: s: string
    of I: i: int
proc mk(): proc(): string =
  var arr = @[S(s: "hello"), I(i: 1)]
  case arr[0]
  of S(s): result = proc(): string = s
  of I(i): discard
discard mk()
