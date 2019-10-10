#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, astalgo, renderer, ropes, types, intsets, tables, msgs, options, lineinfos, strutils, sequtils, strformat, idents, treetab, hashes

# 
# Env: int => nilability
# a = b
#   nilability a <- nilability b
# deref a
#   if Nil error is nil
#   if MaybeNil error might be nil, hint add if isNil
#   if Safe fine
# fun(arg: A)
#   nilability arg <- for ref MaybeNil, for not nil or others Safe
# map is env?
# a or b
#   each one forks a different env
#   result = union(envL, envR)
# a and b
#   b forks a's env
# if a: code
#   result = union(previousEnv after not a, env after code)
# if a: b else: c
#   result = union(env after b, env after c)
# result = b
#   nilability result <- nilability b, if return type is not nil and result not safe, error
# return b
#   as result = b
# try: a catch: b finally: c
#   in b and c env is union of all possible try first n lines, after union of a and b and c
# case a: of b: c
#   similar to if
# call(arg)
#   if it returns ref, assume it's MaybeNil: hint that one can add not nil to the return type
# call(var arg) # zahary comment
#   if arg is ref, assume it's MaybeNil after call
# loop
#   union of env for 0, 1, 2 iterations as Herb Sutter's paper
# return
#   if something: stop (break return etc)
#   is equivalent to if something: .. else: remain
# new(ref)
#   ref becomes Safe
# each check returns its nilability and map

type
  Symbol = int

  TransitionKind = enum TArg, TAssign, TType, TNil, TVarArg, TResult
  
  History = object
    info: TLineInfo
    nilability: Nilability
    kind: TransitionKind
    

  NilMap* = ref object
    locals*:   Table[Symbol, Nilability]
    history*:  Table[Symbol, seq[History]]
    previous*: NilMap
    base*:     NilMap
    top*:      NilMap

  Nilability* = enum Safe, MaybeNil, Nil

  Check = tuple[nilability: Nilability, map: NilMap]

const resultId = -1

proc check(n: PNode, conf: ConfigRef, map: NilMap): Check
proc checkCondition(n: PNode, conf: ConfigRef, map: NilMap, isElse: bool, base: bool): NilMap

proc newNilMap(previous: NilMap = nil, base: NilMap = nil): NilMap =
  result = NilMap(
    locals: initTable[Symbol, Nilability](),
    previous: previous,
    base: base,
    history: initTable[Symbol, seq[History]]())
  result.top = if previous.isNil: result else: previous.top

proc `[]`(map: NilMap, name: Symbol): Nilability =
  var now = map
  while not now.isNil:
    if now.locals.hasKey(name):
      return now.locals[name]
    now = now.previous
  return Safe

proc history(map: NilMap, name: Symbol): seq[History] =
  var now = map
  var h: seq[History] = @[]
  while not now.isNil:
    if now.history.hasKey(name):
      # h = h.concat(now.history[name])
      return now.history[name]
    now = now.previous
  return @[]

import macros

macro aecho*(a: varargs[untyped]): untyped =
  var e = nnkCall.newTree(ident"echo")
  for b in a:
    e.add(b)
  result = quote:
    when defined(nilDebugInfo):
      `e`

proc store(map: NilMap, symbol: Symbol, value: Nilability, kind: TransitionKind, info: TLineInfo) =
  map.locals[symbol] = value
  map.history.mgetOrPut(symbol, @[]).add(History(info: info, kind: kind, nilability: value))

proc hasKey(map: NilMap, name: Symbol): bool =
  var now = map
  result = false
  while not now.isNil:
    if now.locals.hasKey(name):
      return true
    now = now.previous

iterator pairs(map: NilMap): (Symbol, Nilability) =
  var now = map
  while not now.isNil:
    for name, value in now.locals:
      yield (name, value)
    now = now.previous

proc copyMap(map: NilMap): NilMap =
  if map.isNil:
    return nil
  result = newNilMap(map.previous.copyMap())
  for name, value in map.locals:
    result.locals[name] = value
  for name, value in map.history:
    result.history[name] = value

