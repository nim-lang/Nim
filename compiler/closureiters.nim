#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
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
#  STATE0:
#    if a > 0:
#      echo "hi"
#      :state = 1 # Next state
#      return a # yield
#    else:
#      :state = 2 # Next state
#      break :stateLoop # Proceed to the next state
#  STATE1:
#    dec a
#    :state = 0 # Next state
#    break :stateLoop # Proceed to the next state
#  STATE2:
#    :state = -1 # End of execution

# The transformation should play well with lambdalifting, however depending
# on situation, it can be called either before or after lambdalifting
# transformation. As such we behave slightly differently, when accessing
# iterator state, or using temp variables. If lambdalifting did not happen,
# we just create local variables, so that they will be lifted further on.
# Otherwise, we utilize existing env, created by lambdalifting.

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
#    `abs(exceptionTable[i])` is a state idx to which we should jump from state
#    `i` should exception be raised in state `i`. For all states in `try` block
#    the target state is `except` block. For all states in `except` block
#    the target state is `finally` block. For all other states there is no
#    target state (0, as the first block can never be neither except nor finally).
#    `exceptionTable[i]` is < 0 if `abs(exceptionTable[i])` is except block,
#    and > 0, for finally block.
#  - local variable :curExc is created
#  - the iter body is wrapped into a
#      try:
#       closureIterSetupExc(:curExc)
#       ...body...
#      catch:
#        :state = exceptionTable[:state]
#        if :state == 0: raise # No state that could handle exception
#        :unrollFinally = :state > 0 # Target state is finally
#        if :state < 0:
#           :state = -:state
#        :curExc = getCurrentException()
#
# nkReturnStmt within a try/except/finally now has to behave differently as we
# want the nearest finally block to be executed before the return, thus it is
# transformed to:
#  :tmpResult = returnValue (if return doesn't have a value, this is skipped)
#  :unrollFinally = true
#  goto nearestFinally (or -1 if not exists)
#
# Every finally block calls closureIterEndFinally() upon its successful
# completion.
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
#
# Is transformed to (yields are left in place for example simplicity,
#    in reality the code is subdivided even more, as described above):
#
# STATE0: # Try
#   yield 0
#   raise ...
#   :state = 2 # What would happen should we not raise
#   break :stateLoop
# STATE1: # Except
#   yield 1
#   :tmpResult = 3           # Return
#   :unrollFinally = true # Return
#   :state = 2 # Goto Finally
#   break :stateLoop
#   :state = 2 # What would happen should we not return
#   break :stateLoop
# STATE2: # Finally
#   yield 2
#   if :unrollFinally: # This node is created by `newEndFinallyNode`
#     if :curExc.isNil:
#       return :tmpResult
#     else:
#       raise
#   state = -1 # Goto next state. In this case we just exit
#   break :stateLoop

import
  intsets, strutils, options, ast, astalgo, trees, treetab, msgs, os, options,
  idents, renderer, types, magicsys, rodread, lowerings, tables, sequtils,
  lambdalifting

type
  Ctx = object
    fn: PSym
    stateVarSym: PSym # :state variable. nil if env already introduced by lambdalifting
    tmpResultSym: PSym # Used when we return, but finally has to interfere
    unrollFinallySym: PSym # Indicates that we're unrolling finally states (either exception happened or premature return)
    curExcSym: PSym # Current exception

    states: seq[PNode] # The resulting states. Every state is an nkState node.
    blockLevel: int # Temp used to transform break and continue stmts
    stateLoopLabel: PSym # Label to break on, when jumping between states.
    exitStateIdx: int # index of the last state
    tempVarId: int # unique name counter
    tempVars: PNode # Temp var decls, nkVarSection
    exceptionTable: seq[int] # For state `i` jump to state `exceptionTable[i]` if exception is raised
    hasExceptions: bool # Does closure have yield in try?
    curExcHandlingState: int # Negative for except, positive for finally
    nearestFinally: int # Index of the nearest finally block. For try/except it
                    # is their finally. For finally it is parent finally. Otherwise -1

proc newStateAccess(ctx: var Ctx): PNode =
  if ctx.stateVarSym.isNil:
    result = rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)), getStateField(ctx.fn), ctx.fn.info)
  else:
    result = newSymNode(ctx.stateVarSym)

proc newStateAssgn(ctx: var Ctx, toValue: PNode): PNode =
  # Creates state assignment:
  #   :state = toValue
  result = newNode(nkAsgn)
  result.add(ctx.newStateAccess())
  result.add(toValue)

proc newStateAssgn(ctx: var Ctx, stateNo: int = -2): PNode =
  # Creates state assignment:
  #   :state = stateNo
  ctx.newStateAssgn(newIntTypeNode(nkIntLit, stateNo, getSysType(tyInt)))

proc newEnvVar(ctx: var Ctx, name: string, typ: PType): PSym =
  result = newSym(skVar, getIdent(name), ctx.fn, ctx.fn.info)
  result.typ = typ
  assert(not typ.isNil)

  if not ctx.stateVarSym.isNil:
    # We haven't gone through labmda lifting yet, so just create a local var,
    # it will be lifted later
    if ctx.tempVars.isNil:
      ctx.tempVars = newNode(nkVarSection)
      addVar(ctx.tempVars, newSymNode(result))
  else:
    let envParam = getEnvParam(ctx.fn)
    # let obj = envParam.typ.lastSon
    result = addUniqueField(envParam.typ.lastSon, result)

