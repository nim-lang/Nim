#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Injects destructor calls into Nim code as well as
## an optimizer that optimizes copies to moves. This is implemented as an
## AST to AST transformation so that every backend benefits from it.

## See doc/destructors.rst for a spec of the implemented rewrite rules

## XXX Optimization to implement: if a local variable is only assigned
## string literals as in ``let x = conf: "foo" else: "bar"`` do not
## produce a destructor call for ``x``. The address of ``x`` must also
## not have been taken. ``x = "abc"; x.add(...)``

# Todo:
# - eliminate 'wasMoved(x); destroy(x)' pairs as a post processing step.

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents,
  strutils, options, dfa, lowerings, tables, modulegraphs, msgs,
  lineinfos, parampatterns, sighashes, liftdestructors

from trees import exprStructuralEquivalent, getRoot

type
  Scope = object  # well we do scope-based memory management. \
    # a scope is comparable to an nkStmtListExpr like
    # (try: statements; dest = y(); finally: destructors(); dest)
    vars: seq[PSym]
    wasMoved: seq[PNode]
    final: seq[PNode] # finally section
    needsTry: bool
    parent: ptr Scope
    escapingSyms: IntSet # a construct like (block: let x = f(); x)
                         # means that 'x' escapes. We then destroy it
                         # in the parent's scope (and also allocate it there).

type
  Con = object
    owner: PSym
    g: ControlFlowGraph
    jumpTargets: IntSet
    destroys, topLevelVars: PNode
    graph: ModuleGraph
    emptyNode: PNode
    otherRead: PNode
    inLoop, inSpawn: int
    uninit: IntSet # set of uninit'ed vars
    uninitComputed: bool

  ProcessMode = enum
    normal
    consumed
    sinkArg

proc getTemp(c: var Con; s: var Scope; typ: PType; info: TLineInfo): PNode =
  let sym = newSym(skTemp, getIdent(c.graph.cache, ":tmpD"), c.owner, info)
  sym.typ = typ
  s.vars.add(sym)
  result = newSymNode(sym)

proc nestedScope(parent: var Scope): Scope =
  Scope(vars: @[], wasMoved: @[], final: @[], needsTry: false, parent: addr(parent))

proc rememberParent(parent: var Scope; inner: Scope) {.inline.} =
  parent.needsTry = parent.needsTry or inner.needsTry

proc optimize(s: var Scope) =
  # optimize away simple 'wasMoved(x); destroy(x)' pairs.
  #[ Unfortunately this optimization is only really safe when no exceptions
     are possible, see for example:

  proc main(inp: string; cond: bool) =
    if cond:
      try:
        var s = ["hi", inp & "more"]
        for i in 0..4:
          echo s
        consume(s)
        wasMoved(s)
      finally:
        destroy(x)

    Now assume 'echo' raises, then we shouldn't do the 'wasMoved(s)'
  ]#
  # XXX: Investigate how to really insert 'wasMoved()' calls!
  proc findCorrespondingDestroy(final: seq[PNode]; moved: PNode): int =
    # remember that it's destroy(addr(x))
    for i in 0 ..< final.len:
      if final[i] != nil and exprStructuralEquivalent(final[i][1].skipAddr, moved, strictSymEquality = true):
        return i
    return -1

  var removed = 0
  for i in 0 ..< s.wasMoved.len:
    let j = findCorrespondingDestroy(s.final, s.wasMoved[i][1])
    if j >= 0:
      s.wasMoved[i] = nil
      s.final[j] = nil
      inc removed
  if removed > 0:
    template filterNil(field) =
      var m = newSeq[PNode](s.field.len - removed)
      var mi = 0
      for i in 0 ..< s.field.len:
        if s.field[i] != nil:
          m[mi] = s.field[i]
          inc mi
      assert mi == m.len
      s.field = m

    filterNil(wasMoved)
    filterNil(final)

type
  ToTreeFlag = enum
    onlyCareAboutVars,
    producesValue

proc toTree(c: var Con; s: var Scope; ret: PNode; flags: set[ToTreeFlag]): PNode =
  if not s.needsTry: optimize(s)
  assert ret != nil
  if s.vars.len == 0 and s.final.len == 0 and s.wasMoved.len == 0:
    # trivial, nothing was done:
    result = ret
  else:
    let isExpr = producesValue in flags and not isEmptyType(ret.typ)
    var r = PNode(nil)
    if isExpr:
      result = newNodeIT(nkStmtListExpr, ret.info, ret.typ)
      if ret.kind in nkCallKinds + {nkStmtListExpr}:
        r = getTemp(c, s, ret.typ, ret.info)
    else:
      result = newNodeI(nkStmtList, ret.info)

    if s.vars.len > 0:
      let varSection = newNodeI(nkVarSection, ret.info)
      for tmp in s.vars:
        varSection.add newTree(nkIdentDefs, newSymNode(tmp), newNodeI(nkEmpty, ret.info),
                                                             newNodeI(nkEmpty, ret.info))
      result.add varSection
    if onlyCareAboutVars in flags:
      result.add ret
      s.vars.setLen 0
    elif s.needsTry:
      var finSection = newNodeI(nkStmtList, ret.info)
      for m in s.wasMoved: finSection.add m
      for i in countdown(s.final.high, 0): finSection.add s.final[i]
      result.add newTryFinally(ret, finSection)
    else:
      if r != nil:
        if ret.kind == nkStmtListExpr:
          # simplify it a bit further by merging the nkStmtListExprs
          let last = ret.len - 1
          for i in 0 ..< last: result.add ret[i]
          result.add newTree(nkFastAsgn, r, ret[last])
        else:
          result.add newTree(nkFastAsgn, r, ret)
      else:
        result.add ret
      for m in s.wasMoved: result.add m
      for i in countdown(s.final.high, 0): result.add s.final[i]
      if r != nil:
        result.add r


