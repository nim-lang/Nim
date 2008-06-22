//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ast;

// abstract syntax tree + symbol table

interface

{$include 'config.inc'}

uses
  nsystem, charsets, msgs, hashes,
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
    ccFastCall,  // fastcall (pass parameters in registers)
    ccClosure,   // proc has a closure
    ccNoConvention // needed for generating proper C procs sometimes
  );

const
  CallingConvToStr: array [TCallingConvention] of string = (
    '', 'stdcall', 'cdecl', 'safecall', 'syscall', 'inline', 'fastcall',
    'closure', 'noconv');

(*[[[cog
def toEnum(name, elems, prefixlen=0):
  body = ""
  strs = ""
  prefix = ""
  counter = 0
  for e in elems:
    if counter % 4 == 0: prefix = "\n    "
    else: prefix = ""
    body += prefix + e + ', '
    strs += prefix + "'%s', " % e[prefixlen:]
    counter += 1

  return ("type\n  T%s = (%s);\n  T%ss = set of T%s;\n"
            % (name, body.rstrip(", "), name, name),
          "const\n  %sToStr: array [T%s] of string = (%s);\n"
            % (name, name, strs.rstrip(", ")))

enums = eval(file("data/ast.yml").read())
for key, val in enums.iteritems():
  (a, b) = toEnum(key, val)
  cog.out(a)
  cog.out(b)
]]]*)
type
  TSymKind = (
    skUnknownSym, skConditional, skDynLib, skParam, 
    skTypeParam, skTemp, skType, skConst, 
    skVar, skProc, skIterator, skConverter, 
    skMacro, skTemplate, skField, skEnumField, 
    skForVar, skModule, skLabel);
  TSymKinds = set of TSymKind;
const
  SymKindToStr: array [TSymKind] of string = (
    'skUnknownSym', 'skConditional', 'skDynLib', 'skParam', 
    'skTypeParam', 'skTemp', 'skType', 'skConst', 
    'skVar', 'skProc', 'skIterator', 'skConverter', 
    'skMacro', 'skTemplate', 'skField', 'skEnumField', 
    'skForVar', 'skModule', 'skLabel');
type
  TNodeKind = (
    nkNone, nkEmpty, nkIdent, nkSym, 
    nkType, nkCharLit, nkRCharLit, nkIntLit, 
    nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit, 
    nkFloatLit, nkFloat32Lit, nkFloat64Lit, nkStrLit, 
    nkRStrLit, nkTripleStrLit, nkNilLit, nkDotCall, 
    nkCommand, nkCall, nkGenericCall, nkExplicitTypeListCall, 
    nkExprEqExpr, nkExprColonExpr, nkIdentDefs, nkInfix, 
    nkPrefix, nkPostfix, nkPar, nkCurly, 
    nkBracket, nkBracketExpr, nkPragmaExpr, nkRange, 
    nkDotExpr, nkCheckedFieldExpr, nkDerefExpr, nkIfExpr, 
    nkElifExpr, nkElseExpr, nkLambda, nkAccQuoted, 
    nkHeaderQuoted, nkSetConstr, nkConstSetConstr, nkArrayConstr, 
    nkConstArrayConstr, nkRecordConstr, nkConstRecordConstr, nkTableConstr, 
    nkConstTableConstr, nkQualified, nkHiddenStdConv, nkHiddenSubConv, 
    nkHiddenCallConv, nkConv, nkCast, nkAddr, 
    nkAsgn, nkDefaultTypeParam, nkGenericParams, nkFormalParams, 
    nkOfInherit, nkModule, nkProcDef, nkConverterDef, 
    nkMacroDef, nkTemplateDef, nkIteratorDef, nkOfBranch, 
    nkElifBranch, nkExceptBranch, nkElse, nkMacroStmt, 
    nkAsmStmt, nkPragma, nkIfStmt, nkWhenStmt, 
    nkForStmt, nkWhileStmt, nkCaseStmt, nkVarSection, 
    nkConstSection, nkConstDef, nkTypeSection, nkTypeDef, 
    nkYieldStmt, nkTryStmt, nkFinally, nkRaiseStmt, 
    nkReturnStmt, nkBreakStmt, nkContinueStmt, nkBlockStmt, 
    nkGotoStmt, nkDiscardStmt, nkStmtList, nkImportStmt, 
    nkFromStmt, nkImportAs, nkIncludeStmt, nkAccessStmt, 
    nkCommentStmt, nkStmtListExpr, nkBlockExpr, nkVm, 
    nkTypeOfExpr, nkRecordTy, nkObjectTy, nkRecList, 
    nkRecCase, nkRecWhen, nkRefTy, nkPtrTy, 
    nkVarTy, nkProcTy, nkEnumTy, nkEnumFieldDef);
  TNodeKinds = set of TNodeKind;
