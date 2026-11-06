discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_guard_dependencies_", "")
var buildId = 0

proc build(source, expected: string; flags: seq[string] = @[]; directGuard = false) =
  inc buildId
  let main = dir / "main.nim"
  let output = dir / ("prog" & $buildId).addFileExt(ExeExt)
  writeFile(main, source)
  var args = @[nim, "ic", "--skipParentCfg", "--skipUserCfg", "--colors:off",
    "--hint:Conf:off", "--warnings:off", "--nimcache:" & (dir / ("nc" & $buildId)),
    "--out:" & output]
  args.add flags
  args.add main
  let compiled = execCmdEx(quoteShellCommand(args), workingDir = dir)
  doAssert compiled.exitCode == 0, compiled.output
  if directGuard:
    doAssert "module(s) deferred behind undecidable" notin compiled.output, compiled.output
  let rounds = compiled.output.count(".frontend.build.nif [Exec]")
  doAssert rounds in 1..3, "unexpected discovery rounds: " & $rounds & "\n" & compiled.output
  let executed = execCmdEx(quoteShell(output))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(dir / "selected.nim", "proc answer*(): int = 42\n")
  writeFile(dir / "alternate.nim", "proc answer*(): int = 7\n")
  writeFile(dir / "broken.nim", "import nonexistent_guard_dependency\n")

  block direct_boolean_aliases:
    build("""
const featureEnabled = true
const enabled = (feature_enabled)
when enabled:
  import selected
echo answer()
""", "42", directGuard = true)

  block booldefine_overrides:
    const source = """
const enabled* {.booldefine: "guard.enabled".} = true
when enabled:
  import selected
else:
  import alternate
echo answer()
"""
    build(source, "42")
    build(source, "7", @["-d:guard.enabled=off"])
    build(source, "42", @["-d:guard.enabled=on"])

  block false_booldefine_defaults:
    const source = """
const enabled {.booldefine.} = false
when enabled:
  import selected
  echo answer()
else:
  echo 7
"""
    build(source, "7", directGuard = true)
    build(source, "42", @["-d:enabled"], directGuard = true)

  block includes_share_constant_scope:
    writeFile(dir / "settings.nim", "const enabled = true\n")
    writeFile(dir / "imports.nim", "when enabled:\n  import selected\n")
    build("include \"settings\"\ninclude \"imports\"\necho answer()\n", "42",
      directGuard = true)

  block dotted_defines:
    build("""
when defined(features.guard.enabled):
  import selected
echo answer()
""", "42", @["-d:features.guard.enabled"], directGuard = true)

  block imported_boolean_operators:
    # Imported macros can introduce overloads that the source scan cannot see.
    writeFile(dir / "operators.nim", """
import std/macros
macro installOperators*(): untyped =
  parseStmt("proc `and`(a, b: bool): bool = true\n" &
    "proc `or`(a, b: bool): bool = false\n" &
    "proc `not`(a: bool): bool = false\n" &
    "proc `==`(a, b: bool): bool = false\n")
""")
    build("""
import operators
installOperators()
const left = false
const right = false
when left and right:
  import selected
else:
  import broken
echo answer()
""", "42")
    build("""
import operators
installOperators()
const left = true
const right = true
when left or right:
  import broken
else:
  import selected
echo answer()
""", "42")
    build("""
import operators
installOperators()
const enabled = false
when not enabled:
  import broken
else:
  import selected
echo answer()
""", "42")
    build("""
import operators
installOperators()
const left = true
const right = true
when left == right:
  import broken
else:
  import selected
echo answer()
""", "42")

  block initializer_expressions_stay_unknown:
    build("""
import operators
installOperators()
const enabled = false and false
when enabled:
  import selected
else:
  import broken
echo answer()
""", "42")
finally:
  removeDir(dir)