const toDebug {.strdefine.} = ""

template dbg(body) =
  when toDebug.len > 0:
    if c.owner.name.s == toDebug or toDebug == "always":
      body

proc p(n: PNode; c: var Con; s: var Scope; mode: ProcessMode): PNode
proc moveOrCopy(dest, ri: PNode; c: var Con; s: var Scope; isDecl = false): PNode

proc isLastRead(location: PNode; cfg: ControlFlowGraph; otherRead: var PNode; pc, until: int): int =
  var pc = pc
  while pc < cfg.len and pc < until:
    case cfg[pc].kind
    of def:
      if instrTargets(cfg[pc].n, location) == Full:
        # the path leads to a redefinition of 's' --> abandon it.
        return high(int)
      elif instrTargets(cfg[pc].n, location) == Partial:
        # only partially writes to 's' --> can't sink 's', so this def reads 's'
        otherRead = cfg[pc].n
        return -1
      inc pc
    of use:
      if instrTargets(cfg[pc].n, location) != None:
        otherRead = cfg[pc].n
        return -1
      inc pc
    of goto:
      pc = pc + cfg[pc].dest
    of fork:
      # every branch must lead to the last read of the location:
      var variantA = pc + 1
      var variantB = pc + cfg[pc].dest
      while variantA != variantB:
        if min(variantA, variantB) < 0: return -1
        if max(variantA, variantB) >= cfg.len or min(variantA, variantB) >= until:
          break
        if variantA < variantB:
          variantA = isLastRead(location, cfg, otherRead, variantA, min(variantB, until))
        else:
          variantB = isLastRead(location, cfg, otherRead, variantB, min(variantA, until))
      pc = min(variantA, variantB)
  return pc

