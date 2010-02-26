unit llvm;

interface

const
  libname=''; {Setup as you need}

type
  Pdword  = ^dword;
  PLLVMBasicBlockRef  = ^LLVMBasicBlockRef;
  PLLVMExecutionEngineRef  = ^LLVMExecutionEngineRef;
  PLLVMGenericValueRef  = ^LLVMGenericValueRef;
  PLLVMMemoryBufferRef  = ^LLVMMemoryBufferRef;
  PLLVMModuleProviderRef  = ^LLVMModuleProviderRef;
  PLLVMModuleRef  = ^LLVMModuleRef;
  PLLVMTypeRef  = ^LLVMTypeRef;
  PLLVMValueRef  = ^LLVMValueRef;

{ Core.h  }
{ Opaque types.  }
{*
 * The top-level container for all LLVM global data.  See the LLVMContext class.
  }
type

   LLVMContextRef = LLVMOpaqueContext;
{*
 * The top-level container for all other LLVM Intermediate Representation (IR)
 * objects. See the llvm::Module class.
  }

   LLVMModuleRef = LLVMOpaqueModule;
{*
 * Each value in the LLVM IR has a type, an LLVMTypeRef. See the llvm::Type
 * class.
  }

   LLVMTypeRef = LLVMOpaqueType;
{*
 * When building recursive types using LLVMRefineType, LLVMTypeRef values may
 * become invalid; use LLVMTypeHandleRef to resolve this problem. See the
 * llvm::AbstractTypeHolder class.
  }

   LLVMTypeHandleRef = LLVMOpaqueTypeHandle;

   LLVMValueRef = LLVMOpaqueValue;

   LLVMBasicBlockRef = LLVMOpaqueBasicBlock;

   LLVMBuilderRef = LLVMOpaqueBuilder;
{ Used to provide a module to JIT or interpreter.
 * See the llvm::ModuleProvider class.
  }

   LLVMModuleProviderRef = LLVMOpaqueModuleProvider;
{ Used to provide a module to JIT or interpreter.
 * See the llvm::MemoryBuffer class.
  }

   LLVMMemoryBufferRef = LLVMOpaqueMemoryBuffer;
{* See the llvm::PassManagerBase class.  }

   LLVMPassManagerRef = LLVMOpaquePassManager;
{*
 * Used to iterate through the uses of a Value, allowing access to all Values
 * that use this Value.  See the llvm::Use and llvm::value_use_iterator classes.
  }

   LLVMUseIteratorRef = LLVMOpaqueUseIterator;

   LLVMAttribute = (LLVMZExtAttribute := 1 shl 0,LLVMSExtAttribute := 1 shl 1,
     LLVMNoReturnAttribute := 1 shl 2,LLVMInRegAttribute := 1 shl 3,
     LLVMStructRetAttribute := 1 shl 4,LLVMNoUnwindAttribute := 1 shl 5,
     LLVMNoAliasAttribute := 1 shl 6,LLVMByValAttribute := 1 shl 7,
     LLVMNestAttribute := 1 shl 8,LLVMReadNoneAttribute := 1 shl 9,
     LLVMReadOnlyAttribute := 1 shl 10,LLVMNoInlineAttribute := 1 shl 11,
     LLVMAlwaysInlineAttribute := 1 shl 12,LLVMOptimizeForSizeAttribute := 1 shl 13,
     LLVMStackProtectAttribute := 1 shl 14,LLVMStackProtectReqAttribute := 1 shl 15,
     LLVMNoCaptureAttribute := 1 shl 21,LLVMNoRedZoneAttribute := 1 shl 22,
     LLVMNoImplicitFloatAttribute := 1 shl 23,LLVMNakedAttribute := 1 shl 24,
     LLVMInlineHintAttribute := 1 shl 25);

   LLVMOpcode = (LLVMRet := 1,LLVMBr := 2,LLVMSwitch := 3,
     LLVMInvoke := 4,LLVMUnwind := 5,LLVMUnreachable := 6,
     LLVMAdd := 7,LLVMFAdd := 8,LLVMSub := 9,
     LLVMFSub := 10,LLVMMul := 11,LLVMFMul := 12,
     LLVMUDiv := 13,LLVMSDiv := 14,LLVMFDiv := 15,
     LLVMURem := 16,LLVMSRem := 17,LLVMFRem := 18,
     LLVMShl := 19,LLVMLShr := 20,LLVMAShr := 21,
     LLVMAnd := 22,LLVMOr := 23,LLVMXor := 24,
     LLVMMalloc := 25,LLVMFree := 26,LLVMAlloca := 27,
     LLVMLoad := 28,LLVMStore := 29,LLVMGetElementPtr := 30,
     LLVMTrunk := 31,LLVMZExt := 32,LLVMSExt := 33,
     LLVMFPToUI := 34,LLVMFPToSI := 35,LLVMUIToFP := 36,
     LLVMSIToFP := 37,LLVMFPTrunc := 38,LLVMFPExt := 39,
     LLVMPtrToInt := 40,LLVMIntToPtr := 41,
     LLVMBitCast := 42,LLVMICmp := 43,LLVMFCmp := 44,
     LLVMPHI := 45,LLVMCall := 46,LLVMSelect := 47,
     LLVMVAArg := 50,LLVMExtractElement := 51,
     LLVMInsertElement := 52,LLVMShuffleVector := 53,
     LLVMExtractValue := 54,LLVMInsertValue := 55
     );
{*< type with no size  }
{*< 32 bit floating point type  }
{*< 64 bit floating point type  }
{*< 80 bit floating point type (X87)  }
{*< 128 bit floating point type (112-bit mantissa) }
{*< 128 bit floating point type (two 64-bits)  }
{*< Labels  }
{*< Arbitrary bit width integers  }
{*< Functions  }
{*< Structures  }
{*< Arrays  }
{*< Pointers  }
{*< Opaque: type with unknown structure  }
{*< SIMD 'packed' format, or other vector type  }
{*< Metadata  }

   LLVMTypeKind = (LLVMVoidTypeKind,LLVMFloatTypeKind,LLVMDoubleTypeKind,
     LLVMX86_FP80TypeKind,LLVMFP128TypeKind,
     LLVMPPC_FP128TypeKind,LLVMLabelTypeKind,
     LLVMIntegerTypeKind,LLVMFunctionTypeKind,
     LLVMStructTypeKind,LLVMArrayTypeKind,LLVMPointerTypeKind,
     LLVMOpaqueTypeKind,LLVMVectorTypeKind,
     LLVMMetadataTypeKind);
{*< Externally visible function  }
{*< Keep one copy of function when linking (inline) }
{*< Same, but only replaced by something
                            equivalent.  }
{*< Keep one copy of function when linking (weak)  }
{*< Same, but only replaced by something
                            equivalent.  }
{*< Special purpose, only applies to global arrays  }
{*< Rename collisions when linking (static
                               functions)  }
{*< Like Internal, but omit from symbol table  }
{*< Function to be imported from DLL  }
{*< Function to be accessible from DLL  }
{*< ExternalWeak linkage description  }
{*< Stand-in functions for streaming fns from
                               bitcode  }
{*< Tentative definitions  }
{*< Like Private, but linker removes.  }

   LLVMLinkage = (LLVMExternalLinkage,LLVMAvailableExternallyLinkage,
     LLVMLinkOnceAnyLinkage,LLVMLinkOnceODRLinkage,
     LLVMWeakAnyLinkage,LLVMWeakODRLinkage,
     LLVMAppendingLinkage,LLVMInternalLinkage,
     LLVMPrivateLinkage,LLVMDLLImportLinkage,
     LLVMDLLExportLinkage,LLVMExternalWeakLinkage,
     LLVMGhostLinkage,LLVMCommonLinkage,LLVMLinkerPrivateLinkage
     );
{*< The GV is visible  }
{*< The GV is hidden  }
{*< The GV is protected  }

   LLVMVisibility = (LLVMDefaultVisibility,LLVMHiddenVisibility,
     LLVMProtectedVisibility);

   LLVMCallConv = (LLVMCCallConv := 0,LLVMFastCallConv := 8,
     LLVMColdCallConv := 9,LLVMX86StdcallCallConv := 64,
     LLVMX86FastcallCallConv := 65);
{*< equal  }
{*< not equal  }
{*< unsigned greater than  }
{*< unsigned greater or equal  }
{*< unsigned less than  }
{*< unsigned less or equal  }
{*< signed greater than  }
{*< signed greater or equal  }
{*< signed less than  }
{*< signed less or equal  }

   LLVMIntPredicate = (LLVMIntEQ := 32,LLVMIntNE,LLVMIntUGT,LLVMIntUGE,
     LLVMIntULT,LLVMIntULE,LLVMIntSGT,LLVMIntSGE,
     LLVMIntSLT,LLVMIntSLE);
{*< Always false (always folded)  }
{*< True if ordered and equal  }
{*< True if ordered and greater than  }
{*< True if ordered and greater than or equal  }
{*< True if ordered and less than  }
{*< True if ordered and less than or equal  }
{*< True if ordered and operands are unequal  }
{*< True if ordered (no nans)  }
{*< True if unordered: isnan(X) | isnan(Y)  }
{*< True if unordered or equal  }
{*< True if unordered or greater than  }
{*< True if unordered, greater than, or equal  }
{*< True if unordered or less than  }
{*< True if unordered, less than, or equal  }
{*< True if unordered or not equal  }
{*< Always true (always folded)  }

   LLVMRealPredicate = (LLVMRealPredicateFalse,LLVMRealOEQ,LLVMRealOGT,
     LLVMRealOGE,LLVMRealOLT,LLVMRealOLE,LLVMRealONE,
     LLVMRealORD,LLVMRealUNO,LLVMRealUEQ,LLVMRealUGT,
     LLVMRealUGE,LLVMRealULT,LLVMRealULE,LLVMRealUNE,
     LLVMRealPredicateTrue);
{===-- Error handling ----------------------------------------------------=== }

