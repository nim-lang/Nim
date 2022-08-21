block:
  var x: string
  var y = "foo"

  echo x
  doAssert x == ""
  doAssert "" == x

  add(x, y)
  y[0] = 'm'
  doAssert y == "moo" and x == "foo"

block:
  var x = "foo".cstring
  var y: string
  add(y, x)
  doAssert y == "foo"

block:
  type Foo = object
    a: string
  var foo = Foo(a: "foo")
  var y = move foo.a
  doAssert foo.a.len == 0
  doAssert y == "foo"
