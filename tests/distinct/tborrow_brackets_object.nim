##[
This testcase checks that bracket operators can be borrowed from a user defined object
type.
]##

type
  BaseBox = object
    data: seq[int]

proc `[]`*(b: BaseBox, i: int): lent int =
  b.data[i]

proc `[]`*(b: var BaseBox, i: int): var int =
  b.data[i]

proc `[]=`*(b: var BaseBox, i: int, newVal: int) =
  b.data[i] = newVal

type
  BorrowedBox = distinct BaseBox

proc `[]`*(b: BorrowedBox, i: int): lent int {.borrow.}
proc `[]=`*(b: var BorrowedBox, i: int, newVal: int) {.borrow.}

# Section: Borrowed bracket access mutates distinct object wrappers.
block:
  var boxed = BorrowedBox(BaseBox(data: @[1, 2, 3]))
  doAssert boxed[0] == 1
  boxed[0] = 10
  doAssert boxed[0] == 10
  let view = boxed[1]
  doAssert view == 2
