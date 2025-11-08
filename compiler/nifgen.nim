#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the NIF code generator.

import std / [assertions, syncio, os, tables, intsets]

import
  ast, astalgo, modulegraphs, options, pathutils, lineinfos, idents, msgs, types

import "../dist/nimony/src/lib" / nifbuilder
import "../dist/nimony/src/models" / nifler_tags
import "../dist/nimony/src/gear2" / modnames

## This was copied from Nifler's bridge.nim. However, this code will evolve
## in a different direction as it needs to translate the semchecked AST which
## is way more complex. For example, all magics need to be special cased.

const
  SystemModuleSuffix = "sysvq0asl"

type
  TranslationContext = object
    conf: ConfigRef
    b, deps: Builder
    section: NiflerKind
    portablePaths: bool
    depsEnabled, lineInfoEnabled: bool
    hasHoles: bool
    graph: ModuleGraph
    toSuffix: Table[FileIndex, string]
    tempFilename, finalFilename: string  # for atomic file creation
    tempDepsFilename, finalDepsFilename: string  # for atomic deps file creation
    handled: IntSet

  NifModule* = ref object of PPassContext
    graph*: ModuleGraph
    module*: PSym
    tc: TranslationContext
    outfile: string

proc nodeKindTranslation(k: TNodeKind): string =
  case k
  of nkCommand: "cmd"
  of nkCall: "call"
  of nkCallStrLit: "callstrlit"
  of nkInfix: "infix"
  of nkPrefix: "prefix"
  of nkHiddenCallConv: "hiddencallconv"
  of nkExprEqExpr: "vv"
  of nkExprColonExpr: "kv"
  of nkPar: "par"
  of nkObjConstr: "oconstr"
  of nkCurly: "curly"
  of nkCurlyExpr: "curlyat"
  of nkBracket: "bracket"
  of nkBracketExpr: "at"
  of nkPragmaBlock, nkPragmaExpr: "pragmax"
  of nkDotExpr: "dot"
  of nkAsgn, nkFastAsgn: "asgn"
  of nkIfExpr, nkIfStmt: "if"
  of nkWhenStmt, nkRecWhen: "when"
  of nkWhileStmt: "while"
  of nkCaseStmt, nkRecCase: "case"
  of nkForStmt: "for"
  of nkDiscardStmt: "discard"
  of nkBreakStmt: "break"
  of nkReturnStmt: "ret"
  of nkElifExpr, nkElifBranch: "elif"
  of nkElseExpr, nkElse: "else"
  of nkOfBranch: "of"
  of nkCast: "cast"
  of nkLambda: "proc"
  of nkAccQuoted: "quoted"
  of nkTableConstr: "tabconstr"
  of nkStmtListType, nkStmtListExpr, nkStmtList, nkRecList, nkArgList: "stmts"
  of nkBlockStmt, nkBlockExpr, nkBlockType: "block"
  of nkStaticStmt: "staticstmt"
  of nkBind, nkBindStmt: "bind"
  of nkMixinStmt: "mixin"
  of nkAddr: "addr"
  of nkGenericParams: "typevars"
  of nkFormalParams: "params"
  of nkImportAs: "importas"
  of nkRaiseStmt: "raise"
  of nkContinueStmt: "continue"
  of nkYieldStmt: "yld"
  of nkProcDef: "proc"
  of nkFuncDef: "func"
  of nkMethodDef: "method"
  of nkConverterDef: "converter"
  of nkMacroDef: "macro"
  of nkTemplateDef: "template"
  of nkIteratorDef: "iterator"
  of nkExceptBranch: "except"
  of nkTypeOfExpr: "typeof"
  of nkFinally: "fin"
  of nkTryStmt: "try"
  of nkImportStmt: "import"
  of nkImportExceptStmt: "importexcept"
  of nkIncludeStmt: "include"
  of nkExportStmt: "export"
  of nkExportExceptStmt: "exportexcept"
  of nkFromStmt: "fromimport"
  of nkPragma: "pragmas"
  of nkAsmStmt: "asm"
  of nkDefer: "defer"
  of nkUsingStmt: "using"
  of nkCommentStmt: "comment"
  of nkObjectTy: "object"
  of nkTupleTy, nkTupleClassTy: "tuple"
  of nkTypeClassTy: "concept"
  of nkStaticTy: "static"
  of nkRefTy: "ref"
  of nkPtrTy: "ptr"
  of nkVarTy: "mut"
  of nkDistinctTy: "distinct"
  of nkIteratorTy: "itertype"
  of nkEnumTy: "enum"
  #of nkEnumFieldDef: EnumFieldDecl
  of nkTupleConstr: "tup"
  of nkOutTy: "out"
  of nkNone, nkEmpty, nkIdent, nkSym, nkType, nkCharLit,
     nkIntLit, nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit,
     nkUIntLit, nkUInt8Lit, nkUInt16Lit, nkUInt32Lit, nkUInt64Lit,
     nkFloatLit, nkFloat32Lit, nkFloat64Lit, nkFloat128Lit,
     nkStrLit, nkRStrLit, nkTripleStrLit, nkNilLit:
    # atoms special cased:
    "err"
  of nkDerefExpr: "deref"
  of nkClosedSymChoice: "cchoice"
  of nkOpenSymChoice: "ochoice"
  of nkComesFrom,
     nkDotCall, nkPostfix, nkIdentDefs, nkVarTuple, nkRange, nkCheckedFieldExpr, nkDo,
     nkHiddenStdConv, nkHiddenSubConv, nkConv, nkStaticExpr, nkHiddenAddr, nkHiddenDeref,
     nkObjDownConv, nkObjUpConv, nkChckRangeF, nkChckRange64, nkChckRange,
     nkStringToCString, nkCStringToString, nkOfInherit, nkParForStmt, nkTypeSection,
     nkVarSection, nkLetSection, nkConstSection, nkConstDef, nkTypeDef, nkWith, nkWithout,
     nkConstTy, nkProcTy, nkSinkAsgn, nkEnumFieldDef, nkPattern, nkHiddenTryStmt, nkClosure,
     nkGotoState, nkState, nkBreakState, nkError, nkModuleRef, nkReplayAction, nkNilRodNode, nkOpenSym:
    "err"

proc absLineInfo(i: TLineInfo; c: var TranslationContext) =
  var fp = toFullPath(c.conf, i.fileIndex)
  if c.portablePaths:
    fp = relativePath(fp, getCurrentDir(), '/')
  c.b.addLineInfo int32(i.col), int32(i.line), fp

proc relLineInfo(n, parent: PNode; c: var TranslationContext;
                 emitSpace = false) =
  if not c.lineInfoEnabled: return
  let i = n.info
  if parent == nil:
    absLineInfo i, c
    return
  let p = parent.info
  if i.fileIndex != p.fileIndex:
    absLineInfo i, c
    return

  let colDiff = int32(i.col) - int32(p.col)
  let lineDiff = int32(i.line) - int32(p.line)
  c.b.addLineInfo colDiff, lineDiff, ""

proc addIntLit*(b: var Builder; u: BiggestInt; suffix: string) =
  assert suffix.len > 0
  b.withTree "suf":
    b.addIntLit u
    b.addStrLit suffix

proc addUIntLit*(b: var Builder; u: BiggestUInt; suffix: string) =
  assert suffix.len > 0
  b.withTree "suf":
    b.addUIntLit u
    b.addStrLit suffix

proc addFloatLit*(b: var Builder; u: BiggestFloat; suffix: string) =
  assert suffix.len > 0
  b.withTree "suf":
    b.addFloatLit u
    b.addStrLit suffix

type
  IdentDefName = object
    name, visibility, pragma: PNode

