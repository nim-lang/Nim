#
#
#
# order is controlled by the codegen process and it's something
# we don't want to fuck with
#
# module graph mutation during codegen:
#
# x -> y -> n
#   a'   d'                       <- operations that we must cache
#   ^ move all the logic here
#
# current reality:
#
# x -> z -> y -> n
#   b'   c'   d'                  <- operations that we must cache
#
# ideal reality:
#
# x -> z -> y -> n
#   b'   a'   d'                  <- operations that we must cache
#
#
#
#
#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the new compilation cache.

import strutils, intsets, tables, ropes, db_sqlite, msgs, options, ast,
  renderer, rodutils, idents, astalgo, btrees, magicsys, cgmeth, extccomp,
  treetab, condsyms, nversion, pathutils, cgendata, sequtils, trees, ndi,
  sighashes, modulegraphs, idgen, lineinfos, incremental, types, hashes

export nimIncremental

when not defined(release):
  include icaudit

## TODO:
## - Add some backend logic dealing with generics.
## - Dependency computation should use *signature* hashes in order to
##   avoid recompiling dependent modules.
## - Patch the rest of the compiler to do lazy loading of proc bodies.
## - Serialize the AST in a smarter way (avoid storing some ASTs twice!)

## This module implements the canonalization for the various caching mechanisms.

type
  SnippetTable* = Table[SigHash, Snippet]
  Snippets* = seq[Snippet]

  # the in-memory representation of a cachable unit of backend codegen
  CacheUnit*[T] = object
    node*: T                  # the node itself
    snippets*: SnippetTable   # snippets for this node
    graph*: ModuleGraph       # the original module graph, for convenience
    modules*: BModuleList     # modules being built by the backend

  TransformKind = enum
    Unknown
    HeaderFile
    ProtoSet
    ThingSet
    SwingSet
    JetSet
    ReSet
    FlagSet
    TypeStack
    Injection
    GraphRope

  Transform = object
    case kind: TransformKind
    of FlagSet:
      flags: set[CodegenFlag]
    of ProtoSet, ThingSet, SwingSet:
      diff: IntSet
    of HeaderFile:
      filenames: seq[string]
    of TypeStack:
      stack: TTypeSeq
    of Injection:
      rope: Rope
    of GraphRope:
      grope: Rope
    else:
      discard
    module: BModule

  # the in-memory representation of the database record
  Snippet* = object
    signature*: SigHash       # we use the signature to associate the node
    module*: BModule          # the module to which the snippet applies
    section*: TCFileSection   # the section of the module in which to write
    code*: Rope               # the raw backend code itself, eg. C/JS/etc.

  # deprecated but we cannot say so due to nim bug
  SnippetMark* = object
    lengths*: array[TCFileSection, int]
    node*: PSym

  SqlId = int64

template db(): DbConn = g.incr.db

# idea for testing all this logic: *Always* load the AST from the DB, whether
# we already have it in RAM or not!

proc snippetAlreadyStored*(g: ModuleGraph; p: PSym): bool

proc newPreInitProc*(m: BModule): BProc =
  result = newProc(nil, m)
  # little hack so that unique temporaries are generated:
  result.labels = 100_000

proc initProcOptions*(m: BModule): TOptions =
  let opts = m.config.options
  if sfSystemModule in m.module.flags: opts-{optStackTrace} else: opts

proc getTempName*(m: BModule): Rope =
  result = m.tmpBase & rope(m.labels)
  inc m.labels

proc rawNewModule*(g: BModuleList; module: PSym; filename: AbsoluteFile): BModule =
  new(result)
  result.g = g
  result.tmpBase = rope("TM" & $hashOwner(module) & "_")
  result.headerFiles = @[]
  result.cfilename = filename
  result.filename = filename
  result.module = module
  result.typeNodesName = getTempName(result)
  result.nimTypesName = getTempName(result)

  # XXX: keep an eye on these:
  result.declaredThings = initIntSet()
  result.declaredProtos = initIntSet()
  initNodeTable(result.dataCache)
  result.typeStack = @[]
  result.initProc = newProc(nil, result)
  result.initProc.options = initProcOptions(result)
  result.preInitProc = newPreInitProc(result)
  #
  # XXX: these, we share currently
  result.typeCache = newTable[SigHash, Rope]()
  result.forwTypeCache = newTable[SigHash, Rope]()
  result.typeInfoMarker = newTable[SigHash, Rope]()
  result.sigConflicts = newCountTable[SigHash]()
  # XXX: end

  # no line tracing for the init sections of the system module so that we
  # don't generate a TFrame which can confuse the stack bottom initialization:
  if sfSystemModule in module.flags:
    incl result.flags, preventStackTrace
    excl(result.preInitProc.options, optStackTrace)

  # XXX: we might need to move these to a non-raw init
  let ndiName = if optCDebug in g.config.globalOptions:
    changeFileExt(completeCfilePath(g.config, filename), "ndi")
  else:
    AbsoluteFile""
  open(result.ndi, ndiName, g.config)

proc rawNewModule*(g: BModuleList; module: PSym; conf: ConfigRef): BModule =
  result = rawNewModule(g, module,
                        AbsoluteFile toFullPath(conf, module.position.FileIndex))

proc newCacheUnit*[T](modules: BModuleList; node: T): CacheUnit[T] =
  result = CacheUnit[T](node: node, graph: modules.graph)

  # add a container for relevant snippets
  let
    size = rightSize(TCFileSection.high.ord)
  result.snippets = initTable[SigHash, Snippet](size)

  assert modules.graph != nil
  # add fake versions of every module we're working on
  result.modules = newModuleList(modules.graph)
  assert result.modules.modules.len == 0
  for m in modules.modules.items:
    if m == nil:
      result.modules.modules.add nil
    else:
      var
        fake = rawNewModule(result.modules, m.module, m.filename)

      # shared refs
      fake.sigConflicts = m.sigConflicts
      fake.typeCache = m.typeCache
      fake.forwTypeCache = m.forwTypeCache
      fake.typeInfoMarker = m.typeInfoMarker
      fake.tmpBase = rope("tmp_ic_" & $sigHash(node) & "_")

      # XXX: figure this one out...
      fake.labels = m.labels
      fake.typeNodes = m.typeNodes
      fake.nimTypes = m.nimTypes
      fake.headerFiles = m.headerFiles
      # XXX: tricky bit to understand better.
      fake.dataCache = m.dataCache
      fake.flags = m.flags
      fake.declaredThings = m.declaredThings
      fake.declaredProtos = m.declaredProtos

      for t in m.typeStack:
        pushType(fake, t)

      fake.initProc = m.initProc
      fake.preInitProc = m.preInitProc

      # make sure our fake module matches the original module
      assert fake.hash == m.hash, node.name.s & " " & $m.filename

      # these mutate the fake module
      fake.typeNodesName = getTempName(fake)
      fake.nimTypesName = getTempName(fake)

      echo "DING DING ", node.name.s & " " & $m.filename
      result.modules.modules.add fake

# the snippet's module is not necessarily the same as the symbol!
proc newSnippet*[T](node: T; module: BModule; sect: TCFileSection): Snippet =
  result = Snippet(signature: node.sigHash, module: module, section: sect)

proc findModule*(list: BModuleList; child: BModule): BModule =
  assert child != nil
  block found:
    for m in list.modules.items:
      if m != nil:
        if m.module != nil and m.module.id == child.module.id:
          result = m
          break found
    raise newException(Defect, "unable to find module " & $child.module.id)

proc moduleFor*(cache: CacheUnit; p: PSym): BModule =
  block found:
    let
      # the module id for the symbol
      id = getModule(p).id
    # iterate over our fake modules list and find the matching module
    for m in cache.modules.modules.items:
      if m != nil:
        if id == m.module.id:
          result = m
          break found
    raise newException(Defect, "wow, this is a disaster!")
