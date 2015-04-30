discard """
  output: '''ref ref T ptr S'''
"""

proc foo[T](x: T) =
  echo "only T"

proc foo[T](x: ref T) =
  echo "ref T"

proc foo[T, S](x: ref ref T; y: ptr S) =
  echo "ref ref T ptr S"

proc foo[T, S](x: ref T; y: ptr S) =
  echo "ref T ptr S"

proc foo[T](x: ref T; default = 0) =
  echo "ref T; default"

var x: ref ref int
var y: ptr ptr int
foo(x, y)
