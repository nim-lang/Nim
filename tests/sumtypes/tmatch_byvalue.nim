discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
3
4
Some(val: 7)
'''
"""

# bindings of immutable locations are bound by value, those of mutable
# locations by address
type
  R = object
    x: int
  V = object
    case
    of S: r: R
    of I: i: int
  Opt = object
    case
    of None: discard
    of Some: val: int
proc `=copy`(a: var R; b: R) {.error.}

proc p(xs: seq[V]) =
  case xs[0]
  of S(r): echo r.x
  of I(i): echo i
p(@[S(r: R(x: 3))])
let g = @[S(r: R(x: 4))]
case g[0]
of S(r): echo r.x
of I(i): echo i

var os = @[Some(val: 1)]
case os[0]
of Some(v): v = 7
of None: discard
echo os[0]
