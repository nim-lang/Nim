import std / [assertions]
import ".." / [ast, astalgo, idents]
import "../../dist/nimony/src/lib" / nifbuilder
import enum2nif

type
  EncodeContext = object
    b: Builder

proc toNifSymDef(c: var EncodeContext; n: PNode) =
  assert n.kind == nkSym
  let sym = n.sym
  c.b.addTree toNifTag(n.kind)
  c.b.addIdent sym.name.s
  c.b.addIntLit sym.itemId.item
  c.b.endTree()

proc toNif(c: var EncodeContext; n: PNode) =
  case n.kind:
  of nkEmpty:
    c.b.addEmpty()
  of nkIntLit:
    c.b.addIntLit n.intVal
  of nkIdentDefs:
    c.b.addTree toNifTag(n.kind)
    assert n.len == 3
    toNifSymDef(c, n[0])
    toNif c, n[1]
    toNif c, n[2]
    c.b.endTree()
  else:
    assert n.len > 0, $n.kind
    c.b.addTree toNifTag(n.kind)
    for i in 0 ..< n.len:
      toNif c, n[i]
    c.b.endTree()

proc saveNif(c: var EncodeContext; n: PNode) =
  c.b.addHeader "nim2", "nim2-ic-nif"
  c.b.addTree "stmts"
  assert n.kind == nkStmtList
  for i in 0 ..< n.len:
    toNif c, n[i]
  c.b.endTree()

proc saveNifFile*(module: PSym; n: PNode) =
  let outfile = module.name.s & ".nif"
  var c = EncodeContext(b: nifbuilder.open(outfile))
  saveNif(c, n)
  c.b.close()

proc saveNifToBuffer*(n: PNode): string =
  var c = EncodeContext(b: nifbuilder.open(100))
  saveNif(c, n)
  c.b.close()
  result = c.b.extract
