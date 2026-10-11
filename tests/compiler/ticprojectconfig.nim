discard
  """
  joinable: false
"""

# Projects sharing a nimcache must load their own config.nims and project cfg.
import std/[assertions, os, osproc, sha1, strutils, tempfiles, tables, times]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_project_config_", "")
let cache = dir / "nc"
let binary = dir / "prog".addFileExt(ExeExt)

proc build(project, expected: string, reuseShared = false, rebuildShared = false,
           options: seq[string] = @[], output = binary) =
  var args = @[
    nim,
    "ic",
    "--hints:off",
    "--warnings:off",
    "--skipUserCfg",
    "--nimcache:" & cache,
    "--out:" & output,
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
  let executed = execCmdEx(quoteShell(output))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, project & ":\n" & executed.output

proc semanticCache(): Table[string, Time] =
  for file in walkDirRec(cache):
    if file.endsWith(".s.bif"):
      result[file] = getLastModificationTime(file)

proc activeCache(): string =
  cache / "configs" / $secureHash(readFile(cache / "ic_build_args.txt"))

proc artifacts(path: string): Table[string, Time] =
  for file in walkDirRec(path):
    if not file.endsWith(".build.nif"):
      result[file] = getLastModificationTime(file)

proc assertUnchanged(path: string; before: Table[string, Time]) =
  let after = artifacts(path)
  doAssert after.len == before.len, path & " artifact count changed"
  for file, modified in before:
    doAssert after.getOrDefault(file) == modified, file & " was rebuilt"

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
  writeFile(dir / "examples" / "second.nim", "import shared\necho \"second \", value()\n")
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
  writeFile(
    dir / "examples" / "generated.nim",
    """
import std/macros
macro importShared(): untyped = parseStmt("import shared")
importShared()
echo "generated ", value()
""",
  )
  writeFile(
    dir / "src" / "orphan.nim",
    """
const sharedValue {.intdefine.} = 42
const selectedValue = sharedValue
when selectedValue == 42:
  import legacy
  proc orphanValue*(): int = legacyValue()
else:
  proc orphanValue*(): int = sharedValue
""",
  )
  writeFile(
    dir / "src" / "legacy.nim",
    """
const sharedValue {.intdefine.} = 42
static: doAssert sharedValue == 42
proc legacyValue*(): int = sharedValue
""",
  )
  writeFile(dir / "examples" / "warm.nim", "import orphan\necho orphanValue()\n")
  writeFile(
    dir / "examples" / "later.nim",
    """
import std/macros
macro importOrphan(): untyped = parseStmt("import orphan")
importOrphan()
echo orphanValue()
""",
  )
  writeFile(dir / "examples" / "cached.nim", readFile(dir / "examples" / "later.nim"))

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

  # Parsing is shared across settings; semantic/backend outputs use the selected
  # configuration. An unchanged build must reuse every stage.
  let selected = activeCache()
  var parsed, semmed, lowered, generated, objects: int
  for file in walkDirRec(cache / "parsed"):
    if file.endsWith(".p.nif"): inc parsed
  for file in walkDirRec(selected):
    doAssert not file.endsWith(".p.nif"), file
    if file.endsWith(".s.bif"): inc semmed
    if file.endsWith(".t.bif"): inc lowered
    if file.endsWith(".nim.c"): inc generated
    if file.endsWith(".o"): inc objects
  doAssert parsed > 0 and semmed > 0 and lowered > 0 and generated > 0 and objects > 0
  for kind, file in walkDir(cache):
    if kind == pcFile:
      doAssert file.endsWith(".cfg.nif") or
        file.extractFilename in ["ic.version", "ic_build_args.txt", "ic_link_args.txt"], file
  let cached = artifacts(selected)
  build("examples/other.nim", "other 42", reuseShared = true)
  assertUnchanged(selected, cached)

  # Returning to a cached project must restore its own paths and defines.
  build("src/main.nim", "app 42", reuseShared = true)
  build("tests/main.nim", "tests 42", reuseShared = true)
  build("examples/main.nim", "example 42", reuseShared = true)
  assertUnchanged(selected, cached)
  let exampleBackend = artifacts(activeCache() / "backend")

  # Equivalent settings can select different entry points while overwriting the
  # same executable. Returning to either program must relink its cached code.
  build("examples/second.nim", "second 42", reuseShared = true)
  for file, modified in exampleBackend:
    doAssert getLastModificationTime(file) == modified, file & " was rebuilt"
  build("examples/main.nim", "example 42", reuseShared = true)
  let bothBackends = artifacts(activeCache() / "backend")
  build("examples/second.nim", "second 42", reuseShared = true)
  assertUnchanged(activeCache() / "backend", bothBackends)
  let otherOutput = dir / "otherprog".addFileExt(ExeExt)
  build("examples/main.nim", "example 42", reuseShared = true, output = otherOutput)
  build("examples/main.nim", "example 42", reuseShared = true)

  # A module's main role and imported role must coexist under identical settings.
  writeFile(dir / "examples" / "role.nim", """
const role* = when isMainModule: "main" else: "import"
when isMainModule: echo role
""")
  writeFile(dir / "examples" / "roleuser.nim", "import role\necho role.role\n")
  build("examples/roleuser.nim", "import", reuseShared = true)
  let importedRoles = semanticCache()
  build("examples/role.nim", "main", reuseShared = true)
  for file, modified in importedRoles:
    doAssert getLastModificationTime(file) == modified, file & " changed main role"
  build("examples/roleuser.nim", "import", reuseShared = true)
  build("examples/role.nim", "main", reuseShared = true)

  # The isolation includes every member of main's strongly-connected group.
  writeFile(dir / "examples" / "cyclea.nim", """
const roleA* = when isMainModule: "main" else: "import"
import cycleb
when isMainModule: echo roleA, " ", roleB
""")
  writeFile(dir / "examples" / "cycleb.nim", """
const roleB* = when isMainModule: "main" else: "import"
import cyclea
when isMainModule: echo roleA, " ", roleB
""")
  writeFile(dir / "examples" / "cycleuser.nim",
    "import cyclea, cycleb\necho roleA, \" \", roleB\n")
  build("examples/cycleuser.nim", "import import", reuseShared = true)
  let importedCycle = semanticCache()
  build("examples/cyclea.nim", "main import", reuseShared = true)
  build("examples/cycleb.nim", "import main", reuseShared = true)
  for file, modified in importedCycle:
    doAssert getLastModificationTime(file) == modified, file & " changed main cycle"
  build("examples/cycleuser.nim", "import import", reuseShared = true)
  build("examples/cyclea.nim", "main import", reuseShared = true)

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

  # Cache a module that is absent from the next entry point's initial graph.
  let beforeWarm = semanticCache()
  build("examples/warm.nim", "42", reuseShared = true)
  # A new entry point can generate an import whose BIF already exists under
  # these exact settings. Its cached imports still need discovery and build
  # rules, including when a transitive dependency's body changed meanwhile.
  let legacy = dir / "src" / "legacy.nim"
  let legacySource = readFile(legacy)
  writeFile(legacy, legacySource.replace("= sharedValue\n", "= sharedValue + 1\n"))
  build("examples/cached.nim", "43", reuseShared = true)
  writeFile(legacy, legacySource)
  build("examples/warm.nim", "42", reuseShared = true)
  var outsideGraph: Table[string, Time]
  for file, modified in semanticCache():
    if file notin beforeWarm:
      outsideGraph[file] = modified
  doAssert outsideGraph.len > 0
  # A real setting change still invalidates shared modules, even though their
  # own source files and the importing project's source are unchanged.
  let config = dir / "examples" / "config.nims"
  let parsedBeforeConfig = artifacts(cache / "parsed")
  writeFile(config, readFile(config) & "\nswitch(\"define\", \"sharedValue:43\")\n")
  # The scanner cannot see this import. A BIF from the previous configuration
  # must not let sem succeed before the module is discovered and rebuilt.
  build("examples/generated.nim", "generated 43")
  build("examples/main.nim", "example 43")
  for file, modified in parsedBeforeConfig:
    doAssert getLastModificationTime(file) == modified, file & " was reparsed"
  # Configuration changes must leave unrelated artifacts on disk.
  # Later, with the same configuration, a generated import must select its new
  # namespace and discover the missing BIF rather than load the old value 42.
  # Its old .s.deps must also be ignored: legacy is invalid under the new
  # settings and belongs only to the orphan's previous conditional branch.
  for file, modified in outsideGraph:
    doAssert fileExists(file), file & " was deleted"
    doAssert getLastModificationTime(file) == modified, file & " was rebuilt"
  assertUnchanged(selected, cached)
  build("examples/later.nim", "43")
  let beforeRerun = semanticCache()
  build("examples/later.nim", "43")
  doAssert semanticCache() == beforeRerun
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
  # Config validation must work even when interface cookies are disabled.
  build("examples/later.nim", "43", options = @["-d:icNoIfaceGate"])
finally:
  removeDir(dir)
