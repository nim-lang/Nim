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
  modulegraphs, renderer, transf, bitsets, trees, nimsets,
  expanddefaults]
from ".." / lowerings import lowerSwap, lowerTupleUnpacking
from ".." / pathutils import customPath
import .. / ic / bitabs

import nirtypes, nirinsts, nirlineinfos, nirslots, types2ir, nirfiles

when defined(nimCompilerStacktraceHints):
  import std/stackframes

type
  ModuleCon* = ref object
    nirm*: ref NirModule
    types: TypesCon
    module*: PSym
    graph*: ModuleGraph
    nativeIntId, nativeUIntId: TypeId
    strPayloadId: (TypeId, TypeId)
    idgen: IdGenerator
    processedProcs, pendingProcsAsSet: HashSet[ItemId]
    pendingProcs: seq[PSym] # procs we still need to generate code for
    noModularity*: bool
    inProc: int
    toSymId: Table[ItemId, SymId]
    symIdCounter: int32

  ProcCon* = object
    config*: ConfigRef
    lit: Literals
    lastFileKey: FileIndex
    lastFileVal: LitId
    labelGen: int
    exitLabel: LabelId
    #code*: Tree
    blocks: seq[(PSym, LabelId)]
    sm: SlotManager
    idgen: IdGenerator
    m: ModuleCon
    prc: PSym
    options: TOptions

template code(c: ProcCon): Tree = c.m.nirm.code

proc initModuleCon*(graph: ModuleGraph; config: ConfigRef; idgen: IdGenerator; module: PSym;
                    nirm: ref NirModule): ModuleCon =
  #let lit = Literals() # must be shared
  result = ModuleCon(graph: graph, types: initTypesCon(config), nirm: nirm,
    idgen: idgen, module: module)
  case config.target.intSize
  of 2:
    result.nativeIntId = Int16Id
    result.nativeUIntId = UInt16Id
  of 4:
    result.nativeIntId = Int32Id
    result.nativeUIntId = UInt16Id
  else:
    result.nativeIntId = Int64Id
    result.nativeUIntId = UInt16Id
  result.strPayloadId = strPayloadPtrType(result.types, result.nirm.types)

proc initProcCon*(m: ModuleCon; prc: PSym; config: ConfigRef): ProcCon =
  result = ProcCon(m: m, sm: initSlotManager({}), prc: prc, config: config,
    lit: m.nirm.lit, idgen: m.idgen,
    options: if prc != nil: prc.options
             else: config.options)
  result.exitLabel = newLabel(result.labelGen)

proc toLineInfo(c: var ProcCon; i: TLineInfo): PackedLineInfo =
  var val: LitId
  if c.lastFileKey == i.fileIndex:
    val = c.lastFileVal
  else:
    val = c.lit.strings.getOrIncl(toFullPath(c.config, i.fileIndex))
    # remember the entry:
    c.lastFileKey = i.fileIndex
    c.lastFileVal = val
  result = pack(c.m.nirm.man, val, int32 i.line, int32 i.col)

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
    gfAddrOf # load the address of the expression
    gfToOutParam # the expression is passed to an `out` parameter
  GenFlags = set[GenFlag]

proc gen(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags = {})

proc genScope(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags = {}) =
  openScope c.sm
  gen c, n, d, flags
  closeScope c.sm

proc freeTemp(c: var ProcCon; tmp: Value) =
  let s = extractTemp(tmp)
  if s != SymId(-1):
    freeTemp(c.sm, s)

proc freeTemps(c: var ProcCon; tmps: openArray[Value]) =
  for t in tmps: freeTemp(c, t)

proc typeToIr(m: ModuleCon; t: PType): TypeId =
  typeToIr(m.types, m.nirm.types, t)

proc allocTemp(c: var ProcCon; t: TypeId): SymId =
  if c.m.noModularity:
    result = allocTemp(c.sm, t, c.m.symIdCounter)
  else:
    result = allocTemp(c.sm, t, c.idgen.symId)

const
  ListSymId = -1

proc toSymId(c: var ProcCon; s: PSym): SymId =
  if c.m.noModularity:
    result = c.m.toSymId.getOrDefault(s.itemId, SymId(-1))
    if result.int < 0:
      inc c.m.symIdCounter
      result = SymId(c.m.symIdCounter)
      c.m.toSymId[s.itemId] = result
      when ListSymId != -1:
        if result.int == ListSymId or s.name.s == "echoBinSafe":
          echo result.int, " is ", s.name.s, " ", c.m.graph.config $ s.info, " ", s.flags
          writeStackTrace()
  else:
    result = SymId(s.itemId.item)

proc getTemp(c: var ProcCon; n: PNode): Value =
  let info = toLineInfo(c, n.info)
  let t = typeToIr(c.m, n.typ)
  let tmp = allocTemp(c, t)
  c.code.addSummon info, tmp, t
  result = localToValue(info, tmp)

proc getTemp(c: var ProcCon; t: TypeId; info: PackedLineInfo): Value =
  let tmp = allocTemp(c, t)
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
  assert Tree(result).len > 0, $n

proc clearDest(c: var ProcCon; n: PNode; d: var Value) {.inline.} =
  when false:
    if n.typ.isNil or n.typ.kind == tyVoid:
      let s = extractTemp(d)
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
  buildTyped c.code, info, Select, Bool8Id:
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

proc genBlock(c: var ProcCon; n: PNode; d: var Value) =
  openScope c.sm
  let info = toLineInfo(c, n.info)
  let lab1 = newLabel(c.labelGen)

  withBlock(n[0].sym, info, lab1):
    c.gen(n[1], d)

  c.code.addLabel(info, Label, lab1)
  closeScope c.sm
  c.clearDest(n, d)

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

proc genIf(c: var ProcCon; n: PNode; d: var Value) =
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
  if isEmpty(d) and not isEmptyType(n.typ): d = getTemp(c, n)
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
      c.clearDest(n, d)
      if isEmptyType(it[1].typ): # maybe noreturn call, don't touch `d`
        c.genScope(it[1])
      else:
        c.genScope(it[1], d) # then part
      if i < n.len-1:
        c.jumpTo it[1], ending
      c.patch(it, elsePos)
    else:
      c.clearDest(n, d)
      if isEmptyType(it[0].typ): # maybe noreturn call, don't touch `d`
        c.genScope(it[0])
      else:
        c.genScope(it[0], d)
  c.patch(n, ending)
  c.clearDest(n, d)

proc tempToDest(c: var ProcCon; n: PNode; d: var Value; tmp: Value) =
  if isEmpty(d):
    d = tmp
  else:
    let info = toLineInfo(c, n.info)
    build c.code, info, Asgn:
      c.code.addTyped info, typeToIr(c.m, n.typ)
      c.code.copyTree d
      c.code.copyTree tmp
    freeTemp(c, tmp)

proc genAndOr(c: var ProcCon; n: PNode; opc: JmpKind; d: var Value) =
  #   asgn d, a
  #   tjmp|fjmp lab1
  #   asgn d, b
  # lab1:
  var tmp = getTemp(c, n)
  c.gen(n[1], tmp)
  let lab1 = c.xjmp(n, opc, tmp)
  c.gen(n[2], tmp)
  c.patch(n, lab1)
  tempToDest c, n, d, tmp

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

proc addUseCodegenProc(c: var ProcCon; dest: var Tree; name: string; info: PackedLineInfo) =
  let cp = getCompilerProc(c.m.graph, name)
  let theProc = c.genx newSymNode(cp)
  copyTree c.code, theProc

template buildCond(useNegation: bool; cond: typed; body: untyped) =
  let lab = newLabel(c.labelGen)
  buildTyped c.code, info, Select, Bool8Id:
    c.code.copyTree cond
    build c.code, info, SelectPair:
      build c.code, info, SelectValue:
        c.code.boolVal(info, useNegation)
      c.code.gotoLabel info, Goto, lab

  body
  c.code.addLabel info, Label, lab

template buildIf(cond: typed; body: untyped) =
  buildCond false, cond, body

template buildIfNot(cond: typed; body: untyped) =
  buildCond true, cond, body

template buildIfThenElse(cond: typed; then, otherwise: untyped) =
  let lelse = newLabel(c.labelGen)
  let lend = newLabel(c.labelGen)
  buildTyped c.code, info, Select, Bool8Id:
    c.code.copyTree cond
    build c.code, info, SelectPair:
      build c.code, info, SelectValue:
        c.code.boolVal(info, false)
      c.code.gotoLabel info, Goto, lelse

  then()
  c.code.gotoLabel info, Goto, lend
  c.code.addLabel info, Label, lelse
  otherwise()
  c.code.addLabel info, Label, lend

include stringcases

proc genCase(c: var ProcCon; n: PNode; d: var Value) =
  if not isEmptyType(n.typ):
    if isEmpty(d): d = getTemp(c, n)
  else:
    unused(c, n, d)

  if n[0].typ.skipTypes(abstractInst).kind == tyString:
    genStringCase(c, n, d)
    return

  var sections = newSeqOfCap[LabelId](n.len-1)
  let ending = newLabel(c.labelGen)
  let info = toLineInfo(c, n.info)
  withTemp(tmp, n[0]):
    build c.code, info, Select:
      c.code.addTyped info, typeToIr(c.m, n[0].typ)
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

proc canRaiseDisp(c: ProcCon; n: PNode): bool =
  # we assume things like sysFatal cannot raise themselves
  if n.kind == nkSym and {sfNeverRaises, sfImportc, sfCompilerProc} * n.sym.flags != {}:
    result = false
  elif optPanics in c.config.globalOptions or
      (n.kind == nkSym and sfSystemModule in getModule(n.sym).flags and
       sfSystemRaisesDefect notin n.sym.flags):
    # we know we can be strict:
    result = canRaise(n)
  else:
    # we have to be *very* conservative:
    result = canRaiseConservative(n)

proc genCall(c: var ProcCon; n: PNode; d: var Value) =
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

  let tb = typeToIr(c.m, n.typ)
  if not isEmptyType(n.typ):
    if isEmpty(d): d = getTemp(c, n)
    # XXX Handle problematic aliasing here: `a = f_canRaise(a)`.
    build c.code, info, Asgn:
      c.code.addTyped info, tb
      c.code.copyTree d
      rawCall c, info, opc, tb, args
  else:
    rawCall c, info, opc, tb, args
  freeTemps c, args

proc genRaise(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)
  let tb = typeToIr(c.m, n[0].typ)

  let d = genx(c, n[0])
  build c.code, info, SetExc:
    c.code.addTyped info, tb
    c.code.copyTree d
  c.freeTemp(d)
  c.code.addLabel info, Goto, c.exitLabel

proc genReturn(c: var ProcCon; n: PNode) =
  if n[0].kind != nkEmpty:
    gen(c, n[0])
  # XXX Block leave actions?
  let info = toLineInfo(c, n.info)
  c.code.addLabel info, Goto, c.exitLabel

proc genTry(c: var ProcCon; n: PNode; d: var Value) =
  if isEmpty(d) and not isEmptyType(n.typ): d = getTemp(c, n)
  var endings: seq[LabelId] = @[]
  let ehPos = newLabel(c.labelGen)
  let oldExitLab = c.exitLabel
  c.exitLabel = ehPos
  if isEmptyType(n[0].typ): # maybe noreturn call, don't touch `d`
    c.gen(n[0])
  else:
    c.gen(n[0], d)
  c.clearDest(n, d)

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
          c.code.addTyped itinfo, typeToIr(c.m, typ)
      if it.len == 1:
        let itinfo = toLineInfo(c, it.info)
        build c.code, itinfo, TestExc:
          c.code.addTyped itinfo, VoidId
      let body = it.lastSon
      if isEmptyType(body.typ): # maybe noreturn call, don't touch `d`
        c.gen(body)
      else:
        c.gen(body, d)
      c.clearDest(n, d)
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
    c.clearDest(n, d)
  #c.gABx(fin, opcFinallyEnd, 0, 0)

