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
  platform, nimconf, importer, passaux, depends, transf, evals, types

const
  has_LLVM_Backend = false

when has_LLVM_Backend:
  import llvmgen

proc MainCommand*(cmd, filename: string)
# implementation
# ------------------ module handling -----------------------------------------

type 
  TFileModuleRec{.final.} = object 
    filename*: string
    module*: PSym

  TFileModuleMap = seq[TFileModuleRec]

var compMods: TFileModuleMap = @ []

proc registerModule(filename: string, module: PSym) = 
  # all compiled modules
  var length = len(compMods)
  setlen(compMods, length + 1)
  compMods[length].filename = filename
  compMods[length].module = module

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
  
proc CompileModule(filename: string, isMainFile, isSystemFile: bool): PSym
proc importModule(filename: string): PSym = 
  # this is called by the semantic checking phase
  result = getModule(filename)
  if result == nil: 
    # compile the module
    result = compileModule(filename, false, false)
  elif sfSystemModule in result.flags: 
    LocalError(result.info, errAttemptToRedefine, result.Name.s)
  
proc CompileModule(filename: string, isMainFile, isSystemFile: bool): PSym = 
  var rd: PRodReader = nil
  var f = addFileExt(filename, nimExt)
  result = newModule(filename)
  if isMainFile: incl(result.flags, sfMainModule)
  if isSystemFile: incl(result.flags, sfSystemModule)
  if (gCmd == cmdCompileToC) or (gCmd == cmdCompileToCpp): 
    rd = handleSymbolFile(result, f)
    if result.id < 0: 
      InternalError("handleSymbolFile should have set the module\'s ID")
  else: 
    result.id = getID()
  processModule(result, f, nil, rd)

proc CompileProject(filename: string) = 
  discard CompileModule(JoinPath(options.libpath, addFileExt("system", nimExt)), 
                        false, true)
  discard CompileModule(addFileExt(filename, nimExt), true, false)

proc semanticPasses() = 
  registerPass(verbosePass())
  registerPass(sem.semPass())
  registerPass(transf.transfPass())

proc CommandGenDepend(filename: string) = 
  semanticPasses()
  registerPass(genDependPass())
  registerPass(cleanupPass())
  compileProject(filename)
  generateDot(filename)
  execExternalProgram("dot -Tpng -o" & changeFileExt(filename, "png") & ' ' &
      changeFileExt(filename, "dot"))

proc CommandCheck(filename: string) = 
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()            # use an empty backend for semantic checking only
  compileProject(filename)

proc CommandCompileToC(filename: string) = 
  semanticPasses()
  registerPass(cgen.cgenPass())
  registerPass(rodwrite.rodwritePass())
  #registerPass(cleanupPass())
  compileProject(filename)
  if gCmd != cmdRun:
    extccomp.CallCCompiler(changeFileExt(filename, ""))

when has_LLVM_Backend:
  proc CommandCompileToLLVM(filename: string) = 
    semanticPasses()
    registerPass(llvmgen.llvmgenPass())
    registerPass(rodwrite.rodwritePass())
    #registerPass(cleanupPass())
    compileProject(filename)

proc CommandCompileToEcmaScript(filename: string) = 
  incl(gGlobalOptions, optSafeCode)
  setTarget(osEcmaScript, cpuEcmaScript)
  initDefines()
  semanticPasses()
  registerPass(ecmasgenPass())
  compileProject(filename)

proc CommandInteractive() = 
  msgs.gErrorMax = high(int)  # do not stop after first error
  incl(gGlobalOptions, optSafeCode)
  setTarget(osNimrodVM, cpuNimrodVM)
  initDefines()
  registerPass(verbosePass())
  registerPass(sem.semPass())
  registerPass(transf.transfPass())
  registerPass(evals.evalPass()) # load system module:
  discard CompileModule(JoinPath(options.libpath, addFileExt("system", nimExt)), 
                        false, true)
  var m = newModule("stdin")
  m.id = getID()
  incl(m.flags, sfMainModule)
  processModule(m, "stdin", LLStreamOpenStdIn(), nil)

