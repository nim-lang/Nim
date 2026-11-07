discard """
  cmd: "nim $target --skipProjCfg $options $file"
  targets: "c"
"""

# The `cpu.os.cc.*` cross compilation settings must be used both by the
# `--spawncodegen` child, which runs with `--compileOnly` (that otherwise
# selects the host's settings, for niminst), and by the in-process build.
#
# `--skipProjCfg` builds this test for the host; it then builds
# mspawncodegencross.nim for avr (with ./nim.cfg) using fake tools that cannot
# run. The resulting error is not checked: it does not name the missing program
# on every OS (e.g. Windows). Instead, `--listCmd` and `--parallelBuild:1` echo
# each command before it is started, and the linker command is read from the
# JSON build instructions written by the `--spawncodegen` child.

import stdtest/specialpaths
import std/[os, osproc, strutils, json]

const nim = getCurrentCompilerExe()
const fixture = currentSourcePath.parentDir / "mspawncodegencross.nim"
const avrSwitches = "--os:standalone --exceptions:quirky -d:noSignalHandler " &
  "-d:danger --threads:off --listCmd --parallelBuild:1"

proc build(name, switches: string): tuple[output, nimcache: string] =
  let dir = buildDir / "tspawncodegencross" / name
  removeDir dir
  result.nimcache = dir / "nimcache"
  let cmd = nim.quoteShell & " c " & avrSwitches & " " & switches &
    " --nimcache:" & result.nimcache.quoteShell & " -o:" & quoteShell(dir / "m") &
    " " & fixture.quoteShell
  var exitCode: int
  (result.output, exitCode) = execCmdEx(cmd)
  doAssert exitCode != 0, "the fake tools cannot run:\n" & cmd & "\n" & result.output

proc compileCmd(output, exe: string): string =
  ## The first C compiler command echoed by `--listCmd`. Searching for `<exe> -c`
  ## avoids matching the `--avr.standalone.gcc.exe:<exe>` switch itself.
  let exe = exe.addFileExt(ExeExt)
  for line in output.splitLines:
    if exe & " -c " in line: return line
  doAssert false, "no `" & exe & "` compile command in:\n" & output

block: # the compiler, through the --spawncodegen child (the default)
  let (output, _) = build("exe", "--avr.standalone.gcc.exe:nim_fake_avr_cc")
  discard compileCmd(output, "nim_fake_avr_cc")

block: # the compiler, in process
  let (output, _) = build("off", "--spawncodegen:off " &
    "--avr.standalone.gcc.exe:nim_fake_avr_cc")
  discard compileCmd(output, "nim_fake_avr_cc")

block: # the compiler options
  let (output, _) = build("opts", "--avr.standalone.gcc.exe:nim_fake_avr_cc " &
    "--avr.standalone.gcc.options.always:-DNIM_CROSS_MARKER")
  doAssert "-DNIM_CROSS_MARKER" in compileCmd(output, "nim_fake_avr_cc"), output

block: # the linker, emitted into the build instructions by the child
  let (output, nimcache) = build("link", "--avr.standalone.gcc.exe:nim_fake_avr_cc " &
    "--avr.standalone.gcc.linkerexe:nim_fake_avr_ld")
  let instructions = nimcache / "m.json"
  doAssert fileExists(instructions), output
  let linkCmd = parseFile(instructions)["linkcmd"].getStr
  doAssert "nim_fake_avr_ld" in linkCmd, linkCmd
