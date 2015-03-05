#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the parsing of command line arguments.


# We do this here before the 'import' statement so 'defined' does not get
# confused with 'TGCMode.gcGenerational' etc.
template bootSwitch(name, expr, userString: expr): expr =
  # Helper to build boot constants, for debugging you can 'echo' the else part.
  const name = if expr: " " & userString else: ""

bootSwitch(usedRelease, defined(release), "-d:release")
bootSwitch(usedGnuReadline, defined(useGnuReadline), "-d:useGnuReadline")
bootSwitch(usedNoCaas, defined(noCaas), "-d:noCaas")
bootSwitch(usedBoehm, defined(boehmgc), "--gc:boehm")
bootSwitch(usedMarkAndSweep, defined(gcmarkandsweep), "--gc:markAndSweep")
bootSwitch(usedGenerational, defined(gcgenerational), "--gc:generational")
bootSwitch(usedNoGC, defined(nogc), "--gc:none")

import 
  os, msgs, options, nversion, condsyms, strutils, extccomp, platform, lists, 
  wordrecg, parseutils, nimblecmd, idents, parseopt

# but some have deps to imported modules. Yay.
bootSwitch(usedTinyC, hasTinyCBackend, "-d:tinyc")
bootSwitch(usedAvoidTimeMachine, noTimeMachine, "-d:avoidTimeMachine")
bootSwitch(usedNativeStacktrace,
  defined(nativeStackTrace) and nativeStackTraceSupported,
  "-d:nativeStackTrace")
bootSwitch(usedFFI, hasFFI, "-d:useFFI")


proc writeCommandLineUsage*()

type 
  TCmdLinePass* = enum 
    passCmd1,                 # first pass over the command line
    passCmd2,                 # second pass over the command line
    passPP                    # preprocessor called processCommand()

proc processCommand*(switch: string, pass: TCmdLinePass)
proc processSwitch*(switch, arg: string, pass: TCmdLinePass, info: TLineInfo)

# implementation

const
  HelpMessage = "Nim Compiler Version $1 (" & CompileDate & ") [$2: $3]\n" &
      "Copyright (c) 2006-2015 by Andreas Rumpf\n"

const 
  Usage = slurp"doc/basicopt.txt".replace("//", "")
  AdvancedUsage = slurp"doc/advopt.txt".replace("//", "")

proc getCommandLineDesc(): string = 
  result = (HelpMessage % [VersionAsString, platform.OS[platform.hostOS].name, 
                           CPU[platform.hostCPU].name]) & Usage

proc helpOnError(pass: TCmdLinePass) = 
  if pass == passCmd1:
    msgWriteln(getCommandLineDesc())
    msgQuit(0)

proc writeAdvancedUsage(pass: TCmdLinePass) = 
  if pass == passCmd1:
    msgWriteln(`%`(HelpMessage, [VersionAsString, 
                                 platform.OS[platform.hostOS].name, 
                                 CPU[platform.hostCPU].name]) & AdvancedUsage)
    msgQuit(0)

proc writeVersionInfo(pass: TCmdLinePass) = 
  if pass == passCmd1:
    msgWriteln(`%`(HelpMessage, [VersionAsString, 
                                 platform.OS[platform.hostOS].name, 
                                 CPU[platform.hostCPU].name]))

    discard """const gitHash = gorge("git log -n 1 --format=%H")
    if gitHash.strip.len == 40:
      msgWriteln("git hash: " & gitHash)"""

    msgWriteln("active boot switches:" & usedRelease & usedAvoidTimeMachine &
      usedTinyC & usedGnuReadline & usedNativeStacktrace & usedNoCaas &
      usedFFI & usedBoehm & usedMarkAndSweep & usedGenerational & usedNoGC)
    msgQuit(0)

var
  helpWritten: bool

proc writeCommandLineUsage() = 
  if not helpWritten: 
    msgWriteln(getCommandLineDesc())
    helpWritten = true

proc addPrefix(switch: string): string =
  if len(switch) == 1: result = "-" & switch
  else: result = "--" & switch

