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
from std / os import fileExists
import astdef, idents, msgs, options
import lineinfos as astli
import pathutils #, modulegraphs
import "../dist/nimony/src/lib" / [bitabs, nifstreams, nifcursors, lineinfos,
  nifindexes, nifreader]
import "../dist/nimony/src/gear2" / modnames
import "../dist/nimony/src/models" / nifindex_tags
import typekeys
import ic / [enum2nif]

proc typeToNifSym(typ: PType; config: ConfigRef): string =
  result = "`t"
  result.addInt ord(typ.kind)
  result.add '.'
  result.addInt typ.uniqueId.item
  result.add '.'
  result.add modname(typ.uniqueId.module, config)

proc toHookIndexEntry*(config: ConfigRef; typeId: ItemId; hookSym: PSym): HookIndexEntry =
  ## Converts a type ItemId and hook symbol to a HookIndexEntry for the NIF index.
  let typeSymName = "`t" & $typeId.item & "." & cachedModuleSuffix(config, typeId.module.FileIndex)
  let hookSymName = hookSym.name.s & "." & $hookSym.disamb & "." & cachedModuleSuffix(config, hookSym.itemId.module.FileIndex)
  let typSymId = pool.syms.getOrIncl(typeSymName)
  let hookSymId = pool.syms.getOrIncl(hookSymName)
  # Check if it's a generic hook (has non-empty generic params)
  let isGeneric = hookSym.astImpl != nil and hookSym.astImpl.len > genericParamsPos and
                  hookSym.astImpl[genericParamsPos].kind != nkEmpty
  result = HookIndexEntry(typ: typSymId, hook: hookSymId, isGeneric: isGeneric)

proc toConverterIndexEntry*(config: ConfigRef; converterSym: PSym): (nifstreams.SymId, nifstreams.SymId) =
  ## Converts a converter symbol to an index entry (destType, converterSym).
  ## Returns the destination type's SymId and the converter's SymId.
  # Get the return type of the converter (destination type)
  let retType = converterSym.typImpl
  if retType != nil and retType.sonsImpl.len > 0:
    let destType = retType.sonsImpl[0]  # Return type is first son
    if destType != nil:
      let destTypeSymName = "`t" & $destType.itemId.item & "." & cachedModuleSuffix(config, destType.itemId.module.FileIndex)
      let convSymName = converterSym.name.s & "." & $converterSym.disamb & "." & cachedModuleSuffix(config, converterSym.itemId.module.FileIndex)
      result = (pool.syms.getOrIncl(destTypeSymName), pool.syms.getOrIncl(convSymName))
      return
  # Fallback: return empty entry
  result = (nifstreams.SymId(0), nifstreams.SymId(0))

proc toMethodIndexEntry*(config: ConfigRef; methodSym: PSym; signature: string): MethodIndexEntry =
  ## Converts a method symbol to a MethodIndexEntry.
  let methodSymName = methodSym.name.s & "." & $methodSym.disamb & "." & cachedModuleSuffix(config, methodSym.itemId.module.FileIndex)
  result = MethodIndexEntry(
    fn: pool.syms.getOrIncl(methodSymName),
    signature: pool.strings.getOrIncl(signature)
  )

proc toClassSymId*(config: ConfigRef; typeId: ItemId): nifstreams.SymId =
  ## Converts a type ItemId to its SymId for the class index.
  let typeSymName = "`t" & $typeId.item & "." & cachedModuleSuffix(config, typeId.module.FileIndex)
  result = pool.syms.getOrIncl(typeSymName)

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
    # Must use pool.man since toString uses pool.man to unpack
    result = pack(pool.man, fid, info.line.int32, info.col)

proc oldLineInfo(w: var LineInfoWriter; info: PackedLineInfo): TLineInfo =
  if info == NoLineInfo:
    result = unknownLineInfo
  else:
    var x = unpack(pool.man, info)
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

const
  hiddenTypeTagName = "ht"
  symDefTagName = "sd"
  typeDefTagName = "td"

let
  sdefTag = registerTag(symDefTagName)
  tdefTag = registerTag(typeDefTagName)
  hiddenTypeTag = registerTag(hiddenTypeTagName)

type
  Writer = object
    deps: TokenBuf  # include&import deps
    infos: LineInfoWriter
    currentModule: int32
    decodedFileIndices: HashSet[FileIndex]
    locals: HashSet[ItemId]  # track proc-local symbols
    inProc: int
    #writtenTypes: seq[PType]  # types written in this module, to be unloaded later
    #writtenSyms: seq[PSym]    # symbols written in this module, to be unloaded later
    exports: Table[FileIndex, HashSet[string]]  # module -> specific symbol names (empty = all)
    writtenPackages: HashSet[string]

const
  # Symbol kinds that are always local to a proc and should never have module suffix
  skLocalSymKinds = {skParam, skForVar, skResult, skTemp}

proc isLocalSym(sym: PSym): bool {.inline.} =
  sym.kindImpl in skLocalSymKinds or
    (sym.kindImpl in {skVar, skLet} and {sfGlobal, sfThread} * sym.flagsImpl == {})

proc toNifSymName(w: var Writer; sym: PSym): string =
  ## Generate NIF name for a symbol: local names are `ident.disamb`,
  ## global names are `ident.disamb.moduleSuffix`
  result = sym.name.s
  result.add '.'
  result.addInt sym.disamb
  if not isLocalSym(sym) and sym.itemId notin w.locals:
    # Global symbol: ident.disamb.moduleSuffix
    result.add '.'
    let module = if sym.kindImpl == skPackage: w.currentModule else: sym.itemId.module
    result.add modname(module, w.infos.config)


proc globalName(sym: PSym; config: ConfigRef): string =
  result = sym.name.s
  result.add '.'
  result.addInt sym.disamb
  result.add '.'
  result.add modname(sym.itemId.module, config)

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

proc writeNode(w: var Writer; dest: var TokenBuf; n: PNode; forAst = false)
proc writeType(w: var Writer; dest: var TokenBuf; typ: PType)
proc writeSym(w: var Writer; dest: var TokenBuf; sym: PSym)

proc writeLoc(w: var Writer; dest: var TokenBuf; loc: TLoc) =
  dest.addIdent toNifTag(loc.k)
  dest.addIdent toNifTag(loc.storage)
  writeFlags(dest, loc.flags)  # TLocFlags
  dest.addStrLit loc.snippet

