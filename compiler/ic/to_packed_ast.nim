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
import ".." / [ast, idents, lineinfos, options, pathutils]

type
  Context = object
    module: PSym

proc toPackedType(t: PType; ir: var Tree; c: var Context): TypeId =
  result = TypeId(0)

proc toPackedSym(n: PNode; ir: var Tree; c: var Context) =
  let t = toPackedType(n.typ, ir, c)

  var o = n.sym.owner
  while o != nil and o.kind != skModule:
    o = o.owner
  if o == c.module:
    # it is a symbol that belongs to the module we're currently
    # packing:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: ,
      typeId: t, info: n.info)

  else:
    # store it as an external module reference:
      nkModuleRef



proc toPackedNode*(n: PNode; ir: var Tree; c: var Context) =
  case n.kind
  of nkNone, nkEmpty, nkNilLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: 0,
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  of nkIdent:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.strings, n.ident.s),
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  of nkSym:
    toPackedSym(n, ir, c)
  of directIntLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32(n.intVal),
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  of externIntLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.integers, n.intVal),
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  of nkStrLit..nkTripleStrLit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.strings, n.strVal),
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  of nkFloatLit..nkFloat128Lit:
    ir.nodes.add Node(kind: n.kind, flags: n.flags, operand: int32 getOrIncl(ir.sh.floats, n.floatVal),
      typeId: toPackedType(n.typ, ir, c), info: n.info)
  else:
    let patchPos = ir.prepare(n.kind, n.flags, toPackedType(n.typ, ir, c), n.info)
    for i in 0..<n.len:
      toPackedNode(n[i], ir, c)
    ir.patch patchPos

proc moduleToIr*(n: PNode; ir: var Tree; module: PSym) =
  var c = Context(module: module)
  toPackedNode(n, ir, c)
