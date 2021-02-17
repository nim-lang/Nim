#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [hashes, tables, intsets, sha1]
import packed_ast, bitabs, rodfiles
import ".." / [ast, idents, lineinfos, msgs, ropes, options,
  pathutils, condsyms]

from std / os import removeFile, isAbsolute

type
  PackedConfig* = object
    backend: TBackend
    selectedGC: TGCMode
    cCompiler: TSystemCC
    options: TOptions
    globalOptions: TGlobalOptions

  PackedModule* = object ## the parts of a PackedEncoder that are part of the .rod file
    definedSymbols: string
    includes: seq[(LitId, string)] # first entry is the module filename itself
    imports: seq[LitId] # the modules this module depends on
    toReplay: PackedTree # pragmas and VM specific state to replay.
    topLevel*: PackedTree  # top level statements
    bodies*: PackedTree # other trees. Referenced from typ.n and sym.ast by their position.
    #producedGenerics*: Table[GenericKey, SymId]
    exports*: seq[(LitId, int32)]
    reexports*: seq[(LitId, PackedItemId)]
    compilerProcs*: seq[(LitId, int32)]
    converters*, methods*, trmacros*, pureEnums*: seq[int32]
    macroUsages*: seq[(PackedItemId, PackedLineInfo)]

    typeInstCache*: seq[(PackedItemId, PackedItemId)]
    procInstCache*: seq[PackedInstantiation]
    attachedOps*: seq[(TTypeAttachedOp, PackedItemId, PackedItemId)]
    methodsPerType*: seq[(PackedItemId, int, PackedItemId)]
    enumToStringProcs*: seq[(PackedItemId, PackedItemId)]

    sh*: Shared
    cfg: PackedConfig

  PackedEncoder* = object
    #m*: PackedModule
    thisModule*: int32
    lastFile*: FileIndex # remember the last lookup entry.
    lastLit*: LitId
    filenames*: Table[FileIndex, LitId]
    pendingTypes*: seq[PType]
    pendingSyms*: seq[PSym]
    typeMarker*: IntSet #Table[ItemId, TypeId]  # ItemId.item -> TypeId
    symMarker*: IntSet #Table[ItemId, SymId]    # ItemId.item -> SymId
    config*: ConfigRef

template primConfigFields(fn: untyped) {.dirty.} =
  fn backend
  fn selectedGC
  fn cCompiler
  fn options
  fn globalOptions

proc definedSymbolsAsString(config: ConfigRef): string =
  result = newStringOfCap(200)
  result.add "config"
  for d in definedSymbolNames(config.symbols):
    result.add ' '
    result.add d

proc rememberConfig(c: var PackedEncoder; m: var PackedModule; config: ConfigRef; pc: PackedConfig) =
  m.definedSymbols = definedSymbolsAsString(config)
  #template rem(x) =
  #  c.m.cfg.x = config.x
  #primConfigFields rem
  m.cfg = pc

proc configIdentical(m: PackedModule; config: ConfigRef): bool =
  result = m.definedSymbols == definedSymbolsAsString(config)
  #if not result:
  #  echo "A ", m.definedSymbols, " ", definedSymbolsAsString(config)
  template eq(x) =
    result = result and m.cfg.x == config.x
    #if not result:
    #  echo "B ", m.cfg.x, " ", config.x
  primConfigFields eq

proc rememberStartupConfig*(dest: var PackedConfig, config: ConfigRef) =
  template rem(x) =
    dest.x = config.x
  primConfigFields rem

proc hashFileCached(conf: ConfigRef; fileIdx: FileIndex): string =
  result = msgs.getHash(conf, fileIdx)
  if result.len == 0:
    let fullpath = msgs.toFullPath(conf, fileIdx)
    result = $secureHashFile(fullpath)
    msgs.setHash(conf, fileIdx, result)

proc toLitId(x: FileIndex; c: var PackedEncoder; m: var PackedModule): LitId =
  ## store a file index as a literal
  if x == c.lastFile:
    result = c.lastLit
  else:
    result = c.filenames.getOrDefault(x)
    if result == LitId(0):
      let p = msgs.toFullPath(c.config, x)
      result = getOrIncl(m.sh.strings, p)
      c.filenames[x] = result
    c.lastFile = x
    c.lastLit = result
    assert result != LitId(0)

proc toFileIndex*(x: LitId; m: PackedModule; config: ConfigRef): FileIndex =
  result = msgs.fileInfoIdx(config, AbsoluteFile m.sh.strings[x])

proc includesIdentical(m: var PackedModule; config: ConfigRef): bool =
  for it in mitems(m.includes):
    if hashFileCached(config, toFileIndex(it[0], m, config)) != it[1]:
      return false
  result = true

proc initEncoder*(c: var PackedEncoder; m: var PackedModule; moduleSym: PSym; config: ConfigRef; pc: PackedConfig) =
  ## setup a context for serializing to packed ast
  m.sh = Shared()
  c.thisModule = moduleSym.itemId.module
  c.config = config
  m.bodies = newTreeFrom(m.topLevel)
  m.toReplay = newTreeFrom(m.topLevel)

  let thisNimFile = FileIndex c.thisModule
  var h = msgs.getHash(config, thisNimFile)
  if h.len == 0:
    let fullpath = msgs.toFullPath(config, thisNimFile)
    if isAbsolute(fullpath):
      # For NimScript compiler API support the main Nim file might be from a stream.
      h = $secureHashFile(fullpath)
      msgs.setHash(config, thisNimFile, h)
  m.includes.add((toLitId(thisNimFile, c, m), h)) # the module itself

  rememberConfig(c, m, config, pc)

