#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, lists, strutils, strtabs
  
const
  hasTinyCBackend* = defined(tinyc)
  useEffectSystem* = true
  hasFFI* = defined(useFFI)
  newScopeForIf* = true
  useCaas* = not defined(noCaas)

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
    optProfiler,              # profiler turned on
    optImplicitStatic,        # optimization: implicit at compile time
                              # evaluation
    optPatterns               # en/disable pattern matching

  TOptions* = set[TOption]
  TGlobalOption* = enum       # **keep binary compatible**
    gloptNone, optForceFullMake, optDeadCodeElim, 
    optListCmd, optCompileOnly, optNoLinking, 
    optSafeCode,              # only allow safe code
    optCDebug,                # turn on debugging information
    optGenDynLib,             # generate a dynamic library
    optGenStaticLib,          # generate a static library
    optGenGuiApp,             # generate a GUI application
    optGenScript,             # generate a script file to compile the *.c files
    optGenMapping,            # generate a mapping file
    optRun,                   # run the compiled project
    optSymbolFiles,           # use symbol files for speeding up compilation
    optCaasEnabled            # compiler-as-a-service is running
    optSkipConfigFile,        # skip the general config file
    optSkipProjConfigFile,    # skip the project's config file
    optSkipUserConfigFile,    # skip the users's config file
    optSkipParentConfigFiles, # skip parent dir's config files
    optNoMain,                # do not generate a "main" proc
    optThreads,               # support for multi-threading
    optStdout,                # output to stdout
    optSuggest,               # ideTools: 'suggest'
    optContext,               # ideTools: 'context'
    optDef,                   # ideTools: 'def'
    optUsages,                # ideTools: 'usages'
    optThreadAnalysis,        # thread analysis pass
    optTaintMode,             # taint mode turned on
    optTlsEmulation,          # thread var emulation turned on
    optGenIndex               # generate index file for documentation;
    optEmbedOrigSrc           # embed the original source in the generated code
                              # also: generate header file
   
  TGlobalOptions* = set[TGlobalOption]
  TCommands* = enum           # Nimrod's commands
                              # **keep binary compatible**
    cmdNone, cmdCompileToC, cmdCompileToCpp, cmdCompileToOC, 
    cmdCompileToJS, cmdCompileToLLVM, cmdInterpret, cmdPretty, cmdDoc, 
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
  TGCMode* = enum             # the selected GC
    gcNone, gcBoehm, gcMarkAndSweep, gcRefc, gcV2, gcGenerational

const
  ChecksOptions* = {optObjCheck, optFieldCheck, optRangeCheck, optNilCheck, 
    optOverflowCheck, optBoundsCheck, optAssert, optNaNCheck, optInfCheck}

var 
  gOptions*: TOptions = {optObjCheck, optFieldCheck, optRangeCheck, 
                         optBoundsCheck, optOverflowCheck, optAssert, optWarns, 
                         optHints, optStackTrace, optLineTrace,
                         optPatterns, optNilCheck}
  gGlobalOptions*: TGlobalOptions = {optThreadAnalysis}
  gExitcode*: int8
  gCmd*: TCommands = cmdNone  # the command
  gSelectedGC* = gcRefc       # the selected GC
  searchPaths*, lazyPaths*: TLinkedList
  outFile*: string = ""
  headerFile*: string = ""
  gVerbosity* = 1             # how verbose the compiler is
  gNumberOfProcessors*: int   # number of processors
  gWholeProject*: bool        # for 'doc2': output any dependency
  gEvalExpr* = ""             # expression for idetools --eval
  gLastCmdTime*: float        # when caas is enabled, we measure each command
  gListFullPaths*: bool
  isServing*: bool = false
  gDirtyBufferIdx* = 0'i32    # indicates the fileIdx of the dirty version of
                              # the tracked source X, saved by the CAAS client.
  gDirtyOriginalIdx* = 0'i32  # the original source file of the dirtified buffer.