proc isLastRead(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  var instr = -1
  let m = dfa.skipConvDfa(n)

  for i in 0..<c.g.len:
    # This comparison is correct and MUST not be ``instrTargets``:
    if c.g[i].kind == use and c.g[i].n == m:
      if instr < 0:
        instr = i
        break

  dbg: echo "starting point for ", n, " is ", instr, " ", n.kind

  if instr < 0: return false
  # we go through all paths beginning from 'instr+1' and need to
  # ensure that we don't find another 'use X' instruction.
  if instr+1 >= c.g.len: return true

  c.otherRead = nil
  result = isLastRead(n, c.g, c.otherRead, instr+1, int.high) >= 0
  dbg: echo "ugh ", c.otherRead.isNil, " ", result

proc isFirstWrite(location: PNode; cfg: ControlFlowGraph; pc, until: int): int =
  var pc = pc
  while pc < until:
    case cfg[pc].kind
    of def:
      if instrTargets(cfg[pc].n, location) != None:
        # a definition of 's' before ours makes ours not the first write
        return -1
      inc pc
    of use:
      if instrTargets(cfg[pc].n, location) != None:
        return -1
      inc pc
    of goto:
      pc = pc + cfg[pc].dest
    of fork:
      # every branch must not contain a def/use of our location:
      var variantA = pc + 1
      var variantB = pc + cfg[pc].dest
      while variantA != variantB:
        if min(variantA, variantB) < 0: return -1
        if max(variantA, variantB) > until:
          break
        if variantA < variantB:
          variantA = isFirstWrite(location, cfg, variantA, min(variantB, until))
        else:
          variantB = isFirstWrite(location, cfg, variantB, min(variantA, until))
      pc = min(variantA, variantB)
  return pc

proc isFirstWrite(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  var instr = -1
  let m = dfa.skipConvDfa(n)

  for i in countdown(c.g.len-1, 0): # We search backwards here to treat loops correctly
    if c.g[i].kind == def and c.g[i].n == m:
      if instr < 0:
        instr = i
        break

  if instr < 0: return false
  # we go through all paths going to 'instr' and need to
  # ensure that we don't find another 'def/use X' instruction.
  if instr == 0: return true

  result = isFirstWrite(n, c.g, 0, instr) >= 0

proc initialized(code: ControlFlowGraph; pc: int,
                 init, uninit: var IntSet; until: int): int =
  ## Computes the set of definitely initialized variables across all code paths
  ## as an IntSet of IDs.
  var pc = pc
  while pc < code.len:
    case code[pc].kind
    of goto:
      pc = pc + code[pc].dest
    of fork:
      var initA = initIntSet()
      var initB = initIntSet()
      var variantA = pc + 1
      var variantB = pc + code[pc].dest
      while variantA != variantB:
        if max(variantA, variantB) > until:
          break
        if variantA < variantB:
          variantA = initialized(code, variantA, initA, uninit, min(variantB, until))
        else:
          variantB = initialized(code, variantB, initB, uninit, min(variantA, until))
      pc = min(variantA, variantB)
      # we add vars if they are in both branches:
      for v in initA:
        if v in initB:
          init.incl v
    of use:
      let v = code[pc].n.sym
      if v.kind != skParam and v.id notin init:
        # attempt to read an uninit'ed variable
        uninit.incl v.id
      inc pc
    of def:
      let v = code[pc].n.sym
      init.incl v.id
      inc pc
  return pc

template isUnpackedTuple(n: PNode): bool =
  ## we move out all elements of unpacked tuples,
  ## hence unpacked tuples themselves don't need to be destroyed
  (n.kind == nkSym and n.sym.kind == skTemp and n.sym.typ.kind == tyTuple)

proc checkForErrorPragma(c: Con; t: PType; ri: PNode; opname: string) =
  var m = "'" & opname & "' is not available for type <" & typeToString(t) & ">"
  if opname == "=" and ri != nil:
    m.add "; requires a copy because it's not the last read of '"
    m.add renderTree(ri)
    m.add '\''
    if c.otherRead != nil:
      m.add "; another read is done here: "
      m.add c.graph.config $ c.otherRead.info
    elif ri.kind == nkSym and ri.sym.kind == skParam and not isSinkType(ri.sym.typ):
      m.add "; try to make "
      m.add renderTree(ri)
      m.add " a 'sink' parameter"
  m.add "; routine: "
  m.add c.owner.name.s
  localError(c.graph.config, ri.info, errGenerated, m)

proc makePtrType(c: Con, baseType: PType): PType =
  result = newType(tyPtr, c.owner)
  addSonSkipIntLit(result, baseType)

proc genOp(c: Con; op: PSym; dest: PNode): PNode =
  let addrExp = newNodeIT(nkHiddenAddr, dest.info, makePtrType(c, dest.typ))
  addrExp.add(dest)
  result = newTree(nkCall, newSymNode(op), addrExp)

proc genOp(c: Con; t: PType; kind: TTypeAttachedOp; dest, ri: PNode): PNode =
  var op = t.attachedOps[kind]
  if op == nil or op.ast[genericParamsPos].kind != nkEmpty:
    # give up and find the canonical type instead:
    let h = sighashes.hashType(t, {CoType, CoConsiderOwned, CoDistinct})
    let canon = c.graph.canonTypes.getOrDefault(h)
    if canon != nil:
      op = canon.attachedOps[kind]
  if op == nil:
    #echo dest.typ.id
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator not found for type " & typeToString(t))
  elif op.ast[genericParamsPos].kind != nkEmpty:
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator is generic")
  dbg:
    if kind == attachedDestructor:
      echo "destructor is ", op.id, " ", op.ast
  if sfError in op.flags: checkForErrorPragma(c, t, ri, AttachedOpToStr[kind])
  genOp(c, op, dest)

proc genDestroy(c: Con; dest: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedDestructor, dest, nil)

proc canBeMoved(c: Con; t: PType): bool {.inline.} =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  if optOwnedRefs in c.graph.config.globalOptions:
    result = t.kind != tyRef and t.attachedOps[attachedSink] != nil
  else:
    result = t.attachedOps[attachedSink] != nil

proc isNoInit(dest: PNode): bool {.inline.} =
  result = dest.kind == nkSym and sfNoInit in dest.sym.flags

proc genSink(c: var Con; s: var Scope; dest, ri: PNode, isDecl = false): PNode =
  if isUnpackedTuple(dest) or (isDecl and c.inLoop <= 0) or
      (isAnalysableFieldAccess(dest, c.owner) and isFirstWrite(dest, c)) or
      isNoInit(dest):
    # optimize sink call into a bitwise memcopy
    result = newTree(nkFastAsgn, dest, ri)
  else:
    let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    if t.attachedOps[attachedSink] != nil:
      result = genOp(c, t, attachedSink, dest, ri)
      result.add ri
    else:
      # the default is to use combination of `=destroy(dest)` and
      # and copyMem(dest, source). This is efficient.
      let snk = newTree(nkFastAsgn, dest, ri)
      result = newTree(nkStmtList, genDestroy(c, dest), snk)

proc genCopyNoCheck(c: Con; dest, ri: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedAsgn, dest, ri)

proc genCopy(c: var Con; dest, ri: PNode): PNode =
  let t = dest.typ
  if tfHasOwned in t.flags and ri.kind != nkNilLit:
    # try to improve the error message here:
    if c.otherRead == nil: discard isLastRead(ri, c)
    checkForErrorPragma(c, t, ri, "=")
  result = genCopyNoCheck(c, dest, ri)

proc addTopVar(c: var Con; s: var Scope; v: PNode): ptr Scope =
  result = addr(s)
  while v.sym.id in result.escapingSyms and result.parent != nil:
    result = result.parent
  result[].vars.add v.sym

proc genDiscriminantAsgn(c: var Con; s: var Scope; n: PNode): PNode =
  # discriminator is ordinal value that doesn't need sink destroy
  # but fields within active case branch might need destruction

  # tmp to support self assignments
  let tmp = getTemp(c, s, n[1].typ, n.info)

  result = newTree(nkStmtList)
  result.add newTree(nkFastAsgn, tmp, p(n[1], c, s, consumed))
  result.add p(n[0], c, s, normal)

  let le = p(n[0], c, s, normal)
  let leDotExpr = if le.kind == nkCheckedFieldExpr: le[0] else: le
  let objType = leDotExpr[0].typ

  if hasDestructor(objType):
    if objType.attachedOps[attachedDestructor] != nil and
        sfOverriden in objType.attachedOps[attachedDestructor].flags:
      localError(c.graph.config, n.info, errGenerated, """Assignment to discriminant for objects with user defined destructor is not supported, object must have default destructor.
It is best to factor out piece of object that needs custom destructor into separate object or not use discriminator assignment""")
      result.add newTree(nkFastAsgn, le, tmp)
      return

    # generate: if le != tmp: `=destroy`(le)
    let branchDestructor = produceDestructorForDiscriminator(c.graph, objType, leDotExpr[1].sym, n.info)
    let cond = newNodeIT(nkInfix, n.info, getSysType(c.graph, unknownLineInfo, tyBool))
    cond.add newSymNode(getMagicEqSymForType(c.graph, le.typ, n.info))
    cond.add le
    cond.add tmp
    let notExpr = newNodeIT(nkPrefix, n.info, getSysType(c.graph, unknownLineInfo, tyBool))
    notExpr.add newSymNode(createMagic(c.graph, "not", mNot))
    notExpr.add cond
    result.add newTree(nkIfStmt, newTree(nkElifBranch, notExpr, genOp(c, branchDestructor, le)))
  result.add newTree(nkFastAsgn, le, tmp)

proc genWasMoved(n: PNode; c: var Con): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, "wasMoved", mWasMoved)))
  result.add copyTree(n) #mWasMoved does not take the address
  #if n.kind != nkSym:
  #  message(c.graph.config, n.info, warnUser, "wasMoved(" & $n & ")")

