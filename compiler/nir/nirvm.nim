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

import std / [assertions, tables, intsets]
import ".." / ic / bitabs
import nirinsts, nirtypes, nirfiles, nirlineinfos

type
  OpcodeM = enum
    ImmediateValM,
    IntValM,
    StrValM,
    LoadLocalM, # with local ID
    TypedM,   # with type ID
    PragmaIdM, # with Pragma ID, possible values: see PragmaKey enum
    NilValM,
    GotoM,
    CheckedGotoM, # last atom

    LoadProcM,
    LoadGlobalM, # `"module".x`

    ArrayConstrM,
    ObjConstrM,
    RetM,
    YldM,

    SelectM,
    SelectPairM,  # ((values...), Label)
    SelectListM,  # (values...)
    SelectValueM, # (value)
    SelectRangeM, # (valueA..valueB)
    AllocLocals,
    SummonGlobalM,
    SummonThreadLocalM,
    SummonParamM,

    AddrOfM,
    ArrayAtM, # (elemSize, addr(a), i)
    FieldAtM, # addr(obj.field)

    LoadM, # a[]
    AsgnM,  # a = b
    StoreM, # a[] = b
    SetExcM,
    TestExcM,

    CheckedRangeM,
    CheckedIndexM,

    CallM,
    CheckedCallM, # call that can raise
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
  PatchPos = distinct int
  CodePos = distinct int

  Bytecode = object
    code: seq[Instr]
    debug: seq[PackedLineInfo]
    m: NirModule
    procs: Table[SymId, CodePos]
    globals: Table[SymId, uint32]
    globalsAddr: uint32
    typeImpls: Table[string, TypeId]
    offsets: Table[TypeId, seq[int]]
    sizes: Table[TypeId, (int, int)] # (size, alignment)

  Universe* = object ## all units: For interpretation we need that
    units: seq[Bytecode]
    unitNames: Table[string, int]
    current: int

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
          offset = b.m.lit.numbers[b.m.types[y].litId]
          break
      b.offsets.mgetOrPut(offsetKey, @[]).add offset
    of SizeVal:
      size = b.m.lit.numbers[b.m.types[x].litId]
    of AlignVal:
      align = b.m.lit.numbers[b.m.types[x].litId]
    of ObjectTy:
      # inheritance
      assert b.m.types[x.firstSon].kind == NameVal
      let impl = b.typeImpls.getOrDefault(b.m.lit.strings[b.m.types[x.firstSon].litId])
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
    assert b.m.types[t.firstSon].kind == NameVal
    let impl = b.typeImpls[b.m.lit.strings[b.m.types[t.firstSon].litId]]
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

proc traverseTypes(b: var Bytecode) =
  for t in allTypes(b.m.types):
    if b.m.types[t].kind in {ObjectDecl, UnionDecl}:
      assert b.m.types[t.firstSon].kind == NameVal
      b.typeImpls[b.m.lit.strings[b.m.types[t.firstSon].litId]] = t

  for t in allTypes(b.m.types):
    if b.m.types[t].kind in {ObjectDecl, UnionDecl}:
      assert b.m.types[t.firstSon].kind == NameVal
      traverseObject b, t, t

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

type
  Preprocessing = object
    u: ref Universe
    known: Table[LabelId, CodePos]
    toPatch: Table[LabelId, seq[CodePos]]
    locals: Table[SymId, uint32]
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

