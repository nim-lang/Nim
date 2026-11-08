discard """
  joinable: false
"""

# `nim ic` decides `when` guards over module-level `{.*define.}` consts before
# sem; nifler records them in the deps file.

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_define_guards_", "")
var buildId = 0

proc build(main, expected: string; flags: seq[string] = @[]; decided = true) =
  inc buildId
  let output = dir / ("prog" & $buildId).addFileExt(ExeExt)
  var args = @[nim, "ic", "--skipParentCfg", "--skipUserCfg", "--colors:off",
    "--hint:Conf:off", "--warnings:off", "--nimcache:" & (dir / ("nc" & $buildId)),
    "--out:" & output]
  args.add flags
  args.add dir / main
  let compiled = execCmdEx(quoteShellCommand(args), workingDir = dir)
  doAssert compiled.exitCode == 0, compiled.output
  if decided:
    doAssert "deferred behind undecidable" notin compiled.output, compiled.output
  let executed = execCmdEx(quoteShell(output))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(dir / "selected.nim", "proc answer*(): int = 42\n")
  writeFile(dir / "alternate.nim", "proc answer*(): int = 7\n")
  writeFile(dir / "broken.nim", "import nonexistent_guard_dependency\n")

  block strdefine:
    writeFile(dir / "strdef.nim", """
const backend {.strdefine: "pkg.backend".} = "pixie"
when backend == "harfbuzz":
  import broken
elif backend == "other":
  import selected
else:
  import alternate
echo answer()
""")
    build("strdef.nim", "7")
    build("strdef.nim", "42", @["-d:pkg.backend=other"])

  block booldefine:
    writeFile(dir / "booldef.nim", """
const enabled* {.booldefine: "guard.enabled".} = true
when enabled:
  import selected
else:
  import alternate
echo answer()
""")
    build("booldef.nim", "42")
    build("booldef.nim", "7", @["-d:guard.enabled=off"])

  block intdefine_and_generic_define:
    writeFile(dir / "intdef.nim", """
const level {.intdefine.} = 1
const flavour {.define.}: string = "plain"
when level == 2 and flavour == "plain":
  import selected
else:
  import alternate
echo answer()
""")
    build("intdef.nim", "7")
    build("intdef.nim", "42", @["-d:level=2"])

  block define_under_when:
    writeFile(dir / "underwhen.nim", """
when defined(features.on):
  const enabled {.booldefine.} = true
else:
  const enabled {.booldefine.} = false
when enabled:
  import selected
else:
  import alternate
echo answer()
""")
    build("underwhen.nim", "7")
    build("underwhen.nim", "42", @["-d:features.on"])

finally:
  removeDir(dir)
