{.experimental: "sumTypes".}
type
  Opt*[T] = object
    case
    of None: discard
    of Some: val*: T
  Shape* = object
    x*, y*: float
    case
    of Circle: radius*: float
    of Rect, Square: w*, h*: float
  Tree*[T] = ref object
    case
    of Leaf: v*: T
    of Fork: l*, r*: Tree[T]

proc some*[T](x: T): Opt[T] = Some(val: x)
template mk*(x): untyped = Some(val: x)
proc leafs*[T](a, b: T): Tree[T] = Fork(l: Leaf(v: a), r: Leaf(v: b))
let origin* = Circle(radius: 1.0)
