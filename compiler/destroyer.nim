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

## Rules for destructor injections:
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## foo( (tmpX = X(); tmpY = Y(); tmpBar = bar(tmpX, tmpY);
##       destroy(tmpX); destroy(tmpY);
##       tmpBar))
## destroy(tmpBar)
##
## var x = f()
## body
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##  finally:
##    destroy(x)
##
## But this really just an optimization that tries to avoid to
## introduce too many temporaries, the 'destroy' is caused by
## the 'f()' call. No! That is not true for 'result = f()'!
##
## x = y where y is read only once
## is the same as:  move(x, y)
##
## Actually the more general rule is: The *last* read of ``y``
## can become a move if ``y`` is the result of a construction.
##
## We also need to keep in mind here that the number of reads is
## control flow dependent:
## let x = foo()
## while true:
##   y = x  # only one read, but the 2nd iteration will fail!
## This also affects recursions! Only usages that do not cross
## a loop boundary (scope) and are not used in function calls
## are safe.
##
##
## x = f() is the same as:  move(x, f())
##
## x = y
## is the same as:  copy(x, y)
##
## Reassignment works under this scheme:
## var x = f()
## x = y
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##    copy(x, y)
##  finally:
##    destroy(x)
##
##  result = f()  must not destroy 'result'!
##
## The produced temporaries clutter up the code and might lead to
## inefficiencies. A better strategy is to collect all the temporaries
## in a single object that we put into a single try-finally that
## surrounds the proc body. This means the code stays quite efficient
## when compiled to C. In fact, we do the same for variables, so
## destructors are called when the proc returns, not at scope exit!
## This makes certains idioms easier to support. (Taking the slice
## of a temporary object.)
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## var tmp: object
## foo( (move tmp.x, X(); move tmp.y, Y(); tmp.bar = bar(tmpX, tmpY);
##       tmp.bar))
## destroy(tmp.bar)
## destroy(tmp.x); destroy(tmp.y)
##

##[
From https://github.com/nim-lang/Nim/wiki/Destructors

Rule      Pattern                 Transformed into
----      -------                 ----------------
1.1	      var x: T; stmts	        var x: T; try stmts
                                  finally: `=destroy`(x)
1.2       var x: sink T; stmts    var x: sink T; stmts; ensureEmpty(x)
2         x = f()                 `=sink`(x, f())
3         x = lastReadOf z        `=sink`(x, z)
4.1       y = sinkParam           `=sink`(y, sinkParam)
4.2       x = y                   `=`(x, y) # a copy
5.1       f_sink(g())             f_sink(g())
5.2       f_sink(y)               f_sink(copy y); # copy unless we can see it's the last read
5.3       f_sink(move y)          f_sink(y); reset(y) # explicit moves empties 'y'
5.4       f_noSink(g())           var tmp = bitwiseCopy(g()); f(tmp); `=destroy`(tmp)

Remarks: Rule 1.2 is not yet implemented because ``sink`` is currently
  not allowed as a local variable.

``move`` builtin needs to be implemented.
]##

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  strutils, options, dfa, lowerings, tables, modulegraphs,
  lineinfos

const
  InterestingSyms = {skVar, skResult, skLet}

type
  Con = object
    owner: PSym
    g: ControlFlowGraph
    jumpTargets: IntSet
    tmpObj: PType
    tmp: PSym
    destroys, topLevelVars: PNode
    toDropBit: Table[int, PSym]
    graph: ModuleGraph
    emptyNode: PNode

proc getTemp(c: var Con; typ: PType; info: TLineInfo): PNode =
  # XXX why are temps fields in an object here?
  let f = newSym(skField, getIdent(c.graph.cache, ":d" & $c.tmpObj.n.len), c.owner, info)
  f.typ = typ
  rawAddField c.tmpObj, f
  result = rawDirectAccess(c.tmp, f)

