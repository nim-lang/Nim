discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
inner 1
outer 100
same name 2
7 g
5 100
nested 3
2 3
false
1 9
'''
"""

# binding hygiene: shadowing, generics, templates, nesting, other modules
import msumtypes
type
  Shape = object
    case
    of Circle: radius: float
    of Rect: w, h: float

let v = 100
let o = Some(val: 1)
case o
of Some(v): echo "inner ", v      # shadows the outer `v`
of None(): discard
echo "outer ", v

var x = Some(val: 2)
case x
of Some(x): echo "same name ", x  # binding named like the selector
else: discard

proc gen[T](o: Opt[T]): T =
  case o
  of Some(v): v                   # `v` must not bind to the global `v`
  of None(): default(T)
echo gen(Some(val: 7)), " ", gen(Some(val: "g"))

template unwrapOr(o, d: untyped): untyped =
  case o
  of Some(v): v
  of None(): d
echo unwrapOr(Some(val: 5), 0), " ", unwrapOr(Opt[int](None()), v)

let nested = Some(val: Some(val: 3))
case nested
of Some(inner):
  case inner
  of Some(z): echo "nested ", z
  of None(): discard
of None(): discard

proc count(t: Tree[int]): int =
  case t
  of Leaf(_): 1
  of Fork(l, r): count(l) + count(r)
echo count(leafs(1, 2)), " ", count(Fork(l: leafs(1, 2), r: Leaf(v: 3)))

echo compiles((case H1(secret: 1)
               of H1(s): s
               of H2(): 0))

let w = 9
echo unwrapOr(Some(val: 1), 0), " ", unwrapOr(Opt[int](None()), w)
