import

  ".." / [ ast, cgendata, sighashes, options, modulegraphs, pathutils,
  ropes, astalgo, nversion, condsyms, lineinfos, incremental, msgs, idgen,
  btrees, idents, magicsys, cgmeth, extccomp, trees ]

import

  std / [ db_sqlite, intsets, strutils, tables ]

import

  spec, utils, store

type
  SqlId = int64

template db(): DbConn = g.incr.db
template config(): ConfigRef = cache.modules.config

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

  when false:
    if t.sym == nil and t.kind == tyProc:
      echo "NIL SYMBOL FOR PROC"
      debug t
      raise

  if not containsOrIncl(w.tmarks, t.uniqueId):
    w.tstack.add(t)
    if t.kind == tyGenericInst:
      if t.sons.len == 0:
        raise newException(Defect, "write of generic instance w/o sons")

proc pushSym(w: var Writer, s: PSym) =
  if not containsOrIncl(w.smarks, s.id):
    w.sstack.add(s)

template w: untyped = g.incr.w

proc encodeNode*(g: ModuleGraph; fInfo: TLineInfo; n: PNode;
                 result: var EncodingString) =
  if n == nil:
    # nil nodes have to be stored too:
    result.add OpenNode, CloseNode
    return
  result.add OpenNode
  # we do not write comments for now
  # Line information takes easily 20% or more of the filesize! Therefore we
  # omit line information if it is the same as the parent's line information:
  result.addLineInfoDelta n.info, fInfo
  # No need to output the file index, as this is the serialization of one
  # file.
  let f = n.flags * PersistentNodeFlags
  if f != {}:
    result.add SomeFlags
    result.add cast[int32](f)
  if n.typ != nil:
    result.add UniqueId
    result.add n.typ.uniqueId

    when false:
      if n.typ.sym == nil:
        echo "ENCODE NODE WITH NIL TYP.SYM"
        debug n.typ
        when false:
          if n.kind == nkSym and n.sym != nil:
            n.typ.sym = n.sym
          else:
            echo "IT IS AN ", n.kind
            raise

    pushType(w, n.typ)
  case n.kind
  of nkCharLit..nkUInt64Lit:
    if n.intVal != 0:
      result.add AnLiteral
      result.add n.intVal
  of nkFloatLit..nkFloat64Lit:
    if n.floatVal != 0.0:
      result.add AnLiteral
      encodeStr($n.floatVal, result)
  of nkStrLit..nkTripleStrLit:
    if n.strVal != "":
      result.add AnLiteral
      encodeStr(n.strVal, result)
  of nkIdent:
    result.add AnLiteral
    encodeStr(n.ident.s, result)
  of nkSym:
    result.add AnLiteral
    result.add n.sym.id
    pushSym(w, n.sym)
  else:
    for i in 0..<n.len:
      encodeNode(g, n.info, n[i], result)
  result.add(CloseNode)

proc encodeLoc*(g: ModuleGraph; loc: TLoc, result: var EncodingString) =
  var oldLen = result.len
  result.add OpenLoc
  if loc.k != low(loc.k):
    result.add ord(loc.k)
  if loc.storage != low(loc.storage):
    result.add LocStorage
    result.add ord(loc.storage)
  if loc.flags != {}:
    result.add SomeFlags
    result.add cast[int32](loc.flags)
  if loc.lode != nil:
    result.add AnNode
    encodeNode(g, unknownLineInfo, loc.lode, result)
  when compiles(loc.t):
    if loc.t != nil:
      result.add AnType
      encodeNode(g, unknownLineInfo, loc.lode, result)
  if loc.r != nil:
    result.add AnLiteral
    encodeStr($loc.r, result)
  if oldLen + 1 == result.len:
    # no data was necessary, so remove the '<' again:
    setLen(result, oldLen)
  else:
    result.add CloseLoc

