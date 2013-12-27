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

proc defineSymbol*(symbol: string) = 
  gSymbols[symbol] = "true"

proc undefSymbol*(symbol: string) = 
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
  
  # add platform specific symbols:
  case targetCPU
  of cpuI386: defineSymbol("x86")
  of cpuIa64: defineSymbol("itanium")
  of cpuAmd64: defineSymbol("x8664")
  else: discard
  case targetOS
  of osDOS: 
    defineSymbol("msdos")
  of osWindows: 
    defineSymbol("mswindows")
    defineSymbol("win32")
  of osLinux, osMorphOS, osSkyOS, osIrix, osPalmOS, osQNX, osAtari, osAix, 
     osHaiku:
    # these are all 'unix-like'
    defineSymbol("unix")
    defineSymbol("posix")
  of osSolaris: 
    defineSymbol("sunos")
    defineSymbol("unix")
    defineSymbol("posix")
  of osNetBSD, osFreeBSD, osOpenBSD: 
    defineSymbol("unix")
    defineSymbol("bsd")
    defineSymbol("posix")
  of osMacOS: 
    defineSymbol("macintosh")
  of osMacOSX: 
    defineSymbol("macintosh")
    defineSymbol("unix")
    defineSymbol("posix")
  else: discard
  defineSymbol("cpu" & $CPU[targetCPU].bit)
  defineSymbol(normalize(EndianToStr[CPU[targetCPU].endian]))
  defineSymbol(CPU[targetCPU].name)
  defineSymbol(platform.os[targetOS].name)
  if platform.OS[targetOS].props.contains(ospLacksThreadVars):
    defineSymbol("emulatedthreadvars")
