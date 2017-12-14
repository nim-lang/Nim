discard """
  output: '''@[2, 3, 4]321
9.0 4.0
3
@[(Field0: 1, Field1: 2), (Field0: 3, Field1: 5)]
2
@["a", "new one", "c"]
@[1, 2, 3]'''
"""

proc foo[T](x, y: T): T = x

var a = @[1, 2, 3, 4]
var b: array[3, array[2, float]] = [[1.0,2], [3.0,4], [8.0,9]]
echo a[1.. ^1], a[^2], a[^3], a[^4]
echo b[^1][^1], " ", (b[^2]).foo(b[^1])[^1]

b[^1] = [8.8, 8.9]

var c: seq[(int, int)] = @[(1,2), (3,4)]

proc takeA(x: ptr int) = echo x[]

takeA(addr c[^1][0])
c[^1][1] = 5
echo c

proc useOpenarray(x: openArray[int]) =
  echo x[^2]

proc mutOpenarray(x: var openArray[string]) =
  x[^2] = "new one"

useOpenarray([1, 2, 3])

var z = @["a", "b", "c"]
mutOpenarray(z)
echo z

# bug #6675
var y: array[1..5, int] = [1,2,3,4,5]
y[3..5] = [1, 2, 3]
echo y[3..5]
