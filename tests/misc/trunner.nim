discard """
  targets: "c cpp"
  joinable: false
"""

## tests that don't quite fit the mold and are easier to handle via `execCmdEx`
## A few others could be added to here to simplify code.
## Note: this test is a bit slow but tests a lot of things; please don't disable.

import std/[strformat,os,osproc,unittest,compilesettings]
from std/sequtils import toSeq,mapIt
from std/algorithm import sorted
import stdtest/[specialpaths, unittest_light]
from std/private/globs import nativeToUnixPath
from strutils import startsWith, strip, removePrefix
from std/sugar import dup
import "$lib/../compiler/nimpaths"

proc isDots(a: string): bool =
  ## test for `hintProcessing` dots
  a.startsWith(".") and a.strip(chars = {'.'}) == ""

const
  defaultHintsOff = "--hint:successx:off --hint:exec:off --hint:link:off --hint:cc:off --hint:conf:off --hint:processing:off --hint:QuitCalled:off"
    # useful when you want to turn only some hints on, and some common ones off.
    # pending https://github.com/timotheecour/Nim/issues/453, simplify to: `--hints:off`
  nim = getCurrentCompilerExe()
  mode = querySetting(backend)
  nimcache = buildDir / "nimcacheTrunner"
    # instead of `querySetting(nimcacheDir)`, avoids stomping on other parallel tests

proc runCmd(file, options = ""): auto =
  let fileabs = testsDir / file.unixToNativePath
  doAssert fileabs.fileExists, fileabs
  let cmd = fmt"{nim} {mode} {options} --hints:off {fileabs}"
  result = execCmdEx(cmd)
  when false:  echo result[0] & "\n" & result[1] # for debugging

