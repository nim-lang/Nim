discard """
  matrix: "--mm:orc"
  output: '''
Opt[system.int](Some(val: 42)) Opt[system.int](None()) Shape(Dot(x: 1.0))
Node(Add(a: Node(Value(v: 1)), b: nil))
(1, "a") Opt[tuple[a: int]](Some(val: (a: 1)))
'''
"""

{.experimental: "sumTypes".}

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T
  Node = ref object
    case
    of Value: v: int
    of Add: a, b: Node
  Shape = object
    x: float
    case
    of Circle: radius: float
    of Dot: discard

echo repr(Some(val: 42)), " ", repr(Opt[int](None())), " ", repr(Dot(x: 1.0))
echo repr(Add(a: Value(v: 1), b: nil))
echo repr((1, "a")), " ", repr(Some(val: (a: 1)))
