#
#
#            Nimrod Tester
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nimrod against the testcases.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, browsers

const
  cmdTemplate = r"nimrod cc --hints:on $# $#"
  resultsFile = "testresults.html"

type
  TTestAction = enum
    actionCompile, actionRun, actionReject
  TSpec {.pure.} = object
    action: TTestAction
    file, cmd: string
    outp: string
    line: int
    msg: string
    err: bool
    disabled: bool
    substr: bool
  TResults {.pure.} = object
    total, passed, skipped: int
    data: string
  
  TResultEnum = enum
    reFailure, reIgnored, reSuccess

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
  var x = readFile(filename)
  if isNil(x): quit "cannot open file: " & filename
  var a = x.find(tripleQuote)
  var b = x.find(tripleQuote, a+3)
  if a >= 0 and b > a: 
    result = x.copy(a+3, b-1).replace("'''", tripleQuote)
  else:
    #echo "warning: file does not contain spec: " & filename
    result = ""

template parseSpecAux(fillResult: stmt) = 
  var ss = newStringStream(extractSpec(filename))
  var p: TCfgParser
  open(p, ss, filename, 1)
  while true:
    var e = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart, cfgOption, cfgError:
      echo ignoreMsg(p, e)
    of cfgKeyValuePair:
      fillResult
  close(p)
  
proc parseSpec(filename: string): TSpec = 
  result.file = filename
  result.err = true
  result.msg = ""
  result.outp = ""
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
    of "errormsg", "msg": result.msg = e.value
    of "disabled": result.disabled = parseCfgBool(e.value)
    of "cmd": result.cmd = e.value
    else: echo ignoreMsg(p, e)

# ----------------------------------------------------------------------------

proc myExec(cmd: string): string =
  result = osproc.execProcess(cmd)

var
  pegLineError = peg"{[^(]*} '(' {\d+} ', ' \d+ ') Error:' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError / pegSuccess

proc callCompiler(cmdTemplate, filename, options: string): TSpec =
  var c = parseCmdLine(cmdTemplate % [options, filename])
  var a: seq[string] = @[] # slicing is not yet implemented :-(
  for i in 1 .. c.len-1: add(a, c[i])
  var p = startProcess(command=c[0], args=a,
                       options={poStdErrToStdOut, poUseShell})
  var outp = p.outputStream
  var s = ""
  while running(p) or not outp.atEnd(outp):
    var x = outp.readLine()
    if x =~ pegOfInterest:
      # `s` should contain the last error message
      s = x
  result.msg = ""
  result.file = ""
  result.outp = ""
  result.err = true    
  result.line = -1
  if s =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.msg = matches[2]
  elif s =~ pegOtherError:
    result.msg = matches[0]
  elif s =~ pegSuccess:
    result.err = false

proc initResults: TResults = 
  result.total = 0
  result.passed = 0
  result.skipped = 0
  result.data = ""

proc `$`(x: TResults): string = 
  result = ("Tests passed: $1 / $3 <br />\n" &
            "Tests skipped: $2 / $3 <br />\n") %
            [$x.passed, $x.skipped, $x.total]

proc colorResult(r: TResultEnum): string =
  case r
  of reFailure: result = "<span style=\"color:red\">no</span>"
  of reIgnored: result = "<span style=\"color:fuchsia\">ignored</span>"
  of reSuccess: result = "<span style=\"color:green\">yes</span>" 

const
  TableHeader4 = "<table border=\"1\"><tr><td>Test</td><td>Expected</td>" &
                 "<td>Given</td><td>Success</td></tr>\n"
  TableHeader3 = "<table border=\"1\"><tr><td>Test</td>" &
                 "<td>Given</td><td>Success</td></tr>\n"
  TableFooter = "</table>\n"

proc addResult(r: var TResults, test, expected, given: string,
               success: TResultEnum) =
  r.data.addf("<tr><td>$#</td><td>$#</td><td>$#</td><td>$#</td></tr>\n", [
    test, expected, given, success.colorResult])

proc addResult(r: var TResults, test, given: string,
               success: TResultEnum) =
  r.data.addf("<tr><td>$#</td><td>$#</td><td>$#</td></tr>\n", [
    test, given, success.colorResult])

