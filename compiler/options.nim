#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, lists, strutils, strtabs, osproc, sets
  
const
  hasTinyCBackend* = defined(tinyc)
  useEffectSystem* = true
  hasFFI* = defined(useFFI)
  newScopeForIf* = true
  useCaas* = not defined(noCaas)
  noTimeMachine* = defined(avoidTimeMachine) and defined(macosx)

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
    optThreadAnalysis,        # thread analysis pass
    optTaintMode,             # taint mode turned on
    optTlsEmulation,          # thread var emulation turned on
    optGenIndex               # generate index file for documentation;
    optEmbedOrigSrc           # embed the original source in the generated code
                              # also: generate header file
    optIdeDebug               # idetools: debug mode
    optIdeTerse               # idetools: use terse descriptions
  TGlobalOptions* = set[TGlobalOption]
  TCommands* = enum           # Nim's commands
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

  TIdeCmd* = enum
    ideNone, ideSug, ideCon, ideDef, ideUse

var
  gIdeCmd*: TIdeCmd

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
  docSeeSrcUrl*: string = ""  # if empty, no seeSrc will be generated. \
  # The string uses the formatting variables `path` and `line`.
  headerFile*: string = ""
  gVerbosity* = 1             # how verbose the compiler is
  gNumberOfProcessors*: int   # number of processors
  gWholeProject*: bool        # for 'doc2': output any dependency
  gEvalExpr* = ""             # expression for idetools --eval
  gLastCmdTime*: float        # when caas is enabled, we measure each command
  gListFullPaths*: bool
  isServing*: bool = false
  gNoNimblePath* = false
  gExperimentalMode*: bool

proc importantComments*(): bool {.inline.} = gCmd in {cmdDoc, cmdIdeTools}
proc usesNativeGC*(): bool {.inline.} = gSelectedGC >= gcRefc

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
  JsonExt* = "json"
  TexExt* = "tex"
  IniExt* = "ini"
  DefaultConfig* = "nim.cfg"
  DocConfig* = "nimdoc.cfg"
  DocTexConfig* = "nimdoc.tex.cfg"

# additional configuration variables:
var
  gConfigVars* = newStringTable(modeStyleInsensitive)
  gDllOverrides = newStringTable(modeCaseInsensitive)
  libpath* = ""
  gProjectName* = "" # holds a name like 'nimrod'
  gProjectPath* = "" # holds a path like /home/alice/projects/nimrod/compiler/
  gProjectFull* = "" # projectPath/projectName
  gProjectMainIdx*: int32 # the canonical path id of the main module
  nimcacheDir* = ""
  command* = "" # the main command (e.g. cc, check, scan, etc)
  commandArgs*: seq[string] = @[] # any arguments after the main command
  gKeepComments*: bool = true # whether the parser needs to keep comments
  implicitImports*: seq[string] = @[] # modules that are to be implicitly imported
  implicitIncludes*: seq[string] = @[] # modules that are to be implicitly included

const oKeepVariableNames* = true

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
  result = splitPath(getAppDir()).head

proc canonicalizePath*(path: string): string =
  when not FileSystemCaseSensitive: result = path.expandFilename.toLower
  else: result = path.expandFilename

proc shortenDir*(dir: string): string = 
  ## returns the interesting part of a dir
  var prefix = getPrefixDir() & DirSep
  if startsWith(dir, prefix): 
    return substr(dir, len(prefix))
  prefix = gProjectPath & DirSep
  if startsWith(dir, prefix):
    return substr(dir, len(prefix))
  result = dir

proc removeTrailingDirSep*(path: string): string = 
  if (len(path) > 0) and (path[len(path) - 1] == DirSep): 
    result = substr(path, 0, len(path) - 2)
  else: 
    result = path
  
proc getGeneratedPath: string =
  result = if nimcacheDir.len > 0: nimcacheDir else: gProjectPath.shortenDir /
                                                         genSubDir

template newPackageCache(): expr =
  newStringTable(when FileSystemCaseSensitive:
                   modeCaseInsensitive
                 else:
                   modeCaseSensitive)

var packageCache = newPackageCache()

proc resetPackageCache*() = packageCache = newPackageCache()

