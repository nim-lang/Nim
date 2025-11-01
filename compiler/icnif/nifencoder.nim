import std / [assertions, sets]
import ".." / [ast, idents, lineinfos, msgs, options]
import "../../dist/nimony/src/lib" / [bitabs, nifstreams, nifcursors, lineinfos]
import enum2nif, icniftags

type
  EncodeContext = object
    conf: ConfigRef
    decodedSyms: HashSet[ItemId]
    decodedTypes: HashSet[ItemId]
    decodedFileIndices: HashSet[FileIndex]
    dest: TokenBuf

proc initEncodeContext(conf: ConfigRef): EncodeContext =
  result = EncodeContext(conf: conf,
                         dest: createTokenBuf())

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

proc toNif(c: var EncodeContext; info: TLineInfo): PackedLineInfo =
  if info == unknownLineInfo:
    NoLineInfo
  else:
    let fileId = pool.files.getOrIncl(c.conf.toFullPath(info.fileIndex))
    pack(pool.man, fileId, info.line.int32, info.col)

proc toNifModuleId(c: var EncodeContext; moduleId: int) =
  # `ItemId.module` in PType and PSym (and `PSym.position` when it is skModule) are module's FileIndex
  # but it cannot be directly encoded as the uniqueness of it can broke
  # if any import/include statements are changed.
  if not c.decodedFileIndices.containsOrIncl(moduleId.FileIndex):
    c.dest.buildTree modIdTag:
      c.dest.addIntLit moduleId
      let path = toFullPath(c.conf, moduleId.FileIndex)
      c.dest.addStrLit path
  else:
    c.dest.addIntLit moduleId

proc toNif(c: var EncodeContext; sym: PSym)
proc toNif(c: var EncodeContext; typ: PType)
proc toNif(c: var EncodeContext; n: PNode)

proc toNifDef(c: var EncodeContext; sym: PSym) =
  c.dest.addParLe symIdTag, c.toNif sym.info
  c.toNifModuleId sym.itemId.module
  c.dest.addIntLit sym.itemId.item
  c.dest.addIdent sym.name.s
  if sym.magic == mNone:
    c.dest.addDotToken
  else:
    c.dest.addIdent toNifTag(sym.magic)
  c.dest.writeFlags sym.flags
  c.dest.writeFlags sym.options
  c.dest.addIntLit sym.offset
  c.dest.addIntLit sym.disamb
  c.dest.buildTree sym.kind.toNifTag:
    case sym.kind
    of skLet, skVar, skField, skForVar:
      c.toNif sym.guard
      c.dest.addIntLit sym.bitsize
      c.dest.addIntLit sym.alignment
    else:
      discard
  if sym.kind == skModule:
    c.toNifModuleId sym.position
  else:
    c.dest.addIntLit sym.position
  c.toNif sym.typ
  c.toNif sym.owner
  c.dest.addIdent toNifTag(sym.loc.k)
  c.dest.addStrLit sym.loc.snippet
  c.dest.addParRi

proc toNifDef(c: var EncodeContext; typ: PType) =
  c.dest.buildTree typeIdTag:
    c.toNifModuleId typ.itemId.module
    c.dest.addIntLit typ.itemId.item
    c.dest.addIdent toNifTag(typ.kind)
    c.dest.writeFlags typ.flags
    # following PType or PSym type field can have cycles but this proc should not called recursively
    # as c.decodedTypes prevents it.
    if typ.len == 0:
      c.dest.addDotToken
    else:
      c.dest.buildTree sonsTag:
        for ch in typ.kids:
          c.toNif ch

    c.toNif typ.n
    c.toNif typ.owner
    c.toNif typ.sym

proc toNif(c: var EncodeContext; sym: PSym) =
  if sym == nil:
    c.dest.addDotToken()
  else:
    if not c.decodedSyms.containsOrIncl(sym.itemId):
      c.toNifDef sym
    else:
      c.dest.buildTree symTag:
        c.dest.addIntLit sym.itemId.module
        c.dest.addIntLit sym.itemId.item

proc toNif(c: var EncodeContext; typ: PType) =
  if typ == nil:
    c.dest.addDotToken()
  else:
    if not c.decodedTypes.containsOrIncl(typ.itemId):
      c.toNifDef typ
    else:
      c.dest.buildTree typeTag:
        c.dest.addIntLit typ.itemId.module
        c.dest.addIntLit typ.itemId.item

proc writeNodeFlags(dest: var TokenBuf; flags: set[TNodeFlag]) {.inline.} =
  writeFlags dest, flags

template withNode(c: var EncodeContext; n: PNode; body: untyped) =
  c.dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), c.toNif n.info
  writeNodeFlags(c.dest, n.flags)
  c.toNif n.typ
  body
  c.dest.addParRi

proc toNif(c: var EncodeContext; n: PNode) =
  if n == nil:
    c.dest.addDotToken
  else:
    case n.kind:
    of nkEmpty:
      let info = c.toNif n.info
      c.dest.addParLe pool.tags.getOrIncl(toNifTag(nkEmpty)), info
      c.dest.writeNodeFlags(n.flags)
      c.dest.addParRi
    of nkIdent:
      # nkIdent uses flags and typ when it is a generic parameter
      c.withNode n:
        c.dest.addIdent n.ident.s
    of nkSym:
      when false:
        echo "nkSym: ", n.sym.name.s
        if n.sym.kind == skModule:
          echo "position = ", n.sym.position
        debug(n.sym)
        var o = n.sym.owner
        for i in 0 .. 20:
          if o == nil:
            break
          echo "owner ", i, ":"
          if o.kind == skModule:
            echo "position = ", o.position
          debug(o)
          o = o.owner
      # PNode.typ and PNode.sym.typ are different in `int` nkSym Node in following statement:
      # type TestInt = int
      c.withNode n:
        c.toNif n.sym
    of nkCharLit:
      c.withNode n:
        c.dest.add charToken(n.intVal.char, NoLineInfo)
    of nkIntLit .. nkInt64Lit:
      c.withNode n:
        c.dest.addIntLit n.intVal
    of nkUIntLit .. nkUInt64Lit:
      c.withNode n:
        c.dest.addUIntLit cast[BiggestUInt](n.intVal)
    of nkFloatLit .. nkFloat128Lit:
      c.withNode n:
        c.dest.add floatToken(pool.floats.getOrIncl(n.floatVal), NoLineInfo)
    of nkStrLit .. nkTripleStrLit:
      c.withNode n:
        c.dest.addStrLit n.strVal
    of nkNilLit:
      c.withNode n:
        discard
    else:
      #assert n.kind in {nkArgList, nkBracket, nkRecList, nkPragma, nkType} or n.len > 0, $n.kind
      c.withNode(n):
        for i in 0 ..< n.len:
          c.toNif n[i]

proc saveNif(c: var EncodeContext; n: PNode): string =
  toNif c, n

  result = "(.nif24)\n" & toString(c.dest)

proc saveNifFile*(module: PSym; n: PNode; conf: ConfigRef) =
  let outfile = module.name.s & ".nif"
  var c = initEncodeContext(conf)
  writeFile outfile, saveNif(c, n)

proc saveNifToBuffer*(n: PNode; conf: ConfigRef): string =
  var c = initEncodeContext(conf)
  result = saveNif(c, n)
