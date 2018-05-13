#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# implements the command dispatcher and several commands

import
  llstream, strutils, ast, astalgo, lexer, syntaxes, renderer, options, msgs,
  os, condsyms, rodread, rodwrite, times,
  wordrecg, sem, semdata, idents, passes, docgen, extccomp,
  cgen, jsgen, json, nversion,
  platform, nimconf, importer, passaux, depends, vm, vmdef, types, idgen,
  docgen2, service, parser, modules, ccgutils, sigmatch, ropes,
  modulegraphs, tables, rod, configuration

from magicsys import resetSysTypes

proc rodPass =
  if gSymbolFiles in {enabledSf, writeOnlySf}:
    registerPass(rodwritePass)

proc codegenPass =
  registerPass cgenPass

proc semanticPasses =
  registerPass verbosePass
  registerPass semPass

proc writeDepsFile(g: ModuleGraph; project: string) =
  let f = open(changeFileExt(project, "deps"), fmWrite)
  for m in g.modules:
    if m != nil:
      f.writeLine(toFullPath(m.position.FileIndex))
  for k in g.inclToMod.keys:
    if g.getModule(k).isNil:  # don't repeat includes which are also modules
      f.writeLine(k.toFullPath)
  f.close()

proc commandGenDepend(graph: ModuleGraph; cache: IdentCache) =
  semanticPasses()
  registerPass(gendependPass)
  #registerPass(cleanupPass)
  compileProject(graph, cache)
  let project = graph.config.projectFull
  writeDepsFile(graph, project)
  generateDot(project)
  execExternalProgram(graph.config, "dot -Tpng -o" & changeFileExt(project, "png") &
      ' ' & changeFileExt(project, "dot"))

proc commandCheck(graph: ModuleGraph; cache: IdentCache) =
  graph.config.errorMax = high(int)  # do not stop after first error
  defineSymbol(graph.config.symbols, "nimcheck")
  semanticPasses()            # use an empty backend for semantic checking only
  rodPass()
  compileProject(graph, cache)

proc commandDoc2(graph: ModuleGraph; cache: IdentCache; json: bool) =
  graph.config.errorMax = high(int)  # do not stop after first error
  semanticPasses()
  if json: registerPass(docgen2JsonPass)
  else: registerPass(docgen2Pass)
  #registerPass(cleanupPass())
  compileProject(graph, cache)
  finishDoc2Pass(graph.config.projectName)

proc commandCompileToC(graph: ModuleGraph; cache: IdentCache) =
  let conf = graph.config
  extccomp.initVars(conf)
  semanticPasses()
  registerPass(cgenPass)
  rodPass()
  #registerPass(cleanupPass())

  compileProject(graph, cache)
  cgenWriteModules(graph.backend, conf)
  if gCmd != cmdRun:
    let proj = changeFileExt(conf.projectFull, "")
    extccomp.callCCompiler(conf, proj)
    extccomp.writeJsonBuildInstructions(conf, proj)
    if optGenScript in gGlobalOptions:
      writeDepsFile(graph, toGeneratedFile(conf, proj, ""))

proc commandJsonScript(graph: ModuleGraph; cache: IdentCache) =
  let proj = changeFileExt(graph.config.projectFull, "")
  extccomp.runJsonBuildInstructions(graph.config, proj)

proc commandCompileToJS(graph: ModuleGraph; cache: IdentCache) =
  #incl(gGlobalOptions, optSafeCode)
  setTarget(osJS, cpuJS)
  #initDefines()
  defineSymbol(graph.config.symbols, "ecmascript") # For backward compatibility
  defineSymbol(graph.config.symbols, "js")
  semanticPasses()
  registerPass(JSgenPass)
  compileProject(graph, cache)

