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

from options import Feature
from lineinfos import HintsToStr, WarningsToStr

const
  catNone = "false"

proc defineSymbol*(symbols: StringTableRef; symbol: string, value: string = "true") =
  symbols[symbol] = value

proc undefSymbol*(symbols: StringTableRef; symbol: string) =
  symbols[symbol] = catNone

#proc lookupSymbol*(symbols: StringTableRef; symbol: string): string =
#  result = if isDefined(symbol): gSymbols[symbol] else: nil

iterator definedSymbolNames*(symbols: StringTableRef): string =
  for key, val in pairs(symbols):
    if val != catNone: yield key

proc countDefinedSymbols*(symbols: StringTableRef): int =
  result = 0
  for key, val in pairs(symbols):
    if val != catNone: inc(result)

proc initDefines*(symbols: StringTableRef) =
  # for bootstrapping purposes and old code:
  template defineSymbol(s) = symbols.defineSymbol(s)
  defineSymbol("nimhygiene")
  defineSymbol("niminheritable")
  defineSymbol("nimmixin")
  defineSymbol("nimeffects")
  defineSymbol("nimbabel")
  defineSymbol("nimcomputedgoto")
  defineSymbol("nimunion")
  defineSymbol("nimnewshared")
  defineSymbol("nimNewTypedesc")
  defineSymbol("nimrequiresnimframe")
  defineSymbol("nimparsebiggestfloatmagic")
  defineSymbol("nimalias")
  defineSymbol("nimlocks")
  defineSymbol("nimnode")
  defineSymbol("nimnomagic64")
  defineSymbol("nimvarargstyped")
  defineSymbol("nimtypedescfixed")
  defineSymbol("nimKnowsNimvm")
  defineSymbol("nimArrIdx")
  defineSymbol("nimHasalignOf")
  defineSymbol("nimImmediateDeprecated")
  defineSymbol("nimNewShiftOps")
  defineSymbol("nimDistros")
  defineSymbol("nimHasCppDefine")
  defineSymbol("nimGenericInOutFlags")
  when false: defineSymbol("nimHasOpt")
  defineSymbol("nimNoArrayToCstringConversion")
  defineSymbol("nimNewRoof")
  defineSymbol("nimHasRunnableExamples")
  defineSymbol("nimNewDot")
  defineSymbol("nimHasNilChecks")
  defineSymbol("nimSymKind")
  defineSymbol("nimVmEqIdent")
  defineSymbol("nimNoNil")
  defineSymbol("nimNoZeroTerminator")
  defineSymbol("nimNotNil")
  defineSymbol("nimVmExportFixed")
  defineSymbol("nimHasSymOwnerInMacro")
  defineSymbol("nimNewRuntime")
  defineSymbol("nimIncrSeqV3")
  defineSymbol("nimAshr")
  defineSymbol("nimNoNilSeqs")
  defineSymbol("nimNoNilSeqs2")
  defineSymbol("nimHasUserErrors")
  defineSymbol("nimUncheckedArrayTyp")
  defineSymbol("nimHasTypeof")

  defineSymbol("nimHasNilSeqs")
  for f in low(Feature)..high(Feature):
    defineSymbol("nimHas" & $f)

  for s in WarningsToStr:
    defineSymbol("nimHasWarning" & s)
  for s in HintsToStr:
    defineSymbol("nimHasHint" & s)
