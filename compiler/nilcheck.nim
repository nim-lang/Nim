#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, astalgo, renderer, ropes, types, intsets, tables, msgs, options, lineinfos, strutils, sequtils, strformat

# Rules
# 
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
# loop
#   union of env for 0, 1, 2 iterations as Herb Sutter's paper

type
  NilMap* = ref object
    locals*:   Table[string, Nilability]
    previous*: NilMap
    base*:     NilMap

  Nilability* = enum Safe, MaybeNil, Nil

proc check(n: PNode, conf: ConfigRef, map: NilMap): NilMap
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


proc loadNilability(n, map): Nilability =  
  case n.kind:
  of nkSym, nkHiddenDeref:
    result = map[$n]
  of nkNilLit:
    result = Nil
  else:
    result = Safe

proc checkUse(n, conf, map): NilMap =
  # echo "use:",n.sym.name.s
  map

proc checkMagic(n; m: TMagic; conf, map): NilMap =
  result = map
  for child in n:
    result = check(child, conf, result)

proc checkCall(n, conf, map): NilMap =
  for child in n:
    discard check(child, conf, map)
  map

proc checkDeref(n, conf, map): NilMap =
  result = check(n, conf, map)
  let receiver = loadNilability(n, result)
  case receiver:
  of Nil:
    localError conf, n.info, "can't deref " & $n & ": it is nil"
  of MaybeNil:
    localError conf, n.info, "can't deref " & $n & ": it might be nil"
  else:
    message(conf, n.info, hintUser, "can deref " & $n)
    
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

proc checkAsgn(l: PNode, r: PNode; conf, map): NilMap =
  result = check(r, conf, map)
  if result.isNil:
    result = map
  case l.kind:
  of nkSym:
    result[$l] = loadNilability(r, map)
  of nkNilLit:
    result[$l] = Nil
  else:
    discard

proc checkFor(n, conf, map): NilMap =
  var m = map
  var map0 = map.copyMap()
  m = check(n.sons[2], conf, map).copyMap()
  var map1 = m.copyMap()
  var map2 = check(n.sons[2], conf, m)
  
  result = union(map0, map1)
  result = union(result, map2)


proc checkInfix(n, conf, map): NilMap =
  if n[0].kind == nkSym:
    let op = n[0].sym.name.s
    var mapL: NilMap
    var mapR: NilMap
    if n[0].sym.magic != mAnd:
      mapL = checkCondition(n[1], conf, map, false, false)
      mapR = checkCondition(n[2], conf, map, false, false)
    case n[0].sym.magic:
    of mOr:
      result = union(mapL, mapR)
    of mAnd:
      result = checkCondition(n[1], conf, map, false, false)
      result = checkCondition(n[2], conf, result, false, false)
    else:
      result = map
  else:
    result = map

proc checkIsNil(n, conf, map; isElse: bool = false): NilMap =
  if n[1].kind == nkSym:
    result = newNilMap(map)
    result[$n[1]] = if not isElse: Nil else: Safe
  else:
    result = map

proc checkCondition(n, conf, map; isElse: bool, base: bool): NilMap =
  if base:
    map.base = map
  result = map
  echo n.kind
  if n.kind == nkCall:
    if n[0].kind == nkSym and n[0].sym.magic == mIsNil and n[1].kind == nkSym:
      result = newNilMap(map, if base: map else: map.base)
      result[$n[1]] = if not isElse: Nil else: Safe
  elif n.kind == nkPrefix and n[0].kind == nkSym and n[0].sym.magic == mNot:
      result = checkCondition(n[1], conf, map, not isElse, false)
  elif n.kind == nkInfix:
    result = checkInfix(n, conf, map)


proc checkBranch(condition: PNode, n, conf, map; isElse: bool = false): NilMap =
  let childMap = checkCondition(condition, conf, map, isElse, base=true)
  result = check(n, conf, childMap)

proc checkElseBranch(condition: PNode, n, conf, map): NilMap =
  checkBranch(condition, n, conf, map, isElse=true)

# Faith!

proc check(n: PNode, conf: ConfigRef, map: NilMap): NilMap =
  case n.kind:
  of nkSym: result = map # checkUse(n, conf, map)
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
    result = map
    for child in n:
      result = check(child, conf, result)
  of nkDotExpr:
    result = check(n.sons[0], conf, map)
  of nkDerefExpr, nkHiddenDeref:
    result = checkDeref(n.sons[0], conf, map)
  of nkAddr, nkHiddenAddr:
    result = check(n.sons[0], conf, map)
  of nkIfStmt:
    var mapR: NilMap = map.copyMap()
    let mapL = checkBranch(n.sons[0].sons[0], n.sons[0].sons[1], conf, map)
    if n.sons.len > 1:
      mapR = checkElseBranch(n.sons[0].sons[0], n.sons[1], conf, map)
    else:
      mapR = checkCondition(n.sons[0].sons[0], conf, mapR, true, true)
    echo "other", mapL, mapR
    result = union(mapL, mapR)
    echo "result", result
  of nkAsgn:
    result = checkAsgn(n[0], n[1], conf, map)
  of nkVarSection:
    result = map
    for child in n:
      result = checkAsgn(child[0], child[2], conf, result)
  of nkForStmt:
    result = checkFor(n, conf, map)
  of nkNilLit, nkIntLit:
    result = map
  else:
    result = map



proc typeNilability(typ: PType): Nilability =
  echo typeToString(typ)
  if tfNotNil in typ.flags:
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
          # echo "arg", arg.ident.s, " ", map[arg.ident.s]
    discard check(body, conf, map)
  
