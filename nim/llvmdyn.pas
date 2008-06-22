//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit llvmdyn;

// this module implements the interface to LLVM.

interface

{$include 'config.inc'}

uses
  nsystem;

const
  llvmdll = 'llvm.dll';

{ Opaque types.  }
{
  The top-level container for all other LLVM Intermediate Representation (IR)
  objects. See the llvm::Module class.
}
type
  cuint = int32;
  PLLVMBasicBlockRef = ^TLLVMBasicBlockRef;
  PLLVMMemoryBufferRef = ^TLLVMMemoryBufferRef;
  PLLVMTypeRef = ^TLLVMTypeRef;
  PLLVMValueRef = ^TLLVMValueRef;

  TLLVMOpaqueModule = record end;
  TLLVMModuleRef = ^TLLVMOpaqueModule;
{
  Each value in the LLVM IR has a type, an instance of [lltype]. See the
  llvm: : Type class.
}
  TLLVMOpaqueType = record end;
  TLLVMTypeRef = ^TLLVMOpaqueType;
{
  When building recursive types using [refine_type], [lltype] values may become
  invalid; use [lltypehandle] to resolve this problem. See the
  llvm: : AbstractTypeHolder] class.
}
  TLLVMOpaqueTypeHandle = record end;
  TLLVMTypeHandleRef = ^TLLVMOpaqueTypeHandle;
  TLLVMOpaqueValue = record end;
  TLLVMValueRef = ^TLLVMOpaqueValue;
  TLLVMOpaqueBasicBlock = record end;
  TLLVMBasicBlockRef = ^TLLVMOpaqueBasicBlock;

  TLLVMOpaqueBuilder = record end;
  TLLVMBuilderRef = ^TLLVMOpaqueBuilder;
{ Used to provide a module to JIT or interpreter.
  See the llvm: : ModuleProvider class.
}
  TLLVMOpaqueModuleProvider = record end;
  TLLVMModuleProviderRef = ^TLLVMOpaqueModuleProvider;
{ Used to provide a module to JIT or interpreter.
  See the llvm: : MemoryBuffer class.
}
  TLLVMOpaqueMemoryBuffer = record end;
  TLLVMMemoryBufferRef = ^TLLVMOpaqueMemoryBuffer;

  TLLVMTypeKind = (
    LLVMVoidTypeKind, // type with no size
    LLVMFloatTypeKind, // 32 bit floating point type
    LLVMDoubleTypeKind, // 64 bit floating point type
    LLVMX86_FP80TypeKind, // 80 bit floating point type (X87)
    LLVMFP128TypeKind, // 128 bit floating point type (112-bit mantissa)
    LLVMPPC_FP128TypeKind, // 128 bit floating point type (two 64-bits)
    LLVMLabelTypeKind, // Labels
    LLVMIntegerTypeKind, // Arbitrary bit width integers
    LLVMFunctionTypeKind, // Functions
    LLVMStructTypeKind, // Structures
    LLVMArrayTypeKind, // Arrays
    LLVMPointerTypeKind, // Pointers
    LLVMOpaqueTypeKind, // Opaque: type with unknown structure
    LLVMVectorTypeKind // SIMD 'packed' format, or other vector type
  );

  TLLVMLinkage = (
    LLVMExternalLinkage, // Externally visible function
    LLVMLinkOnceLinkage, // Keep one copy of function when linking (inline)
    LLVMWeakLinkage, // Keep one copy of function when linking (weak)
    LLVMAppendingLinkage, // Special purpose, only applies to global arrays
    LLVMInternalLinkage, // Rename collisions when linking (static functions)
    LLVMDLLImportLinkage, // Function to be imported from DLL
    LLVMDLLExportLinkage, // Function to be accessible from DLL
    LLVMExternalWeakLinkage, // ExternalWeak linkage description
    LLVMGhostLinkage // Stand-in functions for streaming fns from bitcode
  );

  TLLVMVisibility = (
    LLVMDefaultVisibility, // The GV is visible
    LLVMHiddenVisibility, // The GV is hidden
    LLVMProtectedVisibility // The GV is protected
  );

  TLLVMCallConv = (
    LLVMCCallConv = 0,
    LLVMFastCallConv = 8,
    LLVMColdCallConv = 9,
    LLVMX86StdcallCallConv = 64,
    LLVMX86FastcallCallConv = 65
  );

  TLLVMIntPredicate = (
    LLVMIntEQ = 32, // equal
    LLVMIntNE, // not equal
    LLVMIntUGT, // unsigned greater than
    LLVMIntUGE, // unsigned greater or equal
    LLVMIntULT, // unsigned less than
    LLVMIntULE, // unsigned less or equal
    LLVMIntSGT, // signed greater than
    LLVMIntSGE, // signed greater or equal
    LLVMIntSLT, // signed less than
    LLVMIntSLE // signed less or equal
  );

  TLLVMRealPredicate = (
    LLVMRealPredicateFalse, // Always false (always folded)
    LLVMRealOEQ, // True if ordered and equal
    LLVMRealOGT, // True if ordered and greater than
    LLVMRealOGE, // True if ordered and greater than or equal
    LLVMRealOLT, // True if ordered and less than
    LLVMRealOLE, // True if ordered and less than or equal
    LLVMRealONE, // True if ordered and operands are unequal
    LLVMRealORD, // True if ordered (no nans)
    LLVMRealUNO, // True if unordered: isnan(X) | isnan(Y)
    LLVMRealUEQ, // True if unordered or equal
    LLVMRealUGT, // True if unordered or greater than
    LLVMRealUGE, // True if unordered, greater than, or equal
    LLVMRealULT, // True if unordered or less than
    LLVMRealULE, // True if unordered, less than, or equal
    LLVMRealUNE, // True if unordered or not equal
    LLVMRealPredicateTrue // Always true (always folded)
  );

