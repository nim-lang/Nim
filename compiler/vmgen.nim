#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the code generator for the VM.
##
## The VM works on packed data (see vmdef): registers are 8 byte slots of
## the stack frame. Scalars held in registers are widened to 64 bits,
## aggregates occupy consecutive slots and use the memory layout.
##
## Every expression that denotes a location (a local, a global, a field, an
## array element, a dereferenced pointer) is translated to a `Loc`. Values
## are loaded from and stored to locations with typed loads and stores.
##
## The code that is fed to the code generator went through `transf` and,
## for the new runtime, through `injectdestructors`: assignments are bit
## copies, all non-trivial copies, moves and destructions are explicit
## calls to hooks.

import std/[tables, intsets, strutils]

when defined(nimPreviewSlimSystem):
  import std/assertions

import
  ast, astalgo, types, msgs, renderer, vmdef, trees,
  magicsys, options, lowerings, lineinfos, transf, astmsgs,
  injectdestructors, int128, vmvalue, idents, sighashes

from lambdalifting import getEnvParam
from modulegraphs import getBody, recordIcImplDep, getAttachedOp
from liftdestructors import isTrivial

when defined(nimCompilerStacktraceHints):
  import std/stackframes

const
  debugEchoCode* = defined(nimVMDebug)

when debugEchoCode:
  import std/private/asciitables

type
  TGenFlag = enum
    gfWantAddr  # not used yet

  TGenFlags = set[TGenFlag]

  LocKind = enum
    lkFrame     # the location is within the stack frame, starting at slot `reg`
    lkMem       # the location is at the address `regs[reg]`

  Loc = object
    kind: LocKind
    reg: TRegister
    off: int        # byte offset
    widened: bool   # lkFrame: a register-resident (widened) scalar
    whole: bool     # lkFrame: the location owns all slots it spans
    isTemp: bool    # `reg` is a temporary that has to be freed
    typ: PType

  VmBuiltin = enum
    vbNone,
    vbAlloc, vbAlignedAlloc, vbDealloc, vbRealloc,
    vbCopyMem, vbZeroMem, vbEqualMem, vbCmpMem,
    vbIncRef, vbDecRefIsLast, vbRawDispose, vbDestroyAndDispose, vbNop,
    vbAsgnStr, vbSameSeqPayload, vbCopySeqPayload

const
  builtinNames = {
    "alloc": vbAlloc, "alloc0": vbAlloc, "allocShared": vbAlloc,
    "allocShared0": vbAlloc, "allocImpl": vbAlloc, "alloc0Impl": vbAlloc,
    "allocSharedImpl": vbAlloc, "allocShared0Impl": vbAlloc,
    "alignedAlloc": vbAlignedAlloc, "alignedAlloc0": vbAlignedAlloc,
    "dealloc": vbDealloc, "deallocShared": vbDealloc, "deallocImpl": vbDealloc,
    "deallocSharedImpl": vbDealloc, "alignedDealloc": vbDealloc,
    "realloc": vbRealloc, "realloc0": vbRealloc, "reallocShared": vbRealloc,
    "reallocShared0": vbRealloc, "reallocImpl": vbRealloc,
    "realloc0Impl": vbRealloc, "reallocSharedImpl": vbRealloc,
    "reallocShared0Impl": vbRealloc,
    "copyMem": vbCopyMem, "moveMem": vbCopyMem, "nimCopyMem": vbCopyMem,
    "c_memcpy": vbCopyMem, "c_memmove": vbCopyMem,
    "zeroMem": vbZeroMem, "nimZeroMem": vbZeroMem,
    "equalMem": vbEqualMem, "cmpMem": vbCmpMem, "nimCmpMem": vbCmpMem,
    "c_memcmp": vbCmpMem,
    "nimIncRef": vbIncRef, "nimIncRefCyclic": vbIncRef,
    "nimDecRefIsLast": vbDecRefIsLast, "nimDecRefIsLastCyclicDyn": vbDecRefIsLast,
    "nimDecRefIsLastCyclicStatic": vbDecRefIsLast, "nimDecRefIsLastDyn": vbDecRefIsLast,
    "nimRawDispose": vbRawDispose, "nimDestroyAndDispose": vbDestroyAndDispose,
    "nimTraceRef": vbNop, "nimTraceRefDyn": vbNop, "nimMarkCyclic": vbNop,
    "nimAsgnStrV2": vbAsgnStr, "sameSeqPayload": vbSameSeqPayload,
    "nimCopySeqPayload": vbCopySeqPayload}

proc debugInfo(c: PCtx; info: TLineInfo): string =
  result = toFileLineCol(c.config, info)

proc codeListing(c: PCtx, result: var string, start=0; last = -1) =
  ## for debugging purposes
  # first iteration: compute all necessary labels:
  var jumpTargets = initIntSet()
  let last = if last < 0: c.code.len-1 else: min(last, c.code.len-1)
  var i = start
  while i <= last:
    let x = c.code[i]
    if x.opcode in relativeJumps + {opcTry}:
      jumpTargets.incl(i+x.regBx-wordExcess)
    if x.opcode in largeInstrs: inc i
    inc i

  template toStr(opc: TOpcode): string = ($opc).substr(3)

  result.add "code listing:\n"
  i = start
  while i <= last:
    if i in jumpTargets: result.addf("L$1:\n", i)
    let x = c.code[i]

    result.add($i)
    let opc = opcode(x)
    if opc in relativeJumps + {opcTry}:
      result.addf("\t$#\tr$#, L$#", opc.toStr, x.regA,
                  i+x.regBx-wordExcess)
    elif opc >= firstABxInstr or opc in {opcLdImmInt}:
      result.addf("\t$#\tr$#, $#", opc.toStr, x.regA, x.regBx-wordExcess)
    else:
      result.addf("\t$#\tr$#, r$#, r$#", opc.toStr, x.regA,
                  x.regB, x.regC)
    if opc in largeInstrs:
      inc i
      result.addf(", w$#", c.code[i].TInstrType)
    result.add("\t# ")
    result.add(debugInfo(c, c.debug[i]))
    result.add("\n")
    inc i
  when debugEchoCode:
    result = result.alignTable

proc echoCode*(c: PCtx; start=0; last = -1) {.deprecated.} =
  var buf = ""
  codeListing(c, buf, start, last)
  echo buf

# ------------------------- emitting instructions -----------------------------

proc gABC(ctx: PCtx; n: PNode; opc: TOpcode;
          a: TRegister = 0, b: TRegister = 0, c: TRegister = 0) =
  ## Takes the registers `b` and `c`, applies the operation `opc` to them, and
  ## stores the result into register `a`
  ## The node is needed for debug information
  let ins = (opc.TInstrType or (a.TInstrType shl regAShift) or
                           (b.TInstrType shl regBShift) or
                           (c.TInstrType shl regCShift)).TInstr
  if opc in {opcEof, opcEofBoxed}: ctx.lastEof = ctx.code.len
  ctx.code.add(ins)
  ctx.debug.add(n.info)

proc genLdSlot(c: PCtx; n: PNode; dest, slot: TRegister; k: MemKind) =
  ## widens the scalar of kind `k` that is stored in `slot`
  let opc = ldSlotOpc(k)
  if opc != opcMov: c.gABC(n, opc, dest, slot)
  elif dest != slot: c.gABC(n, opcMov, dest, slot)

proc genStSlot(c: PCtx; n: PNode; slot, src: TRegister; k: MemKind) =
  ## narrows `src` to the memory format `k` and stores it in `slot`
  let opc = stSlotOpc(k)
  if opc != opcMov: c.gABC(n, opc, slot, 0, src)
  elif slot != src: c.gABC(n, opcMov, slot, src)

proc gW(ctx: PCtx; n: PNode; w: uint64) =
  ## the extra word of an instruction in `largeInstrs`
  ctx.code.add(TInstr(w))
  ctx.debug.add(n.info)

proc gABCW(ctx: PCtx; n: PNode; opc: TOpcode; a, b, c: TRegister; w: uint64) =
  assert opc in largeInstrs
  gABC(ctx, n, opc, a, b, c)
  gW(ctx, n, w)

proc gABI(c: PCtx; n: PNode; opc: TOpcode; a, b: TRegister; imm: BiggestInt) =
  # Takes the `b` register and the immediate `imm`, applies the operation `opc`,
  # and stores the output value into `a`.
  # `imm` is signed and must be within [-128, 127]
  if imm >= -128 and imm <= 127:
    let ins = (opc.TInstrType or (a.TInstrType shl regAShift) or
                             (b.TInstrType shl regBShift) or
                             (imm+byteExcess).TInstrType shl regCShift).TInstr
    c.code.add(ins)
    c.debug.add(n.info)
  else:
    localError(c.config, n.info,
      "VM: immediate value does not fit into an int8")

proc gABx(c: PCtx; n: PNode; opc: TOpcode; a: TRegister = 0; bx: int) =
  # Applies `opc` to `bx` and stores it into register `a`
  # `bx` must be signed and in the range [regBxMin, regBxMax]
  if bx >= regBxMin-1 and bx <= regBxMax:
    let ins = (opc.TInstrType or a.TInstrType shl regAShift or
              (bx+wordExcess).TInstrType shl regBxShift).TInstr
    c.code.add(ins)
    c.debug.add(n.info)
  else:
    localError(c.config, n.info,
      "VM: immediate value does not fit into regBx")

proc xjmp(c: PCtx; n: PNode; opc: TOpcode; a: TRegister = 0): TPosition =
  result = TPosition(c.code.len)
  gABx(c, n, opc, a, 0)

proc genLabel(c: PCtx): TPosition =
  result = TPosition(c.code.len)

proc jmpBack(c: PCtx, n: PNode, p = TPosition(0)) =
  let dist = p.int - c.code.len
  internalAssert(c.config, regBxMin < dist and dist < regBxMax)
  gABx(c, n, opcJmpBack, 0, dist)

proc patch(c: PCtx, p: TPosition) =
  # patch with current index
  let p = p.int
  let diff = c.code.len - p
  internalAssert(c.config, regBxMin < diff and diff < regBxMax)
  let oldInstr = c.code[p]
  # opcode and regA stay the same:
  c.code[p] = ((oldInstr.TInstrType and (regOMask or (regAMask shl regAShift))).TInstrType or
               TInstrType(diff+wordExcess) shl regBxShift).TInstr

proc genLdImm(c: PCtx; n: PNode; dest: TRegister; v: BiggestInt) =
  if v >= regBxMin and v <= regBxMax:
    c.gABx(n, opcLdImmInt, dest, int(v))
  else:
    c.gABCW(n, opcLdImm, dest, 0, 0, cast[uint64](v))

proc genLdImmAddr(c: PCtx; n: PNode; dest: TRegister; a: Address) =
  c.gABCW(n, opcLdImm, dest, 0, 0, uint64(a))

# ------------------------- types ---------------------------------------------

proc vmSize(c: PCtx; t: PType): int = vmSizeOf(c.layouts, c.config, t)
proc vmAlign(c: PCtx; t: PType): int = vmAlignOf(c.layouts, c.config, t)

proc mk(c: PCtx; t: PType): MemKind = memKind(c.config, t)

proc isScalar(c: PCtx; t: PType): bool =
  t != nil and mk(c, t) != mkBlock

proc slotsOf(c: PCtx; t: PType): int =
  if t == nil or isEmptyType(t) or isScalar(c, t): 1
  else: slotsFor(vmSize(c, t))

proc typeHandle(c: PCtx; t: PType): int32 = typeHandle(c.mem, t)

proc valueConv*(c: PCtx): ValueConv =
  ValueConv(mem: addr c.mem, layouts: addr c.layouts, conf: c.config,
            nilType: c.graph.getSysType(unknownLineInfo, tyNil))

proc isFloatType(t: PType): bool =
  t.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc}).kind in {tyFloat..tyFloat128}

proc isUnsigned(c: PCtx; t: PType): bool =
  mk(c, t) in UnsignedMemKinds

proc packAddr(w1, w2: int): uint64 = uint64(w1) or (uint64(w2) shl 32)

proc needsInitObj(c: PCtx; t: PType; marker: var IntSet): bool =
  ## does a zeroed value of type `t` need type headers to be set?
  let t = skipForLayout(t)
  if isNimNodeType(t): return false
  case t.kind
  of tyObject:
    var root = t
    while root.baseClass != nil: root = root.baseClass.skipTypes(skipPtrs)
    if hasTypeHeader(root): return true
    if marker.containsOrIncl(t.id): return false
    proc fieldsNeedInit(c: PCtx; n: PNode; marker: var IntSet): bool =
      case n.kind
      of nkSym: needsInitObj(c, n.sym.typ, marker)
      of nkRecList, nkRecCase, nkOfBranch, nkElse:
        for ch in n:
          if fieldsNeedInit(c, ch, marker): return true
        false
      else: false
    var b = t
    while b != nil:
      if b.n != nil and fieldsNeedInit(c, b.n, marker): return true
      b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
    result = false
  of tyArray:
    result = needsInitObj(c, t.elementType, marker)
  of tyTuple:
    result = false
    for _, ch in t.ikids:
      if needsInitObj(c, ch, marker): return true
  else:
    result = false

proc needsInitObj(c: PCtx; t: PType): bool =
  var marker = initIntSet()
  result = needsInitObj(c, t, marker)

# ------------------------- registers -----------------------------------------

proc bestEffort(c: PCtx): TLineInfo =
  if c.prc != nil and c.prc.sym != nil:
    c.prc.sym.info
  else:
    c.module.info

proc getFreeRange(cc: PCtx; n: int; isTemp: bool): TRegister =
  let c = cc.prc
  let n = max(n, 1)
  var i = 0
  while i + n <= c.regInfo.len:
    block search:
      for j in i..<i+n:
        if c.regInfo[j].inUse:
          i = j+1
          break search
      result = TRegister(i)
      for j in i..<i+n: c.regInfo[j] = SlotUse(inUse: true, isTemp: isTemp)
      c.regInfo[i].rangeLen = int32(n)
      return
  # extend; we can reuse free slots at the end:
  var start = c.regInfo.len
  while start > 0 and not c.regInfo[start-1].inUse: dec start
  if start + n > MaxFrameSlots:
    globalError(cc.config, cc.bestEffort, "VM problem: stack frame too large")
  c.regInfo.setLen max(c.regInfo.len, start + n)
  result = TRegister(start)
  for j in start..<start+n: c.regInfo[j] = SlotUse(inUse: true, isTemp: isTemp)
  c.regInfo[start].rangeLen = int32(n)

proc getTemp(c: PCtx; t: PType): TRegister =
  getFreeRange(c, slotsOf(c, t), true)

proc getTempN(c: PCtx; n: int): TRegister =
  getFreeRange(c, n, true)

proc getIntTemp(c: PCtx): TRegister = getFreeRange(c, 1, true)

proc freeTemp(c: PCtx; r: TRegister) =
  let p = c.prc
  if r < p.regInfo.len and p.regInfo[r].isTemp and p.regInfo[r].inUse:
    let n = max(p.regInfo[r].rangeLen, 1)
    for j in r..<min(r+n, p.regInfo.len):
      p.regInfo[j] = SlotUse()

proc pinTemp(c: PCtx; r: TRegister) =
  let p = c.prc
  if r < p.regInfo.len and p.regInfo[r].isTemp:
    let n = max(p.regInfo[r].rangeLen, 1)
    for j in r..<min(r+n, p.regInfo.len):
      p.regInfo[j].isTemp = false

proc isTemp(c: PCtx; r: TDest): bool =
  r >= 0 and r < c.prc.regInfo.len and c.prc.regInfo[r].isTemp

template withTemp(tmp, typ, body: untyped) {.dirty.} =
  var tmp = getTemp(c, typ)
  body
  c.freeTemp(tmp)

proc popBlock(c: PCtx; oldLen: int) =
  for f in c.prc.blocks[oldLen].fixups:
    c.patch(f)
  c.prc.blocks.setLen(oldLen)

template withBlock(labl: PSym; body: untyped) {.dirty.} =
  var oldLen {.gensym.} = c.prc.blocks.len
  c.prc.blocks.add TBlock(label: labl, fixups: @[], tryDepth: c.prc.tries.len)
  body
  popBlock(c, oldLen)

# ------------------------- locals --------------------------------------------

template isGlobal(s: PSym): bool = sfGlobal in s.flags and s.kind != skForVar
proc isGlobal(n: PNode): bool = n.kind == nkSym and isGlobal(n.sym)

