type
  Vec3[T] = array[3, T]

proc foo(x: Vec3, y: Vec3.T, z: x.T): x.type.T =
  return 10

var y: Vec3[int] = [1, 2, 3]
var z: int = foo(y, 3, 4)

