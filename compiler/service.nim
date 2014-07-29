#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements the "compiler as a service" feature.

import
  times, commands, options, msgs, nimconf,
  extccomp, strutils, os, platform, parseopt

when useCaas:
  import sockets

# We cache modules and the dependency graph. However, we don't check for
# file changes but expect the client to tell us about them, otherwise the
# repeated CRC calculations may turn out to be too slow.

var
  curCaasCmd* = ""
  lastCaasCmd* = ""
    # in caas mode, the list of defines and options will be given at start-up?
    # it's enough to check that the previous compilation command is the same?
  arguments* = ""
    # the arguments to be passed to the program that
    # should be run

proc processCmdLine*(pass: TCmdLinePass, cmd: string) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
  while true: 
    parseopt.next(p)
    case p.kind
    of cmdEnd: break 
    of cmdLongoption, cmdShortOption: 
      # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
      # we fix this here
      var bracketLe = strutils.find(p.key, '[')
      if bracketLe >= 0: 
        var key = substr(p.key, 0, bracketLe - 1)
        var val = substr(p.key, bracketLe + 1) & ':' & p.val
        processSwitch(key, val, pass, gCmdLineInfo)
      else: 
        processSwitch(p.key, p.val, pass, gCmdLineInfo)
    of cmdArgument:
      if argsCount == 0:
        options.command = p.key
      else:
        if pass == passCmd1: options.commandArgs.add p.key
        if argsCount == 1:
          # support UNIX style filenames anywhere for portable build scripts:
          options.gProjectName = unixToNativePath(p.key)
          arguments = cmdLineRest(p)
          break
      inc argsCount
          
  if pass == passCmd2:
    if optRun notin gGlobalOptions and arguments != "" and options.command.normalize != "run":
      rawMessage(errArgsNeedRunOption, [])

proc serve*(action: proc (){.nimcall.}) =
  template execute(cmd) =
    curCaasCmd = cmd
    processCmdLine(passCmd2, cmd)
    action()
    gDirtyBufferIdx = 0
    gDirtyOriginalIdx = 0
    gErrorCounter = 0

  let typ = getConfigVar("server.type")
  case typ
  of "stdin":
    while true:
      var line = stdin.readLine.string
      if line == "quit": quit()
      execute line
      echo ""
      flushFile(stdout)

  of "tcp", "":
    when useCaas:
      var server = socket()
      if server == invalidSocket: osError(osLastError())
      let p = getConfigVar("server.port")
      let port = if p.len > 0: parseInt(p).TPort else: 6000.TPort
      server.bindAddr(port, getConfigVar("server.address"))
      var inp = "".TaintedString
      server.listen()
      new(stdoutSocket)
      while true:
        accept(server, stdoutSocket)
        stdoutSocket.readLine(inp)
        execute inp.string
        stdoutSocket.send("\c\L")
        stdoutSocket.close()
    else:
      quit "server.type not supported; compiler built without caas support"
  else:
    echo "Invalid server.type:", typ
    quit 1