proc skipAddrConv(n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of nkHiddenStdConv, nkHiddenSubConv, nkConv: result = result[1]
    of nkObjUpConv, nkObjDownConv: result = result[0]
    of nkStmtListExpr: result = result.lastSon
    else: break

proc collectAddrTaken(c: PCtx; n: PNode; res: var IntSet) =
  ## collects the locals whose address is taken; these cannot be held in
  ## (widened) registers.
  case n.kind
  of nkAddr, nkHiddenAddr:
    let x = skipAddrConv(n[0])
    if x.kind == nkSym and x.sym.kind in {skVar, skLet, skForVar, skTemp, skResult, skParam}:
      res.incl x.sym.id
      # macros see copies of their result and parameters:
      if x.sym.kind == skResult: c.prc.resultAddrTaken = true
      elif x.sym.kind == skParam: c.prc.paramAddrTaken.incl x.sym.position
    collectAddrTaken(c, n[0], res)
  of nkCallKinds:
    if n[0].kind == nkSym and n[0].sym.magic notin generatedMagics:
      # magics are implemented inline and take their `var` arguments as
      # locations, not as addresses:
      for i in 1..<n.len:
        let a = if n[i].kind in {nkAddr, nkHiddenAddr}: n[i][0] else: n[i]
        collectAddrTaken(c, a, res)
    else:
      for ch in n: collectAddrTaken(c, ch, res)
  of nkLambdaKinds, nkTypeSection, nkConstSection, nkPragma, nkTemplateDef,
     nkMacroDef, nkMethodDef, nkProcDef, nkFuncDef, nkConverterDef, nkIteratorDef:
    discard
  of nkNone..nkNilLit:
    discard
  else:
    for ch in n: collectAddrTaken(c, ch, res)

proc localType(s: PSym): PType =
  ## variables cannot hold types at runtime; a `typedesc[T]` variable comes
  ## from a generic return type `T: typedesc` and holds a `T`.
  result = s.typ
  if result != nil and result.kind == tyTypeDesc and
      s.kind in {skVar, skLet, skTemp, skForVar, skResult} and result.hasElementType:
    result = result.elementType

proc isTypeExpr(n: PNode): bool =
  case n.kind
  of nkType, nkTypeOfExpr: true
  of nkSym:
    n.sym.kind in {skType, skGenericParam} or
      (n.sym.kind == skParam and n.sym.typ.kind == tyTypeDesc)
  of nkBracketExpr: n.len > 0 and isTypeExpr(n[0])
  else: false

proc exprType(n: PNode): PType =
  ## the type of the value `n`; see `localType`
  if n.kind == nkSym: localType(n.sym)
  elif n.typ != nil and n.typ.kind == tyTypeDesc and not isTypeExpr(n) and n.typ.hasElementType:
    n.typ.elementType
  else: n.typ

proc addLocal(c: PCtx; s: PSym; slot: TRegister) =
  let inMem = isScalar(c, localType(s)) and s.id in c.prc.addrTaken
  c.prc.locals[s.itemId] = LocalInfo(slot: slot, inMemory: inMem)

const
  BoxThreshold = 64 * 1024 ## locals bigger than this live on the heap

proc setSlot(c: PCtx; s: PSym; info: PNode = nil): TRegister =
  ## allocates the slots of a local variable
  let x = c.prc.locals.getOrDefault(s.itemId, LocalInfo(slot: -1))
  if x.slot >= 0 and x.slot < c.prc.regInfo.len and c.prc.regInfo[x.slot].inUse:
    return x.slot
  # a symbol can be declared multiple times (templates duplicate their
  # bodies); a dead declaration gets fresh slots.
  let typ = localType(s)
  if not isScalar(c, typ) and vmSize(c, typ) > BoxThreshold:
    # a big value: we allocate it on the heap once and keep its address
    result = getFreeRange(c, 1, false)
    c.prc.locals[s.itemId] = LocalInfo(slot: result, boxed: true)
    let n = if info != nil: info else: newSymNode(s)
    let t = getFreeRange(c, 1, true)
    c.gABC(n, opcIsNil, t, result)
    let skip = c.xjmp(n, opcFJmp, t)
    genLdImm(c, n, t, vmSize(c, typ))
    c.gABC(n, opcAlloc, result, t)
    c.patch(skip)
    c.prc.regInfo[t] = SlotUse()
  else:
    result = getFreeRange(c, slotsOf(c, typ), false)
    addLocal(c, s, result)

proc isLocationExpr(n: PNode): bool =
  case n.kind
  of nkSym: n.sym.kind in {skVar, skLet, skTemp, skForVar, skResult, skParam, skConst}
  of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr, nkDerefExpr, nkHiddenDeref:
    true
  of nkStmtListExpr: isLocationExpr(n.lastSon)
  of nkBlockExpr: isLocationExpr(n[1])
  of nkObjUpConv, nkObjDownConv: isLocationExpr(n[0])
  else: false

# ------------------------- forward declarations ------------------------------

proc gen(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags = {})
proc genLoc(c: PCtx; n: PNode; write = false): Loc
proc genProc*(c: PCtx; s: PSym): VmProcInfo
proc genCall(c: PCtx; n: PNode; dest: var TDest)

proc gen(c: PCtx; n: PNode; dest: TRegister; flags: TGenFlags = {}) =
  var d: TDest = dest
  gen(c, n, d, flags)
  if d != dest:
    # the value ended up elsewhere (an alias of a local); copy it:
    if n.typ != nil and not isEmptyType(n.typ) and d >= 0:
      let k = slotsOf(c, n.typ)
      if k == 1: c.gABC(n, opcMov, dest, d)
      else: c.gABC(n, opcMovN, dest, d, TRegister(k))
      c.freeTemp(d)

proc gen(c: PCtx; n: PNode; flags: TGenFlags = {}) =
  var tmp: TDest = -1
  gen(c, n, tmp, flags)
  if tmp >= 0:
    freeTemp(c, tmp)

proc genx(c: PCtx; n: PNode; flags: TGenFlags = {}): TRegister =
  var tmp: TDest = -1
  gen(c, n, tmp, flags)
  if tmp >= 0:
    result = TRegister(tmp)
  else:
    result = 0

proc clearDest(c: PCtx; n: PNode; dest: var TDest) {.inline.} =
  # stmt is different from 'void' in meta programming contexts.
  # So we only set dest to -1 if 'void':
  if dest >= 0 and (n.typ.isNil or n.typ.kind == tyVoid):
    c.freeTemp(dest)
    dest = -1

proc unused(c: PCtx; n: PNode; x: TDest) {.inline.} =
  if x >= 0:
    globalError(c.config, n.info, "not unused")

# ------------------------- locations -----------------------------------------

proc frameLoc(reg: TRegister; typ: PType; widened, whole, isTemp: bool): Loc =
  Loc(kind: lkFrame, reg: reg, off: 0, widened: widened, whole: whole,
      isTemp: isTemp, typ: typ)

proc memLoc(reg: TRegister; off: int; typ: PType; isTemp: bool): Loc =
  Loc(kind: lkMem, reg: reg, off: off, typ: typ, isTemp: isTemp)

proc freeLoc(c: PCtx; loc: Loc) =
  if loc.isTemp: c.freeTemp(loc.reg)

proc addrOfLoc(c: PCtx; n: PNode; loc: var Loc): TRegister =
  ## turns `loc` into a lkMem location with offset 0 and returns the
  ## register that holds its address. The register is owned by `loc`.
  case loc.kind
  of lkFrame:
    if loc.widened:
      globalError(c.config, n.info, "VM: internal error: cannot take the address of a register")
    let t = c.getIntTemp()
    c.gABC(n, opcAddrSlot, t, loc.reg)
    if loc.off != 0:
      c.gABCW(n, opcAddrOffW, t, t, 0, uint64(loc.off))
    if loc.isTemp:
      # the address of the temporary may be used for a while; we pin it
      # until the end of the block (like the old VM's `slotTempPerm`):
      pinTemp(c, loc.reg)
    loc = memLoc(t, 0, loc.typ, true)
  of lkMem:
    if loc.off != 0:
      let t = if loc.isTemp: loc.reg else: c.getIntTemp()
      if loc.off <= int(regCMask):
        c.gABC(n, opcAddrOff, t, loc.reg, TRegister(loc.off))
      else:
        c.gABCW(n, opcAddrOffW, t, loc.reg, 0, uint64(loc.off))
      loc = memLoc(t, 0, loc.typ, true)
  result = loc.reg

proc loadLoc(c: PCtx; n: PNode; loc: var Loc; dest: var TDest) =
  ## loads the value of `loc` into `dest`. Frees `loc`.
  let t = loc.typ
  if isScalar(c, t):
    let k = mk(c, t)
    case loc.kind
    of lkFrame:
      if loc.widened:
        if dest < 0:
          # alias; locals are only read from here
          dest = loc.reg
          return
        elif dest != loc.reg:
          c.gABC(n, opcMov, dest, loc.reg)
      elif loc.off mod SlotSize == 0:
        if dest < 0: dest = c.getIntTemp()
        c.genLdSlot(n, dest, TRegister(loc.reg + loc.off div SlotSize), k)
      else:
        let a = addrOfLoc(c, n, loc)
        if dest < 0: dest = c.getIntTemp()
        c.gABC(n, ldOpc(k), dest, a, 0)
    of lkMem:
      if dest < 0: dest = c.getIntTemp()
      if loc.off <= int(regCMask):
        c.gABC(n, ldOpc(k), dest, loc.reg, TRegister(loc.off))
      else:
        let a = addrOfLoc(c, n, loc)
        c.gABC(n, ldOpc(k), dest, a, 0)
  else:
    let size = vmSize(c, t)
    let k = slotsOf(c, t)
    if loc.kind == lkFrame and loc.off mod SlotSize == 0:
      let src = TRegister(loc.reg + loc.off div SlotSize)
      if dest < 0 and not loc.isTemp:
        dest = src
        return
      elif dest < 0:
        dest = c.getTemp(t)
      if dest != src:
        c.gABC(n, opcMovN, dest, src, TRegister(k))
    else:
      let a = addrOfLoc(c, n, loc)
      if dest < 0: dest = c.getTemp(t)
      let d = c.getIntTemp()
      c.gABC(n, opcAddrSlot, d, dest)
      if size > 0: c.gABCW(n, opcCopyMem, d, a, 0, uint64(size))
      c.freeTemp(d)
  c.freeLoc(loc)

proc storeLoc(c: PCtx; n: PNode; loc: var Loc; src: TRegister) =
  ## stores the value in register(s) `src` into `loc`. Frees `loc`.
  let t = loc.typ
  if isScalar(c, t):
    let k = mk(c, t)
    case loc.kind
    of lkFrame:
      if loc.widened:
        if src != loc.reg: c.gABC(n, opcMov, loc.reg, src)
      elif loc.off mod SlotSize == 0:
        c.genStSlot(n, TRegister(loc.reg + loc.off div SlotSize), src, k)
      else:
        let a = addrOfLoc(c, n, loc)
        c.gABC(n, stOpc(k), a, 0, src)
    of lkMem:
      if loc.off <= int(regBMask):
        c.gABC(n, stOpc(k), loc.reg, TRegister(loc.off), src)
      else:
        let a = addrOfLoc(c, n, loc)
        c.gABC(n, stOpc(k), a, 0, src)
  else:
    let size = vmSize(c, t)
    if loc.kind == lkFrame and loc.off mod SlotSize == 0 and
        (loc.whole or size mod SlotSize == 0):
      let d = TRegister(loc.reg + loc.off div SlotSize)
      if d != src: c.gABC(n, opcMovN, d, src, TRegister(slotsOf(c, t)))
    elif size > 0:
      let a = addrOfLoc(c, n, loc)
      let s = c.getIntTemp()
      c.gABC(n, opcAddrSlot, s, src)
      c.gABCW(n, opcCopyMem, a, s, 0, uint64(size))
      c.freeTemp(s)
  c.freeLoc(loc)

proc zeroLoc(c: PCtx; n: PNode; loc: var Loc) =
  ## sets `loc` to the default value of its type. Frees `loc`.
  let t = loc.typ
  if isScalar(c, t) and loc.kind == lkFrame and loc.widened:
    c.gABx(n, opcLdImmInt, loc.reg, 0)
    c.freeLoc(loc)
  elif loc.kind == lkFrame and loc.off == 0 and loc.whole and not needsInitObj(c, t):
    c.gABC(n, opcZeroN, loc.reg, TRegister(slotsOf(c, t)))
    c.freeLoc(loc)
  else:
    let size = vmSize(c, t)
    let a = addrOfLoc(c, n, loc)
    if size > 0: c.gABCW(n, opcZeroMem, a, 0, 0, uint64(size))
    if needsInitObj(c, t):
      c.gABCW(n, opcInitObj, a, 0, 0, uint64(typeHandle(c, t)))
    c.freeLoc(loc)

proc valueType(n: PNode): PType =
  ## `injectdestructors` produces untyped `try` expressions (and untyped
  ## statement list expressions within them); we derive their type from the
  ## last expression. (The tree must not be modified, it is shared.)
  result = n.typ
  if result == nil and n.kind in {nkTryStmt, nkHiddenTryStmt, nkStmtListExpr} and n.len > 0:
    result = valueType(if n.kind == nkStmtListExpr: n.lastSon else: n[0])

proc genTempLoc(c: PCtx; n: PNode): Loc =
  ## evaluates the rvalue `n` into a temporary location
  let t = valueType(n)
  var d: TDest = -1
  gen(c, n, d)
  if d < 0:
    d = c.getTemp(t)
  result = frameLoc(d, t, isScalar(c, t), true, c.isTemp(d))

# ------------------------- literals and constants ----------------------------

proc constAddress(c: PCtx; n: PNode; t: PType): Address =
  ## stores the constant `n` in constant memory.
  let size = vmSize(c, t)
  result = allocConst(c.mem, size, vmAlign(c, t))
  storeValue(valueConv(c), result, n, t, inConst = true)

proc symConstAddress(c: PCtx; s: PSym; value: PNode): Address =
  result = c.constAddrs.getOrDefault(s.itemId, 0)
  if result == 0:
    result = constAddress(c, value, s.typ)
    c.constAddrs[s.itemId] = result

proc genLitInto(c: PCtx; n: PNode; t: PType; dest: var TDest) =
  ## a literal or constant value of type `t`
  let s = skipForLayout(t)
  if isScalar(c, t):
    if dest < 0: dest = c.getIntTemp()
    case s.kind
    of tyFloat32:
      let v = if n.kind in nkFloatLiterals: float32(n.floatVal) else: float32(getOrdValue(n).toInt64)
      genLdImm(c, n, dest, cast[BiggestInt](float64(v)))
    of tyFloat, tyFloat64, tyFloat128:
      let v = if n.kind in nkFloatLiterals: n.floatVal else: BiggestFloat(getOrdValue(n).toInt64)
      genLdImm(c, n, dest, cast[BiggestInt](v))
    of tyCstring:
      if n.kind in nkStrKinds:
        var tmp: Address = 0
        let a = allocConst(c.mem, 8, 8)
        storeValue(valueConv(c), a, n, t, inConst = true)
        tmp = ld[Address](a)
        genLdImmAddr(c, n, dest, tmp)
      else:
        c.gABx(n, opcLdImmInt, dest, 0)
    of tyRef, tyTypeDesc, tyUntyped, tyTyped, tyProc, tySet, tyPtr, tyPointer, tyNil:
      # handles, proc addresses, small sets: let `storeValue` compute the bits
      let a = allocConst(c.mem, 8, 8)
      storeValue(valueConv(c), a, n, t, inConst = true)
      genLdImm(c, n, dest, loadInt(a, mk(c, t)))
    else:
      genLdImm(c, n, dest, if n.kind == nkNilLit: 0 else: getOrdValue(n).toInt64)
  else:
    if dest < 0: dest = c.getTemp(t)
    case s.kind
    of tyString:
      if n.kind in nkStrKinds and n.strVal.len == 0 or n.kind == nkNilLit:
        c.gABC(n, opcZeroN, dest, 2)
      else:
        let a = constAddress(c, n, t)
        genLdImm(c, n, dest, ld[int64](a))
        genLdImm(c, n, TRegister(dest+1), ld[int64](a +! 8))
    else:
      let a = constAddress(c, n, t)
      let size = vmSize(c, t)
      var loc = memLoc(c.getIntTemp(), 0, t, true)
      genLdImmAddr(c, n, loc.reg, a)
      var d = dest
      loadLoc(c, n, loc, d)
      if size == 0: discard

proc genLit(c: PCtx; n: PNode; dest: var TDest) =
  genLitInto(c, n, n.typ, dest)

proc genNodeLit(c: PCtx; info: PNode; node: PNode; dest: var TDest) =
  ## a NimNode literal
  if dest < 0: dest = c.getIntTemp()
  genLdImm(c, info, dest, nodeHandle(c.mem, node))

proc genTypeLit(c: PCtx; info: PNode; t: PType; dest: var TDest) =
  genNodeLit(c, info, newNodeIT(nkType, info.info, t), dest)

proc importcCond*(c: PCtx; s: PSym): bool

proc checkProcSym(c: PCtx; n: PNode; s: PSym) =
  ## errors for procs that cannot be used at compile time
  if s.kind == skIterator and s.typ.callConv == TCallingConvention.ccClosure:
    globalError(c.config, n.info, "Closure iterators are not supported by VM!")
  if s.kind in {skProc, skFunc, skConverter, skMethod, skIterator} and
      sfForward in s.flags:
    globalError(c.config, n.info, "cannot evaluate at compile time: " & n.renderTree)
  if importcCond(c, s) and s.offset >= -1 and
      not c.callbackIndex.contains(s.name.s):
    localError(c.config, n.info,
               "cannot 'importc' variable at compile time; " & s.name.s)

proc genProcLit(c: PCtx; n: PNode; s: PSym; dest: var TDest) =
  checkProcSym(c, n, s)
  if dest < 0: dest = c.getTemp(n.typ)
  genLdImmAddr(c, n, dest, procAddress(c.mem, s))
  if slotsOf(c, n.typ) == 2:
    c.gABx(n, opcLdImmInt, TRegister(dest+1), 0)

# ------------------------- globals -------------------------------------------

proc importcCondVar*(s: PSym): bool {.inline.} =
  # see also importcCond
  if sfImportc in s.flags:
    result = s.kind in {skVar, skLet, skConst}
  else:
    result = false

template cannotEval(c: PCtx; n: PNode) =
  if c.config.cmd == cmdCheck and c.config.m.errorOutputs != {}:
    # nim check command with no error outputs doesn't need to cascade here,
    # includes `tryConstExpr` case which should not continue generating code
    localError(c.config, n.info, "cannot evaluate at compile time: " & n.renderTree)
    c.cannotEval = true
    return
  globalError(c.config, n.info, "cannot evaluate at compile time: " &
    n.renderTree)

proc isEmptyBody(n: PNode): bool =
  case n.kind
  of nkStmtList:
    for i in 0..<n.len:
      if not isEmptyBody(n[i]): return false
    result = true
  else:
    result = n.kind in {nkCommentStmt, nkEmpty}

proc importcCond*(c: PCtx; s: PSym): bool =
  ## return true to importc `s`, false to execute its body instead (refs #8405)
  result = false
  if sfImportc in s.flags:
    if s.kind in routineKinds:
      return isEmptyBody(getBody(c.graph, s))

proc genStoreValue(c: PCtx; loc: var Loc; value: PNode)
proc genOpenArrayConv(c: PCtx; n, arg: PNode; dest: var TDest)

proc globalAddress(c: PCtx; n: PNode; s: PSym): Address =
  ## the address of the global `s`; allocates and initializes it lazily.
  result = c.globalAddrs.getOrDefault(s.itemId, 0)
  if result == 0:
    if importcCondVar(s):
      when hasFFI:
        if compiletimeFFI in c.config.features:
          # the VM uses host pointers: the variable is accessed in place
          let p = importcSymbol(c.config, s)
          registerForeign(c.mem, p, vmSize(c, s.typ))
          result = toAddr(p)
          c.globalAddrs[s.itemId] = result
          return
      localError(c.config, n.info,
                 "cannot 'importc' variable at compile time; " & s.name.s)
    result = allocGlobal(c.mem, vmSize(c, s.typ), vmAlign(c, s.typ))
    c.globalAddrs[s.itemId] = result
    if needsInitObj(c, s.typ):
      # a zeroed value with initialized type headers:
      storeValue(valueConv(c), result, newNodeI(nkEmpty, n.info), s.typ, inConst = false)
    # This is rather hard to support, due to the laziness of the VM code
    # generator. See tests/compile/tmacro2 for why this is necessary:
    #   var decls{.compileTime.}: seq[NimNode] = @[]
    # The initializer runs when the code that references the global runs
    # for the first time; a flag word guards against running it again.
    if s.astdef != nil and s.astdef.kind != nkEmpty:
      let flag = allocGlobal(c.mem, 8, 8)
      let t = c.getIntTemp()
      let f = c.getIntTemp()
      genLdImmAddr(c, n, t, flag)
      c.gABC(n, opcLd64, f, t, 0)
      let skip = c.xjmp(n, opcTJmp, f)
      c.gABx(n, opcLdImmInt, f, 1)
      c.gABC(n, opcSt64, t, 0, f)
      var loc = memLoc(c.getIntTemp(), 0, s.typ, true)
      genLdImmAddr(c, n, loc.reg, result)
      genStoreValue(c, loc, s.astdef)
      c.patch(skip)
      c.freeTemp(f)
      c.freeTemp(t)

proc macroParamType(c: PCtx; t: PType; info: TLineInfo): PType =
  ## inside a macro, every parameter that is not `static` is a NimNode
  if t.kind == tyStatic and t.hasElementType: t.base
  elif t.kind == tyTypeDesc: t
  else: getSysSym(c.graph, info, "NimNode").typ

# ------------------------- symbols as locations ------------------------------

proc isOwnedBy(a, b: PSym): bool =
  result = false
  var a = a.owner
  while a != nil and a.kind != skModule:
    if a == b: return true
    a = a.owner

proc getOwner(c: PCtx): PSym =
  result = c.prc.sym
  if result.isNil: result = c.module

proc checkCanEval(c: PCtx; n: PNode) =
  # we need to ensure that we don't evaluate 'x' here:
  # proc foo() = var x ...
  let s = n.sym
  if {sfCompileTime, sfGlobal} <= s.flags: return
  if compiletimeFFI in c.config.features and s.importcCondVar: return
  if s.kind in {skVar, skTemp, skLet, skParam, skResult} and
      not s.isOwnedBy(c.prc.sym) and s.owner != c.module and c.mode != emRepl:
    # little hack ahead for bug #12612: assume gensym'ed variables
    # are in the right scope:
    if sfGenSym in s.flags and c.prc.sym == nil: discard
    elif s.kind == skParam and s.typ.kind == tyTypeDesc: discard
    elif s.kind in {skVar, skLet} and s.id in c.locals: discard
    else: cannotEval(c, n)
  elif s.kind in {skProc, skFunc, skConverter, skMethod,
                  skIterator} and sfForward in s.flags:
    cannotEval(c, n)

proc symLoc(c: PCtx; n: PNode): Loc =
  let s = n.sym
  if s.isGlobal:
    if sfCompileTime notin s.flags and c.mode != emRepl and not importcCondVar(s) and
        not c.globalAddrs.hasKey(s.itemId):
      cannotEval(c, n)
    let a = globalAddress(c, n, s)
    result = memLoc(c.getIntTemp(), 0, s.typ, true)
    genLdImmAddr(c, n, result.reg, a)
  else:
    var x = c.prc.locals.getOrDefault(s.itemId, LocalInfo(slot: -1))
    if x.slot < 0 and s.kind == skParam and s.position >= 0 and
        s.position < c.prc.paramSlots.len and c.prc.sym != nil and
        s.owner == c.prc.sym:
      # macros see copies of their parameters:
      x = c.prc.paramSlots[s.position]
    elif x.slot < 0 and s.kind == skResult and c.prc.hasResult:
      x = c.prc.resultInfo
    if x.slot < 0:
      if c.mode == emRepl:
        discard setSlot(c, s)
        x = c.prc.locals[s.itemId]
      else:
        # see tests/t99bott for an example that triggers it:
        cannotEval(c, n)
    let typ = if s.kind == skGenericParam: macroParamType(c, s.typ, n.info)
              else: localType(s)
    if x.boxed:
      result = memLoc(TRegister(x.slot), 0, typ, false)
    else:
      result = frameLoc(TRegister(x.slot), typ, isScalar(c, typ) and not x.inMemory,
                        true, false)

# ------------------------- compound locations --------------------------------

proc genIndexReg(c: PCtx; n: PNode; arr: PType): TRegister =
  ## the index `n` relative to the start of `arr`
  let a = arr.skipTypes(abstractInst)
  if a.kind == tyArray and (let x = firstOrd(c.config, a.indexType); x != Zero):
    let tmp = c.genx(n)
    result = c.getIntTemp()
    let first = toInt64(x)
    if first >= -127 and first <= 127:
      c.gABI(n, opcSubImmInt, result, tmp, first)
    else:
      let f = c.getIntTemp()
      genLdImm(c, n, f, first)
      c.gABC(n, opcSubInt, result, tmp, f)
      c.freeTemp(f)
    c.freeTemp(tmp)
  else:
    let tmp = c.genx(n)
    if c.isTemp(tmp):
      result = tmp
    else:
      result = c.getIntTemp()
      c.gABC(n, opcMov, result, tmp)

proc derefLoc(c: PCtx; ptrNode: PNode; typ: PType): Loc =
  ## the location that the pointer `ptrNode` points to
  var p = genLoc(c, ptrNode)
  if p.kind == lkFrame and p.widened and p.off == 0:
    result = memLoc(p.reg, 0, typ, p.isTemp)
  else:
    var d: TDest = -1
    loadLoc(c, ptrNode, p, d)
    result = memLoc(d, 0, typ, c.isTemp(d))

proc objBaseLoc(c: PCtx; n: PNode): Loc =
  ## the location of the object `n`; dereferences refs and ptrs
  if n.kind in {nkHiddenSubConv, nkHiddenStdConv, nkConv, nkObjUpConv, nkObjDownConv}:
    # lifted hooks access the parent fields of a `ref object of Base`
    # via a conversion of the object to `Base`, a ref type:
    let inner = if n.kind in {nkObjUpConv, nkObjDownConv}: n[0] else: n[1]
    if inner.typ != nil and inner.typ.skipTypes(abstractInst+{tyOwned}).kind == tyObject:
      return genLoc(c, inner)
  if n.typ != nil and n.typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
    result = derefLoc(c, n, n.typ.skipTypes(abstractInst).elementType)
  else:
    result = genLoc(c, n)

proc fieldLoc(c: PCtx; base: Loc; objType: PType; field: PSym): Loc =
  result = base
  let t = objType.skipTypes(abstractInst+{tyOwned}+skipPtrs)
  if t.kind == tyTuple:
    result.off += elemOffset(c.layouts, c.config, t, field.position)
  else:
    result.off += fieldOffset(c.layouts, c.config, t, field)
  result.typ = field.typ
  result.widened = false
  result.whole = false

proc genField(c: PCtx; n: PNode): PSym =
  if n.kind != nkSym or n.sym.kind != skField:
    globalError(c.config, n.info, "no field symbol")
  result = n.sym

proc baseType(n: PNode): PType =
  result = n.typ.skipTypes(abstractInst+{tyOwned})
  if result.kind in {tyRef, tyPtr}: result = result.elementType.skipTypes(abstractInst+{tyOwned})

proc genSetElem(c: PCtx; n: PNode; setType: PType): TRegister =
  ## the bit index of the set element `n`
  let first = toInt64(firstOrd(c.config, setType.skipTypes(abstractInst).elementType))
  let tmp = c.genx(n)
  result = c.getIntTemp()
  if first == 0:
    c.gABC(n, opcMov, result, tmp)
  elif first >= -127 and first <= 127:
    c.gABI(n, opcSubImmInt, result, tmp, first)
  else:
    let f = c.getIntTemp()
    genLdImm(c, n, f, first)
    c.gABC(n, opcSubInt, result, tmp, f)
    c.freeTemp(f)
  c.freeTemp(tmp)

proc isBigSet(c: PCtx; t: PType): bool = not isScalar(c, t)

proc genValueAddr(c: PCtx; n: PNode): Loc =
  ## evaluates `n` and returns a location of kind lkMem with offset 0 that
  ## holds the address of its value (in memory format).
  var loc = genLoc(c, n)
  if loc.kind == lkFrame and loc.widened:
    # bring the scalar into memory format:
    let t = c.getIntTemp()
    c.genStSlot(n, t, loc.reg, mk(c, loc.typ))
    c.freeLoc(loc)
    loc = frameLoc(t, n.typ, false, true, true)
  discard addrOfLoc(c, n, loc)
  result = loc

proc genCheckedObjAccessAux(c: PCtx; n: PNode): Loc =
  internalAssert c.config, n.kind == nkCheckedFieldExpr
  # nkDotExpr to access the requested field
  let accessExpr = n[0]
  # nkCall to check if the discriminant is valid
  var checkExpr = n[1]

  let negCheck = checkExpr[0].sym.magic == mNot
  if negCheck:
    checkExpr = checkExpr[^1]

  # Discriminant symbol
  let disc = checkExpr[2]
  internalAssert c.config, disc.sym.kind == skField

  var base = objBaseLoc(c, accessExpr[0])
  if base.kind == lkMem: discard addrOfLoc(c, n, base)
  # Load the discriminant
  var dloc = fieldLoc(c, base, baseType(accessExpr[0]), disc.sym)
  dloc.isTemp = false
  var discVal: TDest = c.getIntTemp()
  loadLoc(c, n, dloc, discVal)
  # Check if its value is contained in the supplied set
  let setType = checkExpr[1].typ
  let setLit = c.genx(checkExpr[1])
  let elem = c.getIntTemp()
  let first = toInt64(firstOrd(c.config, setType.skipTypes(abstractInst).elementType))
  c.gABC(n, opcMov, elem, discVal)
  if first != 0:
    let f = c.getIntTemp()
    genLdImm(c, n, f, first)
    c.gABC(n, opcSubInt, elem, elem, f)
    c.freeTemp(f)
  let rs = c.getIntTemp()
  if isBigSet(c, setType):
    let a = c.getIntTemp()
    c.gABC(n, opcAddrSlot, a, setLit)
    c.gABCW(n, opcBSetContains, rs, a, elem, uint64(vmSize(c, setType)))
    c.freeTemp(a)
  else:
    c.gABC(n, opcSetContains, rs, setLit, elem)
  c.freeTemp(elem)
  c.freeTemp(setLit)
  # If the check fails let the user know
  let lab1 = c.xjmp(n, if negCheck: opcFJmp else: opcTJmp, rs)
  c.freeTemp(rs)
  let strType = getSysType(c.graph, n.info, tyString)
  var msgReg: TDest = c.getTemp(strType)
  let fieldName = $accessExpr[1]
  # Re-navigate the discriminant in the object type: under `nim ic` `disc.sym` is a
  # field-use stub with a nil `owner`, which `genFieldDefect` dereferences. Look up the
  # canonical discriminant field by name. Byte-neutral for non-IC (returns the same sym).
  let dfield = lookupFieldAgain(accessExpr[0].typ, disc.sym)
  let msg = genFieldDefect(c.config, fieldName, dfield)
  let strLit = newStrNode(msg, accessExpr[1].info)
  strLit.typ = strType
  c.genLit(strLit, msgReg)
  let ma = c.getIntTemp()
  c.gABC(n, opcAddrSlot, ma, msgReg)
  # the discriminant's type renders its value, `k3` instead of `3`:
  c.gABCW(n, opcInvalidField, ma, discVal, 0, uint64(typeHandle(c, disc.sym.typ)))
  c.freeTemp(ma)
  c.freeTemp(discVal)
  c.freeTemp(msgReg)
  c.patch(lab1)
  result = fieldLoc(c, base, baseType(accessExpr[0]), accessExpr[1].sym)

proc genIndexLoc(c: PCtx; n: PNode; write: bool): Loc =
  result = default(Loc)
  let arrType = exprType(n[0]).skipTypes(abstractVarRange+{tyOwned}-{tyTypeDesc})
  case arrType.kind
  of tyTuple:
    result = genLoc(c, n[0])
    result.off += elemOffset(c.layouts, c.config, arrType, int n[1].intVal)
    result.typ = n.typ
    result.widened = false
    result.whole = false
  of tyArray:
    var base = genLoc(c, n[0])
    let a = addrOfLoc(c, n, base)
    let idx = genIndexReg(c, n[1], arrType)
    let t = c.getIntTemp()
    let len = toInt64(lengthOrd(c.config, arrType))
    c.gABCW(n, opcIdxArr, t, a, idx, packAddr(vmSize(c, arrType.elementType), int len))
    c.freeTemp(idx)
    c.freeLoc(base)
    result = memLoc(t, 0, n.typ, true)
  of tyString, tySequence:
    var base = genLoc(c, n[0])
    let a = addrOfLoc(c, n, base)
    if write and arrType.kind == tyString:
      # copy-on-write for string literals:
      c.gABC(n, opcMakeUnique, a)
    let idx = genIndexReg(c, n[1], arrType)
    let t = c.getIntTemp()
    let et = if arrType.kind == tyString: getSysType(c.graph, n.info, tyChar) else: arrType.elementType
    c.gABCW(n, opcIdxSeq, t, a, idx,
            packAddr(vmSize(c, et), payloadDataOffset(vmAlign(c, et))))
    c.freeTemp(idx)
    c.freeLoc(base)
    result = memLoc(t, 0, n.typ, true)
  of tyOpenArray, tyVarargs:
    var base = genLoc(c, n[0])
    let a = addrOfLoc(c, n, base)
    let idx = genIndexReg(c, n[1], arrType)
    let t = c.getIntTemp()
    c.gABCW(n, opcIdxOpenArr, t, a, idx, uint64(vmSize(c, arrType.elementType)))
    c.freeTemp(idx)
    c.freeLoc(base)
    result = memLoc(t, 0, n.typ, true)
  of tyCstring:
    let p = c.genx(n[0])
    let idx = genIndexReg(c, n[1], arrType)
    let t = c.getIntTemp()
    c.gABCW(n, opcIdxPtr, t, p, idx, 1'u64)
    c.freeTemp(idx)
    c.freeTemp(p)
    result = memLoc(t, 0, n.typ, true)
  of tyUncheckedArray:
    var base = genLoc(c, n[0])
    let a = addrOfLoc(c, n, base)
    let idx = genIndexReg(c, n[1], arrType)
    let t = c.getIntTemp()
    c.gABCW(n, opcIdxPtr, t, a, idx, uint64(vmSize(c, arrType.elementType)))
    c.freeTemp(idx)
    c.freeLoc(base)
    result = memLoc(t, 0, n.typ, true)
  of tyPtr, tyRef:
    # p[i] where p is a ptr to an array
    let x = newTreeIT(nkHiddenDeref, n[0].info, arrType.elementType, n[0])
    let y = newTreeIT(nkBracketExpr, n.info, n.typ, x, n[1])
    result = genIndexLoc(c, y, write)
  else:
    globalError(c.config, n.info, "VM: cannot index a value of type " & typeToString(n[0].typ))

proc reprIsSame(c: PCtx; a, b: PType): bool =
  ## true if values of the types `a` and `b` have the same representation
  let x = a.skipTypes(abstractRange+{tyOwned, tyStatic, tySink}-{tyTypeDesc})
  let y = b.skipTypes(abstractRange+{tyOwned, tyStatic, tySink}-{tyTypeDesc})
  if sameBackendType(x, y): return true
  if x.kind in {tyObject, tyRef, tyPtr, tyPointer, tyNil, tyVar, tyLent} and
     y.kind in {tyObject, tyRef, tyPtr, tyPointer, tyNil, tyVar, tyLent}:
    return true
  if x.kind == tyProc and y.kind == tyProc:
    return (x.callConv == ccClosure) == (y.callConv == ccClosure)
  let kx = mk(c, x)
  let ky = mk(c, y)
  result = kx != mkBlock and kx == ky and (kx in FloatMemKinds) == (ky in FloatMemKinds)

proc genLoc(c: PCtx; n: PNode; write = false): Loc =
  case n.kind
  of nkSym:
    let s = n.sym
    case s.kind
    of skVar, skForVar, skTemp, skLet, skResult:
      checkCanEval(c, n)
      result = symLoc(c, n)
    of skGenericParam:
      # the generic parameters of a macro are locals
      result = symLoc(c, n)
    of skParam:
      checkCanEval(c, n)
      if s.typ.kind == tyTypeDesc:
        result = genTempLoc(c, n)
      else:
        result = symLoc(c, n)
    of skConst:
      let value = if s.astdef != nil: s.astdef else: s.typ.n
      if isScalar(c, s.typ):
        result = genTempLoc(c, value)
        result.typ = s.typ
      else:
        let a = symConstAddress(c, s, value)
        result = memLoc(c.getIntTemp(), 0, s.typ, true)
        genLdImmAddr(c, n, result.reg, a)
    else:
      result = genTempLoc(c, n)
  of nkDotExpr:
    let base = objBaseLoc(c, n[0])
    result = fieldLoc(c, base, baseType(n[0]), genField(c, n[1]))
  of nkCheckedFieldExpr:
    result = genCheckedObjAccessAux(c, n)
  of nkBracketExpr:
    if isTypeExpr(n[0]):
      result = genTempLoc(c, n)
    else:
      result = genIndexLoc(c, n, write)
  of nkDerefExpr, nkHiddenDeref:
    result = derefLoc(c, n[0], n.typ)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    if n.typ != nil and n[1].typ != nil and reprIsSame(c, n.typ, n[1].typ):
      result = genLoc(c, n[1], write)
      result.typ = n.typ
    else:
      result = genTempLoc(c, n)
  of nkObjUpConv, nkObjDownConv:
    result = genLoc(c, n[0], write)
    result.typ = n.typ
  of nkCallKinds:
    if n[0].kind == nkSym and n[0].sym.magic == mAccessTypeField:
      # the type header of an object
      result = genLoc(c, n[1].skipAddr, write)
      result.typ = getSysType(c.graph, n.info, tyInt)
      result.widened = false
      result.whole = false
    else:
      result = genTempLoc(c, n)
  of nkStmtListExpr:
    for i in 0..<n.len-1: gen(c, n[i])
    result = genLoc(c, n[^1], write)
  of nkBlockExpr:
    if isLocationExpr(n[1]):
      withBlock(n[0].sym):
        result = genLoc(c, n[1], write)
    else:
      result = genTempLoc(c, n)
  else:
    result = genTempLoc(c, n)

proc usesNewRuntime(c: PCtx): bool =
  ## the VM injects destructors also for --mm:refc: strings and seqs are
  ## then managed like they are for --mm:orc, see `injectdestructors.hasDestructor`
  not defined(nimVmNoInject)

proc hasHooks(c: PCtx; t: PType): bool =
  ## mirrors `injectdestructors.genOp`: does the type have lifted hooks?
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  if not hasDestructor(t): return false
  var op = getAttachedOp(c.graph, t, attachedAsgn)
  if op == nil or op.ast.isGenericRoutine:
    let h = sighashes.hashType(t, c.config, {CoType, CoConsiderOwned, CoDistinct})
    let canon = c.graph.canonTypes.getOrDefault(h)
    if canon != nil: op = getAttachedOp(c.graph, canon, attachedAsgn)
  result = op != nil and not op.ast.isGenericRoutine

proc needsUnshare(c: PCtx; t: PType; value: PNode): bool =
  ## Without injected destructors (--mm:refc) the VM has to provide value
  ## semantics for strings and seqs itself: a copy of a location must not
  ## share payloads.
  ## The same holds for types without lifted hooks (types that are only used
  ## at compile time): the VM does not lift hooks for them, as that could
  ## conflict with hooks that are declared later.
  ## In code that went through injectdestructors a copy is a `=copy` call
  ## and an assignment of a type that it manages is a move.
  t != nil and not isScalar(c, t) and
    (not usesNewRuntime(c) or not hasHooks(c, t)) and
    isLocationExpr(value) and hasPayloads(t) and
    not (c.prc.injected and
         (hasDestructor(t) or optSeqDestructors notin c.config.globalOptions))

proc genStoreValue(c: PCtx; loc: var Loc; value: PNode) =
  ## evaluates `value` and stores it in `loc`. Frees `loc`.
  when defined(nimVmListing):
    if loc.typ != nil and not isScalar(c, loc.typ):
      echo "STORE ", typeToString(loc.typ), " unshare: ", needsUnshare(c, loc.typ, value),
        " hooks: ", hasHooks(c, loc.typ), " loc: ", isLocationExpr(value), " ", renderTree(value)
  if needsUnshare(c, loc.typ, value):
    let tmp = c.genx(value)
    var keep = loc
    keep.isTemp = false
    let a = addrOfLoc(c, value, keep)
    storeLoc(c, value, keep, tmp)
    c.gABCW(value, opcUnshare, a, 0, 0, uint64(typeHandle(c, loc.typ)))
    c.freeTemp(tmp)
    c.freeLoc(keep)
    c.freeLoc(loc)
  elif value.kind in nkStrKinds and loc.typ != nil and
      loc.typ.skipTypes(abstractInst).kind == tyString and value.strVal.len > 0:
    # a variable that is initialized with a string literal gets its own
    # payload: code like `var s = "abc"; s[0].addr[] = 'x'` relies on it.
    let tmp = c.genx(value)
    var keep = loc
    keep.isTemp = false
    let a = addrOfLoc(c, value, keep)
    storeLoc(c, value, keep, tmp)
    c.gABC(value, opcMakeUnique, a)
    c.freeTemp(tmp)
    c.freeLoc(keep)
    c.freeLoc(loc)
  elif loc.typ != nil and loc.typ.skipTypes(abstractInst).kind in {tyOpenArray, tyVarargs} and
      value.typ != nil and
      value.typ.skipTypes(abstractInst+{tySink}).kind notin {tyOpenArray, tyVarargs}:
    # e.g. an `openArray` field of an object constructor:
    var tmp: TDest = -1
    genOpenArrayConv(c, value, value, tmp)
    storeLoc(c, value, loc, TRegister(tmp))
    c.freeTemp(TRegister(tmp))
  elif loc.kind == lkFrame and loc.widened:
    gen(c, value, loc.reg)
    c.freeLoc(loc)
  elif not isScalar(c, loc.typ) and loc.kind == lkMem and isLocationExpr(value) and
      vmSize(c, loc.typ) > BoxThreshold:
    # big values are copied memory to memory:
    let size = vmSize(c, loc.typ)
    var src = genLoc(c, value)
    let sa = addrOfLoc(c, value, src)
    let da = addrOfLoc(c, value, loc)
    c.gABCW(value, opcCopyMem, da, sa, 0, uint64(size))
    c.freeLoc(src)
    c.freeLoc(loc)
  else:
    let tmp = c.genx(value)
    storeLoc(c, value, loc, tmp)
    c.freeTemp(tmp)

# ------------------------- assignments ---------------------------------------

proc genAsgn(c: PCtx; le, ri: PNode) =
  if le.kind in {nkHiddenStdConv, nkHiddenSubConv, nkConv} and
      not reprIsSame(c, le.typ, le[1].typ):
    genAsgn(c, le[1], ri)
    return
  var loc = genLoc(c, le, write = true)
  genStoreValue(c, loc, ri)

proc genVarSection(c: PCtx; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt: continue
    if a.kind == nkVarTuple:
      for i in 0..<a.len-2:
        if a[i].kind == nkSym:
          if not a[i].sym.isGlobal: discard setSlot(c, a[i].sym)
          checkCanEval(c, a[i])
      c.gen(lowerTupleUnpacking(c.graph, a, c.idgen, c.getOwner))
    elif a[0].kind == nkSym:
      let s = a[0].sym
      c.locals.incl(s.id)
      if s.isGlobal:
        let isNew = not c.globalAddrs.hasKey(s.itemId)
        if isNew:
          let ga = allocGlobal(c.mem, vmSize(c, s.typ), vmAlign(c, s.typ))
          c.globalAddrs[s.itemId] = ga
        let runtimeAccessToCompileTime = c.mode == emRepl and
              sfCompileTime in s.flags and not isNew
        if runtimeAccessToCompileTime or importcCondVar(s):
          discard
        elif sfPure in s.flags:
          # a `{.global.}` variable inside a proc: it is initialized only once.
          # (`injectDestructorCalls` moves its initializer out of the
          # var section for the backend; we use `astdef` then.)
          let init = if a[2].kind != nkEmpty: a[2]
                     elif s.astdef != nil and s.astdef.kind != nkEmpty: s.astdef
                     else: nil
          if init != nil:
            let flag = allocGlobal(c.mem, 8, 8)
            let t = c.getIntTemp()
            let f = c.getIntTemp()
            genLdImmAddr(c, a, t, flag)
            c.gABC(a, opcLd64, f, t, 0)
            let skip = c.xjmp(a, opcTJmp, f)
            c.gABx(a, opcLdImmInt, f, 1)
            c.gABC(a, opcSt64, t, 0, f)
            var loc = memLoc(c.getIntTemp(), 0, s.typ, true)
            genLdImmAddr(c, a, loc.reg, c.globalAddrs[s.itemId])
            genStoreValue(c, loc, init)
            c.patch(skip)
            c.freeTemp(f)
            c.freeTemp(t)
        else:
          var loc = memLoc(c.getIntTemp(), 0, s.typ, true)
          genLdImmAddr(c, a, loc.reg, c.globalAddrs[s.itemId])
          if a[2].kind == nkEmpty:
            zeroLoc(c, a, loc)
          else:
            genStoreValue(c, loc, a[2])
      else:
        discard setSlot(c, s, a)
        var loc = symLoc(c, a[0])
        if a[2].kind == nkEmpty:
          zeroLoc(c, a, loc)
        else:
          genStoreValue(c, loc, a[2])
    else:
      # assign to a[0]; happens for closures
      if a[2].kind == nkEmpty:
        var loc = genLoc(c, a[0])
        zeroLoc(c, a, loc)
      else:
        genAsgn(c, a[0], a[2])

# ------------------------- control flow --------------------------------------

proc isNotOpr(n: PNode): bool =
  n.kind in nkCallKinds and n[0].kind == nkSym and
    n[0].sym.magic == mNot

proc genWhile(c: PCtx; n: PNode) =
  # lab1:
  #   cond, tmp
  #   fjmp tmp, lab2
  #   body
  #   jmp lab1
  # lab2:
  let lab1 = c.genLabel
  withBlock(nil):
    if isTrue(n[0]):
      c.gen(n[1])
      c.jmpBack(n, lab1)
    elif isNotOpr(n[0]):
      var tmp = c.genx(n[0][1])
      let lab2 = c.xjmp(n, opcTJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n[1])
      c.jmpBack(n, lab1)
      c.patch(lab2)
    else:
      var tmp = c.genx(n[0])
      let lab2 = c.xjmp(n, opcFJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n[1])
      c.jmpBack(n, lab1)
      c.patch(lab2)

proc genBlock(c: PCtx; n: PNode; dest: var TDest) =
  let oldRegisterCount = c.prc.regInfo.len
  withBlock(n[0].sym):
    c.gen(n[1], dest)

  # the locals of the block are dead now:
  let keepFrom = if dest >= 0: int(dest) else: high(int)
  let keepTo = if dest >= 0: int(dest) + slotsOf(c, n.typ) - 1 else: -1
  for i in oldRegisterCount..<c.prc.regInfo.len:
    if (i < keepFrom or i > keepTo) and not c.prc.regInfo[i].isTemp:
      c.prc.regInfo[i] = SlotUse()

  c.clearDest(n, dest)

proc leaveTries(c: PCtx; n: PNode; tryDepth: int) =
  ## `break` leaves `try` statements: their safepoints are popped and their
  ## `finally` sections run, innermost first.
  var tries = c.prc.tries # `var`: `let` would alias the seq under `--mm:refc`
  for j in countdown(tries.high, tryDepth):
    if tries[j].hasSafePoint:
      c.gABx(n, opcFinally, 0, 0)
    if tries[j].fin != nil and tries[j].fin.kind == nkFinally:
      # a `break` within the finally section leaves only the outer tries:
      c.prc.tries.setLen j
      c.gen(tries[j].fin[0])
      c.prc.tries = tries

proc genBreak(c: PCtx; n: PNode) =
  var target = c.prc.blocks.high
  if n[0].kind == nkSym:
    target = -1
    for i in countdown(c.prc.blocks.len-1, 0):
      if c.prc.blocks[i].label == n[0].sym:
        target = i
        break
    if target < 0:
      globalError(c.config, n.info, "VM problem: cannot find 'break' target")
  leaveTries(c, n, c.prc.blocks[target].tryDepth)
  let lab1 = c.xjmp(n, opcJmp)
  c.prc.blocks[target].fixups.add lab1

proc genIf(c: PCtx, n: PNode; dest: var TDest) =
  #  if (!expr1) goto lab1;
  #    thenPart
  #    goto LEnd
  #  lab1:
  #  if (!expr2) goto lab2;
  #    thenPart2
  #    goto LEnd
  #  lab2:
  #    elsePart
  #  Lend:
  if dest < 0 and not isEmptyType(n.typ): dest = getTemp(c, n.typ)
  var endings: seq[TPosition] = @[]
  for i in 0..<n.len:
    var it = n[i]
    if it.len == 2:
      var elsePos: TPosition
      if isNotOpr(it[0]):
        let tmp = c.genx(it[0][1])
        elsePos = c.xjmp(it[0][1], opcTJmp, tmp) # if true
        c.freeTemp(tmp)
      else:
        let tmp = c.genx(it[0])
        elsePos = c.xjmp(it[0], opcFJmp, tmp) # if false
        c.freeTemp(tmp)
      c.clearDest(n, dest)
      if isEmptyType(it[1].typ): # maybe noreturn call, don't touch `dest`
        c.gen(it[1])
      else:
        c.gen(it[1], dest) # then part
      if i < n.len-1:
        endings.add(c.xjmp(it[1], opcJmp, 0))
      c.patch(elsePos)
    else:
      c.clearDest(n, dest)
      if isEmptyType(it[0].typ): # maybe noreturn call, don't touch `dest`
        c.gen(it[0])
      else:
        c.gen(it[0], dest)
  for endPos in endings: c.patch(endPos)
  c.clearDest(n, dest)

proc genAndOr(c: PCtx; n: PNode; opc: TOpcode; dest: var TDest) =
  #   asgn dest, a
  #   tjmp|fjmp lab1
  #   asgn dest, b
  # lab1:
  let copyBack = dest < 0 or not isTemp(c, dest)
  let tmp = if copyBack:
              getTemp(c, n.typ)
            else:
              TRegister dest
  c.gen(n[1], tmp)
  let lab1 = c.xjmp(n, opc, tmp)
  c.gen(n[2], tmp)
  c.patch(lab1)
  if dest < 0:
    dest = tmp
  elif copyBack:
    c.gABC(n, opcMov, dest, tmp)
    freeTemp(c, tmp)

proc ordLabel(c: PCtx; n: PNode): BiggestInt =
  case n.kind
  of nkCharLit..nkUInt64Lit: n.intVal
  of nkSym:
    if n.sym.kind == skEnumField: BiggestInt(n.sym.position)
    else: getOrdValue(n).toInt64
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: ordLabel(c, n[1])
  else: getOrdValue(n).toInt64

proc genCaseBody(c: PCtx; n, body: PNode; dest: var TDest) =
  if isEmptyType(body.typ): # maybe noreturn call, don't touch `dest`
    c.gen(body)
  else:
    c.gen(body, dest)

proc genCase(c: PCtx; n: PNode; dest: var TDest) =
  if not isEmptyType(n.typ):
    if dest < 0: dest = getTemp(c, n.typ)
  else:
    unused(c, n, dest)
  var endings: seq[TPosition] = @[]
  let selType = n[0].typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc})
  let isOrdinal = selType.kind notin {tyString, tyCstring, tyFloat..tyFloat128}
  let sel = c.genx(n[0])
  for i in 1..<n.len:
    let it = n[i]
    if it.len == 1:
      # else stmt:
      let body = it[0]
      if body.kind != nkNilLit or body.typ != nil:
        # an nkNilLit with nil for typ implies there is no else branch, this
        # avoids unused related errors as we've already consumed the dest
        genCaseBody(c, n, body, dest)
    elif isOrdinal:
      var table: seq[(BiggestInt, BiggestInt)] = @[]
      for j in 0..<it.len-1:
        let lab = it[j]
        if lab.kind == nkRange:
          table.add (ordLabel(c, lab[0]), ordLabel(c, lab[1]))
        else:
          let v = ordLabel(c, lab)
          table.add (v, v)
      c.branchTables.add table
      c.gABx(it, opcBranch, sel, c.branchTables.len-1)
      let body = it.lastSon
      let elsePos = c.xjmp(body, opcFJmp, sel)
      genCaseBody(c, n, body, dest)
      if i < n.len-1:
        endings.add(c.xjmp(body, opcJmp, 0))
      c.patch(elsePos)
    else:
      var bodyJumps: seq[TPosition] = @[]
      let cond = c.getIntTemp()
      for j in 0..<it.len-1:
        let lab = it[j]
        case selType.kind
        of tyString:
          let lit = c.genx(lab)
          let a = c.getIntTemp()
          let b = c.getIntTemp()
          c.gABC(lab, opcAddrSlot, a, sel)
          c.gABC(lab, opcAddrSlot, b, lit)
          c.gABC(lab, opcStrEq, cond, a, b)
          c.freeTemp(b)
          c.freeTemp(a)
          c.freeTemp(lit)
        of tyCstring:
          let lit = c.genx(lab)
          c.gABC(lab, opcCStrEq, cond, sel, lit)
          c.freeTemp(lit)
        else:
          if lab.kind == nkRange:
            let lo = c.genx(lab[0])
            let hi = c.genx(lab[1])
            let tmp = c.getIntTemp()
            c.gABC(lab, opcLeFloat, cond, lo, sel)
            c.gABC(lab, opcLeFloat, tmp, sel, hi)
            c.gABC(lab, opcBitandInt, cond, cond, tmp)
            c.freeTemp(tmp)
            c.freeTemp(hi)
            c.freeTemp(lo)
          else:
            let lit = c.genx(lab)
            c.gABC(lab, opcEqFloat, cond, sel, lit)
            c.freeTemp(lit)
        bodyJumps.add c.xjmp(lab, opcTJmp, cond)
      c.freeTemp(cond)
      let nextBranch = c.xjmp(it, opcJmp, 0)
      for j in bodyJumps: c.patch(j)
      let body = it.lastSon
      genCaseBody(c, n, body, dest)
      if i < n.len-1:
        endings.add(c.xjmp(body, opcJmp, 0))
      c.patch(nextBranch)
    c.clearDest(n, dest)
  c.freeTemp(sel)
  for endPos in endings: c.patch(endPos)

proc genTry(c: PCtx; n: PNode; dest: var TDest) =
  let typ = valueType(n)
  template clearTryDest() =
    if dest >= 0 and (typ.isNil or typ.kind == tyVoid):
      c.freeTemp(dest)
      dest = -1
  if dest < 0 and not isEmptyType(typ): dest = getTemp(c, typ)
  var endings: seq[TPosition] = @[]
  let fin = lastSon(n)
  let finNode = if fin.kind == nkFinally: fin else: nil
  let ehPos = c.xjmp(n, opcTry, 0)
  c.prc.tries.add TryInfo(fin: finNode, hasSafePoint: true)
  if isEmptyType(valueType(n[0])): # maybe noreturn call, don't touch `dest`
    c.gen(n[0])
  else:
    c.gen(n[0], dest)
  c.prc.tries.setLen c.prc.tries.len-1
  clearTryDest()
  # Add a jump past the exception handling code
  let jumpToFinally = c.xjmp(n, opcJmp, 0)
  # This signals where the body ends and where the exception handling begins
  c.patch(ehPos)
  for i in 1..<n.len:
    let it = n[i]
    if it.kind != nkFinally:
      # first opcExcept contains the end label of the 'except' block:
      let endExcept = c.xjmp(it, opcExcept, 0)
      for j in 0..<it.len - 1:
        assert(it[j].kind == nkType)
        let typ = it[j].typ.skipTypes(abstractPtrs-{tyTypeDesc})
        c.gABx(it, opcExcept, 0, c.typeHandle(typ))
      if it.len == 1:
        # general except section:
        c.gABx(it, opcExcept, 0, 0)
      let body = it.lastSon
      # the safepoint is gone within an except section, but `finally` has
      # to run when we `break` out of it:
      c.prc.tries.add TryInfo(fin: finNode, hasSafePoint: false)
      if isEmptyType(body.typ): # maybe noreturn call, don't touch `dest`
        c.gen(body)
      else:
        c.gen(body, dest)
      c.prc.tries.setLen c.prc.tries.len-1
      clearTryDest()
      if i < n.len:
        endings.add(c.xjmp(it, opcJmp, 0))
      c.patch(endExcept)
  # we always generate an 'opcFinally' as that pops the safepoint
  # from the stack if no exception is raised in the body.
  c.patch(jumpToFinally)
  c.gABx(fin, opcFinally, 0, 0)
  for endPos in endings: c.patch(endPos)
  if fin.kind == nkFinally:
    c.gen(fin[0])
    clearTryDest()
  c.gABx(fin, opcFinallyEnd, 0, 0)

proc genRaise(c: PCtx; n: PNode) =
  if n[0].kind == nkEmpty:
    let t = c.getIntTemp()
    c.gABx(n, opcLdImmInt, t, 0)
    c.gABC(n, opcRaise, t)
    c.freeTemp(t)
  else:
    let dest = genx(c, n[0])
    c.gABC(n, opcRaise, dest)
    c.freeTemp(dest)

proc genRet(c: PCtx; n: PNode) =
  if c.prc.hasResult and c.prc.resultInfo.inMemory:
    # the caller expects a widened scalar:
    let k = mk(c, c.prc.sym.typ.returnType)
    c.genLdSlot(n, c.prc.resultInfo.slot, c.prc.resultInfo.slot, k)
  c.gABC(n, opcRet)

proc genReturn(c: PCtx; n: PNode) =
  if n[0].kind != nkEmpty:
    gen(c, n[0])
  genRet(c, n)

# ------------------------- calls ---------------------------------------------

type
  CallLayout = object
    resultSlots: int
    paramOffsets: seq[int]  # slot offset of each parameter, relative to the first one
    paramTypes: seq[PType]
    paramSlots: int
    isClosure: bool

proc callLayout(c: PCtx; fnType: PType; isMacro: bool; info: TLineInfo;
                isTemplate = false): CallLayout =
  let t = fnType.skipTypes(abstractInst)
  result = CallLayout(isClosure: t.callConv == ccClosure)
  let ret = t.returnType
  if isMacro or isTemplate:
    # macros and templates (getAst) always produce a NimNode
    result.resultSlots = 1
  elif ret != nil and not isEmptyType(ret):
    result.resultSlots = slotsOf(c, ret.skipTypes({tyTypeDesc}))
  var off = 0
  for i in FirstParamAt..<t.signatureLen:
    var pt = t[i]
    if isMacro: pt = macroParamType(c, pt, info)
    result.paramOffsets.add off
    result.paramTypes.add pt
    off += slotsOf(c, pt)
  result.paramSlots = off

proc genCallShape(c: PCtx; L: CallLayout; resultType: PType): CallShape =
  result = CallShape(resultType: resultType, resultSlots: L.resultSlots)
  for i in 0..<L.paramOffsets.len:
    result.paramOffsets.add L.paramOffsets[i] * SlotSize
    result.paramTypes.add L.paramTypes[i]

proc callShapeOf*(c: PCtx; s: PSym): CallShape =
  ## where the arguments and the result of a call of `s` are, relative to
  ## the call area; used for callbacks and templates.
  result = c.procShapes.getOrDefault(s.itemId)
  if result.paramTypes.len == 0 and result.resultType == nil:
    let L = callLayout(c, s.typ, s.kind in {skMacro, skTemplate}, s.info, s.kind == skTemplate)
    let ret = s.typ.returnType
    result = genCallShape(c, L, if ret != nil and not isEmptyType(ret): ret else: nil)
    c.procShapes[s.itemId] = result

proc toKey(s: PSym): string =
  result = ""
  var s = s
  while s != nil:
    result.add s.name.s
    if s.owner != nil:
      if sfFromGeneric in s.flags and s.instantiatedFrom != nil:
        s = s.instantiatedFrom.owner
      else:
        s = s.owner
      result.add "."
    else:
      break

proc procIsCallback(c: PCtx; s: PSym): bool =
  if s.offset < -1: return true
  let key = toKey(s)
  if c.callbackIndex.contains(key):
    let index = c.callbackIndex[key]
    doAssert s.offset == -1
    s.offset = -2'i32 - index.int32
    result = true
  else:
    result = false

proc isSystemSym(c: PCtx; s: PSym): bool =
  let m = getModule(s)
  result = m != nil and (sfSystemModule in m.flags or m.name.s == "system")

proc builtinOf(c: PCtx; s: PSym): VmBuiltin =
  result = vbNone
  if s.kind in routineKinds and (sfCompilerProc in s.flags or isSystemSym(c, s) or
      sfImportc in s.flags):
    for (name, b) in builtinNames:
      if s.name.s == name: return b

proc genVarOpenArrayArg(c: PCtx; n, x: PNode; dest: var TDest)

proc genArgInto(c: PCtx; arg: PNode; pt: PType; slot: TRegister; isMacro: bool) =
  let ptk = pt.skipTypes(abstractInst+{tySink})
  if ptk.kind in {tyOpenArray, tyVarargs} and arg.typ != nil and
      arg.typ.skipTypes(abstractInst+{tySink}).kind notin {tyOpenArray, tyVarargs}:
    # an implicit conversion to openArray
    var d = TDest(slot)
    genOpenArrayConv(c, arg, arg, d)
  elif ptk.kind in {tyVar, tyLent} and
      ptk.elementType.skipTypes(abstractInst).kind in {tyOpenArray, tyVarargs} and
      arg.typ != nil and arg.kind notin {nkHiddenAddr, nkAddr} and
      arg.typ.skipTypes(abstractInst+{tyVar, tyLent}).kind notin {tyOpenArray, tyVarargs}:
    # `var openArray` parameter, passed a `var array/seq/string`
    var d = TDest(slot)
    genVarOpenArrayArg(c, arg, arg, d)
  elif isMacro and pt.kind != tyTypeDesc and isScalar(c, pt) and mk(c, pt) == mkNode and
      (arg.typ == nil or isEmptyType(arg.typ) or arg.typ.kind in {tyUntyped, tyTyped} or
       arg.typ.isCompileTimeOnly) and
      not (arg.kind == nkSym and arg.sym.kind in {skParam, skGenericParam, skVar,
                                                   skLet, skTemp, skResult, skForVar}):
    # a macro or template called with an AST
    var d = TDest(slot)
    genNodeLit(c, arg, arg, d)
  elif isMacro and pt.kind != tyTypeDesc and isScalar(c, pt) and mk(c, pt) == mkNode and
      mk(c, arg.typ) != mkNode:
    # a value is passed to a NimNode parameter of a macro or template: it
    # becomes a literal
    let v = c.genx(arg)
    c.gABCW(arg, opcToNode, slot, v, 0, uint64(typeHandle(c, arg.typ)))
    c.freeTemp(v)
  elif isMacro and pt.kind != tyTypeDesc and mk(c, pt) != mkNode and
      arg.typ != nil and isNimNodeType(arg.typ.skipTypes(abstractInst)):
    # `getAst(m(x))` with an AST `x` for a `static` parameter of `m`: the
    # literal becomes a value
    let v = c.genx(arg)
    c.gABCW(arg, opcFromNode, slot, v, 0, uint64(typeHandle(c, pt)))
    c.freeTemp(v)
  elif arg.kind == nkCurly and arg.len == 0 and ptk.kind == tySet:
    # `{}` can still have the type `set[empty]`; it gets the parameter's:
    let a = copyNode(arg)
    a.typ = ptk
    gen(c, a, slot)
  else:
    gen(c, arg, slot)

proc genBuiltin(c: PCtx; n: PNode; b: VmBuiltin; dest: var TDest) =
  template arg(i): untyped = c.genx(n[i])
  case b
  of vbAlloc, vbAlignedAlloc:
    let size = arg(1)
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcAlloc, dest, size)
    c.freeTemp(size)
  of vbDealloc:
    let p = arg(1)
    c.gABC(n, opcDealloc, p)
    c.freeTemp(p)
  of vbRealloc:
    let p = arg(1)
    let size = arg(2)
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcRealloc, dest, p, size)
    c.freeTemp(size)
    c.freeTemp(p)
  of vbCopyMem:
    let d = arg(1)
    let s = arg(2)
    let size = arg(3)
    c.gABC(n, opcMemMove, d, s, size)
    c.freeTemp(size)
    c.freeTemp(s)
    c.freeTemp(d)
    if dest >= 0 or not isEmptyType(n.typ):
      # c_memcpy returns dest
      if dest < 0: dest = c.getIntTemp()
      c.gABC(n, opcMov, dest, d)
  of vbZeroMem:
    let p = arg(1)
    let size = arg(2)
    c.gABC(n, opcMemZero, p, size)
    c.freeTemp(size)
    c.freeTemp(p)
  of vbEqualMem, vbCmpMem:
    let area = c.getTempN(3)
    for i in 1..3: c.gen(n[i], TRegister(area+i-1))
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcMemCmp, dest, area)
    c.freeTemp(area)
    if b == vbEqualMem:
      let z = c.getIntTemp()
      c.gABx(n, opcLdImmInt, z, 0)
      c.gABC(n, opcEqInt, dest, dest, z)
      c.freeTemp(z)
  of vbIncRef:
    let p = arg(1)
    c.gABC(n, opcIncRef, p)
    c.freeTemp(p)
  of vbDecRefIsLast:
    let p = arg(1)
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcDecRefIsLast, dest, p)
    c.freeTemp(p)
  of vbRawDispose:
    let p = arg(1)
    let al = arg(2)
    c.gABC(n, opcDisposeRef, p, al)
    c.freeTemp(al)
    c.freeTemp(p)
  of vbDestroyAndDispose:
    # calls the destructor of the dynamic type, then frees the cell:
    let p = arg(1)
    c.gABC(n, opcDynDestructor, p, p)
    c.freeTemp(p)
  of vbNop:
    discard
  of vbAsgnStr:
    # nimAsgnStrV2(var string, string)
    let d = arg(1)
    var src = genValueAddr(c, n[2])
    c.gABC(n, opcStrAsgn, d, src.reg)
    c.freeLoc(src)
    c.freeTemp(d)
  of vbSameSeqPayload:
    let a = arg(1)
    let b = arg(2)
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcSamePayload, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of vbCopySeqPayload:
    # nimCopySeqPayload(addr dest, addr src, elemSize, elemAlign)
    let area = c.getTempN(4)
    for i in 1..4: c.gen(n[i], TRegister(area+i-1))
    c.gABC(n, opcSeqCopyPayload, area, TRegister(area+1), TRegister(area+2))
    c.gW(n, 0)
    c.freeTemp(area)
  of vbNone:
    discard