const
  NodeKindToStr: array [TNodeKind] of string = (
    'nkNone', 'nkEmpty', 'nkIdent', 'nkSym', 
    'nkType', 'nkCharLit', 'nkRCharLit', 'nkIntLit', 
    'nkInt8Lit', 'nkInt16Lit', 'nkInt32Lit', 'nkInt64Lit', 
    'nkFloatLit', 'nkFloat32Lit', 'nkFloat64Lit', 'nkStrLit', 
    'nkRStrLit', 'nkTripleStrLit', 'nkNilLit', 'nkDotCall', 
    'nkCommand', 'nkCall', 'nkGenericCall', 'nkExplicitTypeListCall', 
    'nkExprEqExpr', 'nkExprColonExpr', 'nkIdentDefs', 'nkInfix', 
    'nkPrefix', 'nkPostfix', 'nkPar', 'nkCurly', 
    'nkBracket', 'nkBracketExpr', 'nkPragmaExpr', 'nkRange', 
    'nkDotExpr', 'nkCheckedFieldExpr', 'nkDerefExpr', 'nkIfExpr', 
    'nkElifExpr', 'nkElseExpr', 'nkLambda', 'nkAccQuoted', 
    'nkHeaderQuoted', 'nkSetConstr', 'nkConstSetConstr', 'nkArrayConstr', 
    'nkConstArrayConstr', 'nkRecordConstr', 'nkConstRecordConstr', 'nkTableConstr', 
    'nkConstTableConstr', 'nkQualified', 'nkHiddenStdConv', 'nkHiddenSubConv', 
    'nkHiddenCallConv', 'nkConv', 'nkCast', 'nkAddr', 
    'nkAsgn', 'nkDefaultTypeParam', 'nkGenericParams', 'nkFormalParams', 
    'nkOfInherit', 'nkModule', 'nkProcDef', 'nkConverterDef', 
    'nkMacroDef', 'nkTemplateDef', 'nkIteratorDef', 'nkOfBranch', 
    'nkElifBranch', 'nkExceptBranch', 'nkElse', 'nkMacroStmt', 
    'nkAsmStmt', 'nkPragma', 'nkIfStmt', 'nkWhenStmt', 
    'nkForStmt', 'nkWhileStmt', 'nkCaseStmt', 'nkVarSection', 
    'nkConstSection', 'nkConstDef', 'nkTypeSection', 'nkTypeDef', 
    'nkYieldStmt', 'nkTryStmt', 'nkFinally', 'nkRaiseStmt', 
    'nkReturnStmt', 'nkBreakStmt', 'nkContinueStmt', 'nkBlockStmt', 
    'nkGotoStmt', 'nkDiscardStmt', 'nkStmtList', 'nkImportStmt', 
    'nkFromStmt', 'nkImportAs', 'nkIncludeStmt', 'nkAccessStmt', 
    'nkCommentStmt', 'nkStmtListExpr', 'nkBlockExpr', 'nkVm', 
    'nkTypeOfExpr', 'nkRecordTy', 'nkObjectTy', 'nkRecList', 
    'nkRecCase', 'nkRecWhen', 'nkRefTy', 'nkPtrTy', 
    'nkVarTy', 'nkProcTy', 'nkEnumTy', 'nkEnumFieldDef');
