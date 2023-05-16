#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import compiler/renderer
import tables
import times

import globals
import utils
import emacs/emacs
import execution
import repl

import communication
import consts
import parsing
## Nimsuggest is a tool that helps to give editors IDE like capabilities.

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}

import strutils, os, parseopt,  net 
# Do NOT import suggest. It will lead to weird bugs with
# suggestionResultHook, because suggest.nim is included by sigmatch.
# So we import that one instead.

import compiler/[options, commands, modules, passes, passaux, msgs, idents, modulegraphs, lineinfos, cmdlinehelper, pathutils, condsyms]
import types

when defined(nimPreviewSlimSystem):
  import std/typedthreads

when defined(windows):
  import winlean
else:
  import posix





proc execCmd(cmdLineString: string; graph: ModuleGraph; cachedMsgs: CachedMsgs) =
  let conf = graph.config

  template sentinel() =
    # send sentinel for the input reading thread:
    results.send(Suggest(section: ideNone))

  template toggle(sw) =
    if sw in conf.globalOptions:
      excl(conf.globalOptions, sw)
    else:
      incl(conf.globalOptions, sw)
    sentinel()
    return

  template err() =
    echo Help
    sentinel()
    return
  let cmd=parseCommandLine(cmdLineString,string conf.projectFull)
  ##If we can't parse an ideCmd then it's either a nimsuggest command or grabage 
  if cmd.ideCmd==ideNone:
    case cmd.ideCmdString: 
    of "quit":
      sentinel()
      quit()
    of "debug": toggle optIdeDebug
    of "terse": toggle optIdeTerse
    else: err()
  conf.ideCmd=cmd.ideCmd


  if cmd.ideCmd == ideKnown:
    results.send(Suggest(section: ideKnown, quality: ord(fileInfoKnown(conf,  AbsoluteFile cmd.file))))
  elif cmd.ideCmd == ideProject:
    results.send(Suggest(section: ideProject, filePath: string conf.projectFull))
  else:
    if cmd.ideCmd == ideChk:
      for cm in cachedMsgs: errorHook(conf, cm.info, cm.msg, cm.sev)
    execute(cmd, graph)
  sentinel()


proc mainThread(graph: ModuleGraph) =
  ## The main thread that recieves input from external sources and executes nimsuggest commands

  let conf = graph.config
  myLog "searchPaths: "
  for it in conf.searchPaths:
    myLog("  " & it.string)

  proc wrHook(line: string) {.closure.} =
    if gMode == mepc:
      if gLogging: log(line)
    else:
      writelnToChannel(line)

  conf.writelnHook = wrHook
  conf.suggestionResultHook = sugResultHook
  graph.doStopCompile = proc (): bool = requests.peek() > 0
  var idle = 0
  var cachedMsgs: CachedMsgs = @[]
  while true:
    let (hasData, req) = requests.tryRecv()
    if hasData:
      conf.writelnHook = wrHook
      conf.suggestionResultHook = sugResultHook
      execCmd(req, graph, cachedMsgs)
      idle = 0
    else:
      os.sleep 250
      idle += 1
    if idle == 20 and gRefresh and conf.suggestVersion != 3:
      # we use some nimsuggest activity to enable a lazy recompile:
      conf.ideCmd = ideChk
      conf.writelnHook = proc (s: string) = discard
      cachedMsgs.setLen 0
      conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
        cachedMsgs.add(CachedMsg(info: info, msg: msg, sev: sev))
      conf.suggestionResultHook = proc (s: Suggest) = discard
      recompileFullProject(graph)

var
  inputThread: Thread[ThreadParams]

