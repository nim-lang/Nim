#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## AsyncMacro
## *************
## `asyncdispatch` module depends on the `asyncmacro` module to work properly.

import macros, strutils

proc skipUntilStmtList(node: NimNode): NimNode {.compileTime.} =
  # Skips a nest of StmtList's.
  result = node
  if node[0].kind == nnkStmtList:
    result = skipUntilStmtList(node[0])

proc skipStmtList(node: NimNode): NimNode {.compileTime.} =
  result = node
  if node[0].kind == nnkStmtList:
    result = node[0]

template createCb(retFutureSym, iteratorNameSym,
                  name, futureVarCompletions: untyped) =
  var nameIterVar = iteratorNameSym
  #{.push stackTrace: off.}
  proc cb {.closure,gcsafe.} =
    try:
      if not nameIterVar.finished:
        var next = nameIterVar()
        if next == nil:
          if not retFutureSym.finished:
            let msg = "Async procedure ($1) yielded `nil`, are you await'ing a " &
                    "`nil` Future?"
            raise newException(AssertionError, msg % name)
        else:
          next.callback = cb
    except:
      if retFutureSym.finished:
        # Take a look at tasyncexceptions for the bug which this fixes.
        # That test explains it better than I can here.
        raise
      else:
        retFutureSym.fail(getCurrentException())

      futureVarCompletions
  cb()
  #{.pop.}
proc generateExceptionCheck(futSym,
    tryStmt, rootReceiver, fromNode: NimNode): NimNode {.compileTime.} =
  if tryStmt.kind == nnkNilLit:
    result = rootReceiver
  else:
    var exceptionChecks: seq[tuple[cond, body: NimNode]] = @[]
    let errorNode = newDotExpr(futSym, newIdentNode("error"))
    for i in 1 .. <tryStmt.len:
      let exceptBranch = tryStmt[i]
      if exceptBranch[0].kind == nnkStmtList:
        exceptionChecks.add((newIdentNode("true"), exceptBranch[0]))
      else:
        var exceptIdentCount = 0
        var ifCond: NimNode
        for i in 0 .. <exceptBranch.len:
          let child = exceptBranch[i]
          if child.kind == nnkIdent:
            let cond = infix(errorNode, "of", child)
            if exceptIdentCount == 0:
              ifCond = cond
            else:
              ifCond = infix(ifCond, "or", cond)
          else:
            break
          exceptIdentCount.inc

        expectKind(exceptBranch[exceptIdentCount], nnkStmtList)
        exceptionChecks.add((ifCond, exceptBranch[exceptIdentCount]))
    # -> -> else: raise futSym.error
    exceptionChecks.add((newIdentNode("true"),
        newNimNode(nnkRaiseStmt).add(errorNode)))
    # Read the future if there is no error.
    # -> else: futSym.read
    let elseNode = newNimNode(nnkElse, fromNode)
    elseNode.add newNimNode(nnkStmtList, fromNode)
    elseNode[0].add rootReceiver

    let ifBody = newStmtList()
    ifBody.add newCall(newIdentNode("setCurrentException"), errorNode)
    ifBody.add newIfStmt(exceptionChecks)
    ifBody.add newCall(newIdentNode("setCurrentException"), newNilLit())

    result = newIfStmt(
      (newDotExpr(futSym, newIdentNode("failed")), ifBody)
    )
    result.add elseNode

template useVar(result: var NimNode, futureVarNode: NimNode, valueReceiver,
                rootReceiver: untyped, fromNode: NimNode) =
  ## Params:
  ##    futureVarNode: The NimNode which is a symbol identifying the Future[T]
  ##                   variable to yield.
  ##    fromNode: Used for better debug information (to give context).
  ##    valueReceiver: The node which defines an expression that retrieves the
  ##                   future's value.
  ##
  ##    rootReceiver: ??? TODO
  # -> yield future<x>
  result.add newNimNode(nnkYieldStmt, fromNode).add(futureVarNode)
  # -> future<x>.read
  valueReceiver = newDotExpr(futureVarNode, newIdentNode("read"))
  result.add generateExceptionCheck(futureVarNode, tryStmt, rootReceiver,
      fromNode)