type
  TSymFlag = (
    sfGeneric, sfForward, sfImportc, sfExportc, 
    sfVolatile, sfUsed, sfWrite, sfRegister, 
    sfPure, sfCodeGenerated, sfPrivate, sfGlobal, 
    sfResult, sfNoSideEffect, sfMainModule, sfSystemModule, 
    sfNoReturn, sfReturnsNew, sfInInterface, sfNoStatic, 
    sfCompilerProc, sfCppMethod, sfDiscriminant, sfDeprecated, 
    sfInClosure, sfIsCopy, sfStar, sfMinus);
  TSymFlags = set of TSymFlag;
const
  SymFlagToStr: array [TSymFlag] of string = (
    'sfGeneric', 'sfForward', 'sfImportc', 'sfExportc', 
    'sfVolatile', 'sfUsed', 'sfWrite', 'sfRegister', 
    'sfPure', 'sfCodeGenerated', 'sfPrivate', 'sfGlobal', 
    'sfResult', 'sfNoSideEffect', 'sfMainModule', 'sfSystemModule', 
    'sfNoReturn', 'sfReturnsNew', 'sfInInterface', 'sfNoStatic', 
    'sfCompilerProc', 'sfCppMethod', 'sfDiscriminant', 'sfDeprecated', 
    'sfInClosure', 'sfIsCopy', 'sfStar', 'sfMinus');
type
  TTypeKind = (
    tyNone, tyBool, tyChar, tyEmptySet, 
    tyArrayConstr, tyNil, tyRecordConstr, tyGeneric, 
    tyGenericInst, tyGenericParam, tyEnum, tyAnyEnum, 
    tyArray, tyRecord, tyObject, tyTuple, 
    tySet, tyRange, tyPtr, tyRef, 
    tyVar, tySequence, tyProc, tyPointer, 
    tyOpenArray, tyString, tyCString, tyForward, 
    tyInt, tyInt8, tyInt16, tyInt32, 
    tyInt64, tyFloat, tyFloat32, tyFloat64, 
    tyFloat128);
  TTypeKinds = set of TTypeKind;
const
  TypeKindToStr: array [TTypeKind] of string = (
    'tyNone', 'tyBool', 'tyChar', 'tyEmptySet', 
    'tyArrayConstr', 'tyNil', 'tyRecordConstr', 'tyGeneric', 
    'tyGenericInst', 'tyGenericParam', 'tyEnum', 'tyAnyEnum', 
    'tyArray', 'tyRecord', 'tyObject', 'tyTuple', 
    'tySet', 'tyRange', 'tyPtr', 'tyRef', 
    'tyVar', 'tySequence', 'tyProc', 'tyPointer', 
    'tyOpenArray', 'tyString', 'tyCString', 'tyForward', 
    'tyInt', 'tyInt8', 'tyInt16', 'tyInt32', 
    'tyInt64', 'tyFloat', 'tyFloat32', 'tyFloat64', 
    'tyFloat128');
type
  TTypeFlag = (
    tfIsDistinct, tfGeneric, tfExternal, tfImported, 
    tfInfoGenerated, tfSemChecked, tfHasOutParams, tfEnumHasWholes, 
    tfVarargs, tfAssignable);
  TTypeFlags = set of TTypeFlag;
const
  TypeFlagToStr: array [TTypeFlag] of string = (
    'tfIsDistinct', 'tfGeneric', 'tfExternal', 'tfImported', 
    'tfInfoGenerated', 'tfSemChecked', 'tfHasOutParams', 'tfEnumHasWholes', 
    'tfVarargs', 'tfAssignable');
{[[[end]]]}