proc mainCommand(graph: ModuleGraph) =
  ## Orchestrates running interactions with the user.
  ## Starts the requests and results channels the user will use to communicate
  ## Then loads up the main thread that will handle the requests
  let conf = graph.config
  clearPasses(graph)
  registerPass graph, verbosePass
  registerPass graph, semPass
  conf.setCmd cmdIdeTools
  defineSymbol(conf.symbols, $conf.backend)
  wantMainModule(conf)

  if not fileExists(conf.projectFull):
    quit "cannot find file: " & conf.projectFull.string

  add(conf.searchPaths, conf.libpath)

  conf.setErrorMaxHighMaybe # honor --errorMax even if it may not make sense here
  # do not print errors, but log them
  conf.writelnHook = proc (msg: string) = discard

  if graph.config.suggestVersion == 3:
    graph.config.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
      let suggest = Suggest(section: ideChk, filePath: toFullPath(conf, info),
        line: toLinenumber(info), column: toColumn(info), doc: msg, forth: $sev)
      graph.suggestErrors.mgetOrPut(info.fileIndex, @[]).add suggest

  # compile the project before showing any input so that we already
  # can answer questions right away:
  benchmark "Initial compilation":
    compileProject(graph)

  open(requests)
  open(results)

  case gMode
  of mstdin: createThread(inputThread, replStdin, (gPort, gAddress))
  of mtcp: createThread(inputThread, replTcp, (gPort, gAddress))
  of mepc: createThread(inputThread, replEpc, (gPort, gAddress))
  of mcmdsug: createThread(inputThread, replCmdline,
                            (gPort, "sug \"" & conf.projectFull.string & "\":" & gAddress))
  of mcmdcon: createThread(inputThread, replCmdline,
                            (gPort, "con \"" & conf.projectFull.string & "\":" & gAddress))
  mainThread(graph)
  joinThread(inputThread)
  close(requests)
  close(results)

proc processCmdLine*(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var findProject = false
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      case p.key.normalize
      of "help", "h":
        stdout.writeLine(Usage)
        quit()
      of "autobind":
        gMode = mtcp
        gAutoBind = true
      of "port":
        gPort = parseInt(p.val).Port
        gMode = mtcp
      of "address":
        gAddress = p.val
        gMode = mtcp
      of "stdin": gMode = mstdin
      of "cmdsug":
        gMode = mcmdsug
        gAddress = p.val
        incl(conf.globalOptions, optIdeDebug)
      of "cmdcon":
        gMode = mcmdcon
        gAddress = p.val
        incl(conf.globalOptions, optIdeDebug)
      of "epc":
        gMode = mepc
        conf.verbosity = 0          # Port number gotta be first.
      of "debug": incl(conf.globalOptions, optIdeDebug)
      of "v1": conf.suggestVersion = 1
      of "v2": conf.suggestVersion = 0
      of "v3": conf.suggestVersion = 3
      of "tester":
        gMode = mstdin
        gEmitEof = true
        gRefresh = false
      of "log": gLogging = true
      of "refresh":
        if p.val.len > 0:
          gRefresh = parseBool(p.val)
        else:
          gRefresh = true
      of "maxresults":
        conf.suggestMaxResults = parseInt(p.val)
      of "find":
        findProject = true
      else: processSwitch(pass, p, conf)
    of cmdArgument:
      let a = unixToNativePath(p.key)
      if dirExists(a) and not fileExists(a.addFileExt("nim")):
        conf.projectName = findProjectNimFile(conf, a)
        # don't make it worse, report the error the old way:
        if conf.projectName.len == 0: conf.projectName = a
      else:
        if findProject:
          conf.projectName = findProjectNimFile(conf, a.parentDir())
          if conf.projectName.len == 0:
            conf.projectName = a
        else:
          conf.projectName = a
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  let self = NimProg(
    suggestMode: true,
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "nimsuggest")

  if paramCount() == 0:
    stdout.writeLine(Usage)
    return

  self.processCmdLineAndProjectPath(conf)

  if gMode != mstdin:
    conf.writelnHook = proc (msg: string) = discard
  # Find Nim's prefix dir.
  let binaryPath = findExe("nim")
  if binaryPath == "":
    raise newException(IOError,
        "Cannot find Nim standard library: Nim compiler not in PATH")
  conf.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
  if not dirExists(conf.prefixDir / RelativeDir"lib"):
    conf.prefixDir = AbsoluteDir""

  #msgs.writelnHook = proc (line: string) = log(line)
  myLog("START " & conf.projectFull.string)

  var graph = newModuleGraph(cache, conf)
  if self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    mainCommand(graph)

when isMainModule:
  handleCmdLine(newIdentCache(), newConfigRef())
else:
 import testInterface
 export testInterface