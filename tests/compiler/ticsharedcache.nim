discard """
  joinable: false
"""

# IC recompiles objects overwritten by a classic build before an edit.
import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_shared_cache_", "")
let source = dir / "main.nim"
let dependency = dir / "dep.nim"
let binary = dir / "prog".addFileExt(ExeExt)

proc build(command: string) =
  let args = [nim, command, "--hints:off", "--warnings:off",
    "--nimcache:" & dir / "nc", "--out:" & binary, source]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  let executed = execCmdEx(quoteShell(binary))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == "42", executed.output

try:
  writeFile(source, "import dep\necho value()\n")
  writeFile(dependency, "proc value*(): int = 42\n")
  build("ic")
  # Classic codegen overwrites the main C/object pair without updating IC's
  # SHA1. The next edit restores the original IC C text and its matching hash,
  # but the object still belongs to the classic build.
  build("c")
  writeFile(dependency, "\n\nproc value*(): int = 42\n")
  build("ic")
  build("ic")
finally:
  removeDir(dir)