proc writeTypeDef(w: var Writer; dest: var TokenBuf; typ: PType) =
  dest.buildTree tdefTag:
    dest.addSymDef pool.syms.getOrIncl(typeToNifSym(typ, w.infos.config)), NoLineInfo

    #dest.addIdent toNifTag(typ.kind)
    writeFlags(dest, typ.flagsImpl)
    dest.addIdent toNifTag(typ.callConvImpl)
    dest.addIntLit typ.sizeImpl
    dest.addIntLit typ.alignImpl
    dest.addIntLit typ.paddingAtEndImpl
    dest.addIntLit typ.itemId.item  # nonUniqueId

    writeType(w, dest, typ.typeInstImpl)
    #if typ.kind in {tyProc, tyIterator} and typ.nImpl != nil and typ.nImpl.kind != nkFormalParams:

    writeNode(w, dest, typ.nImpl)
    writeSym(w, dest, typ.ownerFieldImpl)
    writeSym(w, dest, typ.symImpl)

    # Write TLoc structure
    writeLoc w, dest, typ.locImpl
    # we store the type's elements here at the end so that
    # it is not ambiguous and saves space:
    for ch in typ.sonsImpl:
      writeType(w, dest, ch)


proc writeType(w: var Writer; dest: var TokenBuf; typ: PType) =
  if typ == nil:
    dest.addDotToken()
  elif typ.itemId.module == w.currentModule and typ.state == Complete:
    typ.state = Sealed
    writeTypeDef(w, dest, typ)
  else:
    dest.addSymUse pool.syms.getOrIncl(typeToNifSym(typ, w.infos.config)), NoLineInfo

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

proc collectGenericParams(w: var Writer; n: PNode) =
  ## Pre-collect generic param symbols into w.locals before writing the type.
  ## This ensures generic params get consistent short names, and their sdefs
  ## are written in the type (where lazy loading can find them).
  if n == nil: return
  case n.kind
  of nkSym:
    if n.sym != nil and w.inProc > 0:
      w.locals.incl(n.sym.itemId)
  of nkIdentDefs, nkVarTuple:
    for i in 0 ..< max(0, n.len - 2):
      collectGenericParams(w, n[i])
  of nkGenericParams:
    for child in n:
      collectGenericParams(w, child)
  else:
    discard

proc writeSymDef(w: var Writer; dest: var TokenBuf; sym: PSym) =
  dest.addParLe sdefTag, trLineInfo(w, sym.infoImpl)
  dest.addSymDef pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  if sfExported in sym.flagsImpl:
    dest.addIdent "x"
  else:
    dest.addDotToken
  # field `disamb` made part of the name, so do not store it here
  dest.buildTree sym.kindImpl.toNifTag:
    case sym.kindImpl
    of skLet, skVar, skField, skForVar:
      writeSym(w, dest, sym.guardImpl)
      dest.addIntLit sym.bitsizeImpl
      dest.addIntLit sym.alignmentImpl
    else:
      discard

  if sym.magicImpl == mNone:
    dest.addDotToken
  else:
    dest.addIdent toNifTag(sym.magicImpl)
  writeFlags(dest, sym.flagsImpl)
  writeFlags(dest, sym.optionsImpl)
  dest.addIntLit sym.offsetImpl

  if sym.kindImpl == skModule:
    dest.addDotToken() # position will be set by the loader!
  else:
    dest.addIntLit sym.positionImpl

  writeLib(w, dest, sym.annexImpl)

  # For routine symbols, pre-collect generic params into w.locals before writing
  # the type. This ensures they get consistent short names, and their sdefs are
  # written in the type where lazy loading can find them via extractLocalSymsFromTree.
  if sym.kindImpl in routineKinds and sym.astImpl != nil and sym.astImpl.len > genericParamsPos:
    inc w.inProc
    collectGenericParams(w, sym.astImpl[genericParamsPos])
    dec w.inProc

  writeType(w, dest, sym.typImpl)
  writeSym(w, dest, sym.ownerFieldImpl)
  # Store the AST for routine symbols and constants
  # Constants need their AST for astdef() to return the constant's value
  writeNode(w, dest, sym.astImpl, forAst = true)
  writeLoc w, dest, sym.locImpl
  writeNode(w, dest, sym.constraintImpl)
  writeSym(w, dest, sym.instantiatedFromImpl)
  dest.addParRi


proc shouldWriteSymDef(w: var Writer; sym: PSym): bool {.inline.} =
  # Don't write module/package symbols - they don't have NIF files
  if sym.kindImpl == skPackage:
    return not w.writtenPackages.containsOrIncl(sym.name.s)
  # Already written - don't write again
  if sym.state == Sealed:
    return false
  # If the symbol belongs to current module and would be written WITHOUT module suffix
  # (due to being in w.locals or being in skLocalSymKinds), it MUST have an sdef.
  # Otherwise it gets written as a bare SymUse and can't be found when loading.
  if sym.itemId.module == w.currentModule:
    if sym.itemId in w.locals or isLocalSym(sym):
      return true  # Would be written without module suffix, needs sdef
    if sym.state == Complete:
      return true  # Normal case for global symbols
  return false

