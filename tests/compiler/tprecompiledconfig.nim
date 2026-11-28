discard """
  joinable: false
"""
# `--precompiledConfig:on` makes a non-IC command (`nim c`, `nim check`) load its
# configuration through the precompiled config artifact. The artifact must be
# reused while nothing it depends on changed, and replaced as soon as anything
# it depends on did: a config file's text, a file a config probed (also one that
# did not exist yet), an environment variable a config read, the command line.
import std/[assertions, os, osproc, strutils, tempfiles, times, envvars]
const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_precompiled_config_", "")
let proj = dir / "proj"
let cache = dir / "nc"
let binary = dir / "prog".addFileExt(ExeExt)
proc build(expected: string; extra: openArray[string] = []; cmd = "c"): string =
  var args = @[nim, cmd, "--hints:off", "--warnings:off", "--skipUserCfg",
    "--precompiledConfig:on", "--nimcache:" & cache, "--out:" & binary]
  for a in extra: args.add a
  args.add proj / "main.nim"
  let compiled = execCmdEx(quoteShellCommand(args))
  doAssert compiled.exitCode == 0, compiled.output
  if cmd == "c":
    let executed = execCmdEx(quoteShell(binary))
    doAssert executed.exitCode == 0, executed.output
    doAssert executed.output.strip == expected, executed.output
  result = compiled.output
proc artifactTime(): Time =
  var found: seq[string] = @[]
  for file in walkFiles(cache / "ic_config_*.cfg.nif"): found.add file
  doAssert found.len == 1, $found
  getLastModificationTime(found[0])
proc config(text: string) =
  writeFile(proj / "config.nims", text)
  # the artifact is stamped with the producer's start; keep the edit after it
  sleep 1100
try:
  createDir(proj)
  writeFile(proj / "main.nim", """
const cfgValue {.intdefine.} = 0
echo cfgValue
""")
  config "switch(\"define\", \"cfgValue=1\")\n"
  discard build("1")
  let made = artifactTime()
  discard build("1")
  doAssert artifactTime() == made, "unchanged config: the artifact was produced again"
  # the command is part of the key (a config can ask for it with getCommand())
  discard build("", cmd = "check")
  # a changed config file
  config "switch(\"define\", \"cfgValue=2\")\n"
  discard build("2")
  # another text under an old time stamp (`cp -p`, `tar x`, `git checkout`)
  writeFile(proj / "config.nims", "switch(\"define\", \"cfgValue=7\")\n")
  setLastModificationTime(proj / "config.nims", fromUnix(1_000_000_000))
  discard build("7")
  # an environment variable the config read
  config "switch(\"define\", \"cfgValue=\" & getEnv(\"NIM_TPCC_VALUE\", \"3\"))\n"
  discard build("3")
  putEnv("NIM_TPCC_VALUE", "4")
  discard build("4")
  delEnv("NIM_TPCC_VALUE")
  discard build("3")
  # a file that did not exist when the artifact was made
  config "discard\n"
  discard build("0")
  writeFile(dir / "config.nims", "switch(\"define\", \"cfgValue=5\")\n")
  discard build("5")
  removeFile(dir / "config.nims")
  discard build("0")
  # a script that changes the process cannot be replayed: never reuse its artifact
  config "putEnv(\"NIM_TPCC_SIDE\", \"1\")\nswitch(\"define\", \"cfgValue=9\")\n"
  discard build("9")
  let volatileMade = artifactTime()
  discard build("9")
  doAssert artifactTime() != volatileMade, "a config that calls putEnv was reused"
  # the command line
  discard build("6", ["-d:cfgValue=6"])
  # what NimScript says through a proc rather than a switch: patchFile
  writeFile(proj / "patched.nim", "static: echo \"PATCHED\"\n")
  config "patchFile(\"stdlib\", \"tables\", \"patched\")\n"
  writeFile(proj / "main.nim", """
import std/tables
const cfgValue {.intdefine.} = 0
echo cfgValue
""")
  discard build("0")
  doAssert "PATCHED" in build("0"), "patchFile lost on the first run"
  doAssert "PATCHED" in build("0"), "patchFile lost on replay"
finally:
  removeDir(dir)
