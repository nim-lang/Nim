discard """
  output: '''666
666'''
"""

# test the new generic converters:

type
  TFoo2[T] = object
    x: T

  TFoo[T] = object
    data: array[0..100, T]

converter toFoo[T](a: TFoo2[T]): TFoo[T] =
  result.data[0] = a.x

proc p(a: TFoo[int]) =
  echo a.data[0]

proc q[T](a: TFoo[T]) =
  echo a.data[0]


var
  aa: TFoo2[int]
aa.x = 666

p aa
q aa


#-------------------------------------------------------------
# issue #16651
type
  PointTup = tuple
    x: float32
    y: float32

converter tupleToPoint[T1, T2: SomeFloat](self: tuple[x: T1, y: T2]): PointTup =
  result = (self.x.float32, self.y.float32)

proc tupleToPointX(self: tuple[x: SomeFloat, y: SomeFloat]): PointTup =
  result = (self.x.float32, self.y.float32)

proc tupleToPointX2(self: tuple[x: SomeFloat, y: distinct SomeFloat]): PointTup =
  result = (self.x.float32, self.y.float32)

var t1: PointTup = tupleToPointX((1.0, 0.0))
var t2: PointTup = tupleToPointX2((1.0, 0.0))
var t3: PointTup = tupleToPointX2((1.0'f32, 0.0))
var t4: PointTup = tupleToPointX2((1.0, 0.0'f32))

var x2: PointTup = (1.0, 0.0)