type
  // symbols that require compiler magic:
  TMagic = (
    //[[[cog
    //magics = eval(file("data/magic.yml").read())
    //for i in range(0, len(magics)-1):
    //  cog.out("m" + magics[i] + ", ")
    //  if (i+1) % 6 == 0: cog.outl("")
    //cog.outl("m" + magics[-1])
    //]]]
    mNone, mDefined, mNew, mNewFinalize, mLow, mHigh, 
    mSizeOf, mRegisterFinalizer, mSucc, mPred, mInc, mDec, 
    mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq, mIncl, mExcl, 
    mCard, mOrd, mChr, mAddI, mSubI, mMulI, 
    mDivI, mModI, mAddI64, mSubI64, mMulI64, mDivI64, 
    mModI64, mShrI, mShlI, mBitandI, mBitorI, mBitxorI, 
    mMinI, mMaxI, mShrI64, mShlI64, mBitandI64, mBitorI64, 
    mBitxorI64, mMinI64, mMaxI64, mAddF64, mSubF64, mMulF64, 
    mDivF64, mMinF64, mMaxF64, mAddU, mSubU, mMulU, 
    mDivU, mModU, mAddU64, mSubU64, mMulU64, mDivU64, 
    mModU64, mEqI, mLeI, mLtI, mEqI64, mLeI64, 
    mLtI64, mEqF64, mLeF64, mLtF64, mLeU, mLtU, 
    mLeU64, mLtU64, mEqEnum, mLeEnum, mLtEnum, mEqCh, 
    mLeCh, mLtCh, mEqB, mLeB, mLtB, mEqRef, 
    mEqProc, mEqUntracedRef, mLePtr, mLtPtr, mEqCString, mXor, 
    mUnaryMinusI, mUnaryMinusI64, mAbsI, mAbsI64, mNot, mUnaryPlusI, 
    mBitnotI, mUnaryPlusI64, mBitnotI64, mUnaryPlusF64, mUnaryMinusF64, mAbsF64, 
    mZe, mZe64, mToU8, mToU16, mToU32, mToFloat, 
    mToBiggestFloat, mToInt, mToBiggestInt, mAnd, mOr, mEqStr, 
    mLeStr, mLtStr, mEqSet, mLeSet, mLtSet, mMulSet, 
    mPlusSet, mMinusSet, mSymDiffSet, mConStrStr, mConArrArr, mConArrT, 
    mConTArr, mConTT, mSlice, mAppendStrCh, mAppendStrStr, mAppendSeqElem, 
    mAppendSeqSeq, mInRange, mInSet, mIs, mAsgn, mRepr, 
    mExit, mSetLengthStr, mSetLengthSeq, mAssert, mSwap, mArray, 
    mOpenArray, mRange, mTuple, mSet, mSeq, mCompileDate, 
    mCompileTime, mNimrodVersion, mNimrodMajor, mNimrodMinor, mNimrodPatch, mCpuEndian
    //[[[end]]]
  );

type
  PNode = ^TNode;
  TNodeSeq = array of PNode;

  PType = ^TType;
  PSym = ^TSym;

  TNode = {@ignore} record // keep this below 32 bytes;
                           // otherwise the AST grows too much
    typ: PType;
    strVal: string;
    comment: string;
    sons: TNodeSeq; // else!
    info: TLineInfo;
    base: TNumericalBase; // only valid for int or float literals
    case Kind: TNodeKind of
      nkCharLit, nkRCharLit, 
      nkIntLit, nkInt8Lit, nkInt16Lit, nkInt32Lit, nkInt64Lit:
        (intVal: biggestInt);
      nkFloatLit, nkFloat32Lit, nkFloat64Lit:
        (floatVal: biggestFloat);
      nkSym: (sym: PSym);
      nkIdent: (ident: PIdent);
  end;
  {@emit
  record // keep this below 32 bytes; otherwise the AST grows too much
    typ: PType;
    comment: string;
    info: TLineInfo;
    base: TNumericalBase; // only valid for int or float literals
    case Kind: TNodeKind of
      nkCharLit..nkInt64Lit:
        (intVal: biggestInt);
      nkFloatLit..nkFloat64Lit:
        (floatVal: biggestFloat);
      nkStrLit..nkTripleStrLit:
        (strVal: string);
      nkSym: (sym: PSym);
      nkIdent: (ident: PIdent);
      else (sons: TNodeSeq);
  end; }

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
    locImmediate,  // location is an immediate value
    locProc,       // location is a proc (an address of a procedure)
    locData,       // location is a constant
    locCall,       // location is a call expression
    locOther       // location is something other
  );

  TLocFlag = (
  //  lfIndirect,    // location needs to be derefered
    lfOnStack,     // location is on hardware stack
    lfOnHeap,      // location is on heap
    lfOnData,      // location is in the static constant data
    lfOnUnknown,   // location is unknown (stack, heap or static)
                   // other backend-flags:
    lfNoDeepCopy,  // no need for a deep copy
    lfNoDecl,      // do not declare it in C
    lfDynamicLib,  // link symbol to dynamic library
    lfHeader       // include header file for symbol
  );

  TLocFlags = set of TLocFlag;
  TLoc = record
    k: TLocKind;    // kind of location
    t: PType;       // type of location
    r: PRope;       // rope value of location (C code generator)
    a: int;         // location's "address", i.e. slot for temporaries
    flags: TLocFlags;  // location's flags
    indirect: int;  // count the number of dereferences needed to access the
                    // location
  end;

