#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables, sets]
import ".." / [ast, astalgo, types, options, lineinfos, msgs, magicsys,
  modulegraphs]
import .. / ic / bitabs

import nirtypes, nirinsts, nirlineinfos, nirslots, types2ir

type
  ModuleCon = ref object
    strings: BiTable[string]
    man: LineInfoManager
    types: TypesCon
    slotGenerator: ref int
    module: PSym
    graph: ModuleGraph

  LocInfo = object
    inUse: bool
    typ: TypeId

  ProcCon = object
    config: ConfigRef
    lastFileKey: FileIndex
    lastFileVal: LitId
    labelGen: int
    exitLabel: LabelId
    code: Tree
    blocks: seq[(PSym, LabelId)]
    sm: SlotManager
    locGen: int
    m: ModuleCon
    prc: PSym

proc initModuleCon*(graph: ModuleGraph; config: ConfigRef; module: PSym): ModuleCon =
  ModuleCon(graph: graph, types: initTypesCon(config), slotGenerator: new(int), module: module)

proc initProcCon*(m: ModuleCon; prc: PSym): ProcCon =
  ProcCon(m: m, sm: initSlotManager({}, m.slotGenerator), prc: prc)

proc toLineInfo(c: var ProcCon; i: TLineInfo): PackedLineInfo =
  var val: LitId
  if c.lastFileKey == i.fileIndex:
    val = c.lastFileVal
  else:
    val = c.m.strings.getOrIncl(toFullPath(c.config, i.fileIndex))
    # remember the entry:
    c.lastFileKey = i.fileIndex
    c.lastFileVal = val
  result = pack(c.m.man, val, int32 i.line, int32 i.col)

when false:
  proc gen*(c: var ProcCon; dest: var Tree; n: PNode)
  proc genv*(c: var ProcCon; dest: var Tree; v: var Value; n: PNode)

  proc genx*(c: var ProcCon; dest: var Tree; n: PNode): SymId =
    let info = toLineInfo(c, n.info)
    let t = typeToIr(c.m.types, n.typ)
    result = allocTemp(c.sm, t)
    addSummon dest, info, result, t
    var ex = localToValue(info, result)
    genv(c, dest, ex, n)
  template withBlock(lab: LabelId; body: untyped) =
    body
    dest.addInstr(info, Label, lab)

  proc genWhile(c: var ProcCon; dest: var Tree; n: PNode) =
    # LoopLabel lab1:
    #   cond, tmp
    #   select cond
    #   of false: goto lab2
    #   body
    #   GotoLoop lab1
    # Label lab2:
    let info = toLineInfo(c, n.info)
    let loopLab = dest.addLabel(c.labelGen, info, LoopLabel)
    let theEnd = newLabel(c.labelGen)
    withBlock(theEnd):
      if isTrue(n[0]):
        c.gen(dest, n[1])
        dest.gotoLabel info, GotoLoop, loopLab
      else:
        let x = c.genx(dest, n[0])
        #dest.addSelect toLineInfo(c, n[0].kind), x
        c.gen(dest, n[1])
        dest.gotoLabel info, GotoLoop, loopLab

  proc genv*(c: var ProcCon; dest: var Tree; v: var Value; n: PNode) =
    quit "too implement"

  proc gen*(c: var ProcCon; dest: var Tree; n: PNode) =
    case n.kind
    of nkWhileStmt:
      genWhile c, dest, n
    else:
      discard

proc bestEffort(c: ProcCon): TLineInfo =
  if c.prc != nil:
    c.prc.info
  else:
    c.m.module.info

proc popBlock(c: var ProcCon; oldLen: int) =
  c.blocks.setLen(oldLen)

template withBlock(labl: PSym; info: PackedLineInfo; asmLabl: LabelId; body: untyped) {.dirty.} =
  var oldLen {.gensym.} = c.blocks.len
  c.blocks.add (labl, asmLabl)
  body
  popBlock(c, oldLen)

type
  GenFlag = enum
    gfAddrOf # Affects how variables are loaded - always loads as rkNodeAddr
    gfToOutParam
  GenFlags = set[GenFlag]

proc gen(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags = {})

proc genScope(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags = {}) =
  openScope c.sm
  gen c, n, dest, flags
  closeScope c.sm

proc freeTemp(c: var ProcCon; tmp: Value) =
  let s = extractTemp(tmp)
  if s != SymId(-1):
    freeLoc(c.sm, s)

proc getTemp(c: var ProcCon; n: PNode): Value =
  let info = toLineInfo(c, n.info)
  let t = typeToIr(c.m.types, n.typ)
  let tmp = allocTemp(c.sm, t)
  c.code.addSummon info, tmp, t
  result = localToValue(info, tmp)

template withTemp(tmp, n, body: untyped) {.dirty.} =
  var tmp = getTemp(c, n)
  body
  c.freeTemp(tmp)

proc gen(c: var ProcCon; n: PNode; flags: GenFlags = {}) =
  var tmp = default(Value)
  gen(c, n, tmp, flags)
  freeTemp c, tmp

proc genScope(c: var ProcCon; n: PNode; flags: GenFlags = {}) =
  openScope c.sm
  gen c, n, flags
  closeScope c.sm

proc genx(c: var ProcCon; n: PNode; flags: GenFlags = {}): Value =
  result = default(Value)
  gen(c, n, result, flags)

proc clearDest(c: var ProcCon; n: PNode; dest: var Value) {.inline.} =
  if n.typ.isNil or n.typ.kind == tyVoid:
    let s = extractTemp(dest)
    if s != SymId(-1):
      freeLoc(c.sm, s)

proc isNotOpr(n: PNode): bool =
  n.kind in nkCallKinds and n[0].kind == nkSym and n[0].sym.magic == mNot

proc jmpBack(c: var ProcCon; n: PNode; lab: LabelId) =
  c.code.gotoLabel toLineInfo(c, n.info), GotoLoop, lab

type
  JmpKind = enum opcFJmp, opcTJmp

proc xjmp(c: var ProcCon; n: PNode; jk: JmpKind; v: Value): LabelId =
  result = newLabel(c.labelGen)
  let info = toLineInfo(c, n.info)
  build c.code, info, Select:
    c.code.addTyped info, Bool8Id
    c.code.copyTree Tree(v)
    build c.code, info, SelectPair:
      build c.code, info, SelectValue:
        c.code.boolVal(info, jk == opcTJmp)
      c.code.gotoLabel info, Goto, result

proc patch(c: var ProcCon; n: PNode; L: LabelId) =
  addLabel c.code, toLineInfo(c, n.info), Label, L

proc genWhile(c: var ProcCon; n: PNode) =
  # lab1:
  #   cond, tmp
  #   fjmp tmp, lab2
  #   body
  #   jmp lab1
  # lab2:
  let info = toLineInfo(c, n.info)
  let lab1 = c.code.addNewLabel(c.labelGen, info, LoopLabel)
  withBlock(nil, info, lab1):
    if isTrue(n[0]):
      c.gen(n[1])
      c.jmpBack(n, lab1)
    elif isNotOpr(n[0]):
      var tmp = c.genx(n[0][1])
      let lab2 = c.xjmp(n, opcTJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n[1])
      c.jmpBack(n, lab1)
      c.patch(n, lab2)
    else:
      var tmp = c.genx(n[0])
      let lab2 = c.xjmp(n, opcFJmp, tmp)
      c.freeTemp(tmp)
      c.gen(n[1])
      c.jmpBack(n, lab1)
      c.patch(n, lab2)

proc genBlock(c: var ProcCon; n: PNode; dest: var Value) =
  openScope c.sm
  let info = toLineInfo(c, n.info)
  let lab1 = newLabel(c.labelGen)

  withBlock(n[0].sym, info, lab1):
    c.gen(n[1], dest)

  c.code.addLabel(info, Label, lab1)
  closeScope c.sm
  c.clearDest(n, dest)

proc jumpTo(c: var ProcCon; n: PNode; L: LabelId) =
  c.code.addLabel(toLineInfo(c, n.info), Goto, L)

proc genBreak(c: var ProcCon; n: PNode) =
  if n[0].kind == nkSym:
    for i in countdown(c.blocks.len-1, 0):
      if c.blocks[i][0] == n[0].sym:
        c.jumpTo n, c.blocks[i][1]
        return
    localError(c.config, n.info, "NIR problem: cannot find 'break' target")
  else:
    c.jumpTo n, c.blocks[c.blocks.high][1]

proc genIf(c: var ProcCon; n: PNode; dest: var Value) =
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
  if isEmpty(dest) and not isEmptyType(n.typ): dest = getTemp(c, n)
  var ending = newLabel(c.labelGen)
  for i in 0..<n.len:
    var it = n[i]
    if it.len == 2:
      let info = toLineInfo(c, it[0].info)
      withTemp(tmp, it[0]):
        var elsePos: LabelId
        if isNotOpr(it[0]):
          c.gen(it[0][1], tmp)
          elsePos = c.xjmp(it[0][1], opcTJmp, tmp) # if true
        else:
          c.gen(it[0], tmp)
          elsePos = c.xjmp(it[0], opcFJmp, tmp) # if false
      c.clearDest(n, dest)
      if isEmptyType(it[1].typ): # maybe noreturn call, don't touch `dest`
        c.genScope(it[1])
      else:
        c.genScope(it[1], dest) # then part
      if i < n.len-1:
        c.jumpTo it[1], ending
      c.patch(it, elsePos)
    else:
      c.clearDest(n, dest)
      if isEmptyType(it[0].typ): # maybe noreturn call, don't touch `dest`
        c.genScope(it[0])
      else:
        c.genScope(it[0], dest)
  c.patch(n, ending)
  c.clearDest(n, dest)

