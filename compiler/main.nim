#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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
  platform, nimconf, importer, passaux, depends, transf, evals, types, idgen

const
  has_LLVM_Backend = false

when has_LLVM_Backend:
  import llvmgen

proc MainCommand*()

# ------------------ module handling -----------------------------------------

type 
  TFileModuleRec = tuple[filename: string, module: PSym]
  TFileModuleMap = seq[TFileModuleRec]

var compMods: TFileModuleMap = @[] # all compiled modules

proc registerModule(filename: string, module: PSym) = 
  compMods.add((filename, module))

proc getModule(filename: string): PSym = 
  for i in countup(0, high(compMods)): 
    if sameFile(compMods[i].filename, filename): 
      return compMods[i].module

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
  result = newModule(filename)
  result.flags = result.flags + flags
  if gCmd in {cmdCompileToC, cmdCompileToCpp}: 
    rd = handleSymbolFile(result, f)
    if result.id < 0: 
      InternalError("handleSymbolFile should have set the module\'s ID")
  else: 
    result.id = getID()
  processModule(result, f, nil, rd)

proc CompileProject(projectFile = projectFullPath) =
  discard CompileModule(options.libpath / "system", {sfSystemModule})
  discard CompileModule(projectFile, {sfMainModule})

proc semanticPasses =
  registerPass(verbosePass())
  registerPass(sem.semPass())
  registerPass(transf.transfPass())

proc CommandGenDepend =
  semanticPasses()
  registerPass(genDependPass())
  registerPass(cleanupPass())
  compileProject()
  generateDot(projectFullPath)
  execExternalProgram("dot -Tpng -o" & changeFileExt(projectFullPath, "png") &
      ' ' & changeFileExt(projectFullPath, "dot"))

proc CommandCheck =
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()            # use an empty backend for semantic checking only
  registerPass(rodwrite.rodwritePass())
  compileProject(mainCommandArg())

proc CommandCompileToC =
  semanticPasses()
  registerPass(cgen.cgenPass())
  registerPass(rodwrite.rodwritePass())
  #registerPass(cleanupPass())
  compileProject()
  if gCmd != cmdRun:
    extccomp.CallCCompiler(changeFileExt(projectFullPath, ""))

when has_LLVM_Backend:
  proc CommandCompileToLLVM =
    semanticPasses()
    registerPass(llvmgen.llvmgenPass())
    registerPass(rodwrite.rodwritePass())
    #registerPass(cleanupPass())
    compileProject()

proc CommandCompileToEcmaScript =
  incl(gGlobalOptions, optSafeCode)
  setTarget(osEcmaScript, cpuEcmaScript)
  initDefines()
  semanticPasses()
  registerPass(ecmasgenPass())
  compileProject()

proc CommandInteractive =
  msgs.gErrorMax = high(int)  # do not stop after first error
  incl(gGlobalOptions, optSafeCode)
  #setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  DefineSymbol("nimrodvm")
  registerPass(verbosePass())
  registerPass(sem.semPass())
  registerPass(evals.evalPass()) # load system module:
  discard CompileModule(options.libpath /"system", {sfSystemModule})
  if commandArgs.len > 0:
    discard CompileModule(mainCommandArg(), {})
  else:
    var m = newModule("stdin")
    m.id = getID()
    incl(m.flags, sfMainModule)
    processModule(m, "stdin", LLStreamOpenStdIn(), nil)

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
  registerPass(rodwrite.rodwritePass())
  compileProject()

proc wantMainModule =
  if projectFullPath.len == 0:
    Fatal(newLineInfo("command line", 1, 1), errCommandExpectsFilename)
  
proc MainCommand =
  appendStr(searchPaths, options.libpath)
  if projectFullPath.len != 0:
    # current path is dalways looked first for modules
    prependStr(searchPaths, projectPath)
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
    discard parseFile(addFileExt(projectFullPath, nimExt))
  of "scan": 
    gCmd = cmdScan
    wantMainModule()
    CommandScan()
    MsgWriteln("Beware: Indentation tokens depend on the parser\'s state!")
  of "i": 
    gCmd = cmdInteractive
    CommandInteractive()
  of "idetools":
    gCmd = cmdIdeTools
    wantMainModule()
    CommandSuggest()
  else: rawMessage(errInvalidCommandX, command)

