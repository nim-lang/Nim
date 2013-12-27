#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
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
  tables, docgen2, service, parser, modules, ccgutils, sigmatch, ropes, lists,
  pretty

from magicsys import SystemModule, resetSysTypes

const
  hasLLVM_Backend = false

when hasLLVM_Backend:
  import llvmgen

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
  registerPass(genDependPass)
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
  if optCaasEnabled in gGlobalOptions:
    # echo "BEFORE CHECK DEP"
    # discard checkDepMem(gProjectMainIdx)
    # echo "CHECK DEP COMPLETE"

  compileProject()
  cgenWriteModules()
  if gCmd != cmdRun:
    extccomp.CallCCompiler(changeFileExt(gProjectFull, ""))

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

when hasLLVM_Backend:
  proc commandCompileToLLVM =
    semanticPasses()
    registerPass(llvmgen.llvmgenPass())
    rodPass()
    #registerPass(cleanupPass())
    compileProject()

proc commandCompileToJS =
  #incl(gGlobalOptions, optSafeCode)
  setTarget(osJS, cpuJS)
  #initDefines()
  DefineSymbol("nimrod") # 'nimrod' is always defined
  DefineSymbol("ecmascript") # For backward compatibility
  DefineSymbol("js")
  semanticPasses()
  registerPass(jsgenPass)
  compileProject()

