discard """
  output: '''1
a
13'''
"""

# bug #5621 #5615
type
  Obj5[T] = ref object of RootObj
    x_impl: T

proc x[T](v476205: Obj5[T]): T {.used.} =
  v476205.x_impl

type
  Obj6[T, U] = ref object of Obj5[T]
    y_impl: U

proc newObj6[T, U](x: T; y: U): Obj6[T, U] =
  new(result)
  result.x_impl = x
  result.y_impl = y

proc x[T, U](v477606: Obj6[T, U]): T {.used.} =
  v477606.x_impl

proc y[T, U](v477608: Obj6[T, U]): U {.used.} =
  v477608.y_impl

let e = newObj6(1, "a")
echo e.x
echo e.y

type
  Fruit[T] = ref object of RootObj
  Apple[T] = ref object of Fruit[T]

proc getColor[T](v: Fruit[T]): T = 13

var w: Apple[int]
let r = getColor(w)
echo r
