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
  sockets,
  times, commands, options, msgs, nimconf,
  extccomp, strutils, os, platform, main, parseopt

# We cache modules and the dependency graph. However, we don't check for
# file changes but expect the client to tell us about them, otherwise the
# repeated CRC calculations may turn out to be too slow.

var 
  arguments: string = ""      # the arguments to be passed to the program that
                              # should be run

proc ProcessCmdLine(pass: TCmdLinePass, cmd: string) = 
  # XXX remove duplication with nimrod.nim
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
  while true: 
    parseopt.next(p)
    case p.kind
    of cmdEnd: break 
    of cmdLongOption, cmdShortOption: 
      # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
      # we fix this here
      var bracketLe = strutils.find(p.key, '[')
      if bracketLe >= 0: 
        var key = substr(p.key, 0, bracketLe - 1)
        var val = substr(p.key, bracketLe + 1) & ':' & p.val
        ProcessSwitch(key, val, pass, gCmdLineInfo)
      else: 
        ProcessSwitch(p.key, p.val, pass, gCmdLineInfo)
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
    if optRun notin gGlobalOptions and arguments != "":
      rawMessage(errArgsNeedRunOption, [])

proc serve*(action: proc (){.nimcall.}) =
  var server = Socket()
  let p = getConfigVar("server.port")
  let port = if p.len > 0: parseInt(p).TPort else: 6000.TPort
  server.bindAddr(port, getConfigVar("server.address"))
  var inp = "".TaintedString
  server.listen()
  while true:
    accept(server, stdoutSocket)
    discard stdoutSocket.recvLine(inp)
    processCmdLine(passCmd2, inp.string)
    action()
    stdoutSocket.send("\c\L")
