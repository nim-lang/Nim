#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Computes hash values for routine (proc, method etc) signatures.

import ast
from hashes import Hash
from astalgo import debug
from types import typeToString, preferDesc
from strutils import startsWith, contains

when defined(useMetroHash64) or defined(useMetroHash128):
  import metrohash
else:
  import md5

when false:
  type
    SigHash* = uint32  ## a hash good enough for a filename or a proc signature

  proc sdbmHash(hash: SigHash, c: char): SigHash {.inline.} =
    return SigHash(c) + (hash shl 6) + (hash shl 16) - hash

  template `&=`*(x: var SigHash, c: char) = x = sdbmHash(x, c)
  template `&=`*(x: var SigHash, s: string) =
    for c in s: x = sdbmHash(x, c)

elif defined(useMetroHash64):
  type
    SigHashContext* = MetroHashContext
    SigHash* = MetroHash64Digest

  template SigHashInit*(c: untyped) = 
    metroHash64Init(c)

  template SigHashUpdate*(c, input, inputSize: untyped) = 
    metroHash64Update(c, input, inputSize)

  template SigHashFinal*(c, result: untyped) = 
    metroHash64Final(c, result)

  template lowlevel(v) =
    metroHash64Update(c, v)

  proc `&=`[T](c: var SigHashContext, input: T) = metroHash64Update(c, input)

elif defined(useMetroHash128):
  type
    SigHashContext* = MetroHashContext
    SigHash* = MetroHash128Digest

  template SigHashInit*(c: untyped) = 
    metroHash128Init(c)

  template SigHashUpdate*(c, input, inputSize: untyped) = 
    metroHash128Update(c, input, inputSize)

  template SigHashFinal*(c, result: untyped) = 
    metroHash128Final(c, result)

  template lowlevel(v) =
    metroHash128Update(c, v)

  proc `&=`[T](c: var SigHashContext, input: T) = metroHash128Update(c, input)

else:
  type
    SigHashContext* = MD5Context
    SigHash* = Md5Digest

  template SigHashInit*(c: untyped) = 
    md5Init(c)

  template SigHashUpdate*(c, input, inputSize: untyped) = 
    md5Update(c, input, inputSize)

  template SigHashFinal*(c, result: untyped) = 
    md5Final(c, result)

  template lowlevel(v) =
    md5Update(c, cast[cstring](unsafeAddr(v)), sizeof(v))

  proc `&=`(c: var SigHashContext, s: string) = md5Update(c, s, s.len)
  proc `&=`(c: var SigHashContext, ch: char) = md5Update(c, unsafeAddr ch, 1)
  proc `&=`(c: var SigHashContext, i: BiggestInt) =
    md5Update(c, cast[cstring](unsafeAddr i), sizeof(i))

const
  cb64 = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
    "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9a",
    "9b", "9c"]

proc toBase64a(s: cstring, len: int): string =
  ## encodes `s` into base64 representation.
  result = newStringOfCap(((len + 2) div 3) * 4)
  result.add '_'
  var i = 0
  while i < len - 2:
    let a = ord(s[i])
    let b = ord(s[i+1])
    let c = ord(s[i+2])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2) or ((c and 0xC0) shr 6)]
    result.add cb64[c and 0x3F]
    inc(i, 3)
  if i < len-1:
    let a = ord(s[i])
    let b = ord(s[i+1])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2)]
  elif i < len:
    let a = ord(s[i])
    result.add cb64[a shr 2]
    result.add cb64[(a and 3) shl 4]

proc `$`*(u: SigHash): string =
  toBase64a(cast[cstring](unsafeAddr u), sizeof(u))

proc `==`*(a, b: SigHash): bool =
  # {.borrow.}
  result = equalMem(unsafeAddr a, unsafeAddr b, sizeof(a))

proc hash*(u: SigHash): Hash =
  result = 0
  for x in 0..u.high:
    result = (result shl 8) or u[x].int

type
  ConsiderFlag* = enum
    CoProc
    CoType
    CoOwnerSig
    CoIgnoreRange

