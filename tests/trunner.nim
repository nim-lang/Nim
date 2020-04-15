discard """
  joinable: false
"""

## tests that don't quite fit the mold and are easier to handle via `execCmdEx`
## A few others could be added to here to simplify code.

import std/[strformat,os,osproc,strutils]

proc runCmd(file, options = ""): auto =
  let mode = if existsEnv("NIM_COMPILE_TO_CPP"): "cpp" else: "c"
  const nim = getCurrentCompilerExe()
  const testsDir = currentSourcePath().parentDir
  let fileabs = testsDir / file.unixToNativePath
  doAssert fileabs.existsFile, fileabs
  let cmd = fmt"{nim} {mode} {options} --hints:off {fileabs}"
  result = execCmdEx(cmd)
  when false: # uncomment if you need to debug
    echo result[0]
    echo result[1]

proc testCodegenStaticAssert() =
  let (output, exitCode) = runCmd("ccgbugs/mstatic_assert.nim")
  doAssert "sizeof(bool) == 2" in output
  doAssert exitCode != 0

proc testCTFFI() =
  let (output, exitCode) = runCmd("vm/mevalffi.nim", "--experimental:compiletimeFFI")
  let expected = """
hello world stderr
hi stderr
foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret={s1:foobar s2:foobar age:25 pi:3.14}
"""
  doAssert output == expected, output
  doAssert exitCode == 0

when defined(nimHasLibFFIEnabled):
  testCTFFI()
else: # don't run twice the same test
  testCodegenStaticAssert()
