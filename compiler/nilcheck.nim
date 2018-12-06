#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, astalgo, renderer, ropes, types, intsets, tables, msgs, options, lineinfos, strutils, sequtils, strformat, idents

# Rules
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
# each check returns its nilability and map

type
  NilMap* = ref object
    locals*:   Table[string, Nilability]
    previous*: NilMap
    base*:     NilMap

  Nilability* = enum Safe, MaybeNil, Nil

  Check = tuple[nilability: Nilability, map: NilMap]

proc check(n: PNode, conf: ConfigRef, map: NilMap): Check
proc checkCondition(n: PNode, conf: ConfigRef, map: NilMap, isElse: bool, base: bool): NilMap

proc newNilMap(previous: NilMap = nil, base: NilMap = nil): NilMap =
  NilMap(locals: initTable[string, Nilability](), previous: previous, base: base)

proc `[]`(map: NilMap, name: string): Nilability =
  var now = map
  while not now.isNil:
    if now.locals.hasKey(name):
      return now.locals[name]
    now = now.previous
  return Safe

proc `[]=`(map: NilMap, name: string, value: Nilability) =
  map.locals[name] = value

proc hasKey(map: NilMap, name: string): bool =
  var now = map
  result = false
  while not now.isNil:
    if now.locals.hasKey(name):
      return true
    now = now.previous

iterator pairs(map: NilMap): (string, Nilability) =
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
  
using
  n: PNode
  conf: ConfigRef
  map: NilMap

proc typeNilability(typ: PType): Nilability

proc checkUse(n, conf, map): NilMap =
  # echo "use:",n.sym.name.s
  map

#proc checkMagic(n; m: TMagic; conf, map): NilMap =
#  result = map
#  for child in n:
#    result = check(child, conf, result)

proc checkCall(n, conf, map): Check =
  # if an argument is passes as var and is ref: make it MaybeNil
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
        result.map[$child] = MaybeNil
  result.nilability = typeNilability(n.typ)
  
proc checkDeref(n, conf, map): Check =
  # deref a : only if a is Safe

  # check a
  result = check(n[0], conf, map)
  
  # message
  case result.nilability:
  of Nil:
    localError conf, n.info, "can't deref " & $n & ": it is nil"
  of MaybeNil:
    localError conf, n.info, "can't deref " & $n & ": it might be nil"
  else:
    message(conf, n.info, hintUser, "can deref " & $n)
    
proc checkDotExpr(n, conf, map): Check =
  # a.b : determine nilability
  result = check(n[0], conf, map)
  if n.typ.kind != tyRef:
    result.nilability = typeNilability(n.typ)
  elif tfNotNil notin n.typ.flags:
    let key = $n
    if result.map.hasKey(key):
      result.nilability = result.map[key]
    else:
      result.map[key] = MaybeNil
      result.nilability = MaybeNil

proc union(l: Nilability, r: Nilability): Nilability =
  if l == r:
    l
  else:
    MaybeNil

proc union(l: NilMap, r: NilMap): NilMap =
  result = newNilMap(l.base)
  for name, value in l:
    if r.hasKey(name) and not result.locals.hasKey(name):
      result[name] = union(value, r[name])

proc checkAsgn(l: PNode, r: PNode; conf, map): Check =
  result = check(r, conf, map)
  if result.map.isNil:
    result.map = map
  case l.kind:
  of nkNilLit:
    result.map[$l] = Nil
  else:
    result.map[$l] = result.nilability

proc checkReturn(n, conf, map): Check =
  # return n same as result = n; return
  result = check(n[0], conf, map)
  result.map["result"] = result.nilability

proc checkFor(n, conf, map): Check =
  var m = map
  var map0 = map.copyMap()
  m = check(n.sons[2], conf, map).map.copyMap()
  var map1 = m.copyMap()
  var check2 = check(n.sons[2], conf, m)
  var map2 = check2.map
  
  result.map = union(map0, map1)
  result.map = union(result.map, map2)
  result.nilability = Safe

proc checkInfix(n, conf, map): Check =
  if n[0].kind == nkSym:
    let op = n[0].sym.name.s
    var mapL: NilMap
    var mapR: NilMap
    if n[0].sym.magic != mAnd:
      mapL = checkCondition(n[1], conf, map, false, false)
      mapR = checkCondition(n[2], conf, map, false, false)
    case n[0].sym.magic:
    of mOr:
      result.map = union(mapL, mapR)
    of mAnd:
      result.map = checkCondition(n[1], conf, map, false, false)
      result.map = checkCondition(n[2], conf, result.map, false, false)
    else:
      result.map = map
  else:
    result.map = map
  result.nilability = Safe

