#
#
#           The Nim Compiler
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Helpers for binaries that use compiler passes, e.g.: nim, nimsuggest, nimfix

import
  options, idents, nimconf, extccomp, commands, msgs,
  lineinfos, modulegraphs, condsyms, os, pathutils, parseopt

from strutils import normalize

proc prependCurDir*(f: AbsoluteFile): AbsoluteFile =
  when defined(unix):
    if os.isAbsolute(f.string): result = f
    else: result = AbsoluteFile("./" & f.string)
  else:
    result = f

proc addCmdPrefix*(result: var string, kind: CmdLineKind) =
  # consider moving this to std/parseopt
  case kind
  of cmdLongOption: result.add "--"
  of cmdShortOption: result.add "-"
  of cmdArgument, cmdEnd: discard

type
  NimProg* = ref object
    suggestMode*: bool
    supportsStdinFile*: bool
    processCmdLine*: proc(pass: TCmdLinePass, cmd: string; config: ConfigRef)

proc initDefinesProg*(self: NimProg, conf: ConfigRef, name: string) =
  condsyms.initDefines(conf.symbols)
  defineSymbol conf.symbols, name

proc processProjectName(conf: ConfigRef) =
  try:
    conf.projectFull = canonicalizePath(conf, AbsoluteFile conf.projectName)
  except OSError:
    conf.projectFull = AbsoluteFile conf.projectName
  let p = splitFile(conf.projectFull)
  let dir = if p.dir.isEmpty: AbsoluteDir getCurrentDir() else: p.dir
  conf.projectPath = AbsoluteDir canonicalizePath(conf, AbsoluteFile dir)
  conf.projectName = p.name

proc processCmdLineAndProjectPath*(self: NimProg, conf: ConfigRef, projectPath = "") =
  self.processCmdLine(passCmd1, "", conf)
  if conf.projectIsCmd and conf.projectName in ["-", ""]:
    handleCmdInput(conf)
  elif self.supportsStdinFile and conf.projectName == "-":
    handleStdinInput(conf)
  elif projectPath != "":
    if dirExists(projectPath):
      conf.projectName = findProjectNimFile(conf, projectPath)
      doAssert conf.projectName != ""
      processProjectName(conf)
    elif fileExists(projectPath):
      conf.projectName = projectPath
      processProjectName(conf)
  elif conf.projectName != "":
    processProjectName(conf)
  else:
    conf.projectPath = AbsoluteDir canonicalizePath(conf, AbsoluteFile getCurrentDir())


proc loadConfigsAndRunMainCommand*(self: NimProg, cache: IdentCache; conf: ConfigRef;
                                   graph: ModuleGraph): bool =
  if self.suggestMode:
    conf.command = "nimsuggest"
  if conf.command == "e":
    incl(conf.globalOptions, optWasNimscript)
  loadConfigs(DefaultConfig, cache, conf, graph.idgen) # load all config files

  if not self.suggestMode:
    let scriptFile = conf.projectFull.changeFileExt("nims")
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
  self.processCmdLine(passCmd2, "", conf)
  if conf.command == "":
    rawMessage(conf, errGenerated, "command missing")

  graph.suggestMode = self.suggestMode
  return true
