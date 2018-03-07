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
  modulegraphs, tables, rod

from magicsys import systemModule, resetSysTypes

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
      f.writeLine(toFullPath(m.position.int32))
  for k in g.inclToMod.keys:
    if g.getModule(k).isNil:  # don't repeat includes which are also modules
      f.writeLine(k.toFullPath)
  f.close()

proc commandGenDepend(graph: ModuleGraph; cache: IdentCache) =
  semanticPasses()
  registerPass(gendependPass)
  #registerPass(cleanupPass)
  compileProject(graph, cache)
  writeDepsFile(graph, gProjectFull)
  generateDot(gProjectFull)
  execExternalProgram("dot -Tpng -o" & changeFileExt(gProjectFull, "png") &
      ' ' & changeFileExt(gProjectFull, "dot"))

proc commandCheck(graph: ModuleGraph; cache: IdentCache) =
  msgs.gErrorMax = high(int)  # do not stop after first error
  defineSymbol("nimcheck")
  semanticPasses()            # use an empty backend for semantic checking only
  rodPass()
  compileProject(graph, cache)

proc commandDoc2(graph: ModuleGraph; cache: IdentCache; json: bool) =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  if json: registerPass(docgen2JsonPass)
  else: registerPass(docgen2Pass)
  #registerPass(cleanupPass())
  compileProject(graph, cache)
  finishDoc2Pass(gProjectName)

proc commandCompileToC(graph: ModuleGraph; cache: IdentCache) =
  extccomp.initVars()
  semanticPasses()
  registerPass(cgenPass)
  rodPass()
  #registerPass(cleanupPass())

  compileProject(graph, cache)
  cgenWriteModules(graph.backend, graph.config)
  if gCmd != cmdRun:
    let proj = changeFileExt(gProjectFull, "")
    extccomp.callCCompiler(proj)
    extccomp.writeJsonBuildInstructions(proj)
    if optGenScript in gGlobalOptions:
      writeDepsFile(graph, toGeneratedFile(proj, ""))

proc commandJsonScript(graph: ModuleGraph; cache: IdentCache) =
  let proj = changeFileExt(gProjectFull, "")
  extccomp.runJsonBuildInstructions(proj)

proc commandCompileToJS(graph: ModuleGraph; cache: IdentCache) =
  #incl(gGlobalOptions, optSafeCode)
  setTarget(osJS, cpuJS)
  #initDefines()
  defineSymbol("nimrod") # 'nimrod' is always defined
  defineSymbol("ecmascript") # For backward compatibility
  defineSymbol("js")
  if gCmd == cmdCompileToPHP: defineSymbol("nimphp")
  semanticPasses()
  registerPass(JSgenPass)
  compileProject(graph, cache)