proc isHarmlessVar*(s: PSym; c: Con): bool =
  # 's' is harmless if it used only once and its
  # definition/usage are not split by any labels:
  #
  # let s = foo()
  # while true:
  #   a[i] = s
  #
  # produces:
  #
  # def s
  # L1:
  #   use s
  # goto L1
  #
  # let s = foo()
  # if cond:
  #   a[i] = s
  # else:
  #   a[j] = s
  #
  # produces:
  #
  # def s
  # fork L2
  # use s
  # goto L3
  # L2:
  # use s
  # L3
  #
  # So this analysis is for now overly conservative, but correct.
  var defsite = -1
  var usages = 0
  for i in 0..<c.g.len:
    case c.g[i].kind
    of def:
      if c.g[i].sym == s:
        if defsite < 0: defsite = i
        else: return false
    of use:
      if c.g[i].sym == s:
        if defsite < 0: return false
        for j in defsite .. i:
          # not within the same basic block?
          if j in c.jumpTargets: return false
        # if we want to die after the first 'use':
        if usages > 1: return false
        inc usages
    of useWithinCall:
      if c.g[i].sym == s: return false
    of goto, fork:
      discard "we do not perform an abstract interpretation yet"

template interestingSym(s: PSym): bool =
  s.owner == c.owner and s.kind in InterestingSyms and hasDestructor(s.typ)

proc patchHead(n: PNode) =
  if n.kind in nkCallKinds and n[0].kind == nkSym and n.len > 1:
    let s = n[0].sym
    if s.name.s[0] == '=' and s.name.s in ["=sink", "=", "=destroy"]:
      if sfFromGeneric in s.flags:
        excl(s.flags, sfFromGeneric)
        patchHead(s.getBody)
      if n[1].typ.isNil:
        # XXX toptree crashes without this workaround. Figure out why.
        return
      let t = n[1].typ.skipTypes({tyVar, tyLent, tyGenericInst, tyAlias, tySink, tyInferred})
      template patch(op, field) =
        if s.name.s == op and field != nil and field != s:
          n.sons[0].sym = field
      patch "=sink", t.sink
      patch "=", t.assignment
      patch "=destroy", t.destructor
  for x in n:
    patchHead(x)

proc patchHead(s: PSym) =
  if sfFromGeneric in s.flags:
    patchHead(s.ast[bodyPos])

template genOp(opr, opname) =
  let op = opr
  if op == nil:
    globalError(c.graph.config, dest.info, "internal error: '" & opname & "' operator not found for type " & typeToString(t))
  elif op.ast[genericParamsPos].kind != nkEmpty:
    globalError(c.graph.config, dest.info, "internal error: '" & opname & "' operator is generic")
  patchHead op
  result = newTree(nkCall, newSymNode(op), newTree(nkHiddenAddr, dest))

