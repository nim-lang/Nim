#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the new compilation cache.

import strutils, os, intsets, tables, ropes, db_sqlite, msgs, options, types,
  renderer, rodutils, idents, astalgo, btrees, magicsys, cgmeth, extccomp,
  btrees, trees, condsyms, nversion, pathutils

## Todo:
## - Dependency computation should use *signature* hashes in order to
##   avoid recompiling dependent modules.
## - Patch the rest of the compiler to do lazy loading of proc bodies.
## - Patch the C codegen to cache proc bodies and maybe types.

template db(): DbConn = g.incr.db

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
      if not needsRecompile(g, fileIdx, fullpath, cycleCheck) and not g.incr.configChanged:
        echo "cached successfully! ", string fullpath
        return -result
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
    for i in 0 ..< sonsLen(n):
      encodeNode(g, n.info, n.sons[i], result)
  add(result, ')')

proc encodeLoc(g: ModuleGraph; loc: TLoc, result: var string) =
  var oldLen = result.len
  result.add('<')
  if loc.k != low(loc.k): encodeVInt(ord(loc.k), result)
  if loc.storage != low(loc.storage):
    add(result, '*')
    encodeVInt(ord(loc.storage), result)
  if loc.flags != {}:
    add(result, '$')
    encodeVInt(cast[int32](loc.flags), result)
  if loc.lode != nil:
    add(result, '^')
    encodeNode(g, unknownLineInfo(), loc.lode, result)
  if loc.r != nil:
    add(result, '!')
    encodeStr($loc.r, result)
  if oldLen + 1 == result.len:
    # no data was necessary, so remove the '<' again:
    setLen(result, oldLen)
  else:
    add(result, '>')

proc encodeType(g: ModuleGraph, t: PType, result: var string) =
  if t == nil:
    # nil nodes have to be stored too:
    result.add("[]")
    return
  # we need no surrounding [] here because the type is in a line of its own
  if t.kind == tyForward: internalError(g.config, "encodeType: tyForward")
  # for the new rodfile viewer we use a preceding [ so that the data section
  # can easily be disambiguated:
  add(result, '[')
  encodeVInt(ord(t.kind), result)
  add(result, '+')
  encodeVInt(t.uniqueId, result)
  if t.id != t.uniqueId:
    add(result, '+')
    encodeVInt(t.id, result)
  if t.n != nil:
    encodeNode(g, unknownLineInfo(), t.n, result)
  if t.flags != {}:
    add(result, '$')
    encodeVInt(cast[int32](t.flags), result)
  if t.callConv != low(t.callConv):
    add(result, '?')
    encodeVInt(ord(t.callConv), result)
  if t.owner != nil:
    add(result, '*')
    encodeVInt(t.owner.id, result)
    pushSym(w, t.owner)
  if t.sym != nil:
    add(result, '&')
    encodeVInt(t.sym.id, result)
    pushSym(w, t.sym)
  if t.size != - 1:
    add(result, '/')
    encodeVBiggestInt(t.size, result)
  if t.align != 2:
    add(result, '=')
    encodeVInt(t.align, result)
  if t.lockLevel.ord != UnspecifiedLockLevel.ord:
    add(result, '\14')
    encodeVInt(t.lockLevel.int16, result)
  if t.destructor != nil and t.destructor.id != 0:
    add(result, '\15')
    encodeVInt(t.destructor.id, result)
    pushSym(w, t.destructor)
  if t.deepCopy != nil:
    add(result, '\16')
    encodeVInt(t.deepcopy.id, result)
    pushSym(w, t.deepcopy)
  if t.assignment != nil:
    add(result, '\17')
    encodeVInt(t.assignment.id, result)
    pushSym(w, t.assignment)
  if t.sink != nil:
    add(result, '\18')
    encodeVInt(t.sink.id, result)
    pushSym(w, t.sink)
  for i, s in items(t.methods):
    add(result, '\19')
    encodeVInt(i, result)
    add(result, '\20')
    encodeVInt(s.id, result)
    pushSym(w, s)
  encodeLoc(g, t.loc, result)
  if t.typeInst != nil:
    add(result, '\21')
    encodeVInt(t.typeInst.uniqueId, result)
    pushType(w, t.typeInst)
  for i in 0 ..< sonsLen(t):
    if t.sons[i] == nil:
      add(result, "^()")
    else:
      add(result, '^')
      encodeVInt(t.sons[i].uniqueId, result)
      pushType(w, t.sons[i])

