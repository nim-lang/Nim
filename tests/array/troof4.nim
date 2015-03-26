discard """
  errormsg: "no surrounding array access context for '^'"
  line: "37"
"""

proc foo[T](x, y: T): T = x

var a = @[1, 2, 3, 4]
var b: array[3, array[2, float]] = [[1.0,2], [3.0,4], [8.0,9]]
echo a[1.. ^1], a[^2], a[^3], a[^4]
echo b[^1][^1], " ", (b[^2]).foo(b[^1])[^1]

type
  MyArray = object
    a, b, c: float

var
  ma = MyArray(a: 1.0, b: 2.0, c: 3.0)

proc len(x: MyArray): int = 3

proc `[]=`(x: var MyArray; idx: range[0..2]; val: float) =
  case idx
  of 0: x.a = val
  of 1: x.b = val
  of 2: x.c = val

proc `[]`(x: var MyArray; idx: range[0..2]): float =
  case idx
  of 0: result = x.a
  of 1: result = x.b
  of 2: result = x.c

ma[^1] = 8.0
echo ma, ma[^2]

echo(^1)