proc encodeConfig(g: ModuleGraph): string =
  result = newStringOfCap(100)
  result.add RodFileVersion
  for d in definedSymbolNames(g.config.symbols):
    result.add ' '
    result.add d

  template serialize(field) =
    result.add ' '
    result.add($g.config.field)

  depConfigFields(serialize)

proc needsRecompile(g: ModuleGraph; fileIdx: FileIndex; fullpath: AbsoluteFile;
                    cycleCheck: var IntSet): bool =
  let root = db.getRow(sql"select id, fullhash from filenames where fullpath = ?",
    fullpath.string)
  if root[0].len == 0: return true
  if root[1] != hashFileCached(g.config, fileIdx, fullpath):
    return true
  # cycle detection: assume "not changed" is correct.
  if cycleCheck.containsOrIncl(int fileIdx):
    return false
  # check dependencies (recursively):
  for row in db.fastRows(sql"select fullpath from filenames where id in (select dependency from deps where module = ?)",
                         root[0]):
    let dep = AbsoluteFile row[0]
    if needsRecompile(g, g.config.fileInfoIdx(dep), dep, cycleCheck):
      return true
  return false

proc getModuleId(g: ModuleGraph; fileIdx: FileIndex; fullpath: AbsoluteFile): int =
  ## Analyse the known dependency graph.
  if g.config.symbolFiles == disabledSf: return getID()
  when false:
    if g.config.symbolFiles in {disabledSf, writeOnlySf} or
      g.incr.configChanged:
      return getID()
  let module = g.incr.db.getRow(
    sql"select id, fullHash, nimid from modules where fullpath = ?", string fullpath)
  let currentFullhash = hashFileCached(g.config, fileIdx, fullpath)
  if module[0].len == 0:
    result = getID()
    db.exec(sql"insert into modules(fullpath, interfHash, fullHash, nimid) values (?, ?, ?, ?)",
      string fullpath, "", currentFullhash, result)
  else:
    result = parseInt(module[2])
    if currentFullhash == module[1]:
      # not changed, so use the cached AST:
      doAssert(result != 0)
      var cycleCheck = initIntSet()
      if not needsRecompile(g, fileIdx, fullpath, cycleCheck):
        if not g.incr.configChanged or g.config.symbolFiles == readOnlySf:
          #echo "cached successfully! ", string fullpath
          return -result
      elif g.config.symbolFiles == readOnlySf:
        internalError(g.config, "file needs to be recompiled: " & (string fullpath))
    db.exec(sql"update modules set fullHash = ? where id = ?", currentFullhash, module[0])
    db.exec(sql"delete from deps where module = ?", module[0])
    db.exec(sql"delete from types where module = ?", module[0])
    db.exec(sql"delete from syms where module = ?", module[0])
    db.exec(sql"delete from toplevelstmts where module = ?", module[0])
    db.exec(sql"delete from statics where module = ?", module[0])

proc loadModuleSym*(g: ModuleGraph; fileIdx: FileIndex; fullpath: AbsoluteFile): (PSym, int) =
  let id = getModuleId(g, fileIdx, fullpath)
  result = (g.incr.r.syms.getOrDefault(abs id), id)

proc pushType(w: var Writer, t: PType) =
  if not containsOrIncl(w.tmarks, t.uniqueId):
    w.tstack.add(t)
    if t.kind == tyGenericInst:
      if t.sons.len == 0:
        raise newException(Defect, "write of generic instance w/o sons")

proc pushSym(w: var Writer, s: PSym) =
  if not containsOrIncl(w.smarks, s.id):
    w.sstack.add(s)

template w: untyped = g.incr.w

proc encodeNode(g: ModuleGraph; fInfo: TLineInfo, n: PNode,
                result: var string) =
  if n == nil:
    # nil nodes have to be stored too:
    result.add("()")
    return
  result.add('(')
  encodeVInt(ord(n.kind), result)
  # we do not write comments for now
  # Line information takes easily 20% or more of the filesize! Therefore we
  # omit line information if it is the same as the parent's line information:
  if fInfo.fileIndex != n.info.fileIndex:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(int n.info.line, result)
    result.add(',')
    #encodeVInt(toDbFileId(g.incr, g.config, n.info.fileIndex), result)
    encodeVInt(n.info.fileIndex.int, result)
  elif fInfo.line != n.info.line:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(int n.info.line, result)
  elif fInfo.col != n.info.col:
    result.add('?')
    encodeVInt(n.info.col, result)
  # No need to output the file index, as this is the serialization of one
  # file.
  let f = n.flags * PersistentNodeFlags
  if f != {}:
    result.add('$')
    encodeVInt(cast[int32](f), result)
  if n.typ != nil:
    result.add('^')
    encodeVInt(n.typ.uniqueId, result)
    pushType(w, n.typ)
  case n.kind
  of nkCharLit..nkUInt64Lit:
    if n.intVal != 0:
      result.add('!')
      encodeVBiggestInt(n.intVal, result)
  of nkFloatLit..nkFloat64Lit:
    if n.floatVal != 0.0:
      result.add('!')
      encodeStr($n.floatVal, result)
  of nkStrLit..nkTripleStrLit:
    if n.strVal != "":
      result.add('!')
      encodeStr(n.strVal, result)
  of nkIdent:
    result.add('!')
    encodeStr(n.ident.s, result)
  of nkSym:
    result.add('!')
    encodeVInt(n.sym.id, result)
    pushSym(w, n.sym)
  else:
    for i in 0..<n.len:
      encodeNode(g, n.info, n[i], result)
  result.add(')')

proc encodeLoc(g: ModuleGraph; loc: TLoc, result: var string) =
  var oldLen = result.len
  result.add('<')
  if loc.k != low(loc.k): encodeVInt(ord(loc.k), result)
  if loc.storage != low(loc.storage):
    result.add('*')
    encodeVInt(ord(loc.storage), result)
  if loc.flags != {}:
    result.add('$')
    encodeVInt(cast[int32](loc.flags), result)
  if loc.lode != nil:
    result.add('^')
    encodeNode(g, unknownLineInfo, loc.lode, result)
  if loc.r != nil:
    result.add('!')
    encodeStr($loc.r, result)
  if oldLen + 1 == result.len:
    # no data was necessary, so remove the '<' again:
    setLen(result, oldLen)
  else:
    result.add('>')

proc encodeType(g: ModuleGraph, t: PType, result: var string) =
  if t == nil:
    # nil nodes have to be stored too:
    result.add("[]")
    return
  # we need no surrounding [] here because the type is in a line of its own
  if t.kind == tyForward: internalError(g.config, "encodeType: tyForward")
  # for the new rodfile viewer we use a preceding [ so that the data section
  # can easily be disambiguated:
  result.add('[')
  encodeVInt(ord(t.kind), result)
  result.add('+')
  encodeVInt(t.uniqueId, result)
  if t.id != t.uniqueId:
    result.add('+')
    encodeVInt(t.id, result)
  if t.n != nil:
    encodeNode(g, unknownLineInfo, t.n, result)
  if t.flags != {}:
    result.add('$')
    encodeVInt(cast[int32](t.flags), result)
  if t.callConv != low(t.callConv):
    result.add('?')
    encodeVInt(ord(t.callConv), result)
  if t.owner != nil:
    result.add('*')
    encodeVInt(t.owner.id, result)
    pushSym(w, t.owner)
  if t.sym != nil:
    result.add('&')
    encodeVInt(t.sym.id, result)
    pushSym(w, t.sym)
  if t.size != - 1:
    result.add('/')
    encodeVBiggestInt(t.size, result)
  if t.align != 2:
    result.add('=')
    encodeVInt(t.align, result)
  if t.lockLevel.ord != UnspecifiedLockLevel.ord:
    result.add('\14')
    encodeVInt(t.lockLevel.int16, result)
  if t.paddingAtEnd != 0:
    result.add('\15')
    encodeVInt(t.paddingAtEnd, result)
  for a in t.attachedOps:
    result.add('\16')
    if a == nil:
      encodeVInt(-1, result)
    else:
      encodeVInt(a.id, result)
      pushSym(w, a)
  for i, s in items(t.methods):
    result.add('\19')
    encodeVInt(i, result)
    result.add('\20')
    encodeVInt(s.id, result)
    pushSym(w, s)
  encodeLoc(g, t.loc, result)
  if t.typeInst != nil:
    result.add('\21')
    encodeVInt(t.typeInst.uniqueId, result)
    # XXX: keep an eye on this
    pushType(w, t.typeInst)
  # we have sons when we write the type,
  # but we don't have them after reading it.
  for i in 0..<t.len:
    if t[i] == nil:
      result.add("^()")
    else:
      result.add('^')
      encodeVInt(t[i].uniqueId, result)
      pushType(w, t[i])

