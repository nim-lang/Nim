discard """
  output: '''@[2, 3, 4]321
9.0 4.0'''
"""

proc foo[T](x, y: T): T = x

var a = @[1, 2, 3, 4]
var b: array[3, array[2, float]] = [[1.0,2], [3.0,4], [8.0,9]]
echo a[1.. ^1], a[^2], a[^3], a[^4]
echo b[^1][^1], " ", (b[^2]).foo(b[^1])[^1]

b[^1] = [8.8, 8.9]
