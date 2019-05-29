discard """
  output: '''calling!stuff
calling!stuff
'''
"""

# issue #7792

import macros


proc callProc(str: string) =
  echo "calling!" & str


macro testMacro(code: typed): untyped =
  let stmtList = newNimNode(nnkStmtList)

  let stmts = code[6]

  for n in stmts.children:
    # the error happens here
    stmtList.add(newCall(bindSym("callProc"), newLit("stuff")))

  code[6] = stmtList

  result = newEmptyNode()


proc main() {.testMacro.} =
  echo "test"
  echo "test2"


when isMainModule:
  main()
