discard """
  output: ""
"""
# test the osproc module

import compiler/unittest_light
import std/special_paths

when defined(case_testfile): # compiled test file for child process
  from posix import exitnow
  proc c_exit2(code: c_int): void {.importc: "_exit", header: "<unistd.h>".}
  import os
  var a = 0
  proc fun(b = 0) =
    a.inc
    # if a mod 100000 == 0:
    if a mod 10000000 == 0:
      echo a
      discard
    fun(b+1)

  proc main() =
    let args = commandLineParams()
    # echo "ok1"
    echo (msg: "child binary", pid: getCurrentProcessId())
    let arg = args[0]
    echo (arg: arg)
    case arg
    of "exit_0":
      if true: quit(0)
    of "exitnow_139":
      if true: exitnow(139)
    of "c_exit2_139":
      if true: c_exit2(139)
    of "quit_139":
      #[
      139-128=11=SIGSEGV
      ]#
      if true: quit(139)
    of "exit_recursion": # stack overflow by infinite recursion
      fun()
      echo a
    of "exit_array": # bad array access
      echo args[1]
  main()

else:

  import os, osproc, strutils, posix

  block execShellCmdTest:
    ## first, compile child program
    const nim = getCurrentCompilerExe()
    const sourcePath = currentSourcePath()
    let output = buildDir / "D20190111T024543".addFileExt(ExeExt)
    let cmd = "$# c -o:$# -d:release -d:case_testfile $#" % [nim, output,
        sourcePath]
    # we're testing `execShellCmd` so don't rely on it to compile test file
    # note: this should be exported in posix.nim
    proc c_system(cmd: cstring): cint {.importc: "system",
      header: "<stdlib.h>".}
    assertEquals c_system(cmd), 0

    ## use it
    template runTest(arg: string, expected: int) =
      echo (arg2: arg, expected2: expected)
      assertEquals execShellCmd(output & " " & arg), expected

    runTest("exit_0", 0)
    runTest("exitnow_139", 139)
    runTest("c_exit2_139", 139)
    runTest("quit_139", 139)
    runTest("exit_array", 1)
    runTest("exit_recursion", SIGSEGV.int + 128)

    assertEquals exitStatusLikeShell(SIGSEGV), SIGSEGV + 128.cint

  block execProcessTest:
    let dir = parentDir(currentSourcePath())
    let (outp, err) = execCmdEx("nim c " & quoteShell(dir / "osproctest.nim"))
    doAssert err == 0
    let exePath = dir / addFileExt("osproctest", ExeExt)
    let outStr1 = execProcess(exePath, workingDir = dir, args = ["foo",
        "b A r"], options = {})
    doAssert outStr1 == dir & "\nfoo\nb A r\n"

    const testDir = "t e st"
    createDir(testDir)
    doAssert dirExists(testDir)
    let outStr2 = execProcess(exePath, workingDir = testDir, args = ["x yz"],
        options = {})
    doAssert outStr2 == absolutePath(testDir) & "\nx yz\n"

    removeDir(testDir)
    removeFile(exePath)
