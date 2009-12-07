#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import 
  times, commands, scanner, condsyms, options, msgs, nversion, nimconf, ropes, 
  extccomp, strutils, os, platform, main, parseopt

var 
  arguments: string = ""      # the arguments to be passed to the program that
                              # should be run
  cmdLineInfo: TLineInfo

proc ProcessCmdLine(pass: TCmdLinePass, command, filename: var string) = 
  var 
    p: TOptParser
    bracketLe: int
    key, val: string
  p = parseopt.init()
  while true: 
    parseopt.next(p)
    case p.kind
    of cmdEnd: 
      break 
    of cmdLongOption, cmdShortOption: 
      # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
      # we fix this here
      bracketLe = strutils.find(p.key, '[')
      if bracketLe >= 0: 
        key = copy(p.key, 0, bracketLe - 1)
        val = copy(p.key, bracketLe + 1) & ':' & p.val
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
    arguments = getRestOfCommandLine(p)
    if not (optRun in gGlobalOptions) and (arguments != ""): 
      rawMessage(errArgsNeedRunOption)
  
proc HandleCmdLine() = 
  var 
    command, filename, prog: string
    start: TTime
  start = getTime()
  if paramCount() == 0: 
    writeCommandLineUsage()
  else: 
    # Process command line arguments:
    command = ""
    filename = ""
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
    if (gCmd != cmdInterpret) and (msgs.gErrorCounter == 0): 
      rawMessage(hintSuccessX, [$(gLinesCompiled), $(getTime() - start)])
    if optRun in gGlobalOptions: 
      when defined(unix): 
        prog = "./" & quoteIfContainsWhite(changeFileExt(filename, ""))
      else: 
        prog = quoteIfContainsWhite(changeFileExt(filename, ""))
      execExternalProgram(prog & ' ' & arguments)

#{@emit
#  GC_disableMarkAndSweep();
#}

cmdLineInfo = newLineInfo("command line", - 1, - 1)
condsyms.InitDefines()
HandleCmdLine()
quit(options.gExitcode)