proc tempToDest(c: var ProcCon; n: PNode; dest: var Value; tmp: Value) =
  if isEmpty(dest):
    dest = tmp
  else:
    let info = toLineInfo(c, n.info)
    build c.code, info, Asgn:
      c.code.addTyped info, typeToIr(c.m.types, n.typ)
      c.code.copyTree dest
      c.code.copyTree tmp
    freeTemp(c, tmp)

proc genAndOr(c: var ProcCon; n: PNode; opc: JmpKind; dest: var Value) =
  #   asgn dest, a
  #   tjmp|fjmp lab1
  #   asgn dest, b
  # lab1:
  var tmp = getTemp(c, n)
  c.gen(n[1], tmp)
  let lab1 = c.xjmp(n, opc, tmp)
  c.gen(n[2], tmp)
  c.patch(n, lab1)
  tempToDest c, n, dest, tmp

proc unused(c: var ProcCon; n: PNode; x: Value) {.inline.} =
  if hasValue(x):
    #debug(n)
    localError(c.config, n.info, "not unused")

proc caseValue(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)
  build c.code, info, SelectValue:
    let x = genx(c, n)
    c.code.copyTree x
    freeTemp(c, x)

proc caseRange(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)
  build c.code, info, SelectRange:
    let x = genx(c, n[0])
    let y = genx(c, n[1])
    c.code.copyTree x
    c.code.copyTree y
    freeTemp(c, y)
    freeTemp(c, x)

proc genCase(c: var ProcCon; n: PNode; dest: var Value) =
  if not isEmptyType(n.typ):
    if isEmpty(dest): dest = getTemp(c, n)
  else:
    unused(c, n, dest)
  var sections = newSeqOfCap[LabelId](n.len-1)
  let ending = newLabel(c.labelGen)
  let info = toLineInfo(c, n.info)
  withTemp(tmp, n[0]):
    build c.code, info, Select:
      c.code.addTyped info, typeToIr(c.m.types, n[0].typ)
      c.gen(n[0], tmp)
      for i in 1..<n.len:
        let section = newLabel(c.labelGen)
        sections.add section
        let it = n[i]
        let itinfo = toLineInfo(c, it.info)
        build c.code, itinfo, SelectPair:
          build c.code, itinfo, SelectList:
            for j in 0..<it.len-1:
              if it[j].kind == nkRange:
                caseRange c, it[j]
              else:
                caseValue c, it[j]
          c.code.addLabel itinfo, Goto, section
  for i in 1..<n.len:
    let it = n[i]
    let itinfo = toLineInfo(c, it.info)
    c.code.addLabel itinfo, Label, sections[i-1]
    c.gen it.lastSon
    if i != n.len-1:
      c.code.addLabel itinfo, Goto, ending
  c.code.addLabel info, Label, ending

proc rawCall(c: var ProcCon; info: PackedLineInfo; opc: Opcode; t: TypeId; args: var openArray[Value]) =
  build c.code, info, opc:
    c.code.addTyped info, t
    if opc in {CheckedCall, CheckedIndirectCall}:
      c.code.addLabel info, CheckedGoto, c.exitLabel
    for a in mitems(args):
      c.code.copyTree a
      freeTemp c, a

proc canRaiseDisp(p: ProcCon; n: PNode): bool =
  # we assume things like sysFatal cannot raise themselves
  if n.kind == nkSym and {sfNeverRaises, sfImportc, sfCompilerProc} * n.sym.flags != {}:
    result = false
  elif optPanics in p.config.globalOptions or
      (n.kind == nkSym and sfSystemModule in getModule(n.sym).flags and
       sfSystemRaisesDefect notin n.sym.flags):
    # we know we can be strict:
    result = canRaise(n)
  else:
    # we have to be *very* conservative:
    result = canRaiseConservative(n)

proc genCall(c: var ProcCon; n: PNode; dest: var Value) =
  let canRaise = canRaiseDisp(c, n[0])

  let opc = if n[0].kind == nkSym and n[0].sym.kind in routineKinds:
              (if canRaise: CheckedCall else: Call)
            else:
              (if canRaise: CheckedIndirectCall else: IndirectCall)
  let info = toLineInfo(c, n.info)

  # In the IR we cannot nest calls. Thus we use two passes:
  var args: seq[Value] = @[]
  var t = n[0].typ
  if t != nil: t = t.skipTypes(abstractInst)
  args.add genx(c, n[0])
  for i in 1..<n.len:
    if t != nil and i < t.len:
      if isCompileTimeOnly(t[i]): discard
      elif isOutParam(t[i]): args.add genx(c, n[i], {gfToOutParam})
      else: args.add genx(c, n[i])
    else:
      args.add genx(c, n[i])

  let tb = typeToIr(c.m.types, n.typ)
  if not isEmptyType(n.typ):
    if isEmpty(dest): dest = getTemp(c, n)
    # XXX Handle problematic aliasing here: `a = f_canRaise(a)`.
    build c.code, info, Asgn:
      c.code.addTyped info, tb
      c.code.copyTree dest
      rawCall c, info, opc, tb, args
  else:
    rawCall c, info, opc, tb, args

proc genRaise(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)
  let tb = typeToIr(c.m.types, n[0].typ)

  let dest = genx(c, n[0])
  build c.code, info, SetExc:
    c.code.addTyped info, tb
    c.code.copyTree dest
  c.freeTemp(dest)
  c.code.addLabel info, Goto, c.exitLabel

proc genReturn(c: var ProcCon; n: PNode) =
  if n[0].kind != nkEmpty:
    gen(c, n[0])
  # XXX Block leave actions?
  let info = toLineInfo(c, n.info)
  c.code.addLabel info, Goto, c.exitLabel

proc genTry(c: var ProcCon; n: PNode; dest: var Value) =
  if isEmpty(dest) and not isEmptyType(n.typ): dest = getTemp(c, n)
  var endings: seq[LabelId] = @[]
  let ehPos = newLabel(c.labelGen)
  let oldExitLab = c.exitLabel
  c.exitLabel = ehPos
  if isEmptyType(n[0].typ): # maybe noreturn call, don't touch `dest`
    c.gen(n[0])
  else:
    c.gen(n[0], dest)
  c.clearDest(n, dest)

  # Add a jump past the exception handling code
  let jumpToFinally = newLabel(c.labelGen)
  c.jumpTo n, jumpToFinally
  # This signals where the body ends and where the exception handling begins
  c.patch(n, ehPos)
  c.exitLabel = oldExitLab
  for i in 1..<n.len:
    let it = n[i]
    if it.kind != nkFinally:
      # first opcExcept contains the end label of the 'except' block:
      let endExcept = newLabel(c.labelGen)
      for j in 0..<it.len - 1:
        assert(it[j].kind == nkType)
        let typ = it[j].typ.skipTypes(abstractPtrs-{tyTypeDesc})
        let itinfo = toLineInfo(c, it[j].info)
        build c.code, itinfo, TestExc:
          c.code.addTyped itinfo, typeToIr(c.m.types, typ)
      if it.len == 1:
        let itinfo = toLineInfo(c, it.info)
        build c.code, itinfo, TestExc:
          c.code.addTyped itinfo, VoidId
      let body = it.lastSon
      if isEmptyType(body.typ): # maybe noreturn call, don't touch `dest`
        c.gen(body)
      else:
        c.gen(body, dest)
      c.clearDest(n, dest)
      if i < n.len:
        endings.add newLabel(c.labelGen)
      c.patch(it, endExcept)
  let fin = lastSon(n)
  # we always generate an 'opcFinally' as that pops the safepoint
  # from the stack if no exception is raised in the body.
  c.patch(fin, jumpToFinally)
  #c.gABx(fin, opcFinally, 0, 0)
  for endPos in endings: c.patch(n, endPos)
  if fin.kind == nkFinally:
    c.gen(fin[0])
    c.clearDest(n, dest)
  #c.gABx(fin, opcFinallyEnd, 0, 0)

template isGlobal(s: PSym): bool = sfGlobal in s.flags and s.kind != skForVar
proc isGlobal(n: PNode): bool = n.kind == nkSym and isGlobal(n.sym)

proc genField(c: var ProcCon; n: PNode; dest: var Value) =
  var pos: int
  if n.kind != nkSym or n.sym.kind != skField:
    localError(c.config, n.info, "no field symbol")
    pos = 0
  else:
    pos = n.sym.position
  dest.addImmediateVal toLineInfo(c, n.info), pos

proc genIndex(c: var ProcCon; n: PNode; arr: PType; dest: var Value) =
  if arr.skipTypes(abstractInst).kind == tyArray and
      (let x = firstOrd(c.config, arr); x != Zero):
    let info = toLineInfo(c, n.info)
    build dest, info, Sub:
      dest.addTyped info, Int32Id
      c.gen(n, dest)
      dest.addImmediateVal toLineInfo(c, n.info), toInt(x)
  else:
    c.gen(n, dest)