proc encodeLib(g: ModuleGraph, lib: PLib, info: TLineInfo, result: var string) =
  add(result, '|')
  encodeVInt(ord(lib.kind), result)
  add(result, '|')
  encodeStr($lib.name, result)
  add(result, '|')
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
    encodeVInt(cast[int32](s.flags), result)
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
    add(result, '#')
    encodeNode(g, unknownLineInfo(), s.constraint, result)
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

proc storeSym(g: ModuleGraph; s: PSym) =
  if sfForward in s.flags and s.kind != skModule:
    w.forwardedSyms.add s
    return
  var buf = newStringOfCap(160)
  encodeSym(g, s, buf)
  # XXX only store the name for exported symbols in order to speed up lookup
  # times once we enable the skStub logic.
  let m = getModule(s)
  let mid = if m == nil: 0 else: abs(m.id)
  db.exec(sql"insert into syms(nimid, module, name, data, exported) values (?, ?, ?, ?, ?)",
    s.id, mid, s.name.s, buf, ord(sfExported in s.flags))

proc storeType(g: ModuleGraph; t: PType) =
  var buf = newStringOfCap(160)
  encodeType(g, t, buf)
  let m = if t.owner != nil: getModule(t.owner) else: nil
  let mid = if m == nil: 0 else: abs(m.id)
  db.exec(sql"insert into types(nimid, module, data) values (?, ?, ?)",
    t.uniqueId, mid, buf)

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
      storeType(g, t)
      when false:
        echo "popped type ", typeToString(t), " ", t.uniqueId
    else:
      break
    inc i

proc storeNode*(g: ModuleGraph; module: PSym; n: PNode) =
  if g.config.symbolFiles == disabledSf: return
  var buf = newStringOfCap(160)
  encodeNode(g, module.info, n, buf)
  db.exec(sql"insert into toplevelstmts(module, position, data) values (?, ?, ?)",
    abs(module.id), module.offset, buf)
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
    # don't store the "command line" entry:
    if nimid != 0:
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
    internalError(g.config, info, "decodeType: no id")
  if b.s[b.pos] == '+':
    inc(b.pos)
    result.id = decodeVInt(b.s, b.pos)
  else:
    result.id = result.uniqueId
  # here this also avoids endless recursion for recursive type
  g.incr.r.types.add(result.uniqueId, result)
  if b.s[b.pos] == '(': result.n = decodeNode(g, b, unknownLineInfo())
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
    result.destructor = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == '\16':
    inc(b.pos)
    result.deepCopy = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == '\17':
    inc(b.pos)
    result.assignment = loadSym(g, decodeVInt(b.s, b.pos), info)
  if b.s[b.pos] == '\18':
    inc(b.pos)
    result.sink = loadSym(g, decodeVInt(b.s, b.pos), info)
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
      else: internalError(g.config, info, "decodeType ^(" & b.s[b.pos])
      rawAddSon(result, nil)
    else:
      let d = decodeVInt(b.s, b.pos)
      rawAddSon(result, loadType(g, d, info))

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
  new(result)
  result.id = id
  result.kind = k
  result.name = ident         # read the rest of the symbol description:
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
    result.flags = cast[TSymFlags](int32(decodeVInt(b.s, b.pos)))
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
    result.constraint = decodeNode(g, b, unknownLineInfo())
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
    #  result.ast = decodeNodeLazyBody(b, result.info, result)
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
        let cname = AbsoluteFile n[1].strVal,
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
  if g.config.symbolFiles == disabledSf: return
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
