//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ast;

// abstract syntax tree + symbol table

interface

{$include 'config.inc'}

uses
  nsystem, charsets, msgs, nhashes,
  nversion, options, strutils, crc, ropes, idents, lists;

const
  ImportTablePos = 0;
  ModuleTablePos = 1;

type
  TCallingConvention = (
    ccDefault,   // proc has no explicit calling convention
    ccStdCall,   // procedure is stdcall
    ccCDecl,     // cdecl
    ccSafeCall,  // safecall
    ccSysCall,   // system call
    ccInline,    // proc should be inlined
    ccNoInline,  // proc should not be inlined
    ccFastCall,  // fastcall (pass parameters in registers)
    ccClosure,   // proc has a closure
    ccNoConvention // needed for generating proper C procs sometimes
  );

const
  CallingConvToStr: array [TCallingConvention] of string = (
    '', 'stdcall', 'cdecl', 'safecall', 'syscall', 'inline', 'noinline',
    'fastcall', 'closure', 'noconv');

(*[[[cog
def toEnum(name, elems, prefixlen=0):
  body = ""
  strs = ""
  prefix = ""
  counter = 0
  for e in elems:
    if counter % 4 == 0: prefix = "\n    "
    else: prefix = ""
    body = body + prefix + e + ', '
    strs = strs + prefix + "'%s', " % e[prefixlen:]
    counter = counter + 1

  return ("type\n  T%s = (%s);\n  T%ss = set of T%s;\n"
            % (name, body[:-2], name, name),
          "const\n  %sToStr: array [T%s] of string = (%s);\n"
            % (name, name, strs[:-2]))

enums = eval(open("data/ast.yml").read())
for key, val in enums.items():
  (a, b) = toEnum(key, val)
  cog.out(a)
  cog.out(b)
]]]*)
type
  TNodeKind = (
    nkNone, nkEmpty, nkIdent, nkSym, 
    nkType, nkCharLit, nkIntLit, nkInt8Lit, 
    nkInt16Lit, nkInt32Lit, nkInt64Lit, nkFloatLit, 
    nkFloat32Lit, nkFloat64Lit, nkStrLit, nkRStrLit, 
    nkTripleStrLit, nkMetaNode, nkNilLit, nkDotCall, 
    nkCommand, nkCall, nkCallStrLit, nkExprEqExpr, 
    nkExprColonExpr, nkIdentDefs, nkVarTuple, nkInfix, 
    nkPrefix, nkPostfix, nkPar, nkCurly, 
    nkBracket, nkBracketExpr, nkPragmaExpr, nkRange, 
    nkDotExpr, nkCheckedFieldExpr, nkDerefExpr, nkIfExpr, 
    nkElifExpr, nkElseExpr, nkLambda, nkAccQuoted, 
    nkTableConstr, nkQualified, nkBind, nkSymChoice, 
    nkHiddenStdConv, nkHiddenSubConv, nkHiddenCallConv, nkConv, 
    nkCast, nkAddr, nkHiddenAddr, nkHiddenDeref, 
    nkObjDownConv, nkObjUpConv, nkChckRangeF, nkChckRange64, 
    nkChckRange, nkStringToCString, nkCStringToString, nkPassAsOpenArray, 
    nkAsgn, nkFastAsgn, nkGenericParams, nkFormalParams, 
    nkOfInherit, nkModule, nkProcDef, nkMethodDef, 
    nkConverterDef, nkMacroDef, nkTemplateDef, nkIteratorDef, 
    nkOfBranch, nkElifBranch, nkExceptBranch, nkElse, 
    nkMacroStmt, nkAsmStmt, nkPragma, nkIfStmt, 
    nkWhenStmt, nkForStmt, nkWhileStmt, nkCaseStmt, 
    nkVarSection, nkConstSection, nkConstDef, nkTypeSection, 
    nkTypeDef, nkYieldStmt, nkTryStmt, nkFinally, 
    nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt, 
    nkBlockStmt, nkDiscardStmt, nkStmtList, nkImportStmt, 
    nkFromStmt, nkIncludeStmt, nkCommentStmt, nkStmtListExpr, 
    nkBlockExpr, nkStmtListType, nkBlockType, nkTypeOfExpr, 
    nkObjectTy, nkTupleTy, nkRecList, nkRecCase, 
    nkRecWhen, nkRefTy, nkPtrTy, nkVarTy, 
    nkDistinctTy, nkProcTy, nkEnumTy, nkEnumFieldDef, 
    nkReturnToken);
  TNodeKinds = set of TNodeKind;
const
  NodeKindToStr: array [TNodeKind] of string = (
    'nkNone', 'nkEmpty', 'nkIdent', 'nkSym', 
    'nkType', 'nkCharLit', 'nkIntLit', 'nkInt8Lit', 
    'nkInt16Lit', 'nkInt32Lit', 'nkInt64Lit', 'nkFloatLit', 
    'nkFloat32Lit', 'nkFloat64Lit', 'nkStrLit', 'nkRStrLit', 
    'nkTripleStrLit', 'nkMetaNode', 'nkNilLit', 'nkDotCall', 
    'nkCommand', 'nkCall', 'nkCallStrLit', 'nkExprEqExpr', 
    'nkExprColonExpr', 'nkIdentDefs', 'nkVarTuple', 'nkInfix', 
    'nkPrefix', 'nkPostfix', 'nkPar', 'nkCurly', 
    'nkBracket', 'nkBracketExpr', 'nkPragmaExpr', 'nkRange', 
    'nkDotExpr', 'nkCheckedFieldExpr', 'nkDerefExpr', 'nkIfExpr', 
    'nkElifExpr', 'nkElseExpr', 'nkLambda', 'nkAccQuoted', 
    'nkTableConstr', 'nkQualified', 'nkBind', 'nkSymChoice', 
    'nkHiddenStdConv', 'nkHiddenSubConv', 'nkHiddenCallConv', 'nkConv', 
    'nkCast', 'nkAddr', 'nkHiddenAddr', 'nkHiddenDeref', 
    'nkObjDownConv', 'nkObjUpConv', 'nkChckRangeF', 'nkChckRange64', 
    'nkChckRange', 'nkStringToCString', 'nkCStringToString', 'nkPassAsOpenArray', 
    'nkAsgn', 'nkFastAsgn', 'nkGenericParams', 'nkFormalParams', 
    'nkOfInherit', 'nkModule', 'nkProcDef', 'nkMethodDef', 
    'nkConverterDef', 'nkMacroDef', 'nkTemplateDef', 'nkIteratorDef', 
    'nkOfBranch', 'nkElifBranch', 'nkExceptBranch', 'nkElse', 
    'nkMacroStmt', 'nkAsmStmt', 'nkPragma', 'nkIfStmt', 
    'nkWhenStmt', 'nkForStmt', 'nkWhileStmt', 'nkCaseStmt', 
    'nkVarSection', 'nkConstSection', 'nkConstDef', 'nkTypeSection', 
    'nkTypeDef', 'nkYieldStmt', 'nkTryStmt', 'nkFinally', 
    'nkRaiseStmt', 'nkReturnStmt', 'nkBreakStmt', 'nkContinueStmt', 
    'nkBlockStmt', 'nkDiscardStmt', 'nkStmtList', 'nkImportStmt', 
    'nkFromStmt', 'nkIncludeStmt', 'nkCommentStmt', 'nkStmtListExpr', 
    'nkBlockExpr', 'nkStmtListType', 'nkBlockType', 'nkTypeOfExpr', 
    'nkObjectTy', 'nkTupleTy', 'nkRecList', 'nkRecCase', 
    'nkRecWhen', 'nkRefTy', 'nkPtrTy', 'nkVarTy', 
    'nkDistinctTy', 'nkProcTy', 'nkEnumTy', 'nkEnumFieldDef', 
    'nkReturnToken');
