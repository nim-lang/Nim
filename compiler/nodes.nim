#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / hashes
import idents, options, lineinfos

type
  PType* = distinct int

proc `==`*(a, b: PType): bool {.borrow.}
proc hash*(a: PType): Hash {.borrow.}

type
  TNodeFlag* = enum
    nfNone,
    nfBase2,    # nfBase10 is default, so not needed
    nfBase8,
    nfBase16,
    nfAllConst, # used to mark complex expressions constant; easy to get rid of
                # but unfortunately it has measurable impact for compilation
                # efficiency
    nfTransf,   # node has been transformed
    nfNoRewrite # node should not be transformed anymore
    nfSem       # node has been checked for semantics
    nfLL        # node has gone through lambda lifting
    nfDotField  # the call can use a dot operator
    nfDotSetter # the call can use a setter dot operarator
    nfExplicitCall # x.y() was used instead of x.y
    nfExprCall  # this is an attempt to call a regular expression
    nfIsRef     # this node is a 'ref' node; used for the VM
    nfIsPtr     # this node is a 'ptr' node; used for the VM
    nfPreventCg # this node should be ignored by the codegen
    nfBlockArg  # this a stmtlist appearing in a call (e.g. a do block)
    nfFromTemplate # a top-level node returned from a template
    nfDefaultParam # an automatically inserter default parameter
    nfDefaultRefsParam # a default param value references another parameter
                       # the flag is applied to proc default values and to calls
    nfExecuteOnReload  # A top-level statement that will be executed during reloads
    nfLastRead  # this node is a last read
    nfFirstWrite # this node is a first write
    nfHasComment # node has a comment
    nfSkipFieldChecking # node skips field visable checking


type
  ItemId* = object
    module*: int32
    item*: int32

proc `$`*(x: ItemId): string =
  "(module: " & $x.module & ", item: " & $x.item & ")"

proc `==`*(a, b: ItemId): bool {.inline.} =
  a.item == b.item and a.module == b.module

proc hash*(x: ItemId): Hash =
  var h: Hash = hash(x.module)
  h = h !& hash(x.item)
  result = !$h
