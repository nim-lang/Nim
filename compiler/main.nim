#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# implements the command dispatcher and several commands as well as the
# module handling

import 
  llstream, strutils, ast, astalgo, lexer, syntaxes, renderer, options, msgs, 
  os, lists, condsyms, rodread, rodwrite, ropes, trees, times,
  wordrecg, sem, semdata, idents, passes, docgen, extccomp,
  cgen, ecmasgen, cgendata,
  platform, nimconf, importer, passaux, depends, evals, types, idgen,
  tables, docgen2, service, magicsys, parser, crc, ccgutils

const
  has_LLVM_Backend = false

when has_LLVM_Backend:
  import llvmgen

proc MainCommand*()

# ------------------ module handling -----------------------------------------

type
  TNeedRecompile = enum Maybe, No, Yes, Probing, Recompiled
  TCrcStatus = enum crcNotTaken, crcCached, crcHasChanged, crcNotChanged

  TModuleInMemory = object
    compiledAt: float
    crc: TCrc32
    deps: seq[int32] ## XXX: slurped files are not currently tracked
    needsRecompile: TNeedRecompile
    crcStatus: TCrcStatus

var
  gCompiledModules: seq[PSym] = @[]
  gMemCacheData: seq[TModuleInMemory] = @[]
    ## XXX: we should implement recycling of file IDs
    ## if the user keeps renaming modules, the file IDs will keep growing

proc getModule(fileIdx: int32): PSym =
  if fileIdx >= 0 and fileIdx < gCompiledModules.len:
    result = gCompiledModules[fileIdx]
  else:
    result = nil

template compiledAt(x: PSym): expr =
  gMemCacheData[x.position].compiledAt

template crc(x: PSym): expr =
  gMemCacheData[x.position].crc

proc crcChanged(fileIdx: int32): bool =
  InternalAssert fileIdx >= 0 and fileIdx < gMemCacheData.len
  
  template updateStatus =
    gMemCacheData[fileIdx].crcStatus = if result: crcHasChanged
                                       else: crcNotChanged
    # echo "TESTING CRC: ", fileIdx.toFilename, " ", result
    
  case gMemCacheData[fileIdx].crcStatus:
  of crcHasChanged:
    result = true
  of crcNotChanged:
    result = false
  of crcCached:
    let newCrc = crcFromFile(fileIdx.toFilename)
    result = newCrc != gMemCacheData[fileIdx].crc
    gMemCacheData[fileIdx].crc = newCrc
    updateStatus()
  of crcNotTaken:
    gMemCacheData[fileIdx].crc = crcFromFile(fileIdx.toFilename)
    result = true
    updateStatus()

proc doCRC(fileIdx: int32) =
  if gMemCacheData[fileIdx].crcStatus == crcNotTaken:
    # echo "FIRST CRC: ", fileIdx.ToFilename
    gMemCacheData[fileIdx].crc = crcFromFile(fileIdx.toFilename)

proc addDep(x: Psym, dep: int32) =
  growCache gMemCacheData, dep
  gMemCacheData[x.position].deps.safeAdd(dep)

proc checkDepMem(fileIdx: int32): TNeedRecompile  =
  template markDirty =
    echo "HARD RESETTING ", fileIdx.toFilename
    gMemCacheData[fileIdx].needsRecompile = Yes
    gCompiledModules[fileIdx] = nil
    cgendata.gModules[fileIdx] = nil
      
    return Yes

  if gMemCacheData[fileIdx].needsRecompile != Maybe:
    return gMemCacheData[fileIdx].needsRecompile

  if optForceFullMake in gGlobalOptions or
     curCaasCmd != lastCaasCmd or
     crcChanged(fileIdx): markDirty
  
  if gMemCacheData[fileIdx].deps != nil:
    gMemCacheData[fileIdx].needsRecompile = Probing
    for dep in gMemCacheData[fileIdx].deps:
      let d = checkDepMem(dep)
      if d in { Yes, Recompiled }:
        echo fileIdx.toFilename, " depends on ", dep.toFilename, " ", d
        markDirty
  
  gMemCacheData[fileIdx].needsRecompile = No
  return No

