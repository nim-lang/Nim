#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# abstract syntax tree + symbol table

import 
  msgs, hashes, nversion, options, strutils, crc, ropes, idents, lists, 
  intsets, idgen

const
  ImportTablePos* = 0         # imported symbols are at level 0
  ModuleTablePos* = 1         # module's top level symbols are at level 1

type 
  TCallingConvention* = enum 
    ccDefault,                # proc has no explicit calling convention
    ccStdCall,                # procedure is stdcall
    ccCDecl,                  # cdecl
    ccSafeCall,               # safecall
    ccSysCall,                # system call
    ccInline,                 # proc should be inlined
    ccNoInline,               # proc should not be inlined
    ccFastCall,               # fastcall (pass parameters in registers)
    ccClosure,                # proc has a closure
    ccNoConvention            # needed for generating proper C procs sometimes

const 
  CallingConvToStr*: array[TCallingConvention, string] = ["", "stdcall", 
    "cdecl", "safecall", "syscall", "inline", "noinline", "fastcall",
    "closure", "noconv"]

type 
  TNodeKind* = enum # order is extremely important, because ranges are used
                    # to check whether a node belongs to a certain class
    nkNone,               # unknown node kind: indicates an error
                          # Expressions:
                          # Atoms:
    nkEmpty,              # the node is empty
    nkIdent,              # node is an identifier
    nkSym,                # node is a symbol
    nkType,               # node is used for its typ field

    nkCharLit,            # a character literal ''
    nkIntLit,             # an integer literal
    nkInt8Lit,
    nkInt16Lit,
    nkInt32Lit,
    nkInt64Lit,
    nkFloatLit,           # a floating point literal
    nkFloat32Lit,
    nkFloat64Lit,
    nkStrLit,             # a string literal ""
    nkRStrLit,            # a raw string literal r""
    nkTripleStrLit,       # a triple string literal """
    nkNilLit,             # the nil literal
                          # end of atoms
    nkMetaNode,           # difficult to explain; represents itself
                          # (used for macros)
    nkDotCall,            # used to temporarily flag a nkCall node; 
                          # this is used
                          # for transforming ``s.len`` to ``len(s)``
    nkCommand,            # a call like ``p 2, 4`` without parenthesis
    nkCall,               # a call like p(x, y) or an operation like +(a, b)
    nkCallStrLit,         # a call with a string literal 
                          # x"abc" has two sons: nkIdent, nkRStrLit
                          # x"""abc""" has two sons: nkIdent, nkTripleStrLit
    nkExprEqExpr,         # a named parameter with equals: ''expr = expr''
    nkExprColonExpr,      # a named parameter with colon: ''expr: expr''
    nkIdentDefs,          # a definition like `a, b: typeDesc = expr`
                          # either typeDesc or expr may be nil; used in
                          # formal parameters, var statements, etc.
    nkVarTuple,           # a ``var (a, b) = expr`` construct
    nkInfix,              # a call like (a + b)
    nkPrefix,             # a call like !a
    nkPostfix,            # something like a! (also used for visibility)
    nkPar,                # syntactic (); may be a tuple constructor
    nkCurly,              # syntactic {}
    nkCurlyExpr,          # an expression like a{i}
    nkBracket,            # syntactic []
    nkBracketExpr,        # an expression like a[i..j, k]
    nkPragmaExpr,         # an expression like a{.pragmas.}
    nkRange,              # an expression like i..j
    nkDotExpr,            # a.b
    nkCheckedFieldExpr,   # a.b, but b is a field that needs to be checked
    nkDerefExpr,          # a^
    nkIfExpr,             # if as an expression
    nkElifExpr,
    nkElseExpr,
    nkLambda,             # lambda expression
    nkAccQuoted,          # `a` as a node

    nkTableConstr,        # a table constructor {expr: expr}
    nkBind,               # ``bind expr`` node
    nkSymChoice,          # symbol choice node
    nkHiddenStdConv,      # an implicit standard type conversion
    nkHiddenSubConv,      # an implicit type conversion from a subtype
                          # to a supertype
    nkHiddenCallConv,     # an implicit type conversion via a type converter
    nkConv,               # a type conversion
    nkCast,               # a type cast
    nkAddr,               # a addr expression
    nkHiddenAddr,         # implicit address operator
    nkHiddenDeref,        # implicit ^ operator
    nkObjDownConv,        # down conversion between object types
    nkObjUpConv,          # up conversion between object types
    nkChckRangeF,         # range check for floats
    nkChckRange64,        # range check for 64 bit ints
    nkChckRange,          # range check for ints
    nkStringToCString,    # string to cstring
    nkCStringToString,    # cstring to string
                          # end of expressions

    nkAsgn,               # a = b
    nkFastAsgn,           # internal node for a fast ``a = b``
                          # (no string copy) 
    nkGenericParams,      # generic parameters
    nkFormalParams,       # formal parameters
    nkOfInherit,          # inherited from symbol

    nkModule,             # the syntax tree of a module
    nkProcDef,            # a proc
    nkMethodDef,          # a method
    nkConverterDef,       # a converter
    nkMacroDef,           # a macro
    nkTemplateDef,        # a template
    nkIteratorDef,        # an iterator

    nkOfBranch,           # used inside case statements
                          # for (cond, action)-pairs
    nkElifBranch,         # used in if statements
    nkExceptBranch,       # an except section
    nkElse,               # an else part
    nkMacroStmt,          # a macro statement
    nkAsmStmt,            # an assembler block
    nkPragma,             # a pragma statement
    nkIfStmt,             # an if statement
    nkWhenStmt,           # a when statement
    nkForStmt,            # a for statement
    nkWhileStmt,          # a while statement
    nkCaseStmt,           # a case statement
    nkTypeSection,        # a type section (consists of type definitions)
    nkVarSection,         # a var section
    nkLetSection,         # a let section
    nkConstSection,       # a const section
    nkConstDef,           # a const definition
    nkTypeDef,            # a type definition
    nkYieldStmt,          # the yield statement as a tree
    nkTryStmt,            # a try statement
    nkFinally,            # a finally section
    nkRaiseStmt,          # a raise statement
    nkReturnStmt,         # a return statement
    nkBreakStmt,          # a break statement
    nkContinueStmt,       # a continue statement
    nkBlockStmt,          # a block statement
    nkDiscardStmt,        # a discard statement
    nkStmtList,           # a list of statements
    nkImportStmt,         # an import statement
    nkFromStmt,           # a from * import statement
    nkIncludeStmt,        # an include statement
    nkBindStmt,           # a bind statement
    nkCommentStmt,        # a comment statement
    nkStmtListExpr,       # a statement list followed by an expr; this is used
                          # to allow powerful multi-line templates
    nkBlockExpr,          # a statement block ending in an expr; this is used
                          # to allowe powerful multi-line templates that open a
                          # temporary scope
    nkStmtListType,       # a statement list ending in a type; for macros
    nkBlockType,          # a statement block ending in a type; for macros
                          # types as syntactic trees:
    nkTypeOfExpr,         # type(1+2)
    nkObjectTy,           # object body
    nkTupleTy,            # tuple body
    nkRecList,            # list of object parts
    nkRecCase,            # case section of object
    nkRecWhen,            # when section of object
    nkRefTy,              # ``ref T``
    nkPtrTy,              # ``ptr T``
    nkVarTy,              # ``var T``
    nkConstTy,            # ``const T``
    nkMutableTy,          # ``mutable T``
    nkDistinctTy,         # distinct type
    nkProcTy,             # proc type
    nkEnumTy,             # enum body
    nkEnumFieldDef,       # `ident = expr` in an enumeration
    nkReturnToken         # token used for interpretation
  TNodeKinds* = set[TNodeKind]

