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

proc addIntLit(b: var Builder; i: int64; suffix: string) =
  withTree(b, "suf"):
    addIntLit(b, i)
    addStrLit(b, suffix)

proc addFloatLit(b: var Builder; f: float; suffix: string) =
  withTree(b, "suf"):
    addFloatLit(b, f)
    addStrLit(b, suffix)

proc writeFlags[E](b: var Builder; flags: set[E]; tag: string) =
  var flagsAsIdent = ""
  genFlags(flags, flagsAsIdent)
  if flagsAsIdent.len > 0:
    b.withTree tag:
      b.addIdent flagsAsIdent

proc toNif(c: var EncodeContext; n: PNode)
proc toNif(c: var EncodeContext; t: PType; isTypeSection = false)

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
  if sfSystemModule in sym.owner.flags and sym.kind == skType and sym.typ != nil:
    toNif c, sym.typ
  else:
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

include nifencodertypes

proc writeNodeFlags(b: var Builder; flags: set[TNodeFlag]) {.inline.} =
  writeFlags b, flags, "nf"

template withNode(b: var Builder; n: PNode; body: untyped) =
  addTree b, toNifTag(n.kind)
  writeNodeFlags(b, n.flags)
  body
  endTree b

proc toNifTypeSection(c: var EncodeContext; n: PNode) =
  assert n.len == 3

  var name: PNode
  var visibility: PNode = nil
  var pragma: PNode = nil
  if n[0].kind == nkPragmaExpr:
    pragma = n[0][1]
    if n[0][0].kind == nkPostfix:
      visibility = n[0][0][0]
      name = n[0][0][1]
    else:
      name = n[0][0]
  elif n[0].kind == nkPostfix:
    visibility = n[0][0]
    name = n[0][1]
  else:
    name = n[0]

  c.b.withTree(toNifTag(n.kind)):
    symdefToNif(c, name)

    if visibility != nil:
      c.b.addIdent "x"
    else:
      c.b.addEmpty

    # TODO: pragma
    c.b.addEmpty

    # TODO: Generics
    toNif c, n[1]

    let last = n[2]
    if name.kind == nkSym:
      if name.sym.typ != nil:
        toNif c, name.sym.typ, true
      else:
        toNif c, last
    else:
      toNif c, last

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
  of nkCharLit:
    c.b.addCharLit n.intVal.char
  of nkIntLit:
    c.b.addIntLit n.intVal
  of nkInt8Lit:
    c.b.addIntLit n.intVal, "i8"
  of nkInt16Lit:
    c.b.addIntLit n.intVal, "i16"
  of nkInt32Lit:
    c.b.addIntLit n.intVal, "i32"
  of nkInt64Lit:
    c.b.addIntLit n.intVal, "i64"
  of nkUIntLit:
    c.b.addUIntLit cast[BiggestUInt](n.intVal)
  of nkUInt8Lit:
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u8"
  of nkUInt16Lit:
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u16"
  of nkUInt32Lit:
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u32"
  of nkUInt64Lit:
    c.b.addUIntLit cast[BiggestUInt](n.intVal), "u64"
  of nkFloatLit:
    c.b.addFloatLit n.floatVal
  of nkFloat32Lit:
    c.b.addFloatLit n.floatVal, "f32"
  of nkFloat64Lit:
    c.b.addFloatLit n.floatVal, "f64"
  of nkFloat128Lit:
    c.b.addFloatLit n.floatVal, "f128"
  of nkStrLit:
    c.b.addStrLit n.strVal
  of nkRStrLit:
    c.b.addStrLit n.strVal, "R"
  of nkTripleStrLit:
    c.b.addStrLit n.strVal, "T"
  of nkIdentDefs:
    c.b.withNode n:
      assert n.len == 3
      symdefToNif(c, n[0])
      if n[1].kind == nkSym:
        symToNif c, n[1].sym
      else:
        assert n[0].kind == nkSym
        toNif c, n[0].sym.typ
      toNif c, n[2]
  of nkTypeDef:
    toNifTypeSection(c, n)
  of nkImportStmt:
    toNifImport(c, n)
  else:
    assert n.len > 0, $n.kind
    c.b.withNode(n):
      for i in 0 ..< n.len:
        toNif c, n[i]

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
