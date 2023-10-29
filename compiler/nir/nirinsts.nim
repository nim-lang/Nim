#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## NIR instructions. Somewhat inspired by LLVM's instructions.

import std / [assertions, hashes]
import .. / ic / [bitabs, rodfiles]
import nirlineinfos, nirtypes

const
  NirVersion = 1
  nirCookie* = [byte(0), byte('N'), byte('I'), byte('R'),
            byte(sizeof(int)*8), byte(system.cpuEndian), byte(0), byte(NirVersion)]

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
    Typed,   # with type ID
    PragmaId, # with Pragma ID, possible values: see PragmaKey enum
    NilVal,
    Label,
    Goto,
    CheckedGoto,
    LoopLabel,
    GotoLoop,  # last atom

    ModuleSymUse, # `"module".x`

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
    SummonResult,
    SummonParam,
    SummonConst,
    Kill, # `Kill x`: scope end for `x`

    AddrOf,
    ArrayAt, # addr(a[i])
    FieldAt, # addr(obj.field)

    Load, # a[]
    Store, # a[] = b
    Asgn,  # a = b
    SetExc,
    TestExc,

    CheckedRange,
    CheckedIndex,

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
    BoolNot,
    Eq,
    Le,
    Lt,
    Cast,
    NumberConv,
    CheckedObjConv,
    ObjConv,
    TestOf,
    Emit,
    ProcDecl,
    PragmaPair

type
  PragmaKey* = enum
    FastCall, StdCall, CDeclCall, SafeCall, SysCall, InlineCall, NoinlineCall, ThisCall, NoCall,
    CoreName,
    ExternName,
    HeaderImport,
    DllImport,
    DllExport,
    ObjExport

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
    BoolNot,
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
    info*: PackedLineInfo

template kind*(n: Instr): Opcode = Opcode(n.x and OpcodeMask)
template operand(n: Instr): uint32 = (n.x shr OpcodeBits)

template rawOperand*(n: Instr): uint32 = (n.x shr OpcodeBits)

template toX(k: Opcode; operand: uint32): uint32 =
  uint32(k) or (operand shl OpcodeBits)

template toX(k: Opcode; operand: LitId): uint32 =
  uint32(k) or (operand.uint32 shl OpcodeBits)

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

template buildTyped*(tree: var Tree; info: PackedLineInfo; kind: Opcode; typ: TypeId; body: untyped) =
  let pos = prepare(tree, info, kind)
  tree.addTyped info, typ
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

proc next*(tree: Tree; pos: var NodePos) {.inline.} = nextChild tree, int(pos)

template firstSon*(n: NodePos): NodePos = NodePos(n.int+1)

iterator sons*(tree: Tree; n: NodePos): NodePos =
  var pos = n.int
  assert tree.nodes[pos].kind > LastAtomicValue
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  while pos < last:
    yield NodePos pos
    nextChild tree, pos

iterator sonsFrom1*(tree: Tree; n: NodePos): NodePos =
  var pos = n.int
  assert tree.nodes[pos].kind > LastAtomicValue
  let last = pos + tree.nodes[pos].rawSpan
  inc pos
  nextChild tree, pos
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

proc sons2*(tree: Tree; n: NodePos): (NodePos, NodePos) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  result = (NodePos a, NodePos b)

proc sons3*(tree: Tree; n: NodePos): (NodePos, NodePos, NodePos) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  result = (NodePos a, NodePos b, NodePos c)

proc typeId*(ins: Instr): TypeId {.inline.} =
  assert ins.kind == Typed
  result = TypeId(ins.operand)

proc symId*(ins: Instr): SymId {.inline.} =
  assert ins.kind in {SymUse, SymDef}
  result = SymId(ins.operand)

proc immediateVal*(ins: Instr): int {.inline.} =
  assert ins.kind == ImmediateVal
  result = cast[int](ins.operand)

proc litId*(ins: Instr): LitId {.inline.} =
  assert ins.kind in {StrVal, IntVal}
  result = LitId(ins.operand)


type
  LabelId* = distinct int

proc `==`*(a, b: LabelId): bool {.borrow.}
proc hash*(a: LabelId): Hash {.borrow.}

proc label*(ins: Instr): LabelId {.inline.} =
  assert ins.kind in {Label, LoopLabel, Goto, GotoLoop, CheckedGoto}
  result = LabelId(ins.operand)

proc newLabel*(labelGen: var int): LabelId {.inline.} =
  result = LabelId labelGen
  inc labelGen

proc newLabels*(labelGen: var int; n: int): LabelId {.inline.} =
  result = LabelId labelGen
  inc labelGen, n

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

proc addSymDef*(t: var Tree; info: PackedLineInfo; s: SymId) {.inline.} =
  t.nodes.add Instr(x: toX(SymDef, uint32(s)), info: info)

proc addTyped*(t: var Tree; info: PackedLineInfo; typ: TypeId) {.inline.} =
  assert typ.int >= 0
  t.nodes.add Instr(x: toX(Typed, uint32(typ)), info: info)

proc addSummon*(t: var Tree; info: PackedLineInfo; s: SymId; typ: TypeId; opc = Summon) {.inline.} =
  assert typ.int >= 0
  assert opc in {Summon, SummonConst, SummonGlobal, SummonThreadLocal, SummonParam, SummonResult}
  let x = prepare(t, info, opc)
  t.nodes.add Instr(x: toX(Typed, uint32(typ)), info: info)
  t.nodes.add Instr(x: toX(SymDef, uint32(s)), info: info)
  patch t, x

