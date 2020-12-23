#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [hashes, tables, md5, sequtils]
import packed_ast, bitabs
import ".." / [ast, idents, lineinfos, msgs, ropes, options, sighashes]

when not defined(release): import ".." / astalgo # debug()

type
  PackedModule* = object ## the parts of a PackedEncoder that are part of the .rod file
    #name*: string
    topLevel*: PackedTree  # top level statements
    bodies*: PackedTree # other trees. Referenced from typ.n and sym.ast by their position.
    hidden*: PackedTree # instantiated generics and other trees not directly in the source code.
    #producedGenerics*: Table[GenericKey, SymId]

  PackedEncoder* = object
    m: PackedModule
    thisModule*: int32
    lastFile*: FileIndex # remember the last lookup entry.
    lastLit*: LitId
    filenames*: Table[FileIndex, LitId]
    pendingTypes*: seq[PType]
    pendingSyms*: seq[PSym]
    typeMap*: Table[ItemId, TypeId]  # ItemId.item -> TypeId
    symMap*: Table[ItemId, SymId]    # ItemId.item -> SymId
    sh: Shared
    config*: ConfigRef

proc initEncoder*(c: var PackedEncoder; m: PSym; config: ConfigRef) =
  ## setup a context for serializing to packed ast
  c.sh = Shared()
  c.thisModule = m.itemId.module
  c.config = config
  c.m.topLevel.sh = c.sh
  c.m.bodies = newTreeFrom(c.m.topLevel)
  c.m.hidden = newTreeFrom(c.m.topLevel)

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var PackedEncoder)
proc toPackedSym*(s: PSym; c: var PackedEncoder): SymId
proc toPackedType(t: PType; c: var PackedEncoder): TypeId

proc safeItemId(s: PSym): ItemId {.inline.} =
  ## given a symbol, produce an ItemId with the correct properties
  ## for local or remote symbols, packing the symbol as necessary
  if s == nil:
    result = nilItemId
  else:
    # XXX translate module IDs?
    result = s.itemId

proc flush(c: var PackedEncoder) =
  ## serialize any pending types or symbols from the context
  while true:
    if c.pendingTypes.len > 0:
      discard toPackedType(c.pendingTypes.pop, c)
    elif c.pendingSyms.len > 0:
      discard toPackedSym(c.pendingSyms.pop, c)
    else:
      break

proc toLitId(x: string; c: var PackedEncoder): LitId =
  ## store a string as a literal
  result = getOrIncl(c.sh.strings, x)

proc toLitId(x: BiggestInt; c: var PackedEncoder): LitId =
  ## store an integer as a literal
  result = getOrIncl(c.sh.integers, x)

proc toLitId(x: FileIndex; c: var PackedEncoder): LitId =
  ## store a file index as a literal
  if x == c.lastFile:
    result = c.lastLit
  else:
    result = c.filenames.getOrDefault(x)
    if result == LitId(0):
      let p = msgs.toFullPath(c.config, x)
      result = getOrIncl(c.sh.strings, p)
      c.filenames[x] = result
    c.lastFile = x
    c.lastLit = result

proc toPackedInfo(x: TLineInfo; c: var PackedEncoder): PackedLineInfo =
  PackedLineInfo(line: x.line, col: x.col, file: toLitId(x.fileIndex, c))

proc addModuleRef(n: PNode; ir: var PackedTree; c: var PackedEncoder) =
  ## add a remote symbol reference to the tree
  let info = n.info.toPackedInfo(c)
  ir.nodes.add PackedNode(kind: nkModuleRef, operand: 2.int32,  # 2 kids...
                          typeId: toPackedType(n.typ, c), info: info)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: n.sym.itemId.module)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: int32 toLitId(n.sym.name.s, c))