proc importantComments*(): bool {.inline.} = gCmd in {cmdDoc, cmdIdeTools}
proc usesNativeGC*(): bool {.inline.} = gSelectedGC >= gcRefc

template isWorkingWithDirtyBuffer*: expr =
  gDirtyBufferIdx != 0

template compilationCachePresent*: expr =
  {optCaasEnabled, optSymbolFiles} * gGlobalOptions != {}

template optPreserveOrigSource*: expr =
  optEmbedOrigSrc in gGlobalOptions

template optPrintSurroundingSrc*: expr =
  gVerbosity >= 2

const 
  genSubDir* = "nimcache"
  NimExt* = "nim"
  RodExt* = "rod"
  HtmlExt* = "html"
  TexExt* = "tex"
  IniExt* = "ini"
  DefaultConfig* = "nimrod.cfg"
  DocConfig* = "nimdoc.cfg"
  DocTexConfig* = "nimdoc.tex.cfg"

# additional configuration variables:
var
  gConfigVars* = newStringTable(modeStyleInsensitive)
  gDllOverrides = newStringtable(modeCaseInsensitive)
  libpath* = ""
  gProjectName* = "" # holds a name like 'nimrod'
  gProjectPath* = "" # holds a path like /home/alice/projects/nimrod/compiler/
  gProjectFull* = "" # projectPath/projectName
  gProjectMainIdx*: int32 # the canonical path id of the main module
  optMainModule* = "" # the main module that should be used for idetools commands
  nimcacheDir* = ""
  command* = "" # the main command (e.g. cc, check, scan, etc)
  commandArgs*: seq[string] = @[] # any arguments after the main command
  gKeepComments*: bool = true # whether the parser needs to keep comments
  implicitImports*: seq[string] = @[] # modules that are to be implicitly imported
  implicitIncludes*: seq[string] = @[] # modules that are to be implicitly included

const oKeepVariableNames* = true

const oUseLateInstantiation* = false

proc mainCommandArg*: string =
  ## This is intended for commands like check or parse
  ## which will work on the main project file unless
  ## explicitly given a specific file argument
  if commandArgs.len > 0:
    result = commandArgs[0]
  else:
    result = gProjectName

proc existsConfigVar*(key: string): bool = 
  result = hasKey(gConfigVars, key)

proc getConfigVar*(key: string): string = 
  result = gConfigVars[key]

proc setConfigVar*(key, val: string) = 
  gConfigVars[key] = val

proc getOutFile*(filename, ext: string): string = 
  if options.outFile != "": result = options.outFile
  else: result = changeFileExt(filename, ext)
  
proc getPrefixDir*(): string = 
  ## gets the application directory
  result = SplitPath(getAppDir()).head

proc canonicalizePath*(path: string): string =
  result = path.expandFilename
  when not FileSystemCaseSensitive: result = result.toLower

proc shortenDir*(dir: string): string = 
  ## returns the interesting part of a dir
  var prefix = getPrefixDir() & dirSep
  if startsWith(dir, prefix): 
    return substr(dir, len(prefix))
  prefix = gProjectPath & dirSep
  if startsWith(dir, prefix):
    return substr(dir, len(prefix))
  result = dir

proc removeTrailingDirSep*(path: string): string = 
  if (len(path) > 0) and (path[len(path) - 1] == dirSep): 
    result = substr(path, 0, len(path) - 2)
  else: 
    result = path
  
proc getGeneratedPath: string =
  result = if nimcacheDir.len > 0: nimcacheDir else: gProjectPath.shortenDir /
                                                         genSubDir

proc getPackageName*(path: string): string =
  var q = 1
  var b = 0
  if path[len(path)-1] in {dirsep, altsep}: q = 2
  for i in countdown(len(path)-q, 0):
    if path[i] in {dirsep, altsep}:
      if b == 0: b = i
      else:
        let x = path.substr(i+1, b-1)
        case x.normalize
        of "lib", "src", "source", "package", "pckg", "library", "private":
          b = i
        else:
          return x.replace('.', '_')
  result = ""

