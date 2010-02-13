/* Core.h */
/* Opaque types. */

/**
 * The top-level container for all LLVM global data.  See the LLVMContext class.
 */
typedef struct LLVMOpaqueContext *LLVMContextRef;

/**
 * The top-level container for all other LLVM Intermediate Representation (IR)
 * objects. See the llvm::Module class.
 */
typedef struct LLVMOpaqueModule *LLVMModuleRef;

/**
 * Each value in the LLVM IR has a type, an LLVMTypeRef. See the llvm::Type
 * class.
 */
typedef struct LLVMOpaqueType *LLVMTypeRef;

/**
 * When building recursive types using LLVMRefineType, LLVMTypeRef values may
 * become invalid; use LLVMTypeHandleRef to resolve this problem. See the
 * llvm::AbstractTypeHolder class.
 */
typedef struct LLVMOpaqueTypeHandle *LLVMTypeHandleRef;

typedef struct LLVMOpaqueValue *LLVMValueRef;
typedef struct LLVMOpaqueBasicBlock *LLVMBasicBlockRef;
typedef struct LLVMOpaqueBuilder *LLVMBuilderRef;

/* Used to provide a module to JIT or interpreter.
 * See the llvm::ModuleProvider class.
 */
typedef struct LLVMOpaqueModuleProvider *LLVMModuleProviderRef;

/* Used to provide a module to JIT or interpreter.
 * See the llvm::MemoryBuffer class.
 */
typedef struct LLVMOpaqueMemoryBuffer *LLVMMemoryBufferRef;

/** See the llvm::PassManagerBase class. */
typedef struct LLVMOpaquePassManager *LLVMPassManagerRef;

/**
 * Used to iterate through the uses of a Value, allowing access to all Values
 * that use this Value.  See the llvm::Use and llvm::value_use_iterator classes.
 */
typedef struct LLVMOpaqueUseIterator *LLVMUseIteratorRef;

typedef enum {
    LLVMZExtAttribute       = 1<<0,
    LLVMSExtAttribute       = 1<<1,
    LLVMNoReturnAttribute   = 1<<2,
    LLVMInRegAttribute      = 1<<3,
    LLVMStructRetAttribute  = 1<<4,
    LLVMNoUnwindAttribute   = 1<<5,
    LLVMNoAliasAttribute    = 1<<6,
    LLVMByValAttribute      = 1<<7,
    LLVMNestAttribute       = 1<<8,
    LLVMReadNoneAttribute   = 1<<9,
    LLVMReadOnlyAttribute   = 1<<10,
    LLVMNoInlineAttribute   = 1<<11,
    LLVMAlwaysInlineAttribute    = 1<<12,
    LLVMOptimizeForSizeAttribute = 1<<13,
    LLVMStackProtectAttribute    = 1<<14,
    LLVMStackProtectReqAttribute = 1<<15,
    LLVMNoCaptureAttribute  = 1<<21,
    LLVMNoRedZoneAttribute  = 1<<22,
    LLVMNoImplicitFloatAttribute = 1<<23,
    LLVMNakedAttribute      = 1<<24,
    LLVMInlineHintAttribute = 1<<25
} LLVMAttribute;

typedef enum {
  LLVMRet            = 1,
  LLVMBr             = 2,
  LLVMSwitch         = 3,
  LLVMInvoke         = 4,
  LLVMUnwind         = 5,
  LLVMUnreachable    = 6,
  LLVMAdd            = 7,
  LLVMFAdd           = 8,
  LLVMSub            = 9,
  LLVMFSub           = 10,
  LLVMMul            = 11,
  LLVMFMul           = 12,
  LLVMUDiv           = 13,
  LLVMSDiv           = 14,
  LLVMFDiv           = 15,
  LLVMURem           = 16,
  LLVMSRem           = 17,
  LLVMFRem           = 18,
  LLVMShl            = 19,
  LLVMLShr           = 20,
  LLVMAShr           = 21,
  LLVMAnd            = 22,
  LLVMOr             = 23,
  LLVMXor            = 24,
  LLVMMalloc         = 25,
  LLVMFree           = 26,
  LLVMAlloca         = 27,
  LLVMLoad           = 28,
  LLVMStore          = 29,
  LLVMGetElementPtr  = 30,
  LLVMTrunk          = 31,
  LLVMZExt           = 32,
  LLVMSExt           = 33,
  LLVMFPToUI         = 34,
  LLVMFPToSI         = 35,
  LLVMUIToFP         = 36,
  LLVMSIToFP         = 37,
  LLVMFPTrunc        = 38,
  LLVMFPExt          = 39,
  LLVMPtrToInt       = 40,
  LLVMIntToPtr       = 41,
  LLVMBitCast        = 42,
  LLVMICmp           = 43,
  LLVMFCmp           = 44,
  LLVMPHI            = 45,
  LLVMCall           = 46,
  LLVMSelect         = 47,
  LLVMVAArg          = 50,
  LLVMExtractElement = 51,
  LLVMInsertElement  = 52,
  LLVMShuffleVector  = 53,
  LLVMExtractValue   = 54,
  LLVMInsertValue    = 55
} LLVMOpcode;

typedef enum {
  LLVMVoidTypeKind,        /**< type with no size */
  LLVMFloatTypeKind,       /**< 32 bit floating point type */
  LLVMDoubleTypeKind,      /**< 64 bit floating point type */
  LLVMX86_FP80TypeKind,    /**< 80 bit floating point type (X87) */
  LLVMFP128TypeKind,       /**< 128 bit floating point type (112-bit mantissa)*/
  LLVMPPC_FP128TypeKind,   /**< 128 bit floating point type (two 64-bits) */
  LLVMLabelTypeKind,       /**< Labels */
  LLVMIntegerTypeKind,     /**< Arbitrary bit width integers */
  LLVMFunctionTypeKind,    /**< Functions */
  LLVMStructTypeKind,      /**< Structures */
  LLVMArrayTypeKind,       /**< Arrays */
  LLVMPointerTypeKind,     /**< Pointers */
  LLVMOpaqueTypeKind,      /**< Opaque: type with unknown structure */
  LLVMVectorTypeKind,      /**< SIMD 'packed' format, or other vector type */
  LLVMMetadataTypeKind     /**< Metadata */
} LLVMTypeKind;

typedef enum {
  LLVMExternalLinkage,    /**< Externally visible function */
  LLVMAvailableExternallyLinkage,
  LLVMLinkOnceAnyLinkage, /**< Keep one copy of function when linking (inline)*/
  LLVMLinkOnceODRLinkage, /**< Same, but only replaced by something
                            equivalent. */
  LLVMWeakAnyLinkage,     /**< Keep one copy of function when linking (weak) */
  LLVMWeakODRLinkage,     /**< Same, but only replaced by something
                            equivalent. */
  LLVMAppendingLinkage,   /**< Special purpose, only applies to global arrays */
  LLVMInternalLinkage,    /**< Rename collisions when linking (static
                               functions) */
  LLVMPrivateLinkage,     /**< Like Internal, but omit from symbol table */
  LLVMDLLImportLinkage,   /**< Function to be imported from DLL */
  LLVMDLLExportLinkage,   /**< Function to be accessible from DLL */
  LLVMExternalWeakLinkage,/**< ExternalWeak linkage description */
  LLVMGhostLinkage,       /**< Stand-in functions for streaming fns from
                               bitcode */
  LLVMCommonLinkage,      /**< Tentative definitions */
  LLVMLinkerPrivateLinkage /**< Like Private, but linker removes. */
} LLVMLinkage;

