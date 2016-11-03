#
#
#           The Nim Compiler
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Computes hash values for routine (proc, method etc) signatures.

import ast

type
  SigHash* = uint32  ## a hash good enough for a filename or a proc signature

proc sdbmHash(hash: SigHash, c: char): SigHash {.inline.} =
  return SigHash(c) + (hash shl 6) + (hash shl 16) - hash

template `&=`*(x: var SigHash, c: char) = x = sdbmHash(x, c)
template `&=`*(x: var SigHash, s: string) =
  for c in s: x = sdbmHash(x, c)

proc hashSym(c: var SigHash, s: PSym) =
  if sfAnon in s.flags or s.kind == skGenericParam:
    c &= ":anon"
  else:
    var it = s
    while it != nil:
      c &= it.name.s
      c &= "."
      it = it.owner

proc hashTree(c: var SigHash, n: PNode) =
  template lowlevel(v) =
    for i in 0..<sizeof(v): c = sdbmHash(c, cast[cstring](unsafeAddr(v))[i])

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
    for i in 0.. <n.len: hashTree(c, n.sons[i])

type
  ConsiderFlag* = enum
    considerParamNames

proc hashType(c: var SigHash, t: PType; flags: set[ConsiderFlag]) =
  # modelled after 'typeToString'
  if t == nil:
    c &= "\254"
    return

  c &= char(t.kind)

  # Every cyclic type in Nim need to be constructed via some 't.sym', so this
  # is actually safe without an infinite recursion check:
  if t.sym != nil and sfAnon notin t.sym.flags:
    # t.n for literals, but not for e.g. objects!
    if t.kind in {tyFloat, tyInt}: c.hashTree(t.n)
    c.hashSym(t.sym)
    return

  case t.kind
  of tyGenericBody, tyGenericInst, tyGenericInvocation:
    for i in countup(0, sonsLen(t) - 1 - ord(t.kind != tyGenericInvocation)):
      c.hashType t.sons[i], flags
  of tyUserTypeClass:
    if t.sym != nil and t.sym.owner != nil:
      c &= t.sym.owner.name.s
    else:
      c &= "unknown typeclass"
  of tyUserTypeClassInst:
    let body = t.sons[0]
    c.hashSym body.sym
    for i in countup(1, sonsLen(t) - 2):
      c.hashType t.sons[i], flags
  of tyFromExpr, tyFieldAccessor:
    c.hashTree(t.n)
  of tyArrayConstr:
    c.hashTree(t.sons[0].n)
    c.hashType(t.sons[1], flags)
  of tyTuple:
    if t.n != nil:
      assert(sonsLen(t.n) == sonsLen(t))
      for i in countup(0, sonsLen(t.n) - 1):
        assert(t.n.sons[i].kind == nkSym)
        c &= t.n.sons[i].sym.name.s
        c &= ':'
        c.hashType(t.sons[i], flags)
        c &= ','
    else:
      for i in countup(0, sonsLen(t) - 1): c.hashType t.sons[i], flags
  of tyRange:
    c.hashTree(t.n)
    c.hashType(t.sons[0], flags)
  of tyProc:
    c &= (if tfIterator in t.flags: "iterator " else: "proc ")
    if considerParamNames in flags and t.n != nil:
      let params = t.n
      for i in 1..<params.len:
        let param = params[i].sym
        c &= param.name.s
        c &= ':'
        c.hashType(param.typ, flags)
        c &= ','
      c.hashType(t.sons[0], flags)
    else:
      for i in 0.. <t.len: c.hashType(t.sons[i], flags)
    c &= char(t.callConv)
    if tfNoSideEffect in t.flags: c &= ".noSideEffect"
    if tfThread in t.flags: c &= ".thread"
  else:
    for i in 0.. <t.len: c.hashType(t.sons[i], flags)
  if tfNotNil in t.flags: c &= "not nil"

proc hashType*(t: PType; flags: set[ConsiderFlag]): SigHash =
  result = 0
  hashType result, t, flags