template maybeDeref(doDeref: bool; body: untyped) =
  var pos = PatchPos(-1)
  if doDeref:
    bc.add info, TypedM, 0'u32
    pos = prepare(bc, info, LoadM)
  body
  if doDeref:
    patch(bc, pos)

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
    bc.add info, StrValM, t[n].rawOperand
  of SymDef:
    assert false, "SymDef outside of declaration context"
  of SymUse:
    let s = t[n].symId
    if c.locals.hasKey(s):
      maybeDeref(WantAddr notin flags):
        bc.add info, LoadLocalM, c.locals[s]
    elif bc.procs.hasKey(s):
      build bc, info, LoadProcM:
        bc.add info, ImmediateValM, c.thisModule
        bc.add info, LoadLocalM, uint32 bc.procs[s]
    elif bc.globals.hasKey(s):
      maybeDeref(WantAddr notin flags):
        build bc, info, LoadGlobalM:
          bc.add info, ImmediateValM, c.thisModule
          bc.add info, LoadLocalM, uint32 s
    else:
      assert false, "don't understand SymUse ID"

  of ModuleSymUse:
    let (x, y) = sons2(t, n)
    let unit = c.u.unitNames.getOrDefault(bc.m.lit.strings[t[x].litId], -1)
    let s = t[y].symId
    if c.u.units[unit].procs.hasKey(s):
      build bc, info, LoadProcM:
        bc.add info, ImmediateValM, uint32 unit
        bc.add info, LoadLocalM, uint32 c.u.units[unit].procs[s]
    elif bc.globals.hasKey(s):
      maybeDeref(WantAddr notin flags):
        build bc, info, LoadGlobalM:
          bc.add info, ImmediateValM, uint32 unit
          bc.add info, LoadLocalM, uint32 s
    else:
      assert false, "don't understand ModuleSymUse ID"

  of Typed:
    bc.add info, TypedM, t[n].rawOperand
  of PragmaId:
    bc.add info, PragmaIdM, t[n].rawOperand
  of NilVal:
    bc.add info, NilValM, t[n].rawOperand
  of LoopLabel, Label:
    let lab = t[n].label
    let here = CodePos(bc.code.len-1)
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
    build bc, info, ArrayConstrM:
      bc.add info, ImmediateValM, uint32 computeSize(bc, typ)[0]
      for ch in sons(t, n):
        preprocess(c, bc, t, ch, {WantAddr})
  of ObjConstr:
    var i = 0
    let typ = t[n.firstSon].typeId
    build bc, info, ObjConstrM:
      for ch in sons(t, n):
        if i > 0:
          if (i mod 2) == 1:
            let offset = bc.offsets[typ][t[ch].immediateVal]
            bc.add info, ImmediateValM, uint32(offset)
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
    bc.globals[s] = global
    bc.globalsAddr += uint32 size

  of Summon:
    let (typ, sym) = sons2(t, n)

    let s = t[sym].symId
    let tid = t[typ].typeId
    let (size, alignment) = computeSize(bc, tid)

    let local = align(c.localsAddr, uint32 alignment)
    c.locals[s] = local
    c.localsAddr += uint32 size
    # allocation is combined into the frame allocation so there is no
    # instruction to emit
  of SummonParam:
    let (typ, sym) = sons2(t, n)

    let s = t[sym].symId
    let tid = t[typ].typeId
    let (size, alignment) = computeSize(bc, tid)

    let local = align(c.localsAddr, uint32 alignment)
    c.locals[s] = local
    c.localsAddr += uint32 size
    bc.add info, SummonParamM, local
  of Kill:
    discard "we don't care about Kill instructions"
  of AddrOf:
    let (_, arg) = sons2(t, n)
    preprocess(c, bc, t, arg, {WantAddr})
    # the address of x is what the VM works with all the time so there is
    # nothing to compute.
  of ArrayAt:
    let (elemType, a, i) = sons3(t, n)
    let tid = t[elemType].typeId
    let size = uint32 computeSize(bc, tid)[0]
    if t[a].kind == Load:
      let (_, arg) = sons2(t, a)
      build bc, info, LoadM:
        bc.add info, ImmediateValM, size
        build bc, info, ArrayAtM:
          bc.add info, ImmediateValM, size
          preprocess(c, bc, t, arg, {WantAddr})
          preprocess(c, bc, t, i, {WantAddr})
    else:
      build bc, info, ArrayAtM:
        bc.add info, ImmediateValM, size
        preprocess(c, bc, t, a, {WantAddr})
        preprocess(c, bc, t, i, {WantAddr})
  of FieldAt:
    # a[] conceptually loads a block of size of T. But when applied to an object selector
    # only a subset of the data is really requested so `(a[] : T).field`
    # becomes `(a+offset(field))[] : T_Field`
    # And now if this is paired with `addr` the deref disappears, as usual: `addr x.field[]`
    # is `(x+offset(field))`.
    let (typ, a, b) = sons3(t, n)
    if t[a].kind == Load:
      let (_, arg) = sons2(t, a)
      build bc, info, LoadM:
        bc.add info, ImmediateValM, uint32 computeSize(bc, t[typ].typeId)[0]
        let offset = bc.offsets[t[typ].typeId][t[b].immediateVal]
        build bc, info, FieldAtM:
          preprocess(c, bc, t, arg, flags+{WantAddr})
          bc.add info, ImmediateValM, uint32(offset)
    else:
      let offset = bc.offsets[t[typ].typeId][t[b].immediateVal]
      build bc, info, FieldAtM:
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
    if t[src].kind in {Call, IndirectCall}:
      # No support for return values, these are mapped to `var T` parameters!
      build bc, info, CallM:
        preprocess(c, bc, t, dest, {WantAddr})
        for ch in sons(t, src): preprocess(c, bc, t, ch, {WantAddr})
    elif t[src].kind in {CheckedCall, CheckedIndirectCall}:
      build bc, info, CheckedCallM:
        preprocess(c, bc, t, src.firstSon, {WantAddr})
        preprocess(c, bc, t, dest, {WantAddr})
        for ch in sonsFrom1(t, src): preprocess(c, bc, t, ch, {WantAddr})
    elif t[dest].kind == Load:
      let (typ, a) = sons2(t, dest)
      build bc, info, StoreM:
        #bc.add info, Typed, uint32 tid
        preprocess(c, bc, t, a, {WantAddr})
        preprocess(c, bc, t, src, {})
    else:
      build bc, info, AsgnM:
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
    recurse CallM
  of CheckedCall, CheckedIndirectCall:
    recurse CheckedCallM
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
    assert false, "cannot interpret: Emit"
  of ProcDecl:
    var c2 = Preprocessing(u: c.u, thisModule: c.thisModule)
    let sym = t[n.firstSon].symId
    bc.procs[sym] = CodePos(bc.len)
    build bc, info, ProcDeclM:
      let toPatch = bc.code.len
      bc.add info, AllocLocals, 0'u32
      for ch in sons(t, n): preprocess(c2, bc, t, ch, {})
      bc.code[toPatch] = toIns(AllocLocals, c2.localsAddr)
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

