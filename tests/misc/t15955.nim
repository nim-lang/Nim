discard """
joinable: false
"""

import stdtest/specialpaths
import std/[osproc, strformat, os]

const
  nim = getCurrentCompilerExe()
  buildLib = buildDir / "libD20220923T19380"
  currentDir = splitFile(currentSourcePath).dir
  file = currentDir / "m15955.nim"
  main = currentDir / "m15955_main.nim"


proc runCmd(cmd: string) =
  let (msg, code) = execCmdEx(cmd)
  doAssert code == 0, msg


runCmd fmt"{nim} c -o:{buildLib} --nomain --nimMainPrefix:libA -f --app:staticlib {file}"
runCmd fmt"{nim} c -r {main}"
