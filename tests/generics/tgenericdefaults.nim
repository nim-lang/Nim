discard """
  file: "tgenericdefaults.nim"
"""
type
  TFoo[T, U, R = int] = object
    x: T
    y: U
    z: R

  TBar[T] = TFoo[T, array[4, T], T]

var x1: TFoo[int, float]

static:
  doAssert type(x1.x) is int
  doAssert type(x1.y) is float
  doAssert type(x1.z) is int

var x2: TFoo[string, R = float, U = seq[int]]

static:
  doAssert type(x2.x) is string
  doAssert type(x2.y) is seq[int]
  doAssert type(x2.z) is float

var x3: TBar[float]

static:
  doAssert type(x3.x) is float
  doAssert type(x3.y) is array[4, float]
  doAssert type(x3.z) is float

