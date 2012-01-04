#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains a word recognizer, i.e. a simple
# procedure which maps special words to an enumeration.
# It is primarily needed because Pascal's case statement
# does not support strings. Without this the code would
# be slow and unreadable.

import 
  hashes, strutils, idents

# Keywords must be kept sorted and within a range

type 
  TSpecialWord* = enum 
    wInvalid, 
    
    wAddr, wAnd, wAs, wAsm, wAtomic, 
    wBind, wBlock, wBreak, wCase, wCast, wConst, 
    wContinue, wConverter, wDiscard, wDistinct, wDiv, wElif, wElse, wEnd, wEnum, 
    wExcept, wExport, wFinally, wFor, wFrom, wGeneric, wIf, wImport, wIn, 
    wInclude, wIs, wIsnot, wIterator, wLambda, wLet,
    wMacro, wMethod, wMod, wNil, 
    wNot, wNotin, wObject, wOf, wOr, wOut, wProc, wPtr, wRaise, wRef, wReturn, 
    wShl, wShr, wTemplate, wTry, wTuple, wType, wVar, wWhen, wWhile, wWith, 
    wWithout, wXor, wYield,
    
    wColon, wColonColon, wEquals, wDot, wDotDot, wStar, wMinus, 
    wMagic, wThread, wFinal, wProfiler, wObjChecks,
    wImportCpp, wImportObjC,
    wImportCompilerProc,
    wImportc, wExportc, wExtern, wIncompleteStruct,
    wAlign, wNodecl, wPure, wVolatile, wRegister, wSideeffect, wHeader, 
    wNosideeffect, wNoreturn, wMerge, wLib, wDynlib, wCompilerproc, wProcVar, 
    wFatal, wError, wWarning, wHint, wLine, wPush, wPop, wDefine, wUndef, 
    wLinedir, wStacktrace, wLinetrace, wLink, wCompile, 
    wLinksys, wDeprecated, wVarargs, wByref, wCallconv, wBreakpoint, wDebugger, 
    wNimcall, wStdcall, wCdecl, wSafecall, wSyscall, wInline, wNoInline, 
    wFastcall, wClosure, wNoconv, wOn, wOff, wChecks, wRangechecks, 
    wBoundchecks, wOverflowchecks, wNilchecks,
    wFloatchecks, wNanChecks, wInfChecks,
    wAssertions, wWarnings, 
    wHints, wOptimization, wSpeed, wSize, wNone, 
    wDeadCodeElim, wSafecode, 
    wPragma,
    wCompileTime, wNoInit,
    wPassc, wPassl, wBorrow, wDiscardable,
    wFieldChecks, 
    wCheckPoint, wSubsChar, 
    wAcyclic, wShallow, wUnroll, wLinearScanEnd,
    wWrite, wPutEnv, wPrependEnv, wAppendEnv, wThreadVar, wEmit, wNoStackFrame
    
  TSpecialWords* = set[TSpecialWord]

const 
  oprLow* = ord(wColon)
  oprHigh* = ord(wDotDot)
  specialWords*: array[low(TSpecialWord)..high(TSpecialWord), string] = ["", 
    
    "addr", "and", "as", "asm", "atomic", 
    "bind", "block", "break", "case", "cast", 
    "const", "continue", "converter", "discard", "distinct", "div", "elif", 
    "else", "end", "enum", "except", "export", 
    "finally", "for", "from", "generic", "if", 
    "import", "in", "include", "is", "isnot", "iterator",
    "lambda", "let",
    "macro", "method", "mod", "nil", "not", "notin", "object", "of", "or", 
    "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "template", 
    "try", "tuple", "type", "var", "when", "while", "with", "without", "xor",
    "yield",

    ":", "::", "=", ".", "..", "*", "-",
    "magic", "thread", "final", "profiler", "objchecks", 
    
    "importcpp", "importobjc",
    "importcompilerproc", "importc", "exportc", "extern", "incompletestruct",
    "align", "nodecl", "pure", "volatile", "register", "sideeffect", 
    "header", "nosideeffect", "noreturn", "merge", "lib", "dynlib", 
    "compilerproc", "procvar", "fatal", "error", "warning", "hint", "line", 
    "push", "pop", "define", "undef", "linedir", "stacktrace", "linetrace", 
    "link", "compile", "linksys", "deprecated", "varargs", 
    "byref", "callconv", "breakpoint", "debugger", "nimcall", "stdcall", 
    "cdecl", "safecall", "syscall", "inline", "noinline", "fastcall", "closure", 
    "noconv", "on", "off", "checks", "rangechecks", "boundchecks", 
    "overflowchecks", "nilchecks",
    "floatchecks", "nanchecks", "infchecks",

    "assertions", "warnings", "hints", 
    "optimization", "speed", "size", "none", 
    "deadcodeelim", "safecode", 
    "pragma",
    "compiletime", "noinit",
    "passc", "passl", "borrow", "discardable", "fieldchecks",
    "checkpoint",
    "subschar", "acyclic", "shallow", "unroll", "linearscanend",
    "write", "putenv", "prependenv", "appendenv", "threadvar", "emit",
    "nostackframe"]

proc findStr*(a: openarray[string], s: string): int = 
  for i in countup(low(a), high(a)): 
    if cmpIgnoreStyle(a[i], s) == 0: 
      return i
  result = - 1

proc whichKeyword*(id: PIdent): TSpecialWord = 
  if id.id < 0: result = wInvalid
  else: result = TSpecialWord(id.id)

proc whichKeyword*(id: String): TSpecialWord = 
  result = whichKeyword(getIdent(id))
  
proc initSpecials() = 
  # initialize the keywords:
  for s in countup(succ(low(specialWords)), high(specialWords)): 
    getIdent(specialWords[s], hashIgnoreStyle(specialWords[s])).id = ord(s)
  
initSpecials()
