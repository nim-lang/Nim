#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# implements the command dispatcher and several commands

when not defined(nimcore):
  {.error: "nimcore MUST be defined for Nim's core tooling".}

import
  llstream, strutils, os, ast, lexer, syntaxes, options, msgs,
  condsyms, times,
  sem, idents, passes, extccomp,
  cgen, json, nversion,
  platform, nimconf, passaux, depends, vm,
  modules,
  modulegraphs, tables, lineinfos, pathutils, vmprofiler

import ic / cbackend
from ic / to_packed_ast import rodViewer

when not defined(leanCompiler):
  import jsgen, docgen, docgen2

proc semanticPasses(g: ModuleGraph) =
  registerPass g, verbosePass
  registerPass g, semPass

proc writeDepsFile(g: ModuleGraph) =
  let fname = g.config.nimcacheDir / RelativeFile(g.config.projectName & ".deps")
  let f = open(fname.string, fmWrite)
  for m in g.ifaces:
    if m.module != nil:
      f.writeLine(toFullPath(g.config, m.module.position.FileIndex))
  for k in g.inclToMod.keys:
    if g.getModule(k).isNil:  # don't repeat includes which are also modules
      f.writeLine(toFullPath(g.config, k))
  f.close()

proc commandGenDepend(graph: ModuleGraph) =
  semanticPasses(graph)
  registerPass(graph, gendependPass)
  compileProject(graph)
  let project = graph.config.projectFull
  writeDepsFile(graph)
  generateDot(graph, project)
  execExternalProgram(graph.config, "dot -Tpng -o" &
      changeFileExt(project, "png").string &
      ' ' & changeFileExt(project, "dot").string)

proc commandCheck(graph: ModuleGraph) =
  graph.config.setErrorMaxHighMaybe
  defineSymbol(graph.config.symbols, "nimcheck")
  semanticPasses(graph)  # use an empty backend for semantic checking only
  compileProject(graph)

when not defined(leanCompiler):
  proc commandDoc2(graph: ModuleGraph; json: bool) =
    handleDocOutputOptions graph.config
    graph.config.setErrorMaxHighMaybe
    semanticPasses(graph)
    if json: registerPass(graph, docgen2JsonPass)
    else: registerPass(graph, docgen2Pass)
    compileProject(graph)
    finishDoc2Pass(graph.config.projectName)

proc commandCompileToC(graph: ModuleGraph) =
  let conf = graph.config
  setOutFile(conf)
  extccomp.initVars(conf)
  semanticPasses(graph)
  if conf.symbolFiles == disabledSf:
    registerPass(graph, cgenPass)

    if {optRun, optForceFullMake} * conf.globalOptions == {optRun} or isDefined(conf, "nimBetterRun"):
      let proj = changeFileExt(conf.projectFull, "")
      if not changeDetectedViaJsonBuildInstructions(conf, proj):
        # nothing changed
        graph.config.notes = graph.config.mainPackageNotes
        return

  if not extccomp.ccHasSaneOverflow(conf):
    conf.symbols.defineSymbol("nimEmulateOverflowChecks")

  compileProject(graph)
  if graph.config.errorCounter > 0:
    return # issue #9933
  if conf.symbolFiles == disabledSf:
    cgenWriteModules(graph.backend, conf)
  else:
    generateCode(graph)
    # graph.backend can be nil under IC when nothing changed at all:
    if graph.backend != nil:
      cgenWriteModules(graph.backend, conf)
  if conf.cmd != cmdTcc and graph.backend != nil:
    extccomp.callCCompiler(conf)
    # for now we do not support writing out a .json file with the build instructions when HCR is on
    if not conf.hcrOn:
      extccomp.writeJsonBuildInstructions(conf)
    if optGenScript in graph.config.globalOptions:
      writeDepsFile(graph)

proc commandJsonScript(graph: ModuleGraph) =
  let proj = changeFileExt(graph.config.projectFull, "")
  extccomp.runJsonBuildInstructions(graph.config, proj)

