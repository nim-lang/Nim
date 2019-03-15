#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Computes hash values for routine (proc, method etc) signatures.

import ast, md5, tables, ropes
from hashes import Hash
from astalgo import debug
import types
from strutils import startsWith, contains

when false:
  type
    SigHash* = uint32  ## a hash good enough for a filename or a proc signature

  proc sdbmHash(hash: SigHash, c: char): SigHash {.inline.} =
    return SigHash(c) + (hash shl 6) + (hash shl 16) - hash

  template `&=`*(x: var SigHash, c: char) = x = sdbmHash(x, c)
  template `&=`*(x: var SigHash, s: string) =
    for c in s: x = sdbmHash(x, c)

else:
  type
    SigHash* = distinct Md5Digest

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
  proc `&=`(c: var MD5Context, s: string) = md5Update(c, s, s.len)
  proc `&=`(c: var MD5Context, ch: char) = md5Update(c, unsafeAddr ch, 1)
  proc `&=`(c: var MD5Context, r: Rope) =
    for l in leaves(r): md5Update(c, l, l.len)
  proc `&=`(c: var MD5Context, i: BiggestInt) =
    md5Update(c, cast[cstring](unsafeAddr i), sizeof(i))

  template lowlevel(v) =
    md5Update(c, cast[cstring](unsafeAddr(v)), sizeof(v))

  proc `==`*(a, b: SigHash): bool =
    # {.borrow.}
    result = equalMem(unsafeAddr a, unsafeAddr b, sizeof(a))

  proc hash*(u: SigHash): Hash =
    result = 0
    for x in 0..3:
      result = (result shl 8) or u.MD5Digest[x].int
type
  ConsiderFlag* = enum
    CoProc
    CoType
    CoOwnerSig
    CoIgnoreRange

proc hashType(c: var MD5Context, t: PType; flags: set[ConsiderFlag])