proc newModule(fileIdx: int32): PSym =
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID. 
  new(result)
  result.id = - 1             # for better error checking
  result.kind = skModule
  let filename = fileIdx.toFilename
  result.name = getIdent(splitFile(filename).name)
  if not isNimrodIdentifier(result.name.s):
    rawMessage(errInvalidModuleName, result.name.s)
  
  result.owner = result       # a module belongs to itself
  result.info = newLineInfo(fileIdx, 1, 1)
  result.position = fileIdx
  
  growCache gMemCacheData, fileIdx
  growCache gCompiledModules, fileIdx
  gCompiledModules[result.position] = result
  
  incl(result.flags, sfUsed)
  initStrTable(result.tab)
  StrTableAdd(result.tab, result) # a module knows itself

proc compileModule(fileIdx: int32, flags: TSymFlags): PSym =
  result = getModule(fileIdx)
  if result == nil:
    growCache gMemCacheData, fileIdx
    gMemCacheData[fileIdx].needsRecompile = Probing
    result = newModule(fileIdx)
    var rd = handleSymbolFile(result)
    result.flags = result.flags + flags
    if gCmd in {cmdCompileToC, cmdCompileToCpp, cmdCheck, cmdIdeTools}:
      rd = handleSymbolFile(result)
      if result.id < 0: 
        InternalError("handleSymbolFile should have set the module\'s ID")
        return
    else:
      result.id = getID()
    processModule(result, nil, rd)
    if optCaasEnabled in gGlobalOptions:
      gMemCacheData[fileIdx].compiledAt = gLastCmdTime
      gMemCacheData[fileIdx].needsRecompile = Recompiled
      doCRC fileIdx
  else:
    if checkDepMem(fileIdx) == Yes:
      result = CompileModule(fileIdx, flags)
    else:
      result = gCompiledModules[fileIdx]

proc compileModule(filename: string, flags: TSymFlags): PSym =
  result = compileModule(filename.fileInfoIdx, flags)

proc importModule(s: PSym, fileIdx: int32): PSym =
  # this is called by the semantic checking phase
  result = compileModule(fileIdx, {})
  if optCaasEnabled in gGlobalOptions: addDep(s, fileIdx)
  if sfSystemModule in result.flags:
    LocalError(result.info, errAttemptToRedefine, result.Name.s)

proc includeModule(s: PSym, fileIdx: int32): PNode =
  result = syntaxes.parseFile(fileIdx)
  if optCaasEnabled in gGlobalOptions:
    growCache gMemCacheData, fileIdx
    addDep(s, fileIdx)
    doCrc(fileIdx)

proc `==^`(a, b: string): bool =
  try:
    result = sameFile(a, b)
  except EOS:
    result = false

proc compileSystemModule =
  if magicsys.SystemModule == nil:
    SystemFileIdx = fileInfoIdx(options.libpath/"system.nim")
    discard CompileModule(SystemFileIdx, {sfSystemModule})

proc CompileProject(projectFile = gProjectFull) =
  let systemFile = options.libpath / "system"
  if projectFile.addFileExt(nimExt) ==^ systemFile.addFileExt(nimExt):
    discard CompileModule(projectFile, {sfMainModule, sfSystemModule})
  else:
    compileSystemModule()
    discard CompileModule(projectFile, {sfMainModule})

proc rodPass =
  if optSymbolFiles in gGlobalOptions:
    registerPass(rodwritePass)

proc semanticPasses =
  registerPass verbosePass
  registerPass semPass

proc CommandGenDepend =
  semanticPasses()
  registerPass(genDependPass)
  registerPass(cleanupPass)
  compileProject()
  generateDot(gProjectFull)
  execExternalProgram("dot -Tpng -o" & changeFileExt(gProjectFull, "png") &
      ' ' & changeFileExt(gProjectFull, "dot"))

