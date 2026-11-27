discard """
  output: '''
5
version 2: 5
'''
"""

# Hot code reloading of a program built by the IC backend (`--ic:on`): the
# program rebuilds itself with a new version of nimhcr_layout_a (the module
# of nimhcr_layout, here with the same layout) and reloads it. The global
# keeps its value across the reload, the proc is the new one.

import os, osproc, strutils, hotcodereloading
import nimhcr_layout_a

st.a = 5
echo show()
let dir = currentSourcePath().parentDir
let module = dir / "nimhcr_layout_a.nim"
let original = readFile(module)
# written, not copied: the copy would keep the old mtime, and the IC build
# notices a changed module by its mtime
writeFile(module, original.replace("""proc show*(): string = $st.a""",
                                   """proc show*(): string = "version 2: " & $st.a"""))
let cmd = commandLineParams().join(" ").replace(" --forceBuild")
let (output, code) = execCmdEx(cmd)
writeFile(module, original)
if code != 0:
  echo "COMPILATION ERROR: ", output
  quit 2
performCodeReload()
echo show()
