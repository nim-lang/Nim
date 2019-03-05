#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the code generator for the VM.

# Important things to remember:
# - The VM does not distinguish between definitions ('var x = y') and
#   assignments ('x = y'). For simple data types that fit into a register
#   this doesn't matter. However it matters for strings and other complex
#   types that use the 'node' field; the reason is that slots are
#   re-used in a register based VM. Example:
#
# .. code-block:: nim
#   let s = a & b  # no matter what, create fresh node
#   s = a & b  # no matter what, keep the node
#
# Also *stores* into non-temporary memory need to perform deep copies:
# a.b = x.y
# We used to generate opcAsgn for the *load* of 'x.y' but this is clearly
# wrong! We need to produce opcAsgn (the copy) for the *store*. This also
# solves the opcLdConst vs opcAsgnConst issue. Of course whether we need
# this copy depends on the involved types.

import
  strutils, ast, astalgo, types, msgs, renderer, vmdef,
  trees, intsets, magicsys, options, lowerings, lineinfos, transf
import platform
from os import splitFile

const
  debugEchoCode* = defined(nimVMDebug)

when debugEchoCode:
  import asciitables
when hasFFI:
  import evalffi

type
  TGenFlag = enum
    gfNode # Affects how variables are loaded - always loads as rkNode
    gfNodeAddr # Affects how variables are loaded - always loads as rkNodeAddr
  TGenFlags = set[TGenFlag]

proc debugInfo(c: PCtx; info: TLineInfo): string =
  result = toFileLineCol(c.config, info)

proc codeListing(c: PCtx, result: var string, start=0; last = -1) =
  ## for debugging purposes
  # first iteration: compute all necessary labels:
  var jumpTargets = initIntSet()
  let last = if last < 0: c.code.len-1 else: min(last, c.code.len-1)
  for i in start..last:
    let x = c.code[i]
    if x.opcode in relativeJumps:
      jumpTargets.incl(i+x.regBx-wordExcess)

  template toStr(opc: TOpcode): string = ($opc).substr(3)

  result.add "code listing:\n"
  var i = start
  while i <= last:
    if i in jumpTargets: result.addf("L$1:\n", i)
    let x = c.code[i]

    result.add($i)
    let opc = opcode(x)
    if opc in {opcIndCall, opcIndCallAsgn}:
      result.addf("\t$#\tr$#, r$#, nargs:$#", opc.toStr, x.regA,
                  x.regB, x.regC)
    elif opc in {opcConv, opcCast}:
      let y = c.code[i+1]
      let z = c.code[i+2]
      result.addf("\t$#\tr$#, r$#, $#, $#", opc.toStr, x.regA, x.regB,
        c.types[y.regBx-wordExcess].typeToString,
        c.types[z.regBx-wordExcess].typeToString)
      inc i, 2
    elif opc < firstABxInstr:
      result.addf("\t$#\tr$#, r$#, r$#", opc.toStr, x.regA,
                  x.regB, x.regC)
    elif opc in relativeJumps + {opcTry}:
      result.addf("\t$#\tr$#, L$#", opc.toStr, x.regA,
                  i+x.regBx-wordExcess)
    elif opc in {opcExcept}:
      let idx = x.regBx-wordExcess
      result.addf("\t$#\t$#, $#", opc.toStr, x.regA, $idx)
    elif opc in {opcLdConst, opcAsgnConst}:
      let idx = x.regBx-wordExcess
      result.addf("\t$#\tr$#, $# ($#)", opc.toStr, x.regA,
        c.constants[idx].renderTree, $idx)
    elif opc in {opcMarshalLoad, opcMarshalStore}:
      let y = c.code[i+1]
      result.addf("\t$#\tr$#, r$#, $#", opc.toStr, x.regA, x.regB,
        c.types[y.regBx-wordExcess].typeToString)
      inc i
    else:
      result.addf("\t$#\tr$#, $#", opc.toStr, x.regA, x.regBx-wordExcess)
    result.add("\t#")
    result.add(debugInfo(c, c.debug[i]))
    result.add("\n")
    inc i
  when debugEchoCode:
    result = result.alignTable

proc echoCode*(c: PCtx; start=0; last = -1) {.deprecated.} =
  var buf = ""
  codeListing(c, buf, start, last)
  echo buf

