discard """
  errormsg: "cannot evaluate at compile time: x"
  line: 9
"""

var x: array[100, char]
template Foo : expr = x[42]

const myConst = foo
