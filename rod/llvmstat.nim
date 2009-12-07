#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module implements the interface to LLVM.

import # Opaque types.  
       #
       #  The top-level container for all other LLVM Intermediate Representation (IR)
       #  objects. See the llvm::Module class.
       #
  ropes

type 
  cuint* = int32
  TLLVMTypeKind* = enum 
    LLVMVoidTypeKind,         # type with no size
    LLVMFloatTypeKind,        # 32 bit floating point type
    LLVMDoubleTypeKind,       # 64 bit floating point type
    LLVMX86_FP80TypeKind,     # 80 bit floating point type (X87)
    LLVMFP128TypeKind,        # 128 bit floating point type (112-bit mantissa)
    LLVMPPC_FP128TypeKind,    # 128 bit floating point type (two 64-bits)
    LLVMLabelTypeKind,        # Labels
    LLVMIntegerTypeKind,      # Arbitrary bit width integers
    LLVMFunctionTypeKind,     # Functions
    LLVMStructTypeKind,       # Structures
    LLVMArrayTypeKind,        # Arrays
    LLVMPointerTypeKind,      # Pointers
    LLVMOpaqueTypeKind,       # Opaque: type with unknown structure
    LLVMVectorTypeKind        # SIMD 'packed' format, or other vector type
  TLLVMLinkage* = enum 
    LLVMExternalLinkage,      # Externally visible function
    LLVMLinkOnceLinkage,      # Keep one copy of function when linking (inline)
    LLVMWeakLinkage,          # Keep one copy of function when linking (weak)
    LLVMAppendingLinkage,     # Special purpose, only applies to global arrays
    LLVMInternalLinkage,      # Rename collisions when linking (static functions)
    LLVMDLLImportLinkage,     # Function to be imported from DLL
    LLVMDLLExportLinkage,     # Function to be accessible from DLL
    LLVMExternalWeakLinkage,  # ExternalWeak linkage description
    LLVMGhostLinkage          # Stand-in functions for streaming fns from bitcode
  TLLVMVisibility* = enum 
    LLVMDefaultVisibility,    # The GV is visible
    LLVMHiddenVisibility,     # The GV is hidden
    LLVMProtectedVisibility   # The GV is protected
  TLLVMCallConv* = enum 
    LLVMCCallConv = 0, LLVMFastCallConv = 8, LLVMColdCallConv = 9, 
    LLVMX86StdcallCallConv = 64, LLVMX86FastcallCallConv = 65
  TLLVMIntPredicate* = enum 
    LLVMIntEQ = 32,           # equal
    LLVMIntNE,                # not equal
    LLVMIntUGT,               # unsigned greater than
    LLVMIntUGE,               # unsigned greater or equal
    LLVMIntULT,               # unsigned less than
    LLVMIntULE,               # unsigned less or equal
    LLVMIntSGT,               # signed greater than
    LLVMIntSGE,               # signed greater or equal
    LLVMIntSLT,               # signed less than
    LLVMIntSLE                # signed less or equal
  TLLVMRealPredicate* = enum 
    LLVMRealPredicateFalse,   # Always false (always folded)
    LLVMRealOEQ,              # True if ordered and equal
    LLVMRealOGT,              # True if ordered and greater than
    LLVMRealOGE,              # True if ordered and greater than or equal
    LLVMRealOLT,              # True if ordered and less than
    LLVMRealOLE,              # True if ordered and less than or equal
    LLVMRealONE,              # True if ordered and operands are unequal
    LLVMRealORD,              # True if ordered (no nans)
    LLVMRealUNO,              # True if unordered: isnan(X) | isnan(Y)
    LLVMRealUEQ,              # True if unordered or equal
    LLVMRealUGT,              # True if unordered or greater than
    LLVMRealUGE,              # True if unordered, greater than, or equal
    LLVMRealULT,              # True if unordered or less than
    LLVMRealULE,              # True if unordered, less than, or equal
    LLVMRealUNE,              # True if unordered or not equal
    LLVMRealPredicateTrue     # Always true (always folded)
  PLLVMBasicBlockRef* = ref TLLVMBasicBlockRef
  PLLVMMemoryBufferRef* = ref TLLVMMemoryBufferRef
  PLLVMTypeRef* = ref TLLVMTypeRef
  PLLVMValueRef* = ref TLLVMValueRef
  TLLVMOpaqueModule*{.final.} = object 
    code*: PRope

  TLLVMModuleRef* = ref TLLVMOpaqueModule #
                                          #  Each value in the LLVM IR has a type, an instance of [lltype]. See the
                                          #  llvm::Type class.
                                          #
  TLLVMOpaqueType*{.final.} = object 
    kind*: TLLVMTypeKind

  TLLVMTypeRef* = ref TLLVMOpaqueType #
                                      #  When building recursive types using [refine_type], [lltype] values may become
                                      #  invalid; use [lltypehandle] to resolve this problem. See the
                                      #  llvm::AbstractTypeHolder] class.
                                      #
  TLLVMOpaqueTypeHandle*{.final.} = object 
  TLLVMTypeHandleRef* = ref TLLVMOpaqueTypeHandle
  TLLVMOpaqueValue*{.final.} = object 
  TLLVMValueRef* = ref TLLVMOpaqueValue
  TLLVMOpaqueBasicBlock*{.final.} = object 
  TLLVMBasicBlockRef* = ref TLLVMOpaqueBasicBlock
  TLLVMOpaqueBuilder*{.final.} = object 
  TLLVMBuilderRef* = ref TLLVMOpaqueBuilder # Used to provide a module to JIT or interpreter.
                                            #  See the llvm::ModuleProvider class.
                                            #
  TLLVMOpaqueModuleProvider*{.final.} = object 
  TLLVMModuleProviderRef* = ref TLLVMOpaqueModuleProvider # Used to provide a module to JIT or interpreter.
                                                          #  See the llvm: : MemoryBuffer class.
                                                          #
  TLLVMOpaqueMemoryBuffer*{.final.} = object 
  TLLVMMemoryBufferRef* = ref TLLVMOpaqueMemoryBuffer #===-- Error handling ----------------------------------------------------=== 