type
  TSymFlag = (
    sfUsed, sfStar, sfMinus, sfInInterface, 
    sfFromGeneric, sfGlobal, sfForward, sfImportc, 
    sfExportc, sfVolatile, sfRegister, sfPure, 
    sfResult, sfNoSideEffect, sfSideEffect, sfMainModule, 
    sfSystemModule, sfNoReturn, sfAddrTaken, sfCompilerProc, 
    sfCppMethod, sfDiscriminant, sfDeprecated, sfInClosure, 
    sfTypeCheck, sfCompileTime, sfThreadVar, sfMerge, 
    sfDeadCodeElim, sfBorrow);
  TSymFlags = set of TSymFlag;
const
  SymFlagToStr: array [TSymFlag] of string = (
    'sfUsed', 'sfStar', 'sfMinus', 'sfInInterface', 
    'sfFromGeneric', 'sfGlobal', 'sfForward', 'sfImportc', 
    'sfExportc', 'sfVolatile', 'sfRegister', 'sfPure', 
    'sfResult', 'sfNoSideEffect', 'sfSideEffect', 'sfMainModule', 
    'sfSystemModule', 'sfNoReturn', 'sfAddrTaken', 'sfCompilerProc', 
    'sfCppMethod', 'sfDiscriminant', 'sfDeprecated', 'sfInClosure', 
    'sfTypeCheck', 'sfCompileTime', 'sfThreadVar', 'sfMerge', 
    'sfDeadCodeElim', 'sfBorrow');
type
  TTypeKind = (
    tyNone, tyBool, tyChar, tyEmpty, 
    tyArrayConstr, tyNil, tyExpr, tyStmt, 
    tyTypeDesc, tyGenericInvokation, tyGenericBody, tyGenericInst, 
    tyGenericParam, tyDistinct, tyEnum, tyOrdinal, 
    tyArray, tyObject, tyTuple, tySet, 
    tyRange, tyPtr, tyRef, tyVar, 
    tySequence, tyProc, tyPointer, tyOpenArray, 
    tyString, tyCString, tyForward, tyInt, 
    tyInt8, tyInt16, tyInt32, tyInt64, 
    tyFloat, tyFloat32, tyFloat64, tyFloat128);
  TTypeKinds = set of TTypeKind;
const
  TypeKindToStr: array [TTypeKind] of string = (
    'tyNone', 'tyBool', 'tyChar', 'tyEmpty', 
    'tyArrayConstr', 'tyNil', 'tyExpr', 'tyStmt', 
    'tyTypeDesc', 'tyGenericInvokation', 'tyGenericBody', 'tyGenericInst', 
    'tyGenericParam', 'tyDistinct', 'tyEnum', 'tyOrdinal', 
    'tyArray', 'tyObject', 'tyTuple', 'tySet', 
    'tyRange', 'tyPtr', 'tyRef', 'tyVar', 
    'tySequence', 'tyProc', 'tyPointer', 'tyOpenArray', 
    'tyString', 'tyCString', 'tyForward', 'tyInt', 
    'tyInt8', 'tyInt16', 'tyInt32', 'tyInt64', 
    'tyFloat', 'tyFloat32', 'tyFloat64', 'tyFloat128');
type
  TNodeFlag = (
    nfNone, nfBase2, nfBase8, nfBase16, 
    nfAllConst, nfTransf, nfSem);
  TNodeFlags = set of TNodeFlag;
const
  NodeFlagToStr: array [TNodeFlag] of string = (
    'nfNone', 'nfBase2', 'nfBase8', 'nfBase16', 
    'nfAllConst', 'nfTransf', 'nfSem');
type
  TTypeFlag = (
    tfVarargs, tfNoSideEffect, tfFinal, tfAcyclic, 
    tfEnumHasWholes);
  TTypeFlags = set of TTypeFlag;
const
  TypeFlagToStr: array [TTypeFlag] of string = (
    'tfVarargs', 'tfNoSideEffect', 'tfFinal', 'tfAcyclic', 
    'tfEnumHasWholes');
type
  TSymKind = (
    skUnknown, skConditional, skDynLib, skParam, 
    skGenericParam, skTemp, skType, skConst, 
    skVar, skProc, skMethod, skIterator, 
    skConverter, skMacro, skTemplate, skField, 
    skEnumField, skForVar, skModule, skLabel, 
    skStub);
  TSymKinds = set of TSymKind;
const
  SymKindToStr: array [TSymKind] of string = (
    'skUnknown', 'skConditional', 'skDynLib', 'skParam', 
    'skGenericParam', 'skTemp', 'skType', 'skConst', 
    'skVar', 'skProc', 'skMethod', 'skIterator', 
    'skConverter', 'skMacro', 'skTemplate', 'skField', 
    'skEnumField', 'skForVar', 'skModule', 'skLabel', 
    'skStub');
{[[[end]]]}

