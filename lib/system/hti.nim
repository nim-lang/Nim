#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type # This should be he same as ast.TTypeKind
     # some enum fields are not used at runtime
  TNimKind = enum
    tyNone, # 0 
    tyBool, # 1 
    tyChar, # 2
    tyEmpty, # 3
    tyArrayConstr, # 4
    tyNil, # 5
    tyGeneric, # 6
    tyGenericInst, # 7
    tyGenericParam, # 8
    tyAbstract, # 9
    tyEnum, # 10
    tyOrdinal, # 11
    tyArray, # 12
    tyObject, # 13 
    tyTuple, # 14
    tySet, # 15
    tyRange, # 16
    tyPtr, # 17
    tyRef, # 18
    tyVar, # 19
    tySequence, # 20
    tyProc, # 21
    tyPointer, # 22
    tyOpenArray, # 23
    tyString, # 24
    tyCString, # 25
    tyForward, # 26
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyPureObject # 36: signals that object has no `n_type` field

  TNimNodeKind = enum nkNone, nkSlot, nkList, nkCase
  TNimNode {.compilerproc, final.} = object
    kind: TNimNodeKind
    offset: int
    typ: ptr TNimType
    name: Cstring
    len: int
    sons: ptr array [0..0x7fff, ptr TNimNode]

  TNimTypeFlag = enum 
    ntfNoRefs = 0,     # type contains no tyRef, tySequence, tyString
    ntfAcyclic = 1     # type cannot form a cycle
  TNimType {.compilerproc, final.} = object
    size: int
    kind: TNimKind
    flags: set[TNimTypeFlag]
    base: ptr TNimType
    node: ptr TNimNode # valid for tyRecord, tyObject, tyTuple, tyEnum
    finalizer: pointer # the finalizer for the type
  PNimType = ptr TNimType
  
# node.len may be the ``first`` element of a set
