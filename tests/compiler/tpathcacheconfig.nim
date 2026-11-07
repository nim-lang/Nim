discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_pathcache_config_", "")
let other = dir / "other"
let binaryName = "pathcache-prog".addFileExt(ExeExt)

try:
  createDir(other)
  writeFile(dir / "config.nims", """
import std/os
cd(thisDir() / "other")
""")
  writeFile(dir / "main.nim", "echo \"pathcache config ok\"\n")
  # --out is resolved before and after config.nims. Its second resolution must
  # use the script's new directory, even if the first pass cached the old one.
  let built = execCmdEx(quoteShellCommand([
    nim, "c", "--skipParentCfg", "--skipUserCfg", "--hints:off",
    "--nimcache:" & (dir / "cache"), "--out:" & binaryName, dir / "main.nim"
  ]), workingDir = dir)
  doAssert built.exitCode == 0, built.output
  doAssert fileExists(other / binaryName), built.output
  doAssert not fileExists(dir / binaryName), built.output
  let executed = execCmdEx(quoteShell(other / binaryName))
  doAssert executed.exitCode == 0, executed.output
  doAssert executed.output.strip == "pathcache config ok", executed.output
finally:
  removeDir(dir)
