#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## AST to NIF bridge.

import std / [assertions, tables, sets]
from std / strutils import startsWith
import ast, idents, msgs, options
import lineinfos as astli
import pathutils
import "../dist/nimony/src/lib" / [bitabs, nifstreams, nifcursors, lineinfos,
  nifindexes, nifreader]
import "../dist/nimony/src/gear2" / modnames

import icnif / [enum2nif]

# ---------------- Line info handling -----------------------------------------

type
  LineInfoWriter = object
    fileK: FileIndex # remember the current pair, even faster than the hash table
    fileV: FileId
    tab: Table[FileIndex, FileId]
    revTab: Table[FileId, FileIndex] # reverse mapping for oldLineInfo
    man: LineInfoManager
    config: ConfigRef

proc get(w: var LineInfoWriter; key: FileIndex): FileId =
  if w.fileK == key:
    result = w.fileV
  else:
    if key in w.tab:
      result = w.tab[key]
      w.fileK = key
      w.fileV = result
    else:
      result = pool.files.getOrIncl(msgs.toFullPath(w.config, key))
      w.fileK = key
      w.fileV = result
      w.tab[key] = result
      w.revTab[result] = key

proc nifLineInfo(w: var LineInfoWriter; info: TLineInfo): PackedLineInfo =
  if info == unknownLineInfo:
    result = NoLineInfo
  else:
    let fid = get(w, info.fileIndex)
    result = pack(w.man, fid, info.line.int32, info.col)

proc oldLineInfo(w: var LineInfoWriter; info: PackedLineInfo): TLineInfo =
  if info == NoLineInfo:
    result = unknownLineInfo
  else:
    var x = unpack(w.man, info)
    var fileIdx: FileIndex
    if w.fileV == x.file:
      fileIdx = w.fileK
    elif x.file in w.revTab:
      fileIdx = w.revTab[x.file]
    else:
      # Need to look up FileId -> FileIndex via the file path
      let filePath = pool.files[x.file]
      fileIdx = msgs.fileInfoIdx(w.config, AbsoluteFile filePath)
      w.revTab[x.file] = fileIdx
    result = TLineInfo(line: x.line.uint16, col: x.col.int16, fileIndex: fileIdx)


# -------------- Module name handling --------------------------------------------

proc modname(moduleToNifSuffix: var Table[FileIndex, string]; module: int; conf: ConfigRef): string =
  let idx = module.FileIndex
  # copied from ../nifgen.nim
  result = moduleToNifSuffix.getOrDefault(idx)
  if result.len == 0:
    let fp = toFullPath(conf, idx)
    result = moduleSuffix(fp, cast[seq[string]](conf.searchPaths))
    moduleToNifSuffix[idx] = result
    #echo result, " -> ", fp

proc modname(moduleToNifSuffix: var Table[FileIndex, string]; module: PSym; conf: ConfigRef): string =
  assert module.kind == skModule
  result = modname(moduleToNifSuffix, module.position, conf)



# ------------- Writer ---------------------------------------------------------------

#[

Strategy:

We produce NIF from the PNode structure as the single source of truth. NIF nodes can
however, refer to PSym and PType, these get NIF names. If the PSym/PType belongs to
the module that we are currently writing, we emit these fields as an inner NIF
structure via the special tags `sd` and `td`. In fact it is only these tags
that get the NIF `SymbolDef` kinds so that the lazy loading mechanism cannot
be confused.

We could also emit non-local symbols and types later as the index structure
will tell us the precise offsets anyway.

]#

let
  sdefTag = registerTag("sd")
  tdefTag = registerTag("td")
  tuseTag = registerTag("t")
  hiddenTypeTag = registerTag("ht")

