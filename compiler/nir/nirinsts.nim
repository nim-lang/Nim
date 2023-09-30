#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## NIR instructions. Somewhat inspired by LLVM's instructions.

import std / assertions
import .. / ic / bitabs
import nirlineinfos

type
  SymId* = distinct int
  InstKind* = enum
    Nop,
    ImmediateVal,
    IntVal,
    StrVal,
    SymDef,
    SymUse,
    ModuleId, # module ID
    ModuleSymUse, # `module.x`
    Label,
    Goto,
    GotoBack,
    Typed,   # with type ID
    NilVal,  # last atom

    ArrayConstr,
    ObjConstr,
    Ret,
    Yld,

    Select,
    SummonGlobal,
    SummonThreadLocal,
    Summon, # x = Summon Typed <Type ID>; x begins to live
    Kill, # `Kill x`: scope end for `x`
    Load,
    Store,
    ArrayAt, # addr(a[i])
    FieldAt, # addr(obj.field)

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
    Emit,
    ProcDecl

const
  LastAtomicValue = NilVal

  InstKindBits = 8'u32
  InstKindMask = (1'u32 shl InstKindBits) - 1'u32

type
  Instr* = object     # 8 bytes
    x: uint32
    info: PackedLineInfo

template kind*(n: Instr): InstKind = InstKind(n.x and InstKindMask)
template operand(n: Instr): uint32 = (n.x shr InstKindBits)

template toX(k: InstKind; operand: uint32): uint32 =
  uint32(k) or (operand shl InstKindBits)

template toX(k: InstKind; operand: LitId): uint32 =
  uint32(k) or (operand.uint32 shl InstKindBits)

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

proc isValid(p: PatchPos): bool {.inline.} = p.int != -1

proc prepare(tree: var Tree; kind: InstKind): PatchPos =
  result = PatchPos tree.nodes.len
  tree.nodes.add Instr(x: toX(kind, 1'u32))

proc isAtom(tree: Tree; pos: int): bool {.inline.} = tree.nodes[pos].kind <= LastAtomicValue
proc isAtom(tree: Tree; pos: NodePos): bool {.inline.} = tree.nodes[pos.int].kind <= LastAtomicValue

proc patch(tree: var Tree; pos: PatchPos) =
  let pos = pos.int
  let k = tree.nodes[pos].kind
  assert k > LastAtomicValue
  let distance = int32(tree.nodes.len - pos)
  assert distance > 0
  tree.nodes[pos].x = toX(k, cast[uint32](distance))

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