proc addIncludeFileDep*(c: var PackedEncoder; m: var PackedModule; f: FileIndex) =
  m.includes.add((toLitId(f, c, m), hashFileCached(c.config, f)))

proc addImportFileDep*(c: var PackedEncoder; m: var PackedModule; f: FileIndex) =
  m.imports.add toLitId(f, c, m)

proc addExported*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  let nameId = getOrIncl(m.sh.strings, s.name.s)
  m.exports.add((nameId, s.itemId.item))

proc addConverter*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  m.converters.add(s.itemId.item)

proc addTrmacro*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  m.trmacros.add(s.itemId.item)

proc addPureEnum*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  assert s.kind == skType
  m.pureEnums.add(s.itemId.item)

proc addMethod*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  m.methods.add s.itemId.item

proc addReexport*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  let nameId = getOrIncl(m.sh.strings, s.name.s)
  m.reexports.add((nameId, PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m),
                                        item: s.itemId.item)))

proc addCompilerProc*(c: var PackedEncoder; m: var PackedModule; s: PSym) =
  let nameId = getOrIncl(m.sh.strings, s.name.s)
  m.compilerProcs.add((nameId, s.itemId.item))

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var PackedEncoder; m: var PackedModule)
proc storeSym*(s: PSym; c: var PackedEncoder; m: var PackedModule): PackedItemId
proc storeType(t: PType; c: var PackedEncoder; m: var PackedModule): PackedItemId

proc flush(c: var PackedEncoder; m: var PackedModule) =
  ## serialize any pending types or symbols from the context
  while true:
    if c.pendingTypes.len > 0:
      discard storeType(c.pendingTypes.pop, c, m)
    elif c.pendingSyms.len > 0:
      discard storeSym(c.pendingSyms.pop, c, m)
    else:
      break

proc toLitId(x: string; m: var PackedModule): LitId =
  ## store a string as a literal
  result = getOrIncl(m.sh.strings, x)

proc toLitId(x: BiggestInt; m: var PackedModule): LitId =
  ## store an integer as a literal
  result = getOrIncl(m.sh.integers, x)

proc toPackedInfo(x: TLineInfo; c: var PackedEncoder; m: var PackedModule): PackedLineInfo =
  PackedLineInfo(line: x.line, col: x.col, file: toLitId(x.fileIndex, c, m))

proc safeItemId(s: PSym; c: var PackedEncoder; m: var PackedModule): PackedItemId {.inline.} =
  ## given a symbol, produce an ItemId with the correct properties
  ## for local or remote symbols, packing the symbol as necessary
  if s == nil or s.kind == skPackage:
    result = nilItemId
  #elif s.itemId.module == c.thisModule:
  #  result = PackedItemId(module: LitId(0), item: s.itemId.item)
  else:
    assert int(s.itemId.module) >= 0
    result = PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m),
                          item: s.itemId.item)

proc addMissing(c: var PackedEncoder; p: PSym) =
  ## consider queuing a symbol for later addition to the packed tree
  if p != nil and p.itemId.module == c.thisModule:
    if p.itemId.item notin c.symMarker:
      c.pendingSyms.add p

proc addMissing(c: var PackedEncoder; p: PType) =
  ## consider queuing a type for later addition to the packed tree
  if p != nil and p.uniqueId.module == c.thisModule:
    if p.uniqueId.item notin c.typeMarker:
      c.pendingTypes.add p

template storeNode(dest, src, field) =
  var nodeId: NodeId
  if src.field != nil:
    nodeId = getNodeId(m.bodies)
    toPackedNode(src.field, m.bodies, c, m)
  else:
    nodeId = emptyNodeId
  dest.field = nodeId

proc storeTypeLater(t: PType; c: var PackedEncoder; m: var PackedModule): PackedItemId =
  # We store multiple different trees in m.bodies. For this to work out, we
  # cannot immediately store types/syms. We enqueue them instead to ensure
  # we only write one tree into m.bodies after the other.
  if t.isNil: return nilItemId

  if t.uniqueId.module != c.thisModule:
    # XXX Assert here that it already was serialized in the foreign module!
    # it is a foreign type:
    assert t.uniqueId.module >= 0
    assert t.uniqueId.item > 0
    return PackedItemId(module: toLitId(t.uniqueId.module.FileIndex, c, m), item: t.uniqueId.item)
  assert t.itemId.module >= 0
  assert t.uniqueId.item > 0
  result = PackedItemId(module: toLitId(t.itemId.module.FileIndex, c, m), item: t.uniqueId.item)
  addMissing(c, t)

proc storeSymLater(s: PSym; c: var PackedEncoder; m: var PackedModule): PackedItemId =
  if s.isNil: return nilItemId
  assert s.itemId.module >= 0
  if s.itemId.module != c.thisModule:
    # XXX Assert here that it already was serialized in the foreign module!
    # it is a foreign symbol:
    assert s.itemId.module >= 0
    return PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m), item: s.itemId.item)
  assert s.itemId.module >= 0
  result = PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m), item: s.itemId.item)
  addMissing(c, s)