proc writeSym(w: var Writer; dest: var TokenBuf; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
  elif shouldWriteSymDef(w, sym):
    sym.state = Sealed
    writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo

proc writeSymNode(w: var Writer; dest: var TokenBuf; n: PNode; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
  elif shouldWriteSymDef(w, sym):
    sym.state = Sealed
    if n.typField != n.sym.typImpl:
      dest.buildTree hiddenTypeTag, trLineInfo(w, n.info):
        writeType(w, dest, n.typField)
        writeSymDef(w, dest, sym)
    else:
      writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    let info = trLineInfo(w, n.info)
    if n.typField != n.sym.typImpl:
      dest.buildTree hiddenTypeTag, info:
        writeType(w, dest, n.typField)
        dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info
    else:
      dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info

proc writeNodeFlags(dest: var TokenBuf; flags: set[TNodeFlag]) {.inline.} =
  writeFlags(dest, flags)

template withNode(w: var Writer; dest: var TokenBuf; n: PNode; body: untyped) =
  dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  writeNodeFlags(dest, n.flags)
  writeType(w, dest, n.typField)
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
  w.deps.addDotToken # flags
  w.deps.addDotToken # type
  for child in n:
    assert child.kind == nkStrLit
    w.deps.addStrLit child.strVal  # raw string literal, no wrapper needed
  w.deps.addParRi

proc trImport(w: var Writer; n: PNode) =
  for child in n:
    if child.kind == nkSym:
      w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
      w.deps.addDotToken # flags
      w.deps.addDotToken # type
      let s = child.sym
      assert s.kindImpl == skModule
      let fp = toFullPath(w.infos.config, s.positionImpl.FileIndex)
      w.deps.addStrLit fp  # raw string literal, no wrapper needed
      w.deps.addParRi

proc writeNode(w: var Writer; dest: var TokenBuf; n: PNode; forAst = false) =
  if n == nil:
    dest.addDotToken
  else:
    case n.kind
    of nkNone:
      assert n.typField == nil, "nkNone should not have a type"
      let info = trLineInfo(w, n.info)
      dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), info
      dest.addParRi
    of nkEmpty:
      if n.typField != nil:
        w.withNode dest, n:
          let info = trLineInfo(w, n.info)
          dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), info
          dest.addParRi
      else:
        let info = trLineInfo(w, n.info)
        dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), info
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
    of nkLetSection, nkVarSection, nkConstSection:
      # Track local variables declared in let/var sections
      w.withNode dest, n:
        for child in n:
          addLocalSyms w, child
          # Process the child node
          writeNode(w, dest, child, forAst)
    of nkForStmt:
      # Track for loop variable (first child is the loop variable)
      w.withNode dest, n:
        if n.len > 0:
          addLocalSyms(w, n[0])
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i], forAst)
    of nkFormalParams:
      # Track parameters (first child is return type, rest are parameters)
      inc w.inProc
      w.withNode dest, n:
        for i in 0 ..< n.len:
          if i > 0:  # Skip return type
            addLocalSyms(w, n[i])
          writeNode(w, dest, n[i], forAst)
      dec w.inProc
    of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkMacroDef, nkTemplateDef:
      # For top-level named routines (not forAst), just write the symbol.
      # The full AST will be stored in the symbol's sdef.
      if not forAst and n[namePos].kind == nkSym:
        writeSym(w, dest, n[namePos].sym)
      else:
        # Writing AST inside sdef or anonymous proc: write full structure
        inc w.inProc
        var ast = n
        var skipParams = false
        if n[namePos].kind == nkSym:
          ast = n[namePos].sym.astImpl
          if ast == nil: ast = n
          else: skipParams = true
        w.withNode dest, ast:
          for i in 0 ..< ast.len:
            if i == paramsPos and skipParams:
              # Parameter are redundant with s.typ.n and even dangerous as for generic instances
              # we do not adapt the symbols properly
              addDotToken(dest)
            else:
              writeNode(w, dest, ast[i], forAst)
        dec w.inProc
    of nkLambda, nkDo:
      # Lambdas are expressions, always write full structure
      inc w.inProc
      var ast = n
      if n[namePos].kind == nkSym:
        ast = n[namePos].sym.astImpl
        if ast == nil: ast = n
      w.withNode dest, ast:
        for i in 0 ..< ast.len:
          writeNode(w, dest, ast[i], forAst)
      dec w.inProc
    of nkImportStmt:
      # this has been transformed for us, see `importer.nim` to contain a list of module syms:
      trImport w, n
    of nkIncludeStmt:
      trInclude w, n
    of nkExportStmt, nkExportExceptStmt:
      # Collect export information for the index
      # nkExportStmt children are nkSym nodes
      # When exporting a module (export dollars), the module symbol is a child
      # followed by all symbols from that module - we use empty set to mean "export all"
      # When exporting specific symbols (export foo, bar), we collect their names
      # Note: nkExportExceptStmt is transformed to nkExportStmt by semExportExcept,
      # but we handle both just in case
      var exportAllModules = initHashSet[FileIndex]()
      for child in n:
        if child.kind == nkSym:
          let s = child.sym
          if s.kindImpl == skModule:
            # Export all from this module - use empty set
            let modIdx = s.positionImpl.FileIndex
            exportAllModules.incl modIdx
            if modIdx notin w.exports:
              w.exports[modIdx] = initHashSet[string]()  # empty means "export all"
          else:
            # Export specific symbol, but only if we're not already exporting all from this module
            let modIdx = s.itemId.module.FileIndex
            if modIdx notin exportAllModules:
              if modIdx notin w.exports:
                w.exports[modIdx] = initHashSet[string]()
              w.exports[modIdx].incl s.name.s
      # Write the export statement as a regular node
      w.withNode dest, n:
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i], forAst)
    else:
      w.withNode dest, n:
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i], forAst)

proc writeToplevelNode(w: var Writer; dest, bottom: var TokenBuf; n: PNode) =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for son in n: writeToplevelNode(w, dest, bottom, son)
  of nkEmpty:
    discard "ignore"
  of nkTypeSection, nkConstSection, nkCommentStmt, nkMixinStmt, nkBindStmt, nkUsingStmt,
     nkPragma,
     nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkMacroDef, nkTemplateDef:
    # We write purely declarative nodes at the bottom of the file
    writeNode(w, bottom, n)
  else:
    writeNode w, dest, n

proc createStmtList(buf: var TokenBuf; info: PackedLineInfo) {.inline.} =
  buf.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), info
  buf.addDotToken # flags
  buf.addDotToken # type

proc buildExportBuf(w: var Writer): TokenBuf =
  ## Build the export section for the NIF index from collected exports
  result = createTokenBuf(32)
  for modIdx, names in w.exports:
    let path = toFullPath(w.infos.config, modIdx)
    if names.len == 0:
      # Export all from this module
      result.addParLe(TagId(ExportIdx), NoLineInfo)
      result.add strToken(pool.strings.getOrIncl(path), NoLineInfo)
      result.addParRi()
    else:
      # Export specific symbols
      result.addParLe(TagId(FromexportIdx), NoLineInfo)
      result.add strToken(pool.strings.getOrIncl(path), NoLineInfo)
      for name in names:
        result.add identToken(pool.strings.getOrIncl(name), NoLineInfo)
      result.addParRi()

let replayTag = registerTag("replay")
let repConverterTag = registerTag("repconverter")
let repDestroyTag = registerTag("repdestroy")
let repWasMovedTag = registerTag("repwasmoved")
let repCopyTag = registerTag("repcopy")
let repSinkTag = registerTag("repsink")
let repDupTag = registerTag("repdup")
let repTraceTag = registerTag("reptrace")
let repDeepCopyTag = registerTag("repdeepcopy")
let repEnumToStrTag = registerTag("repenumtostr")
let repMethodTag = registerTag("repmethod")
#let repClassTag = registerTag("repclass")
let includeTag = registerTag("include")
let importTag = registerTag("import")
let implTag = registerTag("implementation")