type
  // symbols that require compiler magic:
  TMagic = (
    //[[[cog
    //magics = eval(open("data/magic.yml").read())
    //for i in range(0, len(magics)-1):
    //  cog.out("m" + magics[i] + ", ")
    //  if (i+1) % 6 == 0: cog.outl("")
    //cog.outl("m" + magics[-1])
    //]]]
    mNone, mDefined, mDefinedInScope, mLow, mHigh, mSizeOf, 
    mIs, mEcho, mSucc, mPred, mInc, mDec, 
    mOrd, mNew, mNewFinalize, mNewSeq, mLengthOpenArray, mLengthStr, 
    mLengthArray, mLengthSeq, mIncl, mExcl, mCard, mChr, 
    mGCref, mGCunref, mAddI, mSubI, mMulI, mDivI, 
    mModI, mAddI64, mSubI64, mMulI64, mDivI64, mModI64, 
    mShrI, mShlI, mBitandI, mBitorI, mBitxorI, mMinI, 
    mMaxI, mShrI64, mShlI64, mBitandI64, mBitorI64, mBitxorI64, 
    mMinI64, mMaxI64, mAddF64, mSubF64, mMulF64, mDivF64, 
    mMinF64, mMaxF64, mAddU, mSubU, mMulU, mDivU, 
    mModU, mAddU64, mSubU64, mMulU64, mDivU64, mModU64, 
    mEqI, mLeI, mLtI, mEqI64, mLeI64, mLtI64, 
    mEqF64, mLeF64, mLtF64, mLeU, mLtU, mLeU64, 
    mLtU64, mEqEnum, mLeEnum, mLtEnum, mEqCh, mLeCh, 
    mLtCh, mEqB, mLeB, mLtB, mEqRef, mEqProc, 
    mEqUntracedRef, mLePtr, mLtPtr, mEqCString, mXor, mUnaryMinusI, 
    mUnaryMinusI64, mAbsI, mAbsI64, mNot, mUnaryPlusI, mBitnotI, 
    mUnaryPlusI64, mBitnotI64, mUnaryPlusF64, mUnaryMinusF64, mAbsF64, mZe8ToI, 
    mZe8ToI64, mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64, mToU8, 
    mToU16, mToU32, mToFloat, mToBiggestFloat, mToInt, mToBiggestInt, 
    mCharToStr, mBoolToStr, mIntToStr, mInt64ToStr, mFloatToStr, mCStrToStr, 
    mStrToStr, mEnumToStr, mAnd, mOr, mEqStr, mLeStr, 
    mLtStr, mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, 
    mMinusSet, mSymDiffSet, mConStrStr, mConArrArr, mConArrT, mConTArr, 
    mConTT, mSlice, mAppendStrCh, mAppendStrStr, mAppendSeqElem, mInRange, 
    mInSet, mRepr, mExit, mSetLengthStr, mSetLengthSeq, mAssert, 
    mSwap, mIsNil, mArrToSeq, mCopyStr, mCopyStrLast, mNewString, 
    mArray, mOpenArray, mRange, mSet, mSeq, mOrdinal, 
    mInt, mInt8, mInt16, mInt32, mInt64, mFloat, 
    mFloat32, mFloat64, mBool, mChar, mString, mCstring, 
    mPointer, mEmptySet, mIntSetBaseType, mNil, mExpr, mStmt, 
    mTypeDesc, mIsMainModule, mCompileDate, mCompileTime, mNimrodVersion, mNimrodMajor, 
    mNimrodMinor, mNimrodPatch, mCpuEndian, mHostOS, mHostCPU, mNaN, 
    mInf, mNegInf, mNLen, mNChild, mNSetChild, mNAdd, 
    mNAddMultiple, mNDel, mNKind, mNIntVal, mNFloatVal, mNSymbol, 
    mNIdent, mNGetType, mNStrVal, mNSetIntVal, mNSetFloatVal, mNSetSymbol, 
    mNSetIdent, mNSetType, mNSetStrVal, mNNewNimNode, mNCopyNimNode, mNCopyNimTree, 
    mStrToIdent, mIdentToStr, mEqIdent, mNHint, mNWarning, mNError
    //[[[end]]]
  );

type
  PNode = ^TNode;
  PNodePtr = ^{@ptr}PNode;
  TNodeSeq = array of PNode;

  PType = ^TType;
  PSym = ^TSym;

  TNode = {@ignore} record
    typ: PType;
    strVal: string;
    comment: string;
    sons: TNodeSeq; // else!
    info: TLineInfo;
    flags: TNodeFlags;
    case Kind: TNodeKind of
      nkCharLit, nkIntLit, nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit:
        (intVal: biggestInt);
      nkFloatLit, nkFloat32Lit, nkFloat64Lit:
        (floatVal: biggestFloat);
      nkSym: (sym: PSym);
      nkIdent: (ident: PIdent);
      nkMetaNode: (nodePtr: PNodePtr);
  end;
  {@emit
  record // on a 32bit machine, this takes 32 bytes
    typ: PType;
    comment: string;
    info: TLineInfo;
    flags: TNodeFlags;
    case Kind: TNodeKind of
      nkCharLit..nkInt64Lit:
        (intVal: biggestInt);
      nkFloatLit..nkFloat64Lit:
        (floatVal: biggestFloat);
      nkStrLit..nkTripleStrLit:
        (strVal: string);
      nkSym: (sym: PSym);
      nkIdent: (ident: PIdent);
      nkMetaNode: (nodePtr: PNodePtr);
      else (sons: TNodeSeq);
  end acyclic; }

  TSymSeq = array of PSym;
  TStrTable = object           // a table[PIdent] of PSym
    counter: int;
    data: TSymSeq;
  end;

// -------------- backend information -------------------------------

  TLocKind = (
    locNone,       // no location
    locTemp,       // temporary location
    locLocalVar,   // location is a local variable
    locGlobalVar,  // location is a global variable
    locParam,      // location is a parameter
    locField,      // location is a record field
    locArrayElem,  // location is an array element
    locExpr,       // "location" is really an expression
    locProc,       // location is a proc (an address of a procedure)
    locData,       // location is a constant
    locCall,       // location is a call expression
    locOther       // location is something other
  );

  TLocFlag = (
    lfIndirect,    // backend introduced a pointer
    lfParamCopy,   // backend introduced a parameter copy (LLVM)
    lfNoDeepCopy,  // no need for a deep copy
    lfNoDecl,      // do not declare it in C
    lfDynamicLib,  // link symbol to dynamic library
    lfHeader       // include header file for symbol
  );

  TStorageLoc = (
    OnUnknown,     // location is unknown (stack, heap or static)
    OnStack,       // location is on hardware stack
    OnHeap         // location is on heap or global (reference counting needed)
  );

  TLocFlags = set of TLocFlag;
  TLoc = record
    k: TLocKind;    // kind of location
    s: TStorageLoc;
    flags: TLocFlags;  // location's flags
    t: PType;       // type of location
    r: PRope;       // rope value of location (code generators)
    a: int;         // location's "address", i.e. slot for temporaries
  end;

