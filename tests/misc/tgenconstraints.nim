discard """
  errormsg: "cannot instantiate T2"
  file: "tgenconstraints.nim"
  line: 25
  disabled: true
"""

type
  T1[T: int|string] = object
    x: T

  T2[T: Ordinal] = object
    x: T

var x1: T1[int]
var x2: T1[string]
var x3: T2[int]

proc foo[T](x: T): T2[T] {.discardable.} =
  var o: T1[T]

foo(10)

# XXX: allow type intersections in situation like this
proc bar(x: int|TNumber): T1[type(x)] {.discardable.} =
  when type(x) is TNumber:
    var o: T2[type(x)]

bar "test"
bar 100
bar 1.1