proc CommandPretty(filename: string) = 
  var module = parseFile(addFileExt(filename, NimExt))
  if module != nil: 
    renderModule(module, getOutFile(filename, "pretty." & NimExt))
  
proc CommandScan(filename: string) = 
  var f = addFileExt(filename, nimExt)
  var stream = LLStreamOpen(f, fmRead)
  if stream != nil: 
    var 
      L: TLexer
      tok: PToken
    new(tok)
    openLexer(L, f, stream)
    while true: 
      rawGetTok(L, tok[])
      PrintTok(tok)
      if tok.tokType == tkEof: break 
    CloseLexer(L)
  else: 
    rawMessage(errCannotOpenFile, f)
  
proc CommandSuggest(filename: string) = 
  msgs.gErrorMax = high(int)  # do not stop after first error
  semanticPasses()
  compileProject(filename)

proc WantFile(filename: string) = 
  if filename == "": 
    Fatal(newLineInfo("command line", 1, 1), errCommandExpectsFilename)
  
proc MainCommand(cmd, filename: string) = 
  appendStr(searchPaths, options.libpath)
  if filename != "": 
    # current path is always looked first for modules
    prependStr(searchPaths, splitFile(filename).dir)
  setID(100)
  passes.gIncludeFile = syntaxes.parseFile
  passes.gImportModule = importModule
  case cmd.normalize
  of "c", "cc", "compile", "compiletoc": 
    # compile means compileToC currently
    gCmd = cmdCompileToC
    wantFile(filename)
    CommandCompileToC(filename)
  of "compiletocpp": 
    extccomp.cExt = ".cpp"
    gCmd = cmdCompileToCpp
    wantFile(filename)
    CommandCompileToC(filename)
  of "oc", "compiletooc":
    extccomp.cExt = ".m"
    gCmd = cmdCompileToOC
    wantFile(filename)
    CommandCompileToC(filename)
  of "run":
    gCmd = cmdRun
    wantFile(filename)
    when hasTinyCBackend:
      extccomp.setCC("tcc")
      CommandCompileToC(filename)
    else: 
      rawMessage(errInvalidCommandX, cmd)
  of "js", "compiletoecmascript": 
    gCmd = cmdCompileToEcmaScript
    wantFile(filename)
    CommandCompileToEcmaScript(filename)
  of "compiletollvm": 
    gCmd = cmdCompileToLLVM
    wantFile(filename)
    when has_LLVM_Backend:
      CommandCompileToLLVM(filename)
    else:
      rawMessage(errInvalidCommandX, cmd)
  of "pretty": 
    gCmd = cmdPretty
    wantFile(filename)        #CommandExportSymbols(filename);
    CommandPretty(filename)
  of "doc": 
    gCmd = cmdDoc
    LoadSpecialConfig(DocConfig)
    wantFile(filename)
    CommandDoc(filename)
  of "rst2html": 
    gCmd = cmdRst2html
    LoadSpecialConfig(DocConfig)
    wantFile(filename)
    CommandRst2Html(filename)
  of "rst2tex": 
    gCmd = cmdRst2tex
    LoadSpecialConfig(DocTexConfig)
    wantFile(filename)
    CommandRst2TeX(filename)
  of "gendepend": 
    gCmd = cmdGenDepend
    wantFile(filename)
    CommandGenDepend(filename)
  of "dump": 
    gCmd = cmdDump
    condsyms.ListSymbols()
    for it in iterSearchPath(): MsgWriteln(it)
  of "check": 
    gCmd = cmdCheck
    wantFile(filename)
    CommandCheck(filename)
  of "parse": 
    gCmd = cmdParse
    wantFile(filename)
    discard parseFile(addFileExt(filename, nimExt))
  of "scan": 
    gCmd = cmdScan
    wantFile(filename)
    CommandScan(filename)
    MsgWriteln("Beware: Indentation tokens depend on the parser\'s state!")
  of "i": 
    gCmd = cmdInteractive
    CommandInteractive()
  of "idetools":
    gCmd = cmdIdeTools
    wantFile(filename)
    CommandSuggest(filename)
  else: rawMessage(errInvalidCommandX, cmd)

