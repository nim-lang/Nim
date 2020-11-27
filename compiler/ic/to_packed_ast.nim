#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [hashes, tables, md5, sequtils]
import packed_ast, bitabs, contexts
import ".." / [ast, idents, lineinfos, msgs, ropes, options, sighashes]

when not defined(release): import ".." / astalgo # debug()

type
  Context = PackedEncoder  # legacy name

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var Context)
proc toPackedSym(s: PSym; ir: var PackedTree; c: var Context): SymId
proc toPackedType(t: PType; ir: var PackedTree; c: var Context): TypeId
proc toPackedLib(l: PLib; ir: var PackedTree; c: var Context): PackedLib

proc safeItemId(s: PSym; ir: var PackedTree; c: var Context): ItemId =
  ## given a symbol, produce an ItemId with the correct properties
  ## for local or remote symbols, packing the symbol as necessary
  var id = if s.isNil: nilItemId else: s.itemId
  if id == nilItemId:
    discard
  elif id.module == c.thisModule:
    id.item = int32 toPackedSym(s, ir, c)
  else:
    id.item = int32 getOrIncl(ir.sh.strings, s.name.s)
  result = id

proc flush(ir: var PackedTree; c: var Context) =
  ## serialize any pending types or symbols from the context
  while true:
    if c.pendingTypes.len > 0:
      discard toPackedType(c.pendingTypes.pop, ir, c)
    elif c.pendingSyms.len > 0:
      discard toPackedSym(c.pendingSyms.pop, ir, c)
    else:
      break

proc toLitId(x: string; ir: var PackedTree; c: var Context): LitId =
  ## store a string as a literal
  result = getOrIncl(ir.sh.strings, x)

proc toLitId(x: BiggestInt; ir: var PackedTree; c: var Context): LitId =
  ## store an integer as a literal
  # i think smaller integers aren't worth putting into a table
  # because there they become 32bit hash values on the heap...
  result = getOrIncl(ir.sh.integers, x)

proc toLitId(x: FileIndex; ir: var PackedTree; c: var Context): LitId =
  ## store a file index as a literal
  if x == c.lastFile:
    result = c.lastLit
  else:
    result = c.filenames.getOrDefault(x)
    if result == LitId 0:
      let p = msgs.toFullPath(ir.sh.config, x)
      result = getOrIncl(ir.sh.strings, p)
      c.filenames[x] = result
    c.lastFile = x
    c.lastLit = result

proc toPackedInfo(x: TLineInfo; ir: var PackedTree;
                  c: var Context): PackedLineInfo =
  PackedLineInfo(line: x.line, col: x.col, file: toLitId(x.fileIndex, ir, c))

proc addModuleRef(n: PNode; ir: var PackedTree; c: var Context) =
  ## add a remote symbol reference to the tree
  let info = n.info.toPackedInfo(ir, c)
  ir.nodes.add PackedNode(kind: nkModuleRef, operand: 2.int32,  # 2 kids...
                          typeId: toPackedType(n.typ, ir, c), info: info)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: n.sym.itemId.module)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: int32 toLitId(n.sym.name.s, ir, c))

proc addMissing(c: var Context; p: PSym) =
  ## consider queuing a symbol for later addition to the packed tree
  if not p.isNil:
    # we do not pack foreign symbols
    if p.itemId.module == c.thisModule:
      if p.itemId notin c.symMap:
        c.pendingSyms.add p

proc addMissing(c: var Context; p: PType) =
  ## consider queuing a type for later addition to the packed tree
  if not p.isNil:
    # XXX: we DO pack foreign types (for now?), essentially copying them
    #      to make evaluation (much) easier
    #if p.uniqueId.module == c.thisModule:
    if p.uniqueId notin c.typeMap:
      c.pendingTypes.add p

proc toPackedType(t: PType; ir: var PackedTree; c: var Context): TypeId =
  ## serialize a ptype
  if t.isNil: return TypeId(-1)
  template info: PackedLineInfo =
    # too bad the most variant part of the operation comes first...
    (if t.n.isNil: TLineInfo() else: t.n.info).toPackedInfo(ir, c)

  # short-circuit if we already have the TypeId
  result = getOrDefault(c.typeMap, t.uniqueId, TypeId(-1))
  if result != TypeId(-1): return

  ir.sh.types.add:
    PackedType(kind: t.kind, flags: t.flags, info: info, callConv: t.callConv,
               size: t.size, align: t.align, nonUniqueId: t.uniqueId,
               paddingAtEnd: t.paddingAtEnd, lockLevel: t.lockLevel,
               node: newTreeFrom(ir))
  result = TypeId(ir.sh.types.high)
  c.typeMap[t.uniqueId] = result
  template p: PackedType = ir.sh.types[int result]

  for op, s in pairs t.attachedOps:
    c.addMissing s
    p.attachedOps[op] = s.safeItemId(ir, c)
  p.typeInst = t.typeInst.toPackedType(ir, c)
  for kid in items t.sons:
    p.types.add kid.toPackedType(ir, c)
  for i, s in items t.methods:
    c.addMissing s
    p.methods.add (i, s.safeItemId(ir, c))
  c.addMissing t.sym
  p.sym = t.sym.safeItemId(ir, c)
  c.addMissing t.owner
  p.owner = t.owner.safeItemId(ir, c)
  if not t.n.isNil:
    p.nodekind = t.n.kind
    p.nodeflags = t.n.flags
    t.n.toPackedNode(p.node, c)

  ir.flush c   # flush any pending types and symbols