type
  Writer = object
    deps: TokenBuf  # include&import deps
    infos: LineInfoWriter
    currentModule: int32
    writtenSyms: HashSet[ItemId]
    writtenTypes: HashSet[ItemId]
    decodedFileIndices: HashSet[FileIndex]
    moduleToNifSuffix: Table[FileIndex, string]
    locals: HashSet[ItemId]  # track proc-local symbols
    inProc: int

proc toNifSymName(w: var Writer; sym: PSym): string =
  ## Generate NIF name for a symbol: local names are `ident.disamb`,
  ## global names are `ident.disamb.moduleSuffix`
  result = sym.name.s
  result.add '.'
  result.addInt sym.disamb
  if sym.itemId notin w.locals:
    # Global symbol: ident.disamb.moduleSuffix
    let module = sym.itemId.module
    result.add '.'
    result.add modname(w.moduleToNifSuffix, module, w.infos.config)

type
  ParsedSymName* = object
    name*: string
    module*: string
    count*: int

proc parseSymName*(s: string): ParsedSymName =
  var i = s.len - 2
  while i > 0:
    if s[i] == '.':
      if s[i+1] in {'0'..'9'}:
        var count = ord(s[i+1]) - ord('0')
        var j = i+2
        while j < s.len and s[j] in {'0'..'9'}:
          count = count * 10 + ord(s[j]) - ord('0')
          inc j
        return ParsedSymName(name: substr(s, 0, i-1), module: "", count: count)
      else:
        let mend = s.high
        var b = i-1
        while b > 0 and s[b] != '.': dec b
        var j = b+1
        var count = 0
        while j < s.len and s[j] in {'0'..'9'}:
          count = count * 10 + ord(s[j]) - ord('0')
          inc j

        return ParsedSymName(name: substr(s, 0, b-1), module: substr(s, i+1, mend), count: count)
    dec i
  return ParsedSymName(name: s, module: "")

template buildTree(dest: var TokenBuf; tag: TagId; body: untyped) =
  dest.addParLe tag
  body
  dest.addParRi

template buildTree(dest: var TokenBuf; tag: string; body: untyped) =
  buildTree dest, pool.tags.getOrIncl(tag), body

proc writeFlags[E](dest: var TokenBuf; flags: set[E]) =
  var flagsAsIdent = ""
  genFlags(flags, flagsAsIdent)
  if flagsAsIdent.len > 0:
    dest.addIdent flagsAsIdent
  else:
    dest.addDotToken

proc trLineInfo(w: var Writer; info: TLineInfo): PackedLineInfo {.inline.} =
  result = nifLineInfo(w.infos, info)

proc writeNode(w: var Writer; dest: var TokenBuf; n: PNode)
proc writeType(w: var Writer; dest: var TokenBuf; typ: PType)
proc writeSym(w: var Writer; dest: var TokenBuf; sym: PSym)

proc typeToNifSym(w: var Writer; typ: PType): string =
  result = "`t."
  result.addInt typ.uniqueId.item
  result.add '.'
  result.add modname(w.moduleToNifSuffix, typ.uniqueId.module, w.infos.config)

proc writeLoc(w: var Writer; dest: var TokenBuf; loc: TLoc) =
  dest.addIdent toNifTag(loc.k)
  dest.addIdent toNifTag(loc.storage)
  writeFlags(dest, loc.flags)  # TLocFlags
  dest.addStrLit loc.snippet

proc writeTypeDef(w: var Writer; dest: var TokenBuf; typ: PType) =
  dest.buildTree tdefTag:
    dest.addSymDef pool.syms.getOrIncl(w.typeToNifSym(typ)), NoLineInfo

    dest.addIdent toNifTag(typ.kind)
    writeFlags(dest, typ.flags)
    dest.addIdent toNifTag(typ.callConv)
    dest.addIntLit typ.size
    dest.addIntLit typ.align
    dest.addIntLit typ.paddingAtEnd
    dest.addIntLit typ.itemId.item  # nonUniqueId

    writeType(w, dest, typ.typeInst)
    writeNode(w, dest, typ.n)
    writeSym(w, dest, typ.owner)
    writeSym(w, dest, typ.sym)

    # Write TLoc structure
    writeLoc w, dest, typ.loc
    # we store the type's elements here at the end so that
    # it is not ambiguous and saves space:
    for ch in typ.kids:
      writeType(w, dest, ch)


