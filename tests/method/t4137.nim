discard """
  targets: "c cpp"
  matrix: "--warning:Deprecated:off"
  output: '''
x1
y,2
y,2
'''
"""

# bug #4137: methods on a generic object hierarchy
type
  X[T] = object of RootObj
    x: T
  Y[T] = object of X[T]
    y: T

method xxx[T](x: X[T]) {.base.} = echo "x", x.x
method xxx[T](x: Y[T]) = echo "y,", x.y

var x = X[int](x: 1)
var y = Y[int](y: 2)

x.xxx()
y.xxx()

proc viaBase(a: var X[int]) = a.xxx()
viaBase(y)
