#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the conditional symbols.

import
  strtabs, platform, strutils, idents

# We need to use a PStringTable here as defined symbols are always guaranteed
# to be style insensitive. Otherwise hell would break lose.
var gSymbols: PStringTable

proc DefineSymbol*(symbol: string) =
  gSymbols[symbol] = "true"

proc UndefSymbol*(symbol: string) =
  gSymbols[symbol] = "false"

proc isDefined*(symbol: string): bool =
  if gSymbols.hasKey(symbol):
    result = gSymbols[symbol] == "true"

proc isDefined*(symbol: PIdent): bool = isDefined(symbol.s)

iterator definedSymbolNames*: string =
  for key, val in pairs(gSymbols):
    if val == "true": yield key

proc countDefinedSymbols*(): int =
  result = 0
  for key, val in pairs(gSymbols):
    if val == "true": inc(result)

proc InitDefines*() =
  gSymbols = newStringTable(modeStyleInsensitive)
  DefineSymbol("nimrod") # 'nimrod' is always defined
  # for bootstrapping purposes and old code:
  DefineSymbol("nimhygiene")
  DefineSymbol("niminheritable")
  DefineSymbol("nimmixin")
  DefineSymbol("nimeffects")
  DefineSymbol("nimbabel")
  DefineSymbol("nimcomputedgoto")

  # add platform specific symbols:
  case targetCPU
  of cpuI386: DefineSymbol("x86")
  of cpuIa64: DefineSymbol("itanium")
  of cpuAmd64: DefineSymbol("x8664")
  else: discard
  case targetOS
  of osDOS:
    DefineSymbol("msdos")
  of osWindows:
    DefineSymbol("mswindows")
    DefineSymbol("win32")
  of osLinux, osMorphOS, osSkyOS, osIrix, osPalmOS, osQNX, osAtari, osAix,
     osHaiku:
    # these are all 'unix-like'
    DefineSymbol("unix")
    DefineSymbol("posix")
  of osSolaris:
    DefineSymbol("sunos")
    DefineSymbol("unix")
    DefineSymbol("posix")
  of osNetBSD, osFreeBSD, osOpenBSD:
    DefineSymbol("unix")
    DefineSymbol("bsd")
    DefineSymbol("posix")
  of osMacOS:
    DefineSymbol("macintosh")
  of osMacOSX:
    DefineSymbol("macintosh")
    DefineSymbol("unix")
    DefineSymbol("posix")
  else: discard
  DefineSymbol("cpu" & $cpu[targetCPU].bit)
  DefineSymbol(normalize(endianToStr[cpu[targetCPU].endian]))
  DefineSymbol(cpu[targetCPU].name)
  DefineSymbol(platform.os[targetOS].name)
  if platform.OS[targetOS].props.contains(ospLacksThreadVars):
    DefineSymbol("emulatedthreadvars")