proc genDefaultCall(t: PType; c: Con; info: TLineInfo): PNode =
  result = newNodeI(nkCall, info)
  result.add(newSymNode(createMagic(c.graph, "default", mDefault)))
  result.typ = t

proc destructiveMoveVar(n: PNode; c: var Con; s: var Scope): PNode =
  # generate: (let tmp = v; reset(v); tmp)
  if not hasDestructor(n.typ):
    result = copyTree(n)
  else:
    result = newNodeIT(nkStmtListExpr, n.info, n.typ)

    var temp = newSym(skLet, getIdent(c.graph.cache, "blitTmp"), c.owner, n.info)
    temp.typ = n.typ
    var v = newNodeI(nkLetSection, n.info)
    let tempAsNode = newSymNode(temp)

    var vpart = newNodeI(nkIdentDefs, tempAsNode.info, 3)
    vpart[0] = tempAsNode
    vpart[1] = c.emptyNode
    vpart[2] = n
    v.add(vpart)

    result.add v
    let wasMovedCall = genWasMoved(skipConv(n), c)
    result.add wasMovedCall
    result.add tempAsNode

proc isCapturedVar(n: PNode): bool =
  let root = getRoot(n)
  if root != nil: result = root.name.s[0] == ':'

proc passCopyToSink(n: PNode; c: var Con; s: var Scope): PNode =
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let tmp = getTemp(c, s, n.typ, n.info)
  if hasDestructor(n.typ):
    result.add genWasMoved(tmp, c)
    var m = genCopy(c, tmp, n)
    m.add p(n, c, s, normal)
    result.add m
    if isLValue(n) and not isCapturedVar(n) and n.typ.skipTypes(abstractInst).kind != tyRef and c.inSpawn == 0:
      message(c.graph.config, n.info, hintPerformance,
        ("passing '$1' to a sink parameter introduces an implicit copy; " &
        "if possible, rearrange your program's control flow to prevent it") % $n)
  else:
    if c.graph.config.selectedGC in {gcArc, gcOrc}:
      assert(not containsGarbageCollectedRef(n.typ))
    result.add newTree(nkAsgn, tmp, p(n, c, s, normal))
  # Since we know somebody will take over the produced copy, there is
  # no need to destroy it.
  result.add tmp

proc isDangerousSeq(t: PType): bool {.inline.} =
  let t = t.skipTypes(abstractInst)
  result = t.kind == tySequence and tfHasOwned notin t[0].flags

proc containsConstSeq(n: PNode): bool =
  if n.kind == nkBracket and n.len > 0 and n.typ != nil and isDangerousSeq(n.typ):
    return true
  result = false
  case n.kind
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv:
    result = containsConstSeq(n[1])
  of nkObjConstr, nkClosure:
    for i in 1..<n.len:
      if containsConstSeq(n[i]): return true
  of nkCurly, nkBracket, nkPar, nkTupleConstr:
    for son in n:
      if containsConstSeq(son): return true
  else: discard

proc ensureDestruction(arg: PNode; c: var Con; s: var Scope): PNode =
  # it can happen that we need to destroy expression contructors
  # like [], (), closures explicitly in order to not leak them.
  if arg.typ != nil and hasDestructor(arg.typ):
    # produce temp creation for (fn, env). But we need to move 'env'?
    # This was already done in the sink parameter handling logic.
    result = newNodeIT(nkStmtListExpr, arg.info, arg.typ)

    if s.parent != nil:
      let tmp = getTemp(c, s.parent[], arg.typ, arg.info)
      result.add genSink(c, s, tmp, arg, isDecl = true)
      result.add tmp
      s.parent[].final.add genDestroy(c, tmp)
    else:
      let tmp = getTemp(c, s, arg.typ, arg.info)
      result.add genSink(c, s, tmp, arg, isDecl = true)
      result.add tmp
      s.final.add genDestroy(c, tmp)
  else:
    result = arg

proc isCursor(n: PNode): bool =
  case n.kind
  of nkSym:
    result = sfCursor in n.sym.flags
  of nkDotExpr:
    result = sfCursor in n[1].sym.flags
  of nkCheckedFieldExpr:
    result = isCursor(n[0])
  else:
    result = false

proc cycleCheck(n: PNode; c: var Con) =
  if c.graph.config.selectedGC != gcArc: return
  var value = n[1]
  if value.kind == nkClosure:
    value = value[1]
  if value.kind == nkNilLit: return
  let destTyp = n[0].typ.skipTypes(abstractInst)
  if destTyp.kind != tyRef and not (destTyp.kind == tyProc and destTyp.callConv == ccClosure):
    return

  var x = n[0]
  var field: PNode = nil
  while true:
    if x.kind == nkDotExpr:
      field = x[1]
      if field.kind == nkSym and sfCursor in field.sym.flags: return
      x = x[0]
    elif x.kind in {nkBracketExpr, nkCheckedFieldExpr, nkDerefExpr, nkHiddenDeref}:
      x = x[0]
    else:
      break
    if exprStructuralEquivalent(x, value, strictSymEquality = true):
      let msg =
        if field != nil:
          "'$#' creates an uncollectable ref cycle; annotate '$#' with .cursor" % [$n, $field]
        else:
          "'$#' creates an uncollectable ref cycle" % [$n]
      message(c.graph.config, n.info, warnCycleCreated, msg)
      break

