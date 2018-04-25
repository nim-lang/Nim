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


import
  intsets, strutils, options, ast, astalgo, trees, treetab, msgs, os, options,
  idents, renderer, types, magicsys, rodread, lowerings, tables, sequtils,
  lambdalifting

type ClosureIteratorTransformationContext = object
  fn: PSym
  stateVarSym: PSym # :state variable. nil if env already introduced by lambdalifting
  states: seq[PNode] # The resulting states. Every state is an nkState node.
  blockLevel: int # Temp used to transform break and continue stmts
  stateLoopLabel: PSym # Label to break on, when jumping between states.
  exitStateIdx: int # index of the last state
  tempVarId: int # unique name counter
  tempVars: PNode # Temp var decls, nkVarSection
  loweredStmtListExpr: PNode # Temporary used for nkStmtListExpr lowering

proc newStateAssgn(ctx: var ClosureIteratorTransformationContext, stateNo: int = -2): PNode =
  # Creates state assignmen:
  #   :state = stateNo

  result = newNode(nkAsgn)
  if ctx.stateVarSym.isNil:
    let state = getStateField(ctx.fn)
    assert state != nil
    result.add(rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)),
                      state, result.info))
  else:
    result.add(newSymNode(ctx.stateVarSym))
  result.add(newIntTypeNode(nkIntLit, stateNo, getSysType(tyInt)))

proc setStateInAssgn(stateAssgn: PNode, stateNo: int) =
  assert stateAssgn.kind == nkAsgn
  assert stateAssgn[1].kind == nkIntLit
  stateAssgn[1].intVal = stateNo

proc newState(ctx: var ClosureIteratorTransformationContext, n, gotoOut: PNode): int =
  # Creates a new state, adds it to the context fills out `gotoOut` so that it
  # will goto this state.
  # Returns index of the newly created state

  result = ctx.states.len
  let resLit = newIntLit(result)
  let s = newNodeI(nkState, n.info)
  s.add(resLit)
  s.add(n)
  ctx.states.add(s)
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

proc newTempVarAccess(ctx: var ClosureIteratorTransformationContext, typ: PType, i: TLineInfo): PNode =
  if not ctx.stateVarSym.isNil:
    # We haven't gone through labmda lifting yet, so just create a local var,
    # it will be lifted later
    let s = newSym(skVar, getIdent(":tmpSlLower" & $ctx.tempVarId), ctx.fn, i)
    s.typ = typ

    if ctx.tempVars.isNil:
      ctx.tempVars = newNode(nkVarSection)
      addVar(ctx.tempVars, newSymNode(s))

    result = newSymNode(s)
  else:
    # Lambda lifting is done, insert temp var to env.
    let s = newSym(skVar, getIdent(":tmpSlLower" & $ctx.tempVarId), ctx.fn, i)
    s.typ = typ
    result = freshVarForClosureIter(s, ctx.fn)

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

proc transformBreaksAndContinuesInWhile(ctx: var ClosureIteratorTransformationContext, n: PNode, before, after: PNode): PNode =
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

proc transformBreaksInBlock(ctx: var ClosureIteratorTransformationContext, n: PNode, label, after: PNode): PNode =
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

proc collectExceptState(n: PNode): PNode =
  var ifStmt = newNode(nkIfStmt)
  for c in n:
    if c.kind == nkExceptBranch:
      var ifBranch: PNode
      var branchBody: PNode

      if c[0].kind == nkType:
        assert(c.len == 2)
        ifBranch = newNode(nkElifBranch)
        let expression = newNodeI(nkCall, n.info)
        expression.add(callCodegenProc("getCurrentException", emptyNode))
        expression.add(c[0])
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
    result.add(ifStmt)
  else:
    result = emptyNode

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
    result = n.hasYields
  of nkStmtList, nkWhileStmt, nkCaseStmt, nkIfStmt:
    discard
  else:
    for c in n:
      if c.hasYieldsInExpressions:
        return true

proc lowerStmtListExpr(ctx: var ClosureIteratorTransformationContext, n: PNode): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkStmtListExpr:
    if n.hasYields:
      for i in 0 .. n.len - 2:
        ctx.loweredStmtListExpr.add(n[i])

      let tv = ctx.newTempVarAccess(n.typ, n[^1].info)
      let asgn = newNode(nkAsgn)
      asgn.add(tv)
      asgn.add(n[^1])
      ctx.loweredStmtListExpr.add(asgn)
      result = tv

  else:
    for i in 0 ..< n.len:
      n[i] = ctx.lowerStmtListExpr(n[i])

