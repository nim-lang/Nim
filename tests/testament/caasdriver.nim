import osproc, streams, os, strutils, re

## Compiler as a service tester.
##
## Please read docs/idetools.txt for information about this.


type
  TRunMode = enum
    ProcRun, CaasRun, SymbolProcRun

  TNimrodSession* = object
    nim: PProcess # Holds the open process for CaasRun sessions, nil otherwise.
    mode: TRunMode # Stores the type of run mode the session was started with.
    lastOutput: string # Preserves the last output, needed for ProcRun mode.
    filename: string # Appended to each command starting with '>'. Also a var.
    modname: string # Like filename but without extension.
    nimcache: string # Input script based name for the nimcache dir.

const
  modes = [CaasRun, ProcRun, SymbolProcRun]
  filenameReplaceVar = "$TESTNIM"
  moduleReplaceVar = "$MODULE"
  silentReplaceVar = "$SILENT"
  silentReplaceText = "--verbosity:0 --hints:off"

var
  TesterDir = getAppDir() / ".."
  NimrodBin = TesterDir / "../bin/nimrod"

proc replaceVars(session: var TNimrodSession, text: string): string =
  result = text.replace(filenameReplaceVar, session.filename)
  result = result.replace(moduleReplaceVar, session.modname)
  result = result.replace(silentReplaceVar, silentReplaceText)

proc startNimrodSession(project, script: string, mode: TRunMode):
                        TNimrodSession =
  let (dir, name, ext) = project.splitFile
  result.mode = mode
  result.lastOutput = ""
  result.filename = name & ext
  result.modname = name

  let (nimcacheDir, nimcacheName, nimcacheExt) = script.splitFile
  result.nimcache = "SymbolProcRun." & nimcacheName

  if mode == SymbolProcRun:
    removeDir(nimcacheDir / result.nimcache)
  else:
    removeDir(nimcacheDir / "nimcache")

  if mode == CaasRun:
    result.nim = startProcess(NimrodBin, workingDir = dir,
      args = ["serve", "--server.type:stdin", name])

proc doCaasCommand(session: var TNimrodSession, command: string): string =
  assert session.mode == CaasRun
  session.nim.inputStream.write(session.replaceVars(command) & "\n")
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
  assert session.mode == ProcRun or session.mode == SymbolProcRun
  except: result = "FAILED TO EXECUTE: " & command & "\n" & result
  var
    process = startProcess(NimrodBin, args = session.replaceVars(command).split)
    stream = outputStream(process)
    line = TaintedString("")

  result = ""
  while stream.readLine(line):
    if result.len > 0: result &= "\n"
    result &= line.string

  process.close()

proc doCommand(session: var TNimrodSession, command: string) =
  if session.mode == CaasRun:
    if not session.nim.running:
      session.lastOutput = "FAILED TO EXECUTE: " & command & "\n" &
          "Exit code " & $session.nim.peekExitCode
      return
    session.lastOutput = doCaasCommand(session,
                                       command & " " & session.filename)
  else:
    var command = command
    # For symbol runs we prepend the necessary parameters to avoid clobbering
    # the normal nimcache.
    if session.mode == SymbolProcRun:
      command = "--symbolFiles:on --nimcache:" & session.nimcache &
                " " & command
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
      s = startNimrodSession(script.parentDir / project.string, script, mode)
      tline = TaintedString("")
      ln = 1

    while f.readLine(tline):
      var line = tline.string
      inc ln

      # Filter lines by run mode, removing the prefix if the mode is current.
      for testMode in modes:
        if line.startsWith($testMode):
          if testMode != mode:
            line = ""
          else:
            line = line[len($testMode)..len(line) - 1].strip
          break

      if line.strip.len == 0: continue

      if line.startsWith("#"):
        output.writeln line
        continue
      elif line.startsWith(">"):
        s.doCommand(line.substr(1).strip)
        output.writeln line, "\n", s.lastOutput
      else:
        var expectMatch = true
        var pattern = s.replaceVars(line)
        if line.startsWith("!"):
          pattern = pattern.substr(1).strip
          expectMatch = false

        let actualMatch =
          s.lastOutput.find(re(pattern, flags = {reStudy})) != -1

        if expectMatch == actualMatch:
          output.writeln "SUCCESS ", line
        else:
          output.writeln "FAILURE ", line
          result = false

iterator caasTestsRunner*(filter = ""): tuple[test, output: string,
                                              status: bool, mode: TRunMode] =
  for scenario in os.walkFiles(TesterDir / "caas/*.txt"):
    if filter.len > 0 and find(scenario, filter) == -1: continue
    for mode in modes:
      var outStream = newStringStream()
      let r = doScenario(scenario, outStream, mode)
      yield (scenario, outStream.data, r, mode)

when isMainModule:
  var
    filter = ""
    failures = 0
    verbose = false

  for i in 0..ParamCount() - 1:
    let param = string(paramStr(i + 1))
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