proc markEscapingVars(n: PNode; s: var Scope) =
  case n.kind
  of nkSym:
    s.escapingSyms.incl n.sym.id
  of nkDotExpr, nkBracketExpr, nkCheckedFieldExpr, nkDerefExpr, nkHiddenDeref,
     nkAddr, nkHiddenAddr, nkStringToCString, nkCStringToString, nkObjDownConv,
     nkObjUpConv:
    markEscapingVars(n[0], s)
  of nkCast, nkHiddenSubConv, nkHiddenStdConv, nkConv:
    markEscapingVars(n[1], s)
  of nkTupleConstr, nkBracket, nkPar, nkClosure:
    for i in 0 ..< n.len:
      markEscapingVars(n[i], s)
  of nkObjConstr:
    for i in 1 ..< n.len:
      markEscapingVars(n[i], s)
  of nkStmtList, nkStmtListExpr:
    if n.len > 0:
      markEscapingVars(n[^1], s)
  else:
    discard "no arbitrary tree traversal here"

proc pVarTopLevel(v: PNode; c: var Con; s: var Scope; ri, res: PNode) =
  # move the variable declaration to the top of the frame:
  let owningScope = c.addTopVar(s, v)
  if isUnpackedTuple(v):
    if c.inLoop > 0:
      # unpacked tuple needs reset at every loop iteration
      res.add newTree(nkFastAsgn, v, genDefaultCall(v.typ, c, v.info))
  elif sfThread notin v.sym.flags:
    # do not destroy thread vars for now at all for consistency.
    if sfGlobal in v.sym.flags and s.parent == nil:
      c.graph.globalDestructors.add genDestroy(c, v)
    else:
      owningScope[].final.add genDestroy(c, v)
  if ri.kind == nkEmpty and c.inLoop > 0:
    res.add moveOrCopy(v, genDefaultCall(v.typ, c, v.info), c, s, isDecl = true)
  elif ri.kind != nkEmpty:
    res.add moveOrCopy(v, ri, c, s, isDecl = true)

template handleNestedTempl(n, processCall: untyped; alwaysStmt: bool) =
  template maybeVoid(child, s): untyped =
    if isEmptyType(child.typ): p(child, c, s, normal)
    else: processCall(child, s)

  let treeFlags = if not isEmptyType(n.typ) and not alwaysStmt: {producesValue} else: {}
  case n.kind
  of nkStmtList, nkStmtListExpr:
    # a statement list does not open a new scope
    if n.len == 0: return n
    result = copyNode(n)
    if alwaysStmt: result.typ = nil
    for i in 0..<n.len-1:
      result.add p(n[i], c, s, normal)
    result.add maybeVoid(n[^1], s)
    markEscapingVars(n[^1], s)

  of nkCaseStmt:
    result = copyNode(n)
    if alwaysStmt: result.typ = nil
    result.add p(n[0], c, s, normal)
    for i in 1..<n.len:
      let it = n[i]
      assert it.kind in {nkOfBranch, nkElse}

      var branch = shallowCopy(it)
      for j in 0 ..< it.len-1:
        branch[j] = copyTree(it[j])
      var ofScope = nestedScope(s)
      markEscapingVars(it[^1], ofScope)
      let ofResult = maybeVoid(it[^1], ofScope)
      branch[^1] = toTree(c, ofScope, ofResult, treeFlags)
      result.add branch
      rememberParent(s, ofScope)

  of nkWhileStmt:
    inc c.inLoop
    result = copyNode(n)
    result.add p(n[0], c, s, normal)
    var bodyScope = nestedScope(s)
    let bodyResult = p(n[1], c, bodyScope, normal)
    result.add toTree(c, bodyScope, bodyResult, treeFlags)
    rememberParent(s, bodyScope)
    dec c.inLoop

  of nkBlockStmt, nkBlockExpr:
    result = copyNode(n)
    if alwaysStmt: result.typ = nil
    result.add n[0]
    var bodyScope = nestedScope(s)
    markEscapingVars(n[1], bodyScope)
    let bodyResult = processCall(n[1], bodyScope)
    result.add toTree(c, bodyScope, bodyResult, treeFlags)
    rememberParent(s, bodyScope)

  of nkIfStmt, nkIfExpr:
    result = copyNode(n)
    if alwaysStmt: result.typ = nil
    for i in 0..<n.len:
      let it = n[i]
      var branch = shallowCopy(it)
      var branchScope = nestedScope(s)
      branchScope.parent = nil
      if it.kind in {nkElifBranch, nkElifExpr}:
        let cond = p(it[0], c, branchScope, normal)
        branch[0] = toTree(c, branchScope, cond, {producesValue, onlyCareAboutVars})

      branchScope.parent = addr(s)
      markEscapingVars(it[^1], branchScope)
      var branchResult = processCall(it[^1], branchScope)
      branch[^1] = toTree(c, branchScope, branchResult, treeFlags)
      result.add branch
      rememberParent(s, branchScope)

  of nkTryStmt:
    result = copyNode(n)
    if alwaysStmt: result.typ = nil
    var tryScope = nestedScope(s)
    markEscapingVars(n[0], tryScope)
    var tryResult = maybeVoid(n[0], tryScope)
    result.add toTree(c, tryScope, tryResult, treeFlags)
    rememberParent(s, tryScope)

    for i in 1..<n.len:
      let it = n[i]
      var branch = copyTree(it)
      var branchScope = nestedScope(s)
      var branchResult = if it.kind == nkFinally: p(it[^1], c, branchScope, normal)
                         else: processCall(it[^1], branchScope)
      branch[^1] = toTree(c, branchScope, branchResult, treeFlags)
      result.add branch
      rememberParent(s, branchScope)

  of nkWhen: # This should be a "when nimvm" node.
    result = copyTree(n)
    if alwaysStmt: result.typ = nil
    result[1][0] = processCall(n[1][0], s)
  else: assert(false)

