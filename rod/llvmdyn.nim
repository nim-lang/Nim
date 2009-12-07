#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module implements the interface to LLVM.

const 
  llvmdll* = "llvm.dll" # Opaque types.  
                        #
                        #  The top-level container for all other LLVM Intermediate Representation (IR)
                        #  objects. See the llvm::Module class.
                        #

type 
  cuint* = int32
  PLLVMBasicBlockRef* = ref TLLVMBasicBlockRef
  PLLVMMemoryBufferRef* = ref TLLVMMemoryBufferRef
  PLLVMTypeRef* = ref TLLVMTypeRef
  PLLVMValueRef* = ref TLLVMValueRef
  TLLVMOpaqueModule*{.final.} = object 
  TLLVMModuleRef* = ref TLLVMOpaqueModule #
                                          #  Each value in the LLVM IR has a type, an instance of [lltype]. See the
                                          #  llvm: : Type class.
                                          #
  TLLVMOpaqueType*{.final.} = object 
  TLLVMTypeRef* = ref TLLVMOpaqueType #
                                      #  When building recursive types using [refine_type], [lltype] values may become
                                      #  invalid; use [lltypehandle] to resolve this problem. See the
                                      #  llvm: : AbstractTypeHolder] class.
                                      #
  TLLVMOpaqueTypeHandle*{.final.} = object 
  TLLVMTypeHandleRef* = ref TLLVMOpaqueTypeHandle
  TLLVMOpaqueValue*{.final.} = object 
  TLLVMValueRef* = ref TLLVMOpaqueValue
  TLLVMOpaqueBasicBlock*{.final.} = object 
  TLLVMBasicBlockRef* = ref TLLVMOpaqueBasicBlock
  TLLVMOpaqueBuilder*{.final.} = object 
  TLLVMBuilderRef* = ref TLLVMOpaqueBuilder # Used to provide a module to JIT or interpreter.
                                            #  See the llvm: : ModuleProvider class.
                                            #
  TLLVMOpaqueModuleProvider*{.final.} = object 
  TLLVMModuleProviderRef* = ref TLLVMOpaqueModuleProvider # Used to provide a module to JIT or interpreter.
                                                          #  See the llvm: : MemoryBuffer class.
                                                          #
  TLLVMOpaqueMemoryBuffer*{.final.} = object 
  TLLVMMemoryBufferRef* = ref TLLVMOpaqueMemoryBuffer
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
  TLLVMRealPredicate* = enum  #===-- Error handling ----------------------------------------------------=== 
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

proc LLVMDisposeMessage*(msg: cstring){.cdecl, dynlib: llvmdll, importc.}
  #===-- Modules -----------------------------------------------------------=== 
  # Create and destroy modules.  
proc LLVMModuleCreateWithName*(ModuleID: cstring): TLLVMModuleRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMDisposeModule*(M: TLLVMModuleRef){.cdecl, dynlib: llvmdll, importc.}
  # Data layout  
