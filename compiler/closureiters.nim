#
#
#           The Nim Compiler
#        (c) Copyright 2018 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements closure iterator transformations.
# The main idea is to split the closure iterator body to top level statements.
# The body is split by yield statement.
#
# Example:
#  while a > 0:
#    echo "hi"
#    yield a
#    dec a
#
# Should be transformed to:
#  case :state
#  of 0:
#    if a > 0:
#      echo "hi"
#      :state = 1 # Next state
#      return a # yield
#    else:
#      :state = 2 # Next state
#      break :stateLoop # Proceed to the next state
#  of 1:
#    dec a
#    :state = 0 # Next state
#    break :stateLoop # Proceed to the next state
#  of 2:
#    :state = -1 # End of execution
#  else:
#    return

# Lambdalifting treats :state variable specially, it should always end up
# as the first field in env. Currently C codegen depends on this behavior.

# One special subtransformation is nkStmtListExpr lowering.
# Example:
#   template foo(): int =
#     yield 1
#     2
#
#   iterator it(): int {.closure.} =
#     if foo() == 2:
#       yield 3
#
# If a nkStmtListExpr has yield inside, it has first to be lowered to:
#   yield 1
#   :tmpSlLower = 2
#   if :tmpSlLower == 2:
#     yield 3

# nkTryStmt Transformations:
# If the iter has an nkTryStmt with a yield inside
#  - the closure iter is promoted to have exceptions (ctx.hasExceptions = true)
#  - exception table is created. This is a const array, where
#    `exceptionTable[i]` is exception landing state idx to which we should jump from state
#    `i` should exception be raised in state `i`. For all states in `try` block
#    the target state is `except` block. For all states in `except` block
#    the target state is `finally` block. For all other states there is no
#    target state (0, as the first state can never be except nor finally).
#  - env var :curExc is created, where "current" exception within the iterator is stored,
#    also finallies use it to decide their exit logic
#  - if there are finallies, env var :finallyPath is created. It contains exit state labels
#    for every finally level, and is changed in runtime in try, except, break, and return
#    nodes to control finally exit behavior.
#  - the iter body is wrapped into a
#      var :tmp: Exception
#      try:
#       ...body...
#      catch:
#        :state = exceptionTable[:state]
#        if :state == 0: raise # No state that could handle exception
#        :tmp = getCurrentException()
#      pushCurrentException(:tmp)
#
# nkReturnStmt within a try/except/finally now has to behave differently as we
# want parent finallies to be executed before the return, thus it is
# transformed to:
#  :tmpResult = returnValue (if return doesn't have a value, this is skipped)
#  :finallyPath[0] = 0 # Finally at the bottom should just exit
#  :finallyPath[N] = finallyNMinus1State # Next finally should exit to its parent
#  goto finallyNState (or -1 if not exists) # finallyN is the nearest finally
#
# Example:
#
# try:
#  yield 0
#  raise ...
# except:
#  yield 1
#  return 3
# finally:
#  yield 2
# somethingElse()
#
# Is transformed to (yields are left in place for example simplicity,
#    in reality the code is subdivided even more, as described above):
#
# case :state
# of 0: # Try
#   :finallyPath[LEVEL] = curExcLandingState # should exception occur our finally
#                                            # must jump to its landing
#   yield 0
#   raise ...
#   :finallyPath[LEVEL] = 3 # Exception did not happen. Our finally can continue to state 3
#   :state = 2              # And we continue to our finally
#   break :stateLoop
# of 1: # Except
#   yield 1
#   :tmpResult = 3           # Return
#   :finalyPath[LEVEL] = 0   # Configure finally path.
#   :state = 2 # Goto Finally
#   break :stateLoop
#   popCurrentException()    # XXX: This is likely wrong, see #25031
#   :state = 2 # What would happen should we not return
#   break :stateLoop
# of 2: # Finally
#   yield 2
#   if :finallyPath[LEVEL] == 0: # This node is created by `newEndFinallyNode`
#     if :curExc == nil:
#       :state = -1
#       return result = :tmpResult
#     else:
#       raise
#   :state = :finallyPath[LEVEL] # Go to next state
#   break :stateLoop
# of 3:
#   somethingElse()
#   :state = -1 # Exit
#   break :stateLoop
# else:
#   return

import
  ast, msgs, idents,
  renderer, magicsys, lowerings, lambdalifting, modulegraphs, lineinfos

import std/tables

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  FinallyTarget = object
    n: PNode # nkWhileStmt, nkBlock, nkFinally
    label: PNode # exit state for blocks and whiles (used by breaks),
                 # or enter state for finallies (used by breaks and returns)

  State = object
    label: PNode # Int literal with state idx. It is filled after state split
    body: PNode
    excLandingState: PNode # label of exception landing state (except or finally)
    inlinable: bool
    deletable: bool

  Ctx = object
    g: ModuleGraph
    fn: PSym
    tmpResultSym: PSym # Used when we return, but finally has to interfere
    finallyPathSym: PSym
    curExcSym: PSym # Current exception
    externExcSym: PSym # Extern exception: what would getCurrentException() return outside of closure iter

    states: seq[State] # The resulting states. Label is int literal.
    finallyPathStack: seq[FinallyTarget] # Stack of split blocks, whiles and finallies
    stateLoopLabel: PSym # Label to break on, when jumping between states.
    tempVarId: int # unique name counter
    hasExceptions: bool # Does closure have yield in try?
    curExcLandingState: PNode
    curFinallyLevel: int
    idgen: IdGenerator
    varStates: Table[ItemId, int] # Used to detect if local variable belongs to multiple states
    finallyPathLen: PNode # int literal

    nullifyCurExc: PNode # Empty node, if no yields in tries
    restoreExternExc: PNode # Empty node, id no yields in tries

const
  nkSkip = {nkEmpty..nkNilLit, nkTemplateDef, nkTypeSection, nkStaticStmt,
            nkCommentStmt, nkMixinStmt, nkBindStmt, nkTypeOfExpr} + procDefs
  localNotSeen = -1
  localRequiresLifting = -2

proc newStateAccess(ctx: var Ctx): PNode =
  result = rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)),
      getStateField(ctx.g, ctx.fn), ctx.fn.info)

proc newStateAssgn(ctx: var Ctx, toValue: PNode): PNode =
  # Creates state assignment:
  #   :state = toValue
  newTree(nkAsgn, ctx.newStateAccess(), toValue)

proc newEnvVar(ctx: var Ctx, name: string, typ: PType): PSym =
  result = newSym(skVar, getIdent(ctx.g.cache, name), ctx.idgen, ctx.fn, ctx.fn.info)
  result.typ = typ
  result.flags.incl sfNoInit
  assert(not typ.isNil, "Env var needs a type")

  let envParam = getEnvParam(ctx.fn)
  result = addUniqueField(envParam.typ.elementType, result, ctx.g.cache, ctx.idgen)

proc newEnvVarAccess(ctx: Ctx, s: PSym): PNode =
  result = rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)), s, ctx.fn.info)

proc newTempVarAccess(ctx: Ctx, s: PSym): PNode =
  result = newSymNode(s, ctx.fn.info)