// ---------------- end of backend information ------------------------------
  TLibKind = (libHeader, libDynamic);
  TLib = object(lists.TListEntry) // also misused for headers!
    kind: TLibKind;
    generated: bool;
    // needed for the backends:
    name: PRope;
    path: string;
  end;
  PLib = ^TLib;

  TSym = object(TIdObj)      // symbols are identical iff they have the same
                             // id!
    kind: TSymKind;
    magic: TMagic;
    typ: PType;
    name: PIdent;
    info: TLineInfo;
    owner: PSym;
    flags: TSymFlags;
    tab: TStrTable;          // interface table for modules
    ast: PNode;              // syntax tree of proc, iterator, etc.:
                             // the whole proc including header; this is used
                             // for easy generation of proper error messages
                             // for variant record fields the discriminant
                             // expression
    options: TOptions;
    position: int;           // used for many different things:
                             // for enum fields its position;
                             // for fields its offset
                             // for parameters its position
                             // for a conditional:
                             // 1 iff the symbol is defined, else 0
                             // (or not in symbol table)
    offset: int;             // offset of record field
    loc: TLoc;
    annex: PLib;             // additional fields (seldom used, so we use a
                             // reference to another object to safe space)
  end;

  TTypeSeq = array of PType;
  TType = object(TIdObj)     // types are identical iff they have the
                             // same id; there may be multiple copies of a type
                             // in memory!
    kind: TTypeKind;         // kind of type
    sons: TTypeSeq;          // base types, etc.
    n: PNode;                // node for types:
                             // for range types a nkRange node
                             // for record types a nkRecord node
                             // for enum types a list of symbols
                             // else: unused
    flags: TTypeFlags;       // flags of the type
    callConv: TCallingConvention; // for procs
    owner: PSym;             // the 'owner' of the type
    sym: PSym;               // types have the sym associated with them
                             // it is used for converting types to strings
    size: BiggestInt;        // the size of the type in bytes
                             // -1 means that the size is unkwown
    align: int;              // the type's alignment requirements
    containerID: int;        // used for type checking of generics
    loc: TLoc;
  end;

  TPair = record
    key, val: PObject;
  end;
  TPairSeq = array of TPair;

  TTable = record // the same as table[PObject] of PObject
    counter: int;
    data: TPairSeq;
  end;

  TIdPair = record
    key: PIdObj;
    val: PObject;
  end;
  TIdPairSeq = array of TIdPair;

  TIdTable = record // the same as table[PIdent] of PObject
    counter: int;
    data: TIdPairSeq;
  end;

  TIdNodePair = record
    key: PIdObj;
    val: PNode;
  end;
  TIdNodePairSeq = array of TIdNodePair;

  TIdNodeTable = record // the same as table[PIdObj] of PNode
    counter: int;
    data: TIdNodePairSeq;
  end;

  TNodePair = record
    h: THash;   // because it is expensive to compute!
    key: PNode;
    val: int;
  end;
  TNodePairSeq = array of TNodePair;

  TNodeTable = record // the same as table[PNode] of int;
                      // nodes are compared by structure!
    counter: int;
    data: TNodePairSeq;
  end;

  TObjectSeq = array of PObject;

  TObjectSet = record
    counter: int;
    data: TObjectSeq;
  end;

const
  OverloadableSyms = {@set}[skProc, skMethod, skIterator, skConverter];

const // "MagicToStr" array:
  MagicToStr: array [TMagic] of string = (
    //[[[cog
    //for i in range(0, len(magics)-1):
    //  cog.out("'%s', " % magics[i])
    //  if (i+1) % 6 == 0: cog.outl("")
    //cog.outl("'%s'" % magics[-1])
    //]]]
    'None', 'Defined', 'DefinedInScope', 'Low', 'High', 'SizeOf', 
    'Is', 'Echo', 'Succ', 'Pred', 'Inc', 'Dec', 
    'Ord', 'New', 'NewFinalize', 'NewSeq', 'LengthOpenArray', 'LengthStr', 
    'LengthArray', 'LengthSeq', 'Incl', 'Excl', 'Card', 'Chr', 
    'GCref', 'GCunref', 'AddI', 'SubI', 'MulI', 'DivI', 
    'ModI', 'AddI64', 'SubI64', 'MulI64', 'DivI64', 'ModI64', 
    'ShrI', 'ShlI', 'BitandI', 'BitorI', 'BitxorI', 'MinI', 
    'MaxI', 'ShrI64', 'ShlI64', 'BitandI64', 'BitorI64', 'BitxorI64', 
    'MinI64', 'MaxI64', 'AddF64', 'SubF64', 'MulF64', 'DivF64', 
    'MinF64', 'MaxF64', 'AddU', 'SubU', 'MulU', 'DivU', 
    'ModU', 'AddU64', 'SubU64', 'MulU64', 'DivU64', 'ModU64', 
    'EqI', 'LeI', 'LtI', 'EqI64', 'LeI64', 'LtI64', 
    'EqF64', 'LeF64', 'LtF64', 'LeU', 'LtU', 'LeU64', 
    'LtU64', 'EqEnum', 'LeEnum', 'LtEnum', 'EqCh', 'LeCh', 
    'LtCh', 'EqB', 'LeB', 'LtB', 'EqRef', 'EqProc', 
    'EqUntracedRef', 'LePtr', 'LtPtr', 'EqCString', 'Xor', 'UnaryMinusI', 
    'UnaryMinusI64', 'AbsI', 'AbsI64', 'Not', 'UnaryPlusI', 'BitnotI', 
    'UnaryPlusI64', 'BitnotI64', 'UnaryPlusF64', 'UnaryMinusF64', 'AbsF64', 'Ze8ToI', 
    'Ze8ToI64', 'Ze16ToI', 'Ze16ToI64', 'Ze32ToI64', 'ZeIToI64', 'ToU8', 
    'ToU16', 'ToU32', 'ToFloat', 'ToBiggestFloat', 'ToInt', 'ToBiggestInt', 
    'CharToStr', 'BoolToStr', 'IntToStr', 'Int64ToStr', 'FloatToStr', 'CStrToStr', 
    'StrToStr', 'EnumToStr', 'And', 'Or', 'EqStr', 'LeStr', 
    'LtStr', 'EqSet', 'LeSet', 'LtSet', 'MulSet', 'PlusSet', 
    'MinusSet', 'SymDiffSet', 'ConStrStr', 'ConArrArr', 'ConArrT', 'ConTArr', 
    'ConTT', 'Slice', 'AppendStrCh', 'AppendStrStr', 'AppendSeqElem', 'InRange', 
    'InSet', 'Repr', 'Exit', 'SetLengthStr', 'SetLengthSeq', 'Assert', 
    'Swap', 'IsNil', 'ArrToSeq', 'CopyStr', 'CopyStrLast', 'NewString', 
    'Array', 'OpenArray', 'Range', 'Set', 'Seq', 'Ordinal', 
    'Int', 'Int8', 'Int16', 'Int32', 'Int64', 'Float', 
    'Float32', 'Float64', 'Bool', 'Char', 'String', 'Cstring', 
    'Pointer', 'EmptySet', 'IntSetBaseType', 'Nil', 'Expr', 'Stmt', 
    'TypeDesc', 'IsMainModule', 'CompileDate', 'CompileTime', 'NimrodVersion', 'NimrodMajor', 
    'NimrodMinor', 'NimrodPatch', 'CpuEndian', 'HostOS', 'HostCPU', 'NaN', 
    'Inf', 'NegInf', 'NLen', 'NChild', 'NSetChild', 'NAdd', 
    'NAddMultiple', 'NDel', 'NKind', 'NIntVal', 'NFloatVal', 'NSymbol', 
    'NIdent', 'NGetType', 'NStrVal', 'NSetIntVal', 'NSetFloatVal', 'NSetSymbol', 
    'NSetIdent', 'NSetType', 'NSetStrVal', 'NNewNimNode', 'NCopyNimNode', 'NCopyNimTree', 
    'StrToIdent', 'IdentToStr', 'EqIdent', 'NHint', 'NWarning', 'NError'
    //[[[end]]]
  );

