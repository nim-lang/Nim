import std / [assertions, tables]
import "../../dist/nimony/src/lib" / [bitabs, nifreader, nifstreams, nifcursors, lineinfos]
import ".." / [ast, idents, lineinfos, options, modules, modulegraphs, msgs, pathutils]
import enum2nif, icniftags

type
  DecodeContext = object
    graph: ModuleGraph
    symbols: Table[ItemId, PSym]
    types: Table[ItemId, PType]
    modules: Table[int, FileIndex] # maps module id in NIF to FileIndex of the module

proc nodeKind(n: Cursor): TNodeKind {.inline.} =
  assert n.kind == ParLe
  pool.tags[n.tagId].parseNodeKind()

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

when false:
  proc expectTag(n: Cursor; tag: string) =
    let id = pool.tags.getKeyId(tag)
    if id == TagId(0):
      when defined(debug):
        writeStackTrace()
      quit "[NIF decoder] expected: " & tag & " but doesn't exist" & toString n
    else:
      expectTag(n, id)

proc fromNifLineInfo(c: var DecodeContext; n: Cursor): TLineInfo =
  if n.info == NoLineInfo:
    unknownLineInfo
  else:
    let info = pool.man.unpack(n.info)
    c.graph.config.newLineInfo(pool.files[info.file].AbsoluteFile, info.line, info.col)

proc fromNifModuleId(c: var DecodeContext; n: var Cursor): (FileIndex, int32) =
  expect n, {ParLe, IntLit}
  if n.kind == ParLe:
    expectTag n, modIdTag
    incExpect n, IntLit
    let id = pool.integers[n.intId]
    incExpect n, StringLit
    let path = pool.strings[n.litId].AbsoluteFile
    result = (fileInfoIdx(c.graph.config, path), id.int32)
    assert id notin c.modules
    c.modules[id] = result[0]
    inc n
    skipParRi n
  elif n.kind == IntLit:
    let id = pool.integers[n.intId]
    result = (c.modules[id], id.int32)
    inc n

proc fromNifSymbol(c: var DecodeContext; n: var Cursor): PSym
proc fromNifType(c: var DecodeContext; n: var Cursor): PType
proc fromNif(c: var DecodeContext; n: var Cursor): PNode

proc fromNifSymDef(c: var DecodeContext; n: var Cursor): PSym =
  expectTag n, symIdTag
  let info = c.fromNifLineInfo n
  inc n
  let (itemIdModule, nifModId) = c.fromNifModuleId(n)
  expect n, IntLit
  let itemId = pool.integers[n.intId].int32
  incExpect n, Ident
  let ident = c.graph.cache.getIdent(pool.strings[n.litId])
  incExpect n, {Ident, DotToken}
  let magic = if n.kind == Ident: pool.strings[n.litId].parseMagic else: mNone
  incExpect n, {Ident, DotToken}
  let flags = if n.kind == Ident: pool.strings[n.litId].parseSymFlags else: {}
  incExpect n, {Ident, DotToken}
  let options = if n.kind == Ident: pool.strings[n.litId].parseOptions else: {}
  incExpect n, IntLit
  let offset = pool.integers[n.intId].int32
  incExpect n, IntLit
  let disamb = pool.integers[n.intId].int32
  incExpect n, ParLe
  let kind = parseSymKind(pool.tags[n.tagId])
  inc n

  result = PSym(itemId: ItemId(module: itemIdModule.int32, item: itemId),
    kind: kind,
    magic: magic,
    name: ident,
    info: info,
    flags: flags,
    options: options,
    offset: offset,
    disamb: disamb)

  # PNode, PSym or PType type fields in PSym can have cycles.
  # Add PSym to `c.symbols` before parsing these fields so that 
  # they can refer this PSym.
  let nifItemId = ItemId(module: nifModId, item: itemId)
  assert nifItemId notin c.symbols
  c.symbols[nifItemId] = result

  case kind
  of skLet, skVar, skField, skForVar:
    result.guard = c.fromNifSymbol n
    expect n, IntLit
    result.bitsize = pool.integers[n.intId]
    incExpect n, IntLit
    result.alignment = pool.integers[n.intId]
    inc n
  else:
    discard
  skipParRi n
  result.position = if kind == skModule:
      c.fromNifModuleId(n)[0].int
    else:
      expect n, IntLit
      let p = pool.integers[n.intId]
      inc n
      p

  result.typ = c.fromNifType n
  result.setOwner(c.fromNifSymbol n)

  expect n, Ident
  result.loc.k = pool.strings[n.litId].parseLocKind()
  incExpect n, StringLit
  result.loc.snippet.add pool.strings[n.litId]
  inc n
  skipParRi n

