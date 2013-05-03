import osproc, streams, os, strutils, re

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
  var filter = ""
  if paramCount() > 0: filter = paramStr(1)
  
  for t, o, r in caasTestsRunner(filter):
    echo t, "\n", o
    