proc encodeLib(g: ModuleGraph, lib: PLib, info: TLineInfo, result: var string) =
  result.add('|')
  encodeVInt(ord(lib.kind), result)
  result.add('|')
  encodeStr($lib.name, result)
  result.add('|')
  encodeNode(g, info, lib.path, result)

proc encodeInstantiations(g: ModuleGraph; s: seq[PInstantiation];
                          result: var string) =
  for t in s:
    result.add('\15')
    encodeVInt(t.sym.id, result)
    pushSym(w, t.sym)
    for tt in t.concreteTypes:
      result.add('\17')
      encodeVInt(tt.uniqueId, result)
      pushType(w, tt)
    result.add('\20')
    encodeVInt(t.compilesId, result)

proc encodeSym(g: ModuleGraph, s: PSym, result: var string) =
  if s == nil:
    # nil nodes have to be stored too:
    result.add("{}")
    return
  # we need no surrounding {} here because the symbol is in a line of its own
  encodeVInt(ord(s.kind), result)
  result.add('+')
  encodeVInt(s.id, result)
  result.add('&')
  encodeStr(s.name.s, result)
  if s.typ != nil:
    result.add('^')
    encodeVInt(s.typ.uniqueId, result)
    pushType(w, s.typ)
  result.add('?')
  if s.info.col != -1'i16: encodeVInt(s.info.col, result)
  result.add(',')
  encodeVInt(int s.info.line, result)
  result.add(',')
  #encodeVInt(toDbFileId(g.incr, g.config, s.info.fileIndex), result)
  encodeVInt(s.info.fileIndex.int, result)
  if s.owner != nil:
    result.add('*')
    encodeVInt(s.owner.id, result)
    pushSym(w, s.owner)
  if s.flags != {}:
    result.add('$')
    encodeVBiggestInt(cast[int64](s.flags), result)
  if s.magic != mNone:
    result.add('@')
    encodeVInt(ord(s.magic), result)
  result.add('!')
  encodeVInt(cast[int32](s.options), result)
  if s.position != 0:
    result.add('%')
    encodeVInt(s.position, result)
  if s.offset != - 1:
    result.add('`')
    encodeVInt(s.offset, result)
  encodeLoc(g, s.loc, result)
  if s.annex != nil: encodeLib(g, s.annex, s.info, result)
  if s.constraint != nil:
    result.add('#')
    encodeNode(g, unknownLineInfo, s.constraint, result)
  case s.kind
  of skType, skGenericParam:
    for t in s.typeInstCache:
      result.add('\14')
      encodeVInt(t.uniqueId, result)
      pushType(w, t)
  of routineKinds:
    encodeInstantiations(g, s.procInstCache, result)
    if s.gcUnsafetyReason != nil:
      result.add('\16')
      encodeVInt(s.gcUnsafetyReason.id, result)
      pushSym(w, s.gcUnsafetyReason)
    if s.transformedBody != nil:
      result.add('\24')
      encodeNode(g, s.info, s.transformedBody, result)
  of skModule, skPackage:
    encodeInstantiations(g, s.usedGenerics, result)
    # we don't serialize:
    #tab*: TStrTable         # interface table for modules
  of skLet, skVar, skField, skForVar:
    if s.guard != nil:
      result.add('\18')
      encodeVInt(s.guard.id, result)
      pushSym(w, s.guard)
    if s.bitsize != 0:
      result.add('\19')
      encodeVInt(s.bitsize, result)
  else: discard
  # lazy loading will soon reload the ast lazily, so the ast needs to be
  # the last entry of a symbol:
  if s.ast != nil:
    # we used to attempt to save space here by only storing a dummy AST if
    # it is not necessary, but Nim's heavy compile-time evaluation features
    # make that unfeasible nowadays:
    encodeNode(g, s.info, s.ast, result)

proc symbolId*(g: ModuleGraph; p: PSym): SqlId =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"""
      select id from syms
      where module = ? and name = ? and nimid = ?
      limit 1
    """
  let
    name = $p.sigHash
    m = getModule(p)
    mid = if m == nil: 0 else: abs(m.id)
    id = db.getValue(query, mid, name, p.id)
  if id != "":
    result = id.parseInt

proc unstoreSym*(g: ModuleGraph; s: PSym) =
  if g.config.symbolFiles == disabledSf: return
  const
    deinsertion = sql"""
      delete from syms where nimid = ? and module = ? and name = ?
    """
  let
    m = getModule(s)
    mid = if m == nil: 0 else: abs(m.id)
    name = $s.sigHash
    affected = db.execAffectedRows(deinsertion, s.id, mid, name)
  if affected == 0:
    echo "gratuitous unstore of symbol ", s.name.s

proc storeSym*(g: ModuleGraph; s: PSym) =
  if g.config.symbolFiles == disabledSf: return
  if sfForward in s.flags and s.kind != skModule:
    w.forwardedSyms.add s
    return
  let
    existing = g.symbolId(s)
  if existing != 0:
    echo "duplicate store of symbol ", s.name.s
    unstoreSym(g, s)

  var buf = newStringOfCap(160)
  encodeSym(g, s, buf)
  const
    insertion = sql"""
      insert into syms (nimid, module, name, data, exported)
      values (?, ?, ?, ?, ?)
    """
  # XXX only store the name for exported symbols in order to speed up lookup
  # times once we enable the skStub logic.
  # XXX - but we need generics...
  let
    m = getModule(s)
    mid = if m == nil: 0 else: abs(m.id)
    name = $s.sigHash
  db.exec(insertion, s.id, mid, name, buf, ord(sfExported in s.flags))

when false:
  proc decodeDeps(g: ModuleGraph; input: string): Snippets

iterator loadSnippets*(g: ModuleGraph; modules: BModuleList; p: PSym): Snippet =
  ## sighash as input, along with the module
  ##
  ## section and code as output
  const
    selection = sql"""
      select syms.name, module, section, code
      from syms left join snippets
      where syms.name = snippets.signature and syms.name = ?
    """
  var
    count = 0
  let
    name = $p.sigHash
  for row in db.fastRows(selection, name):
    count.inc

    # search for the snippets for the given symbol
    block found:
      # the modules in the modules list are in the modules list
      for module in modules.modules.items:
        # the module id is in the module's module field
        if module.module.id == row[1].parseInt:
          var
            snippet = newSnippet[PSym](p, module,
                                       row[2].parseInt.TCFileSection)
          snippet.code = row[3].rope
          yield snippet
          break found
      # we didn't find the matching backend module; for now we throw
      raise newException(Defect, "could not match module")

  when false:
    if count == 0 and {sfImportc, sfCompilerProc, sfThread} * p.flags == {}:
      echo "flags for ", p.name.s, p.flags
      echo "no snippets gen'd for " & p.name.s

