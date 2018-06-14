#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, strtabs, osproc, sets, lineinfos, platform,
  prefixmatches

from terminal import isatty

const
  hasTinyCBackend* = defined(tinyc)
  useEffectSystem* = true
  useWriteTracking* = false
  hasFFI* = defined(useFFI)
  newScopeForIf* = true
  useCaas* = not defined(noCaas)
  copyrightYear* = "2018"

type                          # please make sure we have under 32 options
                              # (improves code efficiency a lot!)
  TOption* = enum             # **keep binary compatible**
    optNone, optObjCheck, optFieldCheck, optRangeCheck, optBoundsCheck,
    optOverflowCheck, optNilCheck,
    optNaNCheck, optInfCheck, optMoveCheck,
    optAssert, optLineDir, optWarns, optHints,
    optOptimizeSpeed, optOptimizeSize, optStackTrace, # stack tracing support
    optLineTrace,             # line tracing support (includes stack tracing)
    optEndb,                  # embedded debugger
    optByRef,                 # use pass by ref for objects
                              # (for interfacing with C)
    optProfiler,              # profiler turned on
    optImplicitStatic,        # optimization: implicit at compile time
                              # evaluation
    optPatterns,              # en/disable pattern matching
    optMemTracker,
    optHotCodeReloading,
    optLaxStrings

  TOptions* = set[TOption]
  TGlobalOption* = enum       # **keep binary compatible**
    gloptNone, optForceFullMake,
    optDeadCodeElimUnused,    # deprecated, always on
    optListCmd, optCompileOnly, optNoLinking,
    optCDebug,                # turn on debugging information
    optGenDynLib,             # generate a dynamic library
    optGenStaticLib,          # generate a static library
    optGenGuiApp,             # generate a GUI application
    optGenScript,             # generate a script file to compile the *.c files
    optGenMapping,            # generate a mapping file
    optRun,                   # run the compiled project
    optCheckNep1,             # check that the names adhere to NEP-1
    optSkipConfigFile,        # skip the general config file
    optSkipProjConfigFile,    # skip the project's config file
    optSkipUserConfigFile,    # skip the users's config file
    optSkipParentConfigFiles, # skip parent dir's config files
    optNoMain,                # do not generate a "main" proc
    optUseColors,             # use colors for hints, warnings, and errors
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
    optNoCppExceptions        # use C exception handling even with CPP
    optExcessiveStackTrace    # fully qualified module filenames
    optWholeProject           # for 'doc2': output any dependency
    optMixedMode              # true if some module triggered C++ codegen
    optListFullPaths
    optNoNimblePath
    optDynlibOverrideAll
    optUseNimNamespace

  TGlobalOptions* = set[TGlobalOption]

const
  harmlessOptions* = {optForceFullMake, optNoLinking, optRun,
                      optUseColors, optStdout}

