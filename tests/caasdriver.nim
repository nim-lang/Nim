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
  TRunMode = enum
    ProcRun, CaasRun

  TNimrodSession* = object
    nim: PProcess # Holds the open process for CaasRun sessions, nil otherwise.
    mode: TRunMode # Stores the type of run mode the session was started with.
    lastOutput: string # Preserves the last output, needed for ProcRun mode.
    filename: string # Appended to each command starting with '>'.

var
  TesterDir = getAppDir()
  NimrodBin = TesterDir / "../bin/nimrod"

proc startNimrodSession(project: string, mode: TRunMode): TNimrodSession =
  let (dir, name) = project.SplitPath
  result.mode = mode
  result.lastOutput = ""
  result.filename = name
  if mode == CaasRun:
    result.nim = startProcess(NimrodBin, workingDir = dir,
      args = ["serve", "--server.type:stdin", name])

proc doCaasCommand(session: var TNimrodSession, command: string): string =
  assert session.mode == CaasRun
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

proc doProcCommand(session: var TNimrodSession, command: string): string =
  assert session.mode == ProcRun
  except: result = "FAILED TO EXECUTE: " & command & "\n" & result
  var
    process = startProcess(NimrodBin, args = command.split)
    stream = outputStream(process)
    line = TaintedString("")

  result = ""
  while stream.readLine(line):
    if result.len > 0: result &= "\n"
    result &= line.string

  process.close()

proc doCommand(session: var TNimrodSession, command: string) =
  if session.mode == CaasRun:
    session.lastOutput = doCaasCommand(session,
                                       command & " " & session.filename)
  else:
    session.lastOutput = doProcCommand(session,
                                       command & " " & session.filename)

proc close(session: var TNimrodSession) {.destructor.} =
  if session.mode == CaasRun:
    session.nim.close

proc doScenario(script: string, output: PStream, mode: TRunMode): bool =
  result = true

  var f = open(script)
  var project = TaintedString("")

  if f.readLine(project):
    var
      s = startNimrodSession(script.parentDir / project.string, mode)
      tline = TaintedString("")
      ln = 1

    while f.readLine(tline):
      var line = tline.string
      inc ln
      if line.strip.len == 0: continue

      if line.startsWith(">"):
        s.doCommand(line.substr(1).strip)
        output.writeln line, "\n", s.lastOutput
      else:
        var expectMatch = true
        var pattern = line
        if line.startsWith("!"):
          pattern = line.substr(1).strip
          expectMatch = false

        var actualMatch = s.lastOutput.find(re(pattern)) != -1

        if expectMatch == actualMatch:
          output.writeln "SUCCESS ", line
        else:
          output.writeln "FAILURE ", line
          result = false

iterator caasTestsRunner*(filter = ""): tuple[test, output: string,
                                              status: bool, mode: TRunMode] =
  for scenario in os.walkFiles(TesterDir / "caas/*.txt"):
    if filter.len > 0 and find(scenario, filter) == -1: continue
    for mode in [CaasRun, ProcRun]:
      var outStream = newStringStream()
      let r = doScenario(scenario, outStream, mode)
      yield (scenario, outStream.data, r, mode)

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

  for test, output, result, mode in caasTestsRunner(filter):
    if not result or verbose:
      echo test, "\n", output, "-> ", $mode, ":", $result, "\n-----"
    if not result:
      failures += 1

  quit(failures)
