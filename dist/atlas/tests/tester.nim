# Small program that runs the test cases

import std / [strutils, os, osproc, sequtils, strformat]
from std/private/gitutils import diffFiles

if execShellCmd("nim c -r tests/unittests.nim") != 0:
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

proc testWsConflict() =
  const myproject = "tests/ws_conflict/myproject"
  createDir(myproject)
  exec atlasExe & " --project=" & myproject & " --showGraph use https://github.com/apkg"
  if sameDirContents("tests/ws_conflict/expected", myproject):
    removeDir("tests/ws_conflict/apkg")
    removeDir("tests/ws_conflict/bpkg")
    removeDir("tests/ws_conflict/cpkg")
    removeDir("tests/ws_conflict/dpkg")
    removeDir(myproject)

type
  Node = object
    name: string
    versions: seq[string]
    deps: seq[string]

proc createNode(name: string, versions: seq[string], deps: seq[string]): Node =
  result = Node(name: name, versions: versions, deps: deps)

template withDir(dir: string; body: untyped) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentDir(old)

proc createNimblePackage(node: Node) =
  for v in node.versions:
    let packagePath = if v != "1.0.0": node.name & "@" & v else: node.name
    createDir(packagePath)
    withDir packagePath:
      var nimbleContent = ""
      for d in node.deps:
        nimbleContent.add &"requires \"{d}\""
      writeFile(node.name & ".nimble", nimbleContent)

proc testSemVer() =
  # Example graph data
  let graph = @[
    createNode("A", @["1.0.0", "1.1.0", "2.0.0"], @[]),
    createNode("B", @["2.1.0", "3.0.0", "3.1.0"], @["A >= 1.0.0"]),
    createNode("C", @["1.2.0", "1.2.1"], @["B >= 2.0.0"]),
    createNode("D", @["1.0.0", "1.1.0", "1.1.1"], @["C >= 1.0"]),
    createNode("E", @["2.0.0", "2.0.1", "2.1.0"], @["D >= 1.0.0"]),
    createNode("F", @["1.0.0", "1.0.1", "1.1.0"], @["E >= 2.0.0"])
  ]

  createDir "source"
  withDir "source":
    for i in 0..<graph.len:
      createNimblePackage graph[i]

  createDir "myproject"
  withDir "myproject":
    exec atlasExe & " --showGraph use F"

when false:
  withDir "tests/ws_semver":
    testSemVer()
  if sameDirContents("tests/ws_semver/expected", "tests/ws_semver/myproject"):
    removeDir("tests/ws_semver/myproject")
    removeDir("tests/ws_semver/source")

  testWsConflict()

const
  SemVer2ExpectedResult = """selected:
[ ] (proj_a, 1.0.0)
[x] (proj_a, 1.1.0)
[x] (proj_b, 1.1.0)
[x] (proj_c, 1.2.0)
"""

proc testSemVer2() =
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
      writeFile "proj_c.nimble", "requires \"proj_d >= 1.2.0\"\n"
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

  createDir "myproject"
  withDir "myproject":
    let (outp, status) = execCmdEx(atlasExe & " --list use proj_a")
    if status == 0:
      if outp.contains SemVer2ExpectedResult:
        discard "fine"
      else:
        echo "expected ", SemVer2ExpectedResult, " but got ", outp
        raise newException(AssertionDefect, "Test failed!")
    else:
      assert false, outp

withDir "tests/ws_semver2":
  try:
    testSemVer2()
  finally:
    removeDir "does_not_exist"
    removeDir "myproject"
    removeDir "source"
    removeDir "proj_a"
    removeDir "proj_b"
    removeDir "proj_c"
    removeDir "proj_d"

proc integrationTest() =
  # Test installation of some "important_packages" which we are sure
  # won't disappear in the near or far future. Turns out `nitter` has
  # quite some dependencies so it suffices:
  exec atlasExe & " use https://github.com/zedeus/nitter"
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
    cleanupIntegrationTest()

if failures > 0: quit($failures & " failures occurred.")
