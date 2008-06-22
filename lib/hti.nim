#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type # This should be he same as ast.TTypeKind
     # some enum fields are not used at runtime
  TNimKind = enum
    tyNone, tyBool, tyChar,
    tyEmptySet, tyArrayConstr, tyNil, tyRecordConstr,
    tyGeneric,
    tyGenericInst,
    tyGenericParam,
    tyEnum, tyAnyEnum,
    tyArray,
    tyRecord,
    tyObject,
    tyTuple,
    tySet,
    tyRange,
    tyPtr, tyRef,
    tyVar,
    tySequence,
    tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCString, tyForward,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128

  TNimNodeKind = enum nkNone, nkSlot, nkList, nkCase
  TNimNode {.compilerproc.} = record
    kind: TNimNodeKind
    offset: int
    typ: ptr TNimType
    name: Cstring
    len: int
    sons: ptr array [0..0x7fff, ptr TNimNode]

  TNimType {.compilerproc.} = record
    size: int
    kind: TNimKind
    base: ptr TNimType
    node: ptr TNimNode # valid for tyRecord, tyObject, tyTuple, tyEnum
    finalizer: pointer # the finalizer for the type
  PNimType = ptr TNimType
  
# node.len may be the ``first`` element of a set
