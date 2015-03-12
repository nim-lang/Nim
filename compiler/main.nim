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
  tables, docgen2, service, parser, modules, ccgutils, sigmatch, ropes, lists

from magicsys import systemModule, resetSysTypes

proc rodPass =
  if optSymbolFiles in gGlobalOptions:
    registerPass(rodwritePass)

proc codegenPass =
  registerPass cgenPass

proc semanticPasses =
  registerPass verbosePass
  registerPass semPass

proc commandGenDepend =
  semanticPasses()
  registerPass(gendependPass)
  registerPass(cleanupPass)
  compileProject()
  generateDot(gProjectFull)
  execExternalProgram("dot -Tpng -o" & changeFileExt(gProjectFull, "png") &
      ' ' & changeFileExt(gProjectFull, "dot"))

proc commandCheck =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()            # use an empty backend for semantic checking only
  rodPass()
  compileProject()

proc commandDoc2 =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  registerPass(docgen2Pass)
  #registerPass(cleanupPass())
  compileProject()
  finishDoc2Pass(gProjectName)

proc commandCompileToC =
  semanticPasses()
  registerPass(cgenPass)
  rodPass()
  #registerPass(cleanupPass())

  compileProject()
  cgenWriteModules()
  if gCmd != cmdRun:
    extccomp.callCCompiler(if gProjectName == "-": "stdinfile" else: changeFileExt(gProjectFull, ""))

  if isServing:
    # caas will keep track only of the compilation commands
    lastCaasCmd = curCaasCmd
    resetCgenModules()
    for i in 0 .. <gMemCacheData.len:
      gMemCacheData[i].crcStatus = crcCached
      gMemCacheData[i].needsRecompile = Maybe

      # XXX: clean these global vars
      # ccgstmts.gBreakpoints
      # ccgthreadvars.nimtv
      # ccgthreadvars.nimtVDeps
      # ccgthreadvars.nimtvDeclared
      # cgendata
      # cgmeth?
      # condsyms?
      # depends?
      # lexer.gLinesCompiled
      # msgs - error counts
      # magicsys, when system.nim changes
      # rodread.rodcompilerProcs
      # rodread.gTypeTable
      # rodread.gMods

      # !! ropes.cache
      # semthreads.computed?
      #
      # suggest.usageSym
      #
      # XXX: can we run out of IDs?
      # XXX: detect config reloading (implement as error/require restart)
      # XXX: options are appended (they will accumulate over time)
    resetCompilationLists()
    ccgutils.resetCaches()
    GC_fullCollect()

proc commandCompileToJS =
  #incl(gGlobalOptions, optSafeCode)
  setTarget(osJS, cpuJS)
  #initDefines()
  defineSymbol("nimrod") # 'nimrod' is always defined
  defineSymbol("ecmascript") # For backward compatibility
  defineSymbol("js")
  semanticPasses()
  registerPass(JSgenPass)
  compileProject()

