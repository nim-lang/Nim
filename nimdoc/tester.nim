# Small program that runs the test cases for 'nim doc'.
# To run this, cd to the git repo root, and run "nim r nimdoc/tester.nim".
# to change expected results (after carefully verifying everything), use -d:nimTestsNimdocFixup

import strutils, os
from std/private/gitutils import diffFiles

const fixup = defined(nimTestsNimdocFixup)

var
  failures = 0

const
  baseDir = "nimdoc"
let
  baseDirAbs = getCurrentDir() / baseDir

type
  NimSwitches = object
    doc: seq[string]
    docStage2: seq[string]
    buildIndex: seq[string]
    md2html: seq[string]
    md2htmlStage2: seq[string]

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit("FAILURE: " & cmd)

proc testNimDoc(prjDir, docsDir: string; switches: NimSwitches; fixup = false) =
  let
    nimDocSwitches = switches.doc.join(" ")
    nimDocStage2Switches = switches.docStage2.join(" ")
    nimMd2HtmlSwitches = switches.md2html.join(" ")
    nimMd2HtmlStage2Switches = switches.md2htmlStage2.join(" ")
    nimBuildIndexSwitches = switches.buildIndex.join(" ")

  putEnv("SOURCE_DATE_EPOCH", "100000")
  const nimExe = getCurrentCompilerExe() # so that `bin/nim_temp r nimdoc/tester.nim` works

  if nimDocSwitches != "":
    exec("$1 doc $2" % [nimExe, nimDocSwitches])
    echo("$1 doc $2" % [nimExe, nimDocSwitches])

  if nimMd2HtmlSwitches != "":
    exec("$1 md2html $2" % [nimExe, nimMd2HtmlSwitches])
    echo("$1 md2html $2" % [nimExe, nimMd2HtmlSwitches])

  if nimDocStage2Switches != "":
    exec("$1 doc $2" % [nimExe, nimDocStage2Switches])
    echo("$1 doc $2" % [nimExe, nimDocStage2Switches])

  if nimMd2HtmlStage2Switches != "":
    exec("$1 md2html $2" % [nimExe, nimMd2HtmlStage2Switches])
    echo("$1 md2html $2" % [nimExe, nimMd2HtmlStage2Switches])

  if nimBuildIndexSwitches != "":
    exec("$1 buildIndex $2" % [nimExe, nimBuildIndexSwitches])
    echo("$1 buildIndex $2" % [nimExe, nimBuildIndexSwitches])

  for expected in walkDirRec(prjDir / "expected/", checkDir=true):
    let versionCacheParam = "?v=" & $NimMajor & "." & $NimMinor & "." & $NimPatch
    let produced = expected.replace('\\', '/').replace("/expected/", "/$1/" % [docsDir])
    if not fileExists(produced):
      echo "FAILURE: files not found: ", produced
      inc failures
    let producedFile = readFile(produced).replace(versionCacheParam,"") #remove version cache param used for cache invalidation
    if readFile(expected) != producedFile:
      echo "FAILURE: files differ: ", produced
      echo diffFiles(expected, produced).output
      inc failures
      if fixup:
        writeFile(expected, producedFile)
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
testNimDoc(test1Dir, test1DocsDir, test1Switches, fixup)

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
testNimDoc(test2Dir, test2DocsDir, test2Switches, fixup)

# Test `nim doc` on file with `{.doctype.}` pragma
let
  test3PrjDir = "test_doctype"
  test3PrjName = "test_doctype"
  test3Dir = baseDir / test3PrjDir
  test3DocsDir = "htmldocs"
  test3Switches = NimSwitches(doc: @["$1/$2.nim" % [test3Dir, test3PrjName]])
testNimDoc(test3Dir, test3DocsDir, test3Switches, fixup)


# Test concise external links (RFC#125) that work with `.idx` files.
# extlinks
# ├── project
# │   ├── main.nim
# │   ├── manual.md
# │   └── sub
# │       └── submodule.nim
# └── util.nim
#
# `main.nim` imports `submodule.nim` and `../utils.nim`.
# `main.nim`, `submodule.nim`, `manual.md` do importdoc and reference each other.
let
  test4PrjName = "extlinks/project"
  test4Dir = baseDir / test4PrjName
  test4DirAbs = baseDirAbs / test4PrjName
  test4MainModule = "main"
  test4MarkupDoc = "doc" / "manual.md"
  test4DocsDir = "htmldocs"
  # 1st stage is with --index:only, 2nd is final
  test4Switches = NimSwitches(
      doc: @["--project",
             "--outdir:$1/$2" % [test4Dir, test4DocsDir],
             "--index:only",
             "$1/$2.nim" % [test4Dir, test4MainModule]],
      md2html:
             @["--outdir:$1/$2" % [test4Dir, test4DocsDir],
             "--docroot:$1" % [test4DirAbs],
             "--index:only",
             "$1/$2" % [test4Dir, test4MarkupDoc]],
      docStage2:
           @["--project",
             "--outdir:$1/$2" % [test4Dir, test4DocsDir],
             "$1/$2.nim" % [test4Dir, test4MainModule]],
      md2htmlStage2:
             @["--outdir:$1/$2" % [test4Dir, test4DocsDir],
             "--docroot:$1" % [test4DirAbs],
             "$1/$2" % [test4Dir, test4MarkupDoc]],
  )
testNimDoc(test4Dir, test4DocsDir, test4Switches, fixup)

if failures > 0:
  quit "$# failures occurred; see note in nimdoc/tester.nim regarding -d:nimTestsNimdocFixup" %  $failures
