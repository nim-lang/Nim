import os, osproc, strutils

const Iterations = 200

proc testFdLeak() =
  var count = 0
  let
    test = getAppDir() / "tfdleak"
    exe = test.addFileExt(ExeExt).quoteShell
    options = ["", "-d:nimInheritHandles"]
  for opt in options:
    let
      run = "nim c $1 $2" % [opt, quoteShell test]
      (output, status) = execCmdEx run
    doAssert status == 0, "Test complination failed:\n$1\n$2" % [run, output]
    for i in 1..Iterations:
      let (output, status) = execCmdEx exe
      doAssert status == 0, "Execution of " & exe & " failed"
      if "leaked" in output:
        count.inc
    doAssert count == 0, "Leaked " & $count & " times"

when isMainModule: testFdLeak()