proc newTmpResultAccess(ctx: var Ctx): PNode =
  if ctx.tmpResultSym.isNil:
    ctx.tmpResultSym = ctx.newEnvVar(":tmpResult", ctx.fn.typ.returnType)
  ctx.newEnvVarAccess(ctx.tmpResultSym)

proc newArrayType(g: ModuleGraph; len: PNode, t: PType; idgen: IdGenerator; owner: PSym): PType =
  result = newType(tyArray, idgen, owner)

  let rng = newType(tyRange, idgen, owner)
  rng.n = newTree(nkRange, g.newIntLit(owner.info, 0), len)
  rng.rawAddSon(t)

  result.rawAddSon(rng)
  result.rawAddSon(t)

proc newFinallyPathAccess(ctx: var Ctx, level: int, info: TLineInfo): PNode =
  # ctx.:finallyPath[level]
  let minPathLen = level + 1
  if ctx.finallyPathSym.isNil:
    ctx.finallyPathLen = ctx.g.newIntLit(ctx.fn.info, minPathLen)
    let ty = ctx.g.newArrayType(ctx.finallyPathLen, ctx.g.getSysType(ctx.fn.info, tyInt16), ctx.idgen, ctx.fn)
    ctx.finallyPathSym = ctx.newEnvVar(":finallyPath", ty)
  elif ctx.finallyPathLen.intVal < minPathLen:
    ctx.finallyPathLen.intVal = minPathLen

  result = newTreeIT(nkBracketExpr, info, ctx.g.getSysType(info, tyInt),
                   ctx.newEnvVarAccess(ctx.finallyPathSym),
                   ctx.g.newIntLit(ctx.fn.info, level))

proc newFinallyPathAssign(ctx: var Ctx, level: int, label: PNode, info: TLineInfo): PNode =
  assert(label != nil)
  let fp = newFinallyPathAccess(ctx, level, info)
  result = newTree(nkAsgn, fp, label)

proc newCurExcAccess(ctx: var Ctx): PNode =
  if ctx.curExcSym.isNil:
    let getCurExc = ctx.g.callCodegenProc("getCurrentException")
    ctx.curExcSym = ctx.newEnvVar(":curExc", getCurExc.typ)
  ctx.newEnvVarAccess(ctx.curExcSym)

proc newStateLabel(ctx: Ctx): PNode =
  ctx.g.newIntLit(TLineInfo(), 0)

proc newState(ctx: var Ctx, n: PNode, inlinable: bool, label: PNode): PNode =
  # Creates a new state, adds it to the context
  # Returns label of the newly created state
  result = label
  if result.isNil: result = ctx.newStateLabel()
  assert(result.kind == nkIntLit)

  ctx.states.add(State(label: result, body: n, excLandingState: ctx.curExcLandingState, inlinable: inlinable))

proc toStmtList(n: PNode): PNode =
  result = n
  if result.kind notin {nkStmtList, nkStmtListExpr}:
    result = newNodeI(nkStmtList, n.info)
    result.add(n)

proc addGotoOut(n: PNode, gotoOut: PNode): PNode =
  # Make sure `n` is a stmtlist, and ends with `gotoOut`
  result = toStmtList(n)
  if result.len == 0 or result[^1].kind != nkGotoState:
    result.add(gotoOut)

proc newTempVarDef(ctx: Ctx, s: PSym, initialValue: PNode): PNode =
  var v = initialValue
  if v == nil:
    v = ctx.g.emptyNode
  newTree(nkVarSection, newTree(nkIdentDefs, newSymNode(s), ctx.g.emptyNode, v))

proc newTempVar(ctx: var Ctx, typ: PType, parent: PNode, initialValue: PNode = nil): PSym =
  result = newSym(skVar, getIdent(ctx.g.cache, ":tmpSlLower" & $ctx.tempVarId), ctx.idgen, ctx.fn, ctx.fn.info)
  inc ctx.tempVarId
  result.typ = typ
  assert(not typ.isNil, "Temp var needs a type")
  parent.add(ctx.newTempVarDef(result, initialValue))

proc newExternExcAccess(ctx: var Ctx): PNode =
  if ctx.externExcSym == nil:
    ctx.externExcSym = newSym(skVar, getIdent(ctx.g.cache, ":externExc"), ctx.idgen, ctx.fn, ctx.fn.info)
    ctx.externExcSym.typ = ctx.curExcSym.typ
  newSymNode(ctx.externExcSym, ctx.fn.info)

proc newRestoreExternException(ctx: var Ctx): PNode =
  ctx.g.callCodegenProc("closureIterSetExc", ctx.fn.info, ctx.newExternExcAccess())

proc hasYields(n: PNode): bool =
  # TODO: This is very inefficient. It traverses the node, looking for nkYieldStmt.
  case n.kind
  of nkYieldStmt:
    result = true
  of nkSkip:
    result = false
  else:
    result = false
    for i in ord(n.kind == nkCast)..<n.len:
      if n[i].hasYields:
        result = true
        break

proc newNullifyCurExc(ctx: var Ctx, info: TLineInfo): PNode =
  # :curExc = nil
  let curExc = ctx.newCurExcAccess()
  curExc.info = info
  let nilnode = newNodeIT(nkNilLit, info, getSysType(ctx.g, info, tyNil))
  result = newTree(nkAsgn, curExc, nilnode)

proc newOr(g: ModuleGraph, a, b: PNode): PNode {.inline.} =
  result = newTreeIT(nkCall, a.info, g.getSysType(a.info, tyBool),
                     newSymNode(g.getSysMagic(a.info, "or", mOr)), a, b)

proc collectExceptState(ctx: var Ctx, n: PNode): PNode {.inline.} =
  var ifStmt = newNodeI(nkIfStmt, n.info)
  let g = ctx.g
  for c in n:
    if c.kind == nkExceptBranch:
      var ifBranch: PNode

      if c.len > 1:
        var cond: PNode = nil
        for i in 0..<c.len - 1:
          assert(c[i].kind == nkType)
          let nextCond = newTreeIT(nkCall, c.info, ctx.g.getSysType(c.info, tyBool),
            newSymNode(g.getSysMagic(c.info, "of", mOf)),
            g.callCodegenProc("getCurrentException"),
            c[i])

          cond = if cond.isNil: nextCond
                 else: g.newOr(cond, nextCond)

        ifBranch = newTreeI(nkElifBranch, c.info, cond)
      else:
        if ifStmt.len == 0:
          ifStmt = newNodeI(nkStmtList, c.info)
          ifBranch = newNodeI(nkStmtList, c.info)
        else:
          ifBranch = newNodeI(nkElse, c.info)

      ifBranch.add(c[^1])
      ifStmt.add(ifBranch)

  if ifStmt.len != 0:
    result = newTree(nkStmtList, ifStmt)
  else:
    result = ctx.g.emptyNode