proc writeOp(w: var Writer; content: var TokenBuf; op: LogEntry) =
  case op.kind
  of HookEntry:
    case op.op
    of attachedDestructor:
      content.addParLe repDestroyTag, NoLineInfo
    of attachedAsgn:
      content.addParLe repCopyTag, NoLineInfo
    of attachedWasMoved:
      content.addParLe repWasMovedTag, NoLineInfo
    of attachedDup:
      content.addParLe repDupTag, NoLineInfo
    of attachedSink:
      content.addParLe repSinkTag, NoLineInfo
    of attachedTrace:
      content.addParLe repTraceTag, NoLineInfo
    of attachedDeepCopy:
      content.addParLe repDeepCopyTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of ConverterEntry:
    content.addParLe repConverterTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of MethodEntry:
    discard "to implement"
  of EnumToStrEntry:
    discard "to implement"
  of GenericInstEntry:
    discard "will only be written later to ensure it is materialized"

proc writeNifModule*(config: ConfigRef; thisModule: int32; n: PNode;
                     opsLog: seq[LogEntry];
                     replayActions: seq[PNode] = @[]) =
  var w = Writer(infos: LineInfoWriter(config: config), currentModule: thisModule)
  var content = createTokenBuf(300)

  let rootInfo = trLineInfo(w, n.info)
  createStmtList(content, rootInfo)

  # Write replay actions first, wrapped in a (replay ...) node
  if replayActions.len > 0:
    content.addParLe replayTag, rootInfo
    for action in replayActions:
      writeNode(w, content, action)
    content.addParRi()
  # Only write ops that belong to this module
  for op in opsLog:
    if op.module == thisModule.int:
      writeOp(w, content, op)

  var bottom = createTokenBuf(300)
  w.writeToplevelNode content, bottom, n

  # the implTag is used to tell the loader that the
  # bottom of the file is the implementation of the module:
  content.addParLe implTag, NoLineInfo
  content.addParRi()
  content.add bottom
  content.addParRi()

  let m = modname(w.currentModule, w.infos.config)
  let nifFilename = AbsoluteFile(m).changeFileExt(".nif")
  let d = completeGeneratedFilePath(config, nifFilename).string

  var dest = createTokenBuf(600)
  createStmtList(dest, rootInfo)
  dest.add w.deps
  # do not write the (stmts .. ) wrapper:
  for i in 3 ..< content.len-1:
    dest.add content[i]

  # ensure the hooks we announced end up in the NIF file regardless of
  # whether they have been used:
  for op in opsLog:
    if op.module == thisModule.int:
      let s = op.sym
      if s.state != Sealed:
        s.state = Sealed
        writeSymDef w, dest, s

  dest.addParRi()

  writeFile(dest, d)

  let exportBuf = buildExportBuf(w)
  createIndex(d, dest[0].info, false,
    IndexSections(exportBuf: exportBuf))

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
  NifModule = ref object
    stream: nifstreams.Stream
    symCounter: int32
    index: NifIndex
    suffix: string

  DecodeContext* = object
    infos: LineInfoWriter
    #moduleIds: Table[string, int32]
    types: Table[string, (PType, NifIndexEntry)]
    syms: Table[string, (PSym, NifIndexEntry)]
    mods: Table[FileIndex, NifModule]
    cache: IdentCache

proc createDecodeContext*(config: ConfigRef; cache: IdentCache): DecodeContext =
  ## Supposed to be a global variable
  result = DecodeContext(infos: LineInfoWriter(config: config), cache: cache)

proc cursorFromIndexEntry(c: var DecodeContext; module: FileIndex; entry: NifIndexEntry;
                          buf: var TokenBuf): Cursor =
  let s = addr c.mods[module].stream
  s.r.jumpTo entry.offset
  nifcursors.parse(s[], buf, entry.info)
  result = cursorAt(buf, 0)

proc moduleId(c: var DecodeContext; suffix: string): FileIndex =
  var isKnownFile = false
  result = c.infos.config.registerNifSuffix(suffix, isKnownFile)
  if not isKnownFile:
    let modFile = (getNimcacheDir(c.infos.config) / RelativeFile(suffix & ".nif")).string
    let idxFile = (getNimcacheDir(c.infos.config) / RelativeFile(suffix & ".s.idx.nif")).string
    if not fileExists(modFile):
      raiseAssert "NIF file not found for module suffix '" & suffix & "': " & modFile &
        ". This can happen when loading a module from NIF that references another module " &
        "whose NIF file hasn't been written yet."
    c.mods[result] = NifModule(stream: nifstreams.open(modFile), index: readIndex(idxFile), suffix: suffix)

proc getOffset(c: var DecodeContext; module: FileIndex; nifName: string): NifIndexEntry =
  let ii = addr c.mods[module].index
  result = ii.public.getOrDefault(nifName)
  if result.offset == 0:
    result = ii.private.getOrDefault(nifName)
    if result.offset == 0:
      raiseAssert "symbol has no offset: " & nifName

proc loadNode(c: var DecodeContext; n: var Cursor; thisModule: string;
              localSyms: var Table[string, PSym]): PNode

proc createTypeStub(c: var DecodeContext; t: SymId): PType =
  let name = pool.syms[t]
  assert name.startsWith("`t")
  var i = len("`t")
  var k = 0
  while i < name.len and name[i] in {'0'..'9'}:
    k = k * 10 + name[i].ord - ord('0')
    inc i
  if i < name.len and name[i] == '.': inc i
  var itemId = 0'i32
  while i < name.len and name[i] in {'0'..'9'}:
    itemId = itemId * 10'i32 + int32(name[i].ord - ord('0'))
    inc i
  if i < name.len and name[i] == '.': inc i
  let suffix = name.substr(i)
  result = c.types.getOrDefault(name)[0]
  if result == nil:
    let id = ItemId(module: moduleId(c, suffix).int32, item: itemId)
    let offs = c.getOffset(id.module.FileIndex, name)
    result = PType(itemId: id, uniqueId: id, kind: TTypeKind(k), state: Partial)
    c.types[name] = (result, offs)

