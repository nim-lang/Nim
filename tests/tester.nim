#
#
#            Nimrod Tester
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nimrod against the testcases.
## The testcases may contain the directives '#ERROR' or '#ERROR_IN'.
## '#ERROR' is used to indicate that the compiler should report
## an error in the marked line (the line that contains the '#ERROR'
## directive.)
## The format for '#ERROR_IN' is:
##      #ERROR_IN filename linenumber
## One can omit the extension of the filename ('.nim' is then assumed).
## Tests which contain none of the two directives should compile. Thus they
## are executed after successful compilation and their output is verified
## against the results specified with the '#OUT' directive.
## (Tests which require user interaction are not possible.)
## Tests can have an #ERROR_MSG directive specifiying the error message
## Nimrod shall produce.

import
  strutils, pegs, os, osproc, streams

const
  cmdTemplate = r"nimrod cc --hints:on $options $filename"

type
  TSpec = object of TObject ## specification object
    line: int    ## line number where compiler should throw an error
    file: string ## file where compiler should throw an error
    err: bool    ## true if the specification says there should be an error
    outp: string ## output that should be produced
    puremsg: string ## pure message of compiler

proc myExec(cmd: string): string =
  #echo("Executing: " & cmd)
  result = osproc.execProcess(cmd)
  #echo("Received: " & result)

proc parseTest(filename: string): TSpec =
  var i = 0 # the line counter
  var matches: array [0..2, string]
  result.outp = ""
  result.puremsg = ""
  result.file = filename
  for s in lines(filename):
    inc(i)
    if contains(s, peg"'#OUT' \s+ {.*}", matches):
      result.outp = matches[0]
      break
    if contains(s, peg"'#ERROR_IN' \s* {\S*} \s* {\d+}", matches):
      result.file = matches[0]
      result.line = parseInt(matches[1])
      result.err = true
      break
    if contains(s, peg"'#ERROR_MSG' \s* {.*}", matches):
      result.line = i
      result.outp = matches[0]
      result.err = True
      break
    if contains(s, peg"'#ERROR' \s* !.", matches):
      result.line = i
      result.err = true
      break

var
  pegLineError = peg"{[^(]*} '(' {\d+} ', ' \d+ ') Error:' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError / pegSuccess

proc callCompiler(filename, options: string): TSpec =
  var c = parseCmdLine(cmdTemplate % ["filename", filename, "options", options])
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
  result.outp = ""
  result.puremsg = ""
  result.file = ""
  result.err = true
  if s =~ pegLineError:
    result.file = matches[0]
    result.line = parseInt(matches[1])
    result.outp = s
    result.puremsg = matches[2]
  elif s =~ pegOtherError:
    result.puremsg = matches[0]
    result.outp = s
    result.line = 1
  elif s =~ pegSuccess:
    result.outp = s
    result.err = false

proc sameResults(filename: string, spec, comp: TSpec): bool =
  # short filename for messages (better readability):
  var shortfile = os.extractFilename(filename)

  if comp.err and comp.outp == "":
    # the compiler did not say "[Error]" nor "operation sucessful"
    Echo("[Tester] $# -- FAILED; COMPILER BROKEN" % shortfile)
  elif spec.err != comp.err:
    Echo(("[Tester] $# -- FAILED\n" &
         "Compiler says: $#\n" &
         "But specification says: $#") %
         [shortfile, comp.outp, spec.outp])
  elif spec.err:
    if extractFilename(comp.file) != extractFilename(spec.file):
      Echo(("[Tester] $# -- FAILED: file names do not match:\n" &
           "Compiler: $#\nSpec: $#") % [shortfile, comp.file, spec.file])
    elif strip(spec.outp) notin strip(comp.puremsg):
      Echo(("[Tester] $# -- FAILED: error messages do not match:\n" &
           "Compiler: $#\nSpec: $#") % [shortfile, comp.pureMsg, spec.outp])
    elif comp.line != spec.line:
      Echo(("[Tester] $# -- FAILED: line numbers do not match:\n" &
           "Compiler: $#\nSpec: $#") % [shortfile, $comp.line, $spec.line])
    else:
      Echo("[Tester] $# -- OK" % shortfile)
      result = true
  else:
    # we have to run the executable and check its output:
    var exeFile = changeFileExt(filename, ExeExt)
    if ExistsFile(exeFile):
      if len(spec.outp) == 0:
        # we have no output to validate against, but compilation succeeded,
        # so it's okay:
        Echo("[Tester] $# -- OK" % shortfile)
        result = true
      else:
        var buf = myExec(exeFile)
        result = strip(buf) == strip(spec.outp)
        if result:
          Echo("[Tester] $# -- compiled program OK" % shortfile)
        else:
          Echo("[Tester] $# -- compiled program FAILED" % shortfile)
    else:
      Echo("[Tester] $# -- FAILED; executable not found" % shortfile)

proc main(options: string) =
  # runs the complete testsuite
  var total = 0
  var passed = 0
  for filename in os.walkFiles("tests/t*.nim"):
    if extractFilename(filename) == "tester.nim": continue
    var spec = parseTest(filename)
    var comp = callCompiler(filename, options)
    if sameResults(filename, spec, comp): inc(passed)
    inc(total)
  # ensure that the examples at least compile
  for filename in os.walkFiles("examples/*.nim"):
    var comp = callCompiler(filename, options)
    var shortfile = os.extractFilename(filename)
    if comp.err:
      Echo("[Tester] Example '$#' -- FAILED" % shortfile)
    else:
      Echo("[Tester] Example $# -- OK" % shortfile)
      inc(passed)
    inc(total)
  Echo("[Tester] $#/$# tests passed\n" % [$passed, $total])

var
  options = ""
for i in 1.. paramCount():
  add(options, " ")
  add(options, paramStr(i))
main(options)
