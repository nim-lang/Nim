#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [hashes, tables]
import bitabs, packed_ast
import ".." / [ast, lineinfos, options, pathutils, ropes, msgs, idents]

type
  Resolver = proc(module: int32; name: string): PSym
  PackedDecoder* = object
    thisModule: int32
    lastFile: FileIndex # remember the last lookup entry.
    lastLit: LitId
    filenames: Table[LitId, FileIndex]
    pendingTypes: seq[ItemId]
    pendingSyms: seq[ItemId]
    typeMap: Table[ItemId, PType]  # ItemId.item -> PType
    symMap: Table[ItemId, PSym]    # ItemId.item -> PSym
    resolver: Resolver
    idents: IdentCache
  Context = PackedDecoder

proc fromTree(ir: PackedTree; c: var Context; pos = 0.NodePos): PNode
proc fromSym(s: PackedSym; id: ItemId; ir: PackedTree; c: var Context): PSym
proc fromType(t: PackedType; ir: PackedTree; c: var Context): PType

proc fromSym(s: SymId or int32; id: ItemId; ir: PackedTree;
             c: var Context): PSym =
  if s.int >= 0:
    result = fromSym(ir.sh.syms[int s], id, ir, c)

proc fromType(t: TypeId or int32; ir: PackedTree; c: var Context): PType =
  if t.int >= 0:
    result = fromType(ir.sh.types[int t], ir, c)

proc fromIdent(l: LitId; ir: PackedTree; c: var Context): PIdent =
  result = getIdent(c.idents, ir.sh.strings[l])

proc fromLineInfo(p: PackedLineInfo; ir: PackedTree; c: var Context): TLineInfo =
  if p.file notin c.filenames:
    var itIsKnown: bool
    c.filenames[p.file] = fileInfoIdx(ir.sh.config,
                                      AbsoluteFile ir.sh.strings[p.file],
                                      itIsKnown)
  result = TLineInfo(line: p.line, col: p.col, fileIndex: c.filenames[p.file])

proc fromLib(l: PackedLib; ir: PackedTree; c: var Context): PLib =
  # XXX: hack; assume a zero LitId means the PackedLib is all zero (empty)
  if l.name.int == 0: return nil

  result = PLib(generated: l.generated, isOverriden: l.isOverriden,
                kind: l.kind, name: rope ir.sh.strings[l.name],
                path: fromTree(l.path, c))

iterator unpackSymbols*(n: PackedTree; c: var Context; m: PSym;
                        name: PIdent = nil): PSym =
  ## unpack the symbols from the tree
  c.thisModule = m.itemId.module
  for symId, p in n.sh.syms.pairs:
    if name == nil or name.s == n.sh.strings[p.name]:
      let id = ItemId(module: m.itemId.module, item: symId.int32)
      yield p.fromSym(id, n, c)

proc loadSymbol(id: ItemId; c: var Context; ir: PackedTree): PSym =
  if id == nilItemId: return nil
  # short-circuit if we already have the PSym
  result = getOrDefault(c.symMap, id, nil)
  if result == nil:
    if id.module == c.thisModule:
      result = fromSym(id.item, id, ir, c)
    else:
      result = c.resolver(id.module, ir.sh.strings[LitId id.item])
    # cache the result
    c.symMap[id] = result

proc fromSym(s: PackedSym; id: ItemId; ir: PackedTree; c: var Context): PSym =
  result = getOrDefault(c.symMap, id, nil)
  if result != nil: return nil

  result = PSym(itemId: id, kind: s.kind, magic: s.magic, flags: s.flags,
                info: fromLineInfo(s.info, ir, c), options: s.options,
                position: s.position, name: fromIdent(s.name, ir, c))
  c.symMap[id] = result

  result.typ = fromType(s.typeId, ir, c)
  result.constraint = fromTree(s.constraint, c)
  result.ast = fromTree(s.ast, c)
  result.annex = fromLib(s.annex, ir, c)
  when hasFFI:
    result.cname = ir.sh.strings[int s.cname]

  if s.kind in {skLet, skVar, skField, skForVar}:
    result.guard = loadSymbol(s.guard, c, ir)
    result.bitsize = s.bitsize
    result.alignment = s.alignment
  result.owner = loadSymbol(s.owner, c, ir)
  let externalName = ir.sh.strings[s.externalName]
  if externalName != "":
    result.loc.r = rope externalName

proc asItemId(ir: PackedTree; pos = 0.NodePos): ItemId =
  ## read an itemId from the tree
  assert ir.nodes[pos.int].kind == nkModuleRef
  result.module = ir.nodes[pos.int + 1].operand
  result.item = ir.nodes[pos.int + 2].operand

proc fromSymNode(ir: PackedTree; c: var Context; pos = 0.NodePos): PSym =
  template n: PackedNode = ir.nodes[int pos]
  let id =
    case n.kind
    of nkModuleRef:
      asItemId(ir, pos)
    else:
      ItemId(module: c.thisModule, item: n.operand)
  result = loadSymbol(id, c, ir)

proc fromType(t: PackedType; ir: PackedTree; c: var Context): PType =
  # short-circuit if we already have the PType
  result = getOrDefault(c.typeMap, t.nonUniqueId, nil)
  if result != nil: return nil

  result = PType(kind: t.kind, flags: t.flags, size: t.size, align: t.align,
                 paddingAtEnd: t.paddingAtEnd, lockLevel: t.lockLevel,
                 uniqueId: t.nonUniqueId)

  result.sym = loadSymbol(t.sym, c, ir)
  result.owner = loadSymbol(t.owner, c, ir)
  for op, item in pairs t.attachedOps:
    result.attachedOps[op] = loadSymbol(item, c, ir)
  result.typeInst = fromType(t.typeInst, ir, c)
  for son in items t.types:
    result.sons.add fromType(son, ir, c)
  result.n = fromTree(t.node, c)
  for generic, id in items t.methods:
    result.methods.add (generic, loadSymbol(id, c, ir))

proc fromTree(ir: PackedTree; c: var Context; pos = 0.NodePos): PNode =
  template n: PackedNode = ir.nodes[int pos]
  result = PNode(typ: fromType(n.typeId, ir, c), flags: n.flags,
                 kind: n.kind, info: fromLineInfo(n.info, ir, c))

  case n.kind
  of nkNone, nkEmpty, nkNilLit:
    discard
  of nkIdent:
    result.ident = fromIdent(LitId n.operand, ir, c)
  of nkSym:
    result.sym = fromSymNode(ir, c, pos = pos)
  of directIntLit:
    result.intVal = n.operand
  of externIntLit:
    result.intVal = ir.sh.integers[LitId n.operand]
  of nkStrLit..nkTripleStrLit:
    result.strVal = ir.sh.strings[LitId n.operand]
  of nkFloatLit..nkFloat128Lit:
    result.floatVal = ir.sh.floats[LitId n.operand]
  else:
    for son in sonsReadonly(ir, pos):
      result.sons.add fromTree(ir, c, son)

proc initDecoder*(c: var Context; cache: IdentCache; resolver: Resolver) =
  c.idents = cache
  c.resolver = resolver

proc irToModule*(n: PackedTree; module: PSym; c: var Context): PNode =
  c.thisModule = module.itemId.module
  result = fromTree(n, c)

proc unpackAllSymbols*(n: PackedTree; c: var Context; m: PSym): seq[PSym] =
  setLen result, n.sh.syms.len
  var i = 0
  for s in unpackSymbols(n, c, m):
    result[i] = s
    inc i
