discard """
  joinable: false
  disabled: "windows"
"""

## `--compileTime:restricted` (RFC #578): the rules that need a project tree on
## disk (configuration files, symbolic links, the user configuration) are
## checked here by running the compiler on generated projects.
## Disabled on Windows: the fixtures use symbolic links and `sh` scripts.

import std/[os, osproc, strutils, strtabs, unittest]

const nim = getCurrentCompilerExe()

let root = getTempDir() / ("nim_trestricted_" & $getCurrentProcessId())
removeDir(root)
createDir(root)

proc write(path, content: string) =
  createDir(path.parentDir)
  writeFile(path, content)

proc envWith(key, val: string): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  for k, v in envPairs(): result[k] = v
  result[key] = val

proc runNim(args: string; dir = root; env: StringTableRef = nil): tuple[output: string, exitCode: int] =
  ## Runs the compiler under test with an empty user configuration unless
  ## `env` names another one, so that the developer's own config is not read.
  let env = if env != nil: env else: envWith("XDG_CONFIG_HOME", root / "xdg_empty")
  result = execCmdEx(nim & " " & args, env = env, workingDir = dir)

proc refusedRead(output: string): bool =
  "read refused by --compileTime:restricted" in output

suite "--compileTime:restricted":
  test "R4: NimScript cannot change files or the environment; exec takes the whitelist":
    let dir = root / "r4s"
    for (name, code, expected) in [
        ("rm.nims", "rmFile(\"x\")\n", "'removeFile' refused by --compileTime:restricted"),
        ("mk.nims", "mkDir(\"d\")\n", "'createDir' refused by --compileTime:restricted"),
        ("wr.nims", "writeFile(\"w\", \"\")\n", "'writeFile' refused by --compileTime:restricted"),
        ("env.nims", "putEnv(\"NIM_TRESTRICTED\", \"1\")\n", "'putEnv' refused by --compileTime:restricted"),
        ("exec.nims", "exec \"echo nope\"\n", "it is not in --staticExecWhitelist: 'echo nope'")]:
      write(dir / name, code)
      let res = runNim("e --hints:off --compileTime:restricted " & name, dir)
      checkpoint name & ":\n" & res.output
      check res.exitCode != 0
      check expected in res.output
    check not dirExists(dir / "d")
    check not fileExists(dir / "w")
    write(dir / "ok.nims", "exec \"echo yes\"\n")
    let ok = runNim("e --hints:off --compileTime:restricted \"--staticExecWhitelist:echo yes\" ok.nims", dir)
    check ok.exitCode == 0
    check "yes" in ok.output

  test "R6: vmopsDanger from the user configuration is refused in restricted mode":
    let xdg = root / "r6" / "xdg"
    write(xdg / "nim" / "nim.cfg", "--experimental:vmopsDanger\n")
    write(root / "r6" / "m.nim", "echo 1\n")
    let res = runNim("c --compileOnly --hints:off --compileTime:restricted m.nim", root / "r6",
      envWith("XDG_CONFIG_HOME", xdg))
    check res.exitCode != 0
    check "--experimental:vmopsDanger cannot be combined with --compileTime:restricted" in res.output

  test "R1: a cached staticExec result does not bypass the whitelist":
    let proj = root / "r1c"
    write(proj / "m.nim", "const x = staticExec(\"echo cached\", cache = \"k\")\necho x\n")
    let cache = proj / "cache"
    let normal = runNim("c --compileOnly --hints:off --nimcache:" & cache & " m.nim", proj)
    check normal.exitCode == 0
    let restricted = runNim("c --compileOnly --hints:off --compileTime:restricted --nimcache:" &
      cache & " m.nim", proj)
    check restricted.exitCode != 0
    check "it is not in --staticExecWhitelist: 'echo cached'" in restricted.output

  test "R7: nim check still skips staticExec and writeFile, with or without the switch":
    let proj = root / "r7"
    write(proj / "m.nim", "const x = staticExec(\"echo bye\")\nstatic: writeFile(\"r7.marker\", \"\")\n")
    for args in ["check --hints:off m.nim", "check --hints:off --compileTime:restricted m.nim"]:
      let res = runNim(args, proj)
      check res.exitCode == 0
      check not fileExists(proj / "r7.marker")

  # R3: compile-time reads stay under the project, --path, nimble and lib.
  let r3 = root / "r3"
  let proj = r3 / "proj"
  let outside = r3 / "outside"
  let extra = r3 / "extra"
  write(outside / "secret.txt", "secret")
  write(extra / "extra.txt", "extra")
  write(proj / "inside.txt", "inside")
  write(proj / "sub" / "data.txt", "data")
  createSymlink(outside / "secret.txt", proj / "link_file")
  createSymlink(outside, proj / "link_dir")
  write(proj / "r3.nim", """
import std/[os, staticos, compilesettings]
const which {.strdefine.} = ""
const outside {.strdefine.} = ""
const extra {.strdefine.} = ""
when which == "inside":
  const a = staticRead("inside.txt")
  const b = slurp(currentSourcePath.parentDir / "sub" / "data.txt")
  const c = staticRead(extra / "extra.txt")
  const d = staticRead(querySetting(libPath) / "system.nim")
  static:
    doAssert a == "inside" and b == "data" and c == "extra" and d.len > 0
    doAssert readFile("inside.txt") == "inside"
    doAssert readLines("inside.txt", 1) == @["inside"]
    doAssert fileExists("inside.txt") and not fileExists("missing.txt")
    doAssert dirExists("sub")
    doAssert staticFileExists("inside.txt")
    doAssert staticDirExists("sub")
    doAssert staticWalkDir("sub").len == 1
  echo "inside ok"
elif which == "slurpAbs":
  static: discard staticRead(outside / "secret.txt")
elif which == "slurpRel":
  static: discard staticRead("../outside/secret.txt")
elif which == "slurpLinkFile":
  static: discard staticRead("link_file")
elif which == "slurpLinkDir":
  static: discard staticRead("link_dir/secret.txt")
elif which == "readFile":
  static: discard readFile("link_file")
elif which == "readLines":
  static: discard readLines(outside / "secret.txt", 1)
elif which == "fileExists":
  static: discard fileExists(outside / "secret.txt")
elif which == "dirExists":
  static: discard dirExists("link_dir")
elif which == "staticWalkDir":
  static: discard staticWalkDir(outside)
elif which == "staticFileExists":
  static: discard staticFileExists(outside / "missing.txt")
elif which == "staticDirExists":
  static: discard staticDirExists(outside)
""")

  proc runR3(which: string): tuple[output: string, exitCode: int] =
    runNim("c --compileOnly --hints:off --compileTime:restricted --path:" & extra &
      " -d:which=" & which & " -d:outside=" & outside & " -d:extra=" & extra & " r3.nim", proj)

  test "R3: reads under the project, --path and lib are allowed":
    let res = runR3("inside")
    check res.exitCode == 0

  test "R3: reads outside are refused, also through symbolic links":
    for which in ["slurpAbs", "slurpRel", "slurpLinkFile", "slurpLinkDir", "readFile",
                  "readLines", "fileExists", "dirExists", "staticWalkDir",
                  "staticFileExists", "staticDirExists"]:
      let res = runR3(which)
      checkpoint which & ":\n" & res.output
      check res.exitCode != 0
      check refusedRead(res.output)

removeDir(root)