when hasFFI:
  proc isFfiCall(c: PCtx; s: PSym): bool =
    s.kind in routineKinds and compiletimeFFI in c.config.features and
      importcCond(c, s) and not procIsCallback(c, s)

  proc genFfiCall(c: PCtx; n: PNode; dest: var TDest) =
    ## a call of an imported proc: the arguments are laid out one after
    ## another, C varargs use the types of the arguments.
    let s = n[0].sym
    let fntyp = s.typ.skipTypes(abstractInst)
    let fixed = fntyp.signatureLen - FirstParamAt
    var args: seq[FfiArg] = @[]
    var types: seq[PType] = @[]
    var off = 1 # slot 0 is the result
    for i in 1..<n.len:
      let pt = if i-1 < fixed: fntyp[i-1+FirstParamAt] else: n[i].typ
      var a = ffiArgKind(c.config, pt, n[i].info)
      a.offset = off * SlotSize
      args.add a
      types.add pt
      off += slotsOf(c, pt)
    let site = c.ffiSites.len
    c.ffiSites.add initFfiSite(c.config, s, args, min(fixed, n.len-1), n.info)
    let area = c.getTempN(off)
    for i in 1..<n.len:
      genArgInto(c, n[i], types[i-1], TRegister(area + args[i-1].offset div SlotSize), false)
    c.gABCW(n, opcFfiCall, 0, area, 0, uint64(site))
    if n.typ != nil and not isEmptyType(n.typ):
      if dest < 0: dest = c.getTemp(n.typ)
      c.gABC(n, opcMov, dest, area)
    c.freeTemp(area)

