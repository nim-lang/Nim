discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_guard_dependencies_", "")
var buildId = 0

proc build(source, expected: string; flags: seq[string] = @[]; unknownGuard = false) =
  inc buildId
  let main = dir / "main.nim"
  let output = dir / ("prog" & $buildId).addFileExt(ExeExt)
  writeFile(main, source)
  var args = @[nim, "ic", "--skipParentCfg", "--skipUserCfg", "--colors:off",
    "--hint:Conf:off", "--warnings:off", "--nimcache:" & (dir / ("nc" & $buildId)),
    "--out:" & output]
  args.add flags
  args.add main
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  if not unknownGuard:
    doAssert "which is not installed" notin compiled.output, compiled.output
  let rounds = compiled.output.count(".frontend.build.nif [Exec]")
  let maxRounds = if unknownGuard: 3 else: 2
  doAssert rounds in 1..maxRounds, "unexpected discovery rounds: " & $rounds &
    "\n" & compiled.output
  let executed = execCmdEx(quoteShell(output))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(dir / "selected.nim", "proc answer*(): int = 42\n")
  writeFile(dir / "alternate.nim", "proc answer*(): int = 7\n")
  writeFile(dir / "broken.nim", "import nonexistent_guard_dependency\n")

  block local_constant_aliases:
    build("""
const backend = "foo"
const enabled = backend == "foo"
when enabled:
  import selected
else:
  import broken
echo answer()
""", "42")

  block define_overrides:
    const source = """
const backend {.strdefine: "guard.backend".} = "foo"
const count {.intdefine: "guard.count".} = 3
const enabled {.booldefine: "guard.enabled".} = true
when backend == "foo" and count >= 2 and enabled:
  import selected
else:
  import alternate
echo answer()
"""
    build(source, "42")
    build(source, "7", @["-d:guard.backend=bar"])
    build(source, "7", @["-d:guard.count=0"])
    build(source, "7", @["-d:guard.enabled=off"])

  block empty_strings_and_dotted_defines:
    build("""
const backend {.strdefine.} = ""
when backend == "" and defined(features.guard.enabled):
  import selected
else:
  import broken
echo answer()
""", "42", @["-d:features.guard.enabled"])

  block includes_share_constant_scope:
    writeFile(dir / "settings.nim", "const backend = \"foo\"\n")
    writeFile(dir / "imports.nim", "when backend == \"foo\":\n  import selected\n")
    build("include \"settings\"\ninclude \"imports\"\necho answer()\n", "42")

  block overloaded_operators_remain_unknown:
    build("""
proc `==`(a, b: string): bool = false
const enabled = "foo" == "foo"
when enabled:
  import alternate
else:
  import selected
echo answer()
""", "42", unknownGuard = true)
    build("""
proc `==`(a, b: int): bool = false
when 1 == 1:
  import broken
else:
  import selected
echo answer()
""", "42", unknownGuard = true)
finally:
  removeDir(dir)
