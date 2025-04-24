# regression test

converter toPtr[T](x: var T): ptr T =
  result = addr x

var x = 123
let y: ptr int = x