proc addMissing(c: var PackedEncoder; p: PSym) =
  ## consider queuing a symbol for later addition to the packed tree
  if not p.isNil:
    # we do not pack foreign symbols
    if p.itemId.module == c.thisModule:
      if p.itemId notin c.symMap:
        c.pendingSyms.add p

proc addMissing(c: var PackedEncoder; p: PType) =
  ## consider queuing a type for later addition to the packed tree
  if not p.isNil:
    # XXX: we DO pack foreign types (for now?), essentially copying them
    #      to make evaluation (much) easier
    #if p.uniqueId.module == c.thisModule:
    if p.uniqueId notin c.typeMap:
      c.pendingTypes.add p

template storeNode(dest, src, field) =
  var nodeId: NodeId
  if src.field != nil:
    nodeId = getNodeId(c.m.bodies)
    toPackedNode(src.field, c.m.bodies, c)
  else:
    nodeId = emptyNodeId
  dest.field = nodeId

proc toPackedType(t: PType; c: var PackedEncoder): TypeId =
  ## serialize a ptype
  if t.isNil: return TypeId(-1)

  # short-circuit if we already have the TypeId
  result = getOrDefault(c.typeMap, t.uniqueId, TypeId(-1))
  if result != TypeId(-1): return result

  result = TypeId(c.sh.types.len)
  c.typeMap[t.uniqueId] = result
  # reserve the slot already:
  setLen c.sh.types, result.int+1

  var p = PackedType(kind: t.kind, flags: t.flags, callConv: t.callConv,
    size: t.size, align: t.align, uniqueId: t.uniqueId,
    paddingAtEnd: t.paddingAtEnd, lockLevel: t.lockLevel)
  # XXX if p.itemId.module == c.thisModule:
  storeNode(p, t, n)

  for op, s in pairs t.attachedOps:
    c.addMissing s
    p.attachedOps[op] = s.safeItemId

  p.typeInst = t.typeInst.toPackedType(c)
  for kid in items t.sons:
    p.types.add kid.toPackedType(c)
  for i, s in items t.methods:
    c.addMissing s
    p.methods.add (i, s.safeItemId)
  c.addMissing t.sym
  p.sym = t.sym.safeItemId
  c.addMissing t.owner
  p.owner = t.owner.safeItemId

  # fill the reserved slot, nothing else:
  c.sh.types[int result] = p

proc toPackedLib(l: PLib; c: var PackedEncoder): PackedLib =
  ## the plib hangs off the psym via the .annex field
  if l.isNil: return
  result.kind = l.kind
  result.generated = l.generated
  result.isOverriden = l.isOverriden
  result.name = toLitId($l.name, c)
  storeNode(result, l, path)

proc toPackedSym*(s: PSym; c: var PackedEncoder): SymId =
  ## serialize a psym
  if s.isNil: return SymId(-1)

  # short-circuit if we already have the SymId
  result = getOrDefault(c.symMap, s.itemId, SymId(-1))
  if result != SymId(-1): return result

  result = SymId(c.sh.syms.len)
  c.symMap[s.itemId] = result
  # reserve the slot already:
  setLen c.sh.syms, result.int+1

  var p = PackedSym(kind: s.kind, flags: s.flags, info: s.info.toPackedInfo(c), magic: s.magic,
    position: s.position, offset: s.offset, options: s.options,
    name: s.name.s.toLitId(c))

  storeNode(p, s, ast)
  storeNode(p, s, constraint)

  if s.kind in {skLet, skVar, skField, skForVar}:
    c.addMissing s.guard
    p.guard = s.guard.safeItemId
    p.bitsize = s.bitsize
    p.alignment = s.alignment

  p.externalName = toLitId(if s.loc.r.isNil: "" else: $s.loc.r, c)
  c.addMissing s.typ
  p.typ = s.typ.toPackedType(c)
  c.addMissing s.owner
  p.owner = s.owner.safeItemId
  p.annex = toPackedLib(s.annex, c)
  when hasFFI:
    p.cname = toLitId(s.cname, c)

  # fill the reserved slot, nothing else:
  c.sh.syms[int result] = p

