discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
42
3 7 s
Circle(x: 1.0, y: 2.0, radius: 10.0)
300.0 6.0
@[Circle(x: 0.0, y: 0.0, radius: 2.0), Rect(x: 0.0, y: 0.0, w: 9.0, h: 2.0)]
made
10
'''
"""

# pattern matching `case` on sum types, bindings are views
type
  Node = ref object
    case
    of AddOpr, SubOpr:
      a, b: Node
    of Value:
      val: int
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
  Shape = object
    x, y: float
    case
    of Circle: radius: float
    of Rect: w, h: float

proc eval(n: Node): int =
  case n
  of Value(val): result = val
  of AddOpr(a, b): result = eval(a) + eval(b)
  of SubOpr(a, b): result = eval(a) - eval(b)

echo eval(AddOpr(a: Value(val: 40), b: SubOpr(a: Value(val: 5), b: Value(val: 3))))

proc get[T](o: Opt[T]; d: T): T =
  case o
  of Some(v): v
  of None(): d

echo get(Some(val: 3), 0), " ", get(Opt[int](None()), 7), " ", get(Some(val: "s"), "")

var s = Circle(x: 1, y: 2, radius: 3)
case s
of Circle(r):
  r = 10.0          # a view: writes the field
of Rect(_, h): echo h
echo s

proc area(s: Shape): float =
  case s
  of Circle(r): 3.0 * r * r
  of {Rect}(w, h): w * h

echo area(s), " ", area(Rect(w: 2, h: 3))

var shapes = @[Circle(radius: 1), Rect(w: 1, h: 2)]
for i in 0..<shapes.len:
  case shapes[i]
  of Circle(r): r = r * 2
  of Rect(w): w = 9
echo shapes

proc mk(): Opt[string] = Some(val: "made")
case mk()
of Some(x): echo x
else: echo "none"

let k = case Some(val: 5)
        of Some(x): x * 2
        of None: 0
echo k
