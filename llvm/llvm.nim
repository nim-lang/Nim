const 
  libname* = "llvm.dll"               #Setup as you need

type
  OpaqueContext {.pure.} = object
  OpaqueModule {.pure.} = object
  TOpaqueType {.pure.} = object
  OpaqueTypeHandle {.pure.} = object
  OpaqueValue {.pure.} = object
  OpaqueBasicBlock {.pure.} = object
  OpaqueBuilder {.pure.} = object
  OpaqueModuleProvider {.pure.} = object
  OpaqueMemoryBuffer {.pure.} = object
  OpaquePassManager {.pure.} = object
  OpaqueUseIterator {.pure.} = object

  ContextRef* = OpaqueContext
  ModuleRef* = OpaqueModule  
  TypeRef* = TOpaqueType  
  TypeHandleRef* = OpaqueTypeHandle
  ValueRef* = OpaqueValue
  BasicBlockRef* = OpaqueBasicBlock
  BuilderRef* = OpaqueBuilder 
  ModuleProviderRef* = OpaqueModuleProvider   
  MemoryBufferRef* = OpaqueMemoryBuffer   
  PassManagerRef* = OpaquePassManager 
  UseIteratorRef* = OpaqueUseIterator
  Attribute* = enum 
    ZExtAttribute = 1 shl 0, SExtAttribute = 1 shl 1, 
    NoReturnAttribute = 1 shl 2, InRegAttribute = 1 shl 3, 
    StructRetAttribute = 1 shl 4, NoUnwindAttribute = 1 shl 5, 
    NoAliasAttribute = 1 shl 6, ByValAttribute = 1 shl 7, 
    NestAttribute = 1 shl 8, ReadNoneAttribute = 1 shl 9, 
    ReadOnlyAttribute = 1 shl 10, NoInlineAttribute = 1 shl 11, 
    AlwaysInlineAttribute = 1 shl 12, OptimizeForSizeAttribute = 1 shl 13, 
    StackProtectAttribute = 1 shl 14, StackProtectReqAttribute = 1 shl 15, 
    NoCaptureAttribute = 1 shl 21, NoRedZoneAttribute = 1 shl 22, 
    NoImplicitFloatAttribute = 1 shl 23, NakedAttribute = 1 shl 24, 
    InlineHintAttribute = 1 shl 25
  Opcode* = enum
    opcRet = 1, opcBr = 2, opcSwitch = 3, opcInvoke = 4, opcUnwind = 5,
    opcUnreachable = 6, 
    opcAdd = 7, opcFAdd = 8, opcSub = 9, opcFSub = 10, opcMul = 11,
    opcFMul = 12, opcUDiv = 13, 
    opcSDiv = 14, opcFDiv = 15, opcURem = 16, opcSRem = 17, opcFRem = 18,
    opcShl = 19,
    opcLShr = 20, opcAShr = 21, opcAnd = 22, opcOr = 23, opcXor = 24,
    opcMalloc = 25, opcFree = 26, opcAlloca = 27, 
    opcLoad = 28, opcStore = 29,
    opcGetElementPtr = 30, opcTrunk = 31, opcZExt = 32, opcSExt = 33, 
    opcFPToUI = 34, opcFPToSI = 35, opcUIToFP = 36, opcSIToFP = 37,
    opcFPTrunc = 38, opcFPExt = 39, opcPtrToInt = 40, opcIntToPtr = 41,
    opcBitCast = 42, opcICmp = 43, 
    opcFCmp = 44, opcPHI = 45, opcCall = 46, opcSelect = 47, opcVAArg = 50, 
    opcExtractElement = 51, opcInsertElement = 52, opcShuffleVector = 53, 
    opcExtractValue = 54, opcInsertValue = 55
  TypeKind* = enum 
    VoidTypeKind, FloatTypeKind, DoubleTypeKind, X86_FP80TypeKind, 
    FP128TypeKind, PPC_FP128TypeKind, LabelTypeKind, IntegerTypeKind, 
    FunctionTypeKind, StructTypeKind, ArrayTypeKind, PointerTypeKind, 
    OpaqueTypeKind, VectorTypeKind, MetadataTypeKind
  TLinkage* = enum
    ExternalLinkage,            ## Externally visible function 
    AvailableExternallyLinkage, ## Keep one copy of function when linking (inline) 
    LinkOnceAnyLinkage, ## Same, but only replaced by something equivalent.
    LinkOnceODRLinkage, ## Keep one copy of function when linking (weak)
    WeakAnyLinkage,     ## Same, but only replaced by something equivalent.
    WeakODRLinkage,     ## Special purpose, only applies to global arrays
    AppendingLinkage,   ## Rename collisions when linking (static functions)
    InternalLinkage,    ## 
    PrivateLinkage,     ## Like Internal, but omit from symbol table
    DLLImportLinkage,   ## Function to be imported from DLL
    DLLExportLinkage,   ## Function to be accessible from DLL 
    ExternalWeakLinkage, ## ExternalWeak linkage description 
    GhostLinkage,       ## Stand-in functions for streaming fns from bitcode 
    CommonLinkage,      ## Tentative definitions  
    LinkerPrivateLinkage ## Like Private, but linker removes.
  TVisibility* = enum
    DefaultVisibility,
    HiddenVisibility,
    ProtectedVisibility
  TCallConv* = enum          
    CCallConv = 0, FastCallConv = 8, ColdCallConv = 9, X86StdcallCallConv = 64, 
    X86FastcallCallConv = 65
  IntPredicate* = enum       
    IntEQ = 32, IntNE, IntUGT, IntUGE, IntULT, IntULE, IntSGT, IntSGE, IntSLT, 
    IntSLE
  RealPredicate* = enum       
    RealPredicateFalse, RealOEQ, RealOGT, RealOGE, RealOLT, RealOLE, RealONE, 
    RealORD, RealUNO, RealUEQ, RealUGT, RealUGE, RealULT, RealULE, RealUNE, 
    RealPredicateTrue

#===-- Error handling ----------------------------------------------------=== 

proc DisposeMessage*(Message: cstring){.cdecl, dynlib: libname, 
                                        importc: "LLVMDisposeMessage".}
  
#===-- Modules -----------------------------------------------------------=== 
# Create and destroy contexts.  
proc ContextCreate*(): ContextRef{.cdecl, dynlib: libname, 
                                   importc: "LLVMContextCreate".}
proc GetGlobalContext*(): ContextRef{.cdecl, dynlib: libname, 
                                      importc: "LLVMGetGlobalContext".}
proc ContextDispose*(C: ContextRef){.cdecl, dynlib: libname, 
                                     importc: "LLVMContextDispose".}
  # Create and destroy modules.  
  # See llvm::Module::Module.  
proc ModuleCreateWithName*(ModuleID: cstring): ModuleRef{.cdecl, 
    dynlib: libname, importc: "LLVMModuleCreateWithName".}
proc ModuleCreateWithNameInContext*(ModuleID: cstring, C: ContextRef): ModuleRef{.
    cdecl, dynlib: libname, importc: "LLVMModuleCreateWithNameInContext".}
  # See llvm::Module::~Module.  
proc DisposeModule*(M: ModuleRef){.cdecl, dynlib: libname, 
                                   importc: "LLVMDisposeModule".}
  # Data layout. See Module::getDataLayout.  
