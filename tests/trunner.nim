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

when defined(nimHasLibFFIEnabled):
  block: # mevalffi
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

else: # don't run twice the same test
  template check(msg) = doAssert msg in output, output

  block: # mstatic_assert
    let (output, exitCode) = runCmd("ccgbugs/mstatic_assert.nim", "-d:caseBad")
    check "sizeof(bool) == 2"
    doAssert exitCode != 0

  block: # ABI checks
    let file = "misc/msizeof5.nim"
    block:
      let (output, exitCode) = runCmd(file, "-d:checkAbi")
      doAssert exitCode == 0, output
    block:
      let (output, exitCode) = runCmd(file, "-d:checkAbi -d:caseBad")
      # on platforms that support _StaticAssert natively, errors will show full context, eg:
      # error: static_assert failed due to requirement 'sizeof(unsigned char) == 8'
      # "backend & Nim disagree on size for: BadImportcType{int64} [declared in mabi_check.nim(1, 6)]"
      check "sizeof(unsigned char) == 8"
      check "sizeof(struct Foo2) == 1"
      check "sizeof(Foo5) == 16"
      check "sizeof(Foo5) == 3"
      check "sizeof(struct Foo6) == "
      doAssert exitCode != 0
