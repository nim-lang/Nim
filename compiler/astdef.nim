#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  lineinfos, options, ropes, idents, int128

import std/[tables, hashes]

when defined(nimPreviewSlimSystem):
  import std/assertions

export int128

import nodekinds
export nodekinds

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
    ccMember = "member"             # proc is a (cpp) member

  TNodeKinds* = set[TNodeKind]

type
  TSymFlag* = enum    # 63 flags!
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
    sfOverridden,     # proc is overridden
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
    sfWasGenSym       # symbol was 'gensym'ed
    sfForceLift       # variable has to be lifted into closure environment

    sfDirty           # template is not hygienic (old styled template) module,
                      # compiled from a dirty-buffer
    sfCustomPragma    # symbol is custom pragma template
    sfBase,           # a base method
    sfGoto            # var is used for 'goto' code generation
    sfAnon,           # symbol name that was generated by the compiler
                      # the compiler will avoid printing such names
                      # in user messages.
    sfAllUntyped      # macro or template is immediately expanded in a generic context
    sfTemplateRedefinition # symbol is a redefinition of an earlier template

  TSymFlags* = set[TSymFlag]

const
  sfNoInit* = sfMainModule       # don't generate code to init the variable

  sfNoForward* = sfRegister
    # forward declarations are not required (per module)
  sfReorder* = sfForward
    # reordering pass is enabled

  sfCompileToCpp* = sfInfixCall       # compile the module as C++ code
  sfCompileToObjc* = sfNamedParamCall # compile the module as Objective-C code
  sfExperimental* = sfOverridden       # module uses the .experimental switch
  sfWrittenTo* = sfBorrow             # param is assigned to
                                      # currently unimplemented
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

type
  TTypeKind* = enum  # order is important!
                     # Don't forget to change hti.nim if you make a change here
                     # XXX put this into an include file to avoid this issue!
                     # several types are no longer used (guess which), but a
                     # spot in the sequence is kept for backwards compatibility
                     # (apparently something with bootstrapping)
                     # if you need to add a type, they can apparently be reused
    tyNone, tyBool, tyChar,
    tyEmpty, tyAlias, tyNil, tyUntyped, tyTyped, tyTypeDesc,
    tyGenericInvocation, # ``T[a, b]`` for types to invoke
    tyGenericBody,       # ``T[a, b, body]`` last parameter is the body
    tyGenericInst,       # ``T[a, b, realInstance]`` instantiated generic type
                         # realInstance will be a concrete type like tyObject
                         # unless this is an instance of a generic alias type.
                         # then realInstance will be the tyGenericInst of the
                         # completely (recursively) resolved alias.

    tyGenericParam,      # ``a`` in the above patterns
    tyDistinct,
    tyEnum,
    tyOrdinal,           # integer types (including enums and boolean)
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
    tyString, tyCstring, tyForward,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64, # signed integers
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64,
    tyOwned, tySink, tyLent,
    tyVarargs,
    tyUncheckedArray
      # An array with boundaries [0,+∞]

    tyError # used as erroneous type (for idetools)
      # as an erroneous node should match everything

    tyBuiltInTypeClass
      # Type such as the catch-all object, tuple, seq, etc

    tyUserTypeClass
      # the body of a user-defined type class

    tyUserTypeClassInst
      # Instance of a parametric user-defined type class.
      # Structured similarly to tyGenericInst.
      # tyGenericInst represents concrete types, while
      # this is still a "generic param" that will bind types
      # and resolves them during sigmatch and instantiation.

    tyCompositeTypeClass
      # Type such as seq[Number]
      # The notes for tyUserTypeClassInst apply here as well
      # sons[0]: the original expression used by the user.
      # sons[1]: fully expanded and instantiated meta type
      # (potentially following aliases)

    tyInferred
      # In the initial state `base` stores a type class constraining
      # the types that can be inferred. After a candidate type is
      # selected, it's stored in `last`. Between `base` and `last`
      # there may be 0, 2 or more types that were also considered as
      # possible candidates in the inference process (i.e. last will
      # be updated to store a type best conforming to all candidates)

    tyAnd, tyOr, tyNot
      # boolean type classes such as `string|int`,`not seq`,
      # `Sortable and Enumable`, etc

    tyAnything
      # a type class matching any type

    tyStatic
      # a value known at compile type (the underlying type is .base)

    tyFromExpr
      # This is a type representing an expression that depends
      # on generic parameters (the expression is stored in t.n)
      # It will be converted to a real type only during generic
      # instantiation and prior to this it has the potential to
      # be any type.

    tyConcept
      # new style concept.

    tyVoid
      # now different from tyEmpty, hurray!
    tyIterable

