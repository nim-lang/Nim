#
#
#            Nimrod Tester
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nimrod against the testcases.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, browsers, json,
  marshal, cgi, parseopt #, caas

const
  cmdTemplate = r"nimrod cc --hints:on $# $#"
  resultsFile = "testresults.html"
  jsonFile = "testresults.json"
  Usage = "usage: tester [--print] " &
                    "reject|compile|run|" &
                    "merge|special|rodfiles| [nimrod options]\n" &
          "   or: tester test|comp|rej singleTest"

type
  TTestAction = enum
    actionCompile, actionRun, actionReject
  TResultEnum = enum
    reNimrodcCrash,     # nimrod compiler seems to have crashed
    reMsgsDiffer,       # error messages differ
    reFilesDiffer,      # expected and given filenames differ
    reLinesDiffer,      # expected and given line numbers differ
    reOutputsDiffer,
    reExitcodesDiffer,
    reInvalidPeg,
    reCodegenFailure,
    reCodeNotFound,
    reExeNotFound,
    reIgnored,          # test is ignored
    reSuccess           # test was successful

  TTarget = enum
    targetC, targetCpp, targetObjC, targetJS

  TSpec = object
    action: TTestAction
    file, cmd: string
    outp: string
    line, exitCode: int
    msg: string
    ccodeCheck: string
    err: TResultEnum
    substr: bool
  TResults = object
    total, passed, skipped: int
    data: string

# ----------------------- Spec parser ----------------------------------------

when not defined(parseCfgBool):
  # candidate for the stdlib:
  proc parseCfgBool(s: string): bool =
    case normalize(s)
    of "y", "yes", "true", "1", "on": result = true
    of "n", "no", "false", "0", "off": result = false
    else: raise newException(EInvalidValue, "cannot interpret as a bool: " & s)

proc extractSpec(filename: string): string =
  const tripleQuote = "\"\"\""
  var x = readFile(filename).string
  var a = x.find(tripleQuote)
  var b = x.find(tripleQuote, a+3)
  # look for """ only in the first section
  if a >= 0 and b > a and a < 40:
    result = x.substr(a+3, b-1).replace("'''", tripleQuote)
  else:
    #echo "warning: file does not contain spec: " & filename
    result = ""

when not defined(nimhygiene):
  {.pragma: inject.}

template parseSpecAux(fillResult: stmt) {.immediate.} =
  var ss = newStringStream(extractSpec(filename))
  var p {.inject.}: TCfgParser
  open(p, ss, filename, 1)
  while true:
    var e {.inject.} = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart, cfgOption, cfgError:
      echo ignoreMsg(p, e)
    of cfgKeyValuePair:
      fillResult
  close(p)

proc parseSpec(filename: string): TSpec =
  result.file = filename
  result.msg = ""
  result.outp = ""
  result.ccodeCheck = ""
  result.cmd = cmdTemplate
  parseSpecAux:
    case normalize(e.key)
    of "action":
      case e.value.normalize
      of "compile": result.action = actionCompile
      of "run": result.action = actionRun
      of "reject": result.action = actionReject
      else: echo ignoreMsg(p, e)
    of "file": result.file = e.value
    of "line": discard parseInt(e.value, result.line)
    of "output": result.outp = e.value
    of "outputsub":
      result.outp = e.value
      result.substr = true
    of "exitcode": 
      discard parseInt(e.value, result.exitCode)
    of "errormsg", "msg": result.msg = e.value
    of "disabled":
      if parseCfgBool(e.value): result.err = reIgnored
    of "cmd": result.cmd = e.value
    of "ccodecheck": result.ccodeCheck = e.value
    else: echo ignoreMsg(p, e)

# ----------------------------------------------------------------------------

let
  pegLineError = 
    peg"{[^(]*} '(' {\d+} ', ' \d+ ') ' ('Error'/'Warning') ':' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError

proc callCompiler(cmdTemplate, filename, options: string): TSpec =
  let c = parseCmdLine(cmdTemplate % [options, filename])
  var p = startProcess(command=c[0], args=c[1.. -1],
                       options={poStdErrToStdOut, poUseShell})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var x = newStringOfCap(120)
  while outp.readLine(x.TaintedString) or running(p):
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

proc colorResult(r: TResultEnum): string =
  case r
  of reIgnored: result = "<span style=\"color:fuchsia\">ignored</span>"
  of reSuccess: result = "<span style=\"color:green\">yes</span>"
  else: result = "<span style=\"color:red\">no</span>"

