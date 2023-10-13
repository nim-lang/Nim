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

import std / [tables, intsets]
import ".." / ic / bitabs
import nirinsts, nirtypes

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
    SummonGlobalM,
    SummonThreadLocalM,
    SummonM, # x = Summon Typed <Type ID>; x begins to live
    SummonParamM,

    AddrOfM,
    ArrayAtM, # addr(a[i])
    FieldAtM, # addr(obj.field)

    LoadM, # a[]
    StoreM, # a[] = b
    AsgnM,  # a = b
    SetExcM,
    TestExcM,

    CheckedRangeM,
    CheckedIndexM,

    CallM,
    IndirectCallM,
    CheckedCallM, # call that can raise
    CheckedIndirectCallM, # call that can raise
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

template kind(n: Instr): OpcodeM = OpcodeM(n and OpcodeMask)
template operand(n: Instr): uint32 = (n shr OpcodeBits)

template toIns(k: OpcodeM; operand: uint32): Instr =
  Instr(uint32(k) or (operand shl OpcodeBits))

template toIns(k: OpcodeM; operand: LitId): Instr =
  Instr(uint32(k) or (operand.uint32 shl OpcodeBits))

type
  PatchPos = distinct int
  CodePos = distinct int

  Unit = ref object ## a NIR module
    procs: Table[SymId, CodePos]
    globals: Table[SymId, uint32]
    integers: BiTable[int64]
    strings: BiTable[string]
    globalsGen: uint32

  Universe* = object ## all units: For interpretation we need that
    units: Table[string, Unit]

  Bytecode = object
    code: seq[Instr]
    debug: seq[PackedLineInfo]
    u: Unit

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
  add bc, info, kind, uint(lit)

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

template `[]`*(t: Bytecode; n: CodePos): Instr = t.code[n.int]

proc span(bc: Bytecode; pos: int): int {.inline.} =
  if bc.code[pos].kind <= LastAtomicValue: 1 else: int(bc.code[pos].operand)

type
  Preprocessing = object
    known: Table[LabelId, CodePos]
    toPatch: Table[LabelId, seq[CodePos]]
    locals: Table[SymId, uint32]
    c: Bytecode # to be moved out
    thisModule: LitId
    markedWithLabel: IntSet

proc genGoto(c: var Preprocessing; lab: LabelId; opc: OpcodeM) =
  let dest = c.known.getOrDefault(lab, CodePos(-1))
  if dest.int >= 0:
    c.bc.add info, opc, uint32 dest
  else:
    let here = CodePos(c.bc.code.len)
    c.toPatch.mgetOrPut(lab, @[]).add here
    c.bc.add info, opc, 1u32 # will be patched once we traversed the label

proc preprocess(c: var Preprocessing; u: var Universe; t: Tree; n: NodePos) =
  let info = t[n].info

  template recurse(opc) =
    build c.bc, info, opc:
      for c in sons(t, n): preprocess(c, u, t, c)

  case t[n].kind
  of Nop:
    discard "don't use Nop"
  of ImmediateVal:
    c.bc.add info, ImmediateValM, t[n].rawOperand
  of IntVal:
    c.bc.add info, IntValM, t[n].rawOperand
  of StrVal:
    c.bc.add info, StrValM, t[n].rawOperand
  of SymDef:
    assert false, "SymDef outside of declaration context"
  of SymUse:
    let s = t[n].symId
    if c.locals.hasKey(s):
      c.bc.add info, LoadLocalM, c.locals[s]
    elif c.bc.u.procs.hasKey(s):
      build c.bc, info, LoadProcM:
        c.bc.add info, StrValM, thisModule
        c.bc.add info, LoadLocalM, uint32 c.bc.u.procs[s]
    elif c.bc.u.globals.hasKey(s):
      build c.bc, info, LoadGlobalM:
        c.bc.add info, StrValM, thisModule
        c.bc.add info, LoadLocalM, uint32 s
    else:
      assert false, "don't understand SymUse ID"

  of ModuleSymUse:
    let moduleName {.cursor.} = c.bc.u.strings[t[n.firstSon].litId]
    let unit = u.units.getOrDefault(moduleName)

  of Typed:
    c.bc.add info, TypedM, t[n].rawOperand
  of PragmaId:
    c.bc.add info, TypedM, t[n].rawOperand
  of NilVal:
    c.bc.add info, NilValM, t[n].rawOperand
  of LoopLabel, Label:
    let lab = t[n].label
    let here = CodePos(c.bc.code.len-1)
    c.known[lab] = here
    var p: seq[CodePos]
    if c.toPatch.take(lab, p):
      for x in p: c.bc.code[x] = toIns(c.bc.code[x].kind, here)
    c.markedWithLabel.incl here.int # for toString()
  of Goto, GotoLoop:
    c.genGoto(t[n].label, GotoM)
  of CheckedGoto:
    c.genGoto(t[n].label, CheckedGotoM)
  of ArrayConstr:
    recurse ArrayConstrM
  of ObjConstr:
    recurse ObjConstrM
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
    #let s =
    discard "xxx"
  of Summon, SummonParam:
    # x = Summon Typed <Type ID>; x begins to live
    discard "xxx"
  of Kill:
    discard "we don't care about Kill instructions"
  of AddrOf:
    recurse AddrOfM
  of ArrayAt:
    recurse ArrayAtM
  of FieldAt:
    recurse FieldAtM
  of Load:
    recurse LoadM
  of Store:
    recurse StoreM
  of Asgn:
    recurse AsgnM
  of SetExc:
    recurse SetExcM
  of TestExc:
    recurse TestExcM
  of CheckedRange:
    recurse CheckedRangeM
  of CheckedIndex:
    recurse CheckedIndexM
  of Call:
    recurse CallM
  of IndirectCall:
    recurse IndirectCallM
  of CheckedCall:
    recurse CheckedCallM
  of CheckedIndirectCall:
    recurse CheckedIndirectCallM
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
    recurse ProcDeclM
  of PragmaPair:
    recurse PragmaPairM

