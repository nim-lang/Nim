discard """
  joinable: false
"""

# IC: sibling modules, compiled by separate `nim m` processes, never allocate
# the same CacheCounter value (#26201). The order of the values depends on the
# scheduling of those processes, so only uniqueness and stability are checked.
import std/[assertions, os, osproc, strutils, tempfiles, sets, tables, times]

const nim = getCurrentCompilerExe()
const siblings = 12

let dir = createTempDir("nim_ic_cachecounter_", "")
let source = dir / "main.nim"
let binary = dir / "prog".addFileExt(ExeExt)

proc cacheFiles(): Table[string, string] =
  result = initTable[string, string]()
  for f in walkDirRec(dir / "nc"):
    if not f.endsWith(".build.nif") and not f.endsWith("ic_build_args.txt"):
      result[f] = readFile(f)

proc build(): seq[int] =
  let args = [nim, "ic", "--hints:off", "--warnings:off",
    "--nimcache:" & dir / "nc", "--out:" & binary, source]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  result = @[]
  for x in executed.output.strip.split(','): result.add parseInt(x)
  # the last number is the final counter value, all others are allocations
  doAssert toHashSet(result[0..^2]).len == result.len-1, $result
  for x in result[0..^2]: doAssert x in 1..result[^1], $result

try:
  writeFile(dir / "counter.nim", """
import std/macrocache
const ids* = CacheCounter"tests.ic.cachecounter"
proc nextId*(): int {.compileTime.} =
  ids.inc
  ids.value
""")
  var imports = "import counter, std/macrocache"
  var ids = ""
  for i in 1..siblings:
    writeFile(dir / "m" & $i & ".nim", "import counter\nconst id" & $i & "* = nextId()\n")
    imports.add ", m" & $i
    ids.add "id" & $i & ", \",\", "
  writeFile(source, imports & "\nconst total = ids.value\necho " & ids & "total\n")

  let first = build()
  doAssert first.len == siblings+1 and first[^1] == siblings, $first

  # Touching every file re-sems every module; they must be handed the same
  # numbers again, so no artifact changes.
  let before = cacheFiles()
  for f in walkFiles(dir / "*.nim"): setLastModificationTime(f, getTime())
  doAssert build() == first
  let after = cacheFiles()
  for f, content in after:
    if before.getOrDefault(f) != content: echo "CHANGED ", f
  doAssert after == before

  # A re-semmed module that needs more numbers must not collide with the ones
  # the unchanged siblings already embed.
  writeFile(dir / "m1.nim", "import counter\nconst id1* = nextId()\nconst extra* = nextId()\n")
  writeFile(source, readFile(source).replace("echo ", "echo extra, \",\", "))
  let grown = build()
  doAssert grown[1..^2] == first[0..^2], $grown & " vs " & $first
finally:
  removeDir(dir)