proc splitIdentDefName(n: PNode): IdentDefName =
  result = IdentDefName(visibility: nil, pragma: nil)
  if n.kind == nkPragmaExpr:
    result.pragma = n[1]
    if n[0].kind == nkPostfix:
      result.visibility = n[0][0]
      result.name = n[0][1]
    else:
      result.name = n[0]
  elif n.kind == nkPostfix:
    result.visibility = n[0]
    result.name = n[1]
  else:
    result.name = n
    if n.kind == nkSym and sfExported in n.sym.flags:
      result.visibility = n # anything other than `nil` will do here

proc toNif(n, parent: PNode; c: var TranslationContext; allowEmpty = false)
proc toNifType(t: PType; parent: PNode; c: var TranslationContext)

const
  NewOperator = -2
  TypedMagic = -3
  TypedMagicOp1 = -4
  NoMagic = -5
  ArrayType = -6
  StringType = -7
  BecomesCall = -8

proc magicToNifTag(s: TMagic): (string, int) =
  case s
  of mNone: ("bug", NoMagic)
  of mDefined: ("defined", 0)
  of mDeclared: ("declared", 0)
  of mDeclaredInScope: ("declaredinscope", NoMagic)
  of mCompiles: ("compiles", 0)
  of mArrGet: ("arrat", 0)
  of mArrPut: ("arrat", 0)
  of mAsgn: ("asgn", 0)
  of mLow: ("low", 0)
  of mHigh: ("high", 0)
  of mSizeOf: ("sizeof", 0)
  of mAlignOf: ("alignof", 0)
  of mOffsetOf: ("offsetof", 0)
  of mTypeTrait: ("typetrait", NoMagic)
  of mIs: ("is", 0)
  of mOf: ("instanceof", 0)
  of mAddr: ("addr", 0)
  of mType: ("typeof", 0)
  of mTypeOf: ("typeof", 0)
  of mPlugin: ("plugin", NoMagic)
  of mEcho: ("echo", NoMagic)
  of mShallowCopy: ("asgn", 0)
  of mSlurp: ("slurp", NoMagic)
  of mStaticExec: ("staticexec", NoMagic)
  of mStatic: ("static", NoMagic)
  of mParseExprToAst: ("parseexprtoast", NoMagic)
  of mParseStmtToAst: ("parsestmttoast", NoMagic)
  of mExpandToAst: ("expandtoast", NoMagic)
  of mQuoteAst: ("quoteast", NoMagic)
  of mInc: ("inc", NoMagic)
  of mDec: ("dec", NoMagic)
  of mOrd: ("ord", NoMagic)
  of mNew: ("newref", NewOperator)
  of mNewFinalize: ("newref", NewOperator)
  of mNewSeq: ("newseq", NoMagic)
  of mNewSeqOfCap: ("newseqofcap", NoMagic)
  of mLengthOpenArray: ("lenopenarray", NoMagic)
  of mLengthStr: ("lenstr", NoMagic)
  of mLengthArray: ("lenarray", NoMagic)
  of mLengthSeq: ("lenseq", NoMagic)
  of mIncl: ("incl", 0)
  of mExcl: ("excl", 0)
  of mCard: ("card", TypedMagic)
  of mChr: ("chr", NoMagic)
  of mGCref: ("gcref", NoMagic)
  of mGCunref: ("gcunref", NoMagic)
  of mAddI: ("add", TypedMagic)
  of mSubI: ("sub", TypedMagic)
  of mMulI: ("mul", TypedMagic)
  of mDivI: ("div", TypedMagic)
  of mModI: ("mod", TypedMagic)
  of mSucc: ("add", TypedMagic)
  of mPred: ("sub", TypedMagic)
  of mAddF64: ("add", TypedMagic)
  of mSubF64: ("sub", TypedMagic)
  of mMulF64: ("mul", TypedMagic)
  of mDivF64: ("div", TypedMagic)
  of mShrI: ("shr", TypedMagic)
  of mShlI: ("shl", TypedMagic)
  of mAshrI: ("ashr", TypedMagic)
  of mBitandI: ("bitand", TypedMagic)
  of mBitorI: ("bitor", TypedMagic)
  of mBitxorI: ("bitxor", TypedMagic)
  of mMinI: ("min", NoMagic)
  of mMaxI: ("max", NoMagic)
  of mAddU: ("add", TypedMagic)
  of mSubU: ("sub", TypedMagic)
  of mMulU: ("mul", TypedMagic)
  of mDivU: ("div", TypedMagic)
  of mModU: ("mod", TypedMagic)
  of mEqI: ("eq", TypedMagicOp1)
  of mLeI: ("le", TypedMagicOp1)
  of mLtI: ("lt", TypedMagicOp1)
  of mEqF64: ("eq", TypedMagicOp1)
  of mLeF64: ("le", TypedMagicOp1)
  of mLtF64: ("lt", TypedMagicOp1)
  of mLeU: ("le", TypedMagicOp1)
  of mLtU: ("lt", TypedMagicOp1)
  of mEqEnum: ("eq", TypedMagicOp1)
  of mLeEnum: ("le", TypedMagicOp1)
  of mLtEnum: ("lt", TypedMagicOp1)
  of mEqCh: ("eq", TypedMagicOp1)
  of mLeCh: ("le", TypedMagicOp1)
  of mLtCh: ("lt", TypedMagicOp1)
  of mEqB: ("eq", TypedMagicOp1)
  of mLeB: ("le", TypedMagicOp1)
  of mLtB: ("lt", TypedMagicOp1)
  of mEqRef: ("eq", TypedMagicOp1)
  of mLePtr: ("le", TypedMagicOp1)
  of mLtPtr: ("lt", TypedMagicOp1)
  of mXor: ("xor", 0)
  of mEqCString: ("eq", NoMagic)
  of mEqProc: ("eq", TypedMagicOp1)
  of mUnaryMinusI: ("neg", 0)
  of mUnaryMinusI64: ("neg", 0)
  of mAbsI: ("abs", NoMagic)
  of mNot: ("not", 0)
  of mUnaryPlusI: ("unaryplus", NoMagic)
  of mBitnotI: ("bitnot", TypedMagic)
  of mUnaryPlusF64: ("unaryplusf64", NoMagic)
  of mUnaryMinusF64: ("neg", 0)
  of mCharToStr: ("chartostr", NoMagic)
  of mBoolToStr: ("booltostr", NoMagic)
  of mCStrToStr: ("fromCString.0." & SystemModuleSuffix, BecomesCall)
  of mStrToStr: ("strtostr", NoMagic)
  of mEnumToStr: ("enumtostr", 0)
  of mAnd: ("and", 0)
  of mOr: ("or", 0)
  of mImplies: ("implies", NoMagic)
  of mIff: ("iff", NoMagic)
  of mExists: ("exists", NoMagic)
  of mForall: ("forall", NoMagic)
  of mOld: ("old", NoMagic)
  of mEqStr: ("==.15." & SystemModuleSuffix, BecomesCall) # XXX find a better solution
  of mLeStr: ("<=.15." & SystemModuleSuffix, BecomesCall)
  of mLtStr: ("<.15." & SystemModuleSuffix, BecomesCall)
  of mEqSet: ("eqset", TypedMagicOp1)
  of mLeSet: ("leset", TypedMagicOp1)
  of mLtSet: ("ltset", TypedMagicOp1)
  of mMulSet: ("mulset", TypedMagic)
  of mPlusSet: ("plusset", TypedMagic)
  of mMinusSet: ("minusset", TypedMagic)
  of mXorSet: ("xorset", TypedMagic)
  of mConStrStr: ("&.0." & SystemModuleSuffix, BecomesCall)
  of mSlice: ("slice", NoMagic)
  of mDotDot: ("dotdot", NoMagic)
  of mFields: ("fields", 0)
  of mFieldPairs: ("fieldpairs", 0)
  of mOmpParFor: ("ompparfor", NoMagic)
  of mAppendStrCh: ("addstrch", NoMagic)
  of mAppendStrStr: ("addstrstr", NoMagic)
  of mAppendSeqElem: ("addseqelem", NoMagic)
  of mInSet: ("inset", TypedMagicOp1)
  of mRepr: ("repr", NoMagic)
  of mExit: ("exit", NoMagic)
  of mSetLengthStr: ("setlenstr", NoMagic)
  of mSetLengthSeq: ("setlenseq", NoMagic)
  of mSetLengthSeqUninit: ("setlensequninit", NoMagic)
  of mIsPartOf: ("ispartof", NoMagic)
  of mAstToStr: ("asttostr", NoMagic)
  of mParallel: ("parallel", NoMagic)
  of mSwap: ("swap", NoMagic)
  of mIsNil: ("isnil", NoMagic)
  of mArrToSeq: ("arrtoseq", NoMagic)
  of mOpenArrayToSeq: ("openarraytoseq", NoMagic)
  of mNewString: ("newString.0." & SystemModuleSuffix, BecomesCall)
  of mNewStringOfCap: ("newStringOfCap.0." & SystemModuleSuffix, BecomesCall)
  of mParseBiggestFloat: ("parsebiggestfloat", NoMagic)
  of mMove: ("move", NoMagic)
  of mEnsureMove: ("emove", 0)
  of mWasMoved: ("wasmoved", 0)
  of mDup: ("dup", 0)
  of mDestroy: ("destroy", 0)
  of mTrace: ("trace", 0)
  of mDefault: ("defaultobj", NoMagic)
  of mUnown: ("unown", NoMagic)
  of mFinished: ("finished", NoMagic)
  of mIsolate: ("isolate", NoMagic)
  of mAccessEnv: ("accessenv", NoMagic)
  of mAccessTypeField: ("accesstypefield", NoMagic)
  of mArray: ("array", ArrayType)
  of mOpenArray: ("flexarray", NoMagic)
  of mRange: ("range", NoMagic)
  of mSet: ("set", 0)
  of mSeq: ("seq", NoMagic)
  of mVarargs: ("varargs", 0)
  of mRef: ("ref", 0)
  of mPtr: ("ptr", 0)
  of mVar: ("mut", 0)
  of mDistinct: ("distinct", 0)
  of mVoid: ("void", 0)
  of mTuple: ("tuple", 0)
  of mOrdinal: ("ordinal", NoMagic)
  of mIterableType: ("iterabletype", NoMagic)
  of mInt: ("i", -1)
  of mInt8: ("i", 8)
  of mInt16: ("i", 16)
  of mInt32: ("i", 32)
  of mInt64: ("i", 64)
  of mUInt: ("u", -1)
  of mUInt8: ("u", 8)
  of mUInt16: ("u", 16)
  of mUInt32: ("u", 32)
  of mUInt64: ("u", 64)
  of mFloat: ("f", 64)
  of mFloat32: ("f", 32)
  of mFloat64: ("f", 64)
  of mFloat128: ("f", 128)
  of mBool: ("bool", 0)
  of mChar: ("c", 8)
  of mString: ("string", StringType)
  of mCstring: ("cstring", 0)
  of mPointer: ("pointer", 0)
  of mNil: ("nil", 0)
  of mExpr: ("expr", NoMagic)
  of mStmt: ("stmt", NoMagic)
  of mTypeDesc: ("typedesc", 0)
  of mVoidType: ("void", 0)
  of mPNimrodNode: ("nimnode", NoMagic)
  of mSpawn: ("spawn", NoMagic)
  of mDeepCopy: ("deepcopy", NoMagic)
  of mIsMainModule: ("ismainmodule", 0)
  of mCompileDate: ("compiledate", NoMagic)
  of mCompileTime: ("compiletime", NoMagic)
  of mProcCall: ("proccall", 0)
  of mCpuEndian: ("cpuendian", NoMagic)
  of mHostOS: ("hostos", NoMagic)
  of mHostCPU: ("hostcpu", NoMagic)
  of mBuildOS: ("buildos", NoMagic)
  of mBuildCPU: ("buildcpu", NoMagic)
  of mAppType: ("apptype", NoMagic)
  of mCompileOption: ("compileoption", NoMagic)
  of mCompileOptionArg: ("compileoptionarg", NoMagic)
  of mNLen: ("nlen", NoMagic)
  of mNChild: ("nchild", NoMagic)
  of mNSetChild: ("nsetchild", NoMagic)
  of mNAdd: ("nadd", NoMagic)
  of mNAddMultiple: ("naddmultiple", NoMagic)
  of mNDel: ("ndel", NoMagic)
  of mNKind: ("nkind", NoMagic)
  of mNSymKind: ("nsymkind", NoMagic)
  of mNccValue: ("nccvalue", NoMagic)
  of mNccInc: ("nccinc", NoMagic)
  of mNcsAdd: ("ncsadd", NoMagic)
  of mNcsIncl: ("ncsincl", NoMagic)
  of mNcsLen: ("ncslen", NoMagic)
  of mNcsAt: ("ncsat", NoMagic)
  of mNctPut: ("nctput", NoMagic)
  of mNctLen: ("nctlen", NoMagic)
  of mNctGet: ("nctget", NoMagic)
  of mNctHasNext: ("ncthasnext", NoMagic)
  of mNctNext: ("nctnext", NoMagic)
  of mNIntVal: ("nintval", NoMagic)
  of mNFloatVal: ("nfloatval", NoMagic)
  of mNSymbol: ("nsymbol", NoMagic)
  of mNIdent: ("nident", NoMagic)
  of mNGetType: ("ngettype", NoMagic)
  of mNStrVal: ("nstrval", NoMagic)
  of mNSetIntVal: ("nsetintval", NoMagic)
  of mNSetFloatVal: ("nsetfloatval", NoMagic)
  of mNSetSymbol: ("nsetsymbol", NoMagic)
  of mNSetIdent: ("nsetident", NoMagic)
  of mNSetStrVal: ("nsetstrval", NoMagic)
  of mNLineInfo: ("nlineinfo", NoMagic)
  of mNNewNimNode: ("nnewnimnode", NoMagic)
  of mNCopyNimNode: ("ncopynimnode", NoMagic)
  of mNCopyNimTree: ("ncopynimtree", NoMagic)
  of mStrToIdent: ("strtoident", NoMagic)
  of mNSigHash: ("nsighash", NoMagic)
  of mNSizeOf: ("nsizeof", NoMagic)
  of mNBindSym: ("nbindsym", NoMagic)
  of mNCallSite: ("ncallsite", NoMagic)
  of mEqIdent: ("eqident", NoMagic)
  of mEqNimrodNode: ("eqnimnode", NoMagic)
  of mSameNodeType: ("samenodetype", NoMagic)
  of mGetImpl: ("getimpl", NoMagic)
  of mNGenSym: ("ngensym", NoMagic)
  of mNHint: ("nhint", NoMagic)
  of mNWarning: ("nwarning", NoMagic)
  of mNError: ("nerror", NoMagic)
  of mInstantiationInfo: ("instantiationinfo", NoMagic)
  of mGetTypeInfo: ("gettypeinfo", NoMagic)
  of mGetTypeInfoV2: ("gettypeinfov2", NoMagic)
  of mNimvm: ("nimvm", NoMagic)
  of mIntDefine: ("intdefine", NoMagic)
  of mStrDefine: ("strdefine", NoMagic)
  of mBoolDefine: ("booldefine", NoMagic)
  of mGenericDefine: ("genericdefine", NoMagic)
  of mRunnableExamples: ("runnableexamples", NoMagic)
  of mException: ("exception", NoMagic)
  of mBuiltinType: ("builtintype", NoMagic)
  of mSymOwner: ("symowner", NoMagic)
  of mUncheckedArray: ("uarray", 0)
  of mGetImplTransf: ("getimpltransf", NoMagic)
  of mSymIsInstantiationOf: ("symisinstantiationof", NoMagic)
  of mNodeId: ("nodeid", NoMagic)
  of mPrivateAccess: ("privateaccess", NoMagic)
  of mZeroDefault: ("zerodefault", NoMagic)

