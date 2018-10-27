#
#
#            Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nim against the testcases.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, json,
  marshal, backend, parseopt, specs, htmlgen, browsers, terminal,
  algorithm, compiler/nodejs, times, sets, md5

const
  resultsFile = "testresults.html"
  #jsonFile = "testresults.json" # not used
  Usage = """Usage:
  tester [options] command [arguments]

Command:
  all                         run all tests
  c|cat|category <category>   run all the tests of a certain category
  r|run <test>                run single test file
  html                        generate $1 from the database
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --failing                 only show failing/ignored tests
  --targets:"c c++ js objc" run tests for specified targets (default: all)
  --nim:path                use a particular nim executable (default: compiler/nim)
""" % resultsFile

type
  Category = distinct string
  TResults = object
    total, passed, skipped: int
    data: string

  TTest = object
    name: string
    cat: Category
    options: string
    action: TTestAction
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
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError

var targets = {low(TTarget)..high(TTarget)}

proc normalizeMsg(s: string): string =
  result = newStringOfCap(s.len+1)
  for x in splitLines(s):
    if result.len > 0: result.add '\L'
    result.add x.strip

proc getFileDir(filename: string): string =
  result = filename.splitFile().dir
  if not result.isAbsolute():
    result = getCurrentDir() / result

proc nimcacheDir(filename, options: string, target: TTarget): string =
  ## Give each test a private nimcache dir so they don't clobber each other's.
  let hashInput = options & $target
  return "nimcache" / (filename & '_' & hashInput.getMD5)