proc writeType(w: var Writer; dest: var TokenBuf; typ: PType) =
  if typ == nil:
    dest.addDotToken()
  elif typ.itemId.module == w.currentModule and not w.writtenTypes.containsOrIncl(typ.uniqueId):
    writeTypeDef(w, dest, typ)
  else:
    dest.buildTree tuseTag:
      dest.addSymUse pool.syms.getOrIncl(w.typeToNifSym(typ)), NoLineInfo

proc writeBool(dest: var TokenBuf; b: bool) =
  dest.buildTree (if b: "true" else: "false"):
    discard

proc writeLib(w: var Writer; dest: var TokenBuf; lib: PLib) =
  if lib == nil:
    dest.addDotToken()
  else:
    dest.buildTree toNifTag(lib.kind):
      dest.writeBool lib.generated
      dest.writeBool lib.isOverridden
      dest.addStrLit lib.name
      writeNode w, dest, lib.path

proc writeSymDef(w: var Writer; dest: var TokenBuf; sym: PSym) =
  dest.addParLe sdefTag, trLineInfo(w, sym.info)
  dest.addSymDef pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  if sym.magic == mNone:
    dest.addDotToken
  else:
    dest.addIdent toNifTag(sym.magic)
  writeFlags(dest, sym.flags)
  writeFlags(dest, sym.options)
  dest.addIntLit sym.offset
  # field `disamb` made part of the name, so do not store it here
  dest.buildTree sym.kind.toNifTag:
    case sym.kind
    of skLet, skVar, skField, skForVar:
      writeSym(w, dest, sym.guard)
      dest.addIntLit sym.bitsize
      dest.addIntLit sym.alignment
    else:
      discard
  if sym.kind == skModule:
    dest.addDotToken() # position will be set by the loader!
  else:
    dest.addIntLit sym.position
  writeType(w, dest, sym.typ)
  writeSym(w, dest, sym.owner)
  # We do not store `sym.ast` here but instead set it in the deserializer
  #writeNode(w, sym.ast)
  writeLoc w, dest, sym.loc
  writeNode(w, dest, sym.constraint)
  writeSym(w, dest, sym.instantiatedFrom)
  dest.addParRi