proc rawNew(c: var ProcCon; n: PNode; needsInit: bool) =
  # If in doubt, always follow the blueprint of the C code generator for `mm:orc`.
  let refType = n[1].typ.skipTypes(abstractInstOwned)
  assert refType.kind == tyRef
  let baseType = refType.lastSon

  let info = toLineInfo(c, n.info)
  let codegenProc = magicsys.getCompilerProc(c.m.graph,
    if needsInit: "nimNewObj" else: "nimNewObjUninit")
  let x = genx(c, n[1])
  let refTypeIr = typeToIr(c.m.types, refType)
  build c.code, info, Asgn:
    c.code.addTyped info, refTypeIr
    copyTree c.code, x
    build c.code, info, Cast:
      c.code.addTyped info, refTypeIr
      build c.code, info, Call:
        c.code.addTyped info, VoidId # fixme, should be pointer to void
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        c.code.addImmediateVal info, int(getSize(c.config, baseType))
        c.code.addImmediateVal info, int(getAlign(c.config, baseType))

  freeTemp c, x

#[
proc genCheckedObjAccessAux(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags)

proc genNewSeq(c: var ProcCon; n: PNode) =
  let t = n[1].typ
  let dest = c.genx(n[1])
  let tmp = c.genx(n[2])
  c.gABx(n, opcNewSeq, dest, c.genType(t.skipTypes(
                                                  abstractVar-{tyTypeDesc})))
  c.gABx(n, opcNewSeq, tmp, 0)
  c.freeTemp(tmp)
  c.freeTemp(dest)

proc genNewSeqOfCap(c: var ProcCon; n: PNode; dest: var Value) =
  let t = n.typ
  if isEmpty(dest):
    dest = c.getTemp(n)
  let tmp = c.getTemp(n[1])
  c.gABx(n, opcLdNull, dest, c.genType(t))
  c.gABx(n, opcLdImmInt, tmp, 0)
  c.gABx(n, opcNewSeq, dest, c.genType(t.skipTypes(
                                                  abstractVar-{tyTypeDesc})))
  c.gABx(n, opcNewSeq, tmp, 0)
  c.freeTemp(tmp)

proc genUnaryABC(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  let tmp = c.genx(n[1])
  if isEmpty(dest): dest = c.getTemp(n)
  c.gABC(n, opc, dest, tmp)
  c.freeTemp(tmp)

proc genUnaryABI(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode; imm: BiggestInt=0) =
  let tmp = c.genx(n[1])
  if isEmpty(dest): dest = c.getTemp(n)
  c.gABI(n, opc, dest, tmp, imm)
  c.freeTemp(tmp)


proc genBinaryABC(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  let
    tmp = c.genx(n[1])
    tmp2 = c.genx(n[2])
  if isEmpty(dest): dest = c.getTemp(n)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

template sizeOfLikeMsg(name): string =
  "'$1' requires '.importc' types to be '.completeStruct'" % [name]

proc genNarrow(c: var ProcCon; n: PNode; dest: Value) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  # uint is uint64 in the VM, we we only need to mask the result for
  # other unsigned types:
  let size = getSize(c.config, t)
  if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and size < 8):
    c.gABC(n, opcNarrowU, dest, TRegister(size*8))
  elif t.kind in {tyInt8..tyInt32} or (t.kind == tyInt and size < 8):
    c.gABC(n, opcNarrowS, dest, TRegister(size*8))

proc genNarrowU(c: var ProcCon; n: PNode; dest: Value) =
  let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
  # uint is uint64 in the VM, we we only need to mask the result for
  # other unsigned types:
  let size = getSize(c.config, t)
  if t.kind in {tyUInt8..tyUInt32, tyInt8..tyInt32} or
    (t.kind in {tyUInt, tyInt} and size < 8):
    c.gABC(n, opcNarrowU, dest, TRegister(size*8))

proc genBinaryABCnarrow(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrow(c, n, dest)

proc genBinaryABCnarrowU(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  genBinaryABC(c, n, dest, opc)
  genNarrowU(c, n, dest)

proc genSetType(c: var ProcCon; n: PNode; dest: TRegister) =
  let t = skipTypes(n.typ, abstractInst-{tyTypeDesc})
  if t.kind == tySet:
    c.gABx(n, opcSetType, dest, c.genType(t))

proc genBinarySet(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  let
    tmp = c.genx(n[1])
    tmp2 = c.genx(n[2])
  if isEmpty(dest): dest = c.getTemp(n)
  c.genSetType(n[1], tmp)
  c.genSetType(n[2], tmp2)
  c.gABC(n, opc, dest, tmp, tmp2)
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genBinaryStmt(c: var ProcCon; n: PNode; opc: TOpcode) =
  let
    dest = c.genx(n[1])
    tmp = c.genx(n[2])
  c.gABC(n, opc, dest, tmp, 0)
  c.freeTemp(tmp)
  c.freeTemp(dest)

proc genBinaryStmtVar(c: var ProcCon; n: PNode; opc: TOpcode) =
  var x = n[1]
  if x.kind in {nkAddr, nkHiddenAddr}: x = x[0]
  let
    dest = c.genx(x)
    tmp = c.genx(n[2])
  c.gABC(n, opc, dest, tmp, 0)
  c.freeTemp(tmp)
  c.freeTemp(dest)

proc genUnaryStmt(c: var ProcCon; n: PNode; opc: TOpcode) =
  let tmp = c.genx(n[1])
  c.gABC(n, opc, tmp, 0, 0)
  c.freeTemp(tmp)

proc genVarargsABC(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  if isEmpty(dest): dest = getTemp(c, n)
  var x = c.getTempRange(n.len-1, slotTempStr)
  for i in 1..<n.len:
    var r: TRegister = x+i-1
    c.gen(n[i], r)
  c.gABC(n, opc, dest, x, n.len-1)
  c.freeTempRange(x, n.len-1)

proc isInt8Lit(n: PNode): bool =
  if n.kind in {nkCharLit..nkUInt64Lit}:
    result = n.intVal >= low(int8) and n.intVal <= high(int8)
  else:
    result = false

proc isInt16Lit(n: PNode): bool =
  if n.kind in {nkCharLit..nkUInt64Lit}:
    result = n.intVal >= low(int16) and n.intVal <= high(int16)
  else:
    result = false

proc genAddSubInt(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode) =
  if n[2].isInt8Lit:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABI(n, succ(opc), dest, tmp, n[2].intVal)
    c.freeTemp(tmp)
  else:
    genBinaryABC(c, n, dest, opc)
  c.genNarrow(n, dest)

proc genConv(c: var ProcCon; n, arg: PNode; dest: var Value; opc=opcConv) =
  let t2 = n.typ.skipTypes({tyDistinct})
  let targ2 = arg.typ.skipTypes({tyDistinct})

  proc implicitConv(): bool =
    if sameBackendType(t2, targ2): return true
    # xxx consider whether to use t2 and targ2 here
    if n.typ.kind == arg.typ.kind and arg.typ.kind == tyProc:
      # don't do anything for lambda lifting conversions:
      result = true
    else:
      result = false

  if implicitConv():
    gen(c, arg, dest)
    return

  let tmp = c.genx(arg)
  if isEmpty(dest): dest = c.getTemp(n)
  c.gABC(n, opc, dest, tmp)
  c.gABx(n, opc, 0, genType(c, n.typ.skipTypes({tyStatic})))
  c.gABx(n, opc, 0, genType(c, arg.typ.skipTypes({tyStatic})))
  c.freeTemp(tmp)

proc genCard(c: var ProcCon; n: PNode; dest: var Value) =
  let tmp = c.genx(n[1])
  if isEmpty(dest): dest = c.getTemp(n)
  c.genSetType(n[1], tmp)
  c.gABC(n, opcCard, dest, tmp)
  c.freeTemp(tmp)

proc genCastIntFloat(c: var ProcCon; n: PNode; dest: var Value) =
  const allowedIntegers = {tyInt..tyInt64, tyUInt..tyUInt64, tyChar}
  var signedIntegers = {tyInt..tyInt64}
  var unsignedIntegers = {tyUInt..tyUInt64, tyChar}
  let src = n[1].typ.skipTypes(abstractRange)#.kind
  let dst = n[0].typ.skipTypes(abstractRange)#.kind
  let srcSize = getSize(c.config, src)
  let dstSize = getSize(c.config, dst)
  const unsupportedCastDifferentSize =
    "VM does not support 'cast' from $1 with size $2 to $3 with size $4 due to different sizes"
  if src.kind in allowedIntegers and dst.kind in allowedIntegers:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n[0])
    c.gABC(n, opcAsgnInt, dest, tmp)
    if dstSize != sizeof(BiggestInt): # don't do anything on biggest int types
      if dst.kind in signedIntegers: # we need to do sign extensions
        if dstSize <= srcSize:
          # Sign extension can be omitted when the size increases.
          c.gABC(n, opcSignExtend, dest, TRegister(dstSize*8))
      elif dst.kind in unsignedIntegers:
        if src.kind in signedIntegers or dstSize < srcSize:
          # Cast from signed to unsigned always needs narrowing. Cast
          # from unsigned to unsigned only needs narrowing when target
          # is smaller than source.
          c.gABC(n, opcNarrowU, dest, TRegister(dstSize*8))
    c.freeTemp(tmp)
  elif src.kind in allowedIntegers and
      dst.kind in {tyFloat, tyFloat32, tyFloat64}:
    if srcSize != dstSize:
      globalError(c.config, n.info, unsupportedCastDifferentSize %
        [$src.kind, $srcSize, $dst.kind, $dstSize])
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n[0])
    if dst.kind == tyFloat32:
      c.gABC(n, opcCastIntToFloat32, dest, tmp)
    else:
      c.gABC(n, opcCastIntToFloat64, dest, tmp)
    c.freeTemp(tmp)

  elif src.kind in {tyFloat, tyFloat32, tyFloat64} and
                           dst.kind in allowedIntegers:
    if srcSize != dstSize:
      globalError(c.config, n.info, unsupportedCastDifferentSize %
        [$src.kind, $srcSize, $dst.kind, $dstSize])
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n[0])
    if src.kind == tyFloat32:
      c.gABC(n, opcCastFloatToInt32, dest, tmp)
      if dst.kind in unsignedIntegers:
        # integers are sign extended by default.
        # since there is no opcCastFloatToUInt32, narrowing should do the trick.
        c.gABC(n, opcNarrowU, dest, TRegister(32))
    else:
      c.gABC(n, opcCastFloatToInt64, dest, tmp)
      # narrowing for 64 bits not needed (no extended sign bits available).
    c.freeTemp(tmp)
  elif src.kind in PtrLikeKinds + {tyRef} and dst.kind == tyInt:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n[0])
    var imm: BiggestInt = if src.kind in PtrLikeKinds: 1 else: 2
    c.gABI(n, opcCastPtrToInt, dest, tmp, imm)
    c.freeTemp(tmp)
  elif src.kind in PtrLikeKinds + {tyInt} and dst.kind in PtrLikeKinds:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n[0])
    c.gABx(n, opcSetType, dest, c.genType(dst))
    c.gABC(n, opcCastIntToPtr, dest, tmp)
    c.freeTemp(tmp)
  elif src.kind == tyNil and dst.kind in NilableTypes:
    # supports casting nil literals to NilableTypes in VM
    # see #16024
    if isEmpty(dest): dest = c.getTemp(n[0])
    genLit(c, n[1], dest)
  else:
    # todo: support cast from tyInt to tyRef
    globalError(c.config, n.info, "VM does not support 'cast' from " & $src.kind & " to " & $dst.kind)