proc transformClosureIteratorBody(ctx: var ClosureIteratorTransformationContext, n: PNode, gotoOut: PNode): PNode =
  result = n
  case n.kind:
    of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
        nkSym, nkIdent, procDefs, nkTemplateDef:
      discard

    of nkStmtList:
      result = addGotoOut(result, gotoOut)
      for i in 0 ..< n.len:
        if n[i].hasYieldsInExpressions:
          # Lower nkStmtListExpr nodes inside `n[i]` first
          assert(ctx.loweredStmtListExpr.isNil)
          ctx.loweredStmtListExpr = newNodeI(nkStmtList, n.info)
          n[i] = ctx.lowerStmtListExpr(n[i])
          ctx.loweredStmtListExpr.add(n[i])
          n[i] = ctx.loweredStmtListExpr
          ctx.loweredStmtListExpr = nil

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

    of nkStmtListExpr:
      assert(false, "nkStmtListExpr not lowered")

    of nkYieldStmt:
      # echo "YIELD!"
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
      var tryBody = toStmtList(n[0])

      # let popTry = newNode(nkPar)
      # popTry.add(newIdentNode(getIdent("popTry"), n.info))
      var finallyBody = newNode(nkStmtList)
      # finallyBody.add(popTry)
      finallyBody.add(getFinallyNode(n))

      var tryCatchOut = newNode(nkGotoState)

      tryBody = ctx.transformClosureIteratorBody(tryBody, tryCatchOut)
      var exceptBody = collectExceptState(n)

      var exceptIdx = -1
      if exceptBody.kind != nkEmpty:
        exceptBody = ctx.transformClosureIteratorBody(exceptBody, tryCatchOut)
        exceptIdx = ctx.newState(exceptBody, nil)

      finallyBody = ctx.transformClosureIteratorBody(finallyBody, gotoOut)
      let finallyIdx = ctx.newState(finallyBody, tryCatchOut)

      # let pushTry = newNode(nkPar) #newCall(newSym("pushTry"), newIntLit(exceptIdx))
      # pushTry.add(newIdentNode(getIdent("pushTry"), n.info))
      # pushTry.add(newIntLit(exceptIdx))
      # pushTry.add(newIntLit(finallyIdx))
      # tryBody.sons.insert(pushTry, 0)

      result = tryBody

    of nkGotoState, nkForStmt:
      internalError("closure iter " & $n.kind)

    else:
      for i in 0 ..< n.len:
        n[i] = ctx.transformClosureIteratorBody(n[i], gotoOut)

proc stateFromGotoState(n: PNode): int =
  assert(n.kind == nkGotoState)
  result = n[0].intVal.int

proc tranformStateAssignments(ctx: var ClosureIteratorTransformationContext, n: PNode): PNode =
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

proc skipThroughEmptyStates(ctx: var ClosureIteratorTransformationContext, n: PNode): PNode =
  result = n
  case n.kind
  of nkCharLit..nkUInt64Lit, nkFloatLit..nkFloat128Lit, nkStrLit..nkTripleStrLit,
      nkSym, nkIdent, procDefs, nkTemplateDef:
    discard
  of nkGotoState:
    var maxJumps = ctx.states.len # maxJumps used only for debugging purposes.
    result = copyTree(n)
    while true:
      let label = result[0].intVal.int
      if label == ctx.exitStateIdx: break
      var newLabel = label
      if label == -1:
        newLabel = ctx.exitStateIdx
      else:
        let fs = ctx.states[label][1].skipStmtList()
        if fs.kind == nkGotoState:
          newLabel = fs[0].intVal.int
      if label == newLabel: break
      result[0].intVal = newLabel
      dec maxJumps
      if maxJumps == 0:
        assert(false, "Internal error")

    let label = result[0].intVal.int
    result[0].intVal = ctx.states[label][0].intVal
  else:
    for i in 0 ..< n.len:
      n[i] = ctx.skipThroughEmptyStates(n[i])

proc wrapIntoStateLoop(ctx: var ClosureIteratorTransformationContext, n: PNode): PNode =
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

  let blockBody = newNodeI(nkStmtList, n.info)
  blockStmt.add(blockBody)

  let gs = newNodeI(nkGotoState, n.info)
  if ctx.stateVarSym.isNil:
    gs.add(rawIndirectAccess(newSymNode(getEnvParam(ctx.fn)), getStateField(ctx.fn), n.info))
  else:
    gs.add(newSymNode(ctx.stateVarSym))

  gs.add(newIntLit(ctx.states.len - 1))
  blockBody.add(gs)
  blockBody.add(n)
  # gs.add(rawIndirectAccess(newSymNode(ctx.fn.getHiddenParam), getStateField(ctx.fn), n.info))

  loopBody.add(blockStmt)

proc deleteEmptyStates(ctx: var ClosureIteratorTransformationContext) =
  let goOut = newNode(nkGotoState)
  goOut.add(newIntLit(-1))

  ctx.exitStateIdx = ctx.newState(goOut, nil)

  # Apply new state indexes and mark unused states with -1
  var iValid = 0
  for i, s in ctx.states:
    let body = s[1].skipStmtList()
    if body.kind == nkGotoState and i != ctx.states.len - 1:
      # This is an empty state. Mark with -1.
      s[0].intVal = -1
    else:
      s[0].intVal = iValid
      inc iValid

  for i, s in ctx.states:
    let body = s[1].skipStmtList()
    if body.kind != nkGotoState:
      discard ctx.skipThroughEmptyStates(s)

  var i = 0
  while i < ctx.states.len - 1:
    let fs = ctx.states[i][1].skipStmtList()
    if fs.kind == nkGotoState:
      ctx.states.delete(i)
    else:
      inc i

proc transformClosureIterator*(fn: PSym, n: PNode): PNode =
  var ctx: ClosureIteratorTransformationContext
  ctx.fn = fn

  if getEnvParam(fn).isNil:
    # Lambda lifting was not done yet. Use temporary :state sym, which
    # be handled specially by lambda lifting. Local temp vars (if needed)
    # should folllow the same logic.
    ctx.stateVarSym = newSym(skVar, getIdent(":state"), fn, fn.info)
    ctx.stateVarSym.typ = createClosureIterStateType(fn)

  ctx.states = @[]
  ctx.stateLoopLabel = newSym(skLabel, getIdent(":stateLoop"), fn, fn.info)
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

  # Add excpetion handling
  var hasExceptions = false
  if hasExceptions:
    discard # TODO:
    # result = wrapIntoTryCatch(result)

  # while true:
  #   block :stateLoop:
  #     gotoState
  #     body
  result = ctx.wrapIntoStateLoop(result)

  # echo "TRANSFORM TO STATES2: "
  # debug(result)
  # echo renderTree(result)
