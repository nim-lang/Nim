discard """
  joinable: false
"""
# `patchFile` in a config.nims must reach `nim ic`: it is not a switch, so the precompiled config has to carry it.
import std/[assertions, os, osproc, strutils, tempfiles]
const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_config_patch_", "")
let binary = dir / "prog".addFileExt(ExeExt)
try:
  writeFile(dir / "patched.nim", "static: echo \"PATCHED\"\n")
  writeFile(dir / "config.nims", """
patchFile("stdlib", "tables", "patched")
""")
  writeFile(dir / "main.nim", """
import std/tables
echo "ok"
""")
  let args = [nim, "ic", "--hints:off", "--warnings:off", "--skipUserCfg",
    "--nimcache:" & (dir / "nc"), "--out:" & binary, dir / "main.nim"]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  doAssert "PATCHED" in compiled.output, "patchFile was not replayed:\n" & compiled.output
finally:
  removeDir(dir)
