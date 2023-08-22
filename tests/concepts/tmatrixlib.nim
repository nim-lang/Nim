discard """
output: "0"
"""

import matrix, matrixalgo

import typetraits # XXX: this should be removed

var m: Matrix[3, 3, int]
var projectionMatrix: Matrix[4, 4, float]

echo m.transposed.determinant
setPerspectiveProjection projectionMatrix

template ok(x) = assert x
template no(x) = assert(not x)

static:
  ok projectionMatrix is AnyTransform3D
  no m is AnyTransform3D
  
  type SquareStringMatrix = Matrix[5, 5, string]
  
  ok SquareStringMatrix is AnyMatrix
  ok SquareStringMatrix is AnySquareMatrix
  no SquareStringMatrix is AnyTransform3D
  
  ok Matrix[5, 10, int] is AnyMatrix
  no Matrix[7, 15, float] is AnySquareMatrix
  no Matrix[4, 4, int] is AnyTransform3D

