#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) and defined(windows):
  when defined(x86):
    {.link: "icons/nim.res".}
  else:
    {.link: "icons/nim_icon.o".}

import
  commands, lexer, condsyms, options, msgs, nversion, nimconf, ropes,
  extccomp, strutils, os, osproc, platform, main, parseopt, service,
  nodejs

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

proc handleCmdLine() =
  if paramCount() == 0:
    writeCommandLineUsage()
  else:
    # Process command line arguments:
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
    if gVerbosity >= 2: echo(GC_getStatistics())
    #echo(GC_getStatistics())
    if msgs.gErrorCounter == 0:
      when hasTinyCBackend:
        if gCmd == cmdRun:
          tccgen.run(commands.arguments)
      if optRun in gGlobalOptions:
        if gProjectName == "-":
          gProjectFull = "stdinfile"
        if gCmd == cmdCompileToJS:
          var ex: string
          if options.outFile.len > 0:
            ex = options.outFile.prependCurDir.quoteShell
          else:
            ex = quoteShell(
              completeCFilePath(changeFileExt(gProjectFull, "js").prependCurDir))
          execExternalProgram(findNodeJs() & " " & ex & ' ' & commands.arguments)
        else:
          var binPath: string
          if options.outFile.len > 0:
            # If the user specified an outFile path, use that directly.
            binPath = options.outFile.prependCurDir
          else:
            # Figure out ourselves a valid binary name.
            binPath = changeFileExt(gProjectFull, ExeExt).prependCurDir
          var ex = quoteShell(binPath)
          execExternalProgram(ex & ' ' & commands.arguments)

when declared(GC_setMaxPause):
  GC_setMaxPause 2_000

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  # the new correct mark&sweet collector is too slow :-/
  GC_disableMarkAndSweep()
condsyms.initDefines()

when not defined(selftest):
  handleCmdLine()
  msgQuit(int8(msgs.gErrorCounter > 0))