proc CommandCheck =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()            # use an empty backend for semantic checking only
  rodPass()
  compileProject(mainCommandArg())

proc CommandDoc2 =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  registerPass(docgen2Pass)
  #registerPass(cleanupPass())
  compileProject(mainCommandArg())
  finishDoc2Pass(gProjectFull)

proc CommandCompileToC =
  semanticPasses()
  registerPass(cgenPass)
  rodPass()
  #registerPass(cleanupPass())
  if optCaasEnabled in gGlobalOptions:
    # echo "BEFORE CHECK DEP"
    # discard checkDepMem(gProjectMainIdx)
    # echo "CHECK DEP COMPLETE"

  compileProject()

  if optCaasEnabled in gGlobalOptions:
    cgenCaasUpdate()

  if gCmd != cmdRun:
    extccomp.CallCCompiler(changeFileExt(gProjectFull, ""))

  if optCaasEnabled in gGlobalOptions:
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
      # !! semdata.gGenericsCache
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

when has_LLVM_Backend:
  proc CommandCompileToLLVM =
    semanticPasses()
    registerPass(llvmgen.llvmgenPass())
    rodPass()
    #registerPass(cleanupPass())
    compileProject()

proc CommandCompileToEcmaScript =
  incl(gGlobalOptions, optSafeCode)
  setTarget(osEcmaScript, cpuEcmaScript)
  #initDefines()
  DefineSymbol("nimrod") # 'nimrod' is always defined
  DefineSymbol("ecmascript")
  semanticPasses()
  registerPass(ecmasgenPass)
  compileProject()

proc InteractivePasses =
  incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  DefineSymbol("nimrodvm")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

var stdinModule: PSym
proc makeStdinModule: PSym =
  if stdinModule == nil:
    stdinModule = newModule(gCmdLineInfo.fileIndex)
    stdinModule.id = getID()
  result = stdinModule

proc CommandInteractive =
  msgs.gErrorMax = high(int)  # do not stop after first error
  InteractivePasses()
  compileSystemModule()
  if commandArgs.len > 0:
    discard CompileModule(mainCommandArg(), {})
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

proc CommandPretty =
  var projectFile = addFileExt(mainCommandArg(), NimExt)
  var module = parseFile(projectFile.fileInfoIdx)
  if module != nil: 
    renderModule(module, getOutFile(mainCommandArg(), "pretty." & NimExt))
  
proc CommandScan =
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
  
proc CommandSuggest =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  rodPass()
  compileProject()

proc wantMainModule =
  if gProjectFull.len == 0:
    Fatal(gCmdLineInfo, errCommandExpectsFilename)
  gProjectMainIdx = addFileExt(gProjectFull, nimExt).fileInfoIdx
  
proc MainCommand =
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
  of "js", "compiletoecmascript": 
    gCmd = cmdCompileToEcmaScript
    wantMainModule()
    CommandCompileToEcmaScript()
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
  of "buildindex":
    gCmd = cmdDoc
    LoadConfigs(DocConfig)
    CommandBuildIndex()
  of "gendepend": 
    gCmd = cmdGenDepend
    wantMainModule()
    CommandGenDepend()
  of "dump": 
    gCmd = cmdDump
    condsyms.ListSymbols()
    for it in iterSearchPath(): MsgWriteln(it)
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
  of "idetools":
    gCmd = cmdIdeTools
    if gEvalExpr != "":
      commandEval(gEvalExpr)
    else:
      wantMainModule()
      CommandSuggest()
  of "serve":
    gGlobalOptions.incl(optCaasEnabled)
    msgs.gErrorMax = high(int)  # do not stop after first error     
    serve(MainCommand)
    
  else: rawMessage(errInvalidCommandX, command)
  
  if msgs.gErrorCounter == 0 and gCmd notin {cmdInterpret, cmdRun}:
    rawMessage(hintSuccessX, [$gLinesCompiled,
               formatFloat(epochTime() - gLastCmdTime, ffDecimal, 3),
               formatSize(getTotalMem())])