proc genBindSym(c: var ProcCon; n: PNode; dest: var Value) =
  # nah, cannot use c.config.features because sempass context
  # can have local experimental switch
  # if dynamicBindSym notin c.config.features:
  if n.len == 2: # hmm, reliable?
    # bindSym with static input
    if n[1].kind in {nkClosedSymChoice, nkOpenSymChoice, nkSym}:
      let idx = c.genLiteral(n[1])
      if isEmpty(dest): dest = c.getTemp(n)
      c.gABx(n, opcNBindSym, dest, idx)
    else:
      localError(c.config, n.info, "invalid bindSym usage")
  else:
    # experimental bindSym
    if isEmpty(dest): dest = c.getTemp(n)
    let x = c.getTempRange(n.len, slotTempUnknown)

    # callee symbol
    var tmp0 = Value(x)
    c.genLit(n[0], tmp0)

    # original parameters
    for i in 1..<n.len-2:
      var r = TRegister(x+i)
      c.gen(n[i], r)

    # info node
    var tmp1 = Value(x+n.len-2)
    c.genLit(n[^2], tmp1)

    # payload idx
    var tmp2 = Value(x+n.len-1)
    c.genLit(n[^1], tmp2)

    c.gABC(n, opcNDynBindSym, dest, x, n.len)
    c.freeTempRange(x, n.len)

proc fitsRegister*(t: PType): bool =
  assert t != nil
  t.skipTypes(abstractInst + {tyStatic} - {tyTypeDesc}).kind in {
    tyRange, tyEnum, tyBool, tyInt..tyUInt64, tyChar}

proc ldNullOpcode(t: PType): TOpcode =
  assert t != nil
  if fitsRegister(t): opcLdNullReg else: opcLdNull

proc whichAsgnOpc(n: PNode; requiresCopy = true): TOpcode =
  case n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc}).kind
  of tyBool, tyChar, tyEnum, tyOrdinal, tyInt..tyInt64, tyUInt..tyUInt64:
    opcAsgnInt
  of tyFloat..tyFloat128:
    opcAsgnFloat
  of tyRef, tyNil, tyVar, tyLent, tyPtr:
    opcAsgnRef
  else:
    (if requiresCopy: opcAsgnComplex else: opcFastAsgnComplex)