type
  TCallingConvention* = enum
    ccNimCall = "nimcall"           # nimcall, also the default
    ccStdCall = "stdcall"           # procedure is stdcall
    ccCDecl = "cdecl"               # cdecl
    ccSafeCall = "safecall"         # safecall
    ccSysCall = "syscall"           # system call
    ccInline = "inline"             # proc should be inlined
    ccNoInline = "noinline"         # proc should not be inlined
    ccFastCall = "fastcall"         # fastcall (pass parameters in registers)
    ccThisCall = "thiscall"         # thiscall (parameters are pushed right-to-left)
    ccClosure  = "closure"          # proc has a closure
    ccNoConvention = "noconv"       # needed for generating proper C procs sometimes

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
    nkUIntLit,            # an unsigned integer literal
    nkUInt8Lit,
    nkUInt16Lit,
    nkUInt32Lit,
    nkUInt64Lit,
    nkFloatLit,           # a floating point literal
    nkFloat32Lit,
    nkFloat64Lit,
    nkFloat128Lit,
    nkStrLit,             # a string literal ""
    nkRStrLit,            # a raw string literal r""
    nkTripleStrLit,       # a triple string literal """
    nkNilLit,             # the nil literal
                          # end of atoms
    nkComesFrom,          # "comes from" template/macro information for
                          # better stack trace generation
    nkDotCall,            # used to temporarily flag a nkCall node;
                          # this is used
                          # for transforming ``s.len`` to ``len(s)``

    nkCommand,            # a call like ``p 2, 4`` without parenthesis
    nkCall,               # a call like p(x, y) or an operation like +(a, b)
    nkCallStrLit,         # a call with a string literal
                          # x"abc" has two sons: nkIdent, nkRStrLit
                          # x"""abc""" has two sons: nkIdent, nkTripleStrLit
    nkInfix,              # a call like (a + b)
    nkPrefix,             # a call like !a
    nkPostfix,            # something like a! (also used for visibility)
    nkHiddenCallConv,     # an implicit type conversion via a type converter

    nkExprEqExpr,         # a named parameter with equals: ''expr = expr''
    nkExprColonExpr,      # a named parameter with colon: ''expr: expr''
    nkIdentDefs,          # a definition like `a, b: typeDesc = expr`
                          # either typeDesc or expr may be nil; used in
                          # formal parameters, var statements, etc.
    nkVarTuple,           # a ``var (a, b) = expr`` construct
    nkPar,                # syntactic (); may be a tuple constructor
    nkObjConstr,          # object constructor: T(a: 1, b: 2)
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
    nkDo,                 # lambda block appering as trailing proc param
    nkAccQuoted,          # `a` as a node

    nkTableConstr,        # a table constructor {expr: expr}
    nkBind,               # ``bind expr`` node
    nkClosedSymChoice,    # symbol choice node; a list of nkSyms (closed)
    nkOpenSymChoice,      # symbol choice node; a list of nkSyms (open)
    nkHiddenStdConv,      # an implicit standard type conversion
    nkHiddenSubConv,      # an implicit type conversion from a subtype
                          # to a supertype
    nkConv,               # a type conversion
    nkCast,               # a type cast
    nkStaticExpr,         # a static expr
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

    nkImportAs,           # a 'as' b in an import statement
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
    nkAsmStmt,            # an assembler block
    nkPragma,             # a pragma statement
    nkPragmaBlock,        # a pragma with a block
    nkIfStmt,             # an if statement
    nkWhenStmt,           # a when expression or statement
    nkForStmt,            # a for statement
    nkParForStmt,         # a parallel for statement
    nkWhileStmt,          # a while statement
    nkCaseStmt,           # a case statement
    nkTypeSection,        # a type section (consists of type definitions)
    nkVarSection,         # a var section
    nkLetSection,         # a let section
    nkConstSection,       # a const section
    nkConstDef,           # a const definition
    nkTypeDef,            # a type definition
    nkYieldStmt,          # the yield statement as a tree
    nkDefer,              # the 'defer' statement
    nkTryStmt,            # a try statement
    nkFinally,            # a finally section
    nkRaiseStmt,          # a raise statement
    nkReturnStmt,         # a return statement
    nkBreakStmt,          # a break statement
    nkContinueStmt,       # a continue statement
    nkBlockStmt,          # a block statement
    nkStaticStmt,         # a static statement
    nkDiscardStmt,        # a discard statement
    nkStmtList,           # a list of statements
    nkImportStmt,         # an import statement
    nkImportExceptStmt,   # an import x except a statement
    nkExportStmt,         # an export statement
    nkExportExceptStmt,   # an 'export except' statement
    nkFromStmt,           # a from * import statement
    nkIncludeStmt,        # an include statement
    nkBindStmt,           # a bind statement
    nkMixinStmt,          # a mixin statement
    nkUsingStmt,          # an using statement
    nkCommentStmt,        # a comment statement
    nkStmtListExpr,       # a statement list followed by an expr; this is used
                          # to allow powerful multi-line templates
    nkBlockExpr,          # a statement block ending in an expr; this is used
                          # to allow powerful multi-line templates that open a
                          # temporary scope
    nkStmtListType,       # a statement list ending in a type; for macros
    nkBlockType,          # a statement block ending in a type; for macros
                          # types as syntactic trees:

    nkWith,               # distinct with `foo`
    nkWithout,            # distinct without `foo`

    nkTypeOfExpr,         # type(1+2)
    nkObjectTy,           # object body
    nkTupleTy,            # tuple body
    nkTupleClassTy,       # tuple type class
    nkTypeClassTy,        # user-defined type class
    nkStaticTy,           # ``static[T]``
    nkRecList,            # list of object parts
    nkRecCase,            # case section of object
    nkRecWhen,            # when section of object
    nkRefTy,              # ``ref T``
    nkPtrTy,              # ``ptr T``
    nkVarTy,              # ``var T``
    nkConstTy,            # ``const T``
    nkOutTy,              # ``out T``
    nkDistinctTy,         # distinct type
    nkProcTy,             # proc type
    nkIteratorTy,         # iterator type
    nkSinkAsgn,           # '=sink(x, y)'
    nkEnumTy,             # enum body
    nkEnumFieldDef,       # `ident = expr` in an enumeration
    nkArgList,            # argument list
    nkPattern,            # a special pattern; used for matching
    nkHiddenTryStmt,      # a hidden try statement
    nkClosure,            # (prc, env)-pair (internally used for code gen)
    nkGotoState,          # used for the state machine (for iterators)
    nkState,              # give a label to a code section (for iterators)
    nkBreakState,         # special break statement for easier code generation
    nkFuncDef,            # a func
    nkTupleConstr         # a tuple constructor
    nkError               # erroneous AST node
    nkModuleRef           # for .rod file support: A (moduleId, itemId) pair
    nkReplayAction        # for .rod file support: A replay action
    nkNilRodNode          # for .rod file support: a 'nil' PNode

  TNodeKinds* = set[TNodeKind]
