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
## The algorithm operates in 2 phases:
##
##   * Collecting information about assignments (and pass-by-var calls).
##   * Computing an aliasing relation based on the assignments. This relation
##     is then used to compute the 'writes' and 'escapes' effects.

import intsets, idents, ast, astalgo, trees, renderer, msgs, types, options,
  lineinfos

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
  RootInfo = enum
    rootIsResultOrParam,
    rootIsHeapAccess,
    rootIsSym,
    markAsWrittenTo,
    markAsEscaping

  Assignment = object # \
    # Note that the transitive closures MUST be computed in
    # phase 2 of the algorithm.
    dest, src: seq[ptr TSym] # we use 'ptr' here to save RC ops and GC cycles
    destNoTc, srcNoTc: int # length of 'dest', 'src' without the
                           # transitive closure
    destInfo: set[RootInfo]
    info: TLineInfo

  W = object # WriteTrackContext
    owner: PSym
    returnsNew: AssignToResult # assignments to 'result'
    assignments: seq[Assignment] # list of all assignments in this proc

proc allRoots(n: PNode; result: var seq[ptr TSym]; info: var set[RootInfo]) =
  case n.kind
  of nkSym:
    if n.sym.kind in {skParam, skVar, skTemp, skLet, skResult, skForVar}:
      if n.sym.kind in {skResult, skParam}: incl(info, rootIsResultOrParam)
      result.add(cast[ptr TSym](n.sym))
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

proc addAsgn(a: var Assignment; dest, src: PNode; destInfo: set[RootInfo]) =
  a.dest = @[]
  a.src = @[]
  a.destInfo = destInfo
  allRoots(dest, a.dest, a.destInfo)
  if dest.kind == nkSym: incl(a.destInfo, rootIsSym)
  if src != nil:
    var dummy: set[RootInfo]
    allRoots(src, a.src, dummy)
  a.destNoTc = a.dest.len
  a.srcNoTc = a.src.len
  a.info = dest.info
  #echo "ADDING ", dest.info, " ", a.destInfo

proc srcHasSym(a: Assignment; x: ptr TSym): bool =
  for i in 0 ..< a.srcNoTc:
    if a.src[i] == x: return true

proc returnsNewExpr*(n: PNode): NewLocation =
  case n.kind
  of nkCharLit..nkInt64Lit, nkStrLit..nkTripleStrLit,
      nkFloatLit..nkFloat64Lit, nkNilLit:
    result = newLit
  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv,
      nkStmtList, nkStmtListExpr, nkBlockStmt, nkBlockExpr, nkOfBranch,
      nkElifBranch, nkElse, nkExceptBranch, nkFinally, nkCast:
    result = returnsNewExpr(n.lastSon)
  of nkCurly, nkBracket, nkPar, nkTupleConstr, nkObjConstr, nkClosure,
      nkIfExpr, nkIfStmt, nkWhenStmt, nkCaseStmt, nkTryStmt, nkHiddenTryStmt:
    result = newLit
    for i in ord(n.kind == nkObjConstr) ..< n.len:
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

proc deps(w: var W; dest, src: PNode; destInfo: set[RootInfo]) =
  # let x = (localA, localB)
  # compute 'returnsNew' property:
  let retNew = if src.isNil: newNone else: returnsNewExpr(src)
  if dest.kind == nkSym and dest.sym.kind == skResult:
    if retNew != newNone:
      if w.returnsNew != asgnOther: w.returnsNew = asgnNew
    else:
      w.returnsNew = asgnOther
  # mark the dependency, but
  # rule out obviously innocent assignments like 'somebool = true'
  if dest.kind == nkSym and retNew == newLit: discard
  else:
    let L = w.assignments.len
    w.assignments.setLen(L+1)
    addAsgn(w.assignments[L], dest, src, destInfo)

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
      var destInfo: set[RootInfo] = {}
      if sfWrittenTo in paramType.sym.flags or paramType.typ.kind == tyVar:
        # p(f(x, y), X, g(h, z))
        destInfo.incl markAsWrittenTo
      if sfEscapes in paramType.sym.flags:
        destInfo.incl markAsEscaping
      if destInfo != {}:
        deps(w, it, nil, destInfo)