proc writeSym(w: var Writer; dest: var TokenBuf; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
  elif sym.itemId.module == w.currentModule and not w.writtenSyms.containsOrIncl(sym.itemId):
    writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo

proc writeSymNode(w: var Writer; dest: var TokenBuf; n: PNode; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
  elif sym.itemId.module == w.currentModule and not w.writtenSyms.containsOrIncl(sym.itemId):
    if n.typ != n.sym.typ:
      dest.buildTree hiddenTypeTag, trLineInfo(w, n.info):
        writeSymDef(w, dest, sym)
    else:
      writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    let info = trLineInfo(w, n.info)
    if n.typ != n.sym.typ:
      dest.buildTree hiddenTypeTag, info:
        dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info
    else:
      dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info

proc writeNodeFlags(dest: var TokenBuf; flags: set[TNodeFlag]) {.inline.} =
  writeFlags(dest, flags)

template withNode(w: var Writer; dest: var TokenBuf; n: PNode; body: untyped) =
  dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  writeNodeFlags(dest, n.flags)
  writeType(w, dest, n.typ)
  body
  dest.addParRi

proc addLocalSym(w: var Writer; n: PNode) =
  ## Add symbol from a node to locals set if it's a symbol node
  if n != nil and n.kind == nkSym and n.sym != nil and w.inProc > 0:
    w.locals.incl(n.sym.itemId)

proc addLocalSyms(w: var Writer; n: PNode) =
  if n.kind in {nkIdentDefs, nkVarTuple}:
    # nkIdentDefs: [ident1, ident2, ..., type, default]
    # All children except the last two are identifiers
    for i in 0 ..< max(0, n.len - 2):
      addLocalSyms(w, n[i])
  elif n.kind == nkSym:
    addLocalSym(w, n)

proc trInclude(w: var Writer; n: PNode) =
  w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  for child in n:
    assert child.kind == nkStrLit
    w.deps.addStrLit child.strVal
  w.deps.addParRi

proc trImport(w: var Writer; n: PNode) =
  w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  for child in n:
    assert child.kind == nkSym
    let s = child.sym
    assert s.kind == skModule
    let fp = toFullPath(w.infos.config, s.position.FileIndex)
    w.deps.addStrLit fp
  w.deps.addParRi

proc writeNode(w: var Writer; dest: var TokenBuf; n: PNode) =
  if n == nil:
    dest.addDotToken
  else:
    case n.kind:
    of nkEmpty:
      let info = trLineInfo(w, n.info)
      dest.addParLe pool.tags.getOrIncl(toNifTag(nkEmpty)), info
      writeNodeFlags(dest, n.flags)
      dest.addParRi
    of nkIdent:
      # nkIdent uses flags and typ when it is a generic parameter
      w.withNode dest, n:
        dest.addIdent n.ident.s
    of nkSym:
      writeSymNode(w, dest, n, n.sym)
    of nkCharLit:
      w.withNode dest, n:
        dest.add charToken(n.intVal.char, NoLineInfo)
    of nkIntLit .. nkInt64Lit:
      w.withNode dest, n:
        dest.addIntLit n.intVal
    of nkUIntLit .. nkUInt64Lit:
      w.withNode dest, n:
        dest.addUIntLit cast[BiggestUInt](n.intVal)
    of nkFloatLit .. nkFloat128Lit:
      w.withNode dest, n:
        dest.add floatToken(pool.floats.getOrIncl(n.floatVal), NoLineInfo)
    of nkStrLit .. nkTripleStrLit:
      w.withNode dest, n:
        dest.addStrLit n.strVal
    of nkNilLit:
      w.withNode dest, n:
        discard
    of nkLetSection, nkVarSection, nkConstSection, nkGenericParams:
      # Track local variables declared in let/var sections
      w.withNode dest, n:
        for child in n:
          addLocalSyms w, child
          # Process the child node
          writeNode(w, dest, child)
    of nkForStmt, nkTypeDef:
      # Track for loop variable (first child is the loop variable)
      w.withNode dest, n:
        if n.len > 0:
          addLocalSyms(w, n[0])
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i])
    of nkFormalParams:
      # Track parameters (first child is return type, rest are parameters)
      w.withNode dest, n:
        for i in 0 ..< n.len:
          if i > 0:  # Skip return type
            addLocalSyms(w, n[i])
          writeNode(w, dest, n[i])
    of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkLambda, nkDo, nkMacroDef:
      inc w.inProc
      # Entering a proc/function body - parameters are local
      var ast = n
      if n[namePos].kind == nkSym:
        ast = n[namePos].sym.ast
      w.withNode dest, ast:
        # Process body and other parts
        for i in 0 ..< ast.len:
          writeNode(w, dest, ast[i])
      dec w.inProc
    of nkImportStmt:
      # this has been transformed for us, see `importer.nim` to contain a list of module syms:
      trImport w, n
    of nkIncludeStmt:
      trInclude w, n
    else:
      w.withNode dest, n:
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i])

proc writeToplevelNode(w: var Writer; outer, inner: var TokenBuf; n: PNode) =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for son in n: writeToplevelNode(w, outer, inner, son)
  of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkLambda, nkDo, nkMacroDef:
    # Delegate to `w.topLevel`!
    writeNode w, inner, n
  of nkConstSection, nkTypeSection, nkTypeDef:
    writeNode w, inner, n
  else:
    writeNode w, outer, n