proc addElseToExcept(ctx: var Ctx, n, gotoOut: PNode): PNode =
  # We should adjust finallyPath to gotoOut if exception is handled
  # if there is no finally node next to this except, gotoOut must be nil
  result = n
  if n.kind == nkStmtList:
    if n[0].kind == nkIfStmt and n[0][^1].kind != nkElse:
      # Not all cases are covered, which means exception is not handled
      # and we should go to parent exception landing state
      let action =
        if ctx.curFinallyLevel == 0:
          # There is no suitable finally around. We must reraise.
          newTreeI(nkRaiseStmt, n.info, ctx.g.emptyNode)
        else:
          # Jump to finally.
          newTree(nkGotoState, ctx.curExcLandingState)

      n[0].add(newTree(nkElse,
                       newTreeI(nkStmtList, n.info, action)))

    # Exception is handled
    # XXX: This is likely wrong. See #25031. We must clear exception not only here
    # at the end of except but also when except flow is interrupted with break or return
    # and if there's a raise in except flow, current exception must be replaced with the
    # raised one.
    n.add newTree(nkCall,
      newSymNode(ctx.g.getCompilerProc("popCurrentException")))
    n.add ctx.newNullifyCurExc(n.info)
    if gotoOut != nil:
      # We have a finally node following this except block, and exception is handled
      # Configure its path to continue normally
      n.add(ctx.newFinallyPathAssign(ctx.curFinallyLevel - 1, gotoOut[0], n.info))

proc getFinallyNode(ctx: var Ctx, n: PNode): PNode =
  result = n[^1]
  if result.kind == nkFinally:
    result = result[0]
  else:
    result = ctx.g.emptyNode

proc hasYieldsInExpressions(n: PNode): bool =
  case n.kind
  of nkSkip:
    result = false
  of nkStmtListExpr:
    if isEmptyType(n.typ):
      result = false
      for c in n:
        if c.hasYieldsInExpressions:
          return true
    else:
      result = n.hasYields
  of nkCast:
    result = false
    for i in 1..<n.len:
      if n[i].hasYieldsInExpressions:
        return true
  else:
    result = false
    for c in n:
      if c.hasYieldsInExpressions:
        return true

proc exprToStmtList(n: PNode): tuple[s, res: PNode] =
  assert(n.kind == nkStmtListExpr)
  result = (newNodeI(nkStmtList, n.info), nil)
  result.s.sons = @[]

  var n = n
  while n.kind == nkStmtListExpr:
    result.s.sons.add(n.sons)
    result.s.sons.setLen(result.s.len - 1) # delete last son
    n = n[^1]

  result.res = n

proc newTempVarAsgn(ctx: Ctx, s: PSym, v: PNode): PNode =
  if isEmptyType(v.typ):
    result = v
  else:
    result = newTree(nkFastAsgn, ctx.newTempVarAccess(s), v)
    result.info = v.info

proc addExprAssgn(ctx: Ctx, output, input: PNode, sym: PSym) =
  if input.kind == nkStmtListExpr:
    let (st, res) = exprToStmtList(input)
    output.add(st)
    output.add(ctx.newTempVarAsgn(sym, res))
  else:
    output.add(ctx.newTempVarAsgn(sym, input))

proc convertExprBodyToAsgn(ctx: Ctx, exprBody: PNode, res: PSym): PNode =
  result = newNodeI(nkStmtList, exprBody.info)
  ctx.addExprAssgn(result, exprBody, res)

proc newNotCall(g: ModuleGraph; e: PNode): PNode =
  result = newTreeIT(nkCall, e.info, g.getSysType(e.info, tyBool),
                     newSymNode(g.getSysMagic(e.info, "not", mNot), e.info), e)

proc boolLit(g: ModuleGraph; info: TLineInfo; value: bool): PNode =
  result = newIntLit(g, info, ord value)
  result.typ() = getSysType(g, info, tyBool)

proc captureVar(c: var Ctx, s: PSym) =
  if c.varStates.getOrDefault(s.itemId) != localRequiresLifting:
    c.varStates[s.itemId] = localRequiresLifting # Mark this variable for lifting
    let e = getEnvParam(c.fn)
    discard addField(e.typ.elementType, s, c.g.cache, c.idgen)

