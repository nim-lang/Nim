#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Computes hash values for routine (proc, method etc) signatures.

import ast, tables, ropes, md5, modulegraphs
from hashes import Hash
from astalgo import debug
import types
from strutils import startsWith, contains

proc `&=`(c: var MD5Context, s: string) = md5Update(c, s, s.len)
proc `&=`(c: var MD5Context, ch: char) = md5Update(c, unsafeAddr ch, 1)
proc `&=`(c: var MD5Context, r: Rope) =
  for l in leaves(r): md5Update(c, l, l.len)
proc `&=`(c: var MD5Context, i: BiggestInt) =
  md5Update(c, cast[cstring](unsafeAddr i), sizeof(i))
proc `&=`(c: var MD5Context, f: BiggestFloat) =
  md5Update(c, cast[cstring](unsafeAddr f), sizeof(f))
proc `&=`(c: var MD5Context, s: SigHash) =
  md5Update(c, cast[cstring](unsafeAddr s), sizeof(s))
template lowlevel(v) =
  md5Update(c, cast[cstring](unsafeAddr(v)), sizeof(v))


type
  ConsiderFlag* = enum
    CoProc
    CoType
    CoOwnerSig
    CoIgnoreRange
    CoConsiderOwned
    CoDistinct

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
    for i in 0 ..< sonsLen(t):
      c.hashType t.sons[i], flags
  of tyDistinct:
    if CoDistinct in flags:
      if t.sym != nil: c.hashSym(t.sym)
      if t.sym == nil or tfFromGeneric in t.flags:
        c.hashType t.lastSon, flags
    elif CoType in flags or t.sym == nil:
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
  of tyAlias, tySink, tyUserTypeClasses, tyInferred:
    c.hashType t.lastSon, flags
  of tyOwned:
    if CoConsiderOwned in flags:
      c &= char(t.kind)
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
      for i in 0 .. inst.len - 2:
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
      for i in 0 ..< sonsLen(t.n):
        assert(t.n.sons[i].kind == nkSym)
        c &= t.n.sons[i].sym.name.s
        c &= ':'
        c.hashType(t.sons[i], flags+{CoIgnoreRange})
        c &= ','
    else:
      for i in 0 ..< sonsLen(t): c.hashType t.sons[i], flags+{CoIgnoreRange}
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

proc symBodyDigest*(graph: ModuleGraph, sym: PSym): SigHash

proc hashBodyTree(graph: ModuleGraph, c: var MD5Context, n: PNode)

proc hashVarSymBody(graph: ModuleGraph, c: var MD5Context, s: PSym) =
  assert: s.kind in {skParam, skResult, skVar, skLet, skConst, skForVar}
  if sfGlobal notin s.flags:
    c &= char(s.kind)
    c &= s.name.s
  else:
    c &= hashNonProc(s)
    # this one works for let and const but not for var. True variables can change value
    # later on. it is user resposibility to hash his global state if required
    if s.ast != nil and s.ast.kind == nkIdentDefs:
      hashBodyTree(graph, c, s.ast[^1])
    else:
      hashBodyTree(graph, c, s.ast)

proc hashBodyTree(graph: ModuleGraph, c: var MD5Context, n: PNode) =
  # hash Nim tree recursing into simply
  if n == nil:
    c &= "nil"
    return
  c &= char(n.kind)
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    c &= n.ident.s
  of nkSym:
    if n.sym.kind in skProcKinds:
      c &= symBodyDigest(graph, n.sym)
    elif n.sym.kind in {skParam, skResult, skVar, skLet, skConst, skForVar}:
      hashVarSymBody(graph, c, n.sym)
    else:
      c &= hashNonProc(n.sym)
  of nkProcDef, nkFuncDef, nkTemplateDef, nkMacroDef:
    discard # we track usage of proc symbols not their definition
  of nkCharLit..nkUInt64Lit:
    c &= n.intVal
  of nkFloatLit..nkFloat64Lit:
    c &= n.floatVal
  of nkStrLit..nkTripleStrLit:
    c &= n.strVal
  else:
    for i in 0..<n.len:
      hashBodyTree(graph, c, n.sons[i])

proc symBodyDigest*(graph: ModuleGraph, sym: PSym): SigHash =
  ## compute unique digest of the proc/func/method symbols
  ## recursing into invoked symbols as well
  assert(sym.kind in skProcKinds, $sym.kind)

  graph.symBodyHashes.withValue(sym.id, value):
    return value[]

  var c: MD5Context
  md5Init(c)
  c.hashType(sym.typ, {CoProc})
  c &= char(sym.kind)
  c.md5Final(result.Md5Digest)
  graph.symBodyHashes[sym.id] = result # protect from recursion in the body

  if sym.ast != nil:
    md5Init(c)
    c.md5Update(cast[cstring](result.addr), sizeof(result))
    hashBodyTree(graph, c, sym.ast[bodyPos])
    c.md5Final(result.Md5Digest)
    graph.symBodyHashes[sym.id] = result

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

