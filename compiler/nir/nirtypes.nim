#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Type system for NIR. Close to C's type system but without its quirks.

import std / [assertions, hashes]
import .. / ic / [bitabs, rodfiles]

type
  NirTypeKind* = enum
    VoidTy, IntTy, UIntTy, FloatTy, BoolTy, CharTy, NameVal,
    IntVal, SizeVal, AlignVal, OffsetVal,
    AnnotationVal,
    ObjectTy,
    UnionTy,
    VarargsTy, # the `...` in a C prototype; also the last "atom"
    APtrTy, # pointer to aliasable memory
    UPtrTy, # pointer to unique/unaliasable memory
    AArrayPtrTy, # pointer to array of aliasable memory
    UArrayPtrTy, # pointer to array of unique/unaliasable memory
    ArrayTy,
    LastArrayTy, # array of unspecified size as a last field inside an object
    ProcTy,
    ObjectDecl,
    UnionDecl,
    FieldDecl

const
  TypeKindBits = 8'u32
  TypeKindMask = (1'u32 shl TypeKindBits) - 1'u32

type
  TypeNode* = object     # 4 bytes
    x: uint32

template kind*(n: TypeNode): NirTypeKind = NirTypeKind(n.x and TypeKindMask)
template operand(n: TypeNode): uint32 = (n.x shr TypeKindBits)

proc integralBits*(n: TypeNode): int {.inline.} =
  # Number of bits in the IntTy, etc. Only valid for integral types.
  assert n.kind in {IntTy, UIntTy, FloatTy, BoolTy, CharTy}
  result = int(n.operand)

template toX(k: NirTypeKind; operand: uint32): uint32 =
  uint32(k) or (operand shl TypeKindBits)

template toX(k: NirTypeKind; operand: LitId): uint32 =
  uint32(k) or (operand.uint32 shl TypeKindBits)

type
  TypeId* = distinct int

proc `==`*(a, b: TypeId): bool {.borrow.}
proc hash*(a: TypeId): Hash {.borrow.}

type
  Literals* = ref object
    strings*: BiTable[string]
    numbers*: BiTable[int64]

  TypeGraph* = object
    nodes: seq[TypeNode]
    lit: Literals

const
  VoidId* = TypeId 0
  Bool8Id* = TypeId 1
  Char8Id* = TypeId 2
  Int8Id* = TypeId 3
  Int16Id* = TypeId 4
  Int32Id* = TypeId 5
  Int64Id* = TypeId 6
  UInt8Id* = TypeId 7
  UInt16Id* = TypeId 8
  UInt32Id* = TypeId 9
  UInt64Id* = TypeId 10
  Float32Id* = TypeId 11
  Float64Id* = TypeId 12
  VoidPtrId* = TypeId 13
  LastBuiltinId* = 13

proc initTypeGraph*(lit: Literals): TypeGraph =
  result = TypeGraph(nodes: @[
    TypeNode(x: toX(VoidTy, 0'u32)),
    TypeNode(x: toX(BoolTy, 8'u32)),
    TypeNode(x: toX(CharTy, 8'u32)),
    TypeNode(x: toX(IntTy, 8'u32)),
    TypeNode(x: toX(IntTy, 16'u32)),
    TypeNode(x: toX(IntTy, 32'u32)),
    TypeNode(x: toX(IntTy, 64'u32)),
    TypeNode(x: toX(UIntTy, 8'u32)),
    TypeNode(x: toX(UIntTy, 16'u32)),
    TypeNode(x: toX(UIntTy, 32'u32)),
    TypeNode(x: toX(UIntTy, 64'u32)),
    TypeNode(x: toX(FloatTy, 32'u32)),
    TypeNode(x: toX(FloatTy, 64'u32)),
    TypeNode(x: toX(APtrTy, 2'u32)),
    TypeNode(x: toX(VoidTy, 0'u32))
  ], lit: lit)
  assert result.nodes.len == LastBuiltinId+2

type
  TypePatchPos* = distinct int

const
  InvalidTypePatchPos* = TypePatchPos(-1)
  LastAtomicValue = VarargsTy

proc isValid(p: TypePatchPos): bool {.inline.} = p.int != -1

proc prepare(tree: var TypeGraph; kind: NirTypeKind): TypePatchPos =
  result = TypePatchPos tree.nodes.len
  tree.nodes.add TypeNode(x: toX(kind, 1'u32))

proc isAtom(tree: TypeGraph; pos: int): bool {.inline.} = tree.nodes[pos].kind <= LastAtomicValue
proc isAtom(tree: TypeGraph; pos: TypeId): bool {.inline.} = tree.nodes[pos.int].kind <= LastAtomicValue

proc patch(tree: var TypeGraph; pos: TypePatchPos) =
  let pos = pos.int
  let k = tree.nodes[pos].kind
  assert k > LastAtomicValue
  let distance = int32(tree.nodes.len - pos)
  assert distance > 0
  tree.nodes[pos].x = toX(k, cast[uint32](distance))

proc len*(tree: TypeGraph): int {.inline.} = tree.nodes.len

template rawSpan(n: TypeNode): int = int(operand(n))

proc nextChild(tree: TypeGraph; pos: var int) {.inline.} =
  if tree.nodes[pos].kind > LastAtomicValue:
    assert tree.nodes[pos].operand > 0'u32
    inc pos, tree.nodes[pos].rawSpan
  else:
    inc pos

iterator sons*(tree: TypeGraph; n: TypeId): TypeId =
  var pos = n.int
  assert tree.nodes[pos].kind > LastAtomicValue
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  while pos < last:
    yield TypeId pos
    nextChild tree, pos

template `[]`*(t: TypeGraph; n: TypeId): TypeNode = t.nodes[n.int]

proc elementType*(tree: TypeGraph; n: TypeId): TypeId {.inline.} =
  assert tree[n].kind in {APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy, ArrayTy, LastArrayTy}
  result = TypeId(n.int+1)

proc litId*(n: TypeNode): LitId {.inline.} =
  assert n.kind in {NameVal, IntVal, SizeVal, AlignVal, OffsetVal, AnnotationVal, ObjectTy, UnionTy}
  result = LitId(n.operand)

proc kind*(tree: TypeGraph; n: TypeId): NirTypeKind {.inline.} = tree[n].kind

proc span(tree: TypeGraph; pos: int): int {.inline.} =
  if tree.nodes[pos].kind <= LastAtomicValue: 1 else: int(tree.nodes[pos].operand)

proc sons2(tree: TypeGraph; n: TypeId): (TypeId, TypeId) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  result = (TypeId a, TypeId b)

proc sons3(tree: TypeGraph; n: TypeId): (TypeId, TypeId, TypeId) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  result = (TypeId a, TypeId b, TypeId c)

proc arrayName*(tree: TypeGraph; n: TypeId): TypeId {.inline.} =
  assert tree[n].kind == ArrayTy
  let (_, _, c) = sons3(tree, n)
  result = c

proc arrayLen*(tree: TypeGraph; n: TypeId): BiggestInt =
  assert tree[n].kind == ArrayTy
  let (_, b) = sons2(tree, n)
  result = tree.lit.numbers[LitId tree[b].operand]

proc returnType*(tree: TypeGraph; n: TypeId): (TypeId, TypeId) =
  # Returns the positions of the return type + calling convention.
  var pos = n.int
  assert tree.nodes[pos].kind == ProcTy
  let a = n.int+1
  let b = a + span(tree, a)
  result = (TypeId b, TypeId a) # not a typo, order is reversed

iterator params*(tree: TypeGraph; n: TypeId): TypeId =
  var pos = n.int
  assert tree.nodes[pos].kind == ProcTy
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  nextChild tree, pos
  nextChild tree, pos
  while pos < last:
    yield TypeId pos
    nextChild tree, pos

proc openType*(tree: var TypeGraph; kind: NirTypeKind): TypePatchPos =
  assert kind in {APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy,
    ArrayTy, LastArrayTy, ProcTy, ObjectDecl, UnionDecl,
    FieldDecl}
  result = prepare(tree, kind)

template typeInvariant(p: TypePatchPos) =
  when false:
    if tree[TypeId(p)].kind == FieldDecl:
      var k = 0
      for ch in sons(tree, TypeId(p)):
        inc k
      assert k > 2, "damn! " & $k

proc sealType*(tree: var TypeGraph; p: TypePatchPos) =
  patch tree, p
  typeInvariant(p)

proc finishType*(tree: var TypeGraph; p: TypePatchPos): TypeId =
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
        return TypeId(i)
    nextChild tree, i
  result = TypeId(p)

proc nominalType*(tree: var TypeGraph; kind: NirTypeKind; name: string): TypeId =
  assert kind in {ObjectTy, UnionTy}
  let content = TypeNode(x: toX(kind, tree.lit.strings.getOrIncl(name)))
  for i in 0..<tree.len:
    if tree.nodes[i].x == content.x:
      return TypeId(i)
  result = TypeId tree.nodes.len
  tree.nodes.add content

proc addNominalType*(tree: var TypeGraph; kind: NirTypeKind; name: string) =
  assert kind in {ObjectTy, UnionTy}
  tree.nodes.add TypeNode(x: toX(kind, tree.lit.strings.getOrIncl(name)))

proc getTypeTag*(tree: TypeGraph; t: TypeId): string =
  assert tree[t].kind in {ObjectTy, UnionTy}
  result = tree.lit.strings[LitId tree[t].operand]

proc addVarargs*(tree: var TypeGraph) =
  tree.nodes.add TypeNode(x: toX(VarargsTy, 0'u32))

proc getFloat128Type*(tree: var TypeGraph): TypeId =
  result = TypeId tree.nodes.len
  tree.nodes.add TypeNode(x: toX(FloatTy, 128'u32))

proc addBuiltinType*(g: var TypeGraph; id: TypeId) =
  g.nodes.add g[id]

template firstSon*(n: TypeId): TypeId = TypeId(n.int+1)

proc addType*(g: var TypeGraph; t: TypeId) =
  # We cannot simply copy `*Decl` nodes. We have to introduce `*Ty` nodes instead:
  if g[t].kind in {ObjectDecl, UnionDecl}:
    assert g[t.firstSon].kind == NameVal
    let name = LitId g[t.firstSon].operand
    if g[t].kind == ObjectDecl:
      g.nodes.add TypeNode(x: toX(ObjectTy, name))
    else:
      g.nodes.add TypeNode(x: toX(UnionTy, name))
  else:
    let pos = t.int
    let L = span(g, pos)
    let d = g.nodes.len
    g.nodes.setLen(d + L)
    assert L > 0
    for i in 0..<L:
      g.nodes[d+i] = g.nodes[pos+i]

proc addArrayLen*(g: var TypeGraph; len: int64) =
  g.nodes.add TypeNode(x: toX(IntVal, g.lit.numbers.getOrIncl(len)))

proc addSize*(g: var TypeGraph; s: int64) =
  g.nodes.add TypeNode(x: toX(SizeVal, g.lit.numbers.getOrIncl(s)))

proc addOffset*(g: var TypeGraph; offset: int64) =
  g.nodes.add TypeNode(x: toX(OffsetVal, g.lit.numbers.getOrIncl(offset)))

proc addAlign*(g: var TypeGraph; a: int64) =
  g.nodes.add TypeNode(x: toX(AlignVal, g.lit.numbers.getOrIncl(a)))

proc addName*(g: var TypeGraph; name: string) =
  g.nodes.add TypeNode(x: toX(NameVal, g.lit.strings.getOrIncl(name)))

proc addAnnotation*(g: var TypeGraph; name: string) =
  g.nodes.add TypeNode(x: toX(NameVal, g.lit.strings.getOrIncl(name)))

proc addField*(g: var TypeGraph; name: string; typ: TypeId; offset: int64) =
  let f = g.openType FieldDecl
  g.addType typ
  g.addOffset offset
  g.addName name
  sealType(g, f)

proc ptrTypeOf*(g: var TypeGraph; t: TypeId): TypeId =
  let f = g.openType APtrTy
  g.addType t
  result = finishType(g, f)

proc arrayPtrTypeOf*(g: var TypeGraph; t: TypeId): TypeId =
  let f = g.openType AArrayPtrTy
  g.addType t
  result = finishType(g, f)

proc store*(r: var RodFile; g: TypeGraph) =
  storeSeq r, g.nodes

proc load*(r: var RodFile; g: var TypeGraph) =
  loadSeq r, g.nodes

proc toString*(dest: var string; g: TypeGraph; i: TypeId) =
  case g[i].kind
  of VoidTy: dest.add "void"
  of IntTy:
    dest.add "i"
    dest.addInt g[i].operand
  of UIntTy:
    dest.add "u"
    dest.addInt g[i].operand
  of FloatTy:
    dest.add "f"
    dest.addInt g[i].operand
  of BoolTy:
    dest.add "b"
    dest.addInt g[i].operand
  of CharTy:
    dest.add "c"
    dest.addInt g[i].operand
  of NameVal, AnnotationVal:
    dest.add g.lit.strings[LitId g[i].operand]
  of IntVal, SizeVal, AlignVal, OffsetVal:
    dest.add $g[i].kind
    dest.add ' '
    dest.add $g.lit.numbers[LitId g[i].operand]
  of VarargsTy:
    dest.add "..."
  of APtrTy:
    dest.add "aptr["
    toString(dest, g, g.elementType(i))
    dest.add "]"
  of UPtrTy:
    dest.add "uptr["
    toString(dest, g, g.elementType(i))
    dest.add "]"
  of AArrayPtrTy:
    dest.add "aArrayPtr["
    toString(dest, g, g.elementType(i))
    dest.add "]"
  of UArrayPtrTy:
    dest.add "uArrayPtr["
    toString(dest, g, g.elementType(i))
    dest.add "]"
  of ArrayTy:
    dest.add "Array["
    let (elems, len, name) = g.sons3(i)
    toString(dest, g, elems)
    dest.add ", "
    toString(dest, g, len)
    dest.add ", "
    toString(dest, g, name)
    dest.add "]"
  of LastArrayTy:
    # array of unspecified size as a last field inside an object
    dest.add "LastArrayTy["
    toString(dest, g, g.elementType(i))
    dest.add "]"
  of ObjectTy:
    dest.add "object "
    dest.add g.lit.strings[LitId g[i].operand]
  of UnionTy:
    dest.add "union "
    dest.add g.lit.strings[LitId g[i].operand]
  of ProcTy:
    dest.add "proc["
    for t in sons(g, i):
      dest.add ' '
      toString(dest, g, t)
    dest.add "]"
  of ObjectDecl:
    dest.add "object["
    for t in sons(g, i):
      toString(dest, g, t)
      dest.add '\n'
    dest.add "]"
  of UnionDecl:
    dest.add "union["
    for t in sons(g, i):
      toString(dest, g, t)
      dest.add '\n'
    dest.add "]"
  of FieldDecl:
    dest.add "field["
    for t in sons(g, i):
      toString(dest, g, t)
      dest.add ' '
    dest.add "]"

    when false:
      let (typ, offset, name) = g.sons3(i)
      toString(dest, g, typ)
      dest.add ' '
      toString(dest, g, offset)
      dest.add ' '
      toString(dest, g, name)

proc toString*(dest: var string; g: TypeGraph) =
  var i = 0
  while i < g.len:
    dest.add "T<"
    dest.addInt i
    dest.add "> "
    toString(dest, g, TypeId i)
    dest.add '\n'
    nextChild g, i

iterator allTypes*(g: TypeGraph; start = 0): TypeId =
  var i = start
  while i < g.len:
    yield TypeId i
    nextChild g, i

iterator allTypesIncludingInner*(g: TypeGraph; start = 0): TypeId =
  var i = start
  while i < g.len:
    yield TypeId i
    inc i

proc `$`(g: TypeGraph): string =
  result = ""
  toString(result, g)

when isMainModule:
  var g = initTypeGraph(Literals())

  let a = g.openType ArrayTy
  g.addBuiltinType Int8Id
  g.addArrayLen 5
  g.addName "SomeArray"
  let finalArrayType = finishType(g, a)

  let obj = g.openType ObjectDecl
  g.nodes.add TypeNode(x: toX(NameVal, g.lit.strings.getOrIncl("MyType")))

  g.addField "p", finalArrayType, 0
  sealType(g, obj)

  echo g
