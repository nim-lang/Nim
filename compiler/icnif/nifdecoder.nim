import std / [assertions, tables, parseutils]
import "../../dist/nimony/src/lib" / [bitabs, nifreader, nifstreams, nifcursors]
import ".." / [ast, astalgo, idents, lineinfos, options, modules, modulegraphs, msgs, pathutils]
import "../../dist/nimony/src/gear2" / modnames
import enum2nif

type
  DecodeContext = object
    graph: ModuleGraph
    nifSymToPSym: Table[string, PSym] # foo.1.modsuffix -> PSym

proc nodeKind(n: Cursor): TNodeKind {.inline.} =
  assert n.kind == ParLe
  pool.tags[n.tagId].parseNodeKind()

var sysTypes: Table[TTypeKind, PType]

proc getSysType(typeKind: TTypeKind): PType =
  # This will be replaced with magicsys.getSysType
  assert typeKind in {tyBool, tyChar, tyInt .. tyUInt64}
  if typeKind in sysTypes:
    result = sysTypes[typeKind]
  else:
    result = PType(itemId: ItemId(module: 0, item: typeKind.int32), kind: typeKind)
    sysTypes[typeKind] = result

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

proc fromNifSymbol(c: var DecodeContext; n: var Cursor): PSym =
  result = c.nifSymToPSym[pool.syms[n.symId]]
  inc n

proc fromNifSymDef(c: var DecodeContext; n: var Cursor; kind: TNodeKind): PNode =
  assert n.nodeKind == nkSym
  let symKind = case kind:
    of nkVarSection: skVar
    of nkLetSection: skLet
    of nkImportStmt: skModule
    else: skConst
  inc n
  assert n.kind == SymbolDef
  let nifSym = pool.syms[n.symId]
  let symdef = nifSym.splitNifSym
  assert symdef.name.len != 0
  let ident = c.graph.cache.getIdent(symdef.name)
  inc n
  assert n.kind == IntLit
  let itemId = pool.integers[n.intId].int32
  inc n
  assert n.kind in {Symbol, DotToken}, $n.kind
  let owner = if n.kind == Symbol:
      fromNifSymbol(c, n)
    else:
      inc n
      nil
  assert n.kind in {Ident, DotToken}, $n.kind
  let flags = if n.kind == Ident: pool.strings[n.litId].parseSymFlags else: {}
  inc n
  var position = if symKind == skModule:
      assert n.kind == StringLit
      let path = pool.strings[n.litId].AbsoluteFile
      fileInfoIdx(c.graph.config, path).int
    else:
      assert n.kind == IntLit
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
  let hasSym = c.nifSymToPSym.hasKeyOrPut(nifSym, psym)
  assert not hasSym

  assert n.kind == ParRi
  inc n

proc fromNifLocal(c: var DecodeContext; n: var Cursor; kind: TNodeKind): PNode =
  result = newNodeI(kind, unknownLineInfo, 1)
  inc n
  assert n.nodeKind == nkIdentDefs
  result[0] = newNodeI(nkIdentDefs, unknownLineInfo, 3)
  inc n
  result[0][0] = fromNifSymDef(c, n, kind)
  result[0][1] = fromNif(c, n)
  result[0][2] = fromNif(c, n)
  assert n.kind == ParRi  # nkIdentDefs
  inc n
  assert n.kind == ParRi
  inc n

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
    inc n
    assert n.kind == StringLit
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
    inc n
    assert n.kind == StringLit
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
    result = newIntTypeNode(v, getSysType(kind))
  of UIntLit:
    let v = pool.uintegers[n.uintId]
    inc n
    assert n.kind == StringLit
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
    result = newIntTypeNode(cast[BiggestInt](v), getSysType(kind))
  of FloatLit:
    let v = pool.floats[n.floatId]
    inc n
    assert n.kind == StringLit
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
    result.typ() = getSysType(kind[1])
  else:
    assert false, "invalid node in suf node " & $n.kind
  inc n
  assert n.kind == ParRi
  inc n

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
    result = newIntTypeNode(pool.integers[n.intId], getSysType(tyInt))
    inc n
  of UIntLit:
    result = newIntTypeNode(cast[BiggestInt](pool.uintegers[n.uintId]), getSysType(tyUInt))
    inc n
  of FloatLit:
    result = newFloatNode(nkFloatLit, pool.floats[n.floatId])
    result.typ() = getSysType(tyFloat)
    inc n
  of ParLe:
    let kind = n.nodeKind
    case kind:
    of nkStmtList:
      result = newNode(nkStmtList)
      inc n
      while n.kind != ParRi:
        result.add fromNif(c, n)
      inc n
    of nkVarSection, nkLetSection:
      result = fromNifLocal(c, n, kind)
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
  c.nifSymToPSym[nifModSym] = modSym

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