proc pRaiseStmt(n: PNode, c: var Con; s: var Scope): PNode =
  if optOwnedRefs in c.graph.config.globalOptions and n[0].kind != nkEmpty:
    if n[0].kind in nkCallKinds:
      let call = p(n[0], c, s, normal)
      result = copyNode(n)
      result.add call
    else:
      let tmp = getTemp(c, s, n[0].typ, n.info)
      var m = genCopyNoCheck(c, tmp, n[0])
      m.add p(n[0], c, s, normal)
      result = newTree(nkStmtList, genWasMoved(tmp, c), m)
      var toDisarm = n[0]
      if toDisarm.kind == nkStmtListExpr: toDisarm = toDisarm.lastSon
      if toDisarm.kind == nkSym and toDisarm.sym.owner == c.owner:
        result.add genWasMoved(toDisarm, c)
      result.add newTree(nkRaiseStmt, tmp)
  else:
    result = copyNode(n)
    if n[0].kind != nkEmpty:
      result.add p(n[0], c, s, sinkArg)
    else:
      result.add copyNode(n[0])
  s.needsTry = true

proc p(n: PNode; c: var Con; s: var Scope; mode: ProcessMode): PNode =
  if n.kind in {nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkIfStmt,
                nkIfExpr, nkCaseStmt, nkWhen, nkWhileStmt, nkTryStmt}:
    template process(child, s): untyped = p(child, c, s, mode)
    handleNestedTempl(n, process, false)
  elif mode == sinkArg:
    if n.containsConstSeq:
      # const sequences are not mutable and so we need to pass a copy to the
      # sink parameter (bug #11524). Note that the string implementation is
      # different and can deal with 'const string sunk into var'.
      result = passCopyToSink(n, c, s)
    elif n.kind in {nkBracket, nkObjConstr, nkTupleConstr, nkClosure, nkNilLit} +
         nkCallKinds + nkLiterals:
      result = p(n, c, s, consumed)
    elif n.kind == nkSym and isSinkParam(n.sym) and isLastRead(n, c):
      # Sinked params can be consumed only once. We need to reset the memory
      # to disable the destructor which we have not elided
      result = destructiveMoveVar(n, c, s)
    elif isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
      # it is the last read, can be sinkArg. We need to reset the memory
      # to disable the destructor which we have not elided
      result = destructiveMoveVar(n, c, s)
    elif n.kind in {nkHiddenSubConv, nkHiddenStdConv, nkConv}:
      result = copyTree(n)
      if n.typ.skipTypes(abstractInst-{tyOwned}).kind != tyOwned and
          n[1].typ.skipTypes(abstractInst-{tyOwned}).kind == tyOwned:
        # allow conversions from owned to unowned via this little hack:
        let nTyp = n[1].typ
        n[1].typ = n.typ
        result[1] = p(n[1], c, s, sinkArg)
        result[1].typ = nTyp
      else:
        result[1] = p(n[1], c, s, sinkArg)
    elif n.kind in {nkObjDownConv, nkObjUpConv}:
      result = copyTree(n)
      result[0] = p(n[0], c, s, sinkArg)
    elif n.typ == nil:
      # 'raise X' can be part of a 'case' expression. Deal with it here:
      result = p(n, c, s, normal)
    else:
      # copy objects that are not temporary but passed to a 'sink' parameter
      result = passCopyToSink(n, c, s)
  else:
    case n.kind
    of nkBracket, nkObjConstr, nkTupleConstr, nkClosure, nkCurly:
      # Let C(x) be the construction, 'x' the vector of arguments.
      # C(x) either owns 'x' or it doesn't.
      # If C(x) owns its data, we must consume C(x).
      # If it doesn't own the data, it's harmful to destroy it (double frees etc).
      # We have the freedom to choose whether it owns it or not so we are smart about it
      # and we say, "if passed to a sink we demand C(x) to own its data"
      # otherwise we say "C(x) is just some temporary storage, it doesn't own anything,
      # don't destroy it"
      # but if C(x) is a ref it MUST own its data since we must destroy it
      # so then we have no choice but to use 'sinkArg'.
      let isRefConstr = n.kind == nkObjConstr and n.typ.skipTypes(abstractInst).kind == tyRef
      let m = if isRefConstr: sinkArg
              elif mode == normal: normal
              else: sinkArg

      result = copyTree(n)
      for i in ord(n.kind in {nkObjConstr, nkClosure})..<n.len:
        if n[i].kind == nkExprColonExpr:
          result[i][1] = p(n[i][1], c, s, m)
        else:
          result[i] = p(n[i], c, s, m)
      if mode == normal and isRefConstr:
        result = ensureDestruction(result, c, s)
    of nkCallKinds:
      let inSpawn = c.inSpawn
      if n[0].kind == nkSym and n[0].sym.magic == mSpawn:
        c.inSpawn.inc
      elif c.inSpawn > 0:
        c.inSpawn.dec

      let parameters = n[0].typ
      let L = if parameters != nil: parameters.len else: 0

      when false:
        var isDangerous = false
        if n[0].kind == nkSym and n[0].sym.magic in {mOr, mAnd}:
          inc c.inDangerousBranch
          isDangerous = true

      result = shallowCopy(n)
      for i in 1..<n.len:
        if i < L and isCompileTimeOnly(parameters[i]):
          result[i] = n[i]
        elif i < L and (isSinkTypeForParam(parameters[i]) or inSpawn > 0):
          result[i] = p(n[i], c, s, sinkArg)
        else:
          result[i] = p(n[i], c, s, normal)

      when false:
        if isDangerous:
          dec c.inDangerousBranch

      if n[0].kind == nkSym and n[0].sym.magic in {mNew, mNewFinalize}:
        result[0] = copyTree(n[0])
        if c.graph.config.selectedGC in {gcHooks, gcArc, gcOrc}:
          let destroyOld = genDestroy(c, result[1])
          result = newTree(nkStmtList, destroyOld, result)
      else:
        result[0] = p(n[0], c, s, normal)
      if canRaise(n[0]): s.needsTry = true
      if mode == normal:
        result = ensureDestruction(result, c, s)
    of nkDiscardStmt: # Small optimization
      result = shallowCopy(n)
      if n[0].kind != nkEmpty:
        result[0] = p(n[0], c, s, normal)
      else:
        result[0] = copyNode(n[0])
    of nkVarSection, nkLetSection:
      # transform; var x = y to  var x; x op y  where op is a move or copy
      result = newNodeI(nkStmtList, n.info)
      for it in n:
        var ri = it[^1]
        if it.kind == nkVarTuple and hasDestructor(ri.typ):
          let x = lowerTupleUnpacking(c.graph, it, c.owner)
          result.add p(x, c, s, consumed)
        elif it.kind == nkIdentDefs and hasDestructor(it[0].typ) and not isCursor(it[0]):
          for j in 0..<it.len-2:
            let v = it[j]
            if v.kind == nkSym:
              if sfCompileTime in v.sym.flags: continue
              pVarTopLevel(v, c, s, ri, result)
            else:
              if ri.kind == nkEmpty and c.inLoop > 0:
                ri = genDefaultCall(v.typ, c, v.info)
              if ri.kind != nkEmpty:
                result.add moveOrCopy(v, ri, c, s, isDecl = true)
        else: # keep the var but transform 'ri':
          var v = copyNode(n)
          var itCopy = copyNode(it)
          for j in 0..<it.len-1:
            itCopy.add it[j]
          itCopy.add p(it[^1], c, s, normal)
          v.add itCopy
          result.add v
    of nkAsgn, nkFastAsgn:
      if hasDestructor(n[0].typ) and n[1].kind notin {nkProcDef, nkDo, nkLambda} and
          not isCursor(n[0]):
        # rule (self-assignment-removal):
        if n[1].kind == nkSym and n[0].kind == nkSym and n[0].sym == n[1].sym:
          result = newNodeI(nkEmpty, n.info)
        else:
          if n[0].kind in {nkDotExpr, nkCheckedFieldExpr}:
            cycleCheck(n, c)
          assert n[1].kind notin {nkAsgn, nkFastAsgn}
          result = moveOrCopy(p(n[0], c, s, mode), n[1], c, s)
      elif isDiscriminantField(n[0]):
        result = genDiscriminantAsgn(c, s, n)
      else:
        result = copyNode(n)
        result.add p(n[0], c, s, mode)
        result.add p(n[1], c, s, consumed)
    of nkRaiseStmt:
      result = pRaiseStmt(n, c, s)
    of nkWhileStmt:
      internalError(c.graph.config, n.info, "nkWhileStmt should have been handled earlier")
      result = n
    of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
       nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
       nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
       nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
      result = n

    of nkStringToCString, nkCStringToString, nkChckRangeF, nkChckRange64, nkChckRange, nkPragmaBlock:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = p(n[i], c, s, normal)
      if n.typ != nil and hasDestructor(n.typ):
        if mode == normal:
          result = ensureDestruction(result, c, s)

    of nkHiddenSubConv, nkHiddenStdConv, nkConv:
      # we have an "ownership invariance" for all constructors C(x).
      # See the comment for nkBracket construction. If the caller wants
      # to own 'C(x)', it really wants to own 'x' too. If it doesn't,
      # we need to destroy 'x' but the function call handling ensures that
      # already.
      result = copyTree(n)
      if n.typ.skipTypes(abstractInst-{tyOwned}).kind != tyOwned and
          n[1].typ.skipTypes(abstractInst-{tyOwned}).kind == tyOwned:
        # allow conversions from owned to unowned via this little hack:
        let nTyp = n[1].typ
        n[1].typ = n.typ
        result[1] = p(n[1], c, s, mode)
        result[1].typ = nTyp
      else:
        result[1] = p(n[1], c, s, mode)

    of nkObjDownConv, nkObjUpConv:
      result = copyTree(n)
      result[0] = p(n[0], c, s, mode)

    of nkDotExpr:
      result = shallowCopy(n)
      result[0] = p(n[0], c, s, normal)
      for i in 1 ..< n.len:
        result[i] = n[i]
      if mode == sinkArg and hasDestructor(n.typ):
        if isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
          s.wasMoved.add genWasMoved(n, c)
        else:
          result = passCopyToSink(result, c, s)

    of nkBracketExpr, nkAddr, nkHiddenAddr, nkDerefExpr, nkHiddenDeref:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = p(n[i], c, s, normal)
      if mode == sinkArg and hasDestructor(n.typ):
        if isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
          # consider 'a[(g; destroy(g); 3)]', we want to say 'wasMoved(a[3])'
          # without the junk, hence 'genWasMoved(n, c)'
          # and not 'genWasMoved(result, c)':
          s.wasMoved.add genWasMoved(n, c)
        else:
          result = passCopyToSink(result, c, s)

    of nkDefer, nkRange:
      result = shallowCopy(n)
      for i in 0 ..< n.len:
        result[i] = p(n[i], c, s, normal)

    of nkBreakStmt:
      s.needsTry = true
      result = n
    of nkReturnStmt:
      result = shallowCopy(n)
      for i in 0..<n.len:
        result[i] = p(n[i], c, s, mode)
      s.needsTry = true
    of nkCast:
      result = shallowCopy(n)
      result[0] = n[0]
      result[1] = p(n[1], c, s, mode)
    of nkCheckedFieldExpr:
      result = shallowCopy(n)
      result[0] = p(n[0], c, s, mode)
      for i in 1..<n.len:
        result[i] = n[i]
    of nkGotoState, nkState, nkAsmStmt:
      result = n
    else:
      internalError(c.graph.config, n.info, "cannot inject destructors to node kind: " & $n.kind)