proc encodeType(g: ModuleGraph, t: PType, result: var EncodingString) =
  if t == nil:
    # nil nodes have to be stored too:
    result.add OpenType
    result.add CloseType
    return
  # we need no surrounding [] here because the type is in a line of its own
  if t.kind == tyForward: internalError(g.config, "encodeType: tyForward")
  # for the new rodfile viewer we use a preceding [ so that the data section
  # can easily be disambiguated:
  result.add OpenType
  result.add ord(t.kind)
  result.add UniqueId
  result.add t.uniqueId
  if t.id != t.uniqueId:
    result.add UniqueId
    result.add t.id
  if t.n != nil:
    encodeNode(g, unknownLineInfo, t.n, result)
  if t.flags != {}:
    result.add SomeFlags
    result.add cast[int32](t.flags)
  if t.callConv != low(t.callConv):
    result.add CallConv
    result.add ord(t.callConv)
  if t.owner != nil:
    result.add OwnerId
    result.add t.owner.id
    pushSym(w, t.owner)
  if t.sym != nil:
    result.add SymbolId
    result.add t.sym.id
    pushSym(w, t.sym)
  if t.size != - 1:
    result.add SizeValue
    result.add t.size
  if t.align != 2:
    result.add TypeAlignment
    result.add t.align
  if t.lockLevel.ord != UnspecifiedLockLevel.ord:
    result.add LockLevel
    result.add t.lockLevel.int16
  if t.paddingAtEnd != 0:
    result.add PaddingAtEnd
    result.add t.paddingAtEnd
  for a in t.attachedOps:
    result.add AttachedOps
    if a == nil:
      result.add -1
    else:
      result.add a.id
      pushSym(w, a)
  for i, s in items(t.methods):
    result.add MethodIndex
    result.add i
    result.add MethodId
    result.add s.id
    pushSym(w, s)
  encodeLoc(g, t.loc, result)
  if t.typeInst != nil:
    result.add TypeInst
    result.add t.typeInst.uniqueId
    # XXX: keep an eye on this
    pushType(w, t.typeInst)
  for i in 0..<t.len:
    if t[i] == nil:
      result.add TypeId, OpenNode, CloseNode
    else:
      result.add TypeId
      result.add t[i].uniqueId
      pushType(w, t[i])

proc encodeLib(g: ModuleGraph, lib: PLib, info: TLineInfo, result: var EncodingString) =
  result.add('|')
  result.add ord(lib.kind)
  result.add('|')
  encodeStr($lib.name, result)
  result.add('|')
  encodeNode(g, info, lib.path, result)

proc encodeInstantiations(g: ModuleGraph; s: seq[PInstantiation];
                          result: var EncodingString) =
  for t in s:
    result.add SymbolId
    result.add t.sym.id
    pushSym(w, t.sym)
    for tt in t.concreteTypes:
      result.add UniqueId
      result.add tt.uniqueId
      pushType(w, tt)
    result.add TypeCompiles
    result.add t.compilesId

