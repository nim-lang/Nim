#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Type system for Nim.

import std / [assertions, hashes, tables]
import ic / [bitabs, rodfiles]
import nodes

type
  TTypeKind* = enum  # order is important!
                     # Don't forget to change hti.nim if you make a change here
                     # XXX put this into an include file to avoid this issue!
                     # several types are no longer used (guess which), but a
                     # spot in the sequence is kept for backwards compatibility
                     # (apparently something with bootstrapping)
                     # if you need to add a type, they can apparently be reused
    tyNone, tyBool, tyChar,
    tyEmpty, tyAlias, tyNil, tyUntyped, tyTyped, tyTypeDesc,
    tyGenericInvocation, # ``T[a, b]`` for types to invoke
    tyGenericBody,       # ``T[a, b, body]`` last parameter is the body
    tyGenericInst,       # ``T[a, b, realInstance]`` instantiated generic type
                         # realInstance will be a concrete type like tyObject
                         # unless this is an instance of a generic alias type.
                         # then realInstance will be the tyGenericInst of the
                         # completely (recursively) resolved alias.

    tyGenericParam,      # ``a`` in the above patterns
    tyDistinct,
    tyEnum,
    tyOrdinal,           # integer types (including enums and boolean)
    tyArray,
    tyObject,
    tyTuple,
    tySet,
    tyRange,
    tyPtr, tyRef,
    tyVar,
    tySequence,
    tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCstring, tyForward,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64, # signed integers
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64,
    tyOwned, tySink, tyLent,
    tyVarargs,
    tyUncheckedArray
      # An array with boundaries [0,+∞]

    tyProxy # used as errornous type (for idetools)

    tyBuiltInTypeClass
      # Type such as the catch-all object, tuple, seq, etc

    tyUserTypeClass
      # the body of a user-defined type class

    tyUserTypeClassInst
      # Instance of a parametric user-defined type class.
      # Structured similarly to tyGenericInst.
      # tyGenericInst represents concrete types, while
      # this is still a "generic param" that will bind types
      # and resolves them during sigmatch and instantiation.

    tyCompositeTypeClass
      # Type such as seq[Number]
      # The notes for tyUserTypeClassInst apply here as well
      # sons[0]: the original expression used by the user.
      # sons[1]: fully expanded and instantiated meta type
      # (potentially following aliases)

    tyInferred
      # In the initial state `base` stores a type class constraining
      # the types that can be inferred. After a candidate type is
      # selected, it's stored in `lastSon`. Between `base` and `lastSon`
      # there may be 0, 2 or more types that were also considered as
      # possible candidates in the inference process (i.e. lastSon will
      # be updated to store a type best conforming to all candidates)

    tyAnd, tyOr, tyNot
      # boolean type classes such as `string|int`,`not seq`,
      # `Sortable and Enumable`, etc

    tyAnything
      # a type class matching any type

    tyStatic
      # a value known at compile type (the underlying type is .base)

    tyFromExpr
      # This is a type representing an expression that depends
      # on generic parameters (the expression is stored in t.n)
      # It will be converted to a real type only during generic
      # instantiation and prior to this it has the potential to
      # be any type.

    tyConcept
      # new style concept.

    tyVoid
      # now different from tyEmpty, hurray!
    tyIterable

    tyIntVal
    tyStrVal
    tyExtVal # extension
    tyFieldDecl

const
  tyPureObject* = tyTuple
  GcTypeKinds* = {tyRef, tySequence, tyString}
  tyError* = tyProxy # as an errornous node should match everything
  tyUnknown* = tyFromExpr

  tyUnknownTypes* = {tyError, tyFromExpr}

  tyTypeClasses* = {tyBuiltInTypeClass, tyCompositeTypeClass,
                    tyUserTypeClass, tyUserTypeClassInst,
                    tyAnd, tyOr, tyNot, tyAnything}

  tyMetaTypes* = {tyGenericParam, tyTypeDesc, tyUntyped} + tyTypeClasses
  tyUserTypeClasses* = {tyUserTypeClass, tyUserTypeClassInst}
  # consider renaming as `tyAbstractVarRange`
  abstractVarRange* = {tyGenericInst, tyRange, tyVar, tyDistinct, tyOrdinal,
                       tyTypeDesc, tyAlias, tyInferred, tySink, tyOwned}
  abstractInst* = {tyGenericInst, tyDistinct, tyOrdinal, tyTypeDesc, tyAlias,
                   tyInferred, tySink, tyOwned} # xxx what about tyStatic?

