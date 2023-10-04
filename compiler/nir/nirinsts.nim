#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## NIR instructions. Somewhat inspired by LLVM's instructions.

import std / [assertions, hashes, strformat]
import .. / ic / bitabs
import nirlineinfos, nirtypes

type
  SymId* = distinct int

proc `$`*(s: SymId): string {.borrow.}
proc hash*(s: SymId): Hash {.borrow.}
proc `==`*(a, b: SymId): bool {.borrow.}

type
  Opcode* = enum
    Nop,
    ImmediateVal,
    IntVal,
    StrVal,
    SymDef,
    SymUse,
    ModuleId,
    Typed,   # with type ID
    NilVal,
    Label,
    Goto,
    CheckedGoto,
    LoopLabel,
    GotoLoop,  # last atom

    ModuleSymUse, # `module.x`

    ArrayConstr,
    ObjConstr,
    Ret,
    Yld,

    Select,
    SelectPair,  # ((values...), Label)
    SelectList,  # (values...)
    SelectValue, # (value)
    SelectRange, # (valueA..valueB)
    SummonGlobal,
    SummonThreadLocal,
    Summon, # x = Summon Typed <Type ID>; x begins to live
    Kill, # `Kill x`: scope end for `x`

    AddrOf,
    ArrayAt, # addr(a[i])
    FieldAt, # addr(obj.field)

    Load, # a[]
    Store, # a[] = b
    Asgn,  # a = b
    SetExc,
    TestExc,

    Call,
    IndirectCall,
    CheckedCall, # call that can raise
    CheckedIndirectCall, # call that can raise
    CheckedAdd, # with overflow checking etc.
    CheckedSub,
    CheckedMul,
    CheckedDiv,
    CheckedMod,
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    BitShl,
    BitShr,
    BitAnd,
    BitOr,
    BitXor,
    BitNot,
    Eq,
    Le,
    Lt,
    Cast,
    NumberConv,
    CheckedObjConv,
    ObjConv,
    TestOf,
    Emit,
    ProcDecl

