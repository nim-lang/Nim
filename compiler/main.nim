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
  llstream, strutils, ast, astalgo, lexer, syntaxes, renderer, options, msgs,
  os, condsyms, times,
  wordrecg, sem, semdata, idents, passes, docgen, extccomp,
  cgen, jsgen, json, nversion,
  platform, nimconf, importer, passaux, depends, vm, vmdef, types, idgen,
  docgen2, parser, modules, ccgutils, sigmatch, ropes,
  modulegraphs, tables, rod, lineinfos

from magicsys import resetSysTypes

proc codegenPass(g: ModuleGraph) =
  registerPass g, cgenPass

proc semanticPasses(g: ModuleGraph) =
  registerPass g, verbosePass
  registerPass g, semPass

proc writeDepsFile(g: ModuleGraph; project: string) =
  let f = open(changeFileExt(project, "deps"), fmWrite)
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
  writeDepsFile(graph, project)
  generateDot(graph, project)
  execExternalProgram(graph.config, "dot -Tpng -o" & changeFileExt(project, "png") &
      ' ' & changeFileExt(project, "dot"))

proc commandCheck(graph: ModuleGraph) =
  graph.config.errorMax = high(int)  # do not stop after first error
  defineSymbol(graph.config.symbols, "nimcheck")
  semanticPasses(graph)  # use an empty backend for semantic checking only
  compileProject(graph)

proc commandDoc2(graph: ModuleGraph; json: bool) =
  graph.config.errorMax = high(int)  # do not stop after first error
  semanticPasses(graph)
  if json: registerPass(graph, docgen2JsonPass)
  else: registerPass(graph, docgen2Pass)
  compileProject(graph)
  finishDoc2Pass(graph.config.projectName)

proc commandCompileToC(graph: ModuleGraph) =
  let conf = graph.config
  extccomp.initVars(conf)
  semanticPasses(graph)
  registerPass(graph, cgenPass)

  compileProject(graph)
  cgenWriteModules(graph.backend, conf)
  if conf.cmd != cmdRun:
    let proj = changeFileExt(conf.projectFull, "")
    extccomp.callCCompiler(conf, proj)
    extccomp.writeJsonBuildInstructions(conf, proj)
    if optGenScript in graph.config.globalOptions:
      writeDepsFile(graph, toGeneratedFile(conf, proj, ""))

proc commandJsonScript(graph: ModuleGraph) =
  let proj = changeFileExt(graph.config.projectFull, "")
  extccomp.runJsonBuildInstructions(graph.config, proj)

proc commandCompileToJS(graph: ModuleGraph) =
  #incl(gGlobalOptions, optSafeCode)
  setTarget(graph.config.target, osJS, cpuJS)
  #initDefines()
  defineSymbol(graph.config.symbols, "ecmascript") # For backward compatibility
  defineSymbol(graph.config.symbols, "js")
  semanticPasses(graph)
  registerPass(graph, JSgenPass)
  compileProject(graph)

proc interactivePasses(graph: ModuleGraph) =
  initDefines(graph.config.symbols)
  defineSymbol(graph.config.symbols, "nimscript")
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

proc commandEval(graph: ModuleGraph; exp: string) =
  if graph.systemModule == nil:
    interactivePasses(graph)
    compileSystemModule(graph)
  let echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(graph, echoExp.parseString(graph.cache, graph.config),
    makeStdinModule(graph))

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
      printTok(config, tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(config, errGenerated, "cannot open file: " & f)

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
    commandCompileToC(graph)
  of "cpp", "compiletocpp":
    conf.cmd = cmdCompileToCpp
    defineSymbol(graph.config.symbols, "cpp")
    commandCompileToC(graph)
  of "objc", "compiletooc":
    conf.cmd = cmdCompileToOC
    defineSymbol(graph.config.symbols, "objc")
    commandCompileToC(graph)
  of "run":
    conf.cmd = cmdRun
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      commandCompileToC(graph)
    else:
      rawMessage(conf, errGenerated, "'run' command not available; rebuild with -d:tinyc")
  of "js", "compiletojs":
    conf.cmd = cmdCompileToJS
    commandCompileToJS(graph)
  of "doc0":
    wantMainModule(conf)
    conf.cmd = cmdDoc
    loadConfigs(DocConfig, cache, conf)
    commandDoc(cache, conf)
  of "doc2", "doc":
    conf.cmd = cmdDoc
    loadConfigs(DocConfig, cache, conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandDoc2(graph, false)
  of "rst2html":
    conf.cmd = cmdRst2html
    loadConfigs(DocConfig, cache, conf)
    commandRst2Html(cache, conf)
  of "rst2tex":
    conf.cmd = cmdRst2tex
    loadConfigs(DocTexConfig, cache, conf)
    commandRst2TeX(cache, conf)
  of "jsondoc0":
    wantMainModule(conf)
    conf.cmd = cmdDoc
    loadConfigs(DocConfig, cache, conf)
    wantMainModule(conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandJson(cache, conf)
  of "jsondoc2", "jsondoc":
    conf.cmd = cmdDoc
    loadConfigs(DocConfig, cache, conf)
    wantMainModule(conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandDoc2(graph, true)
  of "ctags":
    wantMainModule(conf)
    conf.cmd = cmdDoc
    loadConfigs(DocConfig, cache, conf)
    defineSymbol(conf.symbols, "nimdoc")
    commandTags(cache, conf)
  of "buildindex":
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
      for dir in conf.searchPaths: libpaths.elems.add(%dir)

      var dumpdata = % [
        (key: "version", val: %VersionAsString),
        (key: "project_path", val: %conf.projectFull),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: libpaths)
      ]

      msgWriteln(conf, $dumpdata, {msgStdout, msgSkipHook})
    else:
      msgWriteln(conf, "-- list of currently defined symbols --",
                 {msgStdout, msgSkipHook})
      for s in definedSymbolNames(conf.symbols): msgWriteln(conf, s, {msgStdout, msgSkipHook})
      msgWriteln(conf, "-- end of list --", {msgStdout, msgSkipHook})

      for it in conf.searchPaths: msgWriteln(conf, it)
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
    commandEval(graph, mainCommandArg(conf))
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
    when declared(system.getMaxMem):
      let usedMem = formatSize(getMaxMem()) & " peakmem"
    else:
      let usedMem = formatSize(getTotalMem())
    rawMessage(conf, hintSuccessX, [$conf.linesCompiled,
               formatFloat(epochTime() - conf.lastCmdTime, ffDecimal, 3),
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
