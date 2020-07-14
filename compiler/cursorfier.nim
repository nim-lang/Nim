#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Cursorfier:
## The basic idea was like this: Elide 'destroy(x)' calls if only
## special literals are assigned to 'x' and 'x' is not mutated or
## passed by 'var T' to something else. Special literals are string literals or
## arrays / tuples of string literals etc.
##
## However, there is a much more general rule here: Compute which variables
## can be annotated with `.cursor`. To see how and when we can do that,
## think about this question: In `dest = src` when do we really have to
## *materialize* the full copy? - Only if `dest` or `src` are mutated
## afterwards. `dest` is the potential cursor variable, so that is
## simple to analyse. And if `src` is a location derived from a
## formal parameter, we also know it is not mutated! In other words, we
## do a compile-time copy-on-write analysis.

import
  ast, types, renderer, idents, intsets

type
  Cursor = object
    s: PSym
    deps: IntSet
  Con = object
    cursors: seq[Cursor]
    mayOwnData: IntSet
    mutations: IntSet
    reassigns: IntSet

proc locationRoot(n: PNode): PSym =
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet, skForVar, skParam}:
      result = n.sym
  of nkDotExpr, nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
    result = locationRoot(n[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkCast:
    result = locationRoot(n[1])
  of nkStmtList, nkStmtListExpr:
    if n.len > 0:
      result = locationRoot(n[^1])
  else: discard

proc addDep(c: var Con; dest: var Cursor; dependsOn: PSym) =
  if dest.s != dependsOn:
    dest.deps.incl dependsOn.id

proc cursorId(c: Con; x: PSym): int =
  for i in 0..<c.cursors.len:
    if c.cursors[i].s == x: return i
  return -1

proc getCursors(c: Con): IntSet =
  #[
  Question: if x depends on y and y depends on z then also y depends on z.

    Or does it?

  var y = x # y gets the copy already

  var harmless = x

  y.s = "mutate"

  ]#
  result = initIntSet()
  for cur in c.cursors:
    if not c.mayOwnData.contains(cur.s.id) and
        cur.s.typ.skipTypes({tyGenericInst, tyAlias}).kind != tyOwned:
      block doAdd:
        for d in cur.deps:
          # you cannot borrow from a location that is mutated or (owns data and is re-assigned)
          if c.mutations.contains(d) or (c.mayOwnData.contains(d) and c.reassigns.contains(d)):
            #echo "bah, not a cursor ", cur.s, " bad dependency ", d
            break doAdd
        result.incl cur.s.id
        when false:
          echo "computed as a cursor ", cur.s, " ", cur.deps, " ", cur.s.info.line

proc analyseAsgn(c: var Con; dest: var Cursor; n: PNode) =
  case n.kind
  of nkEmpty, nkCharLit..pred(nkNilLit):
    # primitive literals including the empty are harmless:
    discard
  of nkNilLit:
    when false:
      # XXX think about this case. Is 'nil' an owned location?
      if hasDestructor(n.typ):
        # 'myref = nil' is destructive and so 'myref' should not be a cursor:
        c.mayOwnData.incl dest.s.id

  of nkExprEqExpr, nkExprColonExpr, nkHiddenStdConv, nkHiddenSubConv, nkCast, nkConv:
    analyseAsgn(c, dest, n[1])

  of nkIfStmt, nkIfExpr:
    for i in 0..<n.len:
      analyseAsgn(c, dest, n[i].lastSon)

  of nkCaseStmt:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i].lastSon)

  of nkStmtList, nkStmtListExpr:
    if n.len > 0:
      analyseAsgn(c, dest, n[^1])

  of nkClosure:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i])
    # you must destroy a closure:
    c.mayOwnData.incl dest.s.id

  of nkObjConstr:
    for i in 1..<n.len:
      analyseAsgn(c, dest, n[i])
    if hasDestructor(n.typ):
      # you must destroy a ref object:
      c.mayOwnData.incl dest.s.id

  of nkCurly, nkBracket, nkPar, nkTupleConstr:
    for son in n:
      analyseAsgn(c, dest, son)
    if n.typ.skipTypes(abstractInst).kind == tySequence:
      # you must destroy a sequence:
      c.mayOwnData.incl dest.s.id

  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet, skForVar, skParam} and
        hasDestructor(n.typ):
      if n.sym.flags * {sfThread, sfGlobal} != {}:
        # aliasing a global is inherently dangerous:
        c.mayOwnData.incl dest.s.id
      else:
        # otherwise it's just a dependency, nothing to worry about:
        c.addDep(dest, n.sym)

  of nkDotExpr, nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr, nkAddr, nkHiddenAddr:
    analyseAsgn(c, dest, n[0])

  of nkCallKinds:
    if hasDestructor(n.typ):
      # calls do construct, what we construct must be destroyed,
      # so dest cannot be a cursor:
      c.mayOwnData.incl dest.s.id
    elif n.typ.kind in {tyLent, tyVar}:
      # we know the result is derived from the first argument:
      let r = locationRoot(n[1])
      if r != nil:
        c.addDep(dest, r)
    else:
      let magic = if n[0].kind == nkSym: n[0].sym.magic else: mNone
      # this list is subtle, we try to answer the question if after 'dest = f(src)'
      # there is a connection betwen 'src' and 'dest' so that mutations to 'src'
      # also reflect 'dest':
      if magic in {mNone, mMove, mSlice, mAppendStrCh, mAppendStrStr, mAppendSeqElem, mArrToSeq}:
        for i in 1..<n.len:
          # we always have to assume a 'select(...)' like mechanism.
          # But at least we do filter out simple POD types from the
          # list of dependencies via the 'hasDestructor' check for
          # the root's symbol.
          if hasDestructor(n[i].typ):
            analyseAsgn(c, dest, n[i])

  else:
    # something we cannot handle:
    c.mayOwnData.incl dest.s.id

