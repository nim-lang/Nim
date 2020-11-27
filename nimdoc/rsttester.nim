import os, strutils

const
  baseDir = "nimdoc/rst2html"

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
    if readFile(expectedHtml) != readFile(producedHtml):
      discard execShellCmd("diff -uNdr " & expectedHtml & " " & producedHtml)
      inc failures
      if fixup:
        copyFile(producedHtml, expectedHtml)
    else:
      echo "SUCCESS: files identical: ", producedHtml
    if failures == 0:
      removeDir(baseDir / "source/htmldocs")

testRst2Html(defined(fixup))

# Check for failures
if failures > 0: quit($failures & " failures occurred.")