iterator myParentDirs(p: string): string =
  # XXX os's parentDirs is stupid (multiple yields) and triggers an old bug...
  var current = p
  while true:
    current = current.parentDir
    if current.len == 0: break
    yield current

proc getPackageName*(path: string): string =
  var parents = 0
  block packageSearch:
    for d in myParentDirs(path):
      if packageCache.hasKey(d):
        #echo "from cache ", d, " |", packageCache[d], "|", path.splitFile.name
        return packageCache[d]
      inc parents
      for file in walkFiles(d / "*.nimble"):
        result = file.splitFile.name
        break packageSearch
      for file in walkFiles(d / "*.babel"):
        result = file.splitFile.name
        break packageSearch
  # we also store if we didn't find anything:
  if result.isNil: result = ""
  for d in myParentDirs(path):
    #echo "set cache ", d, " |", result, "|", parents
    packageCache[d] = result
    dec parents
    if parents <= 0: break

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

when noTimeMachine:
  var alreadyExcludedDirs = initSet[string]()
  proc excludeDirFromTimeMachine(dir: string) {.raises: [].} =
    ## Calls a macosx command on the directory to exclude it from backups.
    ##
    ## The macosx tmutil command is invoked to mark the specified path as an
    ## item to be excluded from time machine backups. If a path already exists
    ## with files before excluding it, newer files won't be added to the
    ## directory, but previous files won't be removed from the backup until the
    ## user deletes that directory.
    ##
    ## The whole proc is optional and will ignore all kinds of errors. The only
    ## way to be sure that it works is to call ``tmutil isexcluded path``.
    if alreadyExcludedDirs.contains(dir): return
    alreadyExcludedDirs.incl(dir)
    try:
      var p = startProcess("/usr/bin/tmutil", args = ["addexclusion", dir])
      discard p.waitForExit
      p.close
    except Exception:
      discard

proc completeGeneratedFilePath*(f: string, createSubDir: bool = true): string =
  var (head, tail) = splitPath(f)
  #if len(head) > 0: head = removeTrailingDirSep(shortenDir(head & dirSep))
  var subdir = getGeneratedPath() # / head
  if createSubDir:
    try:
      createDir(subdir)
      when noTimeMachine:
       excludeDirFromTimeMachine(subdir)
    except OSError:
      writeln(stdout, "cannot create directory: " & subdir)
      quit(1)
  result = joinPath(subdir, tail)
  #echo "completeGeneratedFilePath(", f, ") = ", result

iterator iterSearchPath*(searchPaths: TLinkedList): string = 
  var it = PStrEntry(searchPaths.head)
  while it != nil:
    yield it.data
    it = PStrEntry(it.next)

proc rawFindFile(f: string): string =
  for it in iterSearchPath(searchPaths):
    result = joinPath(it, f)
    if existsFile(result):
      return result.canonicalizePath
  result = ""

proc rawFindFile2(f: string): string =
  var it = PStrEntry(lazyPaths.head)
  while it != nil:
    result = joinPath(it.data, f)
    if existsFile(result):
      bringToFront(lazyPaths, it)
      return result.canonicalizePath
    it = PStrEntry(it.next)
  result = ""

proc findFile*(f: string): string {.procvar.} = 
  result = f.rawFindFile
  if result.len == 0:
    result = f.toLower.rawFindFile
    if result.len == 0:
      result = f.rawFindFile2
      if result.len == 0:
        result = f.toLower.rawFindFile2

proc findModule*(modulename, currentModule: string): string =
  # returns path to module
  when defined(nimfix):
    # '.nimfix' modules are preferred over '.nim' modules so that specialized
    # versions can be kept for 'nimfix'.
    block:
      let m = addFileExt(modulename, "nimfix")
      let currentPath = currentModule.splitFile.dir
      result = currentPath / m
      if not existsFile(result):
        result = findFile(m)
        if existsFile(result): return result
  let m = addFileExt(modulename, NimExt)
  let currentPath = currentModule.splitFile.dir
  result = currentPath / m
  if not existsFile(result):
    result = findFile(m)

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

proc binaryStrSearch*(x: openArray[string], y: string): int = 
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

