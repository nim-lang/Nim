##[
This testcase checks that bracket operators can be borrowed on distinct arrays.
]##

type
  Vec4 = distinct array[4, float32]
  Vec4Alt = distinct array[4, float32]

proc `[]`*(v: Vec4, i: int): float32 {.borrow.}
proc `[]`*(v: var Vec4, i: int): var float32 {.borrow.}
proc `[]=`*(v: var Vec4, i: int, val: float32) {.borrow.}
proc `[]`*(v: Vec4Alt, i: int): float32 {.borrow.}
proc `[]`*(v: var Vec4Alt, i: int): var float32 {.borrow.}
proc `[]=`*(v: var Vec4Alt, i: int, val: float32) {.borrow.}

# Section: Borrowed bracket access and updates for distinct arrays.
block:
  var v: Vec4
  v[0] = 1.5'f32
  doAssert v[0] == 1.5'f32
  var w: Vec4Alt
  w[0] = 2.5'f32
  doAssert w[0] == 2.5'f32