template createVar(result: var NimNode, futSymName: string,
                   asyncProc: NimNode,
                   valueReceiver, rootReceiver: untyped,
                   fromNode: NimNode) =
  result = newNimNode(nnkStmtList, fromNode)
  var futSym = genSym(nskVar, "future")
  result.add newVarStmt(futSym, asyncProc) # -> var future<x> = y
  useVar(result, futSym, valueReceiver, rootReceiver, fromNode)

proc createFutureVarCompletions(futureVarIdents: seq[NimNode]): NimNode
                                {.compileTime.} =
  result = newStmtList()
  # Add calls to complete each FutureVar parameter.
  for ident in futureVarIdents:
    # Only complete them if they have not been completed already by the user.
    result.add newIfStmt(
      (
        newCall(newIdentNode("not"),
                newDotExpr(ident, newIdentNode("finished"))),
        newCall(newIdentNode("complete"), ident)
      )
    )

proc processBody(node, retFutureSym: NimNode,
                 subTypeIsVoid: bool, futureVarIdents: seq[NimNode],
                 tryStmt: NimNode): NimNode {.compileTime.} =
  #echo(node.treeRepr)
  result = node
  case node.kind
  of nnkReturnStmt:
    result = newNimNode(nnkStmtList, node)
    if node[0].kind == nnkEmpty:
      if not subTypeIsVoid:
        result.add newCall(newIdentNode("complete"), retFutureSym,
            newIdentNode("result"))
      else:
        result.add newCall(newIdentNode("complete"), retFutureSym)
    else:
      let x = node[0].processBody(retFutureSym, subTypeIsVoid,
                                  futureVarIdents, tryStmt)
      if x.kind == nnkYieldStmt: result.add x
      else:
        result.add newCall(newIdentNode("complete"), retFutureSym, x)

    result.add createFutureVarCompletions(futureVarIdents)

    result.add newNimNode(nnkReturnStmt, node).add(newNilLit())
    return # Don't process the children of this return stmt
  of nnkCommand, nnkCall:
    if node[0].kind == nnkIdent and node[0].ident == !"await":
      case node[1].kind
      of nnkIdent, nnkInfix, nnkDotExpr, nnkCall, nnkCommand:
        # await x
        # await x or y
        # await foo(p, x)
        # await foo p, x
        var futureValue: NimNode
        result.createVar("future" & $node[1][0].toStrLit, node[1], futureValue,
                  futureValue, node)
      else:
        error("Invalid node kind in 'await', got: " & $node[1].kind)
    elif node.len > 1 and node[1].kind == nnkCommand and
         node[1][0].kind == nnkIdent and node[1][0].ident == !"await":
      # foo await x
      var newCommand = node
      result.createVar("future" & $node[0].toStrLit, node[1][1], newCommand[1],
                newCommand, node)

  of nnkVarSection, nnkLetSection:
    case node[0][2].kind
    of nnkCommand:
      if node[0][2][0].kind == nnkIdent and node[0][2][0].ident == !"await":
        # var x = await y
        var newVarSection = node # TODO: Should this use copyNimNode?
        result.createVar("future" & $node[0][0].ident, node[0][2][1],
          newVarSection[0][2], newVarSection, node)
    else: discard
  of nnkAsgn:
    case node[1].kind
    of nnkCommand:
      if node[1][0].ident == !"await":
        # x = await y
        var newAsgn = node
        result.createVar("future" & $node[0].toStrLit, node[1][1], newAsgn[1], newAsgn, node)
    else: discard
  of nnkDiscardStmt:
    # discard await x
    if node[0].kind == nnkCommand and node[0][0].kind == nnkIdent and
          node[0][0].ident == !"await":
      var newDiscard = node
      result.createVar("futureDiscard_" & $toStrLit(node[0][1]), node[0][1],
                newDiscard[0], newDiscard, node)
  of nnkTryStmt:
    # try: await x; except: ...
    result = newNimNode(nnkStmtList, node)
    template wrapInTry(n, tryBody: untyped) =
      var temp = n
      n[0] = tryBody
      tryBody = temp

      # Transform ``except`` body.
      # TODO: Could we perform some ``await`` transformation here to get it
      # working in ``except``?
      tryBody[1] = processBody(n[1], retFutureSym, subTypeIsVoid,
                               futureVarIdents, nil)

    proc processForTry(n: NimNode, i: var int,
                       res: NimNode): bool {.compileTime.} =
      ## Transforms the body of the tryStmt. Does not transform the
      ## body in ``except``.
      ## Returns true if the tryStmt node was transformed into an ifStmt.
      result = false
      var skipped = n.skipStmtList()
      while i < skipped.len:
        var processed = processBody(skipped[i], retFutureSym,
                                    subTypeIsVoid, futureVarIdents, n)

        # Check if we transformed the node into an exception check.
        # This suggests skipped[i] contains ``await``.
        if processed.kind != skipped[i].kind or processed.len != skipped[i].len:
          processed = processed.skipUntilStmtList()
          expectKind(processed, nnkStmtList)
          expectKind(processed[2][1], nnkElse)
          i.inc

          if not processForTry(n, i, processed[2][1][0]):
            # We need to wrap the nnkElse nodes back into a tryStmt.
            # As they are executed if an exception does not happen
            # inside the awaited future.
            # The following code will wrap the nodes inside the
            # original tryStmt.
            wrapInTry(n, processed[2][1][0])

          res.add processed
          result = true
        else:
          res.add skipped[i]
          i.inc
    var i = 0
    if not processForTry(node, i, result):
      # If the tryStmt hasn't been transformed we can just put the body
      # back into it.
      wrapInTry(node, result)
    return
  else: discard

  for i in 0 .. <result.len:
    result[i] = processBody(result[i], retFutureSym, subTypeIsVoid,
                            futureVarIdents, nil)

