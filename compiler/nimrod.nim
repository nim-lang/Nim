#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
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
  commands, lexer, condsyms, options, msgs, nversion, nimconf, ropes,
  extccomp, strutils, os, osproc, platform, main, parseopt, service

when hasTinyCBackend:
  import tccgen

when defined(profiler) or defined(memProfiler):
  {.hint: "Profiling support is turned on!".}
  import nimprof

proc prependCurDir(f: string): string =
  when defined(unix):
    if os.isAbsolute(f): result = f
    else: result = "./" & f
  else:
    result = f

proc HandleCmdLine() =
  if paramCount() == 0:
    writeCommandLineUsage()
  else:
    # Process command line arguments:
    ProcessCmdLine(passCmd1, "")
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
    ProcessCmdLine(passCmd2, "")
    MainCommand()
    if gVerbosity >= 2: echo(GC_getStatistics())
    #echo(GC_getStatistics())
    if msgs.gErrorCounter == 0:
      when hasTinyCBackend:
        if gCmd == cmdRun:
          tccgen.run()
      if optRun in gGlobalOptions:
        if gCmd == cmdCompileToJS:
          var ex = quoteShell(
            completeCFilePath(changeFileExt(gProjectFull, "js").prependCurDir))
          execExternalProgram("node " & ex & ' ' & service.arguments)
        else:
          var binPath: string
          if options.outFile.len > 0:
            # If the user specified an outFile path, use that directly.
            binPath = options.outFile.prependCurDir
          else:
            # Figure out ourselves a valid binary name.
            binPath = changeFileExt(gProjectFull, exeExt).prependCurDir
          var ex = quoteShell(binPath)
          execExternalProgram(ex & ' ' & service.arguments)

when defined(GC_setMaxPause):
  GC_setMaxPause 2_000

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  # the new correct mark&sweet collector is too slow :-/
  GC_disableMarkAndSweep()
condsyms.InitDefines()

when not defined(selftest):
  HandleCmdLine()
  quit(int8(msgs.gErrorCounter > 0))