proc invalidCmdLineOption(pass: TCmdLinePass, switch: string, info: TLineInfo) = 
  if switch == " ": localError(info, errInvalidCmdLineOption, "-")
  else: localError(info, errInvalidCmdLineOption, addPrefix(switch))

proc splitSwitch(switch: string, cmd, arg: var string, pass: TCmdLinePass, 
                 info: TLineInfo) = 
  cmd = ""
  var i = 0
  if i < len(switch) and switch[i] == '-': inc(i)
  if i < len(switch) and switch[i] == '-': inc(i)
  while i < len(switch): 
    case switch[i]
    of 'a'..'z', 'A'..'Z', '0'..'9', '_', '.': add(cmd, switch[i])
    else: break 
    inc(i)
  if i >= len(switch): arg = ""
  elif switch[i] in {':', '=', '['}: arg = substr(switch, i + 1)
  else: invalidCmdLineOption(pass, switch, info)
  
proc processOnOffSwitch(op: TOptions, arg: string, pass: TCmdLinePass, 
                        info: TLineInfo) = 
  case whichKeyword(arg)
  of wOn: gOptions = gOptions + op
  of wOff: gOptions = gOptions - op
  else: localError(info, errOnOrOffExpectedButXFound, arg)
  
proc processOnOffSwitchG(op: TGlobalOptions, arg: string, pass: TCmdLinePass, 
                         info: TLineInfo) = 
  case whichKeyword(arg)
  of wOn: gGlobalOptions = gGlobalOptions + op
  of wOff: gGlobalOptions = gGlobalOptions - op
  else: localError(info, errOnOrOffExpectedButXFound, arg)
  
proc expectArg(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) = 
  if arg == "": localError(info, errCmdLineArgExpected, addPrefix(switch))
  
proc expectNoArg(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) = 
  if arg != "": localError(info, errCmdLineNoArgExpected, addPrefix(switch))
  
proc processSpecificNote(arg: string, state: TSpecialWord, pass: TCmdLinePass, 
                         info: TLineInfo; orig: string) = 
  var id = ""  # arg = "X]:on|off"
  var i = 0
  var n = hintMin
  while i < len(arg) and (arg[i] != ']'): 
    add(id, arg[i])
    inc(i)
  if i < len(arg) and (arg[i] == ']'): inc(i)
  else: invalidCmdLineOption(pass, orig, info)
  if i < len(arg) and (arg[i] in {':', '='}): inc(i)
  else: invalidCmdLineOption(pass, orig, info)
  if state == wHint:
    var x = findStr(msgs.HintsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(hintMin))
    else: localError(info, "unknown hint: " & id)
  else:
    var x = findStr(msgs.WarningsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(warnMin))
    else: localError(info, "unknown warning: " & id)
  case whichKeyword(substr(arg, i))
  of wOn: incl(gNotes, n)
  of wOff: excl(gNotes, n)
  else: localError(info, errOnOrOffExpectedButXFound, arg)

proc processCompile(filename: string) = 
  var found = findFile(filename)
  if found == "": found = filename
  var trunc = changeFileExt(found, "")
  extccomp.addExternalFileToCompile(found)
  extccomp.addFileToLink(completeCFilePath(trunc, false))

proc testCompileOptionArg*(switch, arg: string, info: TLineInfo): bool =
  case switch.normalize
  of "gc":
    case arg.normalize
    of "boehm":        result = gSelectedGC == gcBoehm
    of "refc":         result = gSelectedGC == gcRefc
    of "v2":           result = gSelectedGC == gcV2
    of "markandsweep": result = gSelectedGC == gcMarkAndSweep
    of "generational": result = gSelectedGC == gcGenerational
    of "none":         result = gSelectedGC == gcNone
    else: localError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of "opt":
    case arg.normalize
    of "speed": result = contains(gOptions, optOptimizeSpeed)
    of "size": result = contains(gOptions, optOptimizeSize)
    of "none": result = gOptions * {optOptimizeSpeed, optOptimizeSize} == {}
    else: localError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  else: invalidCmdLineOption(passCmd1, switch, info)