proc deps(w: var W; n: PNode) =
  case n.kind
  of nkLetSection, nkVarSection:
    for child in n:
      let last = lastSon(child)
      if last.kind == nkEmpty: continue
      if child.kind == nkVarTuple and last.kind in {nkPar, nkTupleConstr}:
        if child.len-2 != last.len: return
        for i in 0 .. child.len-3:
          deps(w, child.sons[i], last.sons[i], {})
      else:
        for i in 0 .. child.len-3:
          deps(w, child.sons[i], last, {})
  of nkAsgn, nkFastAsgn:
    deps(w, n.sons[0], n.sons[1], {})
  else:
    for i in 0 ..< n.safeLen:
      deps(w, n.sons[i])
    if n.kind in nkCallKinds:
      if getMagic(n) in {mNew, mNewFinalize, mNewSeq}:
        # may not look like an assignment, but it is:
        deps(w, n.sons[1], newNodeIT(nkObjConstr, n.info, n.sons[1].typ), {})
      else:
        depsArgs(w, n)

proc possibleAliases(w: var W; result: var seq[ptr TSym]) =
  # this is an expensive fixpoint iteration. We could speed up this analysis
  # by a smarter data-structure but we wait until profiling shows us it's
  # expensive. Usually 'w.assignments' is small enough.
  var alreadySeen = initIntSet()
  template addNoDup(x) =
    if not alreadySeen.containsOrIncl(x.id): result.add x
  for x in result: alreadySeen.incl x.id

  var todo = 0
  while todo < result.len:
    let x = result[todo]
    inc todo
    for i in 0..<len(w.assignments):
      let a = addr(w.assignments[i])
      #if a.srcHasSym(x):
      #  # y = f(..., x, ...)
      #  for i in 0 ..< a.destNoTc: addNoDup a.dest[i]
      if a.destNoTc > 0 and a.dest[0] == x and rootIsSym in a.destInfo:
        # x = f(..., y, ....)
        for i in 0 ..< a.srcNoTc: addNoDup a.src[i]

proc markWriteOrEscape(w: var W; conf: ConfigRef) =
  ## Both 'writes' and 'escapes' effects ultimately only care
  ## about *parameters*.
  ## However, due to aliasing, even locals that might not look as parameters
  ## have to count as parameters if they can alias a parameter:
  ##
  ## .. code-block:: nim
  ##   proc modifies(n: Node) {.writes: [n].} =
  ##     let x = n
  ##     x.data = "abc"
  ##
  ## We call a symbol *parameter-like* if it is a parameter or can alias a
  ## parameter.
  ## Let ``p``, ``q`` be *parameter-like* and ``x``, ``y`` be general
  ## expressions.
  ##
  ## A write then looks like ``p[] = x``.
  ## An escape looks like ``p[] = q`` or more generally
  ## like ``p[] = f(q)`` where ``f`` can forward ``q``.
  for i in 0..<len(w.assignments):
    let a = addr(w.assignments[i])
    if a.destInfo != {}:
      possibleAliases(w, a.dest)

    if {rootIsHeapAccess, markAsWrittenTo} * a.destInfo != {}:
      for p in a.dest:
        if p.kind == skParam and p.owner == w.owner:
          incl(p.flags, sfWrittenTo)
          if w.owner.kind == skFunc and p.typ.kind != tyVar:
            localError(conf, a.info, "write access to non-var parameter: " & p.name.s)

    if {rootIsResultOrParam, rootIsHeapAccess, markAsEscaping}*a.destInfo != {}:
      var destIsParam = false
      for p in a.dest:
        if p.kind in {skResult, skParam} and p.owner == w.owner:
          destIsParam = true
          break
      if destIsParam:
        possibleAliases(w, a.src)
        for p in a.src:
          if p.kind == skParam and p.owner == w.owner:
            incl(p.flags, sfEscapes)

proc trackWrites*(owner: PSym; body: PNode; conf: ConfigRef) =
  var w: W
  w.owner = owner
  w.assignments = @[]
  # Phase 1: Collect and preprocess any assignments in the proc body:
  deps(w, body)
  # Phase 2: Compute the 'writes' and 'escapes' effects:
  markWriteOrEscape(w, conf)
  if w.returnsNew != asgnOther and not isEmptyType(owner.typ.sons[0]) and
      containsGarbageCollectedRef(owner.typ.sons[0]):
    incl(owner.typ.flags, tfReturnsNew)
