discard """
  targets: "c cpp"
  joinable: false
"""

## tests that don't quite fit the mold and are easier to handle via `execCmdEx`
## A few others could be added to here to simplify code.

import std/[strformat,os,osproc]

const nim = getCurrentCompilerExe()

const mode =
  when defined(c): "c"
  elif defined(cpp): "cpp"
  else: static: doAssert false

proc runCmd(file, options = ""): auto =
  const testsDir = currentSourcePath().parentDir
  let fileabs = testsDir / file.unixToNativePath
  doAssert fileabs.existsFile, fileabs
  let cmd = fmt"{nim} {mode} {options} --hints:off {fileabs}"
  result = execCmdEx(cmd)
  when false:  echo result[0] & "\n" & result[1] # for debugging

when defined(nimHasLibFFIEnabled):
  block: # mevalffi
    when defined(openbsd):
      #[
      openbsd defines `#define stderr (&__sF[2])` which makes it cumbersome
      for dlopen'ing inside `importcSymbol`. Instead of adding special rules
      inside `importcSymbol` to handle this, we disable just the part that's
      not working and will provide a more general, clean fix in future PR.
      ]#
      var opt = "-d:nimEvalffiStderrWorkaround"
      let prefix = ""
    else:
      var opt = ""
      let prefix = """
hello world stderr
hi stderr
"""
    let (output, exitCode) = runCmd("vm/mevalffi.nim", fmt"{opt} --experimental:compiletimeFFI")
    let expected = fmt"""
{prefix}foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret=[s1:foobar s2:foobar age:25 pi:3.14]
"""
    doAssert output == expected, output
    doAssert exitCode == 0

else: # don't run twice the same test
  import std/[strutils]
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

  import streams
  block: # stdin input
    let nimcmd = fmt"{nim} r --hints:off - -firstparam '-second param'"
    let inputcmd = "import os; echo commandLineParams()"
    let expected = """@["-firstparam", "-second param"]"""
    block:
      let p = startProcess(nimcmd, options = {poEvalCommand})
      p.inputStream.write("import os; echo commandLineParams()")
      p.inputStream.close
      var output = p.outputStream.readAll
      let error = p.errorStream.readAll
      doAssert p.waitForExit == 0
      doAssert error.len == 0, $error
      output.stripLineEnd
      doAssert output == expected
      p.errorStream.close
      p.outputStream.close

    block:
      when defined(posix):
        let cmd = fmt"echo 'import os; echo commandLineParams()' | {nimcmd}"
        var (output, exitCode) = execCmdEx(cmd)
        output.stripLineEnd
        doAssert output == expected