proc newEnvVarAccess(ctx: Ctx, s: PSym): PNode =
  if ctx.stateVarSym.isNil:
    result = rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)), s, ctx.fn.info)
  else:
    result = newSymNode(s)

proc newTmpResultAccess(ctx: var Ctx): PNode =
  if ctx.tmpResultSym.isNil:
    ctx.tmpResultSym = ctx.newEnvVar(":tmpResult", ctx.fn.typ[0])
  ctx.newEnvVarAccess(ctx.tmpResultSym)

proc newUnrollFinallyAccess(ctx: var Ctx): PNode =
  if ctx.unrollFinallySym.isNil:
    ctx.unrollFinallySym = ctx.newEnvVar(":unrollFinally", getSysType(tyBool))
  ctx.newEnvVarAccess(ctx.unrollFinallySym)

proc newCurExcAccess(ctx: var Ctx): PNode =
  if ctx.curExcSym.isNil:
    ctx.curExcSym = ctx.newEnvVar(":curExc", callCodegenProc("getCurrentException", emptyNode).typ)
  ctx.newEnvVarAccess(ctx.curExcSym)

proc setStateInAssgn(stateAssgn: PNode, stateNo: int) =
  assert stateAssgn.kind == nkAsgn
  assert stateAssgn[1].kind == nkIntLit
  stateAssgn[1].intVal = stateNo

proc newState(ctx: var Ctx, n, gotoOut: PNode): int =
  # Creates a new state, adds it to the context fills out `gotoOut` so that it
  # will goto this state.
  # Returns index of the newly created state

  result = ctx.states.len
  let resLit = newIntLit(result)
  let s = newNodeI(nkState, n.info)
  s.add(resLit)
  s.add(n)
  ctx.states.add(s)
  ctx.exceptionTable.add(ctx.curExcHandlingState)

  if not gotoOut.isNil:
    assert(gotoOut.len == 0)
    gotoOut.add(newIntLit(result))

proc toStmtList(n: PNode): PNode =
  result = n
  if result.kind notin {nkStmtList, nkStmtListExpr}:
    result = newNodeI(nkStmtList, n.info)
    result.add(n)

proc addGotoOut(n: PNode, gotoOut: PNode): PNode =
  # Make sure `n` is a stmtlist, and ends with `gotoOut`
  result = toStmtList(n)
  if result.len != 0 and result.sons[^1].kind != nkGotoState:
    result.add(gotoOut)

proc newTempVar(ctx: var Ctx, typ: PType): PSym =
  result = ctx.newEnvVar(":tmpSlLower" & $ctx.tempVarId, typ)
  inc ctx.tempVarId

proc hasYields(n: PNode): bool =
  # TODO: This is very inefficient. It traverses the node, looking for nkYieldStmt.
  case n.kind
  of nkYieldStmt:
    result = true
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  else:
    for c in n:
      if c.hasYields:
        result = true
        break

proc transformBreaksAndContinuesInWhile(ctx: var Ctx, n: PNode, before, after: PNode): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkWhileStmt: discard # Do not recurse into nested whiles
  of nkContinueStmt:
    result = before
  of nkBlockStmt:
    inc ctx.blockLevel
    result[1] = ctx.transformBreaksAndContinuesInWhile(result[1], before, after)
    dec ctx.blockLevel
  of nkBreakStmt:
    if ctx.blockLevel == 0:
      result = after
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.transformBreaksAndContinuesInWhile(n[i], before, after)

proc transformBreaksInBlock(ctx: var Ctx, n: PNode, label, after: PNode): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkBlockStmt, nkWhileStmt:
    inc ctx.blockLevel
    result[1] = ctx.transformBreaksInBlock(result[1], label, after)
    dec ctx.blockLevel
  of nkBreakStmt:
    if n[0].kind == nkEmpty:
      if ctx.blockLevel == 0:
        result = after
    else:
      if label.kind == nkSym and n[0].sym == label.sym:
        result = after
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.transformBreaksInBlock(n[i], label, after)

proc newNullifyCurExc(ctx: var Ctx): PNode =
  # :curEcx = nil
  result = newNode(nkAsgn)
  let curExc = ctx.newCurExcAccess()
  result.add(curExc)

  let nilnode = newNode(nkNilLit)
  nilnode.typ = curExc.typ
  result.add(nilnode)

