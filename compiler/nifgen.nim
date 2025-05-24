#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the NIF code generator.

import
  ast, astalgo, modulegraphs, options, pathutils, lineinfos, idents, msgs

import std / [assertions, syncio, os]
import "../dist/nimony/src/lib" / nifbuilder
import "../dist/nimony/src/models" / nifler_tags

## This was copied from Nifler's bridge.nim. However, this code will evolve
## in a different direction as it needs to translate the semchecked AST which
## is way more complex. For example, all magics need to be special cased.

type
  TranslationContext = object
    conf: ConfigRef
    section: NiflerKind
    b, deps: Builder
    portablePaths: bool
    depsEnabled, lineInfoEnabled: bool

  NifModule* = ref object of PPassContext
    graph*: ModuleGraph
    module*: PSym
    tc: TranslationContext

proc nodeKindTranslation(k: TNodeKind): NiflerKind =
  # many of these kinds are never returned by the parser.
  case k
  of nkCommand: CmdL
  of nkCall: CallL
  of nkCallStrLit: CallstrlitL
  of nkInfix: InfixL
  of nkPrefix: PrefixL
  of nkHiddenCallConv: ErrL
  of nkExprEqExpr: VvL
  of nkExprColonExpr: KvL
  of nkPar: ParL
  of nkObjConstr: OconstrL
  of nkCurly: CurlyL
  of nkCurlyExpr: CurlyatL
  of nkBracket: BracketL
  of nkBracketExpr: AtL
  of nkPragmaBlock, nkPragmaExpr: PragmaxL
  of nkDotExpr: DotL
  of nkAsgn, nkFastAsgn: AsgnL
  of nkIfExpr, nkIfStmt: IfL
  of nkWhenStmt, nkRecWhen: WhenL
  of nkWhileStmt: WhileL
  of nkCaseStmt, nkRecCase: CaseL
  of nkForStmt: ForL
  of nkDiscardStmt: DiscardL
  of nkBreakStmt: BreakL
  of nkReturnStmt: RetL
  of nkElifExpr, nkElifBranch: ElifL
  of nkElseExpr, nkElse: ElseL
  of nkOfBranch: OfL
  of nkCast: CastL
  of nkLambda: ProcL
  of nkAccQuoted: QuotedL
  of nkTableConstr: TabconstrL
  of nkStmtListType, nkStmtListExpr, nkStmtList, nkRecList, nkArgList: StmtsL
  of nkBlockStmt, nkBlockExpr, nkBlockType: BlockL
  of nkStaticStmt: StaticstmtL
  of nkBind, nkBindStmt: BindL
  of nkMixinStmt: MixinL
  of nkAddr: AddrL
  of nkGenericParams: TypevarsL
  of nkFormalParams: ParamsL
  of nkImportAs: ImportasL
  of nkRaiseStmt: RaiseL
  of nkContinueStmt: ContinueL
  of nkYieldStmt: YldL
  of nkProcDef: ProcL
  of nkFuncDef: FuncL
  of nkMethodDef: MethodL
  of nkConverterDef: ConverterL
  of nkMacroDef: MacroL
  of nkTemplateDef: TemplateL
  of nkIteratorDef: IteratorL
  of nkExceptBranch: ExceptL
  of nkTypeOfExpr: TypeofL
  of nkFinally: FinL
  of nkTryStmt: TryL
  of nkImportStmt: ImportL
  of nkImportExceptStmt: ImportexceptL
  of nkIncludeStmt: IncludeL
  of nkExportStmt: ExportL
  of nkExportExceptStmt: ExportexceptL
  of nkFromStmt: FromimportL
  of nkPragma: PragmasL
  of nkAsmStmt: AsmL
  of nkDefer: DeferL
  of nkUsingStmt: UsingL
  of nkCommentStmt: CommentL
  of nkObjectTy: ObjectL
  of nkTupleTy, nkTupleClassTy: TupleL
  of nkTypeClassTy: ConceptL
  of nkStaticTy: StaticL
  of nkRefTy: RefL
  of nkPtrTy: PtrL
  of nkVarTy: MutL
  of nkDistinctTy: DistinctL
  of nkIteratorTy: ItertypeL
  of nkEnumTy: EnumL
  #of nkEnumFieldDef: EnumFieldDecl
  of nkTupleConstr: TupL
  of nkOutTy: OutL
  else: ErrL