proc storeType(t: PType; c: var PackedEncoder; m: var PackedModule): PackedItemId =
  ## serialize a ptype
  if t.isNil: return nilItemId

  if t.uniqueId.module != c.thisModule:
    # XXX Assert here that it already was serialized in the foreign module!
    # it is a foreign type:
    assert t.uniqueId.module >= 0
    assert t.uniqueId.item > 0
    return PackedItemId(module: toLitId(t.uniqueId.module.FileIndex, c, m), item: t.uniqueId.item)

  if not c.typeMarker.containsOrIncl(t.uniqueId.item):
    if t.uniqueId.item >= m.sh.types.len:
      setLen m.sh.types, t.uniqueId.item+1

    var p = PackedType(kind: t.kind, flags: t.flags, callConv: t.callConv,
      size: t.size, align: t.align, nonUniqueId: t.itemId.item,
      paddingAtEnd: t.paddingAtEnd, lockLevel: t.lockLevel)
    storeNode(p, t, n)

    when false:
      for op, s in pairs t.attachedOps:
        c.addMissing s
        p.attachedOps[op] = s.safeItemId(c, m)

    p.typeInst = t.typeInst.storeType(c, m)
    for kid in items t.sons:
      p.types.add kid.storeType(c, m)

    when false:
      for i, s in items t.methods:
        c.addMissing s
        p.methods.add (i, s.safeItemId(c, m))
    c.addMissing t.sym
    p.sym = t.sym.safeItemId(c, m)
    c.addMissing t.owner
    p.owner = t.owner.safeItemId(c, m)

    # fill the reserved slot, nothing else:
    m.sh.types[t.uniqueId.item] = p

  assert t.itemId.module >= 0
  assert t.uniqueId.item > 0
  result = PackedItemId(module: toLitId(t.itemId.module.FileIndex, c, m), item: t.uniqueId.item)

proc toPackedLib(l: PLib; c: var PackedEncoder; m: var PackedModule): PackedLib =
  ## the plib hangs off the psym via the .annex field
  if l.isNil: return
  result.kind = l.kind
  result.generated = l.generated
  result.isOverriden = l.isOverriden
  result.name = toLitId($l.name, m)
  storeNode(result, l, path)

proc storeSym*(s: PSym; c: var PackedEncoder; m: var PackedModule): PackedItemId =
  ## serialize a psym
  if s.isNil: return nilItemId

  assert s.itemId.module >= 0

  if s.itemId.module != c.thisModule:
    # XXX Assert here that it already was serialized in the foreign module!
    # it is a foreign symbol:
    assert s.itemId.module >= 0
    return PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m), item: s.itemId.item)

  if not c.symMarker.containsOrIncl(s.itemId.item):
    if s.itemId.item >= m.sh.syms.len:
      setLen m.sh.syms, s.itemId.item+1

    var p = PackedSym(kind: s.kind, flags: s.flags, info: s.info.toPackedInfo(c, m), magic: s.magic,
      position: s.position, offset: s.offset, options: s.options,
      name: s.name.s.toLitId(m))

    storeNode(p, s, ast)
    storeNode(p, s, constraint)

    if s.kind in {skLet, skVar, skField, skForVar}:
      c.addMissing s.guard
      p.guard = s.guard.safeItemId(c, m)
      p.bitsize = s.bitsize
      p.alignment = s.alignment

    p.externalName = toLitId(if s.loc.r.isNil: "" else: $s.loc.r, m)
    p.locFlags = s.loc.flags
    c.addMissing s.typ
    p.typ = s.typ.storeType(c, m)
    c.addMissing s.owner
    p.owner = s.owner.safeItemId(c, m)
    p.annex = toPackedLib(s.annex, c, m)
    when hasFFI:
      p.cname = toLitId(s.cname, m)

    # fill the reserved slot, nothing else:
    m.sh.syms[s.itemId.item] = p

  assert s.itemId.module >= 0
  result = PackedItemId(module: toLitId(s.itemId.module.FileIndex, c, m), item: s.itemId.item)

proc addModuleRef(n: PNode; ir: var PackedTree; c: var PackedEncoder; m: var PackedModule) =
  ## add a remote symbol reference to the tree
  let info = n.info.toPackedInfo(c, m)
  ir.nodes.add PackedNode(kind: nkModuleRef, operand: 3.int32, # spans 3 nodes in total
                          typeId: storeTypeLater(n.typ, c, m), info: info)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: toLitId(n.sym.itemId.module.FileIndex, c, m).int32)
  ir.nodes.add PackedNode(kind: nkInt32Lit, info: info,
                          operand: n.sym.itemId.item)

proc toPackedNode*(n: PNode; ir: var PackedTree; c: var PackedEncoder; m: var PackedModule) =
  ## serialize a node into the tree
  if n == nil:
    ir.nodes.add PackedNode(kind: nkNilRodNode, flags: {}, operand: 1)
    return
  let info = toPackedInfo(n.info, c, m)
  case n.kind
  of nkNone, nkEmpty, nkNilLit, nkType:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags, operand: 0,
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  of nkIdent:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(m.sh.strings, n.ident.s),
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  of nkSym:
    if n.sym.itemId.module == c.thisModule:
      # it is a symbol that belongs to the module we're currently
      # packing:
      let id = n.sym.storeSymLater(c, m).item
      ir.nodes.add PackedNode(kind: nkSym, flags: n.flags, operand: id,
                              typeId: storeTypeLater(n.typ, c, m), info: info)
    else:
      # store it as an external module reference:
      addModuleRef(n, ir, c, m)
  of directIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32(n.intVal),
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  of externIntLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(m.sh.integers, n.intVal),
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  of nkStrLit..nkTripleStrLit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(m.sh.strings, n.strVal),
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  of nkFloatLit..nkFloat128Lit:
    ir.nodes.add PackedNode(kind: n.kind, flags: n.flags,
                            operand: int32 getOrIncl(m.sh.floats, n.floatVal),
                            typeId: storeTypeLater(n.typ, c, m), info: info)
  else:
    let patchPos = ir.prepare(n.kind, n.flags,
                              storeTypeLater(n.typ, c, m), info)
    for i in 0..<n.len:
      toPackedNode(n[i], ir, c, m)
    ir.patch patchPos