proc encodeSym(g: ModuleGraph, s: PSym, result: var EncodingString) =
  if s == nil:
    # nil nodes have to be stored too:
    result.add("{}")
    return
  # we need no surrounding {} here because the symbol is in a line of its own
  result.add ord(s.kind)
  result.add UniqueId
  result.add s.id
  result.add('&')
  encodeStr(s.name.s, result)
  if s.typ != nil:
    result.add('^')
    result.add s.typ.uniqueId
    when false:
      if s.typ.sym == nil:
        debug s
        raise
    pushType(w, s.typ)
  result.addLineInfo LineColFile, s.info
  if s.owner != nil:
    result.add OwnerId
    result.add s.owner.id
    pushSym(w, s.owner)
  if s.flags != {}:
    result.add SymbolFlags
    result.add cast[int64](s.flags)
  if s.magic != mNone:
    result.add SymbolMagic
    result.add ord(s.magic)
  result.add AnLiteral
  result.add cast[int32](s.options)
  if s.position != 0:
    result.add SymbolPos
    result.add s.position
  if s.offset != - 1:
    result.add SymbolOffset
    result.add s.offset
  encodeLoc(g, s.loc, result)
  if s.annex != nil: encodeLib(g, s.annex, s.info, result)
  if s.constraint != nil:
    result.add SymbolConstraint
    encodeNode(g, unknownLineInfo, s.constraint, result)
  case s.kind
  of skType, skGenericParam:
    for t in s.typeInstCache:
      result.add TypeInst
      result.add t.uniqueId
      pushType(w, t)
  of routineKinds:
    encodeInstantiations(g, s.procInstCache, result)
    if s.gcUnsafetyReason != nil:
      result.add Unsafety
      result.add s.gcUnsafetyReason.id
      pushSym(w, s.gcUnsafetyReason)
    if s.transformedBody != nil:
      result.add Transformed
      encodeNode(g, s.info, s.transformedBody, result)
  of skModule, skPackage:
    encodeInstantiations(g, s.usedGenerics, result)
    # we don't serialize:
    #tab*: TStrTable         # interface table for modules
  of skLet, skVar, skField, skForVar:
    if s.guard != nil:
      result.add Guard
      result.add s.guard.id
      pushSym(w, s.guard)
    if s.bitsize != 0:
      result.add BitSize
      result.add s.bitsize
  else: discard
  # lazy loading will soon reload the ast lazily, so the ast needs to be
  # the last entry of a symbol:
  if s.ast != nil:
    # we used to attempt to save space here by only storing a dummy AST if
    # it is not necessary, but Nim's heavy compile-time evaluation features
    # make that unfeasible nowadays:
    encodeNode(g, s.info, s.ast, result)

proc typeId*(g: ModuleGraph; p: PType): SqlId =
  ## like typeAlreadyStored, but returns the SqlId
  const
    query = sql"""
      select id from types
      where nimid = ?
      limit 1
    """
  let
    m = p.ultimateOwner
    mid = if m == nil: 0 else: abs(m.id)
    id = db.getValue(query, mid, p.uniqueId)
  if id != "":
    result = id.parseInt

proc symbolId*(g: ModuleGraph; p: PSym): SqlId =
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

  var buf = newStringOfCap(160).EncodingString
  encodeSym(g, s, buf)
  const
    insertion = sql"""
      insert into syms (nimid, module, name, data, exported)
      values (?, ?, ?, ?, ?)
    """
  # XXX only store the name for exported symbols in order to speed up lookup
  # times once we enable the skStub logic.
  let
    m = getModule(s)
    mid = if m == nil: 0 else: abs(m.id)
    name = $s.sigHash
  db.exec(insertion, s.id, mid, name, buf, ord(sfExported in s.flags))

template symbolAlreadyStored*(g: ModuleGraph; p: PSym): bool =
  g.symbolId(p) != 0

proc typeAlreadyStored*(g: ModuleGraph; p: PType): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"select nimid from types where nimid = ? limit 1"
  result = db.getValue(query, p.uniqueId) == $p.uniqueId

proc typeAlreadyStored*(g: ModuleGraph; nimid: int): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"select nimid from types where nimid = ? limit 1"
  result = db.getValue(query, nimid) == $nimid

proc symbolAlreadyStored*(g: ModuleGraph; nimid: int): bool =
  if g.config.symbolFiles == disabledSf: return
  const
    query = sql"select nimid from symbols where nimid = ? limit 1"
  result = db.getValue(query, nimid) == $nimid

proc storeType(g: ModuleGraph; t: PType) =
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
  var buf = newStringOfCap(160).EncodingString
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
      db.exec(updation, mid, buf, t.uniqueId)
    else:
      db.exec(insertion, t.uniqueId, mid, buf)
  else:
    db.exec(insertion, t.uniqueId, mid, buf)

proc transitiveClosure(g: ModuleGraph) =
  var i = 0

  when false:
    when not defined(release):
      block found:
        block unfound:
          for t in w.tstack.items:
            if t.sym == nil:
              break unfound
          break found
        echo w.tstack.len, " items in the stack"
        for t in w.tstack.items:
          if t.sym == nil and t.kind == tyProc:
            debug t
            break
        raise

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
      storeType(g, t)
      when false:
        echo "popped type ", typeToString(t), " ", t.uniqueId
    else:
      break
    inc i

