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

proc ProcessCmdLine(pass: TCmdLinePass) = 
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
        var key = substr(p.key, 0, bracketLe - 1)
        var val = substr(p.key, bracketLe + 1) & ':' & p.val
        ProcessSwitch(key, val, pass, gCmdLineInfo)
      else: 
        ProcessSwitch(p.key, p.val, pass, gCmdLineInfo)
    of cmdArgument: 
      if pass == passCmd1:
        if options.command == "":
          options.command = p.key
        else:
          options.commandArgs.add p.key

          if options.projectName == "":
            options.projectName = unixToNativePath(p.key) # BUGFIX for portable build scripts
          
  if pass == passCmd2: 
    arguments = cmdLineRest(p)
    echo "Setting args to ", arguments
    if optRun notin gGlobalOptions and arguments != "": 
      rawMessage(errArgsNeedRunOption, [])
  
proc prependCurDir(f: string): string =
  when defined(unix):
    if os.isAbsolute(f): result = f
    else: result = "./" & f
  else:
    result = f

proc HandleCmdLine() = 
  var start = epochTime()
  if paramCount() == 0: 
    writeCommandLineUsage()
  else: 
    # Process command line arguments:
    ProcessCmdLine(passCmd1)
    if projectName != "":
      try:
        projectFullPath = expandFilename(projectName)
      except EOS:
        projectFullPath = projectName
      var p = splitFile(projectFullPath)
      projectPath = p.dir
      projectName = p.name
    else:
      projectPath = getCurrentDir()
    LoadConfigs() # load all config files
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars()
    ProcessCmdLine(passCmd2)
    MainCommand()
    if gVerbosity >= 2: echo(GC_getStatistics())
    if msgs.gErrorCounter == 0:
      when hasTinyCBackend:
        if gCmd == cmdRun:
          tccgen.run()
      if gCmd notin {cmdInterpret, cmdRun}: 
        rawMessage(hintSuccessX, [$gLinesCompiled, 
                   formatFloat(epochTime() - start, ffDecimal, 3)])
      if optRun in gGlobalOptions: 
        var ex = quoteIfContainsWhite(
            changeFileExt(projectFullPath, "").prependCurDir)
        execExternalProgram(ex & ' ' & arguments)

#GC_disableMarkAndSweep()
condsyms.InitDefines()
HandleCmdLine()
quit(options.gExitcode)