proc LLVMDisposeMessage*(msg: cstring){.cdecl.}
  #===-- Modules -----------------------------------------------------------=== 
  # Create and destroy modules.  
proc LLVMModuleCreateWithName*(ModuleID: cstring): TLLVMModuleRef{.cdecl.}
proc LLVMDisposeModule*(M: TLLVMModuleRef){.cdecl.}
  # Data layout  
proc LLVMGetDataLayout*(M: TLLVMModuleRef): cstring{.cdecl.}
proc LLVMSetDataLayout*(M: TLLVMModuleRef, Triple: cstring){.cdecl.}
  # Target triple  
proc LLVMGetTarget*(M: TLLVMModuleRef): cstring{.cdecl.}
proc LLVMSetTarget*(M: TLLVMModuleRef, Triple: cstring){.cdecl.}
  # Same as Module: : addTypeName.  
proc LLVMAddTypeName*(M: TLLVMModuleRef, Name: cstring, Ty: TLLVMTypeRef): int32{.
    cdecl.}
proc LLVMDeleteTypeName*(M: TLLVMModuleRef, Name: cstring){.cdecl.}
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
proc LLVMGetTypeKind*(Ty: TLLVMTypeRef): TLLVMTypeKind{.cdecl.}
proc LLVMRefineAbstractType*(AbstractType: TLLVMTypeRef, 
                             ConcreteType: TLLVMTypeRef){.cdecl.}
  # Operations on integer types  
proc LLVMInt1Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMInt8Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMInt16Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMInt32Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMInt64Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMIntType*(NumBits: cuint): TLLVMTypeRef{.cdecl.}
proc LLVMGetIntTypeWidth*(IntegerTy: TLLVMTypeRef): cuint{.cdecl.}
  # Operations on real types  