proc extractLocalSymsFromTree(c: var DecodeContext; n: var Cursor; thisModule: string;
                              localSyms: var Table[string, PSym]) =
  ## Scan a tree for local symbol definitions (sdef tags) and add them to localSyms.
  ## This doesn't fully load the symbols, just pre-registers them so references
  ## can find them. After this proc returns, n is positioned AFTER the tree.
  # Handle atoms (non-compound nodes) - just skip them
  if n.kind != ParLe:
    inc n
    return
  var depth = 0
  while true:
    if n.kind == ParLe:
      if n.tagId == sdefTag:
        # Found an sdef - check if it's local
        let name = n.firstSon
        if name.kind == SymbolDef:
          let symName = pool.syms[name.symId]
          let sn = parseSymName(symName)
          if sn.module.len == 0 and symName notin localSyms:
            # Local symbol - create a stub entry in localSyms
            let module = moduleId(c, thisModule)
            let val = addr c.mods[module].symCounter
            inc val[]
            let id = ItemId(module: module.int32, item: val[])
            let sym = PSym(itemId: id, kindImpl: skStub, name: c.cache.getIdent(sn.name),
                          disamb: sn.count.int32, state: Complete)
            localSyms[symName] = sym
      inc depth
    elif n.kind == ParRi:
      dec depth
      if depth == 0:
        inc n  # Move PAST the closing )
        break
    inc n

proc loadTypeFromCursor(c: var DecodeContext; n: var Cursor; t: PType; localSyms: var Table[string, PSym])

proc loadTypeStub(c: var DecodeContext; n: var Cursor; localSyms: var Table[string, PSym]): PType =
  if n.kind == DotToken:
    result = nil
    inc n
  elif n.kind == Symbol:
    let s = n.symId
    result = createTypeStub(c, s)
    inc n
  elif n.kind == ParLe and n.tagId == tdefTag:
    let s = n.firstSon.symId
    result = createTypeStub(c, s)
    if result.state == Partial:
      result.state = Sealed  # Mark as loaded to prevent loadType from re-loading with empty localSyms
      loadTypeFromCursor(c, n, result, localSyms)
    else:
      skip n  # Type already loaded, skip over the td block
  else:
    raiseAssert "type expected but got " & $n.kind

proc loadSymStub(c: var DecodeContext; t: SymId; thisModule: string;
                 localSyms: var Table[string, PSym]): PSym =
  let symAsStr = pool.syms[t]
  let sn = parseSymName(symAsStr)
  # For local symbols (no module suffix), they MUST be in localSyms.
  # Local symbols are not in the index - they're defined inline in the NIF file.
  # If not found, it's a bug in how we populate localSyms.
  if sn.module.len == 0:
    result = localSyms.getOrDefault(symAsStr)
    if result != nil:
      return result
    else:
      raiseAssert "local symbol '" & symAsStr & "' not found in localSyms."
  # Global symbol - look up in index for lazy loading
  result = c.syms.getOrDefault(symAsStr)[0]
  if result == nil:
    let module = moduleId(c, sn.module)
    let val = addr c.mods[module].symCounter
    inc val[]
    let id = ItemId(module: module.int32, item: val[])

    let offs = c.getOffset(module, symAsStr)
    result = PSym(itemId: id, kindImpl: skStub, name: c.cache.getIdent(sn.name), disamb: sn.count.int32, state: Partial)
    c.syms[symAsStr] = (result, offs)

proc loadSymStub(c: var DecodeContext; n: var Cursor; thisModule: string;
                 localSyms: var Table[string, PSym]): PSym =
  if n.kind == DotToken:
    result = nil
    inc n
  elif n.kind == Symbol:
    let s = n.symId
    result = loadSymStub(c, s, thisModule, localSyms)
    inc n
  elif n.kind == ParLe and n.tagId == sdefTag:
    let s = n.firstSon.symId
    skip n
    result = loadSymStub(c, s, thisModule, localSyms)
  else:
    raiseAssert "sym expected but got " & $n.kind

proc isStub*(t: PType): bool {.inline.} = t.state == Partial
proc isStub*(s: PSym): bool {.inline.} = s.state == Partial

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

template loadField(field) {.dirty.} =
  field = loadAtom(typeof(field), n)

proc loadLoc(c: var DecodeContext; n: var Cursor; loc: var TLoc) =
  loadField loc.k
  loadField loc.storage
  loadField loc.flags
  loadField loc.snippet

proc loadTypeFromCursor(c: var DecodeContext; n: var Cursor; t: PType; localSyms: var Table[string, PSym]) =
  expect n, ParLe
  if n.tagId != tdefTag:
    raiseAssert "(td) expected"

  var scanCursor = n  # copy cursor at start of type
  let typesModule = parseSymName(pool.syms[n.firstSon.symId]).module
  extractLocalSymsFromTree(c, scanCursor, typesModule, localSyms)

  inc n  # move past (td
  expect n, SymbolDef
  # ignore the type's name, we have already used it to create this PType's itemId!
  inc n
  #loadField t.kind
  loadField t.flagsImpl
  loadField t.callConvImpl
  loadField t.sizeImpl
  loadField t.alignImpl
  loadField t.paddingAtEndImpl
  loadField t.itemId.item  # nonUniqueId

  t.typeInstImpl = loadTypeStub(c, n, localSyms)
  t.nImpl = loadNode(c, n, typesModule, localSyms)
  t.ownerFieldImpl = loadSymStub(c, n, typesModule, localSyms)
  t.symImpl = loadSymStub(c, n, typesModule, localSyms)
  loadLoc c, n, t.locImpl

  while n.kind != ParRi:
    t.sonsImpl.add loadTypeStub(c, n, localSyms)

  skipParRi n

proc loadType*(c: var DecodeContext; t: PType) =
  if t.state != Partial: return
  t.state = Sealed
  var buf = createTokenBuf(30)
  let typeName = typeToNifSym(t, c.infos.config)
  var n = cursorFromIndexEntry(c, t.itemId.module.FileIndex, c.types[typeName][1], buf)
  var localSyms = initTable[string, PSym]()
  loadTypeFromCursor(c, n, t, localSyms)

proc loadAnnex(c: var DecodeContext; n: var Cursor; thisModule: string; localSyms: var Table[string, PSym]): PLib =
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
    result.path = loadNode(c, n, thisModule, localSyms)
    skipParRi n
  else:
    raiseAssert "`lib/annex` information expected"