const
  TypeKindBits = 8'u32
  TypeKindMask = (1'u32 shl TypeKindBits) - 1'u32

type
  TypeNode* = object     # 4 bytes
    x: uint32

template kind*(n: TypeNode): TTypeKind = TTypeKind(n.x and TypeKindMask)
template operand(n: TypeNode): uint32 = (n.x shr TypeKindBits)

proc integralBits*(n: TypeNode): int {.inline.} =
  # Number of bits in the IntTy, etc. Only valid for integral types.
  assert n.kind in {tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64}
  result = int(n.operand)

template toX(k: TTypeKind; operand: uint32): uint32 =
  uint32(k) or (operand shl TypeKindBits)

template toX(k: TTypeKind; operand: LitId): uint32 =
  uint32(k) or (operand.uint32 shl TypeKindBits)

type
  TTypeAttachedOp* = enum ## as usual, order is important here
    attachedWasMoved,
    attachedDestructor,
    attachedAsgn,
    attachedDup,
    attachedSink,
    attachedTrace,
    attachedDeepCopy

  TType* = object             # Keep in sync with PackedType
    owner*: PSym              # the 'owner' of the type
    sym*: PSym                # types have the sym associated with them
                              # it is used for converting types to strings
    size*: BiggestInt         # the size of the type in bytes
                              # -1 means that the size is unkwown
    align*: int16             # the type's alignment requirements
    paddingAtEnd*: int16      #
    loc*: TLoc
    typeInst*: PType          # for generic instantiations the tyGenericInst that led to this
                              # type.

type
  Literals* = object
    strings*: BiTable[string]
    numbers*: BiTable[int64]

  TypeGraph* = object
    nodes: seq[TypeNode]
    lit: Literals
    ext*: Table[PType, TType]
    flags*: Table[PType, TTypeFlags]
    n*: Table[PType, PNode]
    callConv*: Table[PType, TCallingConvention]

proc prepareExt*(g: var TypeGraph; t: PType): var TType =
  result = g.ext.mgetOrPut(t, default(TType))

const
  VoidId* = PType 0
  Bool8Id* = PType 1
  Char8Id* = PType 2
  LastBuiltinId* = 3

proc initTypeGraph*(lit: Literals): TypeGraph =
  result = TypeGraph(nodes: @[
    TypeNode(x: toX(tyVoid, 0'u32)),
    TypeNode(x: toX(tyBool, 8'u32)),
    TypeNode(x: toX(tyChar, 8'u32)),
  ], lit: lit)
  assert result.nodes.len == LastBuiltinId

type
  TypePatchPos* = distinct int

const
  InvalidTypePatchPos* = TypePatchPos(-1)

  TypeAtoms = {tyNone, tyBool, tyChar,
    tyEmpty, tyNil,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64,
    tyVoid,
    tyIntVal,
    tyStrVal}

proc isValid(p: TypePatchPos): bool {.inline.} = p.int != -1

proc prepare(tree: var TypeGraph; kind: TTypeKind): TypePatchPos =
  result = TypePatchPos tree.nodes.len
  tree.nodes.add TypeNode(x: toX(kind, 1'u32))

proc isAtom(tree: TypeGraph; pos: int): bool {.inline.} = tree.nodes[pos].kind in TypeAtoms
proc isAtom(tree: TypeGraph; pos: PType): bool {.inline.} = tree.nodes[pos.int].kind in TypeAtoms

proc patch(tree: var TypeGraph; pos: TypePatchPos) =
  let pos = pos.int
  let k = tree.nodes[pos].kind
  assert k notin TypeAtoms
  let distance = int32(tree.nodes.len - pos)
  assert distance > 0
  tree.nodes[pos].x = toX(k, cast[uint32](distance))

proc len*(tree: TypeGraph): int {.inline.} = tree.nodes.len

template rawSpan(n: TypeNode): int = int(operand(n))

proc nextChild(tree: TypeGraph; pos: var int) {.inline.} =
  if tree.nodes[pos].kind notin TypeAtoms:
    assert tree.nodes[pos].operand > 0'u32
    inc pos, tree.nodes[pos].rawSpan
  else:
    inc pos

iterator sons*(tree: TypeGraph; n: PType): PType =
  var pos = n.int
  assert tree.nodes[pos].kind notin TypeAtoms
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  while pos < last:
    yield PType pos
    nextChild tree, pos

template `[]`*(t: TypeGraph; n: PType): TypeNode = t.nodes[n.int]

when false:
  proc elementType*(tree: TypeGraph; n: PType): PType {.inline.} =
    assert tree[n].kind in {}
    result = PType(n.int+1)

proc litId*(n: TypeNode): LitId {.inline.} =
  assert n.kind in {tyIntVal, tyStrVal, tyExtVal}
  result = LitId(n.operand)

proc kind*(tree: TypeGraph; n: PType): TTypeKind {.inline.} = tree[n].kind

proc span(tree: TypeGraph; pos: int): int {.inline.} =
  if tree.nodes[pos].kind in TypeAtoms: 1 else: int(tree.nodes[pos].operand)

proc sons2(tree: TypeGraph; n: PType): (PType, PType) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  result = (PType a, PType b)

proc sons3(tree: TypeGraph; n: PType): (PType, PType, PType) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  result = (PType a, PType b, PType c)

proc returnType*(tree: TypeGraph; n: PType): (PType, PType) =
  # Returns the positions of the return type + calling convention.
  var pos = n.int
  assert tree.nodes[pos].kind == tyProc
  let a = n.int+1
  let b = a + span(tree, a)
  result = (PType b, PType a) # not a typo, order is reversed

iterator params*(tree: TypeGraph; n: PType): PType =
  var pos = n.int
  assert tree.nodes[pos].kind == tyProc
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  nextChild tree, pos
  nextChild tree, pos
  while pos < last:
    yield PType pos
    nextChild tree, pos

proc openType*(tree: var TypeGraph; kind: TTypeKind): TypePatchPos =
  assert kind notin TypeAtoms
  result = prepare(tree, kind)

template typeInvariant(p: TypePatchPos) =
  when false:
    if tree[PType(p)].kind == FieldDecl:
      var k = 0
      for ch in sons(tree, PType(p)):
        inc k
      assert k > 2, "damn! " & $k

proc sealType*(tree: var TypeGraph; p: TypePatchPos) =
  patch tree, p
  typeInvariant(p)

proc finishType*(tree: var TypeGraph; p: TypePatchPos): PType =
  # Search for an existing instance of this type in
  # order to reduce memory consumption:
  patch tree, p
  typeInvariant(p)

  let s = span(tree, p.int)
  var i = 0
  while i < p.int:
    if tree.nodes[i].x == tree.nodes[p.int].x:
      var isMatch = true
      for j in 1..<s:
        if tree.nodes[j+i].x == tree.nodes[j+p.int].x:
          discard "still a match"
        else:
          isMatch = false
          break
      if isMatch:
        if p.int+s == tree.len:
          setLen tree.nodes, p.int
        return PType(i)
    nextChild tree, i
  result = PType(p)

proc nominalType*(tree: var TypeGraph; kind: TTypeKind; name: string): PType =
  assert kind in {tyObject, tyEnum, tyDistinct}
  let content = TypeNode(x: toX(kind, tree.lit.strings.getOrIncl(name)))
  for i in 0..<tree.len:
    if tree.nodes[i].x == content.x:
      return PType(i)
  result = PType tree.nodes.len
  tree.nodes.add content

proc addNominalType*(tree: var TypeGraph; kind: TTypeKind; name: string) =
  assert kind in {tyObject, tyEnum, tyDistinct}
  tree.nodes.add TypeNode(x: toX(kind, tree.lit.strings.getOrIncl(name)))

proc getTypeTag*(tree: TypeGraph; t: PType): string =
  assert tree[t].kind in {tyObject, tyEnum, tyDistinct}
  result = tree.lit.strings[LitId tree[t].operand]

proc getFloat128Type*(tree: var TypeGraph): PType =
  result = PType tree.nodes.len
  tree.nodes.add TypeNode(x: toX(tyFloat, 128'u32))

proc addBuiltinType*(g: var TypeGraph; id: PType) =
  g.nodes.add g[id]

template firstSon*(n: PType): PType = PType(n.int+1)

proc addType*(g: var TypeGraph; t: PType) =
  # We cannot simply copy `*Decl` nodes. We have to introduce `*Ty` nodes instead:
  if g[t].kind in {tyObject, tyEnum, tyDistinct}:
    assert g[t.firstSon].kind == tyStrVal
    let name = LitId g[t.firstSon].operand
    g.nodes.add TypeNode(x: toX(g[t].kind, 2))
    g.nodes.add TypeNode(x: toX(tyStrVal, name))
  else:
    let pos = t.int
    let L = span(g, pos)
    let d = g.nodes.len
    g.nodes.setLen(d + L)
    assert L > 0
    for i in 0..<L:
      g.nodes[d+i] = g.nodes[pos+i]

proc addIntVal*(g: var TypeGraph; len: int64) =
  g.nodes.add TypeNode(x: toX(tyIntVal, g.lit.numbers.getOrIncl(len)))

proc addName*(g: var TypeGraph; name: string) =
  g.nodes.add TypeNode(x: toX(tyStrVal, g.lit.strings.getOrIncl(name)))

proc addField*(g: var TypeGraph; name: string; typ: PType; offset: int64) =
  let f = g.openType tyFieldDecl
  g.addType typ
  g.addIntVal offset
  g.addName name
  sealType(g, f)

proc wrapTypeOf*(g: var TypeGraph; t: PType; k: TTypeKind): PType =
  let f = g.openType k
  g.addType t
  result = finishType(g, f)

proc store*(r: var RodFile; g: TypeGraph) =
  storeSeq r, g.nodes

proc load*(r: var RodFile; g: var TypeGraph) =
  loadSeq r, g.nodes

proc toString*(dest: var string; g: TypeGraph; i: PType) =
  case g[i].kind
  of tyVoid, tyNil, tyNone, tyEmpty: dest.add $g[i].kind
  of tyInt, tyInt8, tyInt16, tyInt32, tyInt64:
    dest.add "i"
    dest.addInt g[i].operand
  of tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64:
    dest.add "u"
    dest.addInt g[i].operand
  of tyFloat, tyFloat32, tyFloat64, tyFloat128:
    dest.add "f"
    dest.addInt g[i].operand
  of tyBool:
    dest.add "b"
    dest.addInt g[i].operand
  of tyChar:
    dest.add "c"
    dest.addInt g[i].operand
  of tyStrVal:
    dest.add g.lit.strings[LitId g[i].operand]
  of tyIntVal:
    dest.add $g[i].kind
    dest.add ' '
    dest.add $g.lit.numbers[LitId g[i].operand]
  of tyFieldDecl:
    dest.add "field["
    for t in sons(g, i):
      toString(dest, g, t)
      dest.add ' '
    dest.add "]"
  else:
    dest.add $g[i].kind
    dest.add "["
    for t in sons(g, i):
      dest.add ' '
      toString(dest, g, t)
    dest.add "]"

proc toString*(dest: var string; g: TypeGraph) =
  var i = 0
  while i < g.len:
    dest.add "T<"
    dest.addInt i
    dest.add "> "
    toString(dest, g, PType i)
    dest.add '\n'
    nextChild g, i

iterator allTypes*(g: TypeGraph; start = 0): PType =
  var i = start
  while i < g.len:
    yield PType i
    nextChild g, i

iterator allTypesIncludingInner*(g: TypeGraph; start = 0): PType =
  var i = start
  while i < g.len:
    yield PType i
    inc i

proc `$`(g: TypeGraph): string =
  result = ""
  toString(result, g)
