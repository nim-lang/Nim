//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit llvmstat;

// this module implements the interface to LLVM.

interface

{$include 'config.inc'}

uses
  nsystem, ropes;

{ Opaque types.  }
{
  The top-level container for all other LLVM Intermediate Representation (IR)
  objects. See the llvm::Module class.
}
type
  cuint = int32;

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

  PLLVMBasicBlockRef = ^TLLVMBasicBlockRef;
  PLLVMMemoryBufferRef = ^TLLVMMemoryBufferRef;
  PLLVMTypeRef = ^TLLVMTypeRef;
  PLLVMValueRef = ^TLLVMValueRef;

  TLLVMOpaqueModule = record
    code: PRope;
  end;
  TLLVMModuleRef = ^TLLVMOpaqueModule;
{
  Each value in the LLVM IR has a type, an instance of [lltype]. See the
  llvm::Type class.
}
  TLLVMOpaqueType = record
    kind: TLLVMTypeKind;

  end;
  TLLVMTypeRef = ^TLLVMOpaqueType;
{
  When building recursive types using [refine_type], [lltype] values may become
  invalid; use [lltypehandle] to resolve this problem. See the
  llvm::AbstractTypeHolder] class.
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
  See the llvm::ModuleProvider class.
}
  TLLVMOpaqueModuleProvider = record end;
  TLLVMModuleProviderRef = ^TLLVMOpaqueModuleProvider;
{ Used to provide a module to JIT or interpreter.
  See the llvm: : MemoryBuffer class.
}
  TLLVMOpaqueMemoryBuffer = record end;
  TLLVMMemoryBufferRef = ^TLLVMOpaqueMemoryBuffer;

