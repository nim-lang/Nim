# To run this, cd to the git repo root, and run "nim r nimdoc/booketester.nim".
# to change expected results (after carefully verifying everything), use -d:nimTestsNimdocFixup

import strutils, os
from std/private/gitutils import diffFiles

const fixup = defined(nimTestsNimdocFixup)

var
  failures = 0

const
  prjDir = "nimdoc" / "bookproject"
  expDir = "expected"
  outDir =  "book"

proc exec(cmd: string) =
  if execShellCmd(cmd) != 0:
    quit("FAILURE: " & cmd)

proc testNimBook(fixup = false) =
  putEnv("SOURCE_DATE_EPOCH", "100000")
  const nimExe = getCurrentCompilerExe()

  exec("$1 doc --index:on --project --outdir:$2 $3" % [nimExe,
                                                       prjDir / outDir / "api",
                                                       prjDir / "code1.nim"])
  exec("$1 book --index:only --outdir:$2 $3" % [nimExe, prjDir / outDir, prjDir])
  exec("$1 book --outdir:$2 $3" % [nimExe, prjDir / outDir, prjDir])

  for expected in walkDirRec(prjDir / expDir, checkDir=true):
    let versionCacheParam = "?v=" & $NimMajor & "." & $NimMinor & "." & $NimPatch
    let produced = expected.replace('\\', '/').replace("/$1/" % [expDir], "/$1/" % [outDir])
    if not fileExists(produced):
      echo "FAILURE: files not found: ", produced
      inc failures
    let producedFile = readFile(produced).replace(versionCacheParam,"")
    if readFile(expected) != producedFile:
      echo "FAILURE: files differ: ", produced
      echo diffFiles(expected, produced).output
      inc failures
      if fixup:
        writeFile(expected, producedFile)
    else:
      echo "SUCCESS: files identical: ", produced

  if failures == 0:
    removeDir(prjDir / outDir)

testNimBook(fixup)

if failures > 0:
  quit "$# failures occurred; see note in nimdoc/tester.nim regarding -d:nimTestsNimdocFixup" %  $failures
