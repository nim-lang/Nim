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


import
  intsets, ast, msgs, renderer, magicsys, types, idents,
  strutils, options, dfa, lowerings, tables, modulegraphs, msgs,
  lineinfos, parampatterns, sighashes

from trees import exprStructuralEquivalent

type
  Con = object
    owner: PSym
    g: ControlFlowGraph
    jumpTargets: IntSet
    destroys, topLevelVars: PNode
    graph: ModuleGraph
    emptyNode: PNode
    otherRead: PNode
    inLoop: int
    uninit: IntSet # set of uninit'ed vars
    uninitComputed: bool

const toDebug {.strdefine.} = ""

template dbg(body) =
  when toDebug.len > 0:
    if c.owner.name.s == toDebug or toDebug == "always":
      body

proc isLastRead(location: PNode; c: var Con; pc, comesFrom: int): int =
  var pc = pc
  while pc < c.g.len:
    case c.g[pc].kind
    of def:
      if defInstrTargets(c.g[pc], location):
        # the path leads to a redefinition of 's' --> abandon it.
        return high(int)
      inc pc
    of use:
      if useInstrTargets(c.g[pc], location):
        c.otherRead = c.g[pc].n
        return -1
      inc pc
    of goto:
      pc = pc + c.g[pc].dest
    of fork:
      # every branch must lead to the last read of the location:
      let variantA = isLastRead(location, c, pc+1, pc)
      if variantA < 0: return -1
      var variantB = isLastRead(location, c, pc + c.g[pc].dest, pc)
      if variantB < 0: return -1
      elif variantB == high(int):
        variantB = variantA
      pc = variantB
    of InstrKind.join:
      let dest = pc + c.g[pc].dest
      if dest == comesFrom: return pc + 1
      inc pc
  return pc

proc isLastRead(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  c.otherRead = nil
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

  result = isLastRead(n, c, instr+1, -1) >= 0
  dbg: echo "ugh ", c.otherRead.isNil, " ", result

proc isFirstWrite(location: PNode; c: var Con; pc, comesFrom: int; instr: int): int =
  var pc = pc
  while pc < instr:
    case c.g[pc].kind
    of def:
      if defInstrTargets(c.g[pc], location):
        # a definition of 's' before ours makes ours not the first write
        return -1
      inc pc
    of use:
      if useInstrTargets(c.g[pc], location):
        return -1
      inc pc
    of goto:
      pc = pc + c.g[pc].dest
    of fork:
      # every branch must not contain a def/use of our location:
      let variantA = isFirstWrite(location, c, pc+1, pc, instr)
      if variantA < 0: return -1
      var variantB = isFirstWrite(location, c, pc + c.g[pc].dest, pc, instr + c.g[pc].dest)
      if variantB < 0: return -1
      elif variantB == high(int):
        variantB = variantA
      pc = variantB
    of InstrKind.join:
      let dest = pc + c.g[pc].dest
      if dest == comesFrom: return pc + 1
      inc pc
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

  result = isFirstWrite(n, c, 0, -1, instr) >= 0

proc initialized(code: ControlFlowGraph; pc: int,
                 init, uninit: var IntSet; comesFrom: int): int =
  ## Computes the set of definitely initialized variables across all code paths
  ## as an IntSet of IDs.
  var pc = pc
  while pc < code.len:
    case code[pc].kind
    of goto:
      pc = pc + code[pc].dest
    of fork:
      let target = pc + code[pc].dest
      var initA = initIntSet()
      var initB = initIntSet()
      let pcA = initialized(code, pc+1, initA, uninit, pc)
      discard initialized(code, target, initB, uninit, pc)
      # we add vars if they are in both branches:
      for v in initA:
        if v in initB:
          init.incl v
      pc = pcA+1
    of InstrKind.join:
      let target = pc + code[pc].dest
      if comesFrom == target: return pc
      inc pc
    of use:
      let v = code[pc].sym
      if v.kind != skParam and v.id notin init:
        # attempt to read an uninit'ed variable
        uninit.incl v.id
      inc pc
    of def:
      let v = code[pc].sym
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
  let addrExp = newNodeIT(nkHiddenAddr, dest.info, makePtrType(c, dest.typ))
  addrExp.add(dest)
  result = newTree(nkCall, newSymNode(op), addrExp)

when false:
  proc preventMoveRef(dest, ri: PNode): bool =
    let lhs = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    var ri = ri
    if ri.kind in nkCallKinds and ri[0].kind == nkSym and ri[0].sym.magic == mUnown:
      ri = ri[1]
    let rhs = ri.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    result = lhs.kind == tyRef and rhs.kind == tyOwned

proc canBeMoved(c: Con; t: PType): bool {.inline.} =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  if optOwnedRefs in c.graph.config.globalOptions:
    result = t.kind != tyRef and t.attachedOps[attachedSink] != nil
  else:
    result = t.attachedOps[attachedSink] != nil

proc genSink(c: var Con; dest, ri: PNode): PNode =
  if isFirstWrite(dest, c): # optimize sink call into a bitwise memcopy
    result = newTree(nkFastAsgn, dest)
  else:
    let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
    let k = if t.attachedOps[attachedSink] != nil: attachedSink
            else: attachedAsgn
    if t.attachedOps[k] != nil:
      result = genOp(c, t, k, dest, ri)
    else:
      # in rare cases only =destroy exists but no sink or assignment
      # (see Pony object in tmove_objconstr.nim)
      # we generate a fast assignment in this case:
      result = newTree(nkFastAsgn, dest)

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

proc genDestroy(c: Con; dest: PNode): PNode =
  let t = dest.typ.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedDestructor, dest, nil)

