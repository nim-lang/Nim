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