type
  TMagic* = enum # symbols that require compiler magic:
    mNone,
    mDefined, mDeclared, mDeclaredInScope, mCompiles, mArrGet, mArrPut, mAsgn,
    mLow, mHigh, mSizeOf, mAlignOf, mOffsetOf, mTypeTrait,
    mIs, mOf, mAddr, mType, mTypeOf,
    mPlugin, mEcho, mShallowCopy, mSlurp, mStaticExec, mStatic,
    mParseExprToAst, mParseStmtToAst, mExpandToAst, mQuoteAst,
    mInc, mDec, mOrd,
    mNew, mNewFinalize, mNewSeq, mNewSeqOfCap,
    mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq,
    mIncl, mExcl, mCard, mChr,
    mGCref, mGCunref,
    mAddI, mSubI, mMulI, mDivI, mModI,
    mSucc, mPred,
    mAddF64, mSubF64, mMulF64, mDivF64,
    mShrI, mShlI, mAshrI, mBitandI, mBitorI, mBitxorI,
    mMinI, mMaxI,
    mAddU, mSubU, mMulU, mDivU, mModU,
    mEqI, mLeI, mLtI,
    mEqF64, mLeF64, mLtF64,
    mLeU, mLtU,
    mEqEnum, mLeEnum, mLtEnum,
    mEqCh, mLeCh, mLtCh,
    mEqB, mLeB, mLtB,
    mEqRef, mLePtr, mLtPtr,
    mXor, mEqCString, mEqProc,
    mUnaryMinusI, mUnaryMinusI64, mAbsI, mNot,
    mUnaryPlusI, mBitnotI,
    mUnaryPlusF64, mUnaryMinusF64,
    mCharToStr, mBoolToStr,
    mIntToStr, mInt64ToStr, mFloatToStr, # for compiling nimStdlibVersion < 1.5.1 (not bootstrapping)
    mCStrToStr,
    mStrToStr, mEnumToStr,
    mAnd, mOr,
    mImplies, mIff, mExists, mForall, mOld,
    mEqStr, mLeStr, mLtStr,
    mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, mMinusSet,
    mConStrStr, mSlice,
    mDotDot, # this one is only necessary to give nice compile time warnings
    mFields, mFieldPairs, mOmpParFor,
    mAppendStrCh, mAppendStrStr, mAppendSeqElem,
    mInSet, mRepr, mExit,
    mSetLengthStr, mSetLengthSeq,
    mIsPartOf, mAstToStr, mParallel,
    mSwap, mIsNil, mArrToSeq, mOpenArrayToSeq,
    mNewString, mNewStringOfCap, mParseBiggestFloat,
    mMove, mEnsureMove, mWasMoved, mDup, mDestroy, mTrace,
    mDefault, mUnown, mFinished, mIsolate, mAccessEnv, mAccessTypeField, mReset,
    mArray, mOpenArray, mRange, mSet, mSeq, mVarargs,
    mRef, mPtr, mVar, mDistinct, mVoid, mTuple,
    mOrdinal, mIterableType,
    mInt, mInt8, mInt16, mInt32, mInt64,
    mUInt, mUInt8, mUInt16, mUInt32, mUInt64,
    mFloat, mFloat32, mFloat64, mFloat128,
    mBool, mChar, mString, mCstring,
    mPointer, mNil, mExpr, mStmt, mTypeDesc,
    mVoidType, mPNimrodNode, mSpawn, mDeepCopy,
    mIsMainModule, mCompileDate, mCompileTime, mProcCall,
    mCpuEndian, mHostOS, mHostCPU, mBuildOS, mBuildCPU, mAppType,
    mCompileOption, mCompileOptionArg,
    mNLen, mNChild, mNSetChild, mNAdd, mNAddMultiple, mNDel,
    mNKind, mNSymKind,

    mNccValue, mNccInc, mNcsAdd, mNcsIncl, mNcsLen, mNcsAt,
    mNctPut, mNctLen, mNctGet, mNctHasNext, mNctNext,

    mNIntVal, mNFloatVal, mNSymbol, mNIdent, mNGetType, mNStrVal, mNSetIntVal,
    mNSetFloatVal, mNSetSymbol, mNSetIdent, mNSetStrVal, mNLineInfo,
    mNNewNimNode, mNCopyNimNode, mNCopyNimTree, mStrToIdent, mNSigHash, mNSizeOf,
    mNBindSym, mNCallSite,
    mEqIdent, mEqNimrodNode, mSameNodeType, mGetImpl, mNGenSym,
    mNHint, mNWarning, mNError,
    mInstantiationInfo, mGetTypeInfo, mGetTypeInfoV2,
    mNimvm, mIntDefine, mStrDefine, mBoolDefine, mGenericDefine, mRunnableExamples,
    mException, mBuiltinType, mSymOwner, mUncheckedArray, mGetImplTransf,
    mSymIsInstantiationOf, mNodeId, mPrivateAccess, mZeroDefault