proc loadSymFromCursor(c: var DecodeContext; s: PSym; n: var Cursor; thisModule: string;
                       localSyms: var Table[string, PSym]) =
  ## Loads a symbol definition from the current cursor position.
  ## The cursor should be positioned after the opening (sd tag.
  expect n, SymbolDef
  # ignore the symbol's name, we have already used it to create this PSym instance!
  inc n
  if n.kind == Ident:
    if pool.strings[n.litId] == "x":
      s.flagsImpl.incl sfExported
      inc n
    else:
      raiseAssert "expected `x` as the export marker"
  elif n.kind == DotToken:
    inc n
  else:
    raiseAssert "expected `x` or '.' but got " & $n.kind

  expect n, ParLe
  {.cast(uncheckedAssign).}:
    s.kindImpl = parse(TSymKind, pool.tags[n.tagId])
  inc n

  case s.kindImpl
  of skLet, skVar, skField, skForVar:
    s.guardImpl = loadSymStub(c, n, thisModule, localSyms)
    loadField s.bitsizeImpl
    loadField s.alignmentImpl
  else:
    discard
  skipParRi n

  loadField s.magicImpl
  loadField s.flagsImpl
  loadField s.optionsImpl
  loadField s.offsetImpl

  if s.kindImpl == skModule:
    expect n, DotToken
    inc n
    var isKnownFile = false
    s.positionImpl = int c.infos.config.registerNifSuffix(thisModule, isKnownFile)
    # do to the precompiled mechanism things end up as main modules which are not!
    excl s.flagsImpl, sfMainModule
  else:
    loadField s.positionImpl

  s.annexImpl = loadAnnex(c, n, thisModule, localSyms)

  # Local symbols were already extracted upfront in loadSym, so we can use
  # the simple loadTypeStub here.
  s.typImpl = loadTypeStub(c, n, localSyms)
  s.ownerFieldImpl = loadSymStub(c, n, thisModule, localSyms)
  # Load the AST for routine symbols and constants
  # Constants need their AST for astdef() to return the constant's value
  s.astImpl = loadNode(c, n, thisModule, localSyms)
  loadLoc c, n, s.locImpl
  s.constraintImpl = loadNode(c, n, thisModule, localSyms)
  s.instantiatedFromImpl = loadSymStub(c, n, thisModule, localSyms)
  skipParRi n

proc loadSym*(c: var DecodeContext; s: PSym) =
  if s.state != Partial: return
  s.state = Sealed
  var buf = createTokenBuf(30)
  let symsModule = s.itemId.module.FileIndex
  let nifname = globalName(s, c.infos.config)
  var n = cursorFromIndexEntry(c, symsModule, c.syms[nifname][1], buf)

  expect n, ParLe
  if n.tagId != sdefTag:
    raiseAssert "(sd) expected"

  # Pre-scan the ENTIRE symbol definition to extract ALL local symbols upfront.
  # This ensures local symbols are registered before any references to them,
  # regardless of where they appear in the definition (in types, nested procs, etc.)
  var localSyms = initTable[string, PSym]()
  var scanCursor = n
  extractLocalSymsFromTree(c, scanCursor, c.mods[symsModule].suffix, localSyms)

  # Now parse the symbol definition with all local symbols pre-registered
  s.infoImpl = c.infos.oldLineInfo(n.info)
  inc n
  loadSymFromCursor(c, s, n, c.mods[symsModule].suffix, localSyms)


template withNode(c: var DecodeContext; n: var Cursor; result: PNode; kind: TNodeKind; body: untyped) =
  let info = c.infos.oldLineInfo(n.info)
  inc n
  let flags = loadAtom(TNodeFlags, n)
  result = newNodeI(kind, info)
  result.flags = flags
  result.typField = c.loadTypeStub(n, localSyms)
  body
  skipParRi n

proc loadNode(c: var DecodeContext; n: var Cursor; thisModule: string;
              localSyms: var Table[string, PSym]): PNode =
  result = nil
  case n.kind
  of Symbol:
    let info = c.infos.oldLineInfo(n.info)
    let symName = pool.syms[n.symId]
    # Check local symbols first
    let localSym = localSyms.getOrDefault(symName)
    if localSym != nil:
      result = newSymNode(localSym, info)
      inc n
    else:
      result = newSymNode(c.loadSymStub(n, thisModule, localSyms), info)
      if result.typField == nil:
        result.flags.incl nfLazyType
  of DotToken:
    result = nil
    inc n
  of StringLit:
    result = newStrNode(pool.strings[n.litId], c.infos.oldLineInfo(n.info))
    inc n
  of ParLe:
    let kind = n.nodeKind
    case kind
    of nkNone:
      # special NIF introduced tag?
      case pool.tags[n.tagId]
      of hiddenTypeTagName:
        inc n
        let typ = c.loadTypeStub(n, localSyms)
        let info = c.infos.oldLineInfo(n.info)
        result = newSymNode(c.loadSymStub(n, thisModule, localSyms), info)
        result.typField = typ
        skipParRi n
      of symDefTagName:
        let info = c.infos.oldLineInfo(n.info)
        let name = n.firstSon
        assert name.kind == SymbolDef
        let symName = pool.syms[name.symId]
        # Check if this is a local symbol (no module suffix in name)
        let sn = parseSymName(symName)
        let isLocal = sn.module.len == 0
        var sym: PSym
        if isLocal:
          # Local symbol - not in the index, defined inline in NIF.
          # Check if we already have a stub from extractLocalSymsFromType
          sym = localSyms.getOrDefault(symName)
          if sym == nil:
            # First time seeing this local symbol - create it
            let module = moduleId(c, thisModule)
            let val = addr c.mods[module].symCounter
            inc val[]
            let id = ItemId(module: module.int32, item: val[])
            sym = PSym(itemId: id, kindImpl: skStub, name: c.cache.getIdent(sn.name),
                       disamb: sn.count.int32, state: Complete)
            localSyms[symName] = sym  # register for later references
          # Now fully load the symbol from the sdef
          inc n # skip `sd` tag
          loadSymFromCursor(c, sym, n, thisModule, localSyms)
          sym.state = Sealed  # mark as fully loaded
          result = newSymNode(sym, info)
        else:
          sym = c.loadSymStub(name.symId, thisModule, localSyms)
          skip n  # skip the entire sdef for indexed symbols
          result = newSymNode(sym, info)
          result.flags.incl nfLazyType
      of typeDefTagName:
        raiseAssert "`td` tag in invalid context"
      of "none":
        result = newNodeI(nkNone, c.infos.oldLineInfo(n.info))
        inc n
        result.flags = loadAtom(TNodeFlags, n)
        skipParRi n
      else:
        raiseAssert "Unknown NIF tag " & pool.tags[n.tagId]
    of nkEmpty:
      result = newNodeI(nkEmpty, c.infos.oldLineInfo(n.info))
      inc n
      if n.kind != ParRi:
        result.flags = loadAtom(TNodeFlags, n)
        result.typField = c.loadTypeStub(n, localSyms)
      skipParRi n
    of nkIdent:
      let info = c.infos.oldLineInfo(n.info)
      inc n
      let flags = loadAtom(TNodeFlags, n)
      let typ = c.loadTypeStub(n, localSyms)
      expect n, Ident
      result = newIdentNode(c.cache.getIdent(pool.strings[n.litId]), info)
      inc n
      result.flags = flags
      result.typField = typ
      skipParRi n
    of nkSym:
      #let info = c.infos.oldLineInfo(n.info)
      #result = newSymNode(c.loadSymStub n, info)
      raiseAssert "nkSym should be mapped to a NIF symbol, not a tag"
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
    else:
      c.withNode n, result, kind:
        while n.kind != ParRi:
          result.sons.add c.loadNode(n, thisModule, localSyms)
  else:
    raiseAssert "expected string literal but got " & $n.kind