proc withPackageName*(path: string): string =
  let x = path.getPackageName
  if x.len == 0:
    result = path
  else:
    let (p, file, ext) = path.splitFile
    result = (p / (x & '_' & file)) & ext

proc toGeneratedFile*(path, ext: string): string = 
  ## converts "/home/a/mymodule.nim", "rod" to "/home/a/nimcache/mymodule.rod"
  var (head, tail) = splitPath(path)
  #if len(head) > 0: head = shortenDir(head & dirSep)
  result = joinPath([getGeneratedPath(), changeFileExt(tail, ext)])
  #echo "toGeneratedFile(", path, ", ", ext, ") = ", result

proc completeGeneratedFilePath*(f: string, createSubDir: bool = true): string = 
  var (head, tail) = splitPath(f)
  #if len(head) > 0: head = removeTrailingDirSep(shortenDir(head & dirSep))
  var subdir = getGeneratedPath() # / head
  if createSubDir:
    try: 
      createDir(subdir)
    except EOS: 
      writeln(stdout, "cannot create directory: " & subdir)
      quit(1)
  result = joinPath(subdir, tail)
  #echo "completeGeneratedFilePath(", f, ") = ", result

iterator iterSearchPath*(SearchPaths: TLinkedList): string = 
  var it = PStrEntry(SearchPaths.head)
  while it != nil:
    yield it.data
    it = PStrEntry(it.Next)

proc rawFindFile(f: string): string =
  for it in iterSearchPath(SearchPaths):
    result = JoinPath(it, f)
    if existsFile(result):
      return result.canonicalizePath
  result = ""

proc rawFindFile2(f: string): string =
  var it = PStrEntry(lazyPaths.head)
  while it != nil:
    result = JoinPath(it.data, f)
    if existsFile(result):
      bringToFront(lazyPaths, it)
      return result.canonicalizePath
    it = PStrEntry(it.Next)
  result = ""

proc FindFile*(f: string): string {.procvar.} = 
  result = f.rawFindFile
  if result.len == 0:
    result = f.toLower.rawFindFile
    if result.len == 0:
      result = f.rawFindFile2
      if result.len == 0:
        result = f.toLower.rawFindFile2

proc findModule*(modulename, currentModule: string): string =
  # returns path to module
  let m = addFileExt(modulename, nimExt)
  let currentPath = currentModule.splitFile.dir
  result = currentPath / m
  if not existsFile(result):
    result = FindFile(m)

proc libCandidates*(s: string, dest: var seq[string]) = 
  var le = strutils.find(s, '(')
  var ri = strutils.find(s, ')', le+1)
  if le >= 0 and ri > le:
    var prefix = substr(s, 0, le - 1)
    var suffix = substr(s, ri + 1)
    for middle in split(substr(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else: 
    add(dest, s)

proc canonDynlibName(s: string): string =
  let start = if s.startsWith("lib"): 3 else: 0
  let ende = strutils.find(s, {'(', ')', '.'})
  if ende >= 0:
    result = s.substr(start, ende-1)
  else:
    result = s.substr(start)

proc inclDynlibOverride*(lib: string) =
  gDllOverrides[lib.canonDynlibName] = "true"

proc isDynlibOverride*(lib: string): bool =
  result = gDllOverrides.hasKey(lib.canonDynlibName)

proc binaryStrSearch*(x: openarray[string], y: string): int = 
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

template nimdbg*: expr = c.module.fileIdx == gProjectMainIdx
template cnimdbg*: expr = p.module.module.fileIdx == gProjectMainIdx
template pnimdbg*: expr = p.lex.fileIdx == gProjectMainIdx
template lnimdbg*: expr = L.fileIdx == gProjectMainIdx

