import std / [assertions, tables]
import ".." / [ast, astalgo, idents, lineinfos, msgs, options]
import "../../dist/nimony/src/lib" / nifbuilder
import "../../dist/nimony/src/gear2" / modnames
import enum2nif

type
  EncodeContext = object
    b: Builder
    conf: ConfigRef
    toSuffix: Table[FileIndex, string]
    moduleToNifSuffix: Table[FileIndex, string] # FileIndex (PSym.position) -> module suffix

proc modname(c: var EncodeContext; idx: FileIndex): string =
  # copied from ../nifgen.nim
  result = c.toSuffix.getOrDefault(idx)
  if result.len == 0:
    let fp = toFullPath(c.conf, idx)
    result = moduleSuffix(fp, cast[seq[string]](c.conf.searchPaths))
    c.toSuffix[idx] = result

proc toNifSym(c: var EncodeContext; sym: PSym): string =
  result = sym.name.s & '.' & $sym.disamb
  let owner = sym.skipGenericOwner()
  if owner.kind == skModule:
    result.add '.'
    let fileIndex = FileIndex owner.position
    var modsuf = c.moduleToNifSuffix.getOrDefault(fileIndex)
    if modsuf.len == 0:
      modsuf = modname(c, fileIndex)
      c.moduleToNifSuffix[fileIndex] = modsuf
    result.add modsuf

proc symToNif(c: var EncodeContext; sym: PSym) =
  c.b.addSymbol toNifSym(c, sym)

proc symdefToNif(c: var EncodeContext; n: PNode) =
  assert n.kind == nkSym
  let sym = n.sym
  c.b.addTree toNifTag(n.kind)
  var name = toNifSym(c, sym)
  c.b.addSymbolDef name
  c.b.addIntLit sym.itemId.item
  if sym.owner == nil or sym.owner.kind == skPackage:
    c.b.addEmpty
  else:
    symToNif(c, sym.owner)
  if sym.flags == {}:
    c.b.addEmpty()
  else:
    var flags: string = ""
    genFlags(sym.flags, flags)
    c.b.addIdent flags
  if sym.kind == skModule:
    # position is module's FileIndex but it cannot be directly encoded
    # as the uniqueness of it can broke
    # if any import/include statements are changed.
    let path = toFullPath(c.conf, sym.position.FileIndex)
    c.b.addStrLit path
  else:
    c.b.addIntLit sym.position
  c.b.endTree()

proc toNifImport(c: var EncodeContext; n: PNode) =
  c.b.addTree toNifTag(n.kind)
  for i in 0 ..< n.len:
    assert n[i].kind == nkSym
    let sym = n[i].sym
    assert sym.kind == skModule
    symdefToNif(c, n[i])
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
    symdefToNif(c, n[0])
    toNif c, n[1]
    toNif c, n[2]
    c.b.endTree()
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
    symToNif(c, n.sym)
  of nkImportStmt:
    toNifImport(c, n)
  else:
    assert n.len > 0, $n.kind
    c.b.addTree toNifTag(n.kind)
    for i in 0 ..< n.len:
      toNif c, n[i]
    c.b.endTree()

proc saveNif(c: var EncodeContext; n: PNode) =
  c.b.addHeader "nim2", "nim2-ic-nif"
  toNif c, n

proc saveNifFile*(module: PSym; n: PNode; conf: ConfigRef) =
  let outfile = module.name.s & ".nif"
  var c = EncodeContext(b: nifbuilder.open(outfile), conf: conf)
  saveNif(c, n)
  c.b.close()

proc saveNifToBuffer*(n: PNode; conf: ConfigRef): string =
  var c = EncodeContext(b: nifbuilder.open(100), conf: conf)
  saveNif(c, n)
  c.b.close()
  result = c.b.extract