proc collectExceptState(ctx: var Ctx, n: PNode): PNode =
  var ifStmt = newNode(nkIfStmt)
  for c in n:
    if c.kind == nkExceptBranch:
      var ifBranch: PNode
      var branchBody: PNode

      if c[0].kind == nkType:
        assert(c.len == 2)
        ifBranch = newNode(nkElifBranch)
        let expression = newNodeI(nkCall, n.info)
        expression.add(newSymNode(getSysMagic("of", mOf)))
        expression.add(callCodegenProc("getCurrentException", emptyNode))
        expression.add(c[0])
        expression.typ = getSysType(tyBool)
        ifBranch.add(expression)
        branchBody = c[1]
      else:
        assert(c.len == 1)
        if ifStmt.len == 0:
          ifStmt = newNode(nkStmtList)
          ifBranch = newNode(nkStmtList)
        else:
          ifBranch = newNode(nkElse)
        branchBody = c[0]

      ifBranch.add(branchBody)
      ifStmt.add(ifBranch)

  if ifStmt.len != 0:
    result = newNode(nkStmtList)
    result.add(ctx.newNullifyCurExc())
    result.add(ifStmt)
  else:
    result = emptyNode

proc addElseToExcept(ctx: var Ctx, n: PNode) =
  if n.kind == nkStmtList and n[1].kind == nkIfStmt and n[1][^1].kind != nkElse:
    # Not all cases are covered
    let elseBranch = newNode(nkElse)
    let branchBody = newNode(nkStmtList)

    block: # :unrollFinally = true
      let asgn = newNode(nkAsgn)
      asgn.add(ctx.newUnrollFinallyAccess())
      asgn.add(newIntTypeNode(nkIntLit, 1, getSysType(tyBool)))
      branchBody.add(asgn)

    block: # :curExc = getCurrentException()
      let asgn = newNode(nkAsgn)
      asgn.add(ctx.newCurExcAccess)
      asgn.add(callCodegenProc("getCurrentException", emptyNode))
      branchBody.add(asgn)

    block: # goto nearestFinally
      let goto = newNode(nkGotoState)
      goto.add(newIntLit(ctx.nearestFinally))
      branchBody.add(goto)

    elseBranch.add(branchBody)
    n[1].add(elseBranch)

proc getFinallyNode(n: PNode): PNode =
  result = n[^1]
  if result.kind == nkFinally:
    result = result[0]
  else:
    result = emptyNode

proc hasYieldsInExpressions(n: PNode): bool =
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkStmtListExpr:
    if isEmptyType(n.typ):
      for c in n:
        if c.hasYieldsInExpressions:
          return true
    else:
      result = n.hasYields
  else:
    for c in n:
      if c.hasYieldsInExpressions:
        return true

proc exprToStmtList(n: PNode): tuple[s, res: PNode] =
  assert(n.kind == nkStmtListExpr)

  var parent = n
  var lastSon = n[^1]

  while lastSon.kind == nkStmtListExpr:
    parent = lastSon
    lastSon = lastSon[^1]

  result.s = newNodeI(nkStmtList, n.info)
  result.s.sons = parent.sons
  result.s.sons.setLen(result.s.sons.len - 1) # delete last son
  result.res = lastSon

proc newEnvVarAsgn(ctx: Ctx, s: PSym, v: PNode): PNode =
  result = newNode(nkFastAsgn)
  result.add(ctx.newEnvVarAccess(s))
  result.add(v)

proc addExprAssgn(ctx: Ctx, output, input: PNode, sym: PSym) =
  if input.kind == nkStmtListExpr:
    let (st, res) = exprToStmtList(input)
    output.add(st)
    output.add(ctx.newEnvVarAsgn(sym, res))
  else:
    output.add(ctx.newEnvVarAsgn(sym, input))

proc convertExprBodyToAsgn(ctx: Ctx, exprBody: PNode, res: PSym): PNode =
  result = newNode(nkStmtList)
  ctx.addExprAssgn(result, exprBody, res)

proc newNotCall(e: PNode): PNode =
  result = newNode(nkCall)
  result.add(newSymNode(getSysMagic("not", mNot)))
  result.add(e)
  result.typ = getSysType(tyBool)