proc analyse(c: var Con; n: PNode) =
  case n.kind
  of nkCallKinds:
    let parameters = n[0].typ
    let L = if parameters != nil: parameters.len else: 0

    analyse(c, n[0])
    for i in 1..<n.len:
      let it = n[i]
      let r = locationRoot(it)
      if r != nil and i < L:
        let paramType = parameters[i].skipTypes({tyGenericInst, tyAlias})
        if paramType.kind in {tyVar, tySink, tyOwned}:
          # pass by var? mayOwnData the root
          # Else we seek to take ownership of 'r'. This is only valid when 'r'
          # actually owns its data. Thus 'r' cannot be a cursor:
          c.mayOwnData.incl r.id
          # and we assume it might get wasMoved(...) too:
          c.mutations.incl r.id
      analyse(c, it)

  of nkAsgn, nkFastAsgn:
    analyse(c, n[0])
    analyse(c, n[1])

    if n[0].kind == nkSym:
      if hasDestructor(n[0].typ):
        # re-assignment to the full object is fundamentally different:
        let idx = cursorId(c, n[0].sym)
        if idx >= 0:
          analyseAsgn(c, c.cursors[idx], n[1])

        c.reassigns.incl n[0].sym.id
    else:
      # assignments like 'x.field = value' mean that 'x' itself cannot
      # be a cursor:
      let r = locationRoot(n[0])
      if r != nil and r.typ.skipTypes(abstractInst).kind notin {tyPtr, tyRef}:
        # however, an assignment like 'it.field = x' does not influence r's
        # cursorness property:
        c.mayOwnData.incl r.id
        c.mutations.incl r.id

    when false:
      # XXX think about this
      if n[1].kind == nkSym and hasDestructor(n[1].typ):
        # let x = cursor?
        let s = n[1].sym
        c.mayOwnData.incl s.id
        # and we assume it might get wasMoved(...) too:
        c.mutations.incl s.id

  of nkAddr, nkHiddenAddr:
    analyse(c, n[0])
    let r = locationRoot(n[0])
    if r != nil:
      c.mayOwnData.incl r.id
      c.mutations.incl r.id

  of nkVarSection, nkLetSection:
    for it in n:
      let value = it[^1]
      analyse(c, value)
      if hasDestructor(it[0].typ):
        for i in 0..<it.len-2:
          let v = it[i]
          if v.kind == nkSym and v.sym.flags * {sfThread, sfGlobal} == {}:
            # assume it's a cursor:
            c.cursors.add Cursor(s: it[i].sym)
            if it.kind == nkVarTuple and value.kind in {nkPar, nkTupleConstr} and
                it.len-2 == value.len:
              # this might mayOwnData it again:
              analyseAsgn(c, c.cursors[^1], value[i])
            else:
              # this might mayOwnData it again:
              analyseAsgn(c, c.cursors[^1], value)

  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
    discard
  else:
    for child in n: analyse(c, child)

proc computeCursors*(n: PNode): IntSet =
  var c: Con
  analyse(c, n)
  result = getCursors c
