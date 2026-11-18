discard """
  output: '''
13.5
5
xy
'''
"""

# bug #6622: generic forward declaration used before its implementation
proc myProc[T](arg_1: int, arg_2: T): T

var myVar: float = myProc(1, 12.5)
var myInt = myProc(2, 3)

proc myProc[T](arg_1: int, arg_2: T): T =
  result = T(arg_1) + arg_2

echo myVar
echo myInt

proc twice[T](x: T): T
echo twice("x")
proc twice[T](x: T): T =
  var y: T = x
  result = y & "y"
