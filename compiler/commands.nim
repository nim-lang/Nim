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
template bootSwitch(name, expr, userString) =
  # Helper to build boot constants, for debugging you can 'echo' the else part.
  const name = if expr: " " & userString else: ""

bootSwitch(usedRelease, defined(release), "-d:release")
bootSwitch(usedGnuReadline, defined(useLinenoise), "-d:useLinenoise")
bootSwitch(usedBoehm, defined(boehmgc), "--gc:boehm")
bootSwitch(usedMarkAndSweep, defined(gcmarkandsweep), "--gc:markAndSweep")
bootSwitch(usedGenerational, defined(gcgenerational), "--gc:generational")
bootSwitch(usedGoGC, defined(gogc), "--gc:go")
bootSwitch(usedNoGC, defined(nogc), "--gc:none")

import
  os, msgs, options, nversion, condsyms, strutils, extccomp, platform,
  wordrecg, parseutils, nimblecmd, idents, parseopt, sequtils, configuration

# but some have deps to imported modules. Yay.
bootSwitch(usedTinyC, hasTinyCBackend, "-d:tinyc")
bootSwitch(usedNativeStacktrace,
  defined(nativeStackTrace) and nativeStackTraceSupported,
  "-d:nativeStackTrace")
bootSwitch(usedFFI, hasFFI, "-d:useFFI")

type
  TCmdLinePass* = enum
    passCmd1,                 # first pass over the command line
    passCmd2,                 # second pass over the command line
    passPP                    # preprocessor called processCommand()

const
  HelpMessage = "Nim Compiler Version $1 [$2: $3]\n" &
      "Compiled at $4\n" &
      "Copyright (c) 2006-" & copyrightYear & " by Andreas Rumpf\n"

const
  Usage = slurp"../doc/basicopt.txt".replace("//", "")
  FeatureDesc = block:
    var x = ""
    for f in low(Feature)..high(Feature):
      if x.len > 0: x.add "|"
      x.add $f
    x
  AdvancedUsage = slurp"../doc/advopt.txt".replace("//", "") % FeatureDesc

proc getCommandLineDesc(): string =
  result = (HelpMessage % [VersionAsString, platform.OS[platform.hostOS].name,
                           CPU[platform.hostCPU].name, CompileDate]) &
                           Usage

