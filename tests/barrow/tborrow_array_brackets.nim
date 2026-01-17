##[
This testcase checks that bracket operators can be borrowed on distinct arrays.
]##

type
  Vec4[T] = distinct array[4, T]

proc `[]`*[T](v: Vec4[T], i: int): T {.borrow.}
proc `[]`*[T](v: var Vec4[T], i: int): var T {.borrow.}

block:
  var v: Vec4[float32]
  v[0] = 1.5'f32
  doAssert v[0] == 1.5'f32
