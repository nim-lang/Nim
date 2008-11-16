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
    tyNone, # 0 
    tyBool, # 1 
    tyChar, # 2
    tyEmpty, # 3
    tyArrayConstr, # 4
    tyNil, # 5
    tyGeneric, # 6
    tyGenericInst, # 7
    tyGenericParam, # 8
    tyEnum, # 9
    tyAnyEnum, # 10
    tyArray, # 11
    tyObject, # 12 
    tyTuple, # 13
    tySet, # 14
    tyRange, # 15
    tyPtr, # 16
    tyRef, # 17
    tyVar, # 18
    tySequence, # 19
    tyProc, # 20
    tyPointer, # 21
    tyOpenArray, # 22
    tyString, # 23
    tyCString, # 24
    tyForward, # 25
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyPureObject # 35: signals that object has no `n_type` field

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
