discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
AddOpr SubOpr Value
0 1 2
Some 16 None()
48
Circle(x: 0.0, y: 0.0, radius: 0.0, tag: 3)
B
Q
'''
"""

{.experimental: "sumTypes".}

type
  Node = ref object
    case
    of AddOpr, SubOpr:   # several branch names can share fields
      a, b: Node
    of Value:
      val: int
  Opt[T] = object
    case
    of None: discard     # fieldless branch
    of Some: val: T
  Shape = object         # shared fields before and after the case
    x, y: float
    case
    of Circle: radius: float
    of Rect: w, h: float
    tag: int

echo AddOpr, " ", SubOpr, " ", Value
echo ord(AddOpr), " ", ord(SubOpr), " ", ord(Value)
var o: Opt[string]
echo Some, " ", sizeof(Opt[int]), " ", o
echo sizeof(Shape)
var s: Shape
s.tag = 3
echo s

proc local() =
  type L = object
    case
    of A: discard
    of B: z: int
  echo B
local()

# a typed macro argument is semchecked again:
macro resem(x: typed): untyped = x
resem:
  type R = object
    case
    of P: discard
    of Q: q: int
echo Q