{===-- Error handling ----------------------------------------------------=== }
procedure LLVMDisposeMessage(msg: pchar); cdecl; external llvmdll;
{===-- Modules -----------------------------------------------------------=== }
{ Create and destroy modules.  }
function LLVMModuleCreateWithName(ModuleID: pchar): TLLVMModuleRef; cdecl; external llvmdll;
procedure LLVMDisposeModule(M: TLLVMModuleRef);cdecl;external llvmdll;
{ Data layout  }
function LLVMGetDataLayout(M: TLLVMModuleRef): pchar;cdecl;external llvmdll;
procedure LLVMSetDataLayout(M: TLLVMModuleRef; Triple: pchar);cdecl;external llvmdll;
{ Target triple  }
function LLVMGetTarget(M: TLLVMModuleRef): pchar;cdecl;external llvmdll;
(* Const before type ignored *)
procedure LLVMSetTarget(M: TLLVMModuleRef; Triple: pchar);cdecl;external llvmdll;
{ Same as Module: : addTypeName.  }
function LLVMAddTypeName(M: TLLVMModuleRef; Name: pchar; Ty: TLLVMTypeRef): longint;cdecl;external llvmdll;
procedure LLVMDeleteTypeName(M: TLLVMModuleRef; Name: pchar);cdecl;external llvmdll;
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
function LLVMGetTypeKind(Ty: TLLVMTypeRef): TLLVMTypeKind; cdecl; external llvmdll;
procedure LLVMRefineAbstractType(AbstractType: TLLVMTypeRef; ConcreteType: TLLVMTypeRef); cdecl; external llvmdll;
{ Operations on integer types  }
function LLVMInt1Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMInt8Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMInt16Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMInt32Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMInt64Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMIntType(NumBits: cuint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMGetIntTypeWidth(IntegerTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
{ Operations on real types  }
function LLVMFloatType: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMDoubleType: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMX86FP80Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMFP128Type: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMPPCFP128Type: TLLVMTypeRef;cdecl;external llvmdll;
{ Operations on function types  }
function LLVMFunctionType(ReturnType: TLLVMTypeRef; ParamTypes: PLLVMTypeRef; ParamCount: cuint; IsVarArg: longint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMIsFunctionVarArg(FunctionTy: TLLVMTypeRef): longint;cdecl;external llvmdll;
function LLVMGetReturnType(FunctionTy: TLLVMTypeRef): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMCountParamTypes(FunctionTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
procedure LLVMGetParamTypes(FunctionTy: TLLVMTypeRef; Dest: PLLVMTypeRef);cdecl;external llvmdll;
{ Operations on struct types  }
function LLVMStructType(ElementTypes: PLLVMTypeRef; ElementCount: cuint; isPacked: longint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMCountStructElementTypes(StructTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
procedure LLVMGetStructElementTypes(StructTy: TLLVMTypeRef; Dest: pLLVMTypeRef);cdecl;external llvmdll;
function LLVMIsPackedStruct(StructTy: TLLVMTypeRef): longint;cdecl;external llvmdll;
{ Operations on array, pointer, and vector types (sequence types)  }
function LLVMArrayType(ElementType: TLLVMTypeRef; ElementCount: cuint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMPointerType(ElementType: TLLVMTypeRef; AddressSpace: cuint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMVectorType(ElementType: TLLVMTypeRef; ElementCount: cuint): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMGetElementType(Ty: TLLVMTypeRef): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMGetArrayLength(ArrayTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
function LLVMGetPointerAddressSpace(PointerTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
function LLVMGetVectorSize(VectorTy: TLLVMTypeRef): cuint;cdecl;external llvmdll;
{ Operations on other types  }
function LLVMVoidType: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMLabelType: TLLVMTypeRef;cdecl;external llvmdll;
function LLVMOpaqueType: TLLVMTypeRef;cdecl;external llvmdll;
{ Operations on type handles  }
function LLVMCreateTypeHandle(PotentiallyAbstractTy: TLLVMTypeRef): TLLVMTypeHandleRef;cdecl;external llvmdll;
procedure LLVMRefineType(AbstractTy: TLLVMTypeRef; ConcreteTy: TLLVMTypeRef);cdecl;external llvmdll;
function LLVMResolveTypeHandle(TypeHandle: TLLVMTypeHandleRef): TLLVMTypeRef;cdecl;external llvmdll;
procedure LLVMDisposeTypeHandle(TypeHandle: TLLVMTypeHandleRef);cdecl;external llvmdll;
{===-- Values ------------------------------------------------------------=== }
{ The bulk of LLVM's object model consists of values, which comprise a very
 * rich type hierarchy.
 *
 *   values:
 *     constants:
 *       scalar constants
 *       composite contants
 *       globals:
 *         global variable
 *         function
 *         alias
 *       basic blocks
  }
{ Operations on all values  }
function LLVMTypeOf(Val: TLLVMValueRef): TLLVMTypeRef;cdecl;external llvmdll;
function LLVMGetValueName(Val: TLLVMValueRef): pchar;cdecl;external llvmdll;
procedure LLVMSetValueName(Val: TLLVMValueRef; Name: pchar);cdecl;external llvmdll;
procedure LLVMDumpValue(Val: TLLVMValueRef);cdecl;external llvmdll;
{ Operations on constants of any type  }
function LLVMConstNull(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
{ all zeroes  }
function LLVMConstAllOnes(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
{ only for int/vector  }
function LLVMGetUndef(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMIsConstant(Val: TLLVMValueRef): longint;cdecl;external llvmdll;
function LLVMIsNull(Val: TLLVMValueRef): longint;cdecl;external llvmdll;
function LLVMIsUndef(Val: TLLVMValueRef): longint;cdecl;external llvmdll;
{ Operations on scalar constants  }
function LLVMConstInt(IntTy: TLLVMTypeRef; N: qword; SignExtend: longint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstReal(RealTy: TLLVMTypeRef; N: double): TLLVMValueRef;cdecl;external llvmdll;
{ Operations on composite constants  }
function LLVMConstString(Str: pchar; Length: cuint; DontNullTerminate: longint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstArray(ArrayTy: TLLVMTypeRef; ConstantVals: pLLVMValueRef; Length: cuint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstStruct(ConstantVals: pLLVMValueRef; Count: cuint; ispacked: longint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstVector(ScalarConstantVals: pLLVMValueRef; Size: cuint): TLLVMValueRef;cdecl;external llvmdll;
{ Constant expressions  }
function LLVMSizeOf(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstNeg(ConstantVal: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstNot(ConstantVal: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstAdd(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSub(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstMul(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstUDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstURem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSRem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFRem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstAnd(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstOr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstXor(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstICmp(Predicate: TLLVMIntPredicate; LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFCmp(Predicate: TLLVMRealPredicate; LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstShl(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstLShr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstAShr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstGEP(ConstantVal: TLLVMValueRef; ConstantIndices: PLLVMValueRef; NumIndices: cuint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstTrunc(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstZExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFPTrunc(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFPExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstUIToFP(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSIToFP(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFPToUI(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstFPToSI(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstPtrToInt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstIntToPtr(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstBitCast(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstSelect(ConstantCondition: TLLVMValueRef; ConstantIfTrue: TLLVMValueRef; ConstantIfFalse: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstExtractElement(VectorConstant: TLLVMValueRef; IndexConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstInsertElement(VectorConstant: TLLVMValueRef; ElementValueConstant: TLLVMValueRef; IndexConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMConstShuffleVector(VectorAConstant: TLLVMValueRef; VectorBConstant: TLLVMValueRef; MaskConstant: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
{ Operations on global variables, functions, and aliases (globals)  }
function LLVMIsDeclaration(Global: TLLVMValueRef): longint;cdecl;external llvmdll;
function LLVMGetLinkage(Global: TLLVMValueRef): TLLVMLinkage;cdecl;external llvmdll;
procedure LLVMSetLinkage(Global: TLLVMValueRef; Linkage: TLLVMLinkage);cdecl;external llvmdll;
function LLVMGetSection(Global: TLLVMValueRef): pchar;cdecl;external llvmdll;
procedure LLVMSetSection(Global: TLLVMValueRef; Section: pchar);cdecl;external llvmdll;
function LLVMGetVisibility(Global: TLLVMValueRef): TLLVMVisibility;cdecl;external llvmdll;
procedure LLVMSetVisibility(Global: TLLVMValueRef; Viz: TLLVMVisibility);cdecl;external llvmdll;
function LLVMGetAlignment(Global: TLLVMValueRef): cuint;cdecl;external llvmdll;
procedure LLVMSetAlignment(Global: TLLVMValueRef; Bytes: cuint);cdecl;external llvmdll;
{ Operations on global variables  }
(* Const before type ignored *)
function LLVMAddGlobal(M: TLLVMModuleRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMGetNamedGlobal(M: TLLVMModuleRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
procedure LLVMDeleteGlobal(GlobalVar: TLLVMValueRef);cdecl;external llvmdll;
function LLVMHasInitializer(GlobalVar: TLLVMValueRef): longint;cdecl;external llvmdll;
function LLVMGetInitializer(GlobalVar: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
procedure LLVMSetInitializer(GlobalVar: TLLVMValueRef; ConstantVal: TLLVMValueRef);cdecl;external llvmdll;
function LLVMIsThreadLocal(GlobalVar: TLLVMValueRef): longint;cdecl;external llvmdll;
procedure LLVMSetThreadLocal(GlobalVar: TLLVMValueRef; IsThreadLocal: longint);cdecl;external llvmdll;
function LLVMIsGlobalConstant(GlobalVar: TLLVMValueRef): longint;cdecl;external llvmdll;
procedure LLVMSetGlobalConstant(GlobalVar: TLLVMValueRef; IsConstant: longint);cdecl;external llvmdll;
{ Operations on functions  }
(* Const before type ignored *)
function LLVMAddFunction(M: TLLVMModuleRef; Name: pchar; FunctionTy: TLLVMTypeRef): TLLVMValueRef;cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMGetNamedFunction(M: TLLVMModuleRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
procedure LLVMDeleteFunction(Fn: TLLVMValueRef);cdecl;external llvmdll;
function LLVMCountParams(Fn: TLLVMValueRef): cuint;cdecl;external llvmdll;
procedure LLVMGetParams(Fn: TLLVMValueRef; Params: PLLVMValueRef);cdecl;external llvmdll;
function LLVMGetParam(Fn: TLLVMValueRef; Index: cuint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMGetIntrinsicID(Fn: TLLVMValueRef): cuint;cdecl;external llvmdll;
function LLVMGetFunctionCallConv(Fn: TLLVMValueRef): cuint;cdecl;external llvmdll;
procedure LLVMSetFunctionCallConv(Fn: TLLVMValueRef; CC: cuint);cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMGetCollector(Fn: TLLVMValueRef): pchar;cdecl;external llvmdll;
(* Const before type ignored *)
procedure LLVMSetCollector(Fn: TLLVMValueRef; Coll: pchar);cdecl;external llvmdll;
{ Operations on basic blocks  }
function LLVMBasicBlockAsValue(Bb: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMValueIsBasicBlock(Val: TLLVMValueRef): longint;cdecl;external llvmdll;
function LLVMValueAsBasicBlock(Val: TLLVMValueRef): TLLVMBasicBlockRef;cdecl;external llvmdll;
function LLVMCountBasicBlocks(Fn: TLLVMValueRef): cuint;cdecl;external llvmdll;
procedure LLVMGetBasicBlocks(Fn: TLLVMValueRef; BasicBlocks: PLLVMBasicBlockRef);cdecl;external llvmdll;
function LLVMGetEntryBasicBlock(Fn: TLLVMValueRef): TLLVMBasicBlockRef;cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMAppendBasicBlock(Fn: TLLVMValueRef; Name: pchar): TLLVMBasicBlockRef;cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMInsertBasicBlock(InsertBeforeBB: TLLVMBasicBlockRef; Name: pchar): TLLVMBasicBlockRef;cdecl;external llvmdll;
procedure LLVMDeleteBasicBlock(BB: TLLVMBasicBlockRef);cdecl;external llvmdll;
{ Operations on call sites  }
procedure LLVMSetInstructionCallConv(Instr: TLLVMValueRef; CC: cuint);cdecl;external llvmdll;
function LLVMGetInstructionCallConv(Instr: TLLVMValueRef): cuint;cdecl;external llvmdll;
{ Operations on phi nodes  }
procedure LLVMAddIncoming(PhiNode: TLLVMValueRef; IncomingValues: PLLVMValueRef; IncomingBlocks: PLLVMBasicBlockRef; Count: cuint);cdecl;external llvmdll;
function LLVMCountIncoming(PhiNode: TLLVMValueRef): cuint;cdecl;external llvmdll;
function LLVMGetIncomingValue(PhiNode: TLLVMValueRef; Index: cuint): TLLVMValueRef;cdecl;external llvmdll;
function LLVMGetIncomingBlock(PhiNode: TLLVMValueRef; Index: cuint): TLLVMBasicBlockRef;cdecl;external llvmdll;
{===-- Instruction builders ----------------------------------------------=== }
{ An instruction builder represents a point within a basic block, and is the
 * exclusive means of building instructions using the C interface.
  }
function LLVMCreateBuilder: TLLVMBuilderRef;cdecl;external llvmdll;
procedure LLVMPositionBuilderBefore(Builder: TLLVMBuilderRef; Instr: TLLVMValueRef);cdecl;external llvmdll;
procedure LLVMPositionBuilderAtEnd(Builder: TLLVMBuilderRef; theBlock: TLLVMBasicBlockRef);cdecl;external llvmdll;
procedure LLVMDisposeBuilder(Builder: TLLVMBuilderRef);cdecl;external llvmdll;
{ Terminators  }
function LLVMBuildRetVoid(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildRet(para1: TLLVMBuilderRef; V: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildBr(para1: TLLVMBuilderRef; Dest: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildCondBr(para1: TLLVMBuilderRef; IfCond: TLLVMValueRef; ThenBranch: TLLVMBasicBlockRef; ElseBranch: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSwitch(para1: TLLVMBuilderRef; V: TLLVMValueRef; ElseBranch: TLLVMBasicBlockRef; NumCases: cuint): TLLVMValueRef;cdecl;external llvmdll;
(* Const before type ignored *)
function LLVMBuildInvoke(para1: TLLVMBuilderRef; Fn: TLLVMValueRef; Args: PLLVMValueRef; NumArgs: cuint; ThenBranch: TLLVMBasicBlockRef;
           Catch: TLLVMBasicBlockRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildUnwind(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildUnreachable(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;external llvmdll;
{ Add a case to the switch instruction  }
procedure LLVMAddCase(Switch: TLLVMValueRef; OnVal: TLLVMValueRef; Dest: TLLVMBasicBlockRef);cdecl;external llvmdll;
{ Arithmetic  }
function LLVMBuildAdd(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSub(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildMul(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildUDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildURem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSRem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFRem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildShl(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildLShr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildAShr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildAnd(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildOr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildXor(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildNeg(para1: TLLVMBuilderRef; V: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildNot(para1: TLLVMBuilderRef; V: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
{ Memory  }
function LLVMBuildMalloc(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildArrayMalloc(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Val: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildAlloca(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildArrayAlloca(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Val: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFree(para1: TLLVMBuilderRef; PointerVal: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildLoad(para1: TLLVMBuilderRef; PointerVal: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildStore(para1: TLLVMBuilderRef; Val: TLLVMValueRef; thePtr: TLLVMValueRef): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildGEP(B: TLLVMBuilderRef; Pointer: TLLVMValueRef; Indices: PLLVMValueRef; NumIndices: cuint; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
{ Casts  }
function LLVMBuildTrunc(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildZExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFPToUI(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFPToSI(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildUIToFP(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSIToFP(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFPTrunc(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFPExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildPtrToInt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildIntToPtr(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildBitCast(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
{ Comparisons  }
function LLVMBuildICmp(para1: TLLVMBuilderRef; Op: TLLVMIntPredicate; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildFCmp(para1: TLLVMBuilderRef; Op: TLLVMRealPredicate; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
{ Miscellaneous instructions  }
function LLVMBuildPhi(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildCall(para1: TLLVMBuilderRef; Fn: TLLVMValueRef; Args: PLLVMValueRef; NumArgs: cuint; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildSelect(para1: TLLVMBuilderRef; IfCond: TLLVMValueRef; ThenBranch: TLLVMValueRef; ElseBranch: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildVAArg(para1: TLLVMBuilderRef; List: TLLVMValueRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildExtractElement(para1: TLLVMBuilderRef; VecVal: TLLVMValueRef; Index: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildInsertElement(para1: TLLVMBuilderRef; VecVal: TLLVMValueRef; EltVal: TLLVMValueRef; Index: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
function LLVMBuildShuffleVector(para1: TLLVMBuilderRef; V1: TLLVMValueRef; V2: TLLVMValueRef; Mask: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;external llvmdll;
{===-- Module providers --------------------------------------------------=== }
{ Encapsulates the module M in a module provider, taking ownership of the
  module.
  See the constructor llvm: : ExistingModuleProvider: : ExistingModuleProvider.
}
function LLVMCreateModuleProviderForExistingModule(M: TLLVMModuleRef): TLLVMModuleProviderRef;cdecl;external llvmdll;
{ Destroys the module provider MP as well as the contained module.
  See the destructor llvm: : ModuleProvider: : ~ModuleProvider.
}
procedure LLVMDisposeModuleProvider(MP: TLLVMModuleProviderRef);cdecl;external llvmdll;
{===-- Memory buffers ----------------------------------------------------=== }
function LLVMCreateMemoryBufferWithContentsOfFile(Path: pchar; OutMemBuf: pLLVMMemoryBufferRef; var OutMessage: pchar): longint;cdecl;external llvmdll;
function LLVMCreateMemoryBufferWithSTDIN(OutMemBuf: pLLVMMemoryBufferRef; var OutMessage: pchar): longint;cdecl;external llvmdll;
procedure LLVMDisposeMemoryBuffer(MemBuf: TLLVMMemoryBufferRef);cdecl;external llvmdll;

function LLVMWriteBitcodeToFile(M: TLLVMModuleRef; path: pchar): int; cdecl; external llvmdll;
// Writes a module to the specified path. Returns 0 on success.

implementation

end.