typedef enum {
  LLVMDefaultVisibility,  /**< The GV is visible */
  LLVMHiddenVisibility,   /**< The GV is hidden */
  LLVMProtectedVisibility /**< The GV is protected */
} LLVMVisibility;

typedef enum {
  LLVMCCallConv           = 0,
  LLVMFastCallConv        = 8,
  LLVMColdCallConv        = 9,
  LLVMX86StdcallCallConv  = 64,
  LLVMX86FastcallCallConv = 65
} LLVMCallConv;

typedef enum {
  LLVMIntEQ = 32, /**< equal */
  LLVMIntNE,      /**< not equal */
  LLVMIntUGT,     /**< unsigned greater than */
  LLVMIntUGE,     /**< unsigned greater or equal */
  LLVMIntULT,     /**< unsigned less than */
  LLVMIntULE,     /**< unsigned less or equal */
  LLVMIntSGT,     /**< signed greater than */
  LLVMIntSGE,     /**< signed greater or equal */
  LLVMIntSLT,     /**< signed less than */
  LLVMIntSLE      /**< signed less or equal */
} LLVMIntPredicate;

typedef enum {
  LLVMRealPredicateFalse, /**< Always false (always folded) */
  LLVMRealOEQ,            /**< True if ordered and equal */
  LLVMRealOGT,            /**< True if ordered and greater than */
  LLVMRealOGE,            /**< True if ordered and greater than or equal */
  LLVMRealOLT,            /**< True if ordered and less than */
  LLVMRealOLE,            /**< True if ordered and less than or equal */
  LLVMRealONE,            /**< True if ordered and operands are unequal */
  LLVMRealORD,            /**< True if ordered (no nans) */
  LLVMRealUNO,            /**< True if unordered: isnan(X) | isnan(Y) */
  LLVMRealUEQ,            /**< True if unordered or equal */
  LLVMRealUGT,            /**< True if unordered or greater than */
  LLVMRealUGE,            /**< True if unordered, greater than, or equal */
  LLVMRealULT,            /**< True if unordered or less than */
  LLVMRealULE,            /**< True if unordered, less than, or equal */
  LLVMRealUNE,            /**< True if unordered or not equal */
  LLVMRealPredicateTrue   /**< Always true (always folded) */
} LLVMRealPredicate;


/*===-- Error handling ----------------------------------------------------===*/

void LLVMDisposeMessage(char *Message);


/*===-- Modules -----------------------------------------------------------===*/

/* Create and destroy contexts. */
LLVMContextRef LLVMContextCreate(void);
LLVMContextRef LLVMGetGlobalContext(void);
void LLVMContextDispose(LLVMContextRef C);

/* Create and destroy modules. */ 
/** See llvm::Module::Module. */
LLVMModuleRef LLVMModuleCreateWithName(const char *ModuleID);
LLVMModuleRef LLVMModuleCreateWithNameInContext(const char *ModuleID,
                                                LLVMContextRef C);

/** See llvm::Module::~Module. */
void LLVMDisposeModule(LLVMModuleRef M);

/** Data layout. See Module::getDataLayout. */
const char *LLVMGetDataLayout(LLVMModuleRef M);
void LLVMSetDataLayout(LLVMModuleRef M, const char *Triple);

/** Target triple. See Module::getTargetTriple. */
const char *LLVMGetTarget(LLVMModuleRef M);
void LLVMSetTarget(LLVMModuleRef M, const char *Triple);

/** See Module::addTypeName. */
int LLVMAddTypeName(LLVMModuleRef M, const char *Name, LLVMTypeRef Ty);
void LLVMDeleteTypeName(LLVMModuleRef M, const char *Name);
LLVMTypeRef LLVMGetTypeByName(LLVMModuleRef M, const char *Name);

/** See Module::dump. */
void LLVMDumpModule(LLVMModuleRef M);


/*===-- Types -------------------------------------------------------------===*/

/* LLVM types conform to the following hierarchy:
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
 */

/** See llvm::LLVMTypeKind::getTypeID. */
LLVMTypeKind LLVMGetTypeKind(LLVMTypeRef Ty);

/** See llvm::LLVMType::getContext. */
LLVMContextRef LLVMGetTypeContext(LLVMTypeRef Ty);

/* Operations on integer types */
LLVMTypeRef LLVMInt1TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt8TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt16TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt32TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMInt64TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMIntTypeInContext(LLVMContextRef C, unsigned NumBits);

LLVMTypeRef LLVMInt1Type(void);
LLVMTypeRef LLVMInt8Type(void);
LLVMTypeRef LLVMInt16Type(void);
LLVMTypeRef LLVMInt32Type(void);
LLVMTypeRef LLVMInt64Type(void);
LLVMTypeRef LLVMIntType(unsigned NumBits);
unsigned LLVMGetIntTypeWidth(LLVMTypeRef IntegerTy);

/* Operations on real types */
LLVMTypeRef LLVMFloatTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMDoubleTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMX86FP80TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMFP128TypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMPPCFP128TypeInContext(LLVMContextRef C);

LLVMTypeRef LLVMFloatType(void);
LLVMTypeRef LLVMDoubleType(void);
LLVMTypeRef LLVMX86FP80Type(void);
LLVMTypeRef LLVMFP128Type(void);
LLVMTypeRef LLVMPPCFP128Type(void);

/* Operations on function types */
LLVMTypeRef LLVMFunctionType(LLVMTypeRef ReturnType,
                             LLVMTypeRef *ParamTypes, unsigned ParamCount,
                             int IsVarArg);
int LLVMIsFunctionVarArg(LLVMTypeRef FunctionTy);
LLVMTypeRef LLVMGetReturnType(LLVMTypeRef FunctionTy);
unsigned LLVMCountParamTypes(LLVMTypeRef FunctionTy);
void LLVMGetParamTypes(LLVMTypeRef FunctionTy, LLVMTypeRef *Dest);

/* Operations on struct types */
LLVMTypeRef LLVMStructTypeInContext(LLVMContextRef C, LLVMTypeRef *ElementTypes,
                                    unsigned ElementCount, int Packed);
LLVMTypeRef LLVMStructType(LLVMTypeRef *ElementTypes, unsigned ElementCount,
                           int Packed);
unsigned LLVMCountStructElementTypes(LLVMTypeRef StructTy);
void LLVMGetStructElementTypes(LLVMTypeRef StructTy, LLVMTypeRef *Dest);
int LLVMIsPackedStruct(LLVMTypeRef StructTy);

/* Operations on array, pointer, and vector types (sequence types) */
LLVMTypeRef LLVMArrayType(LLVMTypeRef ElementType, unsigned ElementCount);
LLVMTypeRef LLVMPointerType(LLVMTypeRef ElementType, unsigned AddressSpace);
LLVMTypeRef LLVMVectorType(LLVMTypeRef ElementType, unsigned ElementCount);

LLVMTypeRef LLVMGetElementType(LLVMTypeRef Ty);
unsigned LLVMGetArrayLength(LLVMTypeRef ArrayTy);
unsigned LLVMGetPointerAddressSpace(LLVMTypeRef PointerTy);
unsigned LLVMGetVectorSize(LLVMTypeRef VectorTy);

/* Operations on other types */
LLVMTypeRef LLVMVoidTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMLabelTypeInContext(LLVMContextRef C);
LLVMTypeRef LLVMOpaqueTypeInContext(LLVMContextRef C);

LLVMTypeRef LLVMVoidType(void);
LLVMTypeRef LLVMLabelType(void);
LLVMTypeRef LLVMOpaqueType(void);

