#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import 
  os, lists, strutils, nstrtabs
  
const
  hasTinyCBackend* = defined(tinyc)

type                          # please make sure we have under 32 options
                              # (improves code efficiency a lot!)
  TOption* = enum             # **keep binary compatible**
    optNone, optObjCheck, optFieldCheck, optRangeCheck, optBoundsCheck, 
    optOverflowCheck, optNilCheck,
    optNaNCheck, optInfCheck,
    optAssert, optLineDir, optWarns, optHints, 
    optOptimizeSpeed, optOptimizeSize, optStackTrace, # stack tracing support
    optLineTrace,             # line tracing support (includes stack tracing)
    optEndb,                  # embedded debugger
    optByRef,                 # use pass by ref for objects
                              # (for interfacing with C)
    optCheckpoints,           # check for checkpoints (used for debugging)
    optProfiler               # profiler turned on
  TOptions* = set[TOption]
  TGlobalOption* = enum 
    gloptNone, optForceFullMake, optBoehmGC, optRefcGC, optDeadCodeElim, 
    optListCmd, optCompileOnly, optNoLinking, 
    optSafeCode,              # only allow safe code
    optCDebug,                # turn on debugging information
    optGenDynLib,             # generate a dynamic library
    optGenGuiApp,             # generate a GUI application
    optGenScript,             # generate a script file to compile the *.c files
    optGenMapping,            # generate a mapping file
    optRun,                   # run the compiled project
    optSymbolFiles,           # use symbol files for speeding up compilation
    optSkipConfigFile,        # skip the general config file
    optSkipProjConfigFile,    # skip the project's config file
    optNoMain,                # do not generate a "main" proc
    optThreads,               # support for multi-threading
    optStdout,                # output to stdout
    optSuggest,               # ideTools: 'suggest'
    optContext,               # ideTools: 'context'
    optDef                    # ideTools: 'def'
  TGlobalOptions* = set[TGlobalOption]
  TCommands* = enum           # Nimrod's commands
    cmdNone, cmdCompileToC, cmdCompileToCpp, cmdCompileToOC, 
    cmdCompileToEcmaScript, cmdCompileToLLVM, cmdInterpret, cmdPretty, cmdDoc, 
    cmdGenDepend, cmdDump, 
    cmdCheck,                 # semantic checking for whole project
    cmdParse,                 # parse a single file (for debugging)
    cmdScan,                  # scan a single file (for debugging)
    cmdIdeTools,              # ide tools
    cmdDef,                   # def feature (find definition for IDEs)
    cmdRst2html,              # convert a reStructuredText file to HTML
    cmdRst2tex,               # convert a reStructuredText file to TeX
    cmdInteractive,           # start interactive session
    cmdRun                    # run the project via TCC backend
  TStringSeq* = seq[string]

const 
  ChecksOptions* = {optObjCheck, optFieldCheck, optRangeCheck, optNilCheck, 
    optOverflowCheck, optBoundsCheck, optAssert, optNaNCheck, optInfCheck}

var 
  gOptions*: TOptions = {optObjCheck, optFieldCheck, optRangeCheck, 
                         optBoundsCheck, optOverflowCheck, optAssert, optWarns, 
                         optHints, optStackTrace, optLineTrace}
  gGlobalOptions*: TGlobalOptions = {optRefcGC}
  gExitcode*: int8
  searchPaths*: TLinkedList
  outFile*: string = ""
  gIndexFile*: string = ""
  gCmd*: TCommands = cmdNone  # the command
  gVerbosity*: int            # how verbose the compiler is
  gNumberOfProcessors*: int   # number of processors

proc FindFile*(f: string): string

const 
  genSubDir* = "nimcache"
  NimExt* = "nim"
  RodExt* = "rod"
  HtmlExt* = "html"
  TexExt* = "tex"
  IniExt* = "ini"
  DocConfig* = "nimdoc.cfg"
  DocTexConfig* = "nimdoc.tex.cfg"

