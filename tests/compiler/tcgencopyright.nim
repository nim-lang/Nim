discard """
  joinable: false
"""

# The comment at the top of a generated C file records how the file is
# compiled, so that a changed command or target recompiles it. It must not
# record where the nimcache is.
import std/[assertions, os, osproc, strutils, tempfiles, algorithm]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_cgen_copyright_", "")
let source = dir / "main.nim"

proc build(nimcache: string, extra: varargs[string]): string =
  var args = @[nim, "c", "--warnings:off", "--hint:CC:on",
    "--nimcache:" & nimcache, "--out:" & dir / "prog".addFileExt(ExeExt)]
  args.add extra
  args.add source
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  result = compiled.output

proc cFiles(nimcache: string): seq[string] =
  for f in walkFiles(nimcache / "*.c"):
    result.add f.extractFilename
  result.sort

proc cfilesDiffer(a, b: string): seq[string] =
  ## names of the generated C files that are not identical in both caches
  doAssert cFiles(a) == cFiles(b)
  for name in cFiles(a):
    if readFile(a / name) != readFile(b / name):
      result.add name

proc ccLines(output: string): int =
  for line in output.splitLines:
    if line.startsWith("CC: "): inc result

try:
  writeFile(source, "echo \"hi\"\n")

  # Given a finished build, When it is built again with the same options,
  # Then no C file is compiled.
  discard build(dir / "ncC")
  doAssert ccLines(build(dir / "ncC")) == 0

  # Given a finished build, When --passC changes, Then the C files are compiled
  # again.
  doAssert ccLines(build(dir / "ncC", "--passC:-DFOO")) > 0

  # Given a program, When the target CPU changes, Then the generated C files
  # differ.
  discard build(dir / "ncD", "--compileOnly", "--os:linux", "--cpu:amd64")
  discard build(dir / "ncE", "--compileOnly", "--os:linux", "--cpu:i386")
  doAssert cfilesDiffer(dir / "ncD", dir / "ncE").len > 0

  # Given the same program and options, When it is built into two nimcaches,
  # Then every generated C file is identical.
  discard build(dir / "ncA", "--compileOnly")
  discard build(dir / "ncB", "--compileOnly")
  doAssert cFiles(dir / "ncA").len > 0
  doAssert cfilesDiffer(dir / "ncA", dir / "ncB").len == 0,
    "C files depend on the nimcache: " & $cfilesDiffer(dir / "ncA", dir / "ncB")
  doAssert not readFile(dir / "ncA" / "@mmain.nim.c").contains(dir / "ncA")
finally:
  removeDir(dir)