// ---------------- end of backend information ------------------------------

  TSym = object(TIdObj)      // symbols are identical iff they have the same
                             // id!
    kind: TSymKind;
    typ: PType;
    name: PIdent;
    info: TLineInfo;
    owner: PSym;
    flags: TSymFlags;
    magic: TMagic;
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
    annex: PObject;          // additional fields (seldom used, so we use a
                             // reference to another object to safe space)
  end;

  PTypeSeq = array of PType;
  TType = object(TIdObj)     // types are identical iff they have the
                             // same id; there may be multiple copies of a type
                             // in memory!
    kind: TTypeKind;         // kind of type
    sons: PTypeSeq;          // base types, etc.
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

  // these are not part of the syntax tree, but nevertherless inherit from TNode
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
    val: PNode;
  end;
  TNodePairSeq = array of TNodePair;

  TNodeTable = record // the same as table[PNode] of PNode;
                      // nodes are compared by structure!
    counter: int;
    data: TNodePairSeq;
  end;

  TObjectSeq = array of PObject;

  TObjectSet = record
    counter: int;
    data: TObjectSeq;
  end;
  TLibKind = (libHeader, libDynamic, libDynamicGenerated);
  TLib = object(lists.TListEntry) // also misused for headers!
    kind: TLibKind;
    // needed for the backends:
    name: PRope;
    path: string;
    syms: TObjectSet;
  end;
  PLib = ^TLib;

const
  OverloadableSyms = {@set}[skProc, skIterator, skEnumField];

