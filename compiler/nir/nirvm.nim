#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[ NIR is a little too high level to interpret it efficiently. Thus
we compute `addresses` for SymIds, labels and offsets for object fields
in a preprocessing step.

We also split the instruction stream into separate (code, debug) seqs while
we're at it.
]##

import std / [syncio, assertions, tables, intsets]
import ".." / ic / bitabs
import nirinsts, nirtypes, nirfiles, nirlineinfos

type
  OpcodeM = enum
    ImmediateValM,
    IntValM,
    StrValM,
    LoadLocalM, # with local ID
    LoadGlobalM,
    LoadProcM,
    TypedM,   # with type ID
    PragmaIdM, # with Pragma ID, possible values: see PragmaKey enum
    NilValM,
    AllocLocals,
    SummonParamM,
    GotoM,
    CheckedGotoM, # last atom

    ArrayConstrM,
    ObjConstrM,
    RetM,
    YldM,

    SelectM,
    SelectPairM,  # ((values...), Label)
    SelectListM,  # (values...)
    SelectValueM, # (value)
    SelectRangeM, # (valueA..valueB)

    AddrOfM,
    ArrayAtM, # (elemSize, addr(a), i)
    DerefArrayAtM,
    FieldAtM, # addr(obj.field)
    DerefFieldAtM,

    LoadM, # a[]
    AsgnM,  # a = b
    StoreM, # a[] = b
    SetExcM,
    TestExcM,

    CheckedRangeM,
    CheckedIndexM,

    CallM,
    CheckedAddM, # with overflow checking etc.
    CheckedSubM,
    CheckedMulM,
    CheckedDivM,
    CheckedModM,
    AddM,
    SubM,
    MulM,
    DivM,
    ModM,
    BitShlM,
    BitShrM,
    BitAndM,
    BitOrM,
    BitXorM,
    BitNotM,
    BoolNotM,
    EqM,
    LeM,
    LtM,
    CastM,
    NumberConvM,
    CheckedObjConvM,
    ObjConvM,
    TestOfM,
    ProcDeclM,
    PragmaPairM