proc storeInstantiation*(c: var PackedEncoder; m: var PackedModule; s: PSym; i: PInstantiation) =
  var t = newSeq[PackedItemId](i.concreteTypes.len)
  for j in 0..high(i.concreteTypes):
    t[j] = storeTypeLater(i.concreteTypes[j], c, m)
  m.procInstCache.add PackedInstantiation(key: storeSymLater(s, c, m),
                                          sym: storeSymLater(i.sym, c, m),
                                          concreteTypes: t)

proc storeTypeInst*(c: var PackedEncoder; m: var PackedModule; s: PSym; inst: PType) =
  m.typeInstCache.add (storeSymLater(s, c, m), storeTypeLater(inst, c, m))

proc addPragmaComputation*(c: var PackedEncoder; m: var PackedModule; n: PNode) =
  toPackedNode(n, m.toReplay, c, m)

proc toPackedNodeIgnoreProcDefs(n: PNode, encoder: var PackedEncoder; m: var PackedModule) =
  case n.kind
  of routineDefs:
    # we serialize n[namePos].sym instead
    if n[namePos].kind == nkSym:
      discard storeSym(n[namePos].sym, encoder, m)
    else:
      toPackedNode(n, m.topLevel, encoder, m)
  of nkStmtList, nkStmtListExpr:
    for it in n:
      toPackedNodeIgnoreProcDefs(it, encoder, m)
  else:
    toPackedNode(n, m.topLevel, encoder, m)

proc toPackedNodeTopLevel*(n: PNode, encoder: var PackedEncoder; m: var PackedModule) =
  toPackedNodeIgnoreProcDefs(n, encoder, m)
  flush encoder, m

proc loadError(err: RodFileError; filename: AbsoluteFile) =
  echo "Error: ", $err, " loading file: ", filename.string

proc loadRodFile*(filename: AbsoluteFile; m: var PackedModule; config: ConfigRef): RodFileError =
  m.sh = Shared()
  var f = rodfiles.open(filename.string)
  f.loadHeader()
  f.loadSection configSection

  f.loadPrim m.definedSymbols
  f.loadPrim m.cfg

  if f.err == ok and not configIdentical(m, config):
    f.err = configMismatch

  template loadSeqSection(section, data) {.dirty.} =
    f.loadSection section
    f.loadSeq data

  template loadTabSection(section, data) {.dirty.} =
    f.loadSection section
    f.load data

  loadTabSection stringsSection, m.sh.strings

  loadSeqSection checkSumsSection, m.includes
  if not includesIdentical(m, config):
    f.err = includeFileChanged

  loadSeqSection depsSection, m.imports

  loadTabSection integersSection, m.sh.integers
  loadTabSection floatsSection, m.sh.floats

  loadSeqSection exportsSection, m.exports

  loadSeqSection reexportsSection, m.reexports

  loadSeqSection compilerProcsSection, m.compilerProcs

  loadSeqSection trmacrosSection, m.trmacros

  loadSeqSection convertersSection, m.converters
  loadSeqSection methodsSection, m.methods
  loadSeqSection pureEnumsSection, m.pureEnums
  loadSeqSection macroUsagesSection, m.macroUsages

  loadSeqSection toReplaySection, m.toReplay.nodes
  loadSeqSection topLevelSection, m.topLevel.nodes
  loadSeqSection bodiesSection, m.bodies.nodes
  loadSeqSection symsSection, m.sh.syms
  loadSeqSection typesSection, m.sh.types

  loadSeqSection typeInstCacheSection, m.typeInstCache
  loadSeqSection procInstCacheSection, m.procInstCache
  loadSeqSection attachedOpsSection, m.attachedOps
  loadSeqSection methodsPerTypeSection, m.methodsPerType
  loadSeqSection enumToStringProcsSection, m.enumToStringProcs

  close(f)
  result = f.err

# -------------------------------------------------------------------------

proc storeError(err: RodFileError; filename: AbsoluteFile) =
  echo "Error: ", $err, "; couldn't write to ", filename.string
  removeFile(filename.string)