const // "MagicToStr" array:
  MagicToStr: array [TMagic] of string = (
    //[[[cog
    //for i in range(0, len(magics)-1):
    //  cog.out("'%s', " % magics[i])
    //  if (i+1) % 6 == 0: cog.outl("")
    //cog.outl("'%s'" % magics[-1])
    //]]]
    'None', 'Defined', 'New', 'NewFinalize', 'Low', 'High', 
    'SizeOf', 'RegisterFinalizer', 'Succ', 'Pred', 'Inc', 'Dec', 
    'LengthOpenArray', 'LengthStr', 'LengthArray', 'LengthSeq', 'Incl', 'Excl', 
    'Card', 'Ord', 'Chr', 'AddI', 'SubI', 'MulI', 
    'DivI', 'ModI', 'AddI64', 'SubI64', 'MulI64', 'DivI64', 
    'ModI64', 'ShrI', 'ShlI', 'BitandI', 'BitorI', 'BitxorI', 
    'MinI', 'MaxI', 'ShrI64', 'ShlI64', 'BitandI64', 'BitorI64', 
    'BitxorI64', 'MinI64', 'MaxI64', 'AddF64', 'SubF64', 'MulF64', 
    'DivF64', 'MinF64', 'MaxF64', 'AddU', 'SubU', 'MulU', 
    'DivU', 'ModU', 'AddU64', 'SubU64', 'MulU64', 'DivU64', 
    'ModU64', 'EqI', 'LeI', 'LtI', 'EqI64', 'LeI64', 
    'LtI64', 'EqF64', 'LeF64', 'LtF64', 'LeU', 'LtU', 
    'LeU64', 'LtU64', 'EqEnum', 'LeEnum', 'LtEnum', 'EqCh', 
    'LeCh', 'LtCh', 'EqB', 'LeB', 'LtB', 'EqRef', 
    'EqProc', 'EqUntracedRef', 'LePtr', 'LtPtr', 'EqCString', 'Xor', 
    'UnaryMinusI', 'UnaryMinusI64', 'AbsI', 'AbsI64', 'Not', 'UnaryPlusI', 
    'BitnotI', 'UnaryPlusI64', 'BitnotI64', 'UnaryPlusF64', 'UnaryMinusF64', 'AbsF64', 
    'Ze', 'Ze64', 'ToU8', 'ToU16', 'ToU32', 'ToFloat', 
    'ToBiggestFloat', 'ToInt', 'ToBiggestInt', 'And', 'Or', 'EqStr', 
    'LeStr', 'LtStr', 'EqSet', 'LeSet', 'LtSet', 'MulSet', 
    'PlusSet', 'MinusSet', 'SymDiffSet', 'ConStrStr', 'ConArrArr', 'ConArrT', 
    'ConTArr', 'ConTT', 'Slice', 'AppendStrCh', 'AppendStrStr', 'AppendSeqElem', 
    'AppendSeqSeq', 'InRange', 'InSet', 'Is', 'Asgn', 'Repr', 
    'Exit', 'SetLengthStr', 'SetLengthSeq', 'Assert', 'Swap', 'Array', 
    'OpenArray', 'Range', 'Tuple', 'Set', 'Seq', 'CompileDate', 
    'CompileTime', 'NimrodVersion', 'NimrodMajor', 'NimrodMinor', 'NimrodPatch', 'CpuEndian'
    //[[[end]]]
  );

const
  GenericTypes: TTypeKinds = {@set}[tyGeneric, tyGenericParam];

  StructuralEquivTypes: TTypeKinds = {@set}[
    tyEmptySet, tyArrayConstr, tyNil, tyRecordConstr, tyTuple,
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
    tyBool, tyChar, tyEnum, tyArray, tyRecord, tyObject, tySet, tyTuple,
    tyRange, tyPtr, tyRef, tyVar, tySequence, tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCString,
    tyInt..tyInt64,
    tyFloat..tyFloat128
  ];
  ConstantDataTypes: TTypeKinds = {@set}[tyArray, tyRecord, tySet, tyTuple];
  ExportableSymKinds = {@set}[skVar, skConst, skProc, skType, skEnumField,
                              skIterator, skMacro, skTemplate];
  namePos = 0;
  genericParamsPos = 1;
  paramsPos = 2;
  pragmasPos = 3;
  codePos = 4;
  resultPos = 5;

function getID: int;
procedure setID(id: int);

// creator procs:
function NewSym(symKind: TSymKind; Name: PIdent; owner: PSym): PSym;

function NewType(kind: TTypeKind; owner: PSym): PType; overload;

function newNode(kind: TNodeKind): PNode;
function newIntNode(kind: TNodeKind; const intVal: BiggestInt): PNode;
function newIntTypeNode(kind: TNodeKind; const intVal: BiggestInt;
                        typ: PType): PNode;
function newFloatNode(kind: TNodeKind; const floatVal: BiggestFloat): PNode;
function newStrNode(kind: TNodeKind; const strVal: string): PNode;
function newIdentNode(ident: PIdent): PNode;
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
function copyType(t: PType; owner: PSym): PType;
function copySym(s: PSym; owner: PSym): PSym;
procedure assignType(dest, src: PType);

procedure copyStrTable(out dest: TStrTable; const src: TStrTable);
procedure copyTable(out dest: TTable; const src: TTable);
procedure copyObjectSet(out dest: TObjectSet; const src: TObjectSet);

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

