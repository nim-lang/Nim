import std / [assertions, tables]
import "../../dist/nimony/src/lib" / [bitabs, nifreader, nifstreams, nifcursors]
import ".." / [ast, astalgo, idents, lineinfos, options, modulegraphs, pathutils]
import enum2nif

type
  DecodeContext = object
    graph: ModuleGraph

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

proc fromNif(c: var DecodeContext; n: var Cursor): PNode

proc fromNifLocal(c: var DecodeContext; n: var Cursor; kind: TNodeKind): PNode =
  result = newNodeI(kind, unknownLineInfo, 1)
  inc n
  assert n.nodeKind == nkIdentDefs
  result[0] = newNodeI(nkIdentDefs, unknownLineInfo, 3)
  inc n
  assert n.nodeKind == nkSym
  let symKind = case kind:
    of nkVarSection: skVar
    of nkLetSection: skLet
    else: skConst
  inc n
  assert n.kind == Ident
  let ident = c.graph.cache.getIdent(pool.strings[n.litId])
  inc n
  assert n.kind == IntLit
  let id = pool.integers[n.intId]
  result[0][0] = PSym(itemId: ItemId(module: 0, item: id.int32), kind: symKind, name: ident).newSymNode()
  inc n
  assert n.kind == ParRi
  inc n
  result[0][1] = fromNif(c, n)
  result[0][2] = fromNif(c, n)
  assert n.kind == ParRi
  inc n
  assert n.kind == ParRi
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