when false:
  proc loadSnippet(g: ModuleGraph; id: SqlId): Snippet =
    const
      selection = sql"""
      select id,kind,nimid,code,symbol
      from snippets where id = ?
      """
    let
      row = db.getRow(selection, id)
    if row[0] == "":
      raise newException(Defect, "very bad news; no snippet id " & $id)
    result = Snippet(id: id, kind: parseInt(row[1]).TNodeKind,
                     nimid: parseInt(row[2]),
                     code: rope(row[3]))
    result.symbol = parseInt(row[4])

  proc decodeDeps(g: ModuleGraph; input: string): Snippets {.deprecated.} =
    for id in input.split(","):
      let
        id = parseInt(id)
      result[id] = loadSnippet(g, id)

  proc encodeDeps(deps: Snippets): string {.deprecated.} =
    for snippet in deps.items:
      if result.len == 0:
        result = $snippet.id
      else:
        result &= "," & $snippet.id

proc storeSnippet*(g: ModuleGraph; s: var Snippet) =
  const
    insertion = sql"""
      insert into snippets (signature, module, section, code)
      values (?, ?, ?, ?)
    """
  db.exec(insertion, $s.signature, s.module.module.id, s.section.ord, $s.code)

proc snippetAlreadyStored*(g: ModuleGraph; p: PSym): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"""
      select syms.id
      from syms left join snippets
      where snippets.signature = syms.name and syms.name = ?
      limit 1
    """
  let
    signature = $p.sigHash
  result = db.getValue(query, signature) != ""

template symbolAlreadyStored*(g: ModuleGraph; p: PSym): bool =
  g.symbolId(p) != 0

proc typeAlreadyStored*(g: ModuleGraph; p: PType): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"select nimid from types where nimid = ? limit 1"
  result = db.getValue(query, p.uniqueId) == $p.uniqueId

proc typeAlreadyStored(g: ModuleGraph; nimid: int): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"select nimid from types where nimid = ? limit 1"
  result = db.getValue(query, nimid) == $nimid

proc storeType(g: ModuleGraph; t: PType): SqlId =
  const
    insertion = sql"""
      insert into types(nimid, module, data) values (?, ?, ?)
    """
    updation = sql"""
      update types set module = ?, data = ? where nimid = ?
    """
    selection = sql"""
      select id from types where module = ? and nimid = ?
    """
  var buf = newStringOfCap(160)
  encodeType(g, t, buf)
  let m = if t.owner != nil: getModule(t.owner) else: nil
  let mid = if m == nil: 0 else: abs(m.id)
  when false:
    # took this out because it's possibly incorrect in the event that
    # a type is used in two files but unchanged between either.
    if typeAlreadyStored(g, t.uniqueId):
      when not defined(release):
        echo "rewrite of type id " & $t.uniqueId
      #raise newException(Defect, "rewrite of type id " & $t.uniqueId)
      # XXX mid?  really?  not the primary key id?
      db.exec(updation, mid, buf, t.uniqueId)
      # XXX inefficient
      result = db.getValue(selection, mid, t.uniqueId).parseInt
    else:
      result = db.insertID(insertion, t.uniqueId, mid, buf)
  else:
    result = db.insertID(insertion, t.uniqueId, mid, buf)

proc transitiveClosure(g: ModuleGraph) =
  var i = 0
  while true:
    if i > 100_000:
      doAssert false, "loop never ends!"
    if w.sstack.len > 0:
      let s = w.sstack.pop()
      when false:
        echo "popped ", s.name.s, " ", s.id
      storeSym(g, s)
    elif w.tstack.len > 0:
      let t = w.tstack.pop()
      discard storeType(g, t)
      when false:
        echo "popped type ", typeToString(t), " ", t.uniqueId
    else:
      break
    inc i

proc storeNode*(g: ModuleGraph; module: PSym; n: PNode): SqlId =
  if g.config.symbolFiles == disabledSf: return
  var buf = newStringOfCap(160)
  encodeNode(g, module.info, n, buf)
  const
    insertion = sql"insert into toplevelstmts(module, position, data) values (?, ?, ?)"
  # XXX
  # module should match the primary key of an id in the modules table,
  # right?
  result = db.insertID(insertion, abs(module.id), module.offset, buf)
  inc module.offset
  transitiveClosure(g)

proc recordStmt*(g: ModuleGraph; module: PSym; n: PNode) =
  discard storeNode(g, module, n)

proc storeFilename(g: ModuleGraph; fullpath: AbsoluteFile; fileIdx: FileIndex) =
  let id = db.getValue(sql"select id from filenames where fullpath = ?", fullpath.string)
  if id.len == 0:
    let fullhash = hashFileCached(g.config, fileIdx, fullpath)
    db.exec(sql"insert into filenames(nimid, fullpath, fullhash) values (?, ?, ?)",
        int(fileIdx), fullpath.string, fullhash)

proc storeRemaining*(g: ModuleGraph; module: PSym) =
  if g.config.symbolFiles == disabledSf: return
  var stillForwarded: seq[PSym] = @[]
  for s in w.forwardedSyms:
    if sfForward notin s.flags:
      storeSym(g, s)
    else:
      stillForwarded.add s
  swap w.forwardedSyms, stillForwarded
  transitiveClosure(g)
  var nimid = 0
  for x in items(g.config.m.fileInfos):
    storeFilename(g, x.fullPath, FileIndex(nimid))
    inc nimid

# ---------------- decoder -----------------------------------

type
  BlobReader = object
    s: string
    pos: int

using
  b: var BlobReader
  g: ModuleGraph

proc loadSym(g; id: int, info: TLineInfo): PSym
proc loadType(g; id: int, info: TLineInfo): PType

proc decodeLineInfo(g; b; info: var TLineInfo) =
  if b.s[b.pos] == '?':
    inc(b.pos)
    if b.s[b.pos] == ',': info.col = -1'i16
    else: info.col = int16(decodeVInt(b.s, b.pos))
    if b.s[b.pos] == ',':
      inc(b.pos)
      if b.s[b.pos] == ',': info.line = 0'u16
      else: info.line = uint16(decodeVInt(b.s, b.pos))
      if b.s[b.pos] == ',':
        inc(b.pos)
        #info.fileIndex = fromDbFileId(g.incr, g.config, decodeVInt(b.s, b.pos))
        info.fileIndex = FileIndex decodeVInt(b.s, b.pos)

proc skipNode(b) =
  # ')' itself cannot be part of a string literal so that this is correct.
  assert b.s[b.pos] == '('
  var par = 0
  var pos = b.pos+1
  while true:
    case b.s[pos]
    of ')':
      if par == 0: break
      dec par
    of '(': inc par
    else: discard
    inc pos
  b.pos = pos+1 # skip ')'

