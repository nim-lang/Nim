discard """
  output: '''(c: "hello", a: 10, b: 12.0)
(a: 15.5, b: "hello")
(a: 11.75, b: 123)'''
"""

# bug #5231
# generic object inheriting from
# partial specialized generic object
type
  Curve1[T, X] = object of RootObj
    a: T
    b: X

  Curve2[T] = Curve1[T, float64]

  Curve3[T] = object of Curve2[T]
    c: string

  Curve4[T] = Curve1[float64, T]

  Curve5[T] = object of Curve4[T]

  Curve6[T] = object of T

var x: Curve3[int]
x.a = 10
x.b = 12.0
x.c = "hello"

echo x

var y: Curve5[string]
y.b = "hello"
y.a = 15.5

echo y

var z: Curve6[Curve4[int]]
z.a = 11.75
z.b = 123

echo z