proc testCompileOption*(switch: string, info: TLineInfo): bool = 
  case switch.normalize
  of "debuginfo": result = contains(gGlobalOptions, optCDebug)
  of "compileonly", "c": result = contains(gGlobalOptions, optCompileOnly)
  of "nolinking": result = contains(gGlobalOptions, optNoLinking)
  of "nomain": result = contains(gGlobalOptions, optNoMain)
  of "forcebuild", "f": result = contains(gGlobalOptions, optForceFullMake)
  of "warnings", "w": result = contains(gOptions, optWarns)
  of "hints": result = contains(gOptions, optHints)
  of "threadanalysis": result = contains(gGlobalOptions, optThreadAnalysis)
  of "stacktrace": result = contains(gOptions, optStackTrace)
  of "linetrace": result = contains(gOptions, optLineTrace)
  of "debugger": result = contains(gOptions, optEndb)
  of "profiler": result = contains(gOptions, optProfiler)
  of "checks", "x": result = gOptions * ChecksOptions == ChecksOptions
  of "floatchecks":
    result = gOptions * {optNaNCheck, optInfCheck} == {optNaNCheck, optInfCheck}
  of "infchecks": result = contains(gOptions, optInfCheck)
  of "nanchecks": result = contains(gOptions, optNaNCheck)
  of "objchecks": result = contains(gOptions, optObjCheck)
  of "fieldchecks": result = contains(gOptions, optFieldCheck)
  of "rangechecks": result = contains(gOptions, optRangeCheck)
  of "boundchecks": result = contains(gOptions, optBoundsCheck)
  of "overflowchecks": result = contains(gOptions, optOverflowCheck)
  of "linedir": result = contains(gOptions, optLineDir)
  of "assertions", "a": result = contains(gOptions, optAssert)
  of "deadcodeelim": result = contains(gGlobalOptions, optDeadCodeElim)
  of "run", "r": result = contains(gGlobalOptions, optRun)
  of "symbolfiles": result = contains(gGlobalOptions, optSymbolFiles)
  of "genscript": result = contains(gGlobalOptions, optGenScript)
  of "threads": result = contains(gGlobalOptions, optThreads)
  of "taintmode": result = contains(gGlobalOptions, optTaintMode)
  of "tlsemulation": result = contains(gGlobalOptions, optTlsEmulation)
  of "implicitstatic": result = contains(gOptions, optImplicitStatic)
  of "patterns": result = contains(gOptions, optPatterns)
  of "experimental": result = gExperimentalMode
  else: invalidCmdLineOption(passCmd1, switch, info)
  
proc processPath(path: string, notRelativeToProj = false): string =
  let p = if notRelativeToProj or os.isAbsolute(path) or
              '$' in path or path[0] == '.': 
            path 
          else:
            options.gProjectPath / path
  result = unixToNativePath(p % ["nimrod", getPrefixDir(),
    "nim", getPrefixDir(),
    "lib", libpath,
    "home", removeTrailingDirSep(os.getHomeDir()),
    "projectname", options.gProjectName,
    "projectpath", options.gProjectPath])

proc trackDirty(arg: string, info: TLineInfo) =
  var a = arg.split(',')
  if a.len != 4: localError(info, errTokenExpected,
                            "DIRTY_BUFFER,ORIGINAL_FILE,LINE,COLUMN")
  var line, column: int
  if parseUtils.parseInt(a[2], line) <= 0:
    localError(info, errInvalidNumber, a[1])
  if parseUtils.parseInt(a[3], column) <= 0:
    localError(info, errInvalidNumber, a[2])
  
  let dirtyOriginalIdx = a[1].fileInfoIdx
  if dirtyOriginalIdx >= 0:
    msgs.setDirtyFile(dirtyOriginalIdx, a[0])

  gTrackPos = newLineInfo(dirtyOriginalIdx, line, column)

proc track(arg: string, info: TLineInfo) = 
  var a = arg.split(',')
  if a.len != 3: localError(info, errTokenExpected, "FILE,LINE,COLUMN")
  var line, column: int
  if parseUtils.parseInt(a[1], line) <= 0:
    localError(info, errInvalidNumber, a[1])
  if parseUtils.parseInt(a[2], column) <= 0:
    localError(info, errInvalidNumber, a[2])
  gTrackPos = newLineInfo(a[0], line, column)

