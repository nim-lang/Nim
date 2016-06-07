
# bug #4124

import sequtils

type
    Foo = distinct string

var
  foo: Foo

type
    Alias = (type(foo))
var
  a: Alias

a = foo

when true:
  var xs = @[1,2,3]

  proc asFoo(i: string): Foo =
      Foo(i)

  var xx = xs.mapIt(asFoo($(it + 5)))
