discard """
  output: '''top level statements are executed!
2.0
my secret
'''
"""

## Example program that demonstrates how to use the
## compiler as an API to embed into your own projects.

import "../../compiler" / [ast, vmdef, vm, nimeval]
import std / [os]

proc main() =
  let std = findNimStdLib()
  if std.len == 0:
    quit "cannot find Nim's standard library"

  var intr = createInterpreter("myscript.nim", [std, getAppDir()])
  intr.implementRoutine("*", "exposed", "addFloats", proc (a: VmArgs) =
    setResult(a, getFloat(a, 0) + getFloat(a, 1) + getFloat(a, 2))
  )

  intr.evalScript()

  let foreignProc = selectRoutine(intr, "hostProgramRunsThis")
  if foreignProc == nil:
    quit "script does not export a proc of the name: 'hostProgramRunsThis'"
  let res = intr.callRoutine(foreignProc, [newFloatNode(nkFloatLit, 0.9),
                                           newFloatNode(nkFloatLit, 0.1)])
  if res.kind == nkFloatLit:
    echo res.floatVal
  else:
    echo "bug!"

  let foreignValue = selectUniqueSymbol(intr, "hostProgramWantsThis")
  if foreignValue == nil:
    quit "script does not export a global of the name: hostProgramWantsThis"
  let val = intr.getGlobalValue(foreignValue)
  if val.kind in {nkStrLit..nkTripleStrLit}:
    echo val.strVal
  else:
    echo "bug!"

  destroyInterpreter(intr)

if existsEnv("NIM_EXE_NOT_IN_PATH"):
  # effectively disable this test as 'nim' is not in the PATH so tcompilerapi
  # cannot find Nim's standard library:
  echo "top level statements are executed!"
  echo "2.0"
  echo "my secret"
else:
  main()
