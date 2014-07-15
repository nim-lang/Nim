import macros

proc testProc: string {.compileTime.} =
  result = ""
  result = result & ""

when true:
  macro test(n: stmt): stmt {.immediate.} =
    result = newNimNode(nnkStmtList)
    echo "#", testProc(), "#"
  test:
    "hi"

const
  x = testProc()
  
echo "##", x, "##"

# bug #1310
static:
    var i, j: set[int8] = {}
    var k = i + j