proc genCall(c: PCtx; n: PNode; dest: var TDest) =
  # bug #10901: do not produce code for wrong call expressions:
  if n.len == 0 or n[0].typ.isNil: return
  if n[0].kind == nkSym:
    let b = builtinOf(c, n[0].sym)
    if b != vbNone:
      genBuiltin(c, n, b, dest)
      return
    when hasFFI:
      if isFfiCall(c, n[0].sym):
        genFfiCall(c, n, dest)
        return
  # for a direct call the callee's own signature determines the layout of
  # its frame (`n[0].typ` can be less precise for generic instances):
  let fntyp = if n[0].kind == nkSym and n[0].sym.kind in routineKinds and n[0].sym.typ != nil:
                skipTypes(n[0].sym.typ, abstractInst)
              else: skipTypes(n[0].typ, abstractInst)
  when defined(nimVmListing):
    if n[0].kind == nkSym:
      echo "CALL ", n[0].sym.name.s, " magic: ", n[0].sym.magic, " ", renderTree(n),
        " from: ", (if n[0].sym.instantiatedFrom != nil: $n[0].sym.instantiatedFrom.magic & " " & n[0].sym.instantiatedFrom.name.s else: "nil"),
        " flags: ", n[0].sym.flags
  let isMacro = n[0].kind == nkSym and n[0].sym.kind == skMacro
  let isTemplate = n[0].kind == nkSym and n[0].sym.kind == skTemplate
  let L = callLayout(c, fntyp, isMacro or isTemplate, n.info, isTemplate)
  let area = c.getTempN(2 + L.resultSlots + L.paramSlots)
  # the callee:
  if n[0].kind == nkSym and n[0].sym.kind in routineKinds:
    let s = n[0].sym
    if not procIsCallback(c, s): checkProcSym(c, n[0], s)
    genLdImmAddr(c, n[0], area, procAddress(c.mem, s))
    c.gABx(n[0], opcLdImmInt, TRegister(area+1), 0)
  else:
    let f = c.genx(n[0])
    c.gABC(n[0], opcMov, area, f)
    if fntyp.callConv == ccClosure:
      c.gABC(n[0], opcMov, TRegister(area+1), TRegister(f+1))
    else:
      c.gABx(n[0], opcLdImmInt, TRegister(area+1), 0)
    c.freeTemp(f)
  let firstParam = area + 2 + L.resultSlots
  for i in 1..<n.len:
    if i-1 < L.paramOffsets.len:
      genArgInto(c, n[i], L.paramTypes[i-1],
                 TRegister(firstParam + L.paramOffsets[i-1]), isMacro or isTemplate)
    else:
      globalError(c.config, n.info, "VM: cannot pass varargs to an importc'ed proc")
  c.gABC(n, opcIndCall, 0, area, TRegister(L.resultSlots + L.paramSlots))
  if L.resultSlots > 0 and ((n.typ != nil and not isEmptyType(n.typ)) or isTemplate or isMacro):
    if dest < 0: dest = c.getTemp(n.typ)
    let k = if isTemplate or isMacro: 1 else: slotsOf(c, n.typ)
    if k == 1: c.gABC(n, opcMov, dest, TRegister(area+2))
    else: c.gABC(n, opcMovN, dest, TRegister(area+2), TRegister(k))
  c.freeTemp(area)