proc lowerStmtListExprs(ctx: var Ctx, n: PNode, needsSplit: var bool): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard

  of nkYieldStmt:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      assert(n[0].kind == nkStmtListExpr)
      result = newNodeI(nkStmtList, n.info)
      let (st, ex) = exprToStmtList(n[0])
      result.add(st)
      n[0] = ex
      result.add(n)

    needsSplit = true

  of nkPar, nkObjConstr, nkTupleConstr, nkBracket, nkArgList:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true

      result = newNodeI(nkStmtListExpr, n.info)
      if n.typ.isNil: internalError("lowerStmtListExprs: constr typ.isNil")
      result.typ = n.typ

      for i in 0 ..< n.len:
        if n[i].kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(n[i])
          result.add(st)
          n[i] = ex
      result.add(n)

  of nkIfStmt, nkIfExpr:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      var tmp: PSym
      var s: PNode
      let isExpr = not isEmptyType(n.typ)
      if isExpr:
        tmp = ctx.newTempVar(n.typ)
        result = newNode(nkStmtListExpr)
        result.typ = n.typ
      else:
        result = newNode(nkStmtList)

      var curS = result

      for branch in n:
        case branch.kind
        of nkElseExpr, nkElse:
          if isExpr:
            var newBranch = newNodeI(nkElse, branch.info)
            let branchBody = newNode(nkStmtList)
            ctx.addExprAssgn(branchBody, branch[0], tmp)
            newBranch.add(branchBody)
            curS.add(newBranch)
          else:
            curS.add(branch)

        of nkElifExpr, nkElifBranch:
          var newBranch: PNode
          if branch[0].kind == nkStmtListExpr:
            let elseBody = newNode(nkStmtList)

            let (st, res) = exprToStmtList(branch[0])
            elseBody.add(st)

            newBranch = newNodeI(nkElifBranch, branch.info)
            newBranch.add(res)
            newBranch.add(branch[1])

            let newIf = newNodeI(nkIfStmt, branch.info)
            newIf.add(newBranch)
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
              let newIf = newNodeI(nkIfStmt, branch.info)
              newIf.add(newBranch)
              curS.add(newIf)
              curS = newIf

          if isExpr:
            let branchBody = newNode(nkStmtList)
            ctx.addExprAssgn(branchBody, branch[1], tmp)
            newBranch[1] = branchBody

        else:
          internalError("lowerStmtListExpr(nkIf): " & $branch.kind)

      if isExpr: result.add(ctx.newEnvVarAccess(tmp))

  of nkTryStmt:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        result = newNodeI(nkStmtListExpr, n.info)
        result.typ = n.typ
        let tmp = ctx.newTempVar(n.typ)

        n[0] = ctx.convertExprBodyToAsgn(n[0], tmp)
        for i in 1 ..< n.len:
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
            internalError("lowerStmtListExpr(nkTryStmt): " & $branch.kind)
        result.add(n)
        result.add(ctx.newEnvVarAccess(tmp))

  of nkCaseStmt:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true

      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        let tmp = ctx.newTempVar(n.typ)
        result = newNodeI(nkStmtListExpr, n.info)
        result.typ = n.typ

        if n[0].kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(n[0])
          result.add(st)
          n[0] = ex

        for i in 1 ..< n.len:
          let branch = n[i]
          case branch.kind
          of nkOfBranch:
            branch[1] = ctx.convertExprBodyToAsgn(branch[1], tmp)
          of nkElse:
            branch[0] = ctx.convertExprBodyToAsgn(branch[0], tmp)
          else:
            internalError("lowerStmtListExpr(nkCaseStmt): " & $branch.kind)
        result.add(n)
        result.add(ctx.newEnvVarAccess(tmp))

  of nkCallKinds:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      let isExpr = not isEmptyType(n.typ)

      if isExpr:
        result = newNodeI(nkStmtListExpr, n.info)
        result.typ = n.typ
      else:
        result = newNode(nkStmtList, n.info)

      if n[0].kind == nkSym and n[0].sym.magic in {mAnd, mOr}: # `and`/`or` short cirquiting
        var cond = n[1]
        if cond.kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(cond)
          result.add(st)
          cond = ex

        let tmp = ctx.newTempVar(cond.typ)
        result.add(ctx.newEnvVarAsgn(tmp, cond))

        let ifNode = newNode(nkIfStmt)
        let ifBranch = newNode(nkElifBranch)

        var check = ctx.newEnvVarAccess(tmp)
        if n[0].sym.magic == mOr:
          check = newNotCall(check)
        ifBranch.add(check)

        cond = n[2]
        let ifBody = newNode(nkStmtList)
        if cond.kind == nkStmtListExpr:
          let (st, ex) = exprToStmtList(cond)
          ifBody.add(st)
          cond = ex
        ifBody.add(ctx.newEnvVarAsgn(tmp, cond))
        ifBranch.add(ifBody)
        ifNode.add(ifBranch)
        result.add(ifNode)
        result.add(ctx.newEnvVarAccess(tmp))
      else:
        for i in 0 ..< n.len:
          if n[i].kind == nkStmtListExpr:
            let (st, ex) = exprToStmtList(n[i])
            result.add(st)
            n[i] = ex

          if n[i].kind in nkCallKinds: # XXX: This should better be some sort of side effect tracking
            let tmp = ctx.newTempVar(n[i].typ)
            result.add(ctx.newEnvVarAsgn(tmp, n[i]))
            n[i] = ctx.newEnvVarAccess(tmp)

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
        assert(c[^1].kind == nkStmtListExpr)
        let (st, ex) = exprToStmtList(c[^1])
        result.add(st)
        c[^1] = ex
      result.add(varSect)

  of nkDiscardStmt, nkReturnStmt, nkRaiseStmt:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      result = newNodeI(nkStmtList, n.info)
      let (st, ex) = exprToStmtList(n[0])
      result.add(st)
      n[0] = ex
      result.add(n)

  of nkCast:
    var ns = false
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], ns)

    if ns:
      needsSplit = true
      result = newNodeI(nkStmtListExpr, n.info)
      result.typ = n.typ
      let (st, ex) = exprToStmtList(n[1])
      result.add(st)
      n[1] = ex
      result.add(n)

  of nkAsgn, nkFastAsgn:
    var ns = false
    for i in 0 ..< n.len:
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

  of nkWhileStmt:
    var ns = false

    var condNeedsSplit = false
    n[0] = ctx.lowerStmtListExprs(n[0], condNeedsSplit)
    var bodyNeedsSplit = false
    n[1] = ctx.lowerStmtListExprs(n[1], bodyNeedsSplit)

    if condNeedsSplit or bodyNeedsSplit:
      needsSplit = true

      if condNeedsSplit:
        let newBody = newNode(nkStmtList)

        let (st, ex) = exprToStmtList(n[0])
        newBody.add(st)
        let check = newNode(nkIfStmt)
        let branch = newNode(nkElifBranch)
        branch.add(newNotCall(ex))
        let brk = newNode(nkBreakStmt)
        brk.add(emptyNode)
        branch.add(brk)
        check.add(branch)
        newBody.add(check)
        newBody.add(n[1])

        n[0] = newSymNode(getSysSym("true"))
        n[1] = newBody
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExprs(n[i], needsSplit)