const
  # things that we can evaluate safely at compile time, even if not asked for it:
  ctfeWhitelist* = {mNone, mSucc,
    mPred, mInc, mDec, mOrd, mLengthOpenArray,
    mLengthStr, mLengthArray, mLengthSeq,
    mArrGet, mArrPut, mAsgn, mDestroy,
    mIncl, mExcl, mCard, mChr,
    mAddI, mSubI, mMulI, mDivI, mModI,
    mAddF64, mSubF64, mMulF64, mDivF64,
    mShrI, mShlI, mBitandI, mBitorI, mBitxorI,
    mMinI, mMaxI,
    mAddU, mSubU, mMulU, mDivU, mModU,
    mEqI, mLeI, mLtI,
    mEqF64, mLeF64, mLtF64,
    mLeU, mLtU,
    mEqEnum, mLeEnum, mLtEnum,
    mEqCh, mLeCh, mLtCh,
    mEqB, mLeB, mLtB,
    mEqRef, mEqProc, mLePtr, mLtPtr, mEqCString, mXor,
    mUnaryMinusI, mUnaryMinusI64, mAbsI, mNot, mUnaryPlusI, mBitnotI,
    mUnaryPlusF64, mUnaryMinusF64,
    mCharToStr, mBoolToStr,
    mIntToStr, mInt64ToStr, mFloatToStr,
    mCStrToStr,
    mStrToStr, mEnumToStr,
    mAnd, mOr,
    mEqStr, mLeStr, mLtStr,
    mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, mMinusSet,
    mConStrStr, mAppendStrCh, mAppendStrStr, mAppendSeqElem,
    mInSet, mRepr, mOpenArrayToSeq}

  generatedMagics* = {mNone, mIsolate, mFinished, mOpenArrayToSeq}
    ## magics that are generated as normal procs in the backend

type
  TIdObj* {.acyclic.} = object of RootObj
    itemId*: ItemId
  PIdObj* = ref TIdObj

  # -------------- backend information -------------------------------
  TLocKind* = enum
    locNone,                  # no location
    locTemp,                  # temporary location
    locLocalVar,              # location is a local variable
    locGlobalVar,             # location is a global variable
    locParam,                 # location is a parameter
    locField,                 # location is a record field
    locExpr,                  # "location" is really an expression
    locProc,                  # location is a proc (an address of a procedure)
    locData,                  # location is a constant
    locCall,                  # location is a call expression
    locOther                  # location is something other
  TLocFlag* = enum
    lfIndirect,               # backend introduced a pointer
    lfNoDeepCopy,             # no need for a deep copy
    lfNoDecl,                 # do not declare it in C
    lfDynamicLib,             # link symbol to dynamic library
    lfExportLib,              # export symbol for dynamic library generation
    lfHeader,                 # include header file for symbol
    lfImportCompilerProc,     # ``importc`` of a compilerproc
    lfSingleUse               # no location yet and will only be used once
    lfEnforceDeref            # a copyMem is required to dereference if this a
                              # ptr array due to C array limitations.
                              # See #1181, #6422, #11171
    lfPrepareForMutation      # string location is about to be mutated (V2)
  TStorageLoc* = enum
    OnUnknown,                # location is unknown (stack, heap or static)
    OnStatic,                 # in a static section
    OnStack,                  # location is on hardware stack
    OnHeap                    # location is on heap or global
                              # (reference counting needed)
  TLocFlags* = set[TLocFlag]

  # ---------------- end of backend information ------------------------------

