import std / [assertions, tables, parseutils]
import "../../dist/nimony/src/lib" / [bitabs, nifreader, nifstreams, nifcursors, symparser]
import ".." / [ast, astalgo, idents, lineinfos, options, modulegraphs, msgs, pathutils]
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
  assert n.kind in {Ident, DotToken}, $n.kind
  let flags = if n.kind == Ident: pool.strings[n.litId].parseSymFlags else: {}
  inc n
  var position = 0
  if symKind == skModule:
    assert n.kind == StringLit
    let path = pool.strings[n.litId].AbsoluteFile
    position = fileInfoIdx(c.graph.config, path).int
  else:
    assert n.kind == IntLit
    position = pool.integers[n.intId]
  inc n

  let psym = PSym(itemId: ItemId(module: 0, item: symdef.id.int32), kind: symKind, name: ident, flags: flags, position: position)
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

proc fromNif(c: var DecodeContext; n: var Cursor): PNode =
  result = nil
  case n.kind:
  of DotToken:
    result = newNode(nkEmpty)
    inc n
  of IntLit:
    result = newIntTypeNode(pool.integers[n.intId], getSysType(tyInt))
    inc n
  of Symbol:
    let sym = c.nifSymToPSym[pool.syms[n.symId]]
    result = newSymNode(sym)
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
    else:
      assert false, "Not yet implemented " & $kind
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
    var node = loadNifFile(paramStr(1).AbsoluteFile, graph)
    debug(node)