proc hashSym(c: var MD5Context, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s
    while it != nil:
      c &= it.name.s
      c &= "."
      it = it.owner

proc hashTypeSym(c: var MD5Context, s: PSym) =
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

proc hashTree(c: var MD5Context, n: PNode) =
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
    lowlevel v
  of nkFloatLit..nkFloat64Lit:
    let v = n.floatVal
    lowlevel v
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0..<n.len: hashTree(c, n.sons[i])

proc hashType(c: var MD5Context, t: PType; flags: set[ConsiderFlag]) =
  if t == nil:
    c &= "\254"
    return

  case t.kind
  of tyGenericInvocation:
    for i in countup(0, sonsLen(t) - 1):
      c.hashType t.sons[i], flags
  of tyDistinct:
    if CoType in flags:
      c.hashType t.lastSon, flags
    else:
      c.hashSym(t.sym)
  of tyGenericInst:
    if sfInfixCall in t.base.sym.flags:
      # This is an imported C++ generic type.
      # We cannot trust the `lastSon` to hold a properly populated and unique
      # value for each instantiation, so we hash the generic parameters here:
      let normalizedType = t.skipGenericAlias
      for i in 0 .. normalizedType.len - 2:
        c.hashType t.sons[i], flags
    else:
      c.hashType t.lastSon, flags
  of tyAlias, tySink, tyUserTypeClasses, tyInferred, tyOwned:
    c.hashType t.lastSon, flags
  of tyBool, tyChar, tyInt..tyUInt64:
    # no canonicalization for integral types, so that e.g. ``pid_t`` is
    # produced instead of ``NI``:
    c &= char(t.kind)
    if t.sym != nil and {sfImportc, sfExportc} * t.sym.flags != {}:
      c.hashSym(t.sym)
  of tyObject, tyEnum:
    if t.typeInst != nil:
      # prevent against infinite recursions here, see bug #8883:
      let inst = t.typeInst
      t.typeInst = nil
      assert inst.kind == tyGenericInst
      for i in countup(0, inst.len - 2):
        c.hashType inst.sons[i], flags
      t.typeInst = inst
      return
    c &= char(t.kind)
    # Every cyclic type in Nim need to be constructed via some 't.sym', so this
    # is actually safe without an infinite recursion check:
    if t.sym != nil:
      if {sfCompilerProc} * t.sym.flags != {}:
        doAssert t.sym.loc.r != nil
        # The user has set a specific name for this type
        c &= t.sym.loc.r
      elif CoOwnerSig in flags:
        c.hashTypeSym(t.sym)
      else:
        c.hashSym(t.sym)
      if {sfAnon, sfGenSym} * t.sym.flags != {}:
        # Generated object names can be identical, so we need to
        # disambiguate furthermore by hashing the field types and names.
        if t.n.len > 0:
          let oldFlags = t.sym.flags
          # Mild hack to prevent endless recursion.
          t.sym.flags = t.sym.flags - {sfAnon, sfGenSym}
          for n in t.n:
            assert(n.kind == nkSym)
            let s = n.sym
            c.hashSym s
            c.hashType s.typ, flags
          t.sym.flags = oldFlags
        else:
          # The object has no fields: we _must_ add something here in order to
          # make the hash different from the one we produce by hashing only the
          # type name.
          c &= ".empty"
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
    # purity of functions doesn't have to affect the mangling (which is in fact
    # problematic for HCR - someone could have cached a pointer to another
    # function which changes its purity and suddenly the cached pointer is danglign)
    # IMHO anything that doesn't affect the overload resolution shouldn't be part of the mangling...
    # if CoType notin flags:
    #   if tfNoSideEffect in t.flags: c &= ".noSideEffect"
    #   if tfThread in t.flags: c &= ".thread"
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
  var c: MD5Context
  md5Init c
  hashType c, t, flags+{CoOwnerSig}
  md5Final c, result.Md5Digest
  when defined(debugSigHashes):
    db.exec(sql"INSERT OR IGNORE INTO sighashes(type, hash) VALUES (?, ?)",
            typeToString(t), $result)

proc hashProc*(s: PSym): SigHash =
  var c: MD5Context
  md5Init c
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
  md5Final c, result.Md5Digest

proc hashNonProc*(s: PSym): SigHash =
  var c: MD5Context
  md5Init c
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
  md5Final c, result.Md5Digest

proc hashOwner*(s: PSym): SigHash =
  var c: MD5Context
  md5Init c
  var m = s
  while m.kind != skModule: m = m.owner
  let p = m.owner
  assert p.kind == skPackage
  c &= p.name.s
  c &= "."
  c &= m.name.s

  md5Final c, result.Md5Digest

proc sigHash*(s: PSym): SigHash =
  if s.kind in routineKinds and s.typ != nil:
    result = hashProc(s)
  else:
    result = hashNonProc(s)

proc idOrSig*(s: PSym, currentModule: string,
              sigCollisions: var CountTable[SigHash]): Rope =
  if s.kind in routineKinds and s.typ != nil:
    # signatures for exported routines are reliable enough to
    # produce a unique name and this means produced C++ is more stable wrt
    # Nim changes:
    let sig = hashProc(s)
    result = rope($sig)
    #let m = if s.typ.callConv != ccInline: findPendingModule(m, s) else: m
    let counter = sigCollisions.getOrDefault(sig)
    #if sigs == "_jckmNePK3i2MFnWwZlp6Lg" and s.name.s == "contains":
    #  echo "counter ", counter, " ", s.id
    if counter != 0:
      result.add "_" & rope(counter+1)
    # this minor hack is necessary to make tests/collections/thashes compile.
    # The inlined hash function's original module is ambiguous so we end up
    # generating duplicate names otherwise:
    if s.typ.callConv == ccInline:
      result.add rope(currentModule)
    sigCollisions.inc(sig)
  else:
    let sig = hashNonProc(s)
    result = rope($sig)
    let counter = sigCollisions.getOrDefault(sig)
    if counter != 0:
      result.add "_" & rope(counter+1)
    sigCollisions.inc(sig)

