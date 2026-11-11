discard """
  output: '''
counter 1, version 1
counter 2, version 2
'''
"""

# Hot code reloading of a program built by the IC backend (`--ic:on`): the
# program rebuilds itself with a new version of nimhcr_ic_a and reloads it.
# The global keeps its value across the reload, the procs are the new ones.

import os, osproc, strutils, hotcodereloading
import nimhcr_ic_a

bump()
echo show()
let dir = currentSourcePath().parentDir
let module = dir / "nimhcr_ic_a.nim"
let original = readFile(module)
# written, not copied: the copy would keep the old mtime, and the IC build
# notices a changed module by its mtime
writeFile(module, readFile(dir / "nimhcr_ic_a_1.nim"))
let cmd = commandLineParams().join(" ").replace(" --forceBuild")
let (output, code) = execCmdEx(cmd)
writeFile(module, original)
if code != 0:
  echo "COMPILATION ERROR: ", output
  quit 2
performCodeReload()
bump()
echo show()