proc lowerStmtListExprs(ctx: var Ctx, n: PNode, needsSplit: var bool): PNode =
  result = n
  case n.kind
  of nkSkip:
    discard

  of nkYieldStmt:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      result = newNodeI(nkStmtList, n.info)
      let (st, ex) = exprToStmtList(n[0])
      result.add(st)
      n[0] = ex
      result.add(n)

    needsSplit = true

  of nkPar, nkObjConstr, nkTupleConstr, nkBracket:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true

      if n.typ.isNil: internalError(ctx.g.config, "lowerStmtListExprs: constr typ.isNil")
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)

      for i in 0..<n.len:
        case n[i].kind
        of nkExprColonExpr:
          if n[i][1].kind == nkStmtListExpr:
            let (st, ex) = exprToStmtList(n[i][1])
            result.add(st)
            n[i][1] = ex
        of nkStmtListExpr:
          let (st, ex) = exprToStmtList(n[i])
          result.add(st)
          n[i] = ex
        else: discard
      result.add(n)

  of nkIfStmt, nkIfExpr:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      var tmp: PSym = nil
      let isExpr = not isEmptyType(n.typ)
      if isExpr:
        result = newNodeIT(nkStmtListExpr, n.info, n.typ)
        tmp = ctx.newTempVar(n.typ, result)
      else:
        result = newNodeI(nkStmtList, n.info)

      var curS = result

      for branch in n:
        case branch.kind
        of nkElseExpr, nkElse:
          if isExpr:
            let branchBody = newNodeI(nkStmtList, branch.info)
            ctx.addExprAssgn(branchBody, branch[0], tmp)
            let newBranch = newTree(nkElse, branchBody)
            curS.add(newBranch)
          else:
            curS.add(branch)

        of nkElifExpr, nkElifBranch:
          var newBranch: PNode
          if branch[0].kind == nkStmtListExpr:
            let (st, res) = exprToStmtList(branch[0])
            let elseBody = newTree(nkStmtList, st)

            newBranch = newTree(nkElifBranch, res, branch[1])

            let newIf = newTree(nkIfStmt, newBranch)
            elseBody.add(newIf)
            if curS.kind == nkIfStmt:
              let newElse = newNodeI(nkElse, branch.info)
              newElse.add(elseBody)
              curS.add(newElse)
            else:
              curS.add(elseBody)
            curS = newIf
          else:
            newBranch = branch
            if curS.kind == nkIfStmt:
              curS.add(newBranch)
            else:
              let newIf = newTree(nkIfStmt, newBranch)
              curS.add(newIf)
              curS = newIf

          if isExpr:
            let branchBody = newNodeI(nkStmtList, branch[1].info)
            ctx.addExprAssgn(branchBody, branch[1], tmp)
            newBranch[1] = branchBody

        else:
          internalError(ctx.g.config, "lowerStmtListExpr(nkIf): " & $branch.kind)

      if isExpr: result.add(ctx.newTempVarAccess(tmp))

  of nkTryStmt, nkHiddenTryStmt:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        result = newNodeIT(nkStmtListExpr, n.info, n.typ)
        let tmp = ctx.newTempVar(n.typ, result)

        n[0] = ctx.convertExprBodyToAsgn(n[0], tmp)
        for i in 1..<n.len:
          let branch = n[i]
          case branch.kind
          of nkExceptBranch:
            if branch[0].kind == nkType:
              branch[1] = ctx.convertExprBodyToAsgn(branch[1], tmp)
            else:
              branch[0] = ctx.convertExprBodyToAsgn(branch[0], tmp)
          of nkFinally:
            discard
          else:
            internalError(ctx.g.config, "lowerStmtListExpr(nkTryStmt): " & $branch.kind)
        result.add(n)
        result.add(ctx.newTempVarAccess(tmp))

  of nkCaseStmt:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true

      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        result = newNodeIT(nkStmtListExpr, n.info, n.typ)
        let tmp = ctx.newTempVar(n.typ, result)

        if n[0].kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(n[0])
          result.add(st)
          n[0] = ex

        for i in 1..<n.len:
          let branch = n[i]
          case branch.kind
          of nkOfBranch:
            branch[^1] = ctx.convertExprBodyToAsgn(branch[^1], tmp)
          of nkElse:
            branch[0] = ctx.convertExprBodyToAsgn(branch[0], tmp)
          else:
            internalError(ctx.g.config, "lowerStmtListExpr(nkCaseStmt): " & $branch.kind)
        result.add(n)
        result.add(ctx.newTempVarAccess(tmp))
      elif n[0].kind == nkStmtListExpr:
        result = newNodeI(nkStmtList, n.info)
        let (st, ex) = exprToStmtList(n[0])
        result.add(st)
        n[0] = ex
        result.add(n)

  of nkCallKinds, nkChckRange, nkChckRangeF, nkChckRange64:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      else:
        result = newNodeI(nkStmtList, n.info)

      if n[0].kind == nkSym and n[0].sym.magic in {mAnd, mOr}: # `and`/`or` short cirquiting
        var cond = n[1]
        if cond.kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(cond)
          result.add(st)
          cond = ex

        let tmp = ctx.newTempVar(cond.typ, result, cond)
        # result.add(ctx.newTempVarAsgn(tmp, cond))

        var check = ctx.newTempVarAccess(tmp)
        if n[0].sym.magic == mOr:
          check = ctx.g.newNotCall(check)

        cond = n[2]
        let ifBody = newNodeI(nkStmtList, cond.info)
        if cond.kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(cond)
          ifBody.add(st)
          cond = ex
        ifBody.add(ctx.newTempVarAsgn(tmp, cond))

        let ifBranch = newTree(nkElifBranch, check, ifBody)
        let ifNode = newTree(nkIfStmt, ifBranch)
        result.add(ifNode)
        result.add(ctx.newTempVarAccess(tmp))
      else:
        for i in 0..<n.len:
          if n[i].kind == nkStmtListExpr:
            let (st, ex) = exprToStmtList(n[i])
            result.add(st)
            n[i] = ex

          if n[i].kind in nkCallKinds: # XXX: This should better be some sort of side effect tracking
            let tmp = ctx.newTempVar(n[i].typ, result, n[i])
            # result.add(ctx.newTempVarAsgn(tmp, n[i]))
            n[i] = ctx.newTempVarAccess(tmp)

        result.add(n)

  of nkVarSection, nkLetSection:
    result = newNodeI(nkStmtList, n.info)
    for c in n:
      let varSect = newNodeI(n.kind, n.info)
      varSect.add(c)
      var ns = false
      c[^1] = ctx.lowerStmtListExprs(c[^1], ns)
      if ns:
        needsSplit = true
        let (st, ex) = exprToStmtList(c[^1])
        result.add(st)
        c[^1] = ex
      for i in 0 .. c.len - 3:
        if c[i].kind == nkSym:
          let s = c[i].sym
          if sfForceLift in s.flags:
            ctx.captureVar(s)

      result.add(varSect)

  of nkDiscardStmt, nkReturnStmt, nkRaiseStmt:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      result = newNodeI(nkStmtList, n.info)
      let (st, ex) = exprToStmtList(n[0])
      result.add(st)
      n[0] = ex
      result.add(n)

  of nkCast, nkHiddenStdConv, nkHiddenSubConv, nkConv, nkObjDownConv,
      nkDerefExpr, nkHiddenDeref:
    var ns = false
    for i in ord(n.kind == nkCast)..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let (st, ex) = exprToStmtList(n[^1])
      result.add(st)
      n[^1] = ex
      result.add(n)

  of nkAsgn, nkFastAsgn, nkSinkAsgn:
    var ns = false
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      result = newNodeI(nkStmtList, n.info)
      if n[0].kind == nkStmtListExpr:
        let (st, ex) = exprToStmtList(n[0])
        result.add(st)
        n[0] = ex

      if n[1].kind == nkStmtListExpr:
        let (st, ex) = exprToStmtList(n[1])
        result.add(st)
        n[1] = ex

      result.add(n)

  of nkBracketExpr:
    var lhsNeedsSplit = false
    var rhsNeedsSplit = false
    n[0] = ctx.lowerStmtListExprs(n[0], lhsNeedsSplit)
    n[1] = ctx.lowerStmtListExprs(n[1], rhsNeedsSplit)
    if lhsNeedsSplit or rhsNeedsSplit:
      needsSplit = true
      result = newNodeI(nkStmtListExpr, n.info)
      if lhsNeedsSplit:
        let (st, ex) = exprToStmtList(n[0])
        result.add(st)
        n[0] = ex

      if rhsNeedsSplit:
        let (st, ex) = exprToStmtList(n[1])
        result.add(st)
        n[1] = ex
      result.add(n)

  of nkWhileStmt:
    var condNeedsSplit = false
    n[0] = ctx.lowerStmtListExprs(n[0], condNeedsSplit)
    var bodyNeedsSplit = false
    n[1] = ctx.lowerStmtListExprs(n[1], bodyNeedsSplit)

    if condNeedsSplit or bodyNeedsSplit:
      needsSplit = true

      if condNeedsSplit:
        let (st, ex) = exprToStmtList(n[0])
        let brk = newTree(nkBreakStmt, ctx.g.emptyNode)
        let branch = newTree(nkElifBranch, ctx.g.newNotCall(ex), brk)
        let check = newTree(nkIfStmt, branch)
        let newBody = newTree(nkStmtList, st, check, n[1])

        n[0] = ctx.g.boolLit(n[0].info, true)
        n[1] = newBody

  of nkDotExpr, nkCheckedFieldExpr:
    var ns = false
    n[0] = ctx.lowerStmtListExprs(n[0], ns)
    if ns:
      needsSplit = true
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let (st, ex) = exprToStmtList(n[0])
      result.add(st)
      n[0] = ex
      result.add(n)

  of nkBlockExpr:
    var ns = false
    n[1] = ctx.lowerStmtListExprs(n[1], ns)
    if ns:
      needsSplit = true
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let (st, ex) = exprToStmtList(n[1])
      n.transitionSonsKind(nkBlockStmt)
      n.typ() = nil
      n[1] = st
      result.add(n)
      result.add(ex)

  else:
    for i in 0..<n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], needsSplit)