proc writeNifModule*(config: ConfigRef; thisModule: int32; n: PNode) =
  var w = Writer(infos: LineInfoWriter(config: config), currentModule: thisModule)
  var outer = createTokenBuf(300)
  var inner = createTokenBuf(300)

  let rootInfo = trLineInfo(w, n.info)
  outer.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), rootInfo
  inner.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), rootInfo

  w.writeToplevelNode outer, inner, n

  outer.addParRi()
  inner.addParRi()

  let m = modname(w.moduleToNifSuffix, w.currentModule, w.infos.config)
  let d = toGeneratedFile(config, AbsoluteFile(m), ".nif").string

  var dest = createTokenBuf(600)
  dest.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), rootInfo
  dest.add w.deps
  dest.add outer
  dest.add inner
  dest.addParRi()

  writeFileAndIndex d, dest


# --------------------------- Loader (lazy!) -----------------------------------------------

proc nodeKind(n: Cursor): TNodeKind {.inline.} =
  assert n.kind == ParLe
  parse(TNodeKind, pool.tags[n.tagId])

proc expect(n: Cursor; k: set[NifKind]) =
  if n.kind notin k:
    when defined(debug):
      writeStackTrace()
    quit "[NIF decoder] expected: " & $k & " but got: " & $n.kind & toString n

proc expect(n: Cursor; k: NifKind) {.inline.} =
  expect n, {k}

proc incExpect(n: var Cursor; k: set[NifKind]) =
  inc n
  expect n, k

proc incExpect(n: var Cursor; k: NifKind) {.inline.} =
  incExpect n, {k}

proc skipParRi(n: var Cursor) =
  expect n, {ParRi}
  inc n

proc firstSon*(n: Cursor): Cursor {.inline.} =
  result = n
  inc result

proc expectTag(n: Cursor; tagId: TagId) =
  if n.kind == ParLe and n.tagId == tagId:
    discard
  else:
    when defined(debug):
      writeStackTrace()
    if n.kind != ParLe:
      quit "[NIF decoder] expected: ParLe but got: " & $n.kind & toString n
    else:
      quit "[NIF decoder] expected: " & pool.tags[tagId] & " but got: " & pool.tags[n.tagId] & toString n

proc incExpectTag(n: var Cursor; tagId: TagId) =
  inc n
  expectTag(n, tagId)

proc loadBool(n: var Cursor): bool =
  if n.kind == ParLe:
    result = pool.tags[n.tagId] == "true"
    inc n
    skipParRi n
  else:
    raiseAssert "(true)/(false) expected"

type
  NifModule = object
    stream: nifstreams.Stream
    symCounter: int32
    index: NifIndex

  DecodeContext* = object
    infos: LineInfoWriter
    moduleIds: Table[string, int32]
    types: Table[ItemId, (PType, NifIndexEntry)]
    syms: Table[ItemId, (PSym, NifIndexEntry)]
    mods: seq[NifModule]
    cache: IdentCache
    moduleToNifSuffix: Table[FileIndex, string]

proc createDecodeContext*(config: ConfigRef; cache: IdentCache): DecodeContext =
  ## Supposed to be a global variable
  result = DecodeContext(infos: LineInfoWriter(config: config), cache: cache)

proc idToIdx(x: int32): int {.inline.} =
  assert x <= -2'i32
  result = -(x+2)

proc cursorFromIndexEntry(c: var DecodeContext; module: int32; entry: NifIndexEntry;
                          buf: var TokenBuf): Cursor =
  let m = idToIdx(module)
  let s = addr c.mods[m].stream
  s.r.jumpTo entry.offset
  var buf = createTokenBuf(30)
  nifcursors.parse(s[], buf, entry.info)
  result = cursorAt(buf, 0)