type
  TSymFlag* = enum    # already 30 flags!
    sfUsed,           # read access of sym (for warnings) or simply used
    sfExported,       # symbol is exported from module
    sfFromGeneric,    # symbol is instantiation of a generic; this is needed 
                      # for symbol file generation; such symbols should always
                      # be written into the ROD file
    sfGlobal,         # symbol is at global scope

    sfForward,        # symbol is forward declared
    sfImportc,        # symbol is external; imported
    sfExportc,        # symbol is exported (under a specified name)
    sfVolatile,       # variable is volatile
    sfRegister,       # variable should be placed in a register
    sfPure,           # object is "pure" that means it has no type-information
    
    sfNoSideEffect,   # proc has no side effects
    sfSideEffect,     # proc may have side effects; cannot prove it has none
    sfMainModule,     # module is the main module
    sfSystemModule,   # module is the system module
    sfNoReturn,       # proc never returns (an exit proc)
    sfAddrTaken,      # the variable's address is taken (ex- or implicitely)
    sfCompilerProc,   # proc is a compiler proc, that is a C proc that is
                      # needed for the code generator
    sfProcvar,        # proc can be passed to a proc var
    sfDiscriminant,   # field is a discriminant in a record/object
    sfDeprecated,     # symbol is deprecated
    sfError,          # usage of symbol should trigger a compile-time error
    sfInClosure,      # variable is accessed by a closure
    sfThread,         # proc will run as a thread
                      # variable is a thread variable
    sfCompileTime,    # proc can be evaluated at compile time
    sfMerge,          # proc can be merged with itself
    sfDeadCodeElim,   # dead code elimination for the module is turned on
    sfBorrow,         # proc is borrowed
    sfInfixCall,      # symbol needs infix call syntax in target language;
                      # for interfacing with C++, JS
    sfNamedParamCall, # symbol needs named parameter call syntax in target
                      # language; for interfacing with Objective C
    sfDiscardable     # returned value may be discarded implicitely

  TSymFlags* = set[TSymFlag]

const
  sfFakeConst* = sfDeadCodeElim  # const cannot be put into a data section
  sfDispatcher* = sfDeadCodeElim # copied method symbol is the dispatcher
  sfNoInit* = sfMainModule       # don't generate code to init the variable