proc `$`(map: NilMap): string =
  var now = map
  var stack: seq[NilMap] = @[]
  while not now.isNil:
    stack.add(now)
    now = now.previous
  for i in countdown(stack.len - 1, 0):
    now = stack[i]
    result.add("###\n")
    for name, value in now.locals:
      result.add(&"  {name} {value}\n")
  
proc symbol(n: PNode): Symbol =
  aecho n, n.kind
  case n.kind:
  of nkSym:
    if $n == "result":
      result = resultId
    else:
      result = n.sym.id
  of nkHiddenAddr, nkAddr:
    result = symbol(n[0])
  else:
    result = hashTree(n)
  aecho result

using
  n: PNode
  conf: ConfigRef
  map: NilMap

proc typeNilability(typ: PType): Nilability



proc checkCall(n, conf, map): Check =
  var isNew = false
  result.map = map
  for i, child in n:
    discard check(child, conf, map)
    if i > 0 and child.kind == nkHiddenAddr:
      if child.typ.kind == tyVar and child.typ[0].kind == tyRef:
        # yes
        if not isNew:
          result.map = newNilMap(map)
          isNew = true
        # result.map[$child] = MaybeNil
        # echo "MaybeNil arg"
        # echo "  ", child
        # echo "  ", symbol(child)
        let a = symbol(child)
        result.map.store(a, MaybeNil, TVarArg, n.info)
        # echo result.map

  if n[0].kind == nkSym and n[0].sym.magic == mNew:
    # let b = $n[1]
    let b = symbol(n[1])
    # result.map[b] = Safe
    result.map.store(b, Safe, TAssign, n[1].info)
    result.nilability = Safe
  else:
    result.nilability = typeNilability(n.typ)
  # echo result.map

template event(b: History): string =
  case b.kind:
  of TArg: "param with nilable type"
  of TNil: "isNil"
  of TAssign: "assigns a value which might be nil"
  of TVarArg: "passes it as a var arg which might change to nil"
  of TResult: "it is nil by default"
  of TType: "it has ref type"

proc derefWarning(n, conf, map; maybe: bool) =
  var a = history(map, symbol(n))
  var res = ""
  res.add("can't deref " & $n & " it " & (if maybe: "might be" else: "is") & " nil")
  res.add("\n")
  for b in a:
    res.add("  " & event(b) & " on line " & $b.info.line & ":" & $b.info.col)
  message(conf, n.info, warnNilCheck, res)
    
proc checkDeref(n, conf, map): Check =
  # deref a : only if a is Safe

  # check a
  result = check(n[0], conf, map)
  
  # message
  case result.nilability:
  of Nil:
    derefWarning(n[0], conf, map, false)
  of MaybeNil:
    derefWarning(n[0], conf, map, true)
  else:
    when defined(nilDebugInfo):
      message(conf, n.info, hintUser, "can deref " & $n)
    
proc checkRefExpr(n, conf; check: Check): Check =
  result = check
  if n.typ.kind != tyRef:
    result.nilability = typeNilability(n.typ)
  elif tfNotNil notin n.typ.flags:
    let key = symbol(n)
    if result.map.hasKey(key):
      result.nilability = result.map[key]
    else:
      # result.map[key] = MaybeNil
      result.map.store(key, MaybeNil, TType, n.info)
      result.nilability = MaybeNil


proc checkDotExpr(n, conf, map): Check =
  result = check(n[0], conf, map)
  result = checkRefExpr(n, conf, result)

proc checkBracketExpr(n, conf, map): Check =
  result = check(n[0], conf, map)
  result = check(n[1], conf, result.map)
  result = checkRefExpr(n, conf, result)


template union(l: Nilability, r: Nilability): Nilability =
  if l == r:
    l
  else:
    MaybeNil

proc union(l: NilMap, r: NilMap): NilMap =
  if l.isNil:
    return r
  elif r.isNil:
    return l
  result = newNilMap(l.base)
  for name, value in l:
    if r.hasKey(name) and not result.locals.hasKey(name):
      var h = history(r, name)
      assert h.len > 0
      # echo "history", name, value, r[name], h[^1].info.line
      result.store(name, union(value, r[name]), TAssign, h[^1].info)