type
  TCommands* = enum           # Nim's commands
                              # **keep binary compatible**
    cmdNone, cmdCompileToC, cmdCompileToCpp, cmdCompileToOC,
    cmdCompileToJS,
    cmdCompileToLLVM, cmdInterpret, cmdPretty, cmdDoc,
    cmdGenDepend, cmdDump,
    cmdCheck,                 # semantic checking for whole project
    cmdParse,                 # parse a single file (for debugging)
    cmdScan,                  # scan a single file (for debugging)
    cmdIdeTools,              # ide tools
    cmdDef,                   # def feature (find definition for IDEs)
    cmdRst2html,              # convert a reStructuredText file to HTML
    cmdRst2tex,               # convert a reStructuredText file to TeX
    cmdInteractive,           # start interactive session
    cmdRun,                   # run the project via TCC backend
    cmdJsonScript             # compile a .json build file
  TStringSeq* = seq[string]
  TGCMode* = enum             # the selected GC
    gcNone, gcBoehm, gcGo, gcRegions, gcMarkAndSweep, gcRefc,
    gcV2, gcGenerational

  IdeCmd* = enum
    ideNone, ideSug, ideCon, ideDef, ideUse, ideDus, ideChk, ideMod,
    ideHighlight, ideOutline, ideKnown, ideMsg

  Feature* = enum  ## experimental features
    implicitDeref,
    dotOperators,
    callOperator,
    parallel,
    destructor,
    notnil

  SymbolFilesOption* = enum
    disabledSf, writeOnlySf, readOnlySf, v2Sf

  TSystemCC* = enum
    ccNone, ccGcc, ccLLVM_Gcc, ccCLang, ccLcc, ccBcc, ccDmc, ccWcc, ccVcc,
    ccTcc, ccPcc, ccUcc, ccIcl, ccIcc

  CfileFlag* {.pure.} = enum
    Cached,    ## no need to recompile this time
    External   ## file was introduced via .compile pragma

  Cfile* = object
    cname*, obj*: string
    flags*: set[CFileFlag]
  CfileList* = seq[Cfile]

  Suggest* = ref object
    section*: IdeCmd
    qualifiedPath*: seq[string]
    name*: ptr string         # not used beyond sorting purposes; name is also
                              # part of 'qualifiedPath'
    filePath*: string
    line*: int                   # Starts at 1
    column*: int                 # Starts at 0
    doc*: string           # Not escaped (yet)
    forth*: string               # type
    quality*: range[0..100]   # matching quality
    isGlobal*: bool # is a global variable
    contextFits*: bool # type/non-type context matches
    prefix*: PrefixMatch
    symkind*: byte
    scope*, localUsages*, globalUsages*: int # more usages is better
    tokenLen*: int
    version*: int
  Suggestions* = seq[Suggest]

  ConfigRef* = ref object ## every global configuration
                          ## fields marked with '*' are subject to
                          ## the incremental compilation mechanisms
                          ## (+) means "part of the dependency"
    target*: Target       # (+)
    linesCompiled*: int  # all lines that have been compiled
    options*: TOptions    # (+)
    globalOptions*: TGlobalOptions # (+)
    m*: MsgConfig
    evalTemplateCounter*: int
    evalMacroCounter*: int
    exitcode*: int8
    cmd*: TCommands  # the command
    selectedGC*: TGCMode       # the selected GC (+)
    verbosity*: int            # how verbose the compiler is
    numberOfProcessors*: int   # number of processors
    evalExpr*: string          # expression for idetools --eval
    lastCmdTime*: float        # when caas is enabled, we measure each command
    symbolFiles*: SymbolFilesOption

    cppDefines*: HashSet[string] # (*)
    headerFile*: string
    features*: set[Feature]
    arguments*: string ## the arguments to be passed to the program that
                       ## should be run
    helpWritten*: bool
    ideCmd*: IdeCmd
    oldNewlines*: bool
    cCompiler*: TSystemCC
    enableNotes*: TNoteKinds
    disableNotes*: TNoteKinds
    foreignPackageNotes*: TNoteKinds
    notes*: TNoteKinds
    mainPackageNotes*: TNoteKinds
    mainPackageId*: int
    errorCounter*: int
    hintCounter*: int
    warnCounter*: int
    errorMax*: int
    configVars*: StringTableRef
    symbols*: StringTableRef ## We need to use a StringTableRef here as defined
                             ## symbols are always guaranteed to be style
                             ## insensitive. Otherwise hell would break lose.
    packageCache*: StringTableRef
    searchPaths*: seq[string]
    lazyPaths*: seq[string]
    outFile*, prefixDir*, libpath*, nimcacheDir*: string
    dllOverrides, moduleOverrides*: StringTableRef
    projectName*: string # holds a name like 'nim'
    projectPath*: string # holds a path like /home/alice/projects/nim/compiler/
    projectFull*: string # projectPath/projectName
    projectIsStdin*: bool # whether we're compiling from stdin
    projectMainIdx*: FileIndex # the canonical path id of the main module
    command*: string # the main command (e.g. cc, check, scan, etc)
    commandArgs*: seq[string] # any arguments after the main command
    keepComments*: bool # whether the parser needs to keep comments
    implicitImports*: seq[string] # modules that are to be implicitly imported
    implicitIncludes*: seq[string] # modules that are to be implicitly included
    docSeeSrcUrl*: string # if empty, no seeSrc will be generated. \
    # The string uses the formatting variables `path` and `line`.

     # the used compiler
    cIncludes*: seq[string]  # directories to search for included files
    cLibs*: seq[string]      # directories to search for lib files
    cLinkedLibs*: seq[string]  # libraries to link

    externalToLink*: seq[string]  # files to link in addition to the file
                                  # we compiled (*)
    linkOptionsCmd*: string
    compileOptionsCmd*: seq[string]
    linkOptions*: string          # (*)
    compileOptions*: string       # (*)
    ccompilerpath*: string
    toCompile*: CfileList         # (*)
    suggestionResultHook*: proc (result: Suggest) {.closure.}
    suggestVersion*: int
    suggestMaxResults*: int
    lastLineInfo*: TLineInfo
    writelnHook*: proc (output: string) {.closure.}
    structuredErrorHook*: proc (config: ConfigRef; info: TLineInfo; msg: string;
                                severity: Severity) {.closure.}

