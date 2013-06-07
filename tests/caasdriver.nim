import osproc, streams, os, strutils, re

## Compiler as a service tester.
##
## This test cases uses the txt files in the caas/ subdirectory.
## Each of the text files inside encodes a session with the compiler.
## The first line indicates the main project file. Lines starting with '>'
## indicate a command to be sent to the compiler and the lines following a
## command include checks for expected or forbidden output (! for forbidden).
##
## You can optionally pass parameters at the command line to modify the
## behaviour of the test suite. By default only tests which fail will be echoed
## to stdout. If you want to see all the output pass the word "verbose" as a
## parameter.
##
## If you don't want to run all the test case files, you can pass any substring
## as a parameter. Only files matching the passed substring will be run. The
## filtering doesn't use any globbing metacharacters, it's a plain match.
##
## Example to run only "*-compile*.txt" tests in verbose mode:
##
##   ./caasdriver verbose -compile


type
  TNimrodSession* = object
    nim: PProcess

proc dirname(path: string): string = path.splitPath()[0]

var
  TesterDir = getAppDir()
  NimrodBin = TesterDir / "../bin/nimrod"

proc startNimrodSession*(project: string): TNimrodSession =
  result.nim = startProcess(NimrodBin,
    workingDir = project.dirname,
    args = ["serve", "--server.type:stdin", project])

proc doCommand*(session: var TNimrodSession, command: string): string =
  session.nim.inputStream.write(command & "\n")
  session.nim.inputStream.flush

  result = ""

  while true:
    var line = TaintedString("")
    if session.nim.outputStream.readLine(line):
      if line.string == "": break
      result.add(line.string & "\n")
    else:
      result = "FAILED TO EXECUTE: " & command & "\n" & result
      break

proc close(session: var TNimrodSession) {.destructor.} =
  session.nim.close

proc doScenario(script: string, output: PStream): bool =
  result = true

  var f = open(script)
  var project = TaintedString("")

  if f.readLine(project):
    var
      s = startNimrodSession(script.dirname / project.string)
      tline = TaintedString("")
      lastOutput = ""
      ln = 1

    while f.readLine(tline):
      var line = tline.string
      inc ln
      if line.strip.len == 0: continue

      if line.startsWith(">"):
        lastOutput = s.doCommand(line.substr(1).strip)
        output.writeln line, "\n", lastOutput
      else:
        var expectMatch = true
        var pattern = line
        if line.startsWith("!"):
          pattern = line.substr(1).strip
          expectMatch = false

        var actualMatch = lastOutput.find(re(pattern)) != -1

        if expectMatch == actualMatch:
          output.writeln "SUCCESS ", line
        else:
          output.writeln "FAILURE ", line
          result = false

iterator caasTestsRunner*(filter = ""): tuple[test, output: string,
                                              status: bool] =
  for scenario in os.walkFiles(TesterDir / "caas/*.txt"):
    if filter.len > 0 and find(scenario, filter) == -1: continue
    var outStream = newStringStream()
    let r = doScenario(scenario, outStream)
    yield (scenario, outStream.data, r)

when isMainModule:
  var
    filter = ""
    failures = 0
    verbose = false

  for i in 0..ParamCount() - 1:
    let param = paramStr(i + 1)
    case param
    of "verbose": verbose = true
    else: filter = param

  if verbose and len(filter) > 0:
    echo "Running only test cases matching filter '$1'" % [filter]

  for test, output, result in caasTestsRunner(filter):
    if not result or verbose:
      echo test, "\n", output, "-> ", $result, "\n-----"
    if not result:
      failures += 1

  quit(failures)
