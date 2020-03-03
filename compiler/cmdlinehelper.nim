#
#
#           The Nim Compiler
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Helpers for binaries that use compiler passes, eg: nim, nimsuggest, nimfix

import
  options, idents, nimconf, extccomp, commands, msgs,
  lineinfos, modulegraphs, condsyms, os, pathutils

from strutils import normalize

type
  NimProg* = ref object
    suggestMode*: bool
    supportsStdinFile*: bool
    processCmdLine*: proc(pass: TCmdLinePass, cmd: string; config: ConfigRef)
    mainCommand*: proc(graph: ModuleGraph)

proc initDefinesProg*(self: NimProg, conf: ConfigRef, name: string) =
  condsyms.initDefines(conf.symbols)
  defineSymbol conf.symbols, name

proc processCmdLineAndProjectPath*(self: NimProg, conf: ConfigRef) =
  self.processCmdLine(passCmd1, "", conf)
  if self.supportsStdinFile and conf.projectName == "-":
    handleStdinInput(conf)
  elif conf.projectName != "":
    try:
      conf.projectFull = canonicalizePath(conf, AbsoluteFile conf.projectName)
    except OSError:
      conf.projectFull = AbsoluteFile conf.projectName
    let p = splitFile(conf.projectFull)
    let dir = if p.dir.isEmpty: AbsoluteDir getCurrentDir() else: p.dir
    conf.projectPath = AbsoluteDir canonicalizePath(conf, AbsoluteFile dir)
    conf.projectName = p.name
  else:
    conf.projectPath = AbsoluteDir canonicalizePath(conf, AbsoluteFile getCurrentDir())

proc loadConfigsAndRunMainCommand*(self: NimProg, cache: IdentCache; conf: ConfigRef): bool =
  if self.suggestMode:
    conf.command = "nimsuggest"
  loadConfigs(DefaultConfig, cache, conf) # load all config files

  block:
    let scriptFile = conf.projectFull.changeFileExt("nims")
    if not self.suggestMode:
      # 'nim foo.nims' means to just run the NimScript file and do nothing more:
      if fileExists(scriptFile) and scriptFile == conf.projectFull:
        if conf.command == "":
          conf.command = "e"
          return false
        elif conf.command.normalize == "e":
          return false

  # now process command line arguments again, because some options in the
  # command line can overwrite the config file's settings
  extccomp.initVars(conf)
  # XXX This is hacky. We need to find a better way.
  case conf.command
  of "cpp", "compiletocpp":
    conf.cmd = cmdCompileToCpp
  else:
    discard

  self.processCmdLine(passCmd2, "", conf)
  if conf.command == "":
    rawMessage(conf, errGenerated, "command missing")

  let graph = newModuleGraph(cache, conf)
  graph.suggestMode = self.suggestMode
  self.mainCommand(graph)
  return true
