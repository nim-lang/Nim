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

proc build(project, expected: string, reuseShared = false, rebuildShared = false,
           options: seq[string] = @[]) =
  var args = @[
    nim,
    "ic",
    "--hints:off",
    "--warnings:off",
    "--skipUserCfg",
    "--nimcache:" & cache,
    "--out:" & binary,
  ]
  args.add options
  args.add dir / project
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

proc configSnapshots(): Table[string, Time] =
  for file in walkFiles(cache / "ic_config_*.cfg.nif"):
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
  # Another NimScript config appends the library path again. That redundant
  # search-path entry must not distinguish otherwise equivalent settings.
  writeFile(dir / "demos" / "configured.nims", "discard\n")
  writeFile(dir / "demos" / "configured.nim", readFile(dir / "demos" / "main.nim"))

  # The first three entry points deliberately have the same basename.
  for project, expected in [
    ("src/main.nim", "app 42"),
    ("tests/main.nim", "tests 42"),
    ("examples/main.nim", "example 42"),
    ("examples/other.nim", "other 42"),
  ].items:
    build(project, expected)
    build(project, expected, reuseShared = true)
    if project == "src/main.nim":
      let snapshots = configSnapshots()
      doAssert snapshots.len == 1
      for spelling in ["src/./main.nim", "src/../src/main.nim", "src/main"]:
        build(spelling, expected, reuseShared = true)
        doAssert configSnapshots() == snapshots
  doAssert configSnapshots().len == 4

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

  # Resolved command-line paths count once too, regardless of option spelling.
  let sourcePath = expandFilename(dir / "src")
  build("demos/main.nim", "example 42", reuseShared = true,
    options = @["--path:" & sourcePath, "-p=" & sourcePath])
  build("demos/main.nim", "example 42", reuseShared = true)

  # A real setting change still invalidates shared modules, even though their
  # own source files and the importing project's source are unchanged.
  let config = dir / "examples" / "config.nims"
  writeFile(config, readFile(config) & "\nswitch(\"define\", \"sharedValue:43\")\n")
  build("examples/main.nim", "example 43")
  build("demos/main.nim", "example 42")

  # Distinct paths and lookup order still distinguish configurations.
  let demoConfig = dir / "demos" / "config.nims"
  let originalConfig = readFile(demoConfig)
  writeFile(demoConfig, originalConfig & "\nswitch(\"path\", \"../extra\")\n")
  build("demos/main.nim", "example 42", rebuildShared = true)
  writeFile(demoConfig, "switch(\"path\", \"../extra\")\n" & originalConfig)
  build("demos/main.nim", "example 42", rebuildShared = true)

  # Ordered switches can override earlier values and must affect the signature.
  writeFile(demoConfig, originalConfig & "\n" &
    "switch(\"define\", \"sharedValue:43\")\n" &
    "switch(\"define\", \"sharedValue:44\")\n")
  build("demos/main.nim", "example 44", rebuildShared = true)
  writeFile(demoConfig, originalConfig & "\n" &
    "switch(\"define\", \"sharedValue:44\")\n" &
    "switch(\"define\", \"sharedValue:43\")\n")
  build("demos/main.nim", "example 43", rebuildShared = true)
finally:
  removeDir(dir)