proc newEndFinallyNode(ctx: var Ctx, info: TLineInfo): PNode =
  # Generate the following code:
  # if :finallyPath[FINALLY_LEVEL] == 0:
  #   if :curExc == nil:
  #     :state = -1
  #     return result = :tmpResult
  #   else:
  #     raise

  let cmpStateToZero = newTreeIT(nkCall,
                          info, ctx.g.getSysType(info, tyBool),
                          newSymNode(ctx.g.getSysMagic(info, "==", mEqI), info),
                          ctx.newFinallyPathAccess(ctx.curFinallyLevel, info),
                          ctx.g.newIntLit(info, 0))

  let excNilCmp = newTreeIT(nkCall,
                      info, ctx.g.getSysType(info, tyBool),
                      newSymNode(ctx.g.getSysMagic(info, "==", mEqRef), info),
                      ctx.newCurExcAccess(),
                      newNodeIT(nkNilLit, info, getSysType(ctx.g, info, tyNil)))

  let retStmt =
    block:
      let retValue = if ctx.fn.typ.returnType.isNil:
                   ctx.g.emptyNode
                 else:
                   newTree(nkFastAsgn,
                           newSymNode(getClosureIterResult(ctx.g, ctx.fn, ctx.idgen), info),
                           ctx.newTmpResultAccess())
      newTree(nkReturnStmt, retValue)

  # XXX: nfNoRewrite flag is also used for term rewriting, which should not intersect
  # with how it is used in closureiters transformation
  retStmt.flags.incl(nfNoRewrite)

  let ifBody = newTree(nkIfStmt,
                       newTree(nkElifBranch, excNilCmp, newTree(nkStmtList, ctx.newRestoreExternException(), retStmt)),
                       newTree(nkElse,
                           newTree(nkStmtList,
                                   newTreeI(nkRaiseStmt, info, ctx.g.emptyNode))))

  result = newTree(nkIfStmt,
                   newTreeI(nkElifBranch, info, cmpStateToZero, ifBody))


proc newJumpAlongFinallyChain(ctx: var Ctx, finallyChain: seq[PNode], info: TLineInfo): PNode =
  # The chain must contain labels of all the states we should go through,
  # where the first element is nearest finally, every following is parent finally,
  # and the last is the target state.
  # If len == 1, it only contains the target state.

  # Setup finally path with finallyChain[1 .. ^1], and jump to finallyChain[0]
  result = newNode(nkStmtList, info)
  for i in countdown(finallyChain.high, 1):
    result.add(ctx.newFinallyPathAssign(ctx.curFinallyLevel - i, finallyChain[i], info))
  result.add(newTreeI(nkGotoState, info, finallyChain[0]))

proc transformBreakStmt(ctx: var Ctx, n: PNode): PNode =
  # "Breaking" involves finding the corresponding target state in finallyPathStack,
  # setting finallyPath so that it chains to the target state and jumping to nearest finally.
  # If there are no finallies on the way, then jump to the target block right away

  # The target can be either a named block (breaking in unnamed blocks is forbidden)
  # or a while (if targetName is empty).
  # Let's find it in finallyTarget stack, and remember all finallies on the way to it.
  let targetName = if n[0].kind == nkSym: n[0].sym else: nil
  var finallyChain = newSeq[PNode]()

  var targetFound = false
  for i in countdown(ctx.finallyPathStack.high, 0):
    let b = ctx.finallyPathStack[i].n
    # echo "STACK ", i, " ", b.kind
    if b.kind == nkBlockStmt and targetName != nil and b[0].sym == targetName:
      finallyChain.add(ctx.finallyPathStack[i].label)
      targetFound = true
      break
    elif b.kind == nkWhileStmt and targetName == nil:
      finallyChain.add(ctx.finallyPathStack[i].label)
      targetFound = true
      break
    elif b.kind == nkFinally:
      finallyChain.add(ctx.finallyPathStack[i].label)

  if targetFound:# and finallyChain.len > 0:
    result = ctx.newJumpAlongFinallyChain(finallyChain, n.info)
  else:
    # Target is not in finally path means that it doesn't have yields (no state split),
    # so we don't have to transform this break.
    result = n

proc transformReturnStmt(ctx: var Ctx, n: PNode): PNode =
  # "Returning" involves jumping along all the current finally path.
  # The last finally should exit to state 0 which is a special case for last exit
  # (either return or propagating exception to the caller).
  # It is eccounted for in newEndFinallyNode.
  result = newNodeI(nkStmtList, n.info)

  # Returns prevent exception propagation
  result.add(ctx.nullifyCurExc)


  var finallyChain = newSeq[PNode]()

  for i in countdown(ctx.finallyPathStack.high, 0):
    let b = ctx.finallyPathStack[i].n
    # echo "STACK ", i, " ", b.kind
    if b.kind == nkFinally:
      finallyChain.add(ctx.finallyPathStack[i].label)

  if finallyChain.len > 0:
    # Add proc exit state
    finallyChain.add(ctx.g.newIntLit(n.info, 0))

    if n[0].kind != nkEmpty:
      let asgnTmpResult = newNodeI(nkAsgn, n.info)
      asgnTmpResult.add(ctx.newTmpResultAccess())
      let x = if n[0].kind in {nkAsgn, nkFastAsgn, nkSinkAsgn}: n[0][1] else: n[0]
      asgnTmpResult.add(x)
      result.add(asgnTmpResult)

    result.add(ctx.newJumpAlongFinallyChain(finallyChain, n.info))
  else:
    # There are no (split) finallies on the path, so we can return right away
    result.add(ctx.restoreExternExc)
    result.add(n)

proc transformBreaksAndReturns(ctx: var Ctx, n: PNode): PNode =
  result = n
  case n.kind
  of nkSkip: discard
  of nkBreakStmt: result = ctx.transformBreakStmt(n)
  # of nkContinueStmt: # By this point all relevant continues should be
  # lowered to breaks in transf.nim.
  of nkReturnStmt:
    if nfNoRewrite notin n.flags:
      result = ctx.transformReturnStmt(n)
  else:
    for i in 0..<n.len:
      n[i] = ctx.transformBreaksAndReturns(n[i])