proc moduleId(c: var DecodeContext; suffix: string): int32 =
  # We don't know the "real" FileIndex due to our mapping to a short "Module suffix"
  # This is not a problem, we use negative `ItemId.module` values here and then
  # there is no interference with in-memory-modules. Modulegraphs.nim already uses -1
  # so we start at -2 here.
  result = c.moduleIds.getOrDefault(suffix)
  if result == 0:
    result = -int32(c.moduleIds.len + 2) # negative index!
    let modFile = (getNimcacheDir(c.infos.config) / RelativeFile(suffix & ".nif")).string
    let idxFile = (getNimcacheDir(c.infos.config) / RelativeFile(suffix & ".idx.nif")).string
    c.moduleIds[suffix] = result
    c.mods.add NifModule(stream: nifstreams.open(modFile), index: readIndex(idxFile))
    assert c.mods.len-1 == idToIdx(result)

proc getOffset(c: var DecodeContext; module: int32; nifName: string): NifIndexEntry =
  assert module < 0'i32
  let index = idToIdx(module)
  let ii = addr c.mods[index].index
  result = ii.public.getOrDefault(nifName)
  if result.offset == 0:
    result = ii.private.getOrDefault(nifName)
    if result.offset == 0:
      raiseAssert "symbol has no offset: " & nifName

proc loadNode(c: var DecodeContext; n: var Cursor): PNode

proc loadTypeStub(c: var DecodeContext; t: SymId): PType =
  let name = pool.syms[t]
  assert name.startsWith("`t.")
  var i = len("`t.")
  var itemId = 0'i32
  while i < name.len and name[i] in {'0'..'9'}:
    itemId = itemId * 10'i32 + int32(name[i].ord - ord('0'))
    inc i
  if i < name.len and name[i] == '.': inc i
  let suffix = name.substr(i)
  let id = ItemId(module: moduleId(c, suffix), item: itemId)
  result = c.types.getOrDefault(id)[0]
  if result == nil:
    let offs = c.getOffset(id.module, name)
    result = PType(itemId: id, uniqueId: id, kind: tyStub)
    c.types[id] = (result, offs)

proc loadTypeStub(c: var DecodeContext; n: var Cursor): PType =
  if n.kind == DotToken:
    result = nil
    inc n
  elif n.kind == Symbol:
    let s = n.symId
    result = loadTypeStub(c, s)
    inc n
  elif n.kind == ParLe and n.tagId == tdefTag:
    let s = n.firstSon.symId
    skip n
    result = loadTypeStub(c, s)
  else:
    raiseAssert "type expected but got " & $n.kind

proc loadSymStub(c: var DecodeContext; t: SymId): PSym =
  let symAsStr = pool.syms[t]
  let sn = parseSymName(symAsStr)
  let module = moduleId(c, sn.module)
  let val = addr c.mods[idToIdx(module)].symCounter
  inc val[]

  let id = ItemId(module: module, item: val[])
  result = c.syms.getOrDefault(id)[0]
  if result == nil:
    let offs = c.getOffset(module, symAsStr)
    result = PSym(itemId: id, kind: skStub, name: c.cache.getIdent(sn.name), disamb: sn.count.int32)
    c.syms[id] = (result, offs)

proc loadSymStub(c: var DecodeContext; n: var Cursor): PSym =
  if n.kind == DotToken:
    result = nil
    inc n
  elif n.kind == Symbol:
    let s = n.symId
    result = loadSymStub(c, s)
    inc n
  elif n.kind == ParLe and n.tagId == sdefTag:
    let s = n.firstSon.symId
    skip n
    result = loadSymStub(c, s)
  else:
    raiseAssert "sym expected but got " & $n.kind

proc isStub*(t: PType): bool {.inline.} = t.kind == tyStub
proc isStub*(s: PSym): bool {.inline.} = s.kind == skStub

