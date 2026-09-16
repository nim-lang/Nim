# issue #25826

proc foo(x: var) = x = 123

block:
  var a = 0
  foo(a)
  doAssert a == 123

proc bar(x: var int) =
  foo(x)

block:
  var a = 0
  bar(a)
  doAssert a == 123

proc baz(x: var int): var int = x

block:
  var a = 0
  foo(baz(a))
  doAssert a == 123
