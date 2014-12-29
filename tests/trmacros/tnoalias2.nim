discard """
  output: '''0'''
"""

# bug #206
template optimizeOut{testFunc(a, b)}(a: int, b: int{alias}) : expr = 0

proc testFunc(a, b: int): int = result = a + b
var testVar = 1
echo testFunc(testVar, testVar)


template ex{a = b + c}(a : int{noalias}, b, c : int) =
  a = b
  inc a, b
  echo "came here"

var x = 5
x = x + x