proc genSink(c: Con; t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  genOp(if t.sink != nil: t.sink else: t.assignment, "=sink")

proc genCopy(c: Con; t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  genOp(t.assignment, "=")

proc genDestroy(c: Con; t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  genOp(t.destructor, "=destroy")

proc addTopVar(c: var Con; v: PNode) =
  c.topLevelVars.add newTree(nkIdentDefs, v, c.emptyNode, c.emptyNode)

proc dropBit(c: var Con; s: PSym): PSym =
  result = c.toDropBit.getOrDefault(s.id)
  assert result != nil

proc registerDropBit(c: var Con; s: PSym) =
  let result = newSym(skTemp, getIdent(c.graph.cache, s.name.s & "_AliveBit"), c.owner, s.info)
  result.typ = getSysType(c.graph, s.info, tyBool)
  let trueVal = newIntTypeNode(nkIntLit, 1, result.typ)
  c.topLevelVars.add newTree(nkIdentDefs, newSymNode result, c.emptyNode, trueVal)
  c.toDropBit[s.id] = result
  # generate:
  #  if not sinkParam_AliveBit: `=destroy`(sinkParam)
  c.destroys.add newTree(nkIfStmt,
    newTree(nkElifBranch, newSymNode result, genDestroy(c, s.typ, newSymNode s)))

proc p(n: PNode; c: var Con): PNode

template recurse(n, dest) =
  for i in 0..<n.len:
    dest.add p(n[i], c)

proc isSinkParam(s: PSym): bool {.inline.} =
  result = s.kind == skParam and s.typ.kind == tySink

const constrExprs = nkCallKinds+{nkObjConstr}

proc destructiveMoveSink(n: PNode; c: var Con): PNode =
  # generate:  (chckMove(sinkParam_AliveBit); sinkParam_AliveBit = false; sinkParam)
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let bit = newSymNode dropBit(c, n.sym)
  if optMoveCheck in c.owner.options:
    result.add callCodegenProc(c.graph, "chckMove", bit)
  result.add newTree(nkAsgn, bit,
    newIntTypeNode(nkIntLit, 0, getSysType(c.graph, n.info, tyBool)))
  result.add n

proc moveOrCopy(dest, ri: PNode; c: var Con): PNode =
  if ri.kind in constrExprs:
    result = genSink(c, ri.typ, dest)
    # watch out and no not transform 'ri' twice if it's a call:
    let ri2 = copyNode(ri)
    recurse(ri, ri2)
    result.add ri2
  elif ri.kind == nkSym and isHarmlessVar(ri.sym, c):
    result = genSink(c, ri.typ, dest)
    result.add p(ri, c)
  elif ri.kind == nkSym and isSinkParam(ri.sym):
    result = genSink(c, ri.typ, dest)
    result.add destructiveMoveSink(ri, c)
  else:
    result = genCopy(c, ri.typ, dest)
    result.add p(ri, c)

proc passCopyToSink(n: PNode; c: var Con): PNode =
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let tmp = getTemp(c, n.typ, n.info)
  if hasDestructor(n.typ):
    var m = genCopy(c, n.typ, tmp)
    m.add p(n, c)
    result.add m
    message(c.graph.config, n.info, hintPerformance,
      "passing '$1' to a sink parameter introduces an implicit copy; " &
      "use 'move($1)' to prevent it" % $n)
  else:
    result.add newTree(nkAsgn, tmp, p(n, c))
  result.add tmp

proc genReset(n: PNode; c: var Con): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, "reset", mReset)))
  # The mReset builtin does not take the address:
  result.add n

proc destructiveMoveVar(n: PNode; c: var Con): PNode =
  # generate: (let tmp = v; reset(v); tmp)
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)

  var temp = newSym(skLet, getIdent(c.graph.cache, "blitTmp"), c.owner, n.info)
  var v = newNodeI(nkLetSection, n.info)
  let tempAsNode = newSymNode(temp)

  var vpart = newNodeI(nkIdentDefs, tempAsNode.info, 3)
  vpart.sons[0] = tempAsNode
  vpart.sons[1] = c.emptyNode
  vpart.sons[2] = n
  add(v, vpart)

  result.add v
  result.add genReset(n, c)
  result.add tempAsNode

