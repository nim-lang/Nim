#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of the check that `recover` needs, see
## https://github.com/nim-lang/RFCs/issues/244 for more details.

import
  ast, types, renderer, intsets

proc canAlias(arg, ret: PType; marker: var IntSet): bool

proc canAliasN(arg: PType; n: PNode; marker: var IntSet): bool =
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      result = canAliasN(arg, n[i], marker)
      if result: return
  of nkRecCase:
    assert(n[0].kind == nkSym)
    result = canAliasN(arg, n[0], marker)
    if result: return
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        result = canAliasN(arg, lastSon(n[i]), marker)
        if result: return
      else: discard
  of nkSym:
    result = canAlias(arg, n.sym.typ, marker)
  else: discard

proc canAlias(arg, ret: PType; marker: var IntSet): bool =
  if containsOrIncl(marker, ret.id):
    return false

  if ret.kind in {tyPtr, tyPointer}:
    # unsafe so we don't care:
    return false
  if compareTypes(arg, ret, dcEqIgnoreDistinct):
    return true
  case ret.kind
  of tyObject:
    if isFinal(ret):
      result = canAliasN(arg, ret.n, marker)
      if not result and ret.len > 0 and ret[0] != nil:
        result = canAlias(arg, ret[0], marker)
    else:
      result = true
  of tyTuple:
    for i in 0..<ret.len:
      result = canAlias(arg, ret[i], marker)
      if result: break
  of tyArray, tySequence, tyDistinct, tyGenericInst,
     tyAlias, tyInferred, tySink, tyLent, tyOwned, tyRef:
    result = canAlias(arg, ret.lastSon, marker)
  of tyProc:
    result = ret.callConv == ccClosure
  else:
    result = false

proc isValueOnlyType(t: PType): bool =
  # t doesn't contain pointers and references
  proc wrap(t: PType): bool {.nimcall.} = t.kind in {tyRef, tyPtr, tyVar, tyLent}
  result = not types.searchTypeFor(t, wrap)

proc canAlias*(arg, ret: PType): bool =
  if isValueOnlyType(arg):
    # can alias only with unsafeAddr(arg.x) and we don't care if it is not safe
    result = false
  else:
    var marker = initIntSet()
    result = canAlias(arg, ret, marker)

proc containsVariable(n: PNode): bool =
  case n.kind
  of nodesToIgnoreSet:
    result = false
  of nkSym:
    result = n.sym.kind in {skForVar, skParam, skVar, skLet, skConst, skResult, skTemp}
  else:
    for ch in n:
      if containsVariable(ch): return true
    result = false

proc checkIsolate*(n: PNode): bool =
  if types.containsTyRef(n.typ):
    # XXX Maybe require that 'n.typ' is acyclic. This is not much
    # worse than the already exisiting inheritance and closure restrictions.
    case n.kind
    of nkCharLit..nkNilLit:
      result = true
    of nkCallKinds:
      # XXX: as long as we don't update the analysis while examining arguments
      #      we can do an early check of the return type, otherwise this is a
      #      bug and needs to be moved below
      if tfNoSideEffect notin n[0].typ.flags:
        return false
      for i in 1..<n.len:
        if checkIsolate(n[i]):
          discard "fine, it is isolated already"
        else:
          let argType = n[i].typ
          if argType != nil and not isCompileTimeOnly(argType) and containsTyRef(argType):
            if argType.canAlias(n.typ) or containsVariable(n[i]):
              # bug #19013: Alias information is not enough, we need to check for potential
              # "overlaps". I claim the problem can only happen by reading again from a location
              # that materialized which is only possible if a variable that contains a `ref`
              # is involved.
              return false
      result = true
    of nkIfStmt, nkIfExpr:
      for it in n:
        result = checkIsolate(it.lastSon)
        if not result: break
    of nkCaseStmt:
      for i in 1..<n.len:
        result = checkIsolate(n[i].lastSon)
        if not result: break
    of nkObjConstr:
      result = true
      for i in 1..<n.len:
        result = checkIsolate(n[i].lastSon)
        if not result: break
    of nkBracket, nkTupleConstr, nkPar:
      for it in n:
        result = checkIsolate(it)
        if not result: break
    of nkHiddenStdConv, nkHiddenSubConv, nkCast, nkConv:
      result = checkIsolate(n[1])
    of nkObjUpConv, nkObjDownConv, nkDotExpr:
      result = checkIsolate(n[0])
    of nkStmtList, nkStmtListExpr:
      if n.len > 0:
        result = checkIsolate(n[^1])
      else:
        result = false
    else:
      # unanalysable expression:
      result = false
  else:
    # no ref, no cry:
    result = true
