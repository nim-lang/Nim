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
    {.link: "../icons/nim.res".}
  else:
    {.link: "../icons/nim_icon.o".}

when defined(amd64) and defined(windows) and defined(vcc):
  {.link: "../icons/nim-amd64-windows-vcc.res".}
when defined(i386) and defined(windows) and defined(vcc):
  {.link: "../icons/nim-i386-windows-vcc.res".}

import
  commands, lexer, condsyms, options, msgs, nversion, nimconf, ropes,
  extccomp, strutils, os, osproc, platform, main, parseopt,
  scriptconfig, idents, modulegraphs, lineinfos, cmdlinehelper,
  pathutils

include nodejs

when hasTinyCBackend:
  import tccgen

when defined(profiler) or defined(memProfiler):
  {.hint: "Profiling support is turned on!".}
  import nimprof

proc prependCurDir(f: AbsoluteFile): AbsoluteFile =
  when defined(unix):
    if os.isAbsolute(f.string): result = f
    else: result = AbsoluteFile("./" & f.string)
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
    if {optRun, optWasNimscript} * config.globalOptions == {} and
        config.arguments.len > 0 and config.command.normalize notin ["run", "e"]:
      rawMessage(config, errGenerated, errArgsNeedRunOption)

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: processCmdLine,
    mainCommand: mainCommand
  )
  self.initDefinesProg(conf, "nim_compiler")
  if paramCount() == 0:
    writeCommandLineUsage(conf)
    return

  self.processCmdLineAndProjectPath(conf)
  if not self.loadConfigsAndRunMainCommand(cache, conf): return
  if optHints in conf.options and hintGCStats in conf.notes: echo(GC_getStatistics())
  #echo(GC_getStatistics())
  if conf.errorCounter != 0: return
  when hasTinyCBackend:
    if conf.cmd == cmdRun:
      tccgen.run(conf.arguments)
  if optRun in conf.globalOptions:
    var ex = quoteShell conf.absOutFile
    if conf.cmd == cmdCompileToJS:
      execExternalProgram(conf, findNodeJs() & " " & ex & ' ' & conf.arguments)
    else:
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
