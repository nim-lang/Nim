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
  wordrecg, parseutils, nimblecmd, idents, parseopt, sequtils, lineinfos,
  pathutils

# but some have deps to imported modules. Yay.
bootSwitch(usedTinyC, hasTinyCBackend, "-d:tinyc")
bootSwitch(usedNativeStacktrace,
  defined(nativeStackTrace) and nativeStackTraceSupported,
  "-d:nativeStackTrace")
bootSwitch(usedFFI, hasFFI, "-d:nimHasLibFFI")

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

proc getCommandLineDesc(conf: ConfigRef): string =
  result = (HelpMessage % [VersionAsString, platform.OS[conf.target.hostOS].name,
                           CPU[conf.target.hostCPU].name, CompileDate]) &
                           Usage

proc helpOnError(conf: ConfigRef; pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(conf, getCommandLineDesc(conf), {msgStdout})
    msgQuit(0)

proc writeAdvancedUsage(conf: ConfigRef; pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(conf, (HelpMessage % [VersionAsString,
                                 platform.OS[conf.target.hostOS].name,
                                 CPU[conf.target.hostCPU].name, CompileDate]) &
                                 AdvancedUsage,
               {msgStdout})
    msgQuit(0)

proc writeFullhelp(conf: ConfigRef; pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(conf, `%`(HelpMessage, [VersionAsString,
                                 platform.OS[conf.target.hostOS].name,
                                 CPU[conf.target.hostCPU].name, CompileDate]) &
                                 Usage & AdvancedUsage,
               {msgStdout})
    msgQuit(0)

proc writeVersionInfo(conf: ConfigRef; pass: TCmdLinePass) =
  if pass == passCmd1:
    msgWriteln(conf, `%`(HelpMessage, [VersionAsString,
                                 platform.OS[conf.target.hostOS].name,
                                 CPU[conf.target.hostCPU].name, CompileDate]),
               {msgStdout})

    const gitHash = gorge("git log -n 1 --format=%H").strip
    when gitHash.len == 40:
      msgWriteln(conf, "git hash: " & gitHash, {msgStdout})

    msgWriteln(conf, "active boot switches:" & usedRelease &
      usedTinyC & usedGnuReadline & usedNativeStacktrace &
      usedFFI & usedBoehm & usedMarkAndSweep & usedGenerational & usedGoGC & usedNoGC,
               {msgStdout})
    msgQuit(0)

proc writeCommandLineUsage*(conf: ConfigRef) =
  msgWriteln(conf, getCommandLineDesc(conf), {msgStdout})

proc addPrefix(switch: string): string =
  if len(switch) == 1: result = "-" & switch
  else: result = "--" & switch

const
  errInvalidCmdLineOption = "invalid command line option: '$1'"
  errOnOrOffExpectedButXFound = "'on' or 'off' expected, but '$1' found"
  errOnOffOrListExpectedButXFound = "'on', 'off' or 'list' expected, but '$1' found"
  errOffHintsError = "'off', 'hint' or 'error' expected, but '$1' found"

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
  # cmd:arg => (cmd,arg)
  elif switch[i] in {':', '='}: arg = substr(switch, i + 1)
  # cmd[sub]:rest => (cmd,[sub]:rest)
  elif switch[i] == '[': arg = substr(switch, i)
  else: invalidCmdLineOption(conf, pass, switch, info)

proc processOnOffSwitch(conf: ConfigRef; op: TOptions, arg: string, pass: TCmdLinePass,
                        info: TLineInfo) =
  case arg.normalize
  of "","on": conf.options = conf.options + op
  of "off": conf.options = conf.options - op
  else: localError(conf, info, errOnOrOffExpectedButXFound % arg)

proc processOnOffSwitchOrList(conf: ConfigRef; op: TOptions, arg: string, pass: TCmdLinePass,
                              info: TLineInfo): bool =
  result = false
  case arg.normalize
  of "on": conf.options = conf.options + op
  of "off": conf.options = conf.options - op
  of "list": result = true
  else: localError(conf, info, errOnOffOrListExpectedButXFound % arg)

proc processOnOffSwitchG(conf: ConfigRef; op: TGlobalOptions, arg: string, pass: TCmdLinePass,
                         info: TLineInfo) =
  case arg.normalize
  of "", "on": conf.globalOptions = conf.globalOptions + op
  of "off": conf.globalOptions = conf.globalOptions - op
  else: localError(conf, info, errOnOrOffExpectedButXFound % arg)

proc expectArg(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if arg == "":
    localError(conf, info, "argument for command line option expected: '$1'" % addPrefix(switch))

proc expectNoArg(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if arg != "":
    localError(conf, info, "invalid argument for command line option: '$1'" % addPrefix(switch))

proc processSpecificNote*(arg: string, state: TSpecialWord, pass: TCmdLinePass,
                         info: TLineInfo; orig: string; conf: ConfigRef) =
  var id = ""  # arg = key:val or [key]:val;  with val=on|off
  var i = 0
  var n = hintMin
  var isBracket = false
  if i < len(arg) and arg[i] == '[':
    isBracket = true
    inc(i)
  while i < len(arg) and (arg[i] notin {':', '=', ']'}):
    add(id, arg[i])
    inc(i)
  if isBracket:
    if i < len(arg) and arg[i] == ']': inc(i)
    else: invalidCmdLineOption(conf, pass, orig, info)

  if i < len(arg) and (arg[i] in {':', '='}): inc(i)
  else: invalidCmdLineOption(conf, pass, orig, info)
  if state == wHint:
    let x = findStr(lineinfos.HintsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(hintMin))
    else: localError(conf, info, "unknown hint: " & id)
  else:
    let x = findStr(lineinfos.WarningsToStr, id)
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
  if found.isEmpty: found = AbsoluteFile filename
  extccomp.addExternalFileToCompile(conf, found)

const
  errNoneBoehmRefcExpectedButXFound = "'none', 'boehm' or 'refc' expected, but '$1' found"
  errNoneSpeedOrSizeExpectedButXFound = "'none', 'speed' or 'size' expected, but '$1' found"
  errGuiConsoleOrLibExpectedButXFound = "'gui', 'console' or 'lib' expected, but '$1' found"

proc testCompileOptionArg*(conf: ConfigRef; switch, arg: string, info: TLineInfo): bool =
  case switch.normalize
  of "gc":
    case arg.normalize
    of "boehm":        result = conf.selectedGC == gcBoehm
    of "refc":         result = conf.selectedGC == gcRefc
    of "v2":           result = false
    of "markandsweep": result = conf.selectedGC == gcMarkAndSweep
    of "generational": result = false
    of "destructors":  result = conf.selectedGC == gcDestructors
    of "go":           result = conf.selectedGC == gcGo
    of "none":         result = conf.selectedGC == gcNone
    of "stack", "regions": result = conf.selectedGC == gcRegions
    else: localError(conf, info, errNoneBoehmRefcExpectedButXFound % arg)
  of "opt":
    case arg.normalize
    of "speed": result = contains(conf.options, optOptimizeSpeed)
    of "size": result = contains(conf.options, optOptimizeSize)
    of "none": result = conf.options * {optOptimizeSpeed, optOptimizeSize} == {}
    else: localError(conf, info, errNoneSpeedOrSizeExpectedButXFound % arg)
  of "verbosity": result = $conf.verbosity == arg
  of "app":
    case arg.normalize
    of "gui":       result = contains(conf.globalOptions, optGenGuiApp)
    of "console":   result = not contains(conf.globalOptions, optGenGuiApp)
    of "lib":       result = contains(conf.globalOptions, optGenDynLib) and
                      not contains(conf.globalOptions, optGenGuiApp)
    of "staticlib": result = contains(conf.globalOptions, optGenStaticLib) and
                      not contains(conf.globalOptions, optGenGuiApp)
    else: localError(conf, info, errGuiConsoleOrLibExpectedButXFound % arg)
  of "dynliboverride":
    result = isDynlibOverride(conf, arg)
  else: invalidCmdLineOption(conf, passCmd1, switch, info)

proc testCompileOption*(conf: ConfigRef; switch: string, info: TLineInfo): bool =
  case switch.normalize
  of "debuginfo": result = contains(conf.globalOptions, optCDebug)
  of "compileonly", "c": result = contains(conf.globalOptions, optCompileOnly)
  of "nolinking": result = contains(conf.globalOptions, optNoLinking)
  of "nomain": result = contains(conf.globalOptions, optNoMain)
  of "forcebuild", "f": result = contains(conf.globalOptions, optForceFullMake)
  of "warnings", "w": result = contains(conf.options, optWarns)
  of "hints": result = contains(conf.options, optHints)
  of "threadanalysis": result = contains(conf.globalOptions, optThreadAnalysis)
  of "stacktrace": result = contains(conf.options, optStackTrace)
  of "linetrace": result = contains(conf.options, optLineTrace)
  of "debugger": result = contains(conf.options, optEndb)
  of "profiler": result = contains(conf.options, optProfiler)
  of "memtracker": result = contains(conf.options, optMemTracker)
  of "checks", "x": result = conf.options * ChecksOptions == ChecksOptions
  of "floatchecks":
    result = conf.options * {optNaNCheck, optInfCheck} == {optNaNCheck, optInfCheck}
  of "infchecks": result = contains(conf.options, optInfCheck)
  of "nanchecks": result = contains(conf.options, optNaNCheck)
  of "nilchecks": result = contains(conf.options, optNilCheck)
  of "objchecks": result = contains(conf.options, optObjCheck)
  of "fieldchecks": result = contains(conf.options, optFieldCheck)
  of "rangechecks": result = contains(conf.options, optRangeCheck)
  of "boundchecks": result = contains(conf.options, optBoundsCheck)
  of "overflowchecks": result = contains(conf.options, optOverflowCheck)
  of "movechecks": result = contains(conf.options, optMoveCheck)
  of "linedir": result = contains(conf.options, optLineDir)
  of "assertions", "a": result = contains(conf.options, optAssert)
  of "run", "r": result = contains(conf.globalOptions, optRun)
  of "symbolfiles": result = conf.symbolFiles != disabledSf
  of "genscript": result = contains(conf.globalOptions, optGenScript)
  of "threads": result = contains(conf.globalOptions, optThreads)
  of "taintmode": result = contains(conf.globalOptions, optTaintMode)
  of "tlsemulation": result = contains(conf.globalOptions, optTlsEmulation)
  of "implicitstatic": result = contains(conf.options, optImplicitStatic)
  of "patterns", "trmacros": result = contains(conf.options, optTrMacros)
  of "excessivestacktrace": result = contains(conf.globalOptions, optExcessiveStackTrace)
  of "nilseqs": result = contains(conf.options, optNilSeqs)
  of "oldast": result = contains(conf.options, optOldAst)
  else: invalidCmdLineOption(conf, passCmd1, switch, info)

proc processPath(conf: ConfigRef; path: string, info: TLineInfo,
                 notRelativeToProj = false): AbsoluteDir =
  let p = if os.isAbsolute(path) or '$' in path:
            path
          elif notRelativeToProj:
            getCurrentDir() / path
          else:
            conf.projectPath.string / path
  try:
    result = AbsoluteDir pathSubs(conf, p, toFullPath(conf, info).splitFile().dir)
  except ValueError:
    localError(conf, info, "invalid path: " & p)
    result = AbsoluteDir p

proc processCfgPath(conf: ConfigRef; path: string, info: TLineInfo): AbsoluteDir =
  let path = if path.len > 0 and path[0] == '"': strutils.unescape(path)
             else: path
  let basedir = toFullPath(conf, info).splitFile().dir
  let p = if os.isAbsolute(path) or '$' in path:
            path
          else:
            basedir / path
  try:
    result = AbsoluteDir pathSubs(conf, p, basedir)
  except ValueError:
    localError(conf, info, "invalid path: " & p)
    result = AbsoluteDir p

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

  let dirtyOriginalIdx = fileInfoIdx(conf, AbsoluteFile a[1])
  if dirtyOriginalIdx.int32 >= 0:
    msgs.setDirtyFile(conf, dirtyOriginalIdx, AbsoluteFile a[0])

  conf.m.trackPos = newLineInfo(dirtyOriginalIdx, line, column)

proc track(conf: ConfigRef; arg: string, info: TLineInfo) =
  var a = arg.split(',')
  if a.len != 3: localError(conf, info, "FILE,LINE,COLUMN expected")
  var line, column: int
  if parseUtils.parseInt(a[1], line) <= 0:
    localError(conf, info, errInvalidNumber % a[1])
  if parseUtils.parseInt(a[2], column) <= 0:
    localError(conf, info, errInvalidNumber % a[2])
  conf.m.trackPos = newLineInfo(conf, AbsoluteFile a[0], line, column)

proc dynlibOverride(conf: ConfigRef; switch, arg: string, pass: TCmdLinePass, info: TLineInfo) =
  if pass in {passCmd2, passPP}:
    expectArg(conf, switch, arg, pass, info)
    options.inclDynlibOverride(conf, arg)

proc processSwitch*(switch, arg: string, pass: TCmdLinePass, info: TLineInfo;
                    conf: ConfigRef) =
  var
    key, val: string
  case switch.normalize
  of "path", "p":
    expectArg(conf, switch, arg, pass, info)
    addPath(conf, if pass == passPP: processCfgPath(conf, arg, info)
                  else: processPath(conf, arg, info), info)
  of "nimblepath", "babelpath":
    # keep the old name for compat
    if pass in {passCmd2, passPP} and optNoNimblePath notin conf.globalOptions:
      expectArg(conf, switch, arg, pass, info)
      var path = processPath(conf, arg, info, notRelativeToProj=true)
      let nimbleDir = AbsoluteDir getEnv("NIMBLE_DIR")
      if not nimbleDir.isEmpty and pass == passPP:
        path = nimbleDir / RelativeDir"pkgs"
      nimblePath(conf, path, info)
  of "nonimblepath", "nobabelpath":
    expectNoArg(conf, switch, arg, pass, info)
    disableNimblePath(conf)
  of "excludepath":
    expectArg(conf, switch, arg, pass, info)
    let path = processPath(conf, arg, info)
    conf.searchPaths.keepItIf(it != path)
    conf.lazyPaths.keepItIf(it != path)
  of "nimcache":
    expectArg(conf, switch, arg, pass, info)
    conf.nimcacheDir = processPath(conf, arg, info, true)
  of "out", "o":
    expectArg(conf, switch, arg, pass, info)
    let f = splitFile(arg.expandTilde)
    conf.outFile = RelativeFile f.name & f.ext
    conf.outDir = toAbsoluteDir f.dir
  of "outdir":
    expectArg(conf, switch, arg, pass, info)
    conf.outDir = toAbsoluteDir arg.expandTilde
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
    if pass in {passCmd2, passPP}:
      addExternalFileToLink(conf, AbsoluteFile arg)
  of "debuginfo":
    processOnOffSwitchG(conf, {optCDebug}, arg, pass, info)
  of "embedsrc":
    processOnOffSwitchG(conf, {optEmbedOrigSrc}, arg, pass, info)
  of "compileonly", "c":
    processOnOffSwitchG(conf, {optCompileOnly}, arg, pass, info)
  of "nolinking":
    processOnOffSwitchG(conf, {optNoLinking}, arg, pass, info)
  of "nomain":
    processOnOffSwitchG(conf, {optNoMain}, arg, pass, info)
  of "forcebuild", "f":
    processOnOffSwitchG(conf, {optForceFullMake}, arg, pass, info)
  of "project":
    processOnOffSwitchG(conf, {optWholeProject}, arg, pass, info)
  of "gc":
    expectArg(conf, switch, arg, pass, info)
    case arg.normalize
    of "boehm":
      conf.selectedGC = gcBoehm
      defineSymbol(conf.symbols, "boehmgc")
    of "refc":
      conf.selectedGC = gcRefc
    of "v2":
      message(conf, info, warnDeprecated, "--gc:v2 is deprecated; using default gc")
    of "markandsweep":
      conf.selectedGC = gcMarkAndSweep
      defineSymbol(conf.symbols, "gcmarkandsweep")
    of "destructors":
      conf.selectedGC = gcDestructors
      defineSymbol(conf.symbols, "gcdestructors")
    of "go":
      conf.selectedGC = gcGo
      defineSymbol(conf.symbols, "gogc")
    of "none":
      conf.selectedGC = gcNone
      defineSymbol(conf.symbols, "nogc")
    of "stack", "regions":
      conf.selectedGC= gcRegions
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
      conf.options.incl optEndb
      defineSymbol(conf.symbols, "endb")
    of "off":
      conf.options.excl optEndb
      undefSymbol(conf.symbols, "endb")
    of "native", "gdb":
      incl(conf.globalOptions, optCDebug)
      conf.options = conf.options + {optLineDir} - {optEndb}
      #defineSymbol(conf.symbols, "nimTypeNames") # type names are used in gdb pretty printing
      undefSymbol(conf.symbols, "endb")
    else:
      localError(conf, info, "expected endb|gdb but found " & arg)
  of "g": # alias for --debugger:native
    incl(conf.globalOptions, optCDebug)
    conf.options = conf.options + {optLineDir} - {optEndb}
    #defineSymbol(conf.symbols, "nimTypeNames") # type names are used in gdb pretty printing
    undefSymbol(conf.symbols, "endb")
  of "profiler":
    processOnOffSwitch(conf, {optProfiler}, arg, pass, info)
    if optProfiler in conf.options: defineSymbol(conf.symbols, "profiler")
    else: undefSymbol(conf.symbols, "profiler")
  of "memtracker":
    processOnOffSwitch(conf, {optMemTracker}, arg, pass, info)
    if optMemTracker in conf.options: defineSymbol(conf.symbols, "memtracker")
    else: undefSymbol(conf.symbols, "memtracker")
  of "hotcodereloading":
    processOnOffSwitchG(conf, {optHotCodeReloading}, arg, pass, info)
    if conf.hcrOn:
      defineSymbol(conf.symbols, "hotcodereloading")
      defineSymbol(conf.symbols, "useNimRtl")
      # hardcoded linking with dynamic runtime for MSVC for smaller binaries
      # should do the same for all compilers (wherever applicable)
      if isVSCompatible(conf):
        extccomp.addCompileOptionCmd(conf, "/MD")
    else:
      undefSymbol(conf.symbols, "hotcodereloading")
      undefSymbol(conf.symbols, "useNimRtl")
  of "oldnewlines":
    case arg.normalize
    of "","on":
      conf.oldNewlines = true
      defineSymbol(conf.symbols, "nimOldNewlines")
    of "off":
      conf.oldNewlines = false
      undefSymbol(conf.symbols, "nimOldNewlines")
    else:
      localError(conf, info, errOnOrOffExpectedButXFound % arg)
  of "laxstrings": processOnOffSwitch(conf, {optLaxStrings}, arg, pass, info)
  of "nilseqs": processOnOffSwitch(conf, {optNilSeqs}, arg, pass, info)
  of "oldast": processOnOffSwitch(conf, {optOldAst}, arg, pass, info)
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
    #if optThreads in conf.globalOptions: incl(conf.notes, warnGcUnsafe)
  of "tlsemulation": processOnOffSwitchG(conf, {optTlsEmulation}, arg, pass, info)
  of "taintmode": processOnOffSwitchG(conf, {optTaintMode}, arg, pass, info)
  of "implicitstatic":
    processOnOffSwitch(conf, {optImplicitStatic}, arg, pass, info)
  of "patterns", "trmacros":
    processOnOffSwitch(conf, {optTrMacros}, arg, pass, info)
  of "opt":
    expectArg(conf, switch, arg, pass, info)
    case arg.normalize
    of "speed":
      incl(conf.options, optOptimizeSpeed)
      excl(conf.options, optOptimizeSize)
    of "size":
      excl(conf.options, optOptimizeSpeed)
      incl(conf.options, optOptimizeSize)
    of "none":
      excl(conf.options, optOptimizeSpeed)
      excl(conf.options, optOptimizeSize)
    else: localError(conf, info, errNoneSpeedOrSizeExpectedButXFound % arg)
  of "app":
    expectArg(conf, switch, arg, pass, info)
    case arg.normalize
    of "gui":
      incl(conf.globalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "executable")
      defineSymbol(conf.symbols, "guiapp")
    of "console":
      excl(conf.globalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "executable")
      defineSymbol(conf.symbols, "consoleapp")
    of "lib":
      incl(conf.globalOptions, optGenDynLib)
      excl(conf.globalOptions, optGenGuiApp)
      defineSymbol(conf.symbols, "library")
      defineSymbol(conf.symbols, "dll")
    of "staticlib":
      incl(conf.globalOptions, optGenStaticLib)
      excl(conf.globalOptions, optGenGuiApp)
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
    if pass in {passCmd2, passPP}: conf.cIncludes.add processPath(conf, arg, info)
  of "clibdir":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}: conf.cLibs.add processPath(conf, arg, info)
  of "clib":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}:
      conf.cLinkedLibs.add processPath(conf, arg, info).string
  of "header":
    if conf != nil: conf.headerFile = arg
    incl(conf.globalOptions, optGenIndex)
  of "index":
    processOnOffSwitchG(conf, {optGenIndex}, arg, pass, info)
  of "import":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}:
      conf.implicitImports.add findModule(conf, arg, toFullPath(conf, info)).string
  of "include":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd2, passPP}:
      conf.implicitIncludes.add findModule(conf, arg, toFullPath(conf, info)).string
  of "listcmd":
    processOnOffSwitchG(conf, {optListCmd}, arg, pass, info)
  of "genmapping":
    processOnOffSwitchG(conf, {optGenMapping}, arg, pass, info)
  of "os":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd1, passPP}:
      let theOS = platform.nameToOS(arg)
      if theOS == osNone: localError(conf, info, "unknown OS: '$1'" % arg)
      elif theOS != conf.target.hostOS:
        setTarget(conf.target, theOS, conf.target.targetCPU)
  of "cpu":
    expectArg(conf, switch, arg, pass, info)
    if pass in {passCmd1, passPP}:
      let cpu = platform.nameToCPU(arg)
      if cpu == cpuNone: localError(conf, info, "unknown CPU: '$1'" % arg)
      elif cpu != conf.target.hostCPU:
        setTarget(conf.target, conf.target.targetOS, cpu)
  of "run", "r":
    processOnOffSwitchG(conf, {optRun}, arg, pass, info)
  of "errormax":
    expectArg(conf, switch, arg, pass, info)
    # Note: `nim check` (etc) can overwrite this.
    # `0` is meaningless, give it a useful meaning as in clang's -ferror-limit
    # If user doesn't set this flag and the code doesn't either, it'd
    # have the same effect as errorMax = 1
    let ret = parseInt(arg)
    conf.errorMax = if ret == 0: high(int) else: ret
  of "verbosity":
    expectArg(conf, switch, arg, pass, info)
    let verbosity = parseInt(arg)
    if verbosity notin {0..3}:
      localError(conf, info, "invalid verbosity level: '$1'" % arg)
    conf.verbosity = verbosity
    conf.notes = NotesVerbosity[conf.verbosity]
    incl(conf.notes, conf.enableNotes)
    excl(conf.notes, conf.disableNotes)
    conf.mainPackageNotes = conf.notes
  of "parallelbuild":
    expectArg(conf, switch, arg, pass, info)
    conf.numberOfProcessors = parseInt(arg)
  of "version", "v":
    expectNoArg(conf, switch, arg, pass, info)
    writeVersionInfo(conf, pass)
  of "advanced":
    expectNoArg(conf, switch, arg, pass, info)
    writeAdvancedUsage(conf, pass)
  of "fullhelp":
    expectNoArg(conf, switch, arg, pass, info)
    writeFullhelp(conf, pass)
  of "help", "h":
    expectNoArg(conf, switch, arg, pass, info)
    helpOnError(conf, pass)
  of "symbolfiles": discard "ignore for backwards compat"
  of "incremental":
    when not defined(nimIncremental):
      localError(conf, info, "the compiler was not built with " &
        "incremental compilation features; bootstrap with " &
        "-d:nimIncremental to enable")
    case arg.normalize
    of "on": conf.symbolFiles = v2Sf
    of "off": conf.symbolFiles = disabledSf
    of "writeonly": conf.symbolFiles = writeOnlySf
    of "readonly": conf.symbolFiles = readOnlySf
    of "v2": conf.symbolFiles = v2Sf
    else: localError(conf, info, "invalid option for --incremental: " & arg)
  of "skipcfg":
    processOnOffSwitchG(conf, {optSkipSystemConfigFile}, arg, pass, info)
  of "skipprojcfg":
    processOnOffSwitchG(conf, {optSkipProjConfigFile}, arg, pass, info)
  of "skipusercfg":
    processOnOffSwitchG(conf, {optSkipUserConfigFile}, arg, pass, info)
  of "skipparentcfg":
    processOnOffSwitchG(conf, {optSkipParentConfigFiles}, arg, pass, info)
  of "genscript", "gendeps":
    processOnOffSwitchG(conf, {optGenScript}, arg, pass, info)
    processOnOffSwitchG(conf, {optCompileOnly}, arg, pass, info)
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
    conf.evalExpr = arg
  of "context":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideCon
  of "usages":
    expectNoArg(conf, switch, arg, pass, info)
    conf.ideCmd = ideUse
  of "stdout":
    processOnOffSwitchG(conf, {optStdout}, arg, pass, info)
  of "listfullpaths":
    processOnOffSwitchG(conf, {optListFullPaths}, arg, pass, info)
  of "dynliboverride":
    dynlibOverride(conf, switch, arg, pass, info)
  of "dynliboverrideall":
    processOnOffSwitchG(conf, {optDynlibOverrideAll}, arg, pass, info)
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
    incl(conf.globalOptions, optNoCppExceptions)
    defineSymbol(conf.symbols, "noCppExceptions")
  of "cppdefine":
    expectArg(conf, switch, arg, pass, info)
    if conf != nil:
      conf.cppDefine(arg)
  of "newruntime":
    expectNoArg(conf, switch, arg, pass, info)
    doAssert(conf != nil)
    incl(conf.features, destructor)
    incl(conf.globalOptions, optNimV2)
    defineSymbol(conf.symbols, "nimV2")
    conf.selectedGC = gcDestructors
    defineSymbol(conf.symbols, "gcdestructors")
  of "stylecheck":
    case arg.normalize
    of "off": conf.globalOptions = conf.globalOptions - {optStyleHint, optStyleError}
    of "hint": conf.globalOptions = conf.globalOptions + {optStyleHint}
    of "error": conf.globalOptions = conf.globalOptions + {optStyleError}
    else: localError(conf, info, errOffHintsError % arg)
  of "showallmismatches":
    processOnOffSwitchG(conf, {optShowAllMismatches}, arg, pass, info)
  of "cppcompiletonamespace":
    if arg.len > 0:
      conf.cppCustomNamespace = arg
    else:
      conf.cppCustomNamespace = "Nim"
    defineSymbol(conf.symbols, "cppCompileToNamespace", conf.cppCustomNamespace)
  of "docinternal":
    processOnOffSwitchG(conf, {optDocInternal}, arg, pass, info)
  of "multimethods":
    processOnOffSwitchG(conf, {optMultiMethods}, arg, pass, info)
  else:
    if strutils.find(switch, '.') >= 0: options.setConfigVar(conf, switch, arg)
    else: invalidCmdLineOption(conf, pass, switch, info)

