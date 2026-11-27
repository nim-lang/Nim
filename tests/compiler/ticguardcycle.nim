discard """
  joinable: false
"""

# `nim ic` decides `appType` guards before sem, and recovers when an
# undecidable guard put a dead import into a cycle.

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_guard_cycle_", "")
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
  var exe = output
  when defined(macosx):
    # `--app:gui` moves the executable into an app bundle on macOS.
    if "--app:gui" in flags:
      exe = output & ".app" / "Contents" / "MacOS" / extractFilename(output)
  let executed = execCmdEx(quoteShell(exe))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(dir / "selected.nim", "proc answer*(): int = 42\n")
  writeFile(dir / "alternate.nim", "proc answer*(): int = 7\n")
  writeFile(dir / "broken.nim", "import nonexistent_guard_dependency\n")

  block app_type:
    writeFile(dir / "guiswitch.nim", """
when appType == "gui":
  import selected
else:
  import alternate
echo answer()
""")
    build("guiswitch.nim", "7")
    build("guiswitch.nim", "42", @["--app:gui"])

  block undecidable_guard_inside_cycle:
    # https://forum.nim-lang.org/t/14268#86663: syncio's
    # `when defined(windows) and appType == "console": import std/exitprocs`
    # folded exitprocs into system's cycle group while the branch was dead in
    # sem, so the group never produced it and its importers stalled forever.
    writeFile(dir / "cycmain.nim", "import cycb, cycd\necho bval + dval\n")
    writeFile(dir / "cycb.nim",
      "const bval* = 1\nwhen declared(nothingHere):\n  import cycc\n")
    writeFile(dir / "cycc.nim", "import cycb\nconst cval* = bval + 1\n")
    writeFile(dir / "cycd.nim", "import cycc\nconst dval* = cval + 1\n")
    build("cycmain.nim", "4", decided = false)
finally:
  removeDir(dir)
