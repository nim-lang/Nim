#
#
#            Nim Testament
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nim against the testcases.

import
  strutils, pegs, os, osproc, streams, json, std/exitprocs,
  backend, parseopt, specs, htmlgen, browsers, terminal,
  algorithm, times, md5, azure, intsets, macros
from std/sugar import dup
import compiler/nodejs
import lib/stdtest/testutils
from lib/stdtest/specialpaths import splitTestFile

var useColors = true
var backendLogging = true
var simulate = false

const
  failString* = "FAIL: " # ensures all failures can be searched with 1 keyword in CI logs
  testsDir = "tests" & DirSep
  resultsFile = "testresults.html"
  Usage = """Usage:
  testament [options] command [arguments]

Command:
  p|pat|pattern <glob>        run all the tests matching the given pattern
  all                         run all tests
  c|cat|category <category>   run all the tests of a certain category
  r|run <test>                run single test file
  html                        generate $1 from the database
  stats                       generate statistics about test cases
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --simulate                see what tests would be run but don't run them (for debugging)
  --failing                 only show failing/ignored tests
  --targets:"c cpp js objc" run tests for specified targets (default: all)
  --nim:path                use a particular nim executable (default: $$PATH/nim)
  --directory:dir           Change to directory dir before reading the tests or doing anything else.
  --colors:on|off           Turn messages coloring on|off.
  --backendLogging:on|off   Disable or enable backend logging. By default turned on.
  --megatest:on|off         Enable or disable megatest. Default is on.
  --skipFrom:file           Read tests to skip from `file` - one test per line, # comments ignored

On Azure Pipelines, testament will also publish test results via Azure Pipelines' Test Management API
provided that System.AccessToken is made available via the environment variable SYSTEM_ACCESSTOKEN.

Experimental: using environment variable `NIM_TESTAMENT_REMOTE_NETWORKING=1` enables
tests with remote networking (as in CI).
""" % resultsFile

proc isNimRepoTests(): bool =
  # this logic could either be specific to cwd, or to some file derived from
  # the input file, eg testament r /pathto/tests/foo/tmain.nim; we choose
  # the former since it's simpler and also works with `testament all`.
  let file = "testament"/"testament.nim.cfg"
  result = file.fileExists

type
  Category = distinct string
  TResults = object
    total, passed, skipped: int
    data: string
  TTest = object
    name: string
    cat: Category
    options: string
    args: seq[string]
    spec: TSpec
    startTime: float

# ----------------------------------------------------------------------------

let
  pegLineError =
    peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' ('Error') ':' \s* {.*}"

  pegLineTemplate =
    peg"""
      {[^(]*} '(' {\d+} ', ' {\d+} ') '
      'template/generic instantiation' ( ' of `' [^`]+ '`' )? ' from here' .*
    """
  pegOtherError = peg"'Error:' \s* {.*}"
  pegOfInterest = pegLineError / pegOtherError

var gTargets = {low(TTarget)..high(TTarget)}
var targetsSet = false

proc isSuccess(input: string): bool =
  # not clear how to do the equivalent of pkg/regex's: re"FOO(.*?)BAR" in pegs
  # note: this doesn't handle colors, eg: `\e[1m\e[0m\e[32mHint:`; while we
  # could handle colors, there would be other issues such as handling other flags
  # that may appear in user config (eg: `--listFullPaths`).
  # Passing `XDG_CONFIG_HOME= testament args...` can be used to ignore user config
  # stored in XDG_CONFIG_HOME, refs https://wiki.archlinux.org/index.php/XDG_Base_Directory
  input.startsWith("Hint: ") and input.endsWith("[SuccessX]")

proc getFileDir(filename: string): string =
  result = filename.splitFile().dir
  if not result.isAbsolute():
    result = getCurrentDir() / result