proc transformClosureIteratorBody(ctx: var Ctx, n: PNode, gotoOut: PNode): PNode =
  result = n
  case n.kind
  of nkSkip: discard

  of nkStmtList, nkStmtListExpr:
    result = addGotoOut(result, gotoOut)
    for i in 0..<n.len:
      if n[i].hasYields:
        # Create a new split
        let label = ctx.newStateLabel()
        let go = newTreeI(nkGotoState, n[i].info, label)
        n[i] = ctx.transformClosureIteratorBody(n[i], go)

        let s = newNodeI(nkStmtList, n[i + 1].info)
        for j in i + 1..<n.len:
          s.add(n[j])

        n.sons.setLen(i + 1)
        discard ctx.newState(s, true, label)
        if ctx.transformClosureIteratorBody(s, gotoOut) != s:
          internalError(ctx.g.config, "transformClosureIteratorBody != s")
        break
      else:
        n[i] = ctx.transformBreaksAndReturns(n[i])

  of nkYieldStmt:
    result = addGotoOut(result, gotoOut)
    result = newTree(nkStmtList, ctx.restoreExternExc, result)

  of nkElse, nkElseExpr:
    result[0] = addGotoOut(result[0], gotoOut)
    result[0] = ctx.transformClosureIteratorBody(result[0], gotoOut)

  of nkElifBranch, nkElifExpr, nkOfBranch:
    result[^1] = addGotoOut(result[^1], gotoOut)
    result[^1] = ctx.transformClosureIteratorBody(result[^1], gotoOut)

  of nkIfStmt, nkCaseStmt:
    for i in 0..<n.len:
      n[i] = ctx.transformClosureIteratorBody(n[i], gotoOut)
    if n[^1].kind != nkElse:
      # We don't have an else branch, but every possible branch has to end with
      # gotoOut, so add else here.
      let elseBranch = newTree(nkElse, gotoOut)
      n.add(elseBranch)

  of nkWhileStmt:
    # while e:
    #   s
    # ->
    # BEGIN_STATE:
    #   if e:
    #     s
    #     goto BEGIN_STATE
    #   else:
    #     goto OUT

    # result = newNodeI(nkGotoState, n.info)

    let s = newNodeI(nkStmtList, n.info)
    let enterLabel = ctx.newState(s, false, nil)

    let ifNode = newNodeI(nkIfStmt, n.info)
    let elifBranch = newNodeI(nkElifBranch, n.info)
    elifBranch.add(n[0])
    let gotoBegin = newNodeI(nkGotoState, n.info)
    gotoBegin.add(enterLabel)
    result = gotoBegin

    var body = addGotoOut(n[1], gotoBegin)

    ctx.finallyPathStack.add(FinallyTarget(n: n, label: gotoOut[0]))
    body = ctx.transformClosureIteratorBody(body, gotoBegin)
    discard ctx.finallyPathStack.pop()

    elifBranch.add(body)
    ifNode.add(elifBranch)

    let elseBranch = newTree(nkElse, gotoOut)
    ifNode.add(elseBranch)
    s.add(ifNode)

  of nkBlockStmt:
    result[1] = addGotoOut(result[1], gotoOut)
    ctx.finallyPathStack.add(FinallyTarget(n: result, label: gotoOut[0]))
    result[1] = ctx.transformClosureIteratorBody(result[1], gotoOut)
    discard ctx.finallyPathStack.pop()

  of nkTryStmt, nkHiddenTryStmt:
    # See explanation above about how this works
    ctx.hasExceptions = true

    let tryLabel = ctx.newStateLabel()
    result = newNodeI(nkGotoState, n.info)
    result.add(tryLabel)
    var tryBody = toStmtList(n[0])

    var exceptBody = ctx.collectExceptState(n)
    var finallyBody = ctx.getFinallyNode(n)
    var exceptLabel, finallyLabel = ctx.g.emptyNode

    if exceptBody.kind != nkEmpty:
      exceptLabel = ctx.newStateLabel()

    if finallyBody.kind != nkEmpty:
      finallyBody = newTree(nkStmtList, finallyBody,
                            ctx.newEndFinallyNode(finallyBody.info))
      finallyLabel = ctx.newStateLabel()

    var tryOut = gotoOut
    if finallyBody.kind != nkEmpty:
      # Add finally path to try body
      # START:
      # finallyPath[level] = excHandlingState
      # END:
      # finallyPath[level] = gotoOut
      tryBody = newTree(nkStmtList,
                        ctx.newFinallyPathAssign(ctx.curFinallyLevel, ctx.curExcLandingState, tryBody.info),
                        tryBody,
                        ctx.newFinallyPathAssign(ctx.curFinallyLevel, gotoOut[0], tryBody.info))

      tryOut = newNodeI(nkGotoState, finallyBody.info)
      tryOut.add(finallyLabel)

    block: # Process the states
      let oldExcLandingState = ctx.curExcLandingState
      ctx.curExcLandingState = if exceptBody.kind != nkEmpty: exceptLabel
                             elif finallyBody.kind != nkEmpty: finallyLabel
                             else: oldExcLandingState

      discard ctx.newState(tryBody, false, tryLabel)

      if finallyBody.kind != nkEmpty:
        inc ctx.curFinallyLevel
        ctx.finallyPathStack.add(FinallyTarget(n: n[^1], label: finallyLabel))

      tryBody = ctx.transformClosureIteratorBody(tryBody, tryOut)

      if exceptBody.kind != nkEmpty:
        ctx.curExcLandingState = if finallyBody.kind != nkEmpty: finallyLabel
                                 else: oldExcLandingState
        discard ctx.newState(exceptBody, false, exceptLabel)

        let normalOut = if finallyBody.kind != nkEmpty: gotoOut else: nil
        exceptBody = ctx.addElseToExcept(exceptBody, normalOut)
        # echo "EXCEPT: ", renderTree(exceptBody)
        exceptBody = ctx.transformClosureIteratorBody(exceptBody, tryOut)

      ctx.curExcLandingState = oldExcLandingState

      if finallyBody.kind != nkEmpty:
        discard ctx.finallyPathStack.pop()
        discard ctx.newState(finallyBody, false, finallyLabel)
        let finallyExit = newTree(nkGotoState, ctx.newFinallyPathAccess(ctx.curFinallyLevel - 1, finallyBody.info))
        finallyBody = ctx.transformClosureIteratorBody(finallyBody, finallyExit)
        dec ctx.curFinallyLevel

  of nkGotoState, nkForStmt:
    internalError(ctx.g.config, "closure iter " & $n.kind)

  else:
    for i in 0..<n.len:
      n[i] = ctx.transformClosureIteratorBody(n[i], gotoOut)

proc stateFromGotoState(n: PNode): PNode =
  assert(n.kind == nkGotoState)
  result = n[0]

proc transformStateAssignments(ctx: var Ctx, n: PNode): PNode =
  # This transforms 3 patterns:
  ########################## 1
  # yield e
  # goto STATE
  # ->
  # :state = STATE
  # return e
  ########################## 2
  # goto STATE
  # ->
  # :state = STATE
  # break :stateLoop
  ########################## 3
  # return e
  # ->
  # :state = -1
  # return e
  result = n
  case n.kind
  of nkStmtList, nkStmtListExpr:
    if n.len != 0 and n[0].kind == nkYieldStmt:
      assert(n.len == 2)
      assert(n[1].kind == nkGotoState)

      result = newNodeI(nkStmtList, n.info)
      result.add(ctx.newStateAssgn(stateFromGotoState(n[1])))

      var retStmt = newNodeI(nkReturnStmt, n.info)
      if n[0][0].kind != nkEmpty:
        var a = newNodeI(nkAsgn, n[0][0].info)
        var retVal = n[0][0] #liftCapturedVars(n[0], owner, d, c)
        a.add newSymNode(getClosureIterResult(ctx.g, ctx.fn, ctx.idgen))
        a.add retVal
        retStmt.add(a)
      else:
        retStmt.add(ctx.g.emptyNode)

      result.add(retStmt)
    else:
      for i in 0..<n.len:
        n[i] = ctx.transformStateAssignments(n[i])

  of nkSkip:
    discard

  of nkReturnStmt:
    result = newTreeI(nkStmtList, n.info,
                      ctx.newStateAssgn(ctx.g.newIntLit(n.info, -1)),
                      n)

  of nkGotoState:
    result = newNodeI(nkStmtList, n.info)
    result.add(ctx.newStateAssgn(stateFromGotoState(n)))

    let breakState = newNodeI(nkBreakStmt, n.info)
    breakState.add(newSymNode(ctx.stateLoopLabel))
    result.add(breakState)

  else:
    for i in 0..<n.len:
      n[i] = ctx.transformStateAssignments(n[i])

