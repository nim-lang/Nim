discard """
  output: "Error: constant expression expected"
  line: 7
"""

var x: array[100, char] 
template Foo : expr = x[42]


const myConst = foo