proc newEndFinallyNode(ctx: var Ctx): PNode =
  # Generate the following code:
  #   if :unrollFinally:
  #       if :curExc.isNil:
  #         return :tmpResult
  #       else:
  #         raise

  result = newNode(nkIfStmt)

  let elifBranch = newNode(nkElifBranch)
  elifBranch.add(ctx.newUnrollFinallyAccess())
  result.add(elifBranch)

  let ifBody = newNode(nkIfStmt)
  let branch = newNode(nkElifBranch)

  let cmp = newNode(nkCall)
  cmp.add(getSysMagic("==", mEqRef).newSymNode)
  let curExc = ctx.newCurExcAccess()
  let nilnode = newNode(nkNilLit)
  nilnode.typ = curExc.typ
  cmp.add(curExc)
  cmp.add(nilnode)
  cmp.typ = getSysType(tyBool)
  branch.add(cmp)

  let retStmt = newNode(nkReturnStmt)
  let asgn = newNode(nkFastAsgn)
  addSon(asgn, newSymNode(getClosureIterResult(ctx.fn)))
  addSon(asgn, ctx.newTmpResultAccess())
  retStmt.add(asgn)
  branch.add(retStmt)

  let elseBranch = newNode(nkElse)
  let raiseStmt = newNode(nkRaiseStmt)

  # The C++ backend requires `getCurrentException` here.
  raiseStmt.add(callCodegenProc("getCurrentException", emptyNode))
  elseBranch.add(raiseStmt)

  ifBody.add(branch)
  ifBody.add(elseBranch)

  elifBranch.add(ifBody)

proc transformReturnsInTry(ctx: var Ctx, n: PNode): PNode =
  result = n
  # TODO: This is very inefficient. It traverses the node, looking for nkYieldStmt.
  case n.kind
  of nkReturnStmt:
    # We're somewhere in try, transform to finally unrolling
    assert(ctx.nearestFinally != 0)

    result = newNodeI(nkStmtList, n.info)

    block: # :unrollFinally = true
      let asgn = newNodeI(nkAsgn, n.info)
      asgn.add(ctx.newUnrollFinallyAccess())
      asgn.add(newIntTypeNode(nkIntLit, 1, getSysType(tyBool)))
      result.add(asgn)

    if n[0].kind != nkEmpty:
      let asgnTmpResult = newNodeI(nkAsgn, n.info)
      asgnTmpResult.add(ctx.newTmpResultAccess())
      asgnTmpResult.add(n[0])
      result.add(asgnTmpResult)

    result.add(ctx.newNullifyCurExc())

    let goto = newNodeI(nkGotoState, n.info)
    goto.add(newIntLit(ctx.nearestFinally))
    result.add(goto)

  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.transformReturnsInTry(n[i])