when defined(nimTrunnerFfi):
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

  block: # tests with various options `nim doc --project --index --docroot`
    # regression tests for issues and PRS: #14376 #13223 #6583 ##13647
    let file = testsDir / "nimdoc/sub/mmain.nim"
    let mainFname = "mmain.html"
    let htmldocsDirCustom = nimcache / "htmldocsCustom"
    let docroot = testsDir / "nimdoc"
    let options = [
      0: "--project",
      1: "--project --docroot",
      2: "",
      3: fmt"--outDir:{htmldocsDirCustom}",
      4: fmt"--docroot:{docroot}",
      5: "--project --useNimcache",
      6: "--index:off",
    ]

    for i in 0..<options.len:
      let htmldocsDir = case i
      of 3: htmldocsDirCustom
      of 5: nimcache / htmldocsDirname
      else: file.parentDir / htmldocsDirname

      var cmd = fmt"{nim} doc --index:on --listFullPaths --hint:successX:on --nimcache:{nimcache} {options[i]} {file}"
      removeDir(htmldocsDir)
      let (outp, exitCode) = execCmdEx(cmd)
      check exitCode == 0
      let ret = toSeq(walkDirRec(htmldocsDir, relative=true)).mapIt(it.nativeToUnixPath).sorted.join("\n")
      let context = $(i, ret, cmd)
      case i
      of 0,5:
        let htmlFile = htmldocsDir/mainFname
        check htmlFile in outp # sanity check for `hintSuccessX`
        assertEquals ret, fmt"""
{dotdotMangle}/imp.html
{dotdotMangle}/imp.idx
{docHackJsFname}
imp.html
imp.idx
imp2.html
imp2.idx
{mainFname}
mmain.idx
{nimdocOutCss}
{theindexFname}""", context
      of 1: assertEquals ret, fmt"""
{docHackJsFname}
{nimdocOutCss}
tests/nimdoc/imp.html
tests/nimdoc/imp.idx
tests/nimdoc/sub/imp.html
tests/nimdoc/sub/imp.idx
tests/nimdoc/sub/imp2.html
tests/nimdoc/sub/imp2.idx
tests/nimdoc/sub/{mainFname}
tests/nimdoc/sub/mmain.idx
{theindexFname}"""
      of 2, 3: assertEquals ret, fmt"""
{docHackJsFname}
{mainFname}
mmain.idx
{nimdocOutCss}""", context
      of 4: assertEquals ret, fmt"""
{docHackJsFname}
{nimdocOutCss}
sub/{mainFname}
sub/mmain.idx""", context
      of 6: assertEquals ret, fmt"""
{mainFname}
{nimdocOutCss}""", context
      else: doAssert false

  block: # mstatic_assert
    let (output, exitCode) = runCmd("ccgbugs/mstatic_assert.nim", "-d:caseBad")
    check2 "sizeof(bool) == 2"
    check exitCode != 0

  block: # ABI checks
    let file = "misc/msizeof5.nim"
    block:
      let (output, exitCode) = runCmd(file, "-d:checkAbi")
      doAssert exitCode == 0, output
    block:
      let (output, exitCode) = runCmd(file, "-d:checkAbi -d:caseBad")
      # on platforms that support _StaticAssert natively, errors will show full context, e.g.:
      # error: static_assert failed due to requirement 'sizeof(unsigned char) == 8'
      # "backend & Nim disagree on size for: BadImportcType{int64} [declared in mabi_check.nim(1, 6)]"
      check2 "sizeof(unsigned char) == 8"
      check2 "sizeof(struct Foo2) == 1"
      check2 "sizeof(Foo5) == 16"
      check2 "sizeof(Foo5) == 3"
      check2 "sizeof(struct Foo6) == "
      check exitCode != 0

  import streams
  block: # stdin input
    let nimcmd = fmt"""{nim} r --hints:off - -firstparam "-second param" """
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
      check output == expected
      p.errorStream.close
      p.outputStream.close

    block:
      when defined posix:
        # xxx on windows, `poEvalCommand` should imply `/cmd`, (which should
        # make this work), but currently doesn't
        let cmd = fmt"""echo "import os; echo commandLineParams()" | {nimcmd}"""
        var (output, exitCode) = execCmdEx(cmd)
        output.stripLineEnd
        check output == expected
        doAssert exitCode == 0

  block: # nim doc --backend:$backend --doccmd:$cmd
    # test for https://github.com/nim-lang/Nim/issues/13129
    # test for https://github.com/nim-lang/Nim/issues/13891
    let file = testsDir / "nimdoc/m13129.nim"
    for backend in fmt"{mode} js".split:
      # pending #14343 this fails on windows: --doccmd:"-d:m13129Foo2 --hints:off"
      let cmd = fmt"""{nim} doc -b:{backend} --nimcache:{nimcache} -d:m13129Foo1 "--doccmd:-d:m13129Foo2 --hints:off" --usenimcache --hints:off {file}"""
      check execCmdEx(cmd) == (&"ok1:{backend}\nok2: backend: {backend}\n", 0)
    # checks that --usenimcache works with `nim doc`
    check fileExists(nimcache / "htmldocs/m13129.html")

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

  block: # config.nims, nim.cfg, hintConf, bug #16557
    let cmd = fmt"{nim} r {defaultHintsOff} --hint:conf tests/newconfig/bar/mfoo.nim"
    let (outp, exitCode) = execCmdEx(cmd, options = {poStdErrToStdOut})
    doAssert exitCode == 0
    let dir = getCurrentDir()
    let files = """
tests/config.nims
tests/newconfig/bar/nim.cfg
tests/newconfig/bar/config.nims
tests/newconfig/bar/mfoo.nim.cfg
tests/newconfig/bar/mfoo.nims""".splitLines
    var expected = ""
    for a in files:
      let b = dir / a
      expected.add &"Hint: used config file '{b}' [Conf]\n"
    doAssert outp.endsWith expected, outp & "\n" & expected

  block: # nim --eval
    let opt = "--hints:off"
    check fmt"""{nim} {opt} --eval:"echo defined(nimscript)"""".execCmdEx == ("true\n", 0)
    check fmt"""{nim} r {opt} --eval:"echo defined(c)"""".execCmdEx == ("true\n", 0)
    check fmt"""{nim} r -b:js {opt} --eval:"echo defined(js)"""".execCmdEx == ("true\n", 0)

  block: # `hintProcessing` dots should not interfere with `static: echo` + friends
    let cmd = fmt"""{nim} r {defaultHintsOff} --hint:processing -f --eval:"static: echo 1+1""""
    let (outp, exitCode) = execCmdEx(cmd, options = {poStdErrToStdOut})
    template check3(cond) = doAssert cond, $(outp,)
    doAssert exitCode == 0
    let lines = outp.splitLines
    check3 lines.len == 3
    when not defined(windows): # xxx: on windows, dots not properly handled, gives: `....2\n\n`
      check3 lines[0].isDots
      check3 lines[1] == "2"
      check3 lines[2] == ""
    else:
      check3 "2" in outp

  block: # nim secret
    let opt = fmt"{defaultHintsOff} --hint:processing"
    template check3(cond) = doAssert cond, $(outp,)
    for extra in ["", "--stdout"]:
      let cmd = fmt"""{nim} secret {opt} {extra}"""
      # xxx minor bug: `nim --hint:QuitCalled:off secret` ignores the hint cmdline flag
      template run(input2): untyped =
        execCmdEx(cmd, options = {poStdErrToStdOut}, input = input2)
      block:
        let (outp, exitCode) = run """echo 1+2; import strutils; echo strip(" ab "); quit()"""
        let lines = outp.splitLines
        when not defined(windows):
          check3 lines.len == 5
          check3 lines[0].isDots
          check3 lines[1].dup(removePrefix(">>> ")) == "3" # prompt depends on `nimUseLinenoise`
          check3 lines[2].isDots
          check3 lines[3] == "ab"
          check3 lines[4] == ""
        else:
          check3 "3" in outp
          check3 "ab" in outp
        doAssert exitCode == 0
      block:
        let (outp, exitCode) = run "echo 1+2; quit(2)"
        check3 "3" in outp
        doAssert exitCode == 2
