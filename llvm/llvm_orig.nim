
const 
  libname* = ""               #Setup as you need

type 
  PLLVMBasicBlockRef* = ptr LLVMBasicBlockRef
  PLLVMExecutionEngineRef* = ptr LLVMExecutionEngineRef
  PLLVMGenericValueRef* = ptr LLVMGenericValueRef
  PLLVMMemoryBufferRef* = ptr LLVMMemoryBufferRef
  PLLVMModuleProviderRef* = ptr LLVMModuleProviderRef
  PLLVMModuleRef* = ptr LLVMModuleRef
  PLLVMTypeRef* = ptr LLVMTypeRef
  PLLVMValueRef* = ptr LLVMValueRef # Core.h  
                                    # Opaque types.  
                                    #*
                                    # * The top-level container for all LLVM global data.  See the LLVMContext class.
                                    #  

type 
  LLVMContextRef* = LLVMOpaqueContext #*
                                      # * The top-level container for all other LLVM Intermediate Representation (IR)
                                      # * objects. See the llvm::Module class.
                                      #  
  LLVMModuleRef* = LLVMOpaqueModule #*
                                    # * Each value in the LLVM IR has a type, an LLVMTypeRef. See the llvm::Type
                                    # * class.
                                    #  
  LLVMTypeRef* = LLVMOpaqueType #*
                                # * When building recursive types using LLVMRefineType, LLVMTypeRef values may
                                # * become invalid; use LLVMTypeHandleRef to resolve this problem. See the
                                # * llvm::AbstractTypeHolder class.
                                #  
  LLVMTypeHandleRef* = LLVMOpaqueTypeHandle
  LLVMValueRef* = LLVMOpaqueValue
  LLVMBasicBlockRef* = LLVMOpaqueBasicBlock
  LLVMBuilderRef* = LLVMOpaqueBuilder # Used to provide a module to JIT or interpreter.
                                      # * See the llvm::ModuleProvider class.
                                      #  
  LLVMModuleProviderRef* = LLVMOpaqueModuleProvider # Used to provide a module to JIT or interpreter.
                                                    # * See the llvm::MemoryBuffer class.
                                                    #  
  LLVMMemoryBufferRef* = LLVMOpaqueMemoryBuffer #* See the llvm::PassManagerBase class.  
  LLVMPassManagerRef* = LLVMOpaquePassManager #*
                                              # * Used to iterate through the uses of a Value, allowing access to all Values
                                              # * that use this Value.  See the llvm::Use and llvm::value_use_iterator classes.
                                              #  
  LLVMUseIteratorRef* = LLVMOpaqueUseIterator
  LLVMAttribute* = enum 
    LLVMZExtAttribute = 1 shl 0, LLVMSExtAttribute = 1 shl 1, 
    LLVMNoReturnAttribute = 1 shl 2, LLVMInRegAttribute = 1 shl 3, 
    LLVMStructRetAttribute = 1 shl 4, LLVMNoUnwindAttribute = 1 shl 5, 
    LLVMNoAliasAttribute = 1 shl 6, LLVMByValAttribute = 1 shl 7, 
    LLVMNestAttribute = 1 shl 8, LLVMReadNoneAttribute = 1 shl 9, 
    LLVMReadOnlyAttribute = 1 shl 10, LLVMNoInlineAttribute = 1 shl 11, 
    LLVMAlwaysInlineAttribute = 1 shl 12, 
    LLVMOptimizeForSizeAttribute = 1 shl 13, 
    LLVMStackProtectAttribute = 1 shl 14, 
    LLVMStackProtectReqAttribute = 1 shl 15, LLVMNoCaptureAttribute = 1 shl
        21, LLVMNoRedZoneAttribute = 1 shl 22, 
    LLVMNoImplicitFloatAttribute = 1 shl 23, LLVMNakedAttribute = 1 shl 24, 
    LLVMInlineHintAttribute = 1 shl 25
  LLVMOpcode* = enum  #*< type with no size  
                      #*< 32 bit floating point type  
                      #*< 64 bit floating point type  
                      #*< 80 bit floating point type (X87)  
                      #*< 128 bit floating point type (112-bit mantissa) 
                      #*< 128 bit floating point type (two 64-bits)  
                      #*< Labels  
                      #*< Arbitrary bit width integers  
                      #*< Functions  
                      #*< Structures  
                      #*< Arrays  
                      #*< Pointers  
                      #*< Opaque: type with unknown structure  
                      #*< SIMD 'packed' format, or other vector type  
                      #*< Metadata  
    LLVMRet = 1, LLVMBr = 2, LLVMSwitch = 3, LLVMInvoke = 4, LLVMUnwind = 5, 
    LLVMUnreachable = 6, LLVMAdd = 7, LLVMFAdd = 8, LLVMSub = 9, LLVMFSub = 10, 
    LLVMMul = 11, LLVMFMul = 12, LLVMUDiv = 13, LLVMSDiv = 14, LLVMFDiv = 15, 
    LLVMURem = 16, LLVMSRem = 17, LLVMFRem = 18, LLVMShl = 19, LLVMLShr = 20, 
    LLVMAShr = 21, LLVMAnd = 22, LLVMOr = 23, LLVMXor = 24, LLVMMalloc = 25, 
    LLVMFree = 26, LLVMAlloca = 27, LLVMLoad = 28, LLVMStore = 29, 
    LLVMGetElementPtr = 30, LLVMTrunk = 31, LLVMZExt = 32, LLVMSExt = 33, 
    LLVMFPToUI = 34, LLVMFPToSI = 35, LLVMUIToFP = 36, LLVMSIToFP = 37, 
    LLVMFPTrunc = 38, LLVMFPExt = 39, LLVMPtrToInt = 40, LLVMIntToPtr = 41, 
    LLVMBitCast = 42, LLVMICmp = 43, LLVMFCmp = 44, LLVMPHI = 45, LLVMCall = 46, 
    LLVMSelect = 47, LLVMVAArg = 50, LLVMExtractElement = 51, 
    LLVMInsertElement = 52, LLVMShuffleVector = 53, LLVMExtractValue = 54, 
    LLVMInsertValue = 55
  LLVMTypeKind* = enum  #*< Externally visible function  
                        #*< Keep one copy of function when linking (inline) 
                        #*< Same, but only replaced by something
                        #                            equivalent.  
                        #*< Keep one copy of function when linking (weak)  
                        #*< Same, but only replaced by something
                        #                            equivalent.  
                        #*< Special purpose, only applies to global arrays  
                        #*< Rename collisions when linking (static
                        #                               functions)  
                        #*< Like Internal, but omit from symbol table  
                        #*< Function to be imported from DLL  
                        #*< Function to be accessible from DLL  
                        #*< ExternalWeak linkage description  
                        #*< Stand-in functions for streaming fns from
                        #                               bitcode  
                        #*< Tentative definitions  
                        #*< Like Private, but linker removes.  
    LLVMVoidTypeKind, LLVMFloatTypeKind, LLVMDoubleTypeKind, 
    LLVMX86_FP80TypeKind, LLVMFP128TypeKind, LLVMPPC_FP128TypeKind, 
    LLVMLabelTypeKind, LLVMIntegerTypeKind, LLVMFunctionTypeKind, 
    LLVMStructTypeKind, LLVMArrayTypeKind, LLVMPointerTypeKind, 
    LLVMOpaqueTypeKind, LLVMVectorTypeKind, LLVMMetadataTypeKind
  LLVMLinkage* = enum         #*< The GV is visible  
                              #*< The GV is hidden  
                              #*< The GV is protected  
    LLVMExternalLinkage, LLVMAvailableExternallyLinkage, LLVMLinkOnceAnyLinkage, 
    LLVMLinkOnceODRLinkage, LLVMWeakAnyLinkage, LLVMWeakODRLinkage, 
    LLVMAppendingLinkage, LLVMInternalLinkage, LLVMPrivateLinkage, 
    LLVMDLLImportLinkage, LLVMDLLExportLinkage, LLVMExternalWeakLinkage, 
    LLVMGhostLinkage, LLVMCommonLinkage, LLVMLinkerPrivateLinkage
  LLVMVisibility* = enum 
    LLVMDefaultVisibility, LLVMHiddenVisibility, LLVMProtectedVisibility
  LLVMCallConv* = enum        #*< equal  
                              #*< not equal  
                              #*< unsigned greater than  
                              #*< unsigned greater or equal  
                              #*< unsigned less than  
                              #*< unsigned less or equal  
                              #*< signed greater than  
                              #*< signed greater or equal  
                              #*< signed less than  
                              #*< signed less or equal  
    LLVMCCallConv = 0, LLVMFastCallConv = 8, LLVMColdCallConv = 9, 
    LLVMX86StdcallCallConv = 64, LLVMX86FastcallCallConv = 65
  LLVMIntPredicate* = enum    #*< Always false (always folded)  
                              #*< True if ordered and equal  
                              #*< True if ordered and greater than  
                              #*< True if ordered and greater than or equal  
                              #*< True if ordered and less than  
                              #*< True if ordered and less than or equal  
                              #*< True if ordered and operands are unequal  
                              #*< True if ordered (no nans)  
                              #*< True if unordered: isnan(X) | isnan(Y)  
                              #*< True if unordered or equal  
                              #*< True if unordered or greater than  
                              #*< True if unordered, greater than, or equal  
                              #*< True if unordered or less than  
                              #*< True if unordered, less than, or equal  
                              #*< True if unordered or not equal  
                              #*< Always true (always folded)  
    LLVMIntEQ = 32, LLVMIntNE, LLVMIntUGT, LLVMIntUGE, LLVMIntULT, LLVMIntULE, 
    LLVMIntSGT, LLVMIntSGE, LLVMIntSLT, LLVMIntSLE
  LLVMRealPredicate* = enum   #===-- Error handling ----------------------------------------------------=== 
    LLVMRealPredicateFalse, LLVMRealOEQ, LLVMRealOGT, LLVMRealOGE, LLVMRealOLT, 
    LLVMRealOLE, LLVMRealONE, LLVMRealORD, LLVMRealUNO, LLVMRealUEQ, 
    LLVMRealUGT, LLVMRealUGE, LLVMRealULT, LLVMRealULE, LLVMRealUNE, 
    LLVMRealPredicateTrue

