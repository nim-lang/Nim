discard """
  matrix: "--gc:refc; --gc:arc"
  output: '''
~A
~A
~A
~A
'''
"""


type
  A = object
  B = object
    a: A

proc `=destroy`(a: var A) = echo "~A"

var x = A()
var y = B()
`=destroy`(x)
`=destroy`(y)
