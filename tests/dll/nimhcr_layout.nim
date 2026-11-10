discard """
  exitcode: 1
  outputsub: "hot code reloading: the type of global"
"""

# A reload that changes the type of a global must not go on: the runtime keeps
# the global's old memory, and the new code would read it with the new layout.
# The refusal is caught and printed instead of left uncaught: with hot code
# reloading, the C++ backend does not report an uncaught exception (it
# crashes in its terminate handler).
# The new version of nimhcr_layout_a adds a field, so the size changes.

import os, osproc, strutils, hotcodereloading
import nimhcr_layout_a

echo show()
let dir = currentSourcePath().parentDir
let module = dir / "nimhcr_layout_a.nim"
let original = readFile(module)
copyFile(dir / "nimhcr_layout_a_1.nim", module)
let cmd = commandLineParams().join(" ").replace(" --forceBuild")
let (output, code) = execCmdEx(cmd)
# Restore the fixture before reloading: the refusal is expected to end the
# program.
writeFile(module, original)
if code != 0:
  echo "COMPILATION ERROR: ", output
  quit 2
try:
  performCodeReload()
  echo "not reached: ", show()
except CodeReloadRefusedError as e:
  echo e.msg
  quit 1
