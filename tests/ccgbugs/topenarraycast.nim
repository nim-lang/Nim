proc foo[T](s: var openArray[T]): T =
  for x in s: result += x

proc bar(xyz: var seq[int]) =
  doAssert 6 == (seq[int](xyz)).foo()

var t = @[1,2,3]
bar(t)
