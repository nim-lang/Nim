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

# We need to use a StringTableRef here as defined symbols are always guaranteed
# to be style insensitive. Otherwise hell would break lose.
var gSymbols: StringTableRef

const
  catNone = "false"

proc defineSymbol*(symbol: string) =
  gSymbols[symbol] = "true"

proc undefSymbol*(symbol: string) =
  gSymbols[symbol] = catNone

proc isDefined*(symbol: string): bool =
  if gSymbols.hasKey(symbol):
    result = gSymbols[symbol] != catNone
  elif cmpIgnoreStyle(symbol, CPU[targetCPU].name) == 0:
    result = true
  elif cmpIgnoreStyle(symbol, platform.OS[targetOS].name) == 0:
    result = true
  else:
    case symbol.normalize
    of "x86": result = targetCPU == cpuI386
    of "itanium": result = targetCPU == cpuIa64
    of "x8664": result = targetCPU == cpuAmd64
    of "posix", "unix":
      result = targetOS in {osLinux, osMorphos, osSkyos, osIrix, osPalmos,
                            osQnx, osAtari, osAix,
                            osHaiku, osVxWorks, osSolaris, osNetbsd,
                            osFreebsd, osOpenbsd, osMacosx}
    of "bsd":
      result = targetOS in {osNetbsd, osFreebsd, osOpenbsd}
    of "emulatedthreadvars":
      result = platform.OS[targetOS].props.contains(ospLacksThreadVars)
    of "msdos": result = targetOS == osDos
    of "mswindows", "win32": result = targetOS == osWindows
    of "macintosh": result = targetOS in {osMacos, osMacosx}
    of "sunos": result = targetOS == osSolaris
    of "littleendian": result = CPU[targetCPU].endian == platform.littleEndian
    of "bigendian": result = CPU[targetCPU].endian == platform.bigEndian
    of "cpu8": result = CPU[targetCPU].bit == 8
    of "cpu16": result = CPU[targetCPU].bit == 16
    of "cpu32": result = CPU[targetCPU].bit == 32
    of "cpu64": result = CPU[targetCPU].bit == 64
    of "nimrawsetjmp":
      result = targetOS in {osSolaris, osNetbsd, osFreebsd, osOpenbsd, osMacosx}
    else: discard

proc isDefined*(symbol: PIdent): bool = isDefined(symbol.s)

iterator definedSymbolNames*: string =
  for key, val in pairs(gSymbols):
    if val != catNone: yield key

proc countDefinedSymbols*(): int =
  result = 0
  for key, val in pairs(gSymbols):
    if val != catNone: inc(result)

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