proc gABC(ctx: PCtx; n: PNode; opc: TOpcode; a, b, c: TRegister = 0) =
  ## Takes the registers `b` and `c`, applies the operation `opc` to them, and
  ## stores the result into register `a`
  ## The node is needed for debug information
  assert opc.ord < 255
  let ins = (opc.uint32 or (a.uint32 shl 8'u32) or
                           (b.uint32 shl 16'u32) or
                           (c.uint32 shl 24'u32)).TInstr
  when false:
    if ctx.code.len == 43:
      writeStackTrace()
      echo "generating ", opc
  ctx.code.add(ins)
  ctx.debug.add(n.info)

proc gABI(c: PCtx; n: PNode; opc: TOpcode; a, b: TRegister; imm: BiggestInt) =
  # Takes the `b` register and the immediate `imm`, appies the operation `opc`,
  # and stores the output value into `a`.
  # `imm` is signed and must be within [-128, 127]
  if imm >= -128 and imm <= 127:
    let ins = (opc.uint32 or (a.uint32 shl 8'u32) or
                             (b.uint32 shl 16'u32) or
                             (imm+byteExcess).uint32 shl 24'u32).TInstr
    c.code.add(ins)
    c.debug.add(n.info)
  else:
    localError(c.config, n.info,
      "VM: immediate value does not fit into an int8")

proc gABx(c: PCtx; n: PNode; opc: TOpcode; a: TRegister = 0; bx: int) =
  # Applies `opc` to `bx` and stores it into register `a`
  # `bx` must be signed and in the range [-32768, 32767]
  when false:
    if c.code.len == 43:
      writeStackTrace()
      echo "generating ", opc

  if bx >= -32768 and bx <= 32767:
    let ins = (opc.uint32 or a.uint32 shl 8'u32 or
              (bx+wordExcess).uint32 shl 16'u32).TInstr
    c.code.add(ins)
    c.debug.add(n.info)
  else:
    localError(c.config, n.info,
      "VM: immediate value does not fit into an int16")

proc xjmp(c: PCtx; n: PNode; opc: TOpcode; a: TRegister = 0): TPosition =
  #assert opc in {opcJmp, opcFJmp, opcTJmp}
  result = TPosition(c.code.len)
  gABx(c, n, opc, a, 0)

proc genLabel(c: PCtx): TPosition =
  result = TPosition(c.code.len)
  #c.jumpTargets.incl(c.code.len)

proc jmpBack(c: PCtx, n: PNode, p = TPosition(0)) =
  let dist = p.int - c.code.len
  internalAssert(c.config, -0x7fff < dist and dist < 0x7fff)
  gABx(c, n, opcJmpBack, 0, dist)

proc patch(c: PCtx, p: TPosition) =
  # patch with current index
  let p = p.int
  let diff = c.code.len - p
  #c.jumpTargets.incl(c.code.len)
  internalAssert(c.config, -0x7fff < diff and diff < 0x7fff)
  let oldInstr = c.code[p]
  # opcode and regA stay the same:
  c.code[p] = ((oldInstr.uint32 and 0xffff'u32).uint32 or
               uint32(diff+wordExcess) shl 16'u32).TInstr

proc getSlotKind(t: PType): TSlotKind =
  case t.skipTypes(abstractRange-{tyTypeDesc}).kind
  of tyBool, tyChar, tyEnum, tyOrdinal, tyInt..tyInt64, tyUInt..tyUInt64:
    slotTempInt
  of tyString, tyCString:
    slotTempStr
  of tyFloat..tyFloat128:
    slotTempFloat
  else:
    slotTempComplex

const
  HighRegisterPressure = 40

proc bestEffort(c: PCtx): TLineInfo =
  if c.prc != nil and c.prc.sym != nil:
    c.prc.sym.info
  else:
    c.module.info

proc getTemp(cc: PCtx; tt: PType): TRegister =
  let typ = tt.skipTypesOrNil({tyStatic})
  let c = cc.prc
  # we prefer the same slot kind here for efficiency. Unfortunately for
  # discardable return types we may not know the desired type. This can happen
  # for e.g. mNAdd[Multiple]:
  let k = if typ.isNil: slotTempComplex else: typ.getSlotKind
  for i in 0 .. c.maxSlots-1:
    if c.slots[i].kind == k and not c.slots[i].inUse:
      c.slots[i].inUse = true
      return TRegister(i)

  # if register pressure is high, we re-use more aggressively:
  if c.maxSlots >= HighRegisterPressure and false:
    for i in 0 .. c.maxSlots-1:
      if not c.slots[i].inUse:
        c.slots[i] = (inUse: true, kind: k)
        return TRegister(i)
  if c.maxSlots >= high(TRegister):
    globalError(cc.config, cc.bestEffort, "VM problem: too many registers required")
  result = TRegister(c.maxSlots)
  c.slots[c.maxSlots] = (inUse: true, kind: k)
  inc c.maxSlots

proc freeTemp(c: PCtx; r: TRegister) =
  let c = c.prc
  if c.slots[r].kind in {slotSomeTemp..slotTempComplex}:
    # this seems to cause https://github.com/nim-lang/Nim/issues/10647
    c.slots[r].inUse = false

proc getTempRange(cc: PCtx; n: int; kind: TSlotKind): TRegister =
  # if register pressure is high, we re-use more aggressively:
  let c = cc.prc
  if c.maxSlots >= HighRegisterPressure or c.maxSlots+n >= high(TRegister):
    for i in 0 .. c.maxSlots-n:
      if not c.slots[i].inUse:
        block search:
          for j in i+1 .. i+n-1:
            if c.slots[j].inUse: break search
          result = TRegister(i)
          for k in result .. result+n-1: c.slots[k] = (inUse: true, kind: kind)
          return
  if c.maxSlots+n >= high(TRegister):
    globalError(cc.config, cc.bestEffort, "VM problem: too many registers required")
  result = TRegister(c.maxSlots)
  inc c.maxSlots, n
  for k in result .. result+n-1: c.slots[k] = (inUse: true, kind: kind)

proc freeTempRange(c: PCtx; start: TRegister, n: int) =
  for i in start .. start+n-1: c.freeTemp(TRegister(i))

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
  c.prc.blocks.add TBlock(label: labl, fixups: @[])
  body
  popBlock(c, oldLen)

proc gen(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags = {})
proc gen(c: PCtx; n: PNode; dest: TRegister; flags: TGenFlags = {}) =
  var d: TDest = dest
  gen(c, n, d, flags)
  #internalAssert c.config, d == dest # issue #7407

proc gen(c: PCtx; n: PNode; flags: TGenFlags = {}) =
  var tmp: TDest = -1
  gen(c, n, tmp, flags)
  #if n.typ.isEmptyType: InternalAssert tmp < 0

proc genx(c: PCtx; n: PNode; flags: TGenFlags = {}): TRegister =
  var tmp: TDest = -1
  gen(c, n, tmp, flags)
  #internalAssert c.config, tmp >= 0 # 'nim check' does not like this internalAssert.
  if tmp >= 0:
    result = TRegister(tmp)

proc clearDest(c: PCtx; n: PNode; dest: var TDest) {.inline.} =
  # stmt is different from 'void' in meta programming contexts.
  # So we only set dest to -1 if 'void':
  if dest >= 0 and (n.typ.isNil or n.typ.kind == tyVoid):
    c.freeTemp(dest)
    dest = -1

proc isNotOpr(n: PNode): bool =
  n.kind in nkCallKinds and n.sons[0].kind == nkSym and
    n.sons[0].sym.magic == mNot

proc isTrue(n: PNode): bool =
  n.kind == nkSym and n.sym.kind == skEnumField and n.sym.position != 0 or
    n.kind == nkIntLit and n.intVal != 0

proc genWhile(c: PCtx; n: PNode) =
  # L1:
  #   cond, tmp
  #   fjmp tmp, L2
  #   body
  #   jmp L1
  # L2:
  let L1 = c.genLabel
  withBlock(nil):
    if isTrue(n.sons[0]):
      c.gen(n.sons[1])
      c.jmpBack(n, L1)
    elif isNotOpr(n.sons[0]):
      var tmp = c.genx(n.sons[0].sons[1])
      let L2 = c.xjmp(n, opcTJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n.sons[1])
      c.jmpBack(n, L1)
      c.patch(L2)
    else:
      var tmp = c.genx(n.sons[0])
      let L2 = c.xjmp(n, opcFJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n.sons[1])
      c.jmpBack(n, L1)
      c.patch(L2)

proc genBlock(c: PCtx; n: PNode; dest: var TDest) =
  let oldRegisterCount = c.prc.maxSlots
  withBlock(n.sons[0].sym):
    c.gen(n.sons[1], dest)

  for i in oldRegisterCount ..< c.prc.maxSlots:
    if c.prc.slots[i].kind in {slotFixedVar, slotFixedLet}:
      c.prc.slots[i] = (inUse: false, kind: slotEmpty)

  c.clearDest(n, dest)

proc genBreak(c: PCtx; n: PNode) =
  let L1 = c.xjmp(n, opcJmp)
  if n.sons[0].kind == nkSym:
    #echo cast[int](n.sons[0].sym)
    for i in countdown(c.prc.blocks.len-1, 0):
      if c.prc.blocks[i].label == n.sons[0].sym:
        c.prc.blocks[i].fixups.add L1
        return
    globalError(c.config, n.info, "VM problem: cannot find 'break' target")
  else:
    c.prc.blocks[c.prc.blocks.high].fixups.add L1

proc genIf(c: PCtx, n: PNode; dest: var TDest) =
  #  if (!expr1) goto L1;
  #    thenPart
  #    goto LEnd
  #  L1:
  #  if (!expr2) goto L2;
  #    thenPart2
  #    goto LEnd
  #  L2:
  #    elsePart
  #  Lend:
  if dest < 0 and not isEmptyType(n.typ): dest = getTemp(c, n.typ)
  var endings: seq[TPosition] = @[]
  for i in countup(0, len(n) - 1):
    var it = n.sons[i]
    if it.len == 2:
      withTemp(tmp, it.sons[0].typ):
        var elsePos: TPosition
        if isNotOpr(it.sons[0]):
          c.gen(it.sons[0].sons[1], tmp)
          elsePos = c.xjmp(it.sons[0].sons[1], opcTJmp, tmp) # if true
        else:
          c.gen(it.sons[0], tmp)
          elsePos = c.xjmp(it.sons[0], opcFJmp, tmp) # if false
      c.clearDest(n, dest)
      c.gen(it.sons[1], dest) # then part
      if i < sonsLen(n)-1:
        endings.add(c.xjmp(it.sons[1], opcJmp, 0))
      c.patch(elsePos)
    else:
      c.clearDest(n, dest)
      c.gen(it.sons[0], dest)
  for endPos in endings: c.patch(endPos)
  c.clearDest(n, dest)

proc genAndOr(c: PCtx; n: PNode; opc: TOpcode; dest: var TDest) =
  #   asgn dest, a
  #   tjmp|fjmp L1
  #   asgn dest, b
  # L1:
  if dest < 0: dest = getTemp(c, n.typ)
  c.gen(n.sons[1], dest)
  let L1 = c.xjmp(n, opc, dest)
  c.gen(n.sons[2], dest)
  c.patch(L1)

proc canonValue*(n: PNode): PNode =
  result = n

proc rawGenLiteral(c: PCtx; n: PNode): int =
  result = c.constants.len
  #assert(n.kind != nkCall)
  n.flags.incl nfAllConst
  c.constants.add n.canonValue
  internalAssert c.config, result < 0x7fff

proc sameConstant*(a, b: PNode): bool =
  result = false
  if a == b:
    result = true
  elif a != nil and b != nil and a.kind == b.kind:
    case a.kind
    of nkSym: result = a.sym == b.sym
    of nkIdent: result = a.ident.id == b.ident.id
    of nkCharLit..nkUInt64Lit: result = a.intVal == b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.floatVal == b.floatVal
    of nkStrLit..nkTripleStrLit: result = a.strVal == b.strVal
    of nkType, nkNilLit: result = a.typ == b.typ
    of nkEmpty: result = true
    else:
      if sonsLen(a) == sonsLen(b):
        for i in countup(0, sonsLen(a) - 1):
          if not sameConstant(a.sons[i], b.sons[i]): return
        result = true

proc genLiteral(c: PCtx; n: PNode): int =
  # types do not matter here:
  for i in 0 ..< c.constants.len:
    if sameConstant(c.constants[i], n): return i
  result = rawGenLiteral(c, n)

proc unused(c: PCtx; n: PNode; x: TDest) {.inline.} =
  if x >= 0:
    #debug(n)
    globalError(c.config, n.info, "not unused")

proc genCase(c: PCtx; n: PNode; dest: var TDest) =
  #  if (!expr1) goto L1;
  #    thenPart
  #    goto LEnd
  #  L1:
  #  if (!expr2) goto L2;
  #    thenPart2
  #    goto LEnd
  #  L2:
  #    elsePart
  #  Lend:
  if not isEmptyType(n.typ):
    if dest < 0: dest = getTemp(c, n.typ)
  else:
    unused(c, n, dest)
  var endings: seq[TPosition] = @[]
  withTemp(tmp, n.sons[0].typ):
    c.gen(n.sons[0], tmp)
    # branch tmp, codeIdx
    # fjmp   elseLabel
    for i in 1 ..< n.len:
      let it = n.sons[i]
      if it.len == 1:
        # else stmt:
        c.gen(it.sons[0], dest)
      else:
        let b = rawGenLiteral(c, it)
        c.gABx(it, opcBranch, tmp, b)
        let elsePos = c.xjmp(it.lastSon, opcFJmp, tmp)
        c.gen(it.lastSon, dest)
        if i < sonsLen(n)-1:
          endings.add(c.xjmp(it.lastSon, opcJmp, 0))
        c.patch(elsePos)
      c.clearDest(n, dest)
  for endPos in endings: c.patch(endPos)

proc genType(c: PCtx; typ: PType): int =
  for i, t in c.types:
    if sameType(t, typ): return i
  result = c.types.len
  c.types.add(typ)
  internalAssert(c.config, result <= 0x7fff)

proc genTry(c: PCtx; n: PNode; dest: var TDest) =
  if dest < 0 and not isEmptyType(n.typ): dest = getTemp(c, n.typ)
  var endings: seq[TPosition] = @[]
  let ehPos = c.xjmp(n, opcTry, 0)
  c.gen(n.sons[0], dest)
  c.clearDest(n, dest)
  # Add a jump past the exception handling code
  endings.add(c.xjmp(n, opcJmp, 0))
  # This signals where the body ends and where the exception handling begins
  c.patch(ehPos)
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if it.kind != nkFinally:
      var blen = len(it)
      # first opcExcept contains the end label of the 'except' block:
      let endExcept = c.xjmp(it, opcExcept, 0)
      for j in countup(0, blen - 2):
        assert(it.sons[j].kind == nkType)
        let typ = it.sons[j].typ.skipTypes(abstractPtrs-{tyTypeDesc})
        c.gABx(it, opcExcept, 0, c.genType(typ))
      if blen == 1:
        # general except section:
        c.gABx(it, opcExcept, 0, 0)
      c.gen(it.lastSon, dest)
      c.clearDest(n, dest)
      if i < sonsLen(n):
        endings.add(c.xjmp(it, opcJmp, 0))
      c.patch(endExcept)
  let fin = lastSon(n)
  # we always generate an 'opcFinally' as that pops the safepoint
  # from the stack if no exception is raised in the body.
  c.gABx(fin, opcFinally, 0, 0)
  for endPos in endings: c.patch(endPos)
  if fin.kind == nkFinally:
    c.gen(fin.sons[0])
    c.clearDest(n, dest)
  c.gABx(fin, opcFinallyEnd, 0, 0)

proc genRaise(c: PCtx; n: PNode) =
  let dest = genx(c, n.sons[0])
  c.gABC(n, opcRaise, dest)
  c.freeTemp(dest)

proc genReturn(c: PCtx; n: PNode) =
  if n.sons[0].kind != nkEmpty:
    gen(c, n.sons[0])
  c.gABC(n, opcRet)


proc genLit(c: PCtx; n: PNode; dest: var TDest) =
  # opcLdConst is now always valid. We produce the necessary copy in the
  # assignments now:
  #var opc = opcLdConst
  if dest < 0: dest = c.getTemp(n.typ)
  #elif c.prc.slots[dest].kind == slotFixedVar: opc = opcAsgnConst
  let lit = genLiteral(c, n)
  c.gABx(n, opcLdConst, dest, lit)

proc genCall(c: PCtx; n: PNode; dest: var TDest) =
  # it can happen that due to inlining we have a 'n' that should be
  # treated as a constant (see issue #537).
  #if n.typ != nil and n.typ.sym != nil and n.typ.sym.magic == mPNimrodNode:
  #  genLit(c, n, dest)
  #  return
  if dest < 0 and not isEmptyType(n.typ): dest = getTemp(c, n.typ)
  let x = c.getTempRange(n.len, slotTempUnknown)
  # varargs need 'opcSetType' for the FFI support:
  let fntyp = skipTypes(n.sons[0].typ, abstractInst)
  for i in 0..<n.len:
    #if i > 0 and i < sonsLen(fntyp):
    #  let paramType = fntyp.n.sons[i]
    #  if paramType.typ.isCompileTimeOnly: continue
    var r: TRegister = x+i
    c.gen(n.sons[i], r)
    if i >= fntyp.len:
      internalAssert c.config, tfVarargs in fntyp.flags
      c.gABx(n, opcSetType, r, c.genType(n.sons[i].typ))
  if dest < 0:
    c.gABC(n, opcIndCall, 0, x, n.len)
  else:
    c.gABC(n, opcIndCallAsgn, dest, x, n.len)
  c.freeTempRange(x, n.len)

template isGlobal(s: PSym): bool = sfGlobal in s.flags and s.kind != skForVar
proc isGlobal(n: PNode): bool = n.kind == nkSym and isGlobal(n.sym)

proc needsAsgnPatch(n: PNode): bool =
  n.kind in {nkBracketExpr, nkDotExpr, nkCheckedFieldExpr,
             nkDerefExpr, nkHiddenDeref} or (n.kind == nkSym and n.sym.isGlobal)

proc genField(c: PCtx; n: PNode): TRegister =
  if n.kind != nkSym or n.sym.kind != skField:
    globalError(c.config, n.info, "no field symbol")
  let s = n.sym
  if s.position > high(result):
    globalError(c.config, n.info,
        "too large offset! cannot generate code for: " & s.name.s)
  result = s.position

proc genIndex(c: PCtx; n: PNode; arr: PType): TRegister =
  if arr.skipTypes(abstractInst).kind == tyArray and (let x = firstOrd(c.config, arr);
      x != 0):
    let tmp = c.genx(n)
    # freeing the temporary here means we can produce:  regA = regA - Imm
    c.freeTemp(tmp)
    result = c.getTemp(n.typ)
    c.gABI(n, opcSubImmInt, result, tmp, x.int)
  else:
    result = c.genx(n)

proc genCheckedObjAccessAux(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags)

proc genAsgnPatch(c: PCtx; le: PNode, value: TRegister) =
  case le.kind
  of nkBracketExpr:
    let dest = c.genx(le.sons[0], {gfNode})
    let idx = c.genIndex(le.sons[1], le.sons[0].typ)
    c.gABC(le, opcWrArr, dest, idx, value)
    c.freeTemp(dest)
    c.freeTemp(idx)
  of nkCheckedFieldExpr:
    var objR: TDest = -1
    genCheckedObjAccessAux(c, le, objR, {gfNode})
    let idx = genField(c, le[0].sons[1])
    c.gABC(le[0], opcWrObj, objR, idx, value)
    c.freeTemp(objR)
  of nkDotExpr:
    let dest = c.genx(le.sons[0], {gfNode})
    let idx = genField(c, le.sons[1])
    c.gABC(le, opcWrObj, dest, idx, value)
    c.freeTemp(dest)
  of nkDerefExpr, nkHiddenDeref:
    let dest = c.genx(le.sons[0], {gfNode})
    c.gABC(le, opcWrDeref, dest, 0, value)
    c.freeTemp(dest)
  of nkSym:
    if le.sym.isGlobal:
      let dest = c.genx(le, {gfNodeAddr})
      c.gABC(le, opcWrDeref, dest, 0, value)
      c.freeTemp(dest)
  else:
    discard

proc genNew(c: PCtx; n: PNode) =
  let dest = if needsAsgnPatch(n.sons[1]): c.getTemp(n.sons[1].typ)
             else: c.genx(n.sons[1])
  # we use the ref's base type here as the VM conflates 'ref object'
  # and 'object' since internally we already have a pointer.
  c.gABx(n, opcNew, dest,
         c.genType(n.sons[1].typ.skipTypes(abstractVar-{tyTypeDesc}).sons[0]))
  c.genAsgnPatch(n.sons[1], dest)
  c.freeTemp(dest)

proc genNewSeq(c: PCtx; n: PNode) =
  let t = n.sons[1].typ
  let dest = if needsAsgnPatch(n.sons[1]): c.getTemp(t)
             else: c.genx(n.sons[1])
  let tmp = c.genx(n.sons[2])
  c.gABx(n, opcNewSeq, dest, c.genType(t.skipTypes(
                                                  abstractVar-{tyTypeDesc})))
  c.gABx(n, opcNewSeq, tmp, 0)
  c.freeTemp(tmp)
  c.genAsgnPatch(n.sons[1], dest)
  c.freeTemp(dest)

proc genNewSeqOfCap(c: PCtx; n: PNode; dest: var TDest) =
  let t = n.typ
  let tmp = c.getTemp(n.sons[1].typ)
  c.gABx(n, opcLdNull, dest, c.genType(t))
  c.gABx(n, opcLdImmInt, tmp, 0)
  c.gABx(n, opcNewSeq, dest, c.genType(t.skipTypes(
                                                  abstractVar-{tyTypeDesc})))
  c.gABx(n, opcNewSeq, tmp, 0)
  c.freeTemp(tmp)

proc genUnaryABC(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let tmp = c.genx(n.sons[1])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp)
  c.freeTemp(tmp)

proc genUnaryABI(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode; imm: BiggestInt=0) =
  let tmp = c.genx(n.sons[1])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABI(n, opc, dest, tmp, imm)
  c.freeTemp(tmp)

proc genBinaryABC(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let
    tmp = c.genx(n.sons[1])
    tmp2 = c.genx(n.sons[2])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genBinaryABCD(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let
    tmp = c.genx(n.sons[1])
    tmp2 = c.genx(n.sons[2])
    tmp3 = c.genx(n.sons[3])
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.gABC(n, opc, tmp3)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)
  c.freeTemp(tmp3)

proc genNarrow(c: PCtx; n: PNode; dest: TDest) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  # uint is uint64 in the VM, we we only need to mask the result for
  # other unsigned types:
  if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and t.size < 8):
    c.gABC(n, opcNarrowU, dest, TRegister(t.size*8))
  elif t.kind in {tyInt8..tyInt32} or (t.kind == tyInt and t.size < 8):
    c.gABC(n, opcNarrowS, dest, TRegister(t.size*8))

proc genNarrowU(c: PCtx; n: PNode; dest: TDest) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  # uint is uint64 in the VM, we we only need to mask the result for
  # other unsigned types:
  if t.kind in {tyUInt8..tyUInt32, tyInt8..tyInt32} or
    (t.kind in {tyUInt, tyInt} and t.size < 8):
    c.gABC(n, opcNarrowU, dest, TRegister(t.size*8))

proc genBinaryABCnarrow(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrow(c, n, dest)

proc genBinaryABCnarrowU(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrowU(c, n, dest)

proc genSetType(c: PCtx; n: PNode; dest: TRegister) =
  let t = skipTypes(n.typ, abstractInst-{tyTypeDesc})
  if t.kind == tySet:
    c.gABx(n, opcSetType, dest, c.genType(t))

proc genBinarySet(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  let
    tmp = c.genx(n.sons[1])
    tmp2 = c.genx(n.sons[2])
  if dest < 0: dest = c.getTemp(n.typ)
  c.genSetType(n.sons[1], tmp)
  c.genSetType(n.sons[2], tmp2)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genBinaryStmt(c: PCtx; n: PNode; opc: TOpcode) =
  let
    dest = c.genx(n.sons[1])
    tmp = c.genx(n.sons[2])
  c.gABC(n, opc, dest, tmp, 0)
  c.freeTemp(tmp)

proc genBinaryStmtVar(c: PCtx; n: PNode; opc: TOpcode) =
  var x = n.sons[1]
  if x.kind in {nkAddr, nkHiddenAddr}: x = x.sons[0]
  let
    dest = c.genx(x)
    tmp = c.genx(n.sons[2])
  c.gABC(n, opc, dest, tmp, 0)
  #c.genAsgnPatch(n.sons[1], dest)
  c.freeTemp(tmp)

proc genUnaryStmt(c: PCtx; n: PNode; opc: TOpcode) =
  let tmp = c.genx(n.sons[1])
  c.gABC(n, opc, tmp, 0, 0)
  c.freeTemp(tmp)

proc genVarargsABC(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  if dest < 0: dest = getTemp(c, n.typ)
  var x = c.getTempRange(n.len-1, slotTempStr)
  for i in 1..n.len-1:
    var r: TRegister = x+i-1
    c.gen(n.sons[i], r)
  c.gABC(n, opc, dest, x, n.len-1)
  c.freeTempRange(x, n.len)

proc isInt8Lit(n: PNode): bool =
  if n.kind in {nkCharLit..nkUInt64Lit}:
    result = n.intVal >= low(int8) and n.intVal <= high(int8)

proc isInt16Lit(n: PNode): bool =
  if n.kind in {nkCharLit..nkUInt64Lit}:
    result = n.intVal >= low(int16) and n.intVal <= high(int16)

proc genAddSubInt(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode) =
  if n.sons[2].isInt8Lit:
    let tmp = c.genx(n.sons[1])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABI(n, succ(opc), dest, tmp, n.sons[2].intVal)
    c.freeTemp(tmp)
  else:
    genBinaryABC(c, n, dest, opc)
  c.genNarrow(n, dest)

proc genConv(c: PCtx; n, arg: PNode; dest: var TDest; opc=opcConv) =
  if n.typ.kind == arg.typ.kind and arg.typ.kind == tyProc:
    # don't do anything for lambda lifting conversions:
    gen(c, arg, dest)
    return
  let tmp = c.genx(arg)
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABC(n, opc, dest, tmp)
  c.gABx(n, opc, 0, genType(c, n.typ.skipTypes({tyStatic})))
  c.gABx(n, opc, 0, genType(c, arg.typ.skipTypes({tyStatic})))
  c.freeTemp(tmp)

proc genCard(c: PCtx; n: PNode; dest: var TDest) =
  let tmp = c.genx(n.sons[1])
  if dest < 0: dest = c.getTemp(n.typ)
  c.genSetType(n.sons[1], tmp)
  c.gABC(n, opcCard, dest, tmp)
  c.freeTemp(tmp)

proc genCastIntFloat(c: PCtx; n: PNode; dest: var TDest) =
  const allowedIntegers = {tyInt..tyInt64, tyUInt..tyUInt64, tyChar}
  var signedIntegers = {tyInt8..tyInt32}
  var unsignedIntegers = {tyUInt8..tyUInt32, tyChar}
  let src = n.sons[1].typ.skipTypes(abstractRange)#.kind
  let dst = n.sons[0].typ.skipTypes(abstractRange)#.kind
  let src_size = getSize(c.config, src)
  let dst_size = getSize(c.config, dst)
  if c.config.target.intSize < 8:
    signedIntegers.incl(tyInt)
    unsignedIntegers.incl(tyUInt)
  if src_size == dst_size and src.kind in allowedIntegers and
                                 dst.kind in allowedIntegers:
    let tmp = c.genx(n.sons[1])
    var tmp2 = c.getTemp(n.sons[1].typ)
    let tmp3 = c.getTemp(n.sons[1].typ)
    if dest < 0: dest = c.getTemp(n[0].typ)
    proc mkIntLit(ival: int): int =
      result = genLiteral(c, newIntTypeNode(nkIntLit, ival, getSysType(c.graph, n.info, tyInt)))
    if src.kind in unsignedIntegers and dst.kind in signedIntegers:
      # cast unsigned to signed integer of same size
      # signedVal = (unsignedVal xor offset) -% offset
      let offset = 1 shl (src_size * 8 - 1)
      c.gABx(n, opcLdConst, tmp2, mkIntLit(offset))
      c.gABC(n, opcBitxorInt, tmp3, tmp, tmp2)
      c.gABC(n, opcSubInt, dest, tmp3, tmp2)
    elif src.kind in signedIntegers and dst.kind in unsignedIntegers:
      # cast signed to unsigned integer of same size
      # unsignedVal = (offset +% signedVal +% 1) and offset
      let offset = (1 shl (src_size * 8)) - 1
      c.gABx(n, opcLdConst, tmp2, mkIntLit(offset))
      c.gABx(n, opcLdConst, dest, mkIntLit(offset+1))
      c.gABC(n, opcAddu, tmp3, tmp, dest)
      c.gABC(n, opcNarrowU, tmp3, TRegister(src_size*8))
      c.gABC(n, opcBitandInt, dest, tmp3, tmp2)
    else:
      c.gABC(n, opcAsgnInt, dest, tmp)
    c.freeTemp(tmp)
    c.freeTemp(tmp2)
    c.freeTemp(tmp3)
  elif src_size == dst_size and src.kind in allowedIntegers and
                           dst.kind in {tyFloat, tyFloat32, tyFloat64}:
    let tmp = c.genx(n[1])
    if dest < 0: dest = c.getTemp(n[0].typ)
    if dst.kind == tyFloat32:
      c.gABC(n, opcAsgnFloat32FromInt, dest, tmp)
    else:
      c.gABC(n, opcAsgnFloat64FromInt, dest, tmp)
    c.freeTemp(tmp)

  elif src_size == dst_size and src.kind in {tyFloat, tyFloat32, tyFloat64} and
                           dst.kind in allowedIntegers:
    let tmp = c.genx(n[1])
    if dest < 0: dest = c.getTemp(n[0].typ)
    if src.kind == tyFloat32:
      c.gABC(n, opcAsgnIntFromFloat32, dest, tmp)
    else:
      c.gABC(n, opcAsgnIntFromFloat64, dest, tmp)
    c.freeTemp(tmp)

  else:
    globalError(c.config, n.info, "VM is only allowed to 'cast' between integers and/or floats of same size")

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

proc genBindSym(c: PCtx; n: PNode; dest: var TDest) =
  # nah, cannot use c.config.features because sempass context
  # can have local experimental switch
  # if dynamicBindSym notin c.config.features:
  if n.len == 2: # hmm, reliable?
    # bindSym with static input
    if n[1].kind in {nkClosedSymChoice, nkOpenSymChoice, nkSym}:
      let idx = c.genLiteral(n[1])
      if dest < 0: dest = c.getTemp(n.typ)
      c.gABx(n, opcNBindSym, dest, idx)
    else:
      localError(c.config, n.info, "invalid bindSym usage")
  else:
    # experimental bindSym
    if dest < 0: dest = c.getTemp(n.typ)
    let x = c.getTempRange(n.len, slotTempUnknown)

    # callee symbol
    var tmp0 = TDest(x)
    c.genLit(n.sons[0], tmp0)

    # original parameters
    for i in 1..<n.len-2:
      var r = TRegister(x+i)
      c.gen(n.sons[i], r)

    # info node
    var tmp1 = TDest(x+n.len-2)
    c.genLit(n.sons[^2], tmp1)

    # payload idx
    var tmp2 = TDest(x+n.len-1)
    c.genLit(n.sons[^1], tmp2)

    c.gABC(n, opcNDynBindSym, dest, x, n.len)
    c.freeTempRange(x, n.len)

proc fitsRegister*(t: PType): bool =
  assert t != nil
  t.skipTypes(abstractInst-{tyTypeDesc}).kind in {
    tyRange, tyEnum, tyBool, tyInt..tyUInt64, tyChar}

proc ldNullOpcode(t: PType): TOpcode =
  assert t != nil
  if fitsRegister(t): opcLdNullReg else: opcLdNull

proc genMagic(c: PCtx; n: PNode; dest: var TDest; m: TMagic) =
  case m
  of mAnd: c.genAndOr(n, opcFJmp, dest)
  of mOr:  c.genAndOr(n, opcTJmp, dest)
  of mUnaryLt:
    let tmp = c.genx(n.sons[1])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABI(n, opcSubImmInt, dest, tmp, 1)
    c.freeTemp(tmp)
  of mPred, mSubI:
    c.genAddSubInt(n, dest, opcSubInt)
  of mSucc, mAddI:
    c.genAddSubInt(n, dest, opcAddInt)
  of mInc, mDec:
    unused(c, n, dest)
    let opc = if m == mInc: opcAddInt else: opcSubInt
    let d = c.genx(n.sons[1])
    if n.sons[2].isInt8Lit:
      c.gABI(n, succ(opc), d, d, n.sons[2].intVal)
    else:
      let tmp = c.genx(n.sons[2])
      c.gABC(n, opc, d, d, tmp)
      c.freeTemp(tmp)
    c.genNarrow(n.sons[1], d)
    c.genAsgnPatch(n.sons[1], d)
    c.freeTemp(d)
  of mOrd, mChr, mArrToSeq: c.gen(n.sons[1], dest)
  of mNew, mNewFinalize:
    unused(c, n, dest)
    c.genNew(n)
  of mNewSeq:
    unused(c, n, dest)
    c.genNewSeq(n)
  of mNewSeqOfCap: c.genNewSeqOfCap(n, dest)
  of mNewString:
    genUnaryABC(c, n, dest, opcNewStr)
    # XXX buggy
  of mNewStringOfCap:
    # we ignore the 'cap' argument and translate it as 'newString(0)'.
    # eval n.sons[1] for possible side effects:
    c.freeTemp(c.genx(n.sons[1]))
    var tmp = c.getTemp(n.sons[1].typ)
    c.gABx(n, opcLdImmInt, tmp, 0)
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcNewStr, dest, tmp)
    c.freeTemp(tmp)
    # XXX buggy
  of mLengthOpenArray, mLengthArray, mLengthSeq, mXLenSeq:
    genUnaryABI(c, n, dest, opcLenSeq)
  of mLengthStr, mXLenStr:
    genUnaryABI(c, n, dest, opcLenStr)
  of mIncl, mExcl:
    unused(c, n, dest)
    var d = c.genx(n.sons[1])
    var tmp = c.genx(n.sons[2])
    c.genSetType(n.sons[1], d)
    c.gABC(n, if m == mIncl: opcIncl else: opcExcl, d, tmp)
    c.freeTemp(d)
    c.freeTemp(tmp)
  of mCard: genCard(c, n, dest)
  of mMulI: genBinaryABCnarrow(c, n, dest, opcMulInt)
  of mDivI: genBinaryABCnarrow(c, n, dest, opcDivInt)
  of mModI: genBinaryABCnarrow(c, n, dest, opcModInt)
  of mAddF64: genBinaryABC(c, n, dest, opcAddFloat)
  of mSubF64: genBinaryABC(c, n, dest, opcSubFloat)
  of mMulF64: genBinaryABC(c, n, dest, opcMulFloat)
  of mDivF64: genBinaryABC(c, n, dest, opcDivFloat)
  of mShrI:
    # the idea here is to narrow type if needed before executing right shift
    # inlined modified: genNarrowU(c, n, dest)
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    # uint is uint64 in the VM, we we only need to mask the result for
    # other unsigned types:
    let tmp = c.genx(n.sons[1])
    if t.kind in {tyUInt8..tyUInt32, tyInt8..tyInt32}:
      c.gABC(n, opcNarrowU, tmp, TRegister(t.size*8))

    # inlined modified: genBinaryABC(c, n, dest, opcShrInt)
    let tmp2 = c.genx(n.sons[2])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcShrInt, dest, tmp, tmp2)
    c.freeTemp(tmp)
    c.freeTemp(tmp2)

  of mShlI:
    genBinaryABC(c, n, dest, opcShlInt)
    # genNarrowU modified
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and t.size < 8):
      c.gABC(n, opcNarrowU, dest, TRegister(t.size*8))
    elif t.kind in {tyInt8..tyInt32} or (t.kind == tyInt and t.size < 8):
      c.gABC(n, opcSignExtend, dest, TRegister(t.size*8))
  of mAshrI: genBinaryABC(c, n, dest, opcAshrInt)
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
  of mLePtr, mLeU, mLeU64: genBinaryABC(c, n, dest, opcLeu)
  of mLtPtr, mLtU, mLtU64: genBinaryABC(c, n, dest, opcLtu)
  of mEqProc, mEqRef, mEqUntracedRef:
    genBinaryABC(c, n, dest, opcEqRef)
  of mXor: genBinaryABC(c, n, dest, opcXor)
  of mNot: genUnaryABC(c, n, dest, opcNot)
  of mUnaryMinusI, mUnaryMinusI64:
    genUnaryABC(c, n, dest, opcUnaryMinusInt)
    genNarrow(c, n, dest)
  of mUnaryMinusF64: genUnaryABC(c, n, dest, opcUnaryMinusFloat)
  of mUnaryPlusI, mUnaryPlusF64: gen(c, n.sons[1], dest)
  of mBitnotI:
    genUnaryABC(c, n, dest, opcBitnotInt)
    #genNarrowU modified, do not narrow signed types
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and t.size < 8):
      c.gABC(n, opcNarrowU, dest, TRegister(t.size*8))
  of mToFloat, mToBiggestFloat, mToInt,
     mToBiggestInt, mCharToStr, mBoolToStr, mIntToStr, mInt64ToStr,
     mFloatToStr, mCStrToStr, mStrToStr, mEnumToStr:
    genConv(c, n, n.sons[1], dest)
  of mZe8ToI, mZe8ToI64, mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64:
    #genNarrowU modified
    let t = skipTypes(n.sons[1].typ, abstractVar-{tyTypeDesc})
    let tmp = c.genx(n.sons[1])
    c.gABC(n, opcNarrowU, tmp, TRegister(t.size*8))
    # assign result to dest register
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcAsgnInt, dest, tmp)
    c.freeTemp(tmp)
  of mToU8, mToU16, mToU32:
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    var tmp = c.genx(n.sons[1])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcToNarrowInt, dest, tmp, TRegister(t.size*8))
    c.freeTemp(tmp)
  of mEqStr, mEqCString: genBinaryABC(c, n, dest, opcEqStr)
  of mLeStr: genBinaryABC(c, n, dest, opcLeStr)
  of mLtStr: genBinaryABC(c, n, dest, opcLtStr)
  of mEqSet: genBinarySet(c, n, dest, opcEqSet)
  of mLeSet: genBinarySet(c, n, dest, opcLeSet)
  of mLtSet: genBinarySet(c, n, dest, opcLtSet)
  of mMulSet: genBinarySet(c, n, dest, opcMulSet)
  of mPlusSet: genBinarySet(c, n, dest, opcPlusSet)
  of mMinusSet: genBinarySet(c, n, dest, opcMinusSet)
  of mSymDiffSet: genBinarySet(c, n, dest, opcSymdiffSet)
  of mConStrStr: genVarargsABC(c, n, dest, opcConcatStr)
  of mInSet: genBinarySet(c, n, dest, opcContainsSet)
  of mRepr: genUnaryABC(c, n, dest, opcRepr)
  of mExit:
    unused(c, n, dest)
    var tmp = c.genx(n.sons[1])
    c.gABC(n, opcQuit, tmp)
    c.freeTemp(tmp)
  of mSetLengthStr, mSetLengthSeq:
    unused(c, n, dest)
    var d = c.genx(n.sons[1])
    var tmp = c.genx(n.sons[2])
    c.gABC(n, if m == mSetLengthStr: opcSetLenStr else: opcSetLenSeq, d, tmp)
    c.genAsgnPatch(n.sons[1], d)
    c.freeTemp(tmp)
  of mSwap:
    unused(c, n, dest)
    c.gen(lowerSwap(c.graph, n, if c.prc == nil: c.module else: c.prc.sym))
  of mIsNil: genUnaryABC(c, n, dest, opcIsNil)
  of mCopyStr:
    if dest < 0: dest = c.getTemp(n.typ)
    var
      tmp1 = c.genx(n.sons[1])
      tmp2 = c.genx(n.sons[2])
      tmp3 = c.getTemp(n.sons[2].typ)
    c.gABC(n, opcLenStr, tmp3, tmp1)
    c.gABC(n, opcSubStr, dest, tmp1, tmp2)
    c.gABC(n, opcSubStr, tmp3)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    c.freeTemp(tmp3)
  of mCopyStrLast:
    if dest < 0: dest = c.getTemp(n.typ)
    var
      tmp1 = c.genx(n.sons[1])
      tmp2 = c.genx(n.sons[2])
      tmp3 = c.genx(n.sons[3])
    c.gABC(n, opcSubStr, dest, tmp1, tmp2)
    c.gABC(n, opcSubStr, tmp3)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    c.freeTemp(tmp3)
  of mParseBiggestFloat:
    if dest < 0: dest = c.getTemp(n.typ)
    var d2: TRegister
    # skip 'nkHiddenAddr':
    let d2AsNode = n.sons[2].sons[0]
    if needsAsgnPatch(d2AsNode):
      d2 = c.getTemp(getSysType(c.graph, n.info, tyFloat))
    else:
      d2 = c.genx(d2AsNode)
    var
      tmp1 = c.genx(n.sons[1])
      tmp3 = c.genx(n.sons[3])
    c.gABC(n, opcParseFloat, dest, tmp1, d2)
    c.gABC(n, opcParseFloat, tmp3)
    c.freeTemp(tmp1)
    c.freeTemp(tmp3)
    c.genAsgnPatch(d2AsNode, d2)
    c.freeTemp(d2)
  of mReset:
    unused(c, n, dest)
    var d = c.genx(n.sons[1])
    # XXX use ldNullOpcode() here?
    c.gABx(n, opcLdNull, d, c.genType(n.sons[1].typ))
    c.gABx(n, opcNodeToReg, d, d)
    c.genAsgnPatch(n.sons[1], d)
  of mDefault:
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABx(n, ldNullOpcode(n.typ), dest, c.genType(n.typ))
  of mOf, mIs:
    if dest < 0: dest = c.getTemp(n.typ)
    var tmp = c.genx(n.sons[1])
    var idx = c.getTemp(getSysType(c.graph, n.info, tyInt))
    var typ = n.sons[2].typ
    if m == mOf: typ = typ.skipTypes(abstractPtrs)
    c.gABx(n, opcLdImmInt, idx, c.genType(typ))
    c.gABC(n, if m == mOf: opcOf else: opcIs, dest, tmp, idx)
    c.freeTemp(tmp)
    c.freeTemp(idx)
  of mHigh:
    if dest < 0: dest = c.getTemp(n.typ)
    let tmp = c.genx(n.sons[1])
    case n.sons[1].typ.skipTypes(abstractVar-{tyTypeDesc}).kind:
    of tyString, tyCString:
      c.gABI(n, opcLenStr, dest, tmp, 1)
    else:
      c.gABI(n, opcLenSeq, dest, tmp, 1)
    c.freeTemp(tmp)
  of mEcho:
    unused(c, n, dest)
    let n = n[1].skipConv
    if n.kind == nkBracket:
      # can happen for nim check, see bug #9609
      let x = c.getTempRange(n.len, slotTempUnknown)
      for i in 0..<n.len:
        var r: TRegister = x+i
        c.gen(n.sons[i], r)
      c.gABC(n, opcEcho, x, n.len)
      c.freeTempRange(x, n.len)
  of mAppendStrCh:
    unused(c, n, dest)
    genBinaryStmtVar(c, n, opcAddStrCh)
  of mAppendStrStr:
    unused(c, n, dest)
    genBinaryStmtVar(c, n, opcAddStrStr)
  of mAppendSeqElem:
    unused(c, n, dest)
    genBinaryStmtVar(c, n, opcAddSeqElem)
  of mParseExprToAst:
    genUnaryABC(c, n, dest, opcParseExprToAst)
  of mParseStmtToAst:
    genUnaryABC(c, n, dest, opcParseStmtToAst)
  of mTypeTrait:
    let tmp = c.genx(n.sons[1])
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABx(n, opcSetType, tmp, c.genType(n.sons[1].typ))
    c.gABC(n, opcTypeTrait, dest, tmp)
    c.freeTemp(tmp)
  of mSlurp: genUnaryABC(c, n, dest, opcSlurp)
  of mStaticExec: genBinaryABCD(c, n, dest, opcGorge)
  of mNLen: genUnaryABI(c, n, dest, opcLenSeq, nimNodeFlag)
  of mGetImpl: genUnaryABC(c, n, dest, opcGetImpl)
  of mGetImplTransf: genUnaryABC(c, n, dest, opcGetImplTransf)
  of mSymOwner: genUnaryABC(c, n, dest, opcSymOwner)
  of mSymIsInstantiationOf: genBinaryABC(c, n, dest, opcSymIsInstantiationOf)
  of mNChild: genBinaryABC(c, n, dest, opcNChild)
  of mNSetChild: genVoidABC(c, n, dest, opcNSetChild)
  of mNDel: genVoidABC(c, n, dest, opcNDel)
  of mNAdd: genBinaryABC(c, n, dest, opcNAdd)
  of mNAddMultiple: genBinaryABC(c, n, dest, opcNAddMultiple)
  of mNKind: genUnaryABC(c, n, dest, opcNKind)
  of mNSymKind: genUnaryABC(c, n, dest, opcNSymKind)

  of mNccValue: genUnaryABC(c, n, dest, opcNccValue)
  of mNccInc: genBinaryABC(c, n, dest, opcNccInc)
  of mNcsAdd: genBinaryABC(c, n, dest, opcNcsAdd)
  of mNcsIncl: genBinaryABC(c, n, dest, opcNcsIncl)
  of mNcsLen: genUnaryABC(c, n, dest, opcNcsLen)
  of mNcsAt: genBinaryABC(c, n, dest, opcNcsAt)
  of mNctPut: genVoidABC(c, n, dest, opcNctPut)
  of mNctLen: genUnaryABC(c, n, dest, opcNctLen)
  of mNctGet: genBinaryABC(c, n, dest, opcNctGet)
  of mNctHasNext: genBinaryABC(c, n, dest, opcNctHasNext)
  of mNctNext: genBinaryABC(c, n, dest, opcNctNext)

  of mNIntVal: genUnaryABC(c, n, dest, opcNIntVal)
  of mNFloatVal: genUnaryABC(c, n, dest, opcNFloatVal)
  of mNSymbol: genUnaryABC(c, n, dest, opcNSymbol)
  of mNIdent: genUnaryABC(c, n, dest, opcNIdent)
  of mNGetType:
    let tmp = c.genx(n.sons[1])
    if dest < 0: dest = c.getTemp(n.typ)
    let rc = case n[0].sym.name.s:
      of "getType": 0
      of "typeKind": 1
      of "getTypeInst": 2
      else: 3  # "getTypeImpl"
    c.gABC(n, opcNGetType, dest, tmp, rc)
    c.freeTemp(tmp)
    #genUnaryABC(c, n, dest, opcNGetType)
  of mNStrVal: genUnaryABC(c, n, dest, opcNStrVal)
  of mNSigHash: genUnaryABC(c, n , dest, opcNSigHash)
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
  of mNSetType:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetType)
  of mNSetStrVal:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNSetStrVal)
  of mNNewNimNode: genBinaryABC(c, n, dest, opcNNewNimNode)
  of mNCopyNimNode: genUnaryABC(c, n, dest, opcNCopyNimNode)
  of mNCopyNimTree: genUnaryABC(c, n, dest, opcNCopyNimTree)
  of mNBindSym: genBindSym(c, n, dest)
  of mStrToIdent: genUnaryABC(c, n, dest, opcStrToIdent)
  of mEqIdent: genBinaryABC(c, n, dest, opcEqIdent)
  of mEqNimrodNode: genBinaryABC(c, n, dest, opcEqNimNode)
  of mSameNodeType: genBinaryABC(c, n, dest, opcSameNodeType)
  of mNLineInfo:
    case n[0].sym.name.s
    of "getFile": genUnaryABI(c, n, dest, opcNGetLineInfo, 0)
    of "getLine": genUnaryABI(c, n, dest, opcNGetLineInfo, 1)
    of "getColumn": genUnaryABI(c, n, dest, opcNGetLineInfo, 2)
    of "copyLineInfo":
      internalAssert c.config, n.len == 3
      unused(c, n, dest)
      genBinaryStmt(c, n, opcNSetLineInfo)
    else: internalAssert c.config, false
  of mNHint:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNHint)
  of mNWarning:
    unused(c, n, dest)
    genBinaryStmt(c, n, opcNWarning)
  of mNError:
    if n.len <= 1:
      # query error condition:
      c.gABC(n, opcQueryErrorFlag, dest)
    else:
      # setter
      unused(c, n, dest)
      genBinaryStmt(c, n, opcNError)
  of mNCallSite:
    if dest < 0: dest = c.getTemp(n.typ)
    c.gABC(n, opcCallSite, dest)
  of mNGenSym: genBinaryABC(c, n, dest, opcGenSym)
  of mMinI, mMaxI, mAbsF64, mMinF64, mMaxF64, mAbsI, mDotDot:
    c.genCall(n, dest)
  of mExpandToAst:
    if n.len != 2:
      globalError(c.config, n.info, "expandToAst requires 1 argument")
    let arg = n.sons[1]
    if arg.kind in nkCallKinds:
      #if arg[0].kind != nkSym or arg[0].sym.kind notin {skTemplate, skMacro}:
      #      "ExpandToAst: expanded symbol is no macro or template"
      if dest < 0: dest = c.getTemp(n.typ)
      c.genCall(arg, dest)
      # do not call clearDest(n, dest) here as getAst has a meta-type as such
      # produces a value
    else:
      globalError(c.config, n.info, "expandToAst requires a call expression")
  of mSizeOf, mAlignOf:
    globalError(c.config, n.info, "cannot evaluate 'sizeof/alignof' because its type is not defined completely")
  of mRunnableExamples:
    discard "just ignore any call to runnableExamples"
  of mDestroy: discard "ignore calls to the default destructor"
  else:
    # mGCref, mGCunref,
    globalError(c.config, n.info, "cannot generate code for: " & $m)

proc genMarshalLoad(c: PCtx, n: PNode, dest: var TDest) =
  ## Signature: proc to*[T](data: string): T
  if dest < 0: dest = c.getTemp(n.typ)
  var tmp = c.genx(n.sons[1])
  c.gABC(n, opcMarshalLoad, dest, tmp)
  c.gABx(n, opcMarshalLoad, 0, c.genType(n.typ))
  c.freeTemp(tmp)

proc genMarshalStore(c: PCtx, n: PNode, dest: var TDest) =
  ## Signature: proc `$$`*[T](x: T): string
  if dest < 0: dest = c.getTemp(n.typ)
  var tmp = c.genx(n.sons[1])
  c.gABC(n, opcMarshalStore, dest, tmp)
  c.gABx(n, opcMarshalStore, 0, c.genType(n.sons[1].typ))
  c.freeTemp(tmp)

const
  atomicTypes = {tyBool, tyChar,
    tyExpr, tyStmt, tyTypeDesc, tyStatic,
    tyEnum,
    tyOrdinal,
    tyRange,
    tyProc,
    tyPointer, tyOpenArray,
    tyString, tyCString,
    tyInt, tyInt8, tyInt16, tyInt32, tyInt64,
    tyFloat, tyFloat32, tyFloat64, tyFloat128,
    tyUInt, tyUInt8, tyUInt16, tyUInt32, tyUInt64}

proc unneededIndirection(n: PNode): bool =
  n.typ.skipTypes(abstractInstOwned-{tyTypeDesc}).kind == tyRef

proc canElimAddr(n: PNode): PNode =
  case n.sons[0].kind
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    var m = n.sons[0].sons[0]
    if m.kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      result = copyNode(n.sons[0])
      result.add m.sons[0]
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    var m = n.sons[0].sons[1]
    if m.kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      result = copyNode(n.sons[0])
      result.add m.sons[0]
  else:
    if n.sons[0].kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( deref ( x )) --> x
      result = n.sons[0].sons[0]

proc genAddr(c: PCtx, n: PNode, dest: var TDest, flags: TGenFlags) =
  if (let m = canElimAddr(n); m != nil):
    gen(c, m, dest, flags)
    return

  let af = if n[0].kind in {nkBracketExpr, nkDotExpr, nkCheckedFieldExpr}: {gfNode}
           else: {gfNodeAddr}
  let newflags = flags-{gfNode, gfNodeAddr}+af

  if isGlobal(n.sons[0]):
    gen(c, n.sons[0], dest, flags+af)
  else:
    let tmp = c.genx(n.sons[0], newflags)
    if dest < 0: dest = c.getTemp(n.typ)
    if c.prc.slots[tmp].kind >= slotTempUnknown:
      gABC(c, n, opcAddrNode, dest, tmp)
      # hack ahead; in order to fix bug #1781 we mark the temporary as
      # permanent, so that it's not used for anything else:
      c.prc.slots[tmp].kind = slotTempPerm
      # XXX this is still a hack
      #message(n.info, warnUser, "suspicious opcode used")
    else:
      gABC(c, n, opcAddrReg, dest, tmp)
    c.freeTemp(tmp)

proc genDeref(c: PCtx, n: PNode, dest: var TDest, flags: TGenFlags) =
  if unneededIndirection(n.sons[0]):
    gen(c, n.sons[0], dest, flags)
    if {gfNodeAddr, gfNode} * flags == {} and fitsRegister(n.typ):
      c.gABC(n, opcNodeToReg, dest, dest)
  else:
    let tmp = c.genx(n.sons[0], flags)
    if dest < 0: dest = c.getTemp(n.typ)
    gABC(c, n, opcLdDeref, dest, tmp)
    assert n.typ != nil
    if {gfNodeAddr, gfNode} * flags == {} and fitsRegister(n.typ):
      c.gABC(n, opcNodeToReg, dest, dest)

proc whichAsgnOpc(n: PNode): TOpcode =
  case n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc}).kind
  of tyBool, tyChar, tyEnum, tyOrdinal, tyInt..tyInt64, tyUInt..tyUInt64:
    opcAsgnInt
  of tyString, tyCString:
    opcAsgnStr
  of tyFloat..tyFloat128:
    opcAsgnFloat
  of tyRef, tyNil, tyVar, tyLent, tyPtr:
    opcAsgnRef
  else:
    opcAsgnComplex

proc whichAsgnOpc(n: PNode; opc: TOpcode): TOpcode = opc

proc genAsgn(c: PCtx; dest: TDest; ri: PNode; requiresCopy: bool) =
  let tmp = c.genx(ri)
  assert dest >= 0
  gABC(c, ri, whichAsgnOpc(ri), dest, tmp, 1-ord(requiresCopy))
  c.freeTemp(tmp)

proc setSlot(c: PCtx; v: PSym) =
  # XXX generate type initialization here?
  if v.position == 0:
    if c.prc.maxSlots == 0: c.prc.maxSlots = 1
    if c.prc.maxSlots >= high(TRegister):
      globalError(c.config, v.info, "cannot generate code; too many registers required")
    v.position = c.prc.maxSlots
    c.prc.slots[v.position] = (inUse: true,
        kind: if v.kind == skLet: slotFixedLet else: slotFixedVar)
    inc c.prc.maxSlots

proc cannotEval(c: PCtx; n: PNode) {.noinline.} =
  globalError(c.config, n.info, "cannot evaluate at compile time: " &
    n.renderTree)

proc isOwnedBy(a, b: PSym): bool =
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
  if s.kind in {skVar, skTemp, skLet, skParam, skResult} and
      not s.isOwnedBy(c.prc.sym) and s.owner != c.module and c.mode != emRepl:
    cannotEval(c, n)
  elif s.kind in {skProc, skFunc, skConverter, skMethod,
                  skIterator} and sfForward in s.flags:
    cannotEval(c, n)

proc isTemp(c: PCtx; dest: TDest): bool =
  result = dest >= 0 and c.prc.slots[dest].kind >= slotTempUnknown

template needsAdditionalCopy(n): untyped =
  not c.isTemp(dest) and not fitsRegister(n.typ)

proc genAdditionalCopy(c: PCtx; n: PNode; opc: TOpcode;
                       dest, idx, value: TRegister) =
  var cc = c.getTemp(n.typ)
  c.gABC(n, whichAsgnOpc(n), cc, value, 0)
  c.gABC(n, opc, dest, idx, cc)
  c.freeTemp(cc)

proc preventFalseAlias(c: PCtx; n: PNode; opc: TOpcode;
                       dest, idx, value: TRegister) =
  # opcLdObj et al really means "load address". We sometimes have to create a
  # copy in order to not introduce false aliasing:
  # mylocal = a.b  # needs a copy of the data!
  assert n.typ != nil
  if needsAdditionalCopy(n):
    genAdditionalCopy(c, n, opc, dest, idx, value)
  else:
    c.gABC(n, opc, dest, idx, value)

proc genAsgn(c: PCtx; le, ri: PNode; requiresCopy: bool) =
  case le.kind
  of nkBracketExpr:
    let dest = c.genx(le.sons[0], {gfNode})
    let idx = c.genIndex(le.sons[1], le.sons[0].typ)
    let tmp = c.genx(ri)
    if le.sons[0].typ.skipTypes(abstractVarRange-{tyTypeDesc}).kind in {
        tyString, tyCString}:
      c.preventFalseAlias(le, opcWrStrIdx, dest, idx, tmp)
    else:
      c.preventFalseAlias(le, opcWrArr, dest, idx, tmp)
    c.freeTemp(tmp)
  of nkCheckedFieldExpr:
    var objR: TDest = -1
    genCheckedObjAccessAux(c, le, objR, {gfNode})
    let idx = genField(c, le[0].sons[1])
    let tmp = c.genx(ri)
    c.preventFalseAlias(le[0], opcWrObj, objR, idx, tmp)
    c.freeTemp(tmp)
    c.freeTemp(objR)
  of nkDotExpr:
    let dest = c.genx(le.sons[0], {gfNode})
    let idx = genField(c, le.sons[1])
    let tmp = c.genx(ri)
    c.preventFalseAlias(le, opcWrObj, dest, idx, tmp)
    c.freeTemp(tmp)
  of nkDerefExpr, nkHiddenDeref:
    let dest = c.genx(le.sons[0], {gfNode})
    let tmp = c.genx(ri)
    c.preventFalseAlias(le, opcWrDeref, dest, 0, tmp)
    c.freeTemp(tmp)
  of nkSym:
    let s = le.sym
    checkCanEval(c, le)
    if s.isGlobal:
      withTemp(tmp, le.typ):
        c.gen(le, tmp, {gfNodeAddr})
        let val = c.genx(ri)
        c.preventFalseAlias(le, opcWrDeref, tmp, 0, val)
        c.freeTemp(val)
    else:
      if s.kind == skForVar: c.setSlot s
      internalAssert c.config, s.position > 0 or (s.position == 0 and
                                        s.kind in {skParam,skResult})
      var dest: TRegister = s.position + ord(s.kind == skParam)
      assert le.typ != nil
      if needsAdditionalCopy(le) and s.kind in {skResult, skVar, skParam}:
        var cc = c.getTemp(le.typ)
        gen(c, ri, cc)
        c.gABC(le, whichAsgnOpc(le), dest, cc, 1)
        c.freeTemp(cc)
      else:
        gen(c, ri, dest)
  else:
    let dest = c.genx(le, {gfNodeAddr})
    genAsgn(c, dest, ri, requiresCopy)

proc genTypeLit(c: PCtx; t: PType; dest: var TDest) =
  var n = newNode(nkType)
  n.typ = t
  genLit(c, n, dest)

proc importcSym(c: PCtx; info: TLineInfo; s: PSym) =
  when hasFFI:
    if compiletimeFFI in c.config.features:
      c.globals.add(importcSymbol(c.config, s))
      s.position = c.globals.len
    else:
      localError(c.config, info, "VM is not allowed to 'importc'")
  else:
    localError(c.config, info,
               "cannot 'importc' variable at compile time")

proc getNullValue*(typ: PType, info: TLineInfo; conf: ConfigRef): PNode

proc genGlobalInit(c: PCtx; n: PNode; s: PSym) =
  c.globals.add(getNullValue(s.typ, n.info, c.config))
  s.position = c.globals.len
  # This is rather hard to support, due to the laziness of the VM code
  # generator. See tests/compile/tmacro2 for why this is necessary:
  #   var decls{.compileTime.}: seq[NimNode] = @[]
  let dest = c.getTemp(s.typ)
  c.gABx(n, opcLdGlobal, dest, s.position)
  if s.ast != nil:
    let tmp = c.genx(s.ast)
    c.genAdditionalCopy(n, opcWrDeref, dest, 0, tmp)
    c.freeTemp(dest)
    c.freeTemp(tmp)

proc genRdVar(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags) =
  # gfNodeAddr and gfNode are mutually exclusive
  assert card(flags * {gfNodeAddr, gfNode}) < 2
  let s = n.sym
  if s.isGlobal:
    if sfCompileTime in s.flags or c.mode == emRepl:
      discard
    elif s.position == 0:
      cannotEval(c, n)
    if s.position == 0:
      if sfImportc in s.flags: c.importcSym(n.info, s)
      else: genGlobalInit(c, n, s)
    if dest < 0: dest = c.getTemp(n.typ)
    assert s.typ != nil
    if gfNodeAddr in flags:
      c.gABx(n, opcLdGlobalAddr, dest, s.position)
    elif fitsRegister(s.typ) and gfNode notin flags:
      var cc = c.getTemp(n.typ)
      c.gABx(n, opcLdGlobal, cc, s.position)
      c.gABC(n, opcNodeToReg, dest, cc)
      c.freeTemp(cc)
    else:
      c.gABx(n, opcLdGlobal, dest, s.position)
  else:
    if s.kind == skForVar and c.mode == emRepl: c.setSlot(s)
    if s.position > 0 or (s.position == 0 and
                          s.kind in {skParam,skResult}):
      if dest < 0:
        dest = s.position + ord(s.kind == skParam)
        internalAssert(c.config, c.prc.slots[dest].kind < slotSomeTemp)
      else:
        # we need to generate an assignment:
        genAsgn(c, dest, n, c.prc.slots[dest].kind >= slotSomeTemp)
    else:
      # see tests/t99bott for an example that triggers it:
      cannotEval(c, n)

template needsRegLoad(): untyped =
  {gfNode, gfNodeAddr} * flags == {} and
    fitsRegister(n.typ.skipTypes({tyVar, tyLent, tyStatic}))

proc genArrAccess2(c: PCtx; n: PNode; dest: var TDest; opc: TOpcode;
                   flags: TGenFlags) =
  let a = c.genx(n.sons[0], flags)
  let b = c.genIndex(n.sons[1], n.sons[0].typ)
  if dest < 0: dest = c.getTemp(n.typ)
  if needsRegLoad():
    var cc = c.getTemp(n.typ)
    c.gABC(n, opc, cc, a, b)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    #message(n.info, warnUser, "argh")
    #echo "FLAGS ", flags, " ", fitsRegister(n.typ), " ", typeToString(n.typ)
    c.gABC(n, opc, dest, a, b)
  c.freeTemp(a)
  c.freeTemp(b)

proc genObjAccess(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags) =
  let a = c.genx(n.sons[0], flags)
  let b = genField(c, n.sons[1])
  if dest < 0: dest = c.getTemp(n.typ)
  if needsRegLoad():
    var cc = c.getTemp(n.typ)
    c.gABC(n, opcLdObj, cc, a, b)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    c.gABC(n, opcLdObj, dest, a, b)
  c.freeTemp(a)

proc genCheckedObjAccessAux(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags) =
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

  # Load the object in `dest`
  c.gen(accessExpr[0], dest, flags)
  # Load the discriminant
  var discVal = c.getTemp(disc.typ)
  c.gABC(n, opcLdObj, discVal, dest, genField(c, disc))
  # Check if its value is contained in the supplied set
  let setLit = c.genx(checkExpr[1])
  var rs = c.getTemp(getSysType(c.graph, n.info, tyBool))
  c.gABC(n, opcContainsSet, rs, setLit, discVal)
  c.freeTemp(setLit)
  # If the check fails let the user know
  let L1 = c.xjmp(n, if negCheck: opcFJmp else: opcTJmp, rs)
  c.freeTemp(rs)
  # Not ideal but will do for the moment
  c.gABC(n, opcQuit)
  c.patch(L1)

proc genCheckedObjAccess(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags) =
  var objR: TDest = -1
  genCheckedObjAccessAux(c, n, objR, flags)

  let accessExpr = n[0]
  # Field symbol
  var field = accessExpr[1]
  internalAssert c.config, field.sym.kind == skField

  # Load the content now
  if dest < 0: dest = c.getTemp(n.typ)
  let fieldPos = genField(c, field)
  if needsRegLoad():
    var cc = c.getTemp(accessExpr.typ)
    c.gABC(n, opcLdObj, cc, objR, fieldPos)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    c.gABC(n, opcLdObj, dest, objR, fieldPos)

  c.freeTemp(objR)

proc genArrAccess(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags) =
  let arrayType = n.sons[0].typ.skipTypes(abstractVarRange-{tyTypeDesc}).kind
  if arrayType in {tyString, tyCString}:
    genArrAccess2(c, n, dest, opcLdStrIdx, {})
  elif arrayType == tyTypeDesc:
    c.genTypeLit(n.typ, dest)
  else:
    genArrAccess2(c, n, dest, opcLdArr, flags)

proc getNullValueAux(obj: PNode, result: PNode; conf: ConfigRef) =
  case obj.kind
  of nkRecList:
    for i in countup(0, sonsLen(obj) - 1): getNullValueAux(obj.sons[i], result, conf)
  of nkRecCase:
    getNullValueAux(obj.sons[0], result, conf)
    for i in countup(1, sonsLen(obj) - 1):
      getNullValueAux(lastSon(obj.sons[i]), result, conf)
  of nkSym:
    let field = newNodeI(nkExprColonExpr, result.info)
    field.add(obj)
    field.add(getNullValue(obj.sym.typ, result.info, conf))
    addSon(result, field)
  else: globalError(conf, result.info, "cannot create null element for: " & $obj)

proc getNullValue(typ: PType, info: TLineInfo; conf: ConfigRef): PNode =
  var t = skipTypes(typ, abstractRange+{tyStatic, tyOwned}-{tyTypeDesc})
  case t.kind
  of tyBool, tyEnum, tyChar, tyInt..tyInt64:
    result = newNodeIT(nkIntLit, info, t)
  of tyUInt..tyUInt64:
    result = newNodeIT(nkUIntLit, info, t)
  of tyFloat..tyFloat128:
    result = newNodeIT(nkFloatLit, info, t)
  of tyCString, tyString:
    result = newNodeIT(nkStrLit, info, t)
    result.strVal = ""
  of tyVar, tyLent, tyPointer, tyPtr, tyExpr,
     tyStmt, tyTypeDesc, tyRef, tyNil:
    result = newNodeIT(nkNilLit, info, t)
  of tyProc:
    if t.callConv != ccClosure:
      result = newNodeIT(nkNilLit, info, t)
    else:
      result = newNodeIT(nkTupleConstr, info, t)
      result.add(newNodeIT(nkNilLit, info, t))
      result.add(newNodeIT(nkNilLit, info, t))
  of tyObject:
    result = newNodeIT(nkObjConstr, info, t)
    result.add(newNodeIT(nkEmpty, info, t))
    # initialize inherited fields:
    var base = t.sons[0]
    while base != nil:
      getNullValueAux(skipTypes(base, skipPtrs).n, result, conf)
      base = base.sons[0]
    getNullValueAux(t.n, result, conf)
  of tyArray:
    result = newNodeIT(nkBracket, info, t)
    for i in countup(0, int(lengthOrd(conf, t)) - 1):
      addSon(result, getNullValue(elemType(t), info, conf))
  of tyTuple:
    result = newNodeIT(nkTupleConstr, info, t)
    for i in countup(0, sonsLen(t) - 1):
      addSon(result, getNullValue(t.sons[i], info, conf))
  of tySet:
    result = newNodeIT(nkCurly, info, t)
  of tyOpt:
    result = newNodeIT(nkNilLit, info, t)
  of tySequence:
    result = newNodeIT(nkBracket, info, t)
  else:
    globalError(conf, info, "cannot create null element for: " & $t.kind)
    result = newNodeI(nkEmpty, info)

proc genVarSection(c: PCtx; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt: continue
    #assert(a.sons[0].kind == nkSym) can happen for transformed vars
    if a.kind == nkVarTuple:
      for i in 0 .. a.len-3:
        if a[i].kind == nkSym:
          if not a[i].sym.isGlobal: setSlot(c, a[i].sym)
          checkCanEval(c, a[i])
      c.gen(lowerTupleUnpacking(c.graph, a, c.getOwner))
    elif a.sons[0].kind == nkSym:
      let s = a.sons[0].sym
      checkCanEval(c, a.sons[0])
      if s.isGlobal:
        if s.position == 0:
          if sfImportc in s.flags: c.importcSym(a.info, s)
          else:
            let sa = getNullValue(s.typ, a.info, c.config)
            #if s.ast.isNil: getNullValue(s.typ, a.info)
            #else: canonValue(s.ast)
            assert sa.kind != nkCall
            c.globals.add(sa)
            s.position = c.globals.len
        if a.sons[2].kind != nkEmpty:
          let tmp = c.genx(a.sons[0], {gfNodeAddr})
          let val = c.genx(a.sons[2])
          c.genAdditionalCopy(a.sons[2], opcWrDeref, tmp, 0, val)
          c.freeTemp(val)
          c.freeTemp(tmp)
      else:
        setSlot(c, s)
        if a.sons[2].kind == nkEmpty:
          c.gABx(a, ldNullOpcode(s.typ), s.position, c.genType(s.typ))
        else:
          assert s.typ != nil
          if not fitsRegister(s.typ):
            c.gABx(a, ldNullOpcode(s.typ), s.position, c.genType(s.typ))
          let le = a.sons[0]
          assert le.typ != nil
          if not fitsRegister(le.typ) and s.kind in {skResult, skVar, skParam}:
            var cc = c.getTemp(le.typ)
            gen(c, a.sons[2], cc)
            c.gABC(le, whichAsgnOpc(le), s.position.TRegister, cc, 1)
            c.freeTemp(cc)
          else:
            gen(c, a.sons[2], s.position.TRegister)
    else:
      # assign to a.sons[0]; happens for closures
      if a.sons[2].kind == nkEmpty:
        let tmp = genx(c, a.sons[0])
        c.gABx(a, ldNullOpcode(a[0].typ), tmp, c.genType(a.sons[0].typ))
        c.freeTemp(tmp)
      else:
        genAsgn(c, a.sons[0], a.sons[2], true)

proc genArrayConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABx(n, opcLdNull, dest, c.genType(n.typ))

  let intType = getSysType(c.graph, n.info, tyInt)
  let seqType = n.typ.skipTypes(abstractVar-{tyTypeDesc})
  if seqType.kind == tySequence:
    var tmp = c.getTemp(intType)
    c.gABx(n, opcLdImmInt, tmp, n.len)
    c.gABx(n, opcNewSeq, dest, c.genType(seqType))
    c.gABx(n, opcNewSeq, tmp, 0)
    c.freeTemp(tmp)

  if n.len > 0:
    var tmp = getTemp(c, intType)
    c.gABx(n, opcLdNullReg, tmp, c.genType(intType))
    for x in n:
      let a = c.genx(x)
      c.preventFalseAlias(n, whichAsgnOpc(x, opcWrArr), dest, tmp, a)
      c.gABI(n, opcAddImmInt, tmp, tmp, 1)
      c.freeTemp(a)
    c.freeTemp(tmp)

proc genSetConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABx(n, opcLdNull, dest, c.genType(n.typ))
  for x in n:
    if x.kind == nkRange:
      let a = c.genx(x.sons[0])
      let b = c.genx(x.sons[1])
      c.gABC(n, opcInclRange, dest, a, b)
      c.freeTemp(b)
      c.freeTemp(a)
    else:
      let a = c.genx(x)
      c.gABC(n, opcIncl, dest, a)
      c.freeTemp(a)

proc genObjConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  let t = n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc})
  if t.kind == tyRef:
    c.gABx(n, opcNew, dest, c.genType(t.sons[0]))
  else:
    c.gABx(n, opcLdNull, dest, c.genType(n.typ))
  for i in 1..<n.len:
    let it = n.sons[i]
    if it.kind == nkExprColonExpr and it.sons[0].kind == nkSym:
      let idx = genField(c, it.sons[0])
      let tmp = c.genx(it.sons[1])
      c.preventFalseAlias(it.sons[1], whichAsgnOpc(it.sons[1], opcWrObj),
                          dest, idx, tmp)
      c.freeTemp(tmp)
    else:
      globalError(c.config, n.info, "invalid object constructor")

proc genTupleConstr(c: PCtx, n: PNode, dest: var TDest) =
  if dest < 0: dest = c.getTemp(n.typ)
  c.gABx(n, opcLdNull, dest, c.genType(n.typ))
  # XXX x = (x.old, 22)  produces wrong code ... stupid self assignments
  for i in 0..<n.len:
    let it = n.sons[i]
    if it.kind == nkExprColonExpr:
      let idx = genField(c, it.sons[0])
      let tmp = c.genx(it.sons[1])
      c.preventFalseAlias(it.sons[1], whichAsgnOpc(it.sons[1], opcWrObj),
                          dest, idx, tmp)
      c.freeTemp(tmp)
    else:
      let tmp = c.genx(it)
      c.preventFalseAlias(it, whichAsgnOpc(it, opcWrObj), dest, i.TRegister, tmp)
      c.freeTemp(tmp)

proc genProc*(c: PCtx; s: PSym): int

proc matches(s: PSym; x: string): bool =
  let y = x.split('.')
  var s = s
  var L = y.len-1
  while L >= 0:
    if s == nil or (y[L].cmpIgnoreStyle(s.name.s) != 0 and y[L] != "*"):
      return false
    s = s.owner
    dec L
  result = true

proc matches(s: PSym; y: varargs[string]): bool =
  var s = s
  var L = y.len-1
  while L >= 0:
    if s == nil or (y[L].cmpIgnoreStyle(s.name.s) != 0 and y[L] != "*"):
      return false
    s = if sfFromGeneric in s.flags: s.owner.owner else: s.owner
    dec L
  result = true

proc procIsCallback(c: PCtx; s: PSym): bool =
  if s.offset < -1: return true
  var i = -2
  for key, value in items(c.callbacks):
    if s.matches(key):
      doAssert s.offset == -1
      s.offset = i
      return true
    dec i

proc gen(c: PCtx; n: PNode; dest: var TDest; flags: TGenFlags = {}) =
  case n.kind
  of nkSym:
    let s = n.sym
    checkCanEval(c, n)
    case s.kind
    of skVar, skForVar, skTemp, skLet, skParam, skResult:
      genRdVar(c, n, dest, flags)
    of skProc, skFunc, skConverter, skMacro, skTemplate, skMethod, skIterator:
      # 'skTemplate' is only allowed for 'getAst' support:
      if procIsCallback(c, s): discard
      elif sfImportc in s.flags: c.importcSym(n.info, s)
      genLit(c, n, dest)
    of skConst:
      let constVal = if s.ast != nil: s.ast else: s.typ.n
      gen(c, constVal, dest)
    of skEnumField:
      # we never reach this case - as of the time of this comment,
      # skEnumField is folded to an int in semfold.nim, but this code
      # remains for robustness
      if dest < 0: dest = c.getTemp(n.typ)
      if s.position >= low(int16) and s.position <= high(int16):
        c.gABx(n, opcLdImmInt, dest, s.position)
      else:
        var lit = genLiteral(c, newIntNode(nkIntLit, s.position))
        c.gABx(n, opcLdConst, dest, lit)
    of skType:
      genTypeLit(c, s.typ, dest)
    of skGenericParam:
      if c.prc.sym != nil and c.prc.sym.kind == skMacro:
        genRdVar(c, n, dest, flags)
      else:
        globalError(c.config, n.info, "cannot generate code for: " & s.name.s)
    else:
      globalError(c.config, n.info, "cannot generate code for: " & s.name.s)
  of nkCallKinds:
    if n.sons[0].kind == nkSym:
      let s = n.sons[0].sym
      if s.magic != mNone:
        genMagic(c, n, dest, s.magic)
      elif s.kind == skMethod:
        localError(c.config, n.info, "cannot call method " & s.name.s &
          " at compile time")
      elif matches(s, "stdlib", "marshal", "to"):
        # XXX marshal load&store should not be opcodes, but use the
        # general callback mechanisms.
        genMarshalLoad(c, n, dest)
      elif matches(s, "stdlib", "marshal", "$$"):
        genMarshalStore(c, n, dest)
      else:
        genCall(c, n, dest)
        clearDest(c, n, dest)
    else:
      genCall(c, n, dest)
      clearDest(c, n, dest)
  of nkCharLit..nkInt64Lit:
    if isInt16Lit(n):
      if dest < 0: dest = c.getTemp(n.typ)
      c.gABx(n, opcLdImmInt, dest, n.intVal.int)
    else:
      genLit(c, n, dest)
  of nkUIntLit..pred(nkNilLit): genLit(c, n, dest)
  of nkNilLit:
    if not n.typ.isEmptyType: genLit(c, getNullValue(n.typ, n.info, c.config), dest)
    else: unused(c, n, dest)
  of nkAsgn, nkFastAsgn:
    unused(c, n, dest)
    genAsgn(c, n.sons[0], n.sons[1], n.kind == nkAsgn)
  of nkDotExpr: genObjAccess(c, n, dest, flags)
  of nkCheckedFieldExpr: genCheckedObjAccess(c, n, dest, flags)
  of nkBracketExpr: genArrAccess(c, n, dest, flags)
  of nkDerefExpr, nkHiddenDeref: genDeref(c, n, dest, flags)
  of nkAddr, nkHiddenAddr: genAddr(c, n, dest, flags)
  of nkIfStmt, nkIfExpr: genIf(c, n, dest)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n.sons[0].sons[1], dest)
  of nkCaseStmt: genCase(c, n, dest)
  of nkWhileStmt:
    unused(c, n, dest)
    genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n, dest)
  of nkReturnStmt:
    unused(c, n, dest)
    genReturn(c, n)
  of nkRaiseStmt:
    genRaise(c, n)
  of nkBreakStmt:
    unused(c, n, dest)
    genBreak(c, n)
  of nkTryStmt: genTry(c, n, dest)
  of nkStmtList:
    #unused(c, n, dest)
    # XXX Fix this bug properly, lexim triggers it
    for x in n: gen(c, x)
  of nkStmtListExpr:
    let L = n.len-1
    for i in 0 ..< L: gen(c, n.sons[i])
    gen(c, n.sons[L], dest, flags)
  of nkPragmaBlock:
    gen(c, n.lastSon, dest, flags)
  of nkDiscardStmt:
    unused(c, n, dest)
    gen(c, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    genConv(c, n, n.sons[1], dest)
  of nkObjDownConv:
    genConv(c, n, n.sons[0], dest)
  of nkObjUpConv:
    genConv(c, n, n.sons[0], dest)
  of nkVarSection, nkLetSection:
    unused(c, n, dest)
    genVarSection(c, n)
  of declarativeDefs, nkMacroDef:
    unused(c, n, dest)
  of nkLambdaKinds:
    #let s = n.sons[namePos].sym
    #discard genProc(c, s)
    genLit(c, newSymNode(n.sons[namePos].sym), dest)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    let
      tmp0 = c.genx(n.sons[0])
      tmp1 = c.genx(n.sons[1])
      tmp2 = c.genx(n.sons[2])
    c.gABC(n, opcRangeChck, tmp0, tmp1, tmp2)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    if dest >= 0:
      gABC(c, n, whichAsgnOpc(n), dest, tmp0, 1)
      c.freeTemp(tmp0)
    else:
      dest = tmp0
  of nkEmpty, nkCommentStmt, nkTypeSection, nkConstSection, nkPragma,
     nkTemplateDef, nkIncludeStmt, nkImportStmt, nkFromStmt, nkExportStmt:
    unused(c, n, dest)
  of nkStringToCString, nkCStringToString:
    gen(c, n.sons[0], dest)
  of nkBracket: genArrayConstr(c, n, dest)
  of nkCurly: genSetConstr(c, n, dest)
  of nkObjConstr: genObjConstr(c, n, dest)
  of nkPar, nkClosure, nkTupleConstr: genTupleConstr(c, n, dest)
  of nkCast:
    if allowCast in c.features:
      genConv(c, n, n.sons[1], dest, opcCast)
    else:
      genCastIntFloat(c, n, dest)
  of nkTypeOfExpr:
    genTypeLit(c, n.typ, dest)
  of nkComesFrom:
    discard "XXX to implement for better stack traces"
  else:
    globalError(c.config, n.info, "cannot generate VM code for " & $n)

proc removeLastEof(c: PCtx) =
  let last = c.code.len-1
  if last >= 0 and c.code[last].opcode == opcEof:
    # overwrite last EOF:
    assert c.code.len == c.debug.len
    c.code.setLen(last)
    c.debug.setLen(last)

proc genStmt*(c: PCtx; n: PNode): int =
  c.removeLastEof
  result = c.code.len
  var d: TDest = -1
  c.gen(n, d)
  c.gABC(n, opcEof)
  if d >= 0:
    globalError(c.config, n.info, "VM problem: dest register is set")

proc genExpr*(c: PCtx; n: PNode, requiresValue = true): int =
  c.removeLastEof
  result = c.code.len
  var d: TDest = -1
  c.gen(n, d)
  if d < 0:
    if requiresValue:
      globalError(c.config, n.info, "VM problem: dest register is not set")
    d = 0
  c.gABC(n, opcEof, d)

  #echo renderTree(n)
  #c.echoCode(result)

proc genParams(c: PCtx; params: PNode) =
  # res.sym.position is already 0
  c.prc.slots[0] = (inUse: true, kind: slotFixedVar)
  for i in 1..<params.len:
    c.prc.slots[i] = (inUse: true, kind: slotFixedLet)
  c.prc.maxSlots = max(params.len, 1)

proc finalJumpTarget(c: PCtx; pc, diff: int) =
  internalAssert(c.config, -0x7fff < diff and diff < 0x7fff)
  let oldInstr = c.code[pc]
  # opcode and regA stay the same:
  c.code[pc] = ((oldInstr.uint32 and 0xffff'u32).uint32 or
                uint32(diff+wordExcess) shl 16'u32).TInstr

proc genGenericParams(c: PCtx; gp: PNode) =
  var base = c.prc.maxSlots
  for i in 0..<gp.len:
    var param = gp.sons[i].sym
    param.position = base + i # XXX: fix this earlier; make it consistent with templates
    c.prc.slots[base + i] = (inUse: true, kind: slotFixedLet)
  c.prc.maxSlots = base + gp.len

proc optimizeJumps(c: PCtx; start: int) =
  const maxIterations = 10
  for i in start ..< c.code.len:
    let opc = c.code[i].opcode
    case opc
    of opcTJmp, opcFJmp:
      var reg = c.code[i].regA
      var d = i + c.code[i].jmpDiff
      for iters in countdown(maxIterations, 0):
        case c.code[d].opcode
        of opcJmp, opcJmpBack:
          d = d + c.code[d].jmpDiff
        of opcTJmp, opcFJmp:
          if c.code[d].regA != reg: break
          # tjmp x, 23
          # ...
          # tjmp x, 12
          # -- we know 'x' is true, and so can jump to 12+13:
          if c.code[d].opcode == opc:
            d = d + c.code[d].jmpDiff
          else:
            # tjmp x, 23
            # fjmp x, 22
            # We know 'x' is true so skip to the next instruction:
            d = d + 1
        else: break
      if d != i + c.code[i].jmpDiff:
        c.finalJumpTarget(i, d - i)
    of opcJmp, opcJmpBack:
      var d = i + c.code[i].jmpDiff
      var iters = maxIterations
      while c.code[d].opcode == opcJmp and iters > 0:
        d = d + c.code[d].jmpDiff
        dec iters
      if c.code[d].opcode == opcRet:
        # optimize 'jmp to ret' to 'ret' here
        c.code[i] = c.code[d]
      elif d != i + c.code[i].jmpDiff:
        c.finalJumpTarget(i, d - i)
    else: discard

proc genProc(c: PCtx; s: PSym): int =
  var x = s.ast.sons[miscPos]
  if x.kind == nkEmpty or x[0].kind == nkEmpty:
    #if s.name.s == "outterMacro" or s.name.s == "innerProc":
    #  echo "GENERATING CODE FOR ", s.name.s
    let last = c.code.len-1
    var eofInstr: TInstr
    if last >= 0 and c.code[last].opcode == opcEof:
      eofInstr = c.code[last]
      c.code.setLen(last)
      c.debug.setLen(last)
    #c.removeLastEof
    result = c.code.len+1 # skip the jump instruction
    if x.kind == nkEmpty:
      x = newTree(nkBracket, newIntNode(nkIntLit, result), x)
    else:
      x.sons[0] = newIntNode(nkIntLit, result)
    s.ast.sons[miscPos] = x
    # thanks to the jmp we can add top level statements easily and also nest
    # procs easily:
    let body = transformBody(c.graph, s, cache = not isCompileTimeProc(s),
                             noDestructors = true)
    let procStart = c.xjmp(body, opcJmp, 0)
    var p = PProc(blocks: @[], sym: s)
    let oldPrc = c.prc
    c.prc = p
    # iterate over the parameters and allocate space for them:
    genParams(c, s.typ.n)

    # allocate additional space for any generically bound parameters
    if s.kind == skMacro and
       sfImmediate notin s.flags and
       s.ast[genericParamsPos].kind != nkEmpty:
      genGenericParams(c, s.ast[genericParamsPos])

    if tfCapturesEnv in s.typ.flags:
      #let env = s.ast.sons[paramsPos].lastSon.sym
      #assert env.position == 2
      c.prc.slots[c.prc.maxSlots] = (inUse: true, kind: slotFixedLet)
      inc c.prc.maxSlots
    gen(c, body)
    # generate final 'return' statement:
    c.gABC(body, opcRet)
    c.patch(procStart)
    c.gABC(body, opcEof, eofInstr.regA)
    c.optimizeJumps(result)
    s.offset = c.prc.maxSlots
    # if s.name.s == "fun1":
    #   echo renderTree(body)
    #   c.echoCode(result)
    c.prc = oldPrc
  else:
    c.prc.maxSlots = s.offset
    result = x[0].intVal.int
