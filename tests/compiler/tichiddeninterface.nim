discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_hidden_interface_", "")
let source = dir / "main.nim"
let dependency = dir / "hidden.nim"
let binary = dir / "prog".addFileExt(ExeExt)

proc build(expected: string) =
  let compiled = execCmdEx(quoteShellCommand([nim, "ic", "--hints:off", "--warnings:off",
    "--nimcache:" & dir / "nc", "--out:" & binary, source]))
  doAssert compiled.exitCode == 0, compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == expected, executed.output

try:
  writeFile(source, """
import hidden {.all.}
when compiles(value(1)):
  echo value(1)
else:
  echo value("text")
""")
  writeFile(dependency, "proc value(x: int): string = \"int\"\n")
  build("int")
  build("int")
  let mainModified = getLastModificationTime(source)
  # Keep main.nim untouched: rewriting it would force sem independently of
  # whether the hidden interface correctly invalidates its importer.
  writeFile(dependency, "proc value(x: string): string = \"string\"\n")
  build("string")
  build("string")
  doAssert getLastModificationTime(source) == mainModified
finally:
  removeDir(dir)