proc LLVMFloatType*(): TLLVMTypeRef{.cdecl.}
proc LLVMDoubleType*(): TLLVMTypeRef{.cdecl.}
proc LLVMX86FP80Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMFP128Type*(): TLLVMTypeRef{.cdecl.}
proc LLVMPPCFP128Type*(): TLLVMTypeRef{.cdecl.}
  # Operations on function types  
proc LLVMFunctionType*(ReturnType: TLLVMTypeRef, ParamTypes: PLLVMTypeRef, 
                       ParamCount: cuint, IsVarArg: int32): TLLVMTypeRef{.cdecl.}
proc LLVMIsFunctionVarArg*(FunctionTy: TLLVMTypeRef): int32{.cdecl.}
proc LLVMGetReturnType*(FunctionTy: TLLVMTypeRef): TLLVMTypeRef{.cdecl.}
proc LLVMCountParamTypes*(FunctionTy: TLLVMTypeRef): cuint{.cdecl.}
proc LLVMGetParamTypes*(FunctionTy: TLLVMTypeRef, Dest: PLLVMTypeRef){.cdecl.}
  # Operations on struct types  
proc LLVMStructType*(ElementTypes: PLLVMTypeRef, ElementCount: cuint, 
                     isPacked: int32): TLLVMTypeRef{.cdecl.}
proc LLVMCountStructElementTypes*(StructTy: TLLVMTypeRef): cuint{.cdecl.}
proc LLVMGetStructElementTypes*(StructTy: TLLVMTypeRef, Dest: pLLVMTypeRef){.
    cdecl.}
proc LLVMIsPackedStruct*(StructTy: TLLVMTypeRef): int32{.cdecl.}
  # Operations on array, pointer, and vector types (sequence types)  
proc LLVMArrayType*(ElementType: TLLVMTypeRef, ElementCount: cuint): TLLVMTypeRef{.
    cdecl.}
proc LLVMPointerType*(ElementType: TLLVMTypeRef, AddressSpace: cuint): TLLVMTypeRef{.
    cdecl.}
proc LLVMVectorType*(ElementType: TLLVMTypeRef, ElementCount: cuint): TLLVMTypeRef{.
    cdecl.}
proc LLVMGetElementType*(Ty: TLLVMTypeRef): TLLVMTypeRef{.cdecl.}
proc LLVMGetArrayLength*(ArrayTy: TLLVMTypeRef): cuint{.cdecl.}
proc LLVMGetPointerAddressSpace*(PointerTy: TLLVMTypeRef): cuint{.cdecl.}
proc LLVMGetVectorSize*(VectorTy: TLLVMTypeRef): cuint{.cdecl.}
  # Operations on other types  
proc LLVMVoidType*(): TLLVMTypeRef{.cdecl.}
proc LLVMLabelType*(): TLLVMTypeRef{.cdecl.}
proc LLVMOpaqueType*(): TLLVMTypeRef{.cdecl.}
  # Operations on type handles  
proc LLVMCreateTypeHandle*(PotentiallyAbstractTy: TLLVMTypeRef): TLLVMTypeHandleRef{.
    cdecl.}
proc LLVMRefineType*(AbstractTy: TLLVMTypeRef, ConcreteTy: TLLVMTypeRef){.cdecl.}
proc LLVMResolveTypeHandle*(TypeHandle: TLLVMTypeHandleRef): TLLVMTypeRef{.cdecl.}
proc LLVMDisposeTypeHandle*(TypeHandle: TLLVMTypeHandleRef){.cdecl.}
  #===-- Values ------------------------------------------------------------=== 
  # The bulk of LLVM's object model consists of values, which comprise a very
  # * rich type hierarchy.
  # *
  # *   values:
  # *     constants:
  # *       scalar constants
  # *       composite contants
  # *       globals:
  # *         global variable
  # *         function
  # *         alias
  # *       basic blocks
  #  
  # Operations on all values  
