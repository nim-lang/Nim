#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimsuggest is a tool that helps to give editors IDE like capabilities.

import strutils, os, parseopt, parseUtils
import options, commands, modules, sem, passes, passaux, msgs, nimconf,
  extccomp, condsyms, lists, net, rdstdin

const Usage = """
Nimsuggest - Tool to give every editor IDE like capabilities for Nim
Usage:
  nimsuggest [options] projectfile.nim

Options:
  --port:PORT             port, by default 6000
  --address:HOST          binds to that address, by default ""
  --stdin                 read commands from stdin and write results to
                          stdout instead of using sockets

The server then listens to the connection and takes line-based commands.

In addition, all command line options of Nim that do not affect code generation
are supported.
"""

var
  gPort = 6000.Port
  gAddress = ""
  gUseStdin: bool

const
  seps = {':', ';', ' ', '\t'}
  Help = "usage: sug|con|def|use file.nim[;dirtyfile.nim]:line:col\n"&
         "type 'quit' to quit\n" &
         "type 'debug' to toggle debug mode on/off\n" &
         "type 'terse' to toggle terse mode on/off"

proc parseQuoted(cmd: string; outp: var string; start: int): int =
  var i = start
  i += skipWhitespace(cmd, i)
  if cmd[i] == '"':
    i += parseUntil(cmd, outp, '"', i+1)+2
  else:
    i += parseUntil(cmd, outp, seps, i)
  result = i

proc action(cmd: string) =
  template toggle(sw) =
    if sw in gGlobalOptions:
      excl(gGlobalOptions, sw)
    else:
      incl(gGlobalOptions, sw)
    return

  template err() =
    echo Help
    return

  var opc = ""
  var i = parseIdent(cmd, opc, 0)
  case opc.normalize
  of "sug": gIdeCmd = ideSug
  of "con": gIdeCmd = ideCon
  of "def": gIdeCmd = ideDef
  of "use":
    modules.resetAllModules()
    gIdeCmd = ideUse
  of "quit": quit()
  of "debug": toggle optIdeDebug
  of "terse": toggle optIdeTerse
  else: err()
  var dirtyfile = ""
  var orig = ""
  i = parseQuoted(cmd, orig, i)
  if cmd[i] == ';':
    i = parseQuoted(cmd, dirtyfile, i+1)
  i += skipWhile(cmd, seps, i)
  var line, col = -1
  i += parseInt(cmd, line, i)
  i += skipWhile(cmd, seps, i)
  i += parseInt(cmd, col, i)

  var isKnownFile = true
  if orig.len == 0: err()
  let dirtyIdx = orig.fileInfoIdx(isKnownFile)

  if dirtyfile.len != 0: msgs.setDirtyFile(dirtyIdx, dirtyfile)
  else: msgs.setDirtyFile(dirtyIdx, nil)

  resetModule dirtyIdx
  if dirtyIdx != gProjectMainIdx:
    resetModule gProjectMainIdx
  gTrackPos = newLineInfo(dirtyIdx, line, col)
  #echo dirtyfile, gDirtyBufferIdx, " project ", gProjectMainIdx
  gErrorCounter = 0
  if not isKnownFile:
    compileProject(dirtyIdx)
  else:
    compileProject()

proc serve() =
  # do not stop after the first error:
  msgs.gErrorMax = high(int)
  if gUseStdin:
    echo Help
    var line = ""
    while readLineFromStdin("> ", line):
      action line
      echo ""
      flushFile(stdout)
  else:
    var server = newSocket()
    server.bindAddr(gPort, gAddress)
    var inp = "".TaintedString
    server.listen()

    while true:
      var stdoutSocket = newSocket()
      msgs.writelnHook = proc (line: string) =
        stdoutSocket.send(line & "\c\L")

      accept(server, stdoutSocket)

      stdoutSocket.readLine(inp)
      action inp.string

      stdoutSocket.send("\c\L")
      stdoutSocket.close()

proc mainCommand =
  registerPass verbosePass
  registerPass semPass
  gCmd = cmdIdeTools
  incl gGlobalOptions, optCaasEnabled
  isServing = true
  wantMainModule()
  appendStr(searchPaths, options.libpath)
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)

  serve()

proc processCmdLine*(pass: TCmdLinePass, cmd: string) =
  var p = parseopt.initOptParser(cmd)
  while true: 
    parseopt.next(p)
    case p.kind
    of cmdEnd: break 
    of cmdLongoption, cmdShortOption: 
      case p.key.normalize
      of "port": gPort = parseInt(p.val).Port
      of "address": gAddress = p.val
      of "stdin": gUseStdin = true
      else: processSwitch(pass, p)
    of cmdArgument:
      options.gProjectName = unixToNativePath(p.key)
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine() =
  if paramCount() == 0:
    stdout.writeln(Usage)
  else:
    processCmdLine(passCmd1, "")
    if gProjectName != "":
      try:
        gProjectFull = canonicalizePath(gProjectName)
      except OSError:
        gProjectFull = gProjectName
      var p = splitFile(gProjectFull)
      gProjectPath = p.dir
      gProjectName = p.name
    else:
      gProjectPath = getCurrentDir()
    loadConfigs(DefaultConfig) # load all config files
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars()
    processCmdLine(passCmd2, "")
    mainCommand()

when false:
  proc quitCalled() {.noconv.} =
    writeStackTrace()

  addQuitProc(quitCalled)

condsyms.initDefines()
defineSymbol "nimsuggest"
handleCmdline()