proc dynlibOverride(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if pass in {passCmd2, passPP}:
    expectArg(switch, arg, pass, info)
    options.inclDynlibOverride(arg)

proc processSwitch(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) = 
  var 
    theOS: TSystemOS
    cpu: TSystemCPU
    key, val: string
  case switch.normalize
  of "path", "p": 
    expectArg(switch, arg, pass, info)
    addPath(processPath(arg), info)
  of "nimblepath", "babelpath":
    # keep the old name for compat
    if pass in {passCmd2, passPP} and not options.gNoNimblePath:
      expectArg(switch, arg, pass, info)
      let path = processPath(arg, notRelativeToProj=true)
      nimblePath(path, info)
  of "nonimblepath", "nobabelpath":
    expectNoArg(switch, arg, pass, info)
    options.gNoNimblePath = true
  of "excludepath":
    expectArg(switch, arg, pass, info)
    let path = processPath(arg)
    lists.excludePath(options.searchPaths, path)
    lists.excludePath(options.lazyPaths, path)
    if (len(path) > 0) and (path[len(path) - 1] == DirSep):
      let strippedPath = path[0 .. (len(path) - 2)]
      lists.excludePath(options.searchPaths, strippedPath)
      lists.excludePath(options.lazyPaths, strippedPath)
  of "nimcache":
    expectArg(switch, arg, pass, info)
    options.nimcacheDir = processPath(arg)
  of "out", "o": 
    expectArg(switch, arg, pass, info)
    options.outFile = arg
  of "docseesrcurl":
    expectArg(switch, arg, pass, info)
    options.docSeeSrcUrl = arg
  of "mainmodule", "m":
    discard "allow for backwards compatibility, but don't do anything"
  of "define", "d": 
    expectArg(switch, arg, pass, info)
    defineSymbol(arg)
  of "undef", "u": 
    expectArg(switch, arg, pass, info)
    undefSymbol(arg)
  of "symbol":
    expectArg(switch, arg, pass, info)
    declareSymbol(arg)  
  of "compile": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: processCompile(arg)
  of "link": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: addFileToLink(arg)
  of "debuginfo":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optCDebug)
  of "embedsrc":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optEmbedOrigSrc)
  of "compileonly", "c": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optCompileOnly)
  of "nolinking": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optNoLinking)
  of "nomain": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optNoMain)
  of "forcebuild", "f": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optForceFullMake)
  of "project":
    expectNoArg(switch, arg, pass, info)
    gWholeProject = true
  of "gc": 
    expectArg(switch, arg, pass, info)
    case arg.normalize
    of "boehm": 
      gSelectedGC = gcBoehm
      defineSymbol("boehmgc")
    of "refc":
      gSelectedGC = gcRefc
    of "v2":
      gSelectedGC = gcV2
    of "markandsweep":
      gSelectedGC = gcMarkAndSweep
      defineSymbol("gcmarkandsweep")
    of "generational":
      gSelectedGC = gcGenerational
      defineSymbol("gcgenerational")
    of "none":
      gSelectedGC = gcNone
      defineSymbol("nogc")
    else: localError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of "warnings", "w": processOnOffSwitch({optWarns}, arg, pass, info)
  of "warning": processSpecificNote(arg, wWarning, pass, info, switch)
  of "hint": processSpecificNote(arg, wHint, pass, info, switch)
  of "hints": processOnOffSwitch({optHints}, arg, pass, info)
  of "threadanalysis": processOnOffSwitchG({optThreadAnalysis}, arg, pass, info)
  of "stacktrace": processOnOffSwitch({optStackTrace}, arg, pass, info)
  of "linetrace": processOnOffSwitch({optLineTrace}, arg, pass, info)
  of "debugger":
    case arg.normalize
    of "on", "endb":
      gOptions.incl optEndb
      defineSymbol("endb")
    of "off":
      gOptions.excl optEndb
      undefSymbol("endb")
    of "native", "gdb":
      incl(gGlobalOptions, optCDebug)
      gOptions = gOptions + {optLineDir} - {optEndb}
      undefSymbol("endb")
    else:
      localError(info, "expected endb|gdb but found " & arg)
  of "profiler": 
    processOnOffSwitch({optProfiler}, arg, pass, info)
    if optProfiler in gOptions: defineSymbol("profiler")
    else: undefSymbol("profiler")
  of "checks", "x": processOnOffSwitch(ChecksOptions, arg, pass, info)
  of "floatchecks":
    processOnOffSwitch({optNaNCheck, optInfCheck}, arg, pass, info)
  of "infchecks": processOnOffSwitch({optInfCheck}, arg, pass, info)
  of "nanchecks": processOnOffSwitch({optNaNCheck}, arg, pass, info)
  of "objchecks": processOnOffSwitch({optObjCheck}, arg, pass, info)
  of "fieldchecks": processOnOffSwitch({optFieldCheck}, arg, pass, info)
  of "rangechecks": processOnOffSwitch({optRangeCheck}, arg, pass, info)
  of "boundchecks": processOnOffSwitch({optBoundsCheck}, arg, pass, info)
  of "overflowchecks": processOnOffSwitch({optOverflowCheck}, arg, pass, info)
  of "linedir": processOnOffSwitch({optLineDir}, arg, pass, info)
  of "assertions", "a": processOnOffSwitch({optAssert}, arg, pass, info)
  of "deadcodeelim": processOnOffSwitchG({optDeadCodeElim}, arg, pass, info)
  of "threads":
    processOnOffSwitchG({optThreads}, arg, pass, info)
    if optThreads in gGlobalOptions: incl(gNotes, warnGcUnsafe)
  of "tlsemulation": processOnOffSwitchG({optTlsEmulation}, arg, pass, info)
  of "taintmode": processOnOffSwitchG({optTaintMode}, arg, pass, info)
  of "implicitstatic":
    processOnOffSwitch({optImplicitStatic}, arg, pass, info)
  of "patterns":
    processOnOffSwitch({optPatterns}, arg, pass, info)
  of "opt":
    expectArg(switch, arg, pass, info)
    case arg.normalize
    of "speed": 
      incl(gOptions, optOptimizeSpeed)
      excl(gOptions, optOptimizeSize)
    of "size": 
      excl(gOptions, optOptimizeSpeed)
      incl(gOptions, optOptimizeSize)
    of "none":
      excl(gOptions, optOptimizeSpeed)
      excl(gOptions, optOptimizeSize)
    else: localError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  of "app": 
    expectArg(switch, arg, pass, info)
    case arg.normalize
    of "gui":
      incl(gGlobalOptions, optGenGuiApp)
      defineSymbol("executable")
      defineSymbol("guiapp")
    of "console":
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol("executable")
      defineSymbol("consoleapp")
    of "lib":
      incl(gGlobalOptions, optGenDynLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol("library")
      defineSymbol("dll")
    of "staticlib":
      incl(gGlobalOptions, optGenStaticLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol("library")
      defineSymbol("staticlib")
    else: localError(info, errGuiConsoleOrLibExpectedButXFound, arg)
  of "passc", "t": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addCompileOption(arg)
  of "passl", "l": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addLinkOption(arg)
  of "cincludes":
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cIncludes.add arg.processPath
  of "clibdir":
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cLibs.add arg.processPath
  of "clib":
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cLinkedLibs.add arg.processPath
  of "header":
    headerFile = arg
    incl(gGlobalOptions, optGenIndex)
  of "index":
    processOnOffSwitchG({optGenIndex}, arg, pass, info)
  of "import":
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: implicitImports.add arg
  of "include":
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: implicitIncludes.add arg
  of "listcmd": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optListCmd)
  of "genmapping": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenMapping)
  of "os": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd1, passPP}: 
      theOS = platform.nameToOS(arg)
      if theOS == osNone: localError(info, errUnknownOS, arg)
      elif theOS != platform.hostOS: 
        setTarget(theOS, targetCPU)
        condsyms.initDefines()
  of "cpu": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd1, passPP}: 
      cpu = platform.nameToCPU(arg)
      if cpu == cpuNone: localError(info, errUnknownCPU, arg)
      elif cpu != platform.hostCPU: 
        setTarget(targetOS, cpu)
        condsyms.initDefines()
  of "run", "r": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optRun)
  of "verbosity": 
    expectArg(switch, arg, pass, info)
    gVerbosity = parseInt(arg)
  of "parallelbuild": 
    expectArg(switch, arg, pass, info)
    gNumberOfProcessors = parseInt(arg)
  of "version", "v": 
    expectNoArg(switch, arg, pass, info)
    writeVersionInfo(pass)
  of "advanced": 
    expectNoArg(switch, arg, pass, info)
    writeAdvancedUsage(pass)
  of "help", "h": 
    expectNoArg(switch, arg, pass, info)
    helpOnError(pass)
  of "symbolfiles": 
    processOnOffSwitchG({optSymbolFiles}, arg, pass, info)
  of "skipcfg": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipConfigFile)
  of "skipprojcfg": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipProjConfigFile)
  of "skipusercfg":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipUserConfigFile)
  of "skipparentcfg":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipParentConfigFiles)
  of "genscript": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenScript)
  of "lib":
    expectArg(switch, arg, pass, info)
    libpath = processPath(arg, notRelativeToProj=true)
  of "putenv": 
    expectArg(switch, arg, pass, info)
    splitSwitch(arg, key, val, pass, info)
    os.putEnv(key, val)
  of "cc": 
    expectArg(switch, arg, pass, info)
    setCC(arg)
  of "track":
    expectArg(switch, arg, pass, info)
    track(arg, info)
  of "trackdirty":
    expectArg(switch, arg, pass, info)
    trackDirty(arg, info)
  of "suggest": 
    expectNoArg(switch, arg, pass, info)
    gIdeCmd = ideSug
  of "def":
    expectNoArg(switch, arg, pass, info)
    gIdeCmd = ideDef
  of "eval":
    expectArg(switch, arg, pass, info)
    gEvalExpr = arg
  of "context":
    expectNoArg(switch, arg, pass, info)
    gIdeCmd = ideCon
  of "usages":
    expectNoArg(switch, arg, pass, info)
    gIdeCmd = ideUse
  of "stdout":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optStdout)
  of "listfullpaths":
    expectNoArg(switch, arg, pass, info)
    gListFullPaths = true
  of "dynliboverride":
    dynlibOverride(switch, arg, pass, info)
  of "cs":
    expectArg(switch, arg, pass, info)
    case arg
    of "partial": idents.firstCharIsCS = true
    of "none": idents.firstCharIsCS = false
    else: localError(info, errGenerated,
      "'partial' or 'none' expected, but found " & arg)
  of "experimental":
    expectNoArg(switch, arg, pass, info)
    gExperimentalMode = true
  else:
    if strutils.find(switch, '.') >= 0: options.setConfigVar(switch, arg)
    else: invalidCmdLineOption(pass, switch, info)
  
proc processCommand(switch: string, pass: TCmdLinePass) =
  var cmd, arg: string
  splitSwitch(switch, cmd, arg, pass, gCmdLineInfo)
  processSwitch(cmd, arg, pass, gCmdLineInfo)


var
  arguments* = ""
    # the arguments to be passed to the program that
    # should be run

proc processSwitch*(pass: TCmdLinePass; p: OptParser) =
  # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
  # we fix this here
  var bracketLe = strutils.find(p.key, '[')
  if bracketLe >= 0: 
    var key = substr(p.key, 0, bracketLe - 1)
    var val = substr(p.key, bracketLe + 1) & ':' & p.val
    processSwitch(key, val, pass, gCmdLineInfo)
  else: 
    processSwitch(p.key, p.val, pass, gCmdLineInfo)

proc processArgument*(pass: TCmdLinePass; p: OptParser; 
                      argsCount: var int): bool =
  if argsCount == 0:
    options.command = p.key
  else:
    if pass == passCmd1: options.commandArgs.add p.key
    if argsCount == 1:
      # support UNIX style filenames anywhere for portable build scripts:
      options.gProjectName = unixToNativePath(p.key)
      arguments = cmdLineRest(p)
      result = true
  inc argsCount
