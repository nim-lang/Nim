#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the parsing of command line arguments.

import 
  os, msgs, options, nversion, condsyms, strutils, extccomp, platform, lists, 
  wordrecg, parseutils

proc writeCommandLineUsage*()

type 
  TCmdLinePass* = enum 
    passCmd1,                 # first pass over the command line
    passCmd2,                 # second pass over the command line
    passPP                    # preprocessor called ProcessCommand()

proc ProcessCommand*(switch: string, pass: TCmdLinePass)
proc processSwitch*(switch, arg: string, pass: TCmdlinePass, info: TLineInfo)
# implementation

const
  HelpMessage = "Nimrod Compiler Version $1 (" & compileDate & ") [$2: $3]\n" &
      "Copyright (c) 2004-2011 by Andreas Rumpf\n"

const 
  Usage = """
Usage:
  nimrod command [options] [projectfile] [arguments]
Command:
  compile, c                compile project with default code generator (C)
  doc                       generate the documentation for inputfile
  i                         start Nimrod in interactive mode (limited)
Arguments:
  arguments are passed to the program being run (if --run option is selected)
Options:
  -p, --path:PATH           add path to search paths
  -d, --define:SYMBOL       define a conditional symbol
  -u, --undef:SYMBOL        undefine a conditional symbol
  -f, --forceBuild          force rebuilding of all modules
  --stackTrace:on|off       turn stack tracing on|off
  --lineTrace:on|off        turn line tracing on|off
  --threads:on|off          turn support for multi-threading on|off
  -x, --checks:on|off       turn all runtime checks on|off
  --objChecks:on|off        turn obj conversion checks on|off
  --fieldChecks:on|off      turn case variant field checks on|off
  --rangeChecks:on|off      turn range checks on|off
  --boundChecks:on|off      turn bound checks on|off
  --overflowChecks:on|off   turn int over-/underflow checks on|off
  -a, --assertions:on|off   turn assertions on|off
  --floatChecks:on|off      turn all floating point (NaN/Inf) checks on|off
  --nanChecks:on|off        turn NaN checks on|off
  --infChecks:on|off        turn Inf checks on|off
  --deadCodeElim:on|off     whole program dead code elimination on|off
  --opt:none|speed|size     optimize not at all or for speed|size
  --app:console|gui|lib     generate a console|GUI application|dynamic library
  -r, --run                 run the compiled program with given arguments
  --advanced                show advanced command line switches
  -h, --help                show this help
"""

  AdvancedUsage = """
Advanced commands:
  compileToC, cc            compile project with C code generator
  compileToOC, oc           compile project to Objective C code
  rst2html                  convert a reStructuredText file to HTML
  rst2tex                   convert a reStructuredText file to TeX
  run                       run the project (with Tiny C backend; buggy!)
  pretty                    pretty print the inputfile
  genDepend                 generate a DOT file containing the
                            module dependency graph
  dump                      dump all defined conditionals and search paths
  check                     checks the project for syntax and semantic
  idetools                  compiler support for IDEs: possible options:
    --track:FILE,LINE,COL   track a file/cursor position
    --suggest               suggest all possible symbols at position
    --def                   list all possible symbols at position
    --context               list possible invokation context  
Advanced options:
  -o, --out:FILE            set the output filename
  --stdout                  output to stdout
  -w, --warnings:on|off     turn all warnings on|off
  --warning[X]:on|off       turn specific warning X on|off
  --hints:on|off            turn all hints on|off
  --hint[X]:on|off          turn specific hint X on|off
  --lib:PATH                set the system library path
  -c, --compileOnly         compile only; do not assemble or link
  --noLinking               compile but do not link
  --noMain                  do not generate a main procedure
  --genScript               generate a compile script (in the 'nimcache'
                            subdirectory named 'compile_$project$scriptext')
  --os:SYMBOL               set the target operating system (cross-compilation)
  --cpu:SYMBOL              set the target processor (cross-compilation)
  --debuginfo               enables debug information
  --debugger:on|off         turn Embedded Nimrod Debugger on|off
  -t, --passc:OPTION        pass an option to the C compiler
  -l, --passl:OPTION        pass an option to the linker
  --genMapping              generate a mapping file containing
                            (Nimrod, mangled) identifier pairs
  --lineDir:on|off          generation of #line directive on|off
  --checkpoints:on|off      turn checkpoints on|off; for debugging Nimrod
  --skipCfg                 do not read the general configuration file
  --skipProjCfg             do not read the project's configuration file
  --gc:refc|boehm|none      use Nimrod's native GC|Boehm GC|no GC
  --index:FILE              use FILE to generate a documentation index file
  --putenv:key=value        set an environment variable
  --listCmd                 list the commands used to execute external programs
  --parallelBuild=0|1|...   perform a parallel build
                            value = number of processors (0 for auto-detect)
  --verbosity:0|1|2|3       set Nimrod's verbosity level (0 is default)
  -v, --version             show detailed version information
"""