const PayloadSize = 128

type
  StackFrame = ref object
    locals: pointer   # usually points into `payload` if size is small enough, otherwise it's `alloc`'ed.
    payload: array[PayloadSize, byte]
    caller: StackFrame
    returnAddr: CodePos

proc newStackFrame(size: int; caller: StackFrame; returnAddr: CodePos): StackFrame =
  result = StackFrame(caller: caller, returnAddr: returnAddr)
  if size <= PayloadSize:
    result.locals = addr(result.payload)
  else:
    result.locals = alloc0(size)

proc popStackFrame(s: StackFrame): StackFrame =
  if result.locals != addr(result.payload):
    dealloc result.locals
  result = s.caller

template `+!`(p: pointer; diff: uint): pointer = cast[pointer](cast[uint](p) + diff)

proc eval(c: seq[Instr]; pc: CodePos; s: StackFrame; result: pointer)

proc evalAddr(c: seq[Instr]; pc: CodePos; s: StackFrame): pointer =
  case c[pc].kind
  of LoadLocalM:
    result = s.locals +! c[pc].operand
  of FieldAtM:
    result = eval(c, pc+1, s)
    result = result +! c[pc+2].operand
  of ArrayAtM:
    let elemSize = c[pc+1].operand
    result = eval(c, pc+2, s)
    var idx: int
    eval(c, pc+3, addr idx)
    result = result +! (idx * elemSize)

proc eval(c: seq[Instr]; pc: CodePos; s: StackFrame; result: pointer) =
  case c[pc].kind
  of AddM:
    # assume `int` here for now:
    var x, y: int
    eval c, pc+1, s, addr x
    eval c, pc+2, s, addr y
    cast[ptr int](res)[] = x + y
  of StrValM:
    cast[ptr StringDesc](res)[] = addr(c.strings[c[pc].litId])
  of ObjConstrM:
    for ch in sons(c, pc):
      let offset = c[ch]
      eval c, ch+2, s, result+!offset
  of ArrayConstrM:
    let elemSize = c[pc+1].operand
    var r = result
    for ch in sons(c, pc):
      eval c, ch, s, r
      r = r+!elemSize # can even do strength reduction here!
  else:
    assert false, "cannot happen"

proc exec(c: seq[Instr]; pc: CodePos) =
  var pc = pc
  var currentFrame: StackFrame = nil
  while true:
    case c[pc].kind
    of GotoM:
      pc = CodePos(c[pc].operand)
    of Asgn:
      let (size, a, b) = sons3(c, pc)
      let dest = evalAddr(c, a, s)
      eval(c, b, s, dest)
    of CallM:
      # No support for return values, these are mapped to `var T` parameters!
      let prc = evalProc(c, pc+1)
      # setup storage for the proc already:
      let s2 = newStackFrame(prc.frameSize, currentFrame, pc)
      var i = 0
      for a in sons(c, pc):
        eval(c, a, s2, paramAddr(s2, i))
        inc i
      currentFrame = s2
      pc = pcOf(prc)
    of RetM:
      pc = currentFrame.returnAddr
      currentFrame = popStackFrame(currentFrame)
    of SelectM:
      var x: bool
      eval(c, b, addr x)
      # follow the selection instructions...
      pc = activeBranch(c, b, x)
