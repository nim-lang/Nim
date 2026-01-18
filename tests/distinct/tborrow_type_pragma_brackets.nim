##[
This testcase checks borrow `[]` pragma applied to the type definition.
]##

type
  MySeq[T] {.borrow: `[]`.} = distinct seq[tuple[x: T, y: T]]

block:
  let points = MySeq(@[(x: 1, y: 2), (x: 5, y: 6)])
  doAssert points[0] == (x: 1, y: 2)
