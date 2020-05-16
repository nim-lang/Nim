discard """
  targets: "c cpp"
  joinable: false
"""

## tests that don't quite fit the mold and are easier to handle via `execCmdEx`
## A few others could be added to here to simplify code.

import std/[strformat,os,osproc,unittest]

const nim = getCurrentCompilerExe()

const mode =
  when defined(c): "c"
  elif defined(cpp): "cpp"
  else: static: doAssert false

const testsDir = currentSourcePath().parentDir
const buildDir = testsDir.parentDir / "build"
const nimcache = buildDir / "nimcacheTrunner"
  # `querySetting(nimcacheDir)` would also be possible, but we thus
  # avoid stomping on other parallel tests

proc runCmd(file, options = ""): auto =
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
  template check2(msg) = doAssert msg in output, output

  block: # mstatic_assert
    let (output, exitCode) = runCmd("ccgbugs/mstatic_assert.nim", "-d:caseBad")
    check2 "sizeof(bool) == 2"
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
      check2 "sizeof(unsigned char) == 8"
      check2 "sizeof(struct Foo2) == 1"
      check2 "sizeof(Foo5) == 16"
      check2 "sizeof(Foo5) == 3"
      check2 "sizeof(struct Foo6) == "
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

  block: # nim doc --backend:$backend --doccmd:$cmd
    # test for https://github.com/nim-lang/Nim/issues/13129
    # test for https://github.com/nim-lang/Nim/issues/13891
    let file = testsDir / "nimdoc/m13129.nim"
    for backend in fmt"{mode} js".split:
      let cmd = fmt"{nim} doc -b:{backend} --nimcache:{nimcache} -d:m13129Foo1 --doccmd:'-d:m13129Foo2 --hints:off' --usenimcache --hints:off {file}"
      check execCmdEx(cmd) == (&"ok1:{backend}\nok2: backend: {backend}\n", 0)
    # checks that --usenimcache works with `nim doc`
    check fileExists(nimcache / "m13129.html")

    block: # mak sure --backend works with `nim r`
      let cmd = fmt"{nim} r --backend:{mode} --hints:off --nimcache:{nimcache} {file}"
      check execCmdEx(cmd) == ("ok3\n", 0)

  block: # further issues with `--backend`
    let file = testsDir / "misc/mbackend.nim"
    var cmd = fmt"{nim} doc -b:cpp --hints:off --nimcache:{nimcache} {file}"
    check execCmdEx(cmd) == ("", 0)
    cmd = fmt"{nim} check -b:c -b:cpp --hints:off --nimcache:{nimcache} {file}"
    check execCmdEx(cmd) == ("", 0)
    # issue https://github.com/timotheecour/Nim/issues/175
    cmd = fmt"{nim} c -b:js -b:cpp --hints:off --nimcache:{nimcache} {file}"
    check execCmdEx(cmd) == ("", 0)

  block: # some importc tests
    # issue #14314
    let file = testsDir / "misc/mimportc.nim"
    let cmd = fmt"{nim} r -b:cpp --hints:off --nimcache:{nimcache} --warningAsError:ProveInit {file}"
    check execCmdEx(cmd) == ("witness\n", 0)
