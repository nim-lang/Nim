# Small program that runs the test cases

import std / [strutils, os, sequtils]
from std/private/gitutils import diffFiles

if execShellCmd("nim c -r atlas/versions.nim") != 0:
  quit("FAILURE: unit tests in atlas/versions.nim failed")

var failures = 0

when defined(develop):
  const atlasExe = "bin" / "atlas".addFileExt(ExeExt)
  if execShellCmd("nim c -o:$# atlas/atlas.nim" % [atlasExe]) != 0:
    quit("FAILURE: compilation of atlas failed")
else:
  const atlasExe = "atlas".addFileExt(ExeExt)

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit "FAILURE: " & cmd

proc sameDirContents(expected, given: string) =
  for _, e in walkDir(expected):
    let g = given / splitPath(e).tail
    if fileExists(g):
      if readFile(e) != readFile(g):
        echo "FAILURE: files differ: ", e
        echo diffFiles(e, g).output
        inc failures
    else:
      echo "FAILURE: file does not exist: ", g
      inc failures

proc testWsConflict() =
  const myproject = "atlas/tests/ws_conflict/myproject"
  createDir(myproject)
  exec atlasExe & " --project=" & myproject & " --showGraph --genLock use https://github.com/apkg"
  sameDirContents("atlas/tests/ws_conflict/expected", myproject)
  removeDir("atlas/tests/ws_conflict/apkg")
  removeDir("atlas/tests/ws_conflict/bpkg")
  removeDir("atlas/tests/ws_conflict/cpkg")
  removeDir("atlas/tests/ws_conflict/dpkg")
  removeDir(myproject)

testWsConflict()
if failures > 0: quit($failures & " failures occurred.")