proc storeNode*(g: ModuleGraph; module: PSym; n: PNode) =
  if g.config.symbolFiles == disabledSf: return
  var buf = newStringOfCap(160).EncodingString
  encodeNode(g, module.info, n, buf)
  const
    insertion = sql"insert into toplevelstmts(module, position, data) values (?, ?, ?)"
  db.exec(insertion, abs(module.id), module.offset, buf)
  inc module.offset
  transitiveClosure(g)

proc recordStmt*(g: ModuleGraph; module: PSym; n: PNode) =
  storeNode(g, module, n)

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

using
  b: var BlobReader
  g: ModuleGraph

proc loadSym*(g; id: int, info: TLineInfo): PSym
proc loadType*(g; id: int, info: TLineInfo): PType

proc decodeLineInfo(g; b; info: var TLineInfo) =
  if b.s[b.pos] in {JustCol, LineAndCol, LineColFile}:
    inc(b.pos)
    if b.s[b.pos] == Comma: info.col = -1'i16
    else: info.col = int16(decodeVInt(b.s, b.pos))
    if b.s[b.pos] == Comma:
      inc(b.pos)
      if b.s[b.pos] == Comma: info.line = 0'u16
      else: info.line = uint16(decodeVInt(b.s, b.pos))
      if b.s[b.pos] == Comma:
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
  if b.s[b.pos] == OpenNode:
    inc(b.pos)
    if b.s[b.pos] == CloseNode:
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
      if b.s[b.pos] == AnLiteral:
        inc(b.pos)
        result.intVal = decodeVBiggestInt(b.s, b.pos)
    of nkFloatLit..nkFloat64Lit:
      if b.s[b.pos] == AnLiteral:
        inc(b.pos)
        var fl = decodeStr(b.s, b.pos)
        result.floatVal = parseFloat(fl)
    of nkStrLit..nkTripleStrLit:
      if b.s[b.pos] == AnLiteral:
        inc(b.pos)
        result.strVal = decodeStr(b.s, b.pos)
      else:
        result.strVal = ""
    of nkIdent:
      if b.s[b.pos] == AnLiteral:
        inc(b.pos)
        var fl = decodeStr(b.s, b.pos)
        result.ident = g.cache.getIdent(fl)
      else:
        internalError(g.config, result.info, "decodeNode: nkIdent")
    of nkSym:
      if b.s[b.pos] == AnLiteral:
        inc(b.pos)
        var id = decodeVInt(b.s, b.pos)
        result.sym = loadSym(g, id, result.info)
      else:
        internalError(g.config, result.info, "decodeNode: nkSym")
    else:
      var i = 0
      while b.s[b.pos] != CloseNode:
        when false:
          if belongsTo != nil and i == bodyPos:
            addSonNilAllowed(result, nil)
            belongsTo.offset = b.pos
            skipNode(b)
          else:
            discard
        addSonNilAllowed(result, decodeNodeLazyBody(g, b, result.info, nil))
        inc i
    if b.s[b.pos] == CloseNode: inc(b.pos)
    else: internalError(g.config, result.info, "decodeNode: ')' missing")
  else:
    internalError(g.config, fInfo, "decodeNode: '(' missing " & $b.pos)

proc decodeNode*(g; b; fInfo: TLineInfo): PNode =
  result = decodeNodeLazyBody(g, b, fInfo, nil)

