type
  Field* = object
    elemSize*: int

template `+`*(x: untyped, y: Field): untyped = x