proc listResults(reject, compile, run: TResults) =
  var s = "<html>"
  s.add("<h1>Tests to Reject</h1>\n")
  s.add($reject)
  s.add(TableHeader4 & reject.data & TableFooter)
  s.add("<br /><br /><br /><h1>Tests to Compile</h1>\n")
  s.add($compile)
  s.add(TableHeader3 & compile.data & TableFooter)
  s.add("<br /><br /><br /><h1>Tests to Run</h1>\n")
  s.add($run)
  s.add(TableHeader4 & run.data & TableFooter)
  s.add("</html>")
  var outp: TFile
  if open(outp, resultsFile, fmWrite):
    write(outp, s)
    close(outp)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: string) = 
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, expected.msg, given.msg, reFailure)
  elif extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, expected.file, given.file, reFailure)
  elif expected.line != given.line and expected.line != 0:
    r.addResult(test, $expected.line, $given.line, reFailure)
  else:
    r.addResult(test, expected.msg, given.msg, reSuccess)
    inc(r.passed)

proc reject(r: var TResults, dir, options: string) =  
  ## handle all the tests that the compiler should reject
  for test in os.walkFiles(dir / "t*.nim"):
    var t = extractFilename(test)
    inc(r.total)
    echo t
    var expected = parseSpec(test)
    if expected.disabled: 
      r.addResult(t, "", "", reIgnored)
      inc(r.skipped)
    else:
      var given = callCompiler(expected.cmd, test, options)
      cmpMsgs(r, expected, given, t)
  
proc compile(r: var TResults, pattern, options: string) =
  for test in os.walkFiles(pattern):
    var t = extractFilename(test)
    echo t
    inc(r.total)
    var expected = parseSpec(test)
    if expected.disabled:
      r.addResult(t, "", reIgnored)
      inc(r.skipped)
    else:
      var given = callCompiler(expected.cmd, test, options)
      r.addResult(t, given.msg, if given.err: reFailure else: reSuccess)
      if not given.err: inc(r.passed)

proc compileSingleTest(r: var TResults, test, options: string) =
  var t = extractFilename(test)
  inc(r.total)
  echo t
  var given = callCompiler(cmdTemplate, test, options)
  r.addResult(t, given.msg, if given.err: reFailure else: reSuccess)
  if not given.err: inc(r.passed)

proc runSingleTest(r: var TResults, test, options: string) =
  var t = extractFilename(test)
  echo t
  inc(r.total)
  var expected = parseSpec(test)
  if expected.disabled:
    r.addResult(t, "", "", reIgnored)
    inc(r.skipped)
  else:
    var given = callCompiler(expected.cmd, test, options)
    if given.err:
      r.addResult(t, "", given.msg, reFailure)
    else:
      var exeFile = changeFileExt(test, ExeExt)
      if existsFile(exeFile):
        var buf = myExec(exeFile)
        var success = strip(buf) == strip(expected.outp)
        if expected.substr: success = expected.outp in buf
        if success: inc(r.passed)
        r.addResult(t, expected.outp, 
            buf, if success: reSuccess else: reFailure)
      else:
        r.addResult(t, expected.outp, "executable not found", reFailure)

proc run(r: var TResults, dir, options: string) = 
  for test in os.walkFiles(dir / "t*.nim"): runSingleTest(r, test, options)
  
proc compileExample(r: var TResults, pattern, options: string) = 
  for test in os.walkFiles(pattern): compileSingleTest(r, test, options)

proc testLib(r: var TResults, options: string) =
  nil

var options = ""
var rejectRes = initResults()
var compileRes = initResults()
var runRes = initResults()
  
for i in 1.. paramCount():
  add(options, " ")
  add(options, paramStr(i))

reject(rejectRes, "tests/reject", options)
compile(compileRes, "tests/accept/compile/t*.nim", options)
compileExample(compileRes, "examples/*.nim", options)
compileExample(compileRes, "examples/gtk/*.nim", options)
run(runRes, "tests/accept/run", options)
listResults(rejectRes, compileRes, runRes)
openDefaultBrowser(resultsFile)

