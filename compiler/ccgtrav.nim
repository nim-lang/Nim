#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Generates traversal procs for the C backend. Traversal procs are only an
## optimization; the GC works without them too.

# included from cgen.nim

type
  TTraversalClosure = object
    p: BProc
    visitorFrmt: string

proc genTraverseProc(c: var TTraversalClosure, accessor: Rope, typ: PType)
proc genCaseRange(p: BProc, branch: PNode)
proc getTemp(p: BProc, t: PType, result: var TLoc; needsInit=false)

proc genTraverseProc(c: var TTraversalClosure, accessor: Rope, n: PNode;
                     typ: PType) =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      genTraverseProc(c, accessor, n.sons[i], typ)
  of nkRecCase:
    if (n.sons[0].kind != nkSym): internalError(n.info, "genTraverseProc")
    var p = c.p
    let disc = n.sons[0].sym
    lineF(p, cpsStmts, "switch ($1.$2) {$n", [accessor, disc.loc.r])
    for i in countup(1, sonsLen(n) - 1):
      let branch = n.sons[i]
      assert branch.kind in {nkOfBranch, nkElse}
      if branch.kind == nkOfBranch:
        genCaseRange(c.p, branch)
      else:
        lineF(p, cpsStmts, "default:$n", [])
      genTraverseProc(c, accessor, lastSon(branch), typ)
      lineF(p, cpsStmts, "break;$n", [])
    lineF(p, cpsStmts, "} $n", [])
  of nkSym:
    let field = n.sym
    if field.typ.kind == tyVoid: return
    if field.loc.r == nil: fillObjectFields(c.p.module, typ)
    if field.loc.t == nil:
      internalError(n.info, "genTraverseProc()")
    genTraverseProc(c, "$1.$2" % [accessor, field.loc.r], field.loc.t)
  else: internalError(n.info, "genTraverseProc()")

proc parentObj(accessor: Rope; m: BModule): Rope {.inline.} =
  if not m.compileToCpp:
    result = "$1.Sup" % [accessor]
  else:
    result = accessor

proc genTraverseProc(c: var TTraversalClosure, accessor: Rope, typ: PType) =
  if typ == nil: return

  var p = c.p
  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc, tyAlias, tyDistinct:
    genTraverseProc(c, accessor, lastSon(typ))
  of tyArray:
    let arraySize = lengthOrd(typ.sons[0])
    var i: TLoc
    getTemp(p, getSysType(tyInt), i)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",
            i.r, arraySize.rope)
    genTraverseProc(c, rfmt(nil, "$1[$2]", accessor, i.r), typ.sons[1])
    lineF(p, cpsStmts, "}$n", [])
  of tyObject:
    for i in countup(0, sonsLen(typ) - 1):
      var x = typ.sons[i]
      if x != nil: x = x.skipTypes(skipPtrs)
      genTraverseProc(c, accessor.parentObj(c.p.module), x)
    if typ.n != nil: genTraverseProc(c, accessor, typ.n, typ)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i in countup(0, sonsLen(typ) - 1):
      genTraverseProc(c, rfmt(nil, "$1.Field$2", accessor, i.rope), typ.sons[i])
  of tyRef, tyString, tySequence:
    lineCg(p, cpsStmts, c.visitorFrmt, accessor)
  of tyProc:
    if typ.callConv == ccClosure:
      lineCg(p, cpsStmts, c.visitorFrmt, rfmt(nil, "$1.ClEnv", accessor))
  else:
    discard

proc genTraverseProcSeq(c: var TTraversalClosure, accessor: Rope, typ: PType) =
  var p = c.p
  assert typ.kind == tySequence
  var i: TLoc
  getTemp(p, getSysType(tyInt), i)
  lineF(p, cpsStmts, "for ($1 = 0; $1 < $2->$3; $1++) {$n",
      [i.r, accessor, rope(if c.p.module.compileToCpp: "len" else: "Sup.len")])
  genTraverseProc(c, "$1->data[$2]" % [accessor, i.r], typ.sons[0])
  lineF(p, cpsStmts, "}$n", [])

proc genTraverseProc(m: BModule, origTyp: PType; sig: SigHash;
                     reason: TTypeInfoReason): Rope =
  var c: TTraversalClosure
  var p = newProc(nil, m)
  result = "Marker_" & getTypeName(m, origTyp, sig)
  let typ = origTyp.skipTypes(abstractInst)

  case reason
  of tiNew: c.visitorFrmt = "#nimGCvisit((void*)$1, op);$n"
  else: assert false

  let header = "static N_NIMCALL(void, $1)(void* p, NI op)" % [result]

  let t = getTypeDesc(m, typ)
  lineF(p, cpsLocals, "$1 a;$n", [t])
  lineF(p, cpsInit, "a = ($1)p;$n", [t])

  c.p = p
  assert typ.kind != tyTypeDesc
  if typ.kind == tySequence:
    genTraverseProcSeq(c, "a".rope, typ)
  else:
    if skipTypes(typ.sons[0], typedescInst).kind == tyArray:
      # C's arrays are broken beyond repair:
      genTraverseProc(c, "a".rope, typ.sons[0])
    else:
      genTraverseProc(c, "(*a)".rope, typ.sons[0])

  let generatedProc = "$1 {$n$2$3$4}$n" %
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)]

  m.s[cfsProcHeaders].addf("$1;$n", [header])
  m.s[cfsProcs].add(generatedProc)

proc genTraverseProcForGlobal(m: BModule, s: PSym): Rope =
  discard genTypeInfo(m, s.loc.t)

  var c: TTraversalClosure
  var p = newProc(nil, m)
  var sLoc = s.loc.r
  result = getTempName(m)

  if sfThread in s.flags and emulatedThreadVars():
    accessThreadLocalVar(p, s)
    sLoc = "NimTV->" & sLoc

  c.visitorFrmt = "#nimGCvisit((void*)$1, 0);$n"
  c.p = p
  let header = "static N_NIMCALL(void, $1)(void)" % [result]
  genTraverseProc(c, sLoc, s.loc.t)

  let generatedProc = "$1 {$n$2$3$4}$n" %
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)]

  m.s[cfsProcHeaders].addf("$1;$n", [header])
  m.s[cfsProcs].add(generatedProc)
