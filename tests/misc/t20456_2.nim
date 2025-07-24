discard """
  joinable: false
"""

import std/[osproc, os, strformat]
from stdtest/specialpaths import testsDir

when defined(nimPreviewSlimSystem):
  import std/assertions

const
  nim = getCurrentCompilerExe()
  file = testsDir / "misc" / "m20456.nims"
doAssert execCmd(fmt"{nim} check {file}") == 0
