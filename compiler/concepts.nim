#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## New styled concepts for Nim. See https://github.com/nim-lang/RFCs/issues/168
## for details. Note this is a first implementation and only the "Concept matching"
## section has been implemented.

import ast, astalgo, semdata, lookups, lineinfos, idents, msgs, renderer,
  types, intsets

proc declareSelf(c: PContext; info: TLineInfo) =
  let ow = getCurrOwner(c)
  let s = newSym(skType, getIdent(c.cache, "self"), ow, info)
  s.typ = newType(tyTypeDesc, ow)
  s.typ.flags.incl {tfUnresolved, tfPacked}
  s.typ.add newType(tyEmpty, ow)
  addDecl(c, s, info)

proc isSelf*(t: PType): bool {.inline.} =
  t.kind == tyTypeDesc and tfPacked in t.flags

proc semConceptDecl(c: PContext; n: PNode): PNode =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    result = shallowCopy(n)
    for i in 0..<n.len:
      result[i] = semConceptDecl(c, n[i])
  of nkProcDef..nkIteratorDef, nkFuncDef:
    result = c.semExpr(c, n, {efWantStmt})
  of nkTypeClassTy:
    result = shallowCopy(n)
    for i in 0..<n.len-1:
      result[i] = n[i]
    result[^1] = semConceptDecl(c, n[^1])
  else:
    localError(c.config, n.info, "unexpected construct in the new-styled concept " & renderTree(n))
    result = n

proc semConceptDeclaration*(c: PContext; n: PNode): PNode =
  assert n.kind == nkTypeClassTy
  inc c.inConceptDecl
  openScope(c)
  declareSelf(c, n.info)
  result = semConceptDecl(c, n)
  rawCloseScope(c)
  dec c.inConceptDecl

type
  MatchCon = object
    inferred: seq[(PType, PType)]
    marker: IntSet
    potentialImplementation: PType

proc existingBinding(m: MatchCon; key: PType): PType =
  for i in 0..<m.inferred.len:
    if m.inferred[i][0] == key: return m.inferred[i][1]
  return nil

proc conceptMatchNode(c: PContext; n: PNode; m: var MatchCon): bool

proc matchType(c: PContext; f, a: PType; m: var MatchCon): bool =
  const
    ignorableForArgType = {tyVar, tySink, tyLent, tyOwned, tyGenericInst, tyAlias, tyInferred}
  case f.kind
  of tyAlias:
    result = matchType(c, f.lastSon, a, m)
  of tyTypeDesc:
    if isSelf(f):
      #let oldLen = m.inferred.len
      result = matchType(c, a, m.potentialImplementation, m)
      #m.inferred.setLen oldLen
    else:
      if a.kind == tyTypeDesc and f.len == a.len:
        for i in 0..<a.len:
          if not matchType(c, f[i], a[i], m): return false
        return true

  of tyGenericParam:
    let ak = a.skipTypes({tyVar, tySink, tyLent, tyOwned})
    if ak.kind in {tyTypeDesc, tyStatic} and not isSelf(ak):
      result = false
    else:
      let old = existingBinding(m, f)
      if old == nil:
        if f.len > 0 and f[0].kind != tyNone:
          # also check the generic's constraints:
          let oldLen = m.inferred.len
          result = matchType(c, f[0], a, m)
          m.inferred.setLen oldLen
          if result:
            m.inferred.add((f, ak))
        else:
          m.inferred.add((f, ak))
          #echo "binding ", typeToString(ak), " to ", typeToString(f)
          result = true
      elif not m.marker.containsOrIncl(old.id):
        result = matchType(c, old, ak, m)

  of tyVar, tySink, tyLent, tyOwned:
    # modifiers in the concept must be there in the actual implementation
    # too but not vice versa.
    if a.kind == f.kind:
      result = matchType(c, f.sons[0], a.sons[0], m)
    else:
      result = false
  of tyEnum, tyObject, tyDistinct:
    result = sameType(f, a)
  of tyBool, tyChar, tyEmpty, tyString, tyCString, tyInt..tyUInt64, tyPointer, tyNil,
     tyUntyped, tyTyped, tyVoid:
    result = a.skipTypes(ignorableForArgType).kind == f.kind
  of tyConcept:
    let oldLen = m.inferred.len
    let oldPotentialImplementation = m.potentialImplementation
    m.potentialImplementation = a
    result = conceptMatchNode(c, f.n.lastSon, m)
    m.potentialImplementation = oldPotentialImplementation
    if not result:
      m.inferred.setLen oldLen
  of tyArray, tyTuple, tyVarargs, tyOpenArray, tyRange, tySequence, tyRef, tyPtr,
     tyGenericInst:
    let ak = a.skipTypes(ignorableForArgType - {f.kind})
    if ak.kind == f.kind and f.len == ak.len:
      for i in 0..<ak.len:
        if not matchType(c, f[i], ak[i], m): return false
      return true
  of tyOr:
    let oldLen = m.inferred.len
    if a.kind == tyOr:
      # say the concept requires 'int|float|string' if the potentialImplementation
      # says 'int|string' that is good enough.
      var covered = 0
      for i in 0..<f.len:
        for j in 0..<a.len:
          let oldLenB = m.inferred.len
          let r = matchType(c, f[i], a[j], m)
          if r:
            inc covered
            break
          m.inferred.setLen oldLenB

      result = covered >= a.len
      if not result:
        m.inferred.setLen oldLen
    else:
      for i in 0..<f.len:
        result = matchType(c, f[i], a, m)
        if result: break # and remember the binding!
        m.inferred.setLen oldLen
  of tyNot:
    if a.kind == tyNot:
      result = matchType(c, f[0], a[0], m)
    else:
      let oldLen = m.inferred.len
      result = not matchType(c, f[0], a, m)
      m.inferred.setLen oldLen
  of tyAnything:
    result = true
  of tyOrdinal:
    result = isOrdinalType(a, allowEnumWithHoles = false) or a.kind == tyGenericParam
  else:
    result = false