proc helpOnError(pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(getCommandLineDesc(), {msgStdout})
    msgQuit(0)

proc writeAdvancedUsage(pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(`%`(HelpMessage, [VersionAsString,
                                 platform.OS[platform.hostOS].name,
                                 CPU[platform.hostCPU].name, CompileDate]) &
                                 AdvancedUsage,
               {msgStdout})
    msgQuit(0)

proc writeFullhelp(pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(`%`(HelpMessage, [VersionAsString,
                                 platform.OS[platform.hostOS].name,
                                 CPU[platform.hostCPU].name, CompileDate]) &
                                 Usage & AdvancedUsage,
               {msgStdout})
    msgQuit(0)

proc writeVersionInfo(pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(`%`(HelpMessage, [VersionAsString,
                                 platform.OS[platform.hostOS].name,
                                 CPU[platform.hostCPU].name, CompileDate]),
               {msgStdout})

    const gitHash = gorge("git log -n 1 --format=%H").strip
    when gitHash.len == 40:
      msgWriteln("git hash: " & gitHash, {msgStdout})

    msgWriteln("active boot switches:" & usedRelease &
      usedTinyC & usedGnuReadline & usedNativeStacktrace &
      usedFFI & usedBoehm & usedMarkAndSweep & usedGenerational & usedGoGC & usedNoGC,
               {msgStdout})
    msgQuit(0)

proc writeCommandLineUsage*(helpWritten: var bool) =
  if not helpWritten:
    msgWriteln(getCommandLineDesc(), {msgStdout})
    helpWritten = true

proc addPrefix(switch: string): string =
  if len(switch) == 1: result = "-" & switch
  else: result = "--" & switch

const
  errInvalidCmdLineOption = "invalid command line option: '$1'"
  errOnOrOffExpectedButXFound = "'on' or 'off' expected, but '$1' found"
  errOnOffOrListExpectedButXFound = "'on', 'off' or 'list' expected, but '$1' found"

proc invalidCmdLineOption(conf: ConfigRef; pass: TCmdLinePass, switch: string, info: TLineInfo) =
  if switch == " ": localError(conf, info, errInvalidCmdLineOption % "-")
  else: localError(conf, info, errInvalidCmdLineOption % addPrefix(switch))

proc splitSwitch(conf: ConfigRef; switch: string, cmd, arg: var string, pass: TCmdLinePass,
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
  else: invalidCmdLineOption(conf, pass, switch, info)

proc processOnOffSwitch(conf: ConfigRef; op: TOptions, arg: string, pass: TCmdLinePass,
                        info: TLineInfo) =
  case arg.normalize
  of "on": gOptions = gOptions + op
  of "off": gOptions = gOptions - op
  else: localError(conf, info, errOnOrOffExpectedButXFound % arg)

proc processOnOffSwitchOrList(conf: ConfigRef; op: TOptions, arg: string, pass: TCmdLinePass,
                              info: TLineInfo): bool =
  result = false
  case arg.normalize
  of "on": gOptions = gOptions + op
  of "off": gOptions = gOptions - op
  of "list": result = true
  else: localError(conf, info, errOnOffOrListExpectedButXFound % arg)

proc processOnOffSwitchG(conf: ConfigRef; op: TGlobalOptions, arg: string, pass: TCmdLinePass,
                         info: TLineInfo) =
  case arg.normalize
  of "on": gGlobalOptions = gGlobalOptions + op
  of "off": gGlobalOptions = gGlobalOptions - op
  else: localError(conf, info, errOnOrOffExpectedButXFound % arg)

proc expectArg(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if arg == "":
    localError(conf, info, "argument for command line option expected: '$1'" % addPrefix(switch))

proc expectNoArg(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if arg != "":
    localError(conf, info, "invalid argument for command line option: '$1'" % addPrefix(switch))

proc processSpecificNote*(arg: string, state: TSpecialWord, pass: TCmdLinePass,
                         info: TLineInfo; orig: string; conf: ConfigRef) =
  var id = ""  # arg = "X]:on|off"
  var i = 0
  var n = hintMin
  while i < len(arg) and (arg[i] != ']'):
    add(id, arg[i])
    inc(i)
  if i < len(arg) and (arg[i] == ']'): inc(i)
  else: invalidCmdLineOption(conf, pass, orig, info)
  if i < len(arg) and (arg[i] in {':', '='}): inc(i)
  else: invalidCmdLineOption(conf, pass, orig, info)
  if state == wHint:
    let x = findStr(configuration.HintsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(hintMin))
    else: localError(conf, info, "unknown hint: " & id)
  else:
    let x = findStr(configuration.WarningsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(warnMin))
    else: localError(conf, info, "unknown warning: " & id)
  case substr(arg, i).normalize
  of "on":
    incl(conf.notes, n)
    incl(conf.mainPackageNotes, n)
    incl(conf.enableNotes, n)
  of "off":
    excl(conf.notes, n)
    excl(conf.mainPackageNotes, n)
    incl(conf.disableNotes, n)
    excl(conf.foreignPackageNotes, n)
  else: localError(conf, info, errOnOrOffExpectedButXFound % arg)

proc processCompile(conf: ConfigRef; filename: string) =
  var found = findFile(conf, filename)
  if found == "": found = filename
  extccomp.addExternalFileToCompile(conf, found)

const
  errNoneBoehmRefcExpectedButXFound = "'none', 'boehm' or 'refc' expected, but '$1' found"
  errNoneSpeedOrSizeExpectedButXFound = "'none', 'speed' or 'size' expected, but '$1' found"
  errGuiConsoleOrLibExpectedButXFound = "'gui', 'console' or 'lib' expected, but '$1' found"

proc testCompileOptionArg*(conf: ConfigRef; switch, arg: string, info: TLineInfo): bool =
  case switch.normalize
  of "gc":
    case arg.normalize
    of "boehm":        result = gSelectedGC == gcBoehm
    of "refc":         result = gSelectedGC == gcRefc
    of "v2":           result = gSelectedGC == gcV2
    of "markandsweep": result = gSelectedGC == gcMarkAndSweep
    of "generational": result = gSelectedGC == gcGenerational
    of "go":           result = gSelectedGC == gcGo
    of "none":         result = gSelectedGC == gcNone
    of "stack", "regions": result = gSelectedGC == gcRegions
    else: localError(conf, info, errNoneBoehmRefcExpectedButXFound % arg)
  of "opt":
    case arg.normalize
    of "speed": result = contains(gOptions, optOptimizeSpeed)
    of "size": result = contains(gOptions, optOptimizeSize)
    of "none": result = gOptions * {optOptimizeSpeed, optOptimizeSize} == {}
    else: localError(conf, info, errNoneSpeedOrSizeExpectedButXFound % arg)
  of "verbosity": result = $gVerbosity == arg
  of "app":
    case arg.normalize
    of "gui":       result = contains(gGlobalOptions, optGenGuiApp)
    of "console":   result = not contains(gGlobalOptions, optGenGuiApp)
    of "lib":       result = contains(gGlobalOptions, optGenDynLib) and
                      not contains(gGlobalOptions, optGenGuiApp)
    of "staticlib": result = contains(gGlobalOptions, optGenStaticLib) and
                      not contains(gGlobalOptions, optGenGuiApp)
    else: localError(conf, info, errGuiConsoleOrLibExpectedButXFound % arg)
  of "dynliboverride":
    result = isDynlibOverride(conf, arg)
  else: invalidCmdLineOption(conf, passCmd1, switch, info)

proc testCompileOption*(conf: ConfigRef; switch: string, info: TLineInfo): bool =
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
  of "memtracker": result = contains(gOptions, optMemTracker)
  of "checks", "x": result = gOptions * ChecksOptions == ChecksOptions
  of "floatchecks":
    result = gOptions * {optNaNCheck, optInfCheck} == {optNaNCheck, optInfCheck}
  of "infchecks": result = contains(gOptions, optInfCheck)
  of "nanchecks": result = contains(gOptions, optNaNCheck)
  of "nilchecks": result = contains(gOptions, optNilCheck)
  of "objchecks": result = contains(gOptions, optObjCheck)
  of "fieldchecks": result = contains(gOptions, optFieldCheck)
  of "rangechecks": result = contains(gOptions, optRangeCheck)
  of "boundchecks": result = contains(gOptions, optBoundsCheck)
  of "overflowchecks": result = contains(gOptions, optOverflowCheck)
  of "movechecks": result = contains(gOptions, optMoveCheck)
  of "linedir": result = contains(gOptions, optLineDir)
  of "assertions", "a": result = contains(gOptions, optAssert)
  of "run", "r": result = contains(gGlobalOptions, optRun)
  of "symbolfiles": result = gSymbolFiles != disabledSf
  of "genscript": result = contains(gGlobalOptions, optGenScript)
  of "threads": result = contains(gGlobalOptions, optThreads)
  of "taintmode": result = contains(gGlobalOptions, optTaintMode)
  of "tlsemulation": result = contains(gGlobalOptions, optTlsEmulation)
  of "implicitstatic": result = contains(gOptions, optImplicitStatic)
  of "patterns": result = contains(gOptions, optPatterns)
  of "excessivestacktrace": result = contains(gGlobalOptions, optExcessiveStackTrace)
  else: invalidCmdLineOption(conf, passCmd1, switch, info)

proc processPath(conf: ConfigRef; path: string, info: TLineInfo,
                 notRelativeToProj = false): string =
  let p = if os.isAbsolute(path) or '$' in path:
            path
          elif notRelativeToProj:
            getCurrentDir() / path
          else:
            conf.projectPath / path
  try:
    result = pathSubs(conf, p, info.toFullPath().splitFile().dir)
  except ValueError:
    localError(conf, info, "invalid path: " & p)
    result = p

proc processCfgPath(conf: ConfigRef; path: string, info: TLineInfo): string =
  let path = if path[0] == '"': strutils.unescape(path) else: path
  let basedir = info.toFullPath().splitFile().dir
  let p = if os.isAbsolute(path) or '$' in path:
            path
          else:
            basedir / path
  try:
    result = pathSubs(conf, p, basedir)
  except ValueError:
    localError(conf, info, "invalid path: " & p)
    result = p

const
  errInvalidNumber = "$1 is not a valid number"

proc trackDirty(conf: ConfigRef; arg: string, info: TLineInfo) =
  var a = arg.split(',')
  if a.len != 4: localError(conf, info,
                            "DIRTY_BUFFER,ORIGINAL_FILE,LINE,COLUMN expected")
  var line, column: int
  if parseUtils.parseInt(a[2], line) <= 0:
    localError(conf, info, errInvalidNumber % a[1])
  if parseUtils.parseInt(a[3], column) <= 0:
    localError(conf, info, errInvalidNumber % a[2])

  let dirtyOriginalIdx = fileInfoIdx(conf, a[1])
  if dirtyOriginalIdx.int32 >= 0:
    msgs.setDirtyFile(dirtyOriginalIdx, a[0])

  gTrackPos = newLineInfo(dirtyOriginalIdx, line, column)

proc track(conf: ConfigRef; arg: string, info: TLineInfo) =
  var a = arg.split(',')
  if a.len != 3: localError(conf, info, "FILE,LINE,COLUMN expected")
  var line, column: int
  if parseUtils.parseInt(a[1], line) <= 0:
    localError(conf, info, errInvalidNumber % a[1])
  if parseUtils.parseInt(a[2], column) <= 0:
    localError(conf, info, errInvalidNumber % a[2])
  gTrackPos = newLineInfo(conf, a[0], line, column)

proc dynlibOverride(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if pass in {passCmd2, passPP}:
    expectArg(conf, switch, arg, pass, info)
    options.inclDynlibOverride(conf, arg)

proc processSwitch*(switch, arg: string, pass: TCmdLinePass, info: TLineInfo;
                    conf: ConfigRef) =
  var
    theOS: TSystemOS
    cpu: TSystemCPU
    key, val: string
  case switch.normalize
  of "path", "p":
    expectArg(conf, switch, arg, pass, info)
    addPath(conf, if pass == passPP: processCfgPath(conf, arg, info) else: processPath(conf, arg, info), info)
  of "nimblepath", "babelpath":
    # keep the old name for compat
    if pass in {passCmd2, passPP} and not options.gNoNimblePath:
      expectArg(conf, switch, arg, pass, info)
      var path = processPath(conf, arg, info, notRelativeToProj=true)
      let nimbleDir = getEnv("NIMBLE_DIR")
      if nimbleDir.len > 0 and pass == passPP: path = nimbleDir / "pkgs"
      nimblePath(conf, path, info)
  of "nonimblepath", "nobabelpath":
    expectNoArg(conf, switch, arg, pass, info)
    disableNimblePath(conf)
  of "excludepath":
    expectArg(conf, switch, arg, pass, info)
    let path = processPath(conf, arg, info)

    conf.searchPaths.keepItIf(cmpPaths(it, path) != 0)
    conf.lazyPaths.keepItIf(cmpPaths(it, path) != 0)

    if (len(path) > 0) and (path[len(path) - 1] == DirSep):
      let strippedPath = path[0 .. (len(path) - 2)]
      conf.searchPaths.keepItIf(cmpPaths(it, strippedPath) != 0)
      conf.lazyPaths.keepItIf(cmpPaths(it, strippedPath) != 0)
  of "nimcache":
    expectArg(conf, switch, arg, pass, info)
    conf.nimcacheDir = processPath(conf, arg, info, true)
  of "out", "o":
    expectArg(conf, switch, arg, pass, info)
    conf.outFile = arg
  of "docseesrcurl":
    expectArg(conf, switch, arg, pass, info)
    conf.docSeeSrcUrl = arg
  of "mainmodule", "m":
    discard "allow for backwards compatibility, but don't do anything"
  of "define", "d":
    expectArg(conf, switch, arg, pass, info)
    if {':', '='} in arg:
      splitSwitch(conf, arg, key, val, pass, info)
      defineSymbol(conf.symbols, key, val)
    else:
      defineSymbol(conf.symbols, arg)
  of "undef", "u":
    expectArg(conf, switch, arg, pass, info)
    undefSymbol(conf.symbols, arg)
  of "symbol":
    expectArg(conf, switch, arg, pass, info)
    # deprecated, do nothing
  of "compile":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: processCompile(conf, arg)
  of "link":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: addExternalFileToLink(conf, arg)
  of "debuginfo":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optCDebug)
  of "embedsrc":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optEmbedOrigSrc)
  of "compileonly", "c":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optCompileOnly)
  of "nolinking":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optNoLinking)
  of "nomain":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optNoMain)
  of "forcebuild", "f":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optForceFullMake)
  of "project":
    expectNoArg(conf, switch, arg, pass, info)
    gWholeProject = true
  of "gc":
    expectArg(conf, switch, arg, pass, info)
    case arg.normalize
    of "boehm":
      gSelectedGC = gcBoehm
      defineSymbol(conf.symbols, "boehmgc")
    of "refc":
      gSelectedGC = gcRefc
    of "v2":
      gSelectedGC = gcV2
    of "markandsweep":
      gSelectedGC = gcMarkAndSweep
      defineSymbol(conf.symbols, "gcmarkandsweep")
    of "generational":
      gSelectedGC = gcGenerational
      defineSymbol(conf.symbols, "gcgenerational")
    of "go":
      gSelectedGC = gcGo
      defineSymbol(conf.symbols, "gogc")
    of "none":
      gSelectedGC = gcNone
      defineSymbol(conf.symbols, "nogc")
    of "stack", "regions":
      gSelectedGC= gcRegions
      defineSymbol(conf.symbols, "gcregions")
    else: localError(conf, info, errNoneBoehmRefcExpectedButXFound % arg)
  of "warnings", "w":
    if processOnOffSwitchOrList(conf, {optWarns}, arg, pass, info): listWarnings(conf)
  of "warning": processSpecificNote(arg, wWarning, pass, info, switch, conf)
  of "hint": processSpecificNote(arg, wHint, pass, info, switch, conf)
  of "hints":
    if processOnOffSwitchOrList(conf, {optHints}, arg, pass, info): listHints(conf)
  of "threadanalysis": processOnOffSwitchG(conf, {optThreadAnalysis}, arg, pass, info)
  of "stacktrace": processOnOffSwitch(conf, {optStackTrace}, arg, pass, info)
  of "excessivestacktrace": processOnOffSwitchG(conf, {optExcessiveStackTrace}, arg, pass, info)
  of "linetrace": processOnOffSwitch(conf, {optLineTrace}, arg, pass, info)
  of "debugger":
    case arg.normalize
    of "on", "endb":
      gOptions.incl optEndb
      defineSymbol(conf.symbols, "endb")
    of "off":
      gOptions.excl optEndb
      undefSymbol(conf.symbols, "endb")
    of "native", "gdb":
      incl(gGlobalOptions, optCDebug)
      gOptions = gOptions + {optLineDir} - {optEndb}
      defineSymbol(conf.symbols, "nimTypeNames") # type names are used in gdb pretty printing
      undefSymbol(conf.symbols, "endb")
    else:
      localError(conf, info, "expected endb|gdb but found " & arg)
  of "profiler":
    processOnOffSwitch(conf, {optProfiler}, arg, pass, info)
    if optProfiler in gOptions: defineSymbol(conf.symbols, "profiler")
    else: undefSymbol(conf.symbols, "profiler")
  of "memtracker":
    processOnOffSwitch(conf, {optMemTracker}, arg, pass, info)
    if optMemTracker in gOptions: defineSymbol(conf.symbols, "memtracker")
    else: undefSymbol(conf.symbols, "memtracker")
  of "hotcodereloading":
    processOnOffSwitch(conf, {optHotCodeReloading}, arg, pass, info)
    if optHotCodeReloading in gOptions: defineSymbol(conf.symbols, "hotcodereloading")
    else: undefSymbol(conf.symbols, "hotcodereloading")
  of "oldnewlines":
    case arg.normalize
    of "on":
      conf.oldNewlines = true
      defineSymbol(conf.symbols, "nimOldNewlines")
    of "off":
      conf.oldNewlines = false
      undefSymbol(conf.symbols, "nimOldNewlines")
    else:
      localError(conf, info, errOnOrOffExpectedButXFound % arg)
  of "laxstrings": processOnOffSwitch(conf, {optLaxStrings}, arg, pass, info)
  of "checks", "x": processOnOffSwitch(conf, ChecksOptions, arg, pass, info)
  of "floatchecks":
    processOnOffSwitch(conf, {optNaNCheck, optInfCheck}, arg, pass, info)
  of "infchecks": processOnOffSwitch(conf, {optInfCheck}, arg, pass, info)
  of "nanchecks": processOnOffSwitch(conf, {optNaNCheck}, arg, pass, info)
  of "nilchecks": processOnOffSwitch(conf, {optNilCheck}, arg, pass, info)
  of "objchecks": processOnOffSwitch(conf, {optObjCheck}, arg, pass, info)
  of "fieldchecks": processOnOffSwitch(conf, {optFieldCheck}, arg, pass, info)
  of "rangechecks": processOnOffSwitch(conf, {optRangeCheck}, arg, pass, info)
  of "boundchecks": processOnOffSwitch(conf, {optBoundsCheck}, arg, pass, info)
  of "overflowchecks": processOnOffSwitch(conf, {optOverflowCheck}, arg, pass, info)
  of "movechecks": processOnOffSwitch(conf, {optMoveCheck}, arg, pass, info)
  of "linedir": processOnOffSwitch(conf, {optLineDir}, arg, pass, info)
  of "assertions", "a": processOnOffSwitch(conf, {optAssert}, arg, pass, info)
  of "deadcodeelim": discard # deprecated, dead code elim always on
  of "threads":
    processOnOffSwitchG(conf, {optThreads}, arg, pass, info)
    #if optThreads in gGlobalOptions: incl(conf.notes, warnGcUnsafe)
  of "tlsemulation": processOnOffSwitchG(conf, {optTlsEmulation}, arg, pass, info)
  of "taintmode": processOnOffSwitchG(conf, {optTaintMode}, arg, pass, info)
  of "implicitstatic":
    processOnOffSwitch(conf, {optImplicitStatic}, arg, pass, info)
  of "patterns":
    processOnOffSwitch(conf, {optPatterns}, arg, pass, info)
  of "opt":
    expectArg(conf, switch, arg, pass, info)
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
    else: localError(conf, info, errNoneSpeedOrSizeExpectedButXFound % arg)
  of "app":
    expectArg(conf, switch, arg, pass, info)
    case arg.normalize
    of "gui":
      incl(gGlobalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "executable")
      defineSymbol(conf.symbols, "guiapp")
    of "console":
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "executable")
      defineSymbol(conf.symbols, "consoleapp")
    of "lib":
      incl(gGlobalOptions, optGenDynLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "library")
      defineSymbol(conf.symbols, "dll")
    of "staticlib":
      incl(gGlobalOptions, optGenStaticLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "library")
      defineSymbol(conf.symbols, "staticlib")
    else: localError(conf, info, errGuiConsoleOrLibExpectedButXFound % arg)
  of "passc", "t":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addCompileOptionCmd(conf, arg)
  of "passl", "l":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addLinkOptionCmd(conf, arg)
  of "cincludes":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cIncludes.add processPath(conf, arg, info)
  of "clibdir":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cLibs.add processPath(conf, arg, info)
  of "clib":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: cLinkedLibs.add processPath(conf, arg, info)
  of "header":
    if conf != nil: conf.headerFile = arg
    incl(gGlobalOptions, optGenIndex)
  of "index":
    processOnOffSwitchG(conf, {optGenIndex}, arg, pass, info)
  of "import":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: conf.implicitImports.add arg
  of "include":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: conf.implicitIncludes.add arg
  of "listcmd":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optListCmd)
  of "genmapping":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optGenMapping)
  of "os":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd1, passPP}:
      theOS = platform.nameToOS(arg)
      if theOS == osNone: localError(conf, info, "unknown OS: '$1'" % arg)
      elif theOS != platform.hostOS:
        setTarget(theOS, targetCPU)
  of "cpu":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd1, passPP}:
      cpu = platform.nameToCPU(arg)
      if cpu == cpuNone: localError(conf, info, "unknown CPU: '$1'" % arg)
      elif cpu != platform.hostCPU:
        setTarget(targetOS, cpu)
  of "run", "r":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optRun)
  of "verbosity":
    expectArg(conf, switch, arg, pass, info)
    gVerbosity = parseInt(arg)
    conf.notes = NotesVerbosity[gVerbosity]
    incl(conf.notes, conf.enableNotes)
    excl(conf.notes, conf.disableNotes)
    conf.mainPackageNotes = conf.notes
  of "parallelbuild":
    expectArg(conf, switch, arg, pass, info)
    gNumberOfProcessors = parseInt(arg)
  of "version", "v":
    expectNoArg(conf, switch, arg, pass, info)
    writeVersionInfo(pass)
  of "advanced":
    expectNoArg(conf, switch, arg, pass, info)
    writeAdvancedUsage(pass)
  of "fullhelp":
    expectNoArg(conf, switch, arg, pass, info)
    writeFullhelp(pass)
  of "help", "h":
    expectNoArg(conf, switch, arg, pass, info)
    helpOnError(pass)
  of "symbolfiles":
    case arg.normalize
    of "on": gSymbolFiles = enabledSf
    of "off": gSymbolFiles = disabledSf
    of "writeonly": gSymbolFiles = writeOnlySf
    of "readonly": gSymbolFiles = readOnlySf
    of "v2": gSymbolFiles = v2Sf
    else: localError(conf, info, "invalid option for --symbolFiles: " & arg)
  of "skipcfg":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optSkipConfigFile)
  of "skipprojcfg":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optSkipProjConfigFile)
  of "skipusercfg":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optSkipUserConfigFile)
  of "skipparentcfg":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optSkipParentConfigFiles)
  of "genscript", "gendeps":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optGenScript)
    incl(gGlobalOptions, optCompileOnly)
  of "colors": processOnOffSwitchG(conf, {optUseColors}, arg, pass, info)
  of "lib":
    expectArg(conf, switch, arg, pass, info)
    conf.libpath = processPath(conf, arg, info, notRelativeToProj=true)
  of "putenv":
    expectArg(conf, switch, arg, pass, info)
    splitSwitch(conf, arg, key, val, pass, info)
    os.putEnv(key, val)
  of "cc":
    expectArg(conf, switch, arg, pass, info)
    setCC(conf, arg, info)
  of "track":
    expectArg(conf, switch, arg, pass, info)
    track(conf, arg, info)
  of "trackdirty":
    expectArg(conf, switch, arg, pass, info)
    trackDirty(conf, arg, info)
  of "suggest":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideSug
  of "def":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideDef
  of "eval":
    expectArg(conf, switch, arg, pass, info)
    gEvalExpr = arg
  of "context":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideCon
  of "usages":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideUse
  of "stdout":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optStdout)
  of "listfullpaths":
    expectNoArg(conf, switch, arg, pass, info)
    gListFullPaths = true
  of "dynliboverride":
    dynlibOverride(conf, switch, arg, pass, info)
  of "dynliboverrideall":
    expectNoArg(conf, switch, arg, pass, info)
    gDynlibOverrideAll = true
  of "cs":
    # only supported for compatibility. Does nothing.
    expectArg(conf, switch, arg, pass, info)
  of "experimental":
    if arg.len == 0:
      conf.features.incl oldExperimentalFeatures
    else:
      try:
        conf.features.incl parseEnum[Feature](arg)
      except ValueError:
        localError(conf, info, "unknown experimental feature")
  of "nocppexceptions":
    expectNoArg(conf, switch, arg, pass, info)
    incl(gGlobalOptions, optNoCppExceptions)
    defineSymbol(conf.symbols, "noCppExceptions")
  of "cppdefine":
    expectArg(conf, switch, arg, pass, info)
    if conf != nil:
      conf.cppDefine(arg)
  of "newruntime":
    expectNoArg(conf, switch, arg, pass, info)
    doAssert(conf != nil)
    incl(conf.features, destructor)
    defineSymbol(conf.symbols, "nimNewRuntime")
  of "cppcompiletonamespace":
    expectNoArg(conf, switch, arg, pass, info)
    useNimNamespace = true
    defineSymbol(conf.symbols, "cppCompileToNamespace")
  else:
    if strutils.find(switch, '.') >= 0: options.setConfigVar(conf, switch, arg)
    else: invalidCmdLineOption(conf, pass, switch, info)