proc genMagic(c: var ProcCon; n: PNode; dest: var Value; m: TMagic) =
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
    let d = c.genx(n[1])
    if n[2].isInt8Lit and not isUnsigned:
      c.gABI(n, succ(opc), d, d, n[2].intVal)
    else:
      let tmp = c.genx(n[2])
      c.gABC(n, opc, d, d, tmp)
      c.freeTemp(tmp)
    c.genNarrow(n[1], d)
    c.freeTemp(d)
  of mOrd, mChr, mArrToSeq, mUnown: c.gen(n[1], dest)
  of generatedMagics:
    genCall(c, n, dest)
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
    # eval n[1] for possible side effects:
    c.freeTemp(c.genx(n[1]))
    var tmp = c.getTemp(n[1])
    c.gABx(n, opcLdImmInt, tmp, 0)
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABC(n, opcNewStr, dest, tmp)
    c.freeTemp(tmp)
    # XXX buggy
  of mLengthOpenArray, mLengthArray, mLengthSeq:
    genUnaryABI(c, n, dest, opcLenSeq)
  of mLengthStr:
    case n[1].typ.skipTypes(abstractVarRange).kind
    of tyString: genUnaryABI(c, n, dest, opcLenStr)
    of tyCstring: genUnaryABI(c, n, dest, opcLenCstring)
    else: raiseAssert $n[1].typ.kind
  of mSlice:
    var
      d = c.genx(n[1])
      left = c.genIndex(n[2], n[1].typ)
      right = c.genIndex(n[3], n[1].typ)
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABC(n, opcNodeToReg, dest, d)
    c.gABC(n, opcSlice, dest, left, right)
    c.freeTemp(left)
    c.freeTemp(right)
    c.freeTemp(d)

  of mIncl, mExcl:
    unused(c, n, dest)
    var d = c.genx(n[1])
    var tmp = c.genx(n[2])
    c.genSetType(n[1], d)
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
    # modified: genBinaryABC(c, n, dest, opcShrInt)
    # narrowU is applied to the left operandthe idea here is to narrow the left operand
    let tmp = c.genx(n[1])
    c.genNarrowU(n, tmp)
    let tmp2 = c.genx(n[2])
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABC(n, opcShrInt, dest, tmp, tmp2)
    c.freeTemp(tmp)
    c.freeTemp(tmp2)
  of mShlI:
    genBinaryABC(c, n, dest, opcShlInt)
    # genNarrowU modified
    let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
    let size = getSize(c.config, t)
    if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and size < 8):
      c.gABC(n, opcNarrowU, dest, TRegister(size*8))
    elif t.kind in {tyInt8..tyInt32} or (t.kind == tyInt and size < 8):
      c.gABC(n, opcSignExtend, dest, TRegister(size*8))
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
  of mLePtr, mLeU: genBinaryABC(c, n, dest, opcLeu)
  of mLtPtr, mLtU: genBinaryABC(c, n, dest, opcLtu)
  of mEqProc, mEqRef:
    genBinaryABC(c, n, dest, opcEqRef)
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
    let size = getSize(c.config, t)
    if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and size < 8):
      c.gABC(n, opcNarrowU, dest, TRegister(size*8))
  of mCharToStr, mBoolToStr, mIntToStr, mInt64ToStr, mFloatToStr, mCStrToStr, mStrToStr, mEnumToStr:
    genConv(c, n, n[1], dest)
  of mEqStr: genBinaryABC(c, n, dest, opcEqStr)
  of mEqCString: genBinaryABC(c, n, dest, opcEqCString)
  of mLeStr: genBinaryABC(c, n, dest, opcLeStr)
  of mLtStr: genBinaryABC(c, n, dest, opcLtStr)
  of mEqSet: genBinarySet(c, n, dest, opcEqSet)
  of mLeSet: genBinarySet(c, n, dest, opcLeSet)
  of mLtSet: genBinarySet(c, n, dest, opcLtSet)
  of mMulSet: genBinarySet(c, n, dest, opcMulSet)
  of mPlusSet: genBinarySet(c, n, dest, opcPlusSet)
  of mMinusSet: genBinarySet(c, n, dest, opcMinusSet)
  of mConStrStr: genVarargsABC(c, n, dest, opcConcatStr)
  of mInSet: genBinarySet(c, n, dest, opcContainsSet)
  of mRepr: genUnaryABC(c, n, dest, opcRepr)
  of mExit:
    unused(c, n, dest)
    var tmp = c.genx(n[1])
    c.gABC(n, opcQuit, tmp)
    c.freeTemp(tmp)
  of mSetLengthStr, mSetLengthSeq:
    unused(c, n, dest)
    var d = c.genx(n[1])
    var tmp = c.genx(n[2])
    c.gABC(n, if m == mSetLengthStr: opcSetLenStr else: opcSetLenSeq, d, tmp)
    c.freeTemp(tmp)
    c.freeTemp(d)
  of mSwap:
    unused(c, n, dest)
    c.gen(lowerSwap(c.graph, n, c.idgen, if c.prc == nil or c.prc.sym == nil: c.module else: c.prc.sym))
  of mIsNil: genUnaryABC(c, n, dest, opcIsNil)
  of mParseBiggestFloat:
    genCall c, n, dest
  of mReset:
    unused(c, n, dest)
    var d = c.genx(n[1])
    # XXX use ldNullOpcode() here?
    c.gABx(n, opcLdNull, d, c.genType(n[1].typ))
    c.gABC(n, opcNodeToReg, d, d)
  of mDefault, mZeroDefault:
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABx(n, ldNullOpcode(n.typ), dest, c.genType(n.typ))
  of mOf:
    if isEmpty(dest): dest = c.getTemp(n)
    var tmp = c.genx(n[1])
    var idx = c.getTemp(getSysType(c.graph, n.info, tyInt))
    var typ = n[2].typ
    if m == mOf: typ = typ.skipTypes(abstractPtrs)
    c.gABx(n, opcLdImmInt, idx, c.genType(typ))
    c.gABC(n, opcOf, dest, tmp, idx)
    c.freeTemp(tmp)
    c.freeTemp(idx)
  of mHigh:
    if isEmpty(dest): dest = c.getTemp(n)
    let tmp = c.genx(n[1])
    case n[1].typ.skipTypes(abstractVar-{tyTypeDesc}).kind
    of tyString: c.gABI(n, opcLenStr, dest, tmp, 1)
    of tyCstring: c.gABI(n, opcLenCstring, dest, tmp, 1)
    else: c.gABI(n, opcLenSeq, dest, tmp, 1)
    c.freeTemp(tmp)
  of mEcho:
    unused(c, n, dest)
    let n = n[1].skipConv
    if n.kind == nkBracket:
      # can happen for nim check, see bug #9609
      let x = c.getTempRange(n.len, slotTempUnknown)
      for i in 0..<n.len:
        var r: TRegister = x+i
        c.gen(n[i], r)
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
    genBinaryABC(c, n, dest, opcParseExprToAst)
  of mParseStmtToAst:
    genBinaryABC(c, n, dest, opcParseStmtToAst)
  of mTypeTrait:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABx(n, opcSetType, tmp, c.genType(n[1].typ))
    c.gABC(n, opcTypeTrait, dest, tmp)
    c.freeTemp(tmp)
  of mSlurp: genUnaryABC(c, n, dest, opcSlurp)
  of mNLen: genUnaryABI(c, n, dest, opcLenSeq, nimNodeFlag)
  of mGetImpl: genUnaryABC(c, n, dest, opcGetImpl)
  of mGetImplTransf: genUnaryABC(c, n, dest, opcGetImplTransf)
  of mSymOwner: genUnaryABC(c, n, dest, opcSymOwner)
  of mSymIsInstantiationOf: genBinaryABC(c, n, dest, opcSymIsInstantiationOf)
  of mNChild: genBinaryABC(c, n, dest, opcNChild)
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
  of mNctLen: genUnaryABC(c, n, dest, opcNctLen)
  of mNctGet: genBinaryABC(c, n, dest, opcNctGet)
  of mNctHasNext: genBinaryABC(c, n, dest, opcNctHasNext)
  of mNctNext: genBinaryABC(c, n, dest, opcNctNext)

  of mNIntVal: genUnaryABC(c, n, dest, opcNIntVal)
  of mNFloatVal: genUnaryABC(c, n, dest, opcNFloatVal)
  of mNSymbol: genUnaryABC(c, n, dest, opcNSymbol)
  of mNIdent: genUnaryABC(c, n, dest, opcNIdent)
  of mNGetType:
    let tmp = c.genx(n[1])
    if isEmpty(dest): dest = c.getTemp(n)
    let rc = case n[0].sym.name.s:
      of "getType": 0
      of "typeKind": 1
      of "getTypeInst": 2
      else: 3  # "getTypeImpl"
    c.gABC(n, opcNGetType, dest, tmp, rc)
    c.freeTemp(tmp)
    #genUnaryABC(c, n, dest, opcNGetType)
  of mNSizeOf:
    let imm = case n[0].sym.name.s:
      of "getSize": 0
      of "getAlign": 1
      else: 2 # "getOffset"
    c.genUnaryABI(n, dest, opcNGetSize, imm)
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
      genBinaryStmt(c, n, opcNSetLineInfoFile)
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
    if isEmpty(dest): dest = c.getTemp(n)
    c.gABC(n, opcCallSite, dest)
  of mNGenSym: genBinaryABC(c, n, dest, opcGenSym)
  of mMinI, mMaxI, mAbsI, mDotDot:
    c.genCall(n, dest)
  of mExpandToAst:
    if n.len != 2:
      globalError(c.config, n.info, "expandToAst requires 1 argument")
    let arg = n[1]
    if arg.kind in nkCallKinds:
      #if arg[0].kind != nkSym or arg[0].sym.kind notin {skTemplate, skMacro}:
      #      "ExpandToAst: expanded symbol is no macro or template"
      if isEmpty(dest): dest = c.getTemp(n)
      c.genCall(arg, dest)
      # do not call clearDest(n, dest) here as getAst has a meta-type as such
      # produces a value
    else:
      globalError(c.config, n.info, "expandToAst requires a call expression")
  of mSizeOf:
    globalError(c.config, n.info, sizeOfLikeMsg("sizeof"))
  of mAlignOf:
    globalError(c.config, n.info, sizeOfLikeMsg("alignof"))
  of mOffsetOf:
    globalError(c.config, n.info, sizeOfLikeMsg("offsetof"))
  of mRunnableExamples:
    discard "just ignore any call to runnableExamples"
  of mDestroy, mTrace: discard "ignore calls to the default destructor"
  of mEnsureMove:
    gen(c, n[1], dest)
  of mMove:
    let arg = n[1]
    let a = c.genx(arg)
    if isEmpty(dest): dest = c.getTemp(arg)
    gABC(c, arg, whichAsgnOpc(arg, requiresCopy=false), dest, a)
    c.freeTemp(a)
  of mDup:
    let arg = n[1]
    let a = c.genx(arg)
    if isEmpty(dest): dest = c.getTemp(arg)
    gABC(c, arg, whichAsgnOpc(arg, requiresCopy=false), dest, a)
    c.freeTemp(a)
  of mNodeId:
    c.genUnaryABC(n, dest, opcNodeId)
  else:
    # mGCref, mGCunref,
    globalError(c.config, n.info, "cannot generate code for: " & $m)

proc unneededIndirection(n: PNode): bool =
  n.typ.skipTypes(abstractInstOwned-{tyTypeDesc}).kind == tyRef

proc canElimAddr(n: PNode; idgen: IdGenerator): PNode =
  result = nil
  case n[0].kind
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    var m = n[0][0]
    if m.kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      result = copyNode(n[0])
      result.add m[0]
      if n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        result.typ = n.typ
      elif n.typ.skipTypes(abstractInst).kind in {tyVar}:
        result.typ = toVar(result.typ, n.typ.skipTypes(abstractInst).kind, idgen)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    var m = n[0][1]
    if m.kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( nkConv ( deref ( x ) ) ) --> nkConv(x)
      result = copyNode(n[0])
      result.add n[0][0]
      result.add m[0]
      if n.typ.skipTypes(abstractVar).kind != tyOpenArray:
        result.typ = n.typ
      elif n.typ.skipTypes(abstractInst).kind in {tyVar}:
        result.typ = toVar(result.typ, n.typ.skipTypes(abstractInst).kind, idgen)
  else:
    if n[0].kind in {nkDerefExpr, nkHiddenDeref}:
      # addr ( deref ( x )) --> x
      result = n[0][0]

proc genAddr(c: var ProcCon; n: PNode, dest: var Value, flags: GenFlags) =
  if (let m = canElimAddr(n, c.idgen); m != nil):
    gen(c, m, dest, flags)
    return

  let newflags = flags-{gfNode}+{gfNodeAddr}

  if isGlobal(n[0]) or n[0].kind in {nkDotExpr, nkCheckedFieldExpr, nkBracketExpr}:
    # checking for this pattern:  addr(obj.field) / addr(array[i])
    gen(c, n[0], dest, newflags)
  else:
    let tmp = c.genx(n[0], newflags)
    if isEmpty(dest): dest = c.getTemp(n)
    if c.prc.regInfo[tmp].kind >= slotTempUnknown:
      gABC(c, n, opcAddrNode, dest, tmp)
    else:
      gABC(c, n, opcAddrReg, dest, tmp)
    c.freeTemp(tmp)

proc genDeref(c: var ProcCon; n: PNode, dest: var Value, flags: GenFlags) =
  if unneededIndirection(n[0]):
    gen(c, n[0], dest, flags)
    if {gfNodeAddr, gfNode} * flags == {} and fitsRegister(n.typ):
      c.gABC(n, opcNodeToReg, dest, dest)
  else:
    let tmp = c.genx(n[0], flags)
    if isEmpty(dest): dest = c.getTemp(n)
    gABC(c, n, opcLdDeref, dest, tmp)
    assert n.typ != nil
    if {gfNodeAddr, gfNode} * flags == {} and fitsRegister(n.typ):
      c.gABC(n, opcNodeToReg, dest, dest)
    c.freeTemp(tmp)

proc genAsgn(c: var ProcCon; dest: Value; ri: PNode; requiresCopy: bool) =
  let tmp = c.genx(ri)
  assert dest >= 0
  gABC(c, ri, whichAsgnOpc(ri, requiresCopy), dest, tmp)
  c.freeTemp(tmp)