type
  TTypeKind* = enum  # order is important!
                     # Don't forget to change hti.nim if you make a change here
                     # XXX put this into an include file to avoid this issue!
    tyNone, tyBool, tyChar,
    tyEmpty, tyArrayConstr, tyNil, tyExpr, tyStmt, tyTypeDesc,
    tyGenericInvokation, # ``T[a, b]`` for types to invoke
    tyGenericBody,       # ``T[a, b, body]`` last parameter is the body
    tyGenericInst,       # ``T[a, b, realInstance]`` instantiated generic type
    tyGenericParam,      # ``a`` in the above patterns
    tyDistinct,
    tyEnum,
    tyOrdinal,           # misnamed: should become 'tyConstraint'
    tyArray,
    tyObject,
    tyTuple,
    tySet,
    tyRange,
    tyPtr, tyRef,
    tyVar,
    tySequence,
    tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCString, tyForward,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64, # signed integers
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64,
    tyBigNum, 
    tyConst, tyMutable, tyVarargs, 
    tyIter, # unused
    tyProxy # currently unused

const
  tyPureObject* = tyTuple
  GcTypeKinds* = {tyRef, tySequence, tyString}

type
  TTypeKinds* = set[TTypeKind]

  TNodeFlag* = enum
    nfNone,
    nfBase2,    # nfBase10 is default, so not needed
    nfBase8,
    nfBase16,
    nfAllConst, # used to mark complex expressions constant; easy to get rid of
                # but unfortunately it has measurable impact for compilation
                # efficiency
    nfTransf,   # node has been transformed
    nfSem       # node has been checked for semantics

  TNodeFlags* = set[TNodeFlag]
  TTypeFlag* = enum 
    tfVarargs,        # procedure has C styled varargs
    tfNoSideEffect,   # procedure type does not allow side effects
    tfFinal,          # is the object final?
    tfAcyclic,        # type is acyclic (for GC optimization)
    tfEnumHasHoles,   # enum cannot be mapped into a range
    tfShallow,        # type can be shallow copied on assignment
    tfThread,         # proc type is marked as ``thread``
    tfFromGeneric     # type is an instantiation of a generic; this is needed
                      # because for instantiations of objects, structural
                      # type equality has to be used

  TTypeFlags* = set[TTypeFlag]

  TSymKind* = enum        # the different symbols (start with the prefix sk);
                          # order is important for the documentation generator!
    skUnknown,            # unknown symbol: used for parsing assembler blocks
                          # and first phase symbol lookup in generics
    skConditional,        # symbol for the preprocessor (may become obsolete)
    skDynLib,             # symbol represents a dynamic library; this is used
                          # internally; it does not exist in Nimrod code
    skParam,              # a parameter
    skGenericParam,       # a generic parameter; eq in ``proc x[eq=`==`]()``
    skTemp,               # a temporary variable (introduced by compiler)
    skModule,             # module identifier
    skType,               # a type
    skVar,                # a variable
    skLet,                # a 'let' symbol
    skConst,              # a constant
    skResult,             # special 'result' variable
    skProc,               # a proc
    skMethod,             # a method
    skIterator,           # an iterator
    skConverter,          # a type converter
    skMacro,              # a macro
    skTemplate,           # a template; currently also misused for user-defined
                          # pragmas
    skField,              # a field in a record or object
    skEnumField,          # an identifier in an enum
    skForVar,             # a for loop variable
    skLabel,              # a label (for block statement)
    skStub                # symbol is a stub and not yet loaded from the ROD
                          # file (it is loaded on demand, which may
                          # mean: never)
  TSymKinds* = set[TSymKind]

const
  routineKinds* = {skProc, skMethod, skIterator, skConverter,
    skMacro, skTemplate}

