discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_speculative_imports_", "")
var buildId = 0

proc build(source, expected: string) =
  inc buildId
  let main = dir / "main.nim"
  let output = dir / ("prog" & $buildId).addFileExt(ExeExt)
  writeFile(main, source)
  let compiled = execCmdEx(quoteShellCommand([
    nim, "ic", "--skipParentCfg", "--skipUserCfg", "--colors:off",
    "--hint:Conf:off", "--warnings:off", "--nimcache:" & (dir / ("nc" & $buildId)),
    "--out:" & output, main
  ]), workingDir = dir)
  doAssert compiled.exitCode == 0, compiled.output
  let rounds = compiled.output.count(".frontend.build.nif [Exec]")
  doAssert rounds in 1..2, "unexpected discovery rounds: " & $rounds &
    "\n" & compiled.output
  let executed = execCmdEx(quoteShell(output))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(dir / "leaf.nim", "proc answer*(): int = 42\n")
  writeFile(dir / "middle.nim", "import leaf\nexport leaf\n")
  writeFile(dir / "selected.nim", "import middle\nexport middle\n")
  writeFile(dir / "broken.nim", "import nonexistent_guard_dependency\n")

  block ordinary_imports_do_not_inherit_the_callers_guard:
    # Without the fix, discovery follows this chain one import per round.
    build("""
proc choose(): bool = true
when choose():
  import selected
echo answer()
""", "42")

  block imported_modules_keep_their_own_guards:
    writeFile(dir / "guarded.nim", """
proc choose(): bool = false
when choose():
  import broken
proc answer*(): int = 42
""")
    build("""
proc choose(): bool = true
when choose():
  import guarded
echo answer()
""", "42")

  block siblings_keep_the_callers_guard:
    build("""
proc choose(): bool = false
when choose():
  import selected, broken
echo 42
""", "42")

  block includes_inherit_the_callers_guard:
    writeFile(dir / "unused.nim", "import broken\n")
    build("""
proc choose(): bool = false
when choose():
  include "unused"
echo 42
""", "42")
finally:
  removeDir(dir)