proc transformClosureIteratorBody(ctx: var Ctx, n: PNode, gotoOut: PNode): PNode =
  result = n
  case n.kind:
    of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
        nkSym, nkIdent, procDefs, nkTemplateDef:
      discard

    of nkStmtList, nkStmtListExpr:
      assert(isEmptyType(n.typ), "nkStmtListExpr not lowered")

      result = addGotoOut(result, gotoOut)
      for i in 0 ..< n.len:
        if n[i].hasYieldsInExpressions:
          # Lower nkStmtListExpr nodes inside `n[i]` first
          var ns = false
          n[i] = ctx.lowerStmtListExprs(n[i], ns)

        if n[i].hasYields:
          # Create a new split
          let go = newNode(nkGotoState)
          n[i] = ctx.transformClosureIteratorBody(n[i], go)

          let s = newNode(nkStmtList)
          for j in i + 1 ..< n.len:
            s.add(n[j])

          n.sons.setLen(i + 1)
          discard ctx.newState(s, go)
          discard ctx.transformClosureIteratorBody(s, gotoOut)
          break

    of nkYieldStmt:
      result = newNodeI(nkStmtList, n.info)
      result.add(n)
      result.add(gotoOut)

    of nkElse, nkElseExpr:
      result[0] = addGotoOut(result[0], gotoOut)
      result[0] = ctx.transformClosureIteratorBody(result[0], gotoOut)

    of nkElifBranch, nkElifExpr, nkOfBranch:
      result[1] = addGotoOut(result[1], gotoOut)
      result[1] = ctx.transformClosureIteratorBody(result[1], gotoOut)

    of nkIfStmt, nkCaseStmt:
      for i in 0 ..< n.len:
        n[i] = ctx.transformClosureIteratorBody(n[i], gotoOut)
      if n[^1].kind != nkElse:
        # We don't have an else branch, but every possible branch has to end with
        # gotoOut, so add else here.
        let elseBranch = newNode(nkElse)
        elseBranch.add(gotoOut)
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

      result = newNodeI(nkGotoState, n.info)

      let s = newNodeI(nkStmtList, n.info)
      discard ctx.newState(s, result)
      let ifNode = newNodeI(nkIfStmt, n.info)
      let elifBranch = newNodeI(nkElifBranch, n.info)
      elifBranch.add(n[0])

      var body = addGotoOut(n[1], result)

      body = ctx.transformBreaksAndContinuesInWhile(body, result, gotoOut)
      body = ctx.transformClosureIteratorBody(body, result)

      elifBranch.add(body)
      ifNode.add(elifBranch)

      let elseBranch = newNode(nkElse)
      elseBranch.add(gotoOut)
      ifNode.add(elseBranch)
      s.add(ifNode)

    of nkBlockStmt:
      result[1] = addGotoOut(result[1], gotoOut)
      result[1] = ctx.transformBreaksInBlock(result[1], result[0], gotoOut)
      result[1] = ctx.transformClosureIteratorBody(result[1], gotoOut)

    of nkTryStmt:
      # See explanation above about how this works
      ctx.hasExceptions = true

      result = newNode(nkGotoState)
      var tryBody = toStmtList(n[0])
      var exceptBody = ctx.collectExceptState(n)
      var finallyBody = newNode(nkStmtList)
      finallyBody.add(getFinallyNode(n))
      finallyBody = ctx.transformReturnsInTry(finallyBody)
      finallyBody.add(ctx.newEndFinallyNode())

      # The following index calculation is based on the knowledge how state
      # indexes are assigned
      let tryIdx = ctx.states.len
      var exceptIdx, finallyIdx: int
      if exceptBody.kind != nkEmpty:
        exceptIdx = -(tryIdx + 1)
        finallyIdx = tryIdx + 2
      else:
        exceptIdx = tryIdx + 1
        finallyIdx = tryIdx + 1

      let outToFinally = newNode(nkGotoState)

      block: # Create initial states.
        let oldExcHandlingState = ctx.curExcHandlingState
        ctx.curExcHandlingState = exceptIdx
        let realTryIdx = ctx.newState(tryBody, result)
        assert(realTryIdx == tryIdx)

        if exceptBody.kind != nkEmpty:
          ctx.curExcHandlingState = finallyIdx
          let realExceptIdx = ctx.newState(exceptBody, nil)
          assert(realExceptIdx == -exceptIdx)

        ctx.curExcHandlingState = oldExcHandlingState
        let realFinallyIdx = ctx.newState(finallyBody, outToFinally)
        assert(realFinallyIdx == finallyIdx)

      block: # Subdivide the states
        let oldNearestFinally = ctx.nearestFinally
        ctx.nearestFinally = finallyIdx

        let oldExcHandlingState = ctx.curExcHandlingState

        ctx.curExcHandlingState = exceptIdx

        discard ctx.transformReturnsInTry(tryBody)
        discard ctx.transformClosureIteratorBody(tryBody, outToFinally)

        ctx.curExcHandlingState = finallyIdx
        ctx.addElseToExcept(exceptBody)
        discard ctx.transformReturnsInTry(exceptBody)
        discard ctx.transformClosureIteratorBody(exceptBody, outToFinally)

        ctx.curExcHandlingState = oldExcHandlingState
        ctx.nearestFinally = oldNearestFinally
        discard ctx.transformClosureIteratorBody(finallyBody, gotoOut)

    of nkGotoState, nkForStmt:
      internalError("closure iter " & $n.kind)

    else:
      for i in 0 ..< n.len:
        n[i] = ctx.transformClosureIteratorBody(n[i], gotoOut)

proc stateFromGotoState(n: PNode): int =
  assert(n.kind == nkGotoState)
  result = n[0].intVal.int

proc tranformStateAssignments(ctx: var Ctx, n: PNode): PNode =
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
  #
  result = n
  case n.kind
  of nkStmtList, nkStmtListExpr:
    if n.len != 0 and n[0].kind == nkYieldStmt:
      assert(n.len == 2)
      assert(n[1].kind == nkGotoState)

      result = newNodeI(nkStmtList, n.info)
      result.add(ctx.newStateAssgn(stateFromGotoState(n[1])))

      var retStmt = newNodeI(nkReturnStmt, n.info)
      if n[0].sons[0].kind != nkEmpty:
        var a = newNodeI(nkAsgn, n[0].sons[0].info)
        var retVal = n[0].sons[0] #liftCapturedVars(n.sons[0], owner, d, c)
        addSon(a, newSymNode(getClosureIterResult(ctx.fn)))
        addSon(a, retVal)
        retStmt.add(a)
      else:
        retStmt.add(emptyNode)

      result.add(retStmt)
    else:
      for i in 0 ..< n.len:
        n[i] = ctx.tranformStateAssignments(n[i])

  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard

  of nkReturnStmt:
    result = newNodeI(nkStmtList, n.info)
    result.add(ctx.newStateAssgn(-1))
    result.add(n)

  of nkGotoState:
    result = newNodeI(nkStmtList, n.info)
    result.add(ctx.newStateAssgn(stateFromGotoState(n)))

    let breakState = newNodeI(nkBreakStmt, n.info)
    breakState.add(newSymNode(ctx.stateLoopLabel))
    result.add(breakState)

  else:
    for i in 0 ..< n.len:
      n[i] = ctx.tranformStateAssignments(n[i])

