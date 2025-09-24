import ast, lineinfos, msgs, options, renderer
import std/[strutils]

type
  Expects = enum
    WantT
    WantTButSkipDeref
    WantVarT
    WantVarTResult
    WantMutableT  # `var openArray` does need derefs but mutable locations regardless
    WantForwarding

  CurrentRoutine = object
    returnExpects: Expects
    firstParamKind: TTypeKind
    firstParam: PSym
    resultSym: PSym
    routineSym: PSym

  Context = object
    config: ConfigRef
    r: CurrentRoutine

proc tr(c: var Context; n: PNode; e: Expects): PNode

proc trSons(c: var Context; n: PNode; e: Expects): PNode =
  for i in 0 ..< n.safeLen:
    n[i] = tr(c, n[i], e)

  result = n

proc validBorrowsFrom(c: var Context; n: PNode): bool =
  # --------------------------------------------------------------------------
  # We need to borrow from a location that is derived from the proc's
  # first parameter.
  # See RFC #7373
  # --------------------------------------------------------------------------
  result = false
  var n = n
  var someIndirection = false
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr, nkObjUpConv, nkObjDownConv:
      n = n[0]
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      n = n[1]
    of nkHiddenDeref, nkHiddenAddr, nkDerefExpr, nkAddr:
      n = n[0]
      someIndirection = true
    of nkStmtList, nkStmtListExpr:
      if n.len > 0 and n.typ != nil: n = n.lastSon
      else: break
    of nkCallKinds:
      if n.len > 1:
        let fnType = n[0].typ
        n = n[1]
        if fnType != nil and fnType.len > 1:
          let firstParamType = fnType[1]
          let mightForward = firstParamType.kind in {tyVar, tyLent}
          if not mightForward:
            someIndirection = true
      else:
        break
    else:
      break

  if n.kind == nkSym:
    if n.sym.kind == skParam and n.sym == c.r.firstParam:
      result = c.r.firstParamKind in {tyVar, tyLent} or someIndirection
    else:
      # Allow borrow from global or captured variables for backwards compatibility.
      result = n.sym.owner != c.r.routineSym
  else:
    result = false

proc skipToRoot(n: PNode): PNode =
  var n = n
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr, nkObjUpConv, nkObjDownConv:
      n = n[0]
    of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkCast:
      n = n[1]
    of nkCallKinds:
      if n.len > 1:
        n = n[1]
      else:
        break
    else:
      break
  result = n

proc borrowsFromReadonly(c: var Context; n: PNode; allowLet = false): bool =
  let n = skipToRoot(n)
  if n.kind == nkSym:
    let tk = n.sym.typ.kind
    case n.sym.kind:
    of skConst:
      result = true
    of skLet:
      if allowLet:
        result = tk == tyLent
      else:
        result = tk notin {tyVar, tyLent}
    of skVar:
      result = tk == tyLent
    of skParam:
      result = tk notin {tyVar, tyLent, tySink}
    else:
      result = false
  elif n.kind in nkLiterals + {nkObjConstr}:
    result = true
  else:
    result = false

proc wantMutable(e: Expects): bool {.inline.} =
  e in {WantVarT, WantVarTResult, WantMutableT}

proc trProcDecl(c: var Context; n: PNode): PNode =
  if isGenericRoutine(n):
    result = n
  else:
    var r = CurrentRoutine(returnExpects: WantT)
    if n[namePos].kind == nkSym:
      r.routineSym = n[namePos].sym
      if n[namePos].sym.typ != nil:
        let fnType = n[namePos].sym.typ
        if fnType.len > 1:
          r.firstParamKind = fnType[1].kind
    if n[paramsPos].safeLen > 1 and n[paramsPos][1].kind == nkIdentDefs:
      let firstParam = n[paramsPos][1]
      if firstParam[0].kind == nkSym:
        r.firstParam = firstParam[0].sym
    if n.len > resultPos and n[resultPos].kind == nkSym:
      r.resultSym = n[resultPos].sym
      if n[resultPos].sym.typ != nil and n[resultPos].sym.typ.kind in {tyVar, tyLent}:
        r.returnExpects = WantVarTResult

    swap c.r, r
    result = n
    result[bodyPos] = tr(c, n[bodyPos], c.r.returnExpects)
    swap c.r, r

proc cannotPassToVar(c: var Context; info: TLineInfo; arg: PNode) =
  localError(c.config, info, "cannot pass '$1' to var/out T parameter" % [renderTree(arg, {renderNoComments})])

type
  LvalueStatus = enum
    Valid
    InvalidBorrow
    LocationIsConst

proc trAsgn(c: var Context; n: PNode): PNode =
  var e = WantT
  var err = Valid
  if n[0].kind == nkSym and n[0].sym.kind == skResult and n[0].sym == c.r.resultSym:
    if c.r.returnExpects == WantVarTResult:
      if not validBorrowsFrom(c, n[1]):
        err = InvalidBorrow
        discard
  case err:
  of InvalidBorrow:
    localError c.config, n.info, "cannot borrow from " & renderTree(n[1], {renderNoComments})
  else:
    result = tr(c, n[1], e)
  result = n

proc trLocation(c: var Context; n: PNode; e: Expects): PNode =
  let typ = n.typ
  if typ != nil:
    let k = typ.kind
    if k in {tyVar, tyLent}:
      if e.wantMutable:
        # Consider `fvar(returnsVar(someLet))`: We must not allow this.
        if borrowsFromReadonly(c, n):
          cannotPassToVar c, n.info, n
          result = n
        else:
          result = trSons(c, n, WantT)
      else:
        result = trSons(c, n, WantT)
    elif e.wantMutable:
      if e == WantVarTResult:
        if n.kind == nkSym:
          result = n
        else:
          result = trSons(c, n, WantT)
      elif borrowsFromReadonly(c, n):
        cannotPassToVar c, n.info, n
        result = n
      else:
        result = trSons(c, n, WantT)
    else:
      result = trSons(c, n, WantT)
  else:
    result = n

proc tr(c: var Context; n: PNode; e: Expects): PNode =
  case n.kind
  of nkSym:
    result = trLocation(c, n, e)
  of nkLiterals:
    if e.wantMutable:
      cannotPassToVar c, n.info, n
    result = n
  of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr:
    result = trLocation(c, n, e)
  of nkAsgn:
    result = trAsgn(c, n)
  of nkProcDef, nkFuncDef, nkMethodDef, nkConverterDef, nkIteratorDef:
    result = trProcDecl(c, n)
  else:
    result = trSons(c, n, e)

proc injectDerefs*(config: ConfigRef; n: PNode): PNode =
  var c  = Context(config: config, r: CurrentRoutine())
  result = tr(c, n, WantT)
