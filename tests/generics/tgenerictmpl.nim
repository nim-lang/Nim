
template tmp[T](x: var seq[T]) =
  #var yz: T  # XXX doesn't work yet
  x = @[1, 2, 3]

macro tmp2[T](x: var seq[T]): stmt =
  nil

var y: seq[int]
tmp(y)
tmp(y)
echo y.repr