const
  GenericTypes: TTypeKinds = {@set}[
    tyGenericInvokation, 
    tyGenericBody, 
    tyGenericParam
  ];

  StructuralEquivTypes: TTypeKinds = {@set}[
    tyArrayConstr, tyNil, tyTuple,
    tyArray,
    tySet,
    tyRange,
    tyPtr, tyRef,
    tyVar,
    tySequence,
    tyProc, tyOpenArray
  ];

  ConcreteTypes: TTypeKinds = {@set}[
  // types of the expr that may occur in::
  // var x = expr
    tyBool, tyChar, tyEnum, tyArray, tyObject, tySet, tyTuple,
    tyRange, tyPtr, tyRef, tyVar, tySequence, tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCString,
    tyInt..tyInt64,
    tyFloat..tyFloat128
  ];
  ConstantDataTypes: TTypeKinds = {@set}[tyArray, tySet, tyTuple];
  ExportableSymKinds = {@set}[skVar, skConst, skProc, skMethod, skType,
                              skIterator, skMacro, skTemplate, skConverter,
                              skStub];
  PersistentNodeFlags: TNodeFlags = {@set}[
    nfBase2, nfBase8, nfBase16, nfAllConst];
  namePos = 0;
  genericParamsPos = 1;
  paramsPos = 2;
  pragmasPos = 3;
  codePos = 4;
  resultPos = 5;
  dispatcherPos = 6;

var
  gId: int;

function getID: int;
procedure setID(id: int);
procedure IDsynchronizationPoint(idRange: int);

// creator procs:
function NewSym(symKind: TSymKind; Name: PIdent; owner: PSym): PSym;

function NewType(kind: TTypeKind; owner: PSym): PType; overload;

function newNode(kind: TNodeKind): PNode;
function newIntNode(kind: TNodeKind; const intVal: BiggestInt): PNode;
function newIntTypeNode(kind: TNodeKind; const intVal: BiggestInt;
                        typ: PType): PNode;
function newFloatNode(kind: TNodeKind; const floatVal: BiggestFloat): PNode;
function newStrNode(kind: TNodeKind; const strVal: string): PNode;
function newIdentNode(ident: PIdent; const info: TLineInfo): PNode;
function newSymNode(sym: PSym): PNode;
function newNodeI(kind: TNodeKind; const info: TLineInfo): PNode;
function newNodeIT(kind: TNodeKind; const info: TLineInfo; typ: PType): PNode;

procedure initStrTable(out x: TStrTable);
procedure initTable(out x: TTable);
procedure initIdTable(out x: TIdTable);
procedure initObjectSet(out x: TObjectSet);
procedure initIdNodeTable(out x: TIdNodeTable);
procedure initNodeTable(out x: TNodeTable);

// copy procs:
function copyType(t: PType; owner: PSym; keepId: bool): PType;
function copySym(s: PSym; keepId: bool = false): PSym;
procedure assignType(dest, src: PType);

procedure copyStrTable(out dest: TStrTable; const src: TStrTable);
procedure copyTable(out dest: TTable; const src: TTable);
procedure copyObjectSet(out dest: TObjectSet; const src: TObjectSet);
procedure copyIdTable(var dest: TIdTable; const src: TIdTable);

function sonsLen(n: PNode): int; overload; 
function sonsLen(n: PType): int; overload; 

function lastSon(n: PNode): PNode; overload;
function lastSon(n: PType): PType; overload;
procedure newSons(father: PNode; len: int); overload;
procedure newSons(father: PType; len: int); overload;

procedure addSon(father, son: PNode); overload;
procedure addSon(father, son: PType); overload;

procedure addSonIfNotNil(father, n: PNode);
procedure delSon(father: PNode; idx: int);
function hasSonWith(n: PNode; kind: TNodeKind): boolean;
function hasSubnodeWith(n: PNode; kind: TNodeKind): boolean;
procedure replaceSons(n: PNode; oldKind, newKind: TNodeKind);
function sonsNotNil(n: PNode): bool; // for assertions

function copyNode(src: PNode): PNode;
// does not copy its sons!

function copyTree(src: PNode): PNode;
// does copy its sons!

procedure discardSons(father: PNode);

const // for all kind of hash tables:
  GrowthFactor = 2; // must be power of 2, > 0
  StartSize = 8;    // must be power of 2, > 0

function SameValue(a, b: PNode): Boolean; // a, b are literals
function leValue(a, b: PNode): Boolean; // a <= b? a, b are literals

function ValueToString(a: PNode): string;

// ------------- efficient integer sets -------------------------------------
{@ignore}
type
  TBitScalar = int32; // FPC produces wrong code for ``int``
{@emit
type
  TBitScalar = int; }

