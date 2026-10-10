discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
Circle(radius: 2.0)
Rect(w: 7.0, h: 2.0)
Circle(radius: 42.0)
6.0
circle 2.0
rect 3.0x4.0
3
Some(val: "b")
'''
"""

# selectors: `var` parameters, field paths, `ptr`/`ref` derefs, `lent`, calls
import msumtypes
type
  Shape = object
    case
    of Circle: radius: float
    of Rect: w, h: float
  Box = object
    s: Shape

proc grow(s: var Shape) =
  case s
  of Circle(r): r += 1
  of Rect(w, h): w += 1; h += 1

var a = Circle(radius: 1)
grow(a)
echo a

var b = Box(s: Rect(w: 1, h: 1))
grow(b.s)
case b.s
of Rect(w): w = 7
else: discard
echo b.s

let p = addr a
case p[]
of Circle(r): r = 42
else: discard
echo a

let rp = new(Shape)
rp[] = Rect(w: 2, h: 3)
case rp[]
of Rect(w, h): echo w * h
else: discard

let shapes = @[Circle(radius: 2), Rect(w: 3, h: 4)]
for s in shapes:            # `s` is a `lent` view
  case s
  of Circle(r): echo "circle ", r
  of Rect(w, h): echo "rect ", w, "x", h

proc sum(t: Tree[int]): int =
  case t                    # a `ref` selector
  of Leaf(v): v
  of Fork(l, r): sum(l) + sum(r)
const s3 = sum(leafs(1, 2))
static: echo "ct ", s3
echo s3

proc firstSome[T](xs: seq[Opt[T]]): Opt[T] =
  result = None()
  for x in xs:
    case x
    of Some(_): return x
    of None(): discard
echo firstSome(@[Opt[string](None()), Some(val: "b"), Some(val: "c")])
