discard """
  errormsg: "cannot evaluate at compile time: x"
"""

var x: array[100, char]
template foo : char = x[42]

const myConst = foo