static:
  # remind us when TTypeKind stops to fit in a single 64-bit word
  # assert TTypeKind.high.ord <= 63
  discard

const
  tyPureObject* = tyTuple
  GcTypeKinds* = {tyRef, tySequence, tyString}

  tyTypeClasses* = {tyBuiltInTypeClass, tyCompositeTypeClass,
                    tyUserTypeClass, tyUserTypeClassInst, tyConcept,
                    tyAnd, tyOr, tyNot, tyAnything}

  tyMetaTypes* = {tyGenericParam, tyTypeDesc, tyUntyped} + tyTypeClasses
  tyUserTypeClasses* = {tyUserTypeClass, tyUserTypeClassInst}
  # consider renaming as `tyAbstractVarRange`
  abstractVarRange* = {tyGenericInst, tyRange, tyVar, tyDistinct, tyOrdinal,
                       tyTypeDesc, tyAlias, tyInferred, tySink, tyOwned}
  abstractInst* = {tyGenericInst, tyDistinct, tyOrdinal, tyTypeDesc, tyAlias,
                   tyInferred, tySink, tyOwned} # xxx what about tyStatic?

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
    nfDisabledOpenSym # temporary: node should be nkOpenSym but cannot
                      # because openSym experimental switch is disabled
                      # gives warning instead
    nfLazyType  # node has a lazy type

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
    tfRequiresInit,   # type contains a "not nil" constraint somewhere or
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
  tfNonConstExpr* = tfExplicitCallConv
    ## tyFromExpr where the expression shouldn't be evaluated as a static value
  tfGenericHasDestructor* = tfExplicitCallConv
    ## tyGenericBody where an instance has a generated destructor
  skError* = skUnknown