proc modname(c: var TranslationContext; idx: FileIndex): string =
  result = c.toSuffix.getOrDefault(idx)
  if result.len == 0:
    let fp = toFullPath(c.conf, idx)
    result = moduleSuffix(fp, cast[seq[string]](c.conf.searchPaths))
    c.toSuffix[idx] = result

proc projectHash(c: var TranslationContext): string =
  result = moduleSuffix(c.conf.projectFull.string, [])

proc symToNif(orig: PSym; parent: PNode; c: var TranslationContext; isDef = false) =
  # We do not want to use generic instantiations as the names! We instead want
  # Nimony to re-instantiate the generic symbol:
  let isInstantiated = orig.kind in skProcKinds and sfFromGeneric in orig.flags
  let s = if isInstantiated: orig.owner else: orig
  # Unfortunately, this is not enough. Code like `myGeneric[int, char]()` will
  # have lost the explicit type parameters. We can get these from the instance cache.

  var m = s.name.s & '.' & $s.disamb
  var ow = if orig.kind in {skField, skEnumField}: s.originatingModule() else: s.skipGenericOwner()
  if ow == nil:
    ow = c.graph.systemModule # can happen for magics created by the createMagic
  if ow.kind == skModule:
    m.add '.'
    m.add modname(c, FileIndex ow.position)
  if isDef:
    c.b.addSymbolDef m
  elif isInstantiated:
    c.b.addTree "at"
    c.b.addSymbol m
    for inst in procInstCacheItems(c.graph, s):
      if inst.sym == orig:
        # for terrible reasons `concreteTypes` contains all the types,
        # so we need to know how many generic params there were:
        for i in 0..<inst.genericParamsCount:
          toNifType(inst.concreteTypes[i], parent, c)
        break
    c.b.endTree()
  elif s.kind == skType and sfImportc notin s.flags and s.magic != mNone:
    let (tag, bits) = magicToNifTag(s.magic)
    if bits >= -1:
      c.b.addTree tag
      if bits != 0:
        c.b.addIntLit bits
      c.b.endTree()
    else:
      c.b.addSymbol m
  else:
    c.b.addSymbol m