proc decodeNodeLazyBody(g; b; fInfo: TLineInfo,
                        belongsTo: PSym): PNode =
  result = nil
  if b.s[b.pos] == '(':
    inc(b.pos)
    if b.s[b.pos] == ')':
      inc(b.pos)
      return                  # nil node
    result = newNodeI(TNodeKind(decodeVInt(b.s, b.pos)), fInfo)
    decodeLineInfo(g, b, result.info)
    if b.s[b.pos] == '$':
      inc(b.pos)
      result.flags = cast[TNodeFlags](int32(decodeVInt(b.s, b.pos)))
    if b.s[b.pos] == '^':
      inc(b.pos)
      var id = decodeVInt(b.s, b.pos)
      result.typ = loadType(g, id, result.info)
    case result.kind
    of nkCharLit..nkUInt64Lit:
      if b.s[b.pos] == '!':
        inc(b.pos)
        result.intVal = decodeVBiggestInt(b.s, b.pos)
    of nkFloatLit..nkFloat64Lit:
      if b.s[b.pos] == '!':
        inc(b.pos)
        var fl = decodeStr(b.s, b.pos)
        result.floatVal = parseFloat(fl)
    of nkStrLit..nkTripleStrLit:
      if b.s[b.pos] == '!':
        inc(b.pos)
        result.strVal = decodeStr(b.s, b.pos)
      else:
        result.strVal = ""
    of nkIdent:
      if b.s[b.pos] == '!':
        inc(b.pos)
        var fl = decodeStr(b.s, b.pos)
        result.ident = g.cache.getIdent(fl)
      else:
        internalError(g.config, result.info, "decodeNode: nkIdent")
    of nkSym:
      if b.s[b.pos] == '!':
        inc(b.pos)
        var id = decodeVInt(b.s, b.pos)
        result.sym = loadSym(g, id, result.info)
      else:
        internalError(g.config, result.info, "decodeNode: nkSym")
    else:
      var i = 0
      while b.s[b.pos] != ')':
        when false:
          if belongsTo != nil and i == bodyPos:
            addSonNilAllowed(result, nil)
            belongsTo.offset = b.pos
            skipNode(b)
          else:
            discard
        addSonNilAllowed(result, decodeNodeLazyBody(g, b, result.info, nil))
        inc i
    if b.s[b.pos] == ')': inc(b.pos)
    else: internalError(g.config, result.info, "decodeNode: ')' missing")
  else:
    internalError(g.config, fInfo, "decodeNode: '(' missing " & $b.pos)

proc decodeNode(g; b; fInfo: TLineInfo): PNode =
  result = decodeNodeLazyBody(g, b, fInfo, nil)

proc decodeLoc(g; b; loc: var TLoc, info: TLineInfo) =
  if b.s[b.pos] == '<':
    inc(b.pos)
    if b.s[b.pos] in {'0'..'9', 'a'..'z', 'A'..'Z'}:
      loc.k = TLocKind(decodeVInt(b.s, b.pos))
    else:
      loc.k = low(loc.k)
    if b.s[b.pos] == '*':
      inc(b.pos)
      loc.storage = TStorageLoc(decodeVInt(b.s, b.pos))
    else:
      loc.storage = low(loc.storage)
    if b.s[b.pos] == '$':
      inc(b.pos)
      loc.flags = cast[TLocFlags](int32(decodeVInt(b.s, b.pos)))
    else:
      loc.flags = {}
    if b.s[b.pos] == '^':
      inc(b.pos)
      loc.lode = decodeNode(g, b, info)
      # rrGetType(b, decodeVInt(b.s, b.pos), info)
    else:
      loc.lode = nil
    if b.s[b.pos] == '!':
      inc(b.pos)
      loc.r = rope(decodeStr(b.s, b.pos))
    else:
      loc.r = nil
    if b.s[b.pos] == '>': inc(b.pos)
    else: internalError(g.config, info, "decodeLoc " & b.s[b.pos])

proc loadBlob(g; query: SqlQuery; id: int): BlobReader =
  let blob = db.getValue(query, id)
  if blob.len == 0:
    internalError(g.config, "symbolfiles: cannot find ID " & $ id)
  result = BlobReader(pos: 0)
  shallowCopy(result.s, blob)
  # ensure we can read without index checks:
  result.s.add '\0'

