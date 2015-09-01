#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the write tracking analysis. Read my block post for
## a basic description of the algorithm and ideas.

import idents, ast, astalgo, trees, renderer, msgs, types

const
  debug = false

type
  AssignToResult = enum
    asgnNil,   # 'nil' is fine
    asgnNew,   # 'new(result)'
    asgnOther  # result = fooBar # not a 'new' --> 'result' might not 'new'
  NewLocation = enum
    newNone,
    newLit,
    newCall
  W = object # WriteTrackContext
    owner: PSym
    returnsNew: AssignToResult # assignments to 'result'
    markAsWrittenTo, markAsEscaping: PNode
    assignments: seq[(PNode, PNode)] # list of all assignments in this proc

proc returnsNewExpr*(n: PNode): NewLocation =
  case n.kind
  of nkCharLit..nkInt64Lit, nkStrLit..nkTripleStrLit,
      nkFloatLit..nkFloat64Lit, nkNilLit:
    result = newLit
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv,
      nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkOfBranch,
      nkElifBranch, nkElse, nkExceptBranch, nkFinally, nkCast:
    result = returnsNewExpr(n.lastSon)
  of nkCurly, nkBracket, nkPar, nkObjConstr, nkClosure,
      nkIfExpr, nkIfStmt, nkWhenStmt, nkCaseStmt, nkTryStmt:
    result = newLit
    for i in ord(n.kind == nkObjConstr) .. <n.len:
      let x = returnsNewExpr(n.sons[i])
      case x
      of newNone: return newNone
      of newLit: discard
      of newCall: result = newCall
  of nkCallKinds:
    if n.sons[0].typ != nil and tfReturnsNew in n.sons[0].typ.flags:
      result = newCall
  else:
    result = newNone

proc deps(w: var W; dest, src: PNode) =
  # let x = (localA, localB)
  # compute 'returnsNew' property:
  let retNew = returnsNewExpr(src)
  if dest.kind == nkSym and dest.sym.kind == skResult:
    if retNew != newNone:
      if w.returnsNew != asgnOther: w.returnsNew = asgnNew
    else:
      w.returnsNew = asgnOther
  # mark the dependency, but
  # rule out obviously innocent assignments like 'somebool = true'
  if dest.kind == nkSym and retNew == newLit: discard
  else: w.assignments.add((dest, src))

proc depsArgs(w: var W; n: PNode) =
  if n.sons[0].typ.isNil: return
  var typ = skipTypes(n.sons[0].typ, abstractInst)
  if typ.kind != tyProc: return
  # echo n.info, " ", n, " ", w.owner.name.s, " ", typeToString(typ)
  assert(sonsLen(typ) == sonsLen(typ.n))
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if i < sonsLen(typ):
      assert(typ.n.sons[i].kind == nkSym)
      let paramType = typ.n.sons[i]
      if paramType.typ.isCompileTimeOnly: continue
      if sfWrittenTo in paramType.sym.flags or paramType.typ.kind == tyVar:
        # p(f(x, y), X, g(h, z))
        deps(w, it, w.markAsWrittenTo)
      if sfEscapes in paramType.sym.flags or paramType.typ.kind == tyVar:
        deps(w, it, w.markAsEscaping)

proc deps(w: var W; n: PNode) =
  case n.kind
  of nkLetSection, nkVarSection:
    for child in n:
      let last = lastSon(child)
      if last.kind == nkEmpty: continue
      if child.kind == nkVarTuple and last.kind == nkPar:
        internalAssert child.len-2 == last.len
        for i in 0 .. child.len-3:
          deps(w, child.sons[i], last.sons[i])
      else:
        for i in 0 .. child.len-3:
          deps(w, child.sons[i], last)
  of nkAsgn, nkFastAsgn:
    deps(w, n.sons[0], n.sons[1])
  else:
    for i in 0 ..< n.safeLen:
      deps(w, n.sons[i])
    if n.kind in nkCallKinds:
      if getMagic(n) in {mNew, mNewFinalize, mNewSeq}:
        # may not look like an assignment, but it is:
        deps(w, n.sons[1], newNodeIT(nkObjConstr, n.info, n.sons[1].typ))
      else:
        depsArgs(w, n)

type
  RootInfo = enum
    rootIsResultOrParam,
    rootIsHeapAccess

