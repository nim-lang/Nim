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
import ast, idents, msgs, options
import lineinfos as astli
import pathutils
import "../dist/nimony/src/lib" / [bitabs, nifstreams, nifcursors, lineinfos,
  nifindexes]
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
    dest.addIdent toNifTag(typ.loc.k)
    dest.addIntLit ord(typ.loc.storage)  # TStorageLoc: OnUnknown=0, OnStatic=1, OnStack=2, OnHeap=3
    writeFlags(dest, typ.loc.flags)  # TLocFlags

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
  dest.addIntLit sym.disamb
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
  # Write TLoc structure
  dest.addIdent toNifTag(sym.loc.k)
  dest.addIntLit ord(sym.loc.storage)  # TStorageLoc: OnUnknown=0, OnStatic=1, OnStack=2, OnHeap=3
  writeFlags(dest, sym.loc.flags)  # TLocFlags
  dest.addStrLit sym.loc.snippet
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

  w.writeToplevelNode outer, inner, n
  let m = modname(w.moduleToNifSuffix, w.currentModule, w.infos.config)
  let d = toGeneratedFile(config, AbsoluteFile(m), ".nif").string

  var dest = createTokenBuf(600)
  let rootInfo = if outer.len > 0: outer[0].info else: NoLineInfo
  dest.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), rootInfo
  dest.add w.deps
  dest.add outer
  dest.add inner
  dest.addParRi()

  writeFileAndIndex d, dest


# --------------------------- Loader (lazy!) -----------------------------------------------

proc loadNifModule*(config: ConfigRef; f: FileIndex): PNode =
  var moduleToNifSuffix = initTable[FileIndex, string]()

  let m = modname(moduleToNifSuffix, f.int, config)
  let d = toGeneratedFile(config, AbsoluteFile(m), ".nif").string

  result = nil
