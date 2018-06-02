#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements the new configuration system for Nim. Uses Nim as a scripting
## language.

import
  ast, modules, idents, passes, passaux, condsyms,
  options, nimconf, sem, semdata, llstream, vm, vmdef, commands, msgs,
  os, times, osproc, wordrecg, strtabs, modulegraphs, lineinfos

# we support 'cmpIgnoreStyle' natively for efficiency:
from strutils import cmpIgnoreStyle, contains

proc listDirs(a: VmArgs, filter: set[PathComponent]) =
  let dir = getString(a, 0)
  var result: seq[string] = @[]
  for kind, path in walkDir(dir):
    if kind in filter: result.add path
  setResult(a, result)

proc setupVM*(module: PSym; cache: IdentCache; scriptName: string;
              graph: ModuleGraph): PEvalContext =
  # For Nimble we need to export 'setupVM'.
  result = newCtx(module, cache, graph)
  result.mode = emRepl
  registerAdditionalOps(result)
  let conf = graph.config

  # captured vars:
  var errorMsg: string
  var vthisDir = scriptName.splitFile.dir

  template cbconf(name, body) {.dirty.} =
    result.registerCallback "stdlib.system." & astToStr(name),
      proc (a: VmArgs) =
        body

  template cbos(name, body) {.dirty.} =
    result.registerCallback "stdlib.system." & astToStr(name),
      proc (a: VmArgs) =
        errorMsg = nil
        try:
          body
        except OSError:
          errorMsg = getCurrentExceptionMsg()

  # Idea: Treat link to file as a file, but ignore link to directory to prevent
  # endless recursions out of the box.
  cbos listFiles:
    listDirs(a, {pcFile, pcLinkToFile})
  cbos listDirs:
    listDirs(a, {pcDir})
  cbos removeDir:
    os.removeDir getString(a, 0)
  cbos removeFile:
    os.removeFile getString(a, 0)
  cbos createDir:
    os.createDir getString(a, 0)
  cbos getOsError:
    setResult(a, errorMsg)
  cbos setCurrentDir:
    os.setCurrentDir getString(a, 0)
  cbos getCurrentDir:
    setResult(a, os.getCurrentDir())
  cbos moveFile:
    os.moveFile(getString(a, 0), getString(a, 1))
  cbos moveDir:
    os.moveDir(getString(a, 0), getString(a, 1))
  cbos copyFile:
    os.copyFile(getString(a, 0), getString(a, 1))
  cbos copyDir:
    os.copyDir(getString(a, 0), getString(a, 1))
  cbos getLastModificationTime:
    setResult(a, getLastModificationTime(getString(a, 0)).toUnix)
  cbos findExe:
    setResult(a, os.findExe(getString(a, 0)))

  cbos rawExec:
    setResult(a, osproc.execCmd getString(a, 0))

  cbconf getEnv:
    setResult(a, os.getEnv(a.getString 0, a.getString 1))
  cbconf existsEnv:
    setResult(a, os.existsEnv(a.getString 0))
  cbconf putEnv:
    os.putEnv(a.getString 0, a.getString 1)
  cbconf dirExists:
    setResult(a, os.dirExists(a.getString 0))
  cbconf fileExists:
    setResult(a, os.fileExists(a.getString 0))

  cbconf thisDir:
    setResult(a, vthisDir)
  cbconf put:
    options.setConfigVar(conf, getString(a, 0), getString(a, 1))
  cbconf get:
    setResult(a, options.getConfigVar(conf, a.getString 0))
  cbconf exists:
    setResult(a, options.existsConfigVar(conf, a.getString 0))
  cbconf nimcacheDir:
    setResult(a, options.getNimcacheDir(conf))
  cbconf paramStr:
    setResult(a, os.paramStr(int a.getInt 0))
  cbconf paramCount:
    setResult(a, os.paramCount())
  cbconf cmpIgnoreStyle:
    setResult(a, strutils.cmpIgnoreStyle(a.getString 0, a.getString 1))
  cbconf cmpIgnoreCase:
    setResult(a, strutils.cmpIgnoreCase(a.getString 0, a.getString 1))
  cbconf setCommand:
    conf.command = a.getString 0
    let arg = a.getString 1
    if arg.len > 0:
      conf.projectName = arg
      let path =
        if conf.projectName.isAbsolute: conf.projectName
        else: conf.projectPath / conf.projectName
      try:
        conf.projectFull = canonicalizePath(conf, path)
      except OSError:
        conf.projectFull = path
  cbconf getCommand:
    setResult(a, conf.command)
  cbconf switch:
    processSwitch(a.getString 0, a.getString 1, passPP, module.info, conf)
  cbconf hintImpl:
    processSpecificNote(a.getString 0, wHint, passPP, module.info,
      a.getString 1, conf)
  cbconf warningImpl:
    processSpecificNote(a.getString 0, wWarning, passPP, module.info,
      a.getString 1, conf)
  cbconf patchFile:
    let key = a.getString(0) & "_" & a.getString(1)
    var val = a.getString(2).addFileExt(NimExt)
    if {'$', '~'} in val:
      val = pathSubs(conf, val, vthisDir)
    elif not isAbsolute(val):
      val = vthisDir / val
    conf.moduleOverrides[key] = val
  cbconf selfExe:
    setResult(a, os.getAppFilename())
  cbconf cppDefine:
    options.cppDefine(conf, a.getString(0))

proc runNimScript*(cache: IdentCache; scriptName: string;
                   freshDefines=true; conf: ConfigRef) =
  rawMessage(conf, hintConf, scriptName)

  let graph = newModuleGraph(cache, conf)
  connectCallbacks(graph)
  if freshDefines: initDefines(conf.symbols)

  defineSymbol(conf.symbols, "nimscript")
  defineSymbol(conf.symbols, "nimconfig")
  registerPass(graph, semPass)
  registerPass(graph, evalPass)

  conf.searchPaths.add(conf.libpath)

  var m = graph.makeModule(scriptName)
  incl(m.flags, sfMainModule)
  graph.vm = setupVM(m, cache, scriptName, graph)

  graph.compileSystemModule()
  discard graph.processModule(m, llStreamOpen(scriptName, fmRead))

  # ensure we load 'system.nim' again for the real non-config stuff!
  resetSystemArtifacts(graph)
  # do not remove the defined symbols
  #initDefines()
  undefSymbol(conf.symbols, "nimscript")
  undefSymbol(conf.symbols, "nimconfig")
