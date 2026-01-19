##[
This testcase checks that bracket operators can be borrowed on distinct arrays.
]##

type
  Vec4 = distinct array[4, float32]

proc `[]`*(v: Vec4, i: int): float32 {.borrow.}
proc `[]`*(v: var Vec4, i: int): var float32 {.borrow.}
proc `[]=`*(v: var Vec4, i: int, val: float32) {.borrow.}

block:
  var v: Vec4
  v[0] = 1.5'f32
  doAssert v[0] == 1.5'f32
