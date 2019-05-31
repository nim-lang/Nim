#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import strutils, db_sqlite, md5

var db: DbConn

# We *hash* the relevant information into 128 bit hashes. This should be good
# enough to prevent any collisions.

type
  TUid = distinct MD5Digest

# For name mangling we encode these hashes via a variant of base64 (called
# 'base64a') and prepend the *primary* identifier to ease the debugging pain.
# So a signature like:
#
#   proc gABI(c: PCtx; n: PNode; opc: TOpcode; a, b: TRegister; imm: BiggestInt)
#
# is mangled into:
#   gABI_MTdmOWY5MTQ1MDcyNGQ3ZA
#
# This is a good compromise between correctness and brevity. ;-)

const
  cb64 = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
    "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "_A", "_B"]

proc toBase64a(s: cstring, len: int): string =
  ## encodes `s` into base64 representation. After `lineLen` characters, a
  ## `newline` is added.
  result = newStringOfCap(((len + 2) div 3) * 4)
  var i = 0
  while i < s.len - 2:
    let a = ord(s[i])
    let b = ord(s[i+1])
    let c = ord(s[i+2])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2) or ((c and 0xC0) shr 6)]
    result.add cb64[c and 0x3F]
    inc(i, 3)
  if i < s.len-1:
    let a = ord(s[i])
    let b = ord(s[i+1])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2)]
  elif i < s.len:
    let a = ord(s[i])
    result.add cb64[a shr 2]
    result.add cb64[(a and 3) shl 4]

proc toBase64a(u: TUid): string = toBase64a(cast[cstring](u), sizeof(u))

proc `&=`(c: var MD5Context, s: string) = md5Update(c, s, s.len)

