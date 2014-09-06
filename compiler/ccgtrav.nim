#
#
#           The Nimrod Compiler
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

proc genTraverseProc(c: var TTraversalClosure, accessor: PRope, typ: PType)
proc genCaseRange(p: BProc, branch: PNode)
proc getTemp(p: BProc, t: PType, result: var TLoc; needsInit=false)

proc genTraverseProc(c: var TTraversalClosure, accessor: PRope, n: PNode) =
  if n == nil: return
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      genTraverseProc(c, accessor, n.sons[i])
  of nkRecCase:
    if (n.sons[0].kind != nkSym): internalError(n.info, "genTraverseProc")
    var p = c.p
    let disc = n.sons[0].sym
    lineF(p, cpsStmts, "switch ($1.$2) {$n", accessor, disc.loc.r)
    for i in countup(1, sonsLen(n) - 1):
      let branch = n.sons[i]
      assert branch.kind in {nkOfBranch, nkElse}
      if branch.kind == nkOfBranch:
        genCaseRange(c.p, branch)
      else:
        lineF(p, cpsStmts, "default:$n")
      genTraverseProc(c, accessor, lastSon(branch))
      lineF(p, cpsStmts, "break;$n")
    lineF(p, cpsStmts, "} $n")
  of nkSym:
    let field = n.sym
    if field.loc.t == nil:
      internalError(n.info, "genTraverseProc()")
    genTraverseProc(c, ropef("$1.$2", accessor, field.loc.r), field.loc.t)
  else: internalError(n.info, "genTraverseProc()")

proc parentObj(accessor: PRope): PRope {.inline.} =
  if gCmd != cmdCompileToCpp:
    result = ropef("$1.Sup", accessor)
  else:
    result = accessor

proc genTraverseProc(c: var TTraversalClosure, accessor: PRope, typ: PType) =
  if typ == nil: return
  var p = c.p
  case typ.kind
  of tyGenericInst, tyGenericBody, tyTypeDesc:
    genTraverseProc(c, accessor, lastSon(typ))
  of tyArrayConstr, tyArray:
    let arraySize = lengthOrd(typ.sons[0])
    var i: TLoc
    getTemp(p, getSysType(tyInt), i)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",
            i.r, arraySize.toRope)
    genTraverseProc(c, rfmt(nil, "$1[$2]", accessor, i.r), typ.sons[1])
    lineF(p, cpsStmts, "}$n")
  of tyObject:
    for i in countup(0, sonsLen(typ) - 1):
      genTraverseProc(c, accessor.parentObj, typ.sons[i])
    if typ.n != nil: genTraverseProc(c, accessor, typ.n)
  of tyTuple:
    let typ = getUniqueType(typ)
    for i in countup(0, sonsLen(typ) - 1):
      genTraverseProc(c, rfmt(nil, "$1.Field$2", accessor, i.toRope), typ.sons[i])
  of tyRef, tyString, tySequence:
    lineCg(p, cpsStmts, c.visitorFrmt, accessor)
  of tyProc:
    if typ.callConv == ccClosure:
      lineCg(p, cpsStmts, c.visitorFrmt, rfmt(nil, "$1.ClEnv", accessor))
  else:
    discard

proc genTraverseProcSeq(c: var TTraversalClosure, accessor: PRope, typ: PType) =
  var p = c.p
  assert typ.kind == tySequence  
  var i: TLoc
  getTemp(p, getSysType(tyInt), i)
  lineF(p, cpsStmts, "for ($1 = 0; $1 < $2->$3; $1++) {$n",
      i.r, accessor, toRope(if gCmd != cmdCompileToCpp: "Sup.len" else: "len"))
  genTraverseProc(c, ropef("$1->data[$2]", accessor, i.r), typ.sons[0])
  lineF(p, cpsStmts, "}$n")
  
proc genTraverseProc(m: BModule, typ: PType, reason: TTypeInfoReason): PRope =
  var c: TTraversalClosure
  var p = newProc(nil, m)
  result = getGlobalTempName()
  
  case reason
  of tiNew: c.visitorFrmt = "#nimGCvisit((void*)$1, op);$n"
  else: assert false
  
  let header = ropef("N_NIMCALL(void, $1)(void* p, NI op)", result)
  
  let t = getTypeDesc(m, typ)
  lineF(p, cpsLocals, "$1 a;$n", t)
  lineF(p, cpsInit, "a = ($1)p;$n", t)
  
  c.p = p
  assert typ.kind != tyTypeDesc
  if typ.kind == tySequence:
    genTraverseProcSeq(c, "a".toRope, typ)
  else:
    if skipTypes(typ.sons[0], typedescInst).kind in {tyArrayConstr, tyArray}:
      # C's arrays are broken beyond repair:
      genTraverseProc(c, "a".toRope, typ.sons[0])
    else:
      genTraverseProc(c, "(*a)".toRope, typ.sons[0])
  
  let generatedProc = ropef("$1 {$n$2$3$4}$n",
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)])
  
  m.s[cfsProcHeaders].appf("$1;$n", header)
  m.s[cfsProcs].app(generatedProc)

proc genTraverseProcForGlobal(m: BModule, s: PSym): PRope =
  discard genTypeInfo(m, s.loc.t)
  
  var c: TTraversalClosure
  var p = newProc(nil, m)
  var sLoc = s.loc.r
  result = getGlobalTempName()
  
  if sfThread in s.flags and emulatedThreadVars():
    accessThreadLocalVar(p, s)
    sLoc = con("NimTV->", sLoc)
    
  c.visitorFrmt = "#nimGCvisit((void*)$1, 0);$n"
  c.p = p
  let header = ropef("N_NIMCALL(void, $1)()", result)
  genTraverseProc(c, sLoc, s.loc.t)
  
  let generatedProc = ropef("$1 {$n$2$3$4}$n",
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)])
  
  m.s[cfsProcHeaders].appf("$1;$n", header)
  m.s[cfsProcs].app(generatedProc)