proc toNifDecl(n, parent: PNode; c: var TranslationContext) =
  if n.kind == nkSym:
    relLineInfo(n, parent, c)
    symToNif(n.sym, parent, c, true)
  else:
    toNif n, parent, c

proc toVarTuple(v: PNode, n: PNode; c: var TranslationContext) =
  c.b.addTree("unpacktup")
  for i in 0..<v.len-1: # ignores typedesc
    c.b.addTree("let")

    toNifDecl(v[i], n, c) # name

    c.b.addEmpty 4 # export marker, pragmas, type, value
    c.b.endTree() # LetDecl
  c.b.endTree() # UnpackIntoTuple

proc handleCaseIdentDefs(n, parent: PNode; c: var TranslationContext) =
  if n.kind == nkIdentDefs and n.len > 3:
    # multiple ident defs, we need to add StmtsL
    c.b.addTree("stmts")
    toNif(n, parent, c)
    c.b.endTree()
  else:
    toNif(n, parent, c)

template writeTypeFlags(c: var TranslationContext; t: PType) =
  discard "maybe we need type flags later"

proc isNominalRef(t: PType): bool {.inline.} =
  if t.hasElementType:
    let e = t.elementType
    t.sym != nil and e.kind == tyObject and (e.sym == nil or sfAnon in e.sym.flags)
  else:
    false

template singleElement(keyw: string) {.dirty.} =
  c.b.withTree keyw:
    writeTypeFlags(c, t)
    if t.hasElementType:
      toNifType t.elementType, parent, c
    else:
      c.b.addEmpty

proc atom(t: PType; c: var TranslationContext; tag: string) =
  c.b.withTree tag:
    writeTypeFlags(c, t)

proc toNifTag(s: TTypeKind): string =
  case s
  of tyNone: "none"
  of tyBool: "bool"
  of tyChar: "c"
  of tyEmpty: "empty"
  of tyAlias: "alias"
  of tyNil: "nil"
  of tyUntyped: "untyped"
  of tyTyped: "typed"
  of tyTypeDesc: "typedesc"
  of tyGenericInvocation: "at"
  of tyGenericBody: "gbody"
  of tyGenericInst: "at"
  of tyGenericParam: "gparam"
  of tyDistinct: "distinct"
  of tyEnum: "enum"
  of tyOrdinal: "ordinal"
  of tyArray: "array"
  of tyObject: "object"
  of tyTuple: "tuple"
  of tySet: "set"
  of tyRange: "range"
  of tyPtr: "ptr"
  of tyRef: "ref"
  of tyVar: "mut"
  of tySequence: "seq"
  of tyProc: "proctype"
  of tyPointer: "pointer"
  of tyOpenArray: "openArray"
  of tyString: "string"
  of tyCstring: "cstring"
  of tyForward: "forward"
  of tyInt: "int"
  of tyInt8: "int8"
  of tyInt16: "int16"
  of tyInt32: "int32"
  of tyInt64: "int64"
  of tyFloat: "float"
  of tyFloat32: "float32"
  of tyFloat64: "float64"
  of tyFloat128: "float128"
  of tyUInt: "uint"
  of tyUInt8: "uint8"
  of tyUInt16: "uint16"
  of tyUInt32: "uint32"
  of tyUInt64: "uint64"
  of tyOwned: "owned"
  of tySink: "sink"
  of tyLent: "lent"
  of tyVarargs: "varargs"
  of tyUncheckedArray: "uarray"
  of tyError: "error"
  of tyBuiltInTypeClass: "bconcept"
  of tyUserTypeClass: "uconcept"
  of tyUserTypeClassInst: "uconceptinst"
  of tyCompositeTypeClass: "cconcept"
  of tyInferred: "inferred"
  of tyAnd: "and"
  of tyOr: "or"
  of tyNot: "not"
  of tyAnything: "anything"
  of tyStatic: "static"
  of tyFromExpr: "typeof"
  of tyConcept: "concept"
  of tyVoid: "void"
  of tyIterable: "iterable"
  of tyStub: "stub"

proc atom(t: PType; c: var TranslationContext) =
  c.b.withTree toNifTag(t.kind):
    writeTypeFlags(c, t)

template typeHead(c: var TranslationContext; t: PType; body: untyped) =
  c.b.withTree toNifTag(t.kind):
    writeTypeFlags(c, t)
    body

proc toNifTag(s: TCallingConvention): string =
  case s
  of ccNimCall: "nimcall"
  of ccStdCall: "stdcall"
  of ccCDecl: "cdecl"
  of ccSafeCall: "safecall"
  of ccSysCall: "syscall"
  of ccInline: "inline"
  of ccNoInline: "noinline"
  of ccFastCall: "fastcall"
  of ccThisCall: "thiscall"
  of ccClosure: "closure"
  of ccNoConvention: "noconv"
  of ccMember: "member"

proc symbolType(name: string; t: PType; c: var TranslationContext) =
  c.b.addSymbol name

proc genericAt(name: string; parent: PNode; t: PType; c: var TranslationContext) =
  c.b.withTree "at":
    c.b.addSymbol name
    for _, son in t.ikids: toNifType son, parent, c

