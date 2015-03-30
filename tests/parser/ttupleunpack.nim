discard """
  file: "ttupleunpack.nim"
  output: ""
  exitcode: 0
"""
proc foo(): tuple[x, y, z: int] =
  return (4, 2, 3)

var (x, _, y) = foo()
doAssert x == 4
doAssert y == 3

iterator bar(): tuple[x, y, z: int] =
  yield (1,2,3)

for x, y, _ in bar():
  doAssert x == 1
  doAssert y == 2