proc moveOrCopy(dest, ri: PNode; c: var Con; s: var Scope, isDecl = false): PNode =
  case ri.kind
  of nkCallKinds:
    result = genSink(c, s, dest, p(ri, c, s, consumed), isDecl)
  of nkBracketExpr:
    if isUnpackedTuple(ri[0]):
      # unpacking of tuple: take over the elements
      result = genSink(c, s, dest, p(ri, c, s, consumed), isDecl)
    elif isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c) and
        not aliases(dest, ri):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, s, dest, ri, isDecl)
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, s, consumed)
  of nkBracket:
    # array constructor
    if ri.len > 0 and isDangerousSeq(ri.typ):
      result = genCopy(c, dest, ri)
      result.add p(ri, c, s, consumed)
    else:
      result = genSink(c, s, dest, p(ri, c, s, consumed), isDecl)
  of nkObjConstr, nkTupleConstr, nkClosure, nkCharLit..nkNilLit:
    result = genSink(c, s, dest, p(ri, c, s, consumed), isDecl)
  of nkSym:
    if isSinkParam(ri.sym) and isLastRead(ri, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, s, dest, ri, isDecl)
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    elif ri.sym.kind != skParam and ri.sym.owner == c.owner and
        isLastRead(ri, c) and canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, s, dest, ri, isDecl)
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, s, consumed)
  of nkHiddenSubConv, nkHiddenStdConv, nkConv, nkObjDownConv, nkObjUpConv:
    result = genSink(c, s, dest, p(ri, c, s, sinkArg), isDecl)
  of nkStmtListExpr, nkBlockExpr, nkIfExpr, nkCaseStmt:
    template process(child, s): untyped = moveOrCopy(dest, child, c, s, isDecl)
    handleNestedTempl(ri, process, true)
  of nkRaiseStmt:
    result = pRaiseStmt(ri, c, s)
  else:
    if isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c) and
        canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      let snk = genSink(c, s, dest, ri, isDecl)
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, s, consumed)

