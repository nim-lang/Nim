discard """
  output: '''
v0 1
refused: true
names the global: true
still: v0 1
reloaded: v2 1
'''
"""

# A reload that changes the type of a global is refused before any module is
# re-initialized: the program goes on with the old code, and a later reload
# that keeps the types still works.

import os, osproc, strutils, hotcodereloading
import nimhcr_layout_c

let dir = currentSourcePath().parentDir
let module = dir / "nimhcr_layout_c.nim"
let original = readFile(module)
let cmd = commandLineParams().join(" ").replace(" --forceBuild")

proc rebuildWith(version: string) =
  copyFile(dir / version, module)
  let (output, code) = execCmdEx(cmd)
  # Restore the fixture before reloading, so that the working tree stays clean
  # whatever the reload does.
  writeFile(module, original)
  if code != 0:
    echo "COMPILATION ERROR: ", output
    quit 2

echo show()
rebuildWith("nimhcr_layout_c_1.nim")
try:
  performCodeReload()
  echo "not refused: ", show()
except CodeReloadRefusedError as e:
  echo "refused: true"
  echo "names the global: ", e.msg.startsWith("hot code reloading: the type of global 'st_")
echo "still: ", show()
rebuildWith("nimhcr_layout_c_2.nim")
performCodeReload()
echo "reloaded: ", show()