proc toNifType(t: PType; parent: PNode; c: var TranslationContext) =
  if t == nil:
    c.b.addKeyw "nil"
    return

  case t.kind
  of tyNone: atom t, c
  of tyBool: atom t, c
  of tyChar: atom t, c, "c 8"
  of tyEmpty: c.b.addEmpty
  of tyInt: atom t, c, "i -1"
  of tyInt8: atom t, c, "i 8"
  of tyInt16: atom t, c, "i 16"
  of tyInt32: atom t, c, "i 32"
  of tyInt64: atom t, c, "i 64"
  of tyUInt: atom t, c, "u -1"
  of tyUInt8: atom t, c, "u 8"
  of tyUInt16: atom t, c, "u 16"
  of tyUInt32: atom t, c, "u 32"
  of tyUInt64: atom t, c, "u 64"
  of tyFloat, tyFloat64: atom t, c, "f 64"
  of tyFloat32: atom t, c, "f 32"
  of tyFloat128: atom t, c, "f 128"
  of tyAlias:
    c.typeHead t:
      toNifType t.skipModifier, parent, c
  of tyNil: atom t, c
  of tyUntyped: atom t, c
  of tyTyped: atom t, c
  of tyTypeDesc:
    c.typeHead t:
      if t.kidsLen == 0 or t.elementType.kind == tyNone:
        c.b.addEmpty
      else:
        toNifType t.elementType, parent, c
  of tyGenericParam:
    if t.sym != nil:
      symToNif t.sym, parent, c
    else:
      c.typeHead t:
        discard

  of tyGenericInst:
    c.typeHead t:
      toNifType t.genericHead, parent, c
      for _, a in t.genericInstParams:
        toNifType a, parent, c
  of tyGenericInvocation:
    c.typeHead t:
      toNifType t.genericHead, parent, c
      for _, a in t.genericInvocationParams:
        toNifType a, parent, c
  of tyGenericBody:
    #toNifType t.last, parent, c
    c.typeHead t:
      for _, son in t.ikids: toNifType son, parent, c
  of tyDistinct, tyEnum:
    if t.sym != nil:
      symToNif t.sym, parent, c
    else:
      c.typeHead t:
        for _, son in t.ikids: toNifType son, parent, c
  of tyPtr:
    if isNominalRef(t):
      symToNif t.sym, parent, c
    else:
      c.typeHead t:
        if t.hasElementType:
          toNifType t.elementType, parent, c
        else:
          c.b.addEmpty
  of tyRef:
    if isNominalRef(t):
      symToNif t.sym, parent, c
    else:
      c.typeHead t:
        if t.hasElementType:
          toNifType t.elementType, parent, c
        else:
          c.b.addEmpty
  of tyVar:
    c.b.withTree(if isOutParam(t): "out" else: "mut"):
      toNifType t.elementType, parent, c
  of tyAnd:
    c.typeHead t:
      for _, son in t.ikids: toNifType son, parent, c
  of tyOr:
    c.typeHead t:
      for _, son in t.ikids: toNifType son, parent, c
  of tyNot:
    c.typeHead t: toNifType t.elementType, parent, c

  of tyFromExpr:
    if t.n == nil:
      atom t, c, "err"
    else:
      c.typeHead t:
        toNif t.n, parent, c

  of tyArray:
    c.typeHead t:
      if t.hasElementType:
        toNifType t.elementType, parent, c
        toNifType t.indexType, parent, c
      else:
        c.b.addEmpty 2
  of tyUncheckedArray:
    c.typeHead t:
      if t.hasElementType:
        toNifType t.elementType, parent, c
      else:
        c.b.addEmpty

  of tySequence:
    genericAt "seq.0." & SystemModuleSuffix, parent, t, c

  of tyOrdinal:
    c.typeHead t:
      if t.hasElementType:
        toNifType t.skipModifier, parent, c
      else:
        c.b.addEmpty

  of tySet: singleElement toNifTag(t.kind)
  of tyOpenArray: genericAt "openArray.0." & SystemModuleSuffix, parent, t, c
  of tyIterable: singleElement toNifTag(t.kind)
  of tyLent: singleElement toNifTag(t.kind)

  of tyTuple:
    c.typeHead t:
      if t.n != nil:
        for i in 0..<t.n.len:
          assert(t.n[i].kind == nkSym)
          c.b.withTree "kv":
            c.b.addIdent t.n[i].sym.name.s
            toNifType t.n[i].sym.typ, parent, c
      else:
        for _, son in t.ikids: toNifType son, parent, c

  of tyRange:
    c.typeHead t:
      toNifType t.elementType, parent, c
      if t.n != nil and t.n.kind == nkRange and t.n.len == 2:
        toNif t.n[0], parent, c
        toNif t.n[1], parent, c
      else:
        c.b.addEmpty 2

  of tyProc:
    let kind = if tfIterator in t.flags: "iteratortype"
               else: "proctype"
    c.b.withTree kind:

      c.b.addEmpty # name
      for i, a in t.paramTypes:
        let j = paramTypeToNodeIndex(i)
        if t.n != nil and j < t.n.len and t.n[j].kind == nkSym:
          c.b.addIdent(t.n[j].sym.name.s)
          toNifType a, parent, c
      if tfUnresolved in t.flags:
        c.b.addRaw "[*missing parameters*]"
      if t.hasElementType and t.returnType != nil:
        toNifType t.returnType, parent, c
      else:
        c.b.addEmpty

      c.b.withTree "effects":
        # XXX model explicit .raises and .tags annotations
        if tfNoSideEffect in t.flags:
          c.b.addKeyw "noside"
        if tfThread in t.flags:
          c.b.addKeyw "gcsafe"

      c.b.withTree "pragmas":
        if t.callConv == ccNimCall and tfExplicitCallConv notin t.flags:
          discard "no calling convention to generate"
        else:
          c.b.addKeyw toNifTag(t.callConv)

  of tyVarargs:
    c.typeHead t:
      if t.hasElementType:
        toNifType t.elementType, parent, c
      else:
        c.b.addEmpty
      if t.n != nil:
        toNif t.n, parent, c
      else:
        c.b.addEmpty

  of tySink: singleElement toNifTag(t.kind)
  of tyOwned: singleElement toNifTag(t.kind)
  of tyVoid: atom t, c
  of tyPointer: atom t, c
  of tyString: symbolType "string.0." & SystemModuleSuffix, t, c
  of tyCstring: atom t, c
  of tyObject:
    if t.sym != nil:
      symToNif t.sym, parent, c
    else:
      c.b.addEmpty
  of tyForward: atom t, c
  of tyError: atom t, c
  of tyBuiltInTypeClass:
    # XXX See what to do with this.
    c.typeHead t:
      if t.kidsLen == 0 or t.genericHead.kind == tyNone:
        c.b.addEmpty
      else:
        toNifType t.genericHead, parent, c

  of tyUserTypeClass, tyConcept:
    # ^ old style concept.  ^ new style concept.
    if t.sym != nil:
      symToNif t.sym, parent, c
    else:
      atom t, c, "err"
  of tyUserTypeClassInst:
    # "instantiated" old style concept. Whatever that even means.
    if t.sym != nil:
      symToNif t.sym, parent, c
    else:
      atom t, c, "err"
  of tyCompositeTypeClass: toNifType t.last, parent, c
  of tyInferred: toNifType t.skipModifier, parent, c
  of tyAnything, tyStub: atom t, c
  of tyStatic:
    c.typeHead t:
      if t.hasElementType:
        toNifType t.skipModifier, parent, c
      else:
        c.b.addEmpty
      if t.n != nil:
        toNif t.n, parent, c
      else:
        c.b.addEmpty

