discard """
  targets: "c"
  matrix: "--mm:refc; --mm:orc"
  joinable: false
"""

import compiler/[llstream, nimeval]
import std/os

# Measure the host VM's heap: getOccupiedMem inside a static block would not
# measure the compiler's allocations. Warm up code generation before measuring.
let lib = findNimStdLibCompileTime()
let interpreter = createInterpreter("t26273_script.nim",
  [lib, lib / "pure", lib / "core"])
let script = llStreamOpen("""
iterator fields(values: var seq[(int, int)]): var int =
  yield values[0][0]

iterator addresses(values: var seq[int]): ptr int =
  yield addr values[0]

block:
  var tuples = @[(1, 2)]
  for value in fields(tuples):
    value = 3
  doAssert tuples == @[(3, 2)]

  var values = @[1]
  for address in addresses(values):
    address[] = 2
  doAssert values == @[2]

proc exercise*() =
  for i in 0 ..< 32:
    # #26273: each iteration used to permanently root a fresh string node.
    for value in @[newString(65536)]:
      doAssert value.len == 65536

    for value in [newString(65536)]:
      doAssert value.len == 65536

    var values = @[newString(65536)]
    for value in values.mitems:
      value[0] = 'x'
    doAssert values[0][0] == 'x'

    # Exercise the slice branch of the borrowed-address opcode too.
    for value in values.toOpenArray(0, 0):
      doAssert value.len == 65536
      doAssert value[0] == 'x'
""")
interpreter.evalScript(script)
llStreamClose(script)
let exercise = interpreter.selectRoutine("exercise")
doAssert exercise != nil
discard interpreter.callRoutine(exercise, [])
GC_fullCollect()
let before = getOccupiedMem()
for i in 0 ..< 8:
  discard interpreter.callRoutine(exercise, [])
GC_fullCollect()
let retained = getOccupiedMem() - before
# The old GC_ref calls retain at least 16 MiB here. Allow small bookkeeping
# differences without depending on platform-specific process RSS measurements.
doAssert retained < 1024 * 1024, "VM loop retained " & $retained & " bytes"
destroyInterpreter(interpreter)