proc loadAtom[T](t: typedesc[set[T]]; n: var Cursor): set[T] =
  if n.kind == DotToken:
    result = {}
    inc n
  else:
    expect n, Ident
    result = parse(T, pool.strings[n.litId])
    inc n

proc loadAtom[T: enum](t: typedesc[T]; n: var Cursor): T =
  if n.kind == DotToken:
    result = default(T)
    inc n
  else:
    expect n, Ident
    result = parse(T, pool.strings[n.litId])
    inc n

proc loadAtom(t: typedesc[string]; n: var Cursor): string =
  expect n, StringLit
  result = pool.strings[n.litId]
  inc n

proc loadAtom[T: int16|int32|int64](t: typedesc[T]; n: var Cursor): T =
  expect n, IntLit
  result = pool.integers[n.intId].T
  inc n

template loadField(field) =
  field = loadAtom(typeof(field), n)

proc loadLoc(c: var DecodeContext; n: var Cursor; loc: var TLoc) =
  loadField loc.k
  loadField loc.storage
  loadField loc.flags
  loadField loc.snippet

proc loadType*(c: var DecodeContext; t: PType) =
  if t.kind != tyStub: return
  var buf = createTokenBuf(30)
  var n = cursorFromIndexEntry(c, t.itemId.module, c.types[t.itemId][1], buf)

  expect n, ParLe
  if n.tagId != tdefTag:
    raiseAssert "(td) expected"
  inc n
  expect n, SymbolDef
  # ignore the type's name, we have already used it to create this PType's itemId!
  inc n
  loadField t.kind
  loadField t.flags
  loadField t.callConv
  loadField t.size
  loadField t.align
  loadField t.paddingAtEnd
  loadField t.itemId.item

  t.typeInst = loadTypeStub(c, n)
  t.n = loadNode(c, n)
  t.setOwner loadSymStub(c, n)
  t.sym = loadSymStub(c, n)
  loadLoc c, n, t.loc

  var kids: seq[PType] = @[]
  while n.kind != ParRi:
    kids.add loadTypeStub(c, n)

  t.setSons kids

  skipParRi n

proc loadAnnex(c: var DecodeContext; n: var Cursor): PLib =
  if n.kind == DotToken:
    result = nil
    inc n
  elif n.kind == ParLe:
    result = PLib(kind: parse(TLibKind, pool.tags[n.tagId]))
    inc n
    result.generated = loadBool(n)
    result.isOverridden = loadBool(n)
    expect n, StringLit
    result.name = pool.strings[n.litId]
    inc n
    result.path = loadNode(c, n)
    skipParRi n
  else:
    raiseAssert "`lib/annex` information expected"

proc loadSym*(c: var DecodeContext; s: PSym) =
  if s.kind != skStub: return
  var buf = createTokenBuf(30)
  var n = cursorFromIndexEntry(c, s.itemId.module, c.syms[s.itemId][1], buf)

  expect n, ParLe
  if n.tagId != sdefTag:
    raiseAssert "(sd) expected"
  inc n
  expect n, SymbolDef
  # ignore the symbol's name, we have already used it to create this PSym instance!
  inc n
  loadField s.magic
  loadField s.flags
  loadField s.options
  loadField s.offset

  expect n, ParLe
  s.kind = parse(TSymKind, pool.tags[n.tagId])
  inc n

  case s.kind
  of skLet, skVar, skField, skForVar:
    s.guard = loadSymStub(c, n)
    loadField s.bitsize
    loadField s.alignment
  else:
    discard
  skipParRi n

  if s.kind == skModule:
    expect n, DotToken
    inc n
  else:
    loadField s.position
  s.typ = loadTypeStub(c, n)
  s.setOwner loadSymStub(c, n)
  # We do not store `sym.ast` here but instead set it in the deserializer
  #writeNode(w, sym.ast)
  loadLoc c, n, s.loc
  s.constraint = loadNode(c, n)
  s.instantiatedFrom = loadSymStub(c, n)
  skipParRi n


