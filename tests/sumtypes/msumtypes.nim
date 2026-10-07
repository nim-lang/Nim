{.experimental: "sumTypes".}
type
  Opt*[T] = object
    case
    of None: discard
    of Some: val*: T
  Hidden* = object
    case
    of H1: secret: int
    of H2: discard

proc some*[T](x: T): Opt[T] = Some(val: x)
proc none*[T](): Opt[T] = None()