proc checkAsgn(target: PNode, assigned: PNode; conf, map): Check =
  if assigned.kind != nkEmpty:
    result = check(assigned, conf, map)
  else:
    result = (typeNilability(target.typ), map)
  if result.map.isNil:
    result.map = map
  let t = symbol(target) # $target
  case target.kind:
  of nkNilLit:
    #result.map[t] = Nil
    result.map.store(t, Nil, TAssign, target.info)
  else:
    result.map.store(t, result.nilability, TAssign, target.info)

proc checkReturn(n, conf, map): Check =
  # return n same as result = n; return
  result = check(n[0], conf, map)
  result.map.store(resultId, result.nilability, TAssign, n.info)


proc checkFor(n, conf, map): Check =
  var m = map
  var map0 = map.copyMap()
  m = check(n.sons[2], conf, map).map.copyMap()
  if n[0].kind == nkSym:
    m.store(symbol(n[0]), typeNilability(n[0].typ), TAssign, n[0].info)
  var map1 = m.copyMap()
  var check2 = check(n.sons[2], conf, m)
  var map2 = check2.map
  
  result.map = union(map0, map1)
  result.map = union(result.map, map2)
  result.nilability = Safe

proc checkWhile(n, conf, map): Check =
  var m = checkCondition(n[0], conf, map, false, false)
  var map0 = map.copyMap()
  m = check(n.sons[1], conf, m).map
  var map1 = m.copyMap()
  var check2 = check(n.sons[1], conf, m)
  var map2 = check2.map
  
  result.map = union(map0, map1)
  result.map = union(result.map, map2)
  result.nilability = Safe

proc checkInfix(n, conf, map): Check =
  if n[0].kind == nkSym:
    var mapL: NilMap
    var mapR: NilMap
    if n[0].sym.magic notin {mAnd, mEqRef}:
      mapL = checkCondition(n[1], conf, map, false, false)
      mapR = checkCondition(n[2], conf, map, false, false)
    case n[0].sym.magic:
    of mOr:
      result.map = union(mapL, mapR)
    of mAnd:
      result.map = checkCondition(n[1], conf, map, false, false)
      result.map = checkCondition(n[2], conf, result.map, false, false)
    of mEqRef:
      if n[2].kind == nkIntLit:
        if $n[2] == "true":
          result.map = checkCondition(n[1], conf, map, false, false)
        elif $n[2] == "false":
          result.map = checkCondition(n[1], conf, map, true, false)
      elif n[1].kind == nkIntLit:
        if $n[1] == "true":
          result.map = checkCondition(n[2], conf, map, false, false)
        elif $n[1] == "false":
          result.map = checkCondition(n[2], conf, map, true, false)
      if result.map.isNil:
        result.map = map
    else:
      result.map = map
  else:
    result.map = map
  result.nilability = Safe

proc checkIsNil(n, conf, map; isElse: bool = false): Check =
  result.map = newNilMap(map)
  let value = n[1]
  let value2 = symbol(value)
  result.map.store(symbol(n[1]), if not isElse: Nil else: Safe, TArg, n.info)

proc infix(l: PNode, r: PNode, magic: TMagic): PNode =
  var name = case magic:
    of mEqRef: "=="
    of mAnd: "and"
    of mOr: "or"
    else: ""

  var cache = newIdentCache()
  var op = newSym(skVar, cache.getIdent(name), nil, r.info)

  op.magic = magic
  result = nkInfix.newTree(
    newSymNode(op, r.info),
    l,
    r)
  result.typ = newType(tyBool, nil)

proc prefixNot(node: PNode): PNode =
  var cache = newIdentCache()
  var op = newSym(skVar, cache.getIdent("not"), nil, node.info)

  op.magic = mNot
  result = nkPrefix.newTree(
    newSymNode(op, node.info),
    node)
  result.typ = newType(tyBool, nil)