proc addImmediateVal*(t: var Tree; info: PackedLineInfo; x: int) =
  assert x >= 0 and x < ((1 shl 32) - OpcodeBits.int)
  t.nodes.add Instr(x: toX(ImmediateVal, uint32(x)), info: info)

proc addPragmaId*(t: var Tree; info: PackedLineInfo; x: PragmaKey) =
  t.nodes.add Instr(x: toX(PragmaId, uint32(x)), info: info)

proc addIntVal*(t: var Tree; integers: var BiTable[int64]; info: PackedLineInfo; typ: TypeId; x: int64) =
  buildTyped t, info, NumberConv, typ:
    t.nodes.add Instr(x: toX(IntVal, uint32(integers.getOrIncl(x))), info: info)

proc addStrVal*(t: var Tree; strings: var BiTable[string]; info: PackedLineInfo; s: string) =
  t.nodes.add Instr(x: toX(StrVal, uint32(strings.getOrIncl(s))), info: info)

proc addStrLit*(t: var Tree; info: PackedLineInfo; s: LitId) =
  t.nodes.add Instr(x: toX(StrVal, uint32(s)), info: info)

proc addNilVal*(t: var Tree; info: PackedLineInfo; typ: TypeId) =
  buildTyped t, info, NumberConv, typ:
    t.nodes.add Instr(x: toX(NilVal, uint32(0)), info: info)

proc store*(r: var RodFile; t: Tree) = storeSeq r, t.nodes
proc load*(r: var RodFile; t: var Tree) = loadSeq r, t.nodes

proc escapeToNimLit*(s: string; result: var string) =
  result.add '"'
  for c in items s:
    if c < ' ' or int(c) >= 128:
      result.add '\\'
      result.addInt int(c)
    elif c == '\\':
      result.add r"\\"
    elif c == '\n':
      result.add r"\n"
    elif c == '\r':
      result.add r"\r"
    elif c == '\t':
      result.add r"\t"
    else:
      result.add c
  result.add '"'

type
  SymNames* = object
    s: seq[LitId]

proc `[]=`*(t: var SymNames; key: SymId; val: LitId) =
  let k = int(key)
  if k >= t.s.len: t.s.setLen k+1
  t.s[k] = val

proc `[]`*(t: SymNames; key: SymId): LitId =
  let k = int(key)
  if k < t.s.len: result = t.s[k]
  else: result = LitId(0)

template localName(s: SymId): string =
  let name = names[s]
  if name != LitId(0):
    strings[name]
  else:
    $s.int

proc store*(r: var RodFile; t: SymNames) = storeSeq(r, t.s)
proc load*(r: var RodFile; t: var SymNames) = loadSeq(r, t.s)

proc toString*(t: Tree; pos: NodePos; strings: BiTable[string]; integers: BiTable[int64];
               names: SymNames;
               r: var string; nesting = 0) =
  if r.len > 0 and r[r.len-1] notin {' ', '\n', '(', '[', '{'}:
    r.add ' '

  case t[pos].kind
  of Nop: r.add "Nop"
  of ImmediateVal:
    r.add $t[pos].operand
  of IntVal:
    r.add "IntVal "
    r.add $integers[LitId t[pos].operand]
  of StrVal:
    escapeToNimLit(strings[LitId t[pos].operand], r)
  of SymDef:
    r.add "SymDef "
    r.add localName(SymId t[pos].operand)
  of SymUse:
    r.add "SymUse "
    r.add localName(SymId t[pos].operand)
  of PragmaId:
    r.add $cast[PragmaKey](t[pos].operand)
  of Typed:
    r.add "T<"
    r.add $t[pos].operand
    r.add ">"
  of NilVal:
    r.add "NilVal"
  of Label:
    # undo the nesting:
    var spaces = r.len-1
    while spaces >= 0 and r[spaces] == ' ': dec spaces
    r.setLen spaces+1
    r.add "\n  L"
    r.add $t[pos].operand
  of Goto, CheckedGoto, LoopLabel, GotoLoop:
    r.add $t[pos].kind
    r.add " L"
    r.add $t[pos].operand
  else:
    r.add $t[pos].kind
    r.add "{\n"
    for i in 0..<(nesting+1)*2: r.add ' '
    for p in sons(t, pos):
      toString t, p, strings, integers, names, r, nesting+1
    r.add "\n"
    for i in 0..<nesting*2: r.add ' '
    r.add "}"

proc allTreesToString*(t: Tree; strings: BiTable[string]; integers: BiTable[int64];
                       names: SymNames;
                       r: var string) =
  var i = 0
  while i < t.len:
    toString t, NodePos(i), strings, integers, names, r
    nextChild t, i

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

template buildTyped*(tree: var Value; info: PackedLineInfo; kind: Opcode; typ: TypeId; body: untyped) =
  let pos = prepare(tree, info, kind)
  tree.addTyped info, typ
  body
  patch(tree, pos)

proc addStrVal*(t: var Value; strings: var BiTable[string]; info: PackedLineInfo; s: string) =
  addStrVal(Tree(t), strings, info, s)

proc addNilVal*(t: var Value; info: PackedLineInfo; typ: TypeId) =
  addNilVal Tree(t), info, typ

proc addIntVal*(t: var Value; integers: var BiTable[int64]; info: PackedLineInfo; typ: TypeId; x: int64) =
  addIntVal Tree(t), integers, info, typ, x
