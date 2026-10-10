discard """
  targets: "c"
  joinable: false
"""

# checks --msgFormat:std (default) vs --msgFormat:gcc error message output

import stdtest/specialpaths
import std/[os, osproc, strformat, strutils]

const
  nim = getCurrentCompilerExe()
  badFile = buildDir / "tmsgformat_bad.nim"
  badSource = """
proc p(x: int) = discard
p(1, 2)
"""

createDir(buildDir)
writeFile(badFile, badSource)

proc run(msgFormat: string): (string, int) =
  let opts = if msgFormat.len > 0: "--msgFormat:" & msgFormat else: ""
  execCmdEx(fmt"{nim} c --hints:off --verbosity:0 {opts} {badFile}")

doAssert badFile.fileExists

block:
  let (output, code) = run("gcc")
  doAssert code != 0
  # GNU standard format: file:line:col: Error: message
  doAssert ":2:2: Error: type mismatch" in output, output
  doAssert "(2, 2)" notin output

block:
  let (output, code) = run("std")
  doAssert code != 0
  doAssert "(2, 2) Error: type mismatch" in output, output

block:
  # the default is std
  let (output, code) = run("")
  doAssert code != 0
  doAssert "(2, 2) Error: type mismatch" in output, output

block:
  let (output, code) = run("bogus")
  doAssert code != 0
  doAssert "expected: std|gcc, got: bogus" in output, output

block:
  # the switch is also settable in config files (nim.cfg, project cfg)
  let cfgFile = badFile.string.changeFileExt(".nim.cfg")
  writeFile(cfgFile, "--msgFormat:gcc\n")
  let (output, code) = run("")
  doAssert code != 0
  doAssert ":2:2: Error: type mismatch" in output, output
  removeFile(cfgFile)

# cleanup so this file isn't reused across the test matrix
removeFile(badFile)
