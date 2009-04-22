//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit wordrecg;

// This module contains a word recognizer, i.e. a simple
// procedure which maps special words to an enumeration.
// It is primarily needed because Pascal's case statement
// does not support strings. Without this the code would
// be slow and unreadable.

interface

{$include 'config.inc'}

uses
  nsystem, hashes, strutils, idents;

type
  TSpecialWord = (wInvalid,
    // these are mapped to Nimrod keywords:
    //[[[cog
    //from string import split, capitalize
    //keywords = split(open("data/keywords.txt").read())
    //idents = ""
    //strings = ""
    //i = 1
    //for k in keywords:
    //  idents = idents + "w" + capitalize(k) + ", "
    //  strings = strings + "'" + k + "', "
    //  if i % 4 == 0:
    //    idents = idents + "\n"
    //    strings = strings + "\n"
    //  i = i + 1
    //cog.out(idents)
    //]]]
    wAddr, wAnd, wAs, wAsm, 
    wBlock, wBreak, wCase, wCast, 
    wConst, wContinue, wConverter, wDiscard, 
    wDiv, wElif, wElse, wEnd, 
    wEnum, wExcept, wException, wFinally, 
    wFor, wFrom, wGeneric, wIf, 
    wImplies, wImport, wIn, wInclude, 
    wIs, wIsnot, wIterator, wLambda, 
    wMacro, wMethod, wMod, wNil, 
    wNot, wNotin, wObject, wOf, 
    wOr, wOut, wProc, wPtr, 
    wRaise, wRef, wReturn, wShl, 
    wShr, wTemplate, wTry, wTuple, 
    wType, wVar, wWhen, wWhere, 
    wWhile, wWith, wWithout, wXor, 
    wYield, 
    //[[[end]]]
    // other special tokens:
    wColon, wEquals, wDot, wDotDot, wHat,
    wStar, wMinus,
    // pragmas and command line options:
    wMagic, wTypeCheck, wFinal, wProfiler,
    wObjChecks, wImportc, wExportc, wAlign, wNodecl, wPure,
    wVolatile, wRegister, wNostatic, wHeader, wNosideeffect, wNoreturn,
    wMerge, wLib, wDynlib, wCompilerproc, wCppmethod, wFatal,
    wError, wWarning, wHint, wLine, wPush, wPop,
    wDefine, wUndef, wLinedir, wStacktrace, wLinetrace, wPragma,
    wLink, wCompile, wLinksys, wDeprecated, wVarargs,
    wByref, wCallconv, wBreakpoint, wDebugger, wNimcall, wStdcall,
    wCdecl, wSafecall, wSyscall, wInline, wNoInline, wFastcall, wClosure,
    wNoconv, wOn, wOff, wChecks, wRangechecks, wBoundchecks,
    wOverflowchecks, wNilchecks, wAssertions, wWarnings, wW, wHints,
    wOptimization, wSpeed, wSize, wNone, wPath, wP,
    wD, wU, wDebuginfo, wCompileonly, wNolinking, wForcebuild,
    wF, wDeadCodeElim, wSafecode, wCompileTime,
    wGc, wRefc, wBoehm, wA, wOpt, wO,
    wApp, wConsole, wGui, wPassc, wT, wPassl,
    wL, wListcmd, wGendoc, wGenmapping,
    wOs, wCpu, wGenerate, wG, wC, wCpp,
    wYaml, wRun, wR, wVerbosity, wV, wHelp,
    wH, wSymbolFiles, wFieldChecks, wX, wVersion, wAdvanced,
    wSkipcfg, wSkipProjCfg, wCc, wGenscript, wCheckPoint, wCheckPoints,
    wMaxErr, wExpr, wStmt, wTypeDesc,
    wSubsChar, wAstCache, wAcyclic, wIndex,
    // commands:
    wCompileToC, wCompileToCpp, wCompileToEcmaScript, wCompileToLLVM,
    wPretty, wDoc, wPas,
    wGenDepend, wListDef, wCheck, wParse, wScan, wBoot, wLazy,
    wRst2html, wI,
    // special for the preprocessor of configuration files:
    wWrite, wPutEnv, wPrependEnv, wAppendEnv,
    // additional Pascal keywords:
    wArray, wBegin, wClass,
    wConstructor, wDestructor, wDo, wDownto,
    wExports, wFinalization, wFunction, wGoto,
    wImplementation, wInherited, wInitialization, wInterface,
    wLabel, wLibrary, wPacked,
    wProcedure, wProgram, wProperty, wRecord, wRepeat, wResourcestring,
    wSet, wThen, wThreadvar, wTo, wUnit, wUntil,
    wUses,
    // Pascal special tokens:
    wExternal, wOverload, wFar, wAssembler, wForward, wIfdef, wIfndef,
    wEndif
  );
  TSpecialWords = set of TSpecialWord;
