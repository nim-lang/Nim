discard """
disabled: true
"""

# issue #10441

when defined(case_D20190123T230907): # child process
  {.compile: ("fun2.c").}
  proc foo(): cint {.importc, header:"fun1.h".}
  echo foo()
else:
  # main process
  import os, osproc, strformat, strutils
  import compiler/unittest_light
  import stdtest/specialpaths

  proc main() =
    const nim = getCurrentCompilerExe()
    const input = currentSourcePath()
    const headerGen = buildDir / "D20190123T230907.h"
    defer: removeFile headerGen
    #[
    * the command line doesn't change across 2 subsequent invocations
    * we pass --forceBuild:off just to make sure it's not overridden in config file
    * the only thing that changes across the 2 `nim` invocations is  `headerGen`, included by `fun2.c`
    ]#
    let cmd = fmt"{nim} c --forceBuild:off -r --passC:-I{buildDir.quoteShell} -d:case_D20190123T230907 {input}"
    for a in [123, 124]:
      writeFile headerGen, fmt"""
#define MYVAR {a}
"""
      var (output, exitCode) = execCmdEx(cmd, options = {})
      doAssert exitCode == 0
      output.stripLineEnd
      assertEquals output, $a
  main()