var
  eqTypeFlags* = {tfIterator, tfNotNil, tfVarIsPtr, tfGcSafe, tfNoSideEffect, tfIsOutParam}
    ## type flags that are essential for type equality.
    ## This is now a variable because for emulation of version:1.0 we
    ## might exclude {tfGcSafe, tfNoSideEffect}.

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
    mCStrToStr,
    mStrToStr, mEnumToStr,
    mAnd, mOr,
    mImplies, mIff, mExists, mForall, mOld,
    mEqStr, mLeStr, mLtStr,
    mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, mMinusSet, mXorSet,
    mConStrStr, mSlice,
    mDotDot, # this one is only necessary to give nice compile time warnings
    mFields, mFieldPairs, mOmpParFor,
    mAppendStrCh, mAppendStrStr, mAppendSeqElem,
    mInSet, mRepr, mExit,
    mSetLengthStr, mSetLengthSeq,
    mSetLengthSeqUninit,
    mIsPartOf, mAstToStr, mParallel,
    mSwap, mIsNil, mArrToSeq, mOpenArrayToSeq,
    mNewString, mNewStringOfCap, mParseBiggestFloat,
    mMove, mEnsureMove, mWasMoved, mDup, mDestroy, mTrace,
    mDefault, mUnown, mFinished, mIsolate, mAccessEnv, mAccessTypeField,
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
    mCStrToStr,
    mStrToStr, mEnumToStr,
    mAnd, mOr,
    mEqStr, mLeStr, mLtStr,
    mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, mMinusSet, mXorSet,
    mConStrStr, mAppendStrCh, mAppendStrStr, mAppendSeqElem,
    mInSet, mRepr, mOpenArrayToSeq}

  generatedMagics* = {mNone, mIsolate, mFinished, mOpenArrayToSeq}
    ## magics that are generated as normal procs in the backend

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
  PNode* = ref TNode
  TNodeSeq* = seq[PNode]
  PType* = ref TType
  PSym* = ref TSym
  TNode*{.final, acyclic.} = object # on a 32bit machine, this takes 32 bytes
    when defined(useNodeIds):
      id*: int
    typField*: PType
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

  TStrTable* = object         # a table[PIdent] of PSym
    counter*: int
    data*: seq[PSym]

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
  TLoc* = object
    k*: TLocKind              # kind of location
    storage*: TStorageLoc
    flags*: TLocFlags         # location's flags
    lode*: PNode              # Node where the location came from; can be faked
    snippet*: Rope            # C code snippet of location (code generators)

  # ---------------- end of backend information ------------------------------

  TLibKind* = enum
    libHeader, libDynamic

  TLib* = object              # also misused for headers!
                              # keep in sync with PackedLib
    kind*: TLibKind
    generated*: bool          # needed for the backends:
    isOverridden*: bool
    name*: Rope
    path*: PNode              # can be a string literal!


  CompilesId* = int ## id that is used for the caching logic within
                    ## ``system.compiles``. See the seminst module.
  TInstantiation* = object
    sym*: PSym
    concreteTypes*: seq[PType]
    genericParamsCount*: int   # for terrible reasons `concreteTypes` contains all the types,
                               # so we need to know how many generic params there were
                               # this is not serialized for IC and that is fine.
    compilesId*: CompilesId

  PInstantiation* = ref TInstantiation

  TScope* {.acyclic.} = object
    depthLevel*: int
    symbols*: TStrTable
    parent*: PScope
    allowPrivateAccess*: seq[PSym] #  # enable access to private fields
    optionStackLen*: int

  PScope* = ref TScope

  ItemState* = enum
    Complete # completely in memory
    Partial  # partially in memory
    Sealed   # complete in memory, already written to NIF file, so further mutations are not allowed

  PLib* = ref TLib
  TSym* {.acyclic.} = object # Keep in sync with ast2nif.nim
    itemId*: ItemId
    # proc and type instantiations are cached in the generic symbol
    state*: ItemState
    case kindImpl*: TSymKind  # Note: kept as 'kind' for case statement, but accessor checks state
    of routineKinds:
      #procInstCache*: seq[PInstantiation]
      gcUnsafetyReasonImpl*: PSym  # for better error messages regarding gcsafe
      transformedBodyImpl*: PNode  # cached body after transf pass
    of skLet, skVar, skField, skForVar:
      guardImpl*: PSym
      bitsizeImpl*: int
      alignmentImpl*: int # for alignment
    else: nil
    magicImpl*: TMagic
    typImpl*: PType
    name*: PIdent
    infoImpl*: TLineInfo
    when defined(nimsuggest):
      endInfoImpl*: TLineInfo
      hasUserSpecifiedTypeImpl*: bool  # used for determining whether to display inlay type hints
    ownerFieldImpl*: PSym
    flagsImpl*: TSymFlags
    astImpl*: PNode           # syntax tree of proc, iterator, etc.:
                              # the whole proc including header; this is used
                              # for easy generation of proper error messages
                              # for variant record fields the discriminant
                              # expression
                              # for modules, it's a placeholder for compiler
                              # generated code that will be appended to the
                              # module after the sem pass (see appendToModule)
    optionsImpl*: TOptions
    positionImpl*: int        # used for many different things:
                              # for enum fields its position;
                              # for fields its offset
                              # for parameters its position (starting with 0)
                              # for a conditional:
                              # 1 iff the symbol is defined, else 0
                              # (or not in symbol table)
                              # for modules, an unique index corresponding
                              # to the module's fileIdx
                              # for variables a slot index for the evaluator
    offsetImpl*: int32        # offset of record field
    disamb*: int32            # disambiguation number; the basic idea is that
                              # `<procname>__<module>_<disamb>` is unique
    locImpl*: TLoc
    annexImpl*: PLib          # additional fields (seldom used, so we use a
                              # reference to another object to save space)
    when hasFFI:
      cnameImpl*: string      # resolved C declaration name in importc decl, e.g.:
                              # proc fun() {.importc: "$1aux".} => cname = funaux
    constraintImpl*: PNode    # additional constraints like 'lit|result'; also
                              # misused for the codegenDecl and virtual pragmas in the hope
                              # it won't cause problems
                              # for skModule the string literal to output for
                              # deprecated modules.
    instantiatedFromImpl*: PSym   # for instances, the generic symbol where it came from.
    when defined(nimsuggest):
      allUsagesImpl*: seq[TLineInfo]

  TTypeSeq* = seq[PType]

  TTypeAttachedOp* = enum ## as usual, order is important here
    attachedWasMoved,
    attachedDestructor,
    attachedAsgn,
    attachedDup,
    attachedSink,
    attachedTrace,
    attachedDeepCopy

  TType* {.acyclic.} = object # \
                              # types are identical iff they have the
                              # same id; there may be multiple copies of a type
                              # in memory!
                              # Keep in sync with PackedType
    itemId*: ItemId
    kind*: TTypeKind          # kind of type
    state*: ItemState
    uniqueId*: ItemId         # due to a design mistake, we need to keep the real ID here as it
                              # is required by the --incremental:on mode.
    callConvImpl*: TCallingConvention # for procs
    flagsImpl*: TTypeFlags        # flags of the type
    sonsImpl*: TTypeSeq           # base types, etc.
    nImpl*: PNode                 # node for types:
                              # for range types a nkRange node
                              # for record types a nkRecord node
                              # for enum types a list of symbols
                              # if kind == tyInt: it is an 'int literal(x)' type
                              # for procs and tyGenericBody, it's the
                              # formal param list
                              # for concepts, the concept body
                              # else: unused
    ownerFieldImpl*: PSym         # the 'owner' of the type
    symImpl*: PSym                # types have the sym associated with them
                              # it is used for converting types to strings
    sizeImpl*: BiggestInt         # the size of the type in bytes
                              # -1 means that the size is unknown
    alignImpl*: int16             # the type's alignment requirements
    paddingAtEndImpl*: int16      #
    locImpl*: TLoc
    typeInstImpl*: PType          # for generic instantiations the tyGenericInst that led to this
                              # type.

  TPair* = object
    key*, val*: RootRef

  TPairSeq* = seq[TPair]

  TIdPair*[T] = object
    key*: ItemId
    val*: T

  TIdPairSeq*[T] = seq[TIdPair[T]]
  TIdTable*[T] = object
    counter*: int
    data*: TIdPairSeq[T]

  TNodePair* = object
    h*: Hash                 # because it is expensive to compute!
    key*: PNode
    val*: int

  TNodePairSeq* = seq[TNodePair]
  TNodeTable* = object # the same as table[PNode] of int;
                                # nodes are compared by structure!
    counter*: int
    data*: TNodePairSeq
    ignoreTypes*: bool

  TObjectSeq* = seq[RootRef]
  TObjectSet* = object
    counter*: int
    data*: TObjectSeq

  TImplication* = enum
    impUnknown, impNo, impYes