type
  TSymFlag* = enum    # 51 flags!
    sfUsed,           # read access of sym (for warnings) or simply used
    sfExported,       # symbol is exported from module
    sfFromGeneric,    # symbol is instantiation of a generic; this is needed
                      # for symbol file generation; such symbols should always
                      # be written into the ROD file
    sfGlobal,         # symbol is at global scope

    sfForward,        # symbol is forward declared
    sfWasForwarded,   # symbol had a forward declaration
                      # (implies it's too dangerous to patch its type signature)
    sfImportc,        # symbol is external; imported
    sfExportc,        # symbol is exported (under a specified name)
    sfMangleCpp,      # mangle as cpp (combines with `sfExportc`)
    sfVolatile,       # variable is volatile
    sfRegister,       # variable should be placed in a register
    sfPure,           # object is "pure" that means it has no type-information
                      # enum is "pure", its values need qualified access
                      # variable is "pure"; it's an explicit "global"
    sfNoSideEffect,   # proc has no side effects
    sfSideEffect,     # proc may have side effects; cannot prove it has none
    sfMainModule,     # module is the main module
    sfSystemModule,   # module is the system module
    sfNoReturn,       # proc never returns (an exit proc)
    sfAddrTaken,      # the variable's address is taken (ex- or implicitly);
                      # *OR*: a proc is indirectly called (used as first class)
    sfCompilerProc,   # proc is a compiler proc, that is a C proc that is
                      # needed for the code generator
    sfEscapes         # param escapes
                      # currently unimplemented
    sfDiscriminant,   # field is a discriminant in a record/object
    sfRequiresInit,   # field must be initialized during construction
    sfDeprecated,     # symbol is deprecated
    sfExplain,        # provide more diagnostics when this symbol is used
    sfError,          # usage of symbol should trigger a compile-time error
    sfShadowed,       # a symbol that was shadowed in some inner scope
    sfThread,         # proc will run as a thread
                      # variable is a thread variable
    sfCppNonPod,      # tells compiler to treat such types as non-pod's, so that
                      # `thread_local` is used instead of `__thread` for
                      # {.threadvar.} + `--threads`. Only makes sense for importcpp types.
                      # This has a performance impact so isn't set by default.
    sfCompileTime,    # proc can be evaluated at compile time
    sfConstructor,    # proc is a C++ constructor
    sfDispatcher,     # copied method symbol is the dispatcher
                      # deprecated and unused, except for the con
    sfBorrow,         # proc is borrowed
    sfInfixCall,      # symbol needs infix call syntax in target language;
                      # for interfacing with C++, JS
    sfNamedParamCall, # symbol needs named parameter call syntax in target
                      # language; for interfacing with Objective C
    sfDiscardable,    # returned value may be discarded implicitly
    sfOverridden,      # proc is overridden
    sfCallsite        # A flag for template symbols to tell the
                      # compiler it should use line information from
                      # the calling side of the macro, not from the
                      # implementation.
    sfGenSym          # symbol is 'gensym'ed; do not add to symbol table
    sfNonReloadable   # symbol will be left as-is when hot code reloading is on -
                      # meaning that it won't be renamed and/or changed in any way
    sfGeneratedOp     # proc is a generated '='; do not inject destructors in it
                      # variable is generated closure environment; requires early
                      # destruction for --newruntime.
    sfTemplateParam   # symbol is a template parameter
    sfCursor          # variable/field is a cursor, see RFC 177 for details
    sfInjectDestructors # whether the proc needs the 'injectdestructors' transformation
    sfNeverRaises     # proc can never raise an exception, not even OverflowDefect
                      # or out-of-memory
    sfSystemRaisesDefect # proc in the system can raise defects
    sfUsedInFinallyOrExcept  # symbol is used inside an 'except' or 'finally'
    sfSingleUsedTemp  # For temporaries that we know will only be used once
    sfNoalias         # 'noalias' annotation, means C's 'restrict'
                      # for templates and macros, means cannot be called
                      # as a lone symbol (cannot use alias syntax)
    sfEffectsDelayed  # an 'effectsDelayed' parameter
    sfGeneratedType   # A anonymous generic type that is generated by the compiler for
                      # objects that do not have generic parameters in case one of the
                      # object fields has one.
                      #
                      # This is disallowed but can cause the typechecking to go into
                      # an infinite loop, this flag is used as a sentinel to stop it.
    sfVirtual         # proc is a C++ virtual function
    sfByCopy          # param is marked as pass bycopy
    sfMember          # proc is a C++ member of a type
    sfCodegenDecl     # type, proc, global or proc param is marked as codegenDecl

  TSymFlags* = set[TSymFlag]

  TNodeFlags* = set[TNodeFlag]
  TTypeFlag* = enum   # keep below 32 for efficiency reasons (now: 47)
    tfVarargs,        # procedure has C styled varargs
                      # tyArray type represeting a varargs list
    tfNoSideEffect,   # procedure type does not allow side effects
    tfFinal,          # is the object final?
    tfInheritable,    # is the object inheritable?
    tfHasOwned,       # type contains an 'owned' type and must be moved
    tfEnumHasHoles,   # enum cannot be mapped into a range
    tfShallow,        # type can be shallow copied on assignment
    tfThread,         # proc type is marked as ``thread``; alias for ``gcsafe``
    tfFromGeneric,    # type is an instantiation of a generic; this is needed
                      # because for instantiations of objects, structural
                      # type equality has to be used
    tfUnresolved,     # marks unresolved typedesc/static params: e.g.
                      # proc foo(T: typedesc, list: seq[T]): var T
                      # proc foo(L: static[int]): array[L, int]
                      # can be attached to ranges to indicate that the range
                      # can be attached to generic procs with free standing
                      # type parameters: e.g. proc foo[T]()
                      # depends on unresolved static params.
    tfResolved        # marks a user type class, after it has been bound to a
                      # concrete type (lastSon becomes the concrete type)
    tfRetType,        # marks return types in proc (used to detect type classes
                      # used as return types for return type inference)
    tfCapturesEnv,    # whether proc really captures some environment
    tfByCopy,         # pass object/tuple by copy (C backend)
    tfByRef,          # pass object/tuple by reference (C backend)
    tfIterator,       # type is really an iterator, not a tyProc
    tfPartial,        # type is declared as 'partial'
    tfNotNil,         # type cannot be 'nil'
    tfRequiresInit,   # type constains a "not nil" constraint somewhere or
                      # a `requiresInit` field, so the default zero init
                      # is not appropriate
    tfNeedsFullInit,  # object type marked with {.requiresInit.}
                      # all fields must be initialized
    tfVarIsPtr,       # 'var' type is translated like 'ptr' even in C++ mode
    tfHasMeta,        # type contains "wildcard" sub-types such as generic params
                      # or other type classes
    tfHasGCedMem,     # type contains GC'ed memory
    tfPacked
    tfHasStatic
    tfGenericTypeParam
    tfImplicitTypeParam
    tfInferrableStatic
    tfConceptMatchedTypeSym
    tfExplicit        # for typedescs, marks types explicitly prefixed with the
                      # `type` operator (e.g. type int)
    tfWildcard        # consider a proc like foo[T, I](x: Type[T, I])
                      # T and I here can bind to both typedesc and static types
                      # before this is determined, we'll consider them to be a
                      # wildcard type.
    tfHasAsgn         # type has overloaded assignment operator
    tfBorrowDot       # distinct type borrows '.'
    tfTriggersCompileTime # uses the NimNode type which make the proc
                          # implicitly '.compiletime'
    tfRefsAnonObj     # used for 'ref object' and 'ptr object'
    tfCovariant       # covariant generic param mimicking a ptr type
    tfWeakCovariant   # covariant generic param mimicking a seq/array type
    tfContravariant   # contravariant generic param
    tfCheckedForDestructor # type was checked for having a destructor.
                           # If it has one, t.destructor is not nil.
    tfAcyclic # object type was annotated as .acyclic
    tfIncompleteStruct # treat this type as if it had sizeof(pointer)
    tfCompleteStruct
      # (for importc types); type is fully specified, allowing to compute
      # sizeof, alignof, offsetof at CT
    tfExplicitCallConv
    tfIsConstructor
    tfEffectSystemWorkaround
    tfIsOutParam
    tfSendable
    tfImplicitStatic

  TTypeFlags* = set[TTypeFlag]

  TSymKind* = enum        # the different symbols (start with the prefix sk);
                          # order is important for the documentation generator!
    skUnknown,            # unknown symbol: used for parsing assembler blocks
                          # and first phase symbol lookup in generics
    skConditional,        # symbol for the preprocessor (may become obsolete)
    skDynLib,             # symbol represents a dynamic library; this is used
                          # internally; it does not exist in Nim code
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
    skFunc,               # a func
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
    skStub,               # symbol is a stub and not yet loaded from the ROD
                          # file (it is loaded on demand, which may
                          # mean: never)
    skPackage,            # symbol is a package (used for canonicalization)
  TSymKinds* = set[TSymKind]