proc interactivePasses(graph: ModuleGraph; cache: IdentCache) =
  #incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines(graph.config.symbols)
  defineSymbol(graph.config.symbols, "nimscript")
  when hasFFI: defineSymbol(graph.config.symbols, "nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

proc commandInteractive(graph: ModuleGraph; cache: IdentCache) =
  graph.config.errorMax = high(int)  # do not stop after first error
  interactivePasses(graph, cache)
  compileSystemModule(graph, cache)
  if graph.config.commandArgs.len > 0:
    discard graph.compileModule(fileInfoIdx(graph.config, graph.config.projectFull), cache, {})
  else:
    var m = graph.makeStdinModule()
    incl(m.flags, sfMainModule)
    processModule(graph, m, llStreamOpenStdIn(), nil, cache)

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(graph: ModuleGraph; nodes: PNode, module: PSym; cache: IdentCache) =
  carryPasses(graph, nodes, module, cache, evalPasses)

proc commandEval(graph: ModuleGraph; cache: IdentCache; exp: string) =
  if graph.systemModule == nil:
    interactivePasses(graph, cache)
    compileSystemModule(graph, cache)
  let echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(graph, echoExp.parseString(cache, graph.config),
    makeStdinModule(graph), cache)

proc commandScan(cache: IdentCache, config: ConfigRef) =
  var f = addFileExt(mainCommandArg(config), NimExt)
  var stream = llStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: TLexer
      tok: TToken
    initToken(tok)
    openLexer(L, f, stream, cache, config)
    while true:
      rawGetTok(L, tok)
      printTok(tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(config, errGenerated, "cannot open file: " & f)

const
  PrintRopeCacheStats = false

proc mainCommand*(graph: ModuleGraph; cache: IdentCache) =
  let conf = graph.config

  setupModuleCache()
  # In "nim serve" scenario, each command must reset the registered passes
  clearPasses()
  gLastCmdTime = epochTime()
  conf.searchPaths.add(conf.libpath)
  setId(100)
  case conf.command.normalize
  of "c", "cc", "compile", "compiletoc":
    # compile means compileToC currently
    gCmd = cmdCompileToC
    commandCompileToC(graph, cache)
  of "cpp", "compiletocpp":
    gCmd = cmdCompileToCpp
    defineSymbol(graph.config.symbols, "cpp")
    commandCompileToC(graph, cache)
  of "objc", "compiletooc":
    gCmd = cmdCompileToOC
    defineSymbol(graph.config.symbols, "objc")
    commandCompileToC(graph, cache)
  of "run":
    gCmd = cmdRun
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      commandCompileToC(graph, cache)
    else:
      rawMessage(conf, errGenerated, "'run' command not available; rebuild with -d:tinyc")
  of "js", "compiletojs":
    gCmd = cmdCompileToJS
    commandCompileToJS(graph, cache)
  of "doc0":
    wantMainModule(conf)
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    commandDoc(conf)
  of "doc2", "doc":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    defineSymbol(conf.symbols, "nimdoc")
    commandDoc2(graph, cache, false)
  of "rst2html":
    gCmd = cmdRst2html
    loadConfigs(DocConfig, cache)
    commandRst2Html(conf)
  of "rst2tex":
    gCmd = cmdRst2tex
    loadConfigs(DocTexConfig, cache)
    commandRst2TeX(conf)
  of "jsondoc0":
    wantMainModule(conf)
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    wantMainModule(conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandJson(conf)
  of "jsondoc2", "jsondoc":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    wantMainModule(conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandDoc2(graph, cache, true)
  of "ctags":
    wantMainModule(conf)
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    defineSymbol(conf.symbols, "nimdoc")
    commandTags(conf)
  of "buildindex":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    commandBuildIndex(conf)
  of "gendepend":
    gCmd = cmdGenDepend
    commandGenDepend(graph, cache)
  of "dump":
    gCmd = cmdDump
    if getConfigVar(conf, "dump.format") == "json":
      wantMainModule(conf)

      var definedSymbols = newJArray()
      for s in definedSymbolNames(conf.symbols): definedSymbols.elems.add(%s)

      var libpaths = newJArray()
      for dir in conf.searchPaths: libpaths.elems.add(%dir)

      var dumpdata = % [
        (key: "version", val: %VersionAsString),
        (key: "project_path", val: %conf.projectFull),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: libpaths)
      ]

      msgWriteln($dumpdata, {msgStdout, msgSkipHook})
    else:
      msgWriteln("-- list of currently defined symbols --",
                 {msgStdout, msgSkipHook})
      for s in definedSymbolNames(conf.symbols): msgWriteln(s, {msgStdout, msgSkipHook})
      msgWriteln("-- end of list --", {msgStdout, msgSkipHook})

      for it in conf.searchPaths: msgWriteln(it)
  of "check":
    gCmd = cmdCheck
    commandCheck(graph, cache)
  of "parse":
    gCmd = cmdParse
    wantMainModule(conf)
    discard parseFile(FileIndex conf.projectMainIdx, cache, conf)
  of "scan":
    gCmd = cmdScan
    wantMainModule(conf)
    commandScan(cache, conf)
    msgWriteln("Beware: Indentation tokens depend on the parser's state!")
  of "secret":
    gCmd = cmdInteractive
    commandInteractive(graph, cache)
  of "e":
    commandEval(graph, cache, mainCommandArg(conf))
  of "nop", "help":
    # prevent the "success" message:
    gCmd = cmdDump
  of "jsonscript":
    gCmd = cmdJsonScript
    commandJsonScript(graph, cache)
  else:
    rawMessage(conf, errGenerated, "invalid command: " & conf.command)

  if conf.errorCounter == 0 and
     gCmd notin {cmdInterpret, cmdRun, cmdDump}:
    when declared(system.getMaxMem):
      let usedMem = formatSize(getMaxMem()) & " peakmem"
    else:
      let usedMem = formatSize(getTotalMem())
    rawMessage(conf, hintSuccessX, [$conf.linesCompiled,
               formatFloat(epochTime() - gLastCmdTime, ffDecimal, 3),
               usedMem,
               if isDefined(conf, "release"): "Release Build"
               else: "Debug Build"])

  when PrintRopeCacheStats:
    echo "rope cache stats: "
    echo "  tries : ", gCacheTries
    echo "  misses: ", gCacheMisses
    echo "  int tries: ", gCacheIntTries
    echo "  efficiency: ", formatFloat(1-(gCacheMisses.float/gCacheTries.float),
                                       ffDecimal, 3)

  resetAttributes(conf)

#proc mainCommand*() = mainCommand(newModuleGraph(newConfigRef()), newIdentCache())