proc setSlot(c: var ProcCon; v: PSym) =
  # XXX generate type initialization here?
  if v.position == 0:
    v.position = getFreeRegister(c, if v.kind == skLet: slotFixedLet else: slotFixedVar, start = 1)

proc cannotEval(c: var ProcCon; n: PNode) {.noinline.} =
  globalError(c.config, n.info, "cannot evaluate at compile time: " &
    n.renderTree)

proc isOwnedBy(a, b: PSym): bool =
  result = false
  var a = a.owner
  while a != nil and a.kind != skModule:
    if a == b: return true
    a = a.owner

proc getOwner(c: ProcCon): PSym =
  result = c.prc.sym
  if result.isNil: result = c.module

proc importcCondVar*(s: PSym): bool {.inline.} =
  # see also importcCond
  if sfImportc in s.flags:
    result = s.kind in {skVar, skLet, skConst}
  else:
    result = false

proc checkCanEval(c: var ProcCon; n: PNode) =
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
    else: cannotEval(c, n)
  elif s.kind in {skProc, skFunc, skConverter, skMethod,
                  skIterator} and sfForward in s.flags:
    cannotEval(c, n)

template needsAdditionalCopy(n): untyped =
  not c.isTemp(dest) and not fitsRegister(n.typ)

proc genAdditionalCopy(c: var ProcCon; n: PNode; opc: TOpcode;
                       dest, idx, value: TRegister) =
  var cc = c.getTemp(n)
  c.gABC(n, whichAsgnOpc(n), cc, value)
  c.gABC(n, opc, dest, idx, cc)
  c.freeTemp(cc)

proc preventFalseAlias(c: var ProcCon; n: PNode; opc: TOpcode;
                       dest, idx, value: TRegister) =
  # opcLdObj et al really means "load address". We sometimes have to create a
  # copy in order to not introduce false aliasing:
  # mylocal = a.b  # needs a copy of the data!
  assert n.typ != nil
  if needsAdditionalCopy(n):
    genAdditionalCopy(c, n, opc, dest, idx, value)
  else:
    c.gABC(n, opc, dest, idx, value)

proc genAsgn(c: var ProcCon; le, ri: PNode; requiresCopy: bool) =
  case le.kind
  of nkBracketExpr:
    let
      dest = c.genx(le[0], {gfNode})
      idx = c.genIndex(le[1], le[0].typ)
      tmp = c.genx(ri)
      collTyp = le[0].typ.skipTypes(abstractVarRange-{tyTypeDesc})
    case collTyp.kind
    of tyString, tyCstring:
      c.preventFalseAlias(le, opcWrStrIdx, dest, idx, tmp)
    of tyTuple:
      c.preventFalseAlias(le, opcWrObj, dest, int le[1].intVal, tmp)
    else:
      c.preventFalseAlias(le, opcWrArr, dest, idx, tmp)
    c.freeTemp(tmp)
    c.freeTemp(idx)
    c.freeTemp(dest)
  of nkCheckedFieldExpr:
    var objR: Value = -1
    genCheckedObjAccessAux(c, le, objR, {gfNode})
    let idx = genField(c, le[0][1])
    let tmp = c.genx(ri)
    c.preventFalseAlias(le[0], opcWrObj, objR, idx, tmp)
    c.freeTemp(tmp)
    # c.freeTemp(idx) # BUGFIX, see nkDotExpr
    c.freeTemp(objR)
  of nkDotExpr:
    let dest = c.genx(le[0], {gfNode})
    let idx = genField(c, le[1])
    let tmp = c.genx(ri)
    c.preventFalseAlias(le, opcWrObj, dest, idx, tmp)
    # c.freeTemp(idx) # BUGFIX: idx is an immediate (field position), not a register
    c.freeTemp(tmp)
    c.freeTemp(dest)
  of nkDerefExpr, nkHiddenDeref:
    let dest = c.genx(le[0], {gfNode})
    let tmp = c.genx(ri)
    c.preventFalseAlias(le, opcWrDeref, dest, 0, tmp)
    c.freeTemp(dest)
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
                                        s.kind in {skParam, skResult})
      var dest: TRegister = s.position + ord(s.kind == skParam)
      assert le.typ != nil
      if needsAdditionalCopy(le) and s.kind in {skResult, skVar, skParam}:
        var cc = c.getTemp(le)
        gen(c, ri, cc)
        c.gABC(le, whichAsgnOpc(le), dest, cc)
        c.freeTemp(cc)
      else:
        gen(c, ri, dest)
  else:
    let dest = c.genx(le, {gfNodeAddr})
    genAsgn(c, dest, ri, requiresCopy)
    c.freeTemp(dest)

proc genTypeLit(c: var ProcCon; t: PType; dest: var Value) =
  var n = newNode(nkType)
  n.typ = t
  genLit(c, n, dest)

proc isEmptyBody(n: PNode): bool =
  case n.kind
  of nkStmtList:
    for i in 0..<n.len:
      if not isEmptyBody(n[i]): return false
    result = true
  else:
    result = n.kind in {nkCommentStmt, nkEmpty}

proc importcCond*(c: var ProcCon; s: PSym): bool {.inline.} =
  ## return true to importc `s`, false to execute its body instead (refs #8405)
  result = false
  if sfImportc in s.flags:
    if s.kind in routineKinds:
      return isEmptyBody(getBody(c.graph, s))

proc importcSym(c: var ProcCon; info: TLineInfo; s: PSym) =
  when hasFFI:
    if compiletimeFFI in c.config.features:
      c.globals.add(importcSymbol(c.config, s))
      s.position = c.globals.len
    else:
      localError(c.config, info,
        "VM is not allowed to 'importc' without --experimental:compiletimeFFI")
  else:
    localError(c.config, info,
               "cannot 'importc' variable at compile time; " & s.name.s)

proc getNullValue*(typ: PType, info: TLineInfo; config: ConfigRef): PNode

proc genGlobalInit(c: var ProcCon; n: PNode; s: PSym) =
  c.globals.add(getNullValue(s.typ, n.info, c.config))
  s.position = c.globals.len
  # This is rather hard to support, due to the laziness of the VM code
  # generator. See tests/compile/tmacro2 for why this is necessary:
  #   var decls{.compileTime.}: seq[NimNode] = @[]
  let dest = c.getTemp(s)
  c.gABx(n, opcLdGlobal, dest, s.position)
  if s.astdef != nil:
    let tmp = c.genx(s.astdef)
    c.genAdditionalCopy(n, opcWrDeref, dest, 0, tmp)
    c.freeTemp(dest)
    c.freeTemp(tmp)

proc genRdVar(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags) =
  # gfNodeAddr and gfNode are mutually exclusive
  assert card(flags * {gfNodeAddr, gfNode}) < 2
  let s = n.sym
  if s.isGlobal:
    let isImportcVar = importcCondVar(s)
    if sfCompileTime in s.flags or c.mode == emRepl or isImportcVar:
      discard
    elif s.position == 0:
      cannotEval(c, n)
    if s.position == 0:
      if importcCond(c, s) or isImportcVar: c.importcSym(n.info, s)
      else: genGlobalInit(c, n, s)
    if isEmpty(dest): dest = c.getTemp(n)
    assert s.typ != nil

    if gfNodeAddr in flags:
      if isImportcVar:
        c.gABx(n, opcLdGlobalAddrDerefFFI, dest, s.position)
      else:
        c.gABx(n, opcLdGlobalAddr, dest, s.position)
    elif isImportcVar:
      c.gABx(n, opcLdGlobalDerefFFI, dest, s.position)
    elif fitsRegister(s.typ) and gfNode notin flags:
      var cc = c.getTemp(n)
      c.gABx(n, opcLdGlobal, cc, s.position)
      c.gABC(n, opcNodeToReg, dest, cc)
      c.freeTemp(cc)
    else:
      c.gABx(n, opcLdGlobal, dest, s.position)
  else:
    if s.kind == skForVar and c.mode == emRepl: c.setSlot(s)
    if s.position > 0 or (s.position == 0 and
                          s.kind in {skParam, skResult}):
      if isEmpty(dest):
        dest = s.position + ord(s.kind == skParam)
        internalAssert(c.config, c.prc.regInfo[dest].kind < slotSomeTemp)
      else:
        # we need to generate an assignment:
        let requiresCopy = c.prc.regInfo[dest].kind >= slotSomeTemp and
          gfIsParam notin flags
        genAsgn(c, dest, n, requiresCopy)
    else:
      # see tests/t99bott for an example that triggers it:
      cannotEval(c, n)

template needsRegLoad(): untyped =
  {gfNode, gfNodeAddr} * flags == {} and
    fitsRegister(n.typ.skipTypes({tyVar, tyLent, tyStatic}))

proc genArrAccessOpcode(c: var ProcCon; n: PNode; dest: var Value; opc: TOpcode;
                        flags: GenFlags) =
  let a = c.genx(n[0], flags)
  let b = c.genIndex(n[1], n[0].typ)
  if isEmpty(dest): dest = c.getTemp(n)
  if opc in {opcLdArrAddr, opcLdStrIdxAddr} and gfNodeAddr in flags:
    c.gABC(n, opc, dest, a, b)
  elif needsRegLoad():
    var cc = c.getTemp(n)
    c.gABC(n, opc, cc, a, b)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    #message(c.config, n.info, warnUser, "argh")
    #echo "FLAGS ", flags, " ", fitsRegister(n.typ), " ", typeToString(n.typ)
    c.gABC(n, opc, dest, a, b)
  c.freeTemp(a)
  c.freeTemp(b)