const
  InitIntSetSize = 8; // must be a power of two!
  TrunkShift = 9;
  BitsPerTrunk = 1 shl TrunkShift; 
    // needs to be a power of 2 and divisible by 64
  TrunkMask = BitsPerTrunk-1;
  IntsPerTrunk = BitsPerTrunk div (sizeof(TBitScalar)*8);
  IntShift = 5+ord(sizeof(TBitScalar)=8); // 5 or 6, depending on int width
  IntMask = 1 shl IntShift -1;

type
  PTrunk = ^TTrunk;
  TTrunk = record
    next: PTrunk; // all nodes are connected with this pointer
    key: int;    // start address at bit 0
    bits: array [0..IntsPerTrunk-1] of TBitScalar; // a bit vector
  end;
  TTrunkSeq = array of PTrunk;
  TIntSet = record
    counter, max: int;
    head: PTrunk;
    data: TTrunkSeq;
  end;

function IntSetContains(const s: TIntSet; key: int): bool;
procedure IntSetIncl(var s: TIntSet; key: int);
procedure IntSetExcl(var s: TIntSet; key: int);
procedure IntSetInit(var s: TIntSet);

function IntSetContainsOrIncl(var s: TIntSet; key: int): bool;


const
  debugIds = false;

procedure registerID(id: PIdObj);

implementation

var
  usedIds: TIntSet;

procedure registerID(id: PIdObj);
begin
  if debugIDs then
    if (id.id = -1) or IntSetContainsOrIncl(usedIds, id.id) then
      InternalError('ID already used: ' + toString(id.id));
end;

function getID: int;
begin
  result := gId;
  inc(gId)
end;

procedure setId(id: int);
begin
  gId := max(gId, id+1);
end;

procedure IDsynchronizationPoint(idRange: int);
begin
  gId := (gId div IdRange +1) * IdRange + 1;
end;

function leValue(a, b: PNode): Boolean; // a <= b?
begin
  result := false;
  case a.kind of
    nkCharLit..nkInt64Lit:
      if b.kind in [nkCharLit..nkInt64Lit] then
        result := a.intVal <= b.intVal;
    nkFloatLit..nkFloat64Lit:
      if b.kind in [nkFloatLit..nkFloat64Lit] then
        result := a.floatVal <= b.floatVal;
    nkStrLit..nkTripleStrLit: begin
      if b.kind in [nkStrLit..nkTripleStrLit] then
        result := a.strVal <= b.strVal;
    end
    else InternalError(a.info, 'leValue');
  end
end;

function SameValue(a, b: PNode): Boolean;
begin
  result := false;
  case a.kind of
    nkCharLit..nkInt64Lit:
      if b.kind in [nkCharLit..nkInt64Lit] then
        result := a.intVal = b.intVal;
    nkFloatLit..nkFloat64Lit:
      if b.kind in [nkFloatLit..nkFloat64Lit] then
        result := a.floatVal = b.floatVal;
    nkStrLit..nkTripleStrLit: begin
      if b.kind in [nkStrLit..nkTripleStrLit] then
        result := a.strVal = b.strVal;
    end
    else InternalError(a.info, 'SameValue');
  end
end;

function ValueToString(a: PNode): string;
begin
  case a.kind of
    nkCharLit..nkInt64Lit:
      result := ToString(a.intVal);
    nkFloatLit, nkFloat32Lit, nkFloat64Lit:
      result := toStringF(a.floatVal);
    nkStrLit..nkTripleStrLit:
      result := a.strVal;
    else begin
      InternalError(a.info, 'valueToString');
      result := ''
    end
  end
end;

procedure copyStrTable(out dest: TStrTable; const src: TStrTable);
var
  i: int;
begin
  dest.counter := src.counter;
{@emit
  if isNil(src.data) then exit;
}
  setLength(dest.data, length(src.data));
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure copyIdTable(var dest: TIdTable; const src: TIdTable);
var
  i: int;
begin
  dest.counter := src.counter;
{@emit
  if isNil(src.data) then exit;
}
{@ignore}
  setLength(dest.data, length(src.data));
{@emit
  newSeq(dest.data, length(src.data)); }
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure copyTable(out dest: TTable; const src: TTable);
var
  i: int;
begin
  dest.counter := src.counter;
{@emit
  if isNil(src.data) then exit;
}
  setLength(dest.data, length(src.data));
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure copyObjectSet(out dest: TObjectSet; const src: TObjectSet);
var
  i: int;
begin
  dest.counter := src.counter;
{@emit
  if isNil(src.data) then exit;
}
  setLength(dest.data, length(src.data));
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure discardSons(father: PNode);
begin
  father.sons := nil;
end;

function newNode(kind: TNodeKind): PNode;
begin
  new(result);
{@ignore}
  FillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := kind;
  //result.info := UnknownLineInfo(); inlined:
  result.info.fileIndex := int32(-1);
  result.info.col := int16(-1);
  result.info.line := int16(-1);
end;

function newIntNode(kind: TNodeKind; const intVal: BiggestInt): PNode;
begin
  result := newNode(kind);
  result.intVal := intVal
end;

function newIntTypeNode(kind: TNodeKind; const intVal: BiggestInt;
                        typ: PType): PNode;
begin
  result := newIntNode(kind, intVal);
  result.typ := typ;
end;

function newFloatNode(kind: TNodeKind; const floatVal: BiggestFloat): PNode;
begin
  result := newNode(kind);
  result.floatVal := floatVal
end;

function newStrNode(kind: TNodeKind; const strVal: string): PNode;
begin
  result := newNode(kind);
  result.strVal := strVal
end;

function newIdentNode(ident: PIdent; const info: TLineInfo): PNode;
begin
  result := newNode(nkIdent);
  result.ident := ident;
  result.info := info;
end;

function newSymNode(sym: PSym): PNode;
begin
  result := newNode(nkSym);
  result.sym := sym;
  result.typ := sym.typ;
  result.info := sym.info;
end;

function newNodeI(kind: TNodeKind; const info: TLineInfo): PNode;
begin
  result := newNode(kind);
  result.info := info;
end;

function newNodeIT(kind: TNodeKind; const info: TLineInfo; typ: PType): PNode;
begin
  result := newNode(kind);
  result.info := info;
  result.typ := typ;
end;

function NewType(kind: TTypeKind; owner: PSym): PType; overload;
begin
  new(result);
{@ignore}
  FillChar(result^, sizeof(result^), 0);
{@emit}
  result.kind := kind;
  result.owner := owner;
  result.size := -1;
  result.align := 2; // default alignment
  result.id := getID();
  if debugIds then RegisterId(result);
  //if result.id < 2000 then
  //  MessageOut(typeKindToStr[kind] +{&} ' has id: ' +{&} toString(result.id));
