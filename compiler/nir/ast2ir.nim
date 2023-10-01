#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables]
import ".." / [ast, types, options, lineinfos, msgs]
import .. / ic / bitabs

import nirtypes, nirinsts, nirlineinfos

type
  Context = object
    conf: ConfigRef
    lastFileKey: FileIndex
    lastFileVal: LitId
    strings: BiTable[string]
    man: LineInfoManager
    labelGen: int

proc toLineInfo(c: var Context; i: TLineInfo): PackedLineInfo =
  var val: LitId
  if c.lastFileKey == i.fileIndex:
    val = c.lastFileVal
  else:
    val = c.strings.getOrIncl(toFullPath(c.conf, i.fileIndex))
    # remember the entry:
    c.lastFileKey = i.fileIndex
    c.lastFileVal = val
  result = pack(c.man, val, int32 i.line, int32 i.col)

proc gen*(c: var Context; dest: var Tree; n: PNode)
proc genx*(c: var Context; dest: var Tree; n: PNode): Tree

template withBlock(lab: LabelId; body: untyped) =
  body
  dest.addInstr(info, Label, lab)

proc genWhile(c: var Context; dest: var Tree; n: PNode) =
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

proc genx*(c: var Context; dest: var Tree; n: PNode): Tree =
  quit "too implement"

proc gen*(c: var Context; dest: var Tree; n: PNode) =
  case n.kind
  of nkWhileStmt:
    genWhile c, dest, n
  else:
    discard