template isGlobal(s: PSym): bool = sfGlobal in s.flags and s.kind != skForVar
proc isGlobal(n: PNode): bool = n.kind == nkSym and isGlobal(n.sym)

proc genField(c: var ProcCon; n: PNode; d: var Value) =
  var pos: int
  if n.kind != nkSym or n.sym.kind != skField:
    localError(c.config, n.info, "no field symbol")
    pos = 0
  else:
    pos = n.sym.position
  d.addImmediateVal toLineInfo(c, n.info), pos

proc genIndex(c: var ProcCon; n: PNode; arr: PType; d: var Value) =
  let info = toLineInfo(c, n.info)
  if arr.skipTypes(abstractInst).kind == tyArray and
      (let offset = firstOrd(c.config, arr); offset != Zero):
    let x = c.genx(n)
    buildTyped d, info, Sub, c.m.nativeIntId:
      copyTree d.Tree, x
      d.addImmediateVal toLineInfo(c, n.info), toInt(offset)
  else:
    c.gen(n, d)
  if optBoundsCheck in c.options:
    let idx = move d
    build d, info, CheckedIndex:
      copyTree d.Tree, idx
      let x = toInt64 lengthOrd(c.config, arr)
      d.addIntVal c.lit.numbers, info, c.m.nativeIntId, x
      d.Tree.addLabel info, CheckedGoto, c.exitLabel

proc rawGenNew(c: var ProcCon; d: Value; refType: PType; ninfo: TLineInfo; needsInit: bool) =
  assert refType.kind == tyRef
  let baseType = refType.lastSon

  let info = toLineInfo(c, ninfo)
  let codegenProc = magicsys.getCompilerProc(c.m.graph,
    if needsInit: "nimNewObj" else: "nimNewObjUninit")
  let refTypeIr = typeToIr(c.m, refType)
  buildTyped c.code, info, Asgn, refTypeIr:
    copyTree c.code, d
    buildTyped c.code, info, Cast, refTypeIr:
      buildTyped c.code, info, Call, VoidPtrId:
        let theProc = c.genx newSymNode(codegenProc, ninfo)
        copyTree c.code, theProc
        c.code.addImmediateVal info, int(getSize(c.config, baseType))
        c.code.addImmediateVal info, int(getAlign(c.config, baseType))

proc genNew(c: var ProcCon; n: PNode; needsInit: bool) =
  # If in doubt, always follow the blueprint of the C code generator for `mm:orc`.
  let refType = n[1].typ.skipTypes(abstractInstOwned)
  let d = genx(c, n[1])
  rawGenNew c, d, refType, n.info, needsInit
  freeTemp c, d

proc genNewSeqOfCap(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let seqtype = skipTypes(n.typ, abstractVarRange)
  let baseType = seqtype.lastSon
  var a = c.genx(n[1])
  if isEmpty(d): d = getTemp(c, n)
  # $1.len = 0
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    buildTyped c.code, info, FieldAt, typeToIr(c.m, seqtype):
      copyTree c.code, d
      c.code.addImmediateVal info, 0
    c.code.addImmediateVal info, 0
  # $1.p = ($4*) #newSeqPayloadUninit($2, sizeof($3), NIM_ALIGNOF($3))
  let payloadPtr = seqPayloadPtrType(c.m.types, c.m.nirm.types, seqtype)[0]
  buildTyped c.code, info, Asgn, payloadPtr:
    # $1.p
    buildTyped c.code, info, FieldAt, typeToIr(c.m, seqtype):
      copyTree c.code, d
      c.code.addImmediateVal info, 1
    # ($4*) #newSeqPayloadUninit($2, sizeof($3), NIM_ALIGNOF($3))
    buildTyped c.code, info, Cast, payloadPtr:
      buildTyped c.code, info, Call, VoidPtrId:
        let codegenProc = magicsys.getCompilerProc(c.m.graph, "newSeqPayloadUninit")
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        copyTree c.code, a
        c.code.addImmediateVal info, int(getSize(c.config, baseType))
        c.code.addImmediateVal info, int(getAlign(c.config, baseType))
  freeTemp c, a

proc genNewSeqPayload(c: var ProcCon; info: PackedLineInfo; d, b: Value; seqtype: PType) =
  let baseType = seqtype.lastSon
  # $1.p = ($4*) #newSeqPayload($2, sizeof($3), NIM_ALIGNOF($3))
  let payloadPtr = seqPayloadPtrType(c.m.types, c.m.nirm.types, seqtype)[0]

  # $1.len = $2
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    buildTyped c.code, info, FieldAt, typeToIr(c.m, seqtype):
      copyTree c.code, d
      c.code.addImmediateVal info, 0
    copyTree c.code, b

  buildTyped c.code, info, Asgn, payloadPtr:
    # $1.p
    buildTyped c.code, info, FieldAt, typeToIr(c.m, seqtype):
      copyTree c.code, d
      c.code.addImmediateVal info, 1
    # ($4*) #newSeqPayload($2, sizeof($3), NIM_ALIGNOF($3))
    buildTyped c.code, info, Cast, payloadPtr:
      buildTyped c.code, info, Call, VoidPtrId:
        let codegenProc = magicsys.getCompilerProc(c.m.graph, "newSeqPayload")
        let theProc = c.genx newSymNode(codegenProc)
        copyTree c.code, theProc
        copyTree c.code, b
        c.code.addImmediateVal info, int(getSize(c.config, baseType))
        c.code.addImmediateVal info, int(getAlign(c.config, baseType))

proc genNewSeq(c: var ProcCon; n: PNode) =
  let info = toLineInfo(c, n.info)
  let seqtype = skipTypes(n[1].typ, abstractVarRange)
  var d = c.genx(n[1])
  var b = c.genx(n[2])

  genNewSeqPayload(c, info, d, b, seqtype)

  freeTemp c, b
  freeTemp c, d

template intoDest*(d: var Value; info: PackedLineInfo; typ: TypeId; body: untyped) =
  if typ == VoidId:
    body(c.code)
  elif isEmpty(d):
    body(Tree(d))
  else:
    buildTyped c.code, info, Asgn, typ:
      copyTree c.code, d
      body(c.code)

template valueIntoDest(c: var ProcCon; info: PackedLineInfo; d: var Value; typ: PType; body: untyped) =
  if isEmpty(d):
    body(Tree d)
  else:
    buildTyped c.code, info, Asgn, typeToIr(c.m, typ):
      copyTree c.code, d
      body(c.code)

template constrIntoDest(c: var ProcCon; info: PackedLineInfo; d: var Value; typ: PType; body: untyped) =
  var tmp = default(Value)
  body(Tree tmp)
  if isEmpty(d):
    d = tmp
  else:
    buildTyped c.code, info, Asgn, typeToIr(c.m, typ):
      copyTree c.code, d
      copyTree c.code, tmp

proc genBinaryOp(c: var ProcCon; n: PNode; d: var Value; opc: Opcode) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[1])
  let tmp2 = c.genx(n[2])
  let t = typeToIr(c.m, n.typ)
  template body(target) =
    buildTyped target, info, opc, t:
      if optOverflowCheck in c.options and opc in {CheckedAdd, CheckedSub, CheckedMul, CheckedDiv, CheckedMod}:
        target.addLabel info, CheckedGoto, c.exitLabel
      copyTree target, tmp
      copyTree target, tmp2
  intoDest d, info, t, body
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genCmpOp(c: var ProcCon; n: PNode; d: var Value; opc: Opcode) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[1])
  let tmp2 = c.genx(n[2])
  let t = typeToIr(c.m, n[1].typ)
  template body(target) =
    buildTyped target, info, opc, t:
      copyTree target, tmp
      copyTree target, tmp2
  intoDest d, info, Bool8Id, body
  c.freeTemp(tmp)
  c.freeTemp(tmp2)

proc genUnaryOp(c: var ProcCon; n: PNode; d: var Value; opc: Opcode) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[1])
  let t = typeToIr(c.m, n.typ)
  template body(target) =
    buildTyped target, info, opc, t:
      copyTree target, tmp
  intoDest d, info, t, body
  c.freeTemp(tmp)

proc genIncDec(c: var ProcCon; n: PNode; opc: Opcode) =
  let info = toLineInfo(c, n.info)
  let t = typeToIr(c.m, skipTypes(n[1].typ, abstractVar))

  let d = c.genx(n[1])
  let tmp = c.genx(n[2])
  # we produce code like:  i = i + 1
  buildTyped c.code, info, Asgn, t:
    copyTree c.code, d
    buildTyped c.code, info, opc, t:
      copyTree c.code, d
      copyTree c.code, tmp
  c.freeTemp(tmp)
  #c.genNarrow(n[1], d)
  c.freeTemp(d)

proc genArrayLen(c: var ProcCon; n: PNode; d: var Value) =
  #echo c.m.graph.config $ n.info, " ", n
  let info = toLineInfo(c, n.info)
  var a = n[1]
  #if a.kind == nkHiddenAddr: a = a[0]
  var typ = skipTypes(a.typ, abstractVar + tyUserTypeClasses)
  case typ.kind
  of tyOpenArray, tyVarargs:
    let xa = c.genx(a)
    template body(target) =
      buildTyped target, info, FieldAt, typeToIr(c.m, typ):
        copyTree target, xa
        target.addImmediateVal info, 1 # (p, len)-pair so len is at index 1
    intoDest d, info, c.m.nativeIntId, body

  of tyCstring:
    let xa = c.genx(a)
    if isEmpty(d): d = getTemp(c, n)
    buildTyped c.code, info, Call, c.m.nativeIntId:
      let codegenProc = magicsys.getCompilerProc(c.m.graph, "nimCStrLen")
      assert codegenProc != nil
      let theProc = c.genx newSymNode(codegenProc, n.info)
      copyTree c.code, theProc
      copyTree c.code, xa

  of tyString, tySequence:
    let xa = c.genx(a)

    if typ.kind == tySequence:
      # we go through a temporary here because people write bullshit code.
      if isEmpty(d): d = getTemp(c, n)

    template body(target) =
      buildTyped target, info, FieldAt, typeToIr(c.m, typ):
        copyTree target, xa
        target.addImmediateVal info, 0 # (len, p)-pair so len is at index 0
    intoDest d, info, c.m.nativeIntId, body

  of tyArray:
    template body(target) =
      target.addIntVal(c.lit.numbers, info, c.m.nativeIntId, toInt lengthOrd(c.config, typ))
    intoDest d, info, c.m.nativeIntId, body
  else: internalError(c.config, n.info, "genArrayLen()")

proc genUnaryMinus(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[1])
  let t = typeToIr(c.m, n.typ)
  template body(target) =
    buildTyped target, info, Sub, t:
      # Little hack: This works because we know that `0.0` is all 0 bits:
      target.addIntVal(c.lit.numbers, info, t, 0)
      copyTree target, tmp
  intoDest d, info, t, body
  c.freeTemp(tmp)

