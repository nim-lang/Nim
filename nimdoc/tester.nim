# Small program that runs the test cases for 'nim doc'.
# To run this, cd to the git repo root, and run "nim r nimdoc/tester.nim".
# to change expected results (after carefully verifying everything), use -d:fixup

import strutils, os

var
  failures = 0

const
  baseDir = "nimdoc"

type
  NimSwitches = object
    doc: seq[string]
    buildIndex: seq[string]

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit("FAILURE: " & cmd)

proc testNimDoc(prjDir, docsDir: string; switches: NimSwitches; fixup = false) =
  let
    nimDocSwitches = switches.doc.join(" ")
    nimBuildIndexSwitches = switches.buildIndex.join(" ")

  putEnv("SOURCE_DATE_EPOCH", "100000")
  const nimExe = getCurrentCompilerExe() # so that `bin/nim_temp r nimdoc/tester.nim` works

  if nimDocSwitches != "":
    exec("$1 doc $2" % [nimExe, nimDocSwitches])

  if nimBuildIndexSwitches != "":
    exec("$1 buildIndex $2" % [nimExe, nimBuildIndexSwitches])

  for expected in walkDirRec(prjDir / "expected/"):
    let produced = expected.replace('\\', '/').replace("/expected/", "/$1/" % [docsDir])
    if not fileExists(produced):
      echo "FAILURE: files not found: ", produced
      inc failures
    elif readFile(expected) != readFile(produced):
      echo "FAILURE: files differ: ", produced
      discard execShellCmd("diff -uNdr " & expected & " " & produced)
      inc failures
      if fixup:
        copyFile(produced, expected)
    else:
      echo "SUCCESS: files identical: ", produced

  if failures == 0 and ((prjDir / docsDir) != prjDir):
    removeDir(prjDir / docsDir)

# Test "nim doc --project --out:.. --index:on .."
let
  test1PrjName = "testproject"
  test1Dir = baseDir / test1PrjName
  test1DocsDir = "htmldocs"
  test1Switches = NimSwitches(doc: @["--project",
                                     "--out:$1/$2" % [test1Dir, test1DocsDir],
                                     "--index:on",
                                     "$1/$2.nim" % [test1Dir, test1PrjName]],
                              buildIndex: @["--out:$1/$2/theindex.html" % [test1Dir, test1DocsDir],
                                            "$1/$2" % [test1Dir, test1DocsDir]])
testNimDoc(test1Dir, test1DocsDir, test1Switches, defined(fixup))

# Test "nim doc --out:.. --index:on .."
let
  test2PrjDir = "test_out_index_dot_html"
  test2PrjName = "foo"
  test2Dir = baseDir / test2PrjDir
  test2DocsDir = "htmldocs"
  test2Switches = NimSwitches(doc: @["--out:$1/$2/index.html" % [test2Dir, test2DocsDir],
                                     "--index:on",
                                     "$1/$2.nim" % [test2Dir, test2PrjName]],
                              buildIndex: @["--out:$1/$2/theindex.html" % [test2Dir, test2DocsDir],
                                            "$1/$2" % [test2Dir, test2DocsDir]])
testNimDoc(test2Dir, test2DocsDir, test2Switches, defined(fixup))

# Check for failures
if failures > 0: quit($failures & " failures occurred.")