proc saveRodFile*(filename: AbsoluteFile; encoder: var PackedEncoder; m: var PackedModule) =
  #rememberConfig(encoder, encoder.config)

  var f = rodfiles.create(filename.string)
  f.storeHeader()
  f.storeSection configSection
  f.storePrim m.definedSymbols
  f.storePrim m.cfg

  template storeSeqSection(section, data) {.dirty.} =
    f.storeSection section
    f.storeSeq data

  template storeTabSection(section, data) {.dirty.} =
    f.storeSection section
    f.store data

  storeTabSection stringsSection, m.sh.strings

  storeSeqSection checkSumsSection, m.includes

  storeSeqSection depsSection, m.imports

  storeTabSection integersSection, m.sh.integers
  storeTabSection floatsSection, m.sh.floats

  storeSeqSection exportsSection, m.exports

  storeSeqSection reexportsSection, m.reexports

  storeSeqSection compilerProcsSection, m.compilerProcs

  storeSeqSection trmacrosSection, m.trmacros
  storeSeqSection convertersSection, m.converters
  storeSeqSection methodsSection, m.methods
  storeSeqSection pureEnumsSection, m.pureEnums
  storeSeqSection macroUsagesSection, m.macroUsages

  storeSeqSection toReplaySection, m.toReplay.nodes
  storeSeqSection topLevelSection, m.topLevel.nodes

  storeSeqSection bodiesSection, m.bodies.nodes
  storeSeqSection symsSection, m.sh.syms

  storeSeqSection typesSection, m.sh.types

  storeSeqSection typeInstCacheSection, m.typeInstCache
  storeSeqSection procInstCacheSection, m.procInstCache
  storeSeqSection attachedOpsSection, m.attachedOps
  storeSeqSection methodsPerTypeSection, m.methodsPerType
  storeSeqSection enumToStringProcsSection, m.enumToStringProcs

  close(f)
  if f.err != ok:
    storeError(f.err, filename)

  when false:
    # basic loader testing:
    var m2: PackedModule
    discard loadRodFile(filename, m2, encoder.config)
    echo "loaded ", filename.string

# ----------------------------------------------------------------------------

type
  PackedDecoder* = object
    lastModule: int
    lastLit: LitId
    lastFile: FileIndex # remember the last lookup entry.
    config*: ConfigRef
    cache*: IdentCache

type
  ModuleStatus* = enum
    undefined,
    storing,  # state is strictly for stress-testing purposes
    loading,
    loaded,
    outdated

  LoadedModule* = object
    status*: ModuleStatus
    symsInit, typesInit: bool
    fromDisk*: PackedModule
    syms: seq[PSym] # indexed by itemId
    types: seq[PType]
    module*: PSym # the one true module symbol.
    iface: Table[PIdent, seq[PackedItemId]] # PackedItemId so that it works with reexported symbols too

  PackedModuleGraph* = seq[LoadedModule] # indexed by FileIndex

proc loadType(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int; t: PackedItemId): PType
proc loadSym(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int; s: PackedItemId): PSym

proc toFileIndexCached*(c: var PackedDecoder; g: PackedModuleGraph; thisModule: int; f: LitId): FileIndex =
  if c.lastLit == f and c.lastModule == thisModule:
    result = c.lastFile
  else:
    result = toFileIndex(f, g[thisModule].fromDisk, c.config)
    c.lastModule = thisModule
    c.lastLit = f
    c.lastFile = result

proc translateLineInfo(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int;
                       x: PackedLineInfo): TLineInfo =
  assert g[thisModule].status in {loaded, storing}
  result = TLineInfo(line: x.line, col: x.col,
            fileIndex: toFileIndexCached(c, g, thisModule, x.file))

proc loadNodes*(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int;
                tree: PackedTree; n: NodePos): PNode =
  let k = n.kind
  if k == nkNilRodNode:
    return nil
  when false:
    echo "loading node ", c.config $ translateLineInfo(c, g, thisModule, n.info)
  result = newNodeIT(k, translateLineInfo(c, g, thisModule, n.info),
    loadType(c, g, thisModule, n.typ))
  result.flags = n.flags

  case k
  of nkEmpty, nkNilLit, nkType:
    discard
  of nkIdent:
    result.ident = getIdent(c.cache, g[thisModule].fromDisk.sh.strings[n.litId])
  of nkSym:
    result.sym = loadSym(c, g, thisModule, PackedItemId(module: LitId(0), item: tree.nodes[n.int].operand))
  of directIntLit:
    result.intVal = tree.nodes[n.int].operand
  of externIntLit:
    result.intVal = g[thisModule].fromDisk.sh.integers[n.litId]
  of nkStrLit..nkTripleStrLit:
    result.strVal = g[thisModule].fromDisk.sh.strings[n.litId]
  of nkFloatLit..nkFloat128Lit:
    result.floatVal = g[thisModule].fromDisk.sh.floats[n.litId]
  of nkModuleRef:
    let (n1, n2) = sons2(tree, n)
    assert n1.kind == nkInt32Lit
    assert n2.kind == nkInt32Lit
    transitionNoneToSym(result)
    result.sym = loadSym(c, g, thisModule, PackedItemId(module: n1.litId, item: tree.nodes[n2.int].operand))
  else:
    for n0 in sonsReadonly(tree, n):
      result.addAllowNil loadNodes(c, g, thisModule, tree, n0)

proc initPackedDecoder*(config: ConfigRef; cache: IdentCache): PackedDecoder =
  result = PackedDecoder(
    lastModule: int32(-1),
    lastLit: LitId(0),
    lastFile: FileIndex(-1),
    config: config,
    cache: cache)

proc loadProcHeader(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int;
                    tree: PackedTree; n: NodePos): PNode =
  # do not load the body of the proc. This will be done later in
  # getProcBody, if required.
  let k = n.kind
  result = newNodeIT(k, translateLineInfo(c, g, thisModule, n.info),
    loadType(c, g, thisModule, n.typ))
  result.flags = n.flags
  assert k in {nkProcDef, nkMethodDef, nkIteratorDef, nkFuncDef, nkConverterDef}
  var i = 0
  for n0 in sonsReadonly(tree, n):
    if i != bodyPos:
      result.add loadNodes(c, g, thisModule, tree, n0)
    else:
      result.addAllowNil nil
    inc i

proc loadProcBody(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int;
                  tree: PackedTree; n: NodePos): PNode =
  var i = 0
  for n0 in sonsReadonly(tree, n):
    if i == bodyPos:
      result = loadNodes(c, g, thisModule, tree, n0)
    inc i