proc p(n: PNode; c: var Con): PNode =
  case n.kind
  of nkVarSection, nkLetSection:
    discard "transform; var x = y to  var x; x op y  where op is a move or copy"
    result = newNodeI(nkStmtList, n.info)

    for i in 0..<n.len:
      let it = n[i]
      let L = it.len-1
      let ri = it[L]
      if it.kind == nkVarTuple and hasDestructor(ri.typ):
        let x = lowerTupleUnpacking(c.graph, it, c.owner)
        result.add p(x, c)
      elif it.kind == nkIdentDefs and hasDestructor(it[0].typ):
        for j in 0..L-2:
          let v = it[j]
          doAssert v.kind == nkSym
          # move the variable declaration to the top of the frame:
          c.addTopVar v
          # make sure it's destroyed at the end of the proc:
          c.destroys.add genDestroy(c, v.typ, v)
          if ri.kind != nkEmpty:
            let r = moveOrCopy(v, ri, c)
            result.add r
      else:
        # keep it, but transform 'ri':
        var varSection = copyNode(n)
        var itCopy = copyNode(it)
        for j in 0..L-1:
          itCopy.add it[j]
        itCopy.add p(ri, c)
        varSection.add itCopy
        result.add varSection
  of nkCallKinds:
    let parameters = n[0].typ
    let L = if parameters != nil: parameters.len else: 0
    for i in 1 ..< n.len:
      let arg = n[i]
      if i < L and parameters[i].kind == tySink:
        if arg.kind in nkCallKinds:
          # recurse but skip the call expression in order to prevent
          # destructor injections: Rule 5.1 is different from rule 5.4!
          let a = copyNode(arg)
          recurse(arg, a)
          n.sons[i] = a
        elif arg.kind in {nkObjConstr, nkCharLit..nkFloat128Lit}:
          discard "object construction to sink parameter: nothing to do"
        elif arg.kind == nkSym and isHarmlessVar(arg.sym, c):
          # if x is a variable and it its last read we eliminate its
          # destructor invokation, but don't. We need to reset its memory
          # to disable its destructor which we have not elided:
          n.sons[i] = destructiveMoveVar(arg, c)
        elif arg.kind == nkSym and isSinkParam(arg.sym):
          # mark the sink parameter as used:
          n.sons[i] = destructiveMoveSink(arg, c)
        else:
          # an object that is not temporary but passed to a 'sink' parameter
          # results in a copy.
          n.sons[i] = passCopyToSink(arg, c)
      else:
        n.sons[i] = p(arg, c)

    if n.typ != nil and hasDestructor(n.typ):
      discard "produce temp creation"
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let tmp = getTemp(c, n.typ, n.info)
      var sinkExpr = genSink(c, n.typ, tmp)
      sinkExpr.add n
      result.add sinkExpr
      result.add tmp
      c.destroys.add genDestroy(c, n.typ, tmp)
    else:
      result = n
  of nkAsgn, nkFastAsgn:
    if hasDestructor(n[0].typ):
      result = moveOrCopy(n[0], n[1], c)
    else:
      result = copyNode(n)
      recurse(n, result)
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef,
      nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    result = n
  else:
    result = copyNode(n)
    recurse(n, result)

proc injectDestructorCalls*(g: ModuleGraph; owner: PSym; n: PNode): PNode =
  when defined(nimDebugDestroys):
    echo "injecting into ", n
  var c: Con
  c.owner = owner
  c.tmp = newSym(skTemp, getIdent(g.cache, ":d"), owner, n.info)
  c.tmpObj = createObj(g, owner, n.info)
  c.tmp.typ = c.tmpObj
  c.destroys = newNodeI(nkStmtList, n.info)
  c.topLevelVars = newNodeI(nkVarSection, n.info)
  c.toDropBit = initTable[int, PSym]()
  c.graph = g
  c.emptyNode = newNodeI(nkEmpty, n.info)
  let cfg = constructCfg(owner, n)
  shallowCopy(c.g, cfg)
  c.jumpTargets = initIntSet()
  for i in 0..<c.g.len:
    if c.g[i].kind in {goto, fork}:
      c.jumpTargets.incl(i+c.g[i].dest)
  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1 ..< params.len:
      let param = params[i].sym
      if param.typ.kind == tySink: registerDropBit(c, param)
  let body = p(n, c)
  if c.tmp.typ.n.len > 0:
    c.addTopVar(newSymNode c.tmp)
  result = newNodeI(nkStmtList, n.info)
  if c.topLevelVars.len > 0:
    result.add c.topLevelVars
  if c.destroys.len > 0:
    result.add newTryFinally(body, c.destroys)
  else:
    result.add body

  when defined(nimDebugDestroys):
    if owner.name.s == "main" or true:
      echo "------------------------------------"
      echo owner.name.s, " transformed to: "
      echo result