const
  TableHeader4 = "<table border=\"1\"><tr><td>Test</td><td>Expected</td>" &
                 "<td>Given</td><td>Success</td></tr>\n"
  TableHeader3 = "<table border=\"1\"><tr><td>Test</td>" &
                 "<td>Given</td><td>Success</td></tr>\n"
  TableFooter = "</table>\n"
  HtmlBegin = """<html>
    <head> 
      <title>Test results</title>
      <style type="text/css">
      <!--""" & slurp("css/boilerplate.css") & "\n" &
                slurp("css/style.css") &
      """-->
    </style>

    </head>
    <body>"""
  
  HtmlEnd = "</body></html>"

proc td(s: string): string =
  result = s.substr(0, 200).XMLEncode

proc addResult(r: var TResults, test, expected, given: string,
               success: TResultEnum) =
  r.data.addf("<tr><td>$#</td><td>$#</td><td>$#</td><td>$#</td></tr>\n", [
    XMLEncode(test), td(expected), td(given), success.colorResult])

proc addResult(r: var TResults, test, given: string,
               success: TResultEnum) =
  r.data.addf("<tr><td>$#</td><td>$#</td><td>$#</td></tr>\n", [
    XMLEncode(test), td(given), success.colorResult])

proc listResults(reject, compile, run: TResults) =
  var s = HtmlBegin
  s.add("<h1>Tests to Reject</h1>\n")
  s.add($reject)
  s.add(TableHeader4 & reject.data & TableFooter)
  s.add("<br /><br /><br /><h1>Tests to Compile</h1>\n")
  s.add($compile)
  s.add(TableHeader3 & compile.data & TableFooter)
  s.add("<br /><br /><br /><h1>Tests to Run</h1>\n")
  s.add($run)
  s.add(TableHeader4 & run.data & TableFooter)
  s.add(HtmlEnd)
  writeFile(resultsFile, s)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: string) =
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

proc rejectSingleTest(r: var TResults, test, options: string) =
  let test = test.addFileExt(".nim")
  var t = extractFilename(test)
  inc(r.total)
  echo t
  var expected = parseSpec(test)
  if expected.err == reIgnored:
    r.addResult(t, "", "", reIgnored)
    inc(r.skipped)
  else:
    var given = callCompiler(expected.cmd, test, options)
    cmpMsgs(r, expected, given, t)

proc reject(r: var TResults, dir, options: string) =
  ## handle all the tests that the compiler should reject
  for test in os.walkFiles(dir / "t*.nim"): rejectSingleTest(r, test, options)

proc codegenCheck(test, check, ext: string, given: var TSpec) =
  if check.len > 0:
    try:
      let (path, name, ext2) = test.splitFile
      echo path / "nimcache" / name.changeFileExt(ext)
      let contents = readFile(path / "nimcache" / name.changeFileExt(ext)).string
      if contents.find(check.peg) < 0:
        given.err = reCodegenFailure
    except EInvalidValue:
      given.err = reInvalidPeg
    except EIO:
      given.err = reCodeNotFound
  
proc codegenChecks(test: string, expected: TSpec, given: var TSpec) =
  codegenCheck(test, expected.ccodeCheck, ".c", given)
  
proc compile(r: var TResults, pattern, options: string) =
  for test in os.walkFiles(pattern):
    let t = extractFilename(test)
    echo t
    inc(r.total)
    let expected = parseSpec(test)
    if expected.err == reIgnored:
      r.addResult(t, "", reIgnored)
      inc(r.skipped)
    else:
      var given = callCompiler(expected.cmd, test, options)
      if given.err == reSuccess:
        codegenChecks(test, expected, given)
      r.addResult(t, given.msg, given.err)
      if given.err == reSuccess: inc(r.passed)

proc compileSingleTest(r: var TResults, test, options: string) =
  # does not extract the spec because the file is not supposed to have any
  let test = test.addFileExt(".nim")
  let t = extractFilename(test)
  inc(r.total)
  echo t
  let given = callCompiler(cmdTemplate, test, options)
  r.addResult(t, given.msg, given.err)
  if given.err == reSuccess: inc(r.passed)

proc runSingleTest(r: var TResults, test, options: string, target: TTarget) =
  var test = test.addFileExt(".nim")
  var t = extractFilename(test)
  echo t
  inc(r.total)
  var expected = parseSpec(test)
  if expected.err == reIgnored:
    r.addResult(t, "", "", reIgnored)
    inc(r.skipped)
  else:
    var given = callCompiler(expected.cmd, test, options)
    if given.err != reSuccess:
      r.addResult(t, "", given.msg, given.err)
    else:
      var exeFile: string
      if target == targetC:
        exeFile = changeFileExt(test, ExeExt)
      else:
        let (dir, file, ext) = splitFile(test)
        exeFile = dir / "nimcache" / file & ".js"
      
      if existsFile(exeFile):
        var (buf, exitCode) = execCmdEx(
          (if target==targetJS: "node " else: "") & exeFile)
        if exitCode != expected.ExitCode:
          r.addResult(t, "exitcode: " & $expected.ExitCode,
                         "exitcode: " & $exitCode, reExitCodesDiffer)
        else:
          if strip(buf.string) != strip(expected.outp):
            if not (expected.substr and expected.outp in buf.string):
              given.err = reOutputsDiffer
          if given.err == reSuccess:
            codeGenChecks(test, expected, given)
          if given.err == reSuccess: inc(r.passed)
          r.addResult(t, expected.outp, buf.string, given.err)
      else:
        r.addResult(t, expected.outp, "executable not found", reExeNotFound)

