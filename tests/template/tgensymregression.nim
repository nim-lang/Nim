
template mathPerComponent(op: untyped): untyped =
  proc op*[N,T](v,u: array[N,T]): array[N,T] {.inline.} =
    for i in 0 ..< len(result):
      result[i] = `*`(v[i], u[i])

mathPerComponent(`***`)
# bug #5285
when true:
  if isMainModule:
    var v1: array[3, float64]
    var v2: array[3, float64]
    echo repr(v1 *** v2)


proc foo(): void =
  var v1: array[4, float64]
  var v2: array[4, float64]
  echo repr(v1 *** v2)

foo()
