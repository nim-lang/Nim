discard """
joinable: false
"""

import osproc, streams, strutils, os

const NumberOfProcesses = 13

var gResults {.threadvar.}: seq[string]

proc execCb(idx: int, p: Process) =
  let exitCode = p.peekExitCode
  if exitCode < len(gResults):
    gResults[exitCode] = p.outputStream.readAll.strip

when true:
  if paramCount() == 0:
    gResults = newSeq[string](NumberOfProcesses)
    var checks = newSeq[string](NumberOfProcesses)
    var commands = newSeq[string](NumberOfProcesses)
    for i in 0..len(commands) - 1:
      commands[i] = getAppFileName() & " " & $i
      checks[i] = $i
    let cres = execProcesses(commands, options = {poStdErrToStdOut},
                             afterRunEvent = execCb)
    doAssert(cres == len(commands) - 1)
    doAssert(gResults == checks)
  else:
    echo paramStr(1)
    programResult = parseInt(paramStr(1))
