## Helpers for binaries that use compiler passes, eg: nim, nimsuggest, nimfix

# TODO: nimfix should use this; currently out of sync

import
  compiler/[options, idents, nimconf, scriptconfig, extccomp, commands, msgs, lineinfos, modulegraphs, condsyms],
  std/os

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

proc loadConfigsAndRunMainCommand*(self: NimProg, cache: IdentCache; conf: ConfigRef): bool =
  loadConfigs(DefaultConfig, cache, conf) # load all config files
  if self.suggestMode:
    conf.command = "nimsuggest"

  proc runNimScriptIfExists(path: string)=
    if fileExists(path):
      runNimScript(cache, path, freshDefines = false, conf)

  # Caution: make sure this stays in sync with `loadConfigs`
  if optSkipSystemConfigFile notin conf.globalOptions:
    runNimScriptIfExists(getSystemConfigPath(conf, DefaultConfigNims))

  if optSkipUserConfigFile notin conf.globalOptions:
    runNimScriptIfExists(getUserConfigPath(DefaultConfigNims))

  if optSkipParentConfigFiles notin conf.globalOptions:
    for dir in parentDirs(conf.projectPath, fromRoot = true, inclusive = false):
      runNimScriptIfExists(dir / DefaultConfigNims)

  if optSkipProjConfigFile notin conf.globalOptions:
    runNimScriptIfExists(conf.projectPath / DefaultConfigNims)
  block:
    let scriptFile = conf.projectFull.changeFileExt("nims")
    if not self.suggestMode:
      runNimScriptIfExists(scriptFile)
      # 'nim foo.nims' means to just run the NimScript file and do nothing more:
      if fileExists(scriptFile) and scriptFile.cmpPaths(conf.projectFull) == 0:
        return false
    else:
      if scriptFile.cmpPaths(conf.projectFull) != 0:
        runNimScriptIfExists(scriptFile)
      else:
        # 'nimsuggest foo.nims' means to just auto-complete the NimScript file
        discard

  # now process command line arguments again, because some options in the
  # command line can overwite the config file's settings
  extccomp.initVars(conf)
  self.processCmdLine(passCmd2, "", conf)
  if conf.command == "":
    rawMessage(conf, errGenerated, "command missing")

  let graph = newModuleGraph(cache, conf)
  graph.suggestMode = self.suggestMode
  self.mainCommand(graph)
  return true