{===-- Error handling ----------------------------------------------------=== }
procedure LLVMDisposeMessage(msg: pchar); cdecl;
{===-- Modules -----------------------------------------------------------=== }
{ Create and destroy modules.  }
function LLVMModuleCreateWithName(ModuleID: pchar): TLLVMModuleRef; cdecl;
procedure LLVMDisposeModule(M: TLLVMModuleRef);cdecl;
{ Data layout  }
function LLVMGetDataLayout(M: TLLVMModuleRef): pchar;cdecl;
procedure LLVMSetDataLayout(M: TLLVMModuleRef; Triple: pchar);cdecl;
{ Target triple  }
function LLVMGetTarget(M: TLLVMModuleRef): pchar;cdecl;
procedure LLVMSetTarget(M: TLLVMModuleRef; Triple: pchar);cdecl;
{ Same as Module: : addTypeName.  }
function LLVMAddTypeName(M: TLLVMModuleRef; Name: pchar; Ty: TLLVMTypeRef): longint;cdecl;
procedure LLVMDeleteTypeName(M: TLLVMModuleRef; Name: pchar);cdecl;
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
function LLVMGetTypeKind(Ty: TLLVMTypeRef): TLLVMTypeKind; cdecl;
procedure LLVMRefineAbstractType(AbstractType: TLLVMTypeRef; ConcreteType: TLLVMTypeRef); cdecl;
{ Operations on integer types  }
function LLVMInt1Type: TLLVMTypeRef;cdecl;
function LLVMInt8Type: TLLVMTypeRef;cdecl;
function LLVMInt16Type: TLLVMTypeRef;cdecl;
function LLVMInt32Type: TLLVMTypeRef;cdecl;
function LLVMInt64Type: TLLVMTypeRef;cdecl;
function LLVMIntType(NumBits: cuint): TLLVMTypeRef;cdecl;
function LLVMGetIntTypeWidth(IntegerTy: TLLVMTypeRef): cuint;cdecl;
{ Operations on real types  }
function LLVMFloatType: TLLVMTypeRef;cdecl;
function LLVMDoubleType: TLLVMTypeRef;cdecl;
function LLVMX86FP80Type: TLLVMTypeRef;cdecl;
function LLVMFP128Type: TLLVMTypeRef;cdecl;
function LLVMPPCFP128Type: TLLVMTypeRef;cdecl;
{ Operations on function types  }
function LLVMFunctionType(ReturnType: TLLVMTypeRef; ParamTypes: PLLVMTypeRef; ParamCount: cuint; IsVarArg: longint): TLLVMTypeRef;cdecl;
function LLVMIsFunctionVarArg(FunctionTy: TLLVMTypeRef): longint;cdecl;
function LLVMGetReturnType(FunctionTy: TLLVMTypeRef): TLLVMTypeRef;cdecl;
function LLVMCountParamTypes(FunctionTy: TLLVMTypeRef): cuint;cdecl;
procedure LLVMGetParamTypes(FunctionTy: TLLVMTypeRef; Dest: PLLVMTypeRef);cdecl;
{ Operations on struct types  }
function LLVMStructType(ElementTypes: PLLVMTypeRef; ElementCount: cuint; isPacked: longint): TLLVMTypeRef;cdecl;
function LLVMCountStructElementTypes(StructTy: TLLVMTypeRef): cuint;cdecl;
procedure LLVMGetStructElementTypes(StructTy: TLLVMTypeRef; Dest: pLLVMTypeRef);cdecl;
function LLVMIsPackedStruct(StructTy: TLLVMTypeRef): longint;cdecl;
{ Operations on array, pointer, and vector types (sequence types)  }
function LLVMArrayType(ElementType: TLLVMTypeRef; ElementCount: cuint): TLLVMTypeRef;cdecl;
function LLVMPointerType(ElementType: TLLVMTypeRef; AddressSpace: cuint): TLLVMTypeRef;cdecl;
function LLVMVectorType(ElementType: TLLVMTypeRef; ElementCount: cuint): TLLVMTypeRef;cdecl;
function LLVMGetElementType(Ty: TLLVMTypeRef): TLLVMTypeRef;cdecl;
function LLVMGetArrayLength(ArrayTy: TLLVMTypeRef): cuint;cdecl;
function LLVMGetPointerAddressSpace(PointerTy: TLLVMTypeRef): cuint;cdecl;
function LLVMGetVectorSize(VectorTy: TLLVMTypeRef): cuint;cdecl;
{ Operations on other types  }
function LLVMVoidType: TLLVMTypeRef;cdecl;
function LLVMLabelType: TLLVMTypeRef;cdecl;
function LLVMOpaqueType: TLLVMTypeRef;cdecl;
{ Operations on type handles  }
function LLVMCreateTypeHandle(PotentiallyAbstractTy: TLLVMTypeRef): TLLVMTypeHandleRef;cdecl;
procedure LLVMRefineType(AbstractTy: TLLVMTypeRef; ConcreteTy: TLLVMTypeRef);cdecl;
function LLVMResolveTypeHandle(TypeHandle: TLLVMTypeHandleRef): TLLVMTypeRef;cdecl;
procedure LLVMDisposeTypeHandle(TypeHandle: TLLVMTypeHandleRef);cdecl;
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
function LLVMTypeOf(Val: TLLVMValueRef): TLLVMTypeRef;cdecl;
function LLVMGetValueName(Val: TLLVMValueRef): pchar;cdecl;
procedure LLVMSetValueName(Val: TLLVMValueRef; Name: pchar);cdecl;
procedure LLVMDumpValue(Val: TLLVMValueRef);cdecl;
{ Operations on constants of any type  }
function LLVMConstNull(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;
{ all zeroes  }
function LLVMConstAllOnes(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;
{ only for int/vector  }
function LLVMGetUndef(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMIsConstant(Val: TLLVMValueRef): longint;cdecl;
function LLVMIsNull(Val: TLLVMValueRef): longint;cdecl;
function LLVMIsUndef(Val: TLLVMValueRef): longint;cdecl;
{ Operations on scalar constants  }
function LLVMConstInt(IntTy: TLLVMTypeRef; N: qword; SignExtend: longint): TLLVMValueRef;cdecl;
function LLVMConstReal(RealTy: TLLVMTypeRef; N: double): TLLVMValueRef;cdecl;
{ Operations on composite constants  }
function LLVMConstString(Str: pchar; Length: cuint; DontNullTerminate: longint): TLLVMValueRef;cdecl;
function LLVMConstArray(ArrayTy: TLLVMTypeRef; ConstantVals: pLLVMValueRef; Length: cuint): TLLVMValueRef;cdecl;
function LLVMConstStruct(ConstantVals: pLLVMValueRef; Count: cuint; ispacked: longint): TLLVMValueRef;cdecl;
function LLVMConstVector(ScalarConstantVals: pLLVMValueRef; Size: cuint): TLLVMValueRef;cdecl;
{ Constant expressions  }
function LLVMSizeOf(Ty: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstNeg(ConstantVal: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstNot(ConstantVal: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstAdd(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstSub(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstMul(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstUDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstSDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstFDiv(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstURem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstSRem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstFRem(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstAnd(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstOr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstXor(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstICmp(Predicate: TLLVMIntPredicate; LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstFCmp(Predicate: TLLVMRealPredicate; LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstShl(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstLShr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstAShr(LHSConstant: TLLVMValueRef; RHSConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstGEP(ConstantVal: TLLVMValueRef; ConstantIndices: PLLVMValueRef; NumIndices: cuint): TLLVMValueRef;cdecl;
function LLVMConstTrunc(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstSExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstZExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstFPTrunc(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstFPExt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstUIToFP(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstSIToFP(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstFPToUI(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstFPToSI(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstPtrToInt(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstIntToPtr(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstBitCast(ConstantVal: TLLVMValueRef; ToType: TLLVMTypeRef): TLLVMValueRef;cdecl;
function LLVMConstSelect(ConstantCondition: TLLVMValueRef; ConstantIfTrue: TLLVMValueRef; ConstantIfFalse: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstExtractElement(VectorConstant: TLLVMValueRef; IndexConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstInsertElement(VectorConstant: TLLVMValueRef; ElementValueConstant: TLLVMValueRef; IndexConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMConstShuffleVector(VectorAConstant: TLLVMValueRef; VectorBConstant: TLLVMValueRef; MaskConstant: TLLVMValueRef): TLLVMValueRef;cdecl;
{ Operations on global variables, functions, and aliases (globals)  }
function LLVMIsDeclaration(Global: TLLVMValueRef): longint;cdecl;
function LLVMGetLinkage(Global: TLLVMValueRef): TLLVMLinkage;cdecl;
procedure LLVMSetLinkage(Global: TLLVMValueRef; Linkage: TLLVMLinkage);cdecl;
function LLVMGetSection(Global: TLLVMValueRef): pchar;cdecl;
procedure LLVMSetSection(Global: TLLVMValueRef; Section: pchar);cdecl;
function LLVMGetVisibility(Global: TLLVMValueRef): TLLVMVisibility;cdecl;
procedure LLVMSetVisibility(Global: TLLVMValueRef; Viz: TLLVMVisibility);cdecl;
function LLVMGetAlignment(Global: TLLVMValueRef): cuint;cdecl;
procedure LLVMSetAlignment(Global: TLLVMValueRef; Bytes: cuint);cdecl;
{ Operations on global variables  }
(* Const before type ignored *)
function LLVMAddGlobal(M: TLLVMModuleRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
(* Const before type ignored *)
function LLVMGetNamedGlobal(M: TLLVMModuleRef; Name: pchar): TLLVMValueRef;cdecl;
procedure LLVMDeleteGlobal(GlobalVar: TLLVMValueRef);cdecl;
function LLVMHasInitializer(GlobalVar: TLLVMValueRef): longint;cdecl;
function LLVMGetInitializer(GlobalVar: TLLVMValueRef): TLLVMValueRef;cdecl;
procedure LLVMSetInitializer(GlobalVar: TLLVMValueRef; ConstantVal: TLLVMValueRef);cdecl;
function LLVMIsThreadLocal(GlobalVar: TLLVMValueRef): longint;cdecl;
procedure LLVMSetThreadLocal(GlobalVar: TLLVMValueRef; IsThreadLocal: longint);cdecl;
function LLVMIsGlobalConstant(GlobalVar: TLLVMValueRef): longint;cdecl;
procedure LLVMSetGlobalConstant(GlobalVar: TLLVMValueRef; IsConstant: longint);cdecl;
{ Operations on functions  }
(* Const before type ignored *)
function LLVMAddFunction(M: TLLVMModuleRef; Name: pchar; FunctionTy: TLLVMTypeRef): TLLVMValueRef;cdecl;
(* Const before type ignored *)
function LLVMGetNamedFunction(M: TLLVMModuleRef; Name: pchar): TLLVMValueRef;cdecl;
procedure LLVMDeleteFunction(Fn: TLLVMValueRef);cdecl;
function LLVMCountParams(Fn: TLLVMValueRef): cuint;cdecl;
procedure LLVMGetParams(Fn: TLLVMValueRef; Params: PLLVMValueRef);cdecl;
function LLVMGetParam(Fn: TLLVMValueRef; Index: cuint): TLLVMValueRef;cdecl;
function LLVMGetIntrinsicID(Fn: TLLVMValueRef): cuint;cdecl;
function LLVMGetFunctionCallConv(Fn: TLLVMValueRef): cuint;cdecl;
procedure LLVMSetFunctionCallConv(Fn: TLLVMValueRef; CC: cuint);cdecl;
(* Const before type ignored *)
function LLVMGetCollector(Fn: TLLVMValueRef): pchar;cdecl;
(* Const before type ignored *)
procedure LLVMSetCollector(Fn: TLLVMValueRef; Coll: pchar);cdecl;
{ Operations on basic blocks  }
function LLVMBasicBlockAsValue(Bb: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;
function LLVMValueIsBasicBlock(Val: TLLVMValueRef): longint;cdecl;
function LLVMValueAsBasicBlock(Val: TLLVMValueRef): TLLVMBasicBlockRef;cdecl;
function LLVMCountBasicBlocks(Fn: TLLVMValueRef): cuint;cdecl;
procedure LLVMGetBasicBlocks(Fn: TLLVMValueRef; BasicBlocks: PLLVMBasicBlockRef);cdecl;
function LLVMGetEntryBasicBlock(Fn: TLLVMValueRef): TLLVMBasicBlockRef;cdecl;
(* Const before type ignored *)
function LLVMAppendBasicBlock(Fn: TLLVMValueRef; Name: pchar): TLLVMBasicBlockRef;cdecl;
(* Const before type ignored *)
function LLVMInsertBasicBlock(InsertBeforeBB: TLLVMBasicBlockRef; Name: pchar): TLLVMBasicBlockRef;cdecl;
procedure LLVMDeleteBasicBlock(BB: TLLVMBasicBlockRef);cdecl;
{ Operations on call sites  }
procedure LLVMSetInstructionCallConv(Instr: TLLVMValueRef; CC: cuint);cdecl;
function LLVMGetInstructionCallConv(Instr: TLLVMValueRef): cuint;cdecl;
{ Operations on phi nodes  }
procedure LLVMAddIncoming(PhiNode: TLLVMValueRef; IncomingValues: PLLVMValueRef; IncomingBlocks: PLLVMBasicBlockRef; Count: cuint);cdecl;
function LLVMCountIncoming(PhiNode: TLLVMValueRef): cuint;cdecl;
function LLVMGetIncomingValue(PhiNode: TLLVMValueRef; Index: cuint): TLLVMValueRef;cdecl;
function LLVMGetIncomingBlock(PhiNode: TLLVMValueRef; Index: cuint): TLLVMBasicBlockRef;cdecl;
{===-- Instruction builders ----------------------------------------------=== }
{ An instruction builder represents a point within a basic block, and is the
 * exclusive means of building instructions using the C interface.
  }
function LLVMCreateBuilder: TLLVMBuilderRef;cdecl;
procedure LLVMPositionBuilderBefore(Builder: TLLVMBuilderRef; Instr: TLLVMValueRef);cdecl;
procedure LLVMPositionBuilderAtEnd(Builder: TLLVMBuilderRef; theBlock: TLLVMBasicBlockRef);cdecl;
procedure LLVMDisposeBuilder(Builder: TLLVMBuilderRef);cdecl;
{ Terminators  }
function LLVMBuildRetVoid(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;
function LLVMBuildRet(para1: TLLVMBuilderRef; V: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMBuildBr(para1: TLLVMBuilderRef; Dest: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;
function LLVMBuildCondBr(para1: TLLVMBuilderRef; IfCond: TLLVMValueRef; ThenBranch: TLLVMBasicBlockRef; ElseBranch: TLLVMBasicBlockRef): TLLVMValueRef;cdecl;
function LLVMBuildSwitch(para1: TLLVMBuilderRef; V: TLLVMValueRef; ElseBranch: TLLVMBasicBlockRef; NumCases: cuint): TLLVMValueRef;cdecl;
(* Const before type ignored *)
function LLVMBuildInvoke(para1: TLLVMBuilderRef; Fn: TLLVMValueRef; Args: PLLVMValueRef; NumArgs: cuint; ThenBranch: TLLVMBasicBlockRef;
           Catch: TLLVMBasicBlockRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildUnwind(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;
function LLVMBuildUnreachable(para1: TLLVMBuilderRef): TLLVMValueRef;cdecl;
{ Add a case to the switch instruction  }
procedure LLVMAddCase(Switch: TLLVMValueRef; OnVal: TLLVMValueRef; Dest: TLLVMBasicBlockRef);cdecl;
{ Arithmetic  }
function LLVMBuildAdd(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSub(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildMul(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildUDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFDiv(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildURem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSRem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFRem(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildShl(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildLShr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildAShr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildAnd(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildOr(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildXor(para1: TLLVMBuilderRef; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildNeg(para1: TLLVMBuilderRef; V: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildNot(para1: TLLVMBuilderRef; V: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
{ Memory  }
function LLVMBuildMalloc(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildArrayMalloc(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Val: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildAlloca(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildArrayAlloca(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Val: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFree(para1: TLLVMBuilderRef; PointerVal: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMBuildLoad(para1: TLLVMBuilderRef; PointerVal: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildStore(para1: TLLVMBuilderRef; Val: TLLVMValueRef; thePtr: TLLVMValueRef): TLLVMValueRef;cdecl;
function LLVMBuildGEP(B: TLLVMBuilderRef; Pointer: TLLVMValueRef; Indices: PLLVMValueRef; NumIndices: cuint; Name: pchar): TLLVMValueRef;cdecl;
{ Casts  }
function LLVMBuildTrunc(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildZExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFPToUI(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFPToSI(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildUIToFP(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSIToFP(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFPTrunc(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFPExt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildPtrToInt(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildIntToPtr(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildBitCast(para1: TLLVMBuilderRef; Val: TLLVMValueRef; DestTy: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
{ Comparisons  }
function LLVMBuildICmp(para1: TLLVMBuilderRef; Op: TLLVMIntPredicate; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildFCmp(para1: TLLVMBuilderRef; Op: TLLVMRealPredicate; LHS: TLLVMValueRef; RHS: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
{ Miscellaneous instructions  }
function LLVMBuildPhi(para1: TLLVMBuilderRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildCall(para1: TLLVMBuilderRef; Fn: TLLVMValueRef; Args: PLLVMValueRef; NumArgs: cuint; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildSelect(para1: TLLVMBuilderRef; IfCond: TLLVMValueRef; ThenBranch: TLLVMValueRef; ElseBranch: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildVAArg(para1: TLLVMBuilderRef; List: TLLVMValueRef; Ty: TLLVMTypeRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildExtractElement(para1: TLLVMBuilderRef; VecVal: TLLVMValueRef; Index: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildInsertElement(para1: TLLVMBuilderRef; VecVal: TLLVMValueRef; EltVal: TLLVMValueRef; Index: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
function LLVMBuildShuffleVector(para1: TLLVMBuilderRef; V1: TLLVMValueRef; V2: TLLVMValueRef; Mask: TLLVMValueRef; Name: pchar): TLLVMValueRef;cdecl;
{===-- Module providers --------------------------------------------------=== }
{ Encapsulates the module M in a module provider, taking ownership of the
  module.
  See the constructor llvm: : ExistingModuleProvider: : ExistingModuleProvider.
}
function LLVMCreateModuleProviderForExistingModule(M: TLLVMModuleRef): TLLVMModuleProviderRef;cdecl;
{ Destroys the module provider MP as well as the contained module.
  See the destructor llvm: : ModuleProvider: : ~ModuleProvider.
}
procedure LLVMDisposeModuleProvider(MP: TLLVMModuleProviderRef);cdecl;
{===-- Memory buffers ----------------------------------------------------=== }
function LLVMCreateMemoryBufferWithContentsOfFile(Path: pchar; OutMemBuf: pLLVMMemoryBufferRef; var OutMessage: pchar): longint;cdecl;
function LLVMCreateMemoryBufferWithSTDIN(OutMemBuf: pLLVMMemoryBufferRef; var OutMessage: pchar): longint;cdecl;
procedure LLVMDisposeMemoryBuffer(MemBuf: TLLVMMemoryBufferRef);cdecl;

function LLVMWriteBitcodeToFile(M: TLLVMModuleRef; path: pchar): int; cdecl;
// Writes a module to the specified path. Returns 0 on success.

implementation

end.
