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

proc build(project, expected: string, reuseShared = false, rebuildShared = false) =
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
  if rebuildShared:
    doAssert "shared module semchecked" in compiled.output,
      project & ":\n" & compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, project & ":\n" & executed.output

proc semanticCache(): Table[string, Time] =
  for file in walkFiles(cache / "*.s.bif"):
    result[file] = getLastModificationTime(file)

try:
  for subdir in ["src", "tests", "examples", "demos", "extra"]:
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
  # Running another NimScript config implicitly appends the library path again.
  # It must not change the fingerprint when the effective settings match.
  writeFile(dir / "demos" / "configured.nims", "discard\n")
  writeFile(dir / "demos" / "configured.nim", readFile(dir / "demos" / "main.nim"))
  writeFile(
    dir / "examples" / "generated.nim",
    """
import std/macros
macro importShared(): untyped = parseStmt("import shared")
importShared()
echo "generated ", value()
""",
  )

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
  for project in [
    "demos/main.nim", "demos/configured.nim", "demos/main.nim", "examples/main.nim"
  ]:
    build(project, "example 42", reuseShared = true)
    for file, modified in before:
      doAssert getLastModificationTime(file) == modified, file & " was rebuilt"

  # A real setting change still invalidates shared modules, even though their
  # own source files and the importing project's source are unchanged.
  let config = dir / "examples" / "config.nims"
  writeFile(config, readFile(config) & "\nswitch(\"define\", \"sharedValue:43\")\n")
  # The scanner cannot see this import. A BIF from the previous configuration
  # must not let sem succeed before the module is discovered and rebuilt.
  build("examples/generated.nim", "generated 43")
  build("examples/main.nim", "example 43")
  build("demos/main.nim", "example 42")

  # Distinct paths and their precedence still belong to the fingerprint.
  # Adding a directory, then reversing the same paths, must invalidate it.
  let demoConfig = dir / "demos" / "config.nims"
  let originalConfig = readFile(demoConfig)
  writeFile(demoConfig, originalConfig & "\nswitch(\"path\", \"../extra\")\n")
  build("demos/main.nim", "example 42", rebuildShared = true)
  writeFile(demoConfig, "switch(\"path\", \"../extra\")\n" & originalConfig)
  build("demos/main.nim", "example 42", rebuildShared = true)
finally:
  removeDir(dir)