proc execCmdEx2(command: string, args: openArray[string]; workingDir, input: string = ""): tuple[
                cmdLine: string,
                output: string,
                exitCode: int] {.tags:
                [ExecIOEffect, ReadIOEffect, RootEffect], gcsafe.} =

  result.cmdLine.add quoteShell(command)
  for arg in args:
    result.cmdLine.add ' '
    result.cmdLine.add quoteShell(arg)
  var p = startProcess(command, workingDir = workingDir, args = args,
                       options = {poStdErrToStdOut, poUsePath})
  var outp = outputStream(p)

  # There is no way to provide input for the child process
  # anymore. Closing it will create EOF on stdin instead of eternal
  # blocking.
  let instream = inputStream(p)
  instream.write(input)
  close instream

  result.exitCode = -1
  var line = newStringOfCap(120)
  while true:
    if outp.readLine(line):
      result.output.add line
      result.output.add '\n'
    else:
      result.exitCode = peekExitCode(p)
      if result.exitCode != -1: break
  close(p)

proc nimcacheDir(filename, options: string, target: TTarget): string =
  ## Give each test a private nimcache dir so they don't clobber each other's.
  let hashInput = options & $target
  result = "nimcache" / (filename & '_' & hashInput.getMD5)

proc prepareTestArgs(cmdTemplate, filename, options, nimcache: string,
                     target: TTarget, extraOptions = ""): seq[string] =
  var options = target.defaultOptions & ' ' & options
  # improve pending https://github.com/nim-lang/Nim/issues/14343
  if nimcache.len > 0: options.add ' ' & ("--nimCache:" & nimcache).quoteShell
  options.add ' ' & extraOptions
  result = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                      "options", options, "file", filename.quoteShell,
                      "filedir", filename.getFileDir(), "nim", compilerPrefix])

