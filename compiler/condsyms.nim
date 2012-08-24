#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the conditional symbols.

import 
  ast, astalgo, msgs, hashes, platform, strutils, idents

var gSymbols*: TStrTable

proc DefineSymbol*(symbol: string) = 
  var i = getIdent(symbol)
  var sym = StrTableGet(gSymbols, i)
  if sym == nil: 
    new(sym)                  # circumvent the ID mechanism
    sym.kind = skConditional
    sym.name = i
    StrTableAdd(gSymbols, sym)
  sym.position = 1

proc UndefSymbol*(symbol: string) = 
  var sym = StrTableGet(gSymbols, getIdent(symbol))
  if sym != nil: sym.position = 0
  
proc isDefined*(symbol: PIdent): bool = 
  var sym = StrTableGet(gSymbols, symbol)
  result = sym != nil and sym.position == 1

proc isDefined*(symbol: string): bool = 
  result = isDefined(getIdent(symbol))

proc ListSymbols*() = 
  var it: TTabIter
  var s = InitTabIter(it, gSymbols)
  OutWriteln("-- List of currently defined symbols --")
  while s != nil: 
    if s.position == 1: OutWriteln(s.name.s)
    s = nextIter(it, gSymbols)
  OutWriteln("-- End of list --")

proc countDefinedSymbols*(): int = 
  var it: TTabIter
  var s = InitTabIter(it, gSymbols)
  result = 0
  while s != nil: 
    if s.position == 1: inc(result)
    s = nextIter(it, gSymbols)

proc InitDefines*() = 
  initStrTable(gSymbols)
  DefineSymbol("nimrod") # 'nimrod' is always defined
  # for bootstrapping purposes and old code:
  DefineSymbol("nimhygiene")
  DefineSymbol("niminheritable")
  
  # add platform specific symbols:
  case targetCPU
  of cpuI386: DefineSymbol("x86")
  of cpuIa64: DefineSymbol("itanium")
  of cpuAmd64: DefineSymbol("x8664")
  else: nil
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
  else: nil
  DefineSymbol("cpu" & $cpu[targetCPU].bit)
  DefineSymbol(normalize(endianToStr[cpu[targetCPU].endian]))
  DefineSymbol(cpu[targetCPU].name)
  DefineSymbol(platform.os[targetOS].name)
  if platform.OS[targetOS].props.contains(ospLacksThreadVars):
    DefineSymbol("emulatedthreadvars")


