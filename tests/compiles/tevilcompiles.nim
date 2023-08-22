# bug #1055
import unittest
type TMatrix*[N,M: static[int], T] = object
  data*: array[0..N*M-1, T]
proc `==`*(a: distinct TMatrix; b: distinct TMatrix): bool =
  result = a.data == b.data

test "c":
  var a = TMatrix[2,2,int](data: [1,2,3,4])
  var b = TMatrix[2,2,int](data: [1,2,3,4])
  check(a == b)