type
  TMagic* = enum # symbols that require compiler magic:
    mNone, mDefined, mDefinedInScope, mLow, mHigh, mSizeOf, mIs, mOf,
    mEcho, mShallowCopy, mSlurp,
    mParseExprToAst, mParseStmtToAst, mExpandToAst,
    mUnaryLt, mSucc, 
    mPred, mInc, mDec, mOrd, mNew, mNewFinalize, mNewSeq, mLengthOpenArray, 
    mLengthStr, mLengthArray, mLengthSeq, mIncl, mExcl, mCard, mChr, mGCref, 
    mGCunref, mAddI, mSubI, mMulI, mDivI, mModI, mAddI64, mSubI64, mMulI64, 
    mDivI64, mModI64,
    mAddF64, mSubF64, mMulF64, mDivF64,
    mShrI, mShlI, mBitandI, mBitorI, mBitxorI, mMinI, mMaxI, 
    mShrI64, mShlI64, mBitandI64, mBitorI64, mBitxorI64, mMinI64, mMaxI64,
    mMinF64, mMaxF64, mAddU, mSubU, mMulU, 
    mDivU, mModU, mAddU64, mSubU64, mMulU64, mDivU64, mModU64, mEqI, mLeI,
    mLtI, 
    mEqI64, mLeI64, mLtI64, mEqF64, mLeF64, mLtF64, 
    mLeU, mLtU, mLeU64, mLtU64, 
    mEqEnum, mLeEnum, mLtEnum, mEqCh, mLeCh, mLtCh, mEqB, mLeB, mLtB, mEqRef, 
    mEqProc, mEqUntracedRef, mLePtr, mLtPtr, mEqCString, mXor, mUnaryMinusI, 
    mUnaryMinusI64, mAbsI, mAbsI64, mNot, 
    mUnaryPlusI, mBitnotI, mUnaryPlusI64, 
    mBitnotI64, mUnaryPlusF64, mUnaryMinusF64, mAbsF64, mZe8ToI, mZe8ToI64, 
    mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64, mToU8, mToU16, mToU32, 
    mToFloat, mToBiggestFloat, mToInt, mToBiggestInt, mCharToStr, mBoolToStr, 
    mIntToStr, mInt64ToStr, mFloatToStr, mCStrToStr, mStrToStr, mEnumToStr, 
    mAnd, mOr, mEqStr, mLeStr, mLtStr, mEqSet, mLeSet, mLtSet, mMulSet, 
    mPlusSet, mMinusSet, mSymDiffSet, mConStrStr, mConArrArr, mConArrT, 
    mConTArr, mConTT, mSlice, 
    mFields, mFieldPairs,
    mAppendStrCh, mAppendStrStr, mAppendSeqElem, 
    mInRange, mInSet, mRepr, mExit, mSetLengthStr, mSetLengthSeq, 
    mIsPartOf, mAstToStr, mRand, 
    mSwap, mIsNil, mArrToSeq, mCopyStr, mCopyStrLast, 
    mNewString, mNewStringOfCap,
    mReset,
    mArray, mOpenArray, mRange, mSet, mSeq, 
    mOrdinal, mInt, mInt8, mInt16, mInt32, 
    mInt64, mFloat, mFloat32, mFloat64, mBool, mChar, mString, mCstring, 
    mPointer, mEmptySet, mIntSetBaseType, mNil, mExpr, mStmt, mTypeDesc, 
    mVoidType,
    mIsMainModule, mCompileDate, mCompileTime, mNimrodVersion, mNimrodMajor, 
    mNimrodMinor, mNimrodPatch, mCpuEndian, mHostOS, mHostCPU, mAppType, 
    mNaN, mInf, mNegInf, 
    mCompileOption, mCompileOptionArg,
    mNLen, mNChild, mNSetChild, mNAdd, mNAddMultiple, mNDel, mNKind, 
    mNIntVal, mNFloatVal, mNSymbol, mNIdent, mNGetType, mNStrVal, mNSetIntVal, 
    mNSetFloatVal, mNSetSymbol, mNSetIdent, mNSetType, mNSetStrVal, mNLineInfo,
    mNNewNimNode, mNCopyNimNode, mNCopyNimTree, mStrToIdent, mIdentToStr, 
    mEqIdent, mEqNimrodNode, mNHint, mNWarning, mNError, mGetTypeInfo