proc completeGeneratedFilePath*(f: string, createSubDir: bool = true): string
proc toGeneratedFile*(path, ext: string): string
  # converts "/home/a/mymodule.nim", "rod" to "/home/a/nimcache/mymodule.rod"
proc getPrefixDir*(): string
  # gets the application directory

# additional configuration variables:
var 
  gConfigVars*: PStringTable
  libpath*: string = ""
  projectPath*: string = ""
  gKeepComments*: bool = true # whether the parser needs to keep comments
  gImplicitMods*: TStringSeq = @[] # modules that are to be implicitly imported

proc existsConfigVar*(key: string): bool
proc getConfigVar*(key: string): string
proc setConfigVar*(key, val: string)
proc addImplicitMod*(filename: string)
proc binaryStrSearch*(x: openarray[string], y: string): int
# implementation

proc existsConfigVar(key: string): bool = 
  result = hasKey(gConfigVars, key)

proc getConfigVar(key: string): string = 
  result = nstrtabs.get(gConfigVars, key)

proc setConfigVar(key, val: string) = 
  nstrtabs.put(gConfigVars, key, val)

proc getOutFile*(filename, ext: string): string = 
  if options.outFile != "": result = options.outFile
  else: result = changeFileExt(filename, ext)
  
proc addImplicitMod(filename: string) = 
  var length = len(gImplicitMods)
  setlen(gImplicitMods, length + 1)
  gImplicitMods[length] = filename

proc getPrefixDir(): string = 
  result = SplitPath(getAppDir()).head

proc shortenDir(dir: string): string = 
  # returns the interesting part of a dir
  var prefix = getPrefixDir() & dirSep
  if startsWith(dir, prefix): 
    return copy(dir, len(prefix))
  prefix = getCurrentDir() & dirSep
  if startsWith(dir, prefix): 
    return copy(dir, len(prefix))
  prefix = projectPath & dirSep #writeln(output, prefix);
                                #writeln(output, dir);
  if startsWith(dir, prefix): 
    return copy(dir, len(prefix))
  result = dir

proc removeTrailingDirSep*(path: string): string = 
  if (len(path) > 0) and (path[len(path) - 1] == dirSep): 
    result = copy(path, 0, len(path) - 2)
  else: 
    result = path
  
proc toGeneratedFile(path, ext: string): string = 
  var (head, tail) = splitPath(path)
  if len(head) > 0: head = shortenDir(head & dirSep)
  result = joinPath([projectPath, genSubDir, head, changeFileExt(tail, ext)])

proc completeGeneratedFilePath(f: string, createSubDir: bool = true): string = 
  var (head, tail) = splitPath(f)
  if len(head) > 0: head = removeTrailingDirSep(shortenDir(head & dirSep))
  var subdir = joinPath([projectPath, genSubDir, head])
  if createSubDir: 
    try: 
      createDir(subdir)
    except EOS: 
      writeln(stdout, "cannot create directory: " & subdir)
      quit(1)
  result = joinPath(subdir, tail)

iterator iterSearchPath*(): string = 
  var it = PStrEntry(SearchPaths.head)
  while it != nil: 
    yield it.data
    it = PStrEntry(it.Next)  

proc rawFindFile(f: string): string = 
  if ExistsFile(f): 
    result = f
  else: 
    for it in iterSearchPath():
      result = JoinPath(it, f)
      if ExistsFile(result): return
    result = ""

proc FindFile(f: string): string = 
  result = rawFindFile(f)
  if len(result) == 0: result = rawFindFile(toLower(f))
  
proc binaryStrSearch(x: openarray[string], y: string): int = 
  var a = 0
  var b = len(x) - 1
  while a <= b: 
    var mid = (a + b) div 2
    var c = cmpIgnoreCase(x[mid], y)
    if c < 0: 
      a = mid + 1
    elif c > 0: 
      b = mid - 1
    else: 
      return mid
  result = - 1

gConfigVars = newStringTable([], modeStyleInsensitive)