proc checkIsNil(n, conf, map; isElse: bool = false): Check =
  if n[1].kind == nkSym:
    result.map = newNilMap(map)
    result.map[$n[1]] = if not isElse: Nil else: Safe
  else:
    result.map = map

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

proc checkCondition(n, conf, map; isElse: bool, base: bool): NilMap =
  if base:
    map.base = map
  result = map
  # echo n.kind
  if n.kind == nkCall:
    if n[0].kind == nkSym and n[0].sym.magic == mIsNil: # and n[1].kind == nkSym:
      result = newNilMap(map, if base: map else: map.base)
      result[$n[1]] = if not isElse: Nil else: Safe
  elif n.kind == nkPrefix and n[0].kind == nkSym and n[0].sym.magic == mNot:
      result = checkCondition(n[1], conf, map, not isElse, false)
  elif n.kind == nkInfix:
    result = checkInfix(n, conf, map).map

proc checkResult(n, conf, map) =
  let resultNilability = map["result"]
  # echo map
  case resultNilability:
  of Nil:
    localError conf, n.info, "return value is nil"
  of MaybeNil:
    localError conf, n.info, "return value might be nil"
  of Safe:
    discard    

proc checkBranch(condition: PNode, n, conf, map; isElse: bool = false): Check =
  let childMap = checkCondition(condition, conf, map, isElse, base=true)
  result = check(n, conf, childMap)

proc checkElseBranch(condition: PNode, n, conf, map): Check =
  checkBranch(condition, n, conf, map, isElse=true)

# Faith!

proc check(n: PNode, conf: ConfigRef, map: NilMap): Check =
  # echo debugTree(conf, n, 2, 10)
  case n.kind:
  of nkSym: result = (nilability: map[$n], map: map) # checkUse(n, conf, map)
  of nkCallKinds:
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
     nkBracket, nkCurly, nkPar, nkTupleConstr, nkClosure, nkObjConstr:
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
    if n.sons.len > 1:
      (nilabilityR, mapR) = checkElseBranch(n.sons[0].sons[0], n.sons[1], conf, map)
    else:
      mapR = checkCondition(n.sons[0].sons[0], conf, mapR, true, true)
      nilabilityR = Safe
    #echo "other", mapL, mapR
    result.map = union(mapL, mapR)
    result.nilability = if n.kind == nkIfStmt: Safe else: union(nilabilityL, nilabilityR)
    #echo "result", result
  of nkAsgn:
    result = checkAsgn(n[0], n[1], conf, map)
  of nkVarSection:
    result.map = map
    for child in n:
      result = checkAsgn(child[0], child[2], conf, result.map)
  of nkForStmt:
    result = checkFor(n, conf, map)
  of nkCaseStmt:
    result = checkCase(n, conf, map)
  of nkReturnStmt:
    result = checkReturn(n, conf, map)
  of nkNilLit:
    result = (Nil, map)
  of nkIntLit:
    result = (Safe, map)
  else:
    result = (Safe, map)
  # echo "RESULT ", result.nilability
  # echo ""

proc typeNilability(typ: PType): Nilability =
  echo "type", typeToString(typ)
  if typ.isNil:
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
  # TODO
  if not filename.contains("nim/lib") and not filename.contains("zero-functional") and not filename.contains("/lib"):
    for i, child in s.typ.sons:
      if not child.isNil and not s.ast.isNil:
        if s.ast.sons.len >= 4 and s.ast.sons[3].sons.len > i:
          if s.ast.sons[3].sons[i].kind != nkIdentDefs:
            continue
          let arg = s.ast.sons[3].sons[i].sons[0]
          map[arg.ident.s] = typeNilability(child)
    # even not nil is nil by default
    map["result"] = if not s.typ[0].isNil and s.typ[0].kind == tyRef: Nil else: Safe
    let res = check(body, conf, map)
    if not s.typ[0].isNil and s.typ[0].kind == tyRef and tfNotNil in s.typ[0].flags:
      checkResult(s.ast, conf, res.map)