proc genHigh(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let t = typeToIr(c.m, n.typ)
  var x = default(Value)
  genArrayLen(c, n, x)
  template body(target) =
    buildTyped target, info, Sub, t:
      copyTree target, x
      target.addIntVal(c.lit.numbers, info, t, 1)
  intoDest d, info, t, body
  c.freeTemp x

proc genBinaryCp(c: var ProcCon; n: PNode; d: var Value; compilerProc: string) =
  let info = toLineInfo(c, n.info)
  let xa = c.genx(n[1])
  let xb = c.genx(n[2])
  if isEmpty(d) and not isEmptyType(n.typ): d = getTemp(c, n)

  let t = typeToIr(c.m, n.typ)
  template body(target) =
    buildTyped target, info, Call, t:
      let codegenProc = magicsys.getCompilerProc(c.m.graph, compilerProc)
      #assert codegenProc != nil, $n & " " & (c.m.graph.config $ n.info)
      let theProc = c.genx newSymNode(codegenProc, n.info)
      copyTree target, theProc
      copyTree target, xa
      copyTree target, xb

  intoDest d, info, t, body
  c.freeTemp xb
  c.freeTemp xa

proc genUnaryCp(c: var ProcCon; n: PNode; d: var Value; compilerProc: string; argAt = 1) =
  let info = toLineInfo(c, n.info)
  let xa = c.genx(n[argAt])
  if isEmpty(d) and not isEmptyType(n.typ): d = getTemp(c, n)

  let t = typeToIr(c.m, n.typ)
  template body(target) =
    buildTyped target, info, Call, t:
      let codegenProc = magicsys.getCompilerProc(c.m.graph, compilerProc)
      let theProc = c.genx newSymNode(codegenProc, n.info)
      copyTree target, theProc
      copyTree target, xa

  intoDest d, info, t, body
  c.freeTemp xa

proc genEnumToStr(c: var ProcCon; n: PNode; d: var Value) =
  let t = n[1].typ.skipTypes(abstractInst+{tyRange})
  let toStrProc = getToStringProc(c.m.graph, t)
  # XXX need to modify this logic for IC.
  var nb = copyTree(n)
  nb[0] = newSymNode(toStrProc)
  gen(c, nb, d)

proc genOf(c: var ProcCon; n: PNode; d: var Value) =
  genUnaryOp c, n, d, TestOf

template sizeOfLikeMsg(name): string =
  "'" & name & "' requires '.importc' types to be '.completeStruct'"

proc genIsNil(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[1])
  let t = typeToIr(c.m, n[1].typ)
  template body(target) =
    buildTyped target, info, Eq, t:
      copyTree target, tmp
      addNilVal target, info, t
  intoDest d, info, Bool8Id, body
  c.freeTemp(tmp)

proc fewCmps(conf: ConfigRef; s: PNode): bool =
  # this function estimates whether it is better to emit code
  # for constructing the set or generating a bunch of comparisons directly
  if s.kind != nkCurly:
    result = false
  elif (getSize(conf, s.typ) <= conf.target.intSize) and (nfAllConst in s.flags):
    result = false            # it is better to emit the set generation code
  elif elemType(s.typ).kind in {tyInt, tyInt16..tyInt64}:
    result = true             # better not emit the set if int is basetype!
  else:
    result = s.len <= 8  # 8 seems to be a good value

proc genInBitset(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let b = c.genx(n[2])

  let t = bitsetBasetype(c.m.types, c.m.nirm.types, n[1].typ)
  let setType = typeToIr(c.m, n[1].typ)
  let mask =
    case t
    of UInt8Id: 7
    of UInt16Id: 15
    of UInt32Id: 31
    else: 63
  let expansion = if t == UInt64Id: UInt64Id else: c.m.nativeUIntId
    # "(($1              &(1U<<((NU)($2)&7U)))!=0)"  - or -
    # "(($1[(NU)($2)>>3] &(1U<<((NU)($2)&7U)))!=0)"

  template body(target) =
    buildTyped target, info, BoolNot, Bool8Id:
      buildTyped target, info, Eq, t:
        buildTyped target, info, BitAnd, t:
          if c.m.nirm.types[setType].kind != ArrayTy:
            copyTree target, a
          else:
            buildTyped target, info, ArrayAt, setType:
              copyTree target, a
              buildTyped target, info, BitShr, t:
                buildTyped target, info, Cast, expansion:
                  copyTree target, b
                addIntVal target, c.lit.numbers, info, expansion, 3

          buildTyped target, info, BitShl, t:
            addIntVal target, c.lit.numbers, info, t, 1
            buildTyped target, info, BitAnd, t:
              buildTyped target, info, Cast, expansion:
                copyTree target, b
              addIntVal target, c.lit.numbers, info, expansion, mask
        addIntVal target, c.lit.numbers, info, t, 0
  intoDest d, info, t, body

  c.freeTemp(b)
  c.freeTemp(a)

proc genInSet(c: var ProcCon; n: PNode; d: var Value) =
  let g {.cursor.} = c.m.graph
  if n[1].kind == nkCurly and fewCmps(g.config, n[1]):
    # a set constructor but not a constant set:
    # do not emit the set, but generate a bunch of comparisons; and if we do
    # so, we skip the unnecessary range check: This is a semantical extension
    # that code now relies on. :-/ XXX
    let elem = if n[2].kind in {nkChckRange, nkChckRange64}: n[2][0]
               else: n[2]
    let curly = n[1]
    var ex: PNode = nil
    for it in curly:
      var test: PNode
      if it.kind == nkRange:
        test = newTree(nkCall, g.operators.opAnd.newSymNode,
          newTree(nkCall, g.operators.opLe.newSymNode, it[0], elem), # a <= elem
          newTree(nkCall, g.operators.opLe.newSymNode, elem, it[1])
        )
      else:
        test = newTree(nkCall, g.operators.opEq.newSymNode, elem, it)
      test.typ = getSysType(g, it.info, tyBool)

      if ex == nil: ex = test
      else: ex = newTree(nkCall, g.operators.opOr.newSymNode, ex, test)

    if ex == nil:
      let info = toLineInfo(c, n.info)
      template body(target) =
        boolVal target, info, false
      intoDest d, info, Bool8Id, body
    else:
      gen c, ex, d
  else:
    genInBitset c, n, d

proc genCard(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let t = typeToIr(c.m, n.typ)

  let setType = typeToIr(c.m, n[1].typ)
  if isEmpty(d): d = getTemp(c, n)

  buildTyped c.code, info, Asgn, t:
    copyTree c.code, d
    buildTyped c.code, info, Call, t:
      if c.m.nirm.types[setType].kind == ArrayTy:
        let codegenProc = magicsys.getCompilerProc(c.m.graph, "cardSet")
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        buildTyped c.code, info, AddrOf, ptrTypeOf(c.m.nirm.types, setType):
          copyTree c.code, a
        c.code.addImmediateVal info, int(getSize(c.config, n[1].typ))
      elif t == UInt64Id:
        let codegenProc = magicsys.getCompilerProc(c.m.graph, "countBits64")
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        copyTree c.code, a
      else:
        let codegenProc = magicsys.getCompilerProc(c.m.graph, "countBits32")
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        buildTyped c.code, info, Cast, UInt32Id:
          copyTree c.code, a
  freeTemp c, a

proc genEqSet(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let b = c.genx(n[2])
  let t = typeToIr(c.m, n.typ)

  let setType = typeToIr(c.m, n[1].typ)

  if c.m.nirm.types[setType].kind == ArrayTy:
    if isEmpty(d): d = getTemp(c, n)

    buildTyped c.code, info, Asgn, t:
      copyTree c.code, d
      buildTyped c.code, info, Eq, t:
        buildTyped c.code, info, Call, t:
          let codegenProc = magicsys.getCompilerProc(c.m.graph, "nimCmpMem")
          let theProc = c.genx newSymNode(codegenProc, n.info)
          copyTree c.code, theProc
          buildTyped c.code, info, AddrOf, ptrTypeOf(c.m.nirm.types, setType):
            copyTree c.code, a
          buildTyped c.code, info, AddrOf, ptrTypeOf(c.m.nirm.types, setType):
            copyTree c.code, b
          c.code.addImmediateVal info, int(getSize(c.config, n[1].typ))
        c.code.addIntVal c.lit.numbers, info, c.m.nativeIntId, 0

  else:
    template body(target) =
      buildTyped target, info, Eq, setType:
        copyTree target, a
        copyTree target, b
    intoDest d, info, Bool8Id, body

  freeTemp c, b
  freeTemp c, a

proc beginCountLoop(c: var ProcCon; info: PackedLineInfo; first, last: int): (SymId, LabelId, LabelId) =
  let tmp = allocTemp(c, c.m.nativeIntId)
  c.code.addSummon info, tmp, c.m.nativeIntId
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    c.code.addSymUse info, tmp
    c.code.addIntVal c.lit.numbers, info, c.m.nativeIntId, first
  let lab1 = c.code.addNewLabel(c.labelGen, info, LoopLabel)
  result = (tmp, lab1, newLabel(c.labelGen))

  buildTyped c.code, info, Select, Bool8Id:
    buildTyped c.code, info, Lt, c.m.nativeIntId:
      c.code.addSymUse info, tmp
      c.code.addIntVal c.lit.numbers, info, c.m.nativeIntId, last
    build c.code, info, SelectPair:
      build c.code, info, SelectValue:
        c.code.boolVal(info, false)
      c.code.gotoLabel info, Goto, result[2]

proc beginCountLoop(c: var ProcCon; info: PackedLineInfo; first, last: Value): (SymId, LabelId, LabelId) =
  let tmp = allocTemp(c, c.m.nativeIntId)
  c.code.addSummon info, tmp, c.m.nativeIntId
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    c.code.addSymUse info, tmp
    copyTree c.code, first
  let lab1 = c.code.addNewLabel(c.labelGen, info, LoopLabel)
  result = (tmp, lab1, newLabel(c.labelGen))

  buildTyped c.code, info, Select, Bool8Id:
    buildTyped c.code, info, Le, c.m.nativeIntId:
      c.code.addSymUse info, tmp
      copyTree c.code, last
    build c.code, info, SelectPair:
      build c.code, info, SelectValue:
        c.code.boolVal(info, false)
      c.code.gotoLabel info, Goto, result[2]

proc endLoop(c: var ProcCon; info: PackedLineInfo; s: SymId; back, exit: LabelId) =
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    c.code.addSymUse info, s
    buildTyped c.code, info, Add, c.m.nativeIntId:
      c.code.addSymUse info, s
      c.code.addIntVal c.lit.numbers, info, c.m.nativeIntId, 1
  c.code.addLabel info, GotoLoop, back
  c.code.addLabel info, Label, exit
  freeTemp(c.sm, s)

proc genLeSet(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let b = c.genx(n[2])
  let t = typeToIr(c.m, n.typ)

  let setType = typeToIr(c.m, n[1].typ)

  if c.m.nirm.types[setType].kind == ArrayTy:
    let elemType = bitsetBasetype(c.m.types, c.m.nirm.types, n[1].typ)
    if isEmpty(d): d = getTemp(c, n)
    #    "for ($1 = 0; $1 < $2; $1++):"
    #    "  $3 = (($4[$1] & ~ $5[$1]) == 0)"
    #    "  if (!$3) break;"
    let (idx, backLabel, endLabel) = beginCountLoop(c, info, 0, int(getSize(c.config, n[1].typ)))
    buildTyped c.code, info, Asgn, Bool8Id:
      copyTree c.code, d
      buildTyped c.code, info, Eq, elemType:
        buildTyped c.code, info, BitAnd, elemType:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, a
            c.code.addSymUse info, idx
          buildTyped c.code, info, BitNot, elemType:
            buildTyped c.code, info, ArrayAt, setType:
              copyTree c.code, b
              c.code.addSymUse info, idx
        c.code.addIntVal c.lit.numbers, info, elemType, 0

    # if !$3: break
    buildTyped c.code, info, Select, Bool8Id:
      c.code.copyTree d
      build c.code, info, SelectPair:
        build c.code, info, SelectValue:
          c.code.boolVal(info, false)
        c.code.gotoLabel info, Goto, endLabel

    endLoop(c, info, idx, backLabel, endLabel)
  else:
    # "(($1 & ~ $2)==0)"
    template body(target) =
      buildTyped target, info, Eq, setType:
        buildTyped target, info, BitAnd, setType:
          copyTree target, a
          buildTyped target, info, BitNot, setType:
            copyTree target, b
        target.addIntVal c.lit.numbers, info, setType, 0

    intoDest d, info, Bool8Id, body

  freeTemp c, b
  freeTemp c, a

proc genLtSet(c: var ProcCon; n: PNode; d: var Value) =
  localError(c.m.graph.config, n.info, "`<` for sets not implemented")

proc genBinarySet(c: var ProcCon; n: PNode; d: var Value; m: TMagic) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let b = c.genx(n[2])
  let t = typeToIr(c.m, n.typ)

  let setType = typeToIr(c.m, n[1].typ)

  if c.m.nirm.types[setType].kind == ArrayTy:
    let elemType = bitsetBasetype(c.m.types, c.m.nirm.types, n[1].typ)
    if isEmpty(d): d = getTemp(c, n)
    #    "for ($1 = 0; $1 < $2; $1++):"
    #    "  $3 = (($4[$1] & ~ $5[$1]) == 0)"
    #    "  if (!$3) break;"
    let (idx, backLabel, endLabel) = beginCountLoop(c, info, 0, int(getSize(c.config, n[1].typ)))
    buildTyped c.code, info, Asgn, elemType:
      buildTyped c.code, info, ArrayAt, setType:
        copyTree c.code, d
        c.code.addSymUse info, idx
      buildTyped c.code, info, (if m == mPlusSet: BitOr else: BitAnd), elemType:
        buildTyped c.code, info, ArrayAt, setType:
          copyTree c.code, a
          c.code.addSymUse info, idx
        if m == mMinusSet:
          buildTyped c.code, info, BitNot, elemType:
            buildTyped c.code, info, ArrayAt, setType:
              copyTree c.code, b
              c.code.addSymUse info, idx
        else:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, b
            c.code.addSymUse info, idx

    endLoop(c, info, idx, backLabel, endLabel)
  else:
    # "(($1 & ~ $2)==0)"
    template body(target) =
      buildTyped target, info, (if m == mPlusSet: BitOr else: BitAnd), setType:
        copyTree target, a
        if m == mMinusSet:
          buildTyped target, info, BitNot, setType:
            copyTree target, b
        else:
          copyTree target, b

    intoDest d, info, setType, body

  freeTemp c, b
  freeTemp c, a

proc genInclExcl(c: var ProcCon; n: PNode; m: TMagic) =
  let info = toLineInfo(c, n.info)
  let a = c.genx(n[1])
  let b = c.genx(n[2])

  let setType = typeToIr(c.m, n[1].typ)

  let t = bitsetBasetype(c.m.types, c.m.nirm.types, n[1].typ)
  let mask =
    case t
    of UInt8Id: 7
    of UInt16Id: 15
    of UInt32Id: 31
    else: 63

  buildTyped c.code, info, Asgn, setType:
    if c.m.nirm.types[setType].kind == ArrayTy:
      if m == mIncl:
        # $1[(NU)($2)>>3] |=(1U<<($2&7U))
        buildTyped c.code, info, ArrayAt, setType:
          copyTree c.code, a
          buildTyped c.code, info, BitShr, t:
            buildTyped c.code, info, Cast, c.m.nativeUIntId:
              copyTree c.code, b
            addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
        buildTyped c.code, info, BitOr, t:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, a
            buildTyped c.code, info, BitShr, t:
              buildTyped c.code, info, Cast, c.m.nativeUIntId:
                copyTree c.code, b
              addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
          buildTyped c.code, info, BitShl, t:
            c.code.addIntVal c.lit.numbers, info, t, 1
            buildTyped c.code, info, BitAnd, t:
              copyTree c.code, b
              c.code.addIntVal c.lit.numbers, info, t, 7
      else:
        # $1[(NU)($2)>>3] &= ~(1U<<($2&7U))
        buildTyped c.code, info, ArrayAt, setType:
          copyTree c.code, a
          buildTyped c.code, info, BitShr, t:
            buildTyped c.code, info, Cast, c.m.nativeUIntId:
              copyTree c.code, b
            addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
        buildTyped c.code, info, BitAnd, t:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, a
            buildTyped c.code, info, BitShr, t:
              buildTyped c.code, info, Cast, c.m.nativeUIntId:
                copyTree c.code, b
              addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
          buildTyped c.code, info, BitNot, t:
            buildTyped c.code, info, BitShl, t:
              c.code.addIntVal c.lit.numbers, info, t, 1
              buildTyped c.code, info, BitAnd, t:
                copyTree c.code, b
                c.code.addIntVal c.lit.numbers, info, t, 7

    else:
      copyTree c.code, a
      if m == mIncl:
        # $1 |= ((NU8)1)<<(($2) & 7)
        buildTyped c.code, info, BitOr, setType:
          copyTree c.code, a
          buildTyped c.code, info, BitShl, t:
            c.code.addIntVal c.lit.numbers, info, t, 1
            buildTyped c.code, info, BitAnd, t:
              copyTree c.code, b
              c.code.addIntVal c.lit.numbers, info, t, mask
      else:
        # $1 &= ~(((NU8)1) << (($2) & 7))
        buildTyped c.code, info, BitAnd, setType:
          copyTree c.code, a
          buildTyped c.code, info, BitNot, t:
            buildTyped c.code, info, BitShl, t:
              c.code.addIntVal c.lit.numbers, info, t, 1
              buildTyped c.code, info, BitAnd, t:
                copyTree c.code, b
                c.code.addIntVal c.lit.numbers, info, t, mask
  freeTemp c, b
  freeTemp c, a

proc genSetConstrDyn(c: var ProcCon; n: PNode; d: var Value) =
  # example: { a..b, c, d, e, f..g }
  # we have to emit an expression of the form:
  # nimZeroMem(tmp, sizeof(tmp)); inclRange(tmp, a, b); incl(tmp, c);
  # incl(tmp, d); incl(tmp, e); inclRange(tmp, f, g);
  let info = toLineInfo(c, n.info)
  let setType = typeToIr(c.m, n.typ)
  let size = int(getSize(c.config, n.typ))
  let t = bitsetBasetype(c.m.types, c.m.nirm.types, n.typ)
  let mask =
    case t
    of UInt8Id: 7
    of UInt16Id: 15
    of UInt32Id: 31
    else: 63

  if isEmpty(d): d = getTemp(c, n)
  if c.m.nirm.types[setType].kind != ArrayTy:
    buildTyped c.code, info, Asgn, setType:
      copyTree c.code, d
      c.code.addIntVal c.lit.numbers, info, t, 0

    for it in n:
      if it.kind == nkRange:
        let a = genx(c, it[0])
        let b = genx(c, it[1])
        let (idx, backLabel, endLabel) = beginCountLoop(c, info, a, b)
        buildTyped c.code, info, Asgn, setType:
          copyTree c.code, d
          buildTyped c.code, info, BitAnd, setType:
            copyTree c.code, d
            buildTyped c.code, info, BitNot, t:
              buildTyped c.code, info, BitShl, t:
                c.code.addIntVal c.lit.numbers, info, t, 1
                buildTyped c.code, info, BitAnd, t:
                  c.code.addSymUse info, idx
                  c.code.addIntVal c.lit.numbers, info, t, mask

        endLoop(c, info, idx, backLabel, endLabel)
        freeTemp c, b
        freeTemp c, a

      else:
        let a = genx(c, it)
        buildTyped c.code, info, Asgn, setType:
          copyTree c.code, d
          buildTyped c.code, info, BitAnd, setType:
            copyTree c.code, d
            buildTyped c.code, info, BitNot, t:
              buildTyped c.code, info, BitShl, t:
                c.code.addIntVal c.lit.numbers, info, t, 1
                buildTyped c.code, info, BitAnd, t:
                  copyTree c.code, a
                  c.code.addIntVal c.lit.numbers, info, t, mask
        freeTemp c, a

  else:
    # init loop:
    let (idx, backLabel, endLabel) = beginCountLoop(c, info, 0, size)
    buildTyped c.code, info, Asgn, t:
      copyTree c.code, d
      c.code.addIntVal c.lit.numbers, info, t, 0
    endLoop(c, info, idx, backLabel, endLabel)

    # incl elements:
    for it in n:
      if it.kind == nkRange:
        let a = genx(c, it[0])
        let b = genx(c, it[1])
        let (idx, backLabel, endLabel) = beginCountLoop(c, info, a, b)

        buildTyped c.code, info, Asgn, t:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, d
            buildTyped c.code, info, BitShr, t:
              buildTyped c.code, info, Cast, c.m.nativeUIntId:
                c.code.addSymUse info, idx
              addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
          buildTyped c.code, info, BitOr, t:
            buildTyped c.code, info, ArrayAt, setType:
              copyTree c.code, d
              buildTyped c.code, info, BitShr, t:
                buildTyped c.code, info, Cast, c.m.nativeUIntId:
                  c.code.addSymUse info, idx
                addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
            buildTyped c.code, info, BitShl, t:
              c.code.addIntVal c.lit.numbers, info, t, 1
              buildTyped c.code, info, BitAnd, t:
                c.code.addSymUse info, idx
                c.code.addIntVal c.lit.numbers, info, t, 7

        endLoop(c, info, idx, backLabel, endLabel)
        freeTemp c, b
        freeTemp c, a

      else:
        let a = genx(c, it)
        # $1[(NU)($2)>>3] |=(1U<<($2&7U))
        buildTyped c.code, info, Asgn, t:
          buildTyped c.code, info, ArrayAt, setType:
            copyTree c.code, d
            buildTyped c.code, info, BitShr, t:
              buildTyped c.code, info, Cast, c.m.nativeUIntId:
                copyTree c.code, a
              addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
          buildTyped c.code, info, BitOr, t:
            buildTyped c.code, info, ArrayAt, setType:
              copyTree c.code, d
              buildTyped c.code, info, BitShr, t:
                buildTyped c.code, info, Cast, c.m.nativeUIntId:
                  copyTree c.code, a
                addIntVal c.code, c.lit.numbers, info, c.m.nativeUIntId, 3
            buildTyped c.code, info, BitShl, t:
              c.code.addIntVal c.lit.numbers, info, t, 1
              buildTyped c.code, info, BitAnd, t:
                copyTree c.code, a
                c.code.addIntVal c.lit.numbers, info, t, 7
        freeTemp c, a

proc genSetConstr(c: var ProcCon; n: PNode; d: var Value) =
  if isDeepConstExpr(n):
    let info = toLineInfo(c, n.info)
    let setType = typeToIr(c.m, n.typ)
    let size = int(getSize(c.config, n.typ))
    let cs = toBitSet(c.config, n)

    if c.m.nirm.types[setType].kind != ArrayTy:
      template body(target) =
        target.addIntVal c.lit.numbers, info, setType, cast[BiggestInt](bitSetToWord(cs, size))
      intoDest d, info, setType, body
    else:
      let t = bitsetBasetype(c.m.types, c.m.nirm.types, n.typ)
      template body(target) =
        buildTyped target, info, ArrayConstr, setType:
          for i in 0..high(cs):
            target.addIntVal c.lit.numbers, info, t, int64 cs[i]
      intoDest d, info, setType, body
  else:
    genSetConstrDyn c, n, d

proc genStrConcat(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  #   <Nim code>
  #   s = "Hello " & name & ", how do you feel?" & 'z'
  #
  #   <generated code>
  #  {
  #    string tmp0;
  #    ...
  #    tmp0 = rawNewString(6 + 17 + 1 + s2->len);
  #    // we cannot generate s = rawNewString(...) here, because
  #    // ``s`` may be used on the right side of the expression
  #    appendString(tmp0, strlit_1);
  #    appendString(tmp0, name);
  #    appendString(tmp0, strlit_2);
  #    appendChar(tmp0, 'z');
  #    asgn(s, tmp0);
  #  }
  var args: seq[Value] = @[]
  var argsRuntimeLen: seq[Value] = @[]

  var precomputedLen = 0
  for i in 1 ..< n.len:
    let it = n[i]
    args.add genx(c, it)
    if skipTypes(it.typ, abstractVarRange).kind == tyChar:
      inc precomputedLen
    elif it.kind in {nkStrLit..nkTripleStrLit}:
      inc precomputedLen, it.strVal.len
    else:
      argsRuntimeLen.add args[^1]

  # generate length computation:
  var tmpLen = allocTemp(c, c.m.nativeIntId)
  buildTyped c.code, info, Asgn, c.m.nativeIntId:
    c.code.addSymUse info, tmpLen
    c.code.addIntVal c.lit.numbers, info, c.m.nativeIntId, precomputedLen
  for a in mitems(argsRuntimeLen):
    buildTyped c.code, info, Asgn, c.m.nativeIntId:
      c.code.addSymUse info, tmpLen
      buildTyped c.code, info, CheckedAdd, c.m.nativeIntId:
        c.code.addSymUse info, tmpLen
        buildTyped c.code, info, FieldAt, typeToIr(c.m, n.typ):
          copyTree c.code, a
          c.code.addImmediateVal info, 0 # (len, p)-pair so len is at index 0

  var tmpStr = getTemp(c, n)
  #    ^ because of aliasing, we always go through a temporary
  let t = typeToIr(c.m, n.typ)
  buildTyped c.code, info, Asgn, t:
    copyTree c.code, tmpStr
    buildTyped c.code, info, Call, t:
      let codegenProc = magicsys.getCompilerProc(c.m.graph, "rawNewString")
      #assert codegenProc != nil, $n & " " & (c.m.graph.config $ n.info)
      let theProc = c.genx newSymNode(codegenProc, n.info)
      copyTree c.code, theProc
      c.code.addSymUse info, tmpLen
  freeTemp c.sm, tmpLen

  for i in 1 ..< n.len:
    let it = n[i]
    let isChar = skipTypes(it.typ, abstractVarRange).kind == tyChar
    buildTyped c.code, info, Call, VoidId:
      let codegenProc = magicsys.getCompilerProc(c.m.graph,
        (if isChar: "appendChar" else: "appendString"))
      #assert codegenProc != nil, $n & " " & (c.m.graph.config $ n.info)
      let theProc = c.genx newSymNode(codegenProc, n.info)
      copyTree c.code, theProc
      buildTyped c.code, info, AddrOf, ptrTypeOf(c.m.nirm.types, t):
        copyTree c.code, tmpStr
      copyTree c.code, args[i-1]
    freeTemp c, args[i-1]

  if isEmpty(d):
    d = tmpStr
  else:
    # XXX Test that this does not cause memory leaks!
    buildTyped c.code, info, Asgn, t:
      copyTree c.code, d
      copyTree c.code, tmpStr

proc genDefault(c: var ProcCon; n: PNode; d: var Value) =
  let m = expandDefault(n.typ, n.info)
  gen c, m, d

proc genWasMoved(c: var ProcCon; n: PNode) =
  let n1 = n[1].skipAddr
  # XXX We need a way to replicate this logic or better yet a better
  # solution for injectdestructors.nim:
  #if c.withinBlockLeaveActions > 0 and notYetAlive(n1):
  var d = c.genx(n1)
  assert not isEmpty(d)
  let m = expandDefault(n1.typ, n1.info)
  gen c, m, d

proc genMove(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  let n1 = n[1].skipAddr
  var a = c.genx(n1)
  if n.len == 4:
    # generated by liftdestructors:
    let src = c.genx(n[2])
    # if ($1.p == $2.p) goto lab1
    let lab1 = newLabel(c.labelGen)

    let n1t = typeToIr(c.m, n1.typ)
    let payloadType = seqPayloadPtrType(c.m.types, c.m.nirm.types, n1.typ)[0]
    buildTyped c.code, info, Select, Bool8Id:
      buildTyped c.code, info, Eq, payloadType:
        buildTyped c.code, info, FieldAt, n1t:
          copyTree c.code, a
          c.code.addImmediateVal info, 1 # (len, p)-pair
        buildTyped c.code, info, FieldAt, n1t:
          copyTree c.code, src
          c.code.addImmediateVal info, 1 # (len, p)-pair

      build c.code, info, SelectPair:
        build c.code, info, SelectValue:
          c.code.boolVal(info, true)
        c.code.gotoLabel info, Goto, lab1

    gen(c, n[3])
    c.patch n, lab1

    buildTyped c.code, info, Asgn, typeToIr(c.m, n1.typ):
      copyTree c.code, a
      copyTree c.code, src

  else:
    if isEmpty(d): d = getTemp(c, n)
    buildTyped c.code, info, Asgn, typeToIr(c.m, n1.typ):
      copyTree c.code, d
      copyTree c.code, a
    var op = getAttachedOp(c.m.graph, n.typ, attachedWasMoved)
    if op == nil or skipTypes(n1.typ, abstractVar+{tyStatic}).kind in {tyOpenArray, tyVarargs}:
      let m = expandDefault(n1.typ, n1.info)
      gen c, m, a
    else:
      var opB = c.genx(newSymNode(op))
      buildTyped c.code, info, Call, typeToIr(c.m, n.typ):
        copyTree c.code, opB
        buildTyped c.code, info, AddrOf, ptrTypeOf(c.m.nirm.types, typeToIr(c.m, n1.typ)):
          copyTree c.code, a

template fieldAt(x: Value; i: int; t: TypeId): Tree =
  var result = default(Tree)
  buildTyped result, info, FieldAt, t:
    copyTree result, x
    result.addImmediateVal info, i
  result

template eqNil(x: Tree; t: TypeId): Tree =
  var result = default(Tree)
  buildTyped result, info, Eq, t:
    copyTree result, x
    result.addNilVal info, t
  result

template eqZero(x: Tree): Tree =
  var result = default(Tree)
  buildTyped result, info, Eq, c.m.nativeIntId:
    copyTree result, x
    result.addIntVal c.lit.numbers, info, c.m.nativeIntId, 0
  result

template bitOp(x: Tree; opc: Opcode; y: int): Tree =
  var result = default(Tree)
  buildTyped result, info, opc, c.m.nativeIntId:
    copyTree result, x
    result.addIntVal c.lit.numbers, info, c.m.nativeIntId, y
  result

proc genDestroySeq(c: var ProcCon; n: PNode; t: PType) =
  let info = toLineInfo(c, n.info)
  let strLitFlag = 1 shl (c.m.graph.config.target.intSize * 8 - 2) # see also NIM_STRLIT_FLAG

  let x = c.genx(n[1])
  let baseType = t.lastSon

  let seqType = typeToIr(c.m, t)
  let p = fieldAt(x, 0, seqType)

  # if $1.p != nil and ($1.p.cap and NIM_STRLIT_FLAG) == 0:
  #   alignedDealloc($1.p, NIM_ALIGNOF($2))
  buildIfNot p.eqNil(seqType):
    buildIf fieldAt(Value(p), 0, seqPayloadPtrType(c.m.types, c.m.nirm.types, t)[0]).bitOp(BitAnd, 0).eqZero():
      let codegenProc = getCompilerProc(c.m.graph, "alignedDealloc")
      buildTyped c.code, info, Call, VoidId:
        let theProc = c.genx newSymNode(codegenProc, n.info)
        copyTree c.code, theProc
        copyTree c.code, p
        c.code.addImmediateVal info, int(getAlign(c.config, baseType))

  freeTemp c, x

proc genDestroy(c: var ProcCon; n: PNode) =
  let t = n[1].typ.skipTypes(abstractInst)
  case t.kind
  of tyString:
    var unused = default(Value)
    genUnaryCp(c, n, unused, "nimDestroyStrV1")
  of tySequence:
    genDestroySeq(c, n, t)
  else: discard "nothing to do"

type
  IndexFor = enum
    ForSeq, ForStr, ForOpenArray, ForArray

proc genIndexCheck(c: var ProcCon; n: PNode; a: Value; kind: IndexFor; arr: PType): Value =
  if optBoundsCheck in c.options:
    let info = toLineInfo(c, n.info)
    result = default(Value)
    let idx = genx(c, n)
    build result, info, CheckedIndex:
      copyTree result.Tree, idx
      case kind
      of ForSeq, ForStr:
        buildTyped result, info, FieldAt, typeToIr(c.m, arr):
          copyTree result.Tree, a
          result.addImmediateVal info, 0 # (len, p)-pair
      of ForOpenArray:
        buildTyped result, info, FieldAt, typeToIr(c.m, arr):
          copyTree result.Tree, a
          result.addImmediateVal info, 1 # (p, len)-pair
      of ForArray:
        let x = toInt64 lengthOrd(c.config, arr)
        result.addIntVal c.lit.numbers, info, c.m.nativeIntId, x
      result.Tree.addLabel info, CheckedGoto, c.exitLabel
    freeTemp c, idx
  else:
    result = genx(c, n)

proc addSliceFields(c: var ProcCon; target: var Tree; info: PackedLineInfo;
                    x: Value; n: PNode; arrType: PType) =
  let elemType = arrayPtrTypeOf(c.m.nirm.types, typeToIr(c.m, arrType.lastSon))
  case arrType.kind
  of tyString, tySequence:
    let checkKind = if arrType.kind == tyString: ForStr else: ForSeq
    let pay = if checkKind == ForStr: c.m.strPayloadId
              else: seqPayloadPtrType(c.m.types, c.m.nirm.types, arrType)

    let y = genIndexCheck(c, n[2], x, checkKind, arrType)
    let z = genIndexCheck(c, n[3], x, checkKind, arrType)

    buildTyped target, info, ObjConstr, typeToIr(c.m, n.typ):
      target.addImmediateVal info, 0
      buildTyped target, info, AddrOf, elemType:
        buildTyped target, info, ArrayAt, pay[1]:
          buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
            copyTree target, x
            target.addImmediateVal info, 1 # (len, p)-pair
          copyTree target, y

      # len:
      target.addImmediateVal info, 1
      buildTyped target, info, Add, c.m.nativeIntId:
        buildTyped target, info, Sub, c.m.nativeIntId:
          copyTree target, z
          copyTree target, y
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 1

    freeTemp c, z
    freeTemp c, y
  of tyArray:
    # XXX This evaluates the index check for `y` twice.
    # This check is also still insufficient for non-zero based arrays.
    let y = genIndexCheck(c, n[2], x, ForArray, arrType)
    let z = genIndexCheck(c, n[3], x, ForArray, arrType)

    buildTyped target, info, ObjConstr, typeToIr(c.m, n.typ):
      target.addImmediateVal info, 0
      buildTyped target, info, AddrOf, elemType:
        buildTyped target, info, ArrayAt, typeToIr(c.m, arrType):
          copyTree target, x
          copyTree target, y

      target.addImmediateVal info, 1
      buildTyped target, info, Add, c.m.nativeIntId:
        buildTyped target, info, Sub, c.m.nativeIntId:
          copyTree target, z
          copyTree target, y
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 1

    freeTemp c, z
    freeTemp c, y
  of tyOpenArray:
    # XXX This evaluates the index check for `y` twice.
    let y = genIndexCheck(c, n[2], x, ForOpenArray, arrType)
    let z = genIndexCheck(c, n[3], x, ForOpenArray, arrType)
    let pay = openArrayPayloadType(c.m.types, c.m.nirm.types, arrType)

    buildTyped target, info, ObjConstr, typeToIr(c.m, n.typ):
      target.addImmediateVal info, 0
      buildTyped target, info, AddrOf, elemType:
        buildTyped target, info, ArrayAt, pay:
          buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
            copyTree target, x
            target.addImmediateVal info, 0 # (p, len)-pair
          copyTree target, y

      target.addImmediateVal info, 1
      buildTyped target, info, Add, c.m.nativeIntId:
        buildTyped target, info, Sub, c.m.nativeIntId:
          copyTree target, z
          copyTree target, y
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 1

    freeTemp c, z
    freeTemp c, y
  else:
    raiseAssert "addSliceFields: " & typeToString(arrType)

proc genSlice(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)

  let x = c.genx(n[1])

  let arrType = n[1].typ.skipTypes(abstractVar)

  template body(target) =
    c.addSliceFields target, info, x, n, arrType

  valueIntoDest c, info, d, arrType, body
  freeTemp c, x

proc genMagic(c: var ProcCon; n: PNode; d: var Value; m: TMagic) =
  case m
  of mAnd: c.genAndOr(n, opcFJmp, d)
  of mOr: c.genAndOr(n, opcTJmp, d)
  of mPred, mSubI: c.genBinaryOp(n, d, CheckedSub)
  of mSucc, mAddI: c.genBinaryOp(n, d, CheckedAdd)
  of mInc:
    unused(c, n, d)
    c.genIncDec(n, CheckedAdd)
  of mDec:
    unused(c, n, d)
    c.genIncDec(n, CheckedSub)
  of mOrd, mChr, mUnown:
    c.gen(n[1], d)
  of generatedMagics:
    genCall(c, n, d)
  of mNew, mNewFinalize:
    unused(c, n, d)
    c.genNew(n, needsInit = true)
  of mNewSeq:
    unused(c, n, d)
    c.genNewSeq(n)
  of mNewSeqOfCap: c.genNewSeqOfCap(n, d)
  of mNewString, mNewStringOfCap, mExit: c.genCall(n, d)
  of mLengthOpenArray, mLengthArray, mLengthSeq, mLengthStr:
    genArrayLen(c, n, d)
  of mMulI: genBinaryOp(c, n, d, CheckedMul)
  of mDivI: genBinaryOp(c, n, d, CheckedDiv)
  of mModI: genBinaryOp(c, n, d, CheckedMod)
  of mAddF64: genBinaryOp(c, n, d, Add)
  of mSubF64: genBinaryOp(c, n, d, Sub)
  of mMulF64: genBinaryOp(c, n, d, Mul)
  of mDivF64: genBinaryOp(c, n, d, Div)
  of mShrI: genBinaryOp(c, n, d, BitShr)
  of mShlI: genBinaryOp(c, n, d, BitShl)
  of mAshrI: genBinaryOp(c, n, d, BitShr)
  of mBitandI: genBinaryOp(c, n, d, BitAnd)
  of mBitorI: genBinaryOp(c, n, d, BitOr)
  of mBitxorI: genBinaryOp(c, n, d, BitXor)
  of mAddU: genBinaryOp(c, n, d, Add)
  of mSubU: genBinaryOp(c, n, d, Sub)
  of mMulU: genBinaryOp(c, n, d, Mul)
  of mDivU: genBinaryOp(c, n, d, Div)
  of mModU: genBinaryOp(c, n, d, Mod)
  of mEqI, mEqB, mEqEnum, mEqCh:
    genCmpOp(c, n, d, Eq)
  of mLeI, mLeEnum, mLeCh, mLeB:
    genCmpOp(c, n, d, Le)
  of mLtI, mLtEnum, mLtCh, mLtB:
    genCmpOp(c, n, d, Lt)
  of mEqF64: genCmpOp(c, n, d, Eq)
  of mLeF64: genCmpOp(c, n, d, Le)
  of mLtF64: genCmpOp(c, n, d, Lt)
  of mLePtr, mLeU: genCmpOp(c, n, d, Le)
  of mLtPtr, mLtU: genCmpOp(c, n, d, Lt)
  of mEqProc, mEqRef:
    genCmpOp(c, n, d, Eq)
  of mXor: genBinaryOp(c, n, d, BitXor)
  of mNot: genUnaryOp(c, n, d, BoolNot)
  of mUnaryMinusI, mUnaryMinusI64:
    genUnaryMinus(c, n, d)
    #genNarrow(c, n, d)
  of mUnaryMinusF64: genUnaryMinus(c, n, d)
  of mUnaryPlusI, mUnaryPlusF64: gen(c, n[1], d)
  of mBitnotI:
    genUnaryOp(c, n, d, BitNot)
    when false:
      # XXX genNarrowU modified, do not narrow signed types
      let t = skipTypes(n.typ, abstractVar-{tyTypeDesc})
      let size = getSize(c.config, t)
      if t.kind in {tyUInt8..tyUInt32} or (t.kind == tyUInt and size < 8):
        c.gABC(n, opcNarrowU, d, TRegister(size*8))
  of mStrToStr, mEnsureMove: c.gen n[1], d
  of mIntToStr: genUnaryCp(c, n, d, "nimIntToStr")
  of mInt64ToStr: genUnaryCp(c, n, d, "nimInt64ToStr")
  of mBoolToStr: genUnaryCp(c, n, d, "nimBoolToStr")
  of mCharToStr: genUnaryCp(c, n, d, "nimCharToStr")
  of mFloatToStr:
    if n[1].typ.skipTypes(abstractInst).kind == tyFloat32:
      genUnaryCp(c, n, d, "nimFloat32ToStr")
    else:
      genUnaryCp(c, n, d, "nimFloatToStr")
  of mCStrToStr: genUnaryCp(c, n, d, "cstrToNimstr")
  of mEnumToStr: genEnumToStr(c, n, d)

  of mEqStr: genBinaryCp(c, n, d, "eqStrings")
  of mEqCString: genCall(c, n, d)
  of mLeStr: genBinaryCp(c, n, d, "leStrings")
  of mLtStr: genBinaryCp(c, n, d, "ltStrings")

  of mSetLengthStr:
    unused(c, n, d)
    let nb = copyTree(n)
    nb[1] = makeAddr(nb[1], c.m.idgen)
    genBinaryCp(c, nb, d, "setLengthStrV2")

  of mSetLengthSeq:
    unused(c, n, d)
    let nb = copyTree(n)
    nb[1] = makeAddr(nb[1], c.m.idgen)
    genCall(c, nb, d)

  of mSwap:
    unused(c, n, d)
    c.gen(lowerSwap(c.m.graph, n, c.m.idgen,
      if c.prc == nil: c.m.module else: c.prc), d)
  of mParseBiggestFloat:
    genCall c, n, d
  of mHigh:
    c.genHigh n, d

  of mEcho:
    unused(c, n, d)
    genUnaryCp c, n, d, "echoBinSafe"

  of mAppendStrCh:
    unused(c, n, d)
    let nb = copyTree(n)
    nb[1] = makeAddr(nb[1], c.m.idgen)
    genBinaryCp(c, nb, d, "nimAddCharV1")
  of mMinI, mMaxI, mAbsI, mDotDot:
    c.genCall(n, d)
  of mSizeOf:
    localError(c.config, n.info, sizeOfLikeMsg("sizeof"))
  of mAlignOf:
    localError(c.config, n.info, sizeOfLikeMsg("alignof"))
  of mOffsetOf:
    localError(c.config, n.info, sizeOfLikeMsg("offsetof"))
  of mRunnableExamples:
    discard "just ignore any call to runnableExamples"
  of mOf: genOf(c, n, d)
  of mAppendStrStr:
    unused(c, n, d)
    let nb = copyTree(n)
    nb[1] = makeAddr(nb[1], c.m.idgen)
    genBinaryCp(c, nb, d, "nimAddStrV1")
  of mAppendSeqElem:
    unused(c, n, d)
    let nb = copyTree(n)
    nb[1] = makeAddr(nb[1], c.m.idgen)
    genCall(c, nb, d)
  of mIsNil: genIsNil(c, n, d)
  of mInSet: genInSet(c, n, d)
  of mCard: genCard(c, n, d)
  of mEqSet: genEqSet(c, n, d)
  of mLeSet: genLeSet(c, n, d)
  of mLtSet: genLtSet(c, n, d)
  of mMulSet: genBinarySet(c, n, d, m)
  of mPlusSet: genBinarySet(c, n, d, m)
  of mMinusSet: genBinarySet(c, n, d, m)
  of mIncl, mExcl:
    unused(c, n, d)
    genInclExcl(c, n, m)
  of mConStrStr: genStrConcat(c, n, d)
  of mDefault, mZeroDefault:
    genDefault c, n, d
  of mMove: genMove(c, n, d)
  of mWasMoved, mReset:
    unused(c, n, d)
    genWasMoved(c, n)
  of mDestroy: genDestroy(c, n)
  #of mAccessEnv: unaryExpr(d, n, d, "$1.ClE_0")
  #of mAccessTypeField: genAccessTypeField(c, n, d)
  of mSlice: genSlice(c, n, d)
  of mTrace: discard "no code to generate"
  else:
    # mGCref, mGCunref: unused by ORC
    globalError(c.config, n.info, "cannot generate code for: " & $m)

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

proc genAddr(c: var ProcCon; n: PNode; d: var Value, flags: GenFlags) =
  if (let m = canElimAddr(n, c.m.idgen); m != nil):
    gen(c, m, d, flags)
    return

  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[0], flags)
  template body(target) =
    buildTyped target, info, AddrOf, typeToIr(c.m, n.typ):
      copyTree target, tmp

  valueIntoDest c, info, d, n.typ, body
  freeTemp c, tmp

proc genDeref(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags) =
  let info = toLineInfo(c, n.info)
  let tmp = c.genx(n[0], flags)
  template body(target) =
    buildTyped target, info, Load, typeToIr(c.m, n.typ):
      copyTree target, tmp

  valueIntoDest c, info, d, n.typ, body
  freeTemp c, tmp

proc addAddrOfFirstElem(c: var ProcCon; target: var Tree; info: PackedLineInfo; tmp: Value; typ: PType) =
  let arrType = typ.skipTypes(abstractVar)
  let elemType = arrayPtrTypeOf(c.m.nirm.types, typeToIr(c.m, arrType.lastSon))
  case arrType.kind
  of tyString:
    let t = typeToIr(c.m, typ)
    target.addImmediateVal info, 0
    buildTyped target, info, AddrOf, elemType:
      buildTyped target, info, ArrayAt, c.m.strPayloadId[1]:
        buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
          copyTree target, tmp
          target.addImmediateVal info, 1 # (len, p)-pair
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 0
    # len:
    target.addImmediateVal info, 1
    buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
      copyTree target, tmp
      target.addImmediateVal info, 0 # (len, p)-pair so len is at index 0

  of tySequence:
    let t = typeToIr(c.m, typ)
    target.addImmediateVal info, 0
    buildTyped target, info, AddrOf, elemType:
      buildTyped target, info, ArrayAt, seqPayloadPtrType(c.m.types, c.m.nirm.types, typ)[1]:
        buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
          copyTree target, tmp
          target.addImmediateVal info, 1 # (len, p)-pair
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 0
    # len:
    target.addImmediateVal info, 1
    buildTyped target, info, FieldAt, typeToIr(c.m, arrType):
      copyTree target, tmp
      target.addImmediateVal info, 0 # (len, p)-pair so len is at index 0

  of tyArray:
    let t = typeToIr(c.m, arrType)
    target.addImmediateVal info, 0
    buildTyped target, info, AddrOf, elemType:
      buildTyped target, info, ArrayAt, t:
        copyTree target, tmp
        target.addIntVal c.lit.numbers, info, c.m.nativeIntId, 0
    target.addImmediateVal info, 1
    target.addIntVal(c.lit.numbers, info, c.m.nativeIntId, toInt lengthOrd(c.config, arrType))
  else:
    raiseAssert "addAddrOfFirstElem: " & typeToString(typ)

proc genToOpenArrayConv(c: var ProcCon; arg: PNode; d: var Value; flags: GenFlags; destType: PType) =
  let info = toLineInfo(c, arg.info)
  let tmp = c.genx(arg, flags)
  let arrType = destType.skipTypes(abstractVar)
  template body(target) =
    buildTyped target, info, ObjConstr, typeToIr(c.m, arrType):
      c.addAddrOfFirstElem target, info, tmp, arg.typ

  valueIntoDest c, info, d, arrType, body
  freeTemp c, tmp

proc genConv(c: var ProcCon; n, arg: PNode; d: var Value; flags: GenFlags; opc: Opcode) =
  let targetType = n.typ.skipTypes({tyDistinct})
  let argType = arg.typ.skipTypes({tyDistinct})

  if sameBackendType(targetType, argType) or (
      argType.kind == tyProc and targetType.kind == argType.kind):
    # don't do anything for lambda lifting conversions:
    gen c, arg, d
    return

  if opc != Cast and targetType.skipTypes({tyVar, tyLent}).kind in {tyOpenArray, tyVarargs} and
      argType.skipTypes({tyVar, tyLent}).kind notin {tyOpenArray, tyVarargs}:
    genToOpenArrayConv c, arg, d, flags, n.typ
    return

  let info = toLineInfo(c, n.info)
  let tmp = c.genx(arg, flags)
  template body(target) =
    buildTyped target, info, opc, typeToIr(c.m, n.typ):
      if opc == CheckedObjConv:
        target.addLabel info, CheckedGoto, c.exitLabel
      copyTree target, tmp

  valueIntoDest c, info, d, n.typ, body
  freeTemp c, tmp

proc genObjOrTupleConstr(c: var ProcCon; n: PNode; d: var Value; t: PType) =
  # XXX x = (x.old, 22)  produces wrong code ... stupid self assignments
  let info = toLineInfo(c, n.info)
  template body(target) =
    buildTyped target, info, ObjConstr, typeToIr(c.m, t):
      for i in ord(n.kind == nkObjConstr)..<n.len:
        let it = n[i]
        if it.kind == nkExprColonExpr:
          genField(c, it[0], Value target)
          let tmp = c.genx(it[1])
          copyTree target, tmp
          c.freeTemp(tmp)
        else:
          let tmp = c.genx(it)
          target.addImmediateVal info, i
          copyTree target, tmp
          c.freeTemp(tmp)

      if isException(t):
        target.addImmediateVal info, 1 # "name" field is at position after the "parent". See system.nim
        target.addStrVal c.lit.strings, info, t.skipTypes(abstractInst).sym.name.s

  constrIntoDest c, info, d, t, body

proc genRefObjConstr(c: var ProcCon; n: PNode; d: var Value) =
  if isEmpty(d): d = getTemp(c, n)
  let info = toLineInfo(c, n.info)
  let refType = n.typ.skipTypes(abstractInstOwned)
  let objType = refType.lastSon

  rawGenNew(c, d, refType, n.info, needsInit = nfAllFieldsSet notin n.flags)
  var deref = default(Value)
  deref.buildTyped info, Load, typeToIr(c.m, objType):
    deref.Tree.copyTree d
  genObjOrTupleConstr c, n, deref, objType

proc genSeqConstr(c: var ProcCon; n: PNode; d: var Value) =
  if isEmpty(d): d = getTemp(c, n)

  let info = toLineInfo(c, n.info)
  let seqtype = skipTypes(n.typ, abstractVarRange)
  let baseType = seqtype.lastSon

  var b = default(Value)
  b.addIntVal c.lit.numbers, info, c.m.nativeIntId, n.len

  genNewSeqPayload(c, info, d, b, seqtype)

  for i in 0..<n.len:
    var dd = default(Value)
    buildTyped dd, info, ArrayAt, seqPayloadPtrType(c.m.types, c.m.nirm.types, seqtype)[1]:
      buildTyped dd, info, FieldAt, typeToIr(c.m, seqtype):
        copyTree Tree(dd), d
        dd.addIntVal c.lit.numbers, info, c.m.nativeIntId, i
    gen(c, n[i], dd)

  freeTemp c, d

proc genArrayConstr(c: var ProcCon; n: PNode, d: var Value) =
  let seqType = n.typ.skipTypes(abstractVar-{tyTypeDesc})
  if seqType.kind == tySequence:
    genSeqConstr(c, n, d)
    return

  let info = toLineInfo(c, n.info)
  template body(target) =
    buildTyped target, info, ArrayConstr, typeToIr(c.m, n.typ):
      for i in 0..<n.len:
        let tmp = c.genx(n[i])
        copyTree target, tmp
        c.freeTemp(tmp)

  constrIntoDest c, info, d, n.typ, body

proc genAsgn2(c: var ProcCon; a, b: PNode) =
  assert a != nil
  assert b != nil
  var d = c.genx(a)
  c.gen b, d

proc genVarSection(c: var ProcCon; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt: continue
    #assert(a[0].kind == nkSym) can happen for transformed vars
    if a.kind == nkVarTuple:
      c.gen(lowerTupleUnpacking(c.m.graph, a, c.m.idgen, c.prc))
    else:
      var vn = a[0]
      if vn.kind == nkPragmaExpr: vn = vn[0]
      if vn.kind == nkSym:
        let s = vn.sym
        var opc: Opcode
        if sfThread in s.flags:
          opc = SummonThreadLocal
        elif sfGlobal in s.flags:
          opc = SummonGlobal
        else:
          opc = Summon
        let t = typeToIr(c.m, s.typ)
        #assert t.int >= 0, typeToString(s.typ) & (c.config $ n.info)
        let symId = toSymId(c, s)
        c.code.addSummon toLineInfo(c, a.info), symId, t, opc
        c.m.nirm.symnames[symId] = c.lit.strings.getOrIncl(s.name.s)
        if a[2].kind != nkEmpty:
          genAsgn2(c, vn, a[2])
      else:
        if a[2].kind == nkEmpty:
          genAsgn2(c, vn, expandDefault(vn.typ, vn.info))
        else:
          genAsgn2(c, vn, a[2])

proc genAsgn(c: var ProcCon; n: PNode) =
  var d = c.genx(n[0])
  c.gen n[1], d

proc convStrToCStr(c: var ProcCon; n: PNode; d: var Value) =
  genUnaryCp(c, n, d, "nimToCStringConv", argAt = 0)

proc convCStrToStr(c: var ProcCon; n: PNode; d: var Value) =
  genUnaryCp(c, n, d, "cstrToNimstr", argAt = 0)

proc irModule(c: var ProcCon; owner: PSym): string =
  #if owner == c.m.module: "" else:
  customPath(toFullPath(c.config, owner.info))

proc fromForeignModule(c: ProcCon; s: PSym): bool {.inline.} =
  result = ast.originatingModule(s) != c.m.module and not c.m.noModularity

proc genRdVar(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags) =
  let info = toLineInfo(c, n.info)
  let s = n.sym
  if fromForeignModule(c, s):
    template body(target) =
      build target, info, ModuleSymUse:
        target.addStrVal c.lit.strings, info, irModule(c, ast.originatingModule(s))
        target.addImmediateVal info, s.itemId.item.int

    valueIntoDest c, info, d, s.typ, body
  else:
    template body(target) =
      target.addSymUse info, toSymId(c, s)
    valueIntoDest c, info, d, s.typ, body

proc genSym(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags = {}) =
  let s = n.sym
  case s.kind
  of skVar, skForVar, skTemp, skLet, skResult, skParam, skConst:
    genRdVar(c, n, d, flags)
  of skProc, skFunc, skConverter, skMethod, skIterator:
    if not fromForeignModule(c, s):
      # anon and generic procs have no AST so we need to remember not to forget
      # to emit these:
      if not c.m.processedProcs.contains(s.itemId):
        if not c.m.pendingProcsAsSet.containsOrIncl(s.itemId):
          c.m.pendingProcs.add s
    genRdVar(c, n, d, flags)
  of skEnumField:
    let info = toLineInfo(c, n.info)
    template body(target) =
      target.addIntVal c.lit.numbers, info, typeToIr(c.m, n.typ), s.position
    valueIntoDest c, info, d, n.typ, body
  else:
    localError(c.config, n.info, "cannot generate code for: " & s.name.s)

proc genNumericLit(c: var ProcCon; n: PNode; d: var Value; bits: int64) =
  let info = toLineInfo(c, n.info)
  template body(target) =
    target.addIntVal c.lit.numbers, info, typeToIr(c.m, n.typ), bits
  valueIntoDest c, info, d, n.typ, body

proc genStringLit(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  template body(target) =
    target.addStrVal c.lit.strings, info, n.strVal
  valueIntoDest c, info, d, n.typ, body

proc genNilLit(c: var ProcCon; n: PNode; d: var Value) =
  let info = toLineInfo(c, n.info)
  template body(target) =
    target.addNilVal info, typeToIr(c.m, n.typ)
  valueIntoDest c, info, d, n.typ, body

proc genRangeCheck(c: var ProcCon; n: PNode; d: var Value) =
  if optRangeCheck in c.options:
    let info = toLineInfo(c, n.info)
    let tmp = c.genx n[0]
    let a = c.genx n[1]
    let b = c.genx n[2]
    template body(target) =
      buildTyped target, info, CheckedRange, typeToIr(c.m, n.typ):
        copyTree target, tmp
        copyTree target, a
        copyTree target, b
        target.addLabel info, CheckedGoto, c.exitLabel
    valueIntoDest c, info, d, n.typ, body
    freeTemp c, tmp
    freeTemp c, a
    freeTemp c, b
  else:
    gen c, n[0], d

proc genArrAccess(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags) =
  let arrayType = n[0].typ.skipTypes(abstractVarRange-{tyTypeDesc})
  let arrayKind = arrayType.kind
  let info = toLineInfo(c, n.info)
  case arrayKind
  of tyString:
    let a = genx(c, n[0], flags)
    let b = genIndexCheck(c, n[1], a, ForStr, arrayType)
    let t = typeToIr(c.m, n.typ)
    template body(target) =
      buildTyped target, info, ArrayAt, c.m.strPayloadId[1]:
        buildTyped target, info, FieldAt, typeToIr(c.m, arrayType):
          copyTree target, a
          target.addImmediateVal info, 1 # (len, p)-pair
        copyTree target, b
    intoDest d, info, t, body
    freeTemp c, b
    freeTemp c, a

  of tyCstring, tyPtr, tyUncheckedArray:
    let a = genx(c, n[0], flags)
    let b = genx(c, n[1])
    template body(target) =
      buildTyped target, info, ArrayAt, typeToIr(c.m, arrayType):
        copyTree target, a
        copyTree target, b
    valueIntoDest c, info, d, n.typ, body

    freeTemp c, b
    freeTemp c, a
  of tyTuple:
    let a = genx(c, n[0], flags)
    let b = int n[1].intVal
    template body(target) =
      buildTyped target, info, FieldAt, typeToIr(c.m, arrayType):
        copyTree target, a
        target.addImmediateVal info, b
    valueIntoDest c, info, d, n.typ, body

    freeTemp c, a
  of tyOpenArray, tyVarargs:
    let a = genx(c, n[0], flags)
    let b = genIndexCheck(c, n[1], a, ForOpenArray, arrayType)
    let t = typeToIr(c.m, n.typ)
    template body(target) =
      buildTyped target, info, ArrayAt, openArrayPayloadType(c.m.types, c.m.nirm.types, n[0].typ):
        buildTyped target, info, FieldAt, typeToIr(c.m, arrayType):
          copyTree target, a
          target.addImmediateVal info, 0 # (p, len)-pair
        copyTree target, b
    intoDest d, info, t, body

    freeTemp c, b
    freeTemp c, a
  of tyArray:
    let a = genx(c, n[0], flags)
    var b = default(Value)
    genIndex(c, n[1], n[0].typ, b)

    template body(target) =
      buildTyped target, info, ArrayAt, typeToIr(c.m, arrayType):
        copyTree target, a
        copyTree target, b
    valueIntoDest c, info, d, n.typ, body
    freeTemp c, b
    freeTemp c, a
  of tySequence:
    let a = genx(c, n[0], flags)
    let b = genIndexCheck(c, n[1], a, ForSeq, arrayType)
    let t = typeToIr(c.m, n.typ)
    template body(target) =
      buildTyped target, info, ArrayAt, seqPayloadPtrType(c.m.types, c.m.nirm.types, n[0].typ)[1]:
        buildTyped target, info, FieldAt, t:
          copyTree target, a
          target.addImmediateVal info, 1 # (len, p)-pair
        copyTree target, b
    intoDest d, info, t, body
    freeTemp c, b
    freeTemp c, a
  else:
    localError c.config, n.info, "invalid type for nkBracketExpr: " & $arrayKind

proc genObjAccess(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags) =
  let info = toLineInfo(c, n.info)
  let a = genx(c, n[0], flags)

  template body(target) =
    buildTyped target, info, FieldAt, typeToIr(c.m, n[0].typ):
      copyTree target, a
      genField c, n[1], Value(target)

  valueIntoDest c, info, d, n.typ, body
  freeTemp c, a

proc genParams(c: var ProcCon; params: PNode; prc: PSym) =
  if params.len > 0 and resultPos < prc.ast.len:
    let resNode = prc.ast[resultPos]
    let res = resNode.sym # get result symbol
    c.code.addSummon toLineInfo(c, res.info), toSymId(c, res),
      typeToIr(c.m, res.typ), SummonResult

  for i in 1..<params.len:
    let s = params[i].sym
    if not isCompileTimeOnly(s.typ):
      let t = typeToIr(c.m, s.typ)
      assert t.int != -1, typeToString(s.typ)
      let symId = toSymId(c, s)
      c.code.addSummon toLineInfo(c, params[i].info), symId, t, SummonParam
      c.m.nirm.symnames[symId] = c.lit.strings.getOrIncl(s.name.s)

proc addCallConv(c: var ProcCon; info: PackedLineInfo; callConv: TCallingConvention) =
  template ann(s: untyped) = c.code.addPragmaId info, s
  case callConv
  of ccNimCall, ccFastCall, ccClosure: ann FastCall
  of ccStdCall: ann StdCall
  of ccCDecl: ann CDeclCall
  of ccSafeCall: ann SafeCall
  of ccSysCall: ann SysCall
  of ccInline: ann InlineCall
  of ccNoInline: ann NoinlineCall
  of ccThisCall: ann ThisCall
  of ccNoConvention: ann NoCall

proc genProc(cOuter: var ProcCon; prc: PSym) =
  if cOuter.m.processedProcs.containsOrIncl(prc.itemId):
    return
  #assert cOuter.m.inProc == 0, " in nested proc! " & prc.name.s
  if cOuter.m.inProc > 0:
    if not cOuter.m.pendingProcsAsSet.containsOrIncl(prc.itemId):
      cOuter.m.pendingProcs.add prc
    return
  inc cOuter.m.inProc

  var c = initProcCon(cOuter.m, prc, cOuter.m.graph.config)

  let body = transformBody(c.m.graph, c.m.idgen, prc, {useCache, keepOpenArrayConversions})

  let info = toLineInfo(c, body.info)
  build c.code, info, ProcDecl:
    let symId = toSymId(c, prc)
    addSymDef c.code, info, symId
    c.m.nirm.symnames[symId] = c.lit.strings.getOrIncl(prc.name.s)
    addCallConv c, info, prc.typ.callConv
    if sfCompilerProc in prc.flags:
      build c.code, info, PragmaPair:
        c.code.addPragmaId info, CoreName
        c.code.addStrVal c.lit.strings, info, prc.name.s
    if {sfImportc, sfExportc} * prc.flags != {}:
      build c.code, info, PragmaPair:
        c.code.addPragmaId info, ExternName
        c.code.addStrVal c.lit.strings, info, prc.loc.r
      if sfImportc in prc.flags:
        if lfHeader in prc. loc.flags:
          assert(prc. annex != nil)
          let str = getStr(prc. annex.path)
          build c.code, info, PragmaPair:
            c.code.addPragmaId info, HeaderImport
            c.code.addStrVal c.lit.strings, info, str
        elif lfDynamicLib in prc. loc.flags:
          assert(prc. annex != nil)
          let str = getStr(prc. annex.path)
          build c.code, info, PragmaPair:
            c.code.addPragmaId info, DllImport
            c.code.addStrVal c.lit.strings, info, str
      elif sfExportc in prc.flags:
        if lfDynamicLib in prc. loc.flags:
          c.code.addPragmaId info, DllExport
        else:
          c.code.addPragmaId info, ObjExport

    genParams(c, prc.typ.n, prc)
    gen(c, body)
    patch c, body, c.exitLabel
    build c.code, info, Ret:
      discard

  #copyTree cOuter.code, c.code
  dec cOuter.m.inProc

proc genProc(cOuter: var ProcCon; n: PNode) =
  if n.len == 0 or n[namePos].kind != nkSym: return
  let prc = n[namePos].sym
  if isGenericRoutineStrict(prc) or isCompileTimeProc(prc) or sfForward in prc.flags: return
  genProc cOuter, prc

proc genClosureCall(c: var ProcCon; n: PNode; d: var Value) =
  let typ = skipTypes(n[0].typ, abstractInstOwned)
  if tfIterator in typ.flags:
    const PatIter = "$1.ClP_0($3, $1.ClE_0)" # we know the env exists

  else:
    const PatProc = "$1.ClE_0? $1.ClP_0($3, $1.ClE_0):(($4)($1.ClP_0))($2)"


proc genComplexCall(c: var ProcCon; n: PNode; d: var Value) =
  if n[0].typ != nil and n[0].typ.skipTypes({tyGenericInst, tyAlias, tySink, tyOwned}).callConv == ccClosure:
    # XXX genClosureCall p, n, d
    genCall c, n, d
  else:
    genCall c, n, d

proc gen(c: var ProcCon; n: PNode; d: var Value; flags: GenFlags = {}) =
  when defined(nimCompilerStacktraceHints):
    setFrameMsg c.config$n.info & " " & $n.kind & " " & $flags
  case n.kind
  of nkSym: genSym(c, n, d, flags)
  of nkCallKinds:
    if n[0].kind == nkSym:
      let s = n[0].sym
      if s.magic != mNone:
        genMagic(c, n, d, s.magic)
      elif s.kind == skMethod:
        localError(c.config, n.info, "cannot call method " & s.name.s &
          " at compile time")
      else:
        genComplexCall(c, n, d)
    else:
      genComplexCall(c, n, d)
  of nkCharLit..nkInt64Lit, nkUIntLit..nkUInt64Lit:
    genNumericLit(c, n, d, n.intVal)
  of nkFloatLit..nkFloat128Lit:
    genNumericLit(c, n, d, cast[int64](n.floatVal))
  of nkStrLit..nkTripleStrLit:
    genStringLit(c, n, d)
  of nkNilLit:
    if not n.typ.isEmptyType: genNilLit(c, n, d)
    else: unused(c, n, d)
  of nkAsgn, nkFastAsgn, nkSinkAsgn:
    unused(c, n, d)
    genAsgn(c, n)
  of nkDotExpr: genObjAccess(c, n, d, flags)
  of nkCheckedFieldExpr: genObjAccess(c, n[0], d, flags)
  of nkBracketExpr: genArrAccess(c, n, d, flags)
  of nkDerefExpr, nkHiddenDeref: genDeref(c, n, d, flags)
  of nkAddr, nkHiddenAddr: genAddr(c, n, d, flags)
  of nkIfStmt, nkIfExpr: genIf(c, n, d)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n[0][1], d)
  of nkCaseStmt: genCase(c, n, d)
  of nkWhileStmt:
    unused(c, n, d)
    genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n, d)
  of nkReturnStmt: genReturn(c, n)
  of nkRaiseStmt: genRaise(c, n)
  of nkBreakStmt: genBreak(c, n)
  of nkTryStmt, nkHiddenTryStmt: genTry(c, n, d)
  of nkStmtList:
    #unused(c, n, d)
    # XXX Fix this bug properly, lexim triggers it
    for x in n: gen(c, x)
  of nkStmtListExpr:
    for i in 0..<n.len-1: gen(c, n[i])
    gen(c, n[^1], d, flags)
  of nkPragmaBlock:
    gen(c, n.lastSon, d, flags)
  of nkDiscardStmt:
    unused(c, n, d)
    gen(c, n[0], d)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    genConv(c, n, n[1], d, flags, NumberConv) # misnomer?
  of nkObjDownConv:
    genConv(c, n, n[0], d, flags, ObjConv)
  of nkObjUpConv:
    genConv(c, n, n[0], d, flags, CheckedObjConv)
  of nkVarSection, nkLetSection, nkConstSection:
    unused(c, n, d)
    genVarSection(c, n)
  of nkLambdaKinds:
    #let s = n[namePos].sym
    #discard genProc(c, s)
    gen(c, newSymNode(n[namePos].sym), d)
  of nkChckRangeF, nkChckRange64, nkChckRange:
    genRangeCheck(c, n, d)
  of declarativeDefs - {nkIteratorDef}:
    unused(c, n, d)
    genProc(c, n)
  of nkEmpty, nkCommentStmt, nkTypeSection, nkPragma,
     nkTemplateDef, nkIncludeStmt, nkImportStmt, nkFromStmt, nkExportStmt,
     nkMixinStmt, nkBindStmt, nkMacroDef, nkIteratorDef:
    unused(c, n, d)
  of nkStringToCString: convStrToCStr(c, n, d)
  of nkCStringToString: convCStrToStr(c, n, d)
  of nkBracket: genArrayConstr(c, n, d)
  of nkCurly: genSetConstr(c, n, d)
  of nkObjConstr:
    if n.typ.skipTypes(abstractInstOwned).kind == tyRef:
      genRefObjConstr(c, n, d)
    else:
      genObjOrTupleConstr(c, n, d, n.typ)
  of nkPar, nkClosure, nkTupleConstr:
    genObjOrTupleConstr(c, n, d, n.typ)
  of nkCast:
    genConv(c, n, n[1], d, flags, Cast)
  of nkComesFrom:
    discard "XXX to implement for better stack traces"
  #of nkState: genState(c, n)
  #of nkGotoState: genGotoState(c, n)
  #of nkBreakState: genBreakState(c, n, d)
  else:
    localError(c.config, n.info, "cannot generate IR code for " & $n)

proc genPendingProcs(c: var ProcCon) =
  while c.m.pendingProcs.len > 0:
    let procs = move(c.m.pendingProcs)
    for v in procs:
      genProc(c, v)

proc genStmt*(c: var ProcCon; n: PNode): NodePos =
  result = NodePos c.code.len
  var d = default(Value)
  c.gen(n, d)
  unused c, n, d
  genPendingProcs c

proc genExpr*(c: var ProcCon; n: PNode, requiresValue = true): int =
  result = c.code.len
  var d = default(Value)
  c.gen(n, d)
  genPendingProcs c
  if isEmpty d:
    if requiresValue:
      globalError(c.config, n.info, "VM problem: d register is not set")