proc moduleIndex*(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int;
                  s: PackedItemId): int32 {.inline.} =
  result = if s.module == LitId(0): thisModule.int32
           else: toFileIndexCached(c, g, thisModule, s.module).int32

proc symHeaderFromPacked(c: var PackedDecoder; g: var PackedModuleGraph;
                         s: PackedSym; si, item: int32): PSym =
  result = PSym(itemId: ItemId(module: si, item: item),
    kind: s.kind, magic: s.magic, flags: s.flags,
    info: translateLineInfo(c, g, si, s.info),
    options: s.options,
    position: s.position,
    name: getIdent(c.cache, g[si].fromDisk.sh.strings[s.name])
  )

template loadAstBody(p, field) =
  if p.field != emptyNodeId:
    result.field = loadNodes(c, g, si, g[si].fromDisk.bodies, NodePos p.field)

template loadAstBodyLazy(p, field) =
  if p.field != emptyNodeId:
    result.field = loadProcHeader(c, g, si, g[si].fromDisk.bodies, NodePos p.field)

proc loadLib(c: var PackedDecoder; g: var PackedModuleGraph;
             si, item: int32; l: PackedLib): PLib =
  # XXX: hack; assume a zero LitId means the PackedLib is all zero (empty)
  if l.name.int == 0:
    result = nil
  else:
    result = PLib(generated: l.generated, isOverriden: l.isOverriden,
                  kind: l.kind, name: rope g[si].fromDisk.sh.strings[l.name])
    loadAstBody(l, path)

proc symBodyFromPacked(c: var PackedDecoder; g: var PackedModuleGraph;
                       s: PackedSym; si, item: int32; result: PSym) =
  result.typ = loadType(c, g, si, s.typ)
  loadAstBody(s, constraint)
  if result.kind in {skProc, skFunc, skIterator, skConverter, skMethod}:
    loadAstBodyLazy(s, ast)
  else:
    loadAstBody(s, ast)
  result.annex = loadLib(c, g, si, item, s.annex)
  when hasFFI:
    result.cname = g[si].fromDisk.sh.strings[s.cname]

  if s.kind in {skLet, skVar, skField, skForVar}:
    result.guard = loadSym(c, g, si, s.guard)
    result.bitsize = s.bitsize
    result.alignment = s.alignment
  result.owner = loadSym(c, g, si, s.owner)
  let externalName = g[si].fromDisk.sh.strings[s.externalName]
  if externalName != "":
    result.loc.r = rope externalName
  result.loc.flags = s.locFlags

proc loadSym(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int; s: PackedItemId): PSym =
  if s == nilItemId:
    result = nil
  else:
    let si = moduleIndex(c, g, thisModule, s)
    assert g[si].status in {loaded, storing}
    if not g[si].symsInit:
      g[si].symsInit = true
      setLen g[si].syms, g[si].fromDisk.sh.syms.len

    if g[si].syms[s.item] == nil:
      if g[si].fromDisk.sh.syms[s.item].kind != skModule:
        result = symHeaderFromPacked(c, g, g[si].fromDisk.sh.syms[s.item], si, s.item)
        # store it here early on, so that recursions work properly:
        g[si].syms[s.item] = result
        symBodyFromPacked(c, g, g[si].fromDisk.sh.syms[s.item], si, s.item, result)
      else:
        result = g[si].module
        assert result != nil

    else:
      result = g[si].syms[s.item]

proc typeHeaderFromPacked(c: var PackedDecoder; g: var PackedModuleGraph;
                          t: PackedType; si, item: int32): PType =
  result = PType(itemId: ItemId(module: si, item: t.nonUniqueId), kind: t.kind,
                flags: t.flags, size: t.size, align: t.align,
                paddingAtEnd: t.paddingAtEnd, lockLevel: t.lockLevel,
                uniqueId: ItemId(module: si, item: item),
                callConv: t.callConv)

proc typeBodyFromPacked(c: var PackedDecoder; g: var PackedModuleGraph;
                        t: PackedType; si, item: int32; result: PType) =
  result.sym = loadSym(c, g, si, t.sym)
  result.owner = loadSym(c, g, si, t.owner)
  when false:
    for op, item in pairs t.attachedOps:
      result.attachedOps[op] = loadSym(c, g, si, item)
  result.typeInst = loadType(c, g, si, t.typeInst)
  for son in items t.types:
    result.sons.add loadType(c, g, si, son)
  loadAstBody(t, n)
  when false:
    for gen, id in items t.methods:
      result.methods.add((gen, loadSym(c, g, si, id)))

proc loadType(c: var PackedDecoder; g: var PackedModuleGraph; thisModule: int; t: PackedItemId): PType =
  if t == nilItemId:
    result = nil
  else:
    let si = moduleIndex(c, g, thisModule, t)
    assert g[si].status in {loaded, storing}
    assert t.item > 0

    if not g[si].typesInit:
      g[si].typesInit = true
      setLen g[si].types, g[si].fromDisk.sh.types.len

    if g[si].types[t.item] == nil:
      result = typeHeaderFromPacked(c, g, g[si].fromDisk.sh.types[t.item], si, t.item)
      # store it here early on, so that recursions work properly:
      g[si].types[t.item] = result
      typeBodyFromPacked(c, g, g[si].fromDisk.sh.types[t.item], si, t.item, result)
    else:
      result = g[si].types[t.item]
    assert result.itemId.item > 0

