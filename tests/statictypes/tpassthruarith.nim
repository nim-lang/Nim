discard """
output: '''
[[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]

[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
'''
"""

# https://github.com/nim-lang/Nim/issues/4880

proc `^^`(x: int): int = x * 2

type
  Foo[x: static[int]] = array[x, int]
  Bar[a, b: static[int]] = array[b, Foo[^^a]]

var x: Bar[2, 3]
echo repr(x)

# https://github.com/nim-lang/Nim/issues/2730

type
  Matrix[M,N: static[int]] = distinct array[0..(M*N - 1), int]

proc bigger[M,N](m: Matrix[M,N]): Matrix[(M * N) div 8, (M * N)] =
  discard

proc bigger2[M,N](m: Matrix[M,N]): Matrix[M * 2, N * 2] =
  discard

var m : Matrix[4, 4]
var n = bigger(m)
var o = bigger2(m)

echo repr(m)
echo repr(n)
echo repr(o)