const
  LastAtomicValue = GotoLoop

  OpcodeBits = 8'u32
  OpcodeMask = (1'u32 shl OpcodeBits) - 1'u32

  ValueProducingAtoms = {ImmediateVal, IntVal, StrVal, SymUse, NilVal}

  ValueProducing* = {
    ImmediateVal,
    IntVal,
    StrVal,
    SymUse,
    NilVal,
    ModuleSymUse,
    ArrayConstr,
    ObjConstr,
    CheckedAdd,
    CheckedSub,
    CheckedMul,
    CheckedDiv,
    CheckedMod,
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    BitShl,
    BitShr,
    BitAnd,
    BitOr,
    BitXor,
    BitNot,
    Eq,
    Le,
    Lt,
    Cast,
    NumberConv,
    CheckedObjConv,
    ObjConv,
    AddrOf,
    Load,
    ArrayAt,
    FieldAt,
    TestOf
  }

type
  Instr* = object     # 8 bytes
    x: uint32
    info: PackedLineInfo

template kind*(n: Instr): Opcode = Opcode(n.x and OpcodeMask)
template operand(n: Instr): uint32 = (n.x shr OpcodeBits)

template toX(k: Opcode; operand: uint32): uint32 =
  uint32(k) or (operand shl OpcodeBits)

template toX(k: Opcode; operand: LitId): uint32 =
  uint32(k) or (operand.uint32 shl OpcodeBits)

proc `$`*(n: Instr): string =
  result = fmt"{n.kind}: {n.operand}"


type
  Tree* = object
    nodes: seq[Instr]

  Values* = object
    numbers: BiTable[int64]
    strings: BiTable[string]

type
  PatchPos* = distinct int
  NodePos* = distinct int

const
  InvalidPatchPos* = PatchPos(-1)

proc debug*(t: Tree) {.deprecated.} =
  for i in t.nodes:
    echo i

proc isValid(p: PatchPos): bool {.inline.} = p.int != -1

proc prepare*(tree: var Tree; info: PackedLineInfo; kind: Opcode): PatchPos =
  result = PatchPos tree.nodes.len
  tree.nodes.add Instr(x: toX(kind, 1'u32), info: info)

proc isAtom(tree: Tree; pos: int): bool {.inline.} = tree.nodes[pos].kind <= LastAtomicValue
proc isAtom(tree: Tree; pos: NodePos): bool {.inline.} = tree.nodes[pos.int].kind <= LastAtomicValue

proc patch*(tree: var Tree; pos: PatchPos) =
  let pos = pos.int
  let k = tree.nodes[pos].kind
  assert k > LastAtomicValue
  let distance = int32(tree.nodes.len - pos)
  assert distance > 0
  tree.nodes[pos].x = toX(k, cast[uint32](distance))

template build*(tree: var Tree; info: PackedLineInfo; kind: Opcode; body: untyped) =
  let pos = prepare(tree, info, kind)
  body
  patch(tree, pos)

proc len*(tree: Tree): int {.inline.} = tree.nodes.len

template rawSpan(n: Instr): int = int(operand(n))

proc nextChild(tree: Tree; pos: var int) {.inline.} =
  if tree.nodes[pos].kind > LastAtomicValue:
    assert tree.nodes[pos].operand > 0'u32
    inc pos, tree.nodes[pos].rawSpan
  else:
    inc pos

iterator sons*(tree: Tree; n: NodePos): NodePos =
  var pos = n.int
  assert tree.nodes[pos].kind > LastAtomicValue
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  while pos < last:
    yield NodePos pos
    nextChild tree, pos

template `[]`*(t: Tree; n: NodePos): Instr = t.nodes[n.int]

proc span(tree: Tree; pos: int): int {.inline.} =
  if tree.nodes[pos].kind <= LastAtomicValue: 1 else: int(tree.nodes[pos].operand)

proc copyTree*(dest: var Tree; src: Tree) =
  let pos = 0
  let L = span(src, pos)
  let d = dest.nodes.len
  dest.nodes.setLen(d + L)
  assert L > 0
  for i in 0..<L:
    dest.nodes[d+i] = src.nodes[pos+i]

type
  LabelId* = distinct int

proc newLabel*(labelGen: var int): LabelId {.inline.} =
  result = LabelId labelGen
  inc labelGen

proc addNewLabel*(t: var Tree; labelGen: var int; info: PackedLineInfo; k: Opcode): LabelId =
  assert k in {Label, LoopLabel}
  result = LabelId labelGen
  t.nodes.add Instr(x: toX(k, uint32(result)), info: info)
  inc labelGen

proc boolVal*(t: var Tree; info: PackedLineInfo; b: bool) =
  t.nodes.add Instr(x: toX(ImmediateVal, uint32(b)), info: info)

proc gotoLabel*(t: var Tree; info: PackedLineInfo; k: Opcode; L: LabelId) =
  assert k in {Goto, GotoLoop, CheckedGoto}
  t.nodes.add Instr(x: toX(k, uint32(L)), info: info)

proc addLabel*(t: var Tree; info: PackedLineInfo; k: Opcode; L: LabelId) {.inline.} =
  assert k in {Label, LoopLabel, Goto, GotoLoop, CheckedGoto}
  t.nodes.add Instr(x: toX(k, uint32(L)), info: info)

proc addSymUse*(t: var Tree; info: PackedLineInfo; s: SymId) {.inline.} =
  t.nodes.add Instr(x: toX(SymUse, uint32(s)), info: info)

proc addTyped*(t: var Tree; info: PackedLineInfo; typ: TypeId) {.inline.} =
  t.nodes.add Instr(x: toX(Typed, uint32(typ)), info: info)

proc addSummon*(t: var Tree; info: PackedLineInfo; s: SymId; typ: TypeId) {.inline.} =
  let x = prepare(t, info, Summon)
  t.nodes.add Instr(x: toX(SymDef, uint32(s)), info: info)
  t.nodes.add Instr(x: toX(Typed, uint32(typ)), info: info)
  patch t, x

proc addImmediateVal*(t: var Tree; info: PackedLineInfo; x: int) =
  assert x >= 0 and x < ((1 shl 32) - OpcodeBits.int)
  t.nodes.add Instr(x: toX(ImmediateVal, uint32(x)), info: info)

type
  Value* = distinct Tree

proc prepare*(dest: var Value; info: PackedLineInfo; k: Opcode): PatchPos {.inline.} =
  assert k in ValueProducing - ValueProducingAtoms
  result = prepare(Tree(dest), info, k)

proc patch*(dest: var Value; pos: PatchPos) {.inline.} =
  patch(Tree(dest), pos)

proc localToValue*(info: PackedLineInfo; s: SymId): Value =
  result = Value(Tree())
  Tree(result).addSymUse info, s

proc hasValue*(v: Value): bool {.inline.} = Tree(v).len > 0

proc isEmpty*(v: Value): bool {.inline.} = Tree(v).len == 0

proc extractTemp*(v: Value): SymId =
  if hasValue(v) and Tree(v)[NodePos 0].kind == SymUse:
    result = SymId(Tree(v)[NodePos 0].operand)
  else:
    result = SymId(-1)

proc copyTree*(dest: var Tree; src: Value) = copyTree dest, Tree(src)

proc addImmediateVal*(t: var Value; info: PackedLineInfo; x: int) =
  assert x >= 0 and x < ((1 shl 32) - OpcodeBits.int)
  Tree(t).nodes.add Instr(x: toX(ImmediateVal, uint32(x)), info: info)

template build*(tree: var Value; info: PackedLineInfo; kind: Opcode; body: untyped) =
  let pos = prepare(Tree(tree), info, kind)
  body
  patch(tree, pos)

proc addTyped*(t: var Value; info: PackedLineInfo; typ: TypeId) {.inline.} =
  addTyped(Tree(t), info, typ)