proc skipStmtList(n: PNode): PNode =
  result = n
  while result.kind in {nkStmtList}:
    if result.len == 0: return emptyNode
    result = result[0]

proc skipEmptyStates(ctx: Ctx, stateIdx: int): int =
  # Returns first non-empty state idx for `stateIdx`. Returns `stateIdx` if
  # it is not empty
  var maxJumps = ctx.states.len # maxJumps used only for debugging purposes.
  var stateIdx = stateIdx
  while true:
    let label = stateIdx
    if label == ctx.exitStateIdx: break
    var newLabel = label
    if label == -1:
      newLabel = ctx.exitStateIdx
    else:
      let fs = ctx.states[label][1].skipStmtList()
      if fs.kind == nkGotoState:
        newLabel = fs[0].intVal.int
    if label == newLabel: break
    stateIdx = newLabel
    dec maxJumps
    if maxJumps == 0:
      assert(false, "Internal error")

  result = ctx.states[stateIdx][0].intVal.int

proc skipThroughEmptyStates(ctx: var Ctx, n: PNode): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkGotoState:
    result = copyTree(n)
    result[0].intVal = ctx.skipEmptyStates(result[0].intVal.int)
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.skipThroughEmptyStates(n[i])

proc newArrayType(n: int, t: PType, owner: PSym): PType =
  result = newType(tyArray, owner)

  let rng = newType(tyRange, owner)
  rng.n = newNode(nkRange)
  rng.n.add(newIntLit(0))
  rng.n.add(newIntLit(n))
  rng.rawAddSon(t)

  result.rawAddSon(rng)
  result.rawAddSon(t)

proc createExceptionTable(ctx: var Ctx): PNode =
  result = newNode(nkBracket)
  result.typ = newArrayType(ctx.exceptionTable.len, getSysType(tyInt16), ctx.fn)

  for i in ctx.exceptionTable:
    let elem = newIntNode(nkIntLit, i)
    elem.typ = getSysType(tyInt16)
    result.add(elem)

proc newCatchBody(ctx: var Ctx): PNode {.inline.} =
  # Generates the code:
  # :state = exceptionTable[:state]
  # if :state == 0: raise
  # :unrollFinally = :state > 0
  # if :state < 0:
  #   :state = -:state
  # :curExc = getCurrentException()

  result = newNode(nkStmtList)

  # :state = exceptionTable[:state]
  block:

    # exceptionTable[:state]
    let getNextState = newNode(nkBracketExpr)
    getNextState.add(ctx.createExceptionTable)
    getNextState.add(ctx.newStateAccess())
    getNextState.typ = getSysType(tyInt)

    # :state = exceptionTable[:state]
    result.add(ctx.newStateAssgn(getNextState))

  # if :state == 0: raise
  block:
    let ifStmt = newNode(nkIfStmt)
    let ifBranch = newNode(nkElifBranch)
    let cond = newNode(nkCall)
    cond.add(getSysMagic("==", mEqI).newSymNode)
    cond.add(ctx.newStateAccess())
    cond.add(newIntTypeNode(nkIntLit, 0, getSysType(tyInt)))
    cond.typ = getSysType(tyBool)
    ifBranch.add(cond)

    let raiseStmt = newNode(nkRaiseStmt)
    raiseStmt.add(emptyNode)

    ifBranch.add(raiseStmt)
    ifStmt.add(ifBranch)
    result.add(ifStmt)

  # :unrollFinally = :state > 0
  block:
    let asgn = newNode(nkAsgn)
    asgn.add(ctx.newUnrollFinallyAccess())

    let cond = newNode(nkCall)
    cond.add(getSysMagic("<", mLtI).newSymNode)
    cond.add(newIntTypeNode(nkIntLit, 0, getSysType(tyInt)))
    cond.add(ctx.newStateAccess())
    cond.typ = getSysType(tyBool)
    asgn.add(cond)
    result.add(asgn)

  # if :state < 0: :state = -:state
  block:
    let ifStmt = newNode(nkIfStmt)
    let ifBranch = newNode(nkElifBranch)
    let cond = newNode(nkCall)
    cond.add(getSysMagic("<", mLtI).newSymNode)
    cond.add(ctx.newStateAccess())
    cond.add(newIntTypeNode(nkIntLit, 0, getSysType(tyInt)))
    cond.typ = getSysType(tyBool)
    ifBranch.add(cond)

    let negateState = newNode(nkCall)
    negateState.add(getSysMagic("-", mUnaryMinusI).newSymNode)
    negateState.add(ctx.newStateAccess())
    negateState.typ = getSysType(tyInt)

    ifBranch.add(ctx.newStateAssgn(negateState))
    ifStmt.add(ifBranch)
    result.add(ifStmt)

  # :curExc = getCurrentException()
  block:
    let getCurExc = callCodegenProc("getCurrentException", emptyNode)
    let asgn = newNode(nkAsgn)
    asgn.add(ctx.newCurExcAccess())
    asgn.add(getCurExc)
    result.add(asgn)

