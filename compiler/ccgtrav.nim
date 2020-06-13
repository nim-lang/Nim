#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Generates traversal procs for the C backend.

# included from cgen.nim

type
  TTraversalClosure = object
    p: BProc
    visitorFrmt: string

const
  visitorFrmt = "#nimGCvisit((void*)$1, $2);$n"

proc genTraverseProc(c: TTraversalClosure, accessor: Rope, typ: PType)
proc genCaseRange(p: BProc, branch: PNode)
proc getTemp(p: BProc, t: PType, result: var TLoc; needsInit=false)

proc genTraverseProc(c: TTraversalClosure, accessor: Rope, n: PNode;
                     typ: PType) =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      genTraverseProc(c, accessor, n[i], typ)
  of nkRecCase:
    if (n[0].kind != nkSym): internalError(c.p.config, n.info, "genTraverseProc")
    var p = c.p
    let disc = n[0].sym
    if disc.loc.r == nil: fillObjectFields(c.p.module, typ)
    if disc.loc.t == nil:
      internalError(c.p.config, n.info, "genTraverseProc()")
    lineF(p, cpsStmts, "switch ($1.$2) {$n", [accessor, disc.loc.r])
    for i in 1..<n.len:
      let branch = n[i]
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
      internalError(c.p.config, n.info, "genTraverseProc()")
    genTraverseProc(c, "$1.$2" % [accessor, field.loc.r], field.loc.t)
  else: internalError(c.p.config, n.info, "genTraverseProc()")

proc parentObj(accessor: Rope; m: BModule): Rope {.inline.} =
  if not m.compileToCpp:
    result = "$1.Sup" % [accessor]
  else:
    result = accessor

proc genTraverseProcSeq(c: TTraversalClosure, accessor: Rope, typ: PType)
proc genTraverseProc(c: TTraversalClosure, accessor: Rope, typ: PType) =
  if typ == nil: return

  var p = c.p
  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc, tyAlias, tyDistinct, tyInferred,
     tySink, tyOwned:
    genTraverseProc(c, accessor, lastSon(typ))
  of tyArray:
    let arraySize = lengthOrd(c.p.config, typ[0])
    var i: TLoc
    getTemp(p, getSysType(c.p.module.g.graph, unknownLineInfo, tyInt), i)
    let oldCode = p.s(cpsStmts)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",
            [i.r, arraySize])
    let oldLen = p.s(cpsStmts).len
    genTraverseProc(c, ropecg(c.p.module, "$1[$2]", [accessor, i.r]), typ[1])
    if p.s(cpsStmts).len == oldLen:
      # do not emit dummy long loops for faster debug builds:
      p.s(cpsStmts) = oldCode
    else:
      lineF(p, cpsStmts, "}$n", [])
  of tyObject:
    for i in 0..<typ.len:
      var x = typ[i]
      if x != nil: x = x.skipTypes(skipPtrs)
      genTraverseProc(c, accessor.parentObj(c.p.module), x)
    if typ.n != nil: genTraverseProc(c, accessor, typ.n, typ)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i in 0..<typ.len:
      genTraverseProc(c, ropecg(c.p.module, "$1.Field$2", [accessor, i]), typ[i])
  of tyRef:
    lineCg(p, cpsStmts, visitorFrmt, [accessor, c.visitorFrmt])
  of tySequence:
    if optSeqDestructors notin c.p.module.config.globalOptions:
      lineCg(p, cpsStmts, visitorFrmt, [accessor, c.visitorFrmt])
    elif containsGarbageCollectedRef(typ.lastSon):
      # destructor based seqs are themselves not traced but their data is, if
      # they contain a GC'ed type:
      lineCg(p, cpsStmts, "#nimGCvisitSeq((void*)$1, $2);$n", [accessor, c.visitorFrmt])
      #genTraverseProcSeq(c, accessor, typ)
  of tyString:
    if tfHasAsgn notin typ.flags:
      lineCg(p, cpsStmts, visitorFrmt, [accessor, c.visitorFrmt])
  of tyProc:
    if typ.callConv == ccClosure:
      lineCg(p, cpsStmts, visitorFrmt, [ropecg(c.p.module, "$1.ClE_0", [accessor]), c.visitorFrmt])
  else:
    discard

