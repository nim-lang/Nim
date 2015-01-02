discard """
  msg: "int"
  output: "4"
"""

import typetraits

type ArrayType[T] = distinct T

proc arrayItem(a: ArrayType): auto =
  static: echo(name(type(a).T))
  result = (type(a).T)(4)

var arr: ArrayType[int]
echo arrayItem(arr)