/* Operations on type handles */
LLVMTypeHandleRef LLVMCreateTypeHandle(LLVMTypeRef PotentiallyAbstractTy);
void LLVMRefineType(LLVMTypeRef AbstractTy, LLVMTypeRef ConcreteTy);
LLVMTypeRef LLVMResolveTypeHandle(LLVMTypeHandleRef TypeHandle);
void LLVMDisposeTypeHandle(LLVMTypeHandleRef TypeHandle);



/* Operations on all values */
LLVMTypeRef LLVMTypeOf(LLVMValueRef Val);
const char *LLVMGetValueName(LLVMValueRef Val);
void LLVMSetValueName(LLVMValueRef Val, const char *Name);
void LLVMDumpValue(LLVMValueRef Val);
void LLVMReplaceAllUsesWith(LLVMValueRef OldVal, LLVMValueRef NewVal);

/* Conversion functions. Return the input value if it is an instance of the
   specified class, otherwise NULL. See llvm::dyn_cast_or_null<>. */
LLVMValueRef LLVMIsAArgument(LLVMValueRef Val);
LLVMValueRef LLVMIsABasicBlock(LLVMValueRef Val);
LLVMValueRef LLVMIsAInlineAsm(LLVMValueRef Val);
LLVMValueRef LLVMIsAUser(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstant(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantAggregateZero(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantArray(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantExpr(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantFP(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantInt(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantPointerNull(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantStruct(LLVMValueRef Val);
LLVMValueRef LLVMIsAConstantVector(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalValue(LLVMValueRef Val);
LLVMValueRef LLVMIsAFunction(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalAlias(LLVMValueRef Val);
LLVMValueRef LLVMIsAGlobalVariable(LLVMValueRef Val);
LLVMValueRef LLVMIsAUndefValue(LLVMValueRef Val);
LLVMValueRef LLVMIsAInstruction(LLVMValueRef Val);
LLVMValueRef LLVMIsABinaryOperator(LLVMValueRef Val);
LLVMValueRef LLVMIsACallInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAIntrinsicInst(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgInfoIntrinsic(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgDeclareInst(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgFuncStartInst(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgRegionEndInst(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgRegionStartInst(LLVMValueRef Val);
LLVMValueRef LLVMIsADbgStopPointInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAEHSelectorInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemIntrinsic(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemCpyInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemMoveInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAMemSetInst(LLVMValueRef Val);
LLVMValueRef LLVMIsACmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFCmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAICmpInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractElementInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAGetElementPtrInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertElementInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInsertValueInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAPHINode(LLVMValueRef Val);
LLVMValueRef LLVMIsASelectInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAShuffleVectorInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAStoreInst(LLVMValueRef Val);
LLVMValueRef LLVMIsATerminatorInst(LLVMValueRef Val);
LLVMValueRef LLVMIsABranchInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAInvokeInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAReturnInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASwitchInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUnreachableInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUnwindInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUnaryInstruction(LLVMValueRef Val);
LLVMValueRef LLVMIsAAllocationInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAAllocaInst(LLVMValueRef Val);
LLVMValueRef LLVMIsACastInst(LLVMValueRef Val);
LLVMValueRef LLVMIsABitCastInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPExtInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToSIInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPToUIInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFPTruncInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAIntToPtrInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAPtrToIntInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASExtInst(LLVMValueRef Val);
LLVMValueRef LLVMIsASIToFPInst(LLVMValueRef Val);
LLVMValueRef LLVMIsATruncInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAUIToFPInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAZExtInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAExtractValueInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAFreeInst(LLVMValueRef Val);
LLVMValueRef LLVMIsALoadInst(LLVMValueRef Val);
LLVMValueRef LLVMIsAVAArgInst(LLVMValueRef Val);


/* Operations on Uses */
LLVMUseIteratorRef LLVMGetFirstUse(LLVMValueRef Val);
LLVMUseIteratorRef LLVMGetNextUse(LLVMUseIteratorRef U);
LLVMValueRef LLVMGetUser(LLVMUseIteratorRef U);
LLVMValueRef LLVMGetUsedValue(LLVMUseIteratorRef U);

/* Operations on Users */
LLVMValueRef LLVMGetOperand(LLVMValueRef Val, unsigned Index);

/* Operations on constants of any type */
LLVMValueRef LLVMConstNull(LLVMTypeRef Ty); /* all zeroes */
LLVMValueRef LLVMConstAllOnes(LLVMTypeRef Ty); /* only for int/vector */
LLVMValueRef LLVMGetUndef(LLVMTypeRef Ty);
int LLVMIsConstant(LLVMValueRef Val);
int LLVMIsNull(LLVMValueRef Val);
int LLVMIsUndef(LLVMValueRef Val);
LLVMValueRef LLVMConstPointerNull(LLVMTypeRef Ty);

/* Operations on scalar constants */
LLVMValueRef LLVMConstInt(LLVMTypeRef IntTy, unsigned long long N,
                          int SignExtend);
LLVMValueRef LLVMConstIntOfString(LLVMTypeRef IntTy, const char *Text,
                                  uint8_t Radix);
LLVMValueRef LLVMConstIntOfStringAndSize(LLVMTypeRef IntTy, const char *Text,
                                         unsigned SLen, uint8_t Radix);
LLVMValueRef LLVMConstReal(LLVMTypeRef RealTy, double N);
LLVMValueRef LLVMConstRealOfString(LLVMTypeRef RealTy, const char *Text);
LLVMValueRef LLVMConstRealOfStringAndSize(LLVMTypeRef RealTy, const char *Text,
                                          unsigned SLen);
unsigned long long LLVMConstIntGetZExtValue(LLVMValueRef ConstantVal);
long long LLVMConstIntGetSExtValue(LLVMValueRef ConstantVal);


/* Operations on composite constants */
LLVMValueRef LLVMConstStringInContext(LLVMContextRef C, const char *Str,
                                      unsigned Length, int DontNullTerminate);
LLVMValueRef LLVMConstStructInContext(LLVMContextRef C, 
                                      LLVMValueRef *ConstantVals,
                                      unsigned Count, int Packed);

LLVMValueRef LLVMConstString(const char *Str, unsigned Length,
                             int DontNullTerminate);
LLVMValueRef LLVMConstArray(LLVMTypeRef ElementTy,
                            LLVMValueRef *ConstantVals, unsigned Length);
LLVMValueRef LLVMConstStruct(LLVMValueRef *ConstantVals, unsigned Count,
                             int Packed);
LLVMValueRef LLVMConstVector(LLVMValueRef *ScalarConstantVals, unsigned Size);

/* Constant expressions */
LLVMOpcode LLVMGetConstOpcode(LLVMValueRef ConstantVal);
LLVMValueRef LLVMAlignOf(LLVMTypeRef Ty);
LLVMValueRef LLVMSizeOf(LLVMTypeRef Ty);
LLVMValueRef LLVMConstNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstFNeg(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstNot(LLVMValueRef ConstantVal);
LLVMValueRef LLVMConstAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstNSWAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFAdd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFSub(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFMul(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstUDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstExactSDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFDiv(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstURem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstSRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFRem(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAnd(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstOr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstXor(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstICmp(LLVMIntPredicate Predicate,
                           LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstFCmp(LLVMRealPredicate Predicate,
                           LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstShl(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstLShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstAShr(LLVMValueRef LHSConstant, LLVMValueRef RHSConstant);
LLVMValueRef LLVMConstGEP(LLVMValueRef ConstantVal,
                          LLVMValueRef *ConstantIndices, unsigned NumIndices);
LLVMValueRef LLVMConstInBoundsGEP(LLVMValueRef ConstantVal,
                                  LLVMValueRef *ConstantIndices,
                                  unsigned NumIndices);
LLVMValueRef LLVMConstTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstZExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPTrunc(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPExt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstUIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSIToFP(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToUI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstFPToSI(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstPtrToInt(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntToPtr(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstBitCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstZExtOrBitCast(LLVMValueRef ConstantVal,
                                    LLVMTypeRef ToType);
LLVMValueRef LLVMConstSExtOrBitCast(LLVMValueRef ConstantVal,
                                    LLVMTypeRef ToType);
LLVMValueRef LLVMConstTruncOrBitCast(LLVMValueRef ConstantVal,
                                     LLVMTypeRef ToType);
LLVMValueRef LLVMConstPointerCast(LLVMValueRef ConstantVal,
                                  LLVMTypeRef ToType);
LLVMValueRef LLVMConstIntCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType,
                              unsigned isSigned);
LLVMValueRef LLVMConstFPCast(LLVMValueRef ConstantVal, LLVMTypeRef ToType);
LLVMValueRef LLVMConstSelect(LLVMValueRef ConstantCondition,
                             LLVMValueRef ConstantIfTrue,
                             LLVMValueRef ConstantIfFalse);
LLVMValueRef LLVMConstExtractElement(LLVMValueRef VectorConstant,
                                     LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstInsertElement(LLVMValueRef VectorConstant,
                                    LLVMValueRef ElementValueConstant,
                                    LLVMValueRef IndexConstant);
LLVMValueRef LLVMConstShuffleVector(LLVMValueRef VectorAConstant,
                                    LLVMValueRef VectorBConstant,
                                    LLVMValueRef MaskConstant);
LLVMValueRef LLVMConstExtractValue(LLVMValueRef AggConstant, unsigned *IdxList,
                                   unsigned NumIdx);
LLVMValueRef LLVMConstInsertValue(LLVMValueRef AggConstant,
                                  LLVMValueRef ElementValueConstant,
                                  unsigned *IdxList, unsigned NumIdx);
LLVMValueRef LLVMConstInlineAsm(LLVMTypeRef Ty, 
                                const char *AsmString, const char *Constraints,
                                int HasSideEffects);

/* Operations on global variables, functions, and aliases (globals) */
LLVMModuleRef LLVMGetGlobalParent(LLVMValueRef Global);
int LLVMIsDeclaration(LLVMValueRef Global);
LLVMLinkage LLVMGetLinkage(LLVMValueRef Global);
void LLVMSetLinkage(LLVMValueRef Global, LLVMLinkage Linkage);
const char *LLVMGetSection(LLVMValueRef Global);
void LLVMSetSection(LLVMValueRef Global, const char *Section);
LLVMVisibility LLVMGetVisibility(LLVMValueRef Global);
void LLVMSetVisibility(LLVMValueRef Global, LLVMVisibility Viz);
unsigned LLVMGetAlignment(LLVMValueRef Global);
void LLVMSetAlignment(LLVMValueRef Global, unsigned Bytes);

/* Operations on global variables */
LLVMValueRef LLVMAddGlobal(LLVMModuleRef M, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMGetNamedGlobal(LLVMModuleRef M, const char *Name);
LLVMValueRef LLVMGetFirstGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetLastGlobal(LLVMModuleRef M);
LLVMValueRef LLVMGetNextGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetPreviousGlobal(LLVMValueRef GlobalVar);
void LLVMDeleteGlobal(LLVMValueRef GlobalVar);
LLVMValueRef LLVMGetInitializer(LLVMValueRef GlobalVar);
void LLVMSetInitializer(LLVMValueRef GlobalVar, LLVMValueRef ConstantVal);
int LLVMIsThreadLocal(LLVMValueRef GlobalVar);
void LLVMSetThreadLocal(LLVMValueRef GlobalVar, int IsThreadLocal);
int LLVMIsGlobalConstant(LLVMValueRef GlobalVar);
void LLVMSetGlobalConstant(LLVMValueRef GlobalVar, int IsConstant);

/* Operations on aliases */
LLVMValueRef LLVMAddAlias(LLVMModuleRef M, LLVMTypeRef Ty, LLVMValueRef Aliasee,
                          const char *Name);

/* Operations on functions */
LLVMValueRef LLVMAddFunction(LLVMModuleRef M, const char *Name,
                             LLVMTypeRef FunctionTy);
LLVMValueRef LLVMGetNamedFunction(LLVMModuleRef M, const char *Name);
LLVMValueRef LLVMGetFirstFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetLastFunction(LLVMModuleRef M);
LLVMValueRef LLVMGetNextFunction(LLVMValueRef Fn);
LLVMValueRef LLVMGetPreviousFunction(LLVMValueRef Fn);
void LLVMDeleteFunction(LLVMValueRef Fn);
unsigned LLVMGetIntrinsicID(LLVMValueRef Fn);
unsigned LLVMGetFunctionCallConv(LLVMValueRef Fn);
void LLVMSetFunctionCallConv(LLVMValueRef Fn, unsigned CC);
const char *LLVMGetGC(LLVMValueRef Fn);
void LLVMSetGC(LLVMValueRef Fn, const char *Name);
void LLVMAddFunctionAttr(LLVMValueRef Fn, LLVMAttribute PA);
LLVMAttribute LLVMGetFunctionAttr(LLVMValueRef Fn);
void LLVMRemoveFunctionAttr(LLVMValueRef Fn, LLVMAttribute PA);

/* Operations on parameters */
unsigned LLVMCountParams(LLVMValueRef Fn);
void LLVMGetParams(LLVMValueRef Fn, LLVMValueRef *Params);
LLVMValueRef LLVMGetParam(LLVMValueRef Fn, unsigned Index);
LLVMValueRef LLVMGetParamParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetFirstParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetLastParam(LLVMValueRef Fn);
LLVMValueRef LLVMGetNextParam(LLVMValueRef Arg);
LLVMValueRef LLVMGetPreviousParam(LLVMValueRef Arg);
void LLVMAddAttribute(LLVMValueRef Arg, LLVMAttribute PA);
void LLVMRemoveAttribute(LLVMValueRef Arg, LLVMAttribute PA);
LLVMAttribute LLVMGetAttribute(LLVMValueRef Arg);
void LLVMSetParamAlignment(LLVMValueRef Arg, unsigned align);

/* Operations on basic blocks */
LLVMValueRef LLVMBasicBlockAsValue(LLVMBasicBlockRef BB);
int LLVMValueIsBasicBlock(LLVMValueRef Val);
LLVMBasicBlockRef LLVMValueAsBasicBlock(LLVMValueRef Val);
LLVMValueRef LLVMGetBasicBlockParent(LLVMBasicBlockRef BB);
unsigned LLVMCountBasicBlocks(LLVMValueRef Fn);
void LLVMGetBasicBlocks(LLVMValueRef Fn, LLVMBasicBlockRef *BasicBlocks);
LLVMBasicBlockRef LLVMGetFirstBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetLastBasicBlock(LLVMValueRef Fn);
LLVMBasicBlockRef LLVMGetNextBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetPreviousBasicBlock(LLVMBasicBlockRef BB);
LLVMBasicBlockRef LLVMGetEntryBasicBlock(LLVMValueRef Fn);

LLVMBasicBlockRef LLVMAppendBasicBlockInContext(LLVMContextRef C,
                                                LLVMValueRef Fn,
                                                const char *Name);
LLVMBasicBlockRef LLVMInsertBasicBlockInContext(LLVMContextRef C,
                                                LLVMBasicBlockRef BB,
                                                const char *Name);

LLVMBasicBlockRef LLVMAppendBasicBlock(LLVMValueRef Fn, const char *Name);
LLVMBasicBlockRef LLVMInsertBasicBlock(LLVMBasicBlockRef InsertBeforeBB,
                                       const char *Name);
void LLVMDeleteBasicBlock(LLVMBasicBlockRef BB);

/* Operations on instructions */
LLVMBasicBlockRef LLVMGetInstructionParent(LLVMValueRef Inst);
LLVMValueRef LLVMGetFirstInstruction(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetLastInstruction(LLVMBasicBlockRef BB);
LLVMValueRef LLVMGetNextInstruction(LLVMValueRef Inst);
LLVMValueRef LLVMGetPreviousInstruction(LLVMValueRef Inst);

/* Operations on call sites */
void LLVMSetInstructionCallConv(LLVMValueRef Instr, unsigned CC);
unsigned LLVMGetInstructionCallConv(LLVMValueRef Instr);
void LLVMAddInstrAttribute(LLVMValueRef Instr, unsigned index, LLVMAttribute);
void LLVMRemoveInstrAttribute(LLVMValueRef Instr, unsigned index, 
                              LLVMAttribute);
void LLVMSetInstrParamAlignment(LLVMValueRef Instr, unsigned index, 
                                unsigned align);

/* Operations on call instructions (only) */
int LLVMIsTailCall(LLVMValueRef CallInst);
void LLVMSetTailCall(LLVMValueRef CallInst, int IsTailCall);

/* Operations on phi nodes */
void LLVMAddIncoming(LLVMValueRef PhiNode, LLVMValueRef *IncomingValues,
                     LLVMBasicBlockRef *IncomingBlocks, unsigned Count);
unsigned LLVMCountIncoming(LLVMValueRef PhiNode);
LLVMValueRef LLVMGetIncomingValue(LLVMValueRef PhiNode, unsigned Index);
LLVMBasicBlockRef LLVMGetIncomingBlock(LLVMValueRef PhiNode, unsigned Index);

/*===-- Instruction builders ----------------------------------------------===*/

/* An instruction builder represents a point within a basic block, and is the
 * exclusive means of building instructions using the C interface.
 */

LLVMBuilderRef LLVMCreateBuilderInContext(LLVMContextRef C);
LLVMBuilderRef LLVMCreateBuilder(void);
void LLVMPositionBuilder(LLVMBuilderRef Builder, LLVMBasicBlockRef Block,
                         LLVMValueRef Instr);
void LLVMPositionBuilderBefore(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMPositionBuilderAtEnd(LLVMBuilderRef Builder, LLVMBasicBlockRef Block);
LLVMBasicBlockRef LLVMGetInsertBlock(LLVMBuilderRef Builder);
void LLVMClearInsertionPosition(LLVMBuilderRef Builder);
void LLVMInsertIntoBuilder(LLVMBuilderRef Builder, LLVMValueRef Instr);
void LLVMInsertIntoBuilderWithName(LLVMBuilderRef Builder, LLVMValueRef Instr,
                                   const char *Name);
void LLVMDisposeBuilder(LLVMBuilderRef Builder);

/* Terminators */
LLVMValueRef LLVMBuildRetVoid(LLVMBuilderRef);
LLVMValueRef LLVMBuildRet(LLVMBuilderRef, LLVMValueRef V);
LLVMValueRef LLVMBuildAggregateRet(LLVMBuilderRef, LLVMValueRef *RetVals,
                                   unsigned N);
LLVMValueRef LLVMBuildBr(LLVMBuilderRef, LLVMBasicBlockRef Dest);
LLVMValueRef LLVMBuildCondBr(LLVMBuilderRef, LLVMValueRef If,
                             LLVMBasicBlockRef Then, LLVMBasicBlockRef Else);
LLVMValueRef LLVMBuildSwitch(LLVMBuilderRef, LLVMValueRef V,
                             LLVMBasicBlockRef Else, unsigned NumCases);
LLVMValueRef LLVMBuildInvoke(LLVMBuilderRef, LLVMValueRef Fn,
                             LLVMValueRef *Args, unsigned NumArgs,
                             LLVMBasicBlockRef Then, LLVMBasicBlockRef Catch,
                             const char *Name);
LLVMValueRef LLVMBuildUnwind(LLVMBuilderRef);
LLVMValueRef LLVMBuildUnreachable(LLVMBuilderRef);

/* Add a case to the switch instruction */
void LLVMAddCase(LLVMValueRef Switch, LLVMValueRef OnVal,
                 LLVMBasicBlockRef Dest);

/* Arithmetic */
LLVMValueRef LLVMBuildAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildNSWAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                             const char *Name);
LLVMValueRef LLVMBuildFAdd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildFSub(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildFMul(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildUDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildExactSDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                                const char *Name);
LLVMValueRef LLVMBuildFDiv(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildURem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildSRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildFRem(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildShl(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildLShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildAShr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildAnd(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildOr(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildXor(LLVMBuilderRef, LLVMValueRef LHS, LLVMValueRef RHS,
                          const char *Name);
LLVMValueRef LLVMBuildNeg(LLVMBuilderRef, LLVMValueRef V, const char *Name);
LLVMValueRef LLVMBuildFNeg(LLVMBuilderRef, LLVMValueRef V, const char *Name);
LLVMValueRef LLVMBuildNot(LLVMBuilderRef, LLVMValueRef V, const char *Name);

/* Memory */
LLVMValueRef LLVMBuildMalloc(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildArrayMalloc(LLVMBuilderRef, LLVMTypeRef Ty,
                                  LLVMValueRef Val, const char *Name);
LLVMValueRef LLVMBuildAlloca(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildArrayAlloca(LLVMBuilderRef, LLVMTypeRef Ty,
                                  LLVMValueRef Val, const char *Name);
LLVMValueRef LLVMBuildFree(LLVMBuilderRef, LLVMValueRef PointerVal);
LLVMValueRef LLVMBuildLoad(LLVMBuilderRef, LLVMValueRef PointerVal,
                           const char *Name);
LLVMValueRef LLVMBuildStore(LLVMBuilderRef, LLVMValueRef Val, LLVMValueRef Ptr);
LLVMValueRef LLVMBuildGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                          LLVMValueRef *Indices, unsigned NumIndices,
                          const char *Name);
LLVMValueRef LLVMBuildInBoundsGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                                  LLVMValueRef *Indices, unsigned NumIndices,
                                  const char *Name);
LLVMValueRef LLVMBuildStructGEP(LLVMBuilderRef B, LLVMValueRef Pointer,
                                unsigned Idx, const char *Name);
LLVMValueRef LLVMBuildGlobalString(LLVMBuilderRef B, const char *Str,
                                   const char *Name);
LLVMValueRef LLVMBuildGlobalStringPtr(LLVMBuilderRef B, const char *Str,
                                      const char *Name);

/* Casts */
LLVMValueRef LLVMBuildTrunc(LLVMBuilderRef, LLVMValueRef Val,
                            LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildZExt(LLVMBuilderRef, LLVMValueRef Val,
                           LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSExt(LLVMBuilderRef, LLVMValueRef Val,
                           LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPToUI(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPToSI(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildUIToFP(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSIToFP(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPTrunc(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPExt(LLVMBuilderRef, LLVMValueRef Val,
                            LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildPtrToInt(LLVMBuilderRef, LLVMValueRef Val,
                               LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildIntToPtr(LLVMBuilderRef, LLVMValueRef Val,
                               LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildBitCast(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildZExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                    LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildSExtOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                    LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildTruncOrBitCast(LLVMBuilderRef, LLVMValueRef Val,
                                     LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildPointerCast(LLVMBuilderRef, LLVMValueRef Val,
                                  LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildIntCast(LLVMBuilderRef, LLVMValueRef Val,
                              LLVMTypeRef DestTy, const char *Name);
LLVMValueRef LLVMBuildFPCast(LLVMBuilderRef, LLVMValueRef Val,
                             LLVMTypeRef DestTy, const char *Name);

/* Comparisons */
LLVMValueRef LLVMBuildICmp(LLVMBuilderRef, LLVMIntPredicate Op,
                           LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);
LLVMValueRef LLVMBuildFCmp(LLVMBuilderRef, LLVMRealPredicate Op,
                           LLVMValueRef LHS, LLVMValueRef RHS,
                           const char *Name);

/* Miscellaneous instructions */
LLVMValueRef LLVMBuildPhi(LLVMBuilderRef, LLVMTypeRef Ty, const char *Name);
LLVMValueRef LLVMBuildCall(LLVMBuilderRef, LLVMValueRef Fn,
                           LLVMValueRef *Args, unsigned NumArgs,
                           const char *Name);
LLVMValueRef LLVMBuildSelect(LLVMBuilderRef, LLVMValueRef If,
                             LLVMValueRef Then, LLVMValueRef Else,
                             const char *Name);
LLVMValueRef LLVMBuildVAArg(LLVMBuilderRef, LLVMValueRef List, LLVMTypeRef Ty,
                            const char *Name);
LLVMValueRef LLVMBuildExtractElement(LLVMBuilderRef, LLVMValueRef VecVal,
                                     LLVMValueRef Index, const char *Name);
LLVMValueRef LLVMBuildInsertElement(LLVMBuilderRef, LLVMValueRef VecVal,
                                    LLVMValueRef EltVal, LLVMValueRef Index,
                                    const char *Name);
LLVMValueRef LLVMBuildShuffleVector(LLVMBuilderRef, LLVMValueRef V1,
                                    LLVMValueRef V2, LLVMValueRef Mask,
                                    const char *Name);
LLVMValueRef LLVMBuildExtractValue(LLVMBuilderRef, LLVMValueRef AggVal,
                                   unsigned Index, const char *Name);
LLVMValueRef LLVMBuildInsertValue(LLVMBuilderRef, LLVMValueRef AggVal,
                                  LLVMValueRef EltVal, unsigned Index,
                                  const char *Name);

LLVMValueRef LLVMBuildIsNull(LLVMBuilderRef, LLVMValueRef Val,
                             const char *Name);
LLVMValueRef LLVMBuildIsNotNull(LLVMBuilderRef, LLVMValueRef Val,
                                const char *Name);
LLVMValueRef LLVMBuildPtrDiff(LLVMBuilderRef, LLVMValueRef LHS,
                              LLVMValueRef RHS, const char *Name);


/*===-- Module providers --------------------------------------------------===*/

/* Encapsulates the module M in a module provider, taking ownership of the
 * module.
 * See the constructor llvm::ExistingModuleProvider::ExistingModuleProvider.
 */
LLVMModuleProviderRef
LLVMCreateModuleProviderForExistingModule(LLVMModuleRef M);

/* Destroys the module provider MP as well as the contained module.
 * See the destructor llvm::ModuleProvider::~ModuleProvider.
 */
void LLVMDisposeModuleProvider(LLVMModuleProviderRef MP);


/*===-- Memory buffers ----------------------------------------------------===*/

int LLVMCreateMemoryBufferWithContentsOfFile(const char *Path,
                                             LLVMMemoryBufferRef *OutMemBuf,
                                             char **OutMessage);
int LLVMCreateMemoryBufferWithSTDIN(LLVMMemoryBufferRef *OutMemBuf,
                                    char **OutMessage);
void LLVMDisposeMemoryBuffer(LLVMMemoryBufferRef MemBuf);


/*===-- Pass Managers -----------------------------------------------------===*/

/** Constructs a new whole-module pass pipeline. This type of pipeline is
    suitable for link-time optimization and whole-module transformations.
    See llvm::PassManager::PassManager. */
LLVMPassManagerRef LLVMCreatePassManager(void);

/** Constructs a new function-by-function pass pipeline over the module
    provider. It does not take ownership of the module provider. This type of
    pipeline is suitable for code generation and JIT compilation tasks.
    See llvm::FunctionPassManager::FunctionPassManager. */
LLVMPassManagerRef LLVMCreateFunctionPassManager(LLVMModuleProviderRef MP);

/** Initializes, executes on the provided module, and finalizes all of the
    passes scheduled in the pass manager. Returns 1 if any of the passes
    modified the module, 0 otherwise. See llvm::PassManager::run(Module&). */
int LLVMRunPassManager(LLVMPassManagerRef PM, LLVMModuleRef M);

/** Initializes all of the function passes scheduled in the function pass
    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
    See llvm::FunctionPassManager::doInitialization. */
int LLVMInitializeFunctionPassManager(LLVMPassManagerRef FPM);

/** Executes all of the function passes scheduled in the function pass manager
    on the provided function. Returns 1 if any of the passes modified the
    function, false otherwise.
    See llvm::FunctionPassManager::run(Function&). */
int LLVMRunFunctionPassManager(LLVMPassManagerRef FPM, LLVMValueRef F);

/** Finalizes all of the function passes scheduled in in the function pass
    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
    See llvm::FunctionPassManager::doFinalization. */
int LLVMFinalizeFunctionPassManager(LLVMPassManagerRef FPM);

/** Frees the memory of a pass pipeline. For function pipelines, does not free
    the module provider.
    See llvm::PassManagerBase::~PassManagerBase. */
void LLVMDisposePassManager(LLVMPassManagerRef PM);



/* Analysis.h */

typedef enum {
  LLVMAbortProcessAction, /* verifier will print to stderr and abort() */
  LLVMPrintMessageAction, /* verifier will print to stderr and return 1 */
  LLVMReturnStatusAction  /* verifier will just return 1 */
} LLVMVerifierFailureAction;


/* Verifies that a module is valid, taking the specified action if not.
   Optionally returns a human-readable description of any invalid constructs.
   OutMessage must be disposed with LLVMDisposeMessage. */
int LLVMVerifyModule(LLVMModuleRef M, LLVMVerifierFailureAction Action,
                     char **OutMessage);

/* Verifies that a single function is valid, taking the specified action. Useful
   for debugging. */
int LLVMVerifyFunction(LLVMValueRef Fn, LLVMVerifierFailureAction Action);

/* Open up a ghostview window that displays the CFG of the current function.
   Useful for debugging. */
void LLVMViewFunctionCFG(LLVMValueRef Fn);
void LLVMViewFunctionCFGOnly(LLVMValueRef Fn);

/* BitReader.h */

/* Builds a module from the bitcode in the specified memory buffer, returning a
   reference to the module via the OutModule parameter. Returns 0 on success.
   Optionally returns a human-readable error message via OutMessage. */ 
int LLVMParseBitcode(LLVMMemoryBufferRef MemBuf,
                     LLVMModuleRef *OutModule, char **OutMessage);

int LLVMParseBitcodeInContext(LLVMContextRef ContextRef,
                              LLVMMemoryBufferRef MemBuf,
                              LLVMModuleRef *OutModule, char **OutMessage);

/* Reads a module from the specified path, returning via the OutMP parameter
   a module provider which performs lazy deserialization. Returns 0 on success.
   Optionally returns a human-readable error message via OutMessage. */ 
int LLVMGetBitcodeModuleProvider(LLVMMemoryBufferRef MemBuf,
                                 LLVMModuleProviderRef *OutMP,
                                 char **OutMessage);

int LLVMGetBitcodeModuleProviderInContext(LLVMContextRef ContextRef,
                                          LLVMMemoryBufferRef MemBuf,
                                          LLVMModuleProviderRef *OutMP,
                                          char **OutMessage);

/* BitWriter.h */

/*===-- Operations on modules ---------------------------------------------===*/

/* Writes a module to an open file descriptor. Returns 0 on success.
   Closes the Handle. Use dup first if this is not what you want. */ 
int LLVMWriteBitcodeToFileHandle(LLVMModuleRef M, int Handle);

/* Writes a module to the specified path. Returns 0 on success. */ 
int LLVMWriteBitcodeToFile(LLVMModuleRef M, const char *Path);


/* Target.h */

#define LLVMBigEndian 0
#define LLVMLittleEndian 1
typedef int LLVMByteOrdering;

typedef struct LLVMOpaqueTargetData *LLVMTargetDataRef;
typedef struct LLVMStructLayout *LLVMStructLayoutRef;

/*===-- Target Data -------------------------------------------------------===*/

/** Creates target data from a target layout string.
    See the constructor llvm::TargetData::TargetData. */
LLVMTargetDataRef LLVMCreateTargetData(const char *StringRep);

/** Adds target data information to a pass manager. This does not take ownership
    of the target data.
    See the method llvm::PassManagerBase::add. */
void LLVMAddTargetData(LLVMTargetDataRef, LLVMPassManagerRef);

/** Converts target data to a target layout string. The string must be disposed
    with LLVMDisposeMessage.
    See the constructor llvm::TargetData::TargetData. */
char *LLVMCopyStringRepOfTargetData(LLVMTargetDataRef);

/** Returns the byte order of a target, either LLVMBigEndian or
    LLVMLittleEndian.
    See the method llvm::TargetData::isLittleEndian. */
LLVMByteOrdering LLVMByteOrder(LLVMTargetDataRef);

/** Returns the pointer size in bytes for a target.
    See the method llvm::TargetData::getPointerSize. */
unsigned LLVMPointerSize(LLVMTargetDataRef);

/** Returns the integer type that is the same size as a pointer on a target.
    See the method llvm::TargetData::getIntPtrType. */
LLVMTypeRef LLVMIntPtrType(LLVMTargetDataRef);

/** Computes the size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeSizeInBits. */
unsigned long long LLVMSizeOfTypeInBits(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the storage size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeStoreSize. */
unsigned long long LLVMStoreSizeOfType(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the ABI size of a type in bytes for a target.
    See the method llvm::TargetData::getTypeAllocSize. */
unsigned long long LLVMABISizeOfType(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the ABI alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize. */
unsigned LLVMABIAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the call frame alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize. */
unsigned LLVMCallFrameAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the preferred alignment of a type in bytes for a target.
    See the method llvm::TargetData::getTypeABISize. */
unsigned LLVMPreferredAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef);

/** Computes the preferred alignment of a global variable in bytes for a target.
    See the method llvm::TargetData::getPreferredAlignment. */
unsigned LLVMPreferredAlignmentOfGlobal(LLVMTargetDataRef,
                                        LLVMValueRef GlobalVar);

/** Computes the structure element that contains the byte offset for a target.
    See the method llvm::StructLayout::getElementContainingOffset. */
unsigned LLVMElementAtOffset(LLVMTargetDataRef, LLVMTypeRef StructTy,
                             unsigned long long Offset);

/** Computes the byte offset of the indexed struct element for a target.
    See the method llvm::StructLayout::getElementContainingOffset. */
unsigned long long LLVMOffsetOfElement(LLVMTargetDataRef, LLVMTypeRef StructTy,
                                       unsigned Element);

/** Struct layouts are speculatively cached. If a TargetDataRef is alive when
    types are being refined and removed, this method must be called whenever a
    struct type is removed to avoid a dangling pointer in this cache.
    See the method llvm::TargetData::InvalidateStructLayoutInfo. */
void LLVMInvalidateStructLayout(LLVMTargetDataRef, LLVMTypeRef StructTy);

/** Deallocates a TargetData.
    See the destructor llvm::TargetData::~TargetData. */
void LLVMDisposeTargetData(LLVMTargetDataRef);


/* ExecutionEngine.h */
void LLVMLinkInJIT(void);
void LLVMLinkInInterpreter(void);

typedef struct LLVMOpaqueGenericValue *LLVMGenericValueRef;
typedef struct LLVMOpaqueExecutionEngine *LLVMExecutionEngineRef;

/*===-- Operations on generic values --------------------------------------===*/

LLVMGenericValueRef LLVMCreateGenericValueOfInt(LLVMTypeRef Ty,
                                                unsigned long long N,
                                                int IsSigned);

LLVMGenericValueRef LLVMCreateGenericValueOfPointer(void *P);

LLVMGenericValueRef LLVMCreateGenericValueOfFloat(LLVMTypeRef Ty, double N);

unsigned LLVMGenericValueIntWidth(LLVMGenericValueRef GenValRef);

unsigned long long LLVMGenericValueToInt(LLVMGenericValueRef GenVal,
                                         int IsSigned);

void *LLVMGenericValueToPointer(LLVMGenericValueRef GenVal);

double LLVMGenericValueToFloat(LLVMTypeRef TyRef, LLVMGenericValueRef GenVal);

void LLVMDisposeGenericValue(LLVMGenericValueRef GenVal);

/*===-- Operations on execution engines -----------------------------------===*/

int LLVMCreateExecutionEngine(LLVMExecutionEngineRef *OutEE,
                              LLVMModuleProviderRef MP,
                              char **OutError);

int LLVMCreateInterpreter(LLVMExecutionEngineRef *OutInterp,
                          LLVMModuleProviderRef MP,
                          char **OutError);

int LLVMCreateJITCompiler(LLVMExecutionEngineRef *OutJIT,
                          LLVMModuleProviderRef MP,
                          unsigned OptLevel,
                          char **OutError);

void LLVMDisposeExecutionEngine(LLVMExecutionEngineRef EE);

void LLVMRunStaticConstructors(LLVMExecutionEngineRef EE);

void LLVMRunStaticDestructors(LLVMExecutionEngineRef EE);

int LLVMRunFunctionAsMain(LLVMExecutionEngineRef EE, LLVMValueRef F,
                          unsigned ArgC, const char * const *ArgV,
                          const char * const *EnvP);

LLVMGenericValueRef LLVMRunFunction(LLVMExecutionEngineRef EE, LLVMValueRef F,
                                    unsigned NumArgs,
                                    LLVMGenericValueRef *Args);

void LLVMFreeMachineCodeForFunction(LLVMExecutionEngineRef EE, LLVMValueRef F);

void LLVMAddModuleProvider(LLVMExecutionEngineRef EE, LLVMModuleProviderRef MP);

int LLVMRemoveModuleProvider(LLVMExecutionEngineRef EE,
                             LLVMModuleProviderRef MP,
                             LLVMModuleRef *OutMod, char **OutError);

int LLVMFindFunction(LLVMExecutionEngineRef EE, const char *Name,
                     LLVMValueRef *OutFn);

LLVMTargetDataRef LLVMGetExecutionEngineTargetData(LLVMExecutionEngineRef EE);

void LLVMAddGlobalMapping(LLVMExecutionEngineRef EE, LLVMValueRef Global,
                          void* Addr);

void *LLVMGetPointerToGlobal(LLVMExecutionEngineRef EE, LLVMValueRef Global);


/* LinkTimeOptimizer.h */
/// This provides a dummy type for pointers to the LTO object.
typedef void* llvm_lto_t;

/// This provides a C-visible enumerator to manage status codes.
/// This should map exactly onto the C++ enumerator LTOStatus.
typedef enum llvm_lto_status {
  LLVM_LTO_UNKNOWN,
  LLVM_LTO_OPT_SUCCESS,
  LLVM_LTO_READ_SUCCESS,
  LLVM_LTO_READ_FAILURE,
  LLVM_LTO_WRITE_FAILURE,
  LLVM_LTO_NO_TARGET,
  LLVM_LTO_NO_WORK,
  LLVM_LTO_MODULE_MERGE_FAILURE,
  LLVM_LTO_ASM_FAILURE,

  //  Added C-specific error codes
  LLVM_LTO_NULL_OBJECT
} llvm_lto_status_t;

/// This provides C interface to initialize link time optimizer. This allows
/// linker to use dlopen() interface to dynamically load LinkTimeOptimizer.
/// extern "C" helps, because dlopen() interface uses name to find the symbol.
extern llvm_lto_t llvm_create_optimizer(void);
extern void llvm_destroy_optimizer(llvm_lto_t lto);

extern llvm_lto_status_t llvm_read_object_file
  (llvm_lto_t lto, const char* input_filename);
extern llvm_lto_status_t llvm_optimize_modules
  (llvm_lto_t lto, const char* output_filename);

/* lto.h */

#define LTO_API_VERSION 3

typedef enum {
    LTO_SYMBOL_ALIGNMENT_MASK         = 0x0000001F,    /* log2 of alignment */
    LTO_SYMBOL_PERMISSIONS_MASK       = 0x000000E0,    
    LTO_SYMBOL_PERMISSIONS_CODE       = 0x000000A0,    
    LTO_SYMBOL_PERMISSIONS_DATA       = 0x000000C0,    
    LTO_SYMBOL_PERMISSIONS_RODATA     = 0x00000080,    
    LTO_SYMBOL_DEFINITION_MASK        = 0x00000700,    
    LTO_SYMBOL_DEFINITION_REGULAR     = 0x00000100,    
    LTO_SYMBOL_DEFINITION_TENTATIVE   = 0x00000200,    
    LTO_SYMBOL_DEFINITION_WEAK        = 0x00000300,    
    LTO_SYMBOL_DEFINITION_UNDEFINED   = 0x00000400,    
    LTO_SYMBOL_DEFINITION_WEAKUNDEF   = 0x00000500,
    LTO_SYMBOL_SCOPE_MASK             = 0x00003800,    
    LTO_SYMBOL_SCOPE_INTERNAL         = 0x00000800,    
    LTO_SYMBOL_SCOPE_HIDDEN           = 0x00001000,    
    LTO_SYMBOL_SCOPE_PROTECTED        = 0x00002000,    
    LTO_SYMBOL_SCOPE_DEFAULT          = 0x00001800    
} lto_symbol_attributes;

typedef enum {
    LTO_DEBUG_MODEL_NONE         = 0,
    LTO_DEBUG_MODEL_DWARF        = 1
} lto_debug_model;

typedef enum {
    LTO_CODEGEN_PIC_MODEL_STATIC         = 0,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC        = 1,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2
} lto_codegen_model;


/** opaque reference to a loaded object module */
typedef struct LTOModule*         lto_module_t;

/** opaque reference to a code generator */
typedef struct LTOCodeGenerator*  lto_code_gen_t;

/**
 * Returns a printable string.
 */
extern const char*
lto_get_version(void);


/**
 * Returns the last error string or NULL if last operation was sucessful.
 */
extern const char*
lto_get_error_message(void);

/**
 * Checks if a file is a loadable object file.
 */
extern bool
lto_module_is_object_file(const char* path);


/**
 * Checks if a file is a loadable object compiled for requested target.
 */
extern bool
lto_module_is_object_file_for_target(const char* path, 
                                     const char* target_triple_prefix);


/**
 * Checks if a buffer is a loadable object file.
 */
extern bool
lto_module_is_object_file_in_memory(const void* mem, size_t length);


/**
 * Checks if a buffer is a loadable object compiled for requested target.
 */
extern bool
lto_module_is_object_file_in_memory_for_target(const void* mem, size_t length, 
                                               const char* target_triple_prefix);


/**
 * Loads an object file from disk.
 * Returns NULL on error (check lto_get_error_message() for details).
 */
extern lto_module_t
lto_module_create(const char* path);


/**
 * Loads an object file from memory.
 * Returns NULL on error (check lto_get_error_message() for details).
 */
extern lto_module_t
lto_module_create_from_memory(const void* mem, size_t length);


/**
 * Frees all memory internally allocated by the module.
 * Upon return the lto_module_t is no longer valid.
 */
extern void
lto_module_dispose(lto_module_t mod);


/**
 * Returns triple string which the object module was compiled under.
 */
extern const char*
lto_module_get_target_triple(lto_module_t mod);


/**
 * Returns the number of symbols in the object module.
 */
extern unsigned int
lto_module_get_num_symbols(lto_module_t mod);


/**
 * Returns the name of the ith symbol in the object module.
 */
extern const char*
lto_module_get_symbol_name(lto_module_t mod, unsigned int index);


/**
 * Returns the attributes of the ith symbol in the object module.
 */
extern lto_symbol_attributes
lto_module_get_symbol_attribute(lto_module_t mod, unsigned int index);


/**
 * Instantiates a code generator.
 * Returns NULL on error (check lto_get_error_message() for details).
 */
extern lto_code_gen_t
lto_codegen_create(void);


/**
 * Frees all code generator and all memory it internally allocated.
 * Upon return the lto_code_gen_t is no longer valid.
 */
extern void
lto_codegen_dispose(lto_code_gen_t);



/**
 * Add an object module to the set of modules for which code will be generated.
 * Returns true on error (check lto_get_error_message() for details).
 */
extern bool
lto_codegen_add_module(lto_code_gen_t cg, lto_module_t mod);



/**
 * Sets if debug info should be generated.
 * Returns true on error (check lto_get_error_message() for details).
 */
extern bool
lto_codegen_set_debug_model(lto_code_gen_t cg, lto_debug_model);


/**
 * Sets which PIC code model to generated.
 * Returns true on error (check lto_get_error_message() for details).
 */
extern bool
lto_codegen_set_pic_model(lto_code_gen_t cg, lto_codegen_model);


/**
 * Sets the location of the "gcc" to run. If not set, libLTO will search for
 * "gcc" on the path.
 */
extern void
lto_codegen_set_gcc_path(lto_code_gen_t cg, const char* path);


/**
 * Sets the location of the assembler tool to run. If not set, libLTO
 * will use gcc to invoke the assembler.
 */
extern void
lto_codegen_set_assembler_path(lto_code_gen_t cg, const char* path);


/**
 * Adds to a list of all global symbols that must exist in the final
 * generated code.  If a function is not listed, it might be
 * inlined into every usage and optimized away.
 */
extern void
lto_codegen_add_must_preserve_symbol(lto_code_gen_t cg, const char* symbol);


/**
 * Writes a new object file at the specified path that contains the
 * merged contents of all modules added so far.
 * Returns true on error (check lto_get_error_message() for details).
 */
extern bool
lto_codegen_write_merged_modules(lto_code_gen_t cg, const char* path);


/**
 * Generates code for all added modules into one native object file.
 * On sucess returns a pointer to a generated mach-o/ELF buffer and
 * length set to the buffer size.  The buffer is owned by the 
 * lto_code_gen_t and will be freed when lto_codegen_dispose()
 * is called, or lto_codegen_compile() is called again.
 * On failure, returns NULL (check lto_get_error_message() for details).
 */
extern const void*
lto_codegen_compile(lto_code_gen_t cg, size_t* length);


/**
 * Sets options to help debug codegen bugs.
 */
extern void
lto_codegen_debug_options(lto_code_gen_t cg, const char *);




