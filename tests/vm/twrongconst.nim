discard """
  errormsg: "cannot evaluate at compile time: x"
  line: 7
"""

var x: array[100, char]
template foo : expr = x[42]

const myConst = foo