proc genHookCall(c: PCtx; n: PNode; op: PSym; objAddr: TRegister; objType: PType) =
  ## calls the hook `op` (like `=destroy`) for the value at `objAddr`
  let L = callLayout(c, op.typ, false, n.info)
  let area = c.getTempN(2 + L.resultSlots + L.paramSlots)
  genLdImmAddr(c, n, area, procAddress(c.mem, op))
  c.gABx(n, opcLdImmInt, TRegister(area+1), 0)
  let p = TRegister(area + 2 + L.resultSlots)
  let pt = op.typ.firstParamType
  if pt.skipTypes(abstractInst).kind in {tyVar, tyLent}:
    c.gABC(n, opcMov, p, objAddr)
  else:
    var loc = memLoc(objAddr, 0, objType, false)
    var d = TDest(p)
    loadLoc(c, n, loc, d)
  c.gABC(n, opcIndCall, 0, area, TRegister(L.resultSlots + L.paramSlots))
  c.freeTemp(area)

# ------------------------- constructors --------------------------------------

proc genObjConstr(c: PCtx, n: PNode, dest: var TDest) =
  let t = n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc})
  if t.kind == tyRef:
    let objType = t.elementType.skipTypes(abstractInst+{tyOwned})
    if dest < 0: dest = c.getIntTemp()
    c.gABCW(n, opcNewRef, dest, 0, 0, packAddr(vmSize(c, objType), vmAlign(c, objType)))
    if needsInitObj(c, objType):
      c.gABCW(n, opcInitObj, dest, 0, 0, uint64(typeHandle(c, objType)))
    for i in 1..<n.len:
      let it = n[i]
      if nfPreventCg in it.flags:
        discard
      elif it.kind == nkExprColonExpr and it[0].kind == nkSym:
        var loc = fieldLoc(c, memLoc(dest, 0, objType, false), objType, it[0].sym)
        genStoreValue(c, loc, it[1])
      else:
        globalError(c.config, n.info, "invalid object constructor")
  else:
    # construct into a fresh temporary so that `x = Obj(a: x.b)` works:
    let target = if c.isTemp(dest): TRegister(dest) else: c.getTemp(n.typ)
    var whole = frameLoc(target, n.typ, false, true, false)
    zeroLoc(c, n, whole)
    for i in 1..<n.len:
      let it = n[i]
      if nfPreventCg in it.flags:
        # a field of an inactive branch
        discard
      elif it.kind == nkExprColonExpr and it[0].kind == nkSym:
        var loc = fieldLoc(c, frameLoc(target, n.typ, false, true, false), t, it[0].sym)
        genStoreValue(c, loc, it[1])
      else:
        globalError(c.config, n.info, "invalid object constructor")
    if dest < 0:
      dest = target
    elif dest != target:
      c.gABC(n, opcMovN, dest, target, TRegister(slotsOf(c, n.typ)))
      c.freeTemp(target)

proc genClosureConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  let fn = n[0]
  if fn.kind == nkSym:
    checkProcSym(c, fn, fn.sym)
    genLdImmAddr(c, fn, dest, procAddress(c.mem, fn.sym))
  else:
    gen(c, fn, dest)
  if n[1].kind == nkNilLit:
    c.gABx(n, opcLdImmInt, TRegister(dest+1), 0)
  else:
    gen(c, n[1], TRegister(dest+1))

proc genTupleConstr(c: PCtx, n: PNode, dest: var TDest) =
  let t = n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc})
  if t.kind == tyTypeDesc:
    genTypeLit(c, n, n.typ, dest)
    return
  if t.kind == tyProc:
    genClosureConstr(c, n, dest)
    return
  let target = if c.isTemp(dest): TRegister(dest) else: c.getTemp(n.typ)
  if t.kind == tyObject:
    # an object constructor in tuple syntax (from a default value)
    var whole = frameLoc(target, n.typ, false, true, false)
    zeroLoc(c, n, whole)
  else:
    c.gABC(n, opcZeroN, target, TRegister(slotsOf(c, n.typ)))
  for i in 0..<n.len:
    let it = n[i]
    if nfPreventCg in it.flags: continue
    let (idx, value) = if it.kind == nkExprColonExpr: (it[0].sym.position, it[1])
                       else: (i, it)
    var loc = frameLoc(target, n.typ, false, true, false)
    loc.off = elemOffset(c.layouts, c.config, t, idx)
    loc.typ = t[idx]
    loc.whole = false
    genStoreValue(c, loc, value)
  if dest < 0:
    dest = target
  elif dest != target:
    c.gABC(n, opcMovN, dest, target, TRegister(slotsOf(c, n.typ)))
    c.freeTemp(target)

proc seqW(c: PCtx; elemType: PType): uint64 =
  packAddr(vmSize(c, elemType), vmAlign(c, elemType))

proc genSeqConstrFrom(c: PCtx; n: PNode; seqType: PType; dest: var TDest) =
  ## a seq constructor from the elements of the nkBracket `n`
  let elemType = seqType.skipTypes(abstractInst).elementType
  if dest < 0: dest = c.getTemp(seqType)
  # evaluate the elements before the seq is created:
  var vals: seq[TRegister] = @[]
  for x in n: vals.add c.genx(x)
  let a = c.getIntTemp()
  let len = c.getIntTemp()
  c.gABC(n, opcZeroN, dest, 2)
  c.gABC(n, opcAddrSlot, a, dest)
  genLdImm(c, n, len, n.len)
  c.gABCW(n, opcSeqNew, a, len, 0, seqW(c, elemType))
  if n.len > 0:
    let data = c.getIntTemp()
    c.gABCW(n, opcSeqData, data, a, 0, uint64(payloadDataOffset(vmAlign(c, elemType))))
    let esize = vmSize(c, elemType)
    for i in 0..<n.len:
      var loc = memLoc(data, i*esize, elemType, false)
      storeLoc(c, n[i], loc, vals[i])
    c.freeTemp(data)
  for v in vals: c.freeTemp(v)
  c.freeTemp(len)
  c.freeTemp(a)

proc genArrayConstrInto(c: PCtx, n: PNode; arrType: PType; target: TRegister) =
  let elemType = arrType.skipTypes(abstractInst).elementType
  let esize = vmSize(c, elemType)
  var whole = frameLoc(target, arrType, false, true, false)
  zeroLoc(c, n, whole)
  for i in 0..<n.len:
    var loc = frameLoc(target, elemType, false, false, false)
    loc.off = i*esize
    genStoreValue(c, loc, n[i])

proc genOpenArrayFromBracket(c: PCtx; n: PNode; dest: var TDest) =
  ## builds an array in the frame and an openArray that refers to it
  let elemType = n.typ.skipTypes(abstractInst).elementType
  let esize = vmSize(c, elemType)
  let storage = c.getTempN(max(slotsFor(esize * n.len), 1))
  # the storage must outlive the openArray; we don't free it.
  c.prc.regInfo[storage].isTemp = false
  let arrType = newType(tyArray, c.idgen, getOwner(c))
  genArrayConstrInto(c, n, n.typ, storage)
  if dest < 0: dest = c.getTempN(2)
  c.gABC(n, opcAddrSlot, dest, storage)
  genLdImm(c, n, TRegister(dest+1), n.len)
  discard arrType

proc genArrayConstr(c: PCtx, n: PNode, dest: var TDest) =
  let t = n.typ.skipTypes(abstractVar+{tyStatic}-{tyTypeDesc})
  case t.kind
  of tySequence:
    genSeqConstrFrom(c, n, n.typ, dest)
  of tyOpenArray, tyVarargs:
    genOpenArrayFromBracket(c, n, dest)
  else:
    if isDeepConstExpr(n) and n.len > 0:
      genLit(c, n, dest)
      return
    let target = if c.isTemp(dest): TRegister(dest) else: c.getTemp(n.typ)
    genArrayConstrInto(c, n, n.typ, target)
    if dest < 0:
      dest = target
    elif dest != target:
      c.gABC(n, opcMovN, dest, target, TRegister(slotsOf(c, n.typ)))
      c.freeTemp(target)

proc genSetConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  let big = isBigSet(c, n.typ)
  if big:
    c.gABC(n, opcZeroN, dest, TRegister(slotsOf(c, n.typ)))
  else:
    c.gABx(n, opcLdImmInt, dest, 0)
  let size = vmSize(c, n.typ)
  var a: TRegister = 0
  if big:
    a = c.getIntTemp()
    c.gABC(n, opcAddrSlot, a, dest)
  for x in n:
    if x.kind == nkRange:
      let lo = genSetElem(c, x[0], n.typ)
      let hi = genSetElem(c, x[1], n.typ)
      if big: c.gABCW(n, opcBSetInclRange, a, lo, hi, uint64(size))
      else: c.gABC(n, opcSetInclRange, dest, lo, hi)
      c.freeTemp(hi)
      c.freeTemp(lo)
    else:
      let e = genSetElem(c, x, n.typ)
      if big: c.gABCW(n, opcBSetIncl, a, e, 0, uint64(size))
      else: c.gABC(n, opcSetIncl, dest, e)
      c.freeTemp(e)
  if big: c.freeTemp(a)

# ------------------------- conversions ---------------------------------------

proc intBits(c: PCtx; t: PType): int =
  ## the number of bits of an integer type for arithmetic purposes; follows
  ## the target, like the C backend does
  let t = t.skipTypes(abstractRange+{tyOwned, tyStatic})
  case t.kind
  of tyInt, tyUInt: int(getSize(c.config, t)) * 8
  of tyInt8, tyUInt8, tyChar, tyBool: 8
  of tyInt16, tyUInt16: 16
  of tyInt32, tyUInt32: 32
  of tyEnum: vmSize(c, t) * 8
  else: 64

proc log2Bits(bits: int): int =
  case bits
  of 8: 3
  of 16: 4
  of 32: 5
  else: 6

proc genNarrow(c: PCtx; n: PNode; dest: TDest) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  if t.kind in {tyEnum, tyRange}:
    # `succ`, `pred`, `inc`, `dec` must stay within the type's range:
    let first = c.getIntTemp()
    let last = c.getIntTemp()
    genLdImm(c, n, first, toInt64(firstOrd(c.config, t)))
    genLdImm(c, n, last, toInt64(lastOrd(c.config, t)))
    c.gABC(n, opcRangeChckSucc, dest, first, last)
    c.freeTemp(last)
    c.freeTemp(first)
    return
  let bits = intBits(c, t)
  if bits >= 64: return
  if t.skipTypes(abstractRange).kind in {tyUInt..tyUInt64, tyChar, tyBool}:
    c.gABC(n, opcNarrowU, dest, TRegister(bits))
  elif t.skipTypes(abstractRange).kind in {tyInt..tyInt64}:
    c.gABC(n, opcNarrowS, dest, TRegister(bits))

proc genNarrowU(c: PCtx; n: PNode; dest: TDest) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  let bits = intBits(c, t)
  if bits < 64 and t.skipTypes(abstractRange).kind in {tyUInt..tyUInt64, tyInt..tyInt64}:
    c.gABC(n, opcNarrowU, dest, TRegister(bits))

proc genOpenArrayConv(c: PCtx; n, arg: PNode; dest: var TDest) =
  ## converts an array, seq or string to an openArray
  let st = arg.typ.skipTypes(abstractVarRange+{tyOwned}-{tyTypeDesc})
  if dest < 0: dest = c.getTempN(2)
  case st.kind
  of tyOpenArray, tyVarargs:
    gen(c, arg, dest)
  of tyArray:
    let len = toInt64(lengthOrd(c.config, st))
    if arg.kind == nkBracket and isDeepConstExpr(arg):
      # the view must outlive the evaluation, so a literal lives in constant
      # memory:
      genLdImmAddr(c, n, TRegister(dest), constAddress(c, arg, arg.typ))
    else:
      var loc = genLoc(c, arg)
      let a = addrOfLoc(c, arg, loc)
      c.gABC(n, opcMov, dest, a)
      # an rvalue array lives in a temporary that the view refers to:
      if loc.kind == lkFrame and loc.isTemp: c.pinTemp(loc.reg)
      c.freeLoc(loc)
    genLdImm(c, n, TRegister(dest+1), len)
  of tyString, tySequence:
    var loc = genLoc(c, arg)
    let a = addrOfLoc(c, arg, loc)
    let et = if st.kind == tyString: getSysType(c.graph, n.info, tyChar) else: st.elementType
    c.gABCW(n, opcSeqData, dest, a, 0, uint64(payloadDataOffset(vmAlign(c, et))))
    c.gABC(n, opcLd64, TRegister(dest+1), a, 0)
    c.freeLoc(loc)
  of tyCstring:
    let p = c.genx(arg)
    c.gABC(n, opcMov, dest, p)
    c.gABC(n, opcCStrLen, TRegister(dest+1), p)
    c.freeTemp(p)
  else:
    if arg.kind == nkBracket:
      genOpenArrayFromBracket(c, arg, dest)
    else:
      globalError(c.config, n.info, "VM: cannot convert " & typeToString(arg.typ) & " to openArray")

proc genConv(c: PCtx; n, arg: PNode; dest: var TDest) =
  let dt = n.typ.skipTypes(abstractRange+{tyOwned, tyStatic, tySink}-{tyTypeDesc})
  let st = arg.typ.skipTypes(abstractRange+{tyOwned, tyStatic, tySink}-{tyTypeDesc})
  if dt.kind in {tyOpenArray, tyVarargs}:
    genOpenArrayConv(c, n, arg, dest)
    return
  if dt.kind == tyProc and st.kind == tyProc and
      (dt.callConv == ccClosure) != (st.callConv == ccClosure):
    # nimcall to closure:
    if dest < 0: dest = c.getTemp(n.typ)
    gen(c, arg, dest)
    if dt.callConv == ccClosure:
      c.gABx(n, opcLdImmInt, TRegister(dest+1), 0)
    return
  if reprIsSame(c, dt, st) or dt.kind == tyTypeDesc:
    gen(c, arg, dest)
    if dt.kind in {tyInt..tyInt64, tyUInt..tyUInt64} and dt.kind != st.kind:
      # e.g. int to int32 on a 32 bit target
      let tmp = TRegister(dest)
      if c.isTemp(dest): genNarrow(c, n, tmp)
    return
  case dt.kind
  of tyString:
    if st.kind == tyCstring:
      let p = c.genx(arg)
      if dest < 0: dest = c.getTemp(n.typ)
      c.gABC(n, opcZeroN, dest, 2)
      let a = c.getIntTemp()
      c.gABC(n, opcAddrSlot, a, dest)
      c.gABC(n, opcCStrToStr, a, p)
      c.freeTemp(a)
      c.freeTemp(p)
    else:
      globalError(c.config, n.info, "VM: cannot convert to string from " & typeToString(arg.typ))
  of tyCstring:
    if st.kind == tyString:
      var src = genValueAddr(c, arg)
      if dest < 0: dest = c.getIntTemp()
      c.gABC(n, opcStrToCStr, dest, src.reg)
      c.freeLoc(src)
    else:
      gen(c, arg, dest)
  of tyFloat..tyFloat128:
    let tmp = c.genx(arg)
    if dest < 0: dest = c.getIntTemp()
    case st.kind
    of tyFloat..tyFloat128:
      c.gABC(n, opcMov, dest, tmp)
    else:
      if isUnsigned(c, st): c.gABC(n, opcUIntToFloat, dest, tmp)
      else: c.gABC(n, opcIntToFloat, dest, tmp)
    if dt.kind == tyFloat32:
      c.gABC(n, opcFloatToF32, dest, dest)
    c.freeTemp(tmp)
  of tyInt..tyInt64, tyUInt..tyUInt64, tyEnum, tyBool, tyChar:
    let tmp = c.genx(arg)
    if dest < 0: dest = c.getIntTemp()
    if st.kind in {tyFloat..tyFloat128} and dt.kind == tyBool:
      let z = c.getIntTemp()
      c.gABCW(n, opcLdImm, z, 0, 0, cast[uint64](0.0))
      c.gABC(n, opcEqFloat, dest, tmp, z)
      c.gABC(n, opcNot, dest, dest)
      c.freeTemp(z)
    elif st.kind in {tyFloat..tyFloat128}:
      if dt.kind in {tyUInt..tyUInt64}:
        c.gABC(n, opcFloatToUInt, dest, tmp)
      else:
        c.gABCW(n, opcFloatToInt, dest, tmp, 0, uint64(typeHandle(c, dt)))
    elif dt.kind == tyBool:
      # bool(x) is x != 0
      let z = c.getIntTemp()
      c.gABx(n, opcLdImmInt, z, 0)
      c.gABC(n, opcEqInt, dest, tmp, z)
      c.gABC(n, opcNot, dest, dest)
      c.freeTemp(z)
    else:
      c.gABC(n, opcMov, dest, tmp)
    c.freeTemp(tmp)
    let bits = intBits(c, dt)
    if bits < 64 and dt.kind != tyBool:
      if dt.kind in {tyInt..tyInt64}:
        c.gABC(n, opcNarrowS, dest, TRegister(bits))
      elif dt.kind in {tyUInt..tyUInt64}:
        c.gABC(n, opcNarrowU, dest, TRegister(bits))
  of tyObject, tyTuple, tyArray, tySet, tySequence, tyRef, tyPtr, tyPointer:
    gen(c, arg, dest)
  else:
    globalError(c.config, n.info, "VM: cannot convert " & typeToString(arg.typ) &
                " to " & typeToString(n.typ))

proc genCast(c: PCtx; n: PNode; dest: var TDest) =
  ## `cast` reinterprets the bits of the value in memory
  let dt = n.typ
  let st = n[1].typ
  if n[1].kind == nkNilLit or st == nil or st.kind == tyNil:
    var d = dest
    genLitInto(c, newNodeIT(nkNilLit, n.info, dt), dt, d)
    dest = d
    return
  let dk = mk(c, dt)
  let sk = mk(c, st)
  const intKinds = SignedMemKinds + UnsignedMemKinds + {mkPtr, mkNode}
  if dk in intKinds and sk in intKinds:
    # like the C backend: a value conversion to the bits of the target
    let v = c.genx(n[1])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcMov, dest, v)
    c.freeTemp(v)
    # integers follow the target (`int` is 32 bits for the JS backend):
    let bits = if dk in {mkPtr, mkNode}: 64 else: min(memKindSize(dk) * 8, intBits(c, dt))
    if bits < 64:
      if dk in SignedMemKinds: c.gABC(n, opcSignExtend, dest, TRegister(bits))
      else: c.gABC(n, opcNarrowU, dest, TRegister(bits))
    return
  if (dk in FloatMemKinds and sk in intKinds) or (sk in FloatMemKinds and dk in intKinds):
    let v = c.genx(n[1])
    if dest < 0: dest = c.getIntTemp()
    if dk in FloatMemKinds:
      if memKindSize(sk) != memKindSize(dk):
        globalError(c.config, n.info, "VM does not support 'cast' from " &
        $st.skipTypes(abstractRange).kind & " with size " & $getSize(c.config, st) & " to " &
        $dt.skipTypes(abstractRange).kind & " with size " & $getSize(c.config, dt) & " due to different sizes")
      c.gABC(n, if dk == mkF32: opcCastIntToFloat32 else: opcCastIntToFloat64, dest, v)
    else:
      if memKindSize(sk) != memKindSize(dk):
        globalError(c.config, n.info, "VM does not support 'cast' from " &
        $st.skipTypes(abstractRange).kind & " with size " & $getSize(c.config, st) & " to " &
        $dt.skipTypes(abstractRange).kind & " with size " & $getSize(c.config, dt) & " due to different sizes")
      c.gABC(n, if sk == mkF32: opcCastFloatToInt32 else: opcCastFloatToInt64, dest, v)
      if dk in UnsignedMemKinds and memKindSize(dk) < 8:
        c.gABC(n, opcNarrowU, dest, TRegister(memKindSize(dk)*8))
    c.freeTemp(v)
    return
  let size = max(vmSize(c, dt), vmSize(c, st))
  let tmp = c.getTempN(slotsFor(size))
  c.gABC(n, opcZeroN, tmp, TRegister(slotsFor(size)))
  block:
    var loc = frameLoc(tmp, st, false, false, false)
    let v = c.genx(n[1])
    storeLoc(c, n[1], loc, v)
    c.freeTemp(v)
  var loc = frameLoc(tmp, dt, false, false, false)
  if dest < 0: dest = c.getTemp(dt)
  loadLoc(c, n, loc, dest)
  c.freeTemp(tmp)

# ------------------------- magics -------------------------------------------

proc genUnaryABC(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let tmp = c.genx(n[1])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp)
  c.freeTemp(tmp)

proc genUnaryABI(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode; imm: BiggestInt=0) =
  let tmp = c.genx(n[1])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABI(n, opc, dest, tmp, imm)
  c.freeTemp(tmp)