proc LLVMTypeOf*(Val: TLLVMValueRef): TLLVMTypeRef{.cdecl.}
proc LLVMGetValueName*(Val: TLLVMValueRef): cstring{.cdecl.}
proc LLVMSetValueName*(Val: TLLVMValueRef, Name: cstring){.cdecl.}
proc LLVMDumpValue*(Val: TLLVMValueRef){.cdecl.}
  # Operations on constants of any type  
proc LLVMConstNull*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl.}
  # all zeroes  
proc LLVMConstAllOnes*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl.}
  # only for int/vector  
proc LLVMGetUndef*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl.}
proc LLVMIsConstant*(Val: TLLVMValueRef): int32{.cdecl.}
proc LLVMIsNull*(Val: TLLVMValueRef): int32{.cdecl.}
proc LLVMIsUndef*(Val: TLLVMValueRef): int32{.cdecl.}
  # Operations on scalar constants  
proc LLVMConstInt*(IntTy: TLLVMTypeRef, N: qword, SignExtend: int32): TLLVMValueRef{.
    cdecl.}
proc LLVMConstReal*(RealTy: TLLVMTypeRef, N: float64): TLLVMValueRef{.cdecl.}
  # Operations on composite constants  
proc LLVMConstString*(Str: cstring, len: cuint, DontNullTerminate: int32): TLLVMValueRef{.
    cdecl.}
proc LLVMConstArray*(ArrayTy: TLLVMTypeRef, ConstantVals: pLLVMValueRef, 
                     len: cuint): TLLVMValueRef{.cdecl.}
proc LLVMConstStruct*(ConstantVals: pLLVMValueRef, Count: cuint, ispacked: int32): TLLVMValueRef{.
    cdecl.}
proc LLVMConstVector*(ScalarConstantVals: pLLVMValueRef, Size: cuint): TLLVMValueRef{.
    cdecl.}
  # Constant expressions  