proc addTopVar(c: var Con; v: PNode) =
  c.topLevelVars.add newTree(nkIdentDefs, v, c.emptyNode, c.emptyNode)

proc getTemp(c: var Con; typ: PType; info: TLineInfo): PNode =
  let sym = newSym(skTemp, getIdent(c.graph.cache, ":tmpD"), c.owner, info)
  sym.typ = typ
  result = newSymNode(sym)
  c.addTopVar(result)

proc genWasMoved(n: PNode; c: var Con): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, "wasMoved", mWasMoved)))
  result.add copyTree(n) #mWasMoved does not take the address

proc genDefaultCall(t: PType; c: Con; info: TLineInfo): PNode =
  result = newNodeI(nkCall, info)
  result.add(newSymNode(createMagic(c.graph, "default", mDefault)))
  result.typ = t

proc destructiveMoveVar(n: PNode; c: var Con): PNode =
  # generate: (let tmp = v; reset(v); tmp)
  # XXX: Strictly speaking we can only move if there is a ``=sink`` defined
  # or if no ``=sink`` is defined and also no assignment.
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
    result.add genWasMoved(skipConv(n), c)
    result.add tempAsNode

proc sinkParamIsLastReadCheck(c: var Con, s: PNode) =
  assert s.kind == nkSym and s.sym.kind == skParam
  if not isLastRead(s, c):
     localError(c.graph.config, c.otherRead.info, "sink parameter `" & $s.sym.name.s &
         "` is already consumed at " & toFileLineCol(c. graph.config, s.info))

type
  ProcessMode = enum
    normal
    consumed
    sinkArg

proc p(n: PNode; c: var Con; mode: ProcessMode): PNode
proc moveOrCopy(dest, ri: PNode; c: var Con): PNode

proc isClosureEnv(n: PNode): bool = n.kind == nkSym and n.sym.name.s[0] == ':'

proc passCopyToSink(n: PNode; c: var Con): PNode =
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let tmp = getTemp(c, n.typ, n.info)
  # XXX This is only required if we are in a loop. Since we move temporaries
  # out of loops we need to mark it as 'wasMoved'.
  result.add genWasMoved(tmp, c)
  if hasDestructor(n.typ):
    var m = genCopy(c, tmp, n)
    m.add p(n, c, normal)
    result.add m
    if isLValue(n) and not isClosureEnv(n):
      message(c.graph.config, n.info, hintPerformance,
        ("passing '$1' to a sink parameter introduces an implicit copy; " &
        "use 'move($1)' to prevent it") % $n)
  else:
    if c.graph.config.selectedGC in {gcArc, gcOrc}:
      assert(not containsGarbageCollectedRef(n.typ))
    result.add newTree(nkAsgn, tmp, p(n, c, normal))
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

