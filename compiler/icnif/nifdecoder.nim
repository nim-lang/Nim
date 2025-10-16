import std / [assertions, tables, parseutils]
import "../../dist/nimony/src/lib" / [bitabs, nifreader, nifstreams, nifcursors]
import ".." / [ast, astalgo, idents, lineinfos, options, modules, modulegraphs, msgs, pathutils]
import "../../dist/nimony/src/gear2" / modnames
import enum2nif

type
  DecodeContext = object
    graph: ModuleGraph
    nifSymToPSym: Table[SymId, PSym]
    types: Table[SymId, PType]
    owner: PSym
    sysTypes: Table[TTypeKind, PSym]
    idgen: IdGenerator

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

type
  SplittedNifSym = object
    name: string
    id: int
    module: string

proc splitNifSym(s: string): SplittedNifSym =
  result = SplittedNifSym()
  var i = s.len - 2
  var mp = -1
  while i > 0:
    if s[i] == '.':
      if s[i+1] in {'0'..'9'}:
        var id = 0
        discard parseutils.parseInt(s, id, i + 1)
        return SplittedNifSym(
          name: s.substr(0, i - 1),
          id: id,
          module: if mp < 0: "" else: s.substr(mp, s.high))
      else:
        mp = i + 1
    dec i

proc fromNif(c: var DecodeContext; n: var Cursor): PNode
proc fromNifType(c: var DecodeContext; n: var Cursor): PType

proc fromNifSymbol(c: var DecodeContext; n: var Cursor): PSym =
  result = c.nifSymToPSym[n.symId]
  inc n

proc fromNifSymDef(c: var DecodeContext; n: var Cursor; kind: TNodeKind): PNode =
  assert n.nodeKind == nkSym
  let symKind = case kind:
    of nkTypeSection: skType
    of nkVarSection: skVar
    of nkLetSection: skLet
    of nkImportStmt: skModule
    of nkEnumTy: skEnumField
    of nkRecList: skField
    else: skConst
  incExpect n, SymbolDef
  let nifSymId = n.symId
  let symdef = pool.syms[nifSymId].splitNifSym
  assert symdef.name.len != 0
  let ident = c.graph.cache.getIdent(symdef.name)
  incExpect n, IntLit
  let itemId = pool.integers[n.intId].int32
  incExpect n, {Symbol, DotToken}
  let owner = if n.kind == Symbol:
      fromNifSymbol(c, n)
    else:
      inc n
      nil
  expect n, {Ident, DotToken}
  let flags = if n.kind == Ident: pool.strings[n.litId].parseSymFlags else: {}
  inc n
  var position = if symKind == skModule:
      expect n, StringLit
      let path = pool.strings[n.litId].AbsoluteFile
      fileInfoIdx(c.graph.config, path).int
    else:
      expect n, IntLit
      pool.integers[n.intId]
  inc n

  var psym = PSym(itemId: ItemId(module: 0, item: itemId),
    kind: symKind,
    name: ident,
    flags: flags,
    position: position,
    disamb: symdef.id.int32)
  psym.setOwner(owner)
  result = newSymNode(psym)
  let hasSym = c.nifSymToPSym.hasKeyOrPut(nifSymId, psym)
  assert not hasSym

  skipParRi n

include nifdecodertypes

proc fromNifNodeFlags(n: var Cursor): set[TNodeFlag] =
  result = {}
  if n.kind == ParLe and pool.tags[n.tag] == "nf":
    incExpect n, Ident
    result = parseNodeFlags(pool.strings[n.litId])
    inc n
    skipParRi n

proc fromNifLocal(c: var DecodeContext; n: var Cursor; kind: TNodeKind): PNode =
  result = newNodeI(kind, unknownLineInfo, 1)
  inc n
  result.flags = fromNifNodeFlags(n)
  assert n.nodeKind == nkIdentDefs
  result[0] = newNodeI(nkIdentDefs, unknownLineInfo, 3)
  inc n
  result[0][0] = fromNifSymDef(c, n, kind)
  result[0][1] = newNode(nkEmpty)
  if n.kind == DotToken:
    inc n
  else:
    result[0][0].sym.typ = fromNifType(c, n)
  result[0][2] = fromNif(c, n)
  skipParRi n  # nkIdentDefs
  skipParRi n

proc fromNifTypeSection(c: var DecodeContext; n: var Cursor): PNode =
  result = newNodeI(nkTypeDef, unknownLineInfo, 3)
  inc n
  let sym = fromNifSymDef(c, n, nkTypeSection)
  if n.kind == DotToken:
    result[0] = sym
  else:
    var postfix = newNodeI(nkPostfix, unknownLineInfo, 2)
    postfix.add newIdentNode(c.graph.cache.getIdent("*"), unknownLineInfo)
    postfix.add sym
    result[0] = postfix
  inc n

  # TODO: pragma
  #result.add fromNif(c, n)
  assert n.kind == DotToken
  inc n

  # TODO: generics
  result[1] = fromNif(c, n)

  # type body
  result[2] = newNode(nkEmpty)
  sym.sym.typ = fromNifType(c, n)

  skipParRi n

proc fromNifImport(c: var DecodeContext; n: var Cursor): PNode =
  result = newNode(nkImportStmt)
  inc n
  while n.kind != ParRi:
    result.add fromNifSymDef(c, n, nkImportStmt)
  inc n

