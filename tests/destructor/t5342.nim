discard """
  matrix: "--gc:refc; --gc:arc"
  output: '''
1
2
here
2
1
'''
"""


type
  A = object
    id: int
  B = object
    a: A
proc `=destroy`(a: var A) = echo a.id
var x = A(id: 1)
var y = B(a: A(id: 2))
`=destroy`(x)
`=destroy`(y)
echo "here"