discard """
  exitcode: 1
  outputsub: "hot code reloading: the type of global"
"""

# A reload that changes the type of a global must stop: the runtime keeps the
# global's old memory, and the new code would read it with the new layout.
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
# Restore the fixture before reloading: the reload is expected to end the
# program.
writeFile(module, original)
if code != 0:
  echo "COMPILATION ERROR: ", output
  quit 2
performCodeReload()
echo "not reached: ", show()
