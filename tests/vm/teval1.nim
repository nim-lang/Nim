
discard """
nimout: "##"
"""

import macros

proc testProc: string {.compileTime.} =
  result = ""
  result = result & ""

when true:
  macro test(n: untyped): untyped =
    result = newNimNode(nnkStmtList)
    echo "#", testProc(), "#"
  test:
    "hi"

const
  x = testProc()

doAssert x == ""

# bug #1310
static:
  var i, j: set[int8] = {}
  var k = i + j

type
  Obj = object
    x: int

converter toObj(x: int): Obj = Obj(x: x)

# bug #10514
block:
  const
    b: Obj = 42
    bar = [b]

  let i_runtime = 0
  doAssert bar[i_runtime] == b