template handleNested(n: untyped, processCall: untyped) =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    if n.len == 0: return n
    result = copyNode(n)
    for i in 0..<n.len-1:
      result.add p(n[i], c, normal)
    template node: untyped = n[^1]
    result.add processCall
  of nkBlockStmt, nkBlockExpr:
    result = copyNode(n)
    result.add n[0]
    template node: untyped = n[1]
    result.add processCall
  of nkIfStmt, nkIfExpr:
    result = copyNode(n)
    for son in n:
      var branch = copyNode(son)
      if son.kind in {nkElifBranch, nkElifExpr}:
        template node: untyped = son[1]
        branch.add p(son[0], c, normal) #The condition
        branch.add if node.typ == nil: p(node, c, normal) #noreturn
                   else: processCall
      else:
        template node: untyped = son[0]
        branch.add if node.typ == nil: p(node, c, normal) #noreturn
                   else: processCall
      result.add branch
  of nkCaseStmt:
    result = copyNode(n)
    result.add p(n[0], c, normal)
    for i in 1..<n.len:
      var branch: PNode
      if n[i].kind == nkOfBranch:
        branch = n[i] # of branch conditions are constants
        template node: untyped = n[i][^1]
        branch[^1] = if node.typ == nil: p(node, c, normal) #noreturn
                     else: processCall
      elif n[i].kind in {nkElifBranch, nkElifExpr}:
        branch = copyNode(n[i])
        branch.add p(n[i][0], c, normal) #The condition
        template node: untyped = n[i][1]
        branch.add if node.typ == nil: p(node, c, normal) #noreturn
                   else: processCall
      else:
        branch = copyNode(n[i])
        template node: untyped = n[i][0]
        branch.add if node.typ == nil: p(node, c, normal) #noreturn
                   else: processCall
      result.add branch
  of nkWhen: # This should be a "when nimvm" node.
    result = copyTree(n)
    template node: untyped = n[1][0]
    result[1][0] = processCall
  else: assert(false)

proc ensureDestruction(arg: PNode; c: var Con): PNode =
  # it can happen that we need to destroy expression contructors
  # like [], (), closures explicitly in order to not leak them.
  if arg.typ != nil and hasDestructor(arg.typ):
    # produce temp creation for (fn, env). But we need to move 'env'?
    # This was already done in the sink parameter handling logic.
    result = newNodeIT(nkStmtListExpr, arg.info, arg.typ)
    let tmp = getTemp(c, arg.typ, arg.info)
    var sinkExpr = genSink(c, tmp, arg)
    sinkExpr.add arg
    result.add sinkExpr
    result.add tmp
    c.destroys.add genDestroy(c, tmp)
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

