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
  ast, modules, idents, condsyms,
  options, llstream, vm, vmdef, commands,
  wordrecg, modulegraphs, lineinfos,
  pathutils, pipelines

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions]

import std/[strtabs, os, times, osproc]

# we support 'cmpIgnoreStyle' natively for efficiency:
from std/strutils import cmpIgnoreStyle, contains

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

  template volatileInput(what: string) =
    # The script changed the process or the file system, or read something that
    # cannot be asked again cheaply: a replay would not reproduce that, so the
    # artifact must never be reused (`icconfig.probeChanged`).
    conf.icConfigProbes.add ("volatile", what, "")

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
    conf.icConfigProbes.add ("volatile", "listFiles", "")
    listDirs(a, {pcFile, pcLinkToFile})
  cbos listDirsImpl:
    conf.icConfigProbes.add ("volatile", "listDirs", "")
    listDirs(a, {pcDir})
  cbos removeDir:
    volatileInput "removeDir"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.removeDir(getString(a, 0), getBool(a, 1))
  cbos removeFile:
    volatileInput "removeFile"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.removeFile getString(a, 0)
  cbos createDir:
    volatileInput "createDir"
    os.createDir getString(a, 0)

  result.registerCallback "stdlib.system.getError",
    proc (a: VmArgs) = setResult(a, errorMsg)

  cbos setCurrentDir:
    volatileInput "setCurrentDir"
    os.setCurrentDir getString(a, 0)
  cbos getCurrentDir:
    setResult(a, os.getCurrentDir())
  cbos moveFile:
    volatileInput "moveFile"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.moveFile(getString(a, 0), getString(a, 1))
  cbos moveDir:
    volatileInput "moveDir"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.moveDir(getString(a, 0), getString(a, 1))
  cbos copyFile:
    volatileInput "copyFile"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.copyFile(getString(a, 0), getString(a, 1))
  cbos copyDir:
    volatileInput "copyDir"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      os.copyDir(getString(a, 0), getString(a, 1))
  cbos getLastModificationTime:
    conf.icConfigProbes.add ("volatile", "getLastModificationTime", "")
    setResult(a, getLastModificationTime(getString(a, 0)).toUnix)
  cbos findExe:
    conf.icConfigProbes.add ("volatile", "findExe", "")
    setResult(a, os.findExe(getString(a, 0)))

  cbos rawExec:
    conf.icConfigProbes.add ("volatile", "rawExec", "")
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      discard
    else:
      setResult(a, osproc.execCmd getString(a, 0))

  proc probeEnv(name: string) =
    # What the script saw of the environment is an input of the config; see
    # `options.icConfigProbes`.
    conf.icConfigProbes.add ("env", name,
      if os.existsEnv(name): os.getEnv(name) else: "\0")
  cbconf getEnv:
    probeEnv(a.getString 0)
    setResult(a, os.getEnv(a.getString 0, a.getString 1))
  cbconf existsEnv:
    probeEnv(a.getString 0)
    setResult(a, os.existsEnv(a.getString 0))
  cbconf putEnv:
    volatileInput "putEnv"
    os.putEnv(a.getString 0, a.getString 1)
  cbconf delEnv:
    volatileInput "delEnv"
    os.delEnv(a.getString 0)
  cbconf dirExists:
    conf.icConfigProbes.add ("dir", a.getString 0,
      if os.dirExists(a.getString 0): "1" else: "0")
    setResult(a, os.dirExists(a.getString 0))
  cbconf fileExists:
    conf.icConfigProbes.add ("file", a.getString 0,
      if os.fileExists(a.getString 0): "1" else: "0")
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
    conf.currentConfigDir = vthisDir
    processSwitch(a.getString 0, a.getString 1, passPP, module.info, conf)
  cbconf hintImpl:
    # not through `processSwitch`, so record it into the stream the
    # precompiled config replays (see `icconfig`)
    conf.icConfigSwitches.add ("hint", a.getString 0)
    processSpecificNote(a.getString 0, wHint, passPP, module.info,
      a.getString 1, conf)
  cbconf warningImpl:
    conf.icConfigSwitches.add ("warning", a.getString 0)
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
    volatileInput "stdinReadLine"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      setResult(a, "")
    else:
      setResult(a, stdin.readLine())
  cbexc stdinReadAll, EOFError:
    volatileInput "stdinReadAll"
    if defined(nimsuggest) or graph.config.cmd == cmdCheck:
      setResult(a, "")
    else:
      setResult(a, stdin.readAll())

proc runNimScript*(cache: IdentCache; scriptName: AbsoluteFile;
                   idgen: IdGenerator;
                   freshDefines=true; conf: ConfigRef, stream: PLLStream) =
  # Scripts can change the working directory and filesystem while the compiler
  # is running. Their lookups are uncached; discard the preceding snapshot too.
  defer: conf.resetPathCache()
  let oldSymbolFiles = conf.symbolFiles
  conf.symbolFiles = disabledSf

  let graph = newModuleGraph(cache, conf)
  connectPipelineCallbacks(graph)
  if freshDefines: initDefines(conf.symbols)

  defineSymbol(conf.symbols, "nimscript")
  defineSymbol(conf.symbols, "nimconfig")

  conf.searchPaths.add(conf.libpath)

  let oldGlobalOptions = conf.globalOptions
  let oldSelectedGC = conf.selectedGC
  unregisterArcOrc(conf)
  conf.globalOptions.excl optOwnedRefs
  conf.selectedGC = gcUnselected
  conf.globalOptions.incl optWithinConfigSystem

  var m = graph.makeModule(scriptName)
  incl(m, sfMainModule)
  var vm = setupVM(m, cache, scriptName.string, graph, idgen)
  graph.vm = vm

  graph.setPipeLinePass(EvalPass)
  try:
    graph.compilePipelineSystemModule()
    discard graph.processPipelineModule(m, vm.idgen, stream)
  except ERecoverableError:
    # IDE tooling must still start with an invalid config script. Continue with
    # the settings evaluated so far, restoring the non-script state below.
    if not conf.ideActive: raise

  # watch out, "newruntime" can be set within NimScript itself and then we need
  # to remember this:
  if conf.selectedGC == gcUnselected:
    conf.selectedGC = oldSelectedGC
  if optOwnedRefs in oldGlobalOptions:
    conf.globalOptions.incl {optTinyRtti, optOwnedRefs, optSeqDestructors}
    defineSymbol(conf.symbols, "nimv2")
  if conf.selectedGC in {gcArc, gcOrc, gcYrc, gcAtomicArc}:
    conf.globalOptions.incl {optTinyRtti, optSeqDestructors}
    defineSymbol(conf.symbols, "nimv2")
    defineSymbol(conf.symbols, "gcdestructors")
    defineSymbol(conf.symbols, "nimSeqsV2")
    case conf.selectedGC
    of gcArc:
      defineSymbol(conf.symbols, "gcarc")
    of gcOrc:
      defineSymbol(conf.symbols, "gcorc")
    of gcYrc:
      defineSymbol(conf.symbols, "gcyrc")
    of gcAtomicArc:
      defineSymbol(conf.symbols, "gcatomicarc")
    else:
      raiseAssert "unreachable"

  # ensure we load 'system.nim' again for the real non-config stuff!
  resetSystemArtifacts(graph)
  # do not remove the defined symbols
  #initDefines()
  undefSymbol(conf.symbols, "nimscript")
  undefSymbol(conf.symbols, "nimconfig")
  conf.globalOptions.excl optWithinConfigSystem
  conf.symbolFiles = oldSymbolFiles