proc moduleSuffix(conf: ConfigRef; f: FileIndex): string =
  cachedModuleSuffix(conf, f)

proc loadSymFromIndexEntry(c: var DecodeContext; module: FileIndex;
                           nifName: string; entry: NifIndexEntry; thisModule: string): PSym =
  ## Loads a symbol from the NIF index entry using the entry directly.
  ## Creates a symbol stub without looking up in the index (since the index may be moved out).
  result = c.syms.getOrDefault(nifName)[0]
  if result == nil:
    let symAsStr = nifName
    let sn = parseSymName(symAsStr)
    let symModule = moduleId(c, if sn.module.len > 0: sn.module else: thisModule)
    let val = addr c.mods[symModule].symCounter
    inc val[]

    let id = ItemId(module: symModule.int32, item: val[])
    result = PSym(itemId: id, kindImpl: skStub, name: c.cache.getIdent(sn.name), disamb: sn.count.int32, state: Partial)
    c.syms[symAsStr] = (result, entry)

proc extractBasename(nifName: string): string =
  ## Extract the base name from a NIF name (ident.disamb.module -> ident)
  result = ""
  for c in nifName:
    if c == '.': break
    result.add c

proc populateInterfaceTablesFromIndex(c: var DecodeContext; module: FileIndex;
                                      interf, interfHidden: var TStrTable; thisModule: string) =
  ## Populates interface tables from the NIF index structure.
  ## Uses the index's public/private tables instead of traversing AST.

  # Move the public table and exports list out to avoid iterator invalidation
  # (moduleId can add to c.mods which would invalidate Table iterators)
  # We move them back after iteration.
  var publicTab = move c.mods[module].index.public
  var exportsList = move c.mods[module].index.exports

  # Add all public symbols to interf (exported interface) and interfHidden
  for nifName, entry in publicTab:
    if not nifName.startsWith("`t"):
      # do not load types, they are not part of an interface but an implementation detail!
      #echo "LOADING SYM ", nifName, " ", entry.offset
      let sym = loadSymFromIndexEntry(c, module, nifName, entry, thisModule)
      if sym != nil:
        strTableAdd(interf, sym)
        strTableAdd(interfHidden, sym)

  # Move public table back
  c.mods[module].index.public = move publicTab

  # Process exports (re-exports from other modules)
  for exp in exportsList:
    let (path, kind, names) = exp
    # Convert path to module suffix
    let expSuffix = moduleSuffix(path, cast[seq[string]](c.infos.config.searchPaths))
    # Load the exported module's index
    let expModule = moduleId(c, expSuffix)

    # Move the exported module's public table out to avoid iterator invalidation
    var expPublicTab = move c.mods[expModule].index.public

    # Build a set of names for filtering
    var nameSet = initHashSet[string]()
    for nameId in names:
      nameSet.incl pool.strings[nameId]

    # Add symbols based on export kind
    for nifName, entry in expPublicTab:
      if nifName.startsWith("`t"):
        continue  # skip types

      let basename = extractBasename(nifName)
      let shouldInclude =
        case kind
        of ExportIdx: true  # export all
        of FromexportIdx: basename in nameSet  # only specific names
        of ExportexceptIdx: basename notin nameSet  # all except specific names
        else: false

      if shouldInclude:
        let sym = loadSymFromIndexEntry(c, expModule, nifName, entry, expSuffix)
        if sym != nil:
          strTableAdd(interf, sym)
          strTableAdd(interfHidden, sym)

    # Move exported module's public table back
    c.mods[expModule].index.public = move expPublicTab

  # Move exports list back
  c.mods[module].index.exports = move exportsList

  when false:
    # Add private symbols to interfHidden only
    for nifName, entry in idx.private:
      let sym = loadSymFromIndexEntry(c, module, nifName, entry, thisModule)
      if sym != nil:
        strTableAdd(interfHidden, sym)

proc toNifFilename*(conf: ConfigRef; f: FileIndex): string =
  let suffix = moduleSuffix(conf, f)
  result = toGeneratedFile(conf, AbsoluteFile(suffix), ".nif").string

proc toNifIndexFilename*(conf: ConfigRef; f: FileIndex): string =
  let suffix = moduleSuffix(conf, f)
  result = toGeneratedFile(conf, AbsoluteFile(suffix), ".s.idx.nif").string

proc resolveSym(c: var DecodeContext; symAsStr: string; alsoConsiderPrivate: bool): PSym =
  result = c.syms.getOrDefault(symAsStr)[0]
  if result != nil:
    return result

  let sn = parseSymName(symAsStr)
  if sn.module.len == 0:
    return nil  # Local symbols shouldn't be hooks
  let module = moduleId(c, sn.module)
  # Look up the symbol in the module's index
  var offs = c.mods[module].index.public.getOrDefault(symAsStr)
  if offs.offset == 0:
    if alsoConsiderPrivate:
      offs = c.mods[module].index.private.getOrDefault(symAsStr)
      if offs.offset == 0:
        return nil
    else:
      return nil
  # Create a stub symbol
  let val = addr c.mods[module].symCounter
  inc val[]
  let id = ItemId(module: int32(module), item: val[])
  result = PSym(itemId: id, kindImpl: skProc, name: c.cache.getIdent(sn.name),
                disamb: sn.count.int32, state: Partial)
  c.syms[symAsStr] = (result, offs)