type 
  PNode* = ref TNode
  TNodeSeq* = seq[PNode]
  PType* = ref TType
  PSym* = ref TSym
  TNode*{.acyclic, final.} = object # on a 32bit machine, this takes 32 bytes
    typ*: PType
    comment*: string
    info*: TLineInfo
    flags*: TNodeFlags
    case Kind*: TNodeKind
    of nkCharLit..nkInt64Lit: 
      intVal*: biggestInt
    of nkFloatLit..nkFloat64Lit: 
      floatVal*: biggestFloat
    of nkStrLit..nkTripleStrLit: 
      strVal*: string
    of nkSym: 
      sym*: PSym
    of nkIdent: 
      ident*: PIdent
    else: 
      sons*: TNodeSeq
  
  TSymSeq* = seq[PSym]
  TStrTable* = object         # a table[PIdent] of PSym
    counter*: int
    data*: TSymSeq
  
  # -------------- backend information -------------------------------
  TLocKind* = enum 
    locNone,                  # no location
    locTemp,                  # temporary location
    locLocalVar,              # location is a local variable
    locGlobalVar,             # location is a global variable
    locParam,                 # location is a parameter
    locField,                 # location is a record field
    locArrayElem,             # location is an array element
    locExpr,                  # "location" is really an expression
    locProc,                  # location is a proc (an address of a procedure)
    locData,                  # location is a constant
    locCall,                  # location is a call expression
    locOther                  # location is something other
  TLocFlag* = enum 
    lfIndirect,               # backend introduced a pointer
    lfParamCopy,              # backend introduced a parameter copy (LLVM)
    lfNoDeepCopy,             # no need for a deep copy
    lfNoDecl,                 # do not declare it in C
    lfDynamicLib,             # link symbol to dynamic library
    lfExportLib,              # export symbol for dynamic library generation
    lfHeader,                 # include header file for symbol
    lfImportCompilerProc      # ``importc`` of a compilerproc
  TStorageLoc* = enum 
    OnUnknown,                # location is unknown (stack, heap or static)
    OnStack,                  # location is on hardware stack
    OnHeap                    # location is on heap or global
                              # (reference counting needed)
  TLocFlags* = set[TLocFlag]
  TLoc*{.final.} = object     
    k*: TLocKind              # kind of location
    s*: TStorageLoc
    flags*: TLocFlags         # location's flags
    t*: PType                 # type of location
    r*: PRope                 # rope value of location (code generators)
    a*: int                   # location's "address", i.e. slot for temporaries

  # ---------------- end of backend information ------------------------------

  TLibKind* = enum 
    libHeader, libDynamic
  TLib* = object of lists.TListEntry # also misused for headers!
    kind*: TLibKind
    generated*: bool          # needed for the backends:
    name*: PRope
    path*: PNode              # can be a string literal!
    

  PLib* = ref TLib
  TSym* = object of TIdObj
    kind*: TSymKind
    magic*: TMagic
    typ*: PType
    name*: PIdent
    info*: TLineInfo
    owner*: PSym
    flags*: TSymFlags
    tab*: TStrTable           # interface table for modules
    ast*: PNode               # syntax tree of proc, iterator, etc.:
                              # the whole proc including header; this is used
                              # for easy generation of proper error messages
                              # for variant record fields the discriminant
                              # expression
    options*: TOptions
    position*: int            # used for many different things:
                              # for enum fields its position;
                              # for fields its offset
                              # for parameters its position
                              # for a conditional:
                              # 1 iff the symbol is defined, else 0
                              # (or not in symbol table)
    offset*: int              # offset of record field
    loc*: TLoc
    annex*: PLib              # additional fields (seldom used, so we use a
                              # reference to another object to safe space)
  
  TTypeSeq* = seq[PType]
  TType* = object of TIdObj   # types are identical iff they have the
                              # same id; there may be multiple copies of a type
                              # in memory!
    kind*: TTypeKind          # kind of type
    callConv*: TCallingConvention # for procs
    flags*: TTypeFlags        # flags of the type
    sons*: TTypeSeq           # base types, etc.
    n*: PNode                 # node for types:
                              # for range types a nkRange node
                              # for record types a nkRecord node
                              # for enum types a list of symbols
                              # else: unused
    owner*: PSym              # the 'owner' of the type
    sym*: PSym                # types have the sym associated with them
                              # it is used for converting types to strings
    size*: BiggestInt         # the size of the type in bytes
                              # -1 means that the size is unkwown
    align*: int               # the type's alignment requirements
    containerID*: int         # used for type checking of generics
    loc*: TLoc

  TPair*{.final.} = object 
    key*, val*: PObject

  TPairSeq* = seq[TPair]
  TTable*{.final.} = object   # the same as table[PObject] of PObject
    counter*: int
    data*: TPairSeq

  TIdPair*{.final.} = object 
    key*: PIdObj
    val*: PObject

  TIdPairSeq* = seq[TIdPair]
  TIdTable*{.final.} = object # the same as table[PIdent] of PObject
    counter*: int
    data*: TIdPairSeq

  TIdNodePair*{.final.} = object 
    key*: PIdObj
    val*: PNode

  TIdNodePairSeq* = seq[TIdNodePair]
  TIdNodeTable*{.final.} = object # the same as table[PIdObj] of PNode
    counter*: int
    data*: TIdNodePairSeq

  TNodePair*{.final.} = object 
    h*: THash                 # because it is expensive to compute!
    key*: PNode
    val*: int

  TNodePairSeq* = seq[TNodePair]
  TNodeTable*{.final.} = object # the same as table[PNode] of int;
                                # nodes are compared by structure!
    counter*: int
    data*: TNodePairSeq

  TObjectSeq* = seq[PObject]
  TObjectSet*{.final.} = object 
    counter*: int
    data*: TObjectSeq

# BUGFIX: a module is overloadable so that a proc can have the
# same name as an imported module. This is necessary because of
# the poor naming choices in the standard library.

const 
  OverloadableSyms* = {skProc, skMethod, skIterator, skConverter, skModule}

  GenericTypes*: TTypeKinds = {tyGenericInvokation, tyGenericBody, 
    tyGenericParam}
  StructuralEquivTypes*: TTypeKinds = {tyArrayConstr, tyNil, tyTuple, tyArray, 
    tySet, tyRange, tyPtr, tyRef, tyVar, tySequence, tyProc, tyOpenArray}
  ConcreteTypes*: TTypeKinds = { # types of the expr that may occur in::
                                 # var x = expr
    tyBool, tyChar, tyEnum, tyArray, tyObject, 
    tySet, tyTuple, tyRange, tyPtr, tyRef, tyVar, tySequence, tyProc,
    tyPointer, 
    tyOpenArray, tyString, tyCString, tyInt..tyInt64, tyFloat..tyFloat128,
    tyUInt..tyUInt64}
  IntegralTypes* = {tyBool, tyChar, tyEnum, tyInt..tyInt64,
    tyFloat..tyFloat128, tyUInt..tyUInt64}
  ConstantDataTypes*: TTypeKinds = {tyArrayConstr, tyArray, tySet, 
                                    tyTuple, tySequence}
  ExportableSymKinds* = {skVar, skConst, skProc, skMethod, skType, skIterator, 
    skMacro, skTemplate, skConverter, skEnumField, skLet, skStub}
  PersistentNodeFlags*: TNodeFlags = {nfBase2, nfBase8, nfBase16, nfAllConst}
  namePos* = 0
  genericParamsPos* = 1
  paramsPos* = 2
  pragmasPos* = 3
  bodyPos* = 4       # position of body; use rodread.getBody() instead!
  resultPos* = 5
  dispatcherPos* = 6 # caution: if method has no 'result' it can be position 5!