proc genObjAccessAux(c: var ProcCon; n: PNode; a, b: int, dest: var Value; flags: GenFlags) =
  if isEmpty(dest): dest = c.getTemp(n)
  if {gfNodeAddr} * flags != {}:
    c.gABC(n, opcLdObjAddr, dest, a, b)
  elif needsRegLoad():
    var cc = c.getTemp(n)
    c.gABC(n, opcLdObj, cc, a, b)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    c.gABC(n, opcLdObj, dest, a, b)
  c.freeTemp(a)

proc genObjAccess(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags) =
  genObjAccessAux(c, n, c.genx(n[0], flags), genField(c, n[1]), dest, flags)

proc genCheckedObjAccessAux(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags) =
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
  var discVal = c.getTemp(disc)
  c.gABC(n, opcLdObj, discVal, dest, genField(c, disc))
  # Check if its value is contained in the supplied set
  let setLit = c.genx(checkExpr[1])
  var rs = c.getTemp(getSysType(c.graph, n.info, tyBool))
  c.gABC(n, opcContainsSet, rs, setLit, discVal)
  c.freeTemp(setLit)
  # If the check fails let the user know
  let lab1 = c.xjmp(n, if negCheck: opcFJmp else: opcTJmp, rs)
  c.freeTemp(rs)
  let strType = getSysType(c.graph, n.info, tyString)
  var msgReg: Value = c.getTemp(strType)
  let fieldName = $accessExpr[1]
  let msg = genFieldDefect(c.config, fieldName, disc.sym)
  let strLit = newStrNode(msg, accessExpr[1].info)
  strLit.typ = strType
  c.genLit(strLit, msgReg)
  c.gABC(n, opcInvalidField, msgReg, discVal)
  c.freeTemp(discVal)
  c.freeTemp(msgReg)
  c.patch(lab1)

proc genCheckedObjAccess(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags) =
  var objR: Value = -1
  genCheckedObjAccessAux(c, n, objR, flags)

  let accessExpr = n[0]
  # Field symbol
  var field = accessExpr[1]
  internalAssert c.config, field.sym.kind == skField

  # Load the content now
  if isEmpty(dest): dest = c.getTemp(n)
  let fieldPos = genField(c, field)

  if {gfNodeAddr} * flags != {}:
    c.gABC(n, opcLdObjAddr, dest, objR, fieldPos)
  elif needsRegLoad():
    var cc = c.getTemp(accessExpr)
    c.gABC(n, opcLdObj, cc, objR, fieldPos)
    c.gABC(n, opcNodeToReg, dest, cc)
    c.freeTemp(cc)
  else:
    c.gABC(n, opcLdObj, dest, objR, fieldPos)

  c.freeTemp(objR)

proc genArrAccess(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags) =
  let arrayType = n[0].typ.skipTypes(abstractVarRange-{tyTypeDesc}).kind
  case arrayType
  of tyString, tyCstring:
    let opc = if gfNodeAddr in flags: opcLdStrIdxAddr else: opcLdStrIdx
    genArrAccessOpcode(c, n, dest, opc, flags)
  of tyTuple:
    c.genObjAccessAux(n, c.genx(n[0], flags), int n[1].intVal, dest, flags)
  of tyTypeDesc:
    c.genTypeLit(n.typ, dest)
  else:
    let opc = if gfNodeAddr in flags: opcLdArrAddr else: opcLdArr
    genArrAccessOpcode(c, n, dest, opc, flags)

proc getNullValueAux(t: PType; obj: PNode, result: PNode; config: ConfigRef; currPosition: var int) =
  if t != nil and t.len > 0 and t[0] != nil:
    let b = skipTypes(t[0], skipPtrs)
    getNullValueAux(b, b.n, result, config, currPosition)
  case obj.kind
  of nkRecList:
    for i in 0..<obj.len: getNullValueAux(nil, obj[i], result, config, currPosition)
  of nkRecCase:
    getNullValueAux(nil, obj[0], result, config, currPosition)
    for i in 1..<obj.len:
      getNullValueAux(nil, lastSon(obj[i]), result, config, currPosition)
  of nkSym:
    let field = newNodeI(nkExprColonExpr, result.info)
    field.add(obj)
    let value = getNullValue(obj.sym.typ, result.info, config)
    value.flags.incl nfSkipFieldChecking
    field.add(value)
    result.add field
    doAssert obj.sym.position == currPosition
    inc currPosition
  else: globalError(config, result.info, "cannot create null element for: " & $obj)

proc getNullValue(typ: PType, info: TLineInfo; config: ConfigRef): PNode =
  var t = skipTypes(typ, abstractRange+{tyStatic, tyOwned}-{tyTypeDesc})
  case t.kind
  of tyBool, tyEnum, tyChar, tyInt..tyInt64:
    result = newNodeIT(nkIntLit, info, t)
  of tyUInt..tyUInt64:
    result = newNodeIT(nkUIntLit, info, t)
  of tyFloat..tyFloat128:
    result = newNodeIT(nkFloatLit, info, t)
  of tyString:
    result = newNodeIT(nkStrLit, info, t)
    result.strVal = ""
  of tyCstring, tyVar, tyLent, tyPointer, tyPtr, tyUntyped,
     tyTyped, tyTypeDesc, tyRef, tyNil:
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
    # initialize inherited fields, and all in the correct order:
    var currPosition = 0
    getNullValueAux(t, t.n, result, config, currPosition)
  of tyArray:
    result = newNodeIT(nkBracket, info, t)
    for i in 0..<toInt(lengthOrd(config, t)):
      result.add getNullValue(elemType(t), info, config)
  of tyTuple:
    result = newNodeIT(nkTupleConstr, info, t)
    for i in 0..<t.len:
      result.add getNullValue(t[i], info, config)
  of tySet:
    result = newNodeIT(nkCurly, info, t)
  of tySequence, tyOpenArray:
    result = newNodeIT(nkBracket, info, t)
  else:
    globalError(config, info, "cannot create null element for: " & $t.kind)
    result = newNodeI(nkEmpty, info)