proc genBinaryABC(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let
    tmp = c.genx(n[1])
    tmp2 = c.genx(n[2])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genBinaryStmt(c: PCtx; n: PNode; opc: TOpcode) =
  let
    dest = c.genx(n[1])
    tmp = c.genx(n[2])
  c.gABC(n, opc, dest, tmp, 0)
  c.freeTemp(tmp)
  c.freeTemp(dest)

proc genVoidABC(c: PCtx, n: PNode, dest: TDest, opcode: TOpcode) =
  unused(c, n, dest)
  var
    tmp1 = c.genx(n[1])
    tmp2 = c.genx(n[2])
    tmp3 = c.genx(n[3])
  c.gABC(n, opcode, tmp1, tmp2, tmp3)
  c.freeTemp(tmp1)
  c.freeTemp(tmp2)
  c.freeTemp(tmp3)

proc genBinaryABCnarrow(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrow(c, n, dest)

proc genBinaryABCnarrowU(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrowU(c, n, dest)

proc isInt8Lit(n: PNode): bool =
  if n.kind in {nkCharLit..nkUInt64Lit}:
    result = n.intVal >= low(int8) and n.intVal <= high(int8)
  else:
    result = false

proc genAddSubInt(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  if n[2].isInt8Lit:
    let tmp = c.genx(n[1])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABI(n, succ(opc), dest, tmp, n[2].intVal)
    c.freeTemp(tmp)
  else:
    genBinaryABC(c, n, dest, opc)
  c.genNarrow(n, dest)

proc skipAddr(n: PNode): PNode =
  if n.kind in {nkAddr, nkHiddenAddr}: n[0] else: n

proc genStrDestAddr(c: PCtx; n: PNode; dest: var TDest): TRegister =
  ## prepares `dest` as a fresh string and returns a register with its address
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opcZeroN, dest, TRegister(slotsOf(c, n.typ)))
  result = c.getIntTemp()
  c.gABC(n, opcAddrSlot, result, dest)

proc genStrResult(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode;
                  b: TRegister = 0; cc: TRegister = 0; w = 0'u64; hasW = false) =
  ## an operation that produces a string at the address in register A
  let a = genStrDestAddr(c, n, dest)
  if hasW: c.gABCW(n, opc, a, b, cc, w)
  else: c.gABC(n, opc, a, b, cc)
  c.freeTemp(a)

proc genMutate(c: PCtx; n: PNode; body: proc (c: PCtx; v: TRegister)) =
  ## load-modify-store of the location `n`
  var loc = genLoc(c, n, write = true)
  if loc.kind == lkFrame and loc.widened:
    body(c, loc.reg)
    c.freeLoc(loc)
  else:
    if not (loc.kind == lkFrame and loc.off mod SlotSize == 0):
      discard addrOfLoc(c, n, loc)
    var keep = loc
    keep.isTemp = false
    var v: TDest = c.getTemp(n.typ)
    loadLoc(c, n, keep, v)
    body(c, v)
    storeLoc(c, n, loc, v)
    c.freeTemp(v)

proc genSetLength(c: PCtx; n: PNode; isSeq: bool) =
  var loc = genLoc(c, n[1].skipAddr)
  let a = addrOfLoc(c, n, loc)
  let newLen = c.genx(n[2])
  if isSeq:
    let elemType = n[1].typ.skipTypes(abstractVar+{tyOwned}).elementType
    let op = getAttachedOp(c.graph, elemType, attachedDestructor)
    if op != nil and not isTrivial(op):
      # destroy the elements that are removed:
      let i = c.getIntTemp()
      let L = c.getIntTemp()
      let cond = c.getIntTemp()
      let ea = c.getIntTemp()
      c.gABC(n, opcMov, i, newLen)
      c.gABC(n, opcLd64, L, a, 0)
      let lab1 = c.genLabel
      c.gABC(n, opcLtInt, cond, i, L)
      let lab2 = c.xjmp(n, opcFJmp, cond)
      c.gABCW(n, opcIdxSeq, ea, a, i,
              packAddr(vmSize(c, elemType), payloadDataOffset(vmAlign(c, elemType))))
      genHookCall(c, n, op, ea, elemType)
      c.gABI(n, opcAddImmInt, i, i, 1)
      # not a loop of the program: it must not count as an iteration
      c.gABx(n, opcJmp, 0, lab1.int - c.code.len)
      c.patch(lab2)
      c.freeTemp(ea)
      c.freeTemp(cond)
      c.freeTemp(L)
      c.freeTemp(i)
    c.gABCW(n, opcSeqSetLen, a, newLen, 0, seqW(c, elemType))
  else:
    c.gABC(n, opcStrSetLen, a, newLen)
  c.freeTemp(newLen)
  c.freeLoc(loc)

proc genSlice(c: PCtx; n: PNode; dest: var TDest) =
  # toOpenArray(x, lo, hi)
  let base = n[1]
  let st = base.typ.skipTypes(abstractVarRange+{tyOwned}-{tyTypeDesc})
  let area = c.getTempN(4)
  var esize = 1
  case st.kind
  of tyArray:
    var loc = genLoc(c, base)
    let a = addrOfLoc(c, n, loc)
    c.gABC(n, opcMov, area, a)
    genLdImm(c, n, TRegister(area+1), toInt64(lengthOrd(c.config, st)))
    c.freeLoc(loc)
    esize = vmSize(c, st.elementType)
  of tyString, tySequence, tyOpenArray, tyVarargs, tyCstring:
    var tmp: TDest = -1
    if st.kind == tyString and base.kind == nkHiddenDeref:
      # the slice may be used for mutation (like cgen's prepareForMutation):
      var sloc = genLoc(c, base, write = true)
      let sa = addrOfLoc(c, n, sloc)
      c.gABC(n, opcMakeUnique, sa)
      c.freeLoc(sloc)
    genOpenArrayConv(c, n, base, tmp)
    c.gABC(n, opcMovN, area, tmp, 2)
    c.freeTemp(tmp)
    esize = if st.kind in {tyString, tyCstring}: 1 else: vmSize(c, st.elementType)
  of tyUncheckedArray, tyPtr:
    let p = c.genx(base)
    c.gABC(n, opcMov, area, p)
    genLdImm(c, n, TRegister(area+1), high(int32))
    c.freeTemp(p)
    let et = if st.kind == tyPtr: st.elementType.skipTypes(abstractInst).elementType else: st.elementType
    esize = vmSize(c, et)
  else:
    globalError(c.config, n.info, "VM: cannot slice a value of type " & typeToString(base.typ))
  let lo = genIndexReg(c, n[2], st)
  let hi = genIndexReg(c, n[3], st)
  c.gABC(n, opcMov, TRegister(area+2), lo)
  c.gABC(n, opcMov, TRegister(area+3), hi)
  c.freeTemp(hi)
  c.freeTemp(lo)
  if dest < 0: dest = c.getTempN(2)
  c.gABCW(n, opcSlice, dest, area, 0, uint64(esize))
  c.freeTemp(area)

proc genBindSym(c: PCtx; n: PNode; dest: var TDest) =
  # nah, cannot use c.config.features because sempass context
  # can have local experimental switch
  # if dynamicBindSym notin c.config.features:
  if n.len == 2: # hmm, reliable?
    # bindSym with static input
    if n[1].kind in {nkClosedSymChoice, nkOpenSymChoice, nkOpenSym, nkSym}:
      let t = c.getIntTemp()
      var d = TDest(t)
      genNodeLit(c, n, n[1], d)
      if dest < 0: dest = c.getIntTemp()
      c.gABC(n, opcNBindSym, dest, t)
      c.freeTemp(t)
    else:
      localError(c.config, n.info, "invalid bindSym usage")
  else:
    # experimental bindSym: (ident, rule, ..., info node, callback index)
    if dest < 0: dest = c.getIntTemp()
    var shape = CallShape(resultType: n.typ,
                          callbackIdx: int(n[^1].intVal))
    var slots = 0
    var args: seq[(PNode, PType, int)] = @[]
    for i in 1..<n.len-2:
      args.add (n[i], n[i].typ, slots)
      slots += slotsOf(c, n[i].typ)
    let nodeType = getSysSym(c.graph, n.info, "NimNode").typ
    args.add (n[^2], nodeType, slots)
    slots += 1
    let area = c.getTempN(max(slots, 1))
    for (arg, t, off) in args:
      shape.paramOffsets.add off * SlotSize
      shape.paramTypes.add t
      if t == nodeType and arg == n[^2]:
        var d = TDest(area+off)
        genNodeLit(c, arg, arg, d)
      else:
        gen(c, arg, TRegister(area+off))
    c.callShapes.add shape
    c.gABCW(n, opcNDynBindSym, dest, area, 0, uint64(c.callShapes.len-1))
    c.freeTemp(area)

proc genEqIdentArg(c: PCtx; n: PNode; isStr: var bool): TRegister =
  isStr = n.typ.skipTypes(abstractInst).kind == tyString
  if isStr:
    var loc = genValueAddr(c, n)
    loc.isTemp = false
    result = loc.reg
  else:
    result = c.genx(n)

proc genStrArg(c: PCtx; n: PNode): TRegister =
  ## the address of a string argument; the caller has to free the register
  var loc = genValueAddr(c, n)
  if loc.isTemp:
    result = loc.reg
  else:
    result = c.getIntTemp()
    c.gABC(n, opcMov, result, loc.reg)

proc sizeOfLikeMsg(name: string; incompleteStruct: bool): string =
  if incompleteStruct:
    "'$1' cannot be used with '.incompleteStruct' types" % [name]
  else:
    "'$1' requires '.importc' types to be '.completeStruct'" % [name]

proc genMagic(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags = {}, m: TMagic) =
  case m
  of mAnd: c.genAndOr(n, opcFJmp, dest)
  of mOr:  c.genAndOr(n, opcTJmp, dest)
  of mPred, mSubI:
    c.genAddSubInt(n, dest, opcSubInt)
  of mSucc, mAddI:
    c.genAddSubInt(n, dest, opcAddInt)
  of mInc, mDec:
    unused(c, n, dest)
    let isUnsigned = n[1].typ.skipTypes(abstractVarRange).kind in {tyUInt..tyUInt64}
    let opc = if not isUnsigned:
                if m == mInc: opcAddInt else: opcSubInt
              else:
                if m == mInc: opcAddu else: opcSubu
    let tmp = c.genx(n[2])
    let target = n[1].skipAddr
    genMutate(c, target, proc (c: PCtx; v: TRegister) =
      c.gABC(n, opc, v, v, tmp)
      c.genNarrow(target, v))
    c.freeTemp(tmp)
  of mOrd, mChr, mUnown: c.gen(n[1], dest)
  of mArrToSeq:
    if n[1].kind == nkBracket:
      genSeqConstrFrom(c, n[1], n.typ, dest)
    else:
      # copy the bits of the elements; the array is a `sink` parameter
      let elemType = n.typ.skipTypes(abstractInst).elementType
      let arrType = n[1].typ.skipTypes(abstractInst)
      let len = toInt64(lengthOrd(c.config, arrType))
      var src = genValueAddr(c, n[1])
      if dest < 0: dest = c.getTemp(n.typ)
      let a = c.getIntTemp()
      let lenReg = c.getIntTemp()
      c.gABC(n, opcZeroN, dest, 2)
      c.gABC(n, opcAddrSlot, a, dest)
      genLdImm(c, n, lenReg, len)
      c.gABCW(n, opcSeqNew, a, lenReg, 0, seqW(c, elemType))
      if len > 0:
        let data = c.getIntTemp()
        c.gABCW(n, opcSeqData, data, a, 0, uint64(payloadDataOffset(vmAlign(c, elemType))))
        c.gABCW(n, opcCopyMem, data, src.reg, 0, uint64(len * vmSize(c, elemType)))
        c.freeTemp(data)
      c.freeTemp(lenReg)
      c.freeTemp(a)
      c.freeLoc(src)
  of generatedMagics:
    genCall(c, n, dest)
  of mNew, mNewFinalize:
    unused(c, n, dest)
    let target = n[1].skipAddr
    let objType = target.typ.skipTypes(abstractVar+{tyOwned}-{tyTypeDesc}).elementType.skipTypes(abstractInst)
    let t = c.getIntTemp()
    c.gABCW(n, opcNewRef, t, 0, 0, packAddr(vmSize(c, objType), vmAlign(c, objType)))
    if needsInitObj(c, objType):
      c.gABCW(n, opcInitObj, t, 0, 0, uint64(typeHandle(c, objType)))
    var loc = genLoc(c, target)
    storeLoc(c, n, loc, t)
    c.freeTemp(t)
  of mNewSeq:
    unused(c, n, dest)
    let target = n[1].skipAddr
    let elemType = target.typ.skipTypes(abstractVar+{tyOwned}).elementType
    var loc = genLoc(c, target)
    let a = addrOfLoc(c, n, loc)
    let len = c.genx(n[2])
    c.gABCW(n, opcSeqNew, a, len, 0, seqW(c, elemType))
    c.freeTemp(len)
    c.freeLoc(loc)
  of mNewSeqOfCap:
    let elemType = n.typ.skipTypes(abstractVar+{tyOwned}).elementType
    c.freeTemp(c.genx(n[1]))
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcZeroN, dest, 2)
  of mNewString, mNewStringOfCap:
    var len: TRegister
    if m == mNewStringOfCap:
      # the capacity is only a hint; evaluate it for its side effects:
      c.freeTemp(c.genx(n[1]))
      len = c.getIntTemp()
      c.gABx(n, opcLdImmInt, len, 0)
    else:
      len = c.genx(n[1])
    genStrResult(c, n, dest, opcStrNew, len)
    c.freeTemp(len)
  of mLengthStr:
    case n[1].typ.skipTypes(abstractVarRange).kind
    of tyCstring: genUnaryABC(c, n, dest, opcCStrLen)
    else:
      var loc = genLoc(c, n[1])
      loc.typ = n.typ
      loc.widened = false
      loc.whole = false
      loadLoc(c, n, loc, dest)
  of mLengthSeq, mLengthOpenArray:
    if n[1].typ != nil and mk(c, n[1].typ) == mkNode:
      # `varargsLen` applies this magic to a NimNode and returns a NimNode
      let a = c.genx(n[1])
      let len = c.getIntTemp()
      c.gABC(n, opcNLen, len, a)
      if dest < 0: dest = c.getIntTemp()
      if n.typ != nil and mk(c, n.typ) == mkNode:
        let intType = getSysType(c.graph, n.info, tyInt)
        c.gABCW(n, opcToNode, dest, len, 0, uint64(typeHandle(c, intType)))
      else:
        c.gABC(n, opcMov, dest, len)
      c.freeTemp(len)
      c.freeTemp(a)
      return
    let t = n[1].typ.skipTypes(abstractVarRange+{tyOwned}-{tyTypeDesc})
    if t.kind == tyArray:
      # an inlined iterator over a `varargs` that `transf` turned into an
      # array temporary:
      if dest < 0: dest = c.getIntTemp()
      genLdImm(c, n, dest, toInt64(lengthOrd(c.config, t)))
      return
    var loc = genLoc(c, n[1])
    loc.typ = n.typ
    loc.widened = false
    loc.whole = false
    if t.kind in {tyOpenArray, tyVarargs}: loc.off += OpenArrayLenOffset
    loadLoc(c, n, loc, dest)
  of mLengthArray:
    if dest < 0: dest = c.getIntTemp()
    genLdImm(c, n, dest, toInt64(lengthOrd(c.config, n[1].typ.skipTypes(abstractVarRange))))
  of mHigh:
    let t = n[1].typ.skipTypes(abstractVarRange+{tyOwned}-{tyTypeDesc})
    let lenNode = newTreeIT(nkCall, n.info, n.typ, n[0], n[1])
    case t.kind
    of tyCstring: genUnaryABC(c, lenNode, dest, opcCStrLen)
    of tyArray:
      if dest < 0: dest = c.getIntTemp()
      genLdImm(c, n, dest, toInt64(lengthOrd(c.config, t)))
    else:
      var loc = genLoc(c, n[1])
      loc.typ = n.typ
      loc.widened = false
      loc.whole = false
      if t.kind in {tyOpenArray, tyVarargs}: loc.off += OpenArrayLenOffset
      var d: TDest = -1
      loadLoc(c, n, loc, d)
      if dest < 0: dest = c.getIntTemp()
      c.gABI(n, opcSubImmInt, dest, d, 1)
      if d != dest: c.freeTemp(d)
      return
    c.gABI(n, opcSubImmInt, dest, dest, 1)
  of mSlice:
    genSlice(c, n, dest)
  of mIncl, mExcl:
    unused(c, n, dest)
    let target = n[1].skipAddr
    let setType = target.typ.skipTypes(abstractVar)
    let e = genSetElem(c, n[2], setType)
    if isBigSet(c, setType):
      var loc = genLoc(c, target)
      let a = addrOfLoc(c, n, loc)
      c.gABCW(n, if m == mIncl: opcBSetIncl else: opcBSetExcl, a, e, 0, uint64(vmSize(c, setType)))
      c.freeLoc(loc)
    else:
      genMutate(c, target, proc (c: PCtx; v: TRegister) =
        c.gABC(n, if m == mIncl: opcSetIncl else: opcSetExcl, v, e))
    c.freeTemp(e)
  of mCard:
    let setType = n[1].typ.skipTypes(abstractVar)
    if isBigSet(c, setType):
      var loc = genValueAddr(c, n[1])
      if dest < 0: dest = c.getIntTemp()
      c.gABCW(n, opcBSetCard, dest, loc.reg, 0, uint64(vmSize(c, setType)))
      c.freeLoc(loc)
    else:
      genUnaryABC(c, n, dest, opcSetCard)
  of mInSet:
    let setType = n[1].typ.skipTypes(abstractVar)
    var elem = n[2]
    while elem.kind in {nkHiddenStdConv, nkHiddenSubConv, nkConv} and elem.len == 2: elem = elem[1]
    if elem.kind in nkCallKinds and elem[0].kind == nkSym and
        elem[0].sym.magic == mNGetType and elem[0].sym.name.s == "typeKind" and
        n[1].kind == nkCurly and n[1].len > 0:
      # the old VM left the result register of `typeKind` untouched for an
      # untyped node and it happened to hold the set's element, so
      # `n.typeKind in {...}` was true. Macros like unittest2's `check` rely
      # on this.
      let first = if n[1][0].kind == nkRange: n[1][0][0] else: n[1][0]
      c.typeKindDefault = toInt(getOrdValue(first)) + 1
    let e = genSetElem(c, n[2], setType)
    c.typeKindDefault = 0
    if dest < 0: dest = c.getIntTemp()
    if isBigSet(c, setType):
      var loc = genValueAddr(c, n[1])
      c.gABCW(n, opcBSetContains, dest, loc.reg, e, uint64(vmSize(c, setType)))
      c.freeLoc(loc)
    else:
      let s = c.genx(n[1])
      c.gABC(n, opcSetContains, dest, s, e)
      c.freeTemp(s)
    c.freeTemp(e)
  of mEqSet, mLeSet, mLtSet, mMulSet, mPlusSet, mMinusSet, mXorSet:
    let setType = n[1].typ.skipTypes(abstractVar)
    if isBigSet(c, setType):
      var a = genValueAddr(c, n[1])
      var b = genValueAddr(c, n[2])
      let size = uint64(vmSize(c, setType))
      if m in {mEqSet, mLeSet, mLtSet}:
        if dest < 0: dest = c.getIntTemp()
        let opc = case m
                  of mEqSet: opcBSetEq
                  of mLeSet: opcBSetLe
                  else: opcBSetLt
        c.gABCW(n, opc, dest, a.reg, b.reg, size)
      else:
        if dest < 0: dest = c.getTemp(n.typ)
        let d = c.getIntTemp()
        c.gABC(n, opcAddrSlot, d, dest)
        let opc = case m
                  of mMulSet: opcBSetInter
                  of mPlusSet: opcBSetUnion
                  of mMinusSet: opcBSetDiff
                  else: opcBSetXor
        c.gABCW(n, opc, d, a.reg, b.reg, size)
        c.freeTemp(d)
      c.freeLoc(b)
      c.freeLoc(a)
    else:
      case m
      of mEqSet: genBinaryABC(c, n, dest, opcEqInt)
      of mLeSet: genBinaryABC(c, n, dest, opcSetLe)
      of mLtSet: genBinaryABC(c, n, dest, opcSetLt)
      of mMulSet: genBinaryABC(c, n, dest, opcBitandInt)
      of mPlusSet: genBinaryABC(c, n, dest, opcBitorInt)
      of mXorSet: genBinaryABC(c, n, dest, opcBitxorInt)
      else:
        # a - b = a and not b
        let a = c.genx(n[1])
        let b = c.genx(n[2])
        let nb = c.getIntTemp()
        c.gABC(n, opcBitnotInt, nb, b)
        if dest < 0: dest = c.getIntTemp()
        c.gABC(n, opcBitandInt, dest, a, nb)
        c.freeTemp(nb)
        c.freeTemp(b)
        c.freeTemp(a)
  of mMulI: genBinaryABCnarrow(c, n, dest, opcMulInt)
  of mDivI: genBinaryABCnarrow(c, n, dest, opcDivInt)
  of mModI: genBinaryABCnarrow(c, n, dest, opcModInt)
  of mAddF64: genBinaryABC(c, n, dest, opcAddFloat)
  of mSubF64: genBinaryABC(c, n, dest, opcSubFloat)
  of mMulF64: genBinaryABC(c, n, dest, opcMulFloat)
  of mDivF64: genBinaryABC(c, n, dest, opcDivFloat)
  of mShrI:
    # the left operand has to be narrowed first:
    let bits = intBits(c, skipTypes(n.typ, abstractVar-{tyTypeDesc}))
    let tmp = c.genx(n[1])
    let tmpN = c.getIntTemp()
    c.gABC(n, opcMov, tmpN, tmp)
    c.genNarrowU(n, tmpN)
    let tmp2 = c.genx(n[2])
    let sh = c.getIntTemp()
    c.gABC(n, opcMov, sh, tmp2)
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcNarrowU, sh, TRegister(log2Bits(bits)))
    c.gABC(n, opcShrInt, dest, tmpN, sh)
    c.freeTemp(sh)
    c.freeTemp(tmp)
    c.freeTemp(tmpN)
    c.freeTemp(tmp2)
  of mShlI:
    let typ = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    let bits = intBits(c, typ)
    let tmp1 = c.genx(n[1])
    let tmp2 = c.genx(n[2])
    let sh = c.getIntTemp()
    c.gABC(n, opcMov, sh, tmp2)
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcNarrowU, sh, TRegister(log2Bits(bits)))
    c.gABC(n, opcShlInt, dest, tmp1, sh)
    c.freeTemp(sh)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    if bits < 64:
      if typ.skipTypes(abstractRange).kind in {tyUInt..tyUInt64}:
        c.gABC(n, opcNarrowU, dest, TRegister(bits))
      else:
        c.gABC(n, opcSignExtend, dest, TRegister(bits))
  of mAshrI:
    let bits = intBits(c, skipTypes(n.typ, abstractVar-{tyTypeDesc}))
    let tmp1 = c.genx(n[1])
    let tmp2 = c.genx(n[2])
    let sh = c.getIntTemp()
    c.gABC(n, opcMov, sh, tmp2)
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcNarrowU, sh, TRegister(log2Bits(bits)))
    c.gABC(n, opcAshrInt, dest, tmp1, sh)
    c.freeTemp(sh)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
  of mBitandI: genBinaryABC(c, n, dest, opcBitandInt)
  of mBitorI: genBinaryABC(c, n, dest, opcBitorInt)
  of mBitxorI: genBinaryABC(c, n, dest, opcBitxorInt)
  of mAddU: genBinaryABCnarrowU(c, n, dest, opcAddu)
  of mSubU: genBinaryABCnarrowU(c, n, dest, opcSubu)
  of mMulU: genBinaryABCnarrowU(c, n, dest, opcMulu)
  of mDivU: genBinaryABCnarrowU(c, n, dest, opcDivu)
  of mModU: genBinaryABCnarrowU(c, n, dest, opcModu)
  of mEqI, mEqB, mEqEnum, mEqCh:
    genBinaryABC(c, n, dest, opcEqInt)
  of mLeI, mLeEnum, mLeCh, mLeB:
    genBinaryABC(c, n, dest, opcLeInt)
  of mLtI, mLtEnum, mLtCh, mLtB:
    genBinaryABC(c, n, dest, opcLtInt)
  of mEqF64: genBinaryABC(c, n, dest, opcEqFloat)
  of mLeF64: genBinaryABC(c, n, dest, opcLeFloat)
  of mLtF64: genBinaryABC(c, n, dest, opcLtFloat)
  of mLeU, mLePtr: genBinaryABC(c, n, dest, opcLeu)
  of mLtU, mLtPtr: genBinaryABC(c, n, dest, opcLtu)
  of mEqProc, mEqRef:
    let t = n[1].typ.skipTypes(abstractInst)
    if t.kind == tyProc and t.callConv == ccClosure:
      let a = c.genx(n[1])
      let b = c.genx(n[2])
      let tmp = c.getIntTemp()
      if dest < 0: dest = c.getIntTemp()
      c.gABC(n, opcEqInt, dest, a, b)
      c.gABC(n, opcEqInt, tmp, TRegister(a+1), TRegister(b+1))
      c.gABC(n, opcBitandInt, dest, dest, tmp)
      c.freeTemp(tmp)
      c.freeTemp(b)
      c.freeTemp(a)
    else:
      genBinaryABC(c, n, dest, opcEqInt)
  of mXor: genBinaryABC(c, n, dest, opcXor)
  of mNot: genUnaryABC(c, n, dest, opcNot)
  of mUnaryMinusI, mUnaryMinusI64:
    genUnaryABC(c, n, dest, opcUnaryMinusInt)
    genNarrow(c, n, dest)
  of mUnaryMinusF64: genUnaryABC(c, n, dest, opcUnaryMinusFloat)
  of mUnaryPlusI, mUnaryPlusF64: gen(c, n[1], dest)
  of mBitnotI:
    genUnaryABC(c, n, dest, opcBitnotInt)
    #genNarrowU modified, do not narrow signed types
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    let bits = intBits(c, t)
    if bits < 64 and t.skipTypes(abstractRange).kind in {tyUInt..tyUInt64}:
      c.gABC(n, opcNarrowU, dest, TRegister(bits))
  of mCharToStr, mBoolToStr, mEnumToStr:
    let v = c.genx(n[1])
    genStrResult(c, n, dest, opcToStr, v, 0, uint64(typeHandle(c, n[1].typ)), true)
    c.freeTemp(v)
  of mStrToStr:
    let src = genStrArg(c, n[1])
    genStrResult(c, n, dest, opcStrAsgn, src)
    c.freeTemp(src)
  of mCStrToStr:
    let p = c.genx(n[1])
    genStrResult(c, n, dest, opcCStrToStr, p)
    c.freeTemp(p)
  of mEqStr, mLeStr, mLtStr:
    let a = genStrArg(c, n[1])
    let b = genStrArg(c, n[2])
    if dest < 0: dest = c.getIntTemp()
    let opc = case m
              of mEqStr: opcStrEq
              of mLeStr: opcStrLe
              else: opcStrLt
    c.gABC(n, opc, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mEqCString: genBinaryABC(c, n, dest, opcCStrEq)
  of mConStrStr:
    # evaluate the operands first, then concatenate:
    var parts: seq[(TRegister, bool)] = @[]
    for i in 1..<n.len:
      let isChar = n[i].typ.skipTypes(abstractVarRange).kind == tyChar
      if isChar: parts.add (c.genx(n[i]), true)
      else: parts.add (genStrArg(c, n[i]), false)
    let a = genStrDestAddr(c, n, dest)
    for (r, isChar) in parts:
      c.gABC(n, if isChar: opcStrAddCh else: opcStrAddStr, a, r)
      c.freeTemp(r)
    c.freeTemp(a)
  of mAppendStrCh, mAppendStrStr:
    unused(c, n, dest)
    if n[1].typ.skipTypes(abstractVar).kind == tyCstring:
      genCall(c, n, dest)
    else:
      let v = if m == mAppendStrCh: c.genx(n[2]) else: genStrArg(c, n[2])
      var loc = genLoc(c, n[1].skipAddr)
      let a = addrOfLoc(c, n, loc)
      c.gABC(n, if m == mAppendStrCh: opcStrAddCh else: opcStrAddStr, a, v)
      c.freeLoc(loc)
      c.freeTemp(v)
  of mAppendSeqElem:
    unused(c, n, dest)
    let elemType = n[1].typ.skipTypes(abstractVar+{tyOwned}).elementType
    let v = c.genx(n[2])
    var loc = genLoc(c, n[1].skipAddr)
    let a = addrOfLoc(c, n, loc)
    let e = c.getIntTemp()
    c.gABCW(n, opcSeqGrowOne, e, a, 0, seqW(c, elemType))
    var eloc = memLoc(e, 0, elemType, false)
    storeLoc(c, n, eloc, v)
    if needsUnshare(c, elemType, n[2]):
      c.gABCW(n, opcUnshare, e, 0, 0, uint64(typeHandle(c, elemType)))
    c.freeTemp(e)
    c.freeLoc(loc)
    c.freeTemp(v)
  of mSetLengthStr:
    unused(c, n, dest)
    genSetLength(c, n, false)
  of mSetLengthSeq, mSetLengthSeqUninit:
    unused(c, n, dest)
    genSetLength(c, n, true)
  of mRepr:
    var v = genValueAddr(c, n[1])
    genStrResult(c, n, dest, opcRepr, v.reg, 0, uint64(typeHandle(c, n[1].typ)), true)
    c.freeLoc(v)
  of mExit:
    unused(c, n, dest)
    var tmp = c.genx(n[1])
    c.gABC(n, opcQuit, tmp)
    c.freeTemp(tmp)
  of mSwap:
    unused(c, n, dest)
    c.gen(lowerSwap(c.graph, n, c.idgen, if c.prc == nil or c.prc.sym == nil: c.module else: c.prc.sym))
  of mIsNil:
    let t = n[1].typ.skipTypes(abstractInst)
    if dest < 0: dest = c.getIntTemp()
    case t.kind
    of tyString, tySequence:
      var loc = genLoc(c, n[1])
      loc.off += StrPayloadOffset
      loc.typ = getSysType(c.graph, n.info, tyPointer)
      loc.widened = false
      loc.whole = false
      var p: TDest = -1
      loadLoc(c, n, loc, p)
      c.gABC(n, opcIsNil, dest, p)
      c.freeTemp(p)
    else:
      # closures: the function pointer is in the first slot
      let v = c.genx(n[1])
      c.gABC(n, opcIsNil, dest, v)
      c.freeTemp(v)
  of mParseBiggestFloat:
    if dest < 0: dest = c.getIntTemp()
    var s: TRegister
    if n[1].typ.skipTypes(abstractVarRange).kind in {tyOpenArray, tyVarargs}:
      # copy the chars into a temporary string
      var oa: TDest = c.getTempN(2)
      genOpenArrayConv(c, n[1], n[1], oa)
      let oaAddr = c.getIntTemp()
      c.gABC(n, opcAddrSlot, oaAddr, oa)
      let strTmp = c.getTempN(2)
      c.gABC(n, opcZeroN, strTmp, 2)
      pinTemp(c, strTmp)
      s = c.getIntTemp()
      c.gABC(n, opcAddrSlot, s, strTmp)
      c.gABC(n, opcStrFromChars, s, oaAddr)
      c.freeTemp(oaAddr)
      c.freeTemp(oa)
    else:
      s = genStrArg(c, n[1])
    let f = c.getIntTemp()
    let fa = c.getIntTemp()
    c.gABx(n, opcLdImmInt, f, 0)
    c.gABC(n, opcAddrSlot, fa, f)
    c.gABC(n, opcParseFloat, dest, s, fa)
    var loc = genLoc(c, n[2].skipAddr)
    storeLoc(c, n, loc, f)
    c.freeTemp(fa)
    c.freeTemp(f)
    c.freeTemp(s)
  of mDefault, mZeroDefault:
    if dest < 0: dest = c.getTemp(n.typ)
    var loc = frameLoc(dest, n.typ, isScalar(c, n.typ), true, false)
    zeroLoc(c, n, loc)
  of mOf:
    let t = n[1].typ.skipTypes(abstractInst)
    var p: TRegister
    var loc = default(Loc)
    var owned = false
    if t.kind in {tyRef, tyPtr}:
      p = c.genx(n[1])
      owned = true
    else:
      loc = genValueAddr(c, n[1])
      p = loc.reg
    if dest < 0: dest = c.getIntTemp()
    let target = n[2].typ.skipTypes(abstractPtrs)
    c.gABCW(n, opcOf, dest, p, 0, uint64(typeHandle(c, target)))
    if owned: c.freeTemp(p) else: c.freeLoc(loc)
  of mIs:
    if dest < 0: dest = c.getIntTemp()
    let tmp = c.genx(n[1])
    c.gABCW(n, opcIs, dest, tmp, 0, uint64(typeHandle(c, n[2].typ)))
    c.freeTemp(tmp)
  of mEcho:
    unused(c, n, dest)
    let n = n[1].skipConv
    if n.kind == nkBracket:
      # can happen for nim check, see bug #9609
      let x = c.getTempN(2*n.len)
      for i in 0..<n.len:
        c.gen(n[i], TRegister(x+2*i))
      c.gABC(n, opcEcho, x, TRegister(n.len))
      c.freeTemp(x)
  of mParseExprToAst, mParseStmtToAst:
    let a = genStrArg(c, n[1])
    let b = if n.len > 2: genStrArg(c, n[2]) else: TRegister(0)
    if dest < 0: dest = c.getIntTemp()
    let opc = if m == mParseExprToAst: opcParseExprToAst else: opcParseStmtToAst
    c.gABC(n, if n.len > 2: succ(opc) else: opc, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mTypeTrait:
    let tmp = c.genx(n[1])
    genStrResult(c, n, dest, opcTypeTrait, tmp)
    c.freeTemp(tmp)
  of mSlurp:
    let a = genStrArg(c, n[1])
    genStrResult(c, n, dest, opcSlurp, a)
    c.freeTemp(a)
  of mStaticExec:
    let area = c.getTempN(3)
    for i in 1..3:
      let a = genStrArg(c, n[i])
      c.gABC(n, opcMov, TRegister(area+i-1), a)
      c.freeTemp(a)
    genStrResult(c, n, dest, opcGorge, area)
    c.freeTemp(area)
  of mNLen: genUnaryABC(c, n, dest, opcNLen)
  of mGetImpl: genUnaryABC(c, n, dest, opcGetImpl)
  of mGetImplTransf: genUnaryABC(c, n, dest, opcGetImplTransf)
  of mSymOwner: genUnaryABC(c, n, dest, opcSymOwner)
  of mSymIsInstantiationOf: genBinaryABC(c, n, dest, opcSymIsInstantiationOf)
  of mNChild: genBinaryABC(c, n, dest, opcNChild)
  of mNSetChild: genVoidABC(c, n, dest, opcNSetChild)
  of mNDel: genVoidABC(c, n, dest, opcNDel)
  of mNAdd: genBinaryABC(c, n, dest, opcNAdd)
  of mNAddMultiple:
    let a = c.genx(n[1])
    # the children must be an openArray (data, len):
    var oa: TDest = c.getTempN(2)
    genOpenArrayConv(c, n[2], n[2], oa)
    let b = c.getIntTemp()
    c.gABC(n, opcAddrSlot, b, oa)
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcNAddMultiple, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(oa)
    c.freeTemp(a)
  of mNKind: genUnaryABC(c, n, dest, opcNKind)
  of mNSymKind: genUnaryABC(c, n, dest, opcNSymKind)

  of mNccValue:
    let a = genStrArg(c, n[1])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcNccValue, dest, a)
    c.freeTemp(a)
  of mNccInc, mNcsAdd, mNcsIncl:
    unused(c, n, dest)
    let a = genStrArg(c, n[1])
    let b = c.genx(n[2])
    c.gABC(n, case m
              of mNccInc: opcNccInc
              of mNcsAdd: opcNcsAdd
              else: opcNcsIncl, 0, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNcsLen, mNctLen:
    let a = genStrArg(c, n[1])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, if m == mNcsLen: opcNcsLen else: opcNctLen, dest, a)
    c.freeTemp(a)
  of mNcsAt:
    let a = genStrArg(c, n[1])
    let b = c.genx(n[2])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcNcsAt, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNctPut:
    unused(c, n, dest)
    let a = genStrArg(c, n[1])
    let b = genStrArg(c, n[2])
    let v = c.genx(n[3])
    c.gABC(n, opcNctPut, a, b, v)
    c.freeTemp(v)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNctGet:
    let a = genStrArg(c, n[1])
    let b = genStrArg(c, n[2])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcNctGet, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNctHasNext:
    let a = genStrArg(c, n[1])
    let b = c.genx(n[2])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcNctHasNext, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNctNext:
    let a = genStrArg(c, n[1])
    let b = c.genx(n[2])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcZeroN, dest, TRegister(slotsOf(c, n.typ)))
    let d = c.getIntTemp()
    c.gABC(n, opcAddrSlot, d, dest)
    c.gABCW(n, opcNctNext, d, a, b, uint64(typeHandle(c, n.typ)))
    c.freeTemp(d)
    c.freeTemp(b)
    c.freeTemp(a)

  of mNIntVal: genUnaryABC(c, n, dest, opcNIntVal)
  of mNFloatVal: genUnaryABC(c, n, dest, opcNFloatVal)
  of mNSymbol: genUnaryABC(c, n, dest, opcNSymbol)
  of mNIdent: genUnaryABC(c, n, dest, opcNIdent)
  of mNGetType:
    let tmp = c.genx(n[1])
    if dest < 0: dest = c.getTemp(n.typ)
    case n[0].sym.name.s
    of "getType": c.gABC(n, opcNGetType, dest, tmp)
    of "typeKind": c.gABC(n, opcNTypeKind, dest, tmp, TRegister(c.typeKindDefault))
    of "getTypeInst": c.gABC(n, opcNGetTypeInst, dest, tmp)
    of "getTypeImpl": c.gABC(n, opcNGetTypeImpl, dest, tmp)
    else: c.gABC(n, opcNGetTypeInstSkipAlias, dest, tmp)
    c.freeTemp(tmp)
  of mNSizeOf:
    let imm = case n[0].sym.name.s:
      of "getSize": 0
      of "getAlign": 1
      else: 2 # "getOffset"
    c.genUnaryABI(n, dest, opcNGetSize, imm)
  of mNStrVal:
    let tmp = c.genx(n[1])
    genStrResult(c, n, dest, opcNStrVal, tmp)
    c.freeTemp(tmp)
  of mNSigHash:
    let tmp = c.genx(n[1])
    genStrResult(c, n, dest, opcNSigHash, tmp)
    c.freeTemp(tmp)
  of mNSetIntVal:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetIntVal)
  of mNSetFloatVal:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetFloatVal)
  of mNSetSymbol:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetSymbol)
  of mNSetIdent:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetIdent)
  of mNSetStrVal:
    unused(c, n, dest)
    let a = c.genx(n[1])
    let b = genStrArg(c, n[2])
    c.gABC(n, opcNSetStrVal, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mNNewNimNode: genBinaryABC(c, n, dest, opcNNewNimNode)
  of mNCopyNimNode: genUnaryABC(c, n, dest, opcNCopyNimNode)
  of mNCopyNimTree: genUnaryABC(c, n, dest, opcNCopyNimTree)
  of mNBindSym: genBindSym(c, n, dest)
  of mStrToIdent:
    let a = genStrArg(c, n[1])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcStrToIdent, dest, a)
    c.freeTemp(a)
  of mEqIdent:
    var aIsStr, bIsStr = false
    let a = genEqIdentArg(c, n[1], aIsStr)
    let b = genEqIdentArg(c, n[2], bIsStr)
    if dest < 0: dest = c.getIntTemp()
    let opc = TOpcode(ord(opcEqIdent) + ord(aIsStr) + 2*ord(bIsStr))
    c.gABC(n, opc, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mEqNimrodNode: genBinaryABC(c, n, dest, opcEqNimNode)
  of mSameNodeType: genBinaryABC(c, n, dest, opcSameNodeType)
  of mNLineInfo:
    case n[0].sym.name.s
    of "getFile":
      let tmp = c.genx(n[1])
      genStrResult(c, n, dest, opcNGetLineInfo, tmp, TRegister(byteExcess))
      c.freeTemp(tmp)
    of "getLine": genUnaryABI(c, n, dest, opcNGetLineInfo, 1)
    of "getColumn": genUnaryABI(c, n, dest, opcNGetLineInfo, 2)
    of "copyLineInfo":
      internalAssert c.config, n.len == 3
      unused(c, n, dest)
      genBinaryStmt(c, n, opcNCopyLineInfo)
    of "setLine":
      internalAssert c.config, n.len == 3
      unused(c, n, dest)
      genBinaryStmt(c, n, opcNSetLineInfoLine)
    of "setColumn":
      internalAssert c.config, n.len == 3
      unused(c, n, dest)
      genBinaryStmt(c, n, opcNSetLineInfoColumn)
    of "setFile":
      internalAssert c.config, n.len == 3
      unused(c, n, dest)
      let a = c.genx(n[1])
      let b = genStrArg(c, n[2])
      c.gABC(n, opcNSetLineInfoFile, a, b)
      c.freeTemp(b)
      c.freeTemp(a)
    else: internalAssert c.config, false
  of mNHint, mNWarning, mNError:
    if m == mNError and n.len <= 1:
      # query error condition:
      genStrResult(c, n, dest, opcQueryErrorFlag)
    else:
      unused(c, n, dest)
      let a = genStrArg(c, n[1])
      let b = if n.len > 2: c.genx(n[2]) else: TRegister(0)
      if n.len <= 2:
        c.gABx(n, opcLdImmInt, b, 0)
      c.gABC(n, case m
                of mNHint: opcNHint
                of mNWarning: opcNWarning
                else: opcNError, a, b)
      c.freeTemp(b)
      c.freeTemp(a)
  of mNCallSite:
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcCallSite, dest)
  of mNGenSym:
    let a = c.genx(n[1])
    let b = genStrArg(c, n[2])
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcGenSym, dest, a, b)
    c.freeTemp(b)
    c.freeTemp(a)
  of mMinI, mMaxI, mAbsI, mDotDot:
    c.genCall(n, dest)
  of mExpandToAst:
    if n.len != 2:
      globalError(c.config, n.info, "expandToAst requires 1 argument")
    let arg = n[1]
    if arg.kind in nkCallKinds:
      if dest < 0: dest = c.getTemp(n.typ)
      c.genCall(arg, dest)
    else:
      globalError(c.config, n.info, "expandToAst requires a call expression")
  of mSizeOf, mAlignOf, mOffsetOf:
    # sem folds these unless the type's C layout is unknown; the VM's own
    # layout must not leak:
    let arg = n[1].typ.skipTypes({tyTypeDesc})
    let name = case m
               of mSizeOf: "sizeof"
               of mAlignOf: "alignof"
               else: "offsetof"
    globalError(c.config, n.info, sizeOfLikeMsg(name, tfIncompleteStruct in arg.flags))
  of mRunnableExamples:
    discard "just ignore any call to runnableExamples"
  of mTrace: discard "no cycle collector in the VM"
  of mDestroy:
    # the builtin of liftdestructors frees the payload of a string or seq;
    # injectdestructors' `=destroy` of a type without hooks frees all of its
    # strings and seqs:
    let arg = n[1].skipAddr
    let t = arg.typ.skipTypes(abstractInst+{tyOwned, tyVar, tyLent, tySink})
    let deep = n[0].kind == nkSym and n[0].sym.name.s == "=destroy"
    if t.kind == tyString or (t.kind == tySequence and not (deep and hasPayloads(t.elementType))):
      var loc = genLoc(c, arg)
      let a = addrOfLoc(c, n, loc)
      c.gABC(n, opcPayloadFree, a)
      c.freeLoc(loc)
    elif deep and hasPayloads(t):
      var loc = genLoc(c, arg)
      let a = addrOfLoc(c, n, loc)
      c.gABCW(n, opcDestroyValue, a, 0, 0, uint64(typeHandle(c, t)))
      c.freeLoc(loc)
  of mWasMoved:
    unused(c, n, dest)
    var loc = genLoc(c, n[1].skipAddr)
    zeroLoc(c, n, loc)
  of mMove:
    let arg = n[1].skipAddr
    if n.len == 4:
      # generated by liftdestructors: `move(x, y, destroyCall)`:
      # if x.p != y.p: destroyCall; x = y
      let t = arg.typ.skipTypes(abstractInst+{tyOwned, tyVar, tyLent, tySink})
      if t.kind in {tyString, tySequence}:
        var x = genValueAddr(c, arg)
        var y = genValueAddr(c, n[2])
        let same = c.getIntTemp()
        c.gABC(n, opcSamePayload, same, x.reg, y.reg)
        let lab = c.xjmp(n, opcTJmp, same)
        c.freeTemp(same)
        c.gen(n[3])
        c.patch(lab)
        c.gABCW(n, opcCopyMem, x.reg, y.reg, 0, uint64(vmSize(c, t)))
        c.freeLoc(y)
        c.freeLoc(x)
      else:
        c.gen(n[3])
        genAsgn(c, arg, n[2])
    else:
      var loc = genLoc(c, arg)
      if not (loc.kind == lkFrame and loc.off mod SlotSize == 0):
        discard addrOfLoc(c, n, loc)
      var keep = loc
      keep.isTemp = false
      if dest < 0 or not c.isTemp(dest): dest = c.getTemp(arg.typ)
      loadLoc(c, n, keep, dest)
      if keep.kind == lkFrame and dest == keep.reg:
        # loadLoc aliased the local; we need a real copy:
        let d = c.getTemp(arg.typ)
        let k = slotsOf(c, arg.typ)
        if k == 1: c.gABC(n, opcMov, d, dest)
        else: c.gABC(n, opcMovN, d, dest, TRegister(k))
        dest = d
      zeroLoc(c, n, loc)
  of mEnsureMove:
    gen(c, n[1], dest)
  of mDup:
    # a type without hooks; we copy it with value semantics:
    let arg = n[1].skipAddr
    if dest < 0 or not c.isTemp(dest): dest = c.getTemp(arg.typ)
    var loc = frameLoc(dest, arg.typ, isScalar(c, arg.typ), true, false)
    genStoreValue(c, loc, arg)
  of mAsgn:
    # `=copy` and `=sink` of a type without hooks (see injectdestructors):
    unused(c, n, dest)
    let t = n[1].skipAddr.typ.skipTypes(abstractInst+{tyOwned, tyVar, tyLent, tySink})
    if hasPayloads(t):
      var x = genValueAddr(c, n[1].skipAddr)
      var y = genValueAddr(c, n[2])
      let opc = if n[0].kind == nkSym and n[0].sym.name.s == "=sink": opcSinkValue
                else: opcCopyValue
      c.gABCW(n, opc, x.reg, y.reg, 0, uint64(typeHandle(c, t)))
      c.freeLoc(y)
      c.freeLoc(x)
    else:
      genAsgn(c, n[1].skipAddr, n[2])
  of mAccessEnv:
    var loc = genLoc(c, n[1])
    loc.off += ClosureEnvOffset
    loc.typ = getSysType(c.graph, n.info, tyPointer)
    loc.widened = false
    loc.whole = false
    loadLoc(c, n, loc, dest)
  of mAccessTypeField:
    var loc = genLoc(c, n)
    loadLoc(c, n, loc, dest)
  of mGetTypeInfoV2:
    if dest < 0: dest = c.getIntTemp()
    c.gABx(n, opcLdImmInt, dest, 0)
  of mGCref:
    unused(c, n, dest)
    let p = c.genx(n[1])
    c.gABC(n, opcIncRef, p)
    c.freeTemp(p)
  of mGCunref:
    unused(c, n, dest)
    let p = c.genx(n[1])
    let t = c.getIntTemp()
    c.gABC(n, opcDecRefIsLast, t, p)
    c.freeTemp(t)
    c.freeTemp(p)
  of mNodeId:
    c.genUnaryABC(n, dest, opcNodeId)
  else:
    if n[0].kind == nkSym and n[0].sym.ast != nil and n[0].sym.ast.len > bodyPos and
        getBody(c.graph, n[0].sym).kind != nkEmpty:
      genCall(c, n, dest)
    else:
      globalError(c.config, n.info, "cannot generate code for: " & $m)