# creator procs:
proc NewSym*(symKind: TSymKind, Name: PIdent, owner: PSym): PSym
proc NewType*(kind: TTypeKind, owner: PSym): PType
proc newNode*(kind: TNodeKind): PNode
proc newIntNode*(kind: TNodeKind, intVal: BiggestInt): PNode
proc newIntTypeNode*(kind: TNodeKind, intVal: BiggestInt, typ: PType): PNode
proc newFloatNode*(kind: TNodeKind, floatVal: BiggestFloat): PNode
proc newStrNode*(kind: TNodeKind, strVal: string): PNode
proc newIdentNode*(ident: PIdent, info: TLineInfo): PNode
proc newSymNode*(sym: PSym): PNode
proc newNodeI*(kind: TNodeKind, info: TLineInfo): PNode
proc newNodeIT*(kind: TNodeKind, info: TLineInfo, typ: PType): PNode
proc initStrTable*(x: var TStrTable)
proc initTable*(x: var TTable)
proc initIdTable*(x: var TIdTable)
proc initObjectSet*(x: var TObjectSet)
proc initIdNodeTable*(x: var TIdNodeTable)
proc initNodeTable*(x: var TNodeTable)
  
# copy procs:
proc copyType*(t: PType, owner: PSym, keepId: bool): PType
proc copySym*(s: PSym, keepId: bool = false): PSym
proc assignType*(dest, src: PType)
proc copyStrTable*(dest: var TStrTable, src: TStrTable)
proc copyTable*(dest: var TTable, src: TTable)
proc copyObjectSet*(dest: var TObjectSet, src: TObjectSet)
proc copyIdTable*(dest: var TIdTable, src: TIdTable)
proc sonsLen*(n: PNode): int {.inline.}
proc sonsLen*(n: PType): int {.inline.}
proc lastSon*(n: PNode): PNode {.inline.}
proc lastSon*(n: PType): PType {.inline.}
proc newSons*(father: PNode, length: int)
proc newSons*(father: PType, length: int)
proc addSon*(father, son: PNode)
proc addSon*(father, son: PType)
proc delSon*(father: PNode, idx: int)
proc hasSonWith*(n: PNode, kind: TNodeKind): bool
proc hasSubnodeWith*(n: PNode, kind: TNodeKind): bool
proc replaceSons*(n: PNode, oldKind, newKind: TNodeKind)
proc copyNode*(src: PNode): PNode
  # does not copy its sons!
proc copyTree*(src: PNode): PNode
  # does copy its sons!

const nkCallKinds* = {nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
                      nkCallStrLit}

proc isCallExpr*(n: PNode): bool =
  result = n.kind in nkCallKinds

proc discardSons*(father: PNode)

proc len*(n: PNode): int {.inline.} =
  if isNil(n.sons): result = 0
  else: result = len(n.sons)
  
proc safeLen*(n: PNode): int {.inline.} =
  ## works even for leaves.
  if n.kind in {nkNone..nkNilLit} or isNil(n.sons): result = 0
  else: result = len(n.sons)
  
proc add*(father, son: PNode) =
  assert son != nil
  if isNil(father.sons): father.sons = @[]
  add(father.sons, son)
  
proc `[]`*(n: PNode, i: int): PNode {.inline.} =
  result = n.sons[i]

var emptyNode* = newNode(nkEmpty)
# There is a single empty node that is shared! Do not overwrite it!


const                         # for all kind of hash tables:
  GrowthFactor* = 2           # must be power of 2, > 0
  StartSize* = 8              # must be power of 2, > 0

proc ValueToString*(a: PNode): string = 
  case a.kind
  of nkCharLit..nkInt64Lit: result = $(a.intVal)
  of nkFloatLit, nkFloat32Lit, nkFloat64Lit: result = $(a.floatVal)
  of nkStrLit..nkTripleStrLit: result = a.strVal
  else: 
    InternalError(a.info, "valueToString")
    result = ""

proc copyStrTable(dest: var TStrTable, src: TStrTable) = 
  dest.counter = src.counter
  if isNil(src.data): return 
  setlen(dest.data, len(src.data))
  for i in countup(0, high(src.data)): dest.data[i] = src.data[i]
  
proc copyIdTable(dest: var TIdTable, src: TIdTable) = 
  dest.counter = src.counter
  if isNil(src.data): return 
  newSeq(dest.data, len(src.data))
  for i in countup(0, high(src.data)): dest.data[i] = src.data[i]
  
proc copyTable(dest: var TTable, src: TTable) = 
  dest.counter = src.counter
  if isNil(src.data): return 
  setlen(dest.data, len(src.data))
  for i in countup(0, high(src.data)): dest.data[i] = src.data[i]
  
proc copyObjectSet(dest: var TObjectSet, src: TObjectSet) = 
  dest.counter = src.counter
  if isNil(src.data): return 
  setlen(dest.data, len(src.data))
  for i in countup(0, high(src.data)): dest.data[i] = src.data[i]
  
proc discardSons(father: PNode) = 
  father.sons = nil

proc newNode(kind: TNodeKind): PNode = 
  new(result)
  result.kind = kind
  #result.info = UnknownLineInfo() inlined:
  result.info.fileIndex = int32(- 1)
  result.info.col = int16(- 1)
  result.info.line = int16(- 1)