proc resolveHookSym*(c: var DecodeContext; symId: nifstreams.SymId): PSym =
  ## Resolves a hook SymId to PSym.
  ## Hook symbols are often private (generated =destroy, =wasMoved, etc.)
  let symAsStr = pool.syms[symId]
  result = resolveSym(c, symAsStr, true)

proc tryResolveCompilerProc*(c: var DecodeContext; name: string; moduleFileIdx: FileIndex): PSym =
  ## Tries to resolve a compiler proc from a module by checking the NIF index.
  ## Returns nil if the symbol doesn't exist.
  let suffix = moduleSuffix(c.infos.config, moduleFileIdx)
  let symName = name & ".0." & suffix
  result = resolveSym(c, symName, true)

proc loadLogOp(c: var DecodeContext; logOps: var seq[LogEntry]; s: var Stream; kind: LogEntryKind; op: TTypeAttachedOp; module: int): PackedToken =
  result = next(s)
  var key = ""
  if result.kind == StringLit:
    key = pool.strings[result.litId]
    result = next(s)
  else:
    raiseAssert "expected StringLit but got " & $result.kind
  if result.kind == Symbol:
    let sym = resolveHookSym(c, result.symId)
    if sym != nil:
      logOps.add LogEntry(kind: kind, op: op, module: module, key: key, sym: sym)
    # else: symbol not indexed, skip this hook entry
    result = next(s)
  if result.kind == ParRi:
    result = next(s)
  else:
    raiseAssert "expected ParRi but got " & $result.kind

proc skipTree(s: var Stream): PackedToken =
  result = next(s)
  var nested = 1
  while nested > 0:
    if result.kind == ParLe:
      inc nested
    elif result.kind == ParRi:
      dec nested
    elif result.kind == EofToken:
      break
    result = next(s)

proc nextSubtree(r: var Stream; dest: var TokenBuf; tok: var PackedToken) =
  r.parents[0] = tok.info
  var nested = 1
  dest.add tok # tag
  while true:
    tok = r.next()
    dest.add tok
    if tok.kind == EofToken:
      break
    elif tok.kind == ParLe:
      inc nested
    elif tok.kind == ParRi:
      dec nested
      if nested == 0: break

proc processTopLevel(c: var DecodeContext; s: var Stream; loadFullAst: bool; suffix: string; logOps: var seq[LogEntry]; module: int): PNode =
  result = newNode(nkStmtList)
  var localSyms = initTable[string, PSym]()

  var t = next(s) # skip dot
  var cont = true
  while cont and t.kind != EofToken:
    if t.kind == ParLe:
      if t.tagId == replayTag:
        # Always load replay actions (macro cache operations)
        t = next(s)  # move past (replay
        while t.kind != ParRi and t.kind != EofToken:
          if t.kind == ParLe:
            var buf = createTokenBuf(50)
            nextSubtree(s, buf, t)
            var cursor = cursorAt(buf, 0)
            let replayNode = loadNode(c, cursor, suffix, localSyms)
            if replayNode != nil:
              result.sons.add replayNode
          t = next(s)
        if t.kind == ParRi:
          t = next(s)
        else:
          raiseAssert "expected ParRi but got " & $t.kind
      elif t.tagId == repConverterTag:
        t = loadLogOp(c, logOps, s, ConverterEntry, attachedTrace, module)
      elif t.tagId == repDestroyTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedDestructor, module)
      elif t.tagId == repWasMovedTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedWasMoved, module)
      elif t.tagId == repCopyTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedAsgn, module)
      elif t.tagId == repSinkTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedSink, module)
      elif t.tagId == repDupTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedDup, module)
      elif t.tagId == repTraceTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedTrace, module)
      elif t.tagId == repDeepCopyTag:
        t = loadLogOp(c, logOps, s, HookEntry, attachedDeepCopy, module)
      elif t.tagId == repEnumToStrTag:
        t = loadLogOp(c, logOps, s, EnumToStrEntry, attachedTrace, module)
      elif t.tagId == repMethodTag:
        t = loadLogOp(c, logOps, s, MethodEntry, attachedTrace, module)
        #elif t.tagId == repClassTag:
        #  t = loadLogOp(c, logOps, s, ClassEntry, attachedTrace, module)
      elif t.tagId == includeTag or t.tagId == importTag:
        t = skipTree(s)
      elif t.tagId == implTag:
        cont = false
      elif loadFullAst:
        # Parse the full statement
        var buf = createTokenBuf(50)
        nextSubtree(s, buf, t)
        var cursor = cursorAt(buf, 0)
        let stmtNode = loadNode(c, cursor, suffix, localSyms)
        if stmtNode != nil:
          result.sons.add stmtNode
      else:
        cont = false
    else:
      cont = false

proc loadNifModule*(c: var DecodeContext; f: FileIndex; interf, interfHidden: var TStrTable;
                    logOps: var seq[LogEntry];
                    loadFullAst: bool = false): PNode =
  let suffix = moduleSuffix(c.infos.config, f)

  # Ensure module index is loaded - moduleId returns the FileIndex for this suffix
  let module = moduleId(c, suffix)

  # Populate interface tables from the NIF index structure
  # Symbols are created as stubs (Partial state) and will be loaded lazily via loadSym
  populateInterfaceTablesFromIndex(c, module, interf, interfHidden, suffix)

  # Load the module AST (or just replay actions if loadFullAst is false)
  let s = addr c.mods[module].stream
  s.r.jumpTo 0  # Start from beginning
  discard processDirectives(s.r)
  var t = next(s[])
  if t.kind == ParLe and pool.tags[t.tagId] == toNifTag(nkStmtList):
    t = next(s[])  # skip (stmts
    t = next(s[])  # skip flags
    result = processTopLevel(c, s[], loadFullAst, suffix, logOps, f.int)
  else:
    result = newNode(nkStmtList)


when isMainModule:
  import std / syncio
  let obj = parseSymName("a.123.sys")
  echo obj.name, " ", obj.module, " ", obj.count
  let objb = parseSymName("abcdef.0121")
  echo objb.name, " ", objb.module, " ", objb.count