proc getCommandLineDesc(): string = 
  result = `%`(HelpMessage, [VersionAsString, platform.os[platform.hostOS].name, 
                             cpu[platform.hostCPU].name]) & Usage

var 
  helpWritten: bool           # BUGFIX 19
  versionWritten: bool
  advHelpWritten: bool

proc HelpOnError(pass: TCmdLinePass) = 
  if (pass == passCmd1) and not helpWritten: 
    # BUGFIX 19
    MessageOut(getCommandLineDesc())
    helpWritten = true
    quit(0)

proc writeAdvancedUsage(pass: TCmdLinePass) = 
  if (pass == passCmd1) and not advHelpWritten: 
    # BUGFIX 19
    MessageOut(`%`(HelpMessage, [VersionAsString, 
                                 platform.os[platform.hostOS].name, 
                                 cpu[platform.hostCPU].name]) & AdvancedUsage)
    advHelpWritten = true
    helpWritten = true
    quit(0)

proc writeVersionInfo(pass: TCmdLinePass) = 
  if (pass == passCmd1) and not versionWritten: 
    versionWritten = true
    helpWritten = true
    messageOut(`%`(HelpMessage, [VersionAsString, 
                                 platform.os[platform.hostOS].name, 
                                 cpu[platform.hostCPU].name]))
    quit(0)

proc writeCommandLineUsage() = 
  if not helpWritten: 
    messageOut(getCommandLineDesc())
    helpWritten = true

proc InvalidCmdLineOption(pass: TCmdLinePass, switch: string, info: TLineInfo) = 
  LocalError(info, errInvalidCmdLineOption, switch)

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
  elif switch[i] in {':', '=', '['}: arg = copy(switch, i + 1)
  else: InvalidCmdLineOption(pass, switch, info)
  
proc ProcessOnOffSwitch(op: TOptions, arg: string, pass: TCmdlinePass, 
                        info: TLineInfo) = 
  case whichKeyword(arg)
  of wOn: gOptions = gOptions + op
  of wOff: gOptions = gOptions - op
  else: LocalError(info, errOnOrOffExpectedButXFound, arg)
  
proc ProcessOnOffSwitchG(op: TGlobalOptions, arg: string, pass: TCmdlinePass, 
                         info: TLineInfo) = 
  case whichKeyword(arg)
  of wOn: gGlobalOptions = gGlobalOptions + op
  of wOff: gGlobalOptions = gGlobalOptions - op
  else: LocalError(info, errOnOrOffExpectedButXFound, arg)
  
proc ExpectArg(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) = 
  if arg == "": LocalError(info, errCmdLineArgExpected, switch)
  
proc ExpectNoArg(switch, arg: string, pass: TCmdLinePass, info: TLineInfo) = 
  if arg != "": LocalError(info, errCmdLineNoArgExpected, switch)
  
proc ProcessSpecificNote(arg: string, state: TSpecialWord, pass: TCmdlinePass, 
                         info: TLineInfo) = 
  var id = ""  # arg = "X]:on|off"
  var i = 0
  var n = hintMin
  while (i < len(arg) + 0) and (arg[i] != ']'): 
    add(id, arg[i])
    inc(i)
  if (i < len(arg) + 0) and (arg[i] == ']'): inc(i)
  else: InvalidCmdLineOption(pass, arg, info)
  if (i < len(arg) + 0) and (arg[i] in {':', '='}): inc(i)
  else: InvalidCmdLineOption(pass, arg, info)
  if state == wHint: 
    var x = findStr(msgs.HintsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(hintMin))
    else: InvalidCmdLineOption(pass, arg, info)
  else: 
    var x = findStr(msgs.WarningsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(warnMin))
    else: InvalidCmdLineOption(pass, arg, info)
  case whichKeyword(copy(arg, i))
  of wOn: incl(gNotes, n)
  of wOff: excl(gNotes, n)
  else: LocalError(info, errOnOrOffExpectedButXFound, arg)