proc newIntNode(kind: TNodeKind, intVal: BiggestInt): PNode = 
  result = newNode(kind)
  result.intVal = intVal

proc newIntTypeNode(kind: TNodeKind, intVal: BiggestInt, typ: PType): PNode = 
  result = newIntNode(kind, intVal)
  result.typ = typ

proc newFloatNode(kind: TNodeKind, floatVal: BiggestFloat): PNode = 
  result = newNode(kind)
  result.floatVal = floatVal

proc newStrNode(kind: TNodeKind, strVal: string): PNode = 
  result = newNode(kind)
  result.strVal = strVal

proc newIdentNode(ident: PIdent, info: TLineInfo): PNode = 
  result = newNode(nkIdent)
  result.ident = ident
  result.info = info

proc newSymNode(sym: PSym): PNode = 
  result = newNode(nkSym)
  result.sym = sym
  result.typ = sym.typ
  result.info = sym.info

proc newSymNode*(sym: PSym, info: TLineInfo): PNode = 
  result = newNode(nkSym)
  result.sym = sym
  result.typ = sym.typ
  result.info = info

proc newNodeI(kind: TNodeKind, info: TLineInfo): PNode = 
  result = newNode(kind)
  result.info = info

proc newNodeIT(kind: TNodeKind, info: TLineInfo, typ: PType): PNode = 
  result = newNode(kind)
  result.info = info
  result.typ = typ

proc newMetaNodeIT*(tree: PNode, info: TLineInfo, typ: PType): PNode =
  result = newNodeIT(nkMetaNode, info, typ)
  result.add(tree)

proc NewType(kind: TTypeKind, owner: PSym): PType = 
  new(result)
  result.kind = kind
  result.owner = owner
  result.size = - 1
  result.align = 2            # default alignment
  result.id = getID()
  when debugIds: 
    RegisterId(result)        
  #if result.id < 2000 then
  #  MessageOut(typeKindToStr[kind] & ' has id: ' & toString(result.id))
  
proc mergeLoc(a: var TLoc, b: TLoc) =
  if a.k == low(a.k): a.k = b.k
  if a.s == low(a.s): a.s = b.s
  a.flags = a.flags + b.flags
  if a.t == nil: a.t = b.t
  if a.r == nil: a.r = b.r
  if a.a == 0: a.a = b.a
  
proc assignType(dest, src: PType) = 
  dest.kind = src.kind
  dest.flags = src.flags
  dest.callConv = src.callConv
  dest.n = src.n
  dest.size = src.size
  dest.align = src.align
  dest.containerID = src.containerID
  # this fixes 'type TLock = TSysLock':
  if src.sym != nil:
    if dest.sym != nil:
      dest.sym.flags = dest.sym.flags + src.sym.flags
      if dest.sym.annex == nil: dest.sym.annex = src.sym.annex
      mergeLoc(dest.sym.loc, src.sym.loc)
    else:
      dest.sym = src.sym
  newSons(dest, sonsLen(src))
  for i in countup(0, sonsLen(src) - 1): dest.sons[i] = src.sons[i]
  
proc copyType(t: PType, owner: PSym, keepId: bool): PType = 
  result = newType(t.Kind, owner)
  assignType(result, t)
  if keepId: 
    result.id = t.id
  else: 
    result.id = getID()
    when debugIds: RegisterId(result)
  result.sym = t.sym          # backend-info should not be copied
  
proc copySym(s: PSym, keepId: bool = false): PSym = 
  result = newSym(s.kind, s.name, s.owner)
  result.ast = nil            # BUGFIX; was: s.ast which made problems
  result.info = s.info
  result.typ = s.typ
  if keepId: 
    result.id = s.id
  else: 
    result.id = getID()
    when debugIds: RegisterId(result)
  result.flags = s.flags
  result.magic = s.magic
  copyStrTable(result.tab, s.tab)
  result.options = s.options
  result.position = s.position
  result.loc = s.loc
  result.annex = s.annex      # BUGFIX
  
proc NewSym(symKind: TSymKind, Name: PIdent, owner: PSym): PSym = 
  # generates a symbol and initializes the hash field too
  new(result)
  result.Name = Name
  result.Kind = symKind
  result.flags = {}
  result.info = UnknownLineInfo()
  result.options = gOptions
  result.owner = owner
  result.offset = - 1
  result.id = getID()
  when debugIds: 
    RegisterId(result)
  #if result.id < 2000:
  #  MessageOut(name.s & " has id: " & toString(result.id))
  
proc initStrTable(x: var TStrTable) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc initTable(x: var TTable) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc initIdTable(x: var TIdTable) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc initObjectSet(x: var TObjectSet) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc initIdNodeTable(x: var TIdNodeTable) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc initNodeTable(x: var TNodeTable) = 
  x.counter = 0
  newSeq(x.data, startSize)

proc sonsLen(n: PType): int = 
  if isNil(n.sons): result = 0
  else: result = len(n.sons)

proc len*(n: PType): int = 
  if isNil(n.sons): result = 0
  else: result = len(n.sons)
  
