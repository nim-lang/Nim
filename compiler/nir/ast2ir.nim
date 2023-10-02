#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables, sets]
import ".." / [ast, types, options, lineinfos, msgs]
import .. / ic / bitabs

import nirtypes, nirinsts, nirlineinfos, nirslots, types2ir

type
  ModuleCon = ref object
    strings: BiTable[string]
    man: LineInfoManager
    types: TypesCon
    slotGenerator: ref int

  LocInfo = object
    inUse: bool
    typ: TypeId

  ProcCon = object
    conf: ConfigRef
    lastFileKey: FileIndex
    lastFileVal: LitId
    labelGen: int
    scopes: seq[LabelId]
    sm: SlotManager
    locGen: int
    m: ModuleCon

proc initModuleCon*(conf: ConfigRef): ModuleCon =
  ModuleCon(types: initTypesCon(conf), slotGenerator: new(int))

proc initProcCon*(m: ModuleCon; ): ProcCon =
  ProcCon(m: m, sm: initSlotManager({}, m.slotGenerator))

proc toLineInfo(c: var ProcCon; i: TLineInfo): PackedLineInfo =
  var val: LitId
  if c.lastFileKey == i.fileIndex:
    val = c.lastFileVal
  else:
    val = c.m.strings.getOrIncl(toFullPath(c.conf, i.fileIndex))
    # remember the entry:
    c.lastFileKey = i.fileIndex
    c.lastFileVal = val
  result = pack(c.m.man, val, int32 i.line, int32 i.col)

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