proc fromNifSuf(c: var DecodeContext; n: var Cursor): PNode =
  inc n
  case n.kind:
  of StringLit:
    let v = pool.strings[n.litId]
    incExpect n, StringLit
    let suffix = pool.strings[n.litId]
    let kind = case suffix
      of "R":
        nkRStrLit
      of "T":
        nkTripleStrLit
      else:
        assert false, "Unknown string literal suffix " & suffix
        nkNone
    result = newStrNode(kind, v)
  of IntLit:
    let v = pool.integers[n.intId]
    incExpect n, StringLit
    let suffix = pool.strings[n.litId]
    let kind = case suffix
      of "i8":
        tyInt8
      of "i16":
        tyInt16
      of "i32":
        tyInt32
      of "i64":
        tyInt64
      else:
        assert false, "Unknown int literal suffix " & suffix
        tyNone
    result = newIntTypeNode(v, c.getSysType(kind))
  of UIntLit:
    let v = pool.uintegers[n.uintId]
    incExpect n, StringLit
    let suffix = pool.strings[n.litId]
    let kind = case suffix
      of "u8":
        tyUInt8
      of "u16":
        tyUInt16
      of "u32":
        tyUInt32
      of "u64":
        tyUInt64
      else:
        assert false, "Unknown uint literal suffix " & suffix
        tyNone
    result = newIntTypeNode(cast[BiggestInt](v), c.getSysType(kind))
  of FloatLit:
    let v = pool.floats[n.floatId]
    incExpect n, StringLit
    let suffix = pool.strings[n.litId]
    let kind = case suffix
      of "f32":
        (nkFloat32Lit, tyFloat32)
      of "f64":
        (nkFloat64Lit, tyFloat64)
      of "f128":
        (nkFloat128Lit, tyFloat128)
      else:
        assert false, "Unknown uint literal suffix " & suffix
        (nkNone, tyNone)
    result = newFloatNode(kind[0], v)
    result.typ() = c.getSysType(kind[1])
  else:
    assert false, "invalid node in suf node " & $n.kind
  inc n
  skipParRi n

proc fromNif(c: var DecodeContext; n: var Cursor): PNode =
  result = nil
  case n.kind:
  of DotToken:
    result = newNode(nkEmpty)
    inc n
  of Symbol:
    result = newSymNode(fromNifSymbol(c, n))
  of StringLit:
    result = newStrNode(nkStrLit, pool.strings[n.litId])
    inc n
  of CharLit:
    result = newIntNode(nkCharLit, n.charLit.int)
    inc n
  of IntLit:
    result = newIntTypeNode(pool.integers[n.intId], c.getSysType(tyInt))
    inc n
  of UIntLit:
    result = newIntTypeNode(cast[BiggestInt](pool.uintegers[n.uintId]), c.getSysType(tyUInt))
    inc n
  of FloatLit:
    result = newFloatNode(nkFloatLit, pool.floats[n.floatId])
    result.typ() = c.getSysType(tyFloat)
    inc n
  of ParLe:
    let kind = n.nodeKind
    case kind:
    of nkPostfix, nkTypeSection, nkStmtList:
      result = newNode(kind)
      inc n
      result.flags = fromNifNodeFlags(n)
      while n.kind != ParRi:
        result.add fromNif(c, n)
      inc n
    of nkVarSection, nkLetSection:
      result = fromNifLocal(c, n, kind)
    of nkTypeDef:
      result = fromNifTypeSection(c, n)
    of nkImportStmt:
      result = fromNifImport(c, n)
    of nkNone:
      case pool.tags[n.tagId]:
      of "suf":
        result = fromNifSuf(c, n)
      else:
        assert false, "Unknown tag " & pool.tags[n.tagId]
    else:
      assert false, "Not yet implemented " & $kind
  else:
    assert false, "Not yet implemented " & $n.kind

proc loadNif(stream: var Stream; modulePath: AbsoluteFile; graph: ModuleGraph): PNode =
  discard processDirectives(stream.r)

  var buf = fromStream(stream)
  var n = beginRead(buf)

  var c = DecodeContext(graph: graph)

  let modSym = newModule(graph, fileInfoIdx(graph.config, modulePath))
  let modSuffix = moduleSuffix(modulePath.string, cast[seq[string]](graph.config.searchPaths))
  let nifModSym = modSym.name.s & '.' & $modSym.disamb & '.' & modSuffix
  let nifModSymId = pool.syms.getOrIncl(nifModSym)
  c.nifSymToPSym[nifModSymId] = modSym
  c.owner = modSym
  c.idgen = idGeneratorFromModule(modSym)

  result = fromNif(c, n)

  endRead(buf)

proc loadNifFile*(infile: AbsoluteFile; graph: ModuleGraph): PNode =
  var stream = nifstreams.open(infile.string)
  result = loadNif(stream, infile.changeFileExt("nim"), graph)
  stream.close

proc loadNifFromBuffer*(strbuf: sink string; modulePath: AbsoluteFile; graph: ModuleGraph): PNode =
  var stream = nifstreams.openFromBuffer(strbuf)
  result = loadNif(stream, modulePath, graph)

when isMainModule:
  import std/cmdline

  if paramCount() > 0:
    var graph = newModuleGraph(newIdentCache(), newConfigRef())
    var node = loadNifFile(paramStr(1).toAbsolute(toAbsoluteDir(".")), graph)
    debug(node)
