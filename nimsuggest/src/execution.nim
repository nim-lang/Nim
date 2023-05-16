## Handles executing various IdeCmd commands
## Takes the parsed input of a command and performs an operation on the ModuleGraph such as compining the project
import strformat, times, strutils, net

import compiler/[renerer, options, passes, msgs, sigmatch, modulegraphs, lineinfos, pathutils]

import globals
import utils
import v3/v3
import communication
import types

#[Quick reference of ideCmds
IdeUse #find useages of symbol at cursor
IdeSug #suggest completions at cursor
IdeCon #Show the signature of the function whos parameters the cursor is in
IdeDef #return the definition location of the symbol
]#

proc executeNoHooksDefault(cmd: CommandData, graph: ModuleGraph) =

  let conf = graph.config
  let suggestVersion = conf.suggestVersion
  #This exposes all it's props as variables in the current scope
  destructure cmd

  myLog("cmd: " & $cmd & ", file: " & file.string &
        ", dirtyFile: " & dirtyfile.string &
        "[" & $line & ":" & $col & "]")
  conf.ideCmd = ideCmd
  #TODO: why do we need to reset when we get a use?
  if ideCmd == ideUse and suggestVersion != 0:
    graph.resetAllModules()

  #set the current location and  file, or dirty file if it exists
  var isKnownFile = true
  let dirtyIdx = fileInfoIdx(conf, file, isKnownFile)
  if not dirtyfile.isEmpty: msgs.setDirtyFile(conf, dirtyIdx, dirtyfile)
  else: msgs.setDirtyFile(conf, dirtyIdx, AbsoluteFile"")
  conf.m.trackPos = newLineInfo(dirtyIdx, line, col)
  conf.m.trackPosAttached = false
  conf.errorCounter = 0

  if suggestVersion == 1:
    graph.usageSym = nil

  if not isKnownFile:
    graph.compileProject(dirtyIdx)
  if suggestVersion == 0 and ideCmd in {ideUse, ideDus} and dirtyfile.isEmpty:
    discard "no need to recompile anything"
  else:
    #This then trys to compile the parent project of the file
    #TODO: Why do we always recompile if we are not using version 0?
    let modIdx = graph.parentModule(dirtyIdx)
    graph.markDirty dirtyIdx
    graph.markClientsDirty dirtyIdx
    if ideCmd != ideMod:
      if isKnownFile:
        graph.compileProject(modIdx)
  if ideCmd in {ideUse, ideDus}:
    let u = if suggestVersion != 1: graph.symFromInfo(conf.m.trackPos) else: graph.usageSym
    if u != nil:
      listUsages(graph, u)
    else:
      localError(conf, conf.m.trackPos, "found no symbol at this position " & (conf $
          conf.m.trackPos))


proc executeNoHooks(cmd: CommandData, graph: ModuleGraph) =
  ##Executes the provided command on the provided graph
  ##Though this doesn't return anything it does call procs which call `suggestResult`
  ##which triggers the suggestionResultHook, or a print statement if no hook is provided

  if graph.config.suggestVersion == 3:
    let command = fmt "cmd = {cmd.ideCmd} {cmd.file}:{cmd.line}:{cmd.col}"
    benchmark command:
      executeNoHooksV3(cmd, graph)
  else:
    executeNoHooksDefault(cmd, graph)
# proc executeNoHooks*(cmd:CommandData, graph: ModuleGraph) =
#   cmd.tag=""
#   executeNoHooks(cmd:CommandData, graph)

proc execute*(cmd: CommandData, graph: ModuleGraph) =
  if cmd.ideCmd == ideChk:
    graph.config.structuredErrorHook = errorHook
    graph.config.writelnHook = myLog
  else:
    graph.config.structuredErrorHook = nil
    graph.config.writelnHook = myLog
  executeNoHooks(cmd, graph)