proc interactivePasses =
  #incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  DefineSymbol("nimrodvm")
  when hasFFI: DefineSymbol("nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

proc commandInteractive =
  msgs.gErrorMax = high(int)  # do not stop after first error
  InteractivePasses()
  compileSystemModule()
  if commandArgs.len > 0:
    discard CompileModule(fileInfoIdx(gProjectFull), {})
  else:
    var m = makeStdinModule()
    incl(m.flags, sfMainModule)
    processModule(m, LLStreamOpenStdIn(), nil)

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(nodes: PNode, module: PSym) =
  carryPasses(nodes, module, evalPasses)

proc commandEval(exp: string) =
  if SystemModule == nil:
    InteractivePasses()
    compileSystemModule()
  var echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(echoExp.parseString, makeStdinModule())

proc commandPrettyOld =
  var projectFile = addFileExt(mainCommandArg(), NimExt)
  var module = parseFile(projectFile.fileInfoIdx)
  if module != nil:
    renderModule(module, getOutFile(mainCommandArg(), "pretty." & NimExt))

proc commandPretty =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  registerPass(prettyPass)
  compileProject()
  pretty.overwriteFiles()

proc commandScan =
  var f = addFileExt(mainCommandArg(), nimExt)
  var stream = LLStreamOpen(f, fmRead)
  if stream != nil:
    var
      L: TLexer
      tok: TToken
    initToken(tok)
    openLexer(L, f, stream)
    while true:
      rawGetTok(L, tok)
      PrintTok(tok)
      if tok.tokType == tkEof: break
    CloseLexer(L)
  else:
    rawMessage(errCannotOpenFile, f)

proc commandSuggest =
  if isServing:
    # XXX: hacky work-around ahead
    # Currently, it's possible to issue a idetools command, before
    # issuing the first compile command. This will leave the compiler
    # cache in a state where "no recompilation is necessary", but the
    # cgen pass was never executed at all.
    CommandCompileToC()
    if gDirtyBufferIdx != 0:
      discard compileModule(gDirtyBufferIdx, {sfDirty})
      resetModule(gDirtyBufferIdx)
    if optDef in gGlobalOptions:
      defFromSourceMap(optTrackPos)
  else:
    msgs.gErrorMax = high(int)  # do not stop after first error
    semanticPasses()
    rodPass()
    # XXX: this handles the case when the dirty buffer is the main file,
    # but doesn't handle the case when it's imported module
    var projFile = if gProjectMainIdx == gDirtyOriginalIdx: gDirtyBufferIdx
                   else: gProjectMainIdx
    compileProject(projFile)

proc wantMainModule =
  if gProjectFull.len == 0:
    if optMainModule.len == 0:
      Fatal(gCmdLineInfo, errCommandExpectsFilename)
    else:
      gProjectName = optMainModule
      gProjectFull = gProjectPath / gProjectName

  gProjectMainIdx = addFileExt(gProjectFull, nimExt).fileInfoIdx

proc requireMainModuleOption =
  if optMainModule.len == 0:
    Fatal(gCmdLineInfo, errMainModuleMustBeSpecified)
  else:
    gProjectName = optMainModule
    gProjectFull = gProjectPath / gProjectName

  gProjectMainIdx = addFileExt(gProjectFull, nimExt).fileInfoIdx

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
  # semthreads.computed?
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
  SimiluateCaasMemReset = false
  PrintRopeCacheStats = false

proc mainCommand* =
  when SimiluateCaasMemReset:
    gGlobalOptions.incl(optCaasEnabled)

  # In "nimrod serve" scenario, each command must reset the registered passes
  clearPasses()
  gLastCmdTime = epochTime()
  appendStr(searchPaths, options.libpath)
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)
  setID(100)
  passes.gIncludeFile = includeModule
  passes.gImportModule = importModule
  case command.normalize
  of "c", "cc", "compile", "compiletoc":
    # compile means compileToC currently
    gCmd = cmdCompileToC
    wantMainModule()
    CommandCompileToC()
  of "cpp", "compiletocpp":
    extccomp.cExt = ".cpp"
    gCmd = cmdCompileToCpp
    if cCompiler == ccGcc: setCC("gpp")
    wantMainModule()
    DefineSymbol("cpp")
    CommandCompileToC()
  of "objc", "compiletooc":
    extccomp.cExt = ".m"
    gCmd = cmdCompileToOC
    wantMainModule()
    DefineSymbol("objc")
    CommandCompileToC()
  of "run":
    gCmd = cmdRun
    wantMainModule()
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      CommandCompileToC()
    else:
      rawMessage(errInvalidCommandX, command)
  of "js", "compiletojs":
    gCmd = cmdCompileToJS
    wantMainModule()
    CommandCompileToJS()
  of "compiletollvm":
    gCmd = cmdCompileToLLVM
    wantMainModule()
    when has_LLVM_Backend:
      CommandCompileToLLVM()
    else:
      rawMessage(errInvalidCommandX, command)
  of "pretty":
    gCmd = cmdPretty
    wantMainModule()
    CommandPretty()
  of "doc":
    gCmd = cmdDoc
    LoadConfigs(DocConfig)
    wantMainModule()
    CommandDoc()
  of "doc2":
    gCmd = cmdDoc
    LoadConfigs(DocConfig)
    wantMainModule()
    DefineSymbol("nimdoc")
    CommandDoc2()
  of "rst2html":
    gCmd = cmdRst2html
    LoadConfigs(DocConfig)
    wantMainModule()
    CommandRst2Html()
  of "rst2tex":
    gCmd = cmdRst2tex
    LoadConfigs(DocTexConfig)
    wantMainModule()
    CommandRst2TeX()
  of "jsondoc":
    gCmd = cmdDoc
    LoadConfigs(DocConfig)
    wantMainModule()
    DefineSymbol("nimdoc")
    CommandJSON()
  of "buildindex":
    gCmd = cmdDoc
    LoadConfigs(DocConfig)
    CommandBuildIndex()
  of "gendepend":
    gCmd = cmdGenDepend
    wantMainModule()
    CommandGenDepend()
  of "dump":
    gcmd = cmdDump
    if getconfigvar("dump.format") == "json":
      requireMainModuleOption()

      var definedSymbols = newJArray()
      for s in definedSymbolNames(): definedSymbols.elems.add(%s)

      var libpaths = newJArray()
      for dir in itersearchpath(searchpaths): libpaths.elems.add(%dir)

      var dumpdata = % [
        (key: "version", val: %VersionAsString),
        (key: "project_path", val: %gProjectFull),
        (key: "defined_symbols", val: definedSymbols),
        (key: "lib_paths", val: libpaths)
      ]

      outWriteLn($dumpdata)
    else:
      outWriteLn("-- list of currently defined symbols --")
      for s in definedSymbolNames(): outWriteLn(s)
      outWriteLn("-- end of list --")

      for it in iterSearchPath(searchpaths): msgWriteLn(it)
  of "check":
    gCmd = cmdCheck
    wantMainModule()
    CommandCheck()
  of "parse":
    gCmd = cmdParse
    wantMainModule()
    discard parseFile(gProjectMainIdx)
  of "scan":
    gCmd = cmdScan
    wantMainModule()
    CommandScan()
    MsgWriteln("Beware: Indentation tokens depend on the parser\'s state!")
  of "i":
    gCmd = cmdInteractive
    CommandInteractive()
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
      wantMainModule()
      CommandSuggest()
  of "serve":
    isServing = true
    gGlobalOptions.incl(optCaasEnabled)
    msgs.gErrorMax = high(int)  # do not stop after first error
    serve(MainCommand)
  else:
    rawMessage(errInvalidCommandX, command)

  if (msgs.gErrorCounter == 0 and
      gCmd notin {cmdInterpret, cmdRun, cmdDump} and
      gVerbosity > 0):
    rawMessage(hintSuccessX, [$gLinesCompiled,
               formatFloat(epochTime() - gLastCmdTime, ffDecimal, 3),
               formatSize(getTotalMem())])

  when PrintRopeCacheStats:
    echo "rope cache stats: "
    echo "  tries : ", gCacheTries
    echo "  misses: ", gCacheMisses
    echo "  int tries: ", gCacheIntTries
    echo "  efficiency: ", formatFloat(1-(gCacheMisses.float/gCacheTries.float), ffDecimal, 3)

  when SimiluateCaasMemReset:
    resetMemory()