proc commandCompileToJS(graph: ModuleGraph) =
  when defined(leanCompiler):
    globalError(graph.config, unknownLineInfo, "compiler wasn't built with JS code generator")
  else:
    let conf = graph.config
    conf.exc = excCpp

    if conf.outFile.isEmpty:
      conf.outFile = RelativeFile(conf.projectName & ".js")

    #incl(gGlobalOptions, optSafeCode)
    setTarget(graph.config.target, osJS, cpuJS)
    #initDefines()
    defineSymbol(graph.config.symbols, "ecmascript") # For backward compatibility
    semanticPasses(graph)
    registerPass(graph, JSgenPass)
    compileProject(graph)
    if optGenScript in graph.config.globalOptions:
      writeDepsFile(graph)

proc interactivePasses(graph: ModuleGraph) =
  initDefines(graph.config.symbols)
  defineSymbol(graph.config.symbols, "nimscript")
  # note: seems redundant with -d:nimHasLibFFI
  when hasFFI: defineSymbol(graph.config.symbols, "nimffi")
  registerPass(graph, verbosePass)
  registerPass(graph, semPass)
  registerPass(graph, evalPass)

proc commandInteractive(graph: ModuleGraph) =
  graph.config.setErrorMaxHighMaybe
  interactivePasses(graph)
  compileSystemModule(graph)
  if graph.config.commandArgs.len > 0:
    discard graph.compileModule(fileInfoIdx(graph.config, graph.config.projectFull), {})
  else:
    var m = graph.makeStdinModule()
    incl(m.flags, sfMainModule)
    var idgen = IdGenerator(module: m.itemId.module, symId: m.itemId.item, typeId: 0)
    let s = llStreamOpenStdIn(onPrompt = proc() = flushDot(graph.config))
    processModule(graph, m, idgen, s)