proc callCompiler(cmdTemplate, filename, options: string,
                  target: TTarget, extraOptions=""): TSpec =
  let nimcache = nimcacheDir(filename, options, target)
  let options = options & " " & ("--nimCache:" & nimcache).quoteShell & extraOptions
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell,
                       "filedir", filename.getFileDir()])
  var p = startProcess(command=c[0], args=c[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var tmpl = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
    if x =~ pegOfInterest:
      # `err` should contain the last error/warning message
      err = x
    elif x =~ pegLineTemplate and err == "":
      # `tmpl` contains the last template expansion before the error
      tmpl = x
    elif x =~ pegSuccess:
      suc = x
  close(p)
  result.msg = ""
  result.file = ""
  result.outp = ""
  result.line = 0
  result.column = 0
  result.tfile = ""
  result.tline = 0
  result.tcolumn = 0
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
  elif suc =~ pegSuccess:
    result.err = reSuccess

proc callCCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell,
                       "filedir", filename.getFileDir()])
  var p = startProcess(command="gcc", args=c[5 .. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var x = newStringOfCap(120)
  result.nimout = ""
  result.msg = ""
  result.file = ""
  result.outp = ""
  result.line = -1
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
  close(p)
  if p.peekExitCode == 0:
    result.err = reSuccess

proc initResults: TResults =
  result.total = 0
  result.passed = 0
  result.skipped = 0
  result.data = ""

#proc readResults(filename: string): TResults = # not used
#  result = marshal.to[TResults](readFile(filename).string)

#proc writeResults(filename: string, r: TResults) = # not used
#  writeFile(filename, $$r)

proc `$`(x: TResults): string =
  result = ("Tests passed: $1 / $3 <br />\n" &
            "Tests skipped: $2 / $3 <br />\n") %
            [$x.passed, $x.skipped, $x.total]

proc addResult(r: var TResults, test: TTest, target: TTarget,
               expected, given: string, success: TResultEnum) =
  let name = test.name.extractFilename & " " & $target & test.options
  let duration = epochTime() - test.startTime
  let durationStr = duration.formatFloat(ffDecimal, precision = 8)
  backend.writeTestResult(name = name,
                          category = test.cat.string,
                          target = $target,
                          action = $test.action,
                          result = $success,
                          expected = expected,
                          given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  if success == reSuccess:
    styledEcho fgGreen, "PASS: ", fgCyan, alignLeft(name, 60), fgBlue, " (", durationStr, " secs)"
  elif success == reIgnored:
    styledEcho styleDim, fgYellow, "SKIP: ", styleBright, fgCyan, name
  else:
    styledEcho styleBright, fgRed, "FAIL: ", fgCyan, name
    styledEcho styleBright, fgCyan, "Test \"", test.name, "\"", " in category \"", test.cat.string, "\""
    styledEcho styleBright, fgRed, "Failure: ", $success
    styledEcho fgYellow, "Expected:"
    styledEcho styleBright, expected, "\n"
    styledEcho fgYellow, "Gotten:"
    styledEcho styleBright, given, "\n"

  if existsEnv("APPVEYOR"):
    let (outcome, msg) =
      if success == reSuccess:
        ("Passed", "")
      elif success == reIgnored:
        ("Skipped", "")
      else:
        ("Failed", "Failure: " & $success & "\nExpected:\n" & expected & "\n\n" & "Gotten:\n" & given)
    var p = startProcess("appveyor", args=["AddTest", test.name.replace("\\", "/") & test.options,
                         "-Framework", "nim-testament", "-FileName",
                         test.cat.string,
                         "-Outcome", outcome, "-ErrorMessage", msg,
                         "-Duration", $(duration*1000).int],
                         options={poStdErrToStdOut, poUsePath, poParentStreams})
    discard waitForExit(p)
    close(p)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, target, expected.msg, given.msg, reMsgsDiffer)
  elif expected.nimout.len > 0 and expected.nimout.normalizeMsg notin given.nimout.normalizeMsg:
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
  let (_, name, _) = test.name.splitFile
  let ext = targetToExt[target]
  result = nimcacheDir(test.name, test.options, target) /
    (if target == targetJS: "" else: "compiler_") &
    name.changeFileExt(ext)

proc needsCodegenCheck(spec: TSpec): bool =
  result = spec.maxCodeSize > 0 or spec.ccodeCheck.len > 0

proc codegenCheck(test: TTest, target: TTarget, spec: TSpec, expectedMsg: var string,
                  given: var TSpec) =
  try:
    let genFile = generatedFile(test, target)
    let contents = readFile(genFile).string
    let check = spec.ccodeCheck
    if check.len > 0:
      if check[0] == '\\':
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
  let exp = expectedNimout.strip.replace("\C\L", "\L")
  let giv = given.nimout.strip.replace("\C\L", "\L")
  if exp notin giv:
    given.err = reMsgsDiffer

proc makeDeterministic(s: string): string =
  var x = splitLines(s)
  sort(x, system.cmp)
  result = join(x, "\n")

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
    givenmsg = given.nimout.strip
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, target, expectedmsg, givenmsg, given.err)

proc testSpec(r: var TResults, test: TTest, target = targetC) =
  let tname = test.name.addFileExt(".nim")
  #echo "TESTING ", tname
  var expected: TSpec
  if test.action != actionRunNoSpec:
    expected = parseSpec(tname)
    if test.action == actionRun and expected.action == actionCompile:
      expected.action = actionRun
  else:
    specDefaults expected
    expected.action = actionRunNoSpec

  if expected.err == reIgnored:
    r.addResult(test, target, "", "", reIgnored)
    inc(r.skipped)
    inc(r.total)
    return

  if getEnv("NIM_COMPILE_TO_CPP", "false").string == "true" and target == targetC and expected.targets == {}:
    expected.targets.incl(targetCpp)
  elif expected.targets == {}:
    expected.targets.incl(target)

  for target in expected.targets:
    inc(r.total)
    if target notin targets:
      r.addResult(test, target, "", "", reIgnored)
      inc(r.skipped)
      continue

    case expected.action
    of actionCompile:
      var given = callCompiler(expected.cmd, test.name, test.options, target,
        extraOptions=" --stdout --hint[Path]:off --hint[Processing]:off")
      compilerOutputTests(test, target, given, expected, r)
    of actionRun, actionRunNoSpec:
      # In this branch of code "early return" pattern is clearer than deep
      # nested conditionals - the empty rows in between to clarify the "danger"
      var given = callCompiler(expected.cmd, test.name, test.options,
                               target)

      if given.err != reSuccess:
        r.addResult(test, target, "", given.msg, given.err)
        continue

      let isJsTarget = target == targetJS
      var exeFile: string
      if isJsTarget:
        let (_, file, _) = splitFile(tname)
        exeFile = nimcacheDir(test.name, test.options, target) / file & ".js"
      else:
        exeFile = changeFileExt(tname, ExeExt)

      if not existsFile(exeFile):
        r.addResult(test, target, expected.outp, "executable not found", reExeNotFound)
        continue

      let nodejs = if isJsTarget: findNodeJs() else: ""
      if isJsTarget and nodejs == "":
        r.addResult(test, target, expected.outp, "nodejs binary not in PATH",
                    reExeNotFound)
        continue

      let exeCmd = (if isJsTarget: nodejs & " " else: "") & exeFile
      var (buf, exitCode) = execCmdEx(exeCmd, options = {poStdErrToStdOut})

      # Treat all failure codes from nodejs as 1. Older versions of nodejs used
      # to return other codes, but for us it is sufficient to know that it's not 0.
      if exitCode != 0: exitCode = 1

      let bufB = if expected.sortoutput: makeDeterministic(strip(buf.string))
                 else: strip(buf.string)
      let expectedOut = strip(expected.outp)

      if exitCode != expected.exitCode:
        r.addResult(test, target, "exitcode: " & $expected.exitCode,
                          "exitcode: " & $exitCode & "\n\nOutput:\n" &
                          bufB, reExitCodesDiffer)
        continue

      if bufB != expectedOut and expected.action != actionRunNoSpec:
        if not (expected.substr and expectedOut in bufB):
          given.err = reOutputsDiffer
          r.addResult(test, target, expected.outp, bufB, reOutputsDiffer)
          continue

      compilerOutputTests(test, target, given, expected, r)
      continue

    of actionReject:
      var given = callCompiler(expected.cmd, test.name, test.options,
                               target)
      cmpMsgs(r, expected, given, test, target)
      continue

proc testNoSpec(r: var TResults, test: TTest, target = targetC) =
  # does not extract the spec because the file is not supposed to have any
  #let tname = test.name.addFileExt(".nim")
  inc(r.total)
  let given = callCompiler(cmdTemplate(), test.name, test.options, target)
  r.addResult(test, target, "", given.msg, given.err)
  if given.err == reSuccess: inc(r.passed)

proc testC(r: var TResults, test: TTest) =
  # runs C code. Doesn't support any specs, just goes by exit code.
  let tname = test.name.addFileExt(".c")
  inc(r.total)
  styledEcho "Processing ", fgCyan, extractFilename(tname)
  var given = callCCompiler(cmdTemplate(), test.name & ".c", test.options, targetC)
  if given.err != reSuccess:
    r.addResult(test, targetC, "", given.msg, given.err)
  elif test.action == actionRun:
    let exeFile = changeFileExt(test.name, ExeExt)
    var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
    if exitCode != 0: given.err = reExitCodesDiffer
  if given.err == reSuccess: inc(r.passed)

proc testExec(r: var TResults, test: TTest) =
  # runs executable or script, just goes by exit code
  inc(r.total)
  let (outp, errC) = execCmdEx(test.options.strip())
  var given: TSpec
  specDefaults(given)
  if errC == 0:
    given.err = reSuccess
  else:
    given.err = reExitCodesDiffer
    given.msg = outp.string

  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, targetC, "", given.msg, given.err)