proc allRoots(n: PNode; result: var seq[PSym]; info: var set[RootInfo]) =
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      if result.isNil: result = @[]
      if n.sym notin result:
        if n.sym.kind in {skResult, skParam}: incl(info, rootIsResultOrParam)
        result.add n.sym
  of nkHiddenDeref, nkDerefExpr:
    incl(info, rootIsHeapAccess)
    allRoots(n.sons[0], result, info)
  of nkDotExpr, nkBracketExpr, nkCheckedFieldExpr,
      nkHiddenAddr, nkObjUpConv, nkObjDownConv:
    allRoots(n.sons[0], result, info)
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv, nkConv,
      nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkOfBranch,
      nkElifBranch, nkElse, nkExceptBranch, nkFinally, nkCast:
    allRoots(n.lastSon, result, info)
  of nkCallKinds:
    if getMagic(n) == mSlice:
      allRoots(n.sons[1], result, info)
    else:
      # we do significantly better here by using the available escape
      # information:
      if n.sons[0].typ.isNil: return
      var typ = n.sons[0].typ
      if typ != nil:
        typ = skipTypes(typ, abstractInst)
        if typ.kind != tyProc: typ = nil
        else: assert(sonsLen(typ) == sonsLen(typ.n))

      for i in 1 ..< n.len:
        let it = n.sons[i]
        if typ != nil and i < sonsLen(typ):
          assert(typ.n.sons[i].kind == nkSym)
          let paramType = typ.n.sons[i]
          if paramType.typ.isCompileTimeOnly: continue
          if sfEscapes in paramType.sym.flags or paramType.typ.kind == tyVar:
            allRoots(it, result, info)
        else:
          allRoots(it, result, info)
  else:
    for i in 0..<n.safeLen:
      allRoots(n.sons[i], result, info)

proc allRoots(n: PNode; result: var seq[PSym]) =
  var dummy: set[RootInfo]
  allRoots(n, result, dummy)

proc hasSym(n: PNode; x: PSym): bool =
  when false:
    if n.kind == nkSym:
      result = n.sym == x
    else:
      for i in 0..safeLen(n)-1:
        if hasSym(n.sons[i], x): return true
  else:
    var tmp: seq[PSym]
    allRoots(n, tmp)
    result = not tmp.isNil and x in tmp

when debug:
  proc `$`*(x: PSym): string = x.name.s

proc possibleAliases(w: W; result: var seq[PSym]) =
  var todo = 0
  # this is an expensive fixpoint iteration. We could speed up this analysis
  # by a smarter data-structure but we wait until prolifing shows us it's
  # expensive. Usually 'w.assignments' is small enough.
  while todo < result.len:
    let x = result[todo]
    inc todo
    when debug:
      if w.owner.name.s == "m3": echo "select ", x, " ", todo, " ", result.len
    for dest, src in items(w.assignments):
      if src.hasSym(x):
        # dest = f(..., s, ...)
        allRoots(dest, result)
        when debug:
          if w.owner.name.s == "m3": echo "A ", result
      elif dest.kind == nkSym and dest.sym == x:
        # s = f(..., x, ....)
        allRoots(src, result)
        when debug:
          if w.owner.name.s == "m3": echo "B ", result
      else:
        when debug:
          if w.owner.name.s == "m3": echo "C ", x, " ", todo, " ", result.len

proc markDirty(w: W) =
  for dest, src in items(w.assignments):
    var r: seq[PSym] = nil
    var info: set[RootInfo]
    allRoots(dest, r, info)
    when debug:
      if w.owner.info ?? "temp18":
        echo "ASGN ", dest,  " = ", src, " |", heapAccess, " ", r.name.s
    if rootIsHeapAccess in info or src == w.markAsWrittenTo:
      # we have an assignment like:
      # local.foo = bar
      # --> check which parameter it may alias and mark these parameters
      # as dirty:
      possibleAliases(w, r)
      for a in r:
        if a.kind == skParam and a.owner == w.owner:
          incl(a.flags, sfWrittenTo)

proc markEscaping(w: W) =
  # let p1 = p
  # let p2 = q
  # p2.x = call(..., p1, ...)
  for dest, src in items(w.assignments):
    var r: seq[PSym] = nil
    var info: set[RootInfo]
    allRoots(dest, r, info)

    if (r.len > 0) and (info != {} or src == w.markAsEscaping):
      possibleAliases(w, r)
      var destIsParam = false
      for a in r:
        if a.kind in {skResult, skParam} and a.owner == w.owner:
          destIsParam = true
          break
      if destIsParam:
        var victims: seq[PSym] = @[]
        allRoots(src, victims)
        possibleAliases(w, victims)
        for v in victims:
          if v.kind == skParam and v.owner == w.owner:
            incl(v.flags, sfEscapes)

proc trackWrites*(owner: PSym; body: PNode) =
  var w: W
  w.owner = owner
  w.markAsWrittenTo = newNodeI(nkArgList, body.info)
  w.markAsEscaping = newNodeI(nkArgList, body.info)
  w.assignments = @[]
  deps(w, body)
  markDirty(w)
  markEscaping(w)
  if w.returnsNew != asgnOther and not isEmptyType(owner.typ.sons[0]) and
      containsGarbageCollectedRef(owner.typ.sons[0]):
    incl(owner.typ.flags, tfReturnsNew)