proc LLVMDisposeMessage*(Message: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeMessage".}
  #===-- Modules -----------------------------------------------------------=== 
  # Create and destroy contexts.  
proc LLVMContextCreate*(): LLVMContextRef{.cdecl, dynlib: libname, 
    importc: "LLVMContextCreate".}
proc LLVMGetGlobalContext*(): LLVMContextRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetGlobalContext".}
proc LLVMContextDispose*(C: LLVMContextRef){.cdecl, dynlib: libname, 
    importc: "LLVMContextDispose".}
  # Create and destroy modules.  
  #* See llvm::Module::Module.  
proc LLVMModuleCreateWithName*(ModuleID: cstring): LLVMModuleRef{.cdecl, 
    dynlib: libname, importc: "LLVMModuleCreateWithName".}
proc LLVMModuleCreateWithNameInContext*(ModuleID: cstring, C: LLVMContextRef): LLVMModuleRef{.
    cdecl, dynlib: libname, importc: "LLVMModuleCreateWithNameInContext".}
  #* See llvm::Module::~Module.  
proc LLVMDisposeModule*(M: LLVMModuleRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeModule".}
  #* Data layout. See Module::getDataLayout.  
proc LLVMGetDataLayout*(M: LLVMModuleRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetDataLayout".}
proc LLVMSetDataLayout*(M: LLVMModuleRef, Triple: cstring){.cdecl, 
    dynlib: libname, importc: "LLVMSetDataLayout".}
  #* Target triple. See Module::getTargetTriple.  
proc LLVMGetTarget*(M: LLVMModuleRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetTarget".}
proc LLVMSetTarget*(M: LLVMModuleRef, Triple: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetTarget".}
  #* See Module::addTypeName.  
proc LLVMAddTypeName*(M: LLVMModuleRef, Name: cstring, Ty: LLVMTypeRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMAddTypeName".}
proc LLVMDeleteTypeName*(M: LLVMModuleRef, Name: cstring){.cdecl, 
    dynlib: libname, importc: "LLVMDeleteTypeName".}
proc LLVMGetTypeByName*(M: LLVMModuleRef, Name: cstring): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetTypeByName".}
  #* See Module::dump.  
proc LLVMDumpModule*(M: LLVMModuleRef){.cdecl, dynlib: libname, 
                                        importc: "LLVMDumpModule".}
  #===-- Types -------------------------------------------------------------=== 
  # LLVM types conform to the following hierarchy:
  # * 
  # *   types:
  # *     integer type
  # *     real type
  # *     function type
  # *     sequence types:
  # *       array type
  # *       pointer type
  # *       vector type
  # *     void type
  # *     label type
  # *     opaque type
  #  
  #* See llvm::LLVMTypeKind::getTypeID.  
proc LLVMGetTypeKind*(Ty: LLVMTypeRef): LLVMTypeKind{.cdecl, dynlib: libname, 
    importc: "LLVMGetTypeKind".}
  #* See llvm::LLVMType::getContext.  
proc LLVMGetTypeContext*(Ty: LLVMTypeRef): LLVMContextRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetTypeContext".}
  # Operations on integer types  
proc LLVMInt1TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMInt1TypeInContext".}
proc LLVMInt8TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMInt8TypeInContext".}
proc LLVMInt16TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMInt16TypeInContext".}
proc LLVMInt32TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMInt32TypeInContext".}
proc LLVMInt64TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMInt64TypeInContext".}
proc LLVMIntTypeInContext*(C: LLVMContextRef, NumBits: dword): LLVMTypeRef{.
    cdecl, dynlib: libname, importc: "LLVMIntTypeInContext".}
proc LLVMInt1Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                   importc: "LLVMInt1Type".}
proc LLVMInt8Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                   importc: "LLVMInt8Type".}
proc LLVMInt16Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMInt16Type".}
proc LLVMInt32Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMInt32Type".}
proc LLVMInt64Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMInt64Type".}
proc LLVMIntType*(NumBits: dword): LLVMTypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMIntType".}
proc LLVMGetIntTypeWidth*(IntegerTy: LLVMTypeRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMGetIntTypeWidth".}
  # Operations on real types  
proc LLVMFloatTypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMFloatTypeInContext".}
proc LLVMDoubleTypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMDoubleTypeInContext".}
proc LLVMX86FP80TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMX86FP80TypeInContext".}
proc LLVMFP128TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMFP128TypeInContext".}
proc LLVMPPCFP128TypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMPPCFP128TypeInContext".}
proc LLVMFloatType*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMFloatType".}
proc LLVMDoubleType*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                     importc: "LLVMDoubleType".}
proc LLVMX86FP80Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                      importc: "LLVMX86FP80Type".}
proc LLVMFP128Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMFP128Type".}
proc LLVMPPCFP128Type*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                       importc: "LLVMPPCFP128Type".}
  # Operations on function types  
proc LLVMFunctionType*(ReturnType: LLVMTypeRef, ParamTypes: pLLVMTypeRef, 
                       ParamCount: dword, IsVarArg: int32): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMFunctionType".}
proc LLVMIsFunctionVarArg*(FunctionTy: LLVMTypeRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMIsFunctionVarArg".}
proc LLVMGetReturnType*(FunctionTy: LLVMTypeRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetReturnType".}
proc LLVMCountParamTypes*(FunctionTy: LLVMTypeRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMCountParamTypes".}
proc LLVMGetParamTypes*(FunctionTy: LLVMTypeRef, Dest: pLLVMTypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMGetParamTypes".}
  # Operations on struct types  
proc LLVMStructTypeInContext*(C: LLVMContextRef, ElementTypes: pLLVMTypeRef, 
                              ElementCount: dword, isPacked: int32): LLVMTypeRef{.
    cdecl, dynlib: libname, importc: "LLVMStructTypeInContext".}
proc LLVMStructType*(ElementTypes: pLLVMTypeRef, ElementCount: dword, 
                     isPacked: int32): LLVMTypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMStructType".}
proc LLVMCountStructElementTypes*(StructTy: LLVMTypeRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMCountStructElementTypes".}
proc LLVMGetStructElementTypes*(StructTy: LLVMTypeRef, Dest: pLLVMTypeRef){.
    cdecl, dynlib: libname, importc: "LLVMGetStructElementTypes".}
proc LLVMIsPackedStruct*(StructTy: LLVMTypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsPackedStruct".}
  # Operations on array, pointer, and vector types (sequence types)  
proc LLVMArrayType*(ElementType: LLVMTypeRef, ElementCount: dword): LLVMTypeRef{.
    cdecl, dynlib: libname, importc: "LLVMArrayType".}
proc LLVMPointerType*(ElementType: LLVMTypeRef, AddressSpace: dword): LLVMTypeRef{.
    cdecl, dynlib: libname, importc: "LLVMPointerType".}
proc LLVMVectorType*(ElementType: LLVMTypeRef, ElementCount: dword): LLVMTypeRef{.
    cdecl, dynlib: libname, importc: "LLVMVectorType".}
proc LLVMGetElementType*(Ty: LLVMTypeRef): LLVMTypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetElementType".}
proc LLVMGetArrayLength*(ArrayTy: LLVMTypeRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMGetArrayLength".}
proc LLVMGetPointerAddressSpace*(PointerTy: LLVMTypeRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMGetPointerAddressSpace".}
proc LLVMGetVectorSize*(VectorTy: LLVMTypeRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMGetVectorSize".}
  # Operations on other types  
proc LLVMVoidTypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMVoidTypeInContext".}
proc LLVMLabelTypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMLabelTypeInContext".}
proc LLVMOpaqueTypeInContext*(C: LLVMContextRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMOpaqueTypeInContext".}
proc LLVMVoidType*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                   importc: "LLVMVoidType".}
proc LLVMLabelType*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                    importc: "LLVMLabelType".}
proc LLVMOpaqueType*(): LLVMTypeRef{.cdecl, dynlib: libname, 
                                     importc: "LLVMOpaqueType".}
  # Operations on type handles  
proc LLVMCreateTypeHandle*(PotentiallyAbstractTy: LLVMTypeRef): LLVMTypeHandleRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateTypeHandle".}
proc LLVMRefineType*(AbstractTy: LLVMTypeRef, ConcreteTy: LLVMTypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMRefineType".}
proc LLVMResolveTypeHandle*(TypeHandle: LLVMTypeHandleRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMResolveTypeHandle".}
proc LLVMDisposeTypeHandle*(TypeHandle: LLVMTypeHandleRef){.cdecl, 
    dynlib: libname, importc: "LLVMDisposeTypeHandle".}
  # Operations on all values  
proc LLVMTypeOf*(Val: LLVMValueRef): LLVMTypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMTypeOf".}
proc LLVMGetValueName*(Val: LLVMValueRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetValueName".}
proc LLVMSetValueName*(Val: LLVMValueRef, Name: cstring){.cdecl, 
    dynlib: libname, importc: "LLVMSetValueName".}
proc LLVMDumpValue*(Val: LLVMValueRef){.cdecl, dynlib: libname, 
                                        importc: "LLVMDumpValue".}
proc LLVMReplaceAllUsesWith*(OldVal: LLVMValueRef, NewVal: LLVMValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMReplaceAllUsesWith".}
  # Conversion functions. Return the input value if it is an instance of the
  #   specified class, otherwise NULL. See llvm::dyn_cast_or_null<>.  
proc LLVMIsAArgument*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAArgument".}
proc LLVMIsABasicBlock*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsABasicBlock".}
proc LLVMIsAInlineAsm*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInlineAsm".}
proc LLVMIsAUser*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUser".}
proc LLVMIsAConstant*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstant".}
proc LLVMIsAConstantAggregateZero*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantAggregateZero".}
proc LLVMIsAConstantArray*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantArray".}
proc LLVMIsAConstantExpr*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantExpr".}
proc LLVMIsAConstantFP*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantFP".}
proc LLVMIsAConstantInt*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantInt".}
proc LLVMIsAConstantPointerNull*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantPointerNull".}
proc LLVMIsAConstantStruct*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantStruct".}
proc LLVMIsAConstantVector*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAConstantVector".}
proc LLVMIsAGlobalValue*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAGlobalValue".}
proc LLVMIsAFunction*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFunction".}
proc LLVMIsAGlobalAlias*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAGlobalAlias".}
proc LLVMIsAGlobalVariable*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAGlobalVariable".}
proc LLVMIsAUndefValue*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAUndefValue".}
proc LLVMIsAInstruction*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAInstruction".}
proc LLVMIsABinaryOperator*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsABinaryOperator".}
proc LLVMIsACallInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACallInst".}
proc LLVMIsAIntrinsicInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAIntrinsicInst".}
proc LLVMIsADbgInfoIntrinsic*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgInfoIntrinsic".}
proc LLVMIsADbgDeclareInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgDeclareInst".}
proc LLVMIsADbgFuncStartInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgFuncStartInst".}
proc LLVMIsADbgRegionEndInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgRegionEndInst".}
proc LLVMIsADbgRegionStartInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgRegionStartInst".}
proc LLVMIsADbgStopPointInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsADbgStopPointInst".}
proc LLVMIsAEHSelectorInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAEHSelectorInst".}
proc LLVMIsAMemIntrinsic*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAMemIntrinsic".}
proc LLVMIsAMemCpyInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAMemCpyInst".}
proc LLVMIsAMemMoveInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAMemMoveInst".}
proc LLVMIsAMemSetInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAMemSetInst".}
proc LLVMIsACmpInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACmpInst".}
proc LLVMIsAFCmpInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFCmpInst".}
proc LLVMIsAICmpInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAICmpInst".}
proc LLVMIsAExtractElementInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAExtractElementInst".}
proc LLVMIsAGetElementPtrInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAGetElementPtrInst".}
proc LLVMIsAInsertElementInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAInsertElementInst".}
proc LLVMIsAInsertValueInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAInsertValueInst".}
proc LLVMIsAPHINode*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAPHINode".}
proc LLVMIsASelectInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsASelectInst".}
proc LLVMIsAShuffleVectorInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAShuffleVectorInst".}
proc LLVMIsAStoreInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAStoreInst".}
proc LLVMIsATerminatorInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsATerminatorInst".}
proc LLVMIsABranchInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsABranchInst".}
proc LLVMIsAInvokeInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAInvokeInst".}
proc LLVMIsAReturnInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAReturnInst".}
proc LLVMIsASwitchInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsASwitchInst".}
proc LLVMIsAUnreachableInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAUnreachableInst".}
proc LLVMIsAUnwindInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAUnwindInst".}
proc LLVMIsAUnaryInstruction*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAUnaryInstruction".}
proc LLVMIsAAllocationInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAAllocationInst".}
proc LLVMIsAAllocaInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAAllocaInst".}
proc LLVMIsACastInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACastInst".}
proc LLVMIsABitCastInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsABitCastInst".}
proc LLVMIsAFPExtInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFPExtInst".}
proc LLVMIsAFPToSIInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAFPToSIInst".}
proc LLVMIsAFPToUIInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAFPToUIInst".}
proc LLVMIsAFPTruncInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAFPTruncInst".}
proc LLVMIsAIntToPtrInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAIntToPtrInst".}
proc LLVMIsAPtrToIntInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAPtrToIntInst".}
proc LLVMIsASExtInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsASExtInst".}
proc LLVMIsASIToFPInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsASIToFPInst".}
proc LLVMIsATruncInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsATruncInst".}
proc LLVMIsAUIToFPInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAUIToFPInst".}
proc LLVMIsAZExtInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAZExtInst".}
proc LLVMIsAExtractValueInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMIsAExtractValueInst".}
proc LLVMIsAFreeInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFreeInst".}
proc LLVMIsALoadInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsALoadInst".}
proc LLVMIsAVAArgInst*(Val: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAVAArgInst".}
  # Operations on Uses  
proc LLVMGetFirstUse*(Val: LLVMValueRef): LLVMUseIteratorRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetFirstUse".}
proc LLVMGetNextUse*(U: LLVMUseIteratorRef): LLVMUseIteratorRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextUse".}
proc LLVMGetUser*(U: LLVMUseIteratorRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetUser".}
proc LLVMGetUsedValue*(U: LLVMUseIteratorRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetUsedValue".}
  # Operations on Users  
proc LLVMGetOperand*(Val: LLVMValueRef, Index: dword): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetOperand".}
  # Operations on constants of any type  
proc LLVMConstNull*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstNull".}
  # all zeroes  
proc LLVMConstAllOnes*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstAllOnes".}
  # only for int/vector  
proc LLVMGetUndef*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetUndef".}
proc LLVMIsConstant*(Val: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsConstant".}
proc LLVMIsNull*(Val: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsNull".}
proc LLVMIsUndef*(Val: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsUndef".}
proc LLVMConstPointerNull*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstPointerNull".}
  # Operations on scalar constants  
proc LLVMConstInt*(IntTy: LLVMTypeRef, N: qword, SignExtend: int32): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstInt".}
proc LLVMConstIntOfString*(IntTy: LLVMTypeRef, Text: cstring, Radix: uint8_t): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstIntOfString".}
proc LLVMConstIntOfStringAndSize*(IntTy: LLVMTypeRef, Text: cstring, 
                                  SLen: dword, Radix: uint8_t): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstIntOfStringAndSize".}
proc LLVMConstReal*(RealTy: LLVMTypeRef, N: float64): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstReal".}
proc LLVMConstRealOfString*(RealTy: LLVMTypeRef, Text: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstRealOfString".}
proc LLVMConstRealOfStringAndSize*(RealTy: LLVMTypeRef, Text: cstring, 
                                   SLen: dword): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstRealOfStringAndSize".}
proc LLVMConstIntGetZExtValue*(ConstantVal: LLVMValueRef): qword{.cdecl, 
    dynlib: libname, importc: "LLVMConstIntGetZExtValue".}
proc LLVMConstIntGetSExtValue*(ConstantVal: LLVMValueRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMConstIntGetSExtValue".}
  # Operations on composite constants  
proc LLVMConstStringInContext*(C: LLVMContextRef, Str: cstring, len: dword, 
                               DontNullTerminate: int32): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstStringInContext".}
proc LLVMConstStructInContext*(C: LLVMContextRef, ConstantVals: pLLVMValueRef, 
                               Count: dword, isPacked: int32): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstStructInContext".}
proc LLVMConstString*(Str: cstring, len: dword, DontNullTerminate: int32): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstString".}
proc LLVMConstArray*(ElementTy: LLVMTypeRef, ConstantVals: pLLVMValueRef, 
                     len: dword): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstArray".}
proc LLVMConstStruct*(ConstantVals: pLLVMValueRef, Count: dword, isPacked: int32): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstStruct".}
proc LLVMConstVector*(ScalarConstantVals: pLLVMValueRef, Size: dword): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstVector".}
  # Constant expressions  
proc LLVMGetConstOpcode*(ConstantVal: LLVMValueRef): LLVMOpcode{.cdecl, 
    dynlib: libname, importc: "LLVMGetConstOpcode".}
proc LLVMAlignOf*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMAlignOf".}
proc LLVMSizeOf*(Ty: LLVMTypeRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMSizeOf".}
proc LLVMConstNeg*(ConstantVal: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstNeg".}
proc LLVMConstFNeg*(ConstantVal: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFNeg".}
proc LLVMConstNot*(ConstantVal: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstNot".}
proc LLVMConstAdd*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstAdd".}
proc LLVMConstNSWAdd*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstNSWAdd".}
proc LLVMConstFAdd*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFAdd".}
proc LLVMConstSub*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSub".}
proc LLVMConstFSub*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFSub".}
proc LLVMConstMul*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstMul".}
proc LLVMConstFMul*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFMul".}
proc LLVMConstUDiv*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstUDiv".}
proc LLVMConstSDiv*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSDiv".}
proc LLVMConstExactSDiv*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstExactSDiv".}
proc LLVMConstFDiv*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFDiv".}
proc LLVMConstURem*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstURem".}
proc LLVMConstSRem*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSRem".}
proc LLVMConstFRem*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFRem".}
proc LLVMConstAnd*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstAnd".}
proc LLVMConstOr*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstOr".}
proc LLVMConstXor*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstXor".}
proc LLVMConstICmp*(Predicate: LLVMIntPredicate, LHSConstant: LLVMValueRef, 
                    RHSConstant: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstICmp".}
proc LLVMConstFCmp*(Predicate: LLVMRealPredicate, LHSConstant: LLVMValueRef, 
                    RHSConstant: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFCmp".}
proc LLVMConstShl*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstShl".}
proc LLVMConstLShr*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstLShr".}
proc LLVMConstAShr*(LHSConstant: LLVMValueRef, RHSConstant: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstAShr".}
proc LLVMConstGEP*(ConstantVal: LLVMValueRef, ConstantIndices: pLLVMValueRef, 
                   NumIndices: dword): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstGEP".}
proc LLVMConstInBoundsGEP*(ConstantVal: LLVMValueRef, 
                           ConstantIndices: pLLVMValueRef, NumIndices: dword): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstInBoundsGEP".}
proc LLVMConstTrunc*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstTrunc".}
proc LLVMConstSExt*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSExt".}
proc LLVMConstZExt*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstZExt".}
proc LLVMConstFPTrunc*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFPTrunc".}
proc LLVMConstFPExt*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFPExt".}
proc LLVMConstUIToFP*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstUIToFP".}
proc LLVMConstSIToFP*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSIToFP".}
proc LLVMConstFPToUI*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFPToUI".}
proc LLVMConstFPToSI*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFPToSI".}
proc LLVMConstPtrToInt*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstPtrToInt".}
proc LLVMConstIntToPtr*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstIntToPtr".}
proc LLVMConstBitCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstBitCast".}
proc LLVMConstZExtOrBitCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstZExtOrBitCast".}
proc LLVMConstSExtOrBitCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSExtOrBitCast".}
proc LLVMConstTruncOrBitCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstTruncOrBitCast".}
proc LLVMConstPointerCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstPointerCast".}
proc LLVMConstIntCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef, 
                       isSigned: dword): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstIntCast".}
proc LLVMConstFPCast*(ConstantVal: LLVMValueRef, ToType: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstFPCast".}
proc LLVMConstSelect*(ConstantCondition: LLVMValueRef, 
                      ConstantIfTrue: LLVMValueRef, 
                      ConstantIfFalse: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSelect".}
proc LLVMConstExtractElement*(VectorConstant: LLVMValueRef, 
                              IndexConstant: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstExtractElement".}
proc LLVMConstInsertElement*(VectorConstant: LLVMValueRef, 
                             ElementValueConstant: LLVMValueRef, 
                             IndexConstant: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstInsertElement".}
proc LLVMConstShuffleVector*(VectorAConstant: LLVMValueRef, 
                             VectorBConstant: LLVMValueRef, 
                             MaskConstant: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstShuffleVector".}
proc LLVMConstExtractValue*(AggConstant: LLVMValueRef, IdxList: pdword, 
                            NumIdx: dword): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstExtractValue".}
proc LLVMConstInsertValue*(AggConstant: LLVMValueRef, 
                           ElementValueConstant: LLVMValueRef, IdxList: pdword, 
                           NumIdx: dword): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstInsertValue".}
proc LLVMConstInlineAsm*(Ty: LLVMTypeRef, AsmString: cstring, 
                         Constraints: cstring, HasSideEffects: int32): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstInlineAsm".}
  # Operations on global variables, functions, and aliases (globals)  
proc LLVMGetGlobalParent*(Global: LLVMValueRef): LLVMModuleRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetGlobalParent".}
proc LLVMIsDeclaration*(Global: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsDeclaration".}
proc LLVMGetLinkage*(Global: LLVMValueRef): LLVMLinkage{.cdecl, dynlib: libname, 
    importc: "LLVMGetLinkage".}
proc LLVMSetLinkage*(Global: LLVMValueRef, Linkage: LLVMLinkage){.cdecl, 
    dynlib: libname, importc: "LLVMSetLinkage".}
proc LLVMGetSection*(Global: LLVMValueRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetSection".}
proc LLVMSetSection*(Global: LLVMValueRef, Section: cstring){.cdecl, 
    dynlib: libname, importc: "LLVMSetSection".}
proc LLVMGetVisibility*(Global: LLVMValueRef): LLVMVisibility{.cdecl, 
    dynlib: libname, importc: "LLVMGetVisibility".}
proc LLVMSetVisibility*(Global: LLVMValueRef, Viz: LLVMVisibility){.cdecl, 
    dynlib: libname, importc: "LLVMSetVisibility".}
proc LLVMGetAlignment*(Global: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMGetAlignment".}
proc LLVMSetAlignment*(Global: LLVMValueRef, Bytes: dword){.cdecl, 
    dynlib: libname, importc: "LLVMSetAlignment".}
  # Operations on global variables  
proc LLVMAddGlobal*(M: LLVMModuleRef, Ty: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMAddGlobal".}
proc LLVMGetNamedGlobal*(M: LLVMModuleRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNamedGlobal".}
proc LLVMGetFirstGlobal*(M: LLVMModuleRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetFirstGlobal".}
proc LLVMGetLastGlobal*(M: LLVMModuleRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastGlobal".}
proc LLVMGetNextGlobal*(GlobalVar: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextGlobal".}
proc LLVMGetPreviousGlobal*(GlobalVar: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetPreviousGlobal".}
proc LLVMDeleteGlobal*(GlobalVar: LLVMValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteGlobal".}
proc LLVMGetInitializer*(GlobalVar: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetInitializer".}
proc LLVMSetInitializer*(GlobalVar: LLVMValueRef, ConstantVal: LLVMValueRef){.
    cdecl, dynlib: libname, importc: "LLVMSetInitializer".}
proc LLVMIsThreadLocal*(GlobalVar: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsThreadLocal".}
proc LLVMSetThreadLocal*(GlobalVar: LLVMValueRef, IsThreadLocal: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetThreadLocal".}
proc LLVMIsGlobalConstant*(GlobalVar: LLVMValueRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMIsGlobalConstant".}
proc LLVMSetGlobalConstant*(GlobalVar: LLVMValueRef, IsConstant: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetGlobalConstant".}
  # Operations on aliases  
proc LLVMAddAlias*(M: LLVMModuleRef, Ty: LLVMTypeRef, Aliasee: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMAddAlias".}
  # Operations on functions  
proc LLVMAddFunction*(M: LLVMModuleRef, Name: cstring, FunctionTy: LLVMTypeRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMAddFunction".}
proc LLVMGetNamedFunction*(M: LLVMModuleRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMGetNamedFunction".}
proc LLVMGetFirstFunction*(M: LLVMModuleRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetFirstFunction".}
proc LLVMGetLastFunction*(M: LLVMModuleRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetLastFunction".}
proc LLVMGetNextFunction*(Fn: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextFunction".}
proc LLVMGetPreviousFunction*(Fn: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetPreviousFunction".}
proc LLVMDeleteFunction*(Fn: LLVMValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteFunction".}
proc LLVMGetIntrinsicID*(Fn: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMGetIntrinsicID".}
proc LLVMGetFunctionCallConv*(Fn: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMGetFunctionCallConv".}
proc LLVMSetFunctionCallConv*(Fn: LLVMValueRef, CC: dword){.cdecl, 
    dynlib: libname, importc: "LLVMSetFunctionCallConv".}
proc LLVMGetGC*(Fn: LLVMValueRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetGC".}
proc LLVMSetGC*(Fn: LLVMValueRef, Name: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetGC".}
proc LLVMAddFunctionAttr*(Fn: LLVMValueRef, PA: LLVMAttribute){.cdecl, 
    dynlib: libname, importc: "LLVMAddFunctionAttr".}
proc LLVMGetFunctionAttr*(Fn: LLVMValueRef): LLVMAttribute{.cdecl, 
    dynlib: libname, importc: "LLVMGetFunctionAttr".}
proc LLVMRemoveFunctionAttr*(Fn: LLVMValueRef, PA: LLVMAttribute){.cdecl, 
    dynlib: libname, importc: "LLVMRemoveFunctionAttr".}
  # Operations on parameters  
proc LLVMCountParams*(Fn: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMCountParams".}
proc LLVMGetParams*(Fn: LLVMValueRef, Params: pLLVMValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMGetParams".}
proc LLVMGetParam*(Fn: LLVMValueRef, Index: dword): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetParam".}
proc LLVMGetParamParent*(Inst: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetParamParent".}
proc LLVMGetFirstParam*(Fn: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstParam".}
proc LLVMGetLastParam*(Fn: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastParam".}
proc LLVMGetNextParam*(Arg: LLVMValueRef): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextParam".}
proc LLVMGetPreviousParam*(Arg: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetPreviousParam".}
proc LLVMAddAttribute*(Arg: LLVMValueRef, PA: LLVMAttribute){.cdecl, 
    dynlib: libname, importc: "LLVMAddAttribute".}
proc LLVMRemoveAttribute*(Arg: LLVMValueRef, PA: LLVMAttribute){.cdecl, 
    dynlib: libname, importc: "LLVMRemoveAttribute".}
proc LLVMGetAttribute*(Arg: LLVMValueRef): LLVMAttribute{.cdecl, 
    dynlib: libname, importc: "LLVMGetAttribute".}
proc LLVMSetParamAlignment*(Arg: LLVMValueRef, align: dword){.cdecl, 
    dynlib: libname, importc: "LLVMSetParamAlignment".}
  # Operations on basic blocks  
proc LLVMBasicBlockAsValue*(BB: LLVMBasicBlockRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBasicBlockAsValue".}
proc LLVMValueIsBasicBlock*(Val: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMValueIsBasicBlock".}
proc LLVMValueAsBasicBlock*(Val: LLVMValueRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMValueAsBasicBlock".}
proc LLVMGetBasicBlockParent*(BB: LLVMBasicBlockRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetBasicBlockParent".}
proc LLVMCountBasicBlocks*(Fn: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMCountBasicBlocks".}
proc LLVMGetBasicBlocks*(Fn: LLVMValueRef, BasicBlocks: pLLVMBasicBlockRef){.
    cdecl, dynlib: libname, importc: "LLVMGetBasicBlocks".}
proc LLVMGetFirstBasicBlock*(Fn: LLVMValueRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetFirstBasicBlock".}
proc LLVMGetLastBasicBlock*(Fn: LLVMValueRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetLastBasicBlock".}
proc LLVMGetNextBasicBlock*(BB: LLVMBasicBlockRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextBasicBlock".}
proc LLVMGetPreviousBasicBlock*(BB: LLVMBasicBlockRef): LLVMBasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMGetPreviousBasicBlock".}
proc LLVMGetEntryBasicBlock*(Fn: LLVMValueRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetEntryBasicBlock".}
proc LLVMAppendBasicBlockInContext*(C: LLVMContextRef, Fn: LLVMValueRef, 
                                    Name: cstring): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMAppendBasicBlockInContext".}
proc LLVMInsertBasicBlockInContext*(C: LLVMContextRef, BB: LLVMBasicBlockRef, 
                                    Name: cstring): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMInsertBasicBlockInContext".}
proc LLVMAppendBasicBlock*(Fn: LLVMValueRef, Name: cstring): LLVMBasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMAppendBasicBlock".}
proc LLVMInsertBasicBlock*(InsertBeforeBB: LLVMBasicBlockRef, Name: cstring): LLVMBasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMInsertBasicBlock".}
proc LLVMDeleteBasicBlock*(BB: LLVMBasicBlockRef){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteBasicBlock".}
  # Operations on instructions  
proc LLVMGetInstructionParent*(Inst: LLVMValueRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetInstructionParent".}
proc LLVMGetFirstInstruction*(BB: LLVMBasicBlockRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetFirstInstruction".}
proc LLVMGetLastInstruction*(BB: LLVMBasicBlockRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetLastInstruction".}
proc LLVMGetNextInstruction*(Inst: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextInstruction".}
proc LLVMGetPreviousInstruction*(Inst: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetPreviousInstruction".}
  # Operations on call sites  
proc LLVMSetInstructionCallConv*(Instr: LLVMValueRef, CC: dword){.cdecl, 
    dynlib: libname, importc: "LLVMSetInstructionCallConv".}
proc LLVMGetInstructionCallConv*(Instr: LLVMValueRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMGetInstructionCallConv".}
proc LLVMAddInstrAttribute*(Instr: LLVMValueRef, index: dword, 
                            para3: LLVMAttribute){.cdecl, dynlib: libname, 
    importc: "LLVMAddInstrAttribute".}
proc LLVMRemoveInstrAttribute*(Instr: LLVMValueRef, index: dword, 
                               para3: LLVMAttribute){.cdecl, dynlib: libname, 
    importc: "LLVMRemoveInstrAttribute".}
proc LLVMSetInstrParamAlignment*(Instr: LLVMValueRef, index: dword, align: dword){.
    cdecl, dynlib: libname, importc: "LLVMSetInstrParamAlignment".}
  # Operations on call instructions (only)  
proc LLVMIsTailCall*(CallInst: LLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsTailCall".}
proc LLVMSetTailCall*(CallInst: LLVMValueRef, IsTailCall: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetTailCall".}
  # Operations on phi nodes  
proc LLVMAddIncoming*(PhiNode: LLVMValueRef, IncomingValues: pLLVMValueRef, 
                      IncomingBlocks: pLLVMBasicBlockRef, Count: dword){.cdecl, 
    dynlib: libname, importc: "LLVMAddIncoming".}
proc LLVMCountIncoming*(PhiNode: LLVMValueRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMCountIncoming".}
proc LLVMGetIncomingValue*(PhiNode: LLVMValueRef, Index: dword): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMGetIncomingValue".}
proc LLVMGetIncomingBlock*(PhiNode: LLVMValueRef, Index: dword): LLVMBasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMGetIncomingBlock".}
  #===-- Instruction builders ----------------------------------------------=== 
  # An instruction builder represents a point within a basic block, and is the
  # * exclusive means of building instructions using the C interface.
  #  
proc LLVMCreateBuilderInContext*(C: LLVMContextRef): LLVMBuilderRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateBuilderInContext".}
proc LLVMCreateBuilder*(): LLVMBuilderRef{.cdecl, dynlib: libname, 
    importc: "LLVMCreateBuilder".}
proc LLVMPositionBuilder*(Builder: LLVMBuilderRef, theBlock: LLVMBasicBlockRef, 
                          Instr: LLVMValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMPositionBuilder".}
proc LLVMPositionBuilderBefore*(Builder: LLVMBuilderRef, Instr: LLVMValueRef){.
    cdecl, dynlib: libname, importc: "LLVMPositionBuilderBefore".}
proc LLVMPositionBuilderAtEnd*(Builder: LLVMBuilderRef, theBlock: LLVMBasicBlockRef){.
    cdecl, dynlib: libname, importc: "LLVMPositionBuilderAtEnd".}
proc LLVMGetInsertBlock*(Builder: LLVMBuilderRef): LLVMBasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetInsertBlock".}
proc LLVMClearInsertionPosition*(Builder: LLVMBuilderRef){.cdecl, 
    dynlib: libname, importc: "LLVMClearInsertionPosition".}
proc LLVMInsertIntoBuilder*(Builder: LLVMBuilderRef, Instr: LLVMValueRef){.
    cdecl, dynlib: libname, importc: "LLVMInsertIntoBuilder".}
proc LLVMInsertIntoBuilderWithName*(Builder: LLVMBuilderRef, 
                                    Instr: LLVMValueRef, Name: cstring){.cdecl, 
    dynlib: libname, importc: "LLVMInsertIntoBuilderWithName".}
proc LLVMDisposeBuilder*(Builder: LLVMBuilderRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeBuilder".}
  # Terminators  
proc LLVMBuildRetVoid*(para1: LLVMBuilderRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildRetVoid".}
proc LLVMBuildRet*(para1: LLVMBuilderRef, V: LLVMValueRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildRet".}
proc LLVMBuildAggregateRet*(para1: LLVMBuilderRef, RetVals: pLLVMValueRef, 
                            N: dword): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildAggregateRet".}
proc LLVMBuildBr*(para1: LLVMBuilderRef, Dest: LLVMBasicBlockRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildBr".}
proc LLVMBuildCondBr*(para1: LLVMBuilderRef, Cond: LLVMValueRef, 
                      ThenBranch: LLVMBasicBlockRef, 
                      ElseBranch: LLVMBasicBlockRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildCondBr".}
proc LLVMBuildSwitch*(para1: LLVMBuilderRef, V: LLVMValueRef, 
                      ElseBranch: LLVMBasicBlockRef, NumCases: dword): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSwitch".}
proc LLVMBuildInvoke*(para1: LLVMBuilderRef, Fn: LLVMValueRef, 
                      Args: pLLVMValueRef, NumArgs: dword, 
                      ThenBranch: LLVMBasicBlockRef, Catch: LLVMBasicBlockRef, 
                      Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildInvoke".}
proc LLVMBuildUnwind*(para1: LLVMBuilderRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildUnwind".}
proc LLVMBuildUnreachable*(para1: LLVMBuilderRef): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildUnreachable".}
  # Add a case to the switch instruction  
proc LLVMAddCase*(Switch: LLVMValueRef, OnVal: LLVMValueRef, 
                  Dest: LLVMBasicBlockRef){.cdecl, dynlib: libname, 
    importc: "LLVMAddCase".}
  # Arithmetic  
proc LLVMBuildAdd*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildAdd".}
proc LLVMBuildNSWAdd*(para1: LLVMBuilderRef, LHS: LLVMValueRef, 
                      RHS: LLVMValueRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildNSWAdd".}
proc LLVMBuildFAdd*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFAdd".}
proc LLVMBuildSub*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSub".}
proc LLVMBuildFSub*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFSub".}
proc LLVMBuildMul*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildMul".}
proc LLVMBuildFMul*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFMul".}
proc LLVMBuildUDiv*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildUDiv".}
proc LLVMBuildSDiv*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSDiv".}
proc LLVMBuildExactSDiv*(para1: LLVMBuilderRef, LHS: LLVMValueRef, 
                         RHS: LLVMValueRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildExactSDiv".}
proc LLVMBuildFDiv*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFDiv".}
proc LLVMBuildURem*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildURem".}
proc LLVMBuildSRem*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSRem".}
proc LLVMBuildFRem*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFRem".}
proc LLVMBuildShl*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildShl".}
proc LLVMBuildLShr*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildLShr".}
proc LLVMBuildAShr*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildAShr".}
proc LLVMBuildAnd*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildAnd".}
proc LLVMBuildOr*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                  Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildOr".}
proc LLVMBuildXor*(para1: LLVMBuilderRef, LHS: LLVMValueRef, RHS: LLVMValueRef, 
                   Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildXor".}
proc LLVMBuildNeg*(para1: LLVMBuilderRef, V: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildNeg".}
proc LLVMBuildFNeg*(para1: LLVMBuilderRef, V: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFNeg".}
proc LLVMBuildNot*(para1: LLVMBuilderRef, V: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildNot".}
  # Memory  
proc LLVMBuildMalloc*(para1: LLVMBuilderRef, Ty: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildMalloc".}
proc LLVMBuildArrayMalloc*(para1: LLVMBuilderRef, Ty: LLVMTypeRef, 
                           Val: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildArrayMalloc".}
proc LLVMBuildAlloca*(para1: LLVMBuilderRef, Ty: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAlloca".}
proc LLVMBuildArrayAlloca*(para1: LLVMBuilderRef, Ty: LLVMTypeRef, 
                           Val: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildArrayAlloca".}
proc LLVMBuildFree*(para1: LLVMBuilderRef, PointerVal: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFree".}
proc LLVMBuildLoad*(para1: LLVMBuilderRef, PointerVal: LLVMValueRef, 
                    Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildLoad".}
proc LLVMBuildStore*(para1: LLVMBuilderRef, Val: LLVMValueRef,
                     thePtr: LLVMValueRef): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildStore".}
proc LLVMBuildGEP*(B: LLVMBuilderRef, Pointer: LLVMValueRef, 
                   Indices: pLLVMValueRef, NumIndices: dword, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildGEP".}
proc LLVMBuildInBoundsGEP*(B: LLVMBuilderRef, Pointer: LLVMValueRef, 
                           Indices: pLLVMValueRef, NumIndices: dword, 
                           Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildInBoundsGEP".}
proc LLVMBuildStructGEP*(B: LLVMBuilderRef, Pointer: LLVMValueRef, Idx: dword, 
                         Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildStructGEP".}
proc LLVMBuildGlobalString*(B: LLVMBuilderRef, Str: cstring, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildGlobalString".}
proc LLVMBuildGlobalStringPtr*(B: LLVMBuilderRef, Str: cstring, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildGlobalStringPtr".}
  # Casts  
proc LLVMBuildTrunc*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                     DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildTrunc".}
proc LLVMBuildZExt*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                    DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildZExt".}
proc LLVMBuildSExt*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                    DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildSExt".}
proc LLVMBuildFPToUI*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                      DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFPToUI".}
proc LLVMBuildFPToSI*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                      DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFPToSI".}
proc LLVMBuildUIToFP*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                      DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildUIToFP".}
proc LLVMBuildSIToFP*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                      DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildSIToFP".}
proc LLVMBuildFPTrunc*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                       DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFPTrunc".}
proc LLVMBuildFPExt*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                     DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFPExt".}
proc LLVMBuildPtrToInt*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                        DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildPtrToInt".}
proc LLVMBuildIntToPtr*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                        DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildIntToPtr".}
proc LLVMBuildBitCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                       DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildBitCast".}
proc LLVMBuildZExtOrBitCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                             DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildZExtOrBitCast".}
proc LLVMBuildSExtOrBitCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                             DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSExtOrBitCast".}
proc LLVMBuildTruncOrBitCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                              DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildTruncOrBitCast".}
proc LLVMBuildPointerCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                           DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildPointerCast".}
proc LLVMBuildIntCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                       DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildIntCast".}
proc LLVMBuildFPCast*(para1: LLVMBuilderRef, Val: LLVMValueRef, 
                      DestTy: LLVMTypeRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFPCast".}
  # Comparisons  
proc LLVMBuildICmp*(para1: LLVMBuilderRef, Op: LLVMIntPredicate, 
                    LHS: LLVMValueRef, RHS: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildICmp".}
proc LLVMBuildFCmp*(para1: LLVMBuilderRef, Op: LLVMRealPredicate, 
                    LHS: LLVMValueRef, RHS: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFCmp".}
  # Miscellaneous instructions  
proc LLVMBuildPhi*(para1: LLVMBuilderRef, Ty: LLVMTypeRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildPhi".}
proc LLVMBuildCall*(para1: LLVMBuilderRef, Fn: LLVMValueRef, 
                    Args: pLLVMValueRef, NumArgs: dword, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildCall".}
proc LLVMBuildSelect*(para1: LLVMBuilderRef, Cond: LLVMValueRef, 
                      ThenBranch: LLVMValueRef, ElseBranch: LLVMValueRef, 
                      Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSelect".}
proc LLVMBuildVAArg*(para1: LLVMBuilderRef, List: LLVMValueRef, Ty: LLVMTypeRef, 
                     Name: cstring): LLVMValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildVAArg".}
proc LLVMBuildExtractElement*(para1: LLVMBuilderRef, VecVal: LLVMValueRef, 
                              Index: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildExtractElement".}
proc LLVMBuildInsertElement*(para1: LLVMBuilderRef, VecVal: LLVMValueRef, 
                             EltVal: LLVMValueRef, Index: LLVMValueRef, 
                             Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildInsertElement".}
proc LLVMBuildShuffleVector*(para1: LLVMBuilderRef, V1: LLVMValueRef, 
                             V2: LLVMValueRef, Mask: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildShuffleVector".}
proc LLVMBuildExtractValue*(para1: LLVMBuilderRef, AggVal: LLVMValueRef, 
                            Index: dword, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildExtractValue".}
proc LLVMBuildInsertValue*(para1: LLVMBuilderRef, AggVal: LLVMValueRef, 
                           EltVal: LLVMValueRef, Index: dword, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildInsertValue".}
proc LLVMBuildIsNull*(para1: LLVMBuilderRef, Val: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildIsNull".}
proc LLVMBuildIsNotNull*(para1: LLVMBuilderRef, Val: LLVMValueRef, Name: cstring): LLVMValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildIsNotNull".}
proc LLVMBuildPtrDiff*(para1: LLVMBuilderRef, LHS: LLVMValueRef, 
                       RHS: LLVMValueRef, Name: cstring): LLVMValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildPtrDiff".}
  #===-- Module providers --------------------------------------------------=== 
  # Encapsulates the module M in a module provider, taking ownership of the
  # * module.
  # * See the constructor llvm::ExistingModuleProvider::ExistingModuleProvider.
  #  
proc LLVMCreateModuleProviderForExistingModule*(M: LLVMModuleRef): LLVMModuleProviderRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateModuleProviderForExistingModule".}
  # Destroys the module provider MP as well as the contained module.
  # * See the destructor llvm::ModuleProvider::~ModuleProvider.
  #  
proc LLVMDisposeModuleProvider*(MP: LLVMModuleProviderRef){.cdecl, 
    dynlib: libname, importc: "LLVMDisposeModuleProvider".}
  #===-- Memory buffers ----------------------------------------------------=== 
proc LLVMCreateMemoryBufferWithContentsOfFile*(Path: cstring, 
    OutMemBuf: pLLVMMemoryBufferRef, OutMessage: Ppchar): int32{.cdecl, 
    dynlib: libname, importc: "LLVMCreateMemoryBufferWithContentsOfFile".}
proc LLVMCreateMemoryBufferWithSTDIN*(OutMemBuf: pLLVMMemoryBufferRef, 
                                      OutMessage: Ppchar): int32{.cdecl, 
    dynlib: libname, importc: "LLVMCreateMemoryBufferWithSTDIN".}
proc LLVMDisposeMemoryBuffer*(MemBuf: LLVMMemoryBufferRef){.cdecl, 
    dynlib: libname, importc: "LLVMDisposeMemoryBuffer".}
  #===-- Pass Managers -----------------------------------------------------=== 
  #* Constructs a new whole-module pass pipeline. This type of pipeline is
  #    suitable for link-time optimization and whole-module transformations.
  #    See llvm::PassManager::PassManager.  
proc LLVMCreatePassManager*(): LLVMPassManagerRef{.cdecl, dynlib: libname, 
    importc: "LLVMCreatePassManager".}
  #* Constructs a new function-by-function pass pipeline over the module
  #    provider. It does not take ownership of the module provider. This type of
  #    pipeline is suitable for code generation and JIT compilation tasks.
  #    See llvm::FunctionPassManager::FunctionPassManager.  
proc LLVMCreateFunctionPassManager*(MP: LLVMModuleProviderRef): LLVMPassManagerRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateFunctionPassManager".}
  #* Initializes, executes on the provided module, and finalizes all of the
  #    passes scheduled in the pass manager. Returns 1 if any of the passes
  #    modified the module, 0 otherwise. See llvm::PassManager::run(Module&).  
proc LLVMRunPassManager*(PM: LLVMPassManagerRef, M: LLVMModuleRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMRunPassManager".}
  #* Initializes all of the function passes scheduled in the function pass
  #    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
  #    See llvm::FunctionPassManager::doInitialization.  
proc LLVMInitializeFunctionPassManager*(FPM: LLVMPassManagerRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMInitializeFunctionPassManager".}
  #* Executes all of the function passes scheduled in the function pass manager
  #    on the provided function. Returns 1 if any of the passes modified the
  #    function, false otherwise.
  #    See llvm::FunctionPassManager::run(Function&).  
proc LLVMRunFunctionPassManager*(FPM: LLVMPassManagerRef, F: LLVMValueRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMRunFunctionPassManager".}
  #* Finalizes all of the function passes scheduled in in the function pass
  #    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
  #    See llvm::FunctionPassManager::doFinalization.  
proc LLVMFinalizeFunctionPassManager*(FPM: LLVMPassManagerRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMFinalizeFunctionPassManager".}
  #* Frees the memory of a pass pipeline. For function pipelines, does not free
  #    the module provider.
  #    See llvm::PassManagerBase::~PassManagerBase.  
proc LLVMDisposePassManager*(PM: LLVMPassManagerRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposePassManager".}
  # Analysis.h  
  # verifier will print to stderr and abort()  
  # verifier will print to stderr and return 1  
  # verifier will just return 1  
type 
  LLVMVerifierFailureAction* = enum  # Verifies that a module is valid, taking the specified action if not.
                                     #   Optionally returns a human-readable description of any invalid constructs.
                                     #   OutMessage must be disposed with LLVMDisposeMessage.  
    LLVMAbortProcessAction, LLVMPrintMessageAction, LLVMReturnStatusAction

proc LLVMVerifyModule*(M: LLVMModuleRef, Action: LLVMVerifierFailureAction, 
                       OutMessage: Ppchar): int32{.cdecl, dynlib: libname, 
    importc: "LLVMVerifyModule".}
  # Verifies that a single function is valid, taking the specified action. Useful
  #   for debugging.  
proc LLVMVerifyFunction*(Fn: LLVMValueRef, Action: LLVMVerifierFailureAction): int32{.
    cdecl, dynlib: libname, importc: "LLVMVerifyFunction".}
  # Open up a ghostview window that displays the CFG of the current function.
  #   Useful for debugging.  
proc LLVMViewFunctionCFG*(Fn: LLVMValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMViewFunctionCFG".}
proc LLVMViewFunctionCFGOnly*(Fn: LLVMValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMViewFunctionCFGOnly".}
  # BitReader.h  
  # Builds a module from the bitcode in the specified memory buffer, returning a
  #   reference to the module via the OutModule parameter. Returns 0 on success.
  #   Optionally returns a human-readable error message via OutMessage.  
proc LLVMParseBitcode*(MemBuf: LLVMMemoryBufferRef, OutModule: pLLVMModuleRef, 
                       OutMessage: Ppchar): int32{.cdecl, dynlib: libname, 
    importc: "LLVMParseBitcode".}
proc LLVMParseBitcodeInContext*(ContextRef: LLVMContextRef, 
                                MemBuf: LLVMMemoryBufferRef, 
                                OutModule: pLLVMModuleRef, OutMessage: Ppchar): int32{.
    cdecl, dynlib: libname, importc: "LLVMParseBitcodeInContext".}
  # Reads a module from the specified path, returning via the OutMP parameter
  #   a module provider which performs lazy deserialization. Returns 0 on success.
  #   Optionally returns a human-readable error message via OutMessage.  
proc LLVMGetBitcodeModuleProvider*(MemBuf: LLVMMemoryBufferRef, 
                                   OutMP: pLLVMModuleProviderRef, 
                                   OutMessage: Ppchar): int32{.cdecl, 
    dynlib: libname, importc: "LLVMGetBitcodeModuleProvider".}
proc LLVMGetBitcodeModuleProviderInContext*(ContextRef: LLVMContextRef, 
    MemBuf: LLVMMemoryBufferRef, OutMP: pLLVMModuleProviderRef, 
    OutMessage: Ppchar): int32{.cdecl, dynlib: libname, importc: "LLVMGetBitcodeModuleProviderInContext".}
  # BitWriter.h  
  #===-- Operations on modules ---------------------------------------------=== 
  # Writes a module to an open file descriptor. Returns 0 on success.
  #   Closes the Handle. Use dup first if this is not what you want.  
proc LLVMWriteBitcodeToFileHandle*(M: LLVMModuleRef, Handle: int32): int32{.
    cdecl, dynlib: libname, importc: "LLVMWriteBitcodeToFileHandle".}
  # Writes a module to the specified path. Returns 0 on success.  
proc LLVMWriteBitcodeToFile*(M: LLVMModuleRef, Path: cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMWriteBitcodeToFile".}
  # Target.h  
const 
  LLVMBigEndian* = 0
  LLVMLittleEndian* = 1

type 
  LLVMByteOrdering* = int32
  LLVMTargetDataRef* = LLVMOpaqueTargetData
  LLVMStructLayoutRef* = LLVMStructLayout #===-- Target Data -------------------------------------------------------=== 
                                          #* Creates target data from a target layout string.
                                          #    See the constructor llvm::TargetData::TargetData.  

proc LLVMCreateTargetData*(StringRep: cstring): LLVMTargetDataRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateTargetData".}
  #* Adds target data information to a pass manager. This does not take ownership
  #    of the target data.
  #    See the method llvm::PassManagerBase::add.  
proc LLVMAddTargetData*(para1: LLVMTargetDataRef, para2: LLVMPassManagerRef){.
    cdecl, dynlib: libname, importc: "LLVMAddTargetData".}
  #* Converts target data to a target layout string. The string must be disposed
  #    with LLVMDisposeMessage.
  #    See the constructor llvm::TargetData::TargetData.  
proc LLVMCopyStringRepOfTargetData*(para1: LLVMTargetDataRef): cstring{.cdecl, 
    dynlib: libname, importc: "LLVMCopyStringRepOfTargetData".}
  #* Returns the byte order of a target, either LLVMBigEndian or
  #    LLVMLittleEndian.
  #    See the method llvm::TargetData::isLittleEndian.  
proc LLVMByteOrder*(para1: LLVMTargetDataRef): LLVMByteOrdering{.cdecl, 
    dynlib: libname, importc: "LLVMByteOrder".}
  #* Returns the pointer size in bytes for a target.
  #    See the method llvm::TargetData::getPointerSize.  
proc LLVMPointerSize*(para1: LLVMTargetDataRef): dword{.cdecl, dynlib: libname, 
    importc: "LLVMPointerSize".}
  #* Returns the integer type that is the same size as a pointer on a target.
  #    See the method llvm::TargetData::getIntPtrType.  
proc LLVMIntPtrType*(para1: LLVMTargetDataRef): LLVMTypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMIntPtrType".}
  #* Computes the size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeSizeInBits.  
proc LLVMSizeOfTypeInBits*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): qword{.
    cdecl, dynlib: libname, importc: "LLVMSizeOfTypeInBits".}
  #* Computes the storage size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeStoreSize.  
proc LLVMStoreSizeOfType*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): qword{.
    cdecl, dynlib: libname, importc: "LLVMStoreSizeOfType".}
  #* Computes the ABI size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeAllocSize.  
proc LLVMABISizeOfType*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): qword{.
    cdecl, dynlib: libname, importc: "LLVMABISizeOfType".}
  #* Computes the ABI alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc LLVMABIAlignmentOfType*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): dword{.
    cdecl, dynlib: libname, importc: "LLVMABIAlignmentOfType".}
  #* Computes the call frame alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc LLVMCallFrameAlignmentOfType*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): dword{.
    cdecl, dynlib: libname, importc: "LLVMCallFrameAlignmentOfType".}
  #* Computes the preferred alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc LLVMPreferredAlignmentOfType*(para1: LLVMTargetDataRef, para2: LLVMTypeRef): dword{.
    cdecl, dynlib: libname, importc: "LLVMPreferredAlignmentOfType".}
  #* Computes the preferred alignment of a global variable in bytes for a target.
  #    See the method llvm::TargetData::getPreferredAlignment.  
proc LLVMPreferredAlignmentOfGlobal*(para1: LLVMTargetDataRef, 
                                     GlobalVar: LLVMValueRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMPreferredAlignmentOfGlobal".}
  #* Computes the structure element that contains the byte offset for a target.
  #    See the method llvm::StructLayout::getElementContainingOffset.  
proc LLVMElementAtOffset*(para1: LLVMTargetDataRef, StructTy: LLVMTypeRef, 
                          Offset: qword): dword{.cdecl, dynlib: libname, 
    importc: "LLVMElementAtOffset".}
  #* Computes the byte offset of the indexed struct element for a target.
  #    See the method llvm::StructLayout::getElementContainingOffset.  
proc LLVMOffsetOfElement*(para1: LLVMTargetDataRef, StructTy: LLVMTypeRef, 
                          Element: dword): qword{.cdecl, dynlib: libname, 
    importc: "LLVMOffsetOfElement".}
  #* Struct layouts are speculatively cached. If a TargetDataRef is alive when
  #    types are being refined and removed, this method must be called whenever a
  #    struct type is removed to avoid a dangling pointer in this cache.
  #    See the method llvm::TargetData::InvalidateStructLayoutInfo.  
proc LLVMInvalidateStructLayout*(para1: LLVMTargetDataRef, StructTy: LLVMTypeRef){.
    cdecl, dynlib: libname, importc: "LLVMInvalidateStructLayout".}
  #* Deallocates a TargetData.
  #    See the destructor llvm::TargetData::~TargetData.  
proc LLVMDisposeTargetData*(para1: LLVMTargetDataRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeTargetData".}
  # ExecutionEngine.h  
proc LLVMLinkInJIT*(){.cdecl, dynlib: libname, importc: "LLVMLinkInJIT".}
proc LLVMLinkInInterpreter*(){.cdecl, dynlib: libname, 
                               importc: "LLVMLinkInInterpreter".}
type 
  LLVMGenericValueRef* = LLVMOpaqueGenericValue
  LLVMExecutionEngineRef* = LLVMOpaqueExecutionEngine #===-- Operations on generic values --------------------------------------=== 

proc LLVMCreateGenericValueOfInt*(Ty: LLVMTypeRef, N: qword, IsSigned: int32): LLVMGenericValueRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateGenericValueOfInt".}
proc LLVMCreateGenericValueOfPointer*(P: pointer): LLVMGenericValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateGenericValueOfPointer".}
proc LLVMCreateGenericValueOfFloat*(Ty: LLVMTypeRef, N: float64): LLVMGenericValueRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateGenericValueOfFloat".}
proc LLVMGenericValueIntWidth*(GenValRef: LLVMGenericValueRef): dword{.cdecl, 
    dynlib: libname, importc: "LLVMGenericValueIntWidth".}
proc LLVMGenericValueToInt*(GenVal: LLVMGenericValueRef, IsSigned: int32): qword{.
    cdecl, dynlib: libname, importc: "LLVMGenericValueToInt".}
proc LLVMGenericValueToPointer*(GenVal: LLVMGenericValueRef): pointer{.cdecl, 
    dynlib: libname, importc: "LLVMGenericValueToPointer".}
proc LLVMGenericValueToFloat*(TyRef: LLVMTypeRef, GenVal: LLVMGenericValueRef): float64{.
    cdecl, dynlib: libname, importc: "LLVMGenericValueToFloat".}
proc LLVMDisposeGenericValue*(GenVal: LLVMGenericValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMDisposeGenericValue".}
  #===-- Operations on execution engines -----------------------------------=== 
proc LLVMCreateExecutionEngine*(OutEE: pLLVMExecutionEngineRef, 
                                MP: LLVMModuleProviderRef, OutError: Ppchar): int32{.
    cdecl, dynlib: libname, importc: "LLVMCreateExecutionEngine".}
proc LLVMCreateInterpreter*(OutInterp: pLLVMExecutionEngineRef, 
                            MP: LLVMModuleProviderRef, OutError: Ppchar): int32{.
    cdecl, dynlib: libname, importc: "LLVMCreateInterpreter".}
proc LLVMCreateJITCompiler*(OutJIT: pLLVMExecutionEngineRef, 
                            MP: LLVMModuleProviderRef, OptLevel: dword, 
                            OutError: Ppchar): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCreateJITCompiler".}
proc LLVMDisposeExecutionEngine*(EE: LLVMExecutionEngineRef){.cdecl, 
    dynlib: libname, importc: "LLVMDisposeExecutionEngine".}
proc LLVMRunStaticConstructors*(EE: LLVMExecutionEngineRef){.cdecl, 
    dynlib: libname, importc: "LLVMRunStaticConstructors".}
proc LLVMRunStaticDestructors*(EE: LLVMExecutionEngineRef){.cdecl, 
    dynlib: libname, importc: "LLVMRunStaticDestructors".}
  # Const before declarator ignored 
  # Const before declarator ignored 
proc LLVMRunFunctionAsMain*(EE: LLVMExecutionEngineRef, F: LLVMValueRef, 
                            ArgC: dword, ArgV: Ppchar, EnvP: Ppchar): int32{.
    cdecl, dynlib: libname, importc: "LLVMRunFunctionAsMain".}
proc LLVMRunFunction*(EE: LLVMExecutionEngineRef, F: LLVMValueRef, 
                      NumArgs: dword, Args: pLLVMGenericValueRef): LLVMGenericValueRef{.
    cdecl, dynlib: libname, importc: "LLVMRunFunction".}
proc LLVMFreeMachineCodeForFunction*(EE: LLVMExecutionEngineRef, F: LLVMValueRef){.
    cdecl, dynlib: libname, importc: "LLVMFreeMachineCodeForFunction".}
proc LLVMAddModuleProvider*(EE: LLVMExecutionEngineRef, 
                            MP: LLVMModuleProviderRef){.cdecl, dynlib: libname, 
    importc: "LLVMAddModuleProvider".}
proc LLVMRemoveModuleProvider*(EE: LLVMExecutionEngineRef, 
                               MP: LLVMModuleProviderRef, 
                               OutMod: pLLVMModuleRef, OutError: Ppchar): int32{.
    cdecl, dynlib: libname, importc: "LLVMRemoveModuleProvider".}
proc LLVMFindFunction*(EE: LLVMExecutionEngineRef, Name: cstring, 
                       OutFn: pLLVMValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMFindFunction".}
proc LLVMGetExecutionEngineTargetData*(EE: LLVMExecutionEngineRef): LLVMTargetDataRef{.
    cdecl, dynlib: libname, importc: "LLVMGetExecutionEngineTargetData".}
proc LLVMAddGlobalMapping*(EE: LLVMExecutionEngineRef, Global: LLVMValueRef, 
                           theAddr: pointer){.cdecl, dynlib: libname, 
    importc: "LLVMAddGlobalMapping".}
proc LLVMGetPointerToGlobal*(EE: LLVMExecutionEngineRef, Global: LLVMValueRef): pointer{.
    cdecl, dynlib: libname, importc: "LLVMGetPointerToGlobal".}
  # LinkTimeOptimizer.h  
  #/ This provides a dummy type for pointers to the LTO object. 
type 
  llvm_lto_t* = pointer #/ This provides a C-visible enumerator to manage status codes. 
                        #/ This should map exactly onto the C++ enumerator LTOStatus. 
                        #  Added C-specific error codes 
  llvm_lto_status* = enum 
    LLVM_LTO_UNKNOWN, LLVM_LTO_OPT_SUCCESS, LLVM_LTO_READ_SUCCESS, 
    LLVM_LTO_READ_FAILURE, LLVM_LTO_WRITE_FAILURE, LLVM_LTO_NO_TARGET, 
    LLVM_LTO_NO_WORK, LLVM_LTO_MODULE_MERGE_FAILURE, LLVM_LTO_ASM_FAILURE, 
    LLVM_LTO_NULL_OBJECT
  llvm_lto_status_t* = llvm_lto_status #/ This provides C interface to initialize link time optimizer. This allows 
                                       #/ linker to use dlopen() interface to dynamically load LinkTimeOptimizer. 
                                       #/ extern "C" helps, because dlopen() interface uses name to find the symbol. 

proc llvm_create_optimizer*(): llvm_lto_t{.cdecl, dynlib: libname, 
    importc: "llvm_create_optimizer".}
proc llvm_destroy_optimizer*(lto: llvm_lto_t){.cdecl, dynlib: libname, 
    importc: "llvm_destroy_optimizer".}
proc llvm_read_object_file*(lto: llvm_lto_t, input_filename: cstring): llvm_lto_status_t{.
    cdecl, dynlib: libname, importc: "llvm_read_object_file".}
proc llvm_optimize_modules*(lto: llvm_lto_t, output_filename: cstring): llvm_lto_status_t{.
    cdecl, dynlib: libname, importc: "llvm_optimize_modules".}
  # lto.h  
const 
  LTO_API_VERSION* = 3        # log2 of alignment  

type 
  lto_symbol_attributes* = enum 
    LTO_SYMBOL_ALIGNMENT_MASK = 0x0000001F, 
    LTO_SYMBOL_PERMISSIONS_MASK = 0x000000E0, 
    LTO_SYMBOL_PERMISSIONS_CODE = 0x000000A0, 
    LTO_SYMBOL_PERMISSIONS_DATA = 0x000000C0, 
    LTO_SYMBOL_PERMISSIONS_RODATA = 0x00000080, 
    LTO_SYMBOL_DEFINITION_MASK = 0x00000700, 
    LTO_SYMBOL_DEFINITION_REGULAR = 0x00000100, 
    LTO_SYMBOL_DEFINITION_TENTATIVE = 0x00000200, 
    LTO_SYMBOL_DEFINITION_WEAK = 0x00000300, 
    LTO_SYMBOL_DEFINITION_UNDEFINED = 0x00000400, 
    LTO_SYMBOL_DEFINITION_WEAKUNDEF = 0x00000500, 
    LTO_SYMBOL_SCOPE_MASK = 0x00003800, LTO_SYMBOL_SCOPE_INTERNAL = 0x00000800, 
    LTO_SYMBOL_SCOPE_HIDDEN = 0x00001000, 
    LTO_SYMBOL_SCOPE_PROTECTED = 0x00002000, 
    LTO_SYMBOL_SCOPE_DEFAULT = 0x00001800
  lto_debug_model* = enum 
    LTO_DEBUG_MODEL_NONE = 0, LTO_DEBUG_MODEL_DWARF = 1
  lto_codegen_model* = enum   #* opaque reference to a loaded object module  
    LTO_CODEGEN_PIC_MODEL_STATIC = 0, LTO_CODEGEN_PIC_MODEL_DYNAMIC = 1, 
    LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2
  lto_module_t* = LTOModule   #* opaque reference to a code generator  
  lto_code_gen_t* = LTOCodeGenerator #*
                                     # * Returns a printable string.
                                     #  

proc lto_get_version*(): cstring{.cdecl, dynlib: libname, 
                                  importc: "lto_get_version".}
  #*
  # * Returns the last error string or NULL if last operation was sucessful.
  #  
proc lto_get_error_message*(): cstring{.cdecl, dynlib: libname, 
                                        importc: "lto_get_error_message".}
  #*
  # * Checks if a file is a loadable object file.
  #  
proc lto_module_is_object_file*(path: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file".}
  #*
  # * Checks if a file is a loadable object compiled for requested target.
  #  
proc lto_module_is_object_file_for_target*(path: cstring, 
    target_triple_prefix: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file_for_target".}
  #*
  # * Checks if a buffer is a loadable object file.
  #  
proc lto_module_is_object_file_in_memory*(mem: pointer, len: size_t): bool{.
    cdecl, dynlib: libname, importc: "lto_module_is_object_file_in_memory".}
  #*
  # * Checks if a buffer is a loadable object compiled for requested target.
  #  
proc lto_module_is_object_file_in_memory_for_target*(mem: pointer, len: size_t, 
    target_triple_prefix: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file_in_memory_for_target".}
  #*
  # * Loads an object file from disk.
  # * Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_module_create*(path: cstring): lto_module_t{.cdecl, dynlib: libname, 
    importc: "lto_module_create".}
  #*
  # * Loads an object file from memory.
  # * Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_module_create_from_memory*(mem: pointer, len: size_t): lto_module_t{.
    cdecl, dynlib: libname, importc: "lto_module_create_from_memory".}
  #*
  # * Frees all memory internally allocated by the module.
  # * Upon return the lto_module_t is no longer valid.
  #  
proc lto_module_dispose*(module: lto_module_t){.cdecl, dynlib: libname, 
    importc: "lto_module_dispose".}
  #*
  # * Returns triple string which the object module was compiled under.
  #  
proc lto_module_get_target_triple*(module: lto_module_t): cstring{.cdecl, 
    dynlib: libname, importc: "lto_module_get_target_triple".}
  #*
  # * Returns the number of symbols in the object module.
  #  
proc lto_module_get_num_symbols*(module: lto_module_t): dword{.cdecl, 
    dynlib: libname, importc: "lto_module_get_num_symbols".}
  #*
  # * Returns the name of the ith symbol in the object module.
  #  
proc lto_module_get_symbol_name*(module: lto_module_t, index: dword): cstring{.
    cdecl, dynlib: libname, importc: "lto_module_get_symbol_name".}
  #*
  # * Returns the attributes of the ith symbol in the object module.
  #  
proc lto_module_get_symbol_attribute*(module: lto_module_t, index: dword): lto_symbol_attributes{.
    cdecl, dynlib: libname, importc: "lto_module_get_symbol_attribute".}
  #*
  # * Instantiates a code generator.
  # * Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_create*(): lto_code_gen_t{.cdecl, dynlib: libname, 
    importc: "lto_codegen_create".}
  #*
  # * Frees all code generator and all memory it internally allocated.
  # * Upon return the lto_code_gen_t is no longer valid.
  #  
proc lto_codegen_dispose*(para1: lto_code_gen_t){.cdecl, dynlib: libname, 
    importc: "lto_codegen_dispose".}
  #*
  # * Add an object module to the set of modules for which code will be generated.
  # * Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_add_module*(cg: lto_code_gen_t, module: lto_module_t): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_add_module".}
  #*
  # * Sets if debug info should be generated.
  # * Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_set_debug_model*(cg: lto_code_gen_t, para2: lto_debug_model): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_set_debug_model".}
  #*
  # * Sets which PIC code model to generated.
  # * Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_set_pic_model*(cg: lto_code_gen_t, para2: lto_codegen_model): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_set_pic_model".}
  #*
  # * Sets the location of the "gcc" to run. If not set, libLTO will search for
  # * "gcc" on the path.
  #  
proc lto_codegen_set_gcc_path*(cg: lto_code_gen_t, path: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_set_gcc_path".}
  #*
  # * Sets the location of the assembler tool to run. If not set, libLTO
  # * will use gcc to invoke the assembler.
  #  
proc lto_codegen_set_assembler_path*(cg: lto_code_gen_t, path: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_set_assembler_path".}
  #*
  # * Adds to a list of all global symbols that must exist in the final
  # * generated code.  If a function is not listed, it might be
  # * inlined into every usage and optimized away.
  #  
proc lto_codegen_add_must_preserve_symbol*(cg: lto_code_gen_t, symbol: cstring){.
    cdecl, dynlib: libname, importc: "lto_codegen_add_must_preserve_symbol".}
  #*
  # * Writes a new object file at the specified path that contains the
  # * merged contents of all modules added so far.
  # * Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_write_merged_modules*(cg: lto_code_gen_t, path: cstring): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_write_merged_modules".}
  #*
  # * Generates code for all added modules into one native object file.
  # * On sucess returns a pointer to a generated mach-o/ELF buffer and
  # * length set to the buffer size.  The buffer is owned by the 
  # * lto_code_gen_t and will be freed when lto_codegen_dispose()
  # * is called, or lto_codegen_compile() is called again.
  # * On failure, returns NULL (check lto_get_error_message() for details).
  #  
proc lto_codegen_compile*(cg: lto_code_gen_t, len: var int): pointer{.cdecl, 
    dynlib: libname, importc: "lto_codegen_compile".}
  #*
  # * Sets options to help debug codegen bugs.
  #  
proc lto_codegen_debug_options*(cg: lto_code_gen_t, para2: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_debug_options".}
# implementation