proc LLVMSizeOf*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl.}
proc LLVMConstNeg*(ConstantVal: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstNot*(ConstantVal: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstAdd*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSub*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstMul*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstUDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstURem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSRem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFRem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstAnd*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstOr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstXor*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstICmp*(Predicate: TLLVMIntPredicate, LHSConstant: TLLVMValueRef, 
                    RHSConstant: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstFCmp*(Predicate: TLLVMRealPredicate, LHSConstant: TLLVMValueRef, 
                    RHSConstant: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstShl*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstLShr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstAShr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstGEP*(ConstantVal: TLLVMValueRef, ConstantIndices: PLLVMValueRef, 
                   NumIndices: cuint): TLLVMValueRef{.cdecl.}
proc LLVMConstTrunc*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstZExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFPTrunc*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFPExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstUIToFP*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSIToFP*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFPToUI*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstFPToSI*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstPtrToInt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstIntToPtr*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstBitCast*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstSelect*(ConstantCondition: TLLVMValueRef, 
                      ConstantIfTrue: TLLVMValueRef, 
                      ConstantIfFalse: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstExtractElement*(VectorConstant: TLLVMValueRef, 
                              IndexConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMConstInsertElement*(VectorConstant: TLLVMValueRef, 
                             ElementValueConstant: TLLVMValueRef, 
                             IndexConstant: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMConstShuffleVector*(VectorAConstant: TLLVMValueRef, 
                             VectorBConstant: TLLVMValueRef, 
                             MaskConstant: TLLVMValueRef): TLLVMValueRef{.cdecl.}
  # Operations on global variables, functions, and aliases (globals)  
proc LLVMIsDeclaration*(Global: TLLVMValueRef): int32{.cdecl.}
proc LLVMGetLinkage*(Global: TLLVMValueRef): TLLVMLinkage{.cdecl.}
proc LLVMSetLinkage*(Global: TLLVMValueRef, Linkage: TLLVMLinkage){.cdecl.}
proc LLVMGetSection*(Global: TLLVMValueRef): cstring{.cdecl.}
proc LLVMSetSection*(Global: TLLVMValueRef, Section: cstring){.cdecl.}
proc LLVMGetVisibility*(Global: TLLVMValueRef): TLLVMVisibility{.cdecl.}
proc LLVMSetVisibility*(Global: TLLVMValueRef, Viz: TLLVMVisibility){.cdecl.}
proc LLVMGetAlignment*(Global: TLLVMValueRef): cuint{.cdecl.}
proc LLVMSetAlignment*(Global: TLLVMValueRef, Bytes: cuint){.cdecl.}
  # Operations on global variables  
  # Const before type ignored 
proc LLVMAddGlobal*(M: TLLVMModuleRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
  # Const before type ignored 
proc LLVMGetNamedGlobal*(M: TLLVMModuleRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMDeleteGlobal*(GlobalVar: TLLVMValueRef){.cdecl.}
proc LLVMHasInitializer*(GlobalVar: TLLVMValueRef): int32{.cdecl.}
proc LLVMGetInitializer*(GlobalVar: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMSetInitializer*(GlobalVar: TLLVMValueRef, ConstantVal: TLLVMValueRef){.
    cdecl.}
proc LLVMIsThreadLocal*(GlobalVar: TLLVMValueRef): int32{.cdecl.}
proc LLVMSetThreadLocal*(GlobalVar: TLLVMValueRef, IsThreadLocal: int32){.cdecl.}
proc LLVMIsGlobalConstant*(GlobalVar: TLLVMValueRef): int32{.cdecl.}
proc LLVMSetGlobalConstant*(GlobalVar: TLLVMValueRef, IsConstant: int32){.cdecl.}
  # Operations on functions  
  # Const before type ignored 
proc LLVMAddFunction*(M: TLLVMModuleRef, Name: cstring, FunctionTy: TLLVMTypeRef): TLLVMValueRef{.
    cdecl.}
  # Const before type ignored 
proc LLVMGetNamedFunction*(M: TLLVMModuleRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMDeleteFunction*(Fn: TLLVMValueRef){.cdecl.}
proc LLVMCountParams*(Fn: TLLVMValueRef): cuint{.cdecl.}
proc LLVMGetParams*(Fn: TLLVMValueRef, Params: PLLVMValueRef){.cdecl.}
proc LLVMGetParam*(Fn: TLLVMValueRef, Index: cuint): TLLVMValueRef{.cdecl.}
proc LLVMGetIntrinsicID*(Fn: TLLVMValueRef): cuint{.cdecl.}
proc LLVMGetFunctionCallConv*(Fn: TLLVMValueRef): cuint{.cdecl.}
proc LLVMSetFunctionCallConv*(Fn: TLLVMValueRef, CC: cuint){.cdecl.}
  # Const before type ignored 
proc LLVMGetCollector*(Fn: TLLVMValueRef): cstring{.cdecl.}
  # Const before type ignored 
proc LLVMSetCollector*(Fn: TLLVMValueRef, Coll: cstring){.cdecl.}
  # Operations on basic blocks  
proc LLVMBasicBlockAsValue*(Bb: TLLVMBasicBlockRef): TLLVMValueRef{.cdecl.}
proc LLVMValueIsBasicBlock*(Val: TLLVMValueRef): int32{.cdecl.}
proc LLVMValueAsBasicBlock*(Val: TLLVMValueRef): TLLVMBasicBlockRef{.cdecl.}
proc LLVMCountBasicBlocks*(Fn: TLLVMValueRef): cuint{.cdecl.}
proc LLVMGetBasicBlocks*(Fn: TLLVMValueRef, BasicBlocks: PLLVMBasicBlockRef){.
    cdecl.}
proc LLVMGetEntryBasicBlock*(Fn: TLLVMValueRef): TLLVMBasicBlockRef{.cdecl.}
  # Const before type ignored 
proc LLVMAppendBasicBlock*(Fn: TLLVMValueRef, Name: cstring): TLLVMBasicBlockRef{.
    cdecl.}
  # Const before type ignored 
proc LLVMInsertBasicBlock*(InsertBeforeBB: TLLVMBasicBlockRef, Name: cstring): TLLVMBasicBlockRef{.
    cdecl.}
proc LLVMDeleteBasicBlock*(BB: TLLVMBasicBlockRef){.cdecl.}
  # Operations on call sites  
proc LLVMSetInstructionCallConv*(Instr: TLLVMValueRef, CC: cuint){.cdecl.}
proc LLVMGetInstructionCallConv*(Instr: TLLVMValueRef): cuint{.cdecl.}
  # Operations on phi nodes  
proc LLVMAddIncoming*(PhiNode: TLLVMValueRef, IncomingValues: PLLVMValueRef, 
                      IncomingBlocks: PLLVMBasicBlockRef, Count: cuint){.cdecl.}
proc LLVMCountIncoming*(PhiNode: TLLVMValueRef): cuint{.cdecl.}
proc LLVMGetIncomingValue*(PhiNode: TLLVMValueRef, Index: cuint): TLLVMValueRef{.
    cdecl.}
proc LLVMGetIncomingBlock*(PhiNode: TLLVMValueRef, Index: cuint): TLLVMBasicBlockRef{.
    cdecl.}
  #===-- Instruction builders ----------------------------------------------=== 
  # An instruction builder represents a point within a basic block, and is the
  # * exclusive means of building instructions using the C interface.
  #  
proc LLVMCreateBuilder*(): TLLVMBuilderRef{.cdecl.}
proc LLVMPositionBuilderBefore*(Builder: TLLVMBuilderRef, Instr: TLLVMValueRef){.
    cdecl.}
proc LLVMPositionBuilderAtEnd*(Builder: TLLVMBuilderRef, 
                               theBlock: TLLVMBasicBlockRef){.cdecl.}
proc LLVMDisposeBuilder*(Builder: TLLVMBuilderRef){.cdecl.}
  # Terminators  
proc LLVMBuildRetVoid*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl.}
proc LLVMBuildRet*(para1: TLLVMBuilderRef, V: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildBr*(para1: TLLVMBuilderRef, Dest: TLLVMBasicBlockRef): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildCondBr*(para1: TLLVMBuilderRef, IfCond: TLLVMValueRef, 
                      ThenBranch: TLLVMBasicBlockRef, 
                      ElseBranch: TLLVMBasicBlockRef): TLLVMValueRef{.cdecl.}
proc LLVMBuildSwitch*(para1: TLLVMBuilderRef, V: TLLVMValueRef, 
                      ElseBranch: TLLVMBasicBlockRef, NumCases: cuint): TLLVMValueRef{.
    cdecl.}
  # Const before type ignored 
proc LLVMBuildInvoke*(para1: TLLVMBuilderRef, Fn: TLLVMValueRef, 
                      Args: PLLVMValueRef, NumArgs: cuint, 
                      ThenBranch: TLLVMBasicBlockRef, Catch: TLLVMBasicBlockRef, 
                      Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildUnwind*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl.}
proc LLVMBuildUnreachable*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl.}
  # Add a case to the switch instruction  
proc LLVMAddCase*(Switch: TLLVMValueRef, OnVal: TLLVMValueRef, 
                  Dest: TLLVMBasicBlockRef){.cdecl.}
  # Arithmetic  
proc LLVMBuildAdd*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildSub*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildMul*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildUDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildSDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildFDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildURem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildSRem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildFRem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildShl*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildLShr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildAShr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildAnd*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildOr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                  RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildXor*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildNeg*(para1: TLLVMBuilderRef, V: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildNot*(para1: TLLVMBuilderRef, V: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
  # Memory  
proc LLVMBuildMalloc*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildArrayMalloc*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, 
                           Val: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildAlloca*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildArrayAlloca*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, 
                           Val: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildFree*(para1: TLLVMBuilderRef, PointerVal: TLLVMValueRef): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildLoad*(para1: TLLVMBuilderRef, PointerVal: TLLVMValueRef, 
                    Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildStore*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     thePtr: TLLVMValueRef): TLLVMValueRef{.cdecl.}
proc LLVMBuildGEP*(B: TLLVMBuilderRef, Pointer: TLLVMValueRef, 
                   Indices: PLLVMValueRef, NumIndices: cuint, Name: cstring): TLLVMValueRef{.
    cdecl.}
  # Casts  
proc LLVMBuildTrunc*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildZExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                    DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildSExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                    DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildFPToUI*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildFPToSI*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildUIToFP*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildSIToFP*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildFPTrunc*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                       DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildFPExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildPtrToInt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                        DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildIntToPtr*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                        DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildBitCast*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                       DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
  # Comparisons  
proc LLVMBuildICmp*(para1: TLLVMBuilderRef, Op: TLLVMIntPredicate, 
                    LHS: TLLVMValueRef, RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildFCmp*(para1: TLLVMBuilderRef, Op: TLLVMRealPredicate, 
                    LHS: TLLVMValueRef, RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
  # Miscellaneous instructions  
proc LLVMBuildPhi*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildCall*(para1: TLLVMBuilderRef, Fn: TLLVMValueRef, 
                    Args: PLLVMValueRef, NumArgs: cuint, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildSelect*(para1: TLLVMBuilderRef, IfCond: TLLVMValueRef, 
                      ThenBranch: TLLVMValueRef, ElseBranch: TLLVMValueRef, 
                      Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildVAArg*(para1: TLLVMBuilderRef, List: TLLVMValueRef, 
                     Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildExtractElement*(para1: TLLVMBuilderRef, VecVal: TLLVMValueRef, 
                              Index: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl.}
proc LLVMBuildInsertElement*(para1: TLLVMBuilderRef, VecVal: TLLVMValueRef, 
                             EltVal: TLLVMValueRef, Index: TLLVMValueRef, 
                             Name: cstring): TLLVMValueRef{.cdecl.}
proc LLVMBuildShuffleVector*(para1: TLLVMBuilderRef, V1: TLLVMValueRef, 
                             V2: TLLVMValueRef, Mask: TLLVMValueRef, 
                             Name: cstring): TLLVMValueRef{.cdecl.}
  #===-- Module providers --------------------------------------------------=== 
  # Encapsulates the module M in a module provider, taking ownership of the
  #  module.
  #  See the constructor llvm: : ExistingModuleProvider: : ExistingModuleProvider.
  #
proc LLVMCreateModuleProviderForExistingModule*(M: TLLVMModuleRef): TLLVMModuleProviderRef{.
    cdecl.}
  # Destroys the module provider MP as well as the contained module.
  #  See the destructor llvm: : ModuleProvider: : ~ModuleProvider.
  #
proc LLVMDisposeModuleProvider*(MP: TLLVMModuleProviderRef){.cdecl.}
  #===-- Memory buffers ----------------------------------------------------=== 
proc LLVMCreateMemoryBufferWithContentsOfFile*(Path: cstring, 
    OutMemBuf: pLLVMMemoryBufferRef, OutMessage: var cstring): int32{.cdecl.}
proc LLVMCreateMemoryBufferWithSTDIN*(OutMemBuf: pLLVMMemoryBufferRef, 
                                      OutMessage: var cstring): int32{.cdecl.}
proc LLVMDisposeMemoryBuffer*(MemBuf: TLLVMMemoryBufferRef){.cdecl.}
proc LLVMWriteBitcodeToFile*(M: TLLVMModuleRef, path: cstring): int{.cdecl.}
  # Writes a module to the specified path. Returns 0 on success.
# implementation