procedure LLVMDisposeMessage(Message:pchar);cdecl;external libname name 'LLVMDisposeMessage';
{===-- Modules -----------------------------------------------------------=== }
{ Create and destroy contexts.  }
function LLVMContextCreate:LLVMContextRef;cdecl;external libname name 'LLVMContextCreate';
function LLVMGetGlobalContext:LLVMContextRef;cdecl;external libname name 'LLVMGetGlobalContext';
procedure LLVMContextDispose(C:LLVMContextRef);cdecl;external libname name 'LLVMContextDispose';
{ Create and destroy modules.  }{* See llvm::Module::Module.  }
function LLVMModuleCreateWithName(ModuleID:pchar):LLVMModuleRef;cdecl;external libname name 'LLVMModuleCreateWithName';
function LLVMModuleCreateWithNameInContext(ModuleID:pchar; C:LLVMContextRef):LLVMModuleRef;cdecl;external libname name 'LLVMModuleCreateWithNameInContext';
{* See llvm::Module::~Module.  }
procedure LLVMDisposeModule(M:LLVMModuleRef);cdecl;external libname name 'LLVMDisposeModule';
{* Data layout. See Module::getDataLayout.  }
function LLVMGetDataLayout(M:LLVMModuleRef):pchar;cdecl;external libname name 'LLVMGetDataLayout';
procedure LLVMSetDataLayout(M:LLVMModuleRef; Triple:pchar);cdecl;external libname name 'LLVMSetDataLayout';
{* Target triple. See Module::getTargetTriple.  }
function LLVMGetTarget(M:LLVMModuleRef):pchar;cdecl;external libname name 'LLVMGetTarget';
procedure LLVMSetTarget(M:LLVMModuleRef; Triple:pchar);cdecl;external libname name 'LLVMSetTarget';
{* See Module::addTypeName.  }
function LLVMAddTypeName(M:LLVMModuleRef; Name:pchar; Ty:LLVMTypeRef):longint;cdecl;external libname name 'LLVMAddTypeName';
procedure LLVMDeleteTypeName(M:LLVMModuleRef; Name:pchar);cdecl;external libname name 'LLVMDeleteTypeName';
function LLVMGetTypeByName(M:LLVMModuleRef; Name:pchar):LLVMTypeRef;cdecl;external libname name 'LLVMGetTypeByName';
{* See Module::dump.  }
procedure LLVMDumpModule(M:LLVMModuleRef);cdecl;external libname name 'LLVMDumpModule';
{===-- Types -------------------------------------------------------------=== }
{ LLVM types conform to the following hierarchy:
 * 
 *   types:
 *     integer type
 *     real type
 *     function type
 *     sequence types:
 *       array type
 *       pointer type
 *       vector type
 *     void type
 *     label type
 *     opaque type
  }
{* See llvm::LLVMTypeKind::getTypeID.  }
function LLVMGetTypeKind(Ty:LLVMTypeRef):LLVMTypeKind;cdecl;external libname name 'LLVMGetTypeKind';
{* See llvm::LLVMType::getContext.  }
function LLVMGetTypeContext(Ty:LLVMTypeRef):LLVMContextRef;cdecl;external libname name 'LLVMGetTypeContext';
{ Operations on integer types  }
function LLVMInt1TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMInt1TypeInContext';
function LLVMInt8TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMInt8TypeInContext';
function LLVMInt16TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMInt16TypeInContext';
function LLVMInt32TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMInt32TypeInContext';
function LLVMInt64TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMInt64TypeInContext';
function LLVMIntTypeInContext(C:LLVMContextRef; NumBits:dword):LLVMTypeRef;cdecl;external libname name 'LLVMIntTypeInContext';
function LLVMInt1Type:LLVMTypeRef;cdecl;external libname name 'LLVMInt1Type';
function LLVMInt8Type:LLVMTypeRef;cdecl;external libname name 'LLVMInt8Type';
function LLVMInt16Type:LLVMTypeRef;cdecl;external libname name 'LLVMInt16Type';
function LLVMInt32Type:LLVMTypeRef;cdecl;external libname name 'LLVMInt32Type';
function LLVMInt64Type:LLVMTypeRef;cdecl;external libname name 'LLVMInt64Type';
function LLVMIntType(NumBits:dword):LLVMTypeRef;cdecl;external libname name 'LLVMIntType';
function LLVMGetIntTypeWidth(IntegerTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMGetIntTypeWidth';
{ Operations on real types  }
function LLVMFloatTypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMFloatTypeInContext';
function LLVMDoubleTypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMDoubleTypeInContext';
function LLVMX86FP80TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMX86FP80TypeInContext';
function LLVMFP128TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMFP128TypeInContext';
function LLVMPPCFP128TypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMPPCFP128TypeInContext';
function LLVMFloatType:LLVMTypeRef;cdecl;external libname name 'LLVMFloatType';
function LLVMDoubleType:LLVMTypeRef;cdecl;external libname name 'LLVMDoubleType';
function LLVMX86FP80Type:LLVMTypeRef;cdecl;external libname name 'LLVMX86FP80Type';
function LLVMFP128Type:LLVMTypeRef;cdecl;external libname name 'LLVMFP128Type';
function LLVMPPCFP128Type:LLVMTypeRef;cdecl;external libname name 'LLVMPPCFP128Type';
{ Operations on function types  }
function LLVMFunctionType(ReturnType:LLVMTypeRef; ParamTypes:pLLVMTypeRef; ParamCount:dword; IsVarArg:longint):LLVMTypeRef;cdecl;external libname name 'LLVMFunctionType';
function LLVMIsFunctionVarArg(FunctionTy:LLVMTypeRef):longint;cdecl;external libname name 'LLVMIsFunctionVarArg';
function LLVMGetReturnType(FunctionTy:LLVMTypeRef):LLVMTypeRef;cdecl;external libname name 'LLVMGetReturnType';
function LLVMCountParamTypes(FunctionTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMCountParamTypes';
procedure LLVMGetParamTypes(FunctionTy:LLVMTypeRef; Dest:pLLVMTypeRef);cdecl;external libname name 'LLVMGetParamTypes';
{ Operations on struct types  }
function LLVMStructTypeInContext(C:LLVMContextRef; ElementTypes:pLLVMTypeRef;
                                 ElementCount:dword;
                                 isPacked:longint):LLVMTypeRef;cdecl;external libname name 'LLVMStructTypeInContext';
function LLVMStructType(ElementTypes:pLLVMTypeRef; ElementCount:dword;
                        isPacked:longint):LLVMTypeRef;cdecl;external libname name 'LLVMStructType';
function LLVMCountStructElementTypes(StructTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMCountStructElementTypes';
procedure LLVMGetStructElementTypes(StructTy:LLVMTypeRef; Dest:pLLVMTypeRef);cdecl;external libname name 'LLVMGetStructElementTypes';
function LLVMIsPackedStruct(StructTy:LLVMTypeRef):longint;cdecl;external libname name 'LLVMIsPackedStruct';
{ Operations on array, pointer, and vector types (sequence types)  }
function LLVMArrayType(ElementType:LLVMTypeRef; ElementCount:dword):LLVMTypeRef;cdecl;external libname name 'LLVMArrayType';
function LLVMPointerType(ElementType:LLVMTypeRef; AddressSpace:dword):LLVMTypeRef;cdecl;external libname name 'LLVMPointerType';
function LLVMVectorType(ElementType:LLVMTypeRef; ElementCount:dword):LLVMTypeRef;cdecl;external libname name 'LLVMVectorType';
function LLVMGetElementType(Ty:LLVMTypeRef):LLVMTypeRef;cdecl;external libname name 'LLVMGetElementType';
function LLVMGetArrayLength(ArrayTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMGetArrayLength';
function LLVMGetPointerAddressSpace(PointerTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMGetPointerAddressSpace';
function LLVMGetVectorSize(VectorTy:LLVMTypeRef):dword;cdecl;external libname name 'LLVMGetVectorSize';
{ Operations on other types  }
function LLVMVoidTypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMVoidTypeInContext';
function LLVMLabelTypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMLabelTypeInContext';
function LLVMOpaqueTypeInContext(C:LLVMContextRef):LLVMTypeRef;cdecl;external libname name 'LLVMOpaqueTypeInContext';
function LLVMVoidType:LLVMTypeRef;cdecl;external libname name 'LLVMVoidType';
function LLVMLabelType:LLVMTypeRef;cdecl;external libname name 'LLVMLabelType';
function LLVMOpaqueType:LLVMTypeRef;cdecl;external libname name 'LLVMOpaqueType';
{ Operations on type handles  }
function LLVMCreateTypeHandle(PotentiallyAbstractTy:LLVMTypeRef):LLVMTypeHandleRef;cdecl;external libname name 'LLVMCreateTypeHandle';
procedure LLVMRefineType(AbstractTy:LLVMTypeRef; ConcreteTy:LLVMTypeRef);cdecl;external libname name 'LLVMRefineType';
function LLVMResolveTypeHandle(TypeHandle:LLVMTypeHandleRef):LLVMTypeRef;cdecl;external libname name 'LLVMResolveTypeHandle';
procedure LLVMDisposeTypeHandle(TypeHandle:LLVMTypeHandleRef);cdecl;external libname name 'LLVMDisposeTypeHandle';
{ Operations on all values  }
function LLVMTypeOf(Val:LLVMValueRef):LLVMTypeRef;cdecl;external libname name 'LLVMTypeOf';
function LLVMGetValueName(Val:LLVMValueRef):pchar;cdecl;external libname name 'LLVMGetValueName';
procedure LLVMSetValueName(Val:LLVMValueRef; Name:pchar);cdecl;external libname name 'LLVMSetValueName';
procedure LLVMDumpValue(Val:LLVMValueRef);cdecl;external libname name 'LLVMDumpValue';
procedure LLVMReplaceAllUsesWith(OldVal:LLVMValueRef; NewVal:LLVMValueRef);cdecl;external libname name 'LLVMReplaceAllUsesWith';
{ Conversion functions. Return the input value if it is an instance of the
   specified class, otherwise NULL. See llvm::dyn_cast_or_null<>.  }
function LLVMIsAArgument(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAArgument';
function LLVMIsABasicBlock(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsABasicBlock';
function LLVMIsAInlineAsm(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAInlineAsm';
function LLVMIsAUser(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUser';
function LLVMIsAConstant(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstant';
function LLVMIsAConstantAggregateZero(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantAggregateZero';
function LLVMIsAConstantArray(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantArray';
function LLVMIsAConstantExpr(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantExpr';
function LLVMIsAConstantFP(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantFP';
function LLVMIsAConstantInt(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantInt';
function LLVMIsAConstantPointerNull(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantPointerNull';
function LLVMIsAConstantStruct(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantStruct';
function LLVMIsAConstantVector(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAConstantVector';
function LLVMIsAGlobalValue(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAGlobalValue';
function LLVMIsAFunction(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFunction';
function LLVMIsAGlobalAlias(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAGlobalAlias';
function LLVMIsAGlobalVariable(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAGlobalVariable';
function LLVMIsAUndefValue(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUndefValue';
function LLVMIsAInstruction(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAInstruction';
function LLVMIsABinaryOperator(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsABinaryOperator';
function LLVMIsACallInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsACallInst';
function LLVMIsAIntrinsicInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAIntrinsicInst';
function LLVMIsADbgInfoIntrinsic(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgInfoIntrinsic';
function LLVMIsADbgDeclareInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgDeclareInst';
function LLVMIsADbgFuncStartInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgFuncStartInst';
function LLVMIsADbgRegionEndInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgRegionEndInst';
function LLVMIsADbgRegionStartInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgRegionStartInst';
function LLVMIsADbgStopPointInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsADbgStopPointInst';
function LLVMIsAEHSelectorInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAEHSelectorInst';
function LLVMIsAMemIntrinsic(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAMemIntrinsic';
function LLVMIsAMemCpyInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAMemCpyInst';
function LLVMIsAMemMoveInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAMemMoveInst';
function LLVMIsAMemSetInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAMemSetInst';
function LLVMIsACmpInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsACmpInst';
function LLVMIsAFCmpInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFCmpInst';
function LLVMIsAICmpInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAICmpInst';
function LLVMIsAExtractElementInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAExtractElementInst';
function LLVMIsAGetElementPtrInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAGetElementPtrInst';
function LLVMIsAInsertElementInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAInsertElementInst';
function LLVMIsAInsertValueInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAInsertValueInst';
function LLVMIsAPHINode(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAPHINode';
function LLVMIsASelectInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsASelectInst';
function LLVMIsAShuffleVectorInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAShuffleVectorInst';
function LLVMIsAStoreInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAStoreInst';
function LLVMIsATerminatorInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsATerminatorInst';
function LLVMIsABranchInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsABranchInst';
function LLVMIsAInvokeInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAInvokeInst';
function LLVMIsAReturnInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAReturnInst';
function LLVMIsASwitchInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsASwitchInst';
function LLVMIsAUnreachableInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUnreachableInst';
function LLVMIsAUnwindInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUnwindInst';
function LLVMIsAUnaryInstruction(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUnaryInstruction';
function LLVMIsAAllocationInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAAllocationInst';
function LLVMIsAAllocaInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAAllocaInst';
function LLVMIsACastInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsACastInst';
function LLVMIsABitCastInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsABitCastInst';
function LLVMIsAFPExtInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFPExtInst';
function LLVMIsAFPToSIInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFPToSIInst';
function LLVMIsAFPToUIInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFPToUIInst';
function LLVMIsAFPTruncInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFPTruncInst';
function LLVMIsAIntToPtrInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAIntToPtrInst';
function LLVMIsAPtrToIntInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAPtrToIntInst';
function LLVMIsASExtInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsASExtInst';
function LLVMIsASIToFPInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsASIToFPInst';
function LLVMIsATruncInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsATruncInst';
function LLVMIsAUIToFPInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAUIToFPInst';
function LLVMIsAZExtInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAZExtInst';
function LLVMIsAExtractValueInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAExtractValueInst';
function LLVMIsAFreeInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAFreeInst';
function LLVMIsALoadInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsALoadInst';
function LLVMIsAVAArgInst(Val:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMIsAVAArgInst';
{ Operations on Uses  }
function LLVMGetFirstUse(Val:LLVMValueRef):LLVMUseIteratorRef;cdecl;external libname name 'LLVMGetFirstUse';
function LLVMGetNextUse(U:LLVMUseIteratorRef):LLVMUseIteratorRef;cdecl;external libname name 'LLVMGetNextUse';
function LLVMGetUser(U:LLVMUseIteratorRef):LLVMValueRef;cdecl;external libname name 'LLVMGetUser';
function LLVMGetUsedValue(U:LLVMUseIteratorRef):LLVMValueRef;cdecl;external libname name 'LLVMGetUsedValue';
{ Operations on Users  }
function LLVMGetOperand(Val:LLVMValueRef; Index:dword):LLVMValueRef;cdecl;external libname name 'LLVMGetOperand';
{ Operations on constants of any type  }
function LLVMConstNull(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstNull';
{ all zeroes  }
function LLVMConstAllOnes(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstAllOnes';
{ only for int/vector  }
function LLVMGetUndef(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMGetUndef';
function LLVMIsConstant(Val:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsConstant';
function LLVMIsNull(Val:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsNull';
function LLVMIsUndef(Val:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsUndef';
function LLVMConstPointerNull(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstPointerNull';
{ Operations on scalar constants  }
function LLVMConstInt(IntTy:LLVMTypeRef; N:qword; SignExtend:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstInt';
function LLVMConstIntOfString(IntTy:LLVMTypeRef; Text:pchar; Radix:uint8_t):LLVMValueRef;cdecl;external libname name 'LLVMConstIntOfString';
function LLVMConstIntOfStringAndSize(IntTy:LLVMTypeRef; Text:pchar; SLen:dword; Radix:uint8_t):LLVMValueRef;cdecl;external libname name 'LLVMConstIntOfStringAndSize';
function LLVMConstReal(RealTy:LLVMTypeRef; N:double):LLVMValueRef;cdecl;external libname name 'LLVMConstReal';
function LLVMConstRealOfString(RealTy:LLVMTypeRef; Text:pchar):LLVMValueRef;cdecl;external libname name 'LLVMConstRealOfString';
function LLVMConstRealOfStringAndSize(RealTy:LLVMTypeRef; Text:pchar; SLen:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstRealOfStringAndSize';
function LLVMConstIntGetZExtValue(ConstantVal:LLVMValueRef):qword;cdecl;external libname name 'LLVMConstIntGetZExtValue';
function LLVMConstIntGetSExtValue(ConstantVal:LLVMValueRef):int64;cdecl;external libname name 'LLVMConstIntGetSExtValue';
{ Operations on composite constants  }
function LLVMConstStringInContext(C:LLVMContextRef; Str:pchar; Length:dword; DontNullTerminate:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstStringInContext';
function LLVMConstStructInContext(C:LLVMContextRef;
                                  ConstantVals:pLLVMValueRef; Count:dword; isPacked:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstStructInContext';
function LLVMConstString(Str:pchar; Length:dword; DontNullTerminate:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstString';
function LLVMConstArray(ElementTy:LLVMTypeRef; ConstantVals:pLLVMValueRef; Length:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstArray';
function LLVMConstStruct(ConstantVals:pLLVMValueRef; Count:dword; isPacked:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstStruct';
function LLVMConstVector(ScalarConstantVals:pLLVMValueRef; Size:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstVector';
{ Constant expressions  }
function LLVMGetConstOpcode(ConstantVal:LLVMValueRef):LLVMOpcode;cdecl;external libname name 'LLVMGetConstOpcode';
function LLVMAlignOf(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMAlignOf';
function LLVMSizeOf(Ty:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMSizeOf';
function LLVMConstNeg(ConstantVal:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstNeg';
function LLVMConstFNeg(ConstantVal:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFNeg';
function LLVMConstNot(ConstantVal:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstNot';
function LLVMConstAdd(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstAdd';
function LLVMConstNSWAdd(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstNSWAdd';
function LLVMConstFAdd(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFAdd';
function LLVMConstSub(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSub';
function LLVMConstFSub(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFSub';
function LLVMConstMul(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstMul';
function LLVMConstFMul(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFMul';
function LLVMConstUDiv(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstUDiv';
function LLVMConstSDiv(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSDiv';
function LLVMConstExactSDiv(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstExactSDiv';
function LLVMConstFDiv(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFDiv';
function LLVMConstURem(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstURem';
function LLVMConstSRem(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSRem';
function LLVMConstFRem(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFRem';
function LLVMConstAnd(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstAnd';
function LLVMConstOr(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstOr';
function LLVMConstXor(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstXor';
function LLVMConstICmp(Predicate:LLVMIntPredicate; LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstICmp';
function LLVMConstFCmp(Predicate:LLVMRealPredicate; LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFCmp';
function LLVMConstShl(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstShl';
function LLVMConstLShr(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstLShr';
function LLVMConstAShr(LHSConstant:LLVMValueRef; RHSConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstAShr';
function LLVMConstGEP(ConstantVal:LLVMValueRef; ConstantIndices:pLLVMValueRef; NumIndices:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstGEP';
function LLVMConstInBoundsGEP(ConstantVal:LLVMValueRef; ConstantIndices:pLLVMValueRef; NumIndices:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstInBoundsGEP';
function LLVMConstTrunc(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstTrunc';
function LLVMConstSExt(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSExt';
function LLVMConstZExt(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstZExt';
function LLVMConstFPTrunc(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFPTrunc';
function LLVMConstFPExt(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFPExt';
function LLVMConstUIToFP(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstUIToFP';
function LLVMConstSIToFP(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSIToFP';
function LLVMConstFPToUI(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFPToUI';
function LLVMConstFPToSI(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFPToSI';
function LLVMConstPtrToInt(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstPtrToInt';
function LLVMConstIntToPtr(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstIntToPtr';
function LLVMConstBitCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstBitCast';
function LLVMConstZExtOrBitCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstZExtOrBitCast';
function LLVMConstSExtOrBitCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSExtOrBitCast';
function LLVMConstTruncOrBitCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstTruncOrBitCast';
function LLVMConstPointerCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstPointerCast';
function LLVMConstIntCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef; isSigned:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstIntCast';
function LLVMConstFPCast(ConstantVal:LLVMValueRef; ToType:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMConstFPCast';
function LLVMConstSelect(ConstantCondition:LLVMValueRef; ConstantIfTrue:LLVMValueRef; ConstantIfFalse:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstSelect';
function LLVMConstExtractElement(VectorConstant:LLVMValueRef; IndexConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstExtractElement';
function LLVMConstInsertElement(VectorConstant:LLVMValueRef; ElementValueConstant:LLVMValueRef; IndexConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstInsertElement';
function LLVMConstShuffleVector(VectorAConstant:LLVMValueRef; VectorBConstant:LLVMValueRef; MaskConstant:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMConstShuffleVector';
function LLVMConstExtractValue(AggConstant:LLVMValueRef; IdxList:pdword; NumIdx:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstExtractValue';
function LLVMConstInsertValue(AggConstant:LLVMValueRef; ElementValueConstant:LLVMValueRef; IdxList:pdword; NumIdx:dword):LLVMValueRef;cdecl;external libname name 'LLVMConstInsertValue';

function LLVMConstInlineAsm(Ty:LLVMTypeRef; AsmString:pchar; Constraints:pchar; HasSideEffects:longint):LLVMValueRef;cdecl;external libname name 'LLVMConstInlineAsm';
{ Operations on global variables, functions, and aliases (globals)  }
function LLVMGetGlobalParent(Global:LLVMValueRef):LLVMModuleRef;cdecl;external libname name 'LLVMGetGlobalParent';
function LLVMIsDeclaration(Global:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsDeclaration';
function LLVMGetLinkage(Global:LLVMValueRef):LLVMLinkage;cdecl;external libname name 'LLVMGetLinkage';
procedure LLVMSetLinkage(Global:LLVMValueRef; Linkage:LLVMLinkage);cdecl;external libname name 'LLVMSetLinkage';
function LLVMGetSection(Global:LLVMValueRef):pchar;cdecl;external libname name 'LLVMGetSection';
procedure LLVMSetSection(Global:LLVMValueRef; Section:pchar);cdecl;external libname name 'LLVMSetSection';
function LLVMGetVisibility(Global:LLVMValueRef):LLVMVisibility;cdecl;external libname name 'LLVMGetVisibility';
procedure LLVMSetVisibility(Global:LLVMValueRef; Viz:LLVMVisibility);cdecl;external libname name 'LLVMSetVisibility';
function LLVMGetAlignment(Global:LLVMValueRef):dword;cdecl;external libname name 'LLVMGetAlignment';
procedure LLVMSetAlignment(Global:LLVMValueRef; Bytes:dword);cdecl;external libname name 'LLVMSetAlignment';
{ Operations on global variables  }

function LLVMAddGlobal(M:LLVMModuleRef; Ty:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMAddGlobal';

function LLVMGetNamedGlobal(M:LLVMModuleRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMGetNamedGlobal';
function LLVMGetFirstGlobal(M:LLVMModuleRef):LLVMValueRef;cdecl;external libname name 'LLVMGetFirstGlobal';
function LLVMGetLastGlobal(M:LLVMModuleRef):LLVMValueRef;cdecl;external libname name 'LLVMGetLastGlobal';
function LLVMGetNextGlobal(GlobalVar:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetNextGlobal';
function LLVMGetPreviousGlobal(GlobalVar:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetPreviousGlobal';
procedure LLVMDeleteGlobal(GlobalVar:LLVMValueRef);cdecl;external libname name 'LLVMDeleteGlobal';
function LLVMGetInitializer(GlobalVar:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetInitializer';
procedure LLVMSetInitializer(GlobalVar:LLVMValueRef; ConstantVal:LLVMValueRef);cdecl;external libname name 'LLVMSetInitializer';
function LLVMIsThreadLocal(GlobalVar:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsThreadLocal';
procedure LLVMSetThreadLocal(GlobalVar:LLVMValueRef; IsThreadLocal:longint);cdecl;external libname name 'LLVMSetThreadLocal';
function LLVMIsGlobalConstant(GlobalVar:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsGlobalConstant';
procedure LLVMSetGlobalConstant(GlobalVar:LLVMValueRef; IsConstant:longint);cdecl;external libname name 'LLVMSetGlobalConstant';
{ Operations on aliases  }
function LLVMAddAlias(M:LLVMModuleRef; Ty:LLVMTypeRef; Aliasee:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMAddAlias';
{ Operations on functions  }
function LLVMAddFunction(M:LLVMModuleRef; Name:pchar; FunctionTy:LLVMTypeRef):LLVMValueRef;cdecl;external libname name 'LLVMAddFunction';
function LLVMGetNamedFunction(M:LLVMModuleRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMGetNamedFunction';
function LLVMGetFirstFunction(M:LLVMModuleRef):LLVMValueRef;cdecl;external libname name 'LLVMGetFirstFunction';
function LLVMGetLastFunction(M:LLVMModuleRef):LLVMValueRef;cdecl;external libname name 'LLVMGetLastFunction';
function LLVMGetNextFunction(Fn:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetNextFunction';
function LLVMGetPreviousFunction(Fn:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetPreviousFunction';
procedure LLVMDeleteFunction(Fn:LLVMValueRef);cdecl;external libname name 'LLVMDeleteFunction';
function LLVMGetIntrinsicID(Fn:LLVMValueRef):dword;cdecl;external libname name 'LLVMGetIntrinsicID';
function LLVMGetFunctionCallConv(Fn:LLVMValueRef):dword;cdecl;external libname name 'LLVMGetFunctionCallConv';
procedure LLVMSetFunctionCallConv(Fn:LLVMValueRef; CC:dword);cdecl;external libname name 'LLVMSetFunctionCallConv';
function LLVMGetGC(Fn:LLVMValueRef):pchar;cdecl;external libname name 'LLVMGetGC';
procedure LLVMSetGC(Fn:LLVMValueRef; Name:pchar);cdecl;external libname name 'LLVMSetGC';
procedure LLVMAddFunctionAttr(Fn:LLVMValueRef; PA:LLVMAttribute);cdecl;external libname name 'LLVMAddFunctionAttr';
function LLVMGetFunctionAttr(Fn:LLVMValueRef):LLVMAttribute;cdecl;external libname name 'LLVMGetFunctionAttr';
procedure LLVMRemoveFunctionAttr(Fn:LLVMValueRef; PA:LLVMAttribute);cdecl;external libname name 'LLVMRemoveFunctionAttr';
{ Operations on parameters  }
function LLVMCountParams(Fn:LLVMValueRef):dword;cdecl;external libname name 'LLVMCountParams';
procedure LLVMGetParams(Fn:LLVMValueRef; Params:pLLVMValueRef);cdecl;external libname name 'LLVMGetParams';
function LLVMGetParam(Fn:LLVMValueRef; Index:dword):LLVMValueRef;cdecl;external libname name 'LLVMGetParam';
function LLVMGetParamParent(Inst:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetParamParent';
function LLVMGetFirstParam(Fn:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetFirstParam';
function LLVMGetLastParam(Fn:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetLastParam';
function LLVMGetNextParam(Arg:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetNextParam';
function LLVMGetPreviousParam(Arg:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetPreviousParam';
procedure LLVMAddAttribute(Arg:LLVMValueRef; PA:LLVMAttribute);cdecl;external libname name 'LLVMAddAttribute';
procedure LLVMRemoveAttribute(Arg:LLVMValueRef; PA:LLVMAttribute);cdecl;external libname name 'LLVMRemoveAttribute';
function LLVMGetAttribute(Arg:LLVMValueRef):LLVMAttribute;cdecl;external libname name 'LLVMGetAttribute';
procedure LLVMSetParamAlignment(Arg:LLVMValueRef; align:dword);cdecl;external libname name 'LLVMSetParamAlignment';
{ Operations on basic blocks  }
function LLVMBasicBlockAsValue(BB:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMBasicBlockAsValue';
function LLVMValueIsBasicBlock(Val:LLVMValueRef):longint;cdecl;external libname name 'LLVMValueIsBasicBlock';
function LLVMValueAsBasicBlock(Val:LLVMValueRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMValueAsBasicBlock';
function LLVMGetBasicBlockParent(BB:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMGetBasicBlockParent';
function LLVMCountBasicBlocks(Fn:LLVMValueRef):dword;cdecl;external libname name 'LLVMCountBasicBlocks';
procedure LLVMGetBasicBlocks(Fn:LLVMValueRef; BasicBlocks:pLLVMBasicBlockRef);cdecl;external libname name 'LLVMGetBasicBlocks';
function LLVMGetFirstBasicBlock(Fn:LLVMValueRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetFirstBasicBlock';
function LLVMGetLastBasicBlock(Fn:LLVMValueRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetLastBasicBlock';
function LLVMGetNextBasicBlock(BB:LLVMBasicBlockRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetNextBasicBlock';
function LLVMGetPreviousBasicBlock(BB:LLVMBasicBlockRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetPreviousBasicBlock';
function LLVMGetEntryBasicBlock(Fn:LLVMValueRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetEntryBasicBlock';
function LLVMAppendBasicBlockInContext(C:LLVMContextRef; Fn:LLVMValueRef; Name:pchar):LLVMBasicBlockRef;cdecl;external libname name 'LLVMAppendBasicBlockInContext';
function LLVMInsertBasicBlockInContext(C:LLVMContextRef; BB:LLVMBasicBlockRef; Name:pchar):LLVMBasicBlockRef;cdecl;external libname name 'LLVMInsertBasicBlockInContext';
function LLVMAppendBasicBlock(Fn:LLVMValueRef; Name:pchar):LLVMBasicBlockRef;cdecl;external libname name 'LLVMAppendBasicBlock';
function LLVMInsertBasicBlock(InsertBeforeBB:LLVMBasicBlockRef; Name:pchar):LLVMBasicBlockRef;cdecl;external libname name 'LLVMInsertBasicBlock';
procedure LLVMDeleteBasicBlock(BB:LLVMBasicBlockRef);cdecl;external libname name 'LLVMDeleteBasicBlock';
{ Operations on instructions  }
function LLVMGetInstructionParent(Inst:LLVMValueRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetInstructionParent';
function LLVMGetFirstInstruction(BB:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMGetFirstInstruction';
function LLVMGetLastInstruction(BB:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMGetLastInstruction';
function LLVMGetNextInstruction(Inst:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetNextInstruction';
function LLVMGetPreviousInstruction(Inst:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMGetPreviousInstruction';
{ Operations on call sites  }
procedure LLVMSetInstructionCallConv(Instr:LLVMValueRef; CC:dword);cdecl;external libname name 'LLVMSetInstructionCallConv';
function LLVMGetInstructionCallConv(Instr:LLVMValueRef):dword;cdecl;external libname name 'LLVMGetInstructionCallConv';
procedure LLVMAddInstrAttribute(Instr:LLVMValueRef; index:dword; para3:LLVMAttribute);cdecl;external libname name 'LLVMAddInstrAttribute';
procedure LLVMRemoveInstrAttribute(Instr:LLVMValueRef; index:dword; para3:LLVMAttribute);cdecl;external libname name 'LLVMRemoveInstrAttribute';
procedure LLVMSetInstrParamAlignment(Instr:LLVMValueRef; index:dword; align:dword);cdecl;external libname name 'LLVMSetInstrParamAlignment';
{ Operations on call instructions (only)  }
function LLVMIsTailCall(CallInst:LLVMValueRef):longint;cdecl;external libname name 'LLVMIsTailCall';
procedure LLVMSetTailCall(CallInst:LLVMValueRef; IsTailCall:longint);cdecl;external libname name 'LLVMSetTailCall';
{ Operations on phi nodes  }
procedure LLVMAddIncoming(PhiNode:LLVMValueRef; IncomingValues:pLLVMValueRef; IncomingBlocks:pLLVMBasicBlockRef; Count:dword);cdecl;external libname name 'LLVMAddIncoming';
function LLVMCountIncoming(PhiNode:LLVMValueRef):dword;cdecl;external libname name 'LLVMCountIncoming';
function LLVMGetIncomingValue(PhiNode:LLVMValueRef; Index:dword):LLVMValueRef;cdecl;external libname name 'LLVMGetIncomingValue';
function LLVMGetIncomingBlock(PhiNode:LLVMValueRef; Index:dword):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetIncomingBlock';
{===-- Instruction builders ----------------------------------------------=== }
{ An instruction builder represents a point within a basic block, and is the
 * exclusive means of building instructions using the C interface.
  }
function LLVMCreateBuilderInContext(C:LLVMContextRef):LLVMBuilderRef;cdecl;external libname name 'LLVMCreateBuilderInContext';
function LLVMCreateBuilder:LLVMBuilderRef;cdecl;external libname name 'LLVMCreateBuilder';
procedure LLVMPositionBuilder(Builder:LLVMBuilderRef; Block:LLVMBasicBlockRef; Instr:LLVMValueRef);cdecl;external libname name 'LLVMPositionBuilder';
procedure LLVMPositionBuilderBefore(Builder:LLVMBuilderRef; Instr:LLVMValueRef);cdecl;external libname name 'LLVMPositionBuilderBefore';
procedure LLVMPositionBuilderAtEnd(Builder:LLVMBuilderRef; Block:LLVMBasicBlockRef);cdecl;external libname name 'LLVMPositionBuilderAtEnd';
function LLVMGetInsertBlock(Builder:LLVMBuilderRef):LLVMBasicBlockRef;cdecl;external libname name 'LLVMGetInsertBlock';
procedure LLVMClearInsertionPosition(Builder:LLVMBuilderRef);cdecl;external libname name 'LLVMClearInsertionPosition';
procedure LLVMInsertIntoBuilder(Builder:LLVMBuilderRef; Instr:LLVMValueRef);cdecl;external libname name 'LLVMInsertIntoBuilder';
procedure LLVMInsertIntoBuilderWithName(Builder:LLVMBuilderRef; Instr:LLVMValueRef; Name:pchar);cdecl;external libname name 'LLVMInsertIntoBuilderWithName';
procedure LLVMDisposeBuilder(Builder:LLVMBuilderRef);cdecl;external libname name 'LLVMDisposeBuilder';
{ Terminators  }
function LLVMBuildRetVoid(para1:LLVMBuilderRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildRetVoid';
function LLVMBuildRet(para1:LLVMBuilderRef; V:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildRet';
function LLVMBuildAggregateRet(para1:LLVMBuilderRef; RetVals:pLLVMValueRef; N:dword):LLVMValueRef;cdecl;external libname name 'LLVMBuildAggregateRet';
function LLVMBuildBr(para1:LLVMBuilderRef; Dest:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildBr';
function LLVMBuildCondBr(para1:LLVMBuilderRef; Cond:LLVMValueRef;
                         ThenBranch:LLVMBasicBlockRef; ElseBranch:LLVMBasicBlockRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildCondBr';
function LLVMBuildSwitch(para1:LLVMBuilderRef; V:LLVMValueRef; ElseBranch:LLVMBasicBlockRef; NumCases:dword):LLVMValueRef;cdecl;external libname name 'LLVMBuildSwitch';
function LLVMBuildInvoke(para1:LLVMBuilderRef; Fn:LLVMValueRef; Args:pLLVMValueRef; NumArgs:dword; ThenBranch:LLVMBasicBlockRef; 
           Catch:LLVMBasicBlockRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildInvoke';
function LLVMBuildUnwind(para1:LLVMBuilderRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildUnwind';
function LLVMBuildUnreachable(para1:LLVMBuilderRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildUnreachable';
{ Add a case to the switch instruction  }
procedure LLVMAddCase(Switch:LLVMValueRef; OnVal:LLVMValueRef; Dest:LLVMBasicBlockRef);cdecl;external libname name 'LLVMAddCase';
{ Arithmetic  }
function LLVMBuildAdd(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildAdd';
function LLVMBuildNSWAdd(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildNSWAdd';
function LLVMBuildFAdd(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFAdd';
function LLVMBuildSub(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSub';
function LLVMBuildFSub(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFSub';
function LLVMBuildMul(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildMul';
function LLVMBuildFMul(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFMul';
function LLVMBuildUDiv(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildUDiv';
function LLVMBuildSDiv(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSDiv';
function LLVMBuildExactSDiv(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildExactSDiv';
function LLVMBuildFDiv(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFDiv';
function LLVMBuildURem(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildURem';
function LLVMBuildSRem(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSRem';
function LLVMBuildFRem(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFRem';
function LLVMBuildShl(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildShl';
function LLVMBuildLShr(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildLShr';
function LLVMBuildAShr(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildAShr';
function LLVMBuildAnd(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildAnd';
function LLVMBuildOr(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildOr';
function LLVMBuildXor(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildXor';
function LLVMBuildNeg(para1:LLVMBuilderRef; V:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildNeg';
function LLVMBuildFNeg(para1:LLVMBuilderRef; V:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFNeg';
function LLVMBuildNot(para1:LLVMBuilderRef; V:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildNot';
{ Memory  }
function LLVMBuildMalloc(para1:LLVMBuilderRef; Ty:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildMalloc';
function LLVMBuildArrayMalloc(para1:LLVMBuilderRef; Ty:LLVMTypeRef; Val:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildArrayMalloc';
function LLVMBuildAlloca(para1:LLVMBuilderRef; Ty:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildAlloca';
function LLVMBuildArrayAlloca(para1:LLVMBuilderRef; Ty:LLVMTypeRef; Val:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildArrayAlloca';
function LLVMBuildFree(para1:LLVMBuilderRef; PointerVal:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildFree';
function LLVMBuildLoad(para1:LLVMBuilderRef; PointerVal:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildLoad';
function LLVMBuildStore(para1:LLVMBuilderRef; Val:LLVMValueRef; Ptr:LLVMValueRef):LLVMValueRef;cdecl;external libname name 'LLVMBuildStore';
function LLVMBuildGEP(B:LLVMBuilderRef; Pointer:LLVMValueRef; Indices:pLLVMValueRef; NumIndices:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildGEP';
function LLVMBuildInBoundsGEP(B:LLVMBuilderRef; Pointer:LLVMValueRef; Indices:pLLVMValueRef; NumIndices:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildInBoundsGEP';
function LLVMBuildStructGEP(B:LLVMBuilderRef; Pointer:LLVMValueRef; Idx:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildStructGEP';
function LLVMBuildGlobalString(B:LLVMBuilderRef; Str:pchar; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildGlobalString';
function LLVMBuildGlobalStringPtr(B:LLVMBuilderRef; Str:pchar; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildGlobalStringPtr';
{ Casts  }
function LLVMBuildTrunc(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildTrunc';
function LLVMBuildZExt(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildZExt';
function LLVMBuildSExt(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSExt';
function LLVMBuildFPToUI(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFPToUI';
function LLVMBuildFPToSI(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFPToSI';
function LLVMBuildUIToFP(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildUIToFP';
function LLVMBuildSIToFP(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSIToFP';
function LLVMBuildFPTrunc(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFPTrunc';
function LLVMBuildFPExt(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFPExt';
function LLVMBuildPtrToInt(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildPtrToInt';
function LLVMBuildIntToPtr(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildIntToPtr';
function LLVMBuildBitCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildBitCast';
function LLVMBuildZExtOrBitCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildZExtOrBitCast';
function LLVMBuildSExtOrBitCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSExtOrBitCast';
function LLVMBuildTruncOrBitCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildTruncOrBitCast';
function LLVMBuildPointerCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildPointerCast';
function LLVMBuildIntCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildIntCast';
function LLVMBuildFPCast(para1:LLVMBuilderRef; Val:LLVMValueRef; DestTy:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFPCast';
{ Comparisons  }
function LLVMBuildICmp(para1:LLVMBuilderRef; Op:LLVMIntPredicate; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildICmp';
function LLVMBuildFCmp(para1:LLVMBuilderRef; Op:LLVMRealPredicate; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildFCmp';
{ Miscellaneous instructions  }
function LLVMBuildPhi(para1:LLVMBuilderRef; Ty:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildPhi';
function LLVMBuildCall(para1:LLVMBuilderRef; Fn:LLVMValueRef; Args:pLLVMValueRef; NumArgs:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildCall';
function LLVMBuildSelect(para1:LLVMBuilderRef; Cond:LLVMValueRef; ThenBranch:LLVMValueRef; ElseBranch:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildSelect';
function LLVMBuildVAArg(para1:LLVMBuilderRef; List:LLVMValueRef; Ty:LLVMTypeRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildVAArg';
function LLVMBuildExtractElement(para1:LLVMBuilderRef; VecVal:LLVMValueRef; Index:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildExtractElement';
function LLVMBuildInsertElement(para1:LLVMBuilderRef; VecVal:LLVMValueRef; EltVal:LLVMValueRef; Index:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildInsertElement';
function LLVMBuildShuffleVector(para1:LLVMBuilderRef; V1:LLVMValueRef; V2:LLVMValueRef; Mask:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildShuffleVector';
function LLVMBuildExtractValue(para1:LLVMBuilderRef; AggVal:LLVMValueRef; Index:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildExtractValue';
function LLVMBuildInsertValue(para1:LLVMBuilderRef; AggVal:LLVMValueRef; EltVal:LLVMValueRef; Index:dword; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildInsertValue';
function LLVMBuildIsNull(para1:LLVMBuilderRef; Val:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildIsNull';
function LLVMBuildIsNotNull(para1:LLVMBuilderRef; Val:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildIsNotNull';
function LLVMBuildPtrDiff(para1:LLVMBuilderRef; LHS:LLVMValueRef; RHS:LLVMValueRef; Name:pchar):LLVMValueRef;cdecl;external libname name 'LLVMBuildPtrDiff';
{===-- Module providers --------------------------------------------------=== }
{ Encapsulates the module M in a module provider, taking ownership of the
 * module.
 * See the constructor llvm::ExistingModuleProvider::ExistingModuleProvider.
  }
function LLVMCreateModuleProviderForExistingModule(M:LLVMModuleRef):LLVMModuleProviderRef;cdecl;external libname name 'LLVMCreateModuleProviderForExistingModule';
{ Destroys the module provider MP as well as the contained module.
 * See the destructor llvm::ModuleProvider::~ModuleProvider.
  }
procedure LLVMDisposeModuleProvider(MP:LLVMModuleProviderRef);cdecl;external libname name 'LLVMDisposeModuleProvider';
{===-- Memory buffers ----------------------------------------------------=== }
function LLVMCreateMemoryBufferWithContentsOfFile(Path:pchar; OutMemBuf:pLLVMMemoryBufferRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMCreateMemoryBufferWithContentsOfFile';
function LLVMCreateMemoryBufferWithSTDIN(OutMemBuf:pLLVMMemoryBufferRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMCreateMemoryBufferWithSTDIN';
procedure LLVMDisposeMemoryBuffer(MemBuf:LLVMMemoryBufferRef);cdecl;external libname name 'LLVMDisposeMemoryBuffer';
{===-- Pass Managers -----------------------------------------------------=== }
{* Constructs a new whole-module pass pipeline. This type of pipeline is
    suitable for link-time optimization and whole-module transformations.
    See llvm::PassManager::PassManager.  }
function LLVMCreatePassManager:LLVMPassManagerRef;cdecl;external libname name 'LLVMCreatePassManager';
{* Constructs a new function-by-function pass pipeline over the module
    provider. It does not take ownership of the module provider. This type of
    pipeline is suitable for code generation and JIT compilation tasks.
    See llvm::FunctionPassManager::FunctionPassManager.  }
function LLVMCreateFunctionPassManager(MP:LLVMModuleProviderRef):LLVMPassManagerRef;cdecl;external libname name 'LLVMCreateFunctionPassManager';
{* Initializes, executes on the provided module, and finalizes all of the
    passes scheduled in the pass manager. Returns 1 if any of the passes
    modified the module, 0 otherwise. See llvm::PassManager::run(Module&).  }
function LLVMRunPassManager(PM:LLVMPassManagerRef; M:LLVMModuleRef):longint;cdecl;external libname name 'LLVMRunPassManager';
{* Initializes all of the function passes scheduled in the function pass
    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
    See llvm::FunctionPassManager::doInitialization.  }
function LLVMInitializeFunctionPassManager(FPM:LLVMPassManagerRef):longint;cdecl;external libname name 'LLVMInitializeFunctionPassManager';
{* Executes all of the function passes scheduled in the function pass manager
    on the provided function. Returns 1 if any of the passes modified the
    function, false otherwise.
    See llvm::FunctionPassManager::run(Function&).  }
function LLVMRunFunctionPassManager(FPM:LLVMPassManagerRef; F:LLVMValueRef):longint;cdecl;external libname name 'LLVMRunFunctionPassManager';
{* Finalizes all of the function passes scheduled in in the function pass
    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
    See llvm::FunctionPassManager::doFinalization.  }
function LLVMFinalizeFunctionPassManager(FPM:LLVMPassManagerRef):longint;cdecl;external libname name 'LLVMFinalizeFunctionPassManager';
{* Frees the memory of a pass pipeline. For function pipelines, does not free
    the module provider.
    See llvm::PassManagerBase::~PassManagerBase.  }
procedure LLVMDisposePassManager(PM:LLVMPassManagerRef);cdecl;external libname name 'LLVMDisposePassManager';
{ Analysis.h  }
{ verifier will print to stderr and abort()  }
{ verifier will print to stderr and return 1  }
{ verifier will just return 1  }
type

   LLVMVerifierFailureAction = (LLVMAbortProcessAction,LLVMPrintMessageAction,
     LLVMReturnStatusAction);
{ Verifies that a module is valid, taking the specified action if not.
   Optionally returns a human-readable description of any invalid constructs.
   OutMessage must be disposed with LLVMDisposeMessage.  }

function LLVMVerifyModule(M:LLVMModuleRef; Action:LLVMVerifierFailureAction; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMVerifyModule';
{ Verifies that a single function is valid, taking the specified action. Useful
   for debugging.  }
function LLVMVerifyFunction(Fn:LLVMValueRef; Action:LLVMVerifierFailureAction):longint;cdecl;external libname name 'LLVMVerifyFunction';
{ Open up a ghostview window that displays the CFG of the current function.
   Useful for debugging.  }
procedure LLVMViewFunctionCFG(Fn:LLVMValueRef);cdecl;external libname name 'LLVMViewFunctionCFG';
procedure LLVMViewFunctionCFGOnly(Fn:LLVMValueRef);cdecl;external libname name 'LLVMViewFunctionCFGOnly';
{ BitReader.h  }
{ Builds a module from the bitcode in the specified memory buffer, returning a
   reference to the module via the OutModule parameter. Returns 0 on success.
   Optionally returns a human-readable error message via OutMessage.  }function LLVMParseBitcode(MemBuf:LLVMMemoryBufferRef; OutModule:pLLVMModuleRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMParseBitcode';
function LLVMParseBitcodeInContext(ContextRef:LLVMContextRef; MemBuf:LLVMMemoryBufferRef; OutModule:pLLVMModuleRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMParseBitcodeInContext';
{ Reads a module from the specified path, returning via the OutMP parameter
   a module provider which performs lazy deserialization. Returns 0 on success.
   Optionally returns a human-readable error message via OutMessage.  }function LLVMGetBitcodeModuleProvider(MemBuf:LLVMMemoryBufferRef; OutMP:pLLVMModuleProviderRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMGetBitcodeModuleProvider';
function LLVMGetBitcodeModuleProviderInContext(ContextRef:LLVMContextRef; MemBuf:LLVMMemoryBufferRef; OutMP:pLLVMModuleProviderRef; OutMessage:Ppchar):longint;cdecl;external libname name 'LLVMGetBitcodeModuleProviderInContext';
{ BitWriter.h  }
{===-- Operations on modules ---------------------------------------------=== }
{ Writes a module to an open file descriptor. Returns 0 on success.
   Closes the Handle. Use dup first if this is not what you want.  }function LLVMWriteBitcodeToFileHandle(M:LLVMModuleRef; Handle:longint):longint;cdecl;external libname name 'LLVMWriteBitcodeToFileHandle';
{ Writes a module to the specified path. Returns 0 on success.  }function LLVMWriteBitcodeToFile(M:LLVMModuleRef; Path:pchar):longint;cdecl;external libname name 'LLVMWriteBitcodeToFile';
{ Target.h  }

const
   LLVMBigEndian = 0;   
   LLVMLittleEndian = 1;   
type

   LLVMByteOrdering = longint;

   LLVMTargetDataRef = LLVMOpaqueTargetData;

   LLVMStructLayoutRef = LLVMStructLayout;
{===-- Target Data -------------------------------------------------------=== }
{* Creates target data from a target layout string.
    See the constructor llvm::TargetData::TargetData.  }

function LLVMCreateTargetData(StringRep:pchar):LLVMTargetDataRef;cdecl;external libname name 'LLVMCreateTargetData';
{* Adds target data information to a pass manager. This does not take ownership
    of the target data.
    See the method llvm::PassManagerBase::add.  }
procedure LLVMAddTargetData(para1:LLVMTargetDataRef; para2:LLVMPassManagerRef);cdecl;external libname name 'LLVMAddTargetData';
{* Converts target data to a target layout string. The string must be disposed
    with LLVMDisposeMessage.
    See the constructor llvm::TargetData::TargetData.  }
function LLVMCopyStringRepOfTargetData(para1:LLVMTargetDataRef):pchar;cdecl;external libname name 'LLVMCopyStringRepOfTargetData';
{* Returns the byte order of a target, either LLVMBigEndian or
    LLVMLittleEndian.
    See the method llvm::TargetData::isLittleEndian.  }
function LLVMByteOrder(para1:LLVMTargetDataRef):LLVMByteOrdering;cdecl;external libname name 'LLVMByteOrder';
{* Returns the pointer size in bytes for a target.
    See the method llvm::TargetData::getPointerSize.  }
function LLVMPointerSize(para1:LLVMTargetDataRef):dword;cdecl;external libname name 'LLVMPointerSize';
{* Returns the integer type that is the same size as a pointer on a target.
    See the method llvm::TargetData::getIntPtrType.  }
function LLVMIntPtrType(para1:LLVMTargetDataRef):LLVMTypeRef;cdecl;external libname name 'LLVMIntPtrType';
{* Computes the size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeSizeInBits.  }
function LLVMSizeOfTypeInBits(para1:LLVMTargetDataRef; para2:LLVMTypeRef):qword;cdecl;external libname name 'LLVMSizeOfTypeInBits';
{* Computes the storage size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeStoreSize.  }
function LLVMStoreSizeOfType(para1:LLVMTargetDataRef; para2:LLVMTypeRef):qword;cdecl;external libname name 'LLVMStoreSizeOfType';
{* Computes the ABI size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeAllocSize.  }
function LLVMABISizeOfType(para1:LLVMTargetDataRef; para2:LLVMTypeRef):qword;cdecl;external libname name 'LLVMABISizeOfType';
{* Computes the ABI alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize.  }
function LLVMABIAlignmentOfType(para1:LLVMTargetDataRef; para2:LLVMTypeRef):dword;cdecl;external libname name 'LLVMABIAlignmentOfType';
{* Computes the call frame alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize.  }
function LLVMCallFrameAlignmentOfType(para1:LLVMTargetDataRef; para2:LLVMTypeRef):dword;cdecl;external libname name 'LLVMCallFrameAlignmentOfType';
{* Computes the preferred alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize.  }
function LLVMPreferredAlignmentOfType(para1:LLVMTargetDataRef; para2:LLVMTypeRef):dword;cdecl;external libname name 'LLVMPreferredAlignmentOfType';
{* Computes the preferred alignment of a global variable in bytes for a target.
    See the method llvm::TargetData::getPreferredAlignment.  }
function LLVMPreferredAlignmentOfGlobal(para1:LLVMTargetDataRef; GlobalVar:LLVMValueRef):dword;cdecl;external libname name 'LLVMPreferredAlignmentOfGlobal';
{* Computes the structure element that contains the byte offset for a target.
    See the method llvm::StructLayout::getElementContainingOffset.  }
function LLVMElementAtOffset(para1:LLVMTargetDataRef; StructTy:LLVMTypeRef; Offset:qword):dword;cdecl;external libname name 'LLVMElementAtOffset';
{* Computes the byte offset of the indexed struct element for a target.
    See the method llvm::StructLayout::getElementContainingOffset.  }
function LLVMOffsetOfElement(para1:LLVMTargetDataRef; StructTy:LLVMTypeRef; Element:dword):qword;cdecl;external libname name 'LLVMOffsetOfElement';
{* Struct layouts are speculatively cached. If a TargetDataRef is alive when
    types are being refined and removed, this method must be called whenever a
    struct type is removed to avoid a dangling pointer in this cache.
    See the method llvm::TargetData::InvalidateStructLayoutInfo.  }
procedure LLVMInvalidateStructLayout(para1:LLVMTargetDataRef; StructTy:LLVMTypeRef);cdecl;external libname name 'LLVMInvalidateStructLayout';
{* Deallocates a TargetData.
    See the destructor llvm::TargetData::~TargetData.  }
procedure LLVMDisposeTargetData(para1:LLVMTargetDataRef);cdecl;external libname name 'LLVMDisposeTargetData';
{ ExecutionEngine.h  }
procedure LLVMLinkInJIT;cdecl;external libname name 'LLVMLinkInJIT';
procedure LLVMLinkInInterpreter;cdecl;external libname name 'LLVMLinkInInterpreter';
type

   LLVMGenericValueRef = LLVMOpaqueGenericValue;

   LLVMExecutionEngineRef = LLVMOpaqueExecutionEngine;
{===-- Operations on generic values --------------------------------------=== }

function LLVMCreateGenericValueOfInt(Ty:LLVMTypeRef; N:qword; IsSigned:longint):LLVMGenericValueRef;cdecl;external libname name 'LLVMCreateGenericValueOfInt';
function LLVMCreateGenericValueOfPointer(P:pointer):LLVMGenericValueRef;cdecl;external libname name 'LLVMCreateGenericValueOfPointer';
function LLVMCreateGenericValueOfFloat(Ty:LLVMTypeRef; N:double):LLVMGenericValueRef;cdecl;external libname name 'LLVMCreateGenericValueOfFloat';
function LLVMGenericValueIntWidth(GenValRef:LLVMGenericValueRef):dword;cdecl;external libname name 'LLVMGenericValueIntWidth';
function LLVMGenericValueToInt(GenVal:LLVMGenericValueRef; IsSigned:longint):qword;cdecl;external libname name 'LLVMGenericValueToInt';
function LLVMGenericValueToPointer(GenVal:LLVMGenericValueRef):pointer;cdecl;external libname name 'LLVMGenericValueToPointer';
function LLVMGenericValueToFloat(TyRef:LLVMTypeRef; GenVal:LLVMGenericValueRef):double;cdecl;external libname name 'LLVMGenericValueToFloat';
procedure LLVMDisposeGenericValue(GenVal:LLVMGenericValueRef);cdecl;external libname name 'LLVMDisposeGenericValue';
{===-- Operations on execution engines -----------------------------------=== }
function LLVMCreateExecutionEngine(OutEE:pLLVMExecutionEngineRef; MP:LLVMModuleProviderRef; OutError:Ppchar):longint;cdecl;external libname name 'LLVMCreateExecutionEngine';
function LLVMCreateInterpreter(OutInterp:pLLVMExecutionEngineRef; MP:LLVMModuleProviderRef; OutError:Ppchar):longint;cdecl;external libname name 'LLVMCreateInterpreter';
function LLVMCreateJITCompiler(OutJIT:pLLVMExecutionEngineRef; MP:LLVMModuleProviderRef; OptLevel:dword; OutError:Ppchar):longint;cdecl;external libname name 'LLVMCreateJITCompiler';
procedure LLVMDisposeExecutionEngine(EE:LLVMExecutionEngineRef);cdecl;external libname name 'LLVMDisposeExecutionEngine';
procedure LLVMRunStaticConstructors(EE:LLVMExecutionEngineRef);cdecl;external libname name 'LLVMRunStaticConstructors';
procedure LLVMRunStaticDestructors(EE:LLVMExecutionEngineRef);cdecl;external libname name 'LLVMRunStaticDestructors';
(* Const before declarator ignored *)
(* Const before declarator ignored *)
function LLVMRunFunctionAsMain(EE:LLVMExecutionEngineRef; F:LLVMValueRef; ArgC:dword; ArgV:Ppchar; EnvP:Ppchar):longint;cdecl;external libname name 'LLVMRunFunctionAsMain';
function LLVMRunFunction(EE:LLVMExecutionEngineRef; F:LLVMValueRef; NumArgs:dword; Args:pLLVMGenericValueRef):LLVMGenericValueRef;cdecl;external libname name 'LLVMRunFunction';
procedure LLVMFreeMachineCodeForFunction(EE:LLVMExecutionEngineRef; F:LLVMValueRef);cdecl;external libname name 'LLVMFreeMachineCodeForFunction';
procedure LLVMAddModuleProvider(EE:LLVMExecutionEngineRef; MP:LLVMModuleProviderRef);cdecl;external libname name 'LLVMAddModuleProvider';
function LLVMRemoveModuleProvider(EE:LLVMExecutionEngineRef; MP:LLVMModuleProviderRef; OutMod:pLLVMModuleRef; OutError:Ppchar):longint;cdecl;external libname name 'LLVMRemoveModuleProvider';
function LLVMFindFunction(EE:LLVMExecutionEngineRef; Name:pchar; OutFn:pLLVMValueRef):longint;cdecl;external libname name 'LLVMFindFunction';
function LLVMGetExecutionEngineTargetData(EE:LLVMExecutionEngineRef):LLVMTargetDataRef;cdecl;external libname name 'LLVMGetExecutionEngineTargetData';
procedure LLVMAddGlobalMapping(EE:LLVMExecutionEngineRef; Global:LLVMValueRef; Addr:pointer);cdecl;external libname name 'LLVMAddGlobalMapping';
function LLVMGetPointerToGlobal(EE:LLVMExecutionEngineRef; Global:LLVMValueRef):pointer;cdecl;external libname name 'LLVMGetPointerToGlobal';
{ LinkTimeOptimizer.h  }
{/ This provides a dummy type for pointers to the LTO object. }
type

   llvm_lto_t = pointer;
{/ This provides a C-visible enumerator to manage status codes. }
{/ This should map exactly onto the C++ enumerator LTOStatus. }
{  Added C-specific error codes }

   llvm_lto_status = (LLVM_LTO_UNKNOWN,LLVM_LTO_OPT_SUCCESS,
     LLVM_LTO_READ_SUCCESS,LLVM_LTO_READ_FAILURE,
     LLVM_LTO_WRITE_FAILURE,LLVM_LTO_NO_TARGET,
     LLVM_LTO_NO_WORK,LLVM_LTO_MODULE_MERGE_FAILURE,
     LLVM_LTO_ASM_FAILURE,LLVM_LTO_NULL_OBJECT
     );
   llvm_lto_status_t = llvm_lto_status;
{/ This provides C interface to initialize link time optimizer. This allows }
{/ linker to use dlopen() interface to dynamically load LinkTimeOptimizer. }
{/ extern "C" helps, because dlopen() interface uses name to find the symbol. }

function llvm_create_optimizer:llvm_lto_t;cdecl;external libname name 'llvm_create_optimizer';
procedure llvm_destroy_optimizer(lto:llvm_lto_t);cdecl;external libname name 'llvm_destroy_optimizer';
function llvm_read_object_file(lto:llvm_lto_t; input_filename:pchar):llvm_lto_status_t;cdecl;external libname name 'llvm_read_object_file';
function llvm_optimize_modules(lto:llvm_lto_t; output_filename:pchar):llvm_lto_status_t;cdecl;external libname name 'llvm_optimize_modules';
{ lto.h  }

const
   LTO_API_VERSION = 3;   
{ log2 of alignment  }
type

   lto_symbol_attributes = (LTO_SYMBOL_ALIGNMENT_MASK := $0000001F,LTO_SYMBOL_PERMISSIONS_MASK := $000000E0,
     LTO_SYMBOL_PERMISSIONS_CODE := $000000A0,LTO_SYMBOL_PERMISSIONS_DATA := $000000C0,
     LTO_SYMBOL_PERMISSIONS_RODATA := $00000080,LTO_SYMBOL_DEFINITION_MASK := $00000700,
     LTO_SYMBOL_DEFINITION_REGULAR := $00000100,LTO_SYMBOL_DEFINITION_TENTATIVE := $00000200,
     LTO_SYMBOL_DEFINITION_WEAK := $00000300,LTO_SYMBOL_DEFINITION_UNDEFINED := $00000400,
     LTO_SYMBOL_DEFINITION_WEAKUNDEF := $00000500,
     LTO_SYMBOL_SCOPE_MASK := $00003800,LTO_SYMBOL_SCOPE_INTERNAL := $00000800,
     LTO_SYMBOL_SCOPE_HIDDEN := $00001000,LTO_SYMBOL_SCOPE_PROTECTED := $00002000,
     LTO_SYMBOL_SCOPE_DEFAULT := $00001800);

   lto_debug_model = (LTO_DEBUG_MODEL_NONE := 0,LTO_DEBUG_MODEL_DWARF := 1
     );

   lto_codegen_model = (LTO_CODEGEN_PIC_MODEL_STATIC := 0,LTO_CODEGEN_PIC_MODEL_DYNAMIC := 1,
     LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC := 2
     );
{* opaque reference to a loaded object module  }

   lto_module_t = LTOModule;
{* opaque reference to a code generator  }

   lto_code_gen_t = LTOCodeGenerator;
{*
 * Returns a printable string.
  }

function lto_get_version:pchar;cdecl;external libname name 'lto_get_version';
{*
 * Returns the last error string or NULL if last operation was sucessful.
  }
function lto_get_error_message:pchar;cdecl;external libname name 'lto_get_error_message';
{*
 * Checks if a file is a loadable object file.
  }
function lto_module_is_object_file(path:pchar):bool;cdecl;external libname name 'lto_module_is_object_file';
{*
 * Checks if a file is a loadable object compiled for requested target.
  }
function lto_module_is_object_file_for_target(path:pchar; target_triple_prefix:pchar):bool;cdecl;external libname name 'lto_module_is_object_file_for_target';
{*
 * Checks if a buffer is a loadable object file.
  }
function lto_module_is_object_file_in_memory(mem:pointer; length:size_t):bool;cdecl;external libname name 'lto_module_is_object_file_in_memory';
{*
 * Checks if a buffer is a loadable object compiled for requested target.
  }
function lto_module_is_object_file_in_memory_for_target(mem:pointer; length:size_t; target_triple_prefix:pchar):bool;cdecl;external libname name 'lto_module_is_object_file_in_memory_for_target';
{*
 * Loads an object file from disk.
 * Returns NULL on error (check lto_get_error_message() for details).
  }
function lto_module_create(path:pchar):lto_module_t;cdecl;external libname name 'lto_module_create';
{*
 * Loads an object file from memory.
 * Returns NULL on error (check lto_get_error_message() for details).
  }
function lto_module_create_from_memory(mem:pointer; length:size_t):lto_module_t;cdecl;external libname name 'lto_module_create_from_memory';
{*
 * Frees all memory internally allocated by the module.
 * Upon return the lto_module_t is no longer valid.
  }
procedure lto_module_dispose(module:lto_module_t);cdecl;external libname name 'lto_module_dispose';
{*
 * Returns triple string which the object module was compiled under.
  }
function lto_module_get_target_triple(module:lto_module_t):pchar;cdecl;external libname name 'lto_module_get_target_triple';
{*
 * Returns the number of symbols in the object module.
  }
function lto_module_get_num_symbols(module:lto_module_t):dword;cdecl;external libname name 'lto_module_get_num_symbols';
{*
 * Returns the name of the ith symbol in the object module.
  }
function lto_module_get_symbol_name(module:lto_module_t; index:dword):pchar;cdecl;external libname name 'lto_module_get_symbol_name';
{*
 * Returns the attributes of the ith symbol in the object module.
  }
function lto_module_get_symbol_attribute(module:lto_module_t; index:dword):lto_symbol_attributes;cdecl;external libname name 'lto_module_get_symbol_attribute';
{*
 * Instantiates a code generator.
 * Returns NULL on error (check lto_get_error_message() for details).
  }
function lto_codegen_create:lto_code_gen_t;cdecl;external libname name 'lto_codegen_create';
{*
 * Frees all code generator and all memory it internally allocated.
 * Upon return the lto_code_gen_t is no longer valid.
  }
procedure lto_codegen_dispose(para1:lto_code_gen_t);cdecl;external libname name 'lto_codegen_dispose';
{*
 * Add an object module to the set of modules for which code will be generated.
 * Returns true on error (check lto_get_error_message() for details).
  }
function lto_codegen_add_module(cg:lto_code_gen_t; module:lto_module_t):bool;cdecl;external libname name 'lto_codegen_add_module';
{*
 * Sets if debug info should be generated.
 * Returns true on error (check lto_get_error_message() for details).
  }
function lto_codegen_set_debug_model(cg:lto_code_gen_t; para2:lto_debug_model):bool;cdecl;external libname name 'lto_codegen_set_debug_model';
{*
 * Sets which PIC code model to generated.
 * Returns true on error (check lto_get_error_message() for details).
  }
function lto_codegen_set_pic_model(cg:lto_code_gen_t; 
                                   para2: lto_codegen_model): bool;
cdecl;external libname name 'lto_codegen_set_pic_model';
{*
 * Sets the location of the "gcc" to run. If not set, libLTO will search for
 * "gcc" on the path.
  }
procedure lto_codegen_set_gcc_path(cg:lto_code_gen_t; path:pchar);
cdecl;external libname name 'lto_codegen_set_gcc_path';
{*
 * Sets the location of the assembler tool to run. If not set, libLTO
 * will use gcc to invoke the assembler.
  }
procedure lto_codegen_set_assembler_path(cg:lto_code_gen_t; path:pchar);
cdecl;external libname name 'lto_codegen_set_assembler_path';
{*
 * Adds to a list of all global symbols that must exist in the final
 * generated code.  If a function is not listed, it might be
 * inlined into every usage and optimized away.
  }
procedure lto_codegen_add_must_preserve_symbol(cg:lto_code_gen_t; symbol:pchar);
cdecl;external libname name 'lto_codegen_add_must_preserve_symbol';
{*
 * Writes a new object file at the specified path that contains the
 * merged contents of all modules added so far.
 * Returns true on error (check lto_get_error_message() for details).
  }
function lto_codegen_write_merged_modules(cg:lto_code_gen_t; path:pchar):bool;
cdecl;external libname name 'lto_codegen_write_merged_modules';
{*
 * Generates code for all added modules into one native object file.
 * On sucess returns a pointer to a generated mach-o/ELF buffer and
 * length set to the buffer size.  The buffer is owned by the 
 * lto_code_gen_t and will be freed when lto_codegen_dispose()
 * is called, or lto_codegen_compile() is called again.
 * On failure, returns NULL (check lto_get_error_message() for details).
  }
function lto_codegen_compile(cg:lto_code_gen_t; var length: int): pointer;
cdecl; external libname name 'lto_codegen_compile';
{*
 * Sets options to help debug codegen bugs.
  }
procedure lto_codegen_debug_options(cg: lto_code_gen_t; para2: Pchar);
cdecl;external libname name 'lto_codegen_debug_options';

implementation

end.
