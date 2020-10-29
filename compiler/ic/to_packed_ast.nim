#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [hashes, tables]
import packed_ast, bitabs
import ".." / [ast, idents, lineinfos, options, pathutils, msgs]

type
  Context = object
    thisModule: int32
    lastFile: FileIndex # remember the last lookup entry.
    lastLit: LitId
    filenames: Table[FileIndex, LitId]

proc toLitId(x: FileIndex; ir: var PackedTree; c: var Context): LitId =
  if x == c.lastFile:
    result = c.lastLit
  else:
    result = c.filenames.getOrDefault(x)
    if result == LitId(0):
      let p = msgs.toFullPath(ir.sh.config, x)
      result = getOrIncl(ir.sh.strings, p)
      c.filenames[x] = result
    c.lastFile = x
    c.lastLit = result

proc toPackedInfo(x: TLineInfo; ir: var PackedTree; c: var Context): PackedLineInfo =
  PackedLineInfo(line: x.line, col: x.col, file: toLitId(x.fileIndex, ir, c))

proc toPackedType(t: PType; ir: var PackedTree; c: var Context): TypeId =
  result = TypeId(0)

proc toPackedSym(s: PSym; ir: var PackedTree; c: var Context): SymId =
  result = SymId(0)

proc toPackedSymNode(n: PNode; ir: var PackedTree; c: var Context) =
  assert n.kind == nkSym
  let t = toPackedType(n.typ, ir, c)

  if n.sym.itemId.module == c.thisModule:
    # it is a symbol that belongs to the module we're currently
    # packing:
    let sid = toPackedSym(n.sym, ir, c)
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32(sid),
      typeId: t, info: toPackedInfo(n.info, ir, c))
  else:
    # store it as an external module reference:
    #  nkModuleRef
    discard


proc toPackedNode*(n: PNode; ir: var PackedTree; c: var Context) =
  template toP(x: TLineInfo): PackedLineInfo = toPackedInfo(x, ir, c)

  case n.kind
  of nkNone, nkEmpty, nkNilLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: 0,
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  of nkIdent:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.strings, n.ident.s),
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  of nkSym:
    toPackedSymNode(n, ir, c)
  of directIntLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32(n.intVal),
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  of externIntLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.integers, n.intVal),
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  of nkStrLit..nkTripleStrLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.strings, n.strVal),
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  of nkFloatLit..nkFloat128Lit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.floats, n.floatVal),
      typeId: toPackedType(n.typ, ir, c), info: toP n.info)
  else:
    let patchPos = ir.prepare(n.kind, n.flags, toPackedType(n.typ, ir, c), toP n.info)
    for i in 0..<n.len:
      toPackedNode(n[i], ir, c)
    ir.patch patchPos

proc moduleToIr*(n: PNode; ir: var PackedTree; module: PSym) =
  var c = Context(thisModule: module.itemId.module)
  toPackedNode(n, ir, c)