proc magicCall(m: TMagic; n: PNode; c: var TranslationContext) =
  let (tag, bits) = magicToNifTag(m)
  if bits == NoMagic:
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  elif bits == ArrayType and n.len == 2:
    c.b.addTree(tag)
    # reverse order:
    toNif n[1], n, c
    toNif n[0], n, c
    c.b.endTree()
  elif bits == BecomesCall:
    c.b.addTree("call")
    c.b.addSymbol(tag)
    for i in 1..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  else:
    c.b.addTree(tag)
    if bits == TypedMagic:
      toNifType n.typ, n, c
    elif bits == TypedMagicOp1:
      toNifType n[1].typ, n, c
    for i in 1..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

proc genericParamToNif(n: PNode; parent: PNode; c: var TranslationContext) =
  if n.kind == nkSym:
    c.b.addTree("typevar")
    toNifDecl n, parent, c
    c.b.addEmpty # export
    c.b.addEmpty # pragmas
    let t = n.sym.typ
    if t != nil and t.len > 0:
      # generic constraints:
      toNifType t[0], n, c
    else:
      c.b.addEmpty
    c.b.addEmpty # value
    c.b.endTree()
  else:
    toNif n, parent, c

proc addExternName(sym: PSym; c: var TranslationContext) =
  if sym.loc.snippet != nil:
    c.b.addStrLit sym.loc.snippet
  else:
    c.b.addStrLit sym.name.s

proc takePragmasFromSym(sym: PSym; parent: PNode; c: var TranslationContext) =
  if sfImportc in sym.flags:
    c.b.withTree "importc":
      addExternName(sym, c)
  elif sfExportc in sym.flags:
    c.b.withTree "exportc":
      addExternName(sym, c)
  if sfCursor in sym.flags:
    c.b.addKeyw "cursor"
  if sfNoInit in sym.flags:
    c.b.addKeyw "noinit"
  if lfNoDecl in sym.loc.flags:
    c.b.addKeyw "nodecl"
  if sfNoReturn in sym.flags:
    c.b.addKeyw "noreturn"
  if sym.typ != nil:
    let t = sym.typ
    if t.callConv == ccNimCall and tfExplicitCallConv notin t.flags:
      discard "no calling convention to generate"
    else:
      c.b.addKeyw toNifTag(t.callConv)

  # XXX Add more pragmas here
  var isUntyped = false
  if sym.kind in routineKinds and sym.ast != nil and sym.ast[genericParamsPos].kind == nkGenericParams:
    isUntyped = true
  elif sym.kind == skTemplate:
    isUntyped = true
  if isUntyped:
    c.b.addKeyw "untyped"

proc toNifPragmas(n: PNode; parent: PNode; c: var TranslationContext; name: PNode) =
  if n == nil:
    if name.kind == nkSym:
      c.b.withTree "pragmas":
        takePragmasFromSym(name.sym, parent, c)
    else:
      c.b.addEmpty
  else:
    c.b.withTree "pragmas":
      for child in n:
        toNif child, n, c
      if name.kind == nkSym:
        takePragmasFromSym(name.sym, parent, c)

proc toNifProcBody(n: PNode; parent: PNode; c: var TranslationContext; name: PNode) =
  if n.kind == nkEmpty:
    c.b.addEmpty
  else:
    c.b.withTree "stmts":
      #if name.kind == nkSym and name.sym.kind notin {skTemplate, skIterator} and name.sym.typ != nil and
      var ast = parent
      if name.kind == nkSym and name.sym.ast != nil:
        ast = name.sym.ast
      var resultSym = PSym(nil)
      if resultPos < ast.len and ast[resultPos].kind == nkSym:
        resultSym = ast[resultPos].sym
        c.b.withTree "result":
          toNifDecl(ast[resultPos], parent, c)
          c.b.addEmpty # export marker
          if name.kind == nkSym and sfNoInit in name.sym.flags:
            c.b.withTree "pragmas":
              c.b.addKeyw "noinit"
          else:
            c.b.addEmpty # pragmas
          toNifType resultSym.typ, parent, c
          c.b.addEmpty # value
      var endsInReturn = false
      if n.kind == nkStmtList:
        for child in n:
          toNif child, n, c
          endsInReturn = child.kind == nkReturnStmt
      else:
        endsInReturn = n.kind == nkReturnStmt
        toNif n, parent, c
      if not endsInReturn and resultSym != nil:
        c.b.withTree "ret":
          symToNif resultSym, parent, c

