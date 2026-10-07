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