proc hashType(c: var SigHashContext, t: PType; flags: set[ConsiderFlag])

proc hashSym(c: var SigHashContext, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s
    while it != nil:
      c &= it.name.s
      c &= "."
      it = it.owner

proc hashTypeSym(c: var SigHashContext, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s
    while it != nil:
      if sfFromGeneric in it.flags and it.kind in routineKinds and
          it.typ != nil:
        hashType c, it.typ, {CoProc}
      c &= it.name.s
      c &= "."
      it = it.owner

proc hashTree(c: var SigHashContext, n: PNode) =
  if n == nil:
    c &= "\255"
    return
  let k = n.kind
  c &= char(k)
  # we really must not hash line information. 'n.typ' is debatable but
  # shouldn't be necessary for now and avoids potential infinite recursions.
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c &= n.ident.s
  of nkSym:
    hashSym(c, n.sym)
  of nkCharLit..nkUInt64Lit:
    let v = n.intVal
    lowlevel(v)
  of nkFloatLit..nkFloat64Lit:
    let v = n.floatVal
    lowlevel(v)
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0..<n.len: hashTree(c, n.sons[i])

proc hashType(c: var SigHashContext, t: PType; flags: set[ConsiderFlag]) =
  if t == nil:
    c &= "\254"
    return

  case t.kind
  of tyGenericInvocation:
    for i in countup(0, sonsLen(t) - 1):
      c.hashType t.sons[i], flags
    return
  of tyDistinct:
    if CoType in flags:
      c.hashType t.lastSon, flags
    else:
      c.hashSym(t.sym)
    return
  of tyAlias, tyGenericInst, tyUserTypeClasses:
    c.hashType t.lastSon, flags
    return
  else:
    discard
  case t.kind
  of tyBool, tyChar, tyInt..tyUInt64:
    # no canonicalization for integral types, so that e.g. ``pid_t`` is
    # produced instead of ``NI``:
    c &= char(t.kind)
    if t.sym != nil and {sfImportc, sfExportc} * t.sym.flags != {}:
      c.hashSym(t.sym)
  of tyObject, tyEnum:
    c &= char(t.kind)
    if t.typeInst != nil:
      assert t.typeInst.kind == tyGenericInst
      for i in countup(1, sonsLen(t.typeInst) - 2):
        c.hashType t.typeInst.sons[i], flags
    # Every cyclic type in Nim need to be constructed via some 't.sym', so this
    # is actually safe without an infinite recursion check:
    if t.sym != nil:
      #if "Future:" in t.sym.name.s and t.typeInst == nil:
      #  writeStackTrace()
      #  echo "yes ", t.sym.name.s
      #  #quit 1
      if CoOwnerSig in flags:
        c.hashTypeSym(t.sym)
      else:
        c.hashSym(t.sym)
      if sfAnon in t.sym.flags:
        # generated object names can be identical, so we need to
        # disambiguate furthermore by hashing the field types and names:
        # mild hack to prevent endless recursions (makes nimforum compile again):
        excl t.sym.flags, sfAnon
        let n = t.n
        for i in 0 ..< n.len:
          assert n[i].kind == nkSym
          let s = n[i].sym
          c.hashSym s
          c.hashType s.typ, flags
        incl t.sym.flags, sfAnon
    else:
      c &= t.id
    if t.len > 0 and t.sons[0] != nil:
      hashType c, t.sons[0], flags
  of tyRef, tyPtr, tyGenericBody, tyVar:
    c &= char(t.kind)
    c.hashType t.lastSon, flags
    if tfVarIsPtr in t.flags: c &= ".varisptr"
  of tyFromExpr:
    c &= char(t.kind)
    c.hashTree(t.n)
  of tyTuple:
    c &= char(t.kind)
    if t.n != nil and CoType notin flags:
      assert(sonsLen(t.n) == sonsLen(t))
      for i in countup(0, sonsLen(t.n) - 1):
        assert(t.n.sons[i].kind == nkSym)
        c &= t.n.sons[i].sym.name.s
        c &= ':'
        c.hashType(t.sons[i], flags+{CoIgnoreRange})
        c &= ','
    else:
      for i in countup(0, sonsLen(t) - 1): c.hashType t.sons[i], flags+{CoIgnoreRange}
  of tyRange:
    if CoIgnoreRange notin flags:
      c &= char(t.kind)
      c.hashTree(t.n)
    c.hashType(t.sons[0], flags)
  of tyStatic:
    c &= char(t.kind)
    c.hashTree(t.n)
    c.hashType(t.sons[0], flags)
  of tyProc:
    c &= char(t.kind)
    c &= (if tfIterator in t.flags: "iterator " else: "proc ")
    if CoProc in flags and t.n != nil:
      let params = t.n
      for i in 1..<params.len:
        let param = params[i].sym
        c &= param.name.s
        c &= ':'
        c.hashType(param.typ, flags)
        c &= ','
      c.hashType(t.sons[0], flags)
    else:
      for i in 0..<t.len: c.hashType(t.sons[i], flags)
    c &= char(t.callConv)
    if CoType notin flags:
      if tfNoSideEffect in t.flags: c &= ".noSideEffect"
      if tfThread in t.flags: c &= ".thread"
    if tfVarargs in t.flags: c &= ".varargs"
  of tyArray:
    c &= char(t.kind)
    for i in 0..<t.len: c.hashType(t.sons[i], flags-{CoIgnoreRange})
  else:
    c &= char(t.kind)
    for i in 0..<t.len: c.hashType(t.sons[i], flags)
  if tfNotNil in t.flags and CoType notin flags: c &= "not nil"

when defined(debugSigHashes):
  import db_sqlite

  let db = open(connection="sighashes.db", user="araq", password="",
                database="sighashes")
  db.exec(sql"DROP TABLE IF EXISTS sighashes")
  db.exec sql"""CREATE TABLE sighashes(
    id integer primary key,
    hash varchar(5000) not null,
    type varchar(5000) not null,
    unique (hash, type))"""
  #  select hash, type from sighashes where hash in
  # (select hash from sighashes group by hash having count(*) > 1) order by hash;

proc hashType*(t: PType; flags: set[ConsiderFlag] = {CoType}): SigHash =
  var c: SigHashContext
  SigHashInit(c)
  hashType c, t, flags+{CoOwnerSig}
  SigHashFinal(c, result)
  when defined(debugSigHashes):
    db.exec(sql"INSERT OR IGNORE INTO sighashes(type, hash) VALUES (?, ?)",
            typeToString(t), $result)

proc hashProc*(s: PSym): SigHash =
  var c: SigHashContext
  SigHashInit(c)
  hashType c, s.typ, {CoProc}

  var m = s
  while m.kind != skModule: m = m.owner
  let p = m.owner
  assert p.kind == skPackage
  c &= p.name.s
  c &= "."
  c &= m.name.s
  if sfDispatcher in s.flags:
    c &= ".dispatcher"
  # so that createThread[void]() (aka generic specialization) gets a unique
  # hash, we also hash the line information. This is pretty bad, but the best
  # solution for now:
  #c &= s.info.line
  SigHashFinal(c, result)

proc hashNonProc*(s: PSym): SigHash =
  var c: SigHashContext
  SigHashInit(c)
  hashSym(c, s)
  var it = s
  while it != nil:
    c &= it.name.s
    c &= "."
    it = it.owner
  # for bug #5135 we also take the position into account, but only
  # for parameters, because who knows what else position dependency
  # might cause:
  if s.kind == skParam:
    c &= s.position
  SigHashFinal(c, result)

proc hashOwner*(s: PSym): SigHash =
  var c: SigHashContext
  SigHashInit(c)
  var m = s
  while m.kind != skModule: m = m.owner
  let p = m.owner
  assert p.kind == skPackage
  c &= p.name.s
  c &= "."
  c &= m.name.s

  SigHashFinal(c, result)
