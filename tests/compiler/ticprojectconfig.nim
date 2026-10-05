discard
  """
  joinable: false
"""

# Projects sharing a nimcache must load their own config.nims and project cfg.
import std/[assertions, os, osproc, strutils, tempfiles, tables, times]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_project_config_", "")
let cache = dir / "nc"
let binary = dir / "prog".addFileExt(ExeExt)

proc build(project, expected: string, reuseShared = false) =
  let args = [
    nim,
    "ic",
    "--hints:off",
    "--warnings:off",
    "--skipUserCfg",
    "--nimcache:" & cache,
    "--out:" & binary,
    dir / project,
  ]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, project & ":\n" & compiled.output
  if reuseShared:
    doAssert "shared module semchecked" notin compiled.output,
      project & ":\n" & compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, project & ":\n" & executed.output

proc semanticCache(): Table[string, Time] =
  for file in walkFiles(cache / "*.s.bif"):
    result[file] = getLastModificationTime(file)

try:
  for subdir in ["src", "tests", "examples", "demos"]:
    createDir(dir / subdir)
  writeFile(
    dir / "src" / "shared.nim",
    """
static: echo "shared module semchecked"
const sharedValue {.intdefine.} = 42
proc value*(): int = sharedValue
""",
  )
  writeFile(
    dir / "src" / "main.nim",
    """
import shared
doAssert not defined(testConfig)
doAssert not defined(exampleConfig)
doAssert not defined(otherProjectConfig)
echo "app ", value()
""",
  )
  writeFile(
    dir / "tests" / "config.nims",
    """
switch("path", "../src")
switch("define", "testConfig")
""",
  )
  writeFile(
    dir / "tests" / "main.nim",
    """
import shared
doAssert defined(testConfig)
doAssert not defined(exampleConfig)
echo "tests ", value()
""",
  )
  writeFile(
    dir / "examples" / "config.nims",
    """
switch("path", "../src")
switch("define", "exampleConfig")
""",
  )
  writeFile(
    dir / "examples" / "main.nim",
    """
import shared
doAssert defined(exampleConfig)
doAssert not defined(testConfig)
doAssert not defined(otherProjectConfig)
echo "example ", value()
""",
  )
  writeFile(dir / "examples" / "other.nim.cfg", "--define:otherProjectConfig\n")
  writeFile(
    dir / "examples" / "other.nim",
    """
import shared
doAssert defined(exampleConfig)
doAssert defined(otherProjectConfig)
doAssert not defined(testConfig)
echo "other ", value()
""",
  )
  writeFile(dir / "demos" / "config.nims", readFile(dir / "examples" / "config.nims"))
  writeFile(dir / "demos" / "main.nim", readFile(dir / "examples" / "main.nim"))

  # The first three entry points deliberately have the same basename.
  for project, expected in [
    ("src/main.nim", "app 42"),
    ("tests/main.nim", "tests 42"),
    ("examples/main.nim", "example 42"),
    ("examples/other.nim", "other 42"),
  ].items:
    build(project, expected)
    build(project, expected, reuseShared = true)

  # Returning to a cached project must restore its own paths and defines.
  build("src/main.nim", "app 42")
  build("tests/main.nim", "tests 42")
  build("examples/main.nim", "example 42")

  # Different config files with identical resolved settings must reuse the
  # existing semantic cache. Only the new entry point needs its own BIF.
  let before = semanticCache()
  doAssert before.len > 0
  build("demos/main.nim", "example 42", reuseShared = true)
  for file, modified in before:
    doAssert getLastModificationTime(file) == modified, file & " was rebuilt"
  build("examples/main.nim", "example 42", reuseShared = true)
  for file, modified in before:
    doAssert getLastModificationTime(file) == modified, file & " was rebuilt"

  # A real setting change still invalidates shared modules, even though their
  # own source files and the importing project's source are unchanged.
  let config = dir / "examples" / "config.nims"
  writeFile(config, readFile(config) & "\nswitch(\"define\", \"sharedValue:43\")\n")
  build("examples/main.nim", "example 43")
  build("demos/main.nim", "example 42")
finally:
  removeDir(dir)