proc toPackedSym(s: PSym; ir: var PackedTree; c: var Context): SymId =
  ## serialize a psym
  if s.isNil: return SymId(-1)
  template info: PackedLineInfo = s.info.toPackedInfo(ir, c)

  # short-circuit if we already have the SymId
  result = getOrDefault(c.symMap, s.itemId, SymId(-1))
  if result != SymId(-1): return

  ir.sh.syms.add:
    PackedSym(kind: s.kind, flags: s.flags, info: info, magic: s.magic,
              position: s.position, offset: s.offset, options: s.options,
              name: s.name.s.toLitId(ir, c),
              ast: newTreeFrom(ir), constraint: newTreeFrom(ir))
  result = SymId(ir.sh.syms.high)
  c.symMap[s.itemId] = result
  template p: PackedSym = ir.sh.syms[int result]

  if s.kind in {skLet, skVar, skField, skForVar}:
    c.addMissing s.guard
    p.guard = s.guard.safeItemId(ir, c)
    p.bitsize = s.bitsize
    p.alignment = s.alignment
  p.externalName = toLitId(if s.loc.r.isNil: "" else: $s.loc.r, ir, c)
  c.addMissing s.typ
  p.typeId = s.typ.toPackedType(ir, c)
  c.addMissing s.owner
  p.owner = s.owner.safeItemId(ir, c)
  p.annex = toPackedLib(s.annex, ir, c)
  s.constraint.toPackedNode(p.constraint, c)
  s.ast.toPackedNode(p.ast, c)
  when hasFFI:
    p.cname = toLitId(s.cname, ir, c)

  ir.flush c   # flush any pending types and symbols

proc toSymNode(n: PNode; ir: var PackedTree; c: var Context) =
  ## store a local or remote psym reference in the tree
  assert n.kind == nkSym
  template s: PSym = n.sym
  template info: PackedLineInfo = toPackedInfo(n.info, ir, c)
  var id = s.toPackedSym(ir, c)
  assert id != SymId(-1)
  if s.itemId.module == c.thisModule:
    # it is a symbol that belongs to the module we're currently
    # packing:
    ir.addSym(id, info)
  else:
    # store it as an external module reference:
    addModuleRef(n, ir, c)
  # we'll cache it in the local module in any event
  c.symMap[s.itemId] = id

proc toPackedLib(l: PLib; ir: var PackedTree; c: var Context): PackedLib =
  ## the plib hangs off the psym via the .annex field
  if l.isNil: return
  result.kind = l.kind
  result.generated = l.generated
  result.isOverriden = l.isOverriden
  result.name = toLitId($l.name, ir, c)
  result.path = newTreeFrom(ir)
  l.path.toPackedNode(result.path, c)

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var Context) =
  ## serialize a node into the tree
  if n.isNil: return
  let info = toPackedInfo(n.info, ir, c)
  case n.kind
  of nkNone, nkEmpty, nkNilLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags, operand: 0,
                            typeId: toPackedType(n.typ, ir, c), info: info)
  of nkIdent:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(ir.sh.strings, n.ident.s),
                            typeId: toPackedType(n.typ, ir, c), info: info)
  of nkSym:
    toSymNode(n, ir, c)
  of directIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32(n.intVal),
                            typeId: toPackedType(n.typ, ir, c), info: info)
  of externIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(ir.sh.integers, n.intVal),
                            typeId: toPackedType(n.typ, ir, c), info: info)
  of nkStrLit..nkTripleStrLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(ir.sh.strings, n.strVal),
                            typeId: toPackedType(n.typ, ir, c), info: info)
  of nkFloatLit..nkFloat128Lit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(ir.sh.floats, n.floatVal),
                            typeId: toPackedType(n.typ, ir, c), info: info)
  else:
    let patchPos = ir.prepare(n.kind, n.flags,
                              toPackedType(n.typ, ir, c), info)
    for i in 0..<n.len:
      toPackedNode(n[i], ir, c)
    ir.patch patchPos

  ir.flush c   # flush any pending types and symbols

proc initGenericKey*(s: PSym; types: seq[PType]): GenericKey =
  result.module = s.owner.itemId.module
  result.name = s.name.s
  result.types = mapIt types: hashType(it, {CoType, CoDistinct}).MD5Digest

proc addGeneric*(m: var Module; c: var Context; key: GenericKey; s: PSym) =
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
    template countLocal(c: Context; tab: typed): int =
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