proc toSymNode(n: PNode; ir: var PackedTree; c: var PackedEncoder) =
  ## store a local or remote psym reference in the tree
  assert n.kind == nkSym
  template s: PSym = n.sym
  var id = s.toPackedSym(c)
  assert id != SymId(-1)
  if s.itemId.module == c.thisModule:
    # it is a symbol that belongs to the module we're currently
    # packing:
    ir.addSym(id, toPackedInfo(n.info, c))
  else:
    # store it as an external module reference:
    addModuleRef(n, ir, c)

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var PackedEncoder) =
  ## serialize a node into the tree
  if n.isNil: return
  let info = toPackedInfo(n.info, c)
  case n.kind
  of nkNone, nkEmpty, nkNilLit, nkType:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags, operand: 0,
                            typeId: toPackedType(n.typ, c), info: info)
  of nkIdent:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(c.sh.strings, n.ident.s),
                            typeId: toPackedType(n.typ, c), info: info)
  of nkSym:
    toSymNode(n, ir, c)
  of directIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32(n.intVal),
                            typeId: toPackedType(n.typ, c), info: info)
  of externIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(c.sh.integers, n.intVal),
                            typeId: toPackedType(n.typ, c), info: info)
  of nkStrLit..nkTripleStrLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(c.sh.strings, n.strVal),
                            typeId: toPackedType(n.typ, c), info: info)
  of nkFloatLit..nkFloat128Lit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(c.sh.floats, n.floatVal),
                            typeId: toPackedType(n.typ, c), info: info)
  else:
    let patchPos = ir.prepare(n.kind, n.flags,
                              toPackedType(n.typ, c), info)
    for i in 0..<n.len:
      toPackedNode(n[i], ir, c)
    ir.patch patchPos

  when false:
    ir.flush c   # flush any pending types and symbols

proc toPackedNodeTopLevel*(n: PNode, encoder: var PackedEncoder) =
  toPackedNode(n, encoder.m.topLevel, encoder)
  flush encoder

proc saveRodFile*(filename: string; encoder: var PackedEncoder) =
  discard

when false:
  proc initGenericKey*(s: PSym; types: seq[PType]): GenericKey =
    result.module = s.owner.itemId.module
    result.name = s.name.s
    result.types = mapIt types: hashType(it, {CoType, CoDistinct}).MD5Digest

  proc addGeneric*(m: var Module; c: var PackedEncoder; key: GenericKey; s: PSym) =
    ## add a generic to the module
    if key notin m.generics:
      m.generics[key] = toPackedSym(s, m.ast, c)
      toPackedNode(s.ast, m.ast, c)

  proc moduleToIr*(n: PNode; ir: var PackedTree; module: PSym) =
    ## serialize a module into packed ast
    var c: PackedEncoder
    initEncoder(c, module)
    toPackedNode(n, ir, c)

    when not defined(release):
      var local: int
      template countLocal(c: PackedEncoder; tab: typed): int =
        var local = 0
        for item, sym in pairs tab:
          if item.module == c.thisModule:
            inc local
        local

      echo "     module id: ", c.thisModule
      echo "       symbols: ", ir.sh.syms.len
      local = c.countLocal c.symMap
      echo "                local: ", local
      echo "               remote: ", ir.sh.syms.len - local
      echo "         types: ", ir.sh.types.len
      local = c.countLocal c.typeMap
      echo "                local: ", local
      echo "               remote: ", ir.sh.types.len - local
      echo "         nodes: ", ir.nodes.len
      echo "float literals: ", ir.sh.floats.len
      echo "  int literals: ", ir.sh.integers.len
      echo "  str literals: ", ir.sh.strings.len
      debug ir
      echo ""
    assert c.pendingTypes.len == 0
    assert c.pendingSyms.len == 0
