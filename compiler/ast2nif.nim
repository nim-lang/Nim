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

import icnif / [enum2nif, icniftags]

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
    dest: TokenBuf
    inner: LineInfoWriter
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
    result.add modname(w.moduleToNifSuffix, module, w.inner.config)

template buildTree(dest: var TokenBuf; tag: TagId; body: untyped) =
  dest.addParLe tag
  body
  dest.addParRi

template buildTree(dest: var TokenBuf; tag: string; body: untyped) =
  buildTree dest, pool.tags.getOrIncl(tag), body

proc writeFlags[E](w: var Writer; flags: set[E]) =
  var flagsAsIdent = ""
  genFlags(flags, flagsAsIdent)
  if flagsAsIdent.len > 0:
    w.dest.addIdent flagsAsIdent
  else:
    w.dest.addDotToken

proc trLineInfo(w: var Writer; info: TLineInfo): PackedLineInfo {.inline.} =
  result = nifLineInfo(w.inner, info)

proc writeNode(w: var Writer; n: PNode)
proc writeType(w: var Writer; typ: PType)
proc writeSym(w: var Writer; sym: PSym)

proc typeToNifSym(w: var Writer; typ: PType): string =
  result = "`t."
  result.addInt typ.uniqueId.item
  result.add '.'
  result.add modname(w.moduleToNifSuffix, typ.uniqueId.module, w.inner.config)

proc writeTypeDef(w: var Writer; typ: PType) =
  w.dest.buildTree tdefTag:
    w.dest.addSymDef pool.syms.getOrIncl(w.typeToNifSym(typ)), NoLineInfo

    w.dest.addIdent toNifTag(typ.kind)
    writeFlags(w, typ.flags)
    w.dest.addIdent toNifTag(typ.callConv)
    w.dest.addIntLit typ.size
    w.dest.addIntLit typ.align
    w.dest.addIntLit typ.paddingAtEnd
    w.dest.addIntLit typ.itemId.item  # nonUniqueId

    writeType(w, typ.typeInst)
    writeNode(w, typ.n)
    writeSym(w, typ.owner)
    writeSym(w, typ.sym)
    # we store the type's elements here at the end so that
    # it is not ambiguous and saves space:
    for ch in typ.kids:
      writeType(w, ch)


proc writeType(w: var Writer; typ: PType) =
  if typ == nil:
    w.dest.addDotToken()
  elif typ.itemId.module == w.currentModule and not w.writtenTypes.containsOrIncl(typ.uniqueId):
    writeTypeDef(w, typ)
  else:
    w.dest.buildTree tuseTag:
      w.dest.addSymUse pool.syms.getOrIncl(w.typeToNifSym(typ)), NoLineInfo

proc writeSymDef(w: var Writer; sym: PSym) =
  w.dest.addParLe sdefTag, trLineInfo(w, sym.info)
  w.dest.addSymDef pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  if sym.magic == mNone:
    w.dest.addDotToken
  else:
    w.dest.addIdent toNifTag(sym.magic)
  writeFlags(w, sym.flags)
  writeFlags(w, sym.options)
  w.dest.addIntLit sym.offset
  w.dest.addIntLit sym.disamb
  w.dest.buildTree sym.kind.toNifTag:
    case sym.kind
    of skLet, skVar, skField, skForVar:
      writeSym(w, sym.guard)
      w.dest.addIntLit sym.bitsize
      w.dest.addIntLit sym.alignment
    else:
      discard
  if sym.kind == skModule:
    w.dest.addDotToken() # position will be set by the loader!
  else:
    w.dest.addIntLit sym.position
  writeType(w, sym.typ)
  writeSym(w, sym.owner)
  # We do not store `sym.ast` here but instead set it in the deserializer
  #writeNode(w, sym.ast)
  w.dest.addIdent toNifTag(sym.loc.k)
  w.dest.addStrLit sym.loc.snippet
  writeNode(w, sym.constraint)
  writeSym(w, sym.instantiatedFrom)
  w.dest.addParRi

