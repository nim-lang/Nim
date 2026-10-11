# bug #9006: generic params of the type that matched a concept
type Foo[T] = object
type SomeFoo = concept a
  a.type is Foo[a.type.T]

proc fun(s: SomeFoo): string =
  type T2 = s.type.T
  var x: T2
  doAssert T2 is int
  result = $x & " " & $s.type.T

var s: Foo[int]
doAssert fun(s) == "0 int"