proc p(n: PNode; c: var Con; mode: ProcessMode): PNode =
  if n.kind in {nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkIfStmt, nkIfExpr, nkCaseStmt, nkWhen}:
    handleNested(n): p(node, c, mode)
  elif mode == sinkArg:
    if n.containsConstSeq:
      # const sequences are not mutable and so we need to pass a copy to the
      # sink parameter (bug #11524). Note that the string implementation is
      # different and can deal with 'const string sunk into var'.
      result = passCopyToSink(n, c)
    elif n.kind in {nkBracket, nkObjConstr, nkTupleConstr, nkClosure} + nkCallKinds + nkLiterals:
      result = p(n, c, consumed)
    elif n.kind == nkSym and isSinkParam(n.sym):
      # Sinked params can be consumed only once. We need to reset the memory
      # to disable the destructor which we have not elided
      sinkParamIsLastReadCheck(c, n)
      result = destructiveMoveVar(n, c)
    elif isAnalysableFieldAccess(n, c.owner) and isLastRead(n, c):
      # it is the last read, can be sinkArg. We need to reset the memory
      # to disable the destructor which we have not elided
      result = destructiveMoveVar(n, c)
    elif n.kind in {nkHiddenSubConv, nkHiddenStdConv, nkConv}:
      result = copyTree(n)
      if n.typ.skipTypes(abstractInst-{tyOwned}).kind != tyOwned and
          n[1].typ.skipTypes(abstractInst-{tyOwned}).kind == tyOwned:
        # allow conversions from owned to unowned via this little hack:
        let nTyp = n[1].typ
        n[1].typ = n.typ
        result[1] = p(n[1], c, sinkArg)
        result[1].typ = nTyp
      else:
        result[1] = p(n[1], c, sinkArg)
    elif n.kind in {nkObjDownConv, nkObjUpConv}:
      result = copyTree(n)
      result[0] = p(n[0], c, sinkArg)
    else:
      # copy objects that are not temporary but passed to a 'sink' parameter
      result = passCopyToSink(n, c)
  else:
    case n.kind
    of nkBracket, nkObjConstr, nkTupleConstr, nkClosure:
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
          result[i][1] = p(n[i][1], c, m)
        else:
          result[i] = p(n[i], c, m)
      if mode == normal and isRefConstr:
        result = ensureDestruction(result, c)
    of nkCallKinds:
      let parameters = n[0].typ
      let L = if parameters != nil: parameters.len else: 0
      result = shallowCopy(n)
      for i in 1..<n.len:
        if i < L and isSinkTypeForParam(parameters[i]):
          result[i] = p(n[i], c, sinkArg)
        else:
          result[i] = p(n[i], c, normal)
      if n[0].kind == nkSym and n[0].sym.magic in {mNew, mNewFinalize}:
        result[0] = copyTree(n[0])
        if c.graph.config.selectedGC in {gcHooks, gcArc, gcOrc}:
          let destroyOld = genDestroy(c, result[1])
          result = newTree(nkStmtList, destroyOld, result)
      else:
        result[0] = p(n[0], c, normal)

      if mode == normal:
        result = ensureDestruction(result, c)
    of nkDiscardStmt: # Small optimization
      result = shallowCopy(n)
      if n[0].kind != nkEmpty:
        result[0] = p(n[0], c, normal)
      else:
        result[0] = copyNode(n[0])
    of nkVarSection, nkLetSection:
      # transform; var x = y to  var x; x op y  where op is a move or copy
      result = newNodeI(nkStmtList, n.info)
      for it in n:
        var ri = it[^1]
        if it.kind == nkVarTuple and hasDestructor(ri.typ):
          let x = lowerTupleUnpacking(c.graph, it, c.owner)
          result.add p(x, c, consumed)
        elif it.kind == nkIdentDefs and hasDestructor(it[0].typ) and not isCursor(it[0]):
          for j in 0..<it.len-2:
            let v = it[j]
            if v.kind == nkSym:
              if sfCompileTime in v.sym.flags: continue
              # move the variable declaration to the top of the frame:
              c.addTopVar v
              # make sure it's destroyed at the end of the proc:
              if not isUnpackedTuple(v):
                c.destroys.add genDestroy(c, v)
            if ri.kind == nkEmpty and c.inLoop > 0:
              ri = genDefaultCall(v.typ, c, v.info)
            if ri.kind != nkEmpty:
              let r = moveOrCopy(v, ri, c)
              result.add r
        else: # keep the var but transform 'ri':
          var v = copyNode(n)
          var itCopy = copyNode(it)
          for j in 0..<it.len-1:
            itCopy.add it[j]
          itCopy.add p(it[^1], c, normal)
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
          result = moveOrCopy(n[0], n[1], c)
      else:
        result = copyNode(n)
        result.add copyTree(n[0])
        result.add p(n[1], c, consumed)
    of nkRaiseStmt:
      if optOwnedRefs in c.graph.config.globalOptions and n[0].kind != nkEmpty:
        if n[0].kind in nkCallKinds:
          let call = p(n[0], c, normal)
          result = copyNode(n)
          result.add call
        else:
          let tmp = getTemp(c, n[0].typ, n.info)
          var m = genCopyNoCheck(c, tmp, n[0])
          m.add p(n[0], c, normal)
          result = newTree(nkStmtList, genWasMoved(tmp, c), m)
          var toDisarm = n[0]
          if toDisarm.kind == nkStmtListExpr: toDisarm = toDisarm.lastSon
          if toDisarm.kind == nkSym and toDisarm.sym.owner == c.owner:
            result.add genWasMoved(toDisarm, c)
          result.add newTree(nkRaiseStmt, tmp)
      else:
        result = copyNode(n)
        if n[0].kind != nkEmpty:
          result.add p(n[0], c, sinkArg)
        else:
          result.add copyNode(n[0])
    of nkWhileStmt:
      result = copyNode(n)
      inc c.inLoop
      result.add p(n[0], c, normal)
      result.add p(n[1], c, normal)
      dec c.inLoop
    of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
       nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
       nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
       nkExportStmt, nkPragma, nkCommentStmt, nkBreakStmt, nkBreakState:
      result = n
    else:
      result = shallowCopy(n)
      for i in 0..<n.len:
        result[i] = p(n[i], c, mode)