proc makeTest(test, options: string, cat: Category, action = actionCompile,
              env: string = ""): TTest =
  # start with 'actionCompile', will be overwritten in the spec:
  result = TTest(cat: cat, name: test, options: options,
                 action: action, startTime: epochTime())

when defined(windows):
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = ["coro.nim"]
else:
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = ["-"]

include categories

# proc runCaasTests(r: var TResults) =
#   for test, output, status, mode in caasTestsRunner():
#     r.addResult(test, "", output & "-> " & $mode,
#                 if status: reSuccess else: reOutputsDiffer)

proc main() =
  os.putenv "NIMTEST_COLOR", "never"
  os.putenv "NIMTEST_OUTPUT_LVL", "PRINT_FAILURES"

  backend.open()
  var optPrintResults = false
  var optFailing = false

  var targetsStr = ""

  var p = initOptParser()
  p.next()
  while p.kind == cmdLongoption:
    case p.key.string.normalize
    of "print", "verbose": optPrintResults = true
    of "failing": optFailing = true
    of "pedantic": discard "now always enabled"
    of "targets":
      targetsStr = p.val.string
      targets = parseTargets(targetsStr)
    of "nim": compilerPrefix = p.val.string & " "
    else: quit Usage
    p.next()
  if p.kind != cmdArgument: quit Usage
  var action = p.key.string.normalize
  p.next()
  var r = initResults()
  case action
  of "all":
    let testsDir = "tests" & DirSep
    var myself = quoteShell(findExe("testament" / "tester"))
    if targetsStr.len > 0:
      myself &= " " & quoteShell("--targets:" & targetsStr)

    myself &= " " & quoteShell("--nim:" & compilerPrefix)

    var cmds: seq[string] = @[]
    let rest = if p.cmdLineRest.string.len > 0: " " & p.cmdLineRest.string else: ""
    for kind, dir in walkDir(testsDir):
      assert testsDir.startsWith(testsDir)
      let cat = dir[testsDir.len .. ^1]
      if kind == pcDir and cat notin ["testdata", "nimcache"]:
        cmds.add(myself & " cat " & quoteShell(cat) & rest)
    for cat in AdditionalCategories:
      cmds.add(myself & " cat " & quoteShell(cat) & rest)
    quit osproc.execProcesses(cmds, {poEchoCmd, poStdErrToStdOut, poUsePath, poParentStreams})
  of "c", "cat", "category":
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest.string)
  of "r", "run":
    let (dir, file) = splitPath(p.key.string)
    let (_, subdir) = splitPath(dir)
    var cat = Category(subdir)
    processSingleTest(r, cat, p.cmdLineRest.string, file)
  of "html":
    generateHtml(resultsFile, optFailing)
  else:
    quit Usage

  if optPrintResults:
    if action == "html": openDefaultBrowser(resultsFile)
    else: echo r, r.data
  backend.close()
  var failed = r.total - r.passed - r.skipped
  if failed != 0:
    echo "FAILURE! total: ", r.total, " passed: ", r.passed, " skipped: ",
      r.skipped, " failed: ", failed
    quit(QuitFailure)

if paramCount() == 0:
  quit Usage
main()