proc hashSym(c: var MD5Context, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s.owner
    while it != nil:
      hashSym(c, it)
      c &= "."
      it = s.owner
    c &= s.name.s

proc hashTree(c: var MD5Context, n: PNode) =
  if n == nil:
    c &= "\255"
    return
  var k = n.kind
  md5Update(c, cast[cstring](addr(k)), 1)
  # we really must not hash line information. 'n.typ' is debatable but
  # shouldn't be necessary for now and avoids potential infinite recursions.
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c &= n.ident.s
  of nkSym:
    hashSym(c, n.sym)
  of nkCharLit..nkUInt64Lit:
    var v = n.intVal
    md5Update(c, cast[cstring](addr(v)), sizeof(v))
  of nkFloatLit..nkFloat64Lit:
    var v = n.floatVal
    md5Update(c, cast[cstring](addr(v)), sizeof(v))
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0..<n.len: hashTree(c, n.sons[i])

proc hashType(c: var MD5Context, t: PType) =
  # modelled after 'typeToString'
  if t == nil:
    c &= "\254"
    return

  var k = t.kind
  md5Update(c, cast[cstring](addr(k)), 1)

  if t.sym != nil and sfAnon notin t.sym.flags:
    # t.n for literals, but not for e.g. objects!
    if t.kind in {tyFloat, tyInt}: c.hashNode(t.n)
    c.hashSym(t.sym)

  case t.kind
  of tyGenericBody, tyGenericInst, tyGenericInvocation:
    for i in 0 ..< sonsLen(t)-ord(t.kind != tyGenericInvocation):
      c.hashType t.sons[i]
  of tyUserTypeClass:
    internalAssert t.sym != nil and t.sym.owner != nil
    c &= t.sym.owner.name.s
  of tyUserTypeClassInst:
    let body = t.base
    c.hashSym body.sym
    for i in 1 .. sonsLen(t) - 2:
      c.hashType t.sons[i]
  of tyFromExpr:
    c.hashTree(t.n)
  of tyArray:
    c.hashTree(t.sons[0].n)
    c.hashType(t.sons[1])
  of tyTuple:
    if t.n != nil:
      assert(sonsLen(t.n) == sonsLen(t))
      for i in 0 ..< sonsLen(t.n):
        assert(t.n.sons[i].kind == nkSym)
        c &= t.n.sons[i].sym.name.s
        c &= ":"
        c.hashType(t.sons[i])
        c &= ","
    else:
      for i in 0 ..< sonsLen(t): c.hashType t.sons[i]
  of tyRange:
    c.hashTree(t.n)
    c.hashType(t.sons[0])
  of tyProc:
    c &= (if tfIterator in t.flags: "iterator " else: "proc ")
    for i in 0..<t.len: c.hashType(t.sons[i])
    md5Update(c, cast[cstring](addr(t.callConv)), 1)

    if tfNoSideEffect in t.flags: c &= ".noSideEffect"
    if tfThread in t.flags: c &= ".thread"
  else:
    for i in 0..<t.len: c.hashType(t.sons[i])
  if tfNotNil in t.flags: c &= "not nil"

proc canonConst(n: PNode): TUid =
  var c: MD5Context
  md5Init(c)
  c.hashTree(n)
  c.hashType(n.typ)
  md5Final(c, MD5Digest(result))

proc canonSym(s: PSym): TUid =
  var c: MD5Context
  md5Init(c)
  c.hashSym(s)
  md5Final(c, MD5Digest(result))

proc pushType(w: PRodWriter, t: PType) =
  # check so that the stack does not grow too large:
  if iiTableGet(w.index.tab, t.id) == InvalidKey:
    w.tstack.add(t)

proc pushSym(w: PRodWriter, s: PSym) =
  # check so that the stack does not grow too large:
  if iiTableGet(w.index.tab, s.id) == InvalidKey:
    w.sstack.add(s)

proc encodeNode(w: PRodWriter, fInfo: TLineInfo, n: PNode,
                result: var string) =
  if n == nil:
    # nil nodes have to be stored too:
    result.add("()")
    return
  result.add('(')
  encodeVInt(ord(n.kind), result)
  # we do not write comments for now
  # Line information takes easily 20% or more of the filesize! Therefore we
  # omit line information if it is the same as the father's line information:
  if fInfo.fileIndex != n.info.fileIndex:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
    result.add(',')
    encodeVInt(fileIdx(w, toFilename(n.info)), result)
  elif fInfo.line != n.info.line:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
  elif fInfo.col != n.info.col:
    result.add('?')
    encodeVInt(n.info.col, result)
  var f = n.flags * PersistentNodeFlags
  if f != {}:
    result.add('$')
    encodeVInt(cast[int32](f), result)
  if n.typ != nil:
    result.add('^')
    encodeVInt(n.typ.id, result)
    pushType(w, n.typ)
  case n.kind
  of nkCharLit..nkInt64Lit:
    if n.intVal != 0:
      result.add('!')
      encodeVBiggestInt(n.intVal, result)
  of nkFloatLit..nkFloat64Lit:
    if n.floatVal != 0.0:
      result.add('!')
      encodeStr($n.floatVal, result)
  of nkStrLit..nkTripleStrLit:
    if n.strVal != "":
      result.add('!')
      encodeStr(n.strVal, result)
  of nkIdent:
    result.add('!')
    encodeStr(n.ident.s, result)
  of nkSym:
    result.add('!')
    encodeVInt(n.sym.id, result)
    pushSym(w, n.sym)
  else:
    for i in 0 ..< sonsLen(n):
      encodeNode(w, n.info, n.sons[i], result)
  add(result, ')')

proc encodeLoc(w: PRodWriter, loc: TLoc, result: var string) =
  var oldLen = result.len
  result.add('<')
  if loc.k != low(loc.k): encodeVInt(ord(loc.k), result)
  if loc.s != low(loc.s):
    add(result, '*')
    encodeVInt(ord(loc.s), result)
  if loc.flags != {}:
    add(result, '$')
    encodeVInt(cast[int32](loc.flags), result)
  if loc.t != nil:
    add(result, '^')
    encodeVInt(cast[int32](loc.t.id), result)
    pushType(w, loc.t)
  if loc.r != nil:
    add(result, '!')
    encodeStr($loc.r, result)
  if loc.a != 0:
    add(result, '?')
    encodeVInt(loc.a, result)
  if oldLen + 1 == result.len:
    # no data was necessary, so remove the '<' again:
    setLen(result, oldLen)
  else:
    add(result, '>')

proc encodeType(w: PRodWriter, t: PType, result: var string) =
  if t == nil:
    # nil nodes have to be stored too:
    result.add("[]")
    return
  # we need no surrounding [] here because the type is in a line of its own
  if t.kind == tyForward: internalError("encodeType: tyForward")
  # for the new rodfile viewer we use a preceding [ so that the data section
  # can easily be disambiguated:
  add(result, '[')
  encodeVInt(ord(t.kind), result)
  add(result, '+')
  encodeVInt(t.id, result)
  if t.n != nil:
    encodeNode(w, unknownLineInfo(), t.n, result)
  if t.flags != {}:
    add(result, '$')
    encodeVInt(cast[int32](t.flags), result)
  if t.callConv != low(t.callConv):
    add(result, '?')
    encodeVInt(ord(t.callConv), result)
  if t.owner != nil:
    add(result, '*')
    encodeVInt(t.owner.id, result)
    pushSym(w, t.owner)
  if t.sym != nil:
    add(result, '&')
    encodeVInt(t.sym.id, result)
    pushSym(w, t.sym)
  if t.size != - 1:
    add(result, '/')
    encodeVBiggestInt(t.size, result)
  if t.align != - 1:
    add(result, '=')
    encodeVInt(t.align, result)
  encodeLoc(w, t.loc, result)
  for i in 0 ..< sonsLen(t):
    if t.sons[i] == nil:
      add(result, "^()")
    else:
      add(result, '^')
      encodeVInt(t.sons[i].id, result)
      pushType(w, t.sons[i])

proc encodeLib(w: PRodWriter, lib: PLib, info: TLineInfo, result: var string) =
  add(result, '|')
  encodeVInt(ord(lib.kind), result)
  add(result, '|')
  encodeStr($lib.name, result)
  add(result, '|')
  encodeNode(w, info, lib.path, result)

proc encodeSym(w: PRodWriter, s: PSym, result: var string) =
  if s == nil:
    # nil nodes have to be stored too:
    result.add("{}")
    return
  # we need no surrounding {} here because the symbol is in a line of its own
  encodeVInt(ord(s.kind), result)
  result.add('+')
  encodeVInt(s.id, result)
  result.add('&')
  encodeStr(s.name.s, result)
  if s.typ != nil:
    result.add('^')
    encodeVInt(s.typ.id, result)
    pushType(w, s.typ)
  result.add('?')
  if s.info.col != -1'i16: encodeVInt(s.info.col, result)
  result.add(',')
  if s.info.line != -1'i16: encodeVInt(s.info.line, result)
  result.add(',')
  encodeVInt(fileIdx(w, toFilename(s.info)), result)
  if s.owner != nil:
    result.add('*')
    encodeVInt(s.owner.id, result)
    pushSym(w, s.owner)
  if s.flags != {}:
    result.add('$')
    encodeVInt(cast[int32](s.flags), result)
  if s.magic != mNone:
    result.add('@')
    encodeVInt(ord(s.magic), result)
  if s.options != w.options:
    result.add('!')
    encodeVInt(cast[int32](s.options), result)
  if s.position != 0:
    result.add('%')
    encodeVInt(s.position, result)
  if s.offset != - 1:
    result.add('`')
    encodeVInt(s.offset, result)
  encodeLoc(w, s.loc, result)
  if s.annex != nil: encodeLib(w, s.annex, s.info, result)
  if s.constraint != nil:
    add(result, '#')
    encodeNode(w, unknownLineInfo(), s.constraint, result)
  # lazy loading will soon reload the ast lazily, so the ast needs to be
  # the last entry of a symbol:
  if s.ast != nil:
    # we used to attempt to save space here by only storing a dummy AST if
    # it is not necessary, but Nim's heavy compile-time evaluation features
    # make that unfeasible nowadays:
    encodeNode(w, s.info, s.ast, result)


proc createDb() =
  db.exec(sql"""
    create table if not exists Module(
      id integer primary key,
      name varchar(256) not null,
      fullpath varchar(256) not null,
      interfHash varchar(256) not null,
      fullHash varchar(256) not null,

      created timestamp not null default (DATETIME('now'))
    );""")

  db.exec(sql"""
    create table if not exists Backend(
      id integer primary key,
      strongdeps varchar(max) not null,
      weakdeps varchar(max) not null,
      header varchar(max) not null,
      code varchar(max) not null
    )

    create table if not exists Symbol(
      id integer primary key,
      module integer not null,
      backend integer not null,
      name varchar(max) not null,
      data varchar(max) not null,
      created timestamp not null default (DATETIME('now')),

      foreign key (module) references Module(id),
      foreign key (backend) references Backend(id)
    );""")

  db.exec(sql"""
    create table if not exists Type(
      id integer primary key,
      module integer not null,
      name varchar(max) not null,
      data varchar(max) not null,
      created timestamp not null default (DATETIME('now')),

      foreign key (module) references module(id)
    );""")


