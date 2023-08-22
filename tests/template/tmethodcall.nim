# bug #5909
type
  Vec2[T] = tuple
    x,y: T
  Vec2f = Vec2[float32]

proc vec2f(x,y: float): Vec2f =
  result.x = x
  result.y = y

proc `-`[T](a,b: Vec2[T]): Vec2[T] =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc foo[T](a: Vec2[T]): Vec2[T] =
  result = a

block:
 # this being called foo is a problem when calling .foo()
  var foo = true

  let a = vec2f(1.0,0.0)
  let b = vec2f(3.0,1.0)
  let c = (a - b).foo() # breaks
