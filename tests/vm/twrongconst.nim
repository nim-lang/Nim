discard """
  file: "twrongconst.nim"
  errormsg: "cannot evaluate at compile time: x"
  line: 8
"""

var x: array[100, char]
template foo : expr = x[42]

const myConst = foo