# ------------------------- addresses -----------------------------------------

proc genVarOpenArrayArg(c: PCtx; n, x: PNode; dest: var TDest) =
  ## `x` is passed to a `var openArray` parameter: we need an openArray to
  ## point to.
  let oa = c.getTempN(2)
  var d = TDest(oa)
  var src = if x.kind in {nkHiddenStdConv, nkHiddenSubConv, nkConv}: x[1] else: x
  if src.typ.skipTypes(abstractInst).kind in {tyVar, tyLent}:
    src = newTreeIT(nkHiddenDeref, src.info, src.typ.skipTypes(abstractInst).elementType, src)
  if src.typ.skipTypes(abstractInst).kind == tyString:
    var sloc = genLoc(c, src, write = true)
    let sa = addrOfLoc(c, n, sloc)
    c.gABC(n, opcMakeUnique, sa)
    c.freeLoc(sloc)
  genOpenArrayConv(c, n, src, d)
  pinTemp(c, oa)
  if dest < 0: dest = c.getIntTemp()
  c.gABC(n, opcAddrSlot, dest, oa)

proc genAddr(c: PCtx, n: PNode, dest: var TDest) =
  let x = n[0]
  if n.typ != nil and x.typ != nil and
      n.typ.skipTypes(abstractInst).kind in {tyVar, tyLent, tyPtr} and
      n.typ.skipTypes(abstractInst).elementType.skipTypes(abstractInst).kind in {tyOpenArray, tyVarargs} and
      x.typ.skipTypes(abstractInst+{tyVar, tyLent}).kind notin {tyOpenArray, tyVarargs}:
    genVarOpenArrayArg(c, n, x, dest)
    return
  if x.kind in {nkDerefExpr, nkHiddenDeref}:
    # addr(x[]) is x
    gen(c, x[0], dest)
    return
  if x.kind in nkCallKinds and x[0].kind == nkSym and x[0].sym.magic == mSlice and
      x[1].typ.skipTypes(abstractInst+{tyVar, tyLent}).kind == tyString:
    # a slice that is passed to a `var openArray`: copy-on-write first
    var sloc = genLoc(c, x[1], write = true)
    let sa = addrOfLoc(c, n, sloc)
    c.gABC(n, opcMakeUnique, sa)
    c.freeLoc(sloc)
  var loc = genLoc(c, x, write = true)
  let a = addrOfLoc(c, n, loc)
  if dest < 0 and loc.isTemp:
    dest = a
  else:
    if dest < 0: dest = c.getIntTemp()
    c.gABC(n, opcMov, dest, a)
    c.freeLoc(loc)