proc genVarSection(c: var ProcCon; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt: continue
    #assert(a[0].kind == nkSym) can happen for transformed vars
    if a.kind == nkVarTuple:
      for i in 0..<a.len-2:
        if a[i].kind == nkSym:
          if not a[i].sym.isGlobal: setSlot(c, a[i].sym)
          checkCanEval(c, a[i])
      c.gen(lowerTupleUnpacking(c.graph, a, c.idgen, c.getOwner))
    elif a[0].kind == nkSym:
      let s = a[0].sym
      checkCanEval(c, a[0])
      if s.isGlobal:
        let runtimeAccessToCompileTime = c.mode == emRepl and
              sfCompileTime in s.flags and s.position > 0
        if s.position == 0:
          if importcCond(c, s): c.importcSym(a.info, s)
          else:
            let sa = getNullValue(s.typ, a.info, c.config)
            #if s.ast.isNil: getNullValue(s.typ, a.info)
            #else: s.ast
            assert sa.kind != nkCall
            c.globals.add(sa)
            s.position = c.globals.len
        if runtimeAccessToCompileTime:
          discard
        elif a[2].kind != nkEmpty:
          let tmp = c.genx(a[0], {gfNodeAddr})
          let val = c.genx(a[2])
          c.genAdditionalCopy(a[2], opcWrDeref, tmp, 0, val)
          c.freeTemp(val)
          c.freeTemp(tmp)
        elif not importcCondVar(s) and not (s.typ.kind == tyProc and s.typ.callConv == ccClosure) and
                sfPure notin s.flags: # fixes #10938
          # there is a pre-existing issue with closure types in VM
          # if `(var s: proc () = default(proc ()); doAssert s == nil)` works for you;
          # you might remove the second condition.
          # the problem is that closure types are tuples in VM, but the types of its children
          # shouldn't have the same type as closure types.
          let tmp = c.genx(a[0], {gfNodeAddr})
          let sa = getNullValue(s.typ, a.info, c.config)
          let val = c.genx(sa)
          c.genAdditionalCopy(sa, opcWrDeref, tmp, 0, val)
          c.freeTemp(val)
          c.freeTemp(tmp)
      else:
        setSlot(c, s)
        if a[2].kind == nkEmpty:
          c.gABx(a, ldNullOpcode(s.typ), s.position, c.genType(s.typ))
        else:
          assert s.typ != nil
          if not fitsRegister(s.typ):
            c.gABx(a, ldNullOpcode(s.typ), s.position, c.genType(s.typ))
          let le = a[0]
          assert le.typ != nil
          if not fitsRegister(le.typ) and s.kind in {skResult, skVar, skParam}:
            var cc = c.getTemp(le)
            gen(c, a[2], cc)
            c.gABC(le, whichAsgnOpc(le), s.position.TRegister, cc)
            c.freeTemp(cc)
          else:
            gen(c, a[2], s.position.TRegister)
    else:
      # assign to a[0]; happens for closures
      if a[2].kind == nkEmpty:
        let tmp = genx(c, a[0])
        c.gABx(a, ldNullOpcode(a[0].typ), tmp, c.genType(a[0].typ))
        c.freeTemp(tmp)
      else:
        genAsgn(c, a[0], a[2], true)

proc genArrayConstr(c: var ProcCon; n: PNode, dest: var Value) =
  if isEmpty(dest): dest = c.getTemp(n)
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
      c.preventFalseAlias(n, opcWrArr, dest, tmp, a)
      c.gABI(n, opcAddImmInt, tmp, tmp, 1)
      c.freeTemp(a)
    c.freeTemp(tmp)

proc genSetConstr(c: var ProcCon; n: PNode, dest: var Value) =
  if isEmpty(dest): dest = c.getTemp(n)
  c.gABx(n, opcLdNull, dest, c.genType(n.typ))
  for x in n:
    if x.kind == nkRange:
      let a = c.genx(x[0])
      let b = c.genx(x[1])
      c.gABC(n, opcInclRange, dest, a, b)
      c.freeTemp(b)
      c.freeTemp(a)
    else:
      let a = c.genx(x)
      c.gABC(n, opcIncl, dest, a)
      c.freeTemp(a)

proc genObjConstr(c: var ProcCon; n: PNode, dest: var Value) =
  if isEmpty(dest): dest = c.getTemp(n)
  let t = n.typ.skipTypes(abstractRange+{tyOwned}-{tyTypeDesc})
  if t.kind == tyRef:
    c.gABx(n, opcNew, dest, c.genType(t[0]))
  else:
    c.gABx(n, opcLdNull, dest, c.genType(n.typ))
  for i in 1..<n.len:
    let it = n[i]
    if it.kind == nkExprColonExpr and it[0].kind == nkSym:
      let idx = genField(c, it[0])
      let tmp = c.genx(it[1])
      c.preventFalseAlias(it[1], opcWrObj,
                          dest, idx, tmp)
      c.freeTemp(tmp)
    else:
      globalError(c.config, n.info, "invalid object constructor")

proc genTupleConstr(c: var ProcCon; n: PNode, dest: var Value) =
  if isEmpty(dest): dest = c.getTemp(n)
  if n.typ.kind != tyTypeDesc:
    c.gABx(n, opcLdNull, dest, c.genType(n.typ))
    # XXX x = (x.old, 22)  produces wrong code ... stupid self assignments
    for i in 0..<n.len:
      let it = n[i]
      if it.kind == nkExprColonExpr:
        let idx = genField(c, it[0])
        let tmp = c.genx(it[1])
        c.preventFalseAlias(it[1], opcWrObj,
                            dest, idx, tmp)
        c.freeTemp(tmp)
      else:
        let tmp = c.genx(it)
        c.preventFalseAlias(it, opcWrObj, dest, i.TRegister, tmp)
        c.freeTemp(tmp)

proc genProc*(c: var ProcCon; s: PSym): int

proc toKey(s: PSym): string =
  result = ""
  var s = s
  while s != nil:
    result.add s.name.s
    if s.owner != nil:
      if sfFromGeneric in s.flags:
        s = s.instantiatedFrom.owner
      else:
        s = s.owner
      result.add "."
    else:
      break

proc procIsCallback(c: var ProcCon; s: PSym): bool =
  if s.offset < -1: return true
  let key = toKey(s)
  if c.callbackIndex.contains(key):
    let index = c.callbackIndex[key]
    doAssert s.offset == -1
    s.offset = -2'i32 - index.int32
    result = true
  else:
    result = false

proc gen(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags = {}) =
  when defined(nimCompilerStacktraceHints):
    setFrameMsg c.config$n.info & " " & $n.kind & " " & $flags
  case n.kind
  of nkSym:
    let s = n.sym
    checkCanEval(c, n)
    case s.kind
    of skVar, skForVar, skTemp, skLet, skResult:
      genRdVar(c, n, dest, flags)
    of skParam:
      if s.typ.kind == tyTypeDesc:
        genTypeLit(c, s.typ, dest)
      else:
        genRdVar(c, n, dest, flags)
    of skProc, skFunc, skConverter, skMacro, skTemplate, skMethod, skIterator:
      # 'skTemplate' is only allowed for 'getAst' support:
      if s.kind == skIterator and s.typ.callConv == TCallingConvention.ccClosure:
        globalError(c.config, n.info, "Closure iterators are not supported by VM!")
      if procIsCallback(c, s): discard
      elif importcCond(c, s): c.importcSym(n.info, s)
      genLit(c, n, dest)
    of skConst:
      let constVal = if s.astdef != nil: s.astdef else: s.typ.n
      if dontInlineConstant(n, constVal):
        genLit(c, constVal, dest)
      else:
        gen(c, constVal, dest)
    of skEnumField:
      # we never reach this case - as of the time of this comment,
      # skEnumField is folded to an int in semfold.nim, but this code
      # remains for robustness
      if isEmpty(dest): dest = c.getTemp(n)
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
    if n[0].kind == nkSym:
      let s = n[0].sym
      if s.magic != mNone:
        genMagic(c, n, dest, s.magic)
      elif s.kind == skMethod:
        localError(c.config, n.info, "cannot call method " & s.name.s &
          " at compile time")
      else:
        genCall(c, n, dest)
        clearDest(c, n, dest)
    else:
      genCall(c, n, dest)
      clearDest(c, n, dest)
  of nkCharLit..nkInt64Lit:
    if isInt16Lit(n):
      if isEmpty(dest): dest = c.getTemp(n)
      c.gABx(n, opcLdImmInt, dest, n.intVal.int)
    else:
      genLit(c, n, dest)
  of nkUIntLit..pred(nkNilLit): genLit(c, n, dest)
  of nkNilLit:
    if not n.typ.isEmptyType: genLit(c, getNullValue(n.typ, n.info, c.config), dest)
    else: unused(c, n, dest)
  of nkAsgn, nkFastAsgn, nkSinkAsgn:
    unused(c, n, dest)
    genAsgn(c, n[0], n[1], n.kind == nkAsgn)
  of nkDotExpr: genObjAccess(c, n, dest, flags)
  of nkCheckedFieldExpr: genCheckedObjAccess(c, n, dest, flags)
  of nkBracketExpr: genArrAccess(c, n, dest, flags)
  of nkDerefExpr, nkHiddenDeref: genDeref(c, n, dest, flags)
  of nkAddr, nkHiddenAddr: genAddr(c, n, dest, flags)
  of nkIfStmt, nkIfExpr: genIf(c, n, dest)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n[0][1], dest)
  of nkCaseStmt: genCase(c, n, dest)
  of nkWhileStmt:
    unused(c, n, dest)
    genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n, dest)
  of nkReturnStmt: genReturn(c, n)
  of nkRaiseStmt: genRaise(c, n)
  of nkBreakStmt: genBreak(c, n)
  of nkTryStmt, nkHiddenTryStmt: genTry(c, n, dest)
  of nkStmtList:
    #unused(c, n, dest)
    # XXX Fix this bug properly, lexim triggers it
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
  of nkObjDownConv:
    genConv(c, n, n[0], dest)
  of nkObjUpConv:
    genConv(c, n, n[0], dest)
  of nkVarSection, nkLetSection:
    unused(c, n, dest)
    genVarSection(c, n)
  of nkLambdaKinds:
    #let s = n[namePos].sym
    #discard genProc(c, s)
    genLit(c, newSymNode(n[namePos].sym), dest)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    let
      tmp0 = c.genx(n[0])
      tmp1 = c.genx(n[1])
      tmp2 = c.genx(n[2])
    c.gABC(n, opcRangeChck, tmp0, tmp1, tmp2)
    c.freeTemp(tmp1)
    c.freeTemp(tmp2)
    if dest >= 0:
      gABC(c, n, whichAsgnOpc(n), dest, tmp0)
      c.freeTemp(tmp0)
    else:
      dest = tmp0
  of nkEmpty, nkCommentStmt, nkTypeSection, nkConstSection, nkPragma,
     nkTemplateDef, nkIncludeStmt, nkImportStmt, nkFromStmt, nkExportStmt,
     nkMixinStmt, nkBindStmt, declarativeDefs, nkMacroDef:
    unused(c, n, dest)
  of nkStringToCString, nkCStringToString:
    gen(c, n[0], dest)
  of nkBracket: genArrayConstr(c, n, dest)
  of nkCurly: genSetConstr(c, n, dest)
  of nkObjConstr: genObjConstr(c, n, dest)
  of nkPar, nkClosure, nkTupleConstr: genTupleConstr(c, n, dest)
  of nkCast:
    if allowCast in c.features:
      genConv(c, n, n[1], dest, opcCast)
    else:
      genCastIntFloat(c, n, dest)
  of nkTypeOfExpr:
    genTypeLit(c, n.typ, dest)
  of nkComesFrom:
    discard "XXX to implement for better stack traces"
  else:
    localError(c.config, n.info, "cannot generate IR code for " & $n)

proc genStmt*(c: var ProcCon; n: PNode): int =
  result = c.code.len
  var d = default(Value)
  c.gen(n, d)
  unused c, n, d

proc genExpr*(c: var ProcCon; n: PNode, requiresValue = true): int =
  result = c.code.len
  var d = default(Value)
  c.gen(n, d)
  if isEmpty d:
    if requiresValue:
      globalError(c.config, n.info, "VM problem: dest register is not set")

proc genParams(c: var ProcCon; params: PNode) =
  # res.sym.position is already 0
  setLen(c.prc.regInfo, max(params.len, 1))
  c.prc.regInfo[0] = (inUse: true, kind: slotFixedVar)
  for i in 1..<params.len:
    c.prc.regInfo[i] = (inUse: true, kind: slotFixedLet)

]#

proc gen(c: var ProcCon; n: PNode; dest: var Value; flags: GenFlags = {}) =
  discard
