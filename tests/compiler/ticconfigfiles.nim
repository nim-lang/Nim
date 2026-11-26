discard """
  joinable: false
"""
# `nim ic` replays the precompiled config instead of reading the config files, but must still say which config files stand for it, as every other command does (hint `Conf`).
import std/[assertions, os, osproc, strutils, tempfiles]
const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_config_files_", "")
let binary = dir / "prog".addFileExt(ExeExt)
try:
  writeFile(dir / "config.nims", """
switch("define", "x")
""")
  writeFile(dir / "main.nim", """
echo "ok"
""")
  let args = [nim, "ic", "--hints:on", "--warnings:off", "--skipUserCfg",
    "--nimcache:" & (dir / "nc"), "--out:" & binary, dir / "main.nim"]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  doAssert "used config file" in compiled.output and "config.nims" in compiled.output,
    "no 'used config file' hint for config.nims:\n" & compiled.output
finally:
  removeDir(dir)
