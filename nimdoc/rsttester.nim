# To run this, cd to the git repo root, and run "nim r nimdoc/rsttester.nim".
# to change expected results (after carefully verifying everything), use -d:nimTestsNimdocFixup

import os, strutils
from std/private/gitutils import diffFiles

const
  baseDir = "nimdoc/rst2html"

const fixup = defined(nimTestsNimdocFixup)

var failures = 0

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit("FAILURE: " & cmd)

proc testRst2Html(fixup = false) =
  putEnv("SOURCE_DATE_EPOCH", "100000")
  const nimExe = getCurrentCompilerExe() # so that `bin/nim_temp r nimdoc/tester.nim` works

  for expectedHtml in walkDir(baseDir / "expected"):
    let expectedHtml = expectedHtml.path
    let sourceFile = expectedHtml.replace('\\', '/').replace("/expected/", "/source/").replace(".html", ".rst")
    exec("$1 rst2html $2" % [nimExe, sourceFile])
    let producedHtml = expectedHtml.replace('\\', '/').replace("/expected/", "/source/htmldocs/")
    let versionCacheParam = "?v=" & $NimMajor & "." & $NimMinor & "." & $NimPatch
    let producedFile = readFile(producedHtml).replace(versionCacheParam,"") #remove version cache param used for cache invalidation
    if readFile(expectedHtml) != producedFile:
      echo diffFiles(expectedHtml, producedHtml).output
      inc failures
      if fixup:
        writeFile(expectedHtml, producedFile)
    else:
      echo "SUCCESS: files identical: ", producedHtml
    if failures == 0:
      removeDir(baseDir / "source/htmldocs")

testRst2Html(fixup)

# Check for failures
if failures > 0: quit($failures & " failures occurred.")