proc decodeLoc*(g; b; loc: var TLoc, info: TLineInfo) =
  if b.s[b.pos] == OpenLoc:
    inc(b.pos)
    if b.s[b.pos] in {'0'..'9', 'a'..'z', 'A'..'Z'}:
      loc.k = TLocKind(decodeVInt(b.s, b.pos))
    else:
      loc.k = low(loc.k)
    if b.s[b.pos] == LocStorage:
      inc(b.pos)
      loc.storage = TStorageLoc(decodeVInt(b.s, b.pos))
    else:
      loc.storage = low(loc.storage)
    if b.s[b.pos] == SomeFlags:
      inc(b.pos)
      loc.flags = cast[TLocFlags](int32(decodeVInt(b.s, b.pos)))
    else:
      loc.flags = {}
    if b.s[b.pos] == AnNode:
      inc(b.pos)
      loc.lode = decodeNode(g, b, info)
      # rrGetType(b, decodeVInt(b.s, b.pos), info)
    else:
      loc.lode = nil
    if b.s[b.pos] == AnLiteral:
      inc(b.pos)
      loc.setRope(rope(decodeStr(b.s, b.pos)))
    else:
      loc.setRope(nil)
    if b.s[b.pos] == CloseLoc: inc(b.pos)
    else: internalError(g.config, info, "decodeLoc " & b.s[b.pos])