proc callCompiler(cmdTemplate, filename, options, nimcache: string,
                  target: TTarget, extraOptions = ""): TSpec =
  let c = prepareTestArgs(cmdTemplate, filename, options, nimcache, target,
                          extraOptions)
  result.cmd = quoteShellCommand(c)
  var p = startProcess(command = c[0], args = c[1 .. ^1],
                       options = {poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var tmpl = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while true:
    if outp.readLine(x):
      result.nimout.add(x & '\n')
      if x =~ pegOfInterest:
        # `err` should contain the last error/warning message
        err = x
      elif x =~ pegLineTemplate and err == "":
        # `tmpl` contains the last template expansion before the error
        tmpl = x
      elif x.isSuccess:
        suc = x
    elif not running(p):
      break
  close(p)
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = 0
  result.column = 0
  result.tfile = ""
  result.tline = 0
  result.tcolumn = 0
  result.err = reNimcCrash
  if tmpl =~ pegLineTemplate:
    result.tfile = extractFilename(matches[0])
    result.tline = parseInt(matches[1])
    result.tcolumn = parseInt(matches[2])
  if err =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.column = parseInt(matches[2])
    result.msg = matches[3]
  elif err =~ pegOtherError:
    result.msg = matches[0]
  elif suc.isSuccess:
    result.err = reSuccess

proc callCCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = prepareTestArgs(cmdTemplate, filename, options, nimcache = "", target)
  var p = startProcess(command = "gcc", args = c[5 .. ^1],
                       options = {poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var x = newStringOfCap(120)
  result.nimout = ""
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = -1
  while true:
    if outp.readLine(x):
      result.nimout.add(x & '\n')
    elif not running(p):
      break
  close(p)
  if p.peekExitCode == 0:
    result.err = reSuccess

proc initResults: TResults =
  result.total = 0
  result.passed = 0
  result.skipped = 0
  result.data = ""

macro ignoreStyleEcho(args: varargs[typed]): untyped =
  let typForegroundColor = bindSym"ForegroundColor".getType
  let typBackgroundColor = bindSym"BackgroundColor".getType
  let typStyle = bindSym"Style".getType
  let typTerminalCmd = bindSym"TerminalCmd".getType
  result = newCall(bindSym"echo")
  for arg in children(args):
    if arg.kind == nnkNilLit: continue
    let typ = arg.getType
    if typ.kind != nnkEnumTy or
       typ != typForegroundColor and
       typ != typBackgroundColor and
       typ != typStyle and
       typ != typTerminalCmd:
      result.add(arg)

template maybeStyledEcho(args: varargs[untyped]): untyped =
  if useColors:
    styledEcho(args)
  else:
    ignoreStyleEcho(args)


proc `$`(x: TResults): string =
  result = ("Tests passed: $1 / $3 <br />\n" &
            "Tests skipped: $2 / $3 <br />\n") %
            [$x.passed, $x.skipped, $x.total]

proc addResult(r: var TResults, test: TTest, target: TTarget,
               expected, given: string, successOrig: TResultEnum) =
  # test.name is easier to find than test.name.extractFilename
  # A bit hacky but simple and works with tests/testament/tshould_not_work.nim
  var name = test.name.replace(DirSep, '/')
  name.add ' ' & $target
  if test.options.len > 0: name.add ' ' & test.options

  let duration = epochTime() - test.startTime
  let success = if test.spec.timeout > 0.0 and duration > test.spec.timeout: reTimeout
                else: successOrig

  let durationStr = duration.formatFloat(ffDecimal, precision = 2).align(5)
  if backendLogging:
    backend.writeTestResult(name = name,
                            category = test.cat.string,
                            target = $target,
                            action = $test.spec.action,
                            result = $success,
                            expected = expected,
                            given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  template disp(msg) =
    maybeStyledEcho styleDim, fgYellow, msg & ' ', styleBright, fgCyan, name
  if success == reSuccess:
    maybeStyledEcho fgGreen, "PASS: ", fgCyan, alignLeft(name, 60), fgBlue, " (", durationStr, " sec)"
  elif success == reDisabled:
    if test.spec.inCurrentBatch: disp("SKIP:")
    else: disp("NOTINBATCH:")
  elif success == reJoined: disp("JOINED:")
  else:
    maybeStyledEcho styleBright, fgRed, failString, fgCyan, name
    maybeStyledEcho styleBright, fgCyan, "Test \"", test.name, "\"", " in category \"", test.cat.string, "\""
    maybeStyledEcho styleBright, fgRed, "Failure: ", $success
    if success in {reBuildFailed, reNimcCrash, reInstallFailed}:
      # expected is empty, no reason to print it.
      echo given
    else:
      maybeStyledEcho fgYellow, "Expected:"
      maybeStyledEcho styleBright, expected, "\n"
      maybeStyledEcho fgYellow, "Gotten:"
      maybeStyledEcho styleBright, given, "\n"


  if backendLogging and (isAppVeyor or isAzure):
    let (outcome, msg) =
      case success
      of reSuccess:
        ("Passed", "")
      of reDisabled, reJoined:
        ("Skipped", "")
      of reBuildFailed, reNimcCrash, reInstallFailed:
        ("Failed", "Failure: " & $success & '\n' & given)
      else:
        ("Failed", "Failure: " & $success & "\nExpected:\n" & expected & "\n\n" & "Gotten:\n" & given)
    if isAzure:
      azure.addTestResult(name, test.cat.string, int(duration * 1000), msg, success)
    else:
      var p = startProcess("appveyor", args = ["AddTest", test.name.replace("\\", "/") & test.options,
                           "-Framework", "nim-testament", "-FileName",
                           test.cat.string,
                           "-Outcome", outcome, "-ErrorMessage", msg,
                           "-Duration", $(duration * 1000).int],
                           options = {poStdErrToStdOut, poUsePath, poParentStreams})
      discard waitForExit(p)
      close(p)

proc checkForInlineErrors(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  let pegLine = peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' {[^:]*} ':' \s* {.*}"
  var covered = initIntSet()
  for line in splitLines(given.nimout):

    if line =~ pegLine:
      let file = extractFilename(matches[0])
      let line = try: parseInt(matches[1]) except: -1
      let col = try: parseInt(matches[2]) except: -1
      let kind = matches[3]
      let msg = matches[4]

      if file == extractFilename test.name:
        var i = 0
        for x in expected.inlineErrors:
          if x.line == line and (x.col == col or x.col < 0) and
              x.kind == kind and x.msg in msg:
            covered.incl i
          inc i

  block coverCheck:
    for j in 0..high(expected.inlineErrors):
      if j notin covered:
        var e = test.name
        e.add '('
        e.addInt expected.inlineErrors[j].line
        if expected.inlineErrors[j].col > 0:
          e.add ", "
          e.addInt expected.inlineErrors[j].col
        e.add ") "
        e.add expected.inlineErrors[j].kind
        e.add ": "
        e.add expected.inlineErrors[j].msg

        r.addResult(test, target, e, given.nimout, reMsgsDiffer)
        break coverCheck

    r.addResult(test, target, "", given.msg, reSuccess)
    inc(r.passed)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  if expected.inlineErrors.len > 0:
    checkForInlineErrors(r, expected, given, test, target)
  elif strip(expected.msg) notin strip(given.msg):
    r.addResult(test, target, expected.msg, given.msg, reMsgsDiffer)
  elif expected.nimout.len > 0 and not greedyOrderedSubsetLines(expected.nimout, given.nimout):
    r.addResult(test, target, expected.nimout, given.nimout, reMsgsDiffer)
  elif expected.tfile == "" and extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, target, expected.file, given.file, reFilesDiffer)
  elif expected.line != given.line and expected.line != 0 or
       expected.column != given.column and expected.column != 0:
    r.addResult(test, target, $expected.line & ':' & $expected.column,
                      $given.line & ':' & $given.column,
                      reLinesDiffer)
  elif expected.tfile != "" and extractFilename(expected.tfile) != extractFilename(given.tfile) and
      "internal error:" notin expected.msg:
    r.addResult(test, target, expected.tfile, given.tfile, reFilesDiffer)
  elif expected.tline != given.tline and expected.tline != 0 or
       expected.tcolumn != given.tcolumn and expected.tcolumn != 0:
    r.addResult(test, target, $expected.tline & ':' & $expected.tcolumn,
                      $given.tline & ':' & $given.tcolumn,
                      reLinesDiffer)
  else:
    r.addResult(test, target, expected.msg, given.msg, reSuccess)
    inc(r.passed)

proc generatedFile(test: TTest, target: TTarget): string =
  if target == targetJS:
    result = test.name.changeFileExt("js")
  else:
    let (_, name, _) = test.name.splitFile
    let ext = targetToExt[target]
    result = nimcacheDir(test.name, test.options, target) / "@m" & name.changeFileExt(ext)

proc needsCodegenCheck(spec: TSpec): bool =
  result = spec.maxCodeSize > 0 or spec.ccodeCheck.len > 0

proc codegenCheck(test: TTest, target: TTarget, spec: TSpec, expectedMsg: var string,
                  given: var TSpec) =
  try:
    let genFile = generatedFile(test, target)
    let contents = readFile(genFile)
    for check in spec.ccodeCheck:
      if check.len > 0 and check[0] == '\\':
        # little hack to get 'match' support:
        if not contents.match(check.peg):
          given.err = reCodegenFailure
      elif contents.find(check.peg) < 0:
        given.err = reCodegenFailure
      expectedMsg = check
    if spec.maxCodeSize > 0 and contents.len > spec.maxCodeSize:
      given.err = reCodegenFailure
      given.msg = "generated code size: " & $contents.len
      expectedMsg = "max allowed size: " & $spec.maxCodeSize
  except ValueError:
    given.err = reInvalidPeg
    echo getCurrentExceptionMsg()
  except IOError:
    given.err = reCodeNotFound
    echo getCurrentExceptionMsg()

proc nimoutCheck(test: TTest; expectedNimout: string; given: var TSpec) =
  if not greedyOrderedSubsetLines(expectedNimout, given.nimout):
    given.err = reMsgsDiffer

proc compilerOutputTests(test: TTest, target: TTarget, given: var TSpec,
                         expected: TSpec; r: var TResults) =
  var expectedmsg: string = ""
  var givenmsg: string = ""
  if given.err == reSuccess:
    if expected.needsCodegenCheck:
      codegenCheck(test, target, expected, expectedmsg, given)
      givenmsg = given.msg
    if expected.nimout.len > 0:
      expectedmsg = expected.nimout
      givenmsg = given.nimout.strip
      nimoutCheck(test, expectedmsg, given)
  else:
    givenmsg = "$ " & given.cmd & '\n' & given.nimout
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, target, expectedmsg, givenmsg, given.err)

proc getTestSpecTarget(): TTarget =
  if getEnv("NIM_COMPILE_TO_CPP", "false") == "true":
    result = targetCpp
  else:
    result = targetC

proc checkDisabled(r: var TResults, test: TTest): bool =
  if test.spec.err in {reDisabled, reJoined}:
    # targetC is a lie, but parameter is required
    r.addResult(test, targetC, "", "", test.spec.err)
    inc(r.skipped)
    inc(r.total)
    result = false
  else:
    result = true

var count = 0

proc equalModuloLastNewline(a, b: string): bool =
  # allow lazy output spec that omits last newline, but really those should be fixed instead
  result = a == b or b.endsWith("\n") and a == b[0 ..< ^1]

proc testSpecHelper(r: var TResults, test: var TTest, expected: TSpec,
                    target: TTarget, nimcache: string, extraOptions = "") =
  test.startTime = epochTime()
  case expected.action
  of actionCompile:
    var given = callCompiler(expected.getCmd, test.name, test.options, nimcache, target,
          extraOptions = " --stdout --hint[Path]:off --hint[Processing]:off")
    compilerOutputTests(test, target, given, expected, r)
  of actionRun:
    var given = callCompiler(expected.getCmd, test.name, test.options,
                             nimcache, target, extraOptions)
    if given.err != reSuccess:
      r.addResult(test, target, "", "$ " & given.cmd & '\n' & given.nimout, given.err)
    else:
      let isJsTarget = target == targetJS
      var exeFile = changeFileExt(test.name, if isJsTarget: "js" else: ExeExt)
      if not fileExists(exeFile):
        r.addResult(test, target, expected.output,
                    "executable not found: " & exeFile, reExeNotFound)
      else:
        let nodejs = if isJsTarget: findNodeJs() else: ""
        if isJsTarget and nodejs == "":
          r.addResult(test, target, expected.output, "nodejs binary not in PATH",
                      reExeNotFound)
        else:
          var exeCmd: string
          var args = test.args
          if isJsTarget:
            exeCmd = nodejs
            # see D20210217T215950
            args = @["--unhandled-rejections=strict", exeFile] & args
          else:
            exeCmd = exeFile.dup(normalizeExe)
            if expected.useValgrind != disabled:
              var valgrindOptions = @["--error-exitcode=1"]
              if expected.useValgrind != leaking:
                valgrindOptions.add "--leak-check=yes"
              args = valgrindOptions & exeCmd & args
              exeCmd = "valgrind"
          # xxx honor `testament --verbose` here
          var (_, buf, exitCode) = execCmdEx2(exeCmd, args, input = expected.input)
          # Treat all failure codes from nodejs as 1. Older versions of nodejs used
          # to return other codes, but for us it is sufficient to know that it's not 0.
          if exitCode != 0: exitCode = 1
          let bufB =
            if expected.sortoutput:
              var buf2 = buf
              buf2.stripLineEnd
              var x = splitLines(buf2)
              sort(x, system.cmp)
              join(x, "\n") & '\n'
            else:
              buf
          if exitCode != expected.exitCode:
            r.addResult(test, target, "exitcode: " & $expected.exitCode,
                              "exitcode: " & $exitCode & "\n\nOutput:\n" &
                              bufB, reExitcodesDiffer)
          elif (expected.outputCheck == ocEqual and not expected.output.equalModuloLastNewline(bufB)) or
              (expected.outputCheck == ocSubstr and expected.output notin bufB):
            given.err = reOutputsDiffer
            r.addResult(test, target, expected.output, bufB, reOutputsDiffer)
          else:
            compilerOutputTests(test, target, given, expected, r)
  of actionReject:
    var given = callCompiler(expected.getCmd, test.name, test.options,
                              nimcache, target)
    cmpMsgs(r, expected, given, test, target)

proc targetHelper(r: var TResults, test: TTest, expected: TSpec, extraOptions = "") =
  for target in expected.targets:
    inc(r.total)
    if target notin gTargets:
      r.addResult(test, target, "", "", reDisabled)
      inc(r.skipped)
    elif simulate:
      inc count
      echo "testSpec count: ", count, " expected: ", expected
    else:
      let nimcache = nimcacheDir(test.name, test.options, target)
      var testClone = test
      testSpecHelper(r, testClone, expected, target, nimcache, extraOptions)

proc testSpec(r: var TResults, test: TTest, targets: set[TTarget] = {}) =
  var expected = test.spec
  if expected.parseErrors.len > 0:
    # targetC is a lie, but a parameter is required
    r.addResult(test, targetC, "", expected.parseErrors, reInvalidSpec)
    inc(r.total)
    return
  if not checkDisabled(r, test): return

  expected.targets.incl targets
  # still no target specified at all
  if expected.targets == {}:
    expected.targets = {getTestSpecTarget()}
  if test.spec.matrix.len > 0:
    for m in test.spec.matrix:
      targetHelper(r, test, expected, m)
  else:
    targetHelper(r, test, expected)

proc testSpecWithNimcache(r: var TResults, test: TTest; nimcache: string) {.used.} =
  if not checkDisabled(r, test): return
  for target in test.spec.targets:
    inc(r.total)
    var testClone = test
    testSpecHelper(r, testClone, test.spec, target, nimcache)

proc testC(r: var TResults, test: TTest, action: TTestAction) =
  # runs C code. Doesn't support any specs, just goes by exit code.
  if not checkDisabled(r, test): return

  let tname = test.name.addFileExt(".c")
  inc(r.total)
  maybeStyledEcho "Processing ", fgCyan, extractFilename(tname)
  var given = callCCompiler(getCmd(TSpec()), test.name & ".c", test.options, targetC)
  if given.err != reSuccess:
    r.addResult(test, targetC, "", given.msg, given.err)
  elif action == actionRun:
    let exeFile = changeFileExt(test.name, ExeExt)
    var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
    if exitCode != 0: given.err = reExitcodesDiffer
  if given.err == reSuccess: inc(r.passed)

proc testExec(r: var TResults, test: TTest) =
  # runs executable or script, just goes by exit code
  if not checkDisabled(r, test): return

  inc(r.total)
  let (outp, errC) = execCmdEx(test.options.strip())
  var given: TSpec
  if errC == 0:
    given.err = reSuccess
  else:
    given.err = reExitcodesDiffer
    given.msg = outp

  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, targetC, "", given.msg, given.err)

proc makeTest(test, options: string, cat: Category): TTest =
  result.cat = cat
  result.name = test
  result.options = options
  result.spec = parseSpec(addFileExt(test, ".nim"))
  result.startTime = epochTime()

proc makeRawTest(test, options: string, cat: Category): TTest {.used.} =
  result.cat = cat
  result.name = test
  result.options = options
  result.spec = initSpec(addFileExt(test, ".nim"))
  result.startTime = epochTime()
  result.spec.action = actionCompile
  result.spec.targets = {getTestSpecTarget()}

# TODO: fix these files
const disabledFilesDefault = @[
  "LockFreeHash.nim",
  "sharedstrings.nim",
  "tableimpl.nim",
  "setimpl.nim",
  "hashcommon.nim",

  # Requires compiling with '--threads:on`
  "sharedlist.nim",
  "sharedtables.nim",

  # Error: undeclared identifier: 'hasThreadSupport'
  "ioselectors_epoll.nim",
  "ioselectors_kqueue.nim",
  "ioselectors_poll.nim",

  # Error: undeclared identifier: 'Timeval'
  "ioselectors_select.nim",
]

when defined(windows):
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = disabledFilesDefault & @["coro.nim"]
else:
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = disabledFilesDefault

include categories

proc loadSkipFrom(name: string): seq[string] =
  if name.len == 0: return
  # One skip per line, comments start with #
  # used by `nlvm` (at least)
  for line in lines(name):
    let sline = line.strip()
    if sline.len > 0 and not sline.startsWith('#'):
      result.add sline

proc main() =
  azure.init()
  backend.open()
  var optPrintResults = false
  var optFailing = false
  var targetsStr = ""
  var isMainProcess = true
  var skipFrom = ""
  var useMegatest = true

  var p = initOptParser()
  p.next()
  while p.kind in {cmdLongOption, cmdShortOption}:
    case p.key.normalize
    of "print", "verbose": optPrintResults = true
    of "failing": optFailing = true
    of "pedantic": discard # deadcode refs https://github.com/nim-lang/Nim/issues/16731
    of "targets":
      targetsStr = p.val
      gTargets = parseTargets(targetsStr)
      targetsSet = true
    of "nim":
      compilerPrefix = addFileExt(p.val.absolutePath, ExeExt)
    of "directory":
      setCurrentDir(p.val)
    of "colors":
      case p.val:
      of "on":
        useColors = true
      of "off":
        useColors = false
      else:
        quit Usage
    of "batch":
      testamentData0.batchArg = p.val
      if p.val != "_":
        let s = p.val.split("_")
        doAssert s.len == 2, $(p.val, s)
        testamentData0.testamentBatch = s[0].parseInt
        testamentData0.testamentNumBatch = s[1].parseInt
        doAssert testamentData0.testamentNumBatch > 0
        doAssert testamentData0.testamentBatch >= 0 and testamentData0.testamentBatch < testamentData0.testamentNumBatch
    of "simulate":
      simulate = true
    of "megatest":
      case p.val:
      of "on":
        useMegatest = true
      of "off":
        useMegatest = false
      else:
        quit Usage
    of "backendlogging":
      case p.val:
      of "on":
        backendLogging = true
      of "off":
        backendLogging = false
      else:
        quit Usage
    of "skipfrom":
      skipFrom = p.val
    else:
      quit Usage
    p.next()
  if p.kind != cmdArgument:
    quit Usage
  var action = p.key.normalize
  p.next()
  var r = initResults()
  case action
  of "all":
    #processCategory(r, Category"megatest", p.cmdLineRest, testsDir, runJoinableTests = false)

    var myself = quoteShell(getAppFilename())
    if targetsStr.len > 0:
      myself &= " " & quoteShell("--targets:" & targetsStr)

    myself &= " " & quoteShell("--nim:" & compilerPrefix)
    if testamentData0.batchArg.len > 0:
      myself &= " --batch:" & testamentData0.batchArg

    if skipFrom.len > 0:
      myself &= " " & quoteShell("--skipFrom:" & skipFrom)

    var cats: seq[string]
    let rest = if p.cmdLineRest.len > 0: " " & p.cmdLineRest else: ""
    for kind, dir in walkDir(testsDir):
      assert testsDir.startsWith(testsDir)
      let cat = dir[testsDir.len .. ^1]
      if kind == pcDir and cat notin ["testdata", "nimcache"]:
        cats.add cat
    if isNimRepoTests():
      cats.add AdditionalCategories
    if useMegatest: cats.add MegaTestCat

    var cmds: seq[string]
    for cat in cats:
      let runtype = if useMegatest: " pcat " else: " cat "
      cmds.add(myself & runtype & quoteShell(cat) & rest)

    proc progressStatus(idx: int) =
      echo "progress[all]: $1/$2 starting: cat: $3" % [$idx, $cats.len, cats[idx]]

    if simulate:
      skips = loadSkipFrom(skipFrom)
      for i, cati in cats:
        progressStatus(i)
        processCategory(r, Category(cati), p.cmdLineRest, testsDir, runJoinableTests = false)
    else:
      addExitProc azure.finalize
      quit osproc.execProcesses(cmds, {poEchoCmd, poStdErrToStdOut, poUsePath, poParentStreams}, beforeRunEvent = progressStatus)
  of "c", "cat", "category":
    skips = loadSkipFrom(skipFrom)
    var cat = Category(p.key)
    processCategory(r, cat, p.cmdLineRest, testsDir, runJoinableTests = true)
  of "pcat":
    skips = loadSkipFrom(skipFrom)
    # 'pcat' is used for running a category in parallel. Currently the only
    # difference is that we don't want to run joinable tests here as they
    # are covered by the 'megatest' category.
    isMainProcess = false
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest, testsDir, runJoinableTests = false)
  of "p", "pat", "pattern":
    skips = loadSkipFrom(skipFrom)
    let pattern = p.key
    p.next
    processPattern(r, pattern, p.cmdLineRest, simulate)
  of "r", "run":
    let (cat, path) = splitTestFile(p.key)
    processSingleTest(r, cat.Category, p.cmdLineRest, path, gTargets, targetsSet)
  of "html":
    generateHtml(resultsFile, optFailing)
  else:
    quit Usage

  if optPrintResults:
    if action == "html": openDefaultBrowser(resultsFile)
    else: echo r, r.data
  azure.finalize()
  backend.close()
  var failed = r.total - r.passed - r.skipped
  if failed != 0:
    echo "FAILURE! total: ", r.total, " passed: ", r.passed, " skipped: ",
      r.skipped, " failed: ", failed
    quit(QuitFailure)
  if isMainProcess:
    echo "Used ", compilerPrefix, " to run the tests. Use --nim to override."

if paramCount() == 0:
  quit Usage
main()