proc toNif(n, parent: PNode; c: var TranslationContext; allowEmpty = false) =
  case n.kind
  of nkSym:
    symToNif(n.sym, parent, c)
  of nkNone:
    assert false, "unexpected nkNone"
  of nkEmpty:
    #assert allowEmpty, "unexpected nkEmpty"
    c.b.addEmpty 1
  of nkNilLit:
    relLineInfo(n, parent, c)
    c.b.addRaw "(nil)"
  of nkStrLit:
    relLineInfo(n, parent, c)
    c.b.addStrLit n.strVal
  of nkRStrLit:
    relLineInfo(n, parent, c)
    c.b.addStrLit n.strVal, "R"
  of nkTripleStrLit:
    relLineInfo(n, parent, c)
    c.b.addStrLit n.strVal, "T"
  of nkCharLit:
    relLineInfo(n, parent, c)
    c.b.addCharLit char(n.intVal)
  of nkIntLit:
    relLineInfo(n, parent, c, true)
    c.b.addIntLit n.intVal
  of nkInt8Lit:
    relLineInfo(n, parent, c, true)
    c.b.addIntLit n.intVal, "i8"
  of nkInt16Lit:
    relLineInfo(n, parent, c, true)
    c.b.addIntLit n.intVal, "i16"
  of nkInt32Lit:
    relLineInfo(n, parent, c, true)
    c.b.addIntLit n.intVal, "i32"
  of nkInt64Lit:
    relLineInfo(n, parent, c, true)
    c.b.addIntLit n.intVal, "i64"
  of nkUIntLit:
    relLineInfo(n, parent, c, true)
    c.b.addUIntLit cast[BiggestUInt](n.intVal)
  of nkUInt8Lit:
    relLineInfo(n, parent, c, true)
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u8"
  of nkUInt16Lit:
    relLineInfo(n, parent, c, true)
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u16"
  of nkUInt32Lit:
    relLineInfo(n, parent, c, true)
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u32"
  of nkUInt64Lit:
    relLineInfo(n, parent, c, true)
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u64"
  of nkFloatLit:
    relLineInfo(n, parent, c, true)
    c.b.addFloatLit n.floatVal
  of nkFloat32Lit:
    relLineInfo(n, parent, c, true)
    c.b.addFloatLit n.floatVal, "f32"
  of nkFloat64Lit:
    relLineInfo(n, parent, c, true)
    c.b.addFloatLit n.floatVal, "f64"
  of nkFloat128Lit:
    relLineInfo(n, parent, c, true)
    c.b.addFloatLit n.floatVal, "f128"
  of nkIdent:
    relLineInfo(n, parent, c, true)
    c.b.addIdent n.ident.s
  of nkTypeDef:
    relLineInfo(n, parent, c)
    c.b.addTree "type"
    let split = splitIdentDefName(n[0])

    toNifDecl(split.name, n, c)

    if split.visibility != nil:
      c.b.addRaw " x"
    else:
      c.b.addEmpty

    toNif(n[1], n, c, allowEmpty = true) # generics

    if split.pragma != nil:
      toNif(split.pragma, n, c)
    else:
      c.b.addEmpty

    let oldHasHoles = c.hasHoles
    c.hasHoles = split.name.kind == nkSym and split.name.sym.typ != nil and
      tfEnumHasHoles in split.name.sym.typ.flags
    for i in 2..<n.len:
      toNif(n[i], n, c, allowEmpty = true)
    c.hasHoles = oldHasHoles
    c.b.endTree()

  of nkTypeSection:
    for i in 0..<n.len:
      toNif(n[i], parent, c)

  of nkVarSection:
    c.section = VarL
    for i in 0..<n.len:
      toNif(n[i], parent, c)
  of nkLetSection:
    c.section = LetL
    for i in 0..<n.len:
      toNif(n[i], parent, c)
  of nkConstSection:
    c.section = ConstL
    for i in 0..<n.len:
      toNif(n[i], parent, c)

  of nkFormalParams:
    c.section = ParamL
    relLineInfo(n, parent, c)
    c.b.addTree("params")
    for i in 1..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
    # put return type outside of `(params)`:
    toNif(n[0], n, c, allowEmpty = true)
  of nkGenericParams:
    c.section = TypevarL
    relLineInfo(n, parent, c)
    c.b.addTree("typevars")
    for i in 0..<n.len:
      genericParamToNif(n[i], n, c)
    c.b.endTree()

  of nkIdentDefs, nkConstDef:
    # multiple ident defs are annoying so we remove them here:
    assert c.section != NiflerKind.None
    let last = n.len-1
    for i in 0..last - 2:
      relLineInfo(n[i], parent, c)
      c.b.addTree($c.section)
      # flatten it further:
      let split = splitIdentDefName(n[i])

      toNifDecl(split.name, n[i], c) # name

      if split.visibility != nil:
        c.b.addRaw " x"
      else:
        c.b.addEmpty

      toNifPragmas(split.pragma, n[i], c, split.name)

      if split.name.kind == nkSym and split.name.sym.typ != nil:
        toNifType split.name.sym.typ, n[i], c
      else:
        toNif(n[last-1], n[i], c, allowEmpty = true) # type

      toNif(n[last], n[i], c, allowEmpty = true) # value
      c.b.endTree()
  of nkDo:
    relLineInfo(n, parent, c)
    c.b.addTree("do")
    toNif(n[paramsPos], n, c, allowEmpty = true)
    toNif(n[bodyPos], n, c)
    c.b.endTree()
  of nkOfInherit:
    if n.len == 1:
      toNif(n[0], parent, c)
    else:
      relLineInfo(n, parent, c)
      c.b.addTree("par")
      for i in 0..<n.len:
        toNif(n[i], n, c)
      c.b.endTree()
  of nkOfBranch:
    relLineInfo(n, parent, c)
    c.b.addTree("of")
    c.b.addTree("ranges")
    for i in 0..<n.len-1:
      toNif(n[i], n, c)
    c.b.endTree()
    handleCaseIdentDefs(n[n.len-1], n, c)
    c.b.endTree()
  of nkElse:
    relLineInfo(n, parent, c)
    c.b.addTree("else")
    handleCaseIdentDefs(n[n.len-1], n, c)
    c.b.endTree()

  of nkStmtListType, nkStmtListExpr:
    relLineInfo(n, parent, c)
    c.b.addTree("expr")
    c.b.addTree("stmts")
    for i in 0..<n.len-1:
      toNif(n[i], n, c)
    c.b.endTree()
    if n.len > 0:
      toNif(n[n.len-1], n, c)
    else:
      c.b.addEmpty
    c.b.endTree()

  of nkProcTy, nkIteratorTy:
    relLineInfo(n, parent, c)
    if n.kind == nkProcTy:
      c.b.addTree("proctype")
    else:
      c.b.addTree("itertype")

    c.b.addEmpty 4 # 0: name
    # 1: export marker
    # 2: pattern
    # 3: generics

    if n.len > 0:
      toNif n[0], n, c, allowEmpty = true  # 4: params
    else:
      c.b.addEmpty

    if n.len > 1:
      toNif n[1], n, c, allowEmpty = true  # 5: pragmas
    else:
      c.b.addEmpty

    c.b.addEmpty 2 # 6: exceptions
    # 7: body
    c.b.endTree()

  of nkEnumTy:
    # EnumField
    #   SymDef "x"
    #   Empty      # export marker (always empty)
    #   Empty      # pragmas
    #   EnumType
    #   (Integer value, "string value")
    relLineInfo(n, parent, c)
    if n.len == 0:
      # typeclass, compiles to identifier for nimony
      c.b.addIdent "enum"
    else:
      if c.hasHoles:
        c.b.addTree("onum")
      else:
        c.b.addTree("enum")
      assert n[0].kind == nkEmpty
      c.b.addEmpty # base type
      for i in 1..<n.len:
        let it = n[i]

        var name: PNode
        var val: PNode
        var pragma: PNode

        if it.kind == nkEnumFieldDef:
          let first = it[0]
          if first.kind == nkPragmaExpr:
            name = first[0]
            pragma = first[1]
          else:
            name = it[0]
            pragma = nil
          val = it[1]
        elif it.kind == nkPragmaExpr:
          name = it[0]
          pragma = it[1]
          val = nil
        else:
          name = it
          pragma = nil
          val = nil

        relLineInfo(it, n, c)

        c.b.addTree("efld")

        toNifDecl name, it, c
        c.b.addEmpty # export marker

        toNifPragmas(pragma, it, c, name)

        c.b.addEmpty # type (filled by sema)

        if val == nil:
          c.b.addEmpty
        else:
          toNif(val, it, c)
        c.b.endTree()

      c.b.endTree()

  of nkProcDef, nkFuncDef, nkConverterDef, nkMacroDef, nkTemplateDef, nkIteratorDef, nkMethodDef:
    var name: PNode
    var visibility: PNode = nil
    if n[0].kind == nkPostfix:
      visibility = n[0][0]
      name = n[0][1]
    else:
      name = n[0]
      if name.kind == nkSym and sfExported in name.sym.flags:
        visibility = name # anything other than nil will do
    if name.kind == nkSym and
      ({sfForward, sfFromGeneric} * name.sym.flags != {} or c.handled.containsOrIncl(name.sym.id)):
      # forward declaration, skip the body:
      return

    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))

    toNifDecl(name, n, c)
    if visibility != nil:
      c.b.addRaw " x"
    else:
      c.b.addEmpty

    for i in 1..min(bodyPos, n.len-1):
      if i == pragmasPos:
        toNifPragmas(n[i], n, c, name)
      elif i == miscPos:
        c.b.addEmpty
      elif i == bodyPos:
        if name.kind == nkSym and name.sym.ast != nil:
          # use the semchecked body:
          toNifProcBody(c.graph.getBody(name.sym), n, c, name)
        else:
          toNifProcBody(n[i], n, c, name)
      else:
        toNif(n[i], n, c)
    c.b.endTree()

  of nkVarTuple:
    relLineInfo(n, parent, c)
    assert n[n.len-2].kind == nkEmpty
    c.b.addTree("unpackdecl")
    toNif(n[n.len-1], n, c, allowEmpty = true)

    c.b.addTree("unpacktup")
    for i in 0..<n.len-2:
      if n[i].kind == nkVarTuple:
        toNif(n[i], n, c)
      else:
        c.b.addTree($c.section)
        let split = splitIdentDefName(n[i])
        toNifDecl(split.name, n, c) # name

        if split.visibility != nil:
          c.b.addRaw " x"
        else:
          c.b.addEmpty

        if split.pragma != nil:
          toNif(split.pragma, n, c)
        else:
          c.b.addEmpty

        c.b.addEmpty 2 # type, value
        c.b.endTree()
    c.b.endTree()
    c.b.endTree()

  of nkForStmt:
    relLineInfo(n, parent, c)
    c.b.addTree("for")

    toNif(n[n.len-2], n, c) # iterator

    if n.len == 3 and n[0].kind == nkVarTuple:
      toVarTuple(n[0], n, c)
    else:
      c.b.addTree("unpackflat")
      for i in 0..<n.len-2:
        if n[i].kind == nkVarTuple:
          toVarTuple(n[i], n, c)
        else:
          c.b.addTree("let")

          toNifDecl(n[i], n, c) # name

          c.b.addEmpty 4 # export marker, pragmas, type, value
          c.b.endTree() # LetDecl
      c.b.endTree() # UnpackIntoFlat

    # for-loop-body:
    toNif(n[n.len-1], n, c)
    c.b.endTree()

  of nkRefTy, nkPtrTy:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

  of nkObjectTy:
    let kind = nodeKindTranslation(n.kind)
    c.section = FldL
    relLineInfo(n, parent, c)
    c.b.addTree(kind)
    for i in 0..<n.len-3:
      toNif(n[i], n, c, allowEmpty = true)
    # n.len-3: pragmas: must be empty (it is deprecated anyway)
    if n.len == 0:
      # object typeclass, has no children
      discard
    else:
      if n[n.len-3].kind != nkEmpty:
        c.b.addTree "err"
        c.b.endTree()

      toNif(n[n.len-2], n, c, allowEmpty = true)
      let last {.cursor.} = n[n.len-1]
      if last.kind == nkRecList:
        for child in last:
          toNif(child, n, c)
      elif last.kind != nkEmpty:
        toNif(last, n, c)
    c.b.endTree()

  of nkTupleTy, nkTupleClassTy:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      assert n[i].kind == nkIdentDefs
      let def = n[i]
      let last = def.len - 1
      for j in 0..last - 2:
        relLineInfo(def[j], parent, c)
        c.b.addTree "kv"
        let split = splitIdentDefName(def[j])

        toNifDecl(split.name, def[j], c) # name

        toNif(def[last-1], def[j], c, allowEmpty = true) # type

        c.b.endTree()
    c.b.endTree()

  of nkImportStmt, nkFromStmt, nkExportStmt, nkExportExceptStmt, nkImportAs, nkImportExceptStmt, nkIncludeStmt:
    # the usual recursion:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

    if c.depsEnabled:
      let oldLineInfoEnabled = c.lineInfoEnabled
      c.lineInfoEnabled = false
      let oldDepsEnabled = c.depsEnabled
      swap c.b, c.deps
      c.depsEnabled = false
      toNif(n, nil, c)
      c.depsEnabled = oldDepsEnabled
      swap c.b, c.deps
      c.lineInfoEnabled = oldLineInfoEnabled
  of nkCallKinds:
    let oldDepsEnabled = c.depsEnabled
    if n.len > 0 and n[0].kind == nkIdent and n[0].ident.s == "runnableExamples":
      c.depsEnabled = false
    relLineInfo(n, parent, c)
    if n.len > 0 and n[0].kind == nkSym and n[0].sym.magic != mNone:
      magicCall n[0].sym.magic, n, c
    else:
      c.b.addTree(nodeKindTranslation(n.kind))
      for i in 0..<n.len:
        toNif(n[i], n, c)
      c.b.endTree()
    c.depsEnabled = oldDepsEnabled
  of nkReturnStmt:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    if n.len > 0 and n[0].kind in {nkAsgn, nkFastAsgn}:
      toNif(n[0][1], n, c)
    else:
      for i in 0..<n.len:
        toNif(n[i], n, c, allowEmpty = true)
    c.b.endTree()
  of nkDiscardStmt, nkBreakStmt, nkContinueStmt, nkRaiseStmt,
      nkBlockStmt, nkBlockExpr, nkBlockType, nkTypeClassTy, nkAsmStmt:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c, allowEmpty = true)
    c.b.endTree()
  of nkExceptBranch:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    if n.len == 1:
      c.b.addEmpty 1
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  of nkCurly:
    relLineInfo(n, parent, c)
    c.b.addTree("setconstr")
    toNifType(n.typ, n, c)
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  of nkBracket:
    relLineInfo(n, parent, c)
    c.b.addTree("aconstr")
    toNifType(n.typ, n, c)
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  of nkTupleConstr:
    relLineInfo(n, parent, c)
    c.b.addTree("tupconstr")
    toNifType(n.typ, n, c)
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  of nkCast:
    relLineInfo(n, parent, c)
    c.b.addTree("cast")
    toNifType(n.typ, n, c)
    toNif(n[1], n, c)
    c.b.endTree()
  of nkHiddenSubConv, nkHiddenStdConv, nkConv:
    # XXX Special case conversions to and from OpenArray which are not builtin for Nimony
    relLineInfo(n, parent, c)
    c.b.addTree("conv")
    toNifType(n.typ, n, c)
    toNif(n[1], n, c)
    c.b.endTree()
  of nkCheckedFieldExpr:
    toNif(n[0], n, c)
  of nkObjUpConv, nkObjDownConv:
    let diff = inheritanceDiff(n.typ, n[0].typ)
    relLineInfo(n, parent, c)
    c.b.addTree("baseobj")
    toNifType(n.typ, n, c)
    c.b.addIntLit diff
    toNif(n[0], n, c)
    c.b.endTree()
  of nkObjConstr:
    relLineInfo(n, parent, c)
    c.b.addTree("oconstr")
    # starts with the type as we need it. But maybe it got inferred:
    var start = 0
    if n.len > 0 and n[0].kind == nkEmpty:
      toNifType(n.typ, n, c)
      start = 1
    for i in start..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  of nkStringToCString:
    relLineInfo(n, parent, c)
    c.b.addTree("call")
    c.b.addSymbol("toCString.0." & SystemModuleSuffix)
    c.b.withTree "haddr":
      toNif(n[0], n, c)
    c.b.endTree()
  of nkCStringToString:
    relLineInfo(n, parent, c)
    c.b.addTree("call")
    c.b.addSymbol("fromCString.0." & SystemModuleSuffix)
    toNif(n[0], n, c)
    c.b.endTree()
  else:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

