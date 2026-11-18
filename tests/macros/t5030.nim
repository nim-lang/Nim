discard """
  output: "42"
"""

# bug #5030: macro generated forward declaration and implementation
# sharing one symbol must keep the declared calling convention
import std/macros

proc genProcDeclAndDef(name: var NimNode): NimNode {.compileTime.} =
  result = newStmtList()
  name = genSym(nskProc, "myProc")
  result.add(newProc(name, [newIdentNode("int")], newEmptyNode()))
  result[0][4] = newTree(nnkPragma, newIdentNode("noconv"))
  result.add(copyNimTree(result[0]))
  result[1][4] = newEmptyNode()
  result[1][6] = newStmtList(newLit(42))

type MyProcType = proc(): int {.noconv.}

macro setProcVar(varName: MyProcType) =
  var procName: NimNode
  result = genProcDeclAndDef(procName)
  result.add(newAssignment(varName, procName))

var myProcVar: MyProcType
setProcVar(myProcVar)
echo myProcVar()
