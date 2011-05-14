import macros

proc testProc: string {.compileTime.} =
  result = ""
  result = result & ""

when true:
  macro test(n: stmt): stmt =
    result = newNimNode(nnkStmtList)
    echo "#", testProc(), "#"
  test:
    "hi"

const
  x = testProc()
  
echo "##", x, "##"


