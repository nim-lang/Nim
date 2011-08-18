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
  compileToCpp, cpp         compile project to C++ code
  compileToOC, objc         compile project to Objective C code
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
  --nimcache:PATH           set the path used for generated files
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
  --threadanalysis:on|off   turn thread analysis on|off
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
    MsgWriteln(getCommandLineDesc())
    helpWritten = true
    quit(0)

proc writeAdvancedUsage(pass: TCmdLinePass) = 
  if (pass == passCmd1) and not advHelpWritten: 
    # BUGFIX 19
    MsgWriteln(`%`(HelpMessage, [VersionAsString, 
                                 platform.os[platform.hostOS].name, 
                                 cpu[platform.hostCPU].name]) & AdvancedUsage)
    advHelpWritten = true
    helpWritten = true
    quit(0)

proc writeVersionInfo(pass: TCmdLinePass) = 
  if (pass == passCmd1) and not versionWritten: 
    versionWritten = true
    helpWritten = true
    MsgWriteln(`%`(HelpMessage, [VersionAsString, 
                                 platform.os[platform.hostOS].name, 
                                 cpu[platform.hostCPU].name]))
    quit(0)

proc writeCommandLineUsage() = 
  if not helpWritten: 
    MsgWriteln(getCommandLineDesc())
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
  elif switch[i] in {':', '=', '['}: arg = substr(switch, i + 1)
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
  while i < len(arg) and (arg[i] != ']'): 
    add(id, arg[i])
    inc(i)
  if i < len(arg) and (arg[i] == ']'): inc(i)
  else: InvalidCmdLineOption(pass, arg, info)
  if i < len(arg) and (arg[i] in {':', '='}): inc(i)
  else: InvalidCmdLineOption(pass, arg, info)
  if state == wHint: 
    var x = findStr(msgs.HintsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(hintMin))
    else: InvalidCmdLineOption(pass, arg, info)
  else: 
    var x = findStr(msgs.WarningsToStr, id)
    if x >= 0: n = TNoteKind(x + ord(warnMin))
    else: InvalidCmdLineOption(pass, arg, info)
  case whichKeyword(substr(arg, i))
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
  case switch.normalize
  of "gc": 
    case arg.normalize
    of "boehm": result = contains(gGlobalOptions, optBoehmGC)
    of "refc":  result = contains(gGlobalOptions, optRefcGC)
    of "none":  result = gGlobalOptions * {optBoehmGC, optRefcGC} == {}
    else: LocalError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of "opt": 
    case arg.normalize
    of "speed": result = contains(gOptions, optOptimizeSpeed)
    of "size": result = contains(gOptions, optOptimizeSize)
    of "none": result = gOptions * {optOptimizeSpeed, optOptimizeSize} == {}
    else: LocalError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  else: InvalidCmdLineOption(passCmd1, switch, info)

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
  of "checks", "x": result = gOptions * checksOptions == checksOptions
  of "floatchecks":
    result = gOptions * {optNanCheck, optInfCheck} == {optNanCheck, optInfCheck}
  of "infchecks": result = contains(gOptions, optInfCheck)
  of "nanchecks": result = contains(gOptions, optNanCheck)
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
  else: InvalidCmdLineOption(passCmd1, switch, info)
  
