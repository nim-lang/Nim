{.experimental: "sumTypes".}
type
  Opt*[T] = object
    case
    of None: discard
    of Some: val*: T
  Tree*[T] = ref object
    case
    of Leaf: v*: T
    of Fork: l*, r*: Tree[T]
  Hidden* = object
    case
    of H1: secret: int
    of H2: discard
  Priv = object
    case
    of PA: discard
    of PB: discard

proc some*[T](x: T): Opt[T] = Some(val: x)
proc none*[T](): Opt[T] = None()
template mk*(x): untyped = Some(val: x)
proc leafs*[T](a, b: T): Tree[T] = Fork(l: Leaf(v: a), r: Leaf(v: b))
