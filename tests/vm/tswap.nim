discard """
nimout: '''
x.data = @[10]
y = @[11]
x.data = @[11]
y = @[10]'''
"""

# bug #2946

proc testSwap(): int {.compiletime.} =
  type T = object
    data: seq[int]
  var x: T
  x.data = @[10]
  var y = @[11]
  echo "x.data = ", x.data
  echo "y = ", y
  swap(y, x.data)
  echo "x.data = ", x.data
  echo "y = ", y
  result = 99

const something = testSwap()