proc computeUninit(c: var Con) =
  if not c.uninitComputed:
    c.uninitComputed = true
    c.uninit = initIntSet()
    var init = initIntSet()
    discard initialized(c.g, pc = 0, init, c.uninit, int.high)

proc injectDefaultCalls(n: PNode, c: var Con) =
  case n.kind
  of nkVarSection, nkLetSection:
    for it in n:
      if it.kind == nkIdentDefs and it[^1].kind == nkEmpty:
        computeUninit(c)
        for j in 0..<it.len-2:
          let v = it[j]
          doAssert v.kind == nkSym
          if c.uninit.contains(v.sym.id):
            it[^1] = genDefaultCall(v.sym.typ, c, v.info)
            break
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef,
      nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    discard
  else:
    for i in 0..<n.safeLen:
      injectDefaultCalls(n[i], c)

proc extractDestroysForTemporaries(c: Con, destroys: PNode): PNode =
  result = newNodeI(nkStmtList, destroys.info)
  for i in 0..<destroys.len:
    if destroys[i][1][0].sym.kind in {skTemp, skForVar}:
      result.add destroys[i]
      destroys[i] = c.emptyNode

proc injectDestructorCalls*(g: ModuleGraph; owner: PSym; n: PNode): PNode =
  if sfGeneratedOp in owner.flags or (owner.kind == skIterator and isInlineIterator(owner.typ)):
    return n
  var c: Con
  c.owner = owner
  c.destroys = newNodeI(nkStmtList, n.info)
  c.topLevelVars = newNodeI(nkVarSection, n.info)
  c.graph = g
  c.emptyNode = newNodeI(nkEmpty, n.info)
  let cfg = constructCfg(owner, n)
  shallowCopy(c.g, cfg)
  c.jumpTargets = initIntSet()
  for i in 0..<c.g.len:
    if c.g[i].kind in {goto, fork}:
      c.jumpTargets.incl(i+c.g[i].dest)
  dbg:
    echo "\n### ", owner.name.s, ":\nCFG:"
    echoCfg(c.g)
    echo n

  var scope: Scope
  let body = p(n, c, scope, normal)

  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1..<params.len:
      let t = params[i].sym.typ
      if isSinkTypeForParam(t) and hasDestructor(t.skipTypes({tySink})):
        scope.final.add genDestroy(c, params[i])
  #if optNimV2 in c.graph.config.globalOptions:
  #  injectDefaultCalls(n, c)
  result = toTree(c, scope, body, {})
  dbg:
    echo ">---------transformed-to--------->"
    echo renderTree(result, {renderIds})
