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
  llstream, strutils, ast, lexer, syntaxes, options, msgs,
  condsyms, times,
  sem, idents, passes, extccomp,
  cgen, json, nversion,
  platform, nimconf, passaux, depends, vm, idgen,
  modules,
  modulegraphs, tables, rod, lineinfos, pathutils

when not defined(leanCompiler):
  import jsgen, docgen, docgen2

proc semanticPasses(g: ModuleGraph) =
  registerPass g, verbosePass
  registerPass g, semPass

proc writeDepsFile(g: ModuleGraph) =
  let fname = g.config.nimcacheDir / RelativeFile(g.config.projectName & ".deps")
  let f = open(fname.string, fmWrite)
  for m in g.modules:
    if m != nil:
      f.writeLine(toFullPath(g.config, m.position.FileIndex))
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
  graph.config.errorMax = high(int)  # do not stop after first error
  defineSymbol(graph.config.symbols, "nimcheck")
  semanticPasses(graph)  # use an empty backend for semantic checking only
  compileProject(graph)

when not defined(leanCompiler):
  proc commandDoc2(graph: ModuleGraph; json: bool) =
    handleDocOutputOptions graph.config
    graph.config.errorMax = high(int)  # do not stop after first error
    semanticPasses(graph)
    if json: registerPass(graph, docgen2JsonPass)
    else: registerPass(graph, docgen2Pass)
    compileProject(graph)
    finishDoc2Pass(graph.config.projectName)

proc commandCompileToC(graph: ModuleGraph) =
  let conf = graph.config

  if conf.outDir.isEmpty:
    conf.outDir = conf.projectPath
  if conf.outFile.isEmpty:
    let targetName = if optGenDynLib in conf.globalOptions:
      platform.OS[conf.target.targetOS].dllFrmt % conf.projectName
    else:
      conf.projectName & platform.OS[conf.target.targetOS].exeExt
    conf.outFile = RelativeFile targetName

  extccomp.initVars(conf)
  semanticPasses(graph)
  registerPass(graph, cgenPass)

  if {optRun, optForceFullMake} * conf.globalOptions == {optRun} or isDefined(conf, "nimBetterRun"):
    let proj = changeFileExt(conf.projectFull, "")
    if not changeDetectedViaJsonBuildInstructions(conf, proj):
      # nothing changed
      graph.config.notes = graph.config.mainPackageNotes
      return

  compileProject(graph)
  if graph.config.errorCounter > 0:
    return # issue #9933
  cgenWriteModules(graph.backend, conf)
  if conf.cmd != cmdRun:
    extccomp.callCCompiler(conf)
    # for now we do not support writing out a .json file with the build instructions when HCR is on
    if not conf.hcrOn:
      extccomp.writeJsonBuildInstructions(conf)
    if optGenScript in graph.config.globalOptions:
      writeDepsFile(graph)

proc commandJsonScript(graph: ModuleGraph) =
  let proj = changeFileExt(graph.config.projectFull, "")
  extccomp.runJsonBuildInstructions(graph.config, proj)

when not defined(leanCompiler):
  proc commandCompileToJS(graph: ModuleGraph) =
    let conf = graph.config
    conf.exc = excCpp

    if conf.outDir.isEmpty:
      conf.outDir = conf.projectPath
    if conf.outFile.isEmpty:
      conf.outFile = RelativeFile(conf.projectName & ".js")

    #incl(gGlobalOptions, optSafeCode)
    setTarget(graph.config.target, osJS, cpuJS)
    #initDefines()
    defineSymbol(graph.config.symbols, "ecmascript") # For backward compatibility
    defineSymbol(graph.config.symbols, "js")
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
  graph.config.errorMax = high(int)  # do not stop after first error
  interactivePasses(graph)
  compileSystemModule(graph)
  if graph.config.commandArgs.len > 0:
    discard graph.compileModule(fileInfoIdx(graph.config, graph.config.projectFull), {})
  else:
    var m = graph.makeStdinModule()
    incl(m.flags, sfMainModule)
    processModule(graph, m, llStreamOpenStdIn())

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(graph: ModuleGraph; nodes: PNode, module: PSym) =
  carryPasses(graph, nodes, module, evalPasses)

