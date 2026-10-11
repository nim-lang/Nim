discard
  """
  joinable: false
"""

import std/[assertions, os, osproc, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("testament_ic_options_", "")
let fixture = dir / "tests" / "ic" / "toptions.nim"

try:
  createDir(fixture.parentDir)
  writeFile(dir / "config.nims", "switch(\"define\", \"unexpectedParentConfig\")\n")
  writeFile(
    fixture,
    """
#? metamorphic

#!FILE main.nim
const CliMessage {.strdefine.} = "missing"
doAssert not defined(unexpectedParentConfig)
doAssert CliMessage == "two words"
when defined(stepFlag):
  echo "step"
else:
  echo "base"
#!STEP expect: base

#!FLAGS -d:stepFlag
#!STEP expect: step

#!FLAGS
#!STEP expect: base
""",
  )
  let args = [
    ("testament" / "testament").addFileExt(ExeExt),
    "--nim:" & nim,
    "--colors:off",
    "--backendLogging:off",
    "r",
    fixture,
    "--skipParentCfg",
    "--skipUserCfg",
    "--define:CliMessage=two words",
  ]
  let run = execCmdEx(quoteShellCommand(args))
  doAssert run.exitCode == 0, run.output
finally:
  removeDir(dir)