template addTree(b: var Builder; tag: NiflerKind) = b.addTree $tag

template withTree(b: var Builder; tag: NiflerKind; body: untyped) =
  b.addTree tag
  body
  b.endTree()

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
  b.withTree SufL:
    b.addIntLit u
    b.addStrLit suffix

proc addUIntLit*(b: var Builder; u: BiggestUInt; suffix: string) =
  assert suffix.len > 0
  b.withTree SufL:
    b.addUIntLit u
    b.addStrLit suffix

proc addFloatLit*(b: var Builder; u: BiggestFloat; suffix: string) =
  assert suffix.len > 0
  b.withTree SufL:
    b.addFloatLit u
    b.addStrLit suffix

type IdentDefName = object
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

proc toNif*(n, parent: PNode; c: var TranslationContext; allowEmpty = false)

proc symToNif(s: PSym; c: var TranslationContext; isDef = false) =
  var m = s.name.s & '.' & $s.disamb
  let ow = s.skipGenericOwner()
  if ow.kind == skModule:
    m.add '.'
    let fp = toFullPath(c.conf, FileIndex ow.position)
    var suf = c.toSuffix.getOrDefault(fp)
    if suf.len == 0:
      suf = moduleSuffix(fp)
      m.add suf
      c.toSuffix[fp] = ensureMove suf
    else:
      m.add suf
  if isDef:
    c.b.addSymbolDef m
  else:
    c.b.addSymbol m

proc toNifDecl(n, parent: PNode; c: var TranslationContext) =
  if n.kind == nkSym:
    relLineInfo(n, parent, c)
    symToNif(n.sym, c, true)
  else:
    toNif n, parent, c

proc toVarTuple(v: PNode, n: PNode; c: var TranslationContext) =
  c.b.addTree(UnpacktupL)
  for i in 0..<v.len-1: # ignores typedesc
    c.b.addTree(LetL)

    toNifDecl(v[i], n, c) # name

    c.b.addEmpty 4 # export marker, pragmas, type, value
    c.b.endTree() # LetDecl
  c.b.endTree() # UnpackIntoTuple

proc handleCaseIdentDefs(n, parent: PNode; c: var TranslationContext) =
  if n.kind == nkIdentDefs and n.len > 3:
    # multiple ident defs, we need to add StmtsL
    c.b.addTree(StmtsL)
    toNif(n, parent, c)
    c.b.endTree()
  else:
    toNif(n, parent, c)

const
  NoMagic = -1
  NewOperator = -2
  TypedMagic = -3
  TypedMagicOp1 = -4