const
  OverloadableSyms* = {skProc, skFunc, skMethod, skIterator,
    skConverter, skModule, skTemplate, skMacro, skEnumField}

  GenericTypes*: TTypeKinds = {tyGenericInvocation, tyGenericBody,
    tyGenericParam}

  StructuralEquivTypes*: TTypeKinds = {tyNil, tyTuple, tyArray,
    tySet, tyRange, tyPtr, tyRef, tyVar, tyLent, tySequence, tyProc, tyOpenArray,
    tyVarargs}

  ConcreteTypes*: TTypeKinds = { # types of the expr that may occur in::
                                 # var x = expr
    tyBool, tyChar, tyEnum, tyArray, tyObject,
    tySet, tyTuple, tyRange, tyPtr, tyRef, tyVar, tyLent, tySequence, tyProc,
    tyPointer,
    tyOpenArray, tyString, tyCstring, tyInt..tyInt64, tyFloat..tyFloat128,
    tyUInt..tyUInt64}
  IntegralTypes* = {tyBool, tyChar, tyEnum, tyInt..tyInt64,
    tyFloat..tyFloat128, tyUInt..tyUInt64} # weird name because it contains tyFloat
  ConstantDataTypes*: TTypeKinds = {tyArray, tySet,
                                    tyTuple, tySequence}
  NilableTypes*: TTypeKinds = {tyPointer, tyCstring, tyRef, tyPtr,
    tyProc, tyError} # TODO
  PtrLikeKinds*: TTypeKinds = {tyPointer, tyPtr} # for VM
  PersistentNodeFlags*: TNodeFlags = {nfBase2, nfBase8, nfBase16,
                                      nfDotSetter, nfDotField,
                                      nfIsRef, nfIsPtr, nfPreventCg, nfLL,
                                      nfFromTemplate, nfDefaultRefsParam,
                                      nfExecuteOnReload, nfLastRead,
                                      nfFirstWrite, nfSkipFieldChecking,
                                      nfDisabledOpenSym, nfLazyType}
  namePos* = 0
  patternPos* = 1    # empty except for term rewriting macros
  genericParamsPos* = 2
  paramsPos* = 3
  pragmasPos* = 4
  miscPos* = 5  # used for undocumented and hacky stuff
  bodyPos* = 6       # position of body; use rodread.getBody() instead!
  resultPos* = 7
  dispatcherPos* = 8

  nfAllFieldsSet* = nfBase2

  nkIdentKinds* = {nkIdent, nkSym, nkAccQuoted, nkOpenSymChoice,
                   nkClosedSymChoice, nkOpenSym}

  nkPragmaCallKinds* = {nkExprColonExpr, nkCall, nkCallStrLit}
  nkLiterals* = {nkCharLit..nkTripleStrLit}
  nkFloatLiterals* = {nkFloatLit..nkFloat128Lit}
  nkLambdaKinds* = {nkLambda, nkDo}
  declarativeDefs* = {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef}
  routineDefs* = declarativeDefs + {nkMacroDef, nkTemplateDef}
  procDefs* = nkLambdaKinds + declarativeDefs
  callableDefs* = nkLambdaKinds + routineDefs

  nkSymChoices* = {nkClosedSymChoice, nkOpenSymChoice}
  nkStrKinds* = {nkStrLit..nkTripleStrLit}

  skLocalVars* = {skVar, skLet, skForVar, skParam, skResult}
  skProcKinds* = {skProc, skFunc, skTemplate, skMacro, skIterator,
                  skMethod, skConverter}

  defaultSize* = -1
  defaultAlignment* = -1
  defaultOffset* = -1


