#
#
#            Nimrod Tester
#        (c) Copyright 2008 Andreas Rumpf
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
  strutils, regexprs, os, osproc, streams

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
  result = osproc.executeProcess(cmd)
  #echo("Received: " & result)

proc parseTest(filename: string): TSpec =
  var i = 0 # the line counter
  var matches: array [0..2, string]
  result.outp = ""
  result.puremsg = ""
  result.file = filename
  for s in lines(filename):
    inc(i)
    if find(s, r"\#OUT\s*(.*)", matches):
      result.outp = matches[1]
      break
    if find(s, r"\#ERROR_IN\s*(\S*)\s*(\d+)", matches):
      result.file = matches[1]
      result.line = parseInt(matches[2])
      result.err = true
      break
    if find(s, r"\#ERROR_MSG\s*(.*)", matches):
      result.line = i
      result.outp = matches[1]
      result.err = True
      break
    if find(s, r"\#ERROR$", matches):
      result.line = i
      result.err = true
      break

proc callCompiler(filename, options: string): TSpec =
  var c = parseCmdLine(cmdTemplate % ["filename", filename, "options", options])
  var a: seq[string] = @[] # slicing is not yet implemented :-(
  for i in 1 .. c.len-1: add(a, c[i])
  var p = startProcess(command=c[0], args=a,
                       options={poStdErrToStdOut, poUseShell})
  var outp = p.outputStream
  while running(p) or not outp.atEnd(outp):
    var s = outp.readLine()
    var matches: array [0..3, string]
    result.outp = ""
    result.puremsg = ""
    result.file = ""
    result.err = true
    if match(s, r"(.*)\((\d+), \d+\) Error\: (.*)", matches):
      result.file = matches[1]
      result.line = parseInt(matches[2])
      result.outp = matches[0]
      result.puremsg = matches[3]
      break
    elif match(s, r"Error\: (.*)", matches):
      result.puremsg = matches[1]
      result.outp = matches[0]
      result.line = 1
      break
    elif match(s, r"Hint\: operation successful", matches):
      result.outp = matches[0]
      result.err = false
      break

proc cmpResults(filename: string, spec, comp: TSpec): bool =
  # short filename for messages (better readability):
  var shortfile = os.extractFilename(filename)

  if comp.err and comp.outp == "":
    # the compiler did not say "[Error]" nor "operation sucessful"
    Echo("[Tester] $1 -- FAILED; COMPILER BROKEN" % shortfile)
  elif spec.err != comp.err:
    Echo(("[Tester] $1 -- FAILED\n" &
         "Compiler says: $2\n" &
         "But specification says: $3") %
         [shortfile, comp.outp, spec.outp])
  elif spec.err:
    if extractFilename(comp.file) != extractFilename(spec.file):
      Echo(("[Tester] $1 -- FAILED: file names do not match:\n" &
           "Compiler: $2\nSpec: $3") % [shortfile, comp.file, spec.file])
    elif strip(spec.outp) notin strip(comp.puremsg):
      Echo(("[Tester] $1 -- FAILED: error messages do not match:\n" &
           "Compiler: $2\nSpec: $3") % [shortfile, comp.pureMsg, spec.outp])
    elif comp.line != spec.line:
      Echo(("[Tester] $1 -- FAILED: line numbers do not match:\n" &
           "Compiler: $2\nSpec: $3") % [shortfile, $comp.line, $spec.line])
    else:
      Echo("[Tester] $1 -- OK" % shortfile)
      result = true
  else:
    # we have to run the executable and check its output:
    var exeFile = changeFileExt(filename, ExeExt)
    if ExistsFile(exeFile):
      if len(spec.outp) == 0:
        # we have no output to validate against, but compilation succeeded,
        # so it's okay:
        Echo("[Tester] $1 -- OK" % shortfile)
        result = true
      else:
        var buf = myExec(exeFile)
        result = strip(buf) == strip(spec.outp)
        if result:
          Echo("[Tester] $1 -- compiled program OK" % shortfile)
        else:
          Echo("[Tester] $1 -- compiled program FAILED" % shortfile)
    else:
      Echo("[Tester] $1 -- FAILED; executable not found" % shortfile)

proc main(options: string) =
  # runs the complete testsuite
  var total = 0
  var passed = 0
  for filename in os.walkFiles("tests/t*.nim"):
    if extractFilename(filename) == "tester.nim": continue
    var spec = parseTest(filename)
    var comp = callCompiler(filename, options)
    if cmpResults(filename, spec, comp): inc(passed)
    inc(total)
  Echo("[Tester] $1/$2 tests passed\n" % [$passed, $total])

var
  options = ""
for i in 1.. paramCount():
  add(options, " ")
  add(options, paramStr(i))
main(options)
