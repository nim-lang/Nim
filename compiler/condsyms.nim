#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the conditional symbols.

import 
  strtabs, platform, strutils, idents

# We need to use a PStringTable here as defined symbols are always guaranteed
# to be style insensitive. Otherwise hell would break lose.
var gSymbols: StringTableRef

proc defineSymbol*(symbol: string) = 
  gSymbols[symbol] = "true"

proc declareSymbol*(symbol: string) = 
  gSymbols[symbol] = "unknown"

proc undefSymbol*(symbol: string) = 
  gSymbols[symbol] = "false"

proc isDefined*(symbol: string): bool = 
  if gSymbols.hasKey(symbol):
    result = gSymbols[symbol] == "true"
  
proc isDefined*(symbol: PIdent): bool = isDefined(symbol.s)
proc isDeclared*(symbol: PIdent): bool = gSymbols.hasKey(symbol.s)

iterator definedSymbolNames*: string =
  for key, val in pairs(gSymbols):
    if val == "true": yield key

proc countDefinedSymbols*(): int = 
  result = 0
  for key, val in pairs(gSymbols):
    if val == "true": inc(result)

# For ease of bootstrapping, we keep them here and not in the global config
# file for now:
const
  additionalSymbols = """
    x86 itanium x8664
    msdos mswindows win32 unix posix sunos bsd macintosh RISCOS hpux
    mac

    hppa hp9000 hp9000s300 hp9000s700 hp9000s800 hp9000s820 ELATE sparcv9

    ecmascript js nimrodvm nimffi nimdoc cpp objc
    gcc llvmgcc clang lcc bcc dmc wcc vcc tcc pcc ucc icl
    boehmgc gcmarkandsweep gcgenerational nogc gcUseBitvectors
    endb profiler
    executable guiapp consoleapp library dll staticlib

    quick
    release debug
    useWinAnsi useFork useNimRtl useMalloc useRealtimeGC ssl memProfiler
    nodejs kwin nimfix

    usesysassert usegcassert tinyC useFFI
    useStdoutAsStdmsg createNimRtl
    booting fulldebug corruption nimsuperops noSignalHandler useGnuReadline
    noCaas noDocGen noBusyWaiting nativeStackTrace useNodeIds selftest
    reportMissedDeadlines avoidTimeMachine useClone ignoreAllocationSize
    debugExecProcesses pcreDll useLipzipSrc
    preventDeadlocks UNICODE winUnicode trackGcHeaders posixRealtime

    nimStdSetjmp nimRawSetjmp nimSigSetjmp
  """.split

proc initDefines*() = 
  gSymbols = newStringTable(modeStyleInsensitive)
  defineSymbol("nimrod") # 'nimrod' is always defined
  # for bootstrapping purposes and old code:
  defineSymbol("nimhygiene")
  defineSymbol("niminheritable")
  defineSymbol("nimmixin")
  defineSymbol("nimeffects")
  defineSymbol("nimbabel")
  defineSymbol("nimcomputedgoto")
  defineSymbol("nimunion")
  defineSymbol("nimnewshared")
  defineSymbol("nimrequiresnimframe")
  defineSymbol("nimparsebiggestfloatmagic")
  defineSymbol("nimalias")
  defineSymbol("nimlocks")
  defineSymbol("nimnode")
  
  # add platform specific symbols:
  for c in low(CPU)..high(CPU):
    declareSymbol("cpu" & $CPU[c].bit)
    declareSymbol(normalize(EndianToStr[CPU[c].endian]))
    declareSymbol(CPU[c].name)
  for o in low(platform.OS)..high(platform.OS):
    declareSymbol(platform.OS[o].name)

  for a in additionalSymbols:
    declareSymbol(a)

  # -----------------------------------------------------------
  case targetCPU
  of cpuI386: defineSymbol("x86")
  of cpuIa64: defineSymbol("itanium")
  of cpuAmd64: defineSymbol("x8664")
  else: discard
  case targetOS
  of osDos: 
    defineSymbol("msdos")
  of osWindows: 
    defineSymbol("mswindows")
    defineSymbol("win32")
  of osLinux, osMorphos, osSkyos, osIrix, osPalmos, osQnx, osAtari, osAix, 
     osHaiku, osVxWorks:
    # these are all 'unix-like'
    defineSymbol("unix")
    defineSymbol("posix")
  of osSolaris: 
    defineSymbol("sunos")
    defineSymbol("unix")
    defineSymbol("posix")
  of osNetbsd, osFreebsd, osOpenbsd: 
    defineSymbol("unix")
    defineSymbol("bsd")
    defineSymbol("posix")
  of osMacos: 
    defineSymbol("macintosh")
  of osMacosx: 
    defineSymbol("macintosh")
    defineSymbol("unix")
    defineSymbol("posix")
  else: discard
  defineSymbol("cpu" & $CPU[targetCPU].bit)
  defineSymbol(normalize(EndianToStr[CPU[targetCPU].endian]))
  defineSymbol(CPU[targetCPU].name)
  defineSymbol(platform.OS[targetOS].name)
  declareSymbol("emulatedthreadvars")
  if platform.OS[targetOS].props.contains(ospLacksThreadVars):
    defineSymbol("emulatedthreadvars")
  case targetOS
  of osSolaris, osNetbsd, osFreebsd, osOpenbsd, osMacosx:
    defineSymbol("nimRawSetjmp")
  else: discard