proc len*(n: PNode): int {.inline.} =
  result = n.sons.len

proc safeLen*(n: PNode): int {.inline.} =
  ## works even for leaves.
  if n.kind in {nkNone..nkNilLit}: result = 0
  else: result = n.len

template `[]`*(n: PNode, i: int): PNode = n.sons[i]
template `[]=`*(n: PNode, i: int; x: PNode) = n.sons[i] = x

template `[]`*(n: PNode, i: BackwardsIndex): PNode = n[n.len - i.int]
template `[]=`*(n: PNode, i: BackwardsIndex; x: PNode) = n[n.len - i.int] = x

iterator items*(n: PNode): PNode =
  for i in 0..<n.safeLen: yield n[i]

when defined(useNodeIds):
  const nodeIdToDebug* = -1 # 2322968
  var gNodeId: int

template newNodeImpl(info2) {.dirty.} =
  result = PNode(kind: kind, info: info2)
  when false:
    # this would add overhead, so we skip it; it results in a small amount of leaked entries
    # for old PNode that gets re-allocated at the same address as a PNode that
    # has `nfHasComment` set (and an entry in that table). Only `nfHasComment`
    # should be used to test whether a PNode has a comment; gconfig.comments
    # can contain extra entries for deleted PNode's with comments.
    gconfig.comments.del(cast[int](result))

