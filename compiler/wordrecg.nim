#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains a word recognizer, i.e. a simple
# procedure which maps special words to an enumeration.
# It is primarily needed because Pascal's case statement
# does not support strings. Without this the code would
# be slow and unreadable.

from strutils import cmpIgnoreStyle

# Keywords must be kept sorted and within a range


  specialWords*: array[TSpecialWord, string] = ["",
    
    "immediate", "constructor", "destructor", "delegator", "override",
    "importcpp", "importobjc",
    "importCompilerProc", "importc", "importjs", "exportc", "exportcpp", "exportnims",
    "incompleteStruct",
    "completeStruct",
    "requiresInit", "align", "nodecl", "pure", "sideEffect",
    "header", "noSideEffect", "gcsafe", "noreturn", "nosinks", "merge", "lib", "dynlib",
    "compilerproc", "core", "procvar", "base", "used",
    "fatal", "error", "warning", "hint", "warningAsError", "line",
    "push", "pop", "define", "undef", "lineDir", "stackTrace", "lineTrace",
    "link", "compile", "linksys", "deprecated", "varargs",
    "callconv", "debugger", "nimcall", "stdcall",
    "cdecl", "safecall", "syscall", "inline", "noinline", "fastcall", "thiscall", "closure",
    "noconv", "on", "off", "checks", "rangeChecks", "boundChecks",
    "overflowChecks", "nilChecks",
    "floatChecks", "nanChecks", "infChecks", "styleChecks", "staticBoundChecks",
    "nonReloadable", "executeOnReload",

    "assertions", "patterns", "trmacros", "sinkinference", "warnings", "hints",
    "optimization", "raises", "writes", "reads", "size", "effects", "tags",
    "requires", "ensures", "invariant", "assume", "assert",
    "deadCodeElim",  # deprecated, dead code elim always happens
    "safecode", "package", "noforward", "reorder", "norewrite", "nodestroy",
    "pragma",
    "compileTime", "noinit",
    "passc", "passl", "localPassC", "borrow", "discardable", "fieldChecks",
    "subschar", "acyclic", "shallow", "unroll", "linearScanEnd",
    "computedGoto", "injectStmt", "experimental",
    "write", "gensym", "inject", "dirty", "inheritable", "threadvar", "emit",
    "asmNoStackFrame", "implicitStatic", "global", "codegenDecl", "unchecked",
    "guard", "locks", "partial", "explain", "liftLocals",


    ]