template withNode(c: var DecodeContext; n: var Cursor; result: PNode; kind: TNodeKind; body: untyped) =
  let info = c.infos.oldLineInfo(n.info)
  let flags = loadAtom(TNodeFlags, n)
  result = newNodeI(kind, info)
  result.flags = flags
  result.typ = c.loadTypeStub n
  body
  skipParRi n

proc loadNode(c: var DecodeContext; n: var Cursor): PNode =
  result = nil
  case n.kind:
  of DotToken:
    result = nil
    inc n
  of ParLe:
    let kind = n.nodeKind
    case kind:
    of nkEmpty:
      result = newNodeI(nkEmpty, c.infos.oldLineInfo(n.info))
      result.flags = loadAtom(TNodeFlags, n)
      skipParRi n
    of nkIdent:
      let info = c.infos.oldLineInfo(n.info)
      let flags = loadAtom(TNodeFlags, n)
      let typ = c.loadTypeStub n
      expect n, Ident
      result = newIdentNode(c.cache.getIdent(pool.strings[n.litId]), info)
      inc n
      result.flags = flags
      result.typ = typ
      skipParRi n
    of nkSym:
      c.withNode n, result, kind:
        result.sym = c.loadSymStub n
    of nkCharLit:
      c.withNode n, result, kind:
        expect n, CharLit
        result.intVal = n.charLit.int
        inc n
    of nkIntLit .. nkInt64Lit:
      c.withNode n, result, kind:
        expect n, IntLit
        result.intVal = pool.integers[n.intId]
        inc n
    of nkUIntLit .. nkUInt64Lit:
      c.withNode n, result, kind:
        expect n, UIntLit
        result.intVal = cast[BiggestInt](pool.uintegers[n.uintId])
        inc n
    of nkFloatLit .. nkFloat128Lit:
      c.withNode n, result, kind:
        if n.kind == FloatLit:
          result.floatVal = pool.floats[n.floatId]
          inc n
        elif n.kind == ParLe:
          case pool.tags[n.tagId]
          of "inf":
            result.floatVal = Inf
          of "nan":
            result.floatVal = NaN
          of "neginf":
            result.floatVal = NegInf
          else:
            raiseAssert "expected float literal but got " & pool.tags[n.tagId]
          inc n
          skipParRi n
        else:
          raiseAssert "expected float literal but got " & $n.kind
    of nkStrLit .. nkTripleStrLit:
      c.withNode n, result, kind:
        expect n, StringLit
        result.strVal = pool.strings[n.litId]
        inc n
    of nkNilLit:
      c.withNode n, result, kind:
        discard
    of nkNone:
      raiseAssert "Unknown tag " & pool.tags[n.tagId]
    else:
      c.withNode n, result, kind:
        while n.kind != ParRi:
          result.addAllowNil c.loadNode n
  else:
    raiseAssert "Not yet implemented " & $n.kind


proc loadNifModule*(c: var DecodeContext; f: FileIndex): PNode =
  let moduleSuffix = modname(c.moduleToNifSuffix, f.int, c.infos.config)
  let modFile = toGeneratedFile(c.infos.config, AbsoluteFile(moduleSuffix), ".nif").string

  var buf = createTokenBuf(300)
  var s = nifstreams.open(modFile)
  # XXX We can optimize this here and only load the top level entries!
  try:
    nifcursors.parse(s, buf, NoLineInfo)
  finally:
    nifstreams.close(s)
  var n = cursorAt(buf, 0)
  result = loadNode(c, n)

when isMainModule:
  import std / syncio
  let obj = parseSymName("a.123.sys")
  echo obj.name, " ", obj.module, " ", obj.count
  let objb = parseSymName("abcdef.0121")
  echo objb.name, " ", objb.module, " ", objb.count
