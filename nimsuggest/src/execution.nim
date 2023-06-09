## Handles executing various IdeCmd commands
## Takes the parsed input of a command and performs an operation on the ModuleGraph such as compining the project
import strformat, times, strutils, net

import compiler/[renderer, options, passes, msgs, sigmatch, modulegraphs, lineinfos, pathutils]

import globals, utils, v3/v3, communication, types

#[Quick reference of ideCmds
IdeCon #Show the signature of the function whos parameters the cursor is in
IdeDef #return the definition location of the symbol
IdeSug #suggest completions at cursor
ideUse #Get's a symbols usages. Used for gotoReference
ideDus #Get's a symbols defUsages. As far as i can till it's the same as ideUse
IdeChk #Check a file for errors and warnings (in v3 this checks a file and it's dependencies)
IdeChkFile #V3 command to check a single file for errors without its dependencies
ideMod #Something related to module import suggestions. Not exactly sure if it works or is implimented. Isn't used in either nimlsp or langserver
ideHightlight #Provides hover docs for a partcular line and column
ideOutline #gives a list of the files top level functions and declarations
ideKnown #reports 'true' or 'false' depending on whether the current nimsuggest instance is aware of a file
ideMsg #Not a command to be sent from outside. Just used as a label for responses
ideProject #returns the path of the root file of the project 
ideglobalSymbols #v3: lists all symbols available in the project(up to 100)
ideRecompile #v3: forces a recompile of the whole project
ideChanged #v3: marks a file as dirty when changed 
ideType #v3: trys to get the type at file:line:col position. like hightlight but just for type information
ideDeclaration #v3: trys to find a symbols declaraiton. Often the same as ideDef. These commands are different when searching for a symbol that's defined in a header file
ideExpand #v3: custom lsp command for expanding macros. Unsure if this is actually used 
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


proc executeNoHooks*(cmd: CommandData, graph: ModuleGraph) =
  ##Executes the provided command on the provided graph
  ##Though this doesn't return anything it does call procs which call `suggestResult`
  ##which triggers the suggestionResultHook, or a print statement if no hook is provided

  if graph.config.suggestVersion == 3:
    let command = fmt "cmd = {cmd.ideCmd} {cmd.file}:{cmd.line}:{cmd.col}"
    benchmark command:
      executeNoHooksV3(cmd, graph)
  else:
    executeNoHooksDefault(cmd, graph)

proc execute*(cmd: CommandData, graph: ModuleGraph) =
  if cmd.ideCmd == ideChk:
    graph.config.structuredErrorHook = errorHook
    graph.config.writelnHook = myLog
  else:
    graph.config.structuredErrorHook = nil
    graph.config.writelnHook = myLog
  executeNoHooks(cmd, graph)