proc loadType(g; id: int; info: TLineInfo): PType =
  result = g.incr.r.types.getOrDefault(id)
  if result != nil: return result
  var b = loadBlob(g, sql"select data from types where nimid = ?", id)

  if b.s[b.pos] == '[':
    inc(b.pos)
    if b.s[b.pos] == ']':
      inc(b.pos)
      return                  # nil type
  new(result)
  result.kind = TTypeKind(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == '+':
    inc(b.pos)
    result.uniqueId = decodeVInt(b.s, b.pos)
    setId(result.uniqueId)
    #if debugIds: registerID(result)
  else:
    internalError(g.config, info, "loadType: no id")
  if b.s[b.pos] == '+':
    inc(b.pos)
    result.id = decodeVInt(b.s, b.pos)
  else:
    result.id = result.uniqueId
  # here this also avoids endless recursion for recursive type
  g.incr.r.types.add(result.uniqueId, result)
  if b.s[b.pos] == '(': result.n = decodeNode(g, b, unknownLineInfo)
  if b.s[b.pos] == '$':
    inc(b.pos)
    result.flags = cast[TTypeFlags](int32(decodeVInt(b.s, b.pos)))
  if b.s[b.pos] == '?':
    inc(b.pos)
    result.callConv = TCallingConvention(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == '*':
    inc(b.pos)
    result.owner = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == '&':
    inc(b.pos)
    result.sym = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == '/':
    inc(b.pos)
    result.size = decodeVInt(b.s, b.pos)
  else:
    result.size = -1
  if b.s[b.pos] == '=':
    inc(b.pos)
    result.align = decodeVInt(b.s, b.pos).int16
  else:
    result.align = 2

  if b.s[b.pos] == '\14':
    inc(b.pos)
    result.lockLevel = decodeVInt(b.s, b.pos).TLockLevel
  else:
    result.lockLevel = UnspecifiedLockLevel

  if b.s[b.pos] == '\15':
    inc(b.pos)
    result.paddingAtEnd = decodeVInt(b.s, b.pos).int16

  for a in low(result.attachedOps)..high(result.attachedOps):
    if b.s[b.pos] == '\16':
      inc(b.pos)
      let id = decodeVInt(b.s, b.pos)
      if id >= 0:
        result.attachedOps[a] = loadSym(g, id, info)

  while b.s[b.pos] == '\19':
    inc(b.pos)
    let x = decodeVInt(b.s, b.pos)
    doAssert b.s[b.pos] == '\20'
    inc(b.pos)
    let y = loadSym(g, decodeVInt(b.s, b.pos), info)
    result.methods.add((x, y))
  decodeLoc(g, b, result.loc, info)
  if b.s[b.pos] == '\21':
    inc(b.pos)
    let d = decodeVInt(b.s, b.pos)
    result.typeInst = loadType(g, d, info)
  while b.s[b.pos] == '^':
    inc(b.pos)
    if b.s[b.pos] == '(':
      inc(b.pos)
      if b.s[b.pos] == ')': inc(b.pos)
      else: internalError(g.config, info, "loadType ^(" & b.s[b.pos])
      rawAddSon(result, nil)
    else:
      let d = decodeVInt(b.s, b.pos)
      when not defined(release):
        if not typeAlreadyStored(g, d):
          raise newException(Defect, "the type is not in the db")
      result.sons.add loadType(g, d, info)

proc decodeLib(g; b; info: TLineInfo): PLib =
  result = nil
  if b.s[b.pos] == '|':
    new(result)
    inc(b.pos)
    result.kind = TLibKind(decodeVInt(b.s, b.pos))
    if b.s[b.pos] != '|': internalError(g.config, "decodeLib: 1")
    inc(b.pos)
    result.name = rope(decodeStr(b.s, b.pos))
    if b.s[b.pos] != '|': internalError(g.config, "decodeLib: 2")
    inc(b.pos)
    result.path = decodeNode(g, b, info)

proc decodeInstantiations(g; b; info: TLineInfo;
                          s: var seq[PInstantiation]) =
  while b.s[b.pos] == '\15':
    inc(b.pos)
    var ii: PInstantiation
    new ii
    ii.sym = loadSym(g, decodeVInt(b.s, b.pos), info)
    ii.concreteTypes = @[]
    while b.s[b.pos] == '\17':
      inc(b.pos)
      ii.concreteTypes.add loadType(g, decodeVInt(b.s, b.pos), info)
    if b.s[b.pos] == '\20':
      inc(b.pos)
      ii.compilesId = decodeVInt(b.s, b.pos)
    s.add ii

proc loadSymFromBlob(g; b; info: TLineInfo): PSym =
  if b.s[b.pos] == '{':
    inc(b.pos)
    if b.s[b.pos] == '}':
      inc(b.pos)
      return                  # nil sym
  var k = TSymKind(decodeVInt(b.s, b.pos))
  var id: int
  if b.s[b.pos] == '+':
    inc(b.pos)
    id = decodeVInt(b.s, b.pos)
    setId(id)
  else:
    internalError(g.config, info, "decodeSym: no id")
  var ident: PIdent
  if b.s[b.pos] == '&':
    inc(b.pos)
    ident = g.cache.getIdent(decodeStr(b.s, b.pos))
  else:
    internalError(g.config, info, "decodeSym: no ident")
  #echo "decoding: {", ident.s
  result = PSym(id: id, kind: k, name: ident)
  # read the rest of the symbol description:
  g.incr.r.syms.add(result.id, result)
  if b.s[b.pos] == '^':
    inc(b.pos)
    result.typ = loadType(g, decodeVInt(b.s, b.pos), info)
  decodeLineInfo(g, b, result.info)
  if b.s[b.pos] == '*':
    inc(b.pos)
    result.owner = loadSym(g, decodeVInt(b.s, b.pos), result.info)
  if b.s[b.pos] == '$':
    inc(b.pos)
    result.flags = cast[TSymFlags](decodeVBiggestInt(b.s, b.pos))
  if b.s[b.pos] == '@':
    inc(b.pos)
    result.magic = TMagic(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == '!':
    inc(b.pos)
    result.options = cast[TOptions](int32(decodeVInt(b.s, b.pos)))
  if b.s[b.pos] == '%':
    inc(b.pos)
    result.position = decodeVInt(b.s, b.pos)
  if b.s[b.pos] == '`':
    inc(b.pos)
    result.offset = decodeVInt(b.s, b.pos)
  else:
    result.offset = -1
  decodeLoc(g, b, result.loc, result.info)
  result.annex = decodeLib(g, b, info)
  if b.s[b.pos] == '#':
    inc(b.pos)
    result.constraint = decodeNode(g, b, unknownLineInfo)
  case result.kind
  of skType, skGenericParam:
    while b.s[b.pos] == '\14':
      inc(b.pos)
      result.typeInstCache.add loadType(g, decodeVInt(b.s, b.pos), result.info)
  of routineKinds:
    decodeInstantiations(g, b, result.info, result.procInstCache)
    if b.s[b.pos] == '\16':
      inc(b.pos)
      result.gcUnsafetyReason = loadSym(g, decodeVInt(b.s, b.pos), result.info)
    if b.s[b.pos] == '\24':
      inc b.pos
      result.transformedBody = decodeNode(g, b, result.info)
      #result.transformedBody = nil
  of skModule, skPackage:
    decodeInstantiations(g, b, result.info, result.usedGenerics)
  of skLet, skVar, skField, skForVar:
    if b.s[b.pos] == '\18':
      inc(b.pos)
      result.guard = loadSym(g, decodeVInt(b.s, b.pos), result.info)
    if b.s[b.pos] == '\19':
      inc(b.pos)
      result.bitsize = decodeVInt(b.s, b.pos).int16
  else: discard

  if b.s[b.pos] == '(':
    #if result.kind in routineKinds:
    #  result.ast = nil
    #else:
    result.ast = decodeNode(g, b, result.info)
  if sfCompilerProc in result.flags:
    registerCompilerProc(g, result)
    #echo "loading ", result.name.s

proc loadSym(g; id: int; info: TLineInfo): PSym =
  result = g.incr.r.syms.getOrDefault(id)
  if result != nil: return result
  var b = loadBlob(g, sql"select data from syms where nimid = ?", id)
  result = loadSymFromBlob(g, b, info)
  doAssert id == result.id, "symbol ID is not consistent!"

proc registerModule*(g; module: PSym) =
  g.incr.r.syms.add(abs module.id, module)

proc loadModuleSymTab(g; module: PSym) =
  ## goal: fill  module.tab
  g.incr.r.syms.add(module.id, module)
  for row in db.fastRows(sql"select nimid, data from syms where module = ? and exported = 1", abs(module.id)):
    let id = parseInt(row[0])
    var s = g.incr.r.syms.getOrDefault(id)
    if s == nil:
      var b = BlobReader(pos: 0)
      shallowCopy(b.s, row[1])
      # ensure we can read without index checks:
      b.s.add '\0'
      s = loadSymFromBlob(g, b, module.info)
    assert s != nil
    if s.kind != skField:
      strTableAdd(module.tab, s)
  if sfSystemModule in module.flags:
    g.systemModule = module

proc replay(g: ModuleGraph; module: PSym; n: PNode) =
  # XXX check if we need to replay nkStaticStmt here.
  case n.kind
  #of nkStaticStmt:
    #evalStaticStmt(module, g, n[0], module)
    #of nkVarSection, nkLetSection:
    #  nkVarSections are already covered by the vmgen which produces nkStaticStmt
  of nkMethodDef:
    methodDef(g, n[namePos].sym, fromCache=true)
  of nkCommentStmt:
    # pragmas are complex and can be user-overriden via templates. So
    # instead of using the original ``nkPragma`` nodes, we rely on the
    # fact that pragmas.nim was patched to produce specialized recorded
    # statements for us in the form of ``nkCommentStmt`` with (key, value)
    # pairs. Ordinary nkCommentStmt nodes never have children so this is
    # not ambiguous.
    # Fortunately only a tiny subset of the available pragmas need to
    # be replayed here. This is always a subset of ``pragmas.stmtPragmas``.
    if n.len >= 2:
      internalAssert g.config, n[0].kind == nkStrLit and n[1].kind == nkStrLit
      case n[0].strVal
      of "hint": message(g.config, n.info, hintUser, n[1].strVal)
      of "warning": message(g.config, n.info, warnUser, n[1].strVal)
      of "error": localError(g.config, n.info, errUser, n[1].strVal)
      of "compile":
        internalAssert g.config, n.len == 3 and n[2].kind == nkStrLit
        let cname = AbsoluteFile n[1].strVal
        var cf = Cfile(nimname: splitFile(cname).name, cname: cname,
                       obj: AbsoluteFile n[2].strVal,
                       flags: {CfileFlag.External})
        extccomp.addExternalFileToCompile(g.config, cf)
      of "link":
        extccomp.addExternalFileToLink(g.config, AbsoluteFile n[1].strVal)
      of "passl":
        extccomp.addLinkOption(g.config, n[1].strVal)
      of "passc":
        extccomp.addCompileOption(g.config, n[1].strVal)
      of "localpassc":
        extccomp.addLocalCompileOption(g.config, n[1].strVal, toFullPathConsiderDirty(g.config, module.info.fileIndex))
      of "cppdefine":
        options.cppDefine(g.config, n[1].strVal)
      of "inc":
        let destKey = n[1].strVal
        let by = n[2].intVal
        let v = getOrDefault(g.cacheCounters, destKey)
        g.cacheCounters[destKey] = v+by
      of "put":
        let destKey = n[1].strVal
        let key = n[2].strVal
        let val = n[3]
        if not contains(g.cacheTables, destKey):
          g.cacheTables[destKey] = initBTree[string, PNode]()
        if not contains(g.cacheTables[destKey], key):
          g.cacheTables[destKey].add(key, val)
        else:
          internalError(g.config, n.info, "key already exists: " & key)
      of "incl":
        let destKey = n[1].strVal
        let val = n[2]
        if not contains(g.cacheSeqs, destKey):
          g.cacheSeqs[destKey] = newTree(nkStmtList, val)
        else:
          block search:
            for existing in g.cacheSeqs[destKey]:
              if exprStructuralEquivalent(existing, val, strictSymEquality=true):
                break search
            g.cacheSeqs[destKey].add val
      of "add":
        let destKey = n[1].strVal
        let val = n[2]
        if not contains(g.cacheSeqs, destKey):
          g.cacheSeqs[destKey] = newTree(nkStmtList, val)
        else:
          g.cacheSeqs[destKey].add val
      else:
        internalAssert g.config, false
  of nkImportStmt:
    for x in n:
      internalAssert g.config, x.kind == nkSym
      let modpath = AbsoluteFile toFullPath(g.config, x.sym.info)
      let imported = g.importModuleCallback(g, module, fileInfoIdx(g.config, modpath))
      internalAssert g.config, imported.id < 0
  of nkStmtList, nkStmtListExpr:
    for x in n: replay(g, module, x)
  of nkExportStmt:
    for x in n:
      doAssert x.kind == nkSym
      strTableAdd(module.tab, x.sym)
  else: discard "nothing to do for this node"

proc loadNode*(g: ModuleGraph; module: PSym): PNode =
  loadModuleSymTab(g, module)
  result = newNodeI(nkStmtList, module.info)
  for row in db.rows(sql"select data from toplevelstmts where module = ? order by position asc",
                        abs module.id):
    var b = BlobReader(pos: 0)
    # ensure we can read without index checks:
    b.s = row[0] & '\0'
    result.add decodeNode(g, b, module.info)
  db.exec(sql"insert into controlblock(idgen) values (?)", gFrontEndId)
  replay(g, module, result)

when false:
  proc tail(r: Rope; x: int): Rope =
    var
      i = 0
    # leaves are individual strings that were added to the rope
    for leaf in r.leaves:
      if i == x:
        # just add from here on out
        result &= rope(leaf)
      else:
        # we're still scanning for the index at which we should
        # start adding leaves to the result
        i.inc leaf.len
        if i > x:
          # the assumption is that adds to ropes are atomic with
          # leaves; that every leaf represents an add
          raise newException(Defect, "bad assumption wrt leaves")

when false:
  proc storeNode(g: ModuleGraph; m: PSym; p: PSym): auto =
    storeSym(g, p)

  proc storeNode(g: ModuleGraph; m: PSym; p: PType): auto =
    storeType(g, p)

proc setupModuleCache*(g: ModuleGraph) =
  if g.config.symbolFiles == disabledSf:
    return
  g.recordStmt = recordStmt
  let dbfile = getNimcacheDir(g.config) / RelativeFile"rodfiles.db"
  if g.config.symbolFiles == writeOnlySf:
    removeFile(dbfile)
  createDir getNimcacheDir(g.config)
  let ec = encodeConfig(g)
  if not fileExists(dbfile):
    db = open(connection=string dbfile, user="nim", password="",
              database="nim")
    createDb(db)
    db.exec(sql"insert into config(config) values (?)", ec)
  else:
    db = open(connection=string dbfile, user="nim", password="",
              database="nim")
    let oldConfig = db.getValue(sql"select config from config")
    g.incr.configChanged = oldConfig != ec
    # ensure the filename IDs stay consistent:
    for row in db.rows(sql"select fullpath, nimid from filenames order by nimid"):
      let id = fileInfoIdx(g.config, AbsoluteFile row[0])
      doAssert id.int == parseInt(row[1])
    db.exec(sql"update config set config = ?", ec)
  db.exec(sql"pragma journal_mode=off")
  # This MUST be turned off, otherwise it's way too slow even for testing purposes:
  db.exec(sql"pragma SYNCHRONOUS=off")
  db.exec(sql"pragma LOCKING_MODE=exclusive")
  let lastId = db.getValue(sql"select max(idgen) from controlblock")
  if lastId.len > 0:
    idgen.setId(parseInt lastId)

proc encodeTransform(t: Transform): string =
  case t.kind:
  of HeaderFile:
    result = t.filenames.join("\0")
  of ThingSet, ProtoSet, SwingSet, JetSet, ReSet:
    result = mapIt(t.diff, $it).join("\0")
  of FlagSet:
    result = mapIt(t.flags, $it).join("\0")
  of Injection:
    result = $t.rope
  of GraphRope:
    result = $t.grope
  of TypeStack:
    result = mapIt(t.stack, $it.uniqueId).join("\0")
  else:
    discard

proc decodeTransform(kind: string, module: BModule;
                     data: string): Transform =
  result = Transform(kind: parseEnum[TransformKind](kind), module: module)
  case result.kind:
  of HeaderFile:
    result.filenames = data.split('\0')
  of ThingSet, ProtoSet, SwingSet, JetSet, ReSet:
    for value in mapIt(data.split('\0'), parseInt(it)):
      result.diff.incl value
  of FlagSet:
    for value in mapIt(data.split('\0'), parseEnum[CodegenFlag](it)):
      result.flags.incl value
  of Injection:
    result.rope = rope(data)
  of GraphRope:
    result.grope = rope(data)
  of TypeStack:
    for value in mapIt(data.split('\0'), parseInt(it)):
      # XXX: fake out; terrible
      result.stack.add loadType(module.g.graph, value,
                                module.module.info)
  else:
    discard

proc storeTransform*[T](g: ModuleGraph; node: T; transform: Transform) =
  const
    insertion = sql"""
      insert into transforms (signature, module, kind, data)
      values (?, ?, ?, ?)
    """
  let
    mid = if transform.module == nil: 0 else: transform.module.module.id
  db.exec(insertion, $sigHash(node), mid,
          transform.kind, encodeTransform(transform))

template mergeRopes(cache: CacheUnit;
                    parent: var BModuleList;
                    child: BModuleList; name: untyped) =
  if child.`name` != nil:
    if parent.`name` == nil:
      parent.`name` = child.`name`
    else:
      parent.`name`.add child.`name`
    let
      transform = Transform(kind: TransformKind.GraphRope,
                            grope: child.`name`)
    storeTransform(cache.graph, cache.node, transform)

template mergeRopes(cache: CacheUnit; parent: var BModule;
                    child: BModule; name: untyped) =
  if child.`name` != nil:
    if parent.`name` == nil:
      parent.`name` = child.`name`
    else:
      parent.`name`.add child.`name`
    let
      transform = Transform(kind: Injection, module: parent,
                            rope: child.`name`)
    storeTransform(cache.graph, cache.node, transform)

template mergeIdSets(cache: CacheUnit;
                     parent: var BModule; child: BModule;
                     kind: TransformKind; name: untyped) =
  if parent.`name`.len != child.`name`.len:
    assert (parent.`name` - child.`name`).len == 0
    var
      transform: Transform
    case kind
    of ProtoSet:
      transform = Transform(kind: ProtoSet, module: parent)
    of ThingSet:
      transform = Transform(kind: ThingSet, module: parent)
    else:
      raise newException(Defect, "bad kind")
    transform.diff = child.`name` - parent.`name`
    parent.`name` = parent.`name` + child.`name`
    storeTransform(cache.graph, cache.node, transform)

template mergeHeaders(cache: CacheUnit;
                      parent: var BModule; child: BModule; name: untyped) =

  # nil-separated list?
  var
    transform = Transform(kind: HeaderFile, module: parent)
  for filename in child.headerFiles:
    if filename notin parent.headerFiles:
      parent.headerFiles.add filename
      transform.filenames.add filename
  if transform.filenames.len > 0:
    storeTransform(cache.graph, cache.node, transform)

iterator loadTransforms*(g: ModuleGraph;
                         modules: BModuleList; p: PSym): Transform =
  const
    selection = sql"""
      select kind, module, data
      from syms left join transforms
      where syms.name = transforms.signature and syms.name = ?
    """
  let
    name = $p.sigHash
  for row in db.fastRows(selection, name):
    # search for the snippets for the given symbol
    let
      mid = row[1].parseInt
    var
      module: BModule
    if mid != 0:
      block found:
        # the modules in the modules list are in the modules list
        for m in modules.modules.items:
          # the module id is in the module's module field
          if m.module.id == mid:
            module = m
            break found
        # we didn't find the matching backend module; for now we throw
        raise newException(Defect, "could not match module")
      # module may be nil to indicate that the transform applies to
      # the entire module graph as opposed to a single module
      yield decodeTransform(row[0], module, row[2])

proc mergeSharedTables(cache: CacheUnit;
                       parent: var BModule; child: BModule)
  {.deprecated.} =
  # ❌we are sharing these (for now!)
  ## [SHARE?] sigs -> ropes

  # copy the types over
  for signature, rope in child.typeCache.pairs:
    if signature notin parent.typeCache:
      parent.typeCache[signature] = rope
    when not defined(release):
      echo "typecache size: ", child.typeCache.len
      # XXX

  ## [SHARE?] sigs -> ropes

  # copy the forwarded types over
  for signature, rope in child.forwTypeCache.pairs:
    if signature notin parent.forwTypeCache:
      parent.forwTypeCache[signature] = rope
    when not defined(release):
      echo "forwTypeCache size: ", child.forwTypeCache.len
      # XXX

  ## [SHARE?] sigs -> ropes

  # copy the type info markers over
  for signature, rope in child.typeInfoMarker.pairs:
    if signature notin parent.typeInfoMarker:
      parent.typeInfoMarker[signature] = rope
    when not defined(release):
      echo "typeinfomarker size: ", child.typeInfoMarker.len
      # XXX

proc mergeSections(cache: CacheUnit;
                   parent: var BModule; child: BModule) =
  # copy the generated procs, etc.
  for section, rope in child.s.pairs:
    if rope != nil:
      if parent.s[section] == nil:
        parent.s[section] = rope
      else:
        parent.s[section].add rope
      when not defined(release):
        echo "section ", section,  " length ", rope.len

proc merge(cache: CacheUnit; parent: var BModule; child: BModule) =
  ## miscellaneous ropes
  cache.mergeRopes(parent, child, injectStmt)

  # --- XXX --- we aren't saving these yet
  if parent.initProc.prc == nil and child.initProc.prc != nil:
    parent.initProc = child.initProc
  if parent.preInitProc.prc == nil and child.preInitProc.prc != nil:
    parent.preInitProc = child.preInitProc

  cache.mergeHeaders parent, child, headerFiles

  # 0. flags
  if parent.flags != child.flags:
    let
      transform = Transform(kind: FlagSet, module: parent,
                            flags: child.flags - parent.flags)
    parent.flags = child.flags
    storeTransform(cache.graph, cache.node, transform)

  when defined(tooSlowForMe):
    for pair in child.dataCache.data.items:
      parent.dataCache.nodeTablePutHash(pair.h, pair.key, pair.val)

  ## ✅1. ropes to store per section
  cache.mergeSections(parent, child)

  ## ❌2. ptypes to store

  # copy the types over
  var
    transform = Transform(kind: TypeStack, module: parent)
  for ptype in child.typeStack:
    parent.pushType ptype
    transform.stack.add ptype
    storeTransform(cache.graph, cache.node, transform)
  ## this silliness is due to a bug with templates and enums...

  #cache.mergeIdSets parent, child, TransformKind.ProtoSet, declaredProtos
  if parent.declaredProtos.len != child.declaredProtos.len:
    assert (parent.declaredProtos - child.declaredProtos).len == 0
    var
      transform: Transform
    case ProtoSet
    of ProtoSet:
      transform = Transform(kind: ProtoSet, module: parent)
    of ThingSet:
      transform = Transform(kind: ThingSet, module: parent)
    else:
      raise newException(Defect, "bad kind")
    transform.diff = child.declaredProtos - parent.declaredProtos
    parent.declaredProtos = parent.declaredProtos + child.declaredProtos
    storeTransform(cache.graph, cache.node, transform)

  #cache.mergeIdSets parent, child, TransformKind.ThingSet, declaredThings
  if parent.declaredThings.len != child.declaredThings.len:
    assert (parent.declaredThings - child.declaredThings).len == 0
    var
      transform: Transform
    case ThingSet
    of ProtoSet:
      transform = Transform(kind: ProtoSet, module: parent)
    of ThingSet:
      transform = Transform(kind: ThingSet, module: parent)
    else:
      raise newException(Defect, "bad kind")
    transform.diff = child.declaredThings - parent.declaredThings
    parent.declaredThings = parent.declaredThings + child.declaredThings
    storeTransform(cache.graph, cache.node, transform)

proc merge*(cache: CacheUnit; parent: var BModuleList) =
  template child(): BModuleList = cache.modules
  cache.mergeRopes(parent, child, mainModProcs)
  cache.mergeRopes(parent, child, mainModInit)
  cache.mergeRopes(parent, child, otherModsInit)
  cache.mergeRopes(parent, child, mainDatInit)
  cache.mergeRopes(parent, child, mapping)

  # XXX: graph changes that need to be in transforms ^^^

  # merge child modules
  for m in child.modules.items:
    if m != nil:
      var
        dad = findModule(parent, m)

      # parent is the final backend module in codegen
      if dad != nil:
        cache.merge(dad, m)
      else:
        raise newException(Defect,
                           "could not find parent of " & $m.module.id)

proc isHot*(cache: CacheUnit): bool =
  result = snippetAlreadyStored(cache.graph, cache.node)


proc store*(cache: CacheUnit) =
  if cache.graph.config.symbolFiles in {disabledSf, readOnlySf}:
    raise newException(Defect, "attempt to store cache")

  # work around mutation of symbol
  cache.graph.unstoreSym(cache.node)
  cache.graph.storeSym(cache.node)

  # write snippets
  for module in cache.modules.modules.items:
    if module != nil:
      for section in TCFileSection.low .. TCFileSection.high:
        if module.s[section] != nil:
          var
            snippet = newSnippet(cache.node, module, section)
          snippet.code = module.s[section]
          storeSnippet(cache.graph, snippet)

proc load*(cache: var CacheUnit; list: BModuleList) =
  if cache.graph.config.symbolFiles in {disabledSf, writeOnlySf}:
    raise newException(Defect, "attempt to load cache")

  # work around mutation of symbol
  let
    sym = cache.graph.loadSym(cache.node.id, cache.node.info)
  cache.node = sym

  # read transforms
  # XXX: STEP NEXT

  # read snippets
  for snippet in cache.graph.loadSnippets(list, cache.node):
    let
      m = findModule(list, snippet.module)
    #cache.snippets[snippet.signature] = snippet
    when not defined(release):
      echo "\t", snippet.section, "\t", snippet.module.module.id
    # if the snippet writes to proc headers, mark the proc as declared
    when false:
      if snippet.section == cfsProcHeaders:
        m.declaredProtos.incl prc.id
    if m.s[snippet.section] == nil:
      m.s[snippet.section] = rope("")
    when not defined(release):
      m.s[snippet.section].add fmt"""

/*
cachable: id {cache.node.id} module id {m.module.id}
owner nil: {cache.node.owner == nil}
owner kind: {cache.node.owner.kind}
compiler proc  loc: {lfImportCompilerProc in cache.node.loc.flags}
compiler proc flag: {sfCompilerProc in cache.node.flags}
*/

          """.rope
      m.s[snippet.section].add fmt"""

/*
{cache.node.name.s}
=====================
cached data from {snippet.section}
module: {m.cfilename}
flags: {cache.node.flags}
  loc: {cache.node.loc.flags}
*/

          """.rope
      m.s[snippet.section].add snippet.code
      when not defined(release):
        m.s[snippet.section].add "/* end */\n".rope
      #when not defined(release):
      #  echo "\t", snippet.code
    when false:
      if m.s[snippet.section] == nil:
        m.s[snippet.section] = snippet.code
      else:
        m.s[snippet.section].add snippet.code
