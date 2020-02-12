discard """
  output: '''top level statements are executed!
(ival: 10, fval: 2.0)
2.0
my secret
11
12
'''
  joinable: "false"
"""

## Example program that demonstrates how to use the
## compiler as an API to embed into your own projects.

import "../../compiler" / [ast, vmdef, vm, nimeval, llstream]
import std / [os]

proc main() =
  let std = findNimStdLibCompileTime()
  var intr = createInterpreter("myscript.nim",[std, parentDir(currentSourcePath)])
  intr.implementRoutine("*", "exposed", "addFloats", proc (a: VmArgs) =
    setResult(a, getFloat(a, 0) + getFloat(a, 1) + getFloat(a, 2))
  )

  intr.evalScript()

  let foreignProc = selectRoutine(intr, "hostProgramRunsThis")
  if foreignProc == nil:
    quit "script does not export a proc of the name: 'hostProgramRunsThis'"
  let res = intr.callRoutine(foreignProc, [newFloatNode(nkFloatLit, 0.9),
                                           newFloatNode(nkFloatLit, 0.1)])
  doAssert res.kind == nkFloatLit
  echo res.floatVal

  let foreignValue = selectUniqueSymbol(intr, "hostProgramWantsThis")
  if foreignValue == nil:
    quit "script does not export a global of the name: hostProgramWantsThis"
  let val = intr.getGlobalValue(foreignValue)
  doAssert val.kind in {nkStrLit..nkTripleStrLit}
  echo val.strVal
  destroyInterpreter(intr)

main()

block issue9180:
  proc evalString(code: string, moduleName = "script.nim") =
    let stream = llStreamOpen(code)
    let std = findNimStdLibCompileTime()
    var intr = createInterpreter(moduleName, [std])
    intr.evalScript(stream)
    destroyInterpreter(intr)
    llStreamClose(stream)

  evalString("echo 10+1")
  evalString("echo 10+2")