proc writeSym(w: var Writer; sym: PSym) =
  if sym == nil:
    w.dest.addDotToken()
  elif sym.itemId.module == w.currentModule and not w.writtenSyms.containsOrIncl(sym.itemId):
    writeSymDef(w, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    w.dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo

proc writeSymNode(w: var Writer; n: PNode; sym: PSym) =
  if sym == nil:
    w.dest.addDotToken()
  elif sym.itemId.module == w.currentModule and not w.writtenSyms.containsOrIncl(sym.itemId):
    if n.typ != n.sym.typ:
      w.dest.buildTree hiddenTypeTag, trLineInfo(w, n.info):
        writeSymDef(w, sym)
    else:
      writeSymDef(w, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    let info = trLineInfo(w, n.info)
    if n.typ != n.sym.typ:
      w.dest.buildTree hiddenTypeTag, info:
        w.dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info
    else:
      w.dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info

proc writeNodeFlags(w: var Writer; flags: set[TNodeFlag]) {.inline.} =
  writeFlags(w, flags)

template withNode(w: var Writer; n: PNode; body: untyped) =
  w.dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  writeNodeFlags(w, n.flags)
  writeType(w, n.typ)
  body
  w.dest.addParRi

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

proc writeNode(w: var Writer; n: PNode) =
  if n == nil:
    w.dest.addDotToken
  else:
    case n.kind:
    of nkEmpty:
      let info = trLineInfo(w, n.info)
      w.dest.addParLe pool.tags.getOrIncl(toNifTag(nkEmpty)), info
      writeNodeFlags(w, n.flags)
      w.dest.addParRi
    of nkIdent:
      # nkIdent uses flags and typ when it is a generic parameter
      w.withNode n:
        w.dest.addIdent n.ident.s
    of nkSym:
      writeSymNode(w, n, n.sym)
    of nkCharLit:
      w.withNode n:
        w.dest.add charToken(n.intVal.char, NoLineInfo)
    of nkIntLit .. nkInt64Lit:
      w.withNode n:
        w.dest.addIntLit n.intVal
    of nkUIntLit .. nkUInt64Lit:
      w.withNode n:
        w.dest.addUIntLit cast[BiggestUInt](n.intVal)
    of nkFloatLit .. nkFloat128Lit:
      w.withNode n:
        w.dest.add floatToken(pool.floats.getOrIncl(n.floatVal), NoLineInfo)
    of nkStrLit .. nkTripleStrLit:
      w.withNode n:
        w.dest.addStrLit n.strVal
    of nkNilLit:
      w.withNode n:
        discard
    of nkLetSection, nkVarSection, nkConstSection, nkGenericParams:
      # Track local variables declared in let/var sections
      w.withNode(n):
        for child in n:
          addLocalSyms w, child
          # Process the child node
          writeNode(w, child)
    of nkForStmt, nkTypeDef:
      # Track for loop variable (first child is the loop variable)
      w.withNode(n):
        if n.len > 0:
          addLocalSyms(w, n[0])
        for i in 0 ..< n.len:
          writeNode(w, n[i])
    of nkFormalParams:
      # Track parameters (first child is return type, rest are parameters)
      w.withNode(n):
        for i in 0 ..< n.len:
          if i > 0:  # Skip return type
            addLocalSyms(w, n[i])
          writeNode(w, n[i])
    of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkLambda, nkDo, nkMacroDef:
      inc w.inProc
      # Entering a proc/function body - parameters are local
      var ast = n
      if n[namePos].kind == nkSym:
        ast = n[namePos].sym.ast
      w.withNode(ast):
        # Process body and other parts
        for i in 0 ..< ast.len:
          writeNode(w, ast[i])
      dec w.inProc
    else:
      w.withNode(n):
        for i in 0 ..< n.len:
          writeNode(w, n[i])

proc writeNifModule*(config: ConfigRef; thisModule: int32; n: PNode) =
  var w = Writer(inner: LineInfoWriter(config: config), currentModule: thisModule)
  w.writeNode n
  let m = modname(w.moduleToNifSuffix, w.currentModule, w.inner.config)
  let d = toGeneratedFile(config, AbsoluteFile(m), ".nif").string
  writeFileAndIndex d, w.dest
