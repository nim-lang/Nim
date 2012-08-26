
template tmp[T](x: var seq[T]) =
  var yz: T
  x = @[1, 2, 3]

var y: seq[int]
tmp(y)
echo y.repr