proc infixEq(l: PNode, r: PNode): PNode =
  infix(l, r, mEqRef)

proc infixOr(l: PNode, r: PNode): PNode =
  infix(l, r, mOr)

proc checkBranch(condition: PNode, n, conf, map; isElse: bool = false): Check

proc checkCase(n, conf, map): Check =
  # case a:
  #   of b: c
  #   of b2: c2
  # is like
  # if a == b:
  #   c
  # elif a == b2:
  #   c2
  # also a == true is a , a == false is not a
  let base = n[0]
  result.map = map.copyMap()
  result.nilability = Safe
  var a: PNode
  for child in n:
    case child.kind:
    of nkOfBranch:
      let branchBase = child[0]
      let code = child[1]
      let test = infixEq(base, branchBase)
      if a.isNil:
        a = test
      else:
        a = infixOr(a, test)
      let (newNilability, newMap) = checkBranch(test, code, conf, map)
      result.map = union(result.map, newMap)
      result.nilability = union(result.nilability, newNilability)
    of nkElse:
      let (newNilability, newMap) = checkBranch(prefixNot(a), child[0], conf, map)
      result.map = union(result.map, newMap)
      result.nilability = union(result.nilability, newNilability)
    else:
      discard

proc checkTry(n, conf, map): Check =
  var newMap = map
  var currentMap = map
  for child in n[0]:
    let (childNilability, childMap) = check(child, conf, currentMap)
    currentMap = childMap
    newMap = union(newMap, childMap)
  aecho newMap
  for a, branch in n:
    if a > 0:
      case branch.kind:
      of nkFinally:
        let (_, childMap) = check(branch[0], conf, newMap)
        newMap = union(newMap, childMap)
      of nkExceptBranch:        
        let (_, childMap) = check(branch[^1], conf, newMap)
        newMap = union(newMap, childMap)
      else:
        discard
  result = (Safe, newMap)

proc directStop(n): bool =
  case n.kind:
  of nkStmtList:
    for child in n:
      if directStop(child):
        return true
  of nkReturnStmt, nkBreakStmt, nkContinueStmt, nkRaiseStmt:
    return true
  of nkIfStmt, nkElse:
    return false
  else:
    aecho n.kind
  return false

proc checkCondition(n, conf, map; isElse: bool, base: bool): NilMap =
  if base:
    map.base = map
  result = map
  if n.kind == nkCall:
    if n[0].kind == nkSym and n[0].sym.magic == mIsNil:
      result = newNilMap(map, if base: map else: map.base)
      let a = symbol(n[1])
      result.store(a, if not isElse: Nil else: Safe, TNil, n.info)
  elif n.kind == nkPrefix and n[0].kind == nkSym and n[0].sym.magic == mNot:
    result = checkCondition(n[1], conf, map, not isElse, false)
  elif n.kind == nkInfix:
    result = checkInfix(n, conf, map).map

proc checkResult(n, conf, map) =
  let resultNilability = map[resultId] # "result"]
  case resultNilability:
  of Nil:
    message(conf, n.info, warnNilCheck, "return value is nil")
  of MaybeNil:
    message(conf, n.info, warnNilCheck, "return value might be nil")
  of Safe:
    discard    

proc checkBranch(condition: PNode, n, conf, map; isElse: bool = false): Check =
  let childMap = checkCondition(condition, conf, map, isElse, base=true)
  result = check(n, conf, childMap)

proc checkElseBranch(condition: PNode, n, conf, map): Check =
  checkBranch(condition, n, conf, map, isElse=true)

# Faith!