template gCmdLineInfo*(): untyped = newLineInfo(FileIndex(0), 1, 1)

proc processCommand*(switch: string, pass: TCmdLinePass; config: ConfigRef) =
  var cmd, arg: string
  splitSwitch(config, switch, cmd, arg, pass, gCmdLineInfo)
  processSwitch(cmd, arg, pass, gCmdLineInfo, config)


proc processSwitch*(pass: TCmdLinePass; p: OptParser; config: ConfigRef) =
  # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
  # we fix this here
  var bracketLe = strutils.find(p.key, '[')
  if bracketLe >= 0:
    var key = substr(p.key, 0, bracketLe - 1)
    var val = substr(p.key, bracketLe + 1) & ':' & p.val
    processSwitch(key, val, pass, gCmdLineInfo, config)
  else:
    processSwitch(p.key, p.val, pass, gCmdLineInfo, config)

proc processArgument*(pass: TCmdLinePass; p: OptParser;
                      argsCount: var int; config: ConfigRef): bool =
  if argsCount == 0:
    # nim filename.nims  is the same as "nim e filename.nims":
    if p.key.endswith(".nims"):
      config.command = "e"
      config.projectName = unixToNativePath(p.key)
      config.arguments = cmdLineRest(p)
      result = true
    elif pass != passCmd2:
      config.command = p.key
  else:
    if pass == passCmd1: config.commandArgs.add p.key
    if argsCount == 1:
      # support UNIX style filenames everywhere for portable build scripts:
      config.projectName = unixToNativePath(p.key)
      config.arguments = cmdLineRest(p)
      result = true
  inc argsCount