proc LLVMGetDataLayout*(M: TLLVMModuleRef): cstring{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMSetDataLayout*(M: TLLVMModuleRef, Triple: cstring){.cdecl, 
    dynlib: llvmdll, importc.}
  # Target triple  
proc LLVMGetTarget*(M: TLLVMModuleRef): cstring{.cdecl, dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMSetTarget*(M: TLLVMModuleRef, Triple: cstring){.cdecl, dynlib: llvmdll, 
    importc.}
  # Same as Module: : addTypeName.  
proc LLVMAddTypeName*(M: TLLVMModuleRef, Name: cstring, Ty: TLLVMTypeRef): int32{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMDeleteTypeName*(M: TLLVMModuleRef, Name: cstring){.cdecl, 
    dynlib: llvmdll, importc.}
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
proc LLVMGetTypeKind*(Ty: TLLVMTypeRef): TLLVMTypeKind{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMRefineAbstractType*(AbstractType: TLLVMTypeRef, 
                             ConcreteType: TLLVMTypeRef){.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on integer types  
proc LLVMInt1Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMInt8Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMInt16Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMInt32Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMInt64Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMIntType*(NumBits: cuint): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMGetIntTypeWidth*(IntegerTy: TLLVMTypeRef): cuint{.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on real types  
proc LLVMFloatType*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMDoubleType*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMX86FP80Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMFP128Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMPPCFP128Type*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
  # Operations on function types  
proc LLVMFunctionType*(ReturnType: TLLVMTypeRef, ParamTypes: PLLVMTypeRef, 
                       ParamCount: cuint, IsVarArg: int32): TLLVMTypeRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMIsFunctionVarArg*(FunctionTy: TLLVMTypeRef): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetReturnType*(FunctionTy: TLLVMTypeRef): TLLVMTypeRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMCountParamTypes*(FunctionTy: TLLVMTypeRef): cuint{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetParamTypes*(FunctionTy: TLLVMTypeRef, Dest: PLLVMTypeRef){.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on struct types  
proc LLVMStructType*(ElementTypes: PLLVMTypeRef, ElementCount: cuint, 
                     isPacked: int32): TLLVMTypeRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMCountStructElementTypes*(StructTy: TLLVMTypeRef): cuint{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetStructElementTypes*(StructTy: TLLVMTypeRef, Dest: pLLVMTypeRef){.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMIsPackedStruct*(StructTy: TLLVMTypeRef): int32{.cdecl, dynlib: llvmdll, 
    importc.}
  # Operations on array, pointer, and vector types (sequence types)  
proc LLVMArrayType*(ElementType: TLLVMTypeRef, ElementCount: cuint): TLLVMTypeRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMPointerType*(ElementType: TLLVMTypeRef, AddressSpace: cuint): TLLVMTypeRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMVectorType*(ElementType: TLLVMTypeRef, ElementCount: cuint): TLLVMTypeRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMGetElementType*(Ty: TLLVMTypeRef): TLLVMTypeRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetArrayLength*(ArrayTy: TLLVMTypeRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetPointerAddressSpace*(PointerTy: TLLVMTypeRef): cuint{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetVectorSize*(VectorTy: TLLVMTypeRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
  # Operations on other types  
proc LLVMVoidType*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMLabelType*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMOpaqueType*(): TLLVMTypeRef{.cdecl, dynlib: llvmdll, importc.}
  # Operations on type handles  
proc LLVMCreateTypeHandle*(PotentiallyAbstractTy: TLLVMTypeRef): TLLVMTypeHandleRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMRefineType*(AbstractTy: TLLVMTypeRef, ConcreteTy: TLLVMTypeRef){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMResolveTypeHandle*(TypeHandle: TLLVMTypeHandleRef): TLLVMTypeRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMDisposeTypeHandle*(TypeHandle: TLLVMTypeHandleRef){.cdecl, 
    dynlib: llvmdll, importc.}
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
proc LLVMTypeOf*(Val: TLLVMValueRef): TLLVMTypeRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetValueName*(Val: TLLVMValueRef): cstring{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMSetValueName*(Val: TLLVMValueRef, Name: cstring){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMDumpValue*(Val: TLLVMValueRef){.cdecl, dynlib: llvmdll, importc.}
  # Operations on constants of any type  
proc LLVMConstNull*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
  # all zeroes  
proc LLVMConstAllOnes*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
  # only for int/vector  
proc LLVMGetUndef*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMIsConstant*(Val: TLLVMValueRef): int32{.cdecl, dynlib: llvmdll, importc.}
proc LLVMIsNull*(Val: TLLVMValueRef): int32{.cdecl, dynlib: llvmdll, importc.}
proc LLVMIsUndef*(Val: TLLVMValueRef): int32{.cdecl, dynlib: llvmdll, importc.}
  # Operations on scalar constants  
proc LLVMConstInt*(IntTy: TLLVMTypeRef, N: qword, SignExtend: int32): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstReal*(RealTy: TLLVMTypeRef, N: float64): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on composite constants  
proc LLVMConstString*(Str: cstring, len: cuint, DontNullTerminate: int32): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstArray*(ArrayTy: TLLVMTypeRef, ConstantVals: pLLVMValueRef, 
                     len: cuint): TLLVMValueRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMConstStruct*(ConstantVals: pLLVMValueRef, Count: cuint, ispacked: int32): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstVector*(ScalarConstantVals: pLLVMValueRef, Size: cuint): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Constant expressions  
proc LLVMSizeOf*(Ty: TLLVMTypeRef): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMConstNeg*(ConstantVal: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMConstNot*(ConstantVal: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMConstAdd*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSub*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstMul*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstUDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFDiv*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstURem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSRem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFRem*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstAnd*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstOr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstXor*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstICmp*(Predicate: TLLVMIntPredicate, LHSConstant: TLLVMValueRef, 
                    RHSConstant: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMConstFCmp*(Predicate: TLLVMRealPredicate, LHSConstant: TLLVMValueRef, 
                    RHSConstant: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMConstShl*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstLShr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstAShr*(LHSConstant: TLLVMValueRef, RHSConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstGEP*(ConstantVal: TLLVMValueRef, ConstantIndices: PLLVMValueRef, 
                   NumIndices: cuint): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMConstTrunc*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstZExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFPTrunc*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFPExt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstUIToFP*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSIToFP*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFPToUI*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstFPToSI*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstPtrToInt*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstIntToPtr*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstBitCast*(ConstantVal: TLLVMValueRef, ToType: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstSelect*(ConstantCondition: TLLVMValueRef, 
                      ConstantIfTrue: TLLVMValueRef, 
                      ConstantIfFalse: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMConstExtractElement*(VectorConstant: TLLVMValueRef, 
                              IndexConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstInsertElement*(VectorConstant: TLLVMValueRef, 
                             ElementValueConstant: TLLVMValueRef, 
                             IndexConstant: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMConstShuffleVector*(VectorAConstant: TLLVMValueRef, 
                             VectorBConstant: TLLVMValueRef, 
                             MaskConstant: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on global variables, functions, and aliases (globals)  
proc LLVMIsDeclaration*(Global: TLLVMValueRef): int32{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetLinkage*(Global: TLLVMValueRef): TLLVMLinkage{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMSetLinkage*(Global: TLLVMValueRef, Linkage: TLLVMLinkage){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetSection*(Global: TLLVMValueRef): cstring{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMSetSection*(Global: TLLVMValueRef, Section: cstring){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetVisibility*(Global: TLLVMValueRef): TLLVMVisibility{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMSetVisibility*(Global: TLLVMValueRef, Viz: TLLVMVisibility){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetAlignment*(Global: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMSetAlignment*(Global: TLLVMValueRef, Bytes: cuint){.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on global variables  
  # Const before type ignored 
proc LLVMAddGlobal*(M: TLLVMModuleRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMGetNamedGlobal*(M: TLLVMModuleRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMDeleteGlobal*(GlobalVar: TLLVMValueRef){.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMHasInitializer*(GlobalVar: TLLVMValueRef): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetInitializer*(GlobalVar: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMSetInitializer*(GlobalVar: TLLVMValueRef, ConstantVal: TLLVMValueRef){.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMIsThreadLocal*(GlobalVar: TLLVMValueRef): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMSetThreadLocal*(GlobalVar: TLLVMValueRef, IsThreadLocal: int32){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMIsGlobalConstant*(GlobalVar: TLLVMValueRef): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMSetGlobalConstant*(GlobalVar: TLLVMValueRef, IsConstant: int32){.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on functions  
  # Const before type ignored 
proc LLVMAddFunction*(M: TLLVMModuleRef, Name: cstring, FunctionTy: TLLVMTypeRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMGetNamedFunction*(M: TLLVMModuleRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMDeleteFunction*(Fn: TLLVMValueRef){.cdecl, dynlib: llvmdll, importc.}
proc LLVMCountParams*(Fn: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, importc.}
proc LLVMGetParams*(Fn: TLLVMValueRef, Params: PLLVMValueRef){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetParam*(Fn: TLLVMValueRef, Index: cuint): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetIntrinsicID*(Fn: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetFunctionCallConv*(Fn: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMSetFunctionCallConv*(Fn: TLLVMValueRef, CC: cuint){.cdecl, 
    dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMGetCollector*(Fn: TLLVMValueRef): cstring{.cdecl, dynlib: llvmdll, 
    importc.}
  # Const before type ignored 
proc LLVMSetCollector*(Fn: TLLVMValueRef, Coll: cstring){.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on basic blocks  
proc LLVMBasicBlockAsValue*(Bb: TLLVMBasicBlockRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMValueIsBasicBlock*(Val: TLLVMValueRef): int32{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMValueAsBasicBlock*(Val: TLLVMValueRef): TLLVMBasicBlockRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMCountBasicBlocks*(Fn: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetBasicBlocks*(Fn: TLLVMValueRef, BasicBlocks: PLLVMBasicBlockRef){.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMGetEntryBasicBlock*(Fn: TLLVMValueRef): TLLVMBasicBlockRef{.cdecl, 
    dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMAppendBasicBlock*(Fn: TLLVMValueRef, Name: cstring): TLLVMBasicBlockRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMInsertBasicBlock*(InsertBeforeBB: TLLVMBasicBlockRef, Name: cstring): TLLVMBasicBlockRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMDeleteBasicBlock*(BB: TLLVMBasicBlockRef){.cdecl, dynlib: llvmdll, 
    importc.}
  # Operations on call sites  
proc LLVMSetInstructionCallConv*(Instr: TLLVMValueRef, CC: cuint){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMGetInstructionCallConv*(Instr: TLLVMValueRef): cuint{.cdecl, 
    dynlib: llvmdll, importc.}
  # Operations on phi nodes  
proc LLVMAddIncoming*(PhiNode: TLLVMValueRef, IncomingValues: PLLVMValueRef, 
                      IncomingBlocks: PLLVMBasicBlockRef, Count: cuint){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMCountIncoming*(PhiNode: TLLVMValueRef): cuint{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMGetIncomingValue*(PhiNode: TLLVMValueRef, Index: cuint): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMGetIncomingBlock*(PhiNode: TLLVMValueRef, Index: cuint): TLLVMBasicBlockRef{.
    cdecl, dynlib: llvmdll, importc.}
  #===-- Instruction builders ----------------------------------------------=== 
  # An instruction builder represents a point within a basic block, and is the
  # * exclusive means of building instructions using the C interface.
  #  
proc LLVMCreateBuilder*(): TLLVMBuilderRef{.cdecl, dynlib: llvmdll, importc.}
proc LLVMPositionBuilderBefore*(Builder: TLLVMBuilderRef, Instr: TLLVMValueRef){.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMPositionBuilderAtEnd*(Builder: TLLVMBuilderRef, 
                               theBlock: TLLVMBasicBlockRef){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMDisposeBuilder*(Builder: TLLVMBuilderRef){.cdecl, dynlib: llvmdll, 
    importc.}
  # Terminators  
proc LLVMBuildRetVoid*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildRet*(para1: TLLVMBuilderRef, V: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildBr*(para1: TLLVMBuilderRef, Dest: TLLVMBasicBlockRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildCondBr*(para1: TLLVMBuilderRef, IfCond: TLLVMValueRef, 
                      ThenBranch: TLLVMBasicBlockRef, 
                      ElseBranch: TLLVMBasicBlockRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildSwitch*(para1: TLLVMBuilderRef, V: TLLVMValueRef, 
                      ElseBranch: TLLVMBasicBlockRef, NumCases: cuint): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Const before type ignored 
proc LLVMBuildInvoke*(para1: TLLVMBuilderRef, Fn: TLLVMValueRef, 
                      Args: PLLVMValueRef, NumArgs: cuint, 
                      ThenBranch: TLLVMBasicBlockRef, Catch: TLLVMBasicBlockRef, 
                      Name: cstring): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMBuildUnwind*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildUnreachable*(para1: TLLVMBuilderRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
  # Add a case to the switch instruction  
proc LLVMAddCase*(Switch: TLLVMValueRef, OnVal: TLLVMValueRef, 
                  Dest: TLLVMBasicBlockRef){.cdecl, dynlib: llvmdll, importc.}
  # Arithmetic  
proc LLVMBuildAdd*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildSub*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildMul*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildUDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildSDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildFDiv*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildURem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildSRem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildFRem*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildShl*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildLShr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildAShr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                    RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildAnd*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildOr*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                  RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildXor*(para1: TLLVMBuilderRef, LHS: TLLVMValueRef, 
                   RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildNeg*(para1: TLLVMBuilderRef, V: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildNot*(para1: TLLVMBuilderRef, V: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Memory  
proc LLVMBuildMalloc*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildArrayMalloc*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, 
                           Val: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildAlloca*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildArrayAlloca*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, 
                           Val: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildFree*(para1: TLLVMBuilderRef, PointerVal: TLLVMValueRef): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildLoad*(para1: TLLVMBuilderRef, PointerVal: TLLVMValueRef, 
                    Name: cstring): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMBuildStore*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     thePtr: TLLVMValueRef): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildGEP*(B: TLLVMBuilderRef, Pointer: TLLVMValueRef, 
                   Indices: PLLVMValueRef, NumIndices: cuint, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Casts  
proc LLVMBuildTrunc*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildZExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                    DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildSExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                    DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildFPToUI*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildFPToSI*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildUIToFP*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildSIToFP*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                      DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildFPTrunc*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                       DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildFPExt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                     DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildPtrToInt*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                        DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildIntToPtr*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                        DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildBitCast*(para1: TLLVMBuilderRef, Val: TLLVMValueRef, 
                       DestTy: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Comparisons  
proc LLVMBuildICmp*(para1: TLLVMBuilderRef, Op: TLLVMIntPredicate, 
                    LHS: TLLVMValueRef, RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildFCmp*(para1: TLLVMBuilderRef, Op: TLLVMRealPredicate, 
                    LHS: TLLVMValueRef, RHS: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Miscellaneous instructions  
proc LLVMBuildPhi*(para1: TLLVMBuilderRef, Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildCall*(para1: TLLVMBuilderRef, Fn: TLLVMValueRef, 
                    Args: PLLVMValueRef, NumArgs: cuint, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildSelect*(para1: TLLVMBuilderRef, IfCond: TLLVMValueRef, 
                      ThenBranch: TLLVMValueRef, ElseBranch: TLLVMValueRef, 
                      Name: cstring): TLLVMValueRef{.cdecl, dynlib: llvmdll, 
    importc.}
proc LLVMBuildVAArg*(para1: TLLVMBuilderRef, List: TLLVMValueRef, 
                     Ty: TLLVMTypeRef, Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildExtractElement*(para1: TLLVMBuilderRef, VecVal: TLLVMValueRef, 
                              Index: TLLVMValueRef, Name: cstring): TLLVMValueRef{.
    cdecl, dynlib: llvmdll, importc.}
proc LLVMBuildInsertElement*(para1: TLLVMBuilderRef, VecVal: TLLVMValueRef, 
                             EltVal: TLLVMValueRef, Index: TLLVMValueRef, 
                             Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMBuildShuffleVector*(para1: TLLVMBuilderRef, V1: TLLVMValueRef, 
                             V2: TLLVMValueRef, Mask: TLLVMValueRef, 
                             Name: cstring): TLLVMValueRef{.cdecl, 
    dynlib: llvmdll, importc.}
  #===-- Module providers --------------------------------------------------=== 
  # Encapsulates the module M in a module provider, taking ownership of the
  #  module.
  #  See the constructor llvm: : ExistingModuleProvider: : ExistingModuleProvider.
  #
proc LLVMCreateModuleProviderForExistingModule*(M: TLLVMModuleRef): TLLVMModuleProviderRef{.
    cdecl, dynlib: llvmdll, importc.}
  # Destroys the module provider MP as well as the contained module.
  #  See the destructor llvm: : ModuleProvider: : ~ModuleProvider.
  #
proc LLVMDisposeModuleProvider*(MP: TLLVMModuleProviderRef){.cdecl, 
    dynlib: llvmdll, importc.}
  #===-- Memory buffers ----------------------------------------------------=== 
proc LLVMCreateMemoryBufferWithContentsOfFile*(Path: cstring, 
    OutMemBuf: pLLVMMemoryBufferRef, OutMessage: var cstring): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMCreateMemoryBufferWithSTDIN*(OutMemBuf: pLLVMMemoryBufferRef, 
                                      OutMessage: var cstring): int32{.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMDisposeMemoryBuffer*(MemBuf: TLLVMMemoryBufferRef){.cdecl, 
    dynlib: llvmdll, importc.}
proc LLVMWriteBitcodeToFile*(M: TLLVMModuleRef, path: cstring): int{.cdecl, 
    dynlib: llvmdll, importc.}
  # Writes a module to the specified path. Returns 0 on success.
# implementation
