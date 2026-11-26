discard """
  joinable: false
"""
# The system config (`config/nim.cfg`) carries what `config/config.nims` used to
# say, so that a compiler run does not start the NimScript VM (a module graph and
# sem over system.nim) just for that. Nothing else may change: the settings the
# `.nims` made are still there, and a global `.nims` is still run when one exists.
import std/[assertions, os, osproc, strutils, tempfiles]
const nim = getCurrentCompilerExe()
let dir = createTempDir("nim_global_config_", "")
proc run(args: varargs[string]): tuple[output: string, exitCode: int] =
  var cmd = @[nim] & @args
  execCmdEx(quoteShellCommand(cmd), workingDir = dir)
try:
  writeFile(dir / "v.nim", """
const v {.strdefine: "nimVersion".} = ""
static: echo "version=", v
""")
  writeFile(dir / "s.nim", """
var s = "x"
let t = string(s)
""")
  writeFile(dir / "main.nim", "echo \"ok\"\n")

  # the system config is no longer a NimScript
  let hints = run("check", "--hints:on", "--skipUserCfg", "main.nim")
  doAssert hints.exitCode == 0, hints.output
  doAssert "used config file" in hints.output and "nim.cfg" in hints.output, hints.output
  doAssert ".nims" notin hints.output, "a .nims was run:\n" & hints.output

  # `switch("define", "nimVersion:" & NimVersion)`
  let v = run("check", "--hints:off", "--skipUserCfg", "v.nim")
  doAssert "version=" & NimVersion in v.output, v.output

  # `when defined(nimStrictMode): switch("hintAsError", ...)`
  let plain = run("check", "--hints:on", "--skipUserCfg", "s.nim")
  doAssert plain.exitCode == 0, plain.output
  let strict = run("check", "--hints:on", "--skipUserCfg", "-d:nimStrictMode", "s.nim")
  doAssert strict.exitCode != 0 and "ConvFromXtoItselfNotNeeded" in strict.output, strict.output

  # `cppDefine`: recorded in the precompiled config of `nim ic`
  let ic = run("ic", "--hints:off", "--skipUserCfg", "--nimcache:" & (dir / "nc"), "main.nim")
  doAssert ic.exitCode == 0, ic.output
  var found = 0
  for file in walkFiles(dir / "nc" / "ic_config_*.cfg.nif"):
    let text = readFile(file)
    for d in ["\"errno\"", "\"unix\"", "\"NAN_INFINITY\"", "\"INF\"", "\"NAN\""]:
      doAssert d in text, d & " missing from " & file
    inc found
  doAssert found == 1

  # a user `.nims` still runs: the path the removed file used to exercise
  createDir(dir / "xdg" / "nim")
  writeFile(dir / "g.nim", """
const g {.intdefine.} = 0
static: echo "g=", g
""")
  writeFile(dir / "xdg" / "nim" / "config.nims", "switch(\"define\", \"g=7\")\n")
  putEnv("XDG_CONFIG_HOME", dir / "xdg")
  let user = run("check", "--hints:off", "g.nim")
  doAssert "g=7" in user.output, user.output
finally:
  removeDir(dir)
