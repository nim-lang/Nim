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
  ast, modules, idents, passes, condsyms,
  options, sem, llstream, vm, vmdef, commands,
  os, times, osproc, wordrecg, strtabs, modulegraphs,
  pathutils

# we support 'cmpIgnoreStyle' natively for efficiency:
from strutils import cmpIgnoreStyle, contains

proc listDirs(a: VmArgs, filter: set[PathComponent]) =
  let dir = getString(a, 0)
  var result: seq[string] = @[]
  for kind, path in walkDir(dir):
    if kind in filter: result.add path
  setResult(a, result)

proc setupVM*(module: PSym; cache: IdentCache; scriptName: string;
              graph: ModuleGraph; idgen: IdGenerator): PEvalContext =
  # For Nimble we need to export 'setupVM'.
  result = newCtx(module, cache, graph, idgen)
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

  template cbexc(name, exc, body) {.dirty.} =
    result.registerCallback "stdlib.system." & astToStr(name),
      proc (a: VmArgs) =
        errorMsg = ""
        try:
          body
        except exc:
          errorMsg = getCurrentExceptionMsg()

  template cbos(name, body) {.dirty.} =
    cbexc(name, OSError, body)

  # Idea: Treat link to file as a file, but ignore link to directory to prevent
  # endless recursions out of the box.
  cbos listFilesImpl:
    listDirs(a, {pcFile, pcLinkToFile})
  cbos listDirsImpl:
    listDirs(a, {pcDir})
  cbos removeDir:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.removeDir(getString(a, 0), getBool(a, 1))
  cbos removeFile:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.removeFile getString(a, 0)
  cbos createDir:
    os.createDir getString(a, 0)

  result.registerCallback "stdlib.system.getError",
    proc (a: VmArgs) = setResult(a, errorMsg)

  cbos setCurrentDir:
    os.setCurrentDir getString(a, 0)
  cbos getCurrentDir:
    setResult(a, os.getCurrentDir())
  cbos moveFile:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.moveFile(getString(a, 0), getString(a, 1))
  cbos moveDir:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.moveDir(getString(a, 0), getString(a, 1))
  cbos copyFile:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.copyFile(getString(a, 0), getString(a, 1))
  cbos copyDir:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.copyDir(getString(a, 0), getString(a, 1))
  cbos getLastModificationTime:
    setResult(a, getLastModificationTime(getString(a, 0)).toUnix)
  cbos findExe:
    setResult(a, os.findExe(getString(a, 0)))

  cbos rawExec:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      setResult(a, osproc.execCmd getString(a, 0))

  cbconf getEnv:
    setResult(a, os.getEnv(a.getString 0, a.getString 1))
  cbconf existsEnv:
    setResult(a, os.existsEnv(a.getString 0))
  cbconf putEnv:
    os.putEnv(a.getString 0, a.getString 1)
  cbconf delEnv:
    os.delEnv(a.getString 0)
  cbconf dirExists:
    setResult(a, os.dirExists(a.getString 0))
  cbconf fileExists:
    setResult(a, os.fileExists(a.getString 0))

  cbconf projectName:
    setResult(a, conf.projectName)
  cbconf projectDir:
    setResult(a, conf.projectPath.string)
  cbconf projectPath:
    setResult(a, conf.projectFull.string)
  cbconf thisDir:
    setResult(a, vthisDir)
  cbconf put:
    options.setConfigVar(conf, getString(a, 0), getString(a, 1))
  cbconf get:
    setResult(a, options.getConfigVar(conf, a.getString 0))
  cbconf exists:
    setResult(a, options.existsConfigVar(conf, a.getString 0))
  cbconf nimcacheDir:
    setResult(a, options.getNimcacheDir(conf).string)
  cbconf paramStr:
    setResult(a, os.paramStr(int a.getInt 0))
  cbconf paramCount:
    setResult(a, os.paramCount())
  cbconf cmpIgnoreStyle:
    setResult(a, strutils.cmpIgnoreStyle(a.getString 0, a.getString 1))
  cbconf cmpIgnoreCase:
    setResult(a, strutils.cmpIgnoreCase(a.getString 0, a.getString 1))
  cbconf setCommand:
    conf.setCommandEarly(a.getString 0)
    let arg = a.getString 1
    incl(conf.globalOptions, optWasNimscript)
    if arg.len > 0: setFromProjectName(conf, arg)
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
  cbexc stdinReadLine, EOFError:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      setResult(a, "")
      setResult(a, stdin.readLine())
  cbexc stdinReadAll, EOFError:
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      setResult(a, "")
      setResult(a, stdin.readAll())

proc runNimScript*(cache: IdentCache; scriptName: AbsoluteFile;
                   idgen: IdGenerator;
                   freshDefines=true; conf: ConfigRef, stream: PLLStream) =
  let oldSymbolFiles = conf.symbolFiles
  conf.symbolFiles = disabledSf

  let graph = newModuleGraph(cache, conf)
  connectCallbacks(graph)
  if freshDefines: initDefines(conf.symbols)

  defineSymbol(conf.symbols, "nimscript")
  defineSymbol(conf.symbols, "nimconfig")
  registerPass(graph, semPass)
  registerPass(graph, evalPass)

  conf.searchPaths.add(conf.libpath)

  let oldGlobalOptions = conf.globalOptions
  let oldSelectedGC = conf.selectedGC
  undefSymbol(conf.symbols, "nimv2")
  conf.globalOptions.excl {optTinyRtti, optOwnedRefs, optSeqDestructors}
  conf.selectedGC = gcUnselected

  var m = graph.makeModule(scriptName)
  incl(m.flags, sfMainModule)
  var vm = setupVM(m, cache, scriptName.string, graph, idgen)
  graph.vm = vm

  graph.compileSystemModule()
  discard graph.processModule(m, vm.idgen, stream)

  # watch out, "newruntime" can be set within NimScript itself and then we need
  # to remember this:
  if conf.selectedGC == gcUnselected:
    conf.selectedGC = oldSelectedGC
  if optOwnedRefs in oldGlobalOptions:
    conf.globalOptions.incl {optTinyRtti, optOwnedRefs, optSeqDestructors}
    defineSymbol(conf.symbols, "nimv2")
  if conf.selectedGC in {gcArc, gcOrc}:
    conf.globalOptions.incl {optTinyRtti, optSeqDestructors}
    defineSymbol(conf.symbols, "nimv2")

  # ensure we load 'system.nim' again for the real non-config stuff!
  resetSystemArtifacts(graph)
  # do not remove the defined symbols
  #initDefines()
  undefSymbol(conf.symbols, "nimscript")
  undefSymbol(conf.symbols, "nimconfig")
  conf.symbolFiles = oldSymbolFiles