proc loadType*(g; id: int; info: TLineInfo): PType =
  result = g.incr.r.types.getOrDefault(id)
  if result != nil: return result
  var b = loadBlob(g, sql"select data from types where nimid = ?", id)

  if b.s[b.pos] == OpenType:
    inc(b.pos)
    if b.s[b.pos] == CloseType:
      inc(b.pos)
      return                  # nil type
  new(result)
  result.kind = TTypeKind(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == UniqueId:
    inc(b.pos)
    result.uniqueId = decodeVInt(b.s, b.pos)
    setId(result.uniqueId)
    #if debugIds: registerID(result)
  else:
    internalError(g.config, info, "loadType: no id")
  if b.s[b.pos] == UniqueId:
    inc(b.pos)
    result.id = decodeVInt(b.s, b.pos)
  else:
    result.id = result.uniqueId
  # here this also avoids endless recursion for recursive type
  g.incr.r.types.add(result.uniqueId, result)
  if b.s[b.pos] == OpenNode:
    result.n = decodeNode(g, b, unknownLineInfo)
  if b.s[b.pos] == SomeFlags:
    inc(b.pos)
    result.flags = cast[TTypeFlags](int32(decodeVInt(b.s, b.pos)))
  if b.s[b.pos] == CallConv:
    inc(b.pos)
    result.callConv = TCallingConvention(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == OwnerId:
    inc(b.pos)
    result.owner = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == SymbolId:
    inc(b.pos)
    result.sym = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == SizeValue:
    inc(b.pos)
    result.size = decodeVInt(b.s, b.pos)
  else:
    result.size = -1
  if b.s[b.pos] == TypeAlignment:
    inc(b.pos)
    result.align = decodeVInt(b.s, b.pos).int16
  else:
    result.align = 2

  if b.s[b.pos] == LockLevel:
    inc(b.pos)
    result.lockLevel = decodeVInt(b.s, b.pos).TLockLevel
  else:
    result.lockLevel = UnspecifiedLockLevel

  if b.s[b.pos] == PaddingAtEnd:
    inc(b.pos)
    result.paddingAtEnd = decodeVInt(b.s, b.pos).int16

  for a in low(result.attachedOps)..high(result.attachedOps):
    if b.s[b.pos] == AttachedOps:
      inc(b.pos)
      let id = decodeVInt(b.s, b.pos)
      if id >= 0:
        result.attachedOps[a] = loadSym(g, id, info)

  while b.s[b.pos] == MethodIndex:
    inc(b.pos)
    let x = decodeVInt(b.s, b.pos)
    doAssert b.s[b.pos] == MethodId
    inc(b.pos)
    let y = loadSym(g, decodeVInt(b.s, b.pos), info)
    result.methods.add((x, y))
  decodeLoc(g, b, result.mloc, info)
  if b.s[b.pos] == TypeInst:
    inc(b.pos)
    let d = decodeVInt(b.s, b.pos)
    result.typeInst = loadType(g, d, info)
  while b.s[b.pos] == TypeId:
    inc(b.pos)
    if b.s[b.pos] == OpenNode:
      inc(b.pos)
      if b.s[b.pos] == CloseNode: inc(b.pos)
      else: internalError(g.config, info, "loadType " & b.s[b.pos])
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
  if b.s[b.pos] == OpenSym:
    inc(b.pos)
    if b.s[b.pos] == CloseSym:
      inc(b.pos)
      return                  # nil sym
  var k = TSymKind(decodeVInt(b.s, b.pos))
  var id: int
  if b.s[b.pos] == UniqueId:
    inc(b.pos)
    id = decodeVInt(b.s, b.pos)
    setId(id)
  else:
    internalError(g.config, info, "decodeSym: no id")
  var ident: PIdent
  if b.s[b.pos] == AnIdent:
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
  if b.s[b.pos] == OwnerId:
    inc(b.pos)
    result.owner = loadSym(g, decodeVInt(b.s, b.pos), result.info)
  if b.s[b.pos] == SymbolFlags:
    inc(b.pos)
    result.flags = cast[TSymFlags](decodeVBiggestInt(b.s, b.pos))
  if b.s[b.pos] == SymbolMagic:
    inc(b.pos)
    result.magic = TMagic(decodeVInt(b.s, b.pos))
  if b.s[b.pos] == AnLiteral:
    inc(b.pos)
    result.options = cast[TOptions](int32(decodeVInt(b.s, b.pos)))
  if b.s[b.pos] == SymbolPos:
    inc(b.pos)
    result.position = decodeVInt(b.s, b.pos)
  if b.s[b.pos] == SymbolConstraint:
    inc(b.pos)
    result.offset = decodeVInt(b.s, b.pos)
  else:
    result.offset = -1
  decodeLoc(g, b, result.mloc, result.info)
  result.annex = decodeLib(g, b, info)
  if b.s[b.pos] == SymbolConstraint:
    inc(b.pos)
    result.constraint = decodeNode(g, b, unknownLineInfo)
  case result.kind
  of skType, skGenericParam:
    while b.s[b.pos] == TypeInst:
      inc(b.pos)
      result.typeInstCache.add loadType(g, decodeVInt(b.s, b.pos), result.info)
  of routineKinds:
    decodeInstantiations(g, b, result.info, result.procInstCache)
    if b.s[b.pos] == Unsafety:
      inc(b.pos)
      result.gcUnsafetyReason = loadSym(g, decodeVInt(b.s, b.pos), result.info)
    if b.s[b.pos] == Transformed:
      inc b.pos
      result.transformedBody = decodeNode(g, b, result.info)
      #result.transformedBody = nil
  of skModule, skPackage:
    decodeInstantiations(g, b, result.info, result.usedGenerics)
  of skLet, skVar, skField, skForVar:
    if b.s[b.pos] == Guard:
      inc(b.pos)
      result.guard = loadSym(g, decodeVInt(b.s, b.pos), result.info)
    if b.s[b.pos] == BitSize:
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

proc loadSym*(g; id: int; info: TLineInfo): PSym =
  result = g.incr.r.syms.getOrDefault(id)
  if result != nil: return result
  var b = loadBlob(g, sql"select data from syms where nimid = ?", id)
  try:
    result = loadSymFromBlob(g, b, info)
    echo "loaded ", result.name.s
  finally:
    echo "sym ", id, " "
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

template seal*(tree: typed) =
  ## furry lobster
  tree.sealed = true

template performCachingOnIt*(context: typed; n: PNode;
                             strategy: set[CacheStrategy];
                             body: untyped): untyped =
  let
    audit = it.hash
  var
    it {.inject.} = n
  try:
    body
  finally:
    context.seal

    when nimIcAudit:
      if audit != it.hash and Write notin strategy:
        raise newException(Defect, "audit fail")

template compileUncachedIt*(g: ModuleGraph; context: typed; n: PNode;
                            body: untyped): untyped =
  var
    it {.inject.} = n
  context.performCachingOnIt(n, {Write, Read}):
    body

template compileCachedIt*(g: ModuleGraph; context: typed; p: PSym;
                          body: untyped): untyped =
  var
    it {.inject.} = loadNode(graph, p)
  context.performCachingOnIt(n, {Read, Immutable}):
    body
