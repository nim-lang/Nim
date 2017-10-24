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


import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  strutils, options, dfa, lowerings, rodread

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
    if sfFromGeneric in s.flags and s.name.s[0] == '=' and
        s.name.s in ["=sink", "=", "=destroy"]:
      excl(s.flags, sfFromGeneric)
      patchHead(s.getBody)
      let t = n[1].typ.skipTypes({tyVar, tyGenericInst, tyAlias, tyInferred})
      template patch(op, field) =
        if s.name.s == op and field != nil and field != s:
          n.sons[0].sym = field
      patch "=sink", t.sink
      patch "=", t.assignment
      patch "=destroy", t.destructor
  for x in n:
    patchHead(x)

proc genSink(t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias})
  let op = if t.sink != nil: t.sink else: t.assignment
  assert op != nil
  patchHead op.ast[bodyPos]
  result = newTree(nkCall, newSymNode(op), newTree(nkHiddenAddr, dest))

proc genCopy(t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias})
  assert t.assignment != nil
  patchHead t.assignment.ast[bodyPos]
  result = newTree(nkCall, newSymNode(t.assignment), newTree(nkHiddenAddr, dest))

proc genDestroy(t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias})
  assert t.destructor != nil
  patchHead t.destructor.ast[bodyPos]
  result = newTree(nkCall, newSymNode(t.destructor), newTree(nkHiddenAddr, dest))

proc addTopVar(c: var Con; v: PNode) =
  c.topLevelVars.add newTree(nkIdentDefs, v, emptyNode, emptyNode)

proc p(n: PNode; c: var Con): PNode

template recurse(n, dest) =
  for i in 0..<n.len:
    dest.add p(n[i], c)

proc moveOrCopy(dest, ri: PNode; c: var Con): PNode =
  if ri.kind in nkCallKinds:
    result = genSink(ri.typ, dest)
    # watch out and no not transform 'ri' twice if it's a call:
    let ri2 = copyNode(ri)
    recurse(ri, ri2)
    result.add ri2
  elif ri.kind == nkSym and isHarmlessVar(ri.sym, c):
    result = genSink(ri.typ, dest)
    result.add p(ri, c)
  else:
    result = genCopy(ri.typ, dest)
    result.add p(ri, c)

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
        let x = lowerTupleUnpacking(it, c.owner)
        result.add p(x, c)
      elif it.kind == nkIdentDefs and hasDestructor(it[0].typ):
        for j in 0..L-2:
          let v = it[j]
          doAssert v.kind == nkSym
          # move the variable declaration to the top of the frame:
          c.addTopVar v
          # make sure it's destroyed at the end of the proc:
          c.destroys.add genDestroy(v.typ, v)
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
    if n.typ != nil and hasDestructor(n.typ):
      discard "produce temp creation"
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let f = newSym(skField, getIdent(":d" & $c.tmpObj.n.len), c.owner, n.info)
      f.typ = n.typ
      rawAddField c.tmpObj, f
      var m = genSink(n.typ, rawDirectAccess(c.tmp, f))
      var call = copyNode(n)
      recurse(n, call)
      m.add call
      result.add m
      result.add rawDirectAccess(c.tmp, f)
      c.destroys.add genDestroy(n.typ, rawDirectAccess(c.tmp, f))
    else:
      result = copyNode(n)
      recurse(n, result)
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

proc injectDestructorCalls*(owner: PSym; n: PNode): PNode =
  var c: Con
  c.owner = owner
  c.tmp = newSym(skTemp, getIdent":d", owner, n.info)
  c.tmpObj = createObj(owner, n.info)
  c.tmp.typ = c.tmpObj
  c.destroys = newNodeI(nkStmtList, n.info)
  c.topLevelVars = newNodeI(nkVarSection, n.info)
  let cfg = constructCfg(owner, n)
  shallowCopy(c.g, cfg)
  c.jumpTargets = initIntSet()
  for i in 0..<c.g.len:
    if c.g[i].kind in {goto, fork}:
      c.jumpTargets.incl(i+c.g[i].dest)
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
    if owner.name.s == "createSeq":
      echo "------------------------------------"
      echo owner.name.s, " transformed to: "
      echo result