end;

procedure assignType(dest, src: PType);
var
  i: int;
begin
  dest.kind := src.kind;
  dest.flags := src.flags;
  dest.callConv := src.callConv;
  dest.n := src.n;
  dest.size := src.size;
  dest.align := src.align;
  dest.containerID := src.containerID;
  newSons(dest, sonsLen(src));
  for i := 0 to sonsLen(src)-1 do
    dest.sons[i] := src.sons[i];
end;

function copyType(t: PType; owner: PSym; keepId: bool): PType;
begin
  result := newType(t.Kind, owner);
  assignType(result, t);
  if keepId then result.id := t.id
  else begin
    result.id := getID();
    if debugIds then RegisterId(result);
  end;
  result.sym := t.sym;
  // backend-info should not be copied
end;

function copySym(s: PSym; keepId: bool = false): PSym;
begin
  result := newSym(s.kind, s.name, s.owner);
  result.ast := nil; // BUGFIX; was: s.ast which made problems
  result.info := s.info;
  result.typ := s.typ;
  if keepId then result.id := s.id
  else begin
    result.id := getID();
    if debugIds then RegisterId(result);
  end;
  result.flags := s.flags;
  result.magic := s.magic;
  copyStrTable(result.tab, s.tab);
  result.options := s.options;
  result.position := s.position;
  result.loc := s.loc;
  result.annex := s.annex; // BUGFIX
end;

function NewSym(symKind: TSymKind; Name: PIdent; owner: PSym): PSym;
// generates a symbol and initializes the hash field too
begin
  new(result);
{@ignore}
  FillChar(result^, sizeof(result^), 0);
{@emit}
  result.Name := Name;
  result.Kind := symKind;
  result.flags := {@set}[];
  result.info := UnknownLineInfo();
  result.options := gOptions;
  result.owner := owner;
  result.offset := -1;
  result.id := getID();
  if debugIds then RegisterId(result);
  //if result.id < 2000 then
  //  MessageOut(name.s +{&} ' has id: ' +{&} toString(result.id));
end;

procedure initStrTable(out x: TStrTable);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initTable(out x: TTable);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initIdTable(out x: TIdTable);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initObjectSet(out x: TObjectSet);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initIdNodeTable(out x: TIdNodeTable);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initNodeTable(out x: TNodeTable);
begin
  x.counter := 0;
{@emit
  newSeq(x.data, startSize); }
{@ignore}
  setLength(x.data, startSize);
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

function sonsLen(n: PType): int;
begin
{@ignore}
  result := length(n.sons);
{@emit
  if isNil(n.sons) then result := 0
  else result := length(n.sons); }
end;

procedure newSons(father: PType; len: int);
var
  i, L: int;
begin
{@emit
  if isNil(father.sons) then father.sons := @[]; }
  L := length(father.sons);
  setLength(father.sons, L + len);
{@ignore}
  for i := L to L+len-1 do father.sons[i] := nil // needed for FPC
{@emit}
end;

procedure addSon(father, son: PType);
var
  L: int;
begin
{@ignore}
  L := length(father.sons);
  setLength(father.sons, L+1);
  father.sons[L] := son;
{@emit
  if isNil(father.sons) then father.sons := @[]; }
{@emit add(father.sons, son); }
  assert((father.kind <> tyGenericInvokation) or (son.kind <> tyGenericInst));
end;

function sonsLen(n: PNode): int;
begin
{@ignore}
  result := length(n.sons);
{@emit
  if isNil(n.sons) then result := 0
  else result := length(n.sons); }
end;

procedure newSons(father: PNode; len: int);
var
  i, L: int;
begin
{@emit
  if isNil(father.sons) then father.sons := @[]; }
  L := length(father.sons);
  setLength(father.sons, L + len);
{@ignore}
  for i := L to L+len-1 do father.sons[i] := nil // needed for FPC
{@emit}
end;

procedure addSon(father, son: PNode);
var
  L: int;
begin
{@ignore}
  L := length(father.sons);
  setLength(father.sons, L+1);
  father.sons[L] := son;
{@emit
  if isNil(father.sons) then father.sons := @[]; }
{@emit add(father.sons, son); }
end;

procedure delSon(father: PNode; idx: int);
var
  len, i: int;
begin
{@emit
  if isNil(father.sons) then exit; }
  len := sonsLen(father);
  for i := idx to len-2 do
    father.sons[i] := father.sons[i+1];
  setLength(father.sons, len-1);
end;

function copyNode(src: PNode): PNode;
// does not copy its sons!
begin
  if src = nil then begin result := nil; exit end;
  result := newNode(src.kind);
  result.info := src.info;
  result.typ := src.typ;
  result.flags := src.flags * PersistentNodeFlags;
  case src.Kind of
    nkCharLit..nkInt64Lit:
      result.intVal := src.intVal;
    nkFloatLit, nkFloat32Lit, nkFloat64Lit:
      result.floatVal := src.floatVal;
    nkSym:
      result.sym := src.sym;
    nkIdent:
      result.ident := src.ident;
    nkStrLit..nkTripleStrLit:
      result.strVal := src.strVal;
    nkMetaNode:
      result.nodePtr := src.nodePtr;
    else begin end;
  end;
end;

function copyTree(src: PNode): PNode;
// copy a whole syntax tree; performs deep copying
var
  i: int;
begin
  if src = nil then begin result := nil; exit end;
  result := newNode(src.kind);
  result.info := src.info;
  result.typ := src.typ;
  result.flags := src.flags * PersistentNodeFlags;
  case src.Kind of
    nkCharLit..nkInt64Lit:
      result.intVal := src.intVal;
    nkFloatLit, nkFloat32Lit, nkFloat64Lit:
      result.floatVal := src.floatVal;
    nkSym:
      result.sym := src.sym;
    nkIdent:
      result.ident := src.ident;
    nkStrLit..nkTripleStrLit:
      result.strVal := src.strVal;
    nkMetaNode:
      result.nodePtr := src.nodePtr;
    else begin
      result.sons := nil;
      newSons(result, sonsLen(src));
      for i := 0 to sonsLen(src)-1 do
        result.sons[i] := copyTree(src.sons[i]);
    end;
  end
end;

function lastSon(n: PNode): PNode;
begin
  result := n.sons[sonsLen(n)-1];
end;

function lastSon(n: PType): PType;
begin
  result := n.sons[sonsLen(n)-1];
