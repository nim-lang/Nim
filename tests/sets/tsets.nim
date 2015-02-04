discard """
  file: "tsets.nim"
  output: "Ha ein F ist in s!"
"""
# Test the handling of sets

import
  strutils

proc testSets(s: var set[char]) =
  s = {'A', 'B', 'C', 'E'..'G'} + {'Z'} + s

# test sets if the first element is different from 0:
type
  TAZ = range['a'..'z']
  TAZset = set[TAZ]

  TTokType* = enum 
    tkInvalid, tkEof,
    tkSymbol,
    tkAddr, tkAnd, tkAs, tkAsm, tkBlock, tkBreak, tkCase, tkCast, tkConst, 
    tkContinue, tkConverter, tkDiscard, tkDiv, tkElif, tkElse, tkEnd, tkEnum, 
    tkExcept, tkException, tkFinally, tkFor, tkFrom, tkGeneric, tkIf, tkImplies, 
    tkImport, tkIn, tkInclude, tkIs, tkIsnot, tkIterator, tkLambda, tkMacro, 
    tkMethod, tkMod, tkNil, tkNot, tkNotin, tkObject, tkOf, tkOr, tkOut, tkProc, 
    tkPtr, tkRaise, tkRecord, tkRef, tkReturn, tkShl, tkShr, tkTemplate, tkTry, 
    tkType, tkVar, tkWhen, tkWhere, tkWhile, tkWith, tkWithout, tkXor, tkYield,
    tkIntLit, tkInt8Lit, tkInt16Lit, tkInt32Lit, tkInt64Lit, tkFloatLit, 
    tkFloat32Lit, tkFloat64Lit, tkStrLit, tkRStrLit, tkTripleStrLit, tkCharLit, 
    tkRCharLit, tkParLe, tkParRi, tkBracketLe, tkBracketRi, tkCurlyLe, 
    tkCurlyRi, tkBracketDotLe, tkBracketDotRi, 
    tkCurlyDotLe, tkCurlyDotRi, 
    tkParDotLe, tkParDotRi,
    tkComma, tkSemiColon, tkColon, tkEquals, tkDot, tkDotDot, tkHat, tkOpr, 
    tkComment, tkAccent, tkInd, tkSad, tkDed,
    tkSpaces, tkInfixOpr, tkPrefixOpr, tkPostfixOpr
  TTokTypeRange = range[tkSymbol..tkDed]
  TTokTypes* = set[TTokTypeRange]

const
  toktypes: TTokTypes = {TTokTypeRange(tkSymbol)..pred(tkIntLit), 
                         tkStrLit..tkTripleStrLit}

var
  s: set[char]
  a: TAZset
s = {'0'..'9'}
testSets(s)
if 'F' in s: write(stdout, "Ha ein F ist in s!\n")
else: write(stdout, "BUG: F ist nicht in s!\n")
a = {} #{'a'..'z'}
for x in low(TAZ) .. high(TAZ):
  incl(a, x)
  if x in a: discard
  else: write(stdout, "BUG: something not in a!\n")

for x in low(TTokTypeRange) .. high(TTokTypeRange):
  if x in tokTypes:
    discard
    #writeln(stdout, "the token '$1' is in the set" % repr(x))

#OUT Ha ein F ist in s!