# ------------------------- the dispatcher ------------------------------------

proc genRangeChck(c: PCtx; n: PNode; dest: var TDest) =
  if skipTypes(n.typ, abstractVar).kind in {tyUInt..tyUInt64}:
    genConv(c, n, n[0], dest)
  else:
    let tmp0 = c.genx(n[0])
    let tmp1 = c.genx(n[1])
    let tmp2 = c.genx(n[2])
    c.gABC(n, if n.kind == nkChckRangeF: opcRangeChckF else: opcRangeChck, tmp0, tmp1, tmp2)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    if dest >= 0:
      c.gABC(n, opcMov, dest, tmp0)
      c.freeTemp(tmp0)
    else:
      dest = tmp0

proc gen(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags = {}) =
  when defined(nimCompilerStacktraceHints):
    setFrameMsg c.config$n.info & " " & $n.kind & " " & $flags
  case n.kind
  of nkSym:
    let s = n.sym
    case s.kind
    of skVar, skForVar, skTemp, skLet, skResult:
      var loc = genLoc(c, n)
      loadLoc(c, n, loc, dest)
    of skParam:
      if s.typ.kind == tyTypeDesc:
        genTypeLit(c, n, s.typ.skipTypes({tyTypeDesc}), dest)
      else:
        var loc = genLoc(c, n)
        loadLoc(c, n, loc, dest)
    of skProc, skFunc, skConverter, skMacro, skTemplate, skMethod, skIterator:
      # 'skTemplate' is only allowed for 'getAst' support:
      if s.kind == skIterator and s.typ.callConv == TCallingConvention.ccClosure:
        globalError(c.config, n.info, "Closure iterators are not supported by VM!")
      discard procIsCallback(c, s)
      genProcLit(c, n, s, dest)
    of skConst:
      let constVal = if s.astdef != nil: s.astdef else: s.typ.n
      if isScalar(c, s.typ):
        genLitInto(c, constVal, s.typ, dest)
      else:
        var loc = genLoc(c, n)
        loadLoc(c, n, loc, dest)
    of skEnumField:
      # we never reach this case - as of the time of this comment,
      # skEnumField is folded to an int in semfold.nim, but this code
      # remains for robustness
      if dest < 0: dest = c.getIntTemp()
      genLdImm(c, n, dest, s.position)
    of skType:
      genTypeLit(c, n, s.typ, dest)
    of skGenericParam:
      if c.prc.sym != nil and c.prc.sym.kind == skMacro:
        var loc = genLoc(c, n)
        loadLoc(c, n, loc, dest)
      else:
        globalError(c.config, n.info, "cannot generate code for: " & s.name.s)
    else:
      globalError(c.config, n.info, "cannot generate code for: " & s.name.s)
  of nkCallKinds:
    if n[0].kind == nkSym:
      let s = n[0].sym
      if s.magic != mNone:
        genMagic(c, n, dest, flags, s.magic)
      elif s.kind == skMethod:
        localError(c.config, n.info, "cannot call method " & s.name.s &
          " at compile time")
      else:
        genCall(c, n, dest)
        clearDest(c, n, dest)
    else:
      genCall(c, n, dest)
      clearDest(c, n, dest)
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit:
    genLit(c, n, dest)
  of nkNilLit:
    if n.typ == nil or n.typ.kind == tyNil:
      if dest < 0: dest = c.getIntTemp()
      c.gABx(n, opcLdImmInt, dest, 0)
    elif not n.typ.isEmptyType: genLit(c, n, dest)
    else: unused(c, n, dest)
  of nkAsgn, nkFastAsgn, nkSinkAsgn:
    unused(c, n, dest)
    genAsgn(c, n[0], n[1])
  of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr, nkDerefExpr, nkHiddenDeref:
    if n.kind == nkBracketExpr and isTypeExpr(n[0]):
      genTypeLit(c, n, n.typ, dest)
    else:
      var loc = genLoc(c, n)
      loadLoc(c, n, loc, dest)
  of nkAddr, nkHiddenAddr: genAddr(c, n, dest)
  of nkIfStmt, nkIfExpr: genIf(c, n, dest)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n[0][1], dest)
  of nkCaseStmt: genCase(c, n, dest)
  of nkWhileStmt:
    unused(c, n, dest)
    genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n, dest)
  of nkReturnStmt:
    genReturn(c, n)
  of nkRaiseStmt:
    genRaise(c, n)
  of nkBreakStmt:
    genBreak(c, n)
  of nkTryStmt, nkHiddenTryStmt: genTry(c, n, dest)
  of nkStmtList:
    for x in n: gen(c, x)
  of nkStmtListExpr:
    for i in 0..<n.len-1: gen(c, n[i])
    gen(c, n[^1], dest, flags)
  of nkPragmaBlock:
    gen(c, n.lastSon, dest, flags)
  of nkDiscardStmt:
    unused(c, n, dest)
    gen(c, n[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    genConv(c, n, n[1], dest)
  of nkObjDownConv, nkObjUpConv:
    gen(c, n[0], dest)
  of nkVarSection, nkLetSection:
    unused(c, n, dest)
    genVarSection(c, n)
  of nkLambdaKinds:
    genProcLit(c, n, n[namePos].sym, dest)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    genRangeChck(c, n, dest)
  of nkEmpty, nkCommentStmt, nkTypeSection, nkConstSection, nkPragma,
     nkTemplateDef, nkIncludeStmt, nkImportStmt, nkFromStmt, nkExportStmt,
     nkMixinStmt, nkBindStmt, declarativeDefs, nkMacroDef:
    unused(c, n, dest)
  of nkStringToCString:
    var tmp = n
    genConv(c, tmp, n[0], dest)
  of nkCStringToString:
    genConv(c, n, n[0], dest)
  of nkBracket: genArrayConstr(c, n, dest)
  of nkCurly: genSetConstr(c, n, dest)
  of nkObjConstr: genObjConstr(c, n, dest)
  of nkPar, nkTupleConstr: genTupleConstr(c, n, dest)
  of nkClosure: genClosureConstr(c, n, dest)
  of nkCast: genCast(c, n, dest)
  of nkTypeOfExpr, nkType:
    genTypeLit(c, n, n.typ, dest)
  of nkComesFrom:
    discard "XXX to implement for better stack traces"
  else:
    if n.typ != nil and n.typ.isCompileTimeOnly:
      genTypeLit(c, n, n.typ, dest)
    else:
      globalError(c.config, n.info, "cannot generate VM code for " & $n)

# ------------------------- top level, procs ----------------------------------

proc removeLastEof(c: PCtx) =
  # the last word is not necessarily an instruction (after an aborted
  # code generation it can be the extra word of a large instruction):
  let last = c.code.len-1
  if last >= 0 and c.lastEof == last:
    # overwrite last EOF:
    assert c.code.len == c.debug.len
    c.code.setLen(last)
    c.debug.setLen(last)

proc resolveNimvm(n: PNode): PNode =
  ## replaces `when nimvm` by its VM branch. `injectDestructorCalls` only
  ## processes the runtime branch. Also removes `runnableExamples` (which
  ## `nim doc` keeps, unchecked) since injection cannot deal with them.
  case n.kind
  of nkCallKinds:
    if n[0].kind == nkSym and n[0].sym.magic == mRunnableExamples:
      result = newNodeI(nkEmpty, n.info)
    else:
      result = n
      for i in 0..<n.len:
        result[i] = resolveNimvm(n[i])
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    result = resolveNimvm(n[0][1])
  of nkNone..nkNilLit, nkLambdaKinds, nkTypeSection, nkConstSection,
     nkTemplateDef, nkMacroDef, nkMethodDef, nkProcDef, nkFuncDef,
     nkConverterDef, nkIteratorDef:
    result = n
  else:
    result = n
    for i in 0..<n.len:
      result[i] = resolveNimvm(n[i])

proc vmInjectDestructors(c: PCtx; owner: PSym; n: PNode): PNode =
  ## `injectDestructorCalls` registers destructors and initializers of
  ## globals for the backend; these must not leak out of the VM: VM globals
  ## are initialized lazily and never destroyed.
  let oldDestructors = c.graph.globalDestructors.len
  let oldProcGlobals = c.graph.procGlobals.len
  let n = resolveNimvm(copyTree(n))
  # `injectDestructorCalls` drops the declarations of compile-time variables
  # since the backend has no use for them. But the VM has.
  # The locals of a `static` block inside a proc are owned by the proc but
  # `injectDestructorCalls` only treats the locals of `owner` as locals:
  var ctVars: seq[PSym] = @[]
  var reowned: seq[(PSym, PSym)] = @[]
  proc collectCtVars(n: PNode; res: var seq[PSym]) =
    case n.kind
    of nkVarSection, nkLetSection:
      for it in n:
        if it.kind in {nkIdentDefs, nkVarTuple}:
          for j in 0..<it.len-2:
            let v = if it[j].kind == nkPragmaExpr: it[j][0] else: it[j]
            if v.kind == nkSym and sfCompileTime in v.sym.flags: res.add v.sym
            if v.kind == nkSym and owner.kind == skModule and
                v.sym.owner != nil and v.sym.owner != owner and
                v.sym.owner.kind != skModule and not v.sym.isGlobal:
              reowned.add (v.sym, v.sym.owner)
              v.sym.setOwner owner
          collectCtVars(it[^1], res)
    of nkNone..nkNilLit, nkLambdaKinds, nkTypeSection, nkConstSection,
       nkTemplateDef, nkMacroDef, nkMethodDef, nkProcDef, nkFuncDef,
       nkConverterDef, nkIteratorDef:
      discard
    else:
      for ch in n: collectCtVars(ch, res)
  collectCtVars(n, ctVars)
  for v in ctVars: v.flagsImpl.excl sfCompileTime
  defer:
    for v in ctVars: v.flagsImpl.incl sfCompileTime
    for (v, o) in reowned: v.setOwner o
  let oldInjecting = c.graph.vmInjecting
  c.graph.vmInjecting = true
  result = injectDestructorCalls(c.graph, c.idgen, owner, n)
  c.graph.vmInjecting = oldInjecting
  when defined(nimVmListing):
    echo "INJECTED ", owner.name.s, "\n", renderTree(result, {renderIds})
  c.graph.globalDestructors.setLen oldDestructors
  c.graph.procGlobals.setLen oldProcGlobals

proc resetTopLevel(c: PCtx) =
  ## top level code is executed right after it was generated; its locals
  ## and temporaries are dead afterwards.
  c.prc.regInfo.setLen 0
  c.prc.locals.clear()
  c.prc.addrTaken = initIntSet()

proc prepareTopLevel(c: PCtx; n: PNode): PNode =
  result = n
  if usesNewRuntime(c):
    result = vmInjectDestructors(c, c.module, n)
    c.prc.injected = true
  collectAddrTaken(c, result, c.prc.addrTaken)

proc genStmt*(c: PCtx; n: PNode): int =
  c.removeLastEof
  c.resetTopLevel
  result = c.code.len
  let n = prepareTopLevel(c, n)
  var d: TDest = -1
  c.gen(n, d)
  if d >= 0:
    # for discardable calls etc, otherwise not valid
    freeTemp(c, d)
  c.gABC(n, opcEof)

proc genExpr*(c: PCtx; n: PNode, requiresValue = true): int =
  if n.typ != nil and n.typ.kind == tyError:
    # (the old VM's message, `nim check` tests rely on it)
    globalError(c.config, n.info, "VM problem: dest register is not set")
  c.removeLastEof
  c.resetTopLevel
  result = c.code.len
  if n.typ != nil and not isEmptyType(n.typ) and n.typ.kind != tyTypeDesc and
      usesNewRuntime(c):
    # `:vmres = n` so that the injected destructors do not destroy the
    # result:
    let res = newSym(skTemp, getIdent(c.cache, ":vmres"), c.idgen, c.module, n.info)
    res.typ = n.typ
    let slot = setSlot(c, res, n)
    let boxed = c.prc.locals[res.itemId].boxed
    let body = prepareTopLevel(c, newTreeI(nkAsgn, n.info, newSymNode(res), n))
    c.gen(body)
    c.gABC(n, if boxed: opcEofBoxed else: opcEof, TRegister(slot))
    return
  let n = if requiresValue: n else: prepareTopLevel(c, n)
  # locals whose address is taken must live in memory:
  if requiresValue: collectAddrTaken(c, n, c.prc.addrTaken)
  var d: TDest = -1
  c.gen(n, d)
  if d < 0:
    if requiresValue:
      globalError(c.config, n.info, "VM problem: dest register is not set for " &
                  $n.kind & " " & renderTree(n))
    d = 0
  c.gABC(n, opcEof, d)

proc genProc(c: PCtx; s: PSym): VmProcInfo =
  result = c.procToCodePos.getOrDefault(s.id, NoVmProcInfo)
  if result.frameSlots < 0:
    # compile-time execution consumes this routine's BODY: under IC that is a
    # NeedsImpl dependency on the routine's home module (iface-cookie gating
    # alone would miss body-only edits, e.g. `const x = dep.foo()`).
    recordIcImplDep(c.graph, s)
    let last = c.code.len-1
    var eofInstr = default(TInstr)
    if last >= 0 and c.lastEof == last:
      eofInstr = c.code[last]
      c.code.setLen(last)
      c.debug.setLen(last)
    result.pc = (c.code.len+1).int32 # skip the jump instruction
    # thanks to the jmp we can add top level statements easily and also nest
    # procs easily:
    inc c.graph.inVMTransform
    var body = transformBody(c.graph, c.idgen, s, if isCompileTimeProc(s): {} else: {useCache})
    let injected = usesNewRuntime(c) and sfInjectDestructors in s.flags
    if injected:
      body = vmInjectDestructors(c, s, body)
    dec c.graph.inVMTransform
    let procStart = c.xjmp(body, opcJmp, 0)
    var p = PProc(blocks: @[], sym: s, injected: injected)
    let oldPrc = c.prc
    c.prc = p
    collectAddrTaken(c, body, p.addrTaken)
    # the frame: result, parameters, closure environment, locals
    let isMacro = s.kind == skMacro
    let L = callLayout(c, s.typ, isMacro, s.info)
    discard getFreeRange(c, max(L.resultSlots, 1), false)
    let ret = s.typ.returnType
    let resultInMem = p.resultAddrTaken and L.resultSlots == 1 and ret != nil and
                      isScalar(c, ret.skipTypes({tyTypeDesc}))
    if s.ast != nil and s.ast.len > resultPos and s.ast[resultPos].kind == nkSym:
      let rs = s.ast[resultPos].sym
      p.locals[rs.itemId] = LocalInfo(slot: 0, inMemory: resultInMem)
      p.resultInfo = p.locals[rs.itemId]
      p.hasResult = true
    elif (ret != nil and not isEmptyType(ret)) or isMacro:
      p.resultInfo = LocalInfo(slot: 0, inMemory: resultInMem)
      p.hasResult = true
    let firstParam = max(L.resultSlots, 1)
    if L.paramSlots > 0:
      discard getFreeRange(c, L.paramSlots, false)
    let params = s.typ.n
    for i in 1..<params.len:
      if params[i].kind != nkSym: continue
      let ps = params[i].sym
      let slot = TRegister(firstParam + L.paramOffsets[i-1])
      let inMem = isScalar(c, L.paramTypes[i-1]) and
                  (ps.id in p.addrTaken or ps.position in p.paramAddrTaken)
      let info = LocalInfo(slot: slot, inMemory: inMem)
      p.locals[ps.itemId] = info
      if p.paramSlots.len <= ps.position: p.paramSlots.setLen(ps.position+1)
      p.paramSlots[ps.position] = info
    # the parameters of macros are copies; they have no `addrTaken` info of
    # their own, so we look at the positions:
    var envSlot = -1
    if tfCapturesEnv in s.typ.flags or L.isClosure:
      envSlot = getFreeRange(c, 1, false)
      let env = getEnvParam(s)
      if env != nil: addLocal(c, env, TRegister(envSlot))
    # allocate additional space for any generically bound parameters
    if isMacro and s.isGenericRoutineStrict:
      let gp = s.ast[genericParamsPos]
      for i in 0..<gp.len:
        let gt = macroParamType(c, gp[i].sym.typ, s.info)
        let slot = getFreeRange(c, slotsOf(c, gt), false)
        p.locals[gp[i].sym.itemId] = LocalInfo(slot: slot)
        result.genericParamSlots.add int32(slot)
    # scalar parameters whose address is taken are kept in memory format:
    for i in 1..<params.len:
      if params[i].kind != nkSym: continue
      let ps = params[i].sym
      let info = p.locals[ps.itemId]
      if info.inMemory:
        c.genStSlot(body, info.slot, info.slot, mk(c, L.paramTypes[i-1]))
    # `result` starts with valid type headers (like in the C backend), also
    # when it is only assigned field by field:
    if ret != nil and s.ast != nil and s.ast.len > resultPos and
        s.ast[resultPos].kind == nkSym and needsInitObj(c, ret):
      var loc = symLoc(c, s.ast[resultPos])
      let a = addrOfLoc(c, body, loc)
      c.gABCW(body, opcInitObj, a, 0, 0, uint64(typeHandle(c, ret)))
      c.freeLoc(loc)
    gen(c, body)
    # generate final 'return' statement:
    genRet(c, body)
    c.patch(procStart)
    c.gABC(body, eofInstr.opcode, eofInstr.regA)
    result.frameSlots = c.prc.regInfo.len.int32
    result.resultSlots = L.resultSlots.int32
    result.paramSlots = L.paramSlots.int32
    result.envSlot = envSlot.int32
    c.procToCodePos[s.id] = result
    c.prc = oldPrc
    when defined(nimVmListing):
      echo "PROC ", s.name.s, " frame: ", result.frameSlots, " result: ", result.resultSlots,
        " params: ", result.paramSlots
      c.echoCode result.pc