proc check(n: PNode, conf: ConfigRef, map: NilMap): Check =
  aecho "n", n, " ", n.kind
  if map.isNil:
    echo "map nil ", n.kind
    writeStackTrace()
    quit 1
  case n.kind:
  of nkSym: aecho symbol(n), map; result = (nilability: map[symbol(n)], map: map)
  of nkCallKinds:
    aecho "call", n
    if n.sons[0].kind == nkSym:
      let callSym = n.sons[0].sym
      case callSym.magic:
      of mAnd, mOr:
        result = checkInfix(n, conf, map)
      of mIsNil:
        result = checkIsNil(n, conf, map)
      else:
        result = checkCall(n, conf, map)
    else:
      result = checkCall(n, conf, map)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkExprColonExpr, nkExprEqExpr,
     nkCast:
    result = check(n.sons[1], conf, map)
  of nkStmtList, nkStmtListExpr, nkChckRangeF, nkChckRange64, nkChckRange,
     nkBracket, nkCurly, nkPar, nkTupleConstr, nkClosure, nkObjConstr, nkElse:
    result.map = map
    for child in n:
      result = check(child, conf, result.map)
  of nkDotExpr:
    result = checkDotExpr(n, conf, map)
  of nkDerefExpr, nkHiddenDeref:
    result = checkDeref(n, conf, map)
  of nkAddr, nkHiddenAddr:
    result = check(n.sons[0], conf, map)
  of nkIfStmt, nkIfExpr:
    var mapR: NilMap = map.copyMap()
    var nilabilityR: Nilability = Safe
    let (nilabilityL, mapL) = checkBranch(n.sons[0].sons[0], n.sons[0].sons[1], conf, map)
    var isDirect = false
    if n.sons.len > 1:
      (nilabilityR, mapR) = checkElseBranch(n.sons[0].sons[0], n.sons[1], conf, map)
    else:
      mapR = checkCondition(n.sons[0].sons[0], conf, mapR, true, true)
      nilabilityR = Safe
      if directStop(n[0][1]):
        isDirect = true
        result.map = mapR
        result.nilability = nilabilityR

    #echo "other", mapL, mapR
    if not isDirect:
      result.map = union(mapL, mapR)
      result.nilability = if n.kind == nkIfStmt: Safe else: union(nilabilityL, nilabilityR)
    #echo "result", result
  of nkAsgn:
    result = checkAsgn(n[0], n[1], conf, map)
  of nkVarSection:
    result.map = map
    for child in n:
      aecho child.kind
      result = checkAsgn(child[0], child[2], conf, result.map)
  of nkForStmt:
    result = checkFor(n, conf, map)
  of nkCaseStmt:
    result = checkCase(n, conf, map)
  of nkReturnStmt:
    result = checkReturn(n, conf, map)
  of nkBracketExpr:
    result = checkBracketExpr(n, conf, map)
  of nkTryStmt:
    result = checkTry(n, conf, map)
  of nkWhileStmt:
    result = checkWhile(n, conf, map)
  of nkNilLit:
    result = (Nil, map)
  of nkIntLit:
    result = (Safe, map)
  else:
    # echo n.kind
    result = (Nil, map)
  
proc typeNilability(typ: PType): Nilability =
  if not typ.isNil:
    aecho "type ", typ, " ", typ.flags
  if typ.isNil: # TODO is it ok
    Safe
  elif tfNotNil in typ.flags:
    Safe
  elif typ.kind == tyRef:
    MaybeNil
  else:
    Safe

proc checkNil*(s: PSym; body: PNode; conf: ConfigRef) =
  var map = newNilMap()
  let line = s.ast.info.line
  let fileIndex = s.ast.info.fileIndex.int
  var filename = conf.m.fileInfos[fileIndex].fullPath.string

  # if "nilcheck" notin filename:
    # return
  # TODO
  for i, child in s.typ.n.sons:
    if i > 0:
      if child.kind != nkSym:
        continue
      map.store(symbol(child), typeNilability(child.typ), TArg, child.info)

  map.store(resultId, if not s.typ[0].isNil and s.typ[0].kind == tyRef: Nil else: Safe, TResult, s.ast.info)
  # echo "checking ", s.name.s, " ", filename
  let res = check(body, conf, map)
  if res.nilability == Safe and (not res.map.history.hasKey(resultId) or res.map.history[resultId].len <= 1):
    res.map.store(resultId, Safe, TAssign, s.ast.info)
  if not s.typ[0].isNil and s.typ[0].kind == tyRef and tfNotNil in s.typ[0].flags:
    checkResult(s.ast, conf, res.map)