proc toNifTag(s: TMagic): (string, int) =
  case s
  of mNone: ("bug", NoMagic)
  of mDefined: ("defined", 0)
  of mDeclared: ("declared", 0)
  of mDeclaredInScope: ("declaredinscope", 0)
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
  of mStatic: ("staticm", NoMagic)
  of mParseExprToAst: ("parseexprtoast", NoMagic)
  of mParseStmtToAst: ("parsestmttoast", NoMagic)
  of mExpandToAst: ("expandtoast", NoMagic)
  of mQuoteAst: ("quoteast", NoMagic)
  of mInc: ("inc", NoMagic)
  of mDec: ("dec", NoMagic)
  of mOrd: ("ord", NoMagic)
  of mNew: ("new", NewOperator)
  of mNewFinalize: ("newfinalize", NewOperator)
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
  of mSucc: ("succ", TypedMagic)
  of mPred: ("pred", TypedMagic)
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
  of mXor: ("xor", TypedMagic)
  of mEqCString: ("eq", TypedMagicOp1)
  of mEqProc: ("eq", TypedMagicOp1)
  of mUnaryMinusI: ("neg", 0)
  of mUnaryMinusI64: ("neg", 0)
  of mAbsI: ("abs", NoMagic)
  of mNot: ("not", 0)
  of mUnaryPlusI: ("unaryplus", NoMagic)
  of mBitnotI: ("bitnot", TypedMagic)
  of mUnaryPlusF64: ("unaryplusf64", NoMagic)
  of mUnaryMinusF64: ("neg", 0)
  of mCharToStr: ("chartostr", 0)
  of mBoolToStr: ("booltostr", 0)
  of mCStrToStr: ("cstrtostr", 0)
  of mStrToStr: ("strtostr", 0)
  of mEnumToStr: ("enumtostr", 0)
  of mAnd: ("and", 0)
  of mOr: ("or", 0)
  of mImplies: ("implies", 0)
  of mIff: ("iff", 0)
  of mExists: ("exists", 0)
  of mForall: ("forall", 0)
  of mOld: ("old", 0)
  of mEqStr: ("eqstr", 0)
  of mLeStr: ("lestr", 0)
  of mLtStr: ("ltstr", 0)
  of mEqSet: ("eqset", 0)
  of mLeSet: ("leset", 0)
  of mLtSet: ("ltset", 0)
  of mMulSet: ("mulset", 0)
  of mPlusSet: ("plusset", 0)
  of mMinusSet: ("minusset", 0)
  of mXorSet: ("xorset", 0)
  of mConStrStr: ("constrstr", 0)
  of mSlice: ("slice", 0)
  of mDotDot: ("dotdot", 0)
  of mFields: ("fields", 0)
  of mFieldPairs: ("fieldpairs", 0)
  of mOmpParFor: ("ompparfor", 0)
  of mAppendStrCh: ("addstrch", 0)
  of mAppendStrStr: ("addstrstr", 0)
  of mAppendSeqElem: ("addseqelem", 0)
  of mInSet: ("contains", 0)
  of mRepr: ("repr", 0)
  of mExit: ("exit", 0)
  of mSetLengthStr: ("setlenstr", 0)
  of mSetLengthSeq: ("setlenseq", 0)
  of mIsPartOf: ("ispartof", 0)
  of mAstToStr: ("asttostr", 0)
  of mParallel: ("parallel", 0)
  of mSwap: ("swap", 0)
  of mIsNil: ("isnil", 0)
  of mArrToSeq: ("arrtoseq", 0)
  of mOpenArrayToSeq: ("openarraytoseq", 0)
  of mNewString: ("newstring", 0)
  of mNewStringOfCap: ("newstringofcap", 0)
  of mParseBiggestFloat: ("parsebiggestfloat", 0)
  of mMove: ("move", 0)
  of mEnsureMove: ("ensuremove", 0)
  of mWasMoved: ("wasmoved", 0)
  of mDup: ("dup", 0)
  of mDestroy: ("destroy", 0)
  of mTrace: ("trace", 0)
  of mDefault: ("default", 0)
  of mUnown: ("unown", 0)
  of mFinished: ("finished", 0)
  of mIsolate: ("isolate", 0)
  of mAccessEnv: ("accessenv", 0)
  of mAccessTypeField: ("accesstypefield", 0)
  of mArray: ("array", 0)
  of mOpenArray: ("openarray", 0)
  of mRange: ("rangem", 0)
  of mSet: ("set", 0)
  of mSeq: ("seq", 0)
  of mVarargs: ("varargs", 0)
  of mRef: ("ref", 0)
  of mPtr: ("ptr", 0)
  of mVar: ("varm", 0)
  of mDistinct: ("distinct", 0)
  of mVoid: ("void", 0)
  of mTuple: ("tuple", 0)
  of mOrdinal: ("ordinal", 0)
  of mIterableType: ("iterabletype", 0)
  of mInt: ("int", 0)
  of mInt8: ("int8", 0)
  of mInt16: ("int16", 0)
  of mInt32: ("int32", 0)
  of mInt64: ("int64", 0)
  of mUInt: ("uint", 0)
  of mUInt8: ("uint8", 0)
  of mUInt16: ("uint16", 0)
  of mUInt32: ("uint32", 0)
  of mUInt64: ("uint64", 0)
  of mFloat: ("float", 0)
  of mFloat32: ("float32", 0)
  of mFloat64: ("float64", 0)
  of mFloat128: ("float128", 0)
  of mBool: ("bool", 0)
  of mChar: ("char", 0)
  of mString: ("string", 0)
  of mCstring: ("cstring", 0)
  of mPointer: ("pointer", 0)
  of mNil: ("nil", 0)
  of mExpr: ("exprm", 0)
  of mStmt: ("stmtm", 0)
  of mTypeDesc: ("typedesc", 0)
  of mVoidType: ("voidtype", 0)
  of mPNimrodNode: ("nimnode", 0)
  of mSpawn: ("spawn", 0)
  of mDeepCopy: ("deepcopy", 0)
  of mIsMainModule: ("ismainmodule", 0)
  of mCompileDate: ("compiledate", 0)
  of mCompileTime: ("compiletime", 0)
  of mProcCall: ("proccall", 0)
  of mCpuEndian: ("cpuendian", 0)
  of mHostOS: ("hostos", 0)
  of mHostCPU: ("hostcpu", 0)
  of mBuildOS: ("buildos", 0)
  of mBuildCPU: ("buildcpu", 0)
  of mAppType: ("apptype", 0)
  of mCompileOption: ("compileoption", 0)
  of mCompileOptionArg: ("compileoptionarg", 0)
  of mNLen: ("nlen", 0)
  of mNChild: ("nchild", 0)
  of mNSetChild: ("nsetchild", 0)
  of mNAdd: ("nadd", 0)
  of mNAddMultiple: ("naddmultiple", 0)
  of mNDel: ("ndel", 0)
  of mNKind: ("nkind", 0)
  of mNSymKind: ("nsymkind", 0)
  of mNccValue: ("nccvalue", 0)
  of mNccInc: ("nccinc", 0)
  of mNcsAdd: ("ncsadd", 0)
  of mNcsIncl: ("ncsincl", 0)
  of mNcsLen: ("ncslen", 0)
  of mNcsAt: ("ncsat", 0)
  of mNctPut: ("nctput", 0)
  of mNctLen: ("nctlen", 0)
  of mNctGet: ("nctget", 0)
  of mNctHasNext: ("ncthasnext", 0)
  of mNctNext: ("nctnext", 0)
  of mNIntVal: ("nintval", 0)
  of mNFloatVal: ("nfloatval", 0)
  of mNSymbol: ("nsymbol", 0)
  of mNIdent: ("nident", 0)
  of mNGetType: ("ngettype", 0)
  of mNStrVal: ("nstrval", 0)
  of mNSetIntVal: ("nsetintval", 0)
  of mNSetFloatVal: ("nsetfloatval", 0)
  of mNSetSymbol: ("nsetsymbol", 0)
  of mNSetIdent: ("nsetident", 0)
  of mNSetStrVal: ("nsetstrval", 0)
  of mNLineInfo: ("nlineinfo", 0)
  of mNNewNimNode: ("nnewnimnode", 0)
  of mNCopyNimNode: ("ncopynimnode", 0)
  of mNCopyNimTree: ("ncopynimtree", 0)
  of mStrToIdent: ("strtoident", 0)
  of mNSigHash: ("nsighash", 0)
  of mNSizeOf: ("nsizeof", 0)
  of mNBindSym: ("nbindsym", 0)
  of mNCallSite: ("ncallsite", 0)
  of mEqIdent: ("eqident", 0)
  of mEqNimrodNode: ("eqnimnode", 0)
  of mSameNodeType: ("samenodetype", 0)
  of mGetImpl: ("getimpl", 0)
  of mNGenSym: ("ngensym", 0)
  of mNHint: ("nhint", 0)
  of mNWarning: ("nwarning", 0)
  of mNError: ("nerror", 0)
  of mInstantiationInfo: ("instantiationinfo", 0)
  of mGetTypeInfo: ("gettypeinfo", 0)
  of mGetTypeInfoV2: ("gettypeinfov2", 0)
  of mNimvm: ("nimvm", 0)
  of mIntDefine: ("intdefine", 0)
  of mStrDefine: ("strdefine", 0)
  of mBoolDefine: ("booldefine", 0)
  of mGenericDefine: ("genericdefine", 0)
  of mRunnableExamples: ("runnableexamples", 0)
  of mException: ("exception", 0)
  of mBuiltinType: ("builtintype", 0)
  of mSymOwner: ("symowner", 0)
  of mUncheckedArray: ("uncheckedarray", 0)
  of mGetImplTransf: ("getimpltransf", 0)
  of mSymIsInstantiationOf: ("symisinstantiationof", 0)
  of mNodeId: ("nodeid", 0)
  of mPrivateAccess: ("privateaccess", 0)
  of mZeroDefault: ("zerodefault", 0)