proc commandScan(cache: IdentCache, config: ConfigRef) =
  var f = addFileExt(AbsoluteFile mainCommandArg(config), NimExt)
  var stream = llStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: Lexer
      tok: Token
    initToken(tok)
    openLexer(L, f, stream, cache, config)
    while true:
      rawGetTok(L, tok)
      printTok(config, tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(config, errGenerated, "cannot open file: " & f.string)

proc commandView(graph: ModuleGraph) =
  let f = toAbsolute(mainCommandArg(graph.config), AbsoluteDir getCurrentDir()).addFileExt(RodExt)
  rodViewer(f, graph.config, graph.cache)

const
  PrintRopeCacheStats = false

proc mainCommand*(graph: ModuleGraph) =
  let conf = graph.config
  let cache = graph.cache

  # In "nim serve" scenario, each command must reset the registered passes
  clearPasses(graph)
  conf.lastCmdTime = epochTime()
  conf.searchPaths.add(conf.libpath)

  proc customizeForBackend(backend: TBackend) =
    ## Sets backend specific options but don't compile to backend yet in
    ## case command doesn't require it. This must be called by all commands.
    if conf.backend == backendInvalid:
      # only set if wasn't already set, to allow override via `nim c -b:cpp`
      conf.backend = backend

    defineSymbol(graph.config.symbols, $conf.backend)
    case conf.backend
    of backendC:
      if conf.exc == excNone: conf.exc = excSetjmp
    of backendCpp:
      if conf.exc == excNone: conf.exc = excCpp
    of backendObjc: discard
    of backendJs:
      if conf.hcrOn:
        # XXX: At the moment, system.nim cannot be compiled in JS mode
        # with "-d:useNimRtl". The HCR option has been processed earlier
        # and it has added this define implictly, so we must undo that here.
        # A better solution might be to fix system.nim
        undefSymbol(conf.symbols, "useNimRtl")
    of backendInvalid: doAssert false

  proc compileToBackend() =
    customizeForBackend(conf.backend)
    case conf.backend
    of backendC: commandCompileToC(graph)
    of backendCpp: commandCompileToC(graph)
    of backendObjc: commandCompileToC(graph)
    of backendJs: commandCompileToJS(graph)
    of backendInvalid: doAssert false

  template docLikeCmd(body) =
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      wantMainModule(conf)
      loadConfigs(DocConfig, cache, conf, graph.idgen)
      defineSymbol(conf.symbols, "nimdoc")
      body

  ## command prepass
  if conf.cmd == cmdCrun: conf.globalOptions.incl {optRun, optUseNimcache}
  if conf.cmd notin cmdBackends + {cmdTcc}: customizeForBackend(backendC)
  if conf.outDir.isEmpty:
    # doc like commands can generate a lot of files (especially with --project)
    # so by default should not end up in $PWD nor in $projectPath.
    var ret = if optUseNimcache in conf.globalOptions: getNimcacheDir(conf)
              else: conf.projectPath
    doAssert ret.string.isAbsolute # `AbsoluteDir` is not a real guarantee
    if conf.cmd in cmdDocLike + {cmdRst2html, cmdRst2tex}: ret = ret / htmldocsDir
    conf.outDir = ret

  ## process all commands
  case conf.cmd
  of cmdBackends: compileToBackend()
  of cmdTcc:
    when hasTinyCBackend:
      extccomp.setCC(conf, "tcc", unknownLineInfo)
      if conf.backend != backendC:
        rawMessage(conf, errGenerated, "'run' requires c backend, got: '$1'" % $conf.backend)
      compileToBackend()
    else:
      rawMessage(conf, errGenerated, "'run' command not available; rebuild with -d:tinyc")
  of cmdDoc0: docLikeCmd commandDoc(cache, conf)
  of cmdDoc2:
    docLikeCmd():
      conf.setNoteDefaults(warnLockLevel, false) # issue #13218
      conf.setNoteDefaults(warnRedefinitionOfLabel, false) # issue #13218
        # because currently generates lots of false positives due to conflation
        # of labels links in doc comments, e.g. for random.rand:
        #  ## * `rand proc<#rand,Rand,Natural>`_ that returns an integer
        #  ## * `rand proc<#rand,Rand,range[]>`_ that returns a float
      commandDoc2(graph, false)
      if optGenIndex in conf.globalOptions and optWholeProject in conf.globalOptions:
        commandBuildIndex(conf, $conf.outDir)
  of cmdRst2html:
    # XXX: why are warnings disabled by default for rst2html and rst2tex?
    for warn in [warnUnknownSubstitutionX, warnLanguageXNotSupported,
                 warnFieldXNotSupported, warnRstStyle]:
      conf.setNoteDefaults(warn, true)
    conf.setNoteDefaults(warnRedefinitionOfLabel, false) # similar to issue #13218
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      loadConfigs(DocConfig, cache, conf, graph.idgen)
      commandRst2Html(cache, conf)
  of cmdRst2tex:
    for warn in [warnRedefinitionOfLabel, warnUnknownSubstitutionX,
                 warnLanguageXNotSupported,
                 warnFieldXNotSupported, warnRstStyle]:
      conf.setNoteDefaults(warn, true)
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      loadConfigs(DocTexConfig, cache, conf, graph.idgen)
      commandRst2TeX(cache, conf)
  of cmdJsondoc0: docLikeCmd commandJson(cache, conf)
  of cmdJsondoc: docLikeCmd commandDoc2(graph, true)
  of cmdCtags: docLikeCmd commandTags(cache, conf)
  of cmdBuildindex: docLikeCmd commandBuildIndex(conf, $conf.projectFull, conf.outFile)
  of cmdGendepend: commandGenDepend(graph)
  of cmdDump:
    if getConfigVar(conf, "dump.format") == "json":
      wantMainModule(conf)

      var definedSymbols = newJArray()
      for s in definedSymbolNames(conf.symbols): definedSymbols.elems.add(%s)

      var libpaths = newJArray()
      var lazyPaths = newJArray()
      for dir in conf.searchPaths: libpaths.elems.add(%dir.string)
      for dir in conf.lazyPaths: lazyPaths.elems.add(%dir.string)

      var hints = newJObject() # consider factoring with `listHints`
      for a in hintMin..hintMax:
        hints[$a] = %(a in conf.notes)
      var warnings = newJObject()
      for a in warnMin..warnMax:
        warnings[$a] = %(a in conf.notes)

      var dumpdata = %[
        (key: "version", val: %VersionAsString),
        (key: "nimExe", val: %(getAppFilename())),
        (key: "prefixdir", val: %conf.getPrefixDir().string),
        (key: "libpath", val: %conf.libpath.string),
        (key: "project_path", val: %conf.projectFull.string),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: %libpaths),
        (key: "lazyPaths", val: %lazyPaths),
        (key: "outdir", val: %conf.outDir.string),
        (key: "out", val: %conf.outFile.string),
        (key: "nimcache", val: %getNimcacheDir(conf).string),
        (key: "hints", val: hints),
        (key: "warnings", val: warnings),
      ]

      msgWriteln(conf, $dumpdata, {msgStdout, msgSkipHook})
    else:
      msgWriteln(conf, "-- list of currently defined symbols --",
                 {msgStdout, msgSkipHook})
      for s in definedSymbolNames(conf.symbols): msgWriteln(conf, s, {msgStdout, msgSkipHook})
      msgWriteln(conf, "-- end of list --", {msgStdout, msgSkipHook})

      for it in conf.searchPaths: msgWriteln(conf, it.string)
  of cmdCheck: commandCheck(graph)
  of cmdParse:
    wantMainModule(conf)
    discard parseFile(conf.projectMainIdx, cache, conf)
  of cmdRod:
    wantMainModule(conf)
    commandView(graph)
    #msgWriteln(conf, "Beware: Indentation tokens depend on the parser's state!")
  of cmdInteractive: commandInteractive(graph)
  of cmdNimscript:
    if conf.projectIsCmd or conf.projectIsStdin: discard
    elif not fileExists(conf.projectFull):
      rawMessage(conf, errGenerated, "NimScript file does not exist: " & conf.projectFull.string)
    elif not conf.projectFull.string.endsWith(".nims"):
      rawMessage(conf, errGenerated, "not a NimScript file: " & conf.projectFull.string)
    # main NimScript logic handled in `loadConfigs`.
  of cmdNop: discard
  of cmdJsonscript:
    setOutFile(graph.config)
    commandJsonScript(graph)
  of cmdUnknown, cmdNone, cmdIdeTools, cmdNimfix:
    rawMessage(conf, errGenerated, "invalid command: " & conf.command)

  if conf.errorCounter == 0 and conf.cmd notin {cmdTcc, cmdDump, cmdNop}:
    let mem =
      when declared(system.getMaxMem): formatSize(getMaxMem()) & " peakmem"
      else: formatSize(getTotalMem()) & " totmem"
    let loc = $conf.linesCompiled
    let build = if isDefined(conf, "danger"): "Dangerous Release"
                elif isDefined(conf, "release"): "Release"
                else: "Debug"
    let sec = formatFloat(epochTime() - conf.lastCmdTime, ffDecimal, 3)
    let project = if optListFullPaths in conf.globalOptions: $conf.projectFull else: $conf.projectName

    var output: string
    if optCompileOnly in conf.globalOptions and conf.cmd != cmdJsonscript:
      output = $conf.jsonBuildFile
    elif conf.outFile.isEmpty and conf.cmd notin {cmdJsonscript} + cmdDocLike + cmdBackends:
      # for some cmd we expect a valid absOutFile
      output = "unknownOutput"
    else:
      output = $conf.absOutFile
    if optListFullPaths notin conf.globalOptions: output = output.AbsoluteFile.extractFilename
    if optProfileVM in conf.globalOptions:
      echo conf.dump(conf.vmProfileData)
    rawMessage(conf, hintSuccessX, [
      "loc", loc,
      "sec", sec,
      "mem", mem,
      "build", build,
      "project", project,
      "output", output,
      ])

  when PrintRopeCacheStats:
    echo "rope cache stats: "
    echo "  tries : ", gCacheTries
    echo "  misses: ", gCacheMisses
    echo "  int tries: ", gCacheIntTries
    echo "  efficiency: ", formatFloat(1-(gCacheMisses.float/gCacheTries.float),
                                       ffDecimal, 3)
