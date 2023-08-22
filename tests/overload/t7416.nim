type
  Foo[T] = object
  IntFoo = Foo[int]

proc bar(b: object|tuple) = discard
proc bar(b: IntFoo) = discard

var f: IntFoo
bar(f)