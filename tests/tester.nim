#
#
#            Nimrod Tester
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nimrod against the testcases.

import
  strutils, pegs, os, osproc, streams, parsecsv, browsers

const
  cmdTemplate = r"nimrod cc --hints:on $# $#"
  resultsFile = "testresults.html"

type
  TMsg = tuple[
    file: string,
    line: int,       
    msg: string,
    err: bool]
  TOutp = tuple[file, outp: string]
  TResult = tuple[test, expected, given: string, success: bool]
  TResults = object
    total, passed: int
    data: string

proc myExec(cmd: string): string =
  #echo("Executing: " & cmd)
  result = osproc.execProcess(cmd)
  #echo("Received: " & result)

var
  pegLineError = peg"{[^(]*} '(' {\d+} ', ' \d+ ') Error:' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError / pegSuccess

proc callCompiler(filename, options: string): TMsg =
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

proc setupCvsParser(csvFile: string): TCsvParser = 
  var s = newFileStream(csvFile, fmRead)
  if s == nil: quit("cannot open the file" & csvFile)
  result.open(s, csvFile, separator=';', skipInitialSpace=true)

proc parseRejectData(dir: string): seq[TMsg] = 
  var p = setupCvsParser(dir / "spec.csv")
  result = @[]
  while readRow(p, 3):
    result.add((p.row[0], parseInt(p.row[1]), p.row[2], true))
  close(p)

proc parseRunData(dir: string): seq[TOutp] = 
  var p = setupCvsParser(dir / "spec.csv")
  result = @[]
  while readRow(p, 2):
    result.add((p.row[0], p.row[1]))
  close(p)

proc findSpec[T](specs: seq[T], filename: string): int = 
  while result < specs.len:
    if specs[result].file == filename: return
    inc(result)
  quit("cannot find spec for file: " & filename)

proc initResults: TResults = 
  result.total = 0
  result.passed = 0
  result.data = ""

proc colorBool(b: bool): string =
  if b: result = "<span style=\"color:green\">yes</span>" 
  else: result = "<span style=\"color:red\">no</span>"

const
  TableHeader = "<table border=\"1\"><tr><td>Test</td><td>Expected</td>" &
                "<td>Given</td><td>Success</td></tr>\n"
  TableFooter = "</table>\n"

proc `$`(r: TResults): string = 
  result = TableHeader
  result.add(r.data)
  result.add(TableFooter)

proc addResult(r: var TResults, test, expected, given: string,
               success: bool) =
  r.data.addf("<tr><td>$#</td><td>$#</td><td>$#</td><td>$#</td></tr>\n", [
    test, expected, given, success.colorBool])

proc listResults(reject, compile, run: TResults) =
  var s = "<html>"
  s.add("<h1>Tests to Reject</h1>\n")
  s.add($reject)
  s.add("<br /><br /><br /><h1>Tests to Compile</h1>\n")
  s.add($compile)
  s.add("<br /><br /><br /><h1>Tests to Run</h1>\n")
  s.add($run)
  s.add("</html>")
  var outp: TFile
  if open(outp, resultsFile, fmWrite):
    write(outp, s)
    close(outp)

proc cmpMsgs(r: var TResults, expected, given: TMsg, test: string) = 
  inc(r.total)
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, expected.msg, given.msg, false)
  elif expected.file != given.file:
    r.addResult(test, expected.file, given.file, false)
  elif expected.line != given.line: 
    r.addResult(test, $expected.line, $given.line, false)
  else:
    r.addResult(test, expected.msg, given.msg, true)
    inc(r.passed)

proc reject(r: var TResults, dir, options: string) =  
  ## handle all the tests that the compiler should reject
  var specs = parseRejectData(dir)
  
  for test in os.walkFiles(dir / "t*.nim"):
    var t = extractFilename(test)
    var expected = findSpec(specs, t)
    var given = callCompiler(test, options)
    cmpMsgs(r, specs[expected], given, t)
  
proc compile(r: var TResults, pattern, options: string) = 
  for test in os.walkFiles(pattern): 
    var t = extractFilename(test)
    inc(r.total)
    var given = callCompiler(test, options)
    echo given.msg, "##", given.err
    r.addResult(t, "", given.msg, not given.err)
    if not given.err: inc(r.passed)
  
proc run(r: var TResults, dir, options: string) = 
  var specs = parseRunData(dir)
  for test in os.walkFiles(dir / "t*.nim"): 
    var t = extractFilename(test)
    inc(r.total)
    var given = callCompiler(test, options)
    if given.err:
      r.addResult(t, "", given.msg, not given.err)
    else:
      var exeFile = changeFileExt(test, ExeExt)
      var expected = specs[findSpec(specs, t)]
      if existsFile(exeFile):
        var buf = myExec(exeFile)
        var success = strip(buf) == strip(expected.outp)
        if success: inc(r.passed)
        r.addResult(t, expected.outp, buf, success)
      else:
        r.addResult(t, expected.outp, "executable not found", false)

var options = ""
var rejectRes = initResults()
var compileRes = initResults()
var runRes = initResults()
  
for i in 1.. paramCount():
  add(options, " ")
  add(options, paramStr(i))

#reject(rejectRes, "tests/reject", options)
#compile(compileRes, "tests/accept/compile/t*.nim", options)
compile(compileRes, "examples/*.nim", options)
#compile(compileRes, "examples/gtk/*.nim", options)
#run(runRes, "tests/accept/run", options)
listResults(rejectRes, compileRes, runRes)
openDefaultBrowser(resultsFile)
