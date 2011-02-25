#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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
  nhashes, strutils, idents

# Keywords must be kept sorted and within a range

type 
  TSpecialWord* = enum 
    wInvalid, 
    
    wAddr, wAnd, wAs, wAsm, wAtomic, 
    wBind, wBlock, wBreak, wCase, wCast, wConst, 
    wContinue, wConverter, wDiscard, wDistinct, wDiv, wElif, wElse, wEnd, wEnum, 
    wExcept, wFinally, wFor, wFrom, wGeneric, wIf, wImplies, wImport, wIn, 
    wInclude, wIs, wIsnot, wIterator, wLambda, wLet,
    wMacro, wMethod, wMod, wNil, 
    wNot, wNotin, wObject, wOf, wOr, wOut, wProc, wPtr, wRaise, wRef, wReturn, 
    wShl, wShr, wTemplate, wTry, wTuple, wType, wVar, wWhen, wWhile, wWith, 
    wWithout, wXor, wYield,
    
    wColon, wEquals, wDot, wDotDot, wHat, wStar, wMinus, 
    wMagic, wTypeCheck, wFinal, wProfiler, wObjChecks, wImportc, wExportc, 
    wExtern,
    wAlign, wNodecl, wPure, wVolatile, wRegister, wSideeffect, wHeader, 
    wNosideeffect, wNoreturn, wMerge, wLib, wDynlib, wCompilerproc, wProcVar, 
    wFatal, wError, wWarning, wHint, wLine, wPush, wPop, wDefine, wUndef, 
    wLinedir, wStacktrace, wLinetrace, wParallelBuild, wLink, wCompile, 
    wLinksys, wDeprecated, wVarargs, wByref, wCallconv, wBreakpoint, wDebugger, 
    wNimcall, wStdcall, wCdecl, wSafecall, wSyscall, wInline, wNoInline, 
    wFastcall, wClosure, wNoconv, wOn, wOff, wChecks, wRangechecks, 
    wBoundchecks, wOverflowchecks, wNilchecks,
    wFloatchecks, wNanChecks, wInfChecks,
    wAssertions, wWarnings, wW, 
    wHints, wOptimization, wSpeed, wSize, wNone, wPath, wP, wD, wU, wDebuginfo, 
    wCompileonly, wNolinking, wForcebuild, wF, wDeadCodeElim, wSafecode, 
    wPragma,
    wCompileTime, wGc, wRefc, wBoehm, wA, wOpt, wO, wApp, wConsole, wGui, 
    wPassc, wT, wPassl, wL, wListcmd, wGendoc, wGenmapping, wOs, wCpu, 
    wGenerate, wG, wC, wCpp, wBorrow, wRun, wR, wVerbosity, wV, wHelp, wH, 
    wSymbolFiles, wFieldChecks, wX, wVersion, wAdvanced, wSkipcfg, wSkipProjCfg, 
    wCc, wGenscript, wCheckPoint, wCheckPoints, wNoMain, wSubsChar, 
    wAcyclic, wIndex, 
    wCompileToC, wCompileToCpp, wCompileToEcmaScript, wCompileToLLVM, 
    wCompileToOC,
    wPretty, 
    wDoc, wGenDepend, wDump, wCheck, wParse, wScan, wJs, wOC, 
    wRst2html, wRst2tex, wI,
    wWrite, wPutEnv, wPrependEnv, wAppendEnv, wThreadVar, wEmit, wThreads,
    wRecursivePath, 
    wStdout,
    wIdeTools, wSuggest, wTrack, wDef, wContext
    
  TSpecialWords* = set[TSpecialWord]

const 
  oprLow* = ord(wColon)
  oprHigh* = ord(wHat)
  specialWords*: array[low(TSpecialWord)..high(TSpecialWord), string] = ["", 
    
    "addr", "and", "as", "asm", "atomic", 
    "bind", "block", "break", "case", "cast", 
    "const", "continue", "converter", "discard", "distinct", "div", "elif", 
    "else", "end", "enum", "except", "finally", "for", "from", "generic", "if", 
    "implies", "import", "in", "include", "is", "isnot", "iterator",
    "lambda", "let",
    "macro", "method", "mod", "nil", "not", "notin", "object", "of", "or", 
    "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "template", 
    "try", "tuple", "type", "var", "when", "while", "with", "without", "xor",
    "yield",

    ":", "=", ".", "..", "^", "*", "-",
    "magic", "typecheck", "final", "profiler", "objchecks", "importc", 
    "exportc", "extern",
    "align", "nodecl", "pure", "volatile", "register", "sideeffect", 
    "header", "nosideeffect", "noreturn", "merge", "lib", "dynlib", 
    "compilerproc", "procvar", "fatal", "error", "warning", "hint", "line", 
    "push", "pop", "define", "undef", "linedir", "stacktrace", "linetrace", 
    "parallelbuild", "link", "compile", "linksys", "deprecated", "varargs", 
    "byref", "callconv", "breakpoint", "debugger", "nimcall", "stdcall", 
    "cdecl", "safecall", "syscall", "inline", "noinline", "fastcall", "closure", 
    "noconv", "on", "off", "checks", "rangechecks", "boundchecks", 
    "overflowchecks", "nilchecks",
    "floatchecks", "nanchecks", "infchecks",

    "assertions", "warnings", "w", "hints", 
    "optimization", "speed", "size", "none", "path", "p", "d", "u", "debuginfo", 
    "compileonly", "nolinking", "forcebuild", "f", "deadcodeelim", "safecode", 
    "pragma",
    "compiletime", "gc", "refc", "boehm", "a", "opt", "o", "app", "console", 
    "gui", "passc", "t", "passl", "l", "listcmd", "gendoc", "genmapping", "os", 
    "cpu", "generate", "g", "c", "cpp", "borrow", "run", "r", "verbosity", "v", 
    "help", "h", "symbolfiles", "fieldchecks", "x", "version", "advanced", 
    "skipcfg", "skipprojcfg", "cc", "genscript", "checkpoint", "checkpoints", 
    "nomain", "subschar", "acyclic", "index", 
    "compiletoc", "compiletocpp", "compiletoecmascript", "compiletollvm", 
    "compiletooc",
    "pretty", "doc", "gendepend", "dump", "check", "parse", "scan", 
    "js", "oc", "rst2html", "rst2tex", "i", 
    "write", "putenv", "prependenv", "appendenv", "threadvar", "emit",
    "threads", "recursivepath", 
    "stdout",
    "idetools", "suggest", "track", "def", "context"]

proc whichKeyword*(id: PIdent): TSpecialWord
proc whichKeyword*(id: String): TSpecialWord
proc findStr*(a: openarray[string], s: string): int
# implementation

proc findStr(a: openarray[string], s: string): int = 
  for i in countup(low(a), high(a)): 
    if cmpIgnoreStyle(a[i], s) == 0: 
      return i
  result = - 1

proc whichKeyword(id: String): TSpecialWord = 
  result = whichKeyword(getIdent(id))

proc whichKeyword(id: PIdent): TSpecialWord = 
  if id.id < 0: result = wInvalid
  else: result = TSpecialWord(id.id)
  
proc initSpecials() = 
  # initialize the keywords:
  for s in countup(succ(low(specialWords)), high(specialWords)): 
    getIdent(specialWords[s], getNormalizedHash(specialWords[s])).id = ord(s)
  
initSpecials()