proc magicCall(m: TMagic; n: PNode; c: var TranslationContext) =
  let (tag, bits) = toNifTag(m)
  if bits == NoMagic:
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
  else:
    c.b.addTree(tag)
    if bits == TypedMagic:
      toNifType n.typ, c
    for i in 1..<n.len:
      toNif(n[i], n, c)
    c.b.endTree

proc toNif*(n, parent: PNode; c: var TranslationContext; allowEmpty = false) =
  case n.kind
  of nkSym:
    symToNif(n.sym, c)
  of nkNone:
    assert false, "unexpected nkNone"
  of nkEmpty:
    assert allowEmpty, "unexpected nkEmpty"
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
    c.b.addTree TypeL
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

    for i in 2..<n.len:
      toNif(n[i], n, c, allowEmpty = true)
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
    c.b.addTree(ParamsL)
    for i in 1..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()
    # put return type outside of `(params)`:
    toNif(n[0], n, c, allowEmpty = true)
  of nkGenericParams:
    c.section = TypevarL
    relLineInfo(n, parent, c)
    c.b.addTree(TypevarsL)
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

  of nkIdentDefs, nkConstDef:
    # multiple ident defs are annoying so we remove them here:
    assert c.section != NiflerKind.None
    let last = n.len-1
    for i in 0..last - 2:
      relLineInfo(n[i], parent, c)
      c.b.addTree(c.section)
      # flatten it further:
      let split = splitIdentDefName(n[i])

      toNifDecl(split.name, n[i], c) # name

      if split.visibility != nil:
        c.b.addRaw " x"
      else:
        c.b.addEmpty

      if split.pragma != nil:
        toNif(split.pragma, n[i], c)
      else:
        c.b.addEmpty

      toNif(n[last-1], n[i], c, allowEmpty = true) # type

      toNif(n[last], n[i], c, allowEmpty = true) # value
      c.b.endTree()
  of nkDo:
    relLineInfo(n, parent, c)
    c.b.addTree(DoL)
    toNif(n[paramsPos], n, c, allowEmpty = true)
    toNif(n[bodyPos], n, c)
    c.b.endTree()
  of nkOfInherit:
    if n.len == 1:
      toNif(n[0], parent, c)
    else:
      relLineInfo(n, parent, c)
      c.b.addTree(ParL)
      for i in 0..<n.len:
        toNif(n[i], n, c)
      c.b.endTree()
  of nkOfBranch:
    relLineInfo(n, parent, c)
    c.b.addTree(OfL)
    c.b.addTree(RangesL)
    for i in 0..<n.len-1:
      toNif(n[i], n, c)
    c.b.endTree()
    handleCaseIdentDefs(n[n.len-1], n, c)
    c.b.endTree()
  of nkElse:
    relLineInfo(n, parent, c)
    c.b.addTree(ElseL)
    handleCaseIdentDefs(n[n.len-1], n, c)
    c.b.endTree()

  of nkStmtListType, nkStmtListExpr:
    relLineInfo(n, parent, c)
    c.b.addTree(ExprL)
    c.b.addTree(StmtsL)
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
      c.b.addTree(ProctypeL)
    else:
      c.b.addTree(ItertypeL)

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
      c.b.addTree(EnumL)
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

        c.b.addTree(EfldL)

        toNifDecl name, it, c
        c.b.addEmpty # export marker

        if pragma == nil:
          c.b.addEmpty
        else:
          toNif(pragma, it, c)

        c.b.addEmpty # type (filled by sema)

        if val == nil:
          c.b.addEmpty
        else:
          toNif(val, it, c)
        c.b.endTree()

      c.b.endTree()

  of nkProcDef, nkFuncDef, nkConverterDef, nkMacroDef, nkTemplateDef, nkIteratorDef, nkMethodDef:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))

    var name: PNode
    var visibility: PNode = nil
    if n[0].kind == nkPostfix:
      visibility = n[0][0]
      name = n[0][1]
    else:
      name = n[0]

    toNifDecl(name, n, c)
    if visibility != nil:
      c.b.addRaw " x"
    else:
      c.b.addEmpty

    for i in 1..<n.len:
      toNif(n[i], n, c, allowEmpty = true)
    c.b.endTree()

  of nkVarTuple:
    relLineInfo(n, parent, c)
    assert n[n.len-2].kind == nkEmpty
    c.b.addTree(UnpackdeclL)
    toNif(n[n.len-1], n, c, allowEmpty = true)

    c.b.addTree(UnpacktupL)
    for i in 0..<n.len-2:
      if n[i].kind == nkVarTuple:
        toNif(n[i], n, c)
      else:
        c.b.addTree(c.section)
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
    c.b.addTree(ForL)

    toNif(n[n.len-2], n, c) # iterator

    if n.len == 3 and n[0].kind == nkVarTuple:
      toVarTuple(n[0], n, c)
    else:
      c.b.addTree(UnpackflatL)
      for i in 0..<n.len-2:
        if n[i].kind == nkVarTuple:
          toVarTuple(n[i], n, c)
        else:
          c.b.addTree(LetL)

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
        c.b.addTree ErrL
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
        c.b.addTree(KvL)
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
  of nkDiscardStmt, nkBreakStmt, nkContinueStmt, nkReturnStmt, nkRaiseStmt,
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
  else:
    relLineInfo(n, parent, c)
    c.b.addTree(nodeKindTranslation(n.kind))
    for i in 0..<n.len:
      toNif(n[i], n, c)
    c.b.endTree()