proc fromNifTypeDef(c: var DecodeContext; n: var Cursor): PType =
  expectTag n, typeIdTag
  inc n
  let (itemIdModule, nifModId) = c.fromNifModuleId(n)
  expect n, IntLit
  let itemId = pool.integers[n.intId].int32
  incExpect n, Ident
  let kind = parseTypeKind(pool.strings[n.litId])
  incExpect n, {Ident, DotToken}
  let flags = if n.kind == Ident: pool.strings[n.litId].parseTypeFlags else: {}
  inc n

  result = PType(itemId: ItemId(module: itemIdModule.int32, item: itemId),
    kind: kind,
    flags: flags)
  let nifItemId = ItemId(module: nifModId, item: itemId)
  assert nifItemId notin c.types
  c.types[nifItemId] = result

  expect n, {DotToken, ParLe}
  if n.kind == DotToken:
    inc n
  else:
    expectTag n, sonsTag
    inc n
    while n.kind != ParRi:
      result.addAllowNil c.fromNifType n
    inc n
  result.n = c.fromNif n
  result.setOwner c.fromNifSymbol n
  result.sym = c.fromNifSymbol n
  skipParRi n

proc fromNifNodeFlags(n: var Cursor): set[TNodeFlag] =
  if n.kind == DotToken:
    result = {}
    inc n
  elif n.kind == Ident:
    result = parseNodeFlags(pool.strings[n.litId])
    inc n
  else:
    assert false, "expected Node flag but got " & $n.kind

proc fromNifSymbol(c: var DecodeContext; n: var Cursor): PSym =
  if n.kind == DotToken:
    result = nil
    inc n
  else:
    expect n, ParLe
    if n.tagId == symIdTag:
      result = c.fromNifSymDef n
    elif n.tagId == symTag:
      incExpect n, IntLit
      let nifModId = pool.integers[n.intId].int32
      incExpect n, IntLit
      let item = pool.integers[n.intId].int32
      let nifItemId = ItemId(module: nifModId, item: item)
      result = c.symbols[nifItemId]
      inc n
      skipParRi n
    else:
      assert false, "expected symbol tag but got " & pool.tags[n.tagId]

proc fromNifType(c: var DecodeContext; n: var Cursor): PType =
  if n.kind == DotToken:
    result = nil
    inc n
  else:
    expect n, ParLe
    if n.tagId == typeIdTag:
      result = c.fromNifTypeDef n
    elif n.tagId == typeTag:
      incExpect n, IntLit
      let nifModId = pool.integers[n.intId].int32
      incExpect n, IntLit
      let item = pool.integers[n.intId].int32
      let nifItemId = ItemId(module: nifModId, item: item)
      result = c.types[nifItemId]
      inc n
      skipParRi n
    else:
      assert false, "expected type tag but got " & pool.tags[n.tagId]

template withNode(c: var DecodeContext; n: var Cursor; result: PNode; kind: TNodeKind; body: untyped) =
  let info = c.fromNifLineInfo(n)
  incExpect n, {DotToken, Ident}
  let flags = fromNifNodeFlags n
  result = newNodeI(kind, info)
  result.flags = flags
  result.typ = c.fromNifType n
  body
  skipParRi n

proc fromNif(c: var DecodeContext; n: var Cursor): PNode =
  result = nil
  case n.kind:
  of DotToken:
    result = nil
    inc n
  of ParLe:
    let kind = n.nodeKind
    case kind:
    of nkEmpty:
      result = newNodeI(nkEmpty, c.fromNifLineInfo(n))
      incExpect n, {Ident, DotToken}
      let flags = fromNifNodeFlags n
      result.flags = flags
      skipParRi n
    of nkIdent:
      incExpect n, Ident
      result = newIdentNode(c.graph.cache.getIdent(pool.strings[n.litId]), c.fromNifLineInfo(n))
      inc n
      skipParRi n
    of nkSym:
      c.withNode n, result, kind:
        result.sym = c.fromNifSymbol n
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
        expect n, FloatLit
        result.floatVal = pool.floats[n.floatId]
        inc n
    of nkStrLit .. nkTripleStrLit:
      c.withNode n, result, kind:
        expect n, StringLit
        result.strVal = pool.strings[n.litId]
        inc n
    of nkNilLit:
      c.withNode n, result, kind:
        discard
    of nkNone:
      assert false, "Unknown tag " & pool.tags[n.tagId]
    else:
      c.withNode n, result, kind:
        while n.kind != ParRi:
          result.addAllowNil c.fromNif n
  else:
    assert false, "Not yet implemented " & $n.kind

proc loadNif(stream: var Stream; graph: ModuleGraph): PNode =
  discard processDirectives(stream.r)

  var buf = fromStream(stream)
  var n = beginRead(buf)

  var c = DecodeContext(graph: graph)

  result = fromNif(c, n)

  endRead(buf)

proc loadNifFile*(infile: AbsoluteFile; graph: ModuleGraph): PNode =
  var stream = nifstreams.open(infile.string)
  result = loadNif(stream, graph)
  stream.close

proc loadNifFromBuffer*(strbuf: sink string; graph: ModuleGraph): PNode =
  var stream = nifstreams.openFromBuffer(strbuf)
  result = loadNif(stream, graph)

when isMainModule:
  import std/cmdline

  if paramCount() > 0:
    var graph = newModuleGraph(newIdentCache(), newConfigRef())
    var node = loadNifFile(paramStr(1).toAbsolute(toAbsoluteDir(".")), graph)
    debug(node)
