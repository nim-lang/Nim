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

proc toLineInfo(i: TLineInfo; c: var Context): PackedLineInfo =
  var val: LitId
  if c.lastFileKey == i.fileIndex:
    val = c.lastFileVal
  else:
    val = c.strings.getOrIncl(toFullPath(c.conf, i.fileIndex))
    # remember the entry:
    c.lastFileKey = i.fileIndex
    c.lastFileVal = val
  result = pack(c.man, val, int32 i.line, int32 i.col)

proc astToIr*(n: PNode; dest: var Tree; c: var Context) =
  let info = toLineInfo(n.info, c)

