# Small program that runs the test cases

import std / [strutils, os, osproc, sequtils, strformat]
from std/private/gitutils import diffFiles

if execShellCmd("nim c -d:debug -r tests/unittests.nim") != 0:
  quit("FAILURE: unit tests failed")

var failures = 0

let atlasExe = absolutePath("bin" / "atlas".addFileExt(ExeExt))
if execShellCmd("nim c -o:$# src/atlas.nim" % [atlasExe]) != 0:
  quit("FAILURE: compilation of atlas failed")

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit "FAILURE: " & cmd

proc sameDirContents(expected, given: string): bool =
  result = true
  for _, e in walkDir(expected):
    let g = given / splitPath(e).tail
    if fileExists(g):
      if readFile(e) != readFile(g):
        echo "FAILURE: files differ: ", e
        echo diffFiles(e, g).output
        inc failures
        result = false
    else:
      echo "FAILURE: file does not exist: ", g
      inc failures
      result = false

template withDir(dir: string; body: untyped) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentDir(old)

const
  SemVerExpectedResult = """
[Info] (../resolve) selected:
[Info] (proj_a) [ ] (proj_a, 1.0.0)
[Info] (proj_a) [x] (proj_a, 1.1.0)
[Info] (proj_b) [x] (proj_b, 1.1.0)
[Info] (proj_c) [x] (proj_c, 1.2.0)
[Info] (proj_d) [x] (proj_d, 1.0.0)
[Info] (../resolve) end of selection
"""

  MinVerExpectedResult = """selected:
[ ] (proj_a, 1.1.0)
[x] (proj_a, 1.0.0)
[ ] (proj_b, 1.1.0)
[x] (proj_b, 1.0.0)
[x] (proj_c, 1.2.0)
[ ] (proj_d, 2.0.0)
[x] (proj_d, 1.0.0)
end of selection
"""

proc buildGraph =
  createDir "source"
  withDir "source":

    createDir "proj_a"
    withDir "proj_a":
      exec "git init"
      writeFile "proj_a.nimble", "requires \"proj_b >= 1.0.0\"\n"
      exec "git add proj_a.nimble"
      exec "git commit -m 'update'"
      exec "git tag v1.0.0"
      writeFile "proj_a.nimble", "requires \"proj_b >= 1.1.0\"\n"
      exec "git add proj_a.nimble"
      exec "git commit -m 'update'"
      exec "git tag v1.1.0"

    createDir "proj_b"
    withDir "proj_b":
      exec "git init"
      writeFile "proj_b.nimble", "requires \"proj_c >= 1.0.0\"\n"
      exec "git add proj_b.nimble"
      exec "git commit -m " & quoteShell("Initial commit for project B")
      exec "git tag v1.0.0"

      writeFile "proj_b.nimble", "requires \"proj_c >= 1.1.0\"\n"
      exec "git add proj_b.nimble"
      exec "git commit -m " & quoteShell("Update proj_b.nimble for project B")
      exec "git tag v1.1.0"

    createDir "proj_c"
    withDir "proj_c":
      exec "git init"
      writeFile "proj_c.nimble", "requires \"proj_d >= 1.2.0\"\n"
      exec "git add proj_c.nimble"
      exec "git commit -m " & quoteShell("Initial commit for project C")
      writeFile "proj_c.nimble", "requires \"proj_d >= 1.0.0\"\n"
      exec "git commit -am " & quoteShell("Update proj_c.nimble for project C")
      exec "git tag v1.2.0"

    createDir "proj_d"
    withDir "proj_d":
      exec "git init"
      writeFile "proj_d.nimble", "\n"
      exec "git add proj_d.nimble"
      exec "git commit -m " & quoteShell("Initial commit for project D")
      exec "git tag v1.0.0"
      writeFile "proj_d.nimble", "requires \"does_not_exist >= 1.2.0\"\n"
      exec "git add proj_d.nimble"
      exec "git commit -m " & quoteShell("broken version of package D")

      exec "git tag v2.0.0"

proc testSemVer2() =
  buildGraph()
  createDir "semproject"
  withDir "semproject":
    let (outp, status) = execCmdEx(atlasExe & " --resolver=SemVer --colors:off --list use proj_a")
    if status == 0:
      if outp.contains SemVerExpectedResult:
        discard "fine"
      else:
        echo "expected ", SemVerExpectedResult, " but got ", outp
        raise newException(AssertionDefect, "Test failed!")
    else:
      assert false, outp

proc testMinVer() =
  buildGraph()
  createDir "minproject"
  withDir "minproject":
    let (outp, status) = execCmdEx(atlasExe & " --resolver=MinVer --list use proj_a")
    if status == 0:
      if outp.contains MinVerExpectedResult:
        discard "fine"
      else:
        echo "expected ", MinVerExpectedResult, " but got ", outp
        raise newException(AssertionDefect, "Test failed!")
    else:
      assert false, outp

withDir "tests/ws_semver2":
  try:
    testSemVer2()
  finally:
    removeDir "does_not_exist"
    removeDir "semproject"
    removeDir "minproject"
    removeDir "source"
    removeDir "proj_a"
    removeDir "proj_b"
    removeDir "proj_c"
    removeDir "proj_d"

when false: # withDir "tests/ws_semver2":
  try:
    testMinVer()
  finally:
    removeDir "does_not_exist"
    removeDir "semproject"
    removeDir "minproject"
    removeDir "source"
    removeDir "proj_a"
    removeDir "proj_b"
    removeDir "proj_c"
    removeDir "proj_d"

proc integrationTest() =
  # Test installation of some "important_packages" which we are sure
  # won't disappear in the near or far future. Turns out `nitter` has
  # quite some dependencies so it suffices:
  exec atlasExe & " --verbosity:trace use https://github.com/zedeus/nitter"
  discard sameDirContents("expected", ".")

proc cleanupIntegrationTest() =
  var dirs: seq[string] = @[]
  for k, f in walkDir("."):
    if k == pcDir and dirExists(f / ".git"):
      dirs.add f
  for d in dirs: removeDir d
  removeFile "nim.cfg"
  removeFile "ws_integration.nimble"

withDir "tests/ws_integration":
  try:
    integrationTest()
  finally:
    when not defined(keepTestDirs):
      cleanupIntegrationTest()

if failures > 0: quit($failures & " failures occurred.")