const
  routineKinds* = {skProc, skFunc, skMethod, skIterator,
                   skConverter, skMacro, skTemplate}
  ExportableSymKinds* = {skVar, skLet, skConst, skType, skEnumField, skStub} + routineKinds

  tfUnion* = tfNoSideEffect
  tfGcSafe* = tfThread
  tfObjHasKids* = tfEnumHasHoles
  tfReturnsNew* = tfInheritable
  skError* = skUnknown

type
  PSym* = ref TSym
  TNode*{.final, acyclic.} = object # on a 32bit machine, this takes 32 bytes
    when defined(useNodeIds):
      id*: int
    typ*: PType
    info*: TLineInfo
    flags*: TNodeFlags
    case kind*: TNodeKind
    of nkCharLit..nkUInt64Lit:
      intVal*: BiggestInt
    of nkFloatLit..nkFloat128Lit:
      floatVal*: BiggestFloat
    of nkStrLit..nkTripleStrLit:
      strVal*: string
    of nkSym:
      sym*: PSym
    of nkIdent:
      ident*: PIdent
    else:
      sons*: TNodeSeq
    when defined(nimsuggest):
      endInfo*: TLineInfo

  PLib* = ref TLib
  TSym* {.acyclic.} = object of TIdObj # Keep in sync with PackedSym
    # proc and type instantiations are cached in the generic symbol
    case kind*: TSymKind
    of routineKinds:
      #procInstCache*: seq[PInstantiation]
      gcUnsafetyReason*: PSym  # for better error messages regarding gcsafe
      transformedBody*: PNode  # cached body after transf pass
    of skLet, skVar, skField, skForVar:
      guard*: PSym
      bitsize*: int
      alignment*: int # for alignment
    else: nil
    magic*: TMagic
    typ*: PType
    name*: PIdent
    info*: TLineInfo
    when defined(nimsuggest):
      endInfo*: TLineInfo
      hasUserSpecifiedType*: bool  # used for determining whether to display inlay type hints
    owner*: PSym
    flags*: TSymFlags
    ast*: PNode               # syntax tree of proc, iterator, etc.:
                              # the whole proc including header; this is used
                              # for easy generation of proper error messages
                              # for variant record fields the discriminant
                              # expression
                              # for modules, it's a placeholder for compiler
                              # generated code that will be appended to the
                              # module after the sem pass (see appendToModule)
    options*: TOptions
    position*: int            # used for many different things:
                              # for enum fields its position;
                              # for fields its offset
                              # for parameters its position (starting with 0)
                              # for a conditional:
                              # 1 iff the symbol is defined, else 0
                              # (or not in symbol table)
                              # for modules, an unique index corresponding
                              # to the module's fileIdx
                              # for variables a slot index for the evaluator
    offset*: int32            # offset of record field
    disamb*: int32            # disambiguation number; the basic idea is that
                              # `<procname>__<module>_<disamb>` is unique
    loc*: TLoc
    annex*: PLib              # additional fields (seldom used, so we use a
                              # reference to another object to save space)
    when hasFFI:
      cname*: string          # resolved C declaration name in importc decl, e.g.:
                              # proc fun() {.importc: "$1aux".} => cname = funaux
    constraint*: PNode        # additional constraints like 'lit|result'; also
                              # misused for the codegenDecl and virtual pragmas in the hope
                              # it won't cause problems
                              # for skModule the string literal to output for
                              # deprecated modules.
    instantiatedFrom*: PSym   # for instances, the generic symbol where it came from.
    when defined(nimsuggest):
      allUsages*: seq[TLineInfo]


  TLibKind* = enum
    libHeader, libDynamic

  TLib* = object              # also misused for headers!
                              # keep in sync with PackedLib
    kind*: TLibKind
    generated*: bool          # needed for the backends:
    isOverridden*: bool
    name*: string
    path*: PNode              # can be a string literal!
  CompilesId* = int ## id that is used for the caching logic within
                    ## ``system.compiles``. See the seminst module.
  TInstantiation* = object
    sym*: PSym
    concreteTypes*: seq[PType]
    compilesId*: CompilesId

  PInstantiation* = ref TInstantiation

  TStrTable* = object         # a table[PIdent] of PSym
    counter*: int
    data*: seq[PSym]

  TScope* {.acyclic.} = object
    depthLevel*: int
    symbols*: TStrTable
    parent*: PScope
    allowPrivateAccess*: seq[PSym] #  # enable access to private fields

  PScope* = ref TScope
  TLoc* = object
    k*: TLocKind              # kind of location
    storage*: TStorageLoc
    flags*: TLocFlags         # location's flags
    lode*: PNode              # Node where the location came from; can be faked
    r*: string                # rope value of location (code generators)
  PNode* = ref TNode
  TNodeSeq* = seq[PNode]
  #PType* = ref TType

