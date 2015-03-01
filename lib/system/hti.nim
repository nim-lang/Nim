#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when declared(NimString): 
  # we are in system module:
  {.pragma: codegenType, compilerproc.}
else:
  {.pragma: codegenType, importc.}

type 
  # This should be he same as ast.TTypeKind
  # many enum fields are not used at runtime
  TNimKind = enum
    tyNone,
    tyBool,
    tyChar,
    tyEmpty,
    tyArrayConstr,
    tyNil,
    tyExpr,
    tyStmt,
    tyTypeDesc,
    tyGenericInvocation, # ``T[a, b]`` for types to invoke
    tyGenericBody,       # ``T[a, b, body]`` last parameter is the body
    tyGenericInst,       # ``T[a, b, realInstance]`` instantiated generic type
    tyGenericParam,      # ``a`` in the example
    tyDistinct,          # distinct type
    tyEnum,
    tyOrdinal,
    tyArray,
    tyObject,
    tyTuple,             # WARNING: The compiler uses tyTuple for pure objects!
    tySet,
    tyRange,
    tyPtr,
    tyRef,
    tyVar,
    tySequence,
    tyProc,
    tyPointer,
    tyOpenArray,
    tyString,
    tyCString,
    tyForward,
    tyInt,
    tyInt8,
    tyInt16,
    tyInt32,
    tyInt64,
    tyFloat,
    tyFloat32,
    tyFloat64,
    tyFloat128,
    tyUInt,
    tyUInt8,
    tyUInt16,
    tyUInt32,
    tyUInt64,
    tyBigNum,

  TNimNodeKind = enum nkNone, nkSlot, nkList, nkCase
  TNimNode {.codegenType.} = object
    kind: TNimNodeKind
    offset: int
    typ: ptr TNimType
    name: cstring
    len: int
    sons: ptr array [0..0x7fff, ptr TNimNode]

  TNimTypeFlag = enum 
    ntfNoRefs = 0,     # type contains no tyRef, tySequence, tyString
    ntfAcyclic = 1,    # type cannot form a cycle
    ntfEnumHole = 2    # enum has holes and thus `$` for them needs the slow
                       # version
  TNimType {.codegenType.} = object
    size: int
    kind: TNimKind
    flags: set[TNimTypeFlag]
    base: ptr TNimType
    node: ptr TNimNode # valid for tyRecord, tyObject, tyTuple, tyEnum
    finalizer: pointer # the finalizer for the type
    marker: proc (p: pointer, op: int) {.nimcall, benign.} # marker proc for GC
    deepcopy: proc (p: pointer): pointer {.nimcall, benign.}
  PNimType = ptr TNimType
  
# node.len may be the ``first`` element of a set