template depConfigFields*(fn) {.dirty.} =
  fn(target)
  fn(options)
  fn(globalOptions)
  fn(selectedGC)

const oldExperimentalFeatures* = {implicitDeref, dotOperators, callOperator, parallel}

const
  ChecksOptions* = {optObjCheck, optFieldCheck, optRangeCheck, optNilCheck,
    optOverflowCheck, optBoundsCheck, optAssert, optNaNCheck, optInfCheck,
    optMoveCheck}

  DefaultOptions* = {optObjCheck, optFieldCheck, optRangeCheck,
    optBoundsCheck, optOverflowCheck, optAssert, optWarns,
    optHints, optStackTrace, optLineTrace,
    optPatterns, optNilCheck, optMoveCheck}
  DefaultGlobalOptions* = {optThreadAnalysis}

template newPackageCache*(): untyped =
  newStringTable(when FileSystemCaseSensitive:
                   modeCaseInsensitive
                 else:
                   modeCaseSensitive)

proc newConfigRef*(): ConfigRef =
  result = ConfigRef(
    selectedGC: gcRefc,
    cCompiler: ccGcc,
    verbosity: 1,
    options: DefaultOptions,
    globalOptions: DefaultGlobalOptions,
    m: initMsgConfig(),
    evalExpr: "",
    cppDefines: initSet[string](),
    headerFile: "", features: {}, foreignPackageNotes: {hintProcessing, warnUnknownMagic,
    hintQuitCalled, hintExecuting},
    notes: NotesVerbosity[1], mainPackageNotes: NotesVerbosity[1],
    configVars: newStringTable(modeStyleInsensitive),
    symbols: newStringTable(modeStyleInsensitive),
    packageCache: newPackageCache(),
    searchPaths: @[],
    lazyPaths: @[],
    outFile: "", prefixDir: "", libpath: "", nimcacheDir: "",
    dllOverrides: newStringTable(modeCaseInsensitive),
    moduleOverrides: newStringTable(modeStyleInsensitive),
    projectName: "", # holds a name like 'nim'
    projectPath: "", # holds a path like /home/alice/projects/nim/compiler/
    projectFull: "", # projectPath/projectName
    projectIsStdin: false, # whether we're compiling from stdin
    projectMainIdx: FileIndex(0'i32), # the canonical path id of the main module
    command: "", # the main command (e.g. cc, check, scan, etc)
    commandArgs: @[], # any arguments after the main command
    keepComments: true, # whether the parser needs to keep comments
    implicitImports: @[], # modules that are to be implicitly imported
    implicitIncludes: @[], # modules that are to be implicitly included
    docSeeSrcUrl: "",
    cIncludes: @[],   # directories to search for included files
    cLibs: @[],       # directories to search for lib files
    cLinkedLibs: @[],  # libraries to link

    externalToLink: @[],
    linkOptionsCmd: "",
    compileOptionsCmd: @[],
    linkOptions: "",
    compileOptions: "",
    ccompilerpath: "",
    toCompile: @[],
    arguments: "",
    suggestMaxResults: 10_000
  )
  setTargetFromSystem(result.target)
  # enable colors by default on terminals
  if terminal.isatty(stderr):
    incl(result.globalOptions, optUseColors)

proc newPartialConfigRef*(): ConfigRef =
  ## create a new ConfigRef that is only good enough for error reporting.
  result = ConfigRef(
    selectedGC: gcRefc,
    verbosity: 1,
    options: DefaultOptions,
    globalOptions: DefaultGlobalOptions,
    foreignPackageNotes: {hintProcessing, warnUnknownMagic,
    hintQuitCalled, hintExecuting},
    notes: NotesVerbosity[1], mainPackageNotes: NotesVerbosity[1])

proc cppDefine*(c: ConfigRef; define: string) =
  c.cppDefines.incl define

proc isDefined*(conf: ConfigRef; symbol: string): bool =
  if conf.symbols.hasKey(symbol):
    result = conf.symbols[symbol] != "false"
  elif cmpIgnoreStyle(symbol, CPU[conf.target.targetCPU].name) == 0:
    result = true
  elif cmpIgnoreStyle(symbol, platform.OS[conf.target.targetOS].name) == 0:
    result = true
  else:
    case symbol.normalize
    of "x86": result = conf.target.targetCPU == cpuI386
    of "itanium": result = conf.target.targetCPU == cpuIa64
    of "x8664": result = conf.target.targetCPU == cpuAmd64
    of "posix", "unix":
      result = conf.target.targetOS in {osLinux, osMorphos, osSkyos, osIrix, osPalmos,
                            osQnx, osAtari, osAix,
                            osHaiku, osVxWorks, osSolaris, osNetbsd,
                            osFreebsd, osOpenbsd, osDragonfly, osMacosx,
                            osAndroid}
    of "linux":
      result = conf.target.targetOS in {osLinux, osAndroid}
    of "bsd":
      result = conf.target.targetOS in {osNetbsd, osFreebsd, osOpenbsd, osDragonfly}
    of "emulatedthreadvars":
      result = platform.OS[conf.target.targetOS].props.contains(ospLacksThreadVars)
    of "msdos": result = conf.target.targetOS == osDos
    of "mswindows", "win32": result = conf.target.targetOS == osWindows
    of "macintosh": result = conf.target.targetOS in {osMacos, osMacosx}
    of "sunos": result = conf.target.targetOS == osSolaris
    of "littleendian": result = CPU[conf.target.targetCPU].endian == platform.littleEndian
    of "bigendian": result = CPU[conf.target.targetCPU].endian == platform.bigEndian
    of "cpu8": result = CPU[conf.target.targetCPU].bit == 8
    of "cpu16": result = CPU[conf.target.targetCPU].bit == 16
    of "cpu32": result = CPU[conf.target.targetCPU].bit == 32
    of "cpu64": result = CPU[conf.target.targetCPU].bit == 64
    of "nimrawsetjmp":
      result = conf.target.targetOS in {osSolaris, osNetbsd, osFreebsd, osOpenbsd,
                            osDragonfly, osMacosx}
    else: discard

proc importantComments*(conf: ConfigRef): bool {.inline.} = conf.cmd in {cmdDoc, cmdIdeTools}
proc usesNativeGC*(conf: ConfigRef): bool {.inline.} = conf.selectedGC >= gcRefc

template compilationCachePresent*(conf: ConfigRef): untyped =
  conf.symbolFiles in {v2Sf, writeOnlySf}

template optPreserveOrigSource*(conf: ConfigRef): untyped =
  optEmbedOrigSrc in conf.globalOptions

const
  genSubDir* = "nimcache"
  NimExt* = "nim"
  RodExt* = "rod"
  HtmlExt* = "html"
  JsonExt* = "json"
  TagsExt* = "tags"
  TexExt* = "tex"
  IniExt* = "ini"
  DefaultConfig* = "nim.cfg"
  DocConfig* = "nimdoc.cfg"
  DocTexConfig* = "nimdoc.tex.cfg"

const oKeepVariableNames* = true

template compilingLib*(conf: ConfigRef): bool =
  gGlobalOptions * {optGenGuiApp, optGenDynLib} != {}

proc mainCommandArg*(conf: ConfigRef): string =
  ## This is intended for commands like check or parse
  ## which will work on the main project file unless
  ## explicitly given a specific file argument
  if conf.commandArgs.len > 0:
    result = conf.commandArgs[0]
  else:
    result = conf.projectName

proc existsConfigVar*(conf: ConfigRef; key: string): bool =
  result = hasKey(conf.configVars, key)

proc getConfigVar*(conf: ConfigRef; key: string): string =
  result = conf.configVars.getOrDefault key

proc setConfigVar*(conf: ConfigRef; key, val: string) =
  conf.configVars[key] = val

proc getOutFile*(conf: ConfigRef; filename, ext: string): string =
  if conf.outFile != "": result = conf.outFile
  else: result = changeFileExt(filename, ext)

proc getPrefixDir*(conf: ConfigRef): string =
  ## Gets the prefix dir, usually the parent directory where the binary resides.
  ##
  ## This is overridden by some tools (namely nimsuggest) via the ``conf.prefixDir``
  ## global.
  if conf.prefixDir != "": result = conf.prefixDir
  else: result = splitPath(getAppDir()).head

proc setDefaultLibpath*(conf: ConfigRef) =
  # set default value (can be overwritten):
  if conf.libpath == "":
    # choose default libpath:
    var prefix = getPrefixDir(conf)
    when defined(posix):
      if prefix == "/usr": conf.libpath = "/usr/lib/nim"
      elif prefix == "/usr/local": conf.libpath = "/usr/local/lib/nim"
      else: conf.libpath = joinPath(prefix, "lib")
    else: conf.libpath = joinPath(prefix, "lib")

    # Special rule to support other tools (nimble) which import the compiler
    # modules and make use of them.
    let realNimPath = findExe("nim")
    # Find out if $nim/../../lib/system.nim exists.
    let parentNimLibPath = realNimPath.parentDir.parentDir / "lib"
    if not fileExists(conf.libpath / "system.nim") and
        fileExists(parentNimlibPath / "system.nim"):
      conf.libpath = parentNimLibPath

proc canonicalizePath*(conf: ConfigRef; path: string): string =
  # on Windows, 'expandFilename' calls getFullPathName which doesn't do
  # case corrections, so we have to use this convoluted way of retrieving
  # the true filename (see tests/modules and Nimble uses 'import Uri' instead
  # of 'import uri'):
  when defined(windows):
    result = path.expandFilename
    for x in walkFiles(result):
      return x
  else:
    result = path.expandFilename

proc shortenDir*(conf: ConfigRef; dir: string): string =
  ## returns the interesting part of a dir
  var prefix = conf.projectPath & DirSep
  if startsWith(dir, prefix):
    return substr(dir, len(prefix))
  prefix = getPrefixDir(conf) & DirSep
  if startsWith(dir, prefix):
    return substr(dir, len(prefix))
  result = dir

proc removeTrailingDirSep*(path: string): string =
  if (len(path) > 0) and (path[len(path) - 1] == DirSep):
    result = substr(path, 0, len(path) - 2)
  else:
    result = path

proc disableNimblePath*(conf: ConfigRef) =
  incl conf.globalOptions, optNoNimblePath
  conf.lazyPaths.setLen(0)

include packagehandling

proc getNimcacheDir*(conf: ConfigRef): string =
  result = if conf.nimcacheDir.len > 0: conf.nimcacheDir
           else: shortenDir(conf, conf.projectPath) / genSubDir

proc pathSubs*(conf: ConfigRef; p, config: string): string =
  let home = removeTrailingDirSep(os.getHomeDir())
  result = unixToNativePath(p % [
    "nim", getPrefixDir(conf),
    "lib", conf.libpath,
    "home", home,
    "config", config,
    "projectname", conf.projectName,
    "projectpath", conf.projectPath,
    "projectdir", conf.projectPath,
    "nimcache", getNimcacheDir(conf)])
  if "~/" in result:
    result = result.replace("~/", home & '/')

proc toGeneratedFile*(conf: ConfigRef; path, ext: string): string =
  ## converts "/home/a/mymodule.nim", "rod" to "/home/a/nimcache/mymodule.rod"
  var (head, tail) = splitPath(path)
  #if len(head) > 0: head = shortenDir(head & dirSep)
  result = joinPath([getNimcacheDir(conf), changeFileExt(tail, ext)])
  #echo "toGeneratedFile(", path, ", ", ext, ") = ", result

proc completeGeneratedFilePath*(conf: ConfigRef; f: string, createSubDir: bool = true): string =
  var (head, tail) = splitPath(f)
  #if len(head) > 0: head = removeTrailingDirSep(shortenDir(head & dirSep))
  var subdir = getNimcacheDir(conf) # / head
  if createSubDir:
    try:
      createDir(subdir)
    except OSError:
      writeLine(stdout, "cannot create directory: " & subdir)
      quit(1)
  result = joinPath(subdir, tail)
  #echo "completeGeneratedFilePath(", f, ") = ", result

proc rawFindFile(conf: ConfigRef; f: string): string =
  for it in conf.searchPaths:
    result = joinPath(it, f)
    if existsFile(result):
      return canonicalizePath(conf, result)
  result = ""

proc rawFindFile2(conf: ConfigRef; f: string): string =
  for i, it in conf.lazyPaths:
    result = joinPath(it, f)
    if existsFile(result):
      # bring to front
      for j in countDown(i,1):
        swap(conf.lazyPaths[j], conf.lazyPaths[j-1])

      return canonicalizePath(conf, result)
  result = ""

template patchModule(conf: ConfigRef) {.dirty.} =
  if result.len > 0 and conf.moduleOverrides.len > 0:
    let key = getPackageName(conf, result) & "_" & splitFile(result).name
    if conf.moduleOverrides.hasKey(key):
      let ov = conf.moduleOverrides[key]
      if ov.len > 0: result = ov

proc findFile*(conf: ConfigRef; f: string): string {.procvar.} =
  if f.isAbsolute:
    result = if f.existsFile: f else: ""
  else:
    result = rawFindFile(conf, f)
    if result.len == 0:
      result = rawFindFile(conf, f.toLowerAscii)
      if result.len == 0:
        result = rawFindFile2(conf, f)
        if result.len == 0:
          result = rawFindFile2(conf, f.toLowerAscii)
  patchModule(conf)

proc findModule*(conf: ConfigRef; modulename, currentModule: string): string =
  # returns path to module
  when defined(nimfix):
    # '.nimfix' modules are preferred over '.nim' modules so that specialized
    # versions can be kept for 'nimfix'.
    block:
      let m = addFileExt(modulename, "nimfix")
      let currentPath = currentModule.splitFile.dir
      result = currentPath / m
      if not existsFile(result):
        result = findFile(conf, m)
        if existsFile(result): return result
  let m = addFileExt(modulename, NimExt)
  let currentPath = currentModule.splitFile.dir
  result = currentPath / m
  if not existsFile(result):
    result = findFile(conf, m)
  patchModule(conf)

proc findProjectNimFile*(conf: ConfigRef; pkg: string): string =
  const extensions = [".nims", ".cfg", ".nimcfg", ".nimble"]
  var candidates: seq[string] = @[]
  for k, f in os.walkDir(pkg, relative=true):
    if k == pcFile and f != "config.nims":
      let (_, name, ext) = splitFile(f)
      if ext in extensions:
        let x = changeFileExt(pkg / name, ".nim")
        if fileExists(x):
          candidates.add x
  for c in candidates:
    # nim-foo foo  or  foo  nfoo
    if (pkg in c) or (c in pkg): return c
  if candidates.len >= 1:
    return candidates[0]
  return ""

proc canonDynlibName(s: string): string =
  let start = if s.startsWith("lib"): 3 else: 0
  let ende = strutils.find(s, {'(', ')', '.'})
  if ende >= 0:
    result = s.substr(start, ende-1)
  else:
    result = s.substr(start)

proc inclDynlibOverride*(conf: ConfigRef; lib: string) =
  conf.dllOverrides[lib.canonDynlibName] = "true"

proc isDynlibOverride*(conf: ConfigRef; lib: string): bool =
  result = optDynlibOverrideAll in conf.globalOptions or
     conf.dllOverrides.hasKey(lib.canonDynlibName)

proc parseIdeCmd*(s: string): IdeCmd =
  case s:
  of "sug": ideSug
  of "con": ideCon
  of "def": ideDef
  of "use": ideUse
  of "dus": ideDus
  of "chk": ideChk
  of "mod": ideMod
  of "highlight": ideHighlight
  of "outline": ideOutline
  of "known": ideKnown
  of "msg": ideMsg
  else: ideNone

proc `$`*(c: IdeCmd): string =
  case c:
  of ideSug: "sug"
  of ideCon: "con"
  of ideDef: "def"
  of ideUse: "use"
  of ideDus: "dus"
  of ideChk: "chk"
  of ideMod: "mod"
  of ideNone: "none"
  of ideHighlight: "highlight"
  of ideOutline: "outline"
  of ideKnown: "known"
  of ideMsg: "msg"