template setIdMaybe() =
  when defined(useNodeIds):
    result.id = gNodeId
    if result.id == nodeIdToDebug:
      echo "KIND ", result.kind
      writeStackTrace()
    inc gNodeId

proc newNode*(kind: TNodeKind): PNode =
  ## new node with unknown line info, no type, and no children
  newNodeImpl(unknownLineInfo)
  setIdMaybe()

proc newNodeI*(kind: TNodeKind, info: TLineInfo): PNode =
  ## new node with line info, no type, and no children
  newNodeImpl(info)
  setIdMaybe()

proc newNodeI*(kind: TNodeKind, info: TLineInfo, children: int): PNode =
  ## new node with line info, type, and children
  newNodeImpl(info)
  if children > 0:
    newSeq(result.sons, children)
  setIdMaybe()

proc newNodeIT*(kind: TNodeKind, info: TLineInfo, typ: PType): PNode =
  ## new node with line info, type, and no children
  result = newNode(kind)
  result.info = info
  result.typField = typ

proc newNode*(kind: TNodeKind, info: TLineInfo): PNode =
  ## new node with line info, no type, and no children
  newNodeImpl(info)
  setIdMaybe()

proc newIdentNode*(ident: PIdent, info: TLineInfo): PNode =
  result = newNode(nkIdent)
  result.ident = ident
  result.info = info

proc newSymNode*(sym: PSym, info: TLineInfo): PNode =
  result = newNode(nkSym)
  result.sym = sym
  result.typField = sym.typImpl
  result.info = info

proc newStrNode*(kind: TNodeKind, strVal: string): PNode =
  result = newNode(kind)
  result.strVal = strVal

proc newStrNode*(strVal: string; info: TLineInfo): PNode =
  result = newNodeI(nkStrLit, info)
  result.strVal = strVal

# Hooks, converters, method dispatchers and enum-to-string generated procs need special
# handling for IC, they end up in IC indexes etc. Thus we "log" them in the module graph
# and to pass them around to the NIF writer. This is not very elegant but it works.

type
  LogEntryKind* = enum
    HookEntry, ConverterEntry, MethodEntry, EnumToStrEntry, GenericInstEntry
  LogEntry* = object
    kind*: LogEntryKind
    op*: TTypeAttachedOp
    isGeneric*: bool
    module*: int  # Which module this entry belongs to
    key*: string
    sym*: PSym


proc forcePartial*(s: PSym) =
  ## Resets all impl-fields to their default values and sets state to Partial.
  ## This is useful for creating a stub symbol that can be lazily loaded later.
  ## The fields itemId, name, and disamb are preserved.
  s.state = Partial
  case s.kindImpl
  of routineKinds:
    s.gcUnsafetyReasonImpl = nil
    s.transformedBodyImpl = nil
  of skLet, skVar, skField, skForVar:
    s.guardImpl = nil
    s.bitsizeImpl = 0
    s.alignmentImpl = 0 # for alignment
  else: discard
  s.magicImpl = mNone
  s.typImpl = nil
  s.infoImpl = unknownLineInfo
  s.ownerFieldImpl = nil
  s.flagsImpl = {}
  s.astImpl = nil
  s.optionsImpl = {}
  s.positionImpl = 0
  s.offsetImpl = 0
  s.locImpl = TLoc()
  s.annexImpl = nil
  s.constraintImpl = nil
  s.instantiatedFromImpl = nil
  when defined(nimsuggest):
    s.endInfoImpl = unknownLineInfo
    s.hasUserSpecifiedTypeImpl = false
    s.allUsagesImpl = @[]
  when hasFFI:
    s.cnameImpl = ""

proc forcePartial*(t: PType) =
  ## Resets all impl-fields to their default values and sets state to Partial.
  ## This is useful for creating a stub type that can be lazily loaded later.
  ## The fields itemId, kind, uniqueId are preserved.
  t.state = Partial
  t.callConvImpl = ccNimCall
  t.flagsImpl = {}
  t.sonsImpl = @[]
  t.nImpl = nil
  t.ownerFieldImpl = nil
  t.symImpl = nil
  t.sizeImpl = defaultSize
  t.alignImpl = defaultAlignment
  t.paddingAtEndImpl = 0'i16
  t.locImpl = TLoc()
  t.typeInstImpl = nil

