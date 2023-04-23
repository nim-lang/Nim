## Handles executing various IdeCmd commands
## Takes the parsed input of a command and performs an operation on the ModuleGraph such as compining the project
import compiler/renderer
import strformat
import times
import setup
import strutils, net
import utils
import v3/v3
import communication
import parsing
import types

import compiler/options
import compiler/passes
import compiler/msgs
import compiler/sigmatch
import compiler/modulegraphs
import compiler/lineinfos
import compiler/pathutils

proc executeNoHooks(cmd:CommandData, graph: ModuleGraph) =

  #This exposes all it's props as variables in the current scope
  destructure cmd
  let conf = graph.config

  if conf.suggestVersion == 3:
    let command = fmt "cmd = {cmd} {file}:{line}:{col}"
    benchmark command:
      executeNoHooksV3(cmd, graph)
    return

  myLog("cmd: " & $cmd & ", file: " & file.string &
        ", dirtyFile: " & dirtyfile.string &
        "[" & $line & ":" & $col & "]")
  conf.ideCmd = ideCmd
  if ideCmd == ideUse and conf.suggestVersion != 0:
    graph.resetAllModules()
  var isKnownFile = true
  let dirtyIdx = fileInfoIdx(conf, file, isKnownFile)

  if not dirtyfile.isEmpty: msgs.setDirtyFile(conf, dirtyIdx, dirtyfile)
  else: msgs.setDirtyFile(conf, dirtyIdx, AbsoluteFile"")

  conf.m.trackPos = newLineInfo(dirtyIdx, line, col)
  conf.m.trackPosAttached = false
  conf.errorCounter = 0
  if conf.suggestVersion == 1:
    graph.usageSym = nil
  if not isKnownFile:
    graph.compileProject(dirtyIdx)
  if conf.suggestVersion == 0 and ideCmd in {ideUse, ideDus} and
      dirtyfile.isEmpty:
    discard "no need to recompile anything"
  else:
    let modIdx = graph.parentModule(dirtyIdx)
    graph.markDirty dirtyIdx
    graph.markClientsDirty dirtyIdx
    if ideCmd != ideMod:
      if isKnownFile:
        graph.compileProject(modIdx)
  if ideCmd in {ideUse, ideDus}:
    let u = if conf.suggestVersion != 1: graph.symFromInfo(conf.m.trackPos) else: graph.usageSym
    if u != nil:
      listUsages(graph, u)
    else:
      localError(conf, conf.m.trackPos, "found no symbol at this position " & (conf $ conf.m.trackPos))

# proc executeNoHooks*(cmd:CommandData, graph: ModuleGraph) =
#   cmd.tag=""
#   executeNoHooks(cmd:CommandData, graph)

proc execute*(cmd:CommandData,graph: ModuleGraph) =
  if cmd.ideCmd == ideChk:
    graph.config.structuredErrorHook = errorHook
    graph.config.writelnHook = myLog
  else:
    graph.config.structuredErrorHook = nil
    graph.config.writelnHook = myLog
  executeNoHooks(cmd, graph)