proc newSons(father: PType, length: int) = 
  if isNil(father.sons): father.sons = @[]
  setlen(father.sons, len(father.sons) + length)

proc addSon(father, son: PType) = 
  if isNil(father.sons): father.sons = @[]
  add(father.sons, son)
  #assert((father.kind != tyGenericInvokation) or (son.kind != tyGenericInst))

proc sonsLen(n: PNode): int = 
  if isNil(n.sons): result = 0
  else: result = len(n.sons)
  
proc newSons(father: PNode, length: int) = 
  if isNil(father.sons): father.sons = @[]
  setlen(father.sons, len(father.sons) + length)

proc addSon(father, son: PNode) = 
  assert son != nil
  if isNil(father.sons): father.sons = @[]
  add(father.sons, son)

proc addSonNilAllowed*(father, son: PNode) =
  if isNil(father.sons): father.sons = @[]
  add(father.sons, son)

proc delSon(father: PNode, idx: int) = 
  if isNil(father.sons): return 
  var length = sonsLen(father)
  for i in countup(idx, length - 2): father.sons[i] = father.sons[i + 1]
  setlen(father.sons, length - 1)

proc copyNode(src: PNode): PNode = 
  # does not copy its sons!
  if src == nil: 
    return nil
  result = newNode(src.kind)
  result.info = src.info
  result.typ = src.typ
  result.flags = src.flags * PersistentNodeFlags
  case src.Kind
  of nkCharLit..nkInt64Lit: result.intVal = src.intVal
  of nkFloatLit, nkFloat32Lit, nkFloat64Lit: result.floatVal = src.floatVal
  of nkSym: result.sym = src.sym
  of nkIdent: result.ident = src.ident
  of nkStrLit..nkTripleStrLit: result.strVal = src.strVal
  else: nil

proc shallowCopy*(src: PNode): PNode = 
  # does not copy its sons, but provides space for them:
  if src == nil: return nil
  result = newNode(src.kind)
  result.info = src.info
  result.typ = src.typ
  result.flags = src.flags * PersistentNodeFlags
  case src.Kind
  of nkCharLit..nkInt64Lit: result.intVal = src.intVal
  of nkFloatLit, nkFloat32Lit, nkFloat64Lit: result.floatVal = src.floatVal
  of nkSym: result.sym = src.sym
  of nkIdent: result.ident = src.ident
  of nkStrLit..nkTripleStrLit: result.strVal = src.strVal
  else: newSons(result, sonsLen(src))

proc copyTree(src: PNode): PNode = 
  # copy a whole syntax tree; performs deep copying
  if src == nil: 
    return nil
  result = newNode(src.kind)
  result.info = src.info
  result.typ = src.typ
  result.flags = src.flags * PersistentNodeFlags
  case src.Kind
  of nkCharLit..nkInt64Lit: result.intVal = src.intVal
  of nkFloatLit, nkFloat32Lit, nkFloat64Lit: result.floatVal = src.floatVal
  of nkSym: result.sym = src.sym
  of nkIdent: result.ident = src.ident
  of nkStrLit..nkTripleStrLit: result.strVal = src.strVal
  else: 
    result.sons = nil
    newSons(result, sonsLen(src))
    for i in countup(0, sonsLen(src) - 1): 
      result.sons[i] = copyTree(src.sons[i])
  
proc lastSon(n: PNode): PNode = 
  result = n.sons[sonsLen(n) - 1]

proc lastSon(n: PType): PType = 
  result = n.sons[sonsLen(n) - 1]

proc hasSonWith(n: PNode, kind: TNodeKind): bool = 
  for i in countup(0, sonsLen(n) - 1): 
    if n.sons[i].kind == kind: 
      return true
  result = false

proc hasSubnodeWith(n: PNode, kind: TNodeKind): bool = 
  case n.kind
  of nkEmpty..nkNilLit: result = n.kind == kind
  else: 
    for i in countup(0, sonsLen(n) - 1): 
      if (n.sons[i].kind == kind) or hasSubnodeWith(n.sons[i], kind): 
        return true
    result = false

proc replaceSons(n: PNode, oldKind, newKind: TNodeKind) = 
  for i in countup(0, sonsLen(n) - 1): 
    if n.sons[i].kind == oldKind: n.sons[i].kind = newKind
  
proc sonsNotNil(n: PNode): bool = 
  for i in countup(0, sonsLen(n) - 1): 
    if n.sons[i] == nil: 
      return false
  result = true

proc getInt*(a: PNode): biggestInt = 
  case a.kind
  of nkIntLit..nkInt64Lit: result = a.intVal
  else: 
    internalError(a.info, "getInt")
    result = 0

proc getFloat*(a: PNode): biggestFloat = 
  case a.kind
  of nkFloatLit..nkFloat64Lit: result = a.floatVal
  else: 
    internalError(a.info, "getFloat")
    result = 0.0

proc getStr*(a: PNode): string = 
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  else: 
    internalError(a.info, "getStr")
    result = ""

proc getStrOrChar*(a: PNode): string = 
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  of nkCharLit: result = $chr(int(a.intVal))
  else: 
    internalError(a.info, "getStrOrChar")
    result = ""