const
  LastAtomicValue = CheckedGotoM

  OpcodeBits = 8'u32
  OpcodeMask = (1'u32 shl OpcodeBits) - 1'u32

type
  Instr = distinct uint32

template kind(n: Instr): OpcodeM = OpcodeM(n.uint32 and OpcodeMask)
template operand(n: Instr): uint32 = (n.uint32 shr OpcodeBits)

template toIns(k: OpcodeM; operand: uint32): Instr =
  Instr(uint32(k) or (operand shl OpcodeBits))

template toIns(k: OpcodeM; operand: LitId): Instr =
  Instr(uint32(k) or (operand.uint32 shl OpcodeBits))

type
  NimStrPayloadVM = object
    cap: int
    data: UncheckedArray[char]
  NimStringVM = object
    len: int
    p: ptr NimStrPayloadVM

const
  GlobalsSize = 1024*24

type
  PatchPos = distinct int
  CodePos = distinct int

  Bytecode* = object
    code: seq[Instr]
    debug: seq[PackedLineInfo]
    m: ref NirModule
    procs: Table[SymId, CodePos]
    globals: Table[SymId, (uint32, int)]
    strings: Table[LitId, NimStringVM]
    globalData: pointer
    globalsAddr: uint32
    typeImpls: Table[string, TypeId]
    offsets: Table[TypeId, seq[(int, TypeId)]]
    sizes: Table[TypeId, (int, int)] # (size, alignment)
    oldTypeLen: int
    procUsagesToPatch: Table[SymId, seq[CodePos]]
    interactive*: bool

  Universe* = object ## all units: For interpretation we need that
    units: seq[Bytecode]
    unitNames: Table[string, int]
    current: int

proc initBytecode*(m: ref NirModule): Bytecode = Bytecode(m: m, globalData: alloc0(GlobalsSize))

proc debug(bc: Bytecode; t: TypeId) =
  var buf = ""
  toString buf, bc.m.types, t
  echo buf

proc debug(bc: Bytecode; info: PackedLineInfo) =
  let (litId, line, col) = bc.m.man.unpack(info)
  echo bc.m.lit.strings[litId], ":", line, ":", col

proc debug(bc: Bytecode; t: Tree; n: NodePos) =
  var buf = ""
  toString(t, n, bc.m.lit.strings, bc.m.lit.numbers, bc.m.symnames, buf)
  echo buf

template `[]`(t: seq[Instr]; n: CodePos): Instr = t[n.int]

proc traverseObject(b: var Bytecode; t, offsetKey: TypeId) =
  var size = -1
  var align = -1
  for x in sons(b.m.types, t):
    case b.m.types[x].kind
    of FieldDecl:
      var offset = -1
      for y in sons(b.m.types, x):
        if b.m.types[y].kind == OffsetVal:
          offset = int(b.m.lit.numbers[b.m.types[y].litId])
          break
      b.offsets.mgetOrPut(offsetKey, @[]).add (offset, x.firstSon)
    of SizeVal:
      size = int(b.m.lit.numbers[b.m.types[x].litId])
    of AlignVal:
      align = int(b.m.lit.numbers[b.m.types[x].litId])
    of ObjectTy:
      # inheritance
      let impl = b.typeImpls.getOrDefault(b.m.lit.strings[b.m.types[x].litId])
      assert impl.int > 0
      traverseObject b, impl, offsetKey
    else: discard
  if t == offsetKey:
    b.sizes[t] = (size, align)

proc computeSize(b: var Bytecode; t: TypeId): (int, int) =
  case b.m.types[t].kind
  of ObjectDecl, UnionDecl:
    result = b.sizes[t]
  of ObjectTy, UnionTy:
    let impl = b.typeImpls[b.m.lit.strings[b.m.types[t].litId]]
    result = computeSize(b, impl)
  of IntTy, UIntTy, FloatTy, BoolTy, CharTy:
    let s = b.m.types[t].integralBits div 8
    result = (s, s)
  of APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy, ProcTy:
    result = (sizeof(pointer), sizeof(pointer))
  of ArrayTy:
    let e = elementType(b.m.types, t)
    let n = arrayLen(b.m.types, t)
    let inner = computeSize(b, e)
    result = (inner[0] * n.int, inner[1])
  else:
    result = (0, 0)

proc computeElemSize(b: var Bytecode; t: TypeId): int =
  case b.m.types[t].kind
  of ArrayTy, APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy, LastArrayTy:
    result = computeSize(b, elementType(b.m.types, t))[0]
  else:
    raiseAssert "not an array type"

proc traverseTypes(b: var Bytecode) =
  for t in allTypes(b.m.types, b.oldTypeLen):
    if b.m.types[t].kind in {ObjectDecl, UnionDecl}:
      assert b.m.types[t.firstSon].kind == NameVal
      b.typeImpls[b.m.lit.strings[b.m.types[t.firstSon].litId]] = t

  for t in allTypes(b.m.types, b.oldTypeLen):
    if b.m.types[t].kind in {ObjectDecl, UnionDecl}:
      assert b.m.types[t.firstSon].kind == NameVal
      traverseObject b, t, t
  b.oldTypeLen = b.m.types.len

const
  InvalidPatchPos* = PatchPos(-1)

proc isValid(p: PatchPos): bool {.inline.} = p.int != -1

proc prepare(bc: var Bytecode; info: PackedLineInfo; kind: OpcodeM): PatchPos =
  result = PatchPos bc.code.len
  bc.code.add toIns(kind, 1'u32)
  bc.debug.add info

proc add(bc: var Bytecode; info: PackedLineInfo; kind: OpcodeM; raw: uint32) =
  bc.code.add toIns(kind, raw)
  bc.debug.add info

proc add(bc: var Bytecode; info: PackedLineInfo; kind: OpcodeM; lit: LitId) =
  add bc, info, kind, uint32(lit)

proc isAtom(bc: Bytecode; pos: int): bool {.inline.} = bc.code[pos].kind <= LastAtomicValue
proc isAtom(bc: Bytecode; pos: CodePos): bool {.inline.} = bc.code[pos.int].kind <= LastAtomicValue

proc patch(bc: var Bytecode; pos: PatchPos) =
  let pos = pos.int
  let k = bc.code[pos].kind
  assert k > LastAtomicValue
  let distance = int32(bc.code.len - pos)
  assert distance > 0
  bc.code[pos] = toIns(k, cast[uint32](distance))

template build(bc: var Bytecode; info: PackedLineInfo; kind: OpcodeM; body: untyped) =
  let pos = prepare(bc, info, kind)
  body
  patch(bc, pos)

proc len*(bc: Bytecode): int {.inline.} = bc.code.len

template rawSpan(n: Instr): int = int(operand(n))

proc nextChild(bc: Bytecode; pos: var int) {.inline.} =
  if bc.code[pos].kind > LastAtomicValue:
    assert bc.code[pos].operand > 0'u32
    inc pos, bc.code[pos].rawSpan
  else:
    inc pos

proc next(bc: Bytecode; pos: var CodePos) {.inline.} = nextChild bc, int(pos)

iterator sons(bc: Bytecode; n: CodePos): CodePos =
  var pos = n.int
  assert bc.code[pos].kind > LastAtomicValue
  let last = pos + bc.code[pos].rawSpan
  inc pos
  while pos < last:
    yield CodePos pos
    nextChild bc, pos

iterator sonsFrom1(bc: Bytecode; n: CodePos): CodePos =
  var pos = n.int
  assert bc.code[pos].kind > LastAtomicValue
  let last = pos + bc.code[pos].rawSpan
  inc pos
  nextChild bc, pos
  while pos < last:
    yield CodePos pos
    nextChild bc, pos

iterator sonsFrom2(bc: Bytecode; n: CodePos): CodePos =
  var pos = n.int
  assert bc.code[pos].kind > LastAtomicValue
  let last = pos + bc.code[pos].rawSpan
  inc pos
  nextChild bc, pos
  nextChild bc, pos
  while pos < last:
    yield CodePos pos
    nextChild bc, pos

template firstSon(n: CodePos): CodePos = CodePos(n.int+1)

template `[]`(t: Bytecode; n: CodePos): Instr = t.code[n.int]

proc span(bc: Bytecode; pos: int): int {.inline.} =
  if bc.code[pos].kind <= LastAtomicValue: 1 else: int(bc.code[pos].operand)

iterator triples*(bc: Bytecode; n: CodePos): (uint32, int, CodePos) =
  var pos = n.int
  assert bc.code[pos].kind > LastAtomicValue
  let last = pos + bc.code[pos].rawSpan
  inc pos
  while pos < last:
    let offset = bc.code[pos].operand
    nextChild bc, pos
    let size = bc.code[pos].operand.int
    nextChild bc, pos
    let val = CodePos pos
    yield (offset, size, val)
    nextChild bc, pos

proc toString*(t: Bytecode; pos: CodePos;
               r: var string; nesting = 0) =
  if r.len > 0 and r[r.len-1] notin {' ', '\n', '(', '[', '{'}:
    r.add ' '

  case t[pos].kind
  of ImmediateValM:
    r.add $t[pos].operand
  of IntValM:
    r.add "IntVal "
    r.add $t.m.lit.numbers[LitId t[pos].operand]
  of StrValM:
    escapeToNimLit(t.m.lit.strings[LitId t[pos].operand], r)
  of LoadLocalM, LoadGlobalM, LoadProcM, AllocLocals, SummonParamM:
    r.add $t[pos].kind
    r.add ' '
    r.add $t[pos].operand
  of PragmaIdM:
    r.add $cast[PragmaKey](t[pos].operand)
  of TypedM:
    r.add "T<"
    r.add $t[pos].operand
    r.add ">"
  of NilValM:
    r.add "NilVal"
  of GotoM, CheckedGotoM:
    r.add $t[pos].kind
    r.add " L"
    r.add $t[pos].operand
  else:
    r.add $t[pos].kind
    r.add "{\n"
    for i in 0..<(nesting+1)*2: r.add ' '
    for p in sons(t, pos):
      toString t, p, r, nesting+1
    r.add "\n"
    for i in 0..<nesting*2: r.add ' '
    r.add "}"

proc debug(b: Bytecode; pos: CodePos) =
  var buf = ""
  toString(b, pos, buf)
  echo buf

type
  Preprocessing = object
    u: ref Universe
    known: Table[LabelId, CodePos]
    toPatch: Table[LabelId, seq[CodePos]]
    locals: Table[SymId, (uint32, int)] # address, size
    thisModule: uint32
    localsAddr: uint32
    markedWithLabel: IntSet

proc align(address, alignment: uint32): uint32 =
  result = (address + (alignment - 1'u32)) and not (alignment - 1'u32)

proc genGoto(c: var Preprocessing; bc: var Bytecode; info: PackedLineInfo; lab: LabelId; opc: OpcodeM) =
  let dest = c.known.getOrDefault(lab, CodePos(-1))
  if dest.int >= 0:
    bc.add info, opc, uint32 dest
  else:
    let here = CodePos(bc.code.len)
    c.toPatch.mgetOrPut(lab, @[]).add here
    bc.add info, opc, 1u32 # will be patched once we traversed the label

type
  AddrMode = enum
    InDotExpr, WantAddr

template maybeDeref(doDeref: bool; size: int; body: untyped) =
  var pos = PatchPos(-1)
  if doDeref:
    pos = prepare(bc, info, LoadM)
    bc.add info, ImmediateValM, uint32 size
  body
  if doDeref:
    patch(bc, pos)

proc toReadonlyString(s: string): NimStringVM =
  if s.len == 0:
    result = NimStringVM(len: 0, p: nil)
  else:
    result = NimStringVM(len: s.len, p: cast[ptr NimStrPayloadVM](alloc(s.len+1+sizeof(int))))
    copyMem(addr result.p.data[0], addr s[0], s.len+1)
    result.p.cap = s.len or (1 shl (8 * 8 - 2)) # see also NIM_STRLIT_FLAG

const
  ForwardedProc = 10_000_000'u32

proc preprocess(c: var Preprocessing; bc: var Bytecode; t: Tree; n: NodePos; flags: set[AddrMode]) =
  let info = t[n].info

  template recurse(opc) =
    build bc, info, opc:
      for ch in sons(t, n): preprocess(c, bc, t, ch, {WantAddr})

  case t[n].kind
  of Nop:
    discard "don't use Nop"
  of ImmediateVal:
    bc.add info, ImmediateValM, t[n].rawOperand
  of IntVal:
    bc.add info, IntValM, t[n].rawOperand
  of StrVal:
    let litId = LitId t[n].rawOperand
    if not bc.strings.hasKey(litId):
      bc.strings[litId] = toReadonlyString(bc.m.lit.strings[litId])
    bc.add info, StrValM, t[n].rawOperand
  of SymDef:
    discard "happens for proc decls. Don't copy the node as we don't need it"
  of SymUse:
    let s = t[n].symId
    if c.locals.hasKey(s):
      let (address, size) = c.locals[s]
      maybeDeref(WantAddr notin flags, size):
        bc.add info, LoadLocalM, address
    elif bc.procs.hasKey(s):
      bc.add info, LoadProcM, uint32 bc.procs[s]
    elif bc.globals.hasKey(s):
      let (address, size) = bc.globals[s]
      maybeDeref(WantAddr notin flags, size):
        bc.add info, LoadGlobalM, address
    else:
      let here = CodePos(bc.code.len)
      bc.add info, LoadProcM, ForwardedProc + uint32(s)
      bc.procUsagesToPatch.mgetOrPut(s, @[]).add here
      #raiseAssert "don't understand SymUse ID " & $int(s)

  of ModuleSymUse:
    when false:
      let (x, y) = sons2(t, n)
      let unit = c.u.unitNames.getOrDefault(bc.m.lit.strings[t[x].litId], -1)
      let s = t[y].symId
      if c.u.units[unit].procs.hasKey(s):
        bc.add info, LoadProcM, uint32 c.u.units[unit].procs[s]
      elif bc.globals.hasKey(s):
        maybeDeref(WantAddr notin flags):
          build bc, info, LoadGlobalM:
            bc.add info, ImmediateValM, uint32 unit
            bc.add info, LoadLocalM, uint32 s
      else:
        raiseAssert "don't understand ModuleSymUse ID"

    raiseAssert "don't understand ModuleSymUse ID"
  of Typed:
    bc.add info, TypedM, t[n].rawOperand
  of PragmaId:
    bc.add info, PragmaIdM, t[n].rawOperand
  of NilVal:
    bc.add info, NilValM, t[n].rawOperand
  of LoopLabel, Label:
    let lab = t[n].label
    let here = CodePos(bc.code.len)
    c.known[lab] = here
    var p: seq[CodePos] = @[]
    if c.toPatch.take(lab, p):
      for x in p: (bc.code[x]) = toIns(bc.code[x].kind, uint32 here)
    c.markedWithLabel.incl here.int # for toString()
  of Goto, GotoLoop:
    c.genGoto(bc, info, t[n].label, GotoM)
  of CheckedGoto:
    c.genGoto(bc, info, t[n].label, CheckedGotoM)
  of ArrayConstr:
    let typ = t[n.firstSon].typeId
    let s = computeElemSize(bc, typ)
    build bc, info, ArrayConstrM:
      bc.add info, ImmediateValM, uint32 s
      for ch in sonsFrom1(t, n):
        preprocess(c, bc, t, ch, {WantAddr})
  of ObjConstr:
    #debug bc, t, n
    var i = 0
    let typ = t[n.firstSon].typeId
    build bc, info, ObjConstrM:
      for ch in sons(t, n):
        if i > 0:
          if (i mod 2) == 1:
            let (offset, typ) = bc.offsets[typ][t[ch].immediateVal]
            let size = computeSize(bc, typ)[0]
            bc.add info, ImmediateValM, uint32(offset)
            bc.add info, ImmediateValM, uint32(size)
          else:
            preprocess(c, bc, t, ch, {WantAddr})
        inc i
  of Ret:
    recurse RetM
  of Yld:
    recurse YldM
  of Select:
    recurse SelectM
  of SelectPair:
    recurse SelectPairM
  of SelectList:
    recurse SelectListM
  of SelectValue:
    recurse SelectValueM
  of SelectRange:
    recurse SelectRangeM
  of SummonGlobal, SummonThreadLocal, SummonConst:
    let (typ, sym) = sons2(t, n)

    let s = t[sym].symId
    let tid = t[typ].typeId
    let (size, alignment) = computeSize(bc, tid)

    let global = align(bc.globalsAddr, uint32 alignment)
    bc.globals[s] = (global, size)
    bc.globalsAddr += uint32 size
    assert bc.globalsAddr < GlobalsSize

  of Summon:
    let (typ, sym) = sons2(t, n)

    let s = t[sym].symId
    let tid = t[typ].typeId
    let (size, alignment) = computeSize(bc, tid)

    let local = align(c.localsAddr, uint32 alignment)
    c.locals[s] = (local, size)
    c.localsAddr += uint32 size
    # allocation is combined into the frame allocation so there is no
    # instruction to emit
  of SummonParam, SummonResult:
    let (typ, sym) = sons2(t, n)

    let s = t[sym].symId
    let tid = t[typ].typeId
    let (size, alignment) = computeSize(bc, tid)

    let local = align(c.localsAddr, uint32 alignment)
    c.locals[s] = (local, size)
    c.localsAddr += uint32 size
    bc.add info, SummonParamM, local
    bc.add info, ImmediateValM, uint32 size
  of Kill:
    discard "we don't care about Kill instructions"
  of AddrOf:
    let (_, arg) = sons2(t, n)
    preprocess(c, bc, t, arg, {WantAddr})
    # the address of x is what the VM works with all the time so there is
    # nothing to compute.
  of ArrayAt:
    let (arrayType, a, i) = sons3(t, n)
    let tid = t[arrayType].typeId
    let size = uint32 computeElemSize(bc, tid)
    build bc, info, ArrayAtM:
      bc.add info, ImmediateValM, size
      preprocess(c, bc, t, a, {WantAddr})
      preprocess(c, bc, t, i, {WantAddr})
  of DerefArrayAt:
    let (arrayType, a, i) = sons3(t, n)
    let tid = t[arrayType].typeId
    let size = uint32 computeElemSize(bc, tid)
    build bc, info, DerefArrayAtM:
      bc.add info, ImmediateValM, size
      preprocess(c, bc, t, a, {WantAddr})
      preprocess(c, bc, t, i, {WantAddr})
  of FieldAt:
    let (typ, a, b) = sons3(t, n)
    let offset = bc.offsets[t[typ].typeId][t[b].immediateVal][0]
    build bc, info, FieldAtM:
      preprocess(c, bc, t, a, flags+{WantAddr})
      bc.add info, ImmediateValM, uint32(offset)
  of DerefFieldAt:
    let (typ, a, b) = sons3(t, n)
    let offset = bc.offsets[t[typ].typeId][t[b].immediateVal][0]
    build bc, info, DerefFieldAtM:
      preprocess(c, bc, t, a, flags+{WantAddr})
      bc.add info, ImmediateValM, uint32(offset)
  of Load:
    let (elemType, a) = sons2(t, n)
    let tid = t[elemType].typeId
    build bc, info, LoadM:
      bc.add info, ImmediateValM, uint32 computeSize(bc, tid)[0]
      preprocess(c, bc, t, a, {})

  of Store:
    raiseAssert "Assumption was that Store is unused!"
  of Asgn:
    let (elemType, dest, src) = sons3(t, n)
    let tid = t[elemType].typeId
    if t[src].kind in {Call, IndirectCall}:
      # No support for return values, these are mapped to `var T` parameters!
      build bc, info, CallM:
        preprocess(c, bc, t, src.skipTyped, {WantAddr})
        preprocess(c, bc, t, dest, {WantAddr})
        for ch in sonsFromN(t, src, 2): preprocess(c, bc, t, ch, {WantAddr})
    elif t[src].kind in {CheckedCall, CheckedIndirectCall}:
      let (_, gotoInstr, fn) = sons3(t, src)
      build bc, info, CallM:
        preprocess(c, bc, t, fn, {WantAddr})
        preprocess(c, bc, t, dest, {WantAddr})
        for ch in sonsFromN(t, src, 3): preprocess(c, bc, t, ch, {WantAddr})
      preprocess c, bc, t, gotoInstr, {}
    elif t[dest].kind == Load:
      let (typ, a) = sons2(t, dest)
      let s = computeSize(bc, tid)[0]
      build bc, info, StoreM:
        bc.add info, ImmediateValM, uint32 s
        preprocess(c, bc, t, a, {WantAddr})
        preprocess(c, bc, t, src, {})
    else:
      let s = computeSize(bc, tid)[0]
      build bc, info, AsgnM:
        bc.add info, ImmediateValM, uint32 s
        preprocess(c, bc, t, dest, {WantAddr})
        preprocess(c, bc, t, src, {})
  of SetExc:
    recurse SetExcM
  of TestExc:
    recurse TestExcM
  of CheckedRange:
    recurse CheckedRangeM
  of CheckedIndex:
    recurse CheckedIndexM
  of Call, IndirectCall:
    # avoid the Typed thing at position 0:
    build bc, info, CallM:
      for ch in sonsFrom1(t, n): preprocess(c, bc, t, ch, {WantAddr})
  of CheckedCall, CheckedIndirectCall:
    # avoid the Typed thing at position 0:
    let (_, gotoInstr, fn) = sons3(t, n)
    build bc, info, CallM:
      preprocess(c, bc, t, fn, {WantAddr})
      for ch in sonsFromN(t, n, 3): preprocess(c, bc, t, ch, {WantAddr})
    preprocess c, bc, t, gotoInstr, {WantAddr}
  of CheckedAdd:
    recurse CheckedAddM
  of CheckedSub:
    recurse CheckedSubM
  of CheckedMul:
    recurse CheckedMulM
  of CheckedDiv:
    recurse CheckedDivM
  of CheckedMod:
    recurse CheckedModM
  of Add:
    recurse AddM
  of Sub:
    recurse SubM
  of Mul:
    recurse MulM
  of Div:
    recurse DivM
  of Mod:
    recurse ModM
  of BitShl:
    recurse BitShlM
  of BitShr:
    recurse BitShrM
  of BitAnd:
    recurse BitAndM
  of BitOr:
    recurse BitOrM
  of BitXor:
    recurse BitXorM
  of BitNot:
    recurse BitNotM
  of BoolNot:
    recurse BoolNotM
  of Eq:
    recurse EqM
  of Le:
    recurse LeM
  of Lt:
    recurse LtM
  of Cast:
    recurse CastM
  of NumberConv:
    recurse NumberConvM
  of CheckedObjConv:
    recurse CheckedObjConvM
  of ObjConv:
    recurse ObjConvM
  of TestOf:
    recurse TestOfM
  of Emit:
    raiseAssert "cannot interpret: Emit"
  of ProcDecl:
    var c2 = Preprocessing(u: c.u, thisModule: c.thisModule)
    let sym = t[n.firstSon].symId
    let here = CodePos(bc.len)
    var p: seq[CodePos] = @[]
    if bc.procUsagesToPatch.take(sym, p):
      for x in p: (bc.code[x]) = toIns(bc.code[x].kind, uint32 here)
    bc.procs[sym] = here
    build bc, info, ProcDeclM:
      let toPatch = bc.code.len
      bc.add info, AllocLocals, 0'u32
      for ch in sons(t, n): preprocess(c2, bc, t, ch, {})
      bc.code[toPatch] = toIns(AllocLocals, c2.localsAddr)
    when false:
      if here.int == 39850:
        debug bc, t, n
        debug bc, here

  of PragmaPair:
    recurse PragmaPairM

const PayloadSize = 128

type
  StackFrame = ref object
    locals: pointer   # usually points into `payload` if size is small enough, otherwise it's `alloc`'ed.
    payload: array[PayloadSize, byte]
    caller: StackFrame
    returnAddr: CodePos
    jumpTo: CodePos # exception handling
    u: ref Universe

proc newStackFrame(size: int; caller: StackFrame; returnAddr: CodePos): StackFrame =
  result = StackFrame(caller: caller, returnAddr: returnAddr, u: caller.u)
  if size <= PayloadSize:
    result.locals = addr(result.payload)
  else:
    result.locals = alloc0(size)

proc popStackFrame(s: StackFrame): StackFrame =
  if s.locals != addr(s.payload):
    dealloc s.locals
  result = s.caller

template `+!`(p: pointer; diff: uint): pointer = cast[pointer](cast[uint](p) + diff)

proc isAtom(tree: seq[Instr]; pos: CodePos): bool {.inline.} = tree[pos.int].kind <= LastAtomicValue

proc span(bc: seq[Instr]; pos: int): int {.inline.} =
  if bc[pos].kind <= LastAtomicValue: 1 else: int(bc[pos].operand)

proc sons2(tree: seq[Instr]; n: CodePos): (CodePos, CodePos) =
  assert(not isAtom(tree, n))
  let a = n.int+1
  let b = a + span(tree, a)
  result = (CodePos a, CodePos b)

proc sons3(tree: seq[Instr]; n: CodePos): (CodePos, CodePos, CodePos) =
  assert(not isAtom(tree, n))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  result = (CodePos a, CodePos b, CodePos c)

proc sons4(tree: seq[Instr]; n: CodePos): (CodePos, CodePos, CodePos, CodePos) =
  assert(not isAtom(tree, n))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  let d = c + span(tree, c)
  result = (CodePos a, CodePos b, CodePos c, CodePos d)

proc typeId*(ins: Instr): TypeId {.inline.} =
  assert ins.kind == TypedM
  result = TypeId(ins.operand)

proc immediateVal*(ins: Instr): int {.inline.} =
  assert ins.kind == ImmediateValM
  result = cast[int](ins.operand)

proc litId*(ins: Instr): LitId {.inline.} =
  assert ins.kind in {StrValM, IntValM}
  result = LitId(ins.operand)

proc eval(c: Bytecode; pc: CodePos; s: StackFrame; result: pointer; size: int)

proc evalAddr(c: Bytecode; pc: CodePos; s: StackFrame): pointer =
  case c.code[pc].kind
  of LoadLocalM:
    result = s.locals +! c.code[pc].operand
  of FieldAtM:
    let (x, offset) = sons2(c.code, pc)
    result = evalAddr(c, x, s)
    result = result +! c.code[offset].operand
  of DerefFieldAtM:
    let (x, offset) = sons2(c.code, pc)
    let p = evalAddr(c, x, s)
    result = cast[ptr pointer](p)[] +! c.code[offset].operand
  of ArrayAtM:
    let (e, a, i) = sons3(c.code, pc)
    let elemSize = c.code[e].operand
    result = evalAddr(c, a, s)
    var idx: int = 0
    eval(c, i, s, addr idx, sizeof(int))
    result = result +! (uint32(idx) * elemSize)
  of DerefArrayAtM:
    let (e, a, i) = sons3(c.code, pc)
    let elemSize = c.code[e].operand
    var p = evalAddr(c, a, s)
    var idx: int = 0
    eval(c, i, s, addr idx, sizeof(int))
    result = cast[ptr pointer](p)[] +! (uint32(idx) * elemSize)
  of LoadGlobalM:
    result = c.globalData +! c.code[pc].operand
  else:
    raiseAssert("unimplemented addressing mode")

proc `div`(x, y: float32): float32 {.inline.} = x / y
proc `div`(x, y: float64): float64 {.inline.} = x / y

from std / math import `mod`

template binop(opr) {.dirty.} =
  template impl(typ) {.dirty.} =
    var x = default(typ)
    var y = default(typ)
    eval c, a, s, addr x, sizeof(typ)
    eval c, b, s, addr y, sizeof(typ)
    cast[ptr typ](result)[] = opr(x, y)

  let (t, a, b) = sons3(c.code, pc)
  let tid = TypeId c.code[t].operand
  case tid
  of Bool8Id, Char8Id, UInt8Id: impl uint8
  of Int8Id: impl int8
  of Int16Id: impl int16
  of Int32Id: impl int32
  of Int64Id: impl int64
  of UInt16Id: impl uint16
  of UInt32Id: impl uint32
  of UInt64Id: impl uint64
  of Float32Id: impl float32
  of Float64Id: impl float64
  else: discard

template checkedBinop(opr) {.dirty.} =
  template impl(typ) {.dirty.} =
    var x = default(typ)
    var y = default(typ)
    eval c, a, s, addr x, sizeof(typ)
    eval c, b, s, addr y, sizeof(typ)
    try:
      cast[ptr typ](result)[] = opr(x, y)
    except OverflowDefect, DivByZeroDefect:
      s.jumpTo = CodePos c.code[j].operand

  let (t, j, a, b) = sons4(c.code, pc)
  let tid = TypeId c.code[t].operand
  case tid
  of Bool8Id, Char8Id, UInt8Id: impl uint8
  of Int8Id: impl int8
  of Int16Id: impl int16
  of Int32Id: impl int32
  of Int64Id: impl int64
  of UInt16Id: impl uint16
  of UInt32Id: impl uint32
  of UInt64Id: impl uint64
  of Float32Id: impl float32
  of Float64Id: impl float64
  else: discard

template bitop(opr) {.dirty.} =
  template impl(typ) {.dirty.} =
    var x = default(typ)
    var y = default(typ)
    eval c, a, s, addr x, sizeof(typ)
    eval c, b, s, addr y, sizeof(typ)
    cast[ptr typ](result)[] = opr(x, y)

  let (t, a, b) = sons3(c.code, pc)
  let tid = c.code[t].typeId
  case tid
  of Bool8Id, Char8Id, UInt8Id: impl uint8
  of Int8Id: impl int8
  of Int16Id: impl int16
  of Int32Id: impl int32
  of Int64Id: impl int64
  of UInt16Id: impl uint16
  of UInt32Id: impl uint32
  of UInt64Id: impl uint64
  else: discard

template cmpop(opr) {.dirty.} =
  template impl(typ) {.dirty.} =
    var x = default(typ)
    var y = default(typ)
    eval c, a, s, addr x, sizeof(typ)
    eval c, b, s, addr y, sizeof(typ)
    cast[ptr bool](result)[] = opr(x, y)

  let (t, a, b) = sons3(c.code, pc)
  let tid = c.code[t].typeId
  case tid
  of Bool8Id, Char8Id, UInt8Id: impl uint8
  of Int8Id: impl int8
  of Int16Id: impl int16
  of Int32Id: impl int32
  of Int64Id: impl int64
  of UInt16Id: impl uint16
  of UInt32Id: impl uint32
  of UInt64Id: impl uint64
  of Float32Id: impl float32
  of Float64Id: impl float64
  else: discard

proc evalSelect(c: Bytecode; pc: CodePos; s: StackFrame): CodePos =
  template impl(typ) {.dirty.} =
    var selector = default(typ)
    eval c, sel, s, addr selector, sizeof(typ)
    for pair in sonsFrom2(c, pc):
      assert c.code[pair].kind == SelectPairM
      let (values, action) = sons2(c.code, pair)
      if c.code[values].kind == SelectValueM:
        var a = default(typ)
        eval c, values.firstSon, s, addr a, sizeof(typ)
        if selector == a:
          return CodePos c.code[action].operand
      else:
        assert c.code[values].kind == SelectListM, $c.code[values].kind
        for v in sons(c, values):
          case c.code[v].kind
          of SelectValueM:
            var a = default(typ)
            eval c, v.firstSon, s, addr a, sizeof(typ)
            if selector == a:
              return CodePos c.code[action].operand
          of SelectRangeM:
            let (va, vb) = sons2(c.code, v)
            var a = default(typ)
            eval c, va, s, addr a, sizeof(typ)
            var b = default(typ)
            eval c, vb, s, addr a, sizeof(typ)
            if a <= selector and selector <= b:
              return CodePos c.code[action].operand
          else: raiseAssert "unreachable"
    result = CodePos(-1)

  let (t, sel) = sons2(c.code, pc)
  let tid = c.code[t].typeId
  case tid
  of Bool8Id, Char8Id, UInt8Id: impl uint8
  of Int8Id: impl int8
  of Int16Id: impl int16
  of Int32Id: impl int32
  of Int64Id: impl int64
  of UInt16Id: impl uint16
  of UInt32Id: impl uint32
  of UInt64Id: impl uint64
  else: raiseAssert "unreachable"

proc eval(c: Bytecode; pc: CodePos; s: StackFrame; result: pointer; size: int) =
  case c.code[pc].kind
  of LoadLocalM:
    let src = s.locals +! c.code[pc].operand
    copyMem result, src, size
  of FieldAtM, DerefFieldAtM, ArrayAtM, DerefArrayAtM, LoadGlobalM:
    let src = evalAddr(c, pc, s)
    copyMem result, src, size
  of LoadProcM:
    let procAddr = c.code[pc].operand
    cast[ptr pointer](result)[] = cast[pointer](procAddr)
  of LoadM:
    let (_, arg) = sons2(c.code, pc)
    let src = evalAddr(c, arg, s)
    copyMem result, src, size
  of CheckedAddM: checkedBinop `+`
  of CheckedSubM: checkedBinop `-`
  of CheckedMulM: checkedBinop `*`
  of CheckedDivM: checkedBinop `div`
  of CheckedModM: checkedBinop `mod`
  of AddM: binop `+`
  of SubM: binop `-`
  of MulM: binop `*`
  of DivM: binop `div`
  of ModM: binop `mod`
  of BitShlM: bitop `shl`
  of BitShrM: bitop `shr`
  of BitAndM: bitop `and`
  of BitOrM: bitop `or`
  of BitXorM: bitop `xor`
  of EqM: cmpop `==`
  of LeM: cmpop `<=`
  of LtM: cmpop `<`

  of StrValM:
    # binary compatible and no deep copy required:
    copyMem(cast[ptr string](result), addr(c.strings[c[pc].litId]), sizeof(string))
  of ObjConstrM:
    for offset, size, val in triples(c, pc):
      eval c, val, s, result+!offset, size
  of ArrayConstrM:
    let elemSize = c.code[pc.firstSon].operand
    var r = result
    for ch in sonsFrom1(c, pc):
      eval c, ch, s, r, elemSize.int
      r = r+!elemSize # can even do strength reduction here!
  of NumberConvM:
    let (t, x) = sons2(c.code, pc)
    let word = if c[x].kind == NilValM: 0'i64 else: c.m.lit.numbers[c[x].litId]

    template impl(typ: typedesc) {.dirty.} =
      cast[ptr typ](result)[] = cast[typ](word)

    let tid = c.code[t].typeId
    case tid
    of Bool8Id, Char8Id, UInt8Id: impl uint8
    of Int8Id: impl int8
    of Int16Id: impl int16
    of Int32Id: impl int32
    of Int64Id: impl int64
    of UInt16Id: impl uint16
    of UInt32Id: impl uint32
    of UInt64Id: impl uint64
    of Float32Id: impl float32
    of Float64Id: impl float64
    else:
      case c.m.types[tid].kind
      of ProcTy, UPtrTy, APtrTy, AArrayPtrTy, UArrayPtrTy:
        # the VM always uses 64 bit pointers:
        impl uint64
      else:
        raiseAssert "cannot happen: " & $c.m.types[tid].kind
  else:
    #debug c, c.debug[pc.int]
    raiseAssert "cannot happen: " & $c.code[pc].kind

proc evalProc(c: Bytecode; pc: CodePos; s: StackFrame): CodePos =
  assert c.code[pc].kind == LoadProcM
  let procSym = c[pc].operand
  when false:
    if procSym >= ForwardedProc:
      for k, v in c.procUsagesToPatch:
        if uint32(k) == procSym - ForwardedProc:
          echo k.int, " ", v.len, " <-- this one"
        else:
          echo k.int, " ", v.len

  assert procSym < ForwardedProc
  result = CodePos(procSym)

proc echoImpl(c: Bytecode; pc: CodePos; frame: StackFrame) =
  var s = default(NimStringVM)
  for a in sonsFrom1(c, pc):
    assert c[a].kind == ArrayConstrM
    let elemSize = c.code[a.firstSon].operand.int
    for ch in sonsFrom1(c, a):
      eval c, ch, frame, addr s, elemSize
      if s.len > 0:
        discard stdout.writeBuffer(addr(s.p.data[0]), s.len)
  stdout.write "\n"
  stdout.flushFile()

type
  EvalBuiltinState = enum
    DidNothing, DidEval, DidError

proc evalBuiltin(c: Bytecode; pc: CodePos; s: StackFrame; prc: CodePos; state: var EvalBuiltinState): CodePos =
  var prc = prc
  while true:
    case c[prc].kind
    of PragmaPairM:
      let (x, y) = sons2(c.code, prc)
      let key = cast[PragmaKey](c[x].operand)
      case key
      of CoreName:
        let lit = c[y].litId
        case c.m.lit.strings[lit]
        of "echoBinSafe": echoImpl(c, pc, s)
        else:
          raiseAssert "cannot eval: " & c.m.lit.strings[lit]
        state = DidEval
      of HeaderImport, DllImport:
        let lit = c[y].litId
        raiseAssert "cannot eval: " & c.m.lit.strings[lit]
      else: discard
    of PragmaIdM, AllocLocals: discard
    else: break
    next c, prc
  result = prc

proc exec(c: Bytecode; pc: CodePos; u: ref Universe) =
  var pc = pc
  var frame = StackFrame(u: u)
  while pc.int < c.code.len:
    when false: # c.interactive:
      echo "running: ", pc.int
      debug c, pc

    case c.code[pc].kind
    of GotoM:
      pc = CodePos(c.code[pc].operand)
    of AsgnM:
      let (sz, a, b) = sons3(c.code, pc)
      let dest = evalAddr(c, a, frame)
      eval(c, b, frame, dest, c.code[sz].operand.int)
      next c, pc
    of StoreM:
      let (sz, a, b) = sons3(c.code, pc)
      let destPtr = evalAddr(c, a, frame)
      let dest = cast[ptr pointer](destPtr)[]
      eval(c, b, frame, dest, c.code[sz].operand.int)
      next c, pc
    of CallM:
      # No support for return values, these are mapped to `var T` parameters!
      var prc = evalProc(c, pc.firstSon, frame)
      assert c.code[prc.firstSon].kind == AllocLocals
      let frameSize = int c.code[prc.firstSon].operand
      # skip stupid stuff:
      var evalState = DidNothing
      prc = evalBuiltin(c, pc, frame, prc.firstSon, evalState)
      if evalState != DidNothing:
        next c, pc
        if pc.int < c.code.len and c.code[pc].kind == CheckedGotoM:
          if evalState == DidEval:
            next c, pc
          else:
            pc = CodePos(c.code[pc].operand)
      else:
        # setup storage for the proc already:
        let callInstr = pc
        next c, pc
        let s2 = newStackFrame(frameSize, frame, pc)
        for a in sonsFrom1(c, callInstr):
          assert c[prc].kind == SummonParamM
          let paramAddr = c[prc].operand
          next c, prc
          assert c[prc].kind == ImmediateValM
          let paramSize = c[prc].operand.int
          next c, prc
          eval(c, a, s2, s2.locals +! paramAddr, paramSize)
        frame = s2
        pc = prc
    of RetM:
      pc = frame.returnAddr
      if c.code[pc].kind == CheckedGotoM:
        pc = frame.jumpTo
      frame = popStackFrame(frame)
    of SelectM:
      let pc2 = evalSelect(c, pc, frame)
      if pc2.int >= 0:
        pc = pc2
      else:
        next c, pc
    of ProcDeclM:
      next c, pc
    else:
      #debug c, c.debug[pc.int]
      raiseAssert "unreachable: " & $c.code[pc].kind

proc execCode*(bc: var Bytecode; t: Tree; n: NodePos) =
  traverseTypes bc
  var c = Preprocessing(u: nil, thisModule: 1'u32)
  let start = CodePos(bc.code.len)
  var pc = n
  while pc.int < t.len:
    #if bc.interactive:
    #  echo "RUnning: "
    #  debug bc, t, pc
    preprocess c, bc, t, pc, {}
    next t, pc
  exec bc, start, nil
