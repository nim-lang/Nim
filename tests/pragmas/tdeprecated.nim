# bug #6436
proc foo(size: int, T: typedesc): seq[T]  {.deprecated.}=
  result = newSeq[T](size)

proc foo[T](size: int): seq[T]=
  result = newSeq[T](size)

let bar = foo[int](3) # Warning foo is deprecated

doAssert bar == @[0, 0, 0]
