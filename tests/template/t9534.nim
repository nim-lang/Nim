discard """
  targets: "c cpp"
"""

# bug #9534
type
  Object = object
    data: int

template test() =
  proc methodName(o: Object): int =
    var p: pointer
    doAssert o.data == 521
    let f {.used.} = cast[proc (o: int): int {.nimcall.}](p)
    doAssert o.data == 521
    result = 1314

  var a = Object(data: 521)
  doAssert methodName(a) == 1314

test()