type
  TSpecialWord* {.pure.} = enum
    wInvalid = "",
    wAddr = "addr", wAnd = "and", wAs = "as", wAsm = "asm",
    wBind = "bind", wBlock = "block", wBreak = "break", wCase = "case", wCast = "cast", 
    wConcept = "concept", wConst = "const", wContinue = "continue", wConverter = "converter", 
    wDefer = "defer", wDiscard = "discard", wDistinct = "distinct", wDiv = "div", wDo = "do",
    wElif = "elif", wElse = "else", wEnd = "end", wEnum = "enum", wExcept = "except", wExport = "export",
    wFinally = "finally", wFor = "for", wFrom = "from", wFunc = "func", wIf = "if", wImport = "import",
    wIn = "in", wInclude = "include", wInterface = "interface", wIs = "is", wIsnot = "isnot", 
    wIterator = "iterator", wLet = "let", wMacro = "macro", wMethod = "method", wMixin = "mixin", 
    wMod = "mod", wNil = "nil", wNot = "not", wNotin = "notin", wObject = "object", wOf = "of", wOr = "or",     
    wOut = "out", wProc = "proc", wPtr = "ptr", wRaise = "raise", wRef = "ref", wReturn = "return",
    wShl = "shl", wShr = "shr", wStatic = "static", wTemplate = "template", wTry = "try", 
    wTuple = "tuple", wType = "type", wUsing = "using", wVar = "var",
    wWhen = "when", wWhile = "while", wXor = "xor", wYield = "yield",

    wColon = ":", wColonColon = "::", wEquals = "=", wDot = ".", wDotDot = "..",
    wStar = "*", wMinus = "-",
    wMagic = "magic", wThread = "thread", wFinal = "final", wProfiler = "profile", 
    wMemTracker = "memtracker", wObjChecks = "objchecks",
    wIntDefine = "intdefine", wStrDefine = "strdefine", wBoolDefine = "booldefine", 
    wCursor = "cursor", wNoalias = "noalias",

    wImmediate = "immediate", wConstructor = "constructor", wDestructor = "destructor", wDelegator = "delegator", wOverride = "override",
    wImportCpp = "importcpp", wImportObjC = "importobjc",
    wImportCompilerProc = "importcompilerproc",
    wImportc = "importc", wImportJs = "importjs", wExportc = "exportc", wExportCpp = "exportcpp", wExportNims = "exportnims",
    wIncompleteStruct = "incompletestruct", # deprecated
    wCompleteStruct = "completestruct",
    wRequiresInit = "requiresinit",
    wAlign = "align", wNodecl = "nodecl", wPure = "pure", wSideEffect = "sideeffect", wHeader = "header",
    wNoSideEffect = "nosideeffect", wGcSafe = "gcsafe", wNoreturn = "noreturn", wNosinks = "nosinks", wMerge = "merge", wLib = "lib", wDynlib = "dynlib",
    wCompilerProc = "compilerproc", wCore = "core", wProcVar = "procvar", wBase = "base", wUsed = "used",
    wFatal = "fatal", wError = "error", wWarning = "warning", wHint = "hint", wWarningAsError = "warningaserror", wLine = "line", wPush = "push", wPop = "pop", wDefine = "define", wUndef = "undef",
    wLineDir = "linedir", wStackTrace = "stacktrace", wLineTrace = "linetrace", wLink = "link", wCompile = "compile",
    wLinksys = "linksys", wDeprecated = "deprecated", wVarargs = "varargs", wCallconv = "callconv", wDebugger = "debugger",
    wNimcall = "nimcall", wStdcall = "stdcall", wCdecl = "cdecl", wSafecall = "safecall", wSyscall = "syscall", wInline = "inline", wNoInline = "noinline",
    wFastcall = "fastcall", wThiscall = "thiscall", wClosure = "closure", wNoconv = "noconv", wOn = "on", wOff = "off", wChecks = "checks", wRangeChecks = "rangechecks",
    wBoundChecks = "boundchecks", wOverflowChecks = "overflowchecks", wNilChecks = "nilchecks",
    wFloatChecks = "floatchecks", wNanChecks = "nanchecks", wInfChecks = "infchecks", wStyleChecks = "stylechecks", wStaticBoundchecks = "staticboundchecks",
    wNonReloadable = "nonreloadable", wExecuteOnReload = "executeonreload",
    wAssertions = "assertions", wPatterns = "patterns", wTrMacros = "trmacros", wSinkInference = "sinkinference", wWarnings = "warnings",
    wHints = "hints", wOptimization = "optimization", wRaises = "raises", wWrites = "writes", wReads = "reads", wSize = "size", wEffects = "effects", wTags = "tags",
    wRequires = "requires", wEnsures = "ensures", wInvariant = "invariant", wAssume = "assume", wAssert = "assert",
    wDeadCodeElimUnused = "deadcodeelimunused",  # deprecated, dead code elim always happens
    wSafecode = "safecode", wPackage = "package", wNoForward = "noforward", wReorder = "reorder", wNoRewrite = "norewrite", wNoDestroy = "nodestroy",
    wPragma = "pragma",
    wCompileTime = "compiletime", wNoInit = "noinit",
    wPassc = "passc", wPassl = "passl", wLocalPassc = "localpassc", wBorrow = "borrow", wDiscardable = "discardable",
    wFieldChecks = "fieldchecks",
    wSubsChar = "subschar", wAcyclic = "acyclic", wShallow = "shallow", wUnroll = "unroll", wLinearScanEnd = "linearscanend", wComputedGoto = "computedgoto",
    wInjectStmt = "injectstmt", wExperimental = "experimental",
    wWrite = "write", wGensym = "gensym", wInject = "inject", wDirty = "dirty", wInheritable = "inheritable", wThreadVar = "threadvar", wEmit = "emit",
    wAsmNoStackFrame = "asmnostackframe",
    wImplicitStatic = "implicitstatic", wGlobal = "global", wCodegenDecl = "codegendecl", wUnchecked = "unchecked", wGuard = "guard", wLocks = "locks",
    wPartial = "partial", wExplain = "explain", wLiftLocals = "liftlocals",

    wAuto = "auto", wBool = "Bool", wCatch = "catch", wChar = "char", 
    wClass = "class", wCompl = "compl", wConst_cast = "const_cast", wDefault = "default", 
    wDelete = "delete", wDouble = "double", wDynamic_cast = "dynamic_cast", 
    wExplicit = "explicit", wExtern = "extern", wFalse = "false", wFloat = "float",
    wFriend = "friend", wGoto = "goto", wInt = "int", wLong = "long", wMutable = "mutable", 
    wNamespace = "namespace", wNew = "new", wOperator = "operator", wPrivate = "private", 
    wProtected = "protected", wPublic = "public", wRegister = "register", 
    wReinterpret_cast = "reinterpret_cast", wRestrict = "restrict", wShort = "short", 
    wSigned = "signed", wSizeof = "sizeof", wStatic_cast = "static_cast", wStruct = "struct", wSwitch = "switch",
    wThis = "this", wThrow = "throw", wTrue = "true", wTypedef = "typedef", wTypeid = "typeid", wTypeof = "typeof", 
    wTypename = "typename",
    wUnion = "union", wPacked = "packed", wUnsigned = "unsigned", wVirtual = "virtual", wVoid = "void", wVolatile = "volatile", wWchar_t = "wchar_t",


    "auto", "bool", "catch", "char", "class", "compl",
    "const_cast", "default", "delete", "double",
    "dynamic_cast", "explicit", "extern", "false",
    "float", "friend", "goto", "int", "long", "mutable",
    "namespace", "new", "operator",
    "private", "protected", "public", "register", "reinterpret_cast", "restrict",
    "short", "signed", "sizeof", "static_cast", "struct", "switch",
    "this", "throw", "true", "typedef", "typeid", "typeof",
    "typename", "union", "packed", "unsigned", "virtual", "void", "volatile",
    "wchar_t",


    wAlignas = "alignas", wAlignof = "alignof", wConstexpr = "constexpr", wDecltype = "decltype", 
    wNullptr = "nullptr", wNoexcept = "noexcept",
    wThread_local = "thread_local", wStatic_assert = "static_assert", 
    wChar16_t = "char16_t", wChar32_t = "char32_t",

    wStdIn = "stdin", wStdOut = "stdout", wStdErr = "stderr",

    wInOut = "inout", wByCopy = "bycopy", wByRef = "byref", wOneWay = "oneway",
    wBitsize = "bitsize"

  TSpecialWords* = set[TSpecialWord]

const
  oprLow* = ord(wColon)
  oprHigh* = ord(wDotDot)

  nimKeywordsLow* = ord(wAsm)
  nimKeywordsHigh* = ord(wYield)

  ccgKeywordsLow* = ord(wAuto)
  ccgKeywordsHigh* = ord(wOneWay)

  cppNimSharedKeywords* = {
    wAsm, wBreak, wCase, wConst, wContinue, wDo, wElse, wEnum, wExport,
    wFor, wIf, wReturn, wStatic, wTemplate, wTry, wWhile, wUsing}

proc findStr*(a: openArray[string], s: string): int =
  for i in low(a)..high(a):
    if cmpIgnoreStyle(a[i], s) == 0:
      return i
  result = - 1