proc newPackage(config: ConfigRef; cache: IdentCache; fileIdx: FileIndex): PSym =
  let filename = AbsoluteFile toFullPath(config, fileIdx)
  let name = getIdent(cache, splitFile(filename).name)
  let info = newLineInfo(fileIdx, 1, 1)
  let
    pck = getPackageName(config, filename.string)
    pck2 = if pck.len > 0: pck else: "unknown"
    pack = getIdent(cache, pck2)
  result = newSym(skPackage, getIdent(cache, pck2),
    ItemId(module: PackageModuleId, item: int32(fileIdx)), nil, info)

proc setupLookupTables(g: var PackedModuleGraph; conf: ConfigRef; cache: IdentCache;
                       fileIdx: FileIndex; m: var LoadedModule) =
  m.iface = initTable[PIdent, seq[PackedItemId]]()
  for e in m.fromDisk.exports:
    let nameLit = e[0]
    m.iface.mgetOrPut(cache.getIdent(m.fromDisk.sh.strings[nameLit]), @[]).add(PackedItemId(module: LitId(0), item: e[1]))
  for re in m.fromDisk.reexports:
    let nameLit = re[0]
    m.iface.mgetOrPut(cache.getIdent(m.fromDisk.sh.strings[nameLit]), @[]).add(re[1])

  let filename = AbsoluteFile toFullPath(conf, fileIdx)
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID.
  m.module = PSym(kind: skModule, itemId: ItemId(module: int32(fileIdx), item: 0'i32),
                  name: getIdent(cache, splitFile(filename).name),
                  info: newLineInfo(fileIdx, 1, 1),
                  position: int(fileIdx))
  m.module.owner = newPackage(conf, cache, fileIdx)

proc loadToReplayNodes(g: var PackedModuleGraph; conf: ConfigRef; cache: IdentCache;
                       fileIdx: FileIndex; m: var LoadedModule) =
  m.module.ast = newNode(nkStmtList)
  if m.fromDisk.toReplay.len > 0:
    var decoder = PackedDecoder(
      lastModule: int32(-1),
      lastLit: LitId(0),
      lastFile: FileIndex(-1),
      config: conf,
      cache: cache)
    for p in allNodes(m.fromDisk.toReplay):
      m.module.ast.add loadNodes(decoder, g, int(fileIdx), m.fromDisk.toReplay, p)

proc needsRecompile(g: var PackedModuleGraph; conf: ConfigRef; cache: IdentCache;
                    fileIdx: FileIndex; cachedModules: var seq[FileIndex]): bool =
  # Does the file belong to the fileIdx need to be recompiled?
  let m = int(fileIdx)
  if m >= g.len:
    g.setLen(m+1)

  case g[m].status
  of undefined:
    g[m].status = loading
    let fullpath = msgs.toFullPath(conf, fileIdx)
    let rod = toRodFile(conf, AbsoluteFile fullpath)
    let err = loadRodFile(rod, g[m].fromDisk, conf)
    if err == ok:
      result = false
      # check its dependencies:
      for dep in g[m].fromDisk.imports:
        let fid = toFileIndex(dep, g[m].fromDisk, conf)
        # Warning: we need to traverse the full graph, so
        # do **not use break here**!
        if needsRecompile(g, conf, cache, fid, cachedModules):
          result = true

      if not result:
        setupLookupTables(g, conf, cache, fileIdx, g[m])
        cachedModules.add fileIdx
      g[m].status = if result: outdated else: loaded
    else:
      loadError(err, rod)
      g[m].status = outdated
      result = true
  of loading, loaded:
    # For loading: Assume no recompile is required.
    result = false
  of outdated, storing:
    result = true

proc moduleFromRodFile*(g: var PackedModuleGraph; conf: ConfigRef; cache: IdentCache;
                        fileIdx: FileIndex; cachedModules: var seq[FileIndex]): PSym =
  ## Returns 'nil' if the module needs to be recompiled.
  if needsRecompile(g, conf, cache, fileIdx, cachedModules):
    result = nil
  else:
    result = g[int fileIdx].module
    assert result != nil
    assert result.position == int(fileIdx)
    for m in cachedModules:
      loadToReplayNodes(g, conf, cache, m, g[int m])

template setupDecoder() {.dirty.} =
  var decoder = PackedDecoder(
    lastModule: int32(-1),
    lastLit: LitId(0),
    lastFile: FileIndex(-1),
    config: config,
    cache: cache)

proc loadProcBody*(config: ConfigRef, cache: IdentCache;
                   g: var PackedModuleGraph; s: PSym): PNode =
  let mId = s.itemId.module
  var decoder = PackedDecoder(
    lastModule: int32(-1),
    lastLit: LitId(0),
    lastFile: FileIndex(-1),
    config: config,
    cache: cache)
  let pos = g[mId].fromDisk.sh.syms[s.itemId.item].ast
  assert pos != emptyNodeId
  result = loadProcBody(decoder, g, mId, g[mId].fromDisk.bodies, NodePos pos)

proc loadTypeFromId*(config: ConfigRef, cache: IdentCache;
                     g: var PackedModuleGraph; module: int; id: PackedItemId): PType =
  if id.item < g[module].types.len:
    result = g[module].types[id.item]
  else:
    result = nil
  if result == nil:
    var decoder = PackedDecoder(
      lastModule: int32(-1),
      lastLit: LitId(0),
      lastFile: FileIndex(-1),
      config: config,
      cache: cache)
    result = loadType(decoder, g, module, id)

proc loadSymFromId*(config: ConfigRef, cache: IdentCache;
                    g: var PackedModuleGraph; module: int; id: PackedItemId): PSym =
  if id.item < g[module].syms.len:
    result = g[module].syms[id.item]
  else:
    result = nil
  if result == nil:
    var decoder = PackedDecoder(
      lastModule: int32(-1),
      lastLit: LitId(0),
      lastFile: FileIndex(-1),
      config: config,
      cache: cache)
    result = loadSym(decoder, g, module, id)

proc translateId*(id: PackedItemId; g: PackedModuleGraph; thisModule: int; config: ConfigRef): ItemId =
  if id.module == LitId(0):
    ItemId(module: thisModule.int32, item: id.item)
  else:
    ItemId(module: toFileIndex(id.module, g[thisModule].fromDisk, config).int32, item: id.item)

proc checkForHoles(m: PackedModule; config: ConfigRef; moduleId: int) =
  var bugs = 0
  for i in 1 .. high(m.sh.syms):
    if m.sh.syms[i].kind == skUnknown:
      echo "EMPTY ID ", i, " module ", moduleId, " ", toFullPath(config, FileIndex(moduleId))
      inc bugs
  assert bugs == 0
  when false:
    var nones = 0
    for i in 1 .. high(m.sh.types):
      inc nones, m.sh.types[i].kind == tyNone
    assert nones < 1

proc simulateLoadedModule*(g: var PackedModuleGraph; conf: ConfigRef; cache: IdentCache;
                           moduleSym: PSym; m: PackedModule) =
  # For now only used for heavy debugging. In the future we could use this to reduce the
  # compiler's memory consumption.
  let idx = moduleSym.position
  assert g[idx].status in {storing}
  g[idx].status = loaded
  assert g[idx].module == moduleSym
  setupLookupTables(g, conf, cache, FileIndex(idx), g[idx])
  loadToReplayNodes(g, conf, cache, FileIndex(idx), g[idx])

# ---------------- symbol table handling ----------------

type
  RodIter* = object
    decoder: PackedDecoder
    values: seq[PackedItemId]
    i, module: int

proc initRodIter*(it: var RodIter; config: ConfigRef, cache: IdentCache;
                  g: var PackedModuleGraph; module: FileIndex;
                  name: PIdent): PSym =
  it.decoder = PackedDecoder(
    lastModule: int32(-1),
    lastLit: LitId(0),
    lastFile: FileIndex(-1),
    config: config,
    cache: cache)
  it.values = g[int module].iface.getOrDefault(name)
  it.i = 0
  it.module = int(module)
  if it.i < it.values.len:
    result = loadSym(it.decoder, g, int(module), it.values[it.i])
    inc it.i

proc initRodIterAllSyms*(it: var RodIter; config: ConfigRef, cache: IdentCache;
                         g: var PackedModuleGraph; module: FileIndex): PSym =
  it.decoder = PackedDecoder(
    lastModule: int32(-1),
    lastLit: LitId(0),
    lastFile: FileIndex(-1),
    config: config,
    cache: cache)
  it.values = @[]
  it.module = int(module)
  for v in g[int module].iface.values:
    it.values.add v
  it.i = 0
  if it.i < it.values.len:
    result = loadSym(it.decoder, g, int(module), it.values[it.i])
    inc it.i

proc nextRodIter*(it: var RodIter; g: var PackedModuleGraph): PSym =
  if it.i < it.values.len:
    result = loadSym(it.decoder, g, it.module, it.values[it.i])
    inc it.i

iterator interfaceSymbols*(config: ConfigRef, cache: IdentCache;
                           g: var PackedModuleGraph; module: FileIndex;
                           name: PIdent): PSym =
  setupDecoder()
  let values = g[int module].iface.getOrDefault(name)
  for pid in values:
    let s = loadSym(decoder, g, int(module), pid)
    assert s != nil
    yield s

proc interfaceSymbol*(config: ConfigRef, cache: IdentCache;
                      g: var PackedModuleGraph; module: FileIndex;
                      name: PIdent): PSym =
  setupDecoder()
  let values = g[int module].iface.getOrDefault(name)
  result = loadSym(decoder, g, int(module), values[0])

proc idgenFromLoadedModule*(m: LoadedModule): IdGenerator =
  IdGenerator(module: m.module.itemId.module, symId: int32 m.fromDisk.sh.syms.len,
              typeId: int32 m.fromDisk.sh.types.len)

# ------------------------- .rod file viewer ---------------------------------

proc rodViewer*(rodfile: AbsoluteFile; config: ConfigRef, cache: IdentCache) =
  var m: PackedModule
  if loadRodFile(rodfile, m, config) != ok:
    echo "Error: could not load: ", rodfile.string
    quit 1

  when true:
    echo "exports:"
    for ex in m.exports:
      echo "  ", m.sh.strings[ex[0]]
      assert ex[0] == m.sh.syms[ex[1]].name
      # ex[1] int32

    echo "reexports:"
    for ex in m.reexports:
      echo "  ", m.sh.strings[ex[0]]
    #  reexports*: seq[(LitId, PackedItemId)]
  echo "symbols: ", m.sh.syms.len, " types: ", m.sh.types.len,
    " top level nodes: ", m.topLevel.nodes.len, " other nodes: ", m.bodies.nodes.len,
    " strings: ", m.sh.strings.len, " integers: ", m.sh.integers.len,
    " floats: ", m.sh.floats.len
