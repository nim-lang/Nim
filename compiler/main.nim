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
  os, lists, condsyms, rodread, rodwrite, ropes, trees, 
  wordrecg, sem, semdata, idents, passes, docgen, extccomp,
  cgen, ecmasgen,
  platform, nimconf, importer, passaux, depends, evals, types, idgen,
  tables, docgen2, service, magicsys, parser

const
  has_LLVM_Backend = false

when has_LLVM_Backend:
  import llvmgen

proc MainCommand*()

# ------------------ module handling -----------------------------------------

var
  compMods = initTable[string, PSym]() # all compiled modules

# This expects a normalized module path
proc registerModule(filename: string, module: PSym) =
  compMods[filename] = module

# This expects a normalized module path
proc getModule(filename: string): PSym =
  result = compMods[filename]

var gModulesCount = 0
proc newModule(filename: string): PSym = 
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID. 
  new(result)
  result.id = - 1             # for better error checking
  result.kind = skModule
  result.name = getIdent(splitFile(filename).name)
  if not isNimrodIdentifier(result.name.s):
    rawMessage(errInvalidModuleName, result.name.s)
  
  result.owner = result       # a module belongs to itself
  result.info = newLineInfo(filename, 1, 1)
  result.position = gModulesCount
  inc gModulesCount
  incl(result.flags, sfUsed)
  initStrTable(result.tab)
  RegisterModule(filename, result)
  StrTableAdd(result.tab, result) # a module knows itself
  
proc CompileModule(filename: string, flags: TSymFlags): PSym
proc importModule(filename: string): PSym = 
  # this is called by the semantic checking phase
  result = getModule(filename)
  if result == nil: 
    # compile the module
    result = compileModule(filename, {})
  elif sfSystemModule in result.flags: 
    LocalError(result.info, errAttemptToRedefine, result.Name.s)
  
proc CompileModule(filename: string, flags: TSymFlags): PSym =
  var rd: PRodReader = nil
  var f = addFileExt(filename, nimExt)
  result = newModule(f)
  result.flags = result.flags + flags
  if gCmd in {cmdCompileToC, cmdCompileToCpp, cmdCheck, cmdIdeTools}: 
    rd = handleSymbolFile(result, f)
    if result.id < 0: 
      InternalError("handleSymbolFile should have set the module\'s ID")
      return
  else:
    result.id = getID()
  processModule(result, f, nil, rd)

proc `==^`(a, b: string): bool =
  try:
    result = sameFile(a, b)
  except EOS:
    result = false

proc compileSystemModule =
  if magicsys.SystemModule == nil:
    discard CompileModule(options.libpath /"system", {sfSystemModule})

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
  compileProject()
  if gCmd != cmdRun:
    extccomp.CallCCompiler(changeFileExt(gProjectFull, ""))

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
    stdinModule = newModule("stdin")
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
    processModule(m, "stdin", LLStreamOpenStdIn(), nil)

const evalPasses = [verbosePass, semPass, evalPass]

proc evalNim(nodes: PNode, module: PSym, filename: string) =
  # we don't want to mess with gPasses here, because in nimrod serve
  # scenario, it may be set up properly for normal cgenPass() compilation
  carryPasses(nodes, module, filename, evalPasses)

proc commandEval(exp: string) =
  if SystemModule == nil:
    InteractivePasses()
    compileSystemModule()
  var echoExp = "echo \"eval\\t\", " & "repr(" & exp & ")"
  evalNim(echoExp.parseString, makeStdinModule(), "stdin")

proc CommandPretty =
  var module = parseFile(addFileExt(mainCommandArg(), NimExt))
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
  
proc MainCommand =
  # In "nimrod serve" scenario, each command must reset the registered passes
  clearPasses()
  appendStr(searchPaths, options.libpath)
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)
  setID(100)
  passes.gIncludeFile = syntaxes.parseFile
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
    discard parseFile(addFileExt(gProjectFull, nimExt))
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
    gCmd = cmdIdeTools
    msgs.gErrorMax = high(int)  # do not stop after first error     
    serve(MainCommand)
    
  else: rawMessage(errInvalidCommandX, command)

