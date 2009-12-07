#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module implements data structures for emitting LLVM.

import 
  ast, astalgo, idents, lists, passes

type 
  VTypeKind* = enum 
    VoidTyID,                 #/<  0: type with no size
    FloatTyID,                #/<  1: 32 bit floating point type
    DoubleTyID,               #/<  2: 64 bit floating point type
    X86_FP80TyID,             #/<  3: 80 bit floating point type (X87)
    FP128TyID,                #/<  4: 128 bit floating point type (112-bit mantissa)
    PPC_FP128TyID,            #/<  5: 128 bit floating point type (two 64-bits)
    LabelTyID,                #/<  6: Labels
    MetadataTyID,             #/<  7: Metadata
                              # Derived types... see DerivedTypes.h file...
                              # Make sure FirstDerivedTyID stays up to date!!!
    IntegerTyID,              #/<  8: Arbitrary bit width integers
    FunctionTyID,             #/<  9: Functions
    StructTyID,               #/< 10: Structures
    ArrayTyID,                #/< 11: Arrays
    PointerTyID,              #/< 12: Pointers
    OpaqueTyID,               #/< 13: Opaque: type with unknown structure
    VectorTyID                #/< 14: SIMD 'packed' format, or other vector type
  VType* = ref VTypeDesc
  VTypeSeq* = seq[VType]
  VTypeDesc* = object of TIdObj
    k*: VTypeKind
    s*: VTypeSeq
    arrayLen*: int
    name*: string

  VInstrKind* = enum 
    iNone, iAdd, iSub, iMul, iDiv, iMod
  VLocalVar*{.final.} = object 
  VInstr*{.final.} = object #/ This represents a single basic block in LLVM. A basic block is simply a
                            #/ container of instructions that execute sequentially. Basic blocks are Values
                            #/ because they are referenced by instructions such as branches and switch
                            #/ tables. The type of a BasicBlock is "Type::LabelTy" because the basic block
                            #/ represents a label to which a branch can jump.
                            #/
    k*: VInstrKind

  VBlock* = ref VBlockDesc
  VBlockDesc*{.final.} = object # LLVM basic block
                                # list of instructions
  VLinkage* = enum 
    ExternalLinkage,          # Externally visible function
    LinkOnceLinkage,          # Keep one copy of function when linking (inline)
    WeakLinkage,              # Keep one copy of function when linking (weak)
    AppendingLinkage,         # Special purpose, only applies to global arrays
    InternalLinkage,          # Rename collisions when linking (static functions)
    DLLImportLinkage,         # Function to be imported from DLL
    DLLExportLinkage,         # Function to be accessible from DLL
    ExternalWeakLinkage,      # ExternalWeak linkage description
    GhostLinkage              # Stand-in functions for streaming fns from bitcode
  VVisibility* = enum 
    DefaultVisibility,        # The GV is visible
    HiddenVisibility,         # The GV is hidden
    ProtectedVisibility       # The GV is protected
  TLLVMCallConv* = enum 
    CCallConv = 0, FastCallConv = 8, ColdCallConv = 9, X86StdcallCallConv = 64, 
    X86FastcallCallConv = 65
  VProc* = ref VProcDesc
  VProcDesc*{.final.} = object 
    b*: VBlock
    name*: string
    sym*: PSym                # proc that is generated
    linkage*: VLinkage
    vis*: VVisibility
    callConv*: VCallConv
    next*: VProc

  VModule* = ref VModuleDesc
  VModuleDesc* = object of TPassContext # represents a C source file
    sym*: PSym
    filename*: string
    typeCache*: TIdTable      # cache the generated types
    forwTypeCache*: TIdTable  # cache for forward declarations of types
    declaredThings*: TIntSet  # things we have declared in this file
    declaredProtos*: TIntSet  # prototypes we have declared in this file
    headerFiles*: TLinkedList # needed headers to include
    typeInfoMarker*: TIntSet  # needed for generating type information
    initProc*: VProc          # code for init procedure
    typeStack*: TTypeSeq      # used for type generation
    dataCache*: TNodeTable
    forwardedProcs*: TSymSeq  # keep forwarded procs here
    typeNodes*, nimTypes*: int # used for type info generation
    typeNodesName*, nimTypesName*: PRope # used for type info generation
    labels*: natural          # for generating unique module-scope names
    next*: VModule            # to stack modules
  

# implementation