proc close*(c: var TranslationContext) =
  c.b.endTree()
  c.b.close()
  if c.depsEnabled:
    c.deps.endTree()
    c.deps.close()

proc toNifStmts(n: PNode, c: var TranslationContext) =
  if n.kind == nkStmtList:
    for i in 0..<n.len:
      toNif(n[i], nil, c)
  else:
    toNif(n, nil, c)

proc closeNif*(graph: ModuleGraph; bModule: PPassContext; finalNode: PNode) =
  let m = NifModule(bModule)
  if finalNode != nil and finalNode.kind != nkEmpty:
    toNifStmts(finalNode, m.tc)
  m.tc.close()

  # Rename the file to `.nim2.nif` as file renames are atomic on the OSes we care about.
  moveFile(m.outfile, m.outfile.changeFileExt(".nim2.nif"))

proc setupNifgen*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  let conf = graph.config
  let nimcacheDir = getNimcacheDir(conf).string

  # Ensure nimcache directory exists
  if not dirExists(nimcacheDir):
    createDir(nimcacheDir)

  var c = TranslationContext(conf: conf,
    portablePaths: true, depsEnabled: false, lineInfoEnabled: true, graph: graph)

  # `nim nif` can run in parallel writing to the same nimcache/. So we produce
  # a unique name here and then rename the file in `closeNif` to `.nim2.nif` as
  # file renames are atomic on the OSes we care about:
  let outfile = nimcacheDir / modname(c, FileIndex module.position) & "." & c.projectHash & ".nif"

  c.b = nifbuilder.open(outfile)
  if c.depsEnabled:
    c.deps = nifbuilder.open(outfile.changeFileExt(".nim2.deps.nif"))

  c.b.addHeader "nim2", "nim-parsed"
  c.b.addRaw "(.original "
  c.b.addStrLit module.name.s
  c.b.addRaw ")\n"
  c.b.addTree "stmts"
  if c.depsEnabled:
    c.deps.addHeader "nim2", "nim-deps"
    c.deps.addTree "stmts"

  var m = NifModule(graph: graph, module: module, idgen: idgen, tc: c, outfile: outfile)
  result = m

proc genTopLevelNif*(bModule: PPassContext; n: PNode) =
  let m = NifModule(bModule)
  toNifStmts(n, m.tc)