proc interactivePasses =
  #incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  defineSymbol("nimrodvm")
  when hasFFI: defineSymbol("nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

proc commandInteractive =
  msgs.gErrorMax = high(int)  # do not stop after first error
  interactivePasses()
  compileSystemModule()
  if commandArgs.len > 0:
    discard compileModule(fileInfoIdx(gProjectFull), {})
  else:
    var m = makeStdinModule()
    incl(m.flags, sfMainModule)
    processModule(m, llStreamOpenStdIn(), nil)

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(nodes: PNode, module: PSym) =
  carryPasses(nodes, module, evalPasses)

proc commandEval(exp: string) =
  if systemModule == nil:
    interactivePasses()
    compileSystemModule()
  var echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(echoExp.parseString, makeStdinModule())

proc commandScan =
  var f = addFileExt(mainCommandArg(), NimExt)
  var stream = llStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: TLexer
      tok: TToken
    initToken(tok)
    openLexer(L, f, stream)
    while true:
      rawGetTok(L, tok)
      printTok(tok)
      if tok.tokType == tkEof: break
    closeLexer(L)
  else:
    rawMessage(errCannotOpenFile, f)

proc commandSuggest =
  if isServing:
    # XXX: hacky work-around ahead
    # Currently, it's possible to issue a idetools command, before
    # issuing the first compile command. This will leave the compiler
    # cache in a state where "no recompilation is necessary", but the
    # cgen pass was never executed at all.
    commandCompileToC()
    let gDirtyBufferIdx = gTrackPos.fileIndex
    discard compileModule(gDirtyBufferIdx, {sfDirty})
    resetModule(gDirtyBufferIdx)
  else:
    msgs.gErrorMax = high(int)  # do not stop after first error
    semanticPasses()
    rodPass()
    # XXX: this handles the case when the dirty buffer is the main file,
    # but doesn't handle the case when it's imported module
    #var projFile = if gProjectMainIdx == gDirtyOriginalIdx: gDirtyBufferIdx
    #               else: gProjectMainIdx
    compileProject() #(projFile)

proc resetMemory =
  resetCompilationLists()
  ccgutils.resetCaches()
  resetAllModules()
  resetRopeCache()
  resetSysTypes()
  gOwners = @[]
  rangeDestructorProc = nil
  for i in low(buckets)..high(buckets):
    buckets[i] = nil
  idAnon = nil

  # XXX: clean these global vars
  # ccgstmts.gBreakpoints
  # ccgthreadvars.nimtv
  # ccgthreadvars.nimtVDeps
  # ccgthreadvars.nimtvDeclared
  # cgendata
  # cgmeth?
  # condsyms?
  # depends?
  # lexer.gLinesCompiled
  # msgs - error counts
  # magicsys, when system.nim changes
  # rodread.rodcompilerProcs
  # rodread.gTypeTable
  # rodread.gMods

  # !! ropes.cache
  #
  # suggest.usageSym
  #
  # XXX: can we run out of IDs?
  # XXX: detect config reloading (implement as error/require restart)
  # XXX: options are appended (they will accumulate over time)
  # vis = visimpl
  when compileOption("gc", "v2"):
    gcDebugging = true
    echo "COLLECT 1"
    GC_fullCollect()
    echo "COLLECT 2"
    GC_fullCollect()
    echo "COLLECT 3"
    GC_fullCollect()
    echo GC_getStatistics()

const
  SimulateCaasMemReset = false
  PrintRopeCacheStats = false

proc mainCommand* =
  when SimulateCaasMemReset:
    gGlobalOptions.incl(optCaasEnabled)

  # In "nimrod serve" scenario, each command must reset the registered passes
  clearPasses()
  gLastCmdTime = epochTime()
  appendStr(searchPaths, options.libpath)
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)
  setId(100)
  case command.normalize
  of "c", "cc", "compile", "compiletoc":
    # compile means compileToC currently
    gCmd = cmdCompileToC
    commandCompileToC()
  of "cpp", "compiletocpp":
    gCmd = cmdCompileToCpp
    defineSymbol("cpp")
    commandCompileToC()
  of "objc", "compiletooc":
    gCmd = cmdCompileToOC
    defineSymbol("objc")
    commandCompileToC()
  of "run":
    gCmd = cmdRun
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      commandCompileToC()
    else:
      rawMessage(errInvalidCommandX, command)
  of "js", "compiletojs":
    gCmd = cmdCompileToJS
    commandCompileToJS()
  of "doc":
    wantMainModule()
    gCmd = cmdDoc
    loadConfigs(DocConfig)
    commandDoc()
  of "doc2":
    gCmd = cmdDoc
    loadConfigs(DocConfig)
    defineSymbol("nimdoc")
    commandDoc2()
  of "rst2html":
    gCmd = cmdRst2html
    loadConfigs(DocConfig)
    commandRst2Html()
  of "rst2tex":
    gCmd = cmdRst2tex
    loadConfigs(DocTexConfig)
    commandRst2TeX()
  of "jsondoc":
    wantMainModule()
    gCmd = cmdDoc
    loadConfigs(DocConfig)
    wantMainModule()
    defineSymbol("nimdoc")
    commandJSON()
  of "buildindex":
    gCmd = cmdDoc
    loadConfigs(DocConfig)
    commandBuildIndex()
  of "gendepend":
    gCmd = cmdGenDepend
    commandGenDepend()
  of "dump":
    gCmd = cmdDump
    if getConfigVar("dump.format") == "json":
      wantMainModule()

      var definedSymbols = newJArray()
      for s in definedSymbolNames(): definedSymbols.elems.add(%s)

      var libpaths = newJArray()
      for dir in iterSearchPath(searchPaths): libpaths.elems.add(%dir)

      var dumpdata = % [
        (key: "version", val: %VersionAsString),
        (key: "project_path", val: %gProjectFull),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: libpaths)
      ]

      outWriteln($dumpdata)
    else:
      outWriteln("-- list of currently defined symbols --")
      for s in definedSymbolNames(): outWriteln(s)
      outWriteln("-- end of list --")

      for it in iterSearchPath(searchPaths): msgWriteln(it)
  of "check":
    gCmd = cmdCheck
    commandCheck()
  of "parse":
    gCmd = cmdParse
    wantMainModule()
    discard parseFile(gProjectMainIdx)
  of "scan":
    gCmd = cmdScan
    wantMainModule()
    commandScan()
    msgWriteln("Beware: Indentation tokens depend on the parser\'s state!")
  of "i":
    gCmd = cmdInteractive
    commandInteractive()
  of "e":
    # XXX: temporary command for easier testing
    commandEval(mainCommandArg())
  of "reset":
    resetMemory()
  of "idetools":
    gCmd = cmdIdeTools
    if gEvalExpr != "":
      commandEval(gEvalExpr)
    else:
      commandSuggest()
  of "serve":
    isServing = true
    gGlobalOptions.incl(optCaasEnabled)
    msgs.gErrorMax = high(int)  # do not stop after first error
    serve(mainCommand)
  else:
    rawMessage(errInvalidCommandX, command)

  if (msgs.gErrorCounter == 0 and
      gCmd notin {cmdInterpret, cmdRun, cmdDump} and
      gVerbosity > 0):
    rawMessage(hintSuccessX, [$gLinesCompiled,
               formatFloat(epochTime() - gLastCmdTime, ffDecimal, 3),
               formatSize(getTotalMem()),
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