const
  oprLow = ord(wColon);
  oprHigh = ord(wHat);
  specialWords: array [low(TSpecialWord)..high(TSpecialWord)]
                of string = ('',
    // keywords:
    //[[[cog
    //cog.out(strings)
    //]]]
    'addr', 'and', 'as', 'asm', 
    'block', 'break', 'case', 'cast', 
    'const', 'continue', 'converter', 'discard', 
    'div', 'elif', 'else', 'end', 
    'enum', 'except', 'exception', 'finally', 
    'for', 'from', 'generic', 'if', 
    'implies', 'import', 'in', 'include', 
    'is', 'isnot', 'iterator', 'lambda', 
    'macro', 'method', 'mod', 'nil', 
    'not', 'notin', 'object', 'of', 
    'or', 'out', 'proc', 'ptr', 
    'raise', 'ref', 'return', 'shl', 
    'shr', 'template', 'try', 'tuple', 
    'type', 'var', 'when', 'where', 
    'while', 'with', 'without', 'xor', 
    'yield', 
    //[[[end]]]
    // other special tokens:
    ':'+'', '='+'', '.'+'', '..', '^'+'',
    '*'+'', '-'+'',
    // pragmas and command line options:
    'magic', 'typecheck', 'final', 'profiler',
    'objchecks', 'importc', 'exportc', 'align', 'nodecl', 'pure',
    'volatile', 'register', 'nostatic', 'header', 'nosideeffect', 'noreturn',
    'merge', 'lib', 'dynlib', 'compilerproc', 'cppmethod', 'fatal',
    'error', 'warning', 'hint', 'line', 'push', 'pop',
    'define', 'undef', 'linedir', 'stacktrace', 'linetrace', 'pragma',
    'link', 'compile', 'linksys', 'deprecated', 'varargs',
    'byref', 'callconv', 'breakpoint', 'debugger', 'nimcall', 'stdcall',
    'cdecl', 'safecall', 'syscall', 'inline', 'noinline', 'fastcall', 'closure',
    'noconv', 'on', 'off', 'checks', 'rangechecks', 'boundchecks',
    'overflowchecks', 'nilchecks', 'assertions', 'warnings', 'w'+'', 'hints',
    'optimization', 'speed', 'size', 'none', 'path', 'p'+'',
    'd'+'', 'u'+'', 'debuginfo', 'compileonly', 'nolinking', 'forcebuild',
    'f'+'', 'deadcodeelim', 'safecode', 'compiletime',
    'gc', 'refc', 'boehm', 'a'+'', 'opt', 'o'+'',
    'app', 'console', 'gui', 'passc', 't'+'', 'passl',
    'l'+'', 'listcmd', 'gendoc', 'genmapping',
    'os', 'cpu', 'generate', 'g'+'', 'c'+'', 'cpp',
    'yaml', 'run', 'r'+'', 'verbosity', 'v'+'', 'help',
    'h'+'', 'symbolfiles', 'fieldchecks', 'x'+'', 'version', 'advanced',
    'skipcfg', 'skipprojcfg', 'cc', 'genscript', 'checkpoint', 'checkpoints',
    'maxerr', 'expr', 'stmt', 'typedesc',
    'subschar', 'astcache', 'acyclic', 'index',
    // commands:
    'compiletoc', 'compiletocpp', 'compiletoecmascript', 'compiletollvm',
    'pretty', 'doc', 'pas', 'gendepend', 'listdef', 'check', 'parse',
    'scan', 'boot', 'lazy', 'rst2html', 'i'+'',

    // special for the preprocessor of configuration files:
    'write', 'putenv', 'prependenv', 'appendenv',

    'array', 'begin', 'class',
    'constructor', 'destructor', 'do', 'downto',
    'exports', 'finalization', 'function', 'goto',
    'implementation', 'inherited', 'initialization', 'interface',
    'label', 'library', 'packed',
    'procedure', 'program', 'property', 'record', 'repeat', 'resourcestring',
    'set', 'then', 'threadvar', 'to', 'unit', 'until',
    'uses',

    // Pascal special tokens
    'external', 'overload', 'far', 'assembler', 'forward', 'ifdef', 'ifndef',
    'endif'
  );

function whichKeyword(id: PIdent): TSpecialWord; overload;
function whichKeyword(const id: String): TSpecialWord; overload;

function findStr(const a: array of string; const s: string): int;

implementation

function findStr(const a: array of string; const s: string): int;
var
  i: int;
begin
  for i := low(a) to high(a) do
    if cmpIgnoreStyle(a[i], s) = 0 then begin result := i; exit end;
  result := -1;
end;

function whichKeyword(const id: String): TSpecialWord; overload;
begin
  result := whichKeyword(getIdent(id))
end;

function whichKeyword(id: PIdent): TSpecialWord; overload;
begin
  if id.id < 0 then result := wInvalid
  else result := TSpecialWord(id.id);
end;

procedure initSpecials();
var
  s: TSpecialWord;
begin
  // initialize the keywords:
  for s := succ(low(specialWords)) to high(specialWords) do
    getIdent(specialWords[s],
             getNormalizedHash(specialWords[s])).id := ord(s)
end;

initialization
  initSpecials();
end.
