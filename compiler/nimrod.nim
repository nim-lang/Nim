#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) and defined(windows):
  when defined(x86):
    {.link: "icons/nimrod.res".}
  else:
    {.link: "icons/nimrod_icon.o".}

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
    if gProjectName != "":
      try:
        gProjectFull = canonicalizePath(gProjectName)
      except EOS:
        gProjectFull = gProjectName
      var p = splitFile(gProjectFull)
      gProjectPath = p.dir
      gProjectName = p.name
    else:
      gProjectPath = getCurrentDir()
    LoadConfigs(DefaultConfig) # load all config files
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars()
    ProcessCmdLine(passCmd2)
    MainCommand()
    if gVerbosity >= 2: echo(GC_getStatistics())
    #echo(GC_getStatistics())
    if msgs.gErrorCounter == 0:
      when hasTinyCBackend:
        if gCmd == cmdRun:
          tccgen.run()
      if gCmd notin {cmdInterpret, cmdRun}:
        rawMessage(hintSuccessX, [$gLinesCompiled,
                   formatFloat(epochTime() - start, ffDecimal, 3),
                   formatSize(getTotalMem())])
      if optRun in gGlobalOptions:
        if gCmd == cmdCompileToEcmaScript:
          var ex = quoteIfContainsWhite(
            completeCFilePath(changeFileExt(gProjectFull, "js").prependCurDir))
          execExternalProgram("node " & ex & ' ' & arguments)
        else:
          var ex = quoteIfContainsWhite(
            changeFileExt(gProjectFull, exeExt).prependCurDir)
          execExternalProgram(ex & ' ' & arguments)

#GC_disableMarkAndSweep()

when defined(GC_setMaxPause):
  GC_setMaxPause 2_000
condsyms.InitDefines()
HandleCmdLine()
quit(options.gExitcode)