proc matchReturnType(c: PContext; f, a: PType; m: var MatchCon): bool =
  if f.isEmptyType:
    result = a.isEmptyType
  elif a == nil:
    result = false
  else:
    result = matchType(c, f, a, m)

proc matchSym(c: PContext; candidate: PSym, n: PNode; m: var MatchCon): bool =
  # watch out: only add bindings after a completely successful match.
  let oldLen = m.inferred.len

  let can = candidate.typ.n
  let con = n[0].sym.typ.n

  let common = min(can.len, con.len)

  if can.len < common:
    # too few arguments, cannot be a match:
    return false

  for i in 1 ..< common:
    if not matchType(c, con[i].typ, can[i].typ, m):
      m.inferred.setLen oldLen
      return false

  if not matchReturnType(c, n[0].sym.typ.sons[0], candidate.typ.sons[0], m):
    m.inferred.setLen oldLen
    return false

  # all other parameters have to be optional parameters:
  for i in common ..< can.len:
    assert can[i].kind == nkSym
    if can[i].sym.ast == nil:
      # has too many arguments one of which is not optional:
      m.inferred.setLen oldLen
      return false

  return true

proc matchSyms(c: PContext, n: PNode; kinds: set[TSymKind]; m: var MatchCon): bool =
  let name = n[namePos].sym.name
  for scope in walkScopes(c.currentScope):
    var ti: TIdentIter
    var candidate = initIdentIter(ti, scope.symbols, name)
    while candidate != nil:
      if candidate.kind in kinds:
        #echo "considering ", typeToString(candidate.typ)
        if matchSym(c, candidate, n, m): return true
      candidate = nextIdentIter(ti, scope.symbols)
  result = false

proc conceptMatchNode(c: PContext; n: PNode; m: var MatchCon): bool =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for i in 0..<n.len:
      if not conceptMatchNode(c, n[i], m):
        return false
    return true
  of nkProcDef, nkFuncDef:
    # procs match any of: proc, template, macro, func, method, converter.
    # The others are more specific.
    # XXX: Enforce .noSideEffect for 'nkFuncDef'? But then what are the use cases...
    const filter = {skProc, skTemplate, skMacro, skFunc, skMethod, skConverter}
    result = matchSyms(c, n, filter, m)
  of nkTemplateDef:
    result = matchSyms(c, n, {skTemplate}, m)
  of nkMacroDef:
    result = matchSyms(c, n, {skMacro}, m)
  of nkConverterDef:
    result = matchSyms(c, n, {skConverter}, m)
  of nkMethodDef:
    result = matchSyms(c, n, {skMethod}, m)
  of nkIteratorDef:
    result = matchSyms(c, n, {skIterator}, m)
  else:
    # error was reported earlier.
    result = false

proc conceptMatch*(c: PContext; concpt, arg: PType; bindings: var TIdTable): bool =
  var m = MatchCon(inferred: @[], potentialImplementation: arg)
  result = conceptMatchNode(c, concpt.n.lastSon, m)
  if result:
    for (a, b) in m.inferred:
      if b.kind == tyGenericParam:
        var dest = b
        while true:
          dest = existingBinding(m, dest)
          if dest == nil or dest.kind != tyGenericParam: break
        if dest != nil:
          bindings.idTablePut(a, dest)
      else:
        bindings.idTablePut(a, b)
    # we have a match, so bind 'arg' itself to 'concpt':
    bindings.idTablePut(concpt, arg)