proc eval(c: Bytecode; pc: CodePos; s: StackFrame; result: pointer)

proc evalAddr(c: Bytecode; pc: CodePos; s: StackFrame): pointer =
  case c.code[pc].kind
  of LoadLocalM:
    result = s.locals +! c.code[pc].operand
  of FieldAtM:
    let (x, offset) = sons2(c.code, pc)
    result = evalAddr(c, x, s)
    result = result +! c.code[offset].operand
  of ArrayAtM:
    let (e, a, i) = sons3(c.code, pc)
    let elemSize = c.code[e].operand
    result = evalAddr(c, a, s)
    var idx: int = 0
    eval(c, i, s, addr idx)
    result = result +! (uint32(idx) * elemSize)
  of LoadM:
    let (_, arg) = sons2(c.code, pc)
    let p = evalAddr(c, arg, s)
    result = cast[ptr pointer](p)[]
  else:
    raiseAssert("unimplemented addressing mode")

proc `div`(x, y: float32): float32 {.inline.} = x / y
proc `div`(x, y: float64): float64 {.inline.} = x / y

from math import `mod`

template binop(opr) {.dirty.} =
  template impl(typ) {.dirty.} =
    var x = default(typ)
    var y = default(typ)
    eval c, a, s, addr x
    eval c, b, s, addr y
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
    eval c, a, s, addr x
    eval c, b, s, addr y
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
    eval c, a, s, addr x
    eval c, b, s, addr y
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
    eval c, a, s, addr x
    eval c, b, s, addr y
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
    eval c, sel, s, addr selector
    for pair in sonsFrom2(c, pc):
      assert c.code[pair].kind == SelectPairM
      let (values, action) = sons2(c.code, pair)
      assert c.code[values].kind == SelectListM
      for v in sons(c, values):
        case c.code[v].kind
        of SelectValueM:
          var a = default(typ)
          eval c, v.firstSon, s, addr a
          if selector == a:
            return CodePos c.code[action].operand
        of SelectRangeM:
          let (va, vb) = sons2(c.code, v)
          var a = default(typ)
          eval c, va, s, addr a
          var b = default(typ)
          eval c, vb, s, addr a
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

proc eval(c: Bytecode; pc: CodePos; s: StackFrame; result: pointer) =
  case c.code[pc].kind
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
    copyMem(cast[ptr string](result), addr(c.m.lit.strings[c[pc].litId]), sizeof(string))
    # XXX not correct!
  of ObjConstrM:
    var i = 0
    var offset = 0'u32
    for ch in sons(c, pc):
      if (i mod 2) == 1: offset = c.code[ch].operand
      else: eval c, ch, s, result+!offset
      inc i
  of ArrayConstrM:
    let elemSize = c.code[pc.firstSon].operand
    var r = result
    for ch in sonsFrom1(c, pc):
      eval c, ch, s, r
      r = r+!elemSize # can even do strength reduction here!
  of NumberConvM:
    let (t, x) = sons2(c.code, pc)
    let word = c.m.lit.numbers[c[x].litId]

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
    else: raiseAssert "cannot happen"
  else:
    raiseAssert "cannot happen"

proc exec(c: Bytecode; pc: CodePos; u: ref Universe) =
  var pc = pc
  var s = StackFrame(u: u)
  while pc.int < c.code.len:
    case c.code[pc].kind
    of GotoM:
      pc = CodePos(c.code[pc].operand)
    of AsgnM:
      let (a, b) = sons2(c.code, pc)
      let dest = evalAddr(c, a, s)
      eval(c, b, s, dest)
      nextChild c, int(pc)
    of StoreM:
      let (a, b) = sons2(c.code, pc)
      let destPtr = evalAddr(c, a, s)
      let dest = cast[ptr pointer](destPtr)[]
      eval(c, b, s, dest)
      nextChild c, int(pc)
    of CallM:
      when false:
        # No support for return values, these are mapped to `var T` parameters!
        let prc = evalProc(c, pc.firstSon, s)
        # setup storage for the proc already:
        let s2 = newStackFrame(prc.frameSize, s, pc)
        var i = 0
        for a in sonsFrom1(c, pc):
          eval(c, a, s2, paramAddr(s2, i))
          inc i
        s = s2
        pc = pcOf(prc)
    of RetM:
      pc = s.returnAddr
      s = popStackFrame(s)
    of SelectM:
      let pc2 = evalSelect(c, pc, s)
      if pc2.int >= 0:
        pc = pc2
      else:
        nextChild c, int(pc)
    else:
      raiseAssert "unreachable"