proc createExceptionTable(ctx: var Ctx): PNode {.inline.} =
  let typ = ctx.g.newArrayType(ctx.g.newIntLit(ctx.fn.info, ctx.states.high),
                               ctx.g.getSysType(ctx.fn.info, tyInt16), ctx.idgen, ctx.fn)

  result = newNodeIT(nkBracket, ctx.fn.info, typ)

  for i in 0 .. ctx.states.high:
    result.add(ctx.states[i].excLandingState)

proc wrapIntoTryExcept(ctx: var Ctx, n: PNode): PNode {.inline.} =
  # Generates code:
  # var :tmp = nil
  # try:
  #   body
  # except:
  #   :state = exceptionTable[:state]
  #   :curExc = getCurrentException()
  # if :state == 0:
  #   closureIterSetExc(:externExc)
  #   raise
  #
  # pushCurrentException(:curExc)

  let info = ctx.fn.info
  let getCurExc = ctx.g.callCodegenProc("getCurrentException")
  let exceptBody = newTreeI(nkStmtList, info,
                            ctx.newStateAssgn(
                              newTreeIT(nkBracketExpr, info, ctx.g.getSysType(info, tyInt),
                                        ctx.createExceptionTable(),
                                        ctx.newStateAccess())),
                            newTreeI(nkFastAsgn, info, ctx.newCurExcAccess(), getCurExc))

  result = newTree(nkStmtList)
  result.add newTree(nkTryStmt,
                     newTree(nkStmtList, n),
                     newTree(nkExceptBranch, exceptBody))

  # if :state == 0:
  #   closureIterSetExc(:externExc)
  #   raise
  block:
    let boolTyp = ctx.g.getSysType(info, tyBool)
    let intTyp = ctx.g.getSysType(info, tyInt)
    let cond = newTreeIT(nkCall, info, boolTyp,
      ctx.g.getSysMagic(info, "==", mEqI).newSymNode(),
      ctx.newStateAccess(),
      newIntTypeNode(0, intTyp))

    let raiseStmt = newTree(nkRaiseStmt, ctx.newCurExcAccess())
    let ifBody = newTree(nkStmtList, ctx.newRestoreExternException(), raiseStmt)
    let ifBranch = newTree(nkElifBranch, cond, ifBody)
    let ifStmt = newTree(nkIfStmt, ifBranch)
    result.add(ifStmt)

  result.add newTree(nkCall, newSymNode(ctx.g.getCompilerProc("pushCurrentException")), ctx.newCurExcAccess())

proc wrapIntoStateLoop(ctx: var Ctx, n: PNode): PNode =
  # while true:
  #   block :stateLoop:
  #     local vars decl (if needed)
  #     body # Might get wrapped in try-except
  let loopBody = newNodeI(nkStmtList, n.info)
  result = newTree(nkWhileStmt, ctx.g.boolLit(n.info, true), loopBody)
  result.info = n.info

  let localVars = newNodeI(nkStmtList, n.info)

  let blockStmt = newNodeI(nkBlockStmt, n.info)
  blockStmt.add(newSymNode(ctx.stateLoopLabel))

  var blockBody = newTree(nkStmtList, localVars, n)
  if ctx.hasExceptions:
    blockBody = ctx.wrapIntoTryExcept(blockBody)

  blockStmt.add(blockBody)
  loopBody.add(blockStmt)

  if ctx.hasExceptions:
    # Since we have yields in tries, we must switch current exception
    # between the iter and "outer world"
    # var :externExc = getCurrentException()
    # closureIterSetExc(:curExc)
    let getCurExc = ctx.g.callCodegenProc("getCurrentException")
    discard ctx.newExternExcAccess()
    let setCurExc = ctx.g.callCodegenProc("closureIterSetExc", n.info, ctx.newCurExcAccess())
    result = newTreeI(nkStmtList, n.info,
                      ctx.newTempVarDef(ctx.externExcSym, getCurExc),
                      setCurExc,
                      result)

proc countStateOccurences(ctx: var Ctx, n: PNode, stateOccurences: var openArray[int]) =
  ## Find all nkGotoState(stateIdx) nodes that do not follow nkYield.
  ## For every such node increment stateOccurences[stateIdx]
  for i, c in n:
    if c.kind == nkGotoState and c[0].kind == nkIntLit and (i > 0 and n[i - 1].kind != nkYieldStmt):
      let stateIdx = c[0].intVal
      if stateIdx >= 0:
        inc stateOccurences[stateIdx]
    elif c.kind == nkIntLit:
      let idx = c.intVal
      if idx >= 0 and idx < ctx.states.len and ctx.states[idx].label == c:
        ctx.states[idx].inlinable = false
    else:
      ctx.countStateOccurences(c, stateOccurences)

proc replaceDeletedStates(ctx: var Ctx, n: PNode): PNode =
  result = n
  if n.kind == nkIntLit:
    let idx = n.intVal
    if idx >= 0 and idx < ctx.states.len and ctx.states[idx].label == n and ctx.states[idx].deletable:
      let gt = ctx.replaceDeletedStates(skipStmtList(ctx.states[idx].body))
      assert(gt.kind == nkGotoState)
      result = gt[0]
  else:
    for i in 0 ..< n.safeLen:
      n[i] = ctx.replaceDeletedStates(n[i])

proc replaceInlinedStates(ctx: var Ctx, n: PNode): PNode =
  ## Find all nkGotoState(stateIdx) nodes that do not follow nkYield.
  ## For every such node increment stateOccurences[stateIdx]
  result = n
  for i in 0 ..< n.safeLen:
    let c = n[i]
    if c.kind == nkGotoState and c[0].kind == nkIntLit and (i > 0 and n[i - 1].kind != nkYieldStmt):
      let stateIdx = c[0].intVal
      if stateIdx >= 0:
        if ctx.states[stateIdx].inlinable:
          n[i] = ctx.states[stateIdx].body
    else:
      n[i] = ctx.replaceInlinedStates(c)

