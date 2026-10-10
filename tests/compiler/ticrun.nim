discard """
  joinable: false
"""

# `nim r` is a compile-and-run command, but with `--ic:on` its compilation must
# still go through the IC driver before the ordinary run phase executes.
import std/[assertions, os, osproc, strutils, tempfiles]

const nim = getCurrentCompilerExe()

let dir = createTempDir("nim_ic_run_", "")
let source = dir / "main.nim"
let binary = dir / "prog".addFileExt(ExeExt)
let cache = dir / "nc"

try:
  writeFile(source, "echo 42\n")
  let args = [nim, "r", "--ic:on", "--hints:off", "--warnings:off",
    "--nimcache:" & cache, "--out:" & binary, source]
  let run = execCmdEx(quoteShellCommand(args))
  doAssert run.exitCode == 0, run.output
  doAssert run.output.strip == "42", run.output
  doAssert fileExists(cache / "ic.version"), run.output
finally:
  removeDir(dir)
