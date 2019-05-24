# Small program that runs the test cases for 'nim doc'.
# To run this, cd to the git repo root, and run "nim c -r nimdoc/tester.nim".

import strutils, os

var
  failures = 0

const
  baseDir = "nimdoc"

type
  NimSwitches = object
    doc: seq[string]
    buildIndex: seq[string]

proc testNimDoc(prjDir, docsDir: string; switches: NimSwitches; fixup = false) =
  let
    nimDocSwitches = switches.doc.join(" ")
    nimBuildIndexSwitches = switches.buildIndex.join(" ")

  putEnv("SOURCE_DATE_EPOCH", "100000")

  if nimDocSwitches != "":
    if execShellCmd("nim doc $1" % [nimDocSwitches]) != 0:
      quit("FAILURE: nim doc failed")

  if nimBuildIndexSwitches != "":
    if execShellCmd("nim buildIndex $1" % [nimBuildIndexSwitches]) != 0:
      quit("FAILURE: nim buildIndex failed")

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

  if failures == 0:
    removeDir(prjDir / docsDir)

# Test "nim doc --project .."
let
  test1PrjName = "testproject"
  test1Dir = baseDir / test1PrjName
  test1DocsDir = "htmldocs"
  test1Switches = NimSwitches(doc: @["--project",
                                     "--index:on",
                                     "--outdir:$1/$2" % [test1Dir, test1DocsDir],
                                     "$1/$2.nim" % [test1Dir, test1PrjName]],
                              buildIndex: @["--out:$1/$2/theindex.html" % [test1Dir, test1DocsDir],
                                            "$1/$2" % [test1Dir, test1DocsDir]])
testNimDoc(test1Dir, test1DocsDir, test1Switches, defined(fixup))

# Check for failures
if failures > 0: quit($failures & " failures occurred.")