proc processPath(path: string): string = 
  result = UnixToNativePath(path % ["nimrod", getPrefixDir(), "lib", libpath,
    "home", removeTrailingDirSep(os.getHomeDir()),
    "projectname", options.projectName,
    "projectpath", options.projectPath])

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
  case switch.normalize
  of "path", "p": 
    expectArg(switch, arg, pass, info)
    addPath(processPath(arg), info)
  of "recursivepath":
    expectArg(switch, arg, pass, info)
    var path = processPath(arg)
    addPathRec(path, info)
    addPath(path, info)
  of "nimcache":
    expectArg(switch, arg, pass, info)
    options.nimcacheDir = processPath(arg)
  of "out", "o": 
    expectArg(switch, arg, pass, info)
    options.outFile = arg
  of "define", "d": 
    expectArg(switch, arg, pass, info)
    DefineSymbol(arg)
  of "undef", "u": 
    expectArg(switch, arg, pass, info)
    UndefSymbol(arg)
  of "compile": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: processCompile(arg)
  of "link": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: addFileToLink(arg)
  of "debuginfo": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optCDebug)
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
  of "gc": 
    expectArg(switch, arg, pass, info)
    case arg.normalize
    of "boehm": 
      incl(gGlobalOptions, optBoehmGC)
      excl(gGlobalOptions, optRefcGC)
      DefineSymbol("boehmgc")
    of "refc": 
      excl(gGlobalOptions, optBoehmGC)
      incl(gGlobalOptions, optRefcGC)
    of "none": 
      excl(gGlobalOptions, optRefcGC)
      excl(gGlobalOptions, optBoehmGC)
      defineSymbol("nogc")
    else: LocalError(info, errNoneBoehmRefcExpectedButXFound, arg)
  of "warnings", "w": ProcessOnOffSwitch({optWarns}, arg, pass, info)
  of "warning": ProcessSpecificNote(arg, wWarning, pass, info)
  of "hint": ProcessSpecificNote(arg, wHint, pass, info)
  of "hints": ProcessOnOffSwitch({optHints}, arg, pass, info)
  of "threadanalysis": ProcessOnOffSwitchG({optThreadAnalysis}, arg, pass, info)
  of "stacktrace": ProcessOnOffSwitch({optStackTrace}, arg, pass, info)
  of "linetrace": ProcessOnOffSwitch({optLineTrace}, arg, pass, info)
  of "debugger": 
    ProcessOnOffSwitch({optEndb}, arg, pass, info)
    if optEndb in gOptions: DefineSymbol("endb")
    else: UndefSymbol("endb")
  of "profiler": 
    ProcessOnOffSwitch({optProfiler}, arg, pass, info)
    if optProfiler in gOptions: DefineSymbol("profiler")
    else: UndefSymbol("profiler")
  of "checks", "x": ProcessOnOffSwitch(checksOptions, arg, pass, info)
  of "floatchecks":
    ProcessOnOffSwitch({optNanCheck, optInfCheck}, arg, pass, info)
  of "infchecks": ProcessOnOffSwitch({optInfCheck}, arg, pass, info)
  of "nanchecks": ProcessOnOffSwitch({optNanCheck}, arg, pass, info)
  of "objchecks": ProcessOnOffSwitch({optObjCheck}, arg, pass, info)
  of "fieldchecks": ProcessOnOffSwitch({optFieldCheck}, arg, pass, info)
  of "rangechecks": ProcessOnOffSwitch({optRangeCheck}, arg, pass, info)
  of "boundchecks": ProcessOnOffSwitch({optBoundsCheck}, arg, pass, info)
  of "overflowchecks": ProcessOnOffSwitch({optOverflowCheck}, arg, pass, info)
  of "linedir": ProcessOnOffSwitch({optLineDir}, arg, pass, info)
  of "assertions", "a": ProcessOnOffSwitch({optAssert}, arg, pass, info)
  of "deadcodeelim": ProcessOnOffSwitchG({optDeadCodeElim}, arg, pass, info)
  of "threads": ProcessOnOffSwitchG({optThreads}, arg, pass, info)
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
    else: LocalError(info, errNoneSpeedOrSizeExpectedButXFound, arg)
  of "app": 
    expectArg(switch, arg, pass, info)
    case arg.normalize
    of "gui": 
      incl(gGlobalOptions, optGenGuiApp)
      defineSymbol("guiapp")
    of "console": 
      excl(gGlobalOptions, optGenGuiApp)
    of "lib": 
      incl(gGlobalOptions, optGenDynLib)
      excl(gGlobalOptions, optGenGuiApp)
      defineSymbol("library")
    else: LocalError(info, errGuiConsoleOrLibExpectedButXFound, arg)
  of "passc", "t": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addCompileOption(arg)
  of "passl", "l": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: extccomp.addLinkOption(arg)
  of "index": 
    expectArg(switch, arg, pass, info)
    if pass in {passCmd2, passPP}: gIndexFile = arg
  of "import": 
    expectArg(switch, arg, pass, info)
    options.addImplicitMod(arg)
  of "listcmd": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optListCmd)
  of "genmapping": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenMapping)
  of "os": 
    expectArg(switch, arg, pass, info)
    if (pass == passCmd1): 
      theOS = platform.NameToOS(arg)
      if theOS == osNone: LocalError(info, errUnknownOS, arg)
      elif theOS != platform.hostOS: 
        setTarget(theOS, targetCPU)
        incl(gGlobalOptions, optCompileOnly)
        condsyms.InitDefines()
  of "cpu": 
    expectArg(switch, arg, pass, info)
    if (pass == passCmd1): 
      cpu = platform.NameToCPU(arg)
      if cpu == cpuNone: LocalError(info, errUnknownCPU, arg)
      elif cpu != platform.hostCPU: 
        setTarget(targetOS, cpu)
        incl(gGlobalOptions, optCompileOnly)
        condsyms.InitDefines()
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
    ProcessOnOffSwitchG({optSymbolFiles}, arg, pass, info)
  of "skipcfg": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipConfigFile)
  of "skipprojcfg": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSkipProjConfigFile)
  of "genscript": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optGenScript)
  of "lib": 
    expectArg(switch, arg, pass, info)
    libpath = processPath(arg)
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
  of "suggest": 
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optSuggest)
  of "def":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optDef)
  of "context":
    expectNoArg(switch, arg, pass, info)
    incl(gGlobalOptions, optContext)
  of "stdout": 
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
