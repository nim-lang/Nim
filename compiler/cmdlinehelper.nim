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
  options, idents, nimconf, scriptconfig, extccomp, commands, msgs,
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
  #loadConfigs(DefaultConfig, cache, conf) # load all config files
  startConfigs()

  if self.suggestMode:
    conf.command = "nimsuggest"

  template runNimScriptIfExists(path: AbsoluteFile) =
    let p = path # eval once
    if fileExists(p):
      runNimScript(cache, p, freshDefines = false, conf)

  # Caution: make sure this stays in sync with `loadConfigs`
  if optSkipSystemConfigFile notin conf.globalOptions:
    readConfigFile(getSystemConfigPath(conf, DefaultConfig))
    runNimScriptIfExists(getSystemConfigPath(conf, DefaultConfigNims))

  if optSkipUserConfigFile notin conf.globalOptions:
    readConfigFile(getUserConfigPath(DefaultConfig))
    runNimScriptIfExists(getUserConfigPath(DefaultConfigNims))

  if optSkipParentConfigFiles notin conf.globalOptions:
    for dir in parentDirs(conf.projectPath.string, fromRoot = true, inclusive = false):
      readConfigFile(AbsoluteDir(dir) / DefaultConfig)
      runNimScriptIfExists(AbsoluteDir(dir) / DefaultConfigNims)

  if optSkipProjConfigFile notin conf.globalOptions:
    let pd = if not conf.projectPath.isEmpty: conf.projectPath else: AbsoluteDir(getCurrentDir())
    readConfigFile(pd / DefaultConfig)
    if conf.projectName.len != 0:
      # new project wide config file:
      var projectConfig = changeFileExt(conf.projectFull, "nimcfg")
      if not fileExists(projectConfig):
        projectConfig = changeFileExt(conf.projectFull, "nim.cfg")
      readConfigFile(projectConfig)

    runNimScriptIfExists(conf.projectPath / DefaultConfigNims)

  let scriptFile = conf.projectFull.changeFileExt("nims")
  result = true
  if not self.suggestMode:
    runNimScriptIfExists(scriptFile)
    # 'nim foo.nims' means to just run the NimScript file and do nothing more:
    if fileExists(scriptFile) and scriptFile == conf.projectFull:
      if conf.command == "":
        conf.command = "e"
        result = false
      elif conf.command.normalize == "e":
        result = false
  else:
    if scriptFile != conf.projectFull:
      runNimScriptIfExists(scriptFile)
    else:
      # 'nimsuggest foo.nims' means to just auto-complete the NimScript file
      discard

  if result:
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

  endConfigs()