proc processCompile(filename: string) = 
  var found = findFile(filename)
  if found == "": found = filename
  var trunc = changeFileExt(found, "")
  extccomp.addExternalFileToCompile(found)
  extccomp.addFileToLink(completeCFilePath(trunc, false))

proc testCompileOptionArg*(switch, arg: string, info: TLineInfo): bool = 
  case whichKeyword(switch)
  of wGC: 
    case whichKeyword(arg)
    of wBoehm: result = contains(gGlobalOptions, optBoehmGC)
    of wRefc:  result = contains(gGlobalOptions, optRefcGC)
    of wNone:  result = gGlobalOptions * {optBoehmGC, optRefcGC} == {}
    else: LocalError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of wOpt: 
    case whichKeyword(arg)
    of wSpeed: result = contains(gOptions, optOptimizeSpeed)
    of wSize: result = contains(gOptions, optOptimizeSize)
    of wNone: result = gOptions * {optOptimizeSpeed, optOptimizeSize} == {}
    else: LocalError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  else: InvalidCmdLineOption(passCmd1, switch, info)

proc testCompileOption*(switch: string, info: TLineInfo): bool = 
  case whichKeyword(switch)
  of wDebuginfo: result = contains(gGlobalOptions, optCDebug)
  of wCompileOnly, wC: result = contains(gGlobalOptions, optCompileOnly)
  of wNoLinking: result = contains(gGlobalOptions, optNoLinking)
  of wNoMain: result = contains(gGlobalOptions, optNoMain)
  of wForceBuild, wF: result = contains(gGlobalOptions, optForceFullMake)
  of wWarnings, wW: result = contains(gOptions, optWarns)
  of wHints: result = contains(gOptions, optHints)
  of wCheckpoints: result = contains(gOptions, optCheckpoints)
  of wStackTrace: result = contains(gOptions, optStackTrace)
  of wLineTrace: result = contains(gOptions, optLineTrace)
  of wDebugger: result = contains(gOptions, optEndb)
  of wProfiler: result = contains(gOptions, optProfiler)
  of wChecks, wX: result = gOptions * checksOptions == checksOptions
  of wFloatChecks:
    result = gOptions * {optNanCheck, optInfCheck} == {optNanCheck, optInfCheck}
  of wInfChecks: result = contains(gOptions, optInfCheck)
  of wNanChecks: result = contains(gOptions, optNanCheck)
  of wObjChecks: result = contains(gOptions, optObjCheck)
  of wFieldChecks: result = contains(gOptions, optFieldCheck)
  of wRangeChecks: result = contains(gOptions, optRangeCheck)
  of wBoundChecks: result = contains(gOptions, optBoundsCheck)
  of wOverflowChecks: result = contains(gOptions, optOverflowCheck)
  of wLineDir: result = contains(gOptions, optLineDir)
  of wAssertions, wA: result = contains(gOptions, optAssert)
  of wDeadCodeElim: result = contains(gGlobalOptions, optDeadCodeElim)
  of wRun, wR: result = contains(gGlobalOptions, optRun)
  of wSymbolFiles: result = contains(gGlobalOptions, optSymbolFiles)
  of wGenScript: result = contains(gGlobalOptions, optGenScript)
  of wThreads: result = contains(gGlobalOptions, optThreads)
  else: InvalidCmdLineOption(passCmd1, switch, info)
  
proc processPath(path: string): string = 
  result = UnixToNativePath(path % ["nimrod", getPrefixDir(), "lib", libpath,
    "home", removeTrailingDirSep(os.getHomeDir())])

proc addPath(path: string, info: TLineInfo) = 
  if not contains(options.searchPaths, path): 
    lists.PrependStr(options.searchPaths, path)

proc addPathRec(dir: string, info: TLineInfo) =
  var pos = dir.len-1
  if dir[pos] in {DirSep, AltSep}: inc(pos)
  for k,p in os.walkDir(dir):
    if k == pcDir and p[pos] != '.':
      addPathRec(p, info)
      if not contains(options.searchPaths, p): 
        Message(info, hintPath, p)
        lists.PrependStr(options.searchPaths, p)