proc GetDataLayout*(M: ModuleRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetDataLayout".}
proc SetDataLayout*(M: ModuleRef, Triple: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetDataLayout".}
  # Target triple. See Module::getTargetTriple.  
proc GetTarget*(M: ModuleRef): cstring{.cdecl, dynlib: libname, 
                                        importc: "LLVMGetTarget".}
proc SetTarget*(M: ModuleRef, Triple: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetTarget".}
  # See Module::addTypeName.  
proc AddTypeName*(M: ModuleRef, Name: cstring, Ty: TypeRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMAddTypeName".}
proc DeleteTypeName*(M: ModuleRef, Name: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteTypeName".}
proc GetTypeByName*(M: ModuleRef, Name: cstring): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetTypeByName".}
  # See Module::dump.  
proc DumpModule*(M: ModuleRef){.cdecl, dynlib: libname, 
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
  # See llvm::LLVMTypeKind::getTypeID.  
proc GetTypeKind*(Ty: TypeRef): TypeKind{.cdecl, dynlib: libname, 
    importc: "LLVMGetTypeKind".}
  # See llvm::LLVMType::getContext.  
proc GetTypeContext*(Ty: TypeRef): ContextRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetTypeContext".}
  # Operations on integer types  
proc Int1TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMInt1TypeInContext".}
proc Int8TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMInt8TypeInContext".}
proc Int16TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMInt16TypeInContext".}
proc Int32TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMInt32TypeInContext".}
proc Int64TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMInt64TypeInContext".}
proc IntTypeInContext*(C: ContextRef, NumBits: int32): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMIntTypeInContext".}
proc Int1Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMInt1Type".}
proc Int8Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMInt8Type".}
proc Int16Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMInt16Type".}
proc Int32Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMInt32Type".}
proc Int64Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMInt64Type".}
proc IntType*(NumBits: int32): TypeRef{.cdecl, dynlib: libname, 
                                        importc: "LLVMIntType".}
proc GetIntTypeWidth*(IntegerTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetIntTypeWidth".}
  # Operations on real types  
proc FloatTypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMFloatTypeInContext".}
proc DoubleTypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMDoubleTypeInContext".}
proc X86FP80TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMX86FP80TypeInContext".}
proc FP128TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMFP128TypeInContext".}
proc PPCFP128TypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMPPCFP128TypeInContext".}
proc FloatType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMFloatType".}
proc DoubleType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMDoubleType".}
proc X86FP80Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMX86FP80Type".}
proc FP128Type*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMFP128Type".}
proc PPCFP128Type*(): TypeRef{.cdecl, dynlib: libname, 
                               importc: "LLVMPPCFP128Type".}
  # Operations on function types  
proc FunctionType*(ReturnType: TypeRef, ParamTypes: ptr TypeRef,
                   ParamCount: int32, IsVarArg: int32): TypeRef {.
    cdecl, dynlib: libname, importc: "LLVMFunctionType".}
proc IsFunctionVarArg*(FunctionTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsFunctionVarArg".}
proc GetReturnType*(FunctionTy: TypeRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetReturnType".}
proc CountParamTypes*(FunctionTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCountParamTypes".}
proc GetParamTypes*(FunctionTy: TypeRef, Dest: ptr TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMGetParamTypes".}
  # Operations on struct types  
proc StructTypeInContext*(C: ContextRef, ElementTypes: ptr TypeRef, 
                          ElementCount: int32, isPacked: int32): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMStructTypeInContext".}
proc StructType*(ElementTypes: ptr TypeRef, ElementCount: int32, isPacked: int32): TypeRef{.
    cdecl, dynlib: libname, importc: "LLVMStructType".}
proc CountStructElementTypes*(StructTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCountStructElementTypes".}
proc GetStructElementTypes*(StructTy: TypeRef, Dest: ptr TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMGetStructElementTypes".}
proc IsPackedStruct*(StructTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsPackedStruct".}
  # Operations on array, pointer, and vector types (sequence types)  
proc ArrayType*(ElementType: TypeRef, ElementCount: int32): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMArrayType".}
proc PointerType*(ElementType: TypeRef, AddressSpace: int32): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMPointerType".}
proc VectorType*(ElementType: TypeRef, ElementCount: int32): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMVectorType".}
proc GetElementType*(Ty: TypeRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetElementType".}
proc GetArrayLength*(ArrayTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetArrayLength".}
proc GetPointerAddressSpace*(PointerTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetPointerAddressSpace".}
proc GetVectorSize*(VectorTy: TypeRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetVectorSize".}
  # Operations on other types  
proc VoidTypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMVoidTypeInContext".}
proc LabelTypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMLabelTypeInContext".}
proc OpaqueTypeInContext*(C: ContextRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMOpaqueTypeInContext".}
proc VoidType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMVoidType".}
proc LabelType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMLabelType".}
proc OpaqueType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMOpaqueType".}
  # Operations on type handles  
proc CreateTypeHandle*(PotentiallyAbstractTy: TypeRef): TypeHandleRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateTypeHandle".}
proc RefineType*(AbstractTy: TypeRef, ConcreteTy: TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMRefineType".}
proc ResolveTypeHandle*(TypeHandle: TypeHandleRef): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMResolveTypeHandle".}
proc DisposeTypeHandle*(TypeHandle: TypeHandleRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeTypeHandle".}
  # Operations on all values  
proc TypeOf*(Val: ValueRef): TypeRef{.cdecl, dynlib: libname, 
                                      importc: "LLVMTypeOf".}
proc GetValueName*(Val: ValueRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetValueName".}
proc SetValueName*(Val: ValueRef, Name: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetValueName".}
proc DumpValue*(Val: ValueRef){.cdecl, dynlib: libname, importc: "LLVMDumpValue".}
proc ReplaceAllUsesWith*(OldVal: ValueRef, NewVal: ValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMReplaceAllUsesWith".}
  # Conversion functions. Return the input value if it is an instance of the
  #   specified class, otherwise NULL. See llvm::dyn_cast_or_null<>.  
proc IsAArgument*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAArgument".}
proc IsABasicBlock*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsABasicBlock".}
proc IsAInlineAsm*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInlineAsm".}
proc IsAUser*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
                                        importc: "LLVMIsAUser".}
proc IsAConstant*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstant".}
proc IsAConstantAggregateZero*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantAggregateZero".}
proc IsAConstantArray*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantArray".}
proc IsAConstantExpr*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantExpr".}
proc IsAConstantFP*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantFP".}
proc IsAConstantInt*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantInt".}
proc IsAConstantPointerNull*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantPointerNull".}
proc IsAConstantStruct*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantStruct".}
proc IsAConstantVector*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAConstantVector".}
proc IsAGlobalValue*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAGlobalValue".}
proc IsAFunction*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFunction".}
proc IsAGlobalAlias*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAGlobalAlias".}
proc IsAGlobalVariable*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAGlobalVariable".}
proc IsAUndefValue*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUndefValue".}
proc IsAInstruction*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInstruction".}
proc IsABinaryOperator*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsABinaryOperator".}
proc IsACallInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACallInst".}
proc IsAIntrinsicInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAIntrinsicInst".}
proc IsADbgInfoIntrinsic*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgInfoIntrinsic".}
proc IsADbgDeclareInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgDeclareInst".}
proc IsADbgFuncStartInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgFuncStartInst".}
proc IsADbgRegionEndInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgRegionEndInst".}
proc IsADbgRegionStartInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgRegionStartInst".}
proc IsADbgStopPointInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsADbgStopPointInst".}
proc IsAEHSelectorInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAEHSelectorInst".}
proc IsAMemIntrinsic*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAMemIntrinsic".}
proc IsAMemCpyInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAMemCpyInst".}
proc IsAMemMoveInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAMemMoveInst".}
proc IsAMemSetInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAMemSetInst".}
proc IsACmpInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACmpInst".}
proc IsAFCmpInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFCmpInst".}
proc IsAICmpInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAICmpInst".}
proc IsAExtractElementInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAExtractElementInst".}
proc IsAGetElementPtrInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAGetElementPtrInst".}
proc IsAInsertElementInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInsertElementInst".}
proc IsAInsertValueInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInsertValueInst".}
proc IsAPHINode*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAPHINode".}
proc IsASelectInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsASelectInst".}
proc IsAShuffleVectorInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAShuffleVectorInst".}
proc IsAStoreInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAStoreInst".}
proc IsATerminatorInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsATerminatorInst".}
proc IsABranchInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsABranchInst".}
proc IsAInvokeInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAInvokeInst".}
proc IsAReturnInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAReturnInst".}
proc IsASwitchInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsASwitchInst".}
proc IsAUnreachableInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUnreachableInst".}
proc IsAUnwindInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUnwindInst".}
proc IsAUnaryInstruction*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUnaryInstruction".}
proc IsAAllocationInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAAllocationInst".}
proc IsAAllocaInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAAllocaInst".}
proc IsACastInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsACastInst".}
proc IsABitCastInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsABitCastInst".}
proc IsAFPExtInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFPExtInst".}
proc IsAFPToSIInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFPToSIInst".}
proc IsAFPToUIInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFPToUIInst".}
proc IsAFPTruncInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFPTruncInst".}
proc IsAIntToPtrInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAIntToPtrInst".}
proc IsAPtrToIntInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAPtrToIntInst".}
proc IsASExtInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsASExtInst".}
proc IsASIToFPInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsASIToFPInst".}
proc IsATruncInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsATruncInst".}
proc IsAUIToFPInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAUIToFPInst".}
proc IsAZExtInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAZExtInst".}
proc IsAExtractValueInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAExtractValueInst".}
proc IsAFreeInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAFreeInst".}
proc IsALoadInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsALoadInst".}
proc IsAVAArgInst*(Val: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMIsAVAArgInst".}
  # Operations on Uses  
proc GetFirstUse*(Val: ValueRef): UseIteratorRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstUse".}
proc GetNextUse*(U: UseIteratorRef): UseIteratorRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextUse".}
proc GetUser*(U: UseIteratorRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetUser".}
proc GetUsedValue*(U: UseIteratorRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetUsedValue".}
  # Operations on Users  
proc GetOperand*(Val: ValueRef, Index: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetOperand".}
  # Operations on constants of any type  
proc ConstNull*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
                                        importc: "LLVMConstNull".}
  # all zeroes  
proc ConstAllOnes*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstAllOnes".}
  # only for int/vector  
proc GetUndef*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
                                       importc: "LLVMGetUndef".}
proc IsConstant*(Val: ValueRef): int32{.cdecl, dynlib: libname, 
                                        importc: "LLVMIsConstant".}
proc IsNull*(Val: ValueRef): int32{.cdecl, dynlib: libname, 
                                    importc: "LLVMIsNull".}
proc IsUndef*(Val: ValueRef): int32{.cdecl, dynlib: libname, 
                                     importc: "LLVMIsUndef".}
proc ConstPointerNull*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstPointerNull".}
  # Operations on scalar constants  
proc ConstInt*(IntTy: TypeRef, N: int64, SignExtend: int32): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstInt".}
proc ConstIntOfString*(IntTy: TypeRef, Text: cstring, Radix: byte): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstIntOfString".}
proc ConstIntOfStringAndSize*(IntTy: TypeRef, Text: cstring, SLen: int32, 
                              Radix: byte): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstIntOfStringAndSize".}
proc ConstReal*(RealTy: TypeRef, N: float64): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstReal".}
proc ConstRealOfString*(RealTy: TypeRef, Text: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstRealOfString".}
proc ConstRealOfStringAndSize*(RealTy: TypeRef, Text: cstring, SLen: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstRealOfStringAndSize".}
proc ConstIntGetZExtValue*(ConstantVal: ValueRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMConstIntGetZExtValue".}
proc ConstIntGetSExtValue*(ConstantVal: ValueRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMConstIntGetSExtValue".}
  # Operations on composite constants  
proc ConstStringInContext*(C: ContextRef, Str: cstring, len: int32, 
                           DontNullTerminate: int32): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstStringInContext".}
proc ConstStructInContext*(C: ContextRef, ConstantVals: ptr ValueRef,
                           Count: int32, 
                           isPacked: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstStructInContext".}
proc ConstString*(Str: cstring, len: int32, DontNullTerminate: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstString".}
proc ConstArray*(ElementTy: TypeRef, ConstantVals: ptr ValueRef, len: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstArray".}
proc ConstStruct*(ConstantVals: ptr ValueRef, Count: int32, isPacked: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstStruct".}
proc ConstVector*(ScalarConstantVals: ptr ValueRef, Size: int32): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstVector".}
  # Constant expressions  
proc GetConstOpcode*(ConstantVal: ValueRef): Opcode{.cdecl, dynlib: libname, 
    importc: "LLVMGetConstOpcode".}
proc AlignOf*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
                                      importc: "LLVMAlignOf".}
proc SizeOf*(Ty: TypeRef): ValueRef{.cdecl, dynlib: libname, 
                                     importc: "LLVMSizeOf".}
proc ConstNeg*(ConstantVal: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstNeg".}
proc ConstFNeg*(ConstantVal: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstFNeg".}
proc ConstNot*(ConstantVal: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstNot".}
proc ConstAdd*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstAdd".}
proc ConstNSWAdd*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstNSWAdd".}
proc ConstFAdd*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFAdd".}
proc ConstSub*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSub".}
proc ConstFSub*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFSub".}
proc ConstMul*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstMul".}
proc ConstFMul*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFMul".}
proc ConstUDiv*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstUDiv".}
proc ConstSDiv*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSDiv".}
proc ConstExactSDiv*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstExactSDiv".}
proc ConstFDiv*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFDiv".}
proc ConstURem*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstURem".}
proc ConstSRem*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSRem".}
proc ConstFRem*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFRem".}
proc ConstAnd*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstAnd".}
proc ConstOr*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstOr".}
proc ConstXor*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstXor".}
proc ConstICmp*(Predicate: IntPredicate, LHSConstant: ValueRef, 
                RHSConstant: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstICmp".}
proc ConstFCmp*(Predicate: RealPredicate, LHSConstant: ValueRef, 
                RHSConstant: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstFCmp".}
proc ConstShl*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstShl".}
proc ConstLShr*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstLShr".}
proc ConstAShr*(LHSConstant: ValueRef, RHSConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstAShr".}
proc ConstGEP*(ConstantVal: ValueRef, ConstantIndices: ptr ValueRef, 
               NumIndices: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstGEP".}
proc ConstInBoundsGEP*(ConstantVal: ValueRef, ConstantIndices: ptr ValueRef, 
                       NumIndices: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstInBoundsGEP".}
proc ConstTrunc*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstTrunc".}
proc ConstSExt*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSExt".}
proc ConstZExt*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstZExt".}
proc ConstFPTrunc*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFPTrunc".}
proc ConstFPExt*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFPExt".}
proc ConstUIToFP*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstUIToFP".}
proc ConstSIToFP*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstSIToFP".}
proc ConstFPToUI*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFPToUI".}
proc ConstFPToSI*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFPToSI".}
proc ConstPtrToInt*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstPtrToInt".}
proc ConstIntToPtr*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstIntToPtr".}
proc ConstBitCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstBitCast".}
proc ConstZExtOrBitCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstZExtOrBitCast".}
proc ConstSExtOrBitCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstSExtOrBitCast".}
proc ConstTruncOrBitCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstTruncOrBitCast".}
proc ConstPointerCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstPointerCast".}
proc ConstIntCast*(ConstantVal: ValueRef, ToType: TypeRef, isSigned: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstIntCast".}
proc ConstFPCast*(ConstantVal: ValueRef, ToType: TypeRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstFPCast".}
proc ConstSelect*(ConstantCondition: ValueRef, ConstantIfTrue: ValueRef, 
                  ConstantIfFalse: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstSelect".}
proc ConstExtractElement*(VectorConstant: ValueRef, IndexConstant: ValueRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstExtractElement".}
proc ConstInsertElement*(VectorConstant: ValueRef, 
                         ElementValueConstant: ValueRef, IndexConstant: ValueRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstInsertElement".}
proc ConstShuffleVector*(VectorAConstant: ValueRef, VectorBConstant: ValueRef, 
                         MaskConstant: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstShuffleVector".}
proc ConstExtractValue*(AggConstant: ValueRef, IdxList: ptr int32, NumIdx: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMConstExtractValue".}
proc ConstInsertValue*(AggConstant: ValueRef, ElementValueConstant: ValueRef, 
                       IdxList: ptr int32, NumIdx: int32): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMConstInsertValue".}
proc ConstInlineAsm*(Ty: TypeRef, AsmString: cstring, Constraints: cstring, 
                     HasSideEffects: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMConstInlineAsm".}
  # Operations on global variables, functions, and aliases (globals)  
proc GetGlobalParent*(Global: ValueRef): ModuleRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetGlobalParent".}
proc IsDeclaration*(Global: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsDeclaration".}
proc GetLinkage*(Global: ValueRef): TLinkage{.cdecl, dynlib: libname, 
    importc: "LLVMGetLinkage".}
proc SetLinkage*(Global: ValueRef, Linkage: TLinkage){.cdecl, dynlib: libname, 
    importc: "LLVMSetLinkage".}
proc GetSection*(Global: ValueRef): cstring{.cdecl, dynlib: libname, 
    importc: "LLVMGetSection".}
proc SetSection*(Global: ValueRef, Section: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetSection".}
proc GetVisibility*(Global: ValueRef): TVisibility{.cdecl, dynlib: libname, 
    importc: "LLVMGetVisibility".}
proc SetVisibility*(Global: ValueRef, Viz: TVisibility){.cdecl, dynlib: libname, 
    importc: "LLVMSetVisibility".}
proc GetAlignment*(Global: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetAlignment".}
proc SetAlignment*(Global: ValueRef, Bytes: int32){.cdecl, dynlib: libname, 
    importc: "LLVMSetAlignment".}
  # Operations on global variables  
proc AddGlobal*(M: ModuleRef, Ty: TypeRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMAddGlobal".}
proc GetNamedGlobal*(M: ModuleRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNamedGlobal".}
proc GetFirstGlobal*(M: ModuleRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstGlobal".}
proc GetLastGlobal*(M: ModuleRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastGlobal".}
proc GetNextGlobal*(GlobalVar: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextGlobal".}
proc GetPreviousGlobal*(GlobalVar: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetPreviousGlobal".}
proc DeleteGlobal*(GlobalVar: ValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteGlobal".}
proc GetInitializer*(GlobalVar: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetInitializer".}
proc SetInitializer*(GlobalVar: ValueRef, ConstantVal: ValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMSetInitializer".}
proc IsThreadLocal*(GlobalVar: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsThreadLocal".}
proc SetThreadLocal*(GlobalVar: ValueRef, IsThreadLocal: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetThreadLocal".}
proc IsGlobalConstant*(GlobalVar: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsGlobalConstant".}
proc SetGlobalConstant*(GlobalVar: ValueRef, IsConstant: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetGlobalConstant".}
  # Operations on aliases  
proc AddAlias*(M: ModuleRef, Ty: TypeRef, Aliasee: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMAddAlias".}
  # Operations on functions  
proc AddFunction*(M: ModuleRef, Name: cstring, FunctionTy: TypeRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMAddFunction".}
proc GetNamedFunction*(M: ModuleRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNamedFunction".}
proc GetFirstFunction*(M: ModuleRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstFunction".}
proc GetLastFunction*(M: ModuleRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastFunction".}
proc GetNextFunction*(Fn: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextFunction".}
proc GetPreviousFunction*(Fn: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetPreviousFunction".}
proc DeleteFunction*(Fn: ValueRef){.cdecl, dynlib: libname, 
                                    importc: "LLVMDeleteFunction".}
proc GetIntrinsicID*(Fn: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetIntrinsicID".}
proc GetFunctionCallConv*(Fn: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetFunctionCallConv".}
proc SetFunctionCallConv*(Fn: ValueRef, CC: int32){.cdecl, dynlib: libname, 
    importc: "LLVMSetFunctionCallConv".}
proc GetGC*(Fn: ValueRef): cstring{.cdecl, dynlib: libname, importc: "LLVMGetGC".}
proc SetGC*(Fn: ValueRef, Name: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMSetGC".}
proc AddFunctionAttr*(Fn: ValueRef, PA: Attribute){.cdecl, dynlib: libname, 
    importc: "LLVMAddFunctionAttr".}
proc GetFunctionAttr*(Fn: ValueRef): Attribute{.cdecl, dynlib: libname, 
    importc: "LLVMGetFunctionAttr".}
proc RemoveFunctionAttr*(Fn: ValueRef, PA: Attribute){.cdecl, dynlib: libname, 
    importc: "LLVMRemoveFunctionAttr".}
  # Operations on parameters  
proc CountParams*(Fn: ValueRef): int32{.cdecl, dynlib: libname, 
                                        importc: "LLVMCountParams".}
proc GetParams*(Fn: ValueRef, Params: ptr ValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMGetParams".}
proc GetParam*(Fn: ValueRef, Index: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetParam".}
proc GetParamParent*(Inst: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetParamParent".}
proc GetFirstParam*(Fn: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstParam".}
proc GetLastParam*(Fn: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastParam".}
proc GetNextParam*(Arg: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextParam".}
proc GetPreviousParam*(Arg: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetPreviousParam".}
proc AddAttribute*(Arg: ValueRef, PA: Attribute){.cdecl, dynlib: libname, 
    importc: "LLVMAddAttribute".}
proc RemoveAttribute*(Arg: ValueRef, PA: Attribute){.cdecl, dynlib: libname, 
    importc: "LLVMRemoveAttribute".}
proc GetAttribute*(Arg: ValueRef): Attribute{.cdecl, dynlib: libname, 
    importc: "LLVMGetAttribute".}
proc SetParamAlignment*(Arg: ValueRef, align: int32){.cdecl, dynlib: libname, 
    importc: "LLVMSetParamAlignment".}
  # Operations on basic blocks  
proc BasicBlockAsValue*(BB: BasicBlockRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBasicBlockAsValue".}
proc ValueIsBasicBlock*(Val: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMValueIsBasicBlock".}
proc ValueAsBasicBlock*(Val: ValueRef): BasicBlockRef{.cdecl, dynlib: libname, 
    importc: "LLVMValueAsBasicBlock".}
proc GetBasicBlockParent*(BB: BasicBlockRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetBasicBlockParent".}
proc CountBasicBlocks*(Fn: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCountBasicBlocks".}
proc GetBasicBlocks*(Fn: ValueRef, BasicBlocks: ptr BasicBlockRef){.cdecl, 
    dynlib: libname, importc: "LLVMGetBasicBlocks".}
proc GetFirstBasicBlock*(Fn: ValueRef): BasicBlockRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstBasicBlock".}
proc GetLastBasicBlock*(Fn: ValueRef): BasicBlockRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastBasicBlock".}
proc GetNextBasicBlock*(BB: BasicBlockRef): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetNextBasicBlock".}
proc GetPreviousBasicBlock*(BB: BasicBlockRef): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetPreviousBasicBlock".}
proc GetEntryBasicBlock*(Fn: ValueRef): BasicBlockRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetEntryBasicBlock".}
proc AppendBasicBlockInContext*(C: ContextRef, Fn: ValueRef, Name: cstring): BasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMAppendBasicBlockInContext".}
proc InsertBasicBlockInContext*(C: ContextRef, BB: BasicBlockRef, Name: cstring): BasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMInsertBasicBlockInContext".}
proc AppendBasicBlock*(Fn: ValueRef, Name: cstring): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMAppendBasicBlock".}
proc InsertBasicBlock*(InsertBeforeBB: BasicBlockRef, Name: cstring): BasicBlockRef{.
    cdecl, dynlib: libname, importc: "LLVMInsertBasicBlock".}
proc DeleteBasicBlock*(BB: BasicBlockRef){.cdecl, dynlib: libname, 
    importc: "LLVMDeleteBasicBlock".}
  # Operations on instructions  
proc GetInstructionParent*(Inst: ValueRef): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetInstructionParent".}
proc GetFirstInstruction*(BB: BasicBlockRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetFirstInstruction".}
proc GetLastInstruction*(BB: BasicBlockRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetLastInstruction".}
proc GetNextInstruction*(Inst: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetNextInstruction".}
proc GetPreviousInstruction*(Inst: ValueRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMGetPreviousInstruction".}
  # Operations on call sites  
proc SetInstructionCallConv*(Instr: ValueRef, CC: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetInstructionCallConv".}
proc GetInstructionCallConv*(Instr: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMGetInstructionCallConv".}
proc AddInstrAttribute*(Instr: ValueRef, index: int32, para3: Attribute){.cdecl, 
    dynlib: libname, importc: "LLVMAddInstrAttribute".}
proc RemoveInstrAttribute*(Instr: ValueRef, index: int32, para3: Attribute){.
    cdecl, dynlib: libname, importc: "LLVMRemoveInstrAttribute".}
proc SetInstrParamAlignment*(Instr: ValueRef, index: int32, align: int32){.
    cdecl, dynlib: libname, importc: "LLVMSetInstrParamAlignment".}
  # Operations on call instructions (only)  
proc IsTailCall*(CallInst: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMIsTailCall".}
proc SetTailCall*(CallInst: ValueRef, IsTailCall: int32){.cdecl, 
    dynlib: libname, importc: "LLVMSetTailCall".}
  # Operations on phi nodes  
proc AddIncoming*(PhiNode: ValueRef, IncomingValues: ptr ValueRef, 
                  IncomingBlocks: ptr BasicBlockRef, Count: int32){.cdecl, 
    dynlib: libname, importc: "LLVMAddIncoming".}
proc CountIncoming*(PhiNode: ValueRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCountIncoming".}
proc GetIncomingValue*(PhiNode: ValueRef, Index: int32): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetIncomingValue".}
proc GetIncomingBlock*(PhiNode: ValueRef, Index: int32): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetIncomingBlock".}
  #===-- Instruction builders ----------------------------------------------=== 
  # An instruction builder represents a point within a basic block, and is the
  # * exclusive means of building instructions using the C interface.
  #  
proc CreateBuilderInContext*(C: ContextRef): BuilderRef{.cdecl, dynlib: libname, 
    importc: "LLVMCreateBuilderInContext".}
proc CreateBuilder*(): BuilderRef{.cdecl, dynlib: libname, 
                                   importc: "LLVMCreateBuilder".}
proc PositionBuilder*(Builder: BuilderRef, theBlock: BasicBlockRef, 
                      Instr: ValueRef){.cdecl, dynlib: libname, 
                                        importc: "LLVMPositionBuilder".}
proc PositionBuilderBefore*(Builder: BuilderRef, Instr: ValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMPositionBuilderBefore".}
proc PositionBuilderAtEnd*(Builder: BuilderRef, theBlock: BasicBlockRef){.cdecl, 
    dynlib: libname, importc: "LLVMPositionBuilderAtEnd".}
proc GetInsertBlock*(Builder: BuilderRef): BasicBlockRef{.cdecl, 
    dynlib: libname, importc: "LLVMGetInsertBlock".}
proc ClearInsertionPosition*(Builder: BuilderRef){.cdecl, dynlib: libname, 
    importc: "LLVMClearInsertionPosition".}
proc InsertIntoBuilder*(Builder: BuilderRef, Instr: ValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMInsertIntoBuilder".}
proc InsertIntoBuilderWithName*(Builder: BuilderRef, Instr: ValueRef, 
                                Name: cstring){.cdecl, dynlib: libname, 
    importc: "LLVMInsertIntoBuilderWithName".}
proc DisposeBuilder*(Builder: BuilderRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeBuilder".}
  # Terminators  
proc BuildRetVoid*(para1: BuilderRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildRetVoid".}
proc BuildRet*(para1: BuilderRef, V: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildRet".}
proc BuildAggregateRet*(para1: BuilderRef, RetVals: ptr ValueRef, N: int32): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAggregateRet".}
proc BuildBr*(para1: BuilderRef, Dest: BasicBlockRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildBr".}
proc BuildCondBr*(para1: BuilderRef, Cond: ValueRef, ThenBranch: BasicBlockRef, 
                  ElseBranch: BasicBlockRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildCondBr".}
proc BuildSwitch*(para1: BuilderRef, V: ValueRef, ElseBranch: BasicBlockRef, 
                  NumCases: int32): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSwitch".}
proc BuildInvoke*(para1: BuilderRef, Fn: ValueRef, Args: ptr ValueRef, 
                  NumArgs: int32, ThenBranch: BasicBlockRef, 
                  Catch: BasicBlockRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildInvoke".}
proc BuildUnwind*(para1: BuilderRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildUnwind".}
proc BuildUnreachable*(para1: BuilderRef): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildUnreachable".}
  # Add a case to the switch instruction  
proc AddCase*(Switch: ValueRef, OnVal: ValueRef, Dest: BasicBlockRef){.cdecl, 
    dynlib: libname, importc: "LLVMAddCase".}
  # Arithmetic  
proc BuildAdd*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAdd".}
proc BuildNSWAdd*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildNSWAdd".}
proc BuildFAdd*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFAdd".}
proc BuildSub*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSub".}
proc BuildFSub*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFSub".}
proc BuildMul*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildMul".}
proc BuildFMul*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFMul".}
proc BuildUDiv*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildUDiv".}
proc BuildSDiv*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSDiv".}
proc BuildExactSDiv*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, 
                     Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildExactSDiv".}
proc BuildFDiv*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFDiv".}
proc BuildURem*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildURem".}
proc BuildSRem*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSRem".}
proc BuildFRem*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildFRem".}
proc BuildShl*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildShl".}
proc BuildLShr*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildLShr".}
proc BuildAShr*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAShr".}
proc BuildAnd*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAnd".}
proc BuildOr*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildOr".}
proc BuildXor*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildXor".}
proc BuildNeg*(para1: BuilderRef, V: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildNeg".}
proc BuildFNeg*(para1: BuilderRef, V: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFNeg".}
proc BuildNot*(para1: BuilderRef, V: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildNot".}
  # Memory  
proc BuildMalloc*(para1: BuilderRef, Ty: TypeRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildMalloc".}
proc BuildArrayMalloc*(para1: BuilderRef, Ty: TypeRef, Val: ValueRef, 
                       Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildArrayMalloc".}
proc BuildAlloca*(para1: BuilderRef, Ty: TypeRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildAlloca".}
proc BuildArrayAlloca*(para1: BuilderRef, Ty: TypeRef, Val: ValueRef, 
                       Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildArrayAlloca".}
proc BuildFree*(para1: BuilderRef, PointerVal: ValueRef): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildFree".}
proc BuildLoad*(para1: BuilderRef, PointerVal: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildLoad".}
proc BuildStore*(para1: BuilderRef, Val: ValueRef, thePtr: ValueRef): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildStore".}
proc BuildGEP*(B: BuilderRef, Pointer: ValueRef, Indices: ptr ValueRef, 
               NumIndices: int32, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildGEP".}
proc BuildInBoundsGEP*(B: BuilderRef, Pointer: ValueRef, Indices: ptr ValueRef, 
                       NumIndices: int32, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildInBoundsGEP".}
proc BuildStructGEP*(B: BuilderRef, Pointer: ValueRef, Idx: int32, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildStructGEP".}
proc BuildGlobalString*(B: BuilderRef, Str: cstring, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildGlobalString".}
proc BuildGlobalStringPtr*(B: BuilderRef, Str: cstring, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildGlobalStringPtr".}
  # Casts  
proc BuildTrunc*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                 Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildTrunc".}
proc BuildZExt*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildZExt".}
proc BuildSExt*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildSExt".}
proc BuildFPToUI*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                  Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFPToUI".}
proc BuildFPToSI*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                  Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFPToSI".}
proc BuildUIToFP*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                  Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildUIToFP".}
proc BuildSIToFP*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                  Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSIToFP".}
proc BuildFPTrunc*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                   Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFPTrunc".}
proc BuildFPExt*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                 Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFPExt".}
proc BuildPtrToInt*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                    Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildPtrToInt".}
proc BuildIntToPtr*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                    Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildIntToPtr".}
proc BuildBitCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                   Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildBitCast".}
proc BuildZExtOrBitCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                         Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildZExtOrBitCast".}
proc BuildSExtOrBitCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                         Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildSExtOrBitCast".}
proc BuildTruncOrBitCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                          Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildTruncOrBitCast".}
proc BuildPointerCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                       Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildPointerCast".}
proc BuildIntCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                   Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildIntCast".}
proc BuildFPCast*(para1: BuilderRef, Val: ValueRef, DestTy: TypeRef, 
                  Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFPCast".}
  # Comparisons  
proc BuildICmp*(para1: BuilderRef, Op: IntPredicate, LHS: ValueRef, 
                RHS: ValueRef, Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildICmp".}
proc BuildFCmp*(para1: BuilderRef, Op: RealPredicate, LHS: ValueRef, 
                RHS: ValueRef, Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildFCmp".}
  # Miscellaneous instructions  
proc BuildPhi*(para1: BuilderRef, Ty: TypeRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildPhi".}
proc BuildCall*(para1: BuilderRef, Fn: ValueRef, Args: ptr ValueRef, 
                NumArgs: int32, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildCall".}
proc BuildSelect*(para1: BuilderRef, Cond: ValueRef, ThenBranch: ValueRef, 
                  ElseBranch: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildSelect".}
proc BuildVAArg*(para1: BuilderRef, List: ValueRef, Ty: TypeRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildVAArg".}
proc BuildExtractElement*(para1: BuilderRef, VecVal: ValueRef, Index: ValueRef, 
                          Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildExtractElement".}
proc BuildInsertElement*(para1: BuilderRef, VecVal: ValueRef, EltVal: ValueRef, 
                         Index: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildInsertElement".}
proc BuildShuffleVector*(para1: BuilderRef, V1: ValueRef, V2: ValueRef, 
                         Mask: ValueRef, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildShuffleVector".}
proc BuildExtractValue*(para1: BuilderRef, AggVal: ValueRef, Index: int32, 
                        Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildExtractValue".}
proc BuildInsertValue*(para1: BuilderRef, AggVal: ValueRef, EltVal: ValueRef, 
                       Index: int32, Name: cstring): ValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMBuildInsertValue".}
proc BuildIsNull*(para1: BuilderRef, Val: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildIsNull".}
proc BuildIsNotNull*(para1: BuilderRef, Val: ValueRef, Name: cstring): ValueRef{.
    cdecl, dynlib: libname, importc: "LLVMBuildIsNotNull".}
proc BuildPtrDiff*(para1: BuilderRef, LHS: ValueRef, RHS: ValueRef, 
                   Name: cstring): ValueRef{.cdecl, dynlib: libname, 
    importc: "LLVMBuildPtrDiff".}
  #===-- Module providers --------------------------------------------------=== 
  # Encapsulates the module M in a module provider, taking ownership of the
  # module.
  # See the constructor llvm::ExistingModuleProvider::ExistingModuleProvider.
  #  
proc CreateModuleProviderForExistingModule*(M: ModuleRef): ModuleProviderRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateModuleProviderForExistingModule".}
  # Destroys the module provider MP as well as the contained module.
  # See the destructor llvm::ModuleProvider::~ModuleProvider.
  #  
proc DisposeModuleProvider*(MP: ModuleProviderRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeModuleProvider".}
  #===-- Memory buffers ----------------------------------------------------=== 
proc CreateMemoryBufferWithContentsOfFile*(Path: cstring, 
    OutMemBuf: ptr MemoryBufferRef, OutMessage: var cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMCreateMemoryBufferWithContentsOfFile".}
proc CreateMemoryBufferWithSTDIN*(OutMemBuf: ptr MemoryBufferRef, 
                                  OutMessage: var cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMCreateMemoryBufferWithSTDIN".}
proc DisposeMemoryBuffer*(MemBuf: MemoryBufferRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeMemoryBuffer".}
  #===-- Pass Managers -----------------------------------------------------=== 
  # Constructs a new whole-module pass pipeline. This type of pipeline is
  #    suitable for link-time optimization and whole-module transformations.
  #    See llvm::PassManager::PassManager.  
proc CreatePassManager*(): PassManagerRef{.cdecl, dynlib: libname, 
    importc: "LLVMCreatePassManager".}
  #    Constructs a new function-by-function pass pipeline over the module
  #    provider. It does not take ownership of the module provider. This type of
  #    pipeline is suitable for code generation and JIT compilation tasks.
  #    See llvm::FunctionPassManager::FunctionPassManager.  
proc CreateFunctionPassManager*(MP: ModuleProviderRef): PassManagerRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateFunctionPassManager".}
  # Initializes, executes on the provided module, and finalizes all of the
  #    passes scheduled in the pass manager. Returns 1 if any of the passes
  #    modified the module, 0 otherwise. See llvm::PassManager::run(Module&).  
proc RunPassManager*(PM: PassManagerRef, M: ModuleRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMRunPassManager".}
  # Initializes all of the function passes scheduled in the function pass
  #    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
  #    See llvm::FunctionPassManager::doInitialization.  
proc InitializeFunctionPassManager*(FPM: PassManagerRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMInitializeFunctionPassManager".}
  # Executes all of the function passes scheduled in the function pass manager
  # on the provided function. Returns 1 if any of the passes modified the
  # function, false otherwise.
  # See llvm::FunctionPassManager::run(Function&).  
proc RunFunctionPassManager*(FPM: PassManagerRef, F: ValueRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMRunFunctionPassManager".}
  # Finalizes all of the function passes scheduled in in the function pass
  #    manager. Returns 1 if any of the passes modified the module, 0 otherwise.
  #    See llvm::FunctionPassManager::doFinalization.  
proc FinalizeFunctionPassManager*(FPM: PassManagerRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMFinalizeFunctionPassManager".}
  # Frees the memory of a pass pipeline. For function pipelines, does not free
  #    the module provider.
  #    See llvm::PassManagerBase::~PassManagerBase.  
proc DisposePassManager*(PM: PassManagerRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposePassManager".}
  # Analysis.h  
  # verifier will print to stderr and abort()  
  # verifier will print to stderr and return 1  
  # verifier will just return 1  
type 
  VerifierFailureAction* = enum  # Verifies that a module is valid, taking the specified action if not.
                                 #   Optionally returns a human-readable description of any invalid constructs.
                                 #   OutMessage must be disposed with LLVMDisposeMessage.  
    AbortProcessAction, PrintMessageAction, ReturnStatusAction

proc VerifyModule*(M: ModuleRef, Action: VerifierFailureAction, 
                   OutMessage: var cstring): int32{.cdecl, dynlib: libname, 
    importc: "LLVMVerifyModule".}
  # Verifies that a single function is valid, taking the specified action. Useful
  #   for debugging.  
proc VerifyFunction*(Fn: ValueRef, Action: VerifierFailureAction): int32{.cdecl, 
    dynlib: libname, importc: "LLVMVerifyFunction".}
  # Open up a ghostview window that displays the CFG of the current function.
  #   Useful for debugging.  
proc ViewFunctionCFG*(Fn: ValueRef){.cdecl, dynlib: libname, 
                                     importc: "LLVMViewFunctionCFG".}
proc ViewFunctionCFGOnly*(Fn: ValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMViewFunctionCFGOnly".}
  # BitReader.h  
  # Builds a module from the bitcode in the specified memory buffer, returning a
  #   reference to the module via the OutModule parameter. Returns 0 on success.
  #   Optionally returns a human-readable error message via OutMessage.  
proc ParseBitcode*(MemBuf: MemoryBufferRef, OutModule: var ModuleRef, 
                   OutMessage: var cstring): int32{.cdecl, dynlib: libname, 
    importc: "LLVMParseBitcode".}
proc ParseBitcodeInContext*(ContextRef: ContextRef, MemBuf: MemoryBufferRef, 
                            OutModule: var ModuleRef, OutMessage: var cstring): int32{.
    cdecl, dynlib: libname, importc: "LLVMParseBitcodeInContext".}
  # Reads a module from the specified path, returning via the OutMP parameter
  #   a module provider which performs lazy deserialization. Returns 0 on success.
  #   Optionally returns a human-readable error message via OutMessage.  
proc GetBitcodeModuleProvider*(MemBuf: MemoryBufferRef, 
                               OutMP: var ModuleProviderRef,
                               OutMessage: var cstring): int32{.
    cdecl, dynlib: libname, importc: "LLVMGetBitcodeModuleProvider".}
proc GetBitcodeModuleProviderInContext*(ContextRef: ContextRef, 
                                        MemBuf: MemoryBufferRef, 
                                        OutMP: var ModuleProviderRef, 
                                        OutMessage: var cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMGetBitcodeModuleProviderInContext".}
  # BitWriter.h  
  #===-- Operations on modules ---------------------------------------------=== 
  # Writes a module to an open file descriptor. Returns 0 on success.
  #   Closes the Handle. Use dup first if this is not what you want.  
proc WriteBitcodeToFileHandle*(M: ModuleRef, Handle: int32): int32{.cdecl, 
    dynlib: libname, importc: "LLVMWriteBitcodeToFileHandle".}
  # Writes a module to the specified path. Returns 0 on success.  
proc WriteBitcodeToFile*(M: ModuleRef, Path: cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMWriteBitcodeToFile".}
  # Target.h  
const 
  BigEndian* = 0
  LittleEndian* = 1

type 
  ByteOrdering* = int32
  OpaqueTargetData {.pure} = object
  StructLayout {.pure} = object
  TargetDataRef* = ref OpaqueTargetData
  StructLayoutRef* = ref StructLayout
  
  
#===-- Target Data -------------------------------------------------------=== 
# Creates target data from a target layout string.
# See the constructor llvm::TargetData::TargetData.  

proc CreateTargetData*(StringRep: cstring): TargetDataRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateTargetData".}
  # Adds target data information to a pass manager. This does not take ownership
  #    of the target data.
  #    See the method llvm::PassManagerBase::add.  
proc AddTargetData*(para1: TargetDataRef, para2: PassManagerRef){.cdecl, 
    dynlib: libname, importc: "LLVMAddTargetData".}
  # Converts target data to a target layout string. The string must be disposed
  #    with LLVMDisposeMessage.
  #    See the constructor llvm::TargetData::TargetData.  
proc CopyStringRepOfTargetData*(para1: TargetDataRef): cstring{.cdecl, 
    dynlib: libname, importc: "LLVMCopyStringRepOfTargetData".}
  # Returns the byte order of a target, either LLVMBigEndian or
  #    LLVMLittleEndian.
  #    See the method llvm::TargetData::isLittleEndian.  
proc ByteOrder*(para1: TargetDataRef): ByteOrdering{.cdecl, dynlib: libname, 
    importc: "LLVMByteOrder".}
  # Returns the pointer size in bytes for a target.
  #    See the method llvm::TargetData::getPointerSize.  
proc PointerSize*(para1: TargetDataRef): int32{.cdecl, dynlib: libname, 
    importc: "LLVMPointerSize".}
  # Returns the integer type that is the same size as a pointer on a target.
  #    See the method llvm::TargetData::getIntPtrType.  
proc IntPtrType*(para1: TargetDataRef): TypeRef{.cdecl, dynlib: libname, 
    importc: "LLVMIntPtrType".}
  # Computes the size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeSizeInBits.  
proc SizeOfTypeInBits*(para1: TargetDataRef, para2: TypeRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMSizeOfTypeInBits".}
  # Computes the storage size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeStoreSize.  
proc StoreSizeOfType*(para1: TargetDataRef, para2: TypeRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMStoreSizeOfType".}
  # Computes the ABI size of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeAllocSize.  
proc ABISizeOfType*(para1: TargetDataRef, para2: TypeRef): int64{.cdecl, 
    dynlib: libname, importc: "LLVMABISizeOfType".}
  # Computes the ABI alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc ABIAlignmentOfType*(para1: TargetDataRef, para2: TypeRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMABIAlignmentOfType".}
  # Computes the call frame alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc CallFrameAlignmentOfType*(para1: TargetDataRef, para2: TypeRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMCallFrameAlignmentOfType".}
  # Computes the preferred alignment of a type in bytes for a target.
  #    See the method llvm::TargetData::getTypeABISize.  
proc PreferredAlignmentOfType*(para1: TargetDataRef, para2: TypeRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMPreferredAlignmentOfType".}
  # Computes the preferred alignment of a global variable in bytes for a target.
  #    See the method llvm::TargetData::getPreferredAlignment.  
proc PreferredAlignmentOfGlobal*(para1: TargetDataRef, GlobalVar: ValueRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMPreferredAlignmentOfGlobal".}
  # Computes the structure element that contains the byte offset for a target.
  #    See the method llvm::StructLayout::getElementContainingOffset.  
proc ElementAtOffset*(para1: TargetDataRef, StructTy: TypeRef, Offset: int64): int32{.
    cdecl, dynlib: libname, importc: "LLVMElementAtOffset".}
  # Computes the byte offset of the indexed struct element for a target.
  #    See the method llvm::StructLayout::getElementContainingOffset.  
proc OffsetOfElement*(para1: TargetDataRef, StructTy: TypeRef, Element: int32): int64{.
    cdecl, dynlib: libname, importc: "LLVMOffsetOfElement".}
  # Struct layouts are speculatively cached. If a TargetDataRef is alive when
  #    types are being refined and removed, this method must be called whenever a
  #    struct type is removed to avoid a dangling pointer in this cache.
  #    See the method llvm::TargetData::InvalidateStructLayoutInfo.  
proc InvalidateStructLayout*(para1: TargetDataRef, StructTy: TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMInvalidateStructLayout".}
  # Deallocates a TargetData.
  #    See the destructor llvm::TargetData::~TargetData.  
proc DisposeTargetData*(para1: TargetDataRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeTargetData".}
  # ExecutionEngine.h  
proc LinkInJIT*(){.cdecl, dynlib: libname, importc: "LLVMLinkInJIT".}
proc LinkInInterpreter*(){.cdecl, dynlib: libname, 
                           importc: "LLVMLinkInInterpreter".}
type 
  OpaqueGenericValue {.pure} = object
  OpaqueExecutionEngine {.pure} = object
  GenericValueRef* = OpaqueGenericValue
  ExecutionEngineRef* = OpaqueExecutionEngine
  
#===-- Operations on generic values --------------------------------------=== 

proc CreateGenericValueOfInt*(Ty: TypeRef, N: int64, IsSigned: int32): GenericValueRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateGenericValueOfInt".}
proc CreateGenericValueOfPointer*(P: pointer): GenericValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateGenericValueOfPointer".}
proc CreateGenericValueOfFloat*(Ty: TypeRef, N: float64): GenericValueRef{.
    cdecl, dynlib: libname, importc: "LLVMCreateGenericValueOfFloat".}
proc GenericValueIntWidth*(GenValRef: GenericValueRef): int32{.cdecl, 
    dynlib: libname, importc: "LLVMGenericValueIntWidth".}
proc GenericValueToInt*(GenVal: GenericValueRef, IsSigned: int32): int64{.cdecl, 
    dynlib: libname, importc: "LLVMGenericValueToInt".}
proc GenericValueToPointer*(GenVal: GenericValueRef): pointer{.cdecl, 
    dynlib: libname, importc: "LLVMGenericValueToPointer".}
proc GenericValueToFloat*(TyRef: TypeRef, GenVal: GenericValueRef): float64{.
    cdecl, dynlib: libname, importc: "LLVMGenericValueToFloat".}
proc DisposeGenericValue*(GenVal: GenericValueRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeGenericValue".}
  
#===-- Operations on execution engines -----------------------------------=== 
proc CreateExecutionEngine*(OutEE: var ExecutionEngineRef, MP: ModuleProviderRef, 
                            OutError: var cstring): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCreateExecutionEngine".}
proc CreateInterpreter*(OutInterp: var ExecutionEngineRef, MP: ModuleProviderRef, 
                        OutError: var cstring): int32{.cdecl, dynlib: libname, 
    importc: "LLVMCreateInterpreter".}
proc CreateJITCompiler*(OutJIT: var ExecutionEngineRef, MP: ModuleProviderRef, 
                        OptLevel: int32, OutError: var cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMCreateJITCompiler".}
proc DisposeExecutionEngine*(EE: ExecutionEngineRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeExecutionEngine".}
proc RunStaticConstructors*(EE: ExecutionEngineRef){.cdecl, dynlib: libname, 
    importc: "LLVMRunStaticConstructors".}
proc RunStaticDestructors*(EE: ExecutionEngineRef){.cdecl, dynlib: libname, 
    importc: "LLVMRunStaticDestructors".}

proc RunFunctionAsMain*(EE: ExecutionEngineRef, F: ValueRef, ArgC: int32, 
                        ArgV: cstringArray, EnvP: cstringArray): int32{.cdecl, 
    dynlib: libname, importc: "LLVMRunFunctionAsMain".}
proc RunFunction*(EE: ExecutionEngineRef, F: ValueRef, NumArgs: int32, 
                  Args: ptr GenericValueRef): GenericValueRef{.cdecl, 
    dynlib: libname, importc: "LLVMRunFunction".}
proc FreeMachineCodeForFunction*(EE: ExecutionEngineRef, F: ValueRef){.cdecl, 
    dynlib: libname, importc: "LLVMFreeMachineCodeForFunction".}
proc AddModuleProvider*(EE: ExecutionEngineRef, MP: ModuleProviderRef){.cdecl, 
    dynlib: libname, importc: "LLVMAddModuleProvider".}
proc RemoveModuleProvider*(EE: ExecutionEngineRef, MP: ModuleProviderRef, 
                           OutMod: var ModuleRef, OutError: var cstring): int32{.cdecl, 
    dynlib: libname, importc: "LLVMRemoveModuleProvider".}
proc FindFunction*(EE: ExecutionEngineRef, Name: cstring, OutFn: var ValueRef): int32{.
    cdecl, dynlib: libname, importc: "LLVMFindFunction".}
proc GetExecutionEngineTargetData*(EE: ExecutionEngineRef): TargetDataRef{.
    cdecl, dynlib: libname, importc: "LLVMGetExecutionEngineTargetData".}
proc AddGlobalMapping*(EE: ExecutionEngineRef, Global: ValueRef, 
                       theAddr: pointer){.cdecl, dynlib: libname, 
    importc: "LLVMAddGlobalMapping".}
proc GetPointerToGlobal*(EE: ExecutionEngineRef, Global: ValueRef): pointer{.
    cdecl, dynlib: libname, importc: "LLVMGetPointerToGlobal".}

# LinkTimeOptimizer.h  
# This provides a dummy type for pointers to the LTO object. 
type 
  lto_t* = pointer
  lto_status* = enum 
    LTO_UNKNOWN, LTO_OPT_SUCCESS, LTO_READ_SUCCESS, LTO_READ_FAILURE, 
    LTO_WRITE_FAILURE, LTO_NO_TARGET, LTO_NO_WORK, LTO_MODULE_MERGE_FAILURE, 
    LTO_ASM_FAILURE, LTO_NULL_OBJECT
  lto_status_t* = lto_status
  # This provides C interface to initialize link time optimizer. This allows 
  # linker to use dlopen() interface to dynamically load LinkTimeOptimizer. 
  # extern "C" helps, because dlopen() interface uses name to find the symbol. 

proc create_optimizer*(): lto_t{.cdecl, dynlib: libname, 
                                 importc: "llvm_create_optimizer".}
proc destroy_optimizer*(lto: lto_t){.cdecl, dynlib: libname, 
                                     importc: "llvm_destroy_optimizer".}
proc read_object_file*(lto: lto_t, input_filename: cstring): lto_status_t{.
    cdecl, dynlib: libname, importc: "llvm_read_object_file".}
proc optimize_modules*(lto: lto_t, output_filename: cstring): lto_status_t{.
    cdecl, dynlib: libname, importc: "llvm_optimize_modules".}
  
# lto.h  
const 
  LTO_API_VERSION* = 3        # log2 of alignment  

type 
  lto_symbol_attributes* = enum 
    SYMBOL_ALIGNMENT_MASK = 0x0000001F,
    SYMBOL_PERMISSIONS_RODATA = 0x00000080,
    SYMBOL_PERMISSIONS_CODE = 0x000000A0,
    SYMBOL_PERMISSIONS_DATA = 0x000000C0, 
    SYMBOL_PERMISSIONS_MASK = 0x000000E0, 
    
    SYMBOL_DEFINITION_REGULAR = 0x00000100, 
    SYMBOL_DEFINITION_TENTATIVE = 0x00000200, 
    SYMBOL_DEFINITION_WEAK = 0x00000300, 
    SYMBOL_DEFINITION_UNDEFINED = 0x00000400, 
    SYMBOL_DEFINITION_WEAKUNDEF = 0x00000500,
    SYMBOL_DEFINITION_MASK = 0x00000700, 
    SYMBOL_SCOPE_INTERNAL = 0x00000800,
    
    SYMBOL_SCOPE_HIDDEN = 0x00001000,
    SYMBOL_SCOPE_DEFAULT = 0x00001800,
    SYMBOL_SCOPE_PROTECTED = 0x00002000,
    SYMBOL_SCOPE_MASK = 0x00003800, 
  lto_debug_model* = enum 
    DEBUG_MODEL_NONE = 0, DEBUG_MODEL_DWARF = 1
  lto_codegen_model* = enum
    CODEGEN_PIC_MODEL_STATIC = 0, CODEGEN_PIC_MODEL_DYNAMIC = 1, 
    CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2
  
  LTOModule {.pure} = object
  LTOCodeGenerator {.pure} = object
  lto_module_t* = ref LTOModule
  lto_code_gen_t* = ref LTOCodeGenerator

proc lto_get_version*(): cstring{.cdecl, dynlib: libname, 
                                  importc: "lto_get_version".}
  #
  # Returns the last error string or NULL if last operation was sucessful.
  #  
proc lto_get_error_message*(): cstring{.cdecl, dynlib: libname, 
                                        importc: "lto_get_error_message".}
  #
  # Checks if a file is a loadable object file.
  #  
proc lto_module_is_object_file*(path: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file".}
  #
  # Checks if a file is a loadable object compiled for requested target.
  #  
proc lto_module_is_object_file_for_target*(path: cstring, 
    target_triple_prefix: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file_for_target".}
  #
  # Checks if a buffer is a loadable object file.
  #  
proc lto_module_is_object_file_in_memory*(mem: pointer, len: int): bool{.
    cdecl, dynlib: libname, importc: "lto_module_is_object_file_in_memory".}
  #
  # Checks if a buffer is a loadable object compiled for requested target.
  #  
proc lto_module_is_object_file_in_memory_for_target*(mem: pointer, len: int, 
    target_triple_prefix: cstring): bool{.cdecl, dynlib: libname, 
    importc: "lto_module_is_object_file_in_memory_for_target".}
  #
  # Loads an object file from disk.
  # Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_module_create*(path: cstring): lto_module_t{.cdecl, dynlib: libname, 
    importc: "lto_module_create".}
  #
  # Loads an object file from memory.
  # Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_module_create_from_memory*(mem: pointer, len: int): lto_module_t{.
    cdecl, dynlib: libname, importc: "lto_module_create_from_memory".}
  #
  # Frees all memory internally allocated by the module.
  # Upon return the lto_module_t is no longer valid.
  #  
proc lto_module_dispose*(module: lto_module_t){.cdecl, dynlib: libname, 
    importc: "lto_module_dispose".}
  #
  # Returns triple string which the object module was compiled under.
  #  
proc lto_module_get_target_triple*(module: lto_module_t): cstring{.cdecl, 
    dynlib: libname, importc: "lto_module_get_target_triple".}
  #
  # Returns the number of symbols in the object module.
  #  
proc lto_module_get_num_symbols*(module: lto_module_t): int32{.cdecl, 
    dynlib: libname, importc: "lto_module_get_num_symbols".}
  #
  # Returns the name of the ith symbol in the object module.
  #  
proc lto_module_get_symbol_name*(module: lto_module_t, index: int32): cstring{.
    cdecl, dynlib: libname, importc: "lto_module_get_symbol_name".}
  #
  # Returns the attributes of the ith symbol in the object module.
  #  
proc lto_module_get_symbol_attribute*(module: lto_module_t, index: int32): lto_symbol_attributes{.
    cdecl, dynlib: libname, importc: "lto_module_get_symbol_attribute".}
  #
  # Instantiates a code generator.
  # Returns NULL on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_create*(): lto_code_gen_t{.cdecl, dynlib: libname, 
    importc: "lto_codegen_create".}
  #
  # Frees all code generator and all memory it internally allocated.
  # Upon return the lto_code_gen_t is no longer valid.
  #  
proc lto_codegen_dispose*(para1: lto_code_gen_t){.cdecl, dynlib: libname, 
    importc: "lto_codegen_dispose".}
  #
  # Add an object module to the set of modules for which code will be generated.
  # Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_add_module*(cg: lto_code_gen_t, module: lto_module_t): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_add_module".}
  #
  # Sets if debug info should be generated.
  # Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_set_debug_model*(cg: lto_code_gen_t, para2: lto_debug_model): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_set_debug_model".}
  #
  # Sets which PIC code model to generated.
  # Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_set_pic_model*(cg: lto_code_gen_t, para2: lto_codegen_model): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_set_pic_model".}
  #
  # Sets the location of the "gcc" to run. If not set, libLTO will search for
  # "gcc" on the path.
  #  
proc lto_codegen_set_gcc_path*(cg: lto_code_gen_t, path: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_set_gcc_path".}
  #
  # Sets the location of the assembler tool to run. If not set, libLTO
  # will use gcc to invoke the assembler.
  #  
proc lto_codegen_set_assembler_path*(cg: lto_code_gen_t, path: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_set_assembler_path".}
  #
  # Adds to a list of all global symbols that must exist in the final
  # generated code.  If a function is not listed, it might be
  # inlined into every usage and optimized away.
  #  
proc lto_codegen_add_must_preserve_symbol*(cg: lto_code_gen_t, symbol: cstring){.
    cdecl, dynlib: libname, importc: "lto_codegen_add_must_preserve_symbol".}
  #
  # Writes a new object file at the specified path that contains the
  # merged contents of all modules added so far.
  # Returns true on error (check lto_get_error_message() for details).
  #  
proc lto_codegen_write_merged_modules*(cg: lto_code_gen_t, path: cstring): bool{.
    cdecl, dynlib: libname, importc: "lto_codegen_write_merged_modules".}
  #
  # Generates code for all added modules into one native object file.
  # On sucess returns a pointer to a generated mach-o/ELF buffer and
  # length set to the buffer size.  The buffer is owned by the 
  # lto_code_gen_t and will be freed when lto_codegen_dispose()
  # is called, or lto_codegen_compile() is called again.
  # On failure, returns NULL (check lto_get_error_message() for details).
  #  
proc lto_codegen_compile*(cg: lto_code_gen_t, len: var int): pointer{.cdecl, 
    dynlib: libname, importc: "lto_codegen_compile".}
  #
  # Sets options to help debug codegen bugs.
  #  
proc lto_codegen_debug_options*(cg: lto_code_gen_t, para2: cstring){.cdecl, 
    dynlib: libname, importc: "lto_codegen_debug_options".}
