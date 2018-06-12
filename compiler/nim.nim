#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) and defined(windows):
  when defined(x86):
    {.link: "icons/nim.res".}
  else:
    {.link: "icons/nim_icon.o".}

when defined(amd64) and defined(windows) and defined(vcc):
  {.link: "icons/nim-amd64-windows-vcc.res".}
when defined(i386) and defined(windows) and defined(vcc):
  {.link: "icons/nim-i386-windows-vcc.res".}

import
  commands, lexer, condsyms, options, msgs, nversion, nimconf, ropes,
  extccomp, strutils, os, osproc, platform, main, parseopt,
  nodejs, scriptconfig, idents, modulegraphs, lineinfos

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

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongoption, cmdShortOption:
      if p.key == " ":
        p.key = "-"
        if processArgument(pass, p, argsCount, config): break
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      if processArgument(pass, p, argsCount, config): break
  if pass == passCmd2:
    if optRun notin config.globalOptions and config.arguments.len > 0 and config.command.normalize != "run":
      rawMessage(config, errGenerated, errArgsNeedRunOption)

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  condsyms.initDefines(conf.symbols)
  if paramCount() == 0:
    writeCommandLineUsage(conf, conf.helpWritten)
  else:
    # Process command line arguments:
    processCmdLine(passCmd1, "", conf)
    if conf.projectName == "-":
      conf.projectName = "stdinfile"
      conf.projectFull = "stdinfile"
      conf.projectPath = canonicalizePath(conf, getCurrentDir())
      conf.projectIsStdin = true
    elif conf.projectName != "":
      try:
        conf.projectFull = canonicalizePath(conf, conf.projectName)
      except OSError:
        conf.projectFull = conf.projectName
      let p = splitFile(conf.projectFull)
      let dir = if p.dir.len > 0: p.dir else: getCurrentDir()
      conf.projectPath = canonicalizePath(conf, dir)
      conf.projectName = p.name
    else:
      conf.projectPath = canonicalizePath(conf, getCurrentDir())
    loadConfigs(DefaultConfig, cache, conf) # load all config files
    let scriptFile = conf.projectFull.changeFileExt("nims")
    if fileExists(scriptFile):
      runNimScript(cache, scriptFile, freshDefines=false, conf)
      # 'nim foo.nims' means to just run the NimScript file and do nothing more:
      if scriptFile == conf.projectFull: return
    elif fileExists(conf.projectPath / "config.nims"):
      # directory wide NimScript file
      runNimScript(cache, conf.projectPath / "config.nims", freshDefines=false, conf)
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars(conf)
    processCmdLine(passCmd2, "", conf)
    if conf.command == "":
      rawMessage(conf, errGenerated, "command missing")
    mainCommand(newModuleGraph(cache, conf))
    if optHints in conf.options and hintGCStats in conf.notes: echo(GC_getStatistics())
    #echo(GC_getStatistics())
    if conf.errorCounter == 0:
      when hasTinyCBackend:
        if conf.cmd == cmdRun:
          tccgen.run(conf.arguments)
      if optRun in conf.globalOptions:
        if conf.cmd == cmdCompileToJS:
          var ex: string
          if conf.outFile.len > 0:
            ex = conf.outFile.prependCurDir.quoteShell
          else:
            ex = quoteShell(
              completeCFilePath(conf, changeFileExt(conf.projectFull, "js").prependCurDir))
          execExternalProgram(conf, findNodeJs() & " " & ex & ' ' & conf.arguments)
        else:
          var binPath: string
          if conf.outFile.len > 0:
            # If the user specified an outFile path, use that directly.
            binPath = conf.outFile.prependCurDir
          else:
            # Figure out ourselves a valid binary name.
            binPath = changeFileExt(conf.projectFull, ExeExt).prependCurDir
          var ex = quoteShell(binPath)
          execExternalProgram(conf, ex & ' ' & conf.arguments)

when declared(GC_setMaxPause):
  GC_setMaxPause 2_000

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  # the new correct mark&sweet collector is too slow :-/
  GC_disableMarkAndSweep()

when not defined(selftest):
  let conf = newConfigRef()
  handleCmdLine(newIdentCache(), conf)
  when declared(GC_setMaxPause):
    echo GC_getStatistics()
  msgQuit(int8(conf.errorCounter > 0))
