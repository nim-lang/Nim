#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nim against the testcases.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, json,
  marshal, backend, parseopt, specs, htmlgen, browsers, terminal,
  algorithm, compiler/nodejs, re, times, sets

const
  resultsFile = "testresults.html"
  jsonFile = "testresults.json"
  Usage = """Usage:
  tester [options] command [arguments]

Command:
  all                         run all tests
  c|category <category>       run all the tests of a certain category
  r|run <test>                run single test file
  html [commit]               generate $1 from the database; uses the latest
                              commit or a specific one (use -1 for the commit
                              before latest etc)
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --failing                 only show failing/ignored tests
  --pedantic                return non-zero status code if there are failures
  --targets:"c c++ js objc" run tests for specified targets (default: all)
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
    target: TTarget
    action: TTestAction
    startTime: float

# ----------------------------------------------------------------------------

let
  pegLineError =
    peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' ('Error') ':' \s* {.*}"
  pegLineTemplate =
    peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' 'template/generic instantiation from here'.*"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError

var targets = {low(TTarget)..high(TTarget)}

proc callCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell])
  var p = startProcess(command=c[0], args=c[1.. ^1],
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
                       "options", options, "file", filename.quoteShell])
  var p = startProcess(command="gcc", args=c[5.. ^1],
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

proc readResults(filename: string): TResults =
  result = marshal.to[TResults](readFile(filename).string)

proc writeResults(filename: string, r: TResults) =
  writeFile(filename, $$r)

proc `$`(x: TResults): string =
  result = ("Tests passed: $1 / $3 <br />\n" &
            "Tests skipped: $2 / $3 <br />\n") %
            [$x.passed, $x.skipped, $x.total]

proc addResult(r: var TResults, test: TTest,
               expected, given: string, success: TResultEnum) =
  let name = test.name.extractFilename & test.options
  let duration = epochTime() - test.startTime
  backend.writeTestResult(name = name,
                          category = test.cat.string,
                          target = $test.target,
                          action = $test.action,
                          result = $success,
                          expected = expected,
                          given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  if success == reSuccess:
    styledEcho fgGreen, "PASS: ", fgCyan, name
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
    var p = startProcess("appveyor", args=["AddTest", test.name.replace("\\", "/") & test.options, "-Framework", "nim-testament", "-FileName", test.cat.string, "-Outcome", outcome, "-ErrorMessage", msg, "-Duration", $(duration*1000).int], options={poStdErrToStdOut, poUsePath, poParentStreams})
    discard waitForExit(p)
    close(p)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest) =
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, expected.msg, given.msg, reMsgsDiffer)
  elif expected.tfile == "" and extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, expected.file, given.file, reFilesDiffer)
  elif expected.line   != given.line   and expected.line   != 0 or
       expected.column != given.column and expected.column != 0:
    r.addResult(test, $expected.line & ':' & $expected.column,
                      $given.line    & ':' & $given.column,
                      reLinesDiffer)
  elif expected.tfile != "" and extractFilename(expected.tfile) != extractFilename(given.tfile) and
      "internal error:" notin expected.msg:
    r.addResult(test, expected.tfile, given.tfile, reFilesDiffer)
  elif expected.tline   != given.tline   and expected.tline   != 0 or
       expected.tcolumn != given.tcolumn and expected.tcolumn != 0:
    r.addResult(test, $expected.tline & ':' & $expected.tcolumn,
                      $given.tline    & ':' & $given.tcolumn,
                      reLinesDiffer)
  else:
    r.addResult(test, expected.msg, given.msg, reSuccess)
    inc(r.passed)

proc generatedFile(path, name: string, target: TTarget): string =
  let ext = targetToExt[target]
  result = path / "nimcache" /
    (if target == targetJS: path.splitPath.tail & "_" else: "compiler_") &
    name.changeFileExt(ext)

proc codegenCheck(test: TTest, check: string, given: var TSpec) =
  try:
    let (path, name, _) = test.name.splitFile
    let genFile = generatedFile(path, name, test.target)
    let contents = readFile(genFile).string
    if check[0] == '\\':
      # little hack to get 'match' support:
      if not contents.match(check.peg):
        given.err = reCodegenFailure
    elif contents.find(check.peg) < 0:
      given.err = reCodegenFailure
  except ValueError:
    given.err = reInvalidPeg
    echo getCurrentExceptionMsg()
  except IOError:
    given.err = reCodeNotFound

proc nimoutCheck(test: TTest; expectedNimout: string; given: var TSpec) =
  let exp = expectedNimout.strip.replace("\C\L", "\L")
  let giv = given.nimout.strip.replace("\C\L", "\L")
  if exp notin giv:
    given.err = reMsgsDiffer

proc makeDeterministic(s: string): string =
  var x = splitLines(s)
  sort(x, system.cmp)
  result = join(x, "\n")

proc compilerOutputTests(test: TTest, given: var TSpec, expected: TSpec;
                         r: var TResults) =
  var expectedmsg: string = ""
  var givenmsg: string = ""
  if given.err == reSuccess:
    if expected.ccodeCheck.len > 0:
      codegenCheck(test, expected.ccodeCheck, given)
      expectedmsg = expected.ccodeCheck
      givenmsg = given.msg
    if expected.nimout.len > 0:
      expectedmsg = expected.nimout
      givenmsg = given.nimout.strip
      nimoutCheck(test, expectedmsg, given)
  else:
    givenmsg = given.nimout.strip
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, expectedmsg, givenmsg, given.err)

proc analyzeAndConsolidateOutput(s: string): string =
  result = ""
  let rows = s.splitLines
  for i in 0 ..< rows.len:
    if (let pos = find(rows[i], "Traceback (most recent call last)"); pos != -1):
      result = substr(rows[i], pos) & "\n"
      for i in i+1 ..< rows.len:
        result.add rows[i] & "\n"
        if not (rows[i] =~ re"^[^(]+\(\d+\)\s+"):
          return
    elif (let pos = find(rows[i], "SIGSEGV: Illegal storage access."); pos != -1):
      result = substr(rows[i], pos)
      return

proc testSpec(r: var TResults, test: TTest) =
  # major entry point for a single test
  if test.target notin targets:
    r.addResult(test, "", "", reIgnored)
    inc(r.skipped)
    return

  let tname = test.name.addFileExt(".nim")
  #echo "TESTING ", tname
  inc(r.total)
  var expected: TSpec
  if test.action != actionRunNoSpec:
    expected = parseSpec(tname)
  else:
    specDefaults expected
    expected.action = actionRunNoSpec

  if expected.err == reIgnored:
    r.addResult(test, "", "", reIgnored)
    inc(r.skipped)
    return

  case expected.action
  of actionCompile:
    var given = callCompiler(expected.cmd, test.name,
      test.options & " --stdout --hint[Path]:off --hint[Processing]:off",
      test.target)
    compilerOutputTests(test, given, expected, r)
  of actionRun, actionRunNoSpec:
    # In this branch of code "early return" pattern is clearer than deep
    # nested conditionals - the empty rows in between to clarify the "danger"
    var given = callCompiler(expected.cmd, test.name, test.options,
                             test.target)

    if given.err != reSuccess:
      r.addResult(test, "", given.msg, given.err)
      return

    let isJsTarget = test.target == targetJS
    var exeFile: string
    if isJsTarget:
      let (dir, file, _) = splitFile(tname)
      exeFile = dir / "nimcache" / file & ".js" # *TODO* hardcoded "nimcache"
    else:
      exeFile = changeFileExt(tname, ExeExt)

    if not existsFile(exeFile):
      r.addResult(test, expected.outp, "executable not found", reExeNotFound)
      return

    let nodejs = if isJsTarget: findNodeJs() else: ""
    if isJsTarget and nodejs == "":
      r.addResult(test, expected.outp, "nodejs binary not in PATH",
                  reExeNotFound)
      return

    let exeCmd = (if isJsTarget: nodejs & " " else: "") & exeFile
    var (buf, exitCode) = execCmdEx(exeCmd, options = {poStdErrToStdOut})

    # Treat all failure codes from nodejs as 1. Older versions of nodejs used
    # to return other codes, but for us it is sufficient to know that it's not 0.
    if exitCode != 0: exitCode = 1

    let bufB = if expected.sortoutput: makeDeterministic(strip(buf.string))
               else: strip(buf.string)
    let expectedOut = strip(expected.outp)

    if exitCode != expected.exitCode:
      r.addResult(test, "exitcode: " & $expected.exitCode,
                        "exitcode: " & $exitCode & "\n\nOutput:\n" &
                        analyzeAndConsolidateOutput(bufB),
                        reExitCodesDiffer)
      return

    if bufB != expectedOut and expected.action != actionRunNoSpec:
      if not (expected.substr and expectedOut in bufB):
        given.err = reOutputsDiffer
        r.addResult(test, expected.outp, bufB, reOutputsDiffer)
        return

    compilerOutputTests(test, given, expected, r)
    return

  of actionReject:
    var given = callCompiler(expected.cmd, test.name, test.options,
                             test.target)
    cmpMsgs(r, expected, given, test)
    return

proc testNoSpec(r: var TResults, test: TTest) =
  # does not extract the spec because the file is not supposed to have any
  #let tname = test.name.addFileExt(".nim")
  inc(r.total)
  let given = callCompiler(cmdTemplate, test.name, test.options, test.target)
  r.addResult(test, "", given.msg, given.err)
  if given.err == reSuccess: inc(r.passed)

proc testC(r: var TResults, test: TTest) =
  # runs C code. Doesn't support any specs, just goes by exit code.
  let tname = test.name.addFileExt(".c")
  inc(r.total)
  styledEcho "Processing ", fgCyan, extractFilename(tname)
  var given = callCCompiler(cmdTemplate, test.name & ".c", test.options, test.target)
  if given.err != reSuccess:
    r.addResult(test, "", given.msg, given.err)
  elif test.action == actionRun:
    let exeFile = changeFileExt(test.name, ExeExt)
    var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
    if exitCode != 0: given.err = reExitCodesDiffer
  if given.err == reSuccess: inc(r.passed)

proc makeTest(test, options: string, cat: Category, action = actionCompile,
              target = targetC, env: string = ""): TTest =
  # start with 'actionCompile', will be overwritten in the spec:
  result = TTest(cat: cat, name: test, options: options,
                 target: target, action: action, startTime: epochTime())

when defined(windows):
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = ["coro.nim", "fsmonitor.nim"]
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
  os.putenv "NIMTEST_NO_COLOR", "1"
  os.putenv "NIMTEST_OUTPUT_LVL", "PRINT_FAILURES"

  backend.open()
  var optPrintResults = false
  var optFailing = false
  var optPedantic = false

  var p = initOptParser()
  p.next()
  while p.kind == cmdLongoption:
    case p.key.string.normalize
    of "print", "verbose": optPrintResults = true
    of "failing": optFailing = true
    of "pedantic": optPedantic = true
    of "targets": targets = parseTargets(p.val.string)
    else: quit Usage
    p.next()
  if p.kind != cmdArgument: quit Usage
  var action = p.key.string.normalize
  p.next()
  var r = initResults()
  case action
  of "all":
    let testsDir = "tests" & DirSep
    for kind, dir in walkDir(testsDir):
      assert testsDir.startsWith(testsDir)
      let cat = dir[testsDir.len .. ^1]
      if kind == pcDir and cat notin ["testament", "testdata", "nimcache"]:
        processCategory(r, Category(cat), p.cmdLineRest.string)
    for a in AdditionalCategories:
      processCategory(r, Category(a), p.cmdLineRest.string)
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
    var commit = 0
    discard parseInt(p.cmdLineRest.string, commit)
    generateHtml(resultsFile, commit, optFailing)
    generateJson(jsonFile, commit)
  else:
    quit Usage

  if optPrintResults:
    if action == "html": openDefaultBrowser(resultsFile)
    else: echo r, r.data
  backend.close()
  if optPedantic:
    var failed = r.total - r.passed - r.skipped
    if failed > 0:
      echo "FAILURE! total: ", r.total, " passed: ", r.passed, " skipped: ", r.skipped
      quit(QuitFailure)

if paramCount() == 0:
  quit Usage
main()
