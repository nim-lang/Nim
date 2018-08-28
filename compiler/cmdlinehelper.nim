## Helpers for binaries that use compiler passes, eg: nim, nimsuggest, nimfix

# TODO: nimfix should use this; currently out of sync

import
  compiler/[options, idents, nimconf, scriptconfig, extccomp, commands, msgs, lineinfos, modulegraphs, condsyms],
  std/os

type ProgBase* = ref object of RootObj
  name*: string
  suggestMode*: bool

method processCmdLine(self: ProgBase, pass: TCmdLinePass, cmd: string; config: ConfigRef) {.base.} =
  doAssert false

method mainCommand(self: ProgBase, graph: ModuleGraph) {.base.} =
  doAssert false

proc initDefinesProg*(self: ProgBase, conf: ConfigRef) =
  condsyms.initDefines(conf.symbols)
  defineSymbol conf.symbols, self.name

proc processCmdLineAndProjectPath*(self: ProgBase, conf: ConfigRef) =
  self.processCmdLine(passCmd1, "", conf)
  if conf.projectName == "-":
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

proc loadConfigsAndRunMainCommand*(self: ProgBase, cache: IdentCache; conf: ConfigRef): bool =
  loadConfigs(DefaultConfig, cache, conf) # load all config files
  if self.suggestMode:
    conf.command = "nimsuggest"

  proc runNimScriptIfExists(scriptFile: string)=
    if fileExists(scriptFile):
      runNimScript(cache, scriptFile, freshDefines=false, conf)

  # TODO:
  # merge this complex logic with `loadConfigs`
  # check whether these should be controlled via
  # optSkipConfigFile, optSkipUserConfigFile
  const configNims = "config.nims"
  runNimScriptIfExists(getSystemConfigPath(conf, configNims))
  runNimScriptIfExists(getUserConfigPath(configNims))
  runNimScriptIfExists(conf.projectPath / configNims)
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
