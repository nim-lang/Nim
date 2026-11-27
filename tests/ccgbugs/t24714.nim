discard """
  targets: "c"
"""

# bug #24714
discard (newSeq[set['0'..'9']](),)
discard (newSeq[set['a'..'z']](),)

# Bigger version of the bug
type
  A = range[0 .. 5]
  B = range[0 .. 7]

proc field[T](): iterator (): tuple[value: seq[T]] {.closure.} =
  result = iterator (): tuple[value: seq[T]] {.closure.} =
    yield (@[T(1)],)

let a = field[A]()
let b = field[B]()

doAssert a()[0] == @[A(1)]
doAssert b()[0] == @[B(1)]