proc initTranslationContext*(conf: ConfigRef; outfile: string; portablePaths, depsEnabled: bool): TranslationContext =
  result = TranslationContext(conf: conf, b: nifbuilder.open(outfile),
    portablePaths: portablePaths, depsEnabled: depsEnabled, lineInfoEnabled: true)
  if depsEnabled:
    result.deps = nifbuilder.open(outfile.changeFileExt(".deps.nif"))

proc close*(c: var TranslationContext) =
  c.b.close()
  if c.depsEnabled:
    c.deps.endTree()
    c.deps.close()

proc moduleToIr*(n: PNode; c: var TranslationContext) =
  c.b.addHeader "Nifler", "nim-parsed"
  if c.depsEnabled:
    c.deps.addHeader "Nifler", "nim-deps"
    c.deps.addTree StmtsL
  toNif(n, nil, c)

proc closeNif*(graph: ModuleGraph; bModule: PPassContext; finalNode: PNode) =
  let m = NifModule(bModule)
  moduleToIr(finalNode, m.tc)
  m.tc.close()

proc setupNifgen*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  let conf = graph.config
  let modname = module.name.s
  let nimcacheDir = getNimcacheDir(conf).string
  let outfile = nimcacheDir / modname & ".nif"

  # Ensure nimcache directory exists
  if not dirExists(nimcacheDir):
    createDir(nimcacheDir)

  var tc = initTranslationContext(conf, outfile, portablePaths = true, depsEnabled = false)
  var m = NifModule(graph: graph, module: module, idgen: idgen, tc: tc)
  result = m

proc genTopLevelNif*(bModule: PPassContext; finalNode: PNode) =
  # This is called for each top-level node, but we'll handle everything in closeNif
  discard