const                         # for all kind of hash tables:
  GrowthFactor* = 2           # must be power of 2, > 0
  StartSize* = 8              # must be power of 2, > 0

proc nextTry*(h, maxHash: Hash): Hash {.inline.} =
  result = ((5 * h) + 1) and maxHash
  # For any initial h in range(maxHash), repeating that maxHash times
  # generates each int in range(maxHash) exactly once (see any text on
  # random-number generation for proof).

proc mustRehash*(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc strTableContains*(t: TStrTable, n: PSym): bool =
  var h: Hash = n.name.h and high(t.data) # start with real hash value
  while t.data[h] != nil:
    if (t.data[h] == n):
      return true
    h = nextTry(h, high(t.data))
  result = false

proc strTableRawInsert(data: var seq[PSym], n: PSym) =
  var h: Hash = n.name.h and high(data)
  while data[h] != nil:
    if data[h] == n:
      # allowed for 'export' feature:
      #InternalError(n.info, "StrTableRawInsert: " & n.name.s)
      return
    h = nextTry(h, high(data))
  assert(data[h] == nil)
  data[h] = n

proc symTabReplaceRaw(data: var seq[PSym], prevSym: PSym, newSym: PSym) =
  assert prevSym.name.h == newSym.name.h
  var h: Hash = prevSym.name.h and high(data)
  while data[h] != nil:
    if data[h] == prevSym:
      data[h] = newSym
      return
    h = nextTry(h, high(data))
  assert false

proc symTabReplace*(t: var TStrTable, prevSym: PSym, newSym: PSym) =
  symTabReplaceRaw(t.data, prevSym, newSym)

proc strTableEnlarge(t: var TStrTable) =
  var n: seq[PSym]
  newSeq(n, t.data.len * GrowthFactor)
  for i in 0..high(t.data):
    if t.data[i] != nil: strTableRawInsert(n, t.data[i])
  swap(t.data, n)

proc strTableAdd*(t: var TStrTable, n: PSym) =
  if mustRehash(t.data.len, t.counter): strTableEnlarge(t)
  strTableRawInsert(t.data, n)
  inc(t.counter)

proc strTableInclReportConflict*(t: var TStrTable, n: PSym;
                                 onConflictKeepOld = false): PSym =
  # if `t` has a conflicting symbol (same identifier as `n`), return it
  # otherwise return `nil`. Incl `n` to `t` unless `onConflictKeepOld = true`
  # and a conflict was found.
  assert n.name != nil
  var h: Hash = n.name.h and high(t.data)
  var replaceSlot = -1
  while true:
    var it = t.data[h]
    if it == nil: break
    # Semantic checking can happen multiple times thanks to templates
    # and overloading: (var x=@[]; x).mapIt(it).
    # So it is possible the very same sym is added multiple
    # times to the symbol table which we allow here with the 'it == n' check.
    if it.name.id == n.name.id:
      if it == n: return nil
      replaceSlot = h
    h = nextTry(h, high(t.data))
  if replaceSlot >= 0:
    result = t.data[replaceSlot] # found it
    if not onConflictKeepOld:
      t.data[replaceSlot] = n # overwrite it with newer definition!
    return result # but return the old one
  elif mustRehash(t.data.len, t.counter):
    strTableEnlarge(t)
    strTableRawInsert(t.data, n)
  else:
    assert(t.data[h] == nil)
    t.data[h] = n
  inc(t.counter)
  result = nil

proc strTableIncl*(t: var TStrTable, n: PSym;
                   onConflictKeepOld = false): bool {.discardable.} =
  result = strTableInclReportConflict(t, n, onConflictKeepOld) != nil

proc strTableGet*(t: TStrTable, name: PIdent): PSym =
  var h: Hash = name.h and high(t.data)
  while true:
    result = t.data[h]
    if result == nil: break
    if result.name.id == name.id: break
    h = nextTry(h, high(t.data))
