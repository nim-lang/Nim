type 
  TFoo[T, U, R = int] = object
    x: T
    y: U
    z: R

  TBar[T] = TFoo[T, array[4, T], T]

var x1: TFoo[int, float]

static:
  assert type(x1.x) is int
  assert type(x1.y) is float
  assert type(x1.z) is int
  
var x2: TFoo[string, R = float, U = seq[int]]

static:
  assert type(x2.x) is string
  assert type(x2.y) is seq[int]
  assert type(x2.z) is float

var x3: TBar[float]

static:
  assert type(x3.x) is float
  assert type(x3.y) is array[4, float]
  assert type(x3.z) is float

