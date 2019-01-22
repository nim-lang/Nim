# Small program that runs the test cases for 'nim doc'.

import strutils, os

var
  failures = 0

proc test(dir: string; fixup = false) =
  putEnv("SOURCE_DATE_EPOCH", "100000")
  if execShellCmd("nim doc --project --index:on -o:$1/htmldocs $1/testproject.nim" % dir) != 0:
    quit("FAILURE: nim doc failed")

  if execShellCmd("nim buildIndex -o:$1/htmldocs/theindex.html $1/htmldocs" % [dir]) != 0:
    quit("FAILURE: nim buildIndex failed")

  for expected in walkDirRec(dir / "expected/"):
    let produced = expected.replace('\\', '/').replace("/expected/", "/htmldocs/")
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
  removeDir(dir / "htmldocs")

test("nimdoc/testproject", defined(fixup))
if failures > 0: quit($failures & " failures occurred.")