proc optimizeStates(ctx: var Ctx) =
  # Optimize empty states away and inline inlinable states
  # This step requires that unique indexes are already assigned to state labels

  # Find empty states (those consisting only of gotoState node) and mark
  # them deletable.
  for i in 0 .. ctx.states.high:
    let s = ctx.states[i]
    let body = skipStmtList(s.body)
    if body.kind == nkGotoState and body[0].kind == nkIntLit and body[0].intVal >= 0:
      ctx.states[i].deletable = true

  # Replace deletable state labels to labels of respective non-empty states
  for i in 0 .. ctx.states.high:
    ctx.states[i].body = ctx.replaceDeletedStates(ctx.states[i].body)
    ctx.states[i].excLandingState = ctx.replaceDeletedStates(ctx.states[i].excLandingState)

  # Remove deletable states
  var i = 0
  while i < ctx.states.len:
    if ctx.states[i].deletable:
      ctx.states.delete(i)
    else:
      inc i

  # Reassign state label indexes
  for i in 0 .. ctx.states.high:
    ctx.states[i].label.intVal = i

  # Count state occurences
  var stateOccurences = newSeq[int](ctx.states.len)
  for s in ctx.states:
    ctx.countStateOccurences(s.body, stateOccurences)

  # If there are inlinable states refered not exactly once, prevent them from inlining
  for i, o in stateOccurences:
    if o != 1:
      ctx.states[i].inlinable = false

  # echo "States to optimize:"
  # for i, s in ctx.states:
  #   if s.deletable: echo i, ": delete"
  #   elif s.inlinable: echo i, ": inline"

  # Inline states
  for i in 0 .. ctx.states.high:
    ctx.states[i].body = ctx.replaceInlinedStates(ctx.states[i].body)

  # Remove inlined states
  i = 0
  while i < ctx.states.len:
    if ctx.states[i].inlinable:
      ctx.states.delete(i)
    else:
      inc i

  # Reassign state label indexes one last time
  for i in 0 .. ctx.states.high:
    ctx.states[i].label.intVal = i

proc detectCapturedVars(c: var Ctx, n: PNode, stateIdx: int) =
  case n.kind
  of nkSym:
    let s = n.sym
    if s.kind in {skResult, skVar, skLet, skForVar, skTemp} and sfGlobal notin s.flags and s.owner == c.fn and s != c.externExcSym:
      let vs = c.varStates.getOrDefault(s.itemId, localNotSeen)
      if vs == localNotSeen: # First seing this variable
        c.varStates[s.itemId] = stateIdx
      elif vs == localRequiresLifting:
        discard # Sym already marked
      elif vs != stateIdx:
        c.captureVar(s)
  of nkReturnStmt:
    if n[0].kind in {nkAsgn, nkFastAsgn, nkSinkAsgn}:
      # we have a `result = result` expression produced by the closure
      # transform, let's not touch the LHS in order to make the lifting pass
      # correct when `result` is lifted
      detectCapturedVars(c, n[0][1], stateIdx)
    else:
      detectCapturedVars(c, n[0], stateIdx)
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit,
     nkTemplateDef, nkTypeSection, nkProcDef, nkMethodDef,
     nkConverterDef, nkMacroDef, nkFuncDef, nkCommentStmt,
     nkTypeOfExpr, nkMixinStmt, nkBindStmt:
    discard
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      detectCapturedVars(c, n[namePos], stateIdx)
  else:
    for i in 0 ..< n.safeLen:
      detectCapturedVars(c, n[i], stateIdx)

proc detectCapturedVars(c: var Ctx) =
  for i, s in c.states:
    detectCapturedVars(c, s.body, i)

proc liftLocals(c: var Ctx, n: PNode): PNode =
  result = n
  case n.kind
  of nkSym:
    let s = n.sym
    if c.varStates.getOrDefault(s.itemId) == localRequiresLifting:
      # lift
      let e = getEnvParam(c.fn)
      let field = getFieldFromObj(e.typ.elementType, s)
      assert(field != nil)
      result = rawIndirectAccess(newSymNode(e), field, n.info)
    # elif c.varStates.getOrDefault(s.itemId, localNotSeen) != localNotSeen:
    #   echo "Not lifting ", s.name.s

  of nkReturnStmt:
    if n[0].kind in {nkAsgn, nkFastAsgn, nkSinkAsgn}:
      # we have a `result = result` expression produced by the closure
      # transform, let's not touch the LHS in order to make the lifting pass
      # correct when `result` is lifted
      n[0][1] = liftLocals(c, n[0][1])
    else:
      n[0] = liftLocals(c, n[0])
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit,
     nkTemplateDef, nkTypeSection, nkProcDef, nkMethodDef,
     nkConverterDef, nkMacroDef, nkFuncDef, nkCommentStmt,
     nkTypeOfExpr, nkMixinStmt, nkBindStmt,
     nkLambdaKinds, nkIteratorDef:
    discard
  else:
    for i in 0 ..< n.safeLen:
      n[i] = liftLocals(c, n[i])

proc transformClosureIterator*(g: ModuleGraph; idgen: IdGenerator; fn: PSym, n: PNode): PNode =
  var ctx = Ctx(g: g, fn: fn, idgen: idgen)

  # The transformation should always happen after at least partial lambdalifting
  # is performed, so that the closure iter environment is always created upfront.
  doAssert(getEnvParam(fn) != nil, "Env param not created before iter transformation")

  ctx.curExcLandingState = ctx.newStateLabel()
  ctx.stateLoopLabel = newSym(skLabel, getIdent(ctx.g.cache, ":stateLoop"), idgen, fn, fn.info)


  ctx.nullifyCurExc = newTree(nkStmtList)
  ctx.restoreExternExc = newTree(nkStmtList)

  var n = n.toStmtList
  # echo "transformed into ", n

  discard ctx.newState(n, false, nil)

  let gotoOut = newTree(nkGotoState, g.newIntLit(n.info, -1))

  var ns = false
  n = ctx.lowerStmtListExprs(n, ns)
  # echo "LOWERED: ", renderTree(n)

  if n.hasYieldsInExpressions():
    internalError(ctx.g.config, n.info, "yield in expr not lowered")

  # Splitting transformation
  discard ctx.transformClosureIteratorBody(n, gotoOut)

  if ctx.hasExceptions:
    ctx.nullifyCurExc.add(ctx.newNullifyCurExc(fn.info))
    ctx.restoreExternExc.add(ctx.newRestoreExternException())

  # Assign state label indexes
  for i in 0 .. ctx.states.high:
    ctx.states[i].label.intVal = i

  ctx.optimizeStates()

  let caseDispatcher = newTreeI(nkCaseStmt, n.info,
      ctx.newStateAccess())

  # Lamdalifting will not touch our locals, it is our responsibility to lift those that
  # need it.
  detectCapturedVars(ctx)

  for s in ctx.states:
    let body = ctx.transformStateAssignments(s.body)
    caseDispatcher.add newTreeI(nkOfBranch, body.info, s.label, body)

  caseDispatcher.add newTreeI(nkElse, n.info,
                              newTree(nkStmtList, ctx.restoreExternExc,
                                      newTreeI(nkReturnStmt, n.info, g.emptyNode)))

  result = wrapIntoStateLoop(ctx, caseDispatcher)
  result = liftLocals(ctx, result)

  when false:
    echo "TRANSFORM TO STATES:"
    echo renderTree(result)

    # echo "exception table:"
    # for i, s in ctx.states:
    #   echo i, " -> ", s.excLandingState

    # echo "ENV: ", renderTree(getEnvParam(fn).typ.elementType.n)
