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
  commands, options, msgs,
  extccomp, strutils, os, main, parseopt,
  idents, lineinfos, cmdlinehelper,
  pathutils, modulegraphs

from browsers import openDefaultBrowser
from nodejs import findNodeJs
from std/private/browserutils import getHtmlFile, serveJsBrowserLivereload

when hasTinyCBackend:
  import tccgen

when defined(profiler) or defined(memProfiler):
  {.hint: "Profiling support is turned on!".}
  import nimprof

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0

  config.commandLine.setLen 0
    # bugfix: otherwise, config.commandLine ends up duplicated

  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      config.commandLine.add " "
      config.commandLine.addCmdPrefix p.kind
      config.commandLine.add p.key.quoteShell # quoteShell to be future proof
      if p.val.len > 0:
        config.commandLine.add ':'
        config.commandLine.add p.val.quoteShell

      if p.key == "": # `-` was passed to indicate main project is stdin
        p.key = "-"
        if processArgument(pass, p, argsCount, config): break
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      config.commandLine.add " "
      config.commandLine.add p.key.quoteShell
      if processArgument(pass, p, argsCount, config): break
  if pass == passCmd2:
    if {optRun, optWasNimscript} * config.globalOptions == {} and
        config.arguments.len > 0 and config.cmd notin {cmdTcc, cmdNimscript, cmdCrun}:
      rawMessage(config, errGenerated, errArgsNeedRunOption)

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "nim_compiler")
  if paramCount() == 0:
    writeCommandLineUsage(conf)
    return

  self.processCmdLineAndProjectPath(conf)
  var graph = newModuleGraph(cache, conf)
  if not self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    return
  mainCommand(graph)
  if conf.hasHint(hintGCStats): echo(GC_getStatistics())
  #echo(GC_getStatistics())
  if conf.errorCounter != 0: return
  when hasTinyCBackend:
    if conf.cmd == cmdTcc:
      tccgen.run(conf, conf.arguments)
  if optRun in conf.globalOptions:
    let output = conf.absOutFile
    proc execProg(cmdPrefix = "") =
      # No space after `cmdPrefix` otherwise on windows you'd get a cryptic: `The parameter is incorrect`
      execExternalProgram(conf, cmdPrefix & output.quoteShell & ' ' & conf.arguments)
    case conf.cmd
    of cmdBackends, cmdTcc:
      case conf.backend
      of backendC, backendCpp, backendObjc: execProg()
      of backendJs:
        if conf.useBrowser:
          let fileJs = $output
          let fileHtml = getHtmlFile($conf.nimcacheDir, fileJs)
          serveJsBrowserLivereload(fileJs, fileHtml, port = conf.livereloadPort)
          openDefaultBrowser(fileHtml)
        else:
          # D20210217T215950:here this flag is needed for node < v15.0.0, otherwise
          # tasyncjs_fail` would fail, refs https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode
          execProg(findNodeJs() & " --unhandled-rejections=strict ")
      else: doAssert false, $conf.backend
    of cmdDocLike, cmdRst2html, cmdRst2tex: # bugfix(cmdRst2tex was missing)
      if conf.arguments.len > 0:
        # reserved for future use
        rawMessage(conf, errGenerated, "'$1 cannot handle arguments" % [$conf.cmd])
      openDefaultBrowser($output)
    else:
      # support as needed
      rawMessage(conf, errGenerated, "'$1 cannot handle --run" % [$conf.cmd])

when declared(GC_setMaxPause):
  GC_setMaxPause 2_000

when compileOption("gc", "refc"):
  # the new correct mark&sweet collector is too slow :-/
  GC_disableMarkAndSweep()

when not defined(selftest):
  let conf = newConfigRef()
  handleCmdLine(newIdentCache(), conf)
  when declared(GC_setMaxPause):
    echo GC_getStatistics()
  msgQuit(int8(conf.errorCounter > 0))
