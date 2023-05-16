import compiler/renderer
import strformat
import algorithm
import tables
import std/sha1
import times

import v3/v3
import globals
import utils
import execution

import communication
import types
## Nimsuggest is a tool that helps to give editors IDE like capabilities.

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}

const nimsuggest=true
import strutils, os, parseopt, parseutils, sequtils, net, rdstdin, sexp
import compiler/ [options, commands, modules, passes, passaux, msgs,
  sigmatch, ast,
  idents, modulegraphs, prefixmatches, lineinfos, cmdlinehelper,
  pathutils, condsyms, syntaxes]

export Suggest
export IdeCmd
export AbsoluteFile
type NimSuggest* = ref object
  graph: ModuleGraph
  idle: int
  cachedMsgs: CachedMsgs

proc initNimSuggest*(project: string, nimPath: string = ""): NimSuggest =
  var retval: ModuleGraph
  proc mockCommand(graph: ModuleGraph) =
    retval = graph
    let conf = graph.config
    conf.setCmd cmdIdeTools
    defineSymbol(conf.symbols, $conf.backend)
    clearPasses(graph)
    registerPass graph, verbosePass
    registerPass graph, semPass

    wantMainModule(conf)

    if not fileExists(conf.projectFull):
      quit "cannot find file: " & conf.projectFull.string

    add(conf.searchPaths, conf.libpath)

    conf.setErrorMaxHighMaybe
    # do not print errors, but log them
    conf.writelnHook = myLog
    conf.structuredErrorHook = nil

    # compile the project before showing any input so that we already
    # can answer questions right away:
    compileProject(graph)


  proc mockCmdLine(pass: TCmdLinePass, cmd: string; conf: ConfigRef) =
    conf.suggestVersion = 0
    let a = unixToNativePath(project)
    if dirExists(a) and not fileExists(a.addFileExt("nim")):
      conf.projectName = findProjectNimFile(conf, a)
      # don't make it worse, report the error the old way:
      if conf.projectName.len == 0: conf.projectName = a
    else:
      conf.projectName = a
        # if processArgument(pass, p, argsCount): break
  let
    cache = newIdentCache()
    conf = newConfigRef()
    self = NimProg(
      suggestMode: true,
      processCmdLine: mockCmdLine
    )
  self.initDefinesProg(conf, "nimsuggest")

  self.processCmdLineAndProjectPath(conf)

  if gMode != mstdin:
    conf.writelnHook = proc (msg: string) = discard
  # Find Nim's prefix dir.
  if nimPath == "":
    let binaryPath = findExe("nim")
    if binaryPath == "":
      raise newException(IOError,
          "Cannot find Nim standard library: Nim compiler not in PATH")
    conf.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
    if not dirExists(conf.prefixDir / RelativeDir"lib"):
      conf.prefixDir = AbsoluteDir""
  else:
    conf.prefixDir = AbsoluteDir nimPath

  #msgs.writelnHook = proc (line: string) = log(line)
  myLog("START " & conf.projectFull.string)

  var graph = newModuleGraph(cache, conf)
  if self.loadConfigsAndProcessCmdLine(cache, conf, graph):
    mockCommand(graph)
  if gLogging:
    myLog("Search paths:")
    for it in conf.searchPaths:
      myLog(" " & it.string)

  retval.doStopCompile = proc (): bool = false
  return NimSuggest(graph: retval, idle: 0, cachedMsgs: @[])

proc runCmd*(nimsuggest: NimSuggest, cmd: IdeCmd, file, dirtyfile: AbsoluteFile, line, col: int): seq[Suggest] =
  var retval: seq[Suggest] = @[]
  let conf = nimsuggest.graph.config
  conf.ideCmd = cmd
  conf.writelnHook = proc (line: string) =
    retval.add(Suggest(section: ideMsg, doc: line))
  conf.suggestionResultHook = proc (s: Suggest) =
    retval.add(s)
  conf.writelnHook = proc (s: string) =
    stderr.write s & "\n"
  if conf.ideCmd == ideKnown:
    retval.add(Suggest(section: ideKnown, quality: ord(fileInfoKnown(conf, file))))
  elif conf.ideCmd == ideProject:
    retval.add(Suggest(section: ideProject, filePath: string conf.projectFull))
  else:
    if conf.ideCmd == ideChk:
      for cm in nimsuggest.cachedMsgs: errorHook(conf, cm.info, cm.msg, cm.sev)
    if conf.ideCmd == ideChk:
      conf.structuredErrorHook = proc (conf: ConfigRef; info: TLineInfo; msg: string; sev: Severity) =
        retval.add(Suggest(section: ideChk, filePath: toFullPath(conf, info),
          line: toLinenumber(info), column: toColumn(info), doc: msg,
          forth: $sev))

    else:
      conf.structuredErrorHook = nil
    executeNoHooks(conf.ideCmd, file, dirtyfile, line, col, nimsuggest.graph)
  return retval