template gCmdLineInfo*(): untyped = newLineInfo(config, AbsoluteFile"command line", 1, 1)

proc processCommand*(switch: string, pass: TCmdLinePass; config: ConfigRef) =
  var cmd, arg: string
  splitSwitch(config, switch, cmd, arg, pass, gCmdLineInfo)
  processSwitch(cmd, arg, pass, gCmdLineInfo, config)


proc processSwitch*(pass: TCmdLinePass; p: OptParser; config: ConfigRef) =
  # hint[X]:off is parsed as (p.key = "hint[X]", p.val = "off")
  # we transform it to (key = hint, val = [X]:off)
  var bracketLe = strutils.find(p.key, '[')
  if bracketLe >= 0:
    var key = substr(p.key, 0, bracketLe - 1)
    var val = substr(p.key, bracketLe) & ':' & p.val
    processSwitch(key, val, pass, gCmdLineInfo, config)
  else:
    processSwitch(p.key, p.val, pass, gCmdLineInfo, config)

proc processArgument*(pass: TCmdLinePass; p: OptParser;
                      argsCount: var int; config: ConfigRef): bool =
  if argsCount == 0:
    # nim filename.nims  is the same as "nim e filename.nims":
    if p.key.endswith(".nims"):
      config.command = "e"
      incl(config.globalOptions, optWasNimscript)
      config.projectName = unixToNativePath(p.key)
      config.arguments = cmdLineRest(p)
      result = true
    elif pass != passCmd2:
      config.command = p.key
  else:
    if pass == passCmd1: config.commandArgs.add p.key
    if argsCount == 1:
      # support UNIX style filenames everywhere for portable build scripts:
      if config.projectName.len == 0:
        config.projectName = unixToNativePath(p.key)
      config.arguments = cmdLineRest(p)
      result = true
  inc argsCount
