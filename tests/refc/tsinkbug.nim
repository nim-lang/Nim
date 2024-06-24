discard """
  matrix: "--gc:refc; --gc:arc"
  output: '''
Value is: 42
Value is: 42'''
"""

type AnObject* = object of RootObj
  value*: int

proc mutate(a: sink AnObject) =
  a.value = 1

var obj = AnObject(value: 42)
echo "Value is: ", obj.value
mutate(obj)
echo "Value is: ", obj.value