proc wrapIntoTryExcept(ctx: var Ctx, n: PNode): PNode =
  result = newNode(nkTryStmt)

  let tryBody = newNode(nkStmtList)

  let setupExc = newNode(nkCall)
  setupExc.add(newSymNode(getCompilerProc("closureIterSetupExc")))

  tryBody.add(setupExc)

  tryBody.add(n)
  result.add(tryBody)

  let catchNode = newNode(nkExceptBranch)
  result.add(catchNode)

  let catchBody = newNode(nkStmtList)
  catchBody.add(ctx.newCatchBody())
  catchNode.add(catchBody)

  setupExc.add(ctx.newCurExcAccess())

proc wrapIntoStateLoop(ctx: var Ctx, n: PNode): PNode =
  # while true:
  #   block :stateLoop:
  #     gotoState :state
  #     body # Might get wrapped in try-except

  result = newNode(nkWhileStmt)
  result.add(newSymNode(getSysSym("true")))

  let loopBody = newNodeI(nkStmtList, n.info)
  result.add(loopBody)

  if not ctx.stateVarSym.isNil:
    let varSect = newNodeI(nkVarSection, n.info)
    addVar(varSect, newSymNode(ctx.stateVarSym))
    loopBody.add(varSect)

    if not ctx.tempVars.isNil:
      loopBody.add(ctx.tempVars)

  let blockStmt = newNodeI(nkBlockStmt, n.info)
  blockStmt.add(newSymNode(ctx.stateLoopLabel))

  var blockBody = newNodeI(nkStmtList, n.info)

  let gs = newNodeI(nkGotoState, n.info)
  gs.add(ctx.newStateAccess())
  gs.add(newIntLit(ctx.states.len - 1))

  blockBody.add(gs)
  blockBody.add(n)

  if ctx.hasExceptions:
    blockBody = ctx.wrapIntoTryExcept(blockBody)

  blockStmt.add(blockBody)

  loopBody.add(blockStmt)

proc deleteEmptyStates(ctx: var Ctx) =
  let goOut = newNode(nkGotoState)
  goOut.add(newIntLit(-1))

  ctx.exitStateIdx = ctx.newState(goOut, nil)

  # Apply new state indexes and mark unused states with -1
  var iValid = 0
  for i, s in ctx.states:
    let body = s[1].skipStmtList()
    if body.kind == nkGotoState and i != ctx.states.len - 1 and i != 0:
      # This is an empty state. Mark with -1.
      s[0].intVal = -1
    else:
      s[0].intVal = iValid
      inc iValid

  for i, s in ctx.states:
    let body = s[1].skipStmtList()
    if body.kind != nkGotoState or i == 0:
      discard ctx.skipThroughEmptyStates(s)
      let excHandlState = ctx.exceptionTable[i]
      if excHandlState < 0:
        ctx.exceptionTable[i] = -ctx.skipEmptyStates(-excHandlState)
      elif excHandlState != 0:
        ctx.exceptionTable[i] = ctx.skipEmptyStates(excHandlState)

  var i = 0
  while i < ctx.states.len - 1:
    let fs = ctx.states[i][1].skipStmtList()
    if fs.kind == nkGotoState and i != 0:
      ctx.states.delete(i)
      ctx.exceptionTable.delete(i)
    else:
      inc i

proc transformClosureIterator*(fn: PSym, n: PNode): PNode =
  var ctx: Ctx
  ctx.fn = fn

  if getEnvParam(fn).isNil:
    # Lambda lifting was not done yet. Use temporary :state sym, which
    # be handled specially by lambda lifting. Local temp vars (if needed)
    # should folllow the same logic.
    ctx.stateVarSym = newSym(skVar, getIdent(":state"), fn, fn.info)
    ctx.stateVarSym.typ = createClosureIterStateType(fn)

  ctx.states = @[]
  ctx.stateLoopLabel = newSym(skLabel, getIdent(":stateLoop"), fn, fn.info)
  ctx.exceptionTable = @[]
  let n = n.toStmtList

  discard ctx.newState(n, nil)
  let gotoOut = newNode(nkGotoState)
  gotoOut.add(newIntLit(-1))

  # Splitting transformation
  discard ctx.transformClosureIteratorBody(n, gotoOut)

  # Optimize empty states away
  ctx.deleteEmptyStates()

  # Make new body by concating the list of states
  result = newNode(nkStmtList)
  for i, s in ctx.states:
    # result.add(s)
    let body = s[1]
    s.sons.del(1)
    result.add(s)
    result.add(body)

  result = ctx.tranformStateAssignments(result)
  result = ctx.wrapIntoStateLoop(result)

  # echo "TRANSFORM TO STATES: "
  # echo renderTree(result)

  # echo "exception table:"
  # for i, e in ctx.exceptionTable:
  #   echo i, " -> ", e