proc track(arg: string, info: TLineInfo) = 
  var a = arg.split(',')
  if a.len != 3: LocalError(info, errTokenExpected, "FILE,LINE,COLMUN")
  var line, column: int
  if parseUtils.parseInt(a[1], line) <= 0:
    LocalError(info, errInvalidNumber, a[1])
  if parseUtils.parseInt(a[2], column) <= 0:
    LocalError(info, errInvalidNumber, a[2])
  msgs.addCheckpoint(newLineInfo(a[0], line, column))

proc processSwitch(switch, arg: string, pass: TCmdlinePass, info: TLineInfo) = 
  var 
    theOS: TSystemOS
    cpu: TSystemCPU
    key, val: string
  case whichKeyword(switch)
  of wPath, wP: 
    expectArg(switch, arg, pass, info)
    addPath(processPath(arg), info)
  of wRecursivePath:
    expectArg(switch, arg, pass, info)
    var path = processPath(arg)
    addPathRec(path, info)
    addPath(path, info)
  of wOut, wO: 
    expectArg(switch, arg, pass, info)
    options.outFile = arg
  of wDefine, wD: 
    expectArg(switch, arg, pass, info)
    DefineSymbol(arg)
  of wUndef, wU: 
    expectArg(switch, arg, pass, info)
    UndefSymbol(arg)
  of wCompile: 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: processCompile(arg)
  of wLink: 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: addFileToLink(arg)
  of wDebuginfo: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optCDebug)
  of wCompileOnly, wC: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optCompileOnly)
  of wNoLinking: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optNoLinking)
  of wNoMain: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optNoMain)
  of wForceBuild, wF: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optForceFullMake)
  of wGC: 
    expectArg(switch, arg, pass, info)
    case whichKeyword(arg)
    of wBoehm: 
      incl(gGlobalOptions, optBoehmGC)
      excl(gGlobalOptions, optRefcGC)
      DefineSymbol("boehmgc")
    of wRefc: 
      excl(gGlobalOptions, optBoehmGC)
      incl(gGlobalOptions, optRefcGC)
    of wNone: 
      excl(gGlobalOptions, optRefcGC)
      excl(gGlobalOptions, optBoehmGC)
      defineSymbol("nogc")
    else: LocalError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of wWarnings, wW: ProcessOnOffSwitch({optWarns}, arg, pass, info)
  of wWarning: ProcessSpecificNote(arg, wWarning, pass, info)
  of wHint: ProcessSpecificNote(arg, wHint, pass, info)
  of wHints: ProcessOnOffSwitch({optHints}, arg, pass, info)
  of wCheckpoints: ProcessOnOffSwitch({optCheckpoints}, arg, pass, info)
  of wStackTrace: ProcessOnOffSwitch({optStackTrace}, arg, pass, info)
  of wLineTrace: ProcessOnOffSwitch({optLineTrace}, arg, pass, info)
  of wDebugger: 
    ProcessOnOffSwitch({optEndb}, arg, pass, info)
    if optEndb in gOptions: DefineSymbol("endb")
    else: UndefSymbol("endb")
  of wProfiler: 
    ProcessOnOffSwitch({optProfiler}, arg, pass, info)
    if optProfiler in gOptions: DefineSymbol("profiler")
    else: UndefSymbol("profiler")
  of wChecks, wX: ProcessOnOffSwitch(checksOptions, arg, pass, info)
  of wFloatChecks:
    ProcessOnOffSwitch({optNanCheck, optInfCheck}, arg, pass, info)
  of wInfChecks: ProcessOnOffSwitch({optInfCheck}, arg, pass, info)
  of wNanChecks: ProcessOnOffSwitch({optNanCheck}, arg, pass, info)
  of wObjChecks: ProcessOnOffSwitch({optObjCheck}, arg, pass, info)
  of wFieldChecks: ProcessOnOffSwitch({optFieldCheck}, arg, pass, info)
  of wRangeChecks: ProcessOnOffSwitch({optRangeCheck}, arg, pass, info)
  of wBoundChecks: ProcessOnOffSwitch({optBoundsCheck}, arg, pass, info)
  of wOverflowChecks: ProcessOnOffSwitch({optOverflowCheck}, arg, pass, info)
  of wLineDir: ProcessOnOffSwitch({optLineDir}, arg, pass, info)
  of wAssertions, wA: ProcessOnOffSwitch({optAssert}, arg, pass, info)
  of wDeadCodeElim: ProcessOnOffSwitchG({optDeadCodeElim}, arg, pass, info)
  of wThreads: ProcessOnOffSwitchG({optThreads}, arg, pass, info)
  of wOpt: 
    expectArg(switch, arg, pass, info)
    case whichKeyword(arg)
    of wSpeed: 
      incl(gOptions, optOptimizeSpeed)
      excl(gOptions, optOptimizeSize)
    of wSize: 
      excl(gOptions, optOptimizeSpeed)
      incl(gOptions, optOptimizeSize)
    of wNone: 
      excl(gOptions, optOptimizeSpeed)
      excl(gOptions, optOptimizeSize)
    else: LocalError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  of wApp: 
    expectArg(switch, arg, pass, info)
    case whichKeyword(arg)
    of wGui: 
      incl(gGlobalOptions, optGenGuiApp)
      defineSymbol("guiapp")
    of wConsole: 
      excl(gGlobalOptions, optGenGuiApp)
    of wLib: 
      incl(gGlobalOptions, optGenDynLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol("library")
    else: LocalError(info, errGuiConsoleOrLibExpectedButXFound, arg)
  of wPassC, wT: 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addCompileOption(arg)
  of wPassL, wL: 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addLinkOption(arg)
  of wIndex: 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: gIndexFile = arg
  of wImport: 
    expectArg(switch, arg, pass, info)
    options.addImplicitMod(arg)
  of wListCmd: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optListCmd)
  of wGenMapping: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenMapping)
  of wOS: 
    expectArg(switch, arg, pass, info)
    if (pass == passCmd1): 
      theOS = platform.NameToOS(arg)
      if theOS == osNone: LocalError(info, errUnknownOS, arg)
      elif theOS != platform.hostOS: 
        setTarget(theOS, targetCPU)
        incl(gGlobalOptions, optCompileOnly)
        condsyms.InitDefines()
  of wCPU: 
    expectArg(switch, arg, pass, info)
    if (pass == passCmd1): 
      cpu = platform.NameToCPU(arg)
      if cpu == cpuNone: LocalError(info, errUnknownCPU, arg)
      elif cpu != platform.hostCPU: 
        setTarget(targetOS, cpu)
        incl(gGlobalOptions, optCompileOnly)
        condsyms.InitDefines()
  of wRun, wR: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optRun)
  of wVerbosity: 
    expectArg(switch, arg, pass, info)
    gVerbosity = parseInt(arg)
  of wParallelBuild: 
    expectArg(switch, arg, pass, info)
    gNumberOfProcessors = parseInt(arg)
  of wVersion, wV: 
    expectNoArg(switch, arg, pass, info)
    writeVersionInfo(pass)
  of wAdvanced: 
    expectNoArg(switch, arg, pass, info)
    writeAdvancedUsage(pass)
  of wHelp, wH: 
    expectNoArg(switch, arg, pass, info)
    helpOnError(pass)
  of wSymbolFiles: 
    ProcessOnOffSwitchG({optSymbolFiles}, arg, pass, info)
  of wSkipCfg: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipConfigFile)
  of wSkipProjCfg: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipProjConfigFile)
  of wGenScript: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenScript)
  of wLib: 
    expectArg(switch, arg, pass, info)
    libpath = processPath(arg)
  of wPutEnv: 
    expectArg(switch, arg, pass, info)
    splitSwitch(arg, key, val, pass, info)
    os.putEnv(key, val)
  of wCC: 
    expectArg(switch, arg, pass, info)
    setCC(arg)
  of wTrack:
    expectArg(switch, arg, pass, info)
    track(arg, info)
  of wSuggest: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSuggest)
  of wDef:
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optDef)
  of wContext:
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optContext)
  of wStdout: 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optStdout)
  else: 
    if strutils.find(switch, '.') >= 0: options.setConfigVar(switch, arg)
    else: InvalidCmdLineOption(pass, switch, info)
  
proc ProcessCommand(switch: string, pass: TCmdLinePass) = 
  var 
    cmd, arg: string
    info: TLineInfo
  info = newLineInfo("command line", 1, 1)
  splitSwitch(switch, cmd, arg, pass, info)
  ProcessSwitch(cmd, arg, pass, info)