proc commandScan(cache: IdentCache, config: ConfigRef) =
  var f = addFileExt(AbsoluteFile mainCommandArg(config), NimExt)
  var stream = llStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: TLexer
      tok: TToken
    initToken(tok)
    openLexer(L, f, stream, cache, config)
    while true:
      rawGetTok(L, tok)
      printTok(config, tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(config, errGenerated, "cannot open file: " & f.string)

const
  PrintRopeCacheStats = false

proc mainCommand*(graph: ModuleGraph) =
  let conf = graph.config
  let cache = graph.cache

  setupModuleCache(graph)
  # In "nim serve" scenario, each command must reset the registered passes
  clearPasses(graph)
  conf.lastCmdTime = epochTime()
  conf.searchPaths.add(conf.libpath)
  setId(100)
  case conf.command.normalize
  of "c", "cc", "compile", "compiletoc":
    # compile means compileToC currently
    conf.cmd = cmdCompileToC
    if conf.exc == excNone: conf.exc = excSetjmp
    defineSymbol(graph.config.symbols, "c")
    commandCompileToC(graph)
  of "cpp", "compiletocpp":
    conf.cmd = cmdCompileToCpp
    if conf.exc == excNone: conf.exc = excCpp
    defineSymbol(graph.config.symbols, "cpp")
    commandCompileToC(graph)
  of "objc", "compiletooc":
    conf.cmd = cmdCompileToOC
    defineSymbol(graph.config.symbols, "objc")
    commandCompileToC(graph)
  of "run":
    conf.cmd = cmdRun
    when hasTinyCBackend:
      extccomp.setCC(conf, "tcc", unknownLineInfo)
      commandCompileToC(graph)
    else:
      rawMessage(conf, errGenerated, "'run' command not available; rebuild with -d:tinyc")
  of "js", "compiletojs":
    when defined(leanCompiler):
      quit "compiler wasn't built with JS code generator"
    else:
      conf.cmd = cmdCompileToJS
      if conf.hcrOn:
        # XXX: At the moment, system.nim cannot be compiled in JS mode
        # with "-d:useNimRtl". The HCR option has been processed earlier
        # and it has added this define implictly, so we must undo that here.
        # A better solution might be to fix system.nim
        undefSymbol(conf.symbols, "useNimRtl")
      commandCompileToJS(graph)
  of "doc0":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      wantMainModule(conf)
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      commandDoc(cache, conf)
  of "doc2", "doc":
    conf.setNoteDefaults(warnLockLevel, false) # issue #13218
    conf.setNoteDefaults(warnRedefinitionOfLabel, false) # issue #13218
      # because currently generates lots of false positives due to conflation
      # of labels links in doc comments, eg for random.rand:
      #  ## * `rand proc<#rand,Rand,Natural>`_ that returns an integer
      #  ## * `rand proc<#rand,Rand,range[]>`_ that returns a float
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      defineSymbol(conf.symbols, "nimdoc")
      commandDoc2(graph, false)
  of "rst2html":
    conf.setNoteDefaults(warnRedefinitionOfLabel, false) # similar to issue #13218
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      conf.cmd = cmdRst2html
      loadConfigs(DocConfig, cache, conf)
      commandRst2Html(cache, conf)
  of "rst2tex":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      conf.cmd = cmdRst2tex
      loadConfigs(DocTexConfig, cache, conf)
      commandRst2TeX(cache, conf)
  of "jsondoc0":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      wantMainModule(conf)
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      wantMainModule(conf)
      defineSymbol(conf.symbols, "nimdoc")
      commandJson(cache, conf)
  of "jsondoc2", "jsondoc":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      wantMainModule(conf)
      defineSymbol(conf.symbols, "nimdoc")
      commandDoc2(graph, true)
  of "ctags":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      wantMainModule(conf)
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      defineSymbol(conf.symbols, "nimdoc")
      commandTags(cache, conf)
  of "buildindex":
    when defined(leanCompiler):
      quit "compiler wasn't built with documentation generator"
    else:
      conf.cmd = cmdDoc
      loadConfigs(DocConfig, cache, conf)
      commandBuildIndex(cache, conf)
  of "gendepend":
    conf.cmd = cmdGenDepend
    commandGenDepend(graph)
  of "dump":
    conf.cmd = cmdDump
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
        let key = lineinfos.HintsToStr[ord(a) - ord(hintMin)]
        hints[key] = %(a in conf.notes)
      var warnings = newJObject()
      for a in warnMin..warnMax:
        let key = lineinfos.WarningsToStr[ord(a) - ord(warnMin)]
        warnings[key] = %(a in conf.notes)

      var dumpdata = %[
        (key: "version", val: %VersionAsString),
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
  of "check":
    conf.cmd = cmdCheck
    commandCheck(graph)
  of "parse":
    conf.cmd = cmdParse
    wantMainModule(conf)
    discard parseFile(conf.projectMainIdx, cache, conf)
  of "scan":
    conf.cmd = cmdScan
    wantMainModule(conf)
    commandScan(cache, conf)
    msgWriteln(conf, "Beware: Indentation tokens depend on the parser's state!")
  of "secret":
    conf.cmd = cmdInteractive
    commandInteractive(graph)
  of "e":
    if not fileExists(conf.projectFull):
      rawMessage(conf, errGenerated, "NimScript file does not exist: " & conf.projectFull.string)
    elif not conf.projectFull.string.endsWith(".nims"):
      rawMessage(conf, errGenerated, "not a NimScript file: " & conf.projectFull.string)
    # main NimScript logic handled in cmdlinehelper.nim.
  of "nop", "help":
    # prevent the "success" message:
    conf.cmd = cmdDump
  of "jsonscript":
    conf.cmd = cmdJsonScript
    commandJsonScript(graph)
  else:
    rawMessage(conf, errGenerated, "invalid command: " & conf.command)

  if conf.errorCounter == 0 and
     conf.cmd notin {cmdInterpret, cmdRun, cmdDump}:
    let mem =
      when declared(system.getMaxMem): formatSize(getMaxMem()) & " peakmem"
      else: formatSize(getTotalMem()) & " totmem"
    let loc = $conf.linesCompiled
    let build = if isDefined(conf, "danger"): "Dangerous Release"
                elif isDefined(conf, "release"): "Release"
                else: "Debug"
    let sec = formatFloat(epochTime() - conf.lastCmdTime, ffDecimal, 3)
    let project = if optListFullPaths in conf.globalOptions: $conf.projectFull else: $conf.projectName
    var output = $conf.absOutFile
    if optListFullPaths notin conf.globalOptions: output = output.AbsoluteFile.extractFilename
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

  resetAttributes(conf)