end;

function hasSonWith(n: PNode; kind: TNodeKind): boolean;
var
  i: int;
begin
  for i := 0 to sonsLen(n)-1 do begin
    if (n.sons[i] <> nil) and (n.sons[i].kind = kind) then begin
      result := true; exit
    end
  end;
  result := false
end;

function hasSubnodeWith(n: PNode; kind: TNodeKind): boolean;
var
  i: int;
begin
  case n.kind of
    nkEmpty..nkNilLit: result := n.kind = kind;
    else begin
      for i := 0 to sonsLen(n)-1 do begin
        if (n.sons[i] <> nil) and (n.sons[i].kind = kind)
        or hasSubnodeWith(n.sons[i], kind) then begin
          result := true; exit
        end
      end;
      result := false
    end
  end
end;

procedure replaceSons(n: PNode; oldKind, newKind: TNodeKind);
var
  i: int;
begin
  for i := 0 to sonsLen(n)-1 do
    if n.sons[i].kind = oldKind then n.sons[i].kind := newKind
end;

function sonsNotNil(n: PNode): bool;
var
  i: int;
begin
  for i := 0 to sonsLen(n)-1 do
    if n.sons[i] = nil then begin result := false; exit end;
  result := true
end;

procedure addSonIfNotNil(father, n: PNode);
begin
  if n <> nil then addSon(father, n)
end;

// ---------------- efficient integer sets ----------------------------------
// Same algorithm as the one the GC uses

function mustRehash(len, counter: int): bool;
begin
  assert(len > counter);
  result := (len * 2 < counter * 3) or (len-counter < 4);
end;

function nextTry(h, maxHash: THash): THash;
begin
  result := ((5*h) + 1) and maxHash;
  // For any initial h in range(maxHash), repeating that maxHash times
  // generates each int in range(maxHash) exactly once (see any text on
  // random-number generation for proof).
end;

procedure IntSetInit(var s: TIntSet);
begin
{@ignore}
  fillChar(s, sizeof(s), 0);
{@emit}
{@ignore}
  setLength(s.data, InitIntSetSize);
  fillChar(s.data[0], length(s.data)*sizeof(s.data[0]), 0);
{@emit
  newSeq(s.data, InitIntSetSize); }
  s.max := InitIntSetSize-1;
  s.counter := 0;
  s.head := nil
end;

function IntSetGet(const t: TIntSet; key: int): PTrunk;
var
  h: int;
begin
  h := key and t.max;
  while t.data[h] <> nil do begin
    if t.data[h].key = key then begin
      result := t.data[h]; exit
    end;
    h := nextTry(h, t.max)
  end;
  result := nil
end;

procedure IntSetRawInsert(const t: TIntSet; var data: TTrunkSeq; desc: PTrunk);
var
  h: int;
begin
  h := desc.key and t.max;
  while data[h] <> nil do begin
    assert(data[h] <> desc);
    h := nextTry(h, t.max)
  end;
  assert(data[h] = nil);
  data[h] := desc
end;

procedure IntSetEnlarge(var t: TIntSet);
var
  n: TTrunkSeq;
  i, oldMax: int;
begin
  oldMax := t.max;
  t.max := ((t.max+1)*2)-1;
{@ignore}
  setLength(n, t.max + 1);
  fillChar(n[0], length(n)*sizeof(n[0]), 0);
{@emit
  newSeq(n, t.max+1); }
  for i := 0 to oldmax do
    if t.data[i] <> nil then
      IntSetRawInsert(t, n, t.data[i]);
{@ignore}
  t.data := n;
{@emit
  swap(t.data, n); }
end;

function IntSetPut(var t: TIntSet; key: int): PTrunk;
var
  h: int;
begin
  h := key and t.max;
  while t.data[h] <> nil do begin
    if t.data[h].key = key then begin
      result := t.data[h]; exit
    end;
    h := nextTry(h, t.max)
  end;

  if mustRehash(t.max+1, t.counter) then IntSetEnlarge(t);
  inc(t.counter);
  h := key and t.max;
  while t.data[h] <> nil do h := nextTry(h, t.max);
  assert(t.data[h] = nil);
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  result.next := t.head;
  result.key := key;
  t.head := result;
  t.data[h] := result;
end;

// ---------- slightly higher level procs ----------------------------------

function IntSetContains(const s: TIntSet; key: int): bool;
var
  u: TBitScalar;
  t: PTrunk;
begin
  t := IntSetGet(s, shru(key, TrunkShift));
  if t <> nil then begin
    u := key and TrunkMask;
    result := (t.bits[shru(u, IntShift)] and shlu(1, u and IntMask)) <> 0
  end
  else
    result := false
end;

procedure IntSetIncl(var s: TIntSet; key: int);
var
  u: TBitScalar;
  t: PTrunk;
begin
  t := IntSetPut(s, shru(key, TrunkShift));
  u := key and TrunkMask;
  t.bits[shru(u, IntShift)] := t.bits[shru(u, IntShift)]
                            or shlu(1, u and IntMask);
end;

procedure IntSetExcl(var s: TIntSet; key: int);
var
  u: TBitScalar;
  t: PTrunk;
begin
  t := IntSetGet(s, shru(key, TrunkShift));
  if t <> nil then begin
    u := key and TrunkMask;
    t.bits[shru(u, IntShift)] := t.bits[shru(u, IntShift)]
                               and not shlu(1, u and IntMask);
  end
end;

function IntSetContainsOrIncl(var s: TIntSet; key: int): bool;
var
  u: TBitScalar;
  t: PTrunk;
begin
  t := IntSetGet(s, shru(key, TrunkShift));
  if t <> nil then begin
    u := key and TrunkMask;
    result := (t.bits[shru(u, IntShift)] and shlu(1, u and IntMask)) <> 0;
    if not result then
      t.bits[shru(u, IntShift)] := t.bits[shru(u, IntShift)]
                                or shlu(1, u and IntMask);
  end
  else begin
    IntSetIncl(s, key);
    result := false
  end
end;
(*
procedure IntSetDebug(const s: TIntSet);
var
  it: PTrunk;
  i, j: int;
begin
  it := s.head;
  while it <> nil do begin
    for i := 0 to high(it.bits) do 
      for j := 0 to BitsPerInt-1 do begin
        if (it.bits[j] and (1 shl j)) <> 0 then
          MessageOut('Contains key: ' + toString(it.key + i * BitsPerInt + j));
      end;
    it := it.next
  end
end;*)

initialization
  if debugIDs then IntSetInit(usedIds);
end.
