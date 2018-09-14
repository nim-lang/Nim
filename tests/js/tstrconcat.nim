var x: string
var y = "foo"
add(x, y)
y[0] = 'm'
doAssert y == "moo" and x == "foo"
