# bug #11669: an iterator overloaded with a proc passed to an `iterable` param
template foo(iter: iterable[int]): untyped =
  var s = 0
  for x in iter: s += x
  s
proc bar(x: int): int = 100
iterator bar(x: int): int =
  yield x
  yield x
doAssert foo(bar(3)) == 6
doAssert bar(3) == 100