proc moveOrCopy(dest, ri: PNode; c: var Con): PNode =
  case ri.kind
  of nkCallKinds:
    if isUnpackedTuple(dest):
      result = newTree(nkFastAsgn, dest, p(ri, c, consumed))
    else:
      result = genSink(c, dest, ri)
      result.add p(ri, c, consumed)
  of nkBracketExpr:
    if isUnpackedTuple(ri[0]):
      # unpacking of tuple: take over elements
      result = newTree(nkFastAsgn, dest, p(ri, c, consumed))
    elif isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, consumed)
  of nkBracket:
    # array constructor
    if ri.len > 0 and isDangerousSeq(ri.typ):
      result = genCopy(c, dest, ri)
    else:
      result = genSink(c, dest, ri)
    result.add p(ri, c, consumed)
  of nkObjConstr, nkTupleConstr, nkClosure, nkCharLit..nkNilLit:
    result = genSink(c, dest, ri)
    result.add p(ri, c, consumed)
  of nkSym:
    if isSinkParam(ri.sym):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      sinkParamIsLastReadCheck(c, ri)
      var snk = genSink(c, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    elif ri.sym.kind != skParam and ri.sym.owner == c.owner and
        isLastRead(ri, c) and canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, consumed)
  of nkHiddenSubConv, nkHiddenStdConv, nkConv:
    when false:
      result = moveOrCopy(dest, ri[1], c)
      if not sameType(ri.typ, ri[1].typ):
        let copyRi = copyTree(ri)
        copyRi[1] = result[^1]
        result[^1] = copyRi
    else:
      result = genSink(c, dest, ri)
      result.add p(ri, c, sinkArg)
  of nkObjDownConv, nkObjUpConv:
    when false:
      result = moveOrCopy(dest, ri[0], c)
      let copyRi = copyTree(ri)
      copyRi[0] = result[^1]
      result[^1] = copyRi
    else:
      result = genSink(c, dest, ri)
      result.add p(ri, c, sinkArg)
  of nkStmtListExpr, nkBlockExpr, nkIfExpr, nkCaseStmt:
    handleNested(ri): moveOrCopy(dest, node, c)
  else:
    if isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c) and
        canBeMoved(c, dest.typ):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest, ri)
      result.add p(ri, c, consumed)

proc computeUninit(c: var Con) =
  if not c.uninitComputed:
    c.uninitComputed = true
    c.uninit = initIntSet()
    var init = initIntSet()
    discard initialized(c.g, pc = 0, init, c.uninit, comesFrom = -1)

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
    if destroys[i][1][0].sym.kind == skTemp:
      result.add destroys[i]
      destroys[i] = c.emptyNode

proc reverseDestroys(destroys: seq[PNode]): seq[PNode] =
  for i in countdown(destroys.len - 1, 0):
    result.add destroys[i]

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
  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1..<params.len:
      let t = params[i].sym.typ
      if isSinkTypeForParam(t) and hasDestructor(t.skipTypes({tySink})):
        c.destroys.add genDestroy(c, params[i])

  #if optNimV2 in c.graph.config.globalOptions:
  #  injectDefaultCalls(n, c)
  let body = p(n, c, normal)
  result = newNodeI(nkStmtList, n.info)
  if c.topLevelVars.len > 0:
    result.add c.topLevelVars
  if c.destroys.len > 0:
    c.destroys.sons = reverseDestroys(c.destroys.sons)
    if owner.kind == skModule:
      result.add newTryFinally(body, extractDestroysForTemporaries(c, c.destroys))
      g.globalDestructors.add c.destroys
    else:
      result.add newTryFinally(body, c.destroys)
  else:
    result.add body
  dbg:
    echo ">---------transformed-to--------->"
    echo renderTree(result, {renderIds})