proc interactivePasses(graph: ModuleGraph; cache: IdentCache) =
  #incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  defineSymbol("nimscript")
  when hasFFI: defineSymbol("nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

proc commandInteractive(graph: ModuleGraph; cache: IdentCache) =
  msgs.gErrorMax = high(int)  # do not stop after first error
  interactivePasses(graph, cache)
  compileSystemModule(graph, cache)
  if commandArgs.len > 0:
    discard graph.compileModule(fileInfoIdx(gProjectFull), cache, {})
  else:
    var m = graph.makeStdinModule()
    incl(m.flags, sfMainModule)
    processModule(graph, m, llStreamOpenStdIn(), nil, cache)

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(graph: ModuleGraph; nodes: PNode, module: PSym; cache: IdentCache) =
  carryPasses(graph, nodes, module, cache, evalPasses)

proc commandEval(graph: ModuleGraph; cache: IdentCache; exp: string) =
  if systemModule == nil:
    interactivePasses(graph, cache)
    compileSystemModule(graph, cache)
  let echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(graph, echoExp.parseString(cache), makeStdinModule(graph), cache)

proc commandScan(cache: IdentCache) =
  var f = addFileExt(mainCommandArg(), NimExt)
  var stream = llStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: TLexer
      tok: TToken
    initToken(tok)
    openLexer(L, f, stream, cache)
    while true:
      rawGetTok(L, tok)
      printTok(tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(errCannotOpenFile, f)

const
  SimulateCaasMemReset = false
  PrintRopeCacheStats = false

proc mainCommand*(graph: ModuleGraph; cache: IdentCache) =
  when SimulateCaasMemReset:
    gGlobalOptions.incl(optCaasEnabled)

  setupModuleCache()
  # In "nim serve" scenario, each command must reset the registered passes
  clearPasses()
  gLastCmdTime = epochTime()
  searchPaths.add(options.libpath)
  when false: # gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)
  setId(100)
  case command.normalize
  of "c", "cc", "compile", "compiletoc":
    # compile means compileToC currently
    gCmd = cmdCompileToC
    commandCompileToC(graph, cache)
  of "cpp", "compiletocpp":
    gCmd = cmdCompileToCpp
    defineSymbol("cpp")
    commandCompileToC(graph, cache)
  of "objc", "compiletooc":
    gCmd = cmdCompileToOC
    defineSymbol("objc")
    commandCompileToC(graph, cache)
  of "run":
    gCmd = cmdRun
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      commandCompileToC(graph, cache)
    else:
      rawMessage(errInvalidCommandX, command)
  of "js", "compiletojs":
    gCmd = cmdCompileToJS
    commandCompileToJS(graph, cache)
  of "php":
    gCmd = cmdCompileToPHP
    commandCompileToJS(graph, cache)
  of "doc0":
    wantMainModule()
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    commandDoc()
  of "doc2", "doc":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    defineSymbol("nimdoc")
    commandDoc2(graph, cache, false)
  of "rst2html":
    gCmd = cmdRst2html
    loadConfigs(DocConfig, cache)
    commandRst2Html()
  of "rst2tex":
    gCmd = cmdRst2tex
    loadConfigs(DocTexConfig, cache)
    commandRst2TeX()
  of "jsondoc0":
    wantMainModule()
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    wantMainModule()
    defineSymbol("nimdoc")
    commandJson()
  of "jsondoc2", "jsondoc":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    wantMainModule()
    defineSymbol("nimdoc")
    commandDoc2(graph, cache, true)
  of "ctags":
    wantMainModule()
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    wantMainModule()
    defineSymbol("nimdoc")
    commandTags()
  of "buildindex":
    gCmd = cmdDoc
    loadConfigs(DocConfig, cache)
    commandBuildIndex()
  of "gendepend":
    gCmd = cmdGenDepend
    commandGenDepend(graph, cache)
  of "dump":
    gCmd = cmdDump
    if getConfigVar("dump.format") == "json":
      wantMainModule()

      var definedSymbols = newJArray()
      for s in definedSymbolNames(): definedSymbols.elems.add(%s)

      var libpaths = newJArray()
      for dir in searchPaths: libpaths.elems.add(%dir)

      var dumpdata = % [
        (key: "version", val: %VersionAsString),
        (key: "project_path", val: %gProjectFull),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: libpaths)
      ]

      msgWriteln($dumpdata, {msgStdout, msgSkipHook})
    else:
      msgWriteln("-- list of currently defined symbols --",
                 {msgStdout, msgSkipHook})
      for s in definedSymbolNames(): msgWriteln(s, {msgStdout, msgSkipHook})
      msgWriteln("-- end of list --", {msgStdout, msgSkipHook})

      for it in searchPaths: msgWriteln(it)
  of "check":
    gCmd = cmdCheck
    commandCheck(graph, cache)
  of "parse":
    gCmd = cmdParse
    wantMainModule()
    discard parseFile(gProjectMainIdx, cache)
  of "scan":
    gCmd = cmdScan
    wantMainModule()
    commandScan(cache)
    msgWriteln("Beware: Indentation tokens depend on the parser's state!")
  of "secret":
    gCmd = cmdInteractive
    commandInteractive(graph, cache)
  of "e":
    commandEval(graph, cache, mainCommandArg())
  of "nop", "help":
    # prevent the "success" message:
    gCmd = cmdDump
  of "jsonscript":
    gCmd = cmdJsonScript
    commandJsonScript(graph, cache)
  else:
    rawMessage(errInvalidCommandX, command)

  if msgs.gErrorCounter == 0 and
     gCmd notin {cmdInterpret, cmdRun, cmdDump}:
    when declared(system.getMaxMem):
      let usedMem = formatSize(getMaxMem()) & " peakmem"
    else:
      let usedMem = formatSize(getTotalMem())
    rawMessage(hintSuccessX, [$gLinesCompiled,
               formatFloat(epochTime() - gLastCmdTime, ffDecimal, 3),
               usedMem,
               if condSyms.isDefined("release"): "Release Build"
               else: "Debug Build"])

  when PrintRopeCacheStats:
    echo "rope cache stats: "
    echo "  tries : ", gCacheTries
    echo "  misses: ", gCacheMisses
    echo "  int tries: ", gCacheIntTries
    echo "  efficiency: ", formatFloat(1-(gCacheMisses.float/gCacheTries.float),
                                       ffDecimal, 3)

  when SimulateCaasMemReset:
    resetMemory()

  resetAttributes()

proc mainCommand*() = mainCommand(newModuleGraph(newConfigRef()), newIdentCache())