proc runSingleTest(r: var TResults, test, options: string) =
  runSingleTest(r, test, options, targetC)

proc run(r: var TResults, dir, options: string) =
  for test in os.walkFiles(dir / "t*.nim"): runSingleTest(r, test, options)

include specials

proc compileExample(r: var TResults, pattern, options: string) =
  for test in os.walkFiles(pattern): compileSingleTest(r, test, options)

proc toJson(res: TResults): PJsonNode =
  result = newJObject()
  result["total"] = newJInt(res.total)
  result["passed"] = newJInt(res.passed)
  result["skipped"] = newJInt(res.skipped)

proc outputJSON(reject, compile, run: TResults) =
  var doc = newJObject()
  doc["reject"] = toJson(reject)
  doc["compile"] = toJson(compile)
  doc["run"] = toJson(run)
  var s = pretty(doc)
  writeFile(jsonFile, s)

# proc runCaasTests(r: var TResults) =
#   for test, output, status, mode in caasTestsRunner():
#     r.addResult(test, "", output & "-> " & $mode,
#                 if status: reSuccess else: reOutputsDiffer)

proc main() =
  os.putenv "NIMTEST_NO_COLOR", "1"
  os.putenv "NIMTEST_OUTPUT_LVL", "PRINT_FAILURES"

  const
    compileJson = "compile.json"
    runJson = "run.json"
    rejectJson = "reject.json"
  
  var optPrintResults = false
  var p = initOptParser()
  p.next()
  if p.kind == cmdLongoption:
    case p.key.string
    of "print": optPrintResults = true
    else: quit usage
    p.next()
  if p.kind != cmdArgument: quit usage
  var action = p.key.string.normalize
  p.next()
  var r = initResults()
  case action
  of "reject":
    reject(r, "tests/reject", p.cmdLineRest.string)
    rejectSpecialTests(r, p.cmdLineRest.string)
    writeResults(rejectJson, r)
  of "compile":
    compile(r, "tests/compile/t*.nim", p.cmdLineRest.string)
    compile(r, "tests/ccg/t*.nim", p.cmdLineRest.string)
    compile(r, "tests/js.nim", p.cmdLineRest.string)
    compileExample(r, "lib/pure/*.nim", p.cmdLineRest.string)
    compileExample(r, "examples/*.nim", p.cmdLineRest.string)
    compileExample(r, "examples/gtk/*.nim", p.cmdLineRest.string)
    compileExample(r, "examples/talk/*.nim", p.cmdLineRest.string)
    compileSpecialTests(r, p.cmdLineRest.string)
    writeResults(compileJson, r)
  of "run":
    run(r, "tests/run", p.cmdLineRest.string)
    runSpecialTests(r, p.cmdLineRest.string)
    writeResults(runJson, r)
  of "special":
    runSpecialTests(r, p.cmdLineRest.string)
    # runCaasTests(r)
    writeResults(runJson, r)
  of "rodfiles":
    runRodFiles(r, p.cmdLineRest.string)
    writeResults(runJson, r)
  of "js":
    if existsFile(runJSon):
      r = readResults(runJson)
    runJsTests(r, p.cmdLineRest.string)
    writeResults(runJson, r)
  of "merge":
    var rejectRes = readResults(rejectJson)
    var compileRes = readResults(compileJson)
    var runRes = readResults(runJson)
    listResults(rejectRes, compileRes, runRes)
    outputJSON(rejectRes, compileRes, runRes)
  of "dll":
    runDLLTests r, p.cmdLineRest.string
  of "gc":
    runGCTests(r, p.cmdLineRest.string)
  of "test":
    if p.kind != cmdArgument: quit usage
    var testFile = p.key.string
    p.next()
    runSingleTest(r, testFile, p.cmdLineRest.string)
  of "comp", "rej":
    if p.kind != cmdArgument: quit usage
    var testFile = p.key.string
    p.next()
    if peg"'/reject/'" in testFile or action == "rej":
      rejectSingleTest(r, testFile, p.cmdLineRest.string)
    elif peg"'/compile/'" in testFile or action == "comp":
      compileSingleTest(r, testFile, p.cmdLineRest.string)
    else:
      runSingleTest(r, testFile, p.cmdLineRest.string)
  else:
    quit usage

  if optPrintResults: echo r, r.data

if paramCount() == 0:
  quit usage
main()