proc getName(node: NimNode): string {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return $node[1].ident
  of nnkIdent:
    return $node.ident
  of nnkEmpty:
    return "anonymous"
  else:
    error("Unknown name.")

proc getFutureVarIdents(params: NimNode): seq[NimNode] {.compileTime.} =
  result = @[]
  for i in 1 .. <len(params):
    expectKind(params[i], nnkIdentDefs)
    if params[i][1].kind == nnkBracketExpr and
       ($params[i][1][0].ident).normalize == "futurevar":
      result.add(params[i][0])

proc isInvalidReturnType(typeName: string): bool =
  return typeName notin ["Future"] #, "FutureStream"]

proc verifyReturnType(typeName: string) {.compileTime.} =
  if typeName.isInvalidReturnType:
    error("Expected return type of 'Future' got '$1'" %
          typeName)

proc asyncSingleProc(prc: NimNode): NimNode {.compileTime.} =
  ## This macro transforms a single procedure into a closure iterator.
  ## The ``async`` macro supports a stmtList holding multiple async procedures.
  if prc.kind notin {nnkProcDef, nnkLambda, nnkMethodDef}:
      error("Cannot transform this node kind into an async proc." &
            " proc/method definition or lambda node expected.")

  hint("Processing " & prc[0].getName & " as an async proc.")

  let returnType = prc[3][0]
  var baseType: NimNode
  # Verify that the return type is a Future[T]
  if returnType.kind == nnkBracketExpr:
    let fut = repr(returnType[0])
    verifyReturnType(fut)
    baseType = returnType[1]
  elif returnType.kind in nnkCallKinds and $returnType[0] == "[]":
    let fut = repr(returnType[1])
    verifyReturnType(fut)
    baseType = returnType[2]
  elif returnType.kind == nnkEmpty:
    baseType = returnType
  else:
    verifyReturnType(repr(returnType))

  let subtypeIsVoid = returnType.kind == nnkEmpty or
        (baseType.kind == nnkIdent and returnType[1].ident == !"void")

  let futureVarIdents = getFutureVarIdents(prc[3])

  var outerProcBody = newNimNode(nnkStmtList, prc[6])

  # -> var retFuture = newFuture[T]()
  var retFutureSym = genSym(nskVar, "retFuture")
  var subRetType =
    if returnType.kind == nnkEmpty: newIdentNode("void")
    else: baseType
  outerProcBody.add(
    newVarStmt(retFutureSym,
      newCall(
        newNimNode(nnkBracketExpr, prc[6]).add(
          newIdentNode(!"newFuture"), # TODO: Strange bug here? Remove the `!`.
          subRetType),
      newLit(prc[0].getName)))) # Get type from return type of this proc

  # -> iterator nameIter(): FutureBase {.closure.} =
  # ->   {.push warning[resultshadowed]: off.}
  # ->   var result: T
  # ->   {.pop.}
  # ->   <proc_body>
  # ->   complete(retFuture, result)
  var iteratorNameSym = genSym(nskIterator, $prc[0].getName & "Iter")
  var procBody = prc[6].processBody(retFutureSym, subtypeIsVoid,
                                    futureVarIdents, nil)
  # don't do anything with forward bodies (empty)
  if procBody.kind != nnkEmpty:
    if not subtypeIsVoid:
      procBody.insert(0, newNimNode(nnkPragma).add(newIdentNode("push"),
        newNimNode(nnkExprColonExpr).add(newNimNode(nnkBracketExpr).add(
          newIdentNode("warning"), newIdentNode("resultshadowed")),
        newIdentNode("off")))) # -> {.push warning[resultshadowed]: off.}

      procBody.insert(1, newNimNode(nnkVarSection, prc[6]).add(
        newIdentDefs(newIdentNode("result"), baseType))) # -> var result: T

      procBody.insert(2, newNimNode(nnkPragma).add(
        newIdentNode("pop"))) # -> {.pop.})

      procBody.add(
        newCall(newIdentNode("complete"),
          retFutureSym, newIdentNode("result"))) # -> complete(retFuture, result)
    else:
      # -> complete(retFuture)
      procBody.add(newCall(newIdentNode("complete"), retFutureSym))

    procBody.add(createFutureVarCompletions(futureVarIdents))

    var closureIterator = newProc(iteratorNameSym, [newIdentNode("FutureBase")],
                                  procBody, nnkIteratorDef)
    closureIterator[4] = newNimNode(nnkPragma, prc[6]).add(newIdentNode("closure"))
    outerProcBody.add(closureIterator)

    # -> createCb(retFuture)
    #var cbName = newIdentNode("cb")
    var procCb = getAst createCb(retFutureSym, iteratorNameSym,
                         newStrLitNode(prc[0].getName),
                         createFutureVarCompletions(futureVarIdents))
    outerProcBody.add procCb

    # -> return retFuture
    outerProcBody.add newNimNode(nnkReturnStmt, prc[6][prc[6].len-1]).add(retFutureSym)

  result = prc

  # Remove the 'async' pragma.
  for i in 0 .. <result[4].len:
    if result[4][i].kind == nnkIdent and result[4][i].ident == !"async":
      result[4].del(i)
  result[4] = newEmptyNode()
  if subtypeIsVoid:
    # Add discardable pragma.
    if returnType.kind == nnkEmpty:
      # Add Future[void]
      result[3][0] = parseExpr("Future[void]")
  if procBody.kind != nnkEmpty:
    result[6] = outerProcBody
  #echo(treeRepr(result))
  #if prc[0].getName == "beta":
  #  echo(toStrLit(result))

macro async*(prc: untyped): untyped =
  ## Macro which processes async procedures into the appropriate
  ## iterators and yield statements.
  if prc.kind == nnkStmtList:
    for oneProc in prc:
      result = newStmtList()
      result.add asyncSingleProc(oneProc)
  else:
    result = asyncSingleProc(prc)
  when defined(nimDumpAsync):
    echo repr result


# Multisync
proc emptyNoop[T](x: T): T =
  # The ``await``s are replaced by a call to this for simplicity.
  when T isnot void:
    return x

proc stripAwait(node: NimNode): NimNode =
  ## Strips out all ``await`` commands from a procedure body, replaces them
  ## with ``emptyNoop`` for simplicity.
  result = node

  let emptyNoopSym = bindSym("emptyNoop")

  case node.kind
  of nnkCommand, nnkCall:
    if node[0].kind == nnkIdent and node[0].ident == !"await":
      node[0] = emptyNoopSym
    elif node.len > 1 and node[1].kind == nnkCommand and
         node[1][0].kind == nnkIdent and node[1][0].ident == !"await":
      # foo await x
      node[1][0] = emptyNoopSym
  of nnkVarSection, nnkLetSection:
    case node[0][2].kind
    of nnkCommand:
      if node[0][2][0].kind == nnkIdent and node[0][2][0].ident == !"await":
        # var x = await y
        node[0][2][0] = emptyNoopSym
    else: discard
  of nnkAsgn:
    case node[1].kind
    of nnkCommand:
      if node[1][0].ident == !"await":
        # x = await y
        node[1][0] = emptyNoopSym
    else: discard
  of nnkDiscardStmt:
    # discard await x
    if node[0].kind == nnkCommand and node[0][0].kind == nnkIdent and
          node[0][0].ident == !"await":
      node[0][0] = emptyNoopSym
  else: discard

  for i in 0 .. <result.len:
    result[i] = stripAwait(result[i])

proc splitParamType(paramType: NimNode, async: bool): NimNode =
  result = paramType
  if paramType.kind == nnkInfix and $paramType[0].ident in ["|", "or"]:
    let firstType = paramType[1]
    let firstTypeName = $firstType.ident
    let secondType = paramType[2]
    let secondTypeName = $secondType.ident

    # Make sure that at least one has the name `async`, otherwise we shouldn't
    # touch it.
    if not ("async" in firstTypeName.normalize or
            "async" in secondTypeName.normalize):
      return

    if async:
      if firstTypeName.normalize.startsWith("async"):
        result = paramType[1]
      elif secondTypeName.normalize.startsWith("async"):
        result = paramType[2]
    else:
      if not firstTypeName.normalize.startsWith("async"):
        result = paramType[1]
      elif not secondTypeName.normalize.startsWith("async"):
        result = paramType[2]

proc stripReturnType(returnType: NimNode): NimNode =
  # Strip out the 'Future' from 'Future[T]'.
  result = returnType
  if returnType.kind == nnkBracketExpr:
    let fut = repr(returnType[0])
    verifyReturnType(fut)
    result = returnType[1]

proc splitProc(prc: NimNode): (NimNode, NimNode) =
  ## Takes a procedure definition which takes a generic union of arguments,
  ## for example: proc (socket: Socket | AsyncSocket).
  ## It transforms them so that ``proc (socket: Socket)`` and
  ## ``proc (socket: AsyncSocket)`` are returned.

  result[0] = prc.copyNimTree()
  # Retrieve the `T` inside `Future[T]`.
  let returnType = stripReturnType(result[0][3][0])
  result[0][3][0] = splitParamType(returnType, async=false)
  for i in 1 .. <result[0][3].len:
    # Sync proc (0) -> FormalParams (3) -> IdentDefs, the parameter (i) ->
    # parameter type (1).
    result[0][3][i][1] = splitParamType(result[0][3][i][1], async=false)
  result[0][6] = stripAwait(result[0][6])

  result[1] = prc.copyNimTree()
  if result[1][3][0].kind == nnkBracketExpr:
    result[1][3][0][1] = splitParamType(result[1][3][0][1], async=true)
  for i in 1 .. <result[1][3].len:
    # Async proc (1) -> FormalParams (3) -> IdentDefs, the parameter (i) ->
    # parameter type (1).
    result[1][3][i][1] = splitParamType(result[1][3][i][1], async=true)

macro multisync*(prc: untyped): untyped =
  ## Macro which processes async procedures into both asynchronous and
  ## synchronous procedures.
  ##
  ## The generated async procedures use the ``async`` macro, whereas the
  ## generated synchronous procedures simply strip off the ``await`` calls.
  hint("Processing " & prc[0].getName & " as a multisync proc.")

  let (sync, asyncPrc) = splitProc(prc)
  result = newStmtList()
  result.add(asyncSingleProc(asyncPrc))
  result.add(sync)