proc genTraverseProcSeq(c: TTraversalClosure, accessor: Rope, typ: PType) =
  var p = c.p
  assert typ.kind == tySequence
  var i: TLoc
  getTemp(p, getSysType(c.p.module.g.graph, unknownLineInfo, tyInt), i)
  let oldCode = p.s(cpsStmts)
  var a: TLoc
  a.r = accessor

  lineF(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",
      [i.r, lenExpr(c.p, a)])
  let oldLen = p.s(cpsStmts).len
  genTraverseProc(c, "$1$3[$2]" % [accessor, i.r, dataField(c.p)], typ[0])
  if p.s(cpsStmts).len == oldLen:
    # do not emit dummy long loops for faster debug builds:
    p.s(cpsStmts) = oldCode
  else:
    lineF(p, cpsStmts, "}$n", [])

proc genTraverseProc(m: BModule, origTyp: PType; sig: SigHash): Rope =
  var c: TTraversalClosure
  var p = newProc(nil, m)
  result = "Marker_" & getTypeName(m, origTyp, sig)
  let
    hcrOn = m.hcrOn
    typ = origTyp.skipTypes(abstractInstOwned)
    markerName = if hcrOn: result & "_actual" else: result
    header = "static N_NIMCALL(void, $1)(void* p, NI op)" % [markerName]
    t = getTypeDesc(m, typ)

  lineF(p, cpsLocals, "$1 a;$n", [t])
  lineF(p, cpsInit, "a = ($1)p;$n", [t])

  c.p = p
  c.visitorFrmt = "op" # "#nimGCvisit((void*)$1, op);$n"

  assert typ.kind != tyTypeDesc
  if typ.kind == tySequence:
    genTraverseProcSeq(c, "a".rope, typ)
  else:
    if skipTypes(typ[0], typedescInst+{tyOwned}).kind == tyArray:
      # C's arrays are broken beyond repair:
      genTraverseProc(c, "a".rope, typ[0])
    else:
      genTraverseProc(c, "(*a)".rope, typ[0])

  let generatedProc = "$1 {$n$2$3$4}\n" %
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)]

  m.s[cfsProcHeaders].addf("$1;\n", [header])
  m.s[cfsProcs].add(generatedProc)

  if hcrOn:
    m.s[cfsProcHeaders].addf("N_NIMCALL_PTR(void, $1)(void*, NI);\n", [result])
    m.s[cfsDynLibInit].addf("\t$1 = (N_NIMCALL_PTR(void, )(void*, NI)) hcrRegisterProc($3, \"$1\", (void*)$2);\n",
         [result, markerName, getModuleDllPath(m)])

proc genTraverseProcForGlobal(m: BModule, s: PSym; info: TLineInfo): Rope =
  discard genTypeInfoV1(m, s.loc.t, info)

  var c: TTraversalClosure
  var p = newProc(nil, m)
  var sLoc = rdLoc(s.loc)
  result = getTempName(m)

  if sfThread in s.flags and emulatedThreadVars(m.config):
    accessThreadLocalVar(p, s)
    sLoc = "NimTV_->" & sLoc

  c.visitorFrmt = "0" # "#nimGCvisit((void*)$1, 0);$n"
  c.p = p
  let header = "static N_NIMCALL(void, $1)(void)" % [result]
  genTraverseProc(c, sLoc, s.loc.t)

  let generatedProc = "$1 {$n$2$3$4}$n" %
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)]

  m.s[cfsProcHeaders].addf("$1;$n", [header])
  m.s[cfsProcs].add(generatedProc)
