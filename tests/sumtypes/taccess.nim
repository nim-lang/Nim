discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
Some(val: 42) None()
Circle(x: 1.0, y: 2.0, radius: 5.0, color: 3)
Pair(a: 1, b: "x")
1.0 3
42 2
`kind val
(a: 1, k: false, c: "x") (1, 2) (a: 1, b: "s")
'''
"""

{.experimental: "sumTypes".}

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
  Shape = object
    x, y: float
    case
    of Circle: radius: float
    of Rect: w, h: float
    color: int
  P = object
    case
    of Pair:
      a: int
      b: string
    of Single: discard
  Plain = object
    a: int
    case k: bool
    of true: b: int
    of false: c: string

# `$` renders a sum type like its constructor:
let a = Some(val: 42)
echo a, " ", Opt[int](None())
let s = Circle(x: 1.0, y: 2.0, radius: 5.0, color: 3)
echo s
echo Pair(a: 1, b: "x")

# shared fields are always accessible:
echo s.x, " ", s.color

# branch fields only in `{.cast(uncheckedAccess).}`:
var m = Some(val: 1)
{.cast(uncheckedAccess).}:
  m.val = 2
  echo a.val, " ", m.val

# `fieldPairs` sees the hidden discriminator:
var names = ""
for name, value in fieldPairs(a):
  if names.len > 0: names.add " "
  names.add name
echo names

# other objects and tuples are unaffected:
echo Plain(a: 1, k: false, c: "x"), " ", (1, 2), " ", (a: 1, b: "s")
