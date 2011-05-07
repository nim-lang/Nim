#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) and defined(windows): 
  {.link: "icons/nimrod.res".}

import 
  times, commands, lexer, condsyms, options, msgs, nversion, nimconf, ropes, 
  extccomp, strutils, os, platform, main, parseopt

when hasTinyCBackend:
  import tccgen

var 
  arguments: string = ""      # the arguments to be passed to the program that
                              # should be run
  cmdLineInfo: TLineInfo

proc ProcessCmdLine(pass: TCmdLinePass, command, filename: var string) = 
  var p = parseopt.initOptParser()
  while true: 
    parseopt.next(p)
    case p.kind
    of cmdEnd: break 
    of cmdLongOption, cmdShortOption: 
      # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
      # we fix this here
      var bracketLe = strutils.find(p.key, '[')
      if bracketLe >= 0: 
        var key = copy(p.key, 0, bracketLe - 1)
        var val = copy(p.key, bracketLe + 1) & ':' & p.val
        ProcessSwitch(key, val, pass, cmdLineInfo)
      else: 
        ProcessSwitch(p.key, p.val, pass, cmdLineInfo)
    of cmdArgument: 
      if command == "": 
        command = p.key
      elif filename == "": 
        filename = unixToNativePath(p.key) # BUGFIX for portable build scripts
        break 
  if pass == passCmd2: 
    arguments = cmdLineRest(p)
    if optRun notin gGlobalOptions and arguments != "": 
      rawMessage(errArgsNeedRunOption, [])
  
proc HandleCmdLine() = 
  var start = epochTime()
  if paramCount() == 0: 
    writeCommandLineUsage()
  else: 
    # Process command line arguments:
    var command = ""
    var filename = ""
    ProcessCmdLine(passCmd1, command, filename)
    if filename != "": options.projectPath = splitFile(filename).dir
    nimconf.LoadConfig(filename) # load the right config file
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars()
    command = ""
    filename = ""
    ProcessCmdLine(passCmd2, command, filename)
    MainCommand(command, filename)
    if gVerbosity >= 2: echo(GC_getStatistics())
    if msgs.gErrorCounter == 0:
      when hasTinyCBackend:
        if gCmd == cmdRun:
          tccgen.run()
      if gCmd notin {cmdInterpret, cmdRun}: 
        rawMessage(hintSuccessX, [$gLinesCompiled, 
                   formatFloat(epochTime() - start, ffDecimal, 3)])
      if optRun in gGlobalOptions: 
        when defined(unix): 
          var prog = "./" & quoteIfContainsWhite(changeFileExt(filename, ""))
        else: 
          var prog = quoteIfContainsWhite(changeFileExt(filename, ""))
        execExternalProgram(prog & ' ' & arguments)

#GC_disableMarkAndSweep()
cmdLineInfo = newLineInfo("command line", -1, -1)
condsyms.InitDefines()
HandleCmdLine()
quit(options.gExitcode)
