#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements destructors.


# special marker values that indicates that we are
# 1) AnalyzingDestructor: currently analyzing the type for destructor
# generation (needed for recursive types)
# 2) DestructorIsTrivial: completed the analysis before and determined
# that the type has a trivial destructor
var AnalyzingDestructor, DestructorIsTrivial: PSym
new(AnalyzingDestructor)
new(DestructorIsTrivial)

var
  destructorName = getIdent"destroy_"
  destructorParam = getIdent"this_"
  destructorPragma = newIdentNode(getIdent"destructor", UnknownLineInfo())
  rangeDestructorProc*: PSym

proc instantiateDestructor(c: PContext, typ: PType): bool

proc doDestructorStuff(c: PContext, s: PSym, n: PNode) =
  let t = s.typ.sons[1].skipTypes({tyVar})
  t.destructor = s
  # automatically insert calls to base classes' destructors
  if n.sons[bodyPos].kind != nkEmpty:
    for i in countup(0, t.sonsLen - 1):
      # when inheriting directly from object
      # there will be a single nil son
      if t.sons[i] == nil: continue
      if instantiateDestructor(c, t.sons[i]):
        n.sons[bodyPos].addSon(newNode(nkCall, t.sym.info, @[
            useSym(t.sons[i].destructor),
            n.sons[paramsPos][1][0]]))

proc destroyField(c: PContext, field: PSym, holder: PNode): PNode =
  if instantiateDestructor(c, field.typ):
    result = newNode(nkCall, field.info, @[
      useSym(field.typ.destructor),
      newNode(nkDotExpr, field.info, @[holder, useSym(field)])])

proc destroyCase(c: PContext, n: PNode, holder: PNode): PNode =
  var nonTrivialFields = 0
  result = newNode(nkCaseStmt, n.info, @[])
  # case x.kind
  result.addSon(newNode(nkDotExpr, n.info, @[holder, n.sons[0]]))
  for i in countup(1, n.len - 1):
    # of A, B:
    var caseBranch = newNode(n[i].kind, n[i].info, n[i].sons[0 .. -2])
    let recList = n[i].lastSon
    var destroyRecList = newNode(nkStmtList, n[i].info, @[])
    template addField(f: expr): stmt =
      let stmt = destroyField(c, f, holder)
      if stmt != nil:
        destroyRecList.addSon(stmt)
        inc nonTrivialFields

    case recList.kind
    of nkSym:
      addField(recList.sym)
    of nkRecList:
      for j in countup(0, recList.len - 1):
        addField(recList[j].sym)
    else:
      internalAssert false

    caseBranch.addSon(destroyRecList)
    result.addSon(caseBranch)
  # maybe no fields were destroyed?
  if nonTrivialFields == 0:
    result = nil

proc generateDestructor(c: PContext, t: PType): PNode =
  ## generate a destructor for a user-defined object or tuple type
  ## returns nil if the destructor turns out to be trivial

  template addLine(e: expr): stmt =
    if result == nil: result = newNode(nkStmtList)
    result.addSon(e)

  # XXX: This may be true for some C-imported types such as
  # Tposix_spawnattr
  if t.n == nil or t.n.sons == nil: return
  internalAssert t.n.kind == nkRecList
  let destructedObj = newIdentNode(destructorParam, UnknownLineInfo())
  # call the destructods of all fields
  for s in countup(0, t.n.sons.len - 1):
    case t.n.sons[s].kind
    of nkRecCase:
      let stmt = destroyCase(c, t.n.sons[s], destructedObj)
      if stmt != nil: addLine(stmt)
    of nkSym:
      let stmt = destroyField(c, t.n.sons[s].sym, destructedObj)
      if stmt != nil: addLine(stmt)
    else:
      internalAssert false
  # base classes' destructors will be automatically called by
  # semProcAux for both auto-generated and user-defined destructors

proc instantiateDestructor(c: PContext, typ: PType): bool =
  # returns true if the type already had a user-defined
  # destructor or if the compiler generated a default
  # member-wise one
  var t = skipTypes(typ, {tyConst, tyMutable})

  if t.destructor != nil:
    # XXX: This is not entirely correct for recursive types, but we need
    # it temporarily to hide the "destroy is already defined" problem
    return t.destructor notin [AnalyzingDestructor, DestructorIsTrivial]

  case t.kind
  of tySequence, tyArray, tyArrayConstr, tyOpenArray, tyVarargs:
    if instantiateDestructor(c, t.sons[0]):
      if rangeDestructorProc == nil:
        rangeDestructorProc = searchInScopes(c, getIdent"nimDestroyRange")
      t.destructor = rangeDestructorProc
      return true
    else:
      return false
  of tyTuple, tyObject:
    t.destructor = AnalyzingDestructor
    let generated = generateDestructor(c, t)
    if generated != nil:
      internalAssert t.sym != nil
      var i = t.sym.info
      let fullDef = newNode(nkProcDef, i, @[
        newIdentNode(destructorName, i),
        emptyNode,
        emptyNode,
        newNode(nkFormalParams, i, @[
          emptyNode,
          newNode(nkIdentDefs, i, @[
            newIdentNode(destructorParam, i),
            useSym(t.sym),
            emptyNode]),
          ]),
        newNode(nkPragma, i, @[destructorPragma]),
        emptyNode,
        generated
        ])
      discard semProc(c, fullDef)
      internalAssert t.destructor != nil
      return true
    else:
      t.destructor = DestructorIsTrivial
      return false
  else:
    return false

proc insertDestructors(c: PContext,
                       varSection: PNode): tuple[outer, inner: PNode] =
  # Accepts a var or let section.
  #
  # When a var section has variables with destructors
  # the var section is split up and finally blocks are inserted
  # immediately after all "destructable" vars
  #
  # In case there were no destrucable variables, the proc returns
  # (nil, nil) and the enclosing stmt-list requires no modifications.
  #
  # Otherwise, after the try blocks are created, the rest of the enclosing
  # stmt-list should be inserted in the most `inner` such block (corresponding
  # to the last variable).
  #
  # `outer` is a statement list that should replace the original var section.
  # It will include the new truncated var section followed by the outermost
  # try block.
  let totalVars = varSection.sonsLen
  for j in countup(0, totalVars - 1):
    let
      varId = varSection[j][0]
      varTyp = varId.sym.typ
      info = varId.info

    if varTyp != nil and instantiateDestructor(c, varTyp) and
        sfGlobal notin varId.sym.flags:
      var tryStmt = newNodeI(nkTryStmt, info)

      if j < totalVars - 1:
        var remainingVars = newNodeI(varSection.kind, info)
        remainingVars.sons = varSection.sons[(j+1)..(-1)]
        let (outer, inner) = insertDestructors(c, remainingVars)
        if outer != nil:
          tryStmt.addSon(outer)
          result.inner = inner
        else:
          result.inner = newNodeI(nkStmtList, info)
          result.inner.addSon(remainingVars)
          tryStmt.addSon(result.inner)
      else:
        result.inner = newNodeI(nkStmtList, info)
        tryStmt.addSon(result.inner)

      tryStmt.addSon(
        newNode(nkFinally, info, @[
          semStmt(c, newNode(nkCall, info, @[
            useSym(varTyp.destructor),
            useSym(varId.sym)]))]))

      result.outer = newNodeI(nkStmtList, info)
      varSection.sons.setLen(j+1)
      result.outer.addSon(varSection)
      result.outer.addSon(tryStmt)

      return
