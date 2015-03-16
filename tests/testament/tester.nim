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
  algorithm, compiler/nodejs

const
  resultsFile = "testresults.html"
  jsonFile = "testresults.json"
  Usage = """Usage:
  tester [options] command [arguments]

Command:
  all                         run all tests
  c|category <category>       run all the tests of a certain category
  html [commit]               generate $1 from the database; uses the latest
                              commit or a specific one (use -1 for the commit
                              before latest etc)
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --failing                 only show failing/ignored tests
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

# ----------------------------------------------------------------------------

let
  pegLineError =
    peg"{[^(]*} '(' {\d+} ', ' \d+ ') ' ('Error') ':' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError

proc callCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell])
  var p = startProcess(command=c[0], args=c[1.. -1],
                       options={poStdErrToStdOut, poUseShell})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
    if x =~ pegOfInterest:
      # `err` should contain the last error/warning message
      err = x
    elif x =~ pegSuccess:
      suc = x
  close(p)
  result.msg = ""
  result.file = ""
  result.outp = ""
  result.line = -1
  if err =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.msg = matches[2]
  elif err =~ pegOtherError:
    result.msg = matches[0]
  elif suc =~ pegSuccess:
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
  backend.writeTestResult(name = name,
                          category = test.cat.string,
                          target = $test.target,
                          action = $test.action,
                          result = $success,
                          expected = expected,
                          given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  if success == reIgnored:
    styledEcho styleBright, name, fgYellow, " [", $success, "]"
  elif success != reSuccess:
    styledEcho styleBright, name, fgRed, " [", $success, "]"
    echo"Expected:"
    styledEcho styleBright, expected
    echo"Given:"
    styledEcho styleBright, given

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest) =
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, expected.msg, given.msg, reMsgsDiffer)
  elif extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, expected.file, given.file, reFilesDiffer)
  elif expected.line != given.line and expected.line != 0:
    r.addResult(test, $expected.line, $given.line, reLinesDiffer)
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
    let (path, name, ext2) = test.name.splitFile
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
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, expectedmsg, givenmsg, given.err)

proc testSpec(r: var TResults, test: TTest) =
  # major entry point for a single test
  let tname = test.name.addFileExt(".nim")
  inc(r.total)
  styledEcho "Processing ", fgCyan, extractFilename(tname)
  var expected = parseSpec(tname)
  if expected.err == reIgnored:
    r.addResult(test, "", "", reIgnored)
    inc(r.skipped)
  else:
    case expected.action
    of actionCompile:
      var given = callCompiler(expected.cmd, test.name,
        test.options & " --hint[Path]:off --hint[Processing]:off", test.target)
      compilerOutputTests(test, given, expected, r)
    of actionRun:
      var given = callCompiler(expected.cmd, test.name, test.options,
                               test.target)
      if given.err != reSuccess:
        r.addResult(test, "", given.msg, given.err)
      else:
        var exeFile: string
        if test.target == targetJS:
          let (dir, file, ext) = splitFile(tname)
          exeFile = dir / "nimcache" / file & ".js"
        else:
          exeFile = changeFileExt(tname, ExeExt)
        if existsFile(exeFile):
          let nodejs = findNodeJs()
          if test.target == targetJS and nodejs == "":
            r.addResult(test, expected.outp, "nodejs binary not in PATH",
                        reExeNotFound)
            return
          var (buf, exitCode) = execCmdEx(
            (if test.target == targetJS: nodejs & " " else: "") & exeFile)
          if exitCode != expected.exitCode:
            r.addResult(test, "exitcode: " & $expected.exitCode,
                              "exitcode: " & $exitCode, reExitCodesDiffer)
          else:
            var bufB = strip(buf.string)
            if expected.sortoutput: bufB = makeDeterministic(bufB)
            if bufB != strip(expected.outp):
              if not (expected.substr and expected.outp in bufB):
                given.err = reOutputsDiffer
            compilerOutputTests(test, given, expected, r)
        else:
          r.addResult(test, expected.outp, "executable not found", reExeNotFound)
    of actionReject:
      var given = callCompiler(expected.cmd, test.name, test.options,
                               test.target)
      cmpMsgs(r, expected, given, test)

proc testNoSpec(r: var TResults, test: TTest) =
  # does not extract the spec because the file is not supposed to have any
  let tname = test.name.addFileExt(".nim")
  inc(r.total)
  styledEcho "Processing ", fgCyan, extractFilename(tname)
  let given = callCompiler(cmdTemplate, test.name, test.options, test.target)
  r.addResult(test, "", given.msg, given.err)
  if given.err == reSuccess: inc(r.passed)

proc makeTest(test, options: string, cat: Category, action = actionCompile,
              target = targetC): TTest =
  # start with 'actionCompile', will be overwritten in the spec:
  result = TTest(cat: cat, name: test, options: options,
                 target: target, action: action)

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
  var p = initOptParser()
  p.next()
  while p.kind == cmdLongoption:
    case p.key.string.normalize
    of "print", "verbose": optPrintResults = true
    of "failing": optFailing = true
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
      let cat = dir[testsDir.len .. -1]
      if kind == pcDir and cat notin ["testament", "testdata", "nimcache"]:
        processCategory(r, Category(cat), p.cmdLineRest.string)
    for a in AdditionalCategories:
      processCategory(r, Category(a), p.cmdLineRest.string)
  of "c", "cat", "category":
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest.string)
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

if paramCount() == 0:
  quit Usage
main()