implementation

var
  gId: int;

function getID: int;
begin
  inc(gId);
  result := gId
end;

procedure setId(id: int);
begin
  gId := max(gId, id)
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
    else assert(false);
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
    else assert(false);
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
      assert(false);
      result := ''
    end
  end
end;

procedure copyStrTable(out dest: TStrTable; const src: TStrTable);
var
  i: int;
begin
  dest.counter := src.counter;
  setLength(dest.data, length(src.data));
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure copyTable(out dest: TTable; const src: TTable);
var
  i: int;
begin
  dest.counter := src.counter;
  setLength(dest.data, length(src.data));
  for i := 0 to high(src.data) do
    dest.data[i] := src.data[i];
end;

procedure copyObjectSet(out dest: TObjectSet; const src: TObjectSet);
var
  i: int;
begin
  dest.counter := src.counter;
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
  result.info := UnknownLineInfo;
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

function newIdentNode(ident: PIdent): PNode;
begin
  result := newNode(nkIdent);
  result.ident := ident
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
  result.id := getID()
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
  newSons(dest, sonsLen(src));
  for i := 0 to sonsLen(src)-1 do
    dest.sons[i] := src.sons[i];
end;

function copyType(t: PType; owner: PSym): PType;
begin
  result := newType(t.Kind, owner);
  assignType(result, t);
  if owner = t.owner then result.id := t.id
  else result.id := getID();
  result.sym := t.sym;
  // backend-info should not be copied
end;

function copySym(s: PSym; owner: PSym): PSym;
begin
  result := newSym(s.kind, s.name, owner);
  result.ast := nil; // BUGFIX; was: s.ast which made problems
  result.info := s.info;
  result.typ := s.typ;
  if owner = s.owner then result.id := s.id
  else result.id := getID();
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
  result.info := UnknownLineInfo;
  result.options := gOptions;
  result.owner := owner;
  result.offset := -1;
  result.id := getID()
end;

procedure initStrTable(out x: TStrTable);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initTable(out x: TTable);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initIdTable(out x: TIdTable);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initObjectSet(out x: TObjectSet);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initIdNodeTable(out x: TIdNodeTable);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

procedure initNodeTable(out x: TNodeTable);
begin
  x.counter := 0;
{@emit
  x.data := []; }
  setLength(x.data, startSize);
{@ignore}
  fillChar(x.data[0], length(x.data)*sizeof(x.data[0]), 0);
{@emit}
end;

function sonsLen(n: PType): int;
begin
  if n.sons = nil then result := 0
  else result := length(n.sons)
end;

procedure newSons(father: PType; len: int);
var
  i, L: int;
begin
{@emit
  if father.sons = nil then father.sons := []; }
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
{@emit
  if father.sons = nil then father.sons := []; }
  L := length(father.sons);
  setLength(father.sons, L+1);
  father.sons[L] := son;
end;

function sonsLen(n: PNode): int;
begin
  if n.sons = nil then result := 0
  else result := length(n.sons)
end;

procedure newSons(father: PNode; len: int);
var
  i, L: int;
begin
{@emit
  if father.sons = nil then father.sons := []; }
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
{@emit
  if father.sons = nil then father.sons := []; }
  L := length(father.sons);
  setLength(father.sons, L+1);
  father.sons[L] := son;
end;

procedure delSon(father: PNode; idx: int);
var
  len, i: int;
begin
{@emit
  if father.sons = nil then exit; }
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
  result.base := src.base;
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
    else begin end;
  end;
end;

function copyTree(src: PNode): PNode;
// copy a whole syntax tree; performs deep copying
var
  i: int;
begin
  if src = nil then begin result := nil; exit end;
  result := copyNode(src);
  result.sons := nil; // BUGFIX
  newSons(result, sonsLen(src));
  for i := 0 to sonsLen(src)-1 do
    result.sons[i] := copyTree(src.sons[i]);
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

end.