const
  sfNoInit* = sfMainModule       # don't generate code to init the variable

  sfAllUntyped* = sfVolatile # macro or template is immediately expanded \
    # in a generic context

  sfDirty* = sfPure
    # template is not hygienic (old styled template)
    # module, compiled from a dirty-buffer

  sfAnon* = sfDiscardable
    # symbol name that was generated by the compiler
    # the compiler will avoid printing such names
    # in user messages.

  sfNoForward* = sfRegister
    # forward declarations are not required (per module)
  sfReorder* = sfForward
    # reordering pass is enabled

  sfCompileToCpp* = sfInfixCall       # compile the module as C++ code
  sfCompileToObjc* = sfNamedParamCall # compile the module as Objective-C code
  sfExperimental* = sfOverridden       # module uses the .experimental switch
  sfGoto* = sfOverridden               # var is used for 'goto' code generation
  sfWrittenTo* = sfBorrow             # param is assigned to
                                      # currently unimplemented
  sfBase* = sfDiscriminant
  sfCustomPragma* = sfRegister        # symbol is custom pragma template
  sfTemplateRedefinition* = sfExportc # symbol is a redefinition of an earlier template
  sfCppMember* = { sfVirtual, sfMember, sfConstructor } # proc is a C++ member, meaning it will be attached to the type definition

const
  # getting ready for the future expr/stmt merge
  nkWhen* = nkWhenStmt
  nkWhenExpr* = nkWhenStmt
  nkEffectList* = nkArgList
  # hacks ahead: an nkEffectList is a node with 4 children:
  exceptionEffects* = 0 # exceptions at position 0
  requiresEffects* = 1      # 'requires' annotation
  ensuresEffects* = 2     # 'ensures' annotation
  tagEffects* = 3       # user defined tag ('gc', 'time' etc.)
  pragmasEffects* = 4    # not an effect, but a slot for pragmas in proc type
  forbiddenEffects* = 5    # list of illegal effects
  effectListLen* = 6    # list of effects list
  nkLastBlockStmts* = {nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt}
                        # these must be last statements in a block
