discard """
  joinable: false
"""
# What NimScript says through `hint()` and `warning()` rather than `switch()` must reach `nim ic`, whose driver and children replay the precompiled config instead of running the script.
import std/[assertions, os, osproc, strutils, tempfiles]
const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_ic_config_hint_", "")
let binary = dir / "prog".addFileExt(ExeExt)
try:
  writeFile(dir / "config.nims", """
hint("XDeclaredButNotUsed", false)
warning("Deprecated", false)
""")
  writeFile(dir / "main.nim", """
proc old(x: int) {.deprecated.} = discard
proc f() =
  var unusedVar = 1
  old(1)
f()
echo "ok"
""")
  let args = [nim, "ic", "--hints:on", "--warnings:on", "--skipUserCfg",
    "--nimcache:" & (dir / "nc"), "--out:" & binary, dir / "main.nim"]
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  # collect both, so that one failing does not hide the other
  var failures = ""
  if "XDeclaredButNotUsed" in compiled.output: failures.add "hint() was not replayed; "
  if "Deprecated" in compiled.output: failures.add "warning() was not replayed; "
  doAssert failures.len == 0, failures & compiled.output
finally:
  removeDir(dir)
