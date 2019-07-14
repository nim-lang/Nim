#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements common simple lowerings.

const
  genPrefix* = ":tmp"         # prefix for generated names

import ast, astalgo, types, idents, magicsys, msgs, options, modulegraphs,
  lineinfos
from trees import getMagic

proc newDeref*(n: PNode): PNode {.inline.} =
  result = newNodeIT(nkHiddenDeref, n.info, n.typ.sons[0])
  addSon(result, n)

proc newTupleAccess*(g: ModuleGraph; tup: PNode, i: int): PNode =
  if tup.kind == nkHiddenAddr:
    result = newNodeIT(nkHiddenAddr, tup.info, tup.typ.skipTypes(abstractInst+{tyPtr, tyVar}))
    result.addSon(newNodeIT(nkBracketExpr, tup.info, tup.typ.skipTypes(abstractInst+{tyPtr, tyVar}).sons[i]))
    addSon(result[0], tup[0])
    var lit = newNodeIT(nkIntLit, tup.info, getSysType(g, tup.info, tyInt))
    lit.intVal = i
    addSon(result[0], lit)
  else:
    result = newNodeIT(nkBracketExpr, tup.info, tup.typ.skipTypes(
                       abstractInst).sons[i])
    addSon(result, copyTree(tup))
    var lit = newNodeIT(nkIntLit, tup.info, getSysType(g, tup.info, tyInt))
    lit.intVal = i
    addSon(result, lit)

proc addVar*(father, v: PNode) =
  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = v
  vpart.sons[1] = newNodeI(nkEmpty, v.info)
  vpart.sons[2] = vpart[1]
  addSon(father, vpart)

proc newAsgnStmt*(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newFastAsgnStmt*(le, ri: PNode): PNode =
  result = newNodeI(nkFastAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc lowerTupleUnpacking*(g: ModuleGraph; n: PNode; owner: PSym): PNode =
  assert n.kind == nkVarTuple
  let value = n.lastSon
  result = newNodeI(nkStmtList, n.info)

  var temp = newSym(skTemp, getIdent(g.cache, genPrefix), owner, value.info, g.config.options)
  temp.typ = skipTypes(value.typ, abstractInst)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, value.info)
  let tempAsNode = newSymNode(temp)
  v.addVar(tempAsNode)
  result.add(v)

  result.add newAsgnStmt(tempAsNode, value)
  for i in 0 .. n.len-3:
    if n.sons[i].kind == nkSym: v.addVar(n.sons[i])
    result.add newAsgnStmt(n.sons[i], newTupleAccess(g, tempAsNode, i))

proc evalOnce*(g: ModuleGraph; value: PNode; owner: PSym): PNode =
  ## Turns (value) into (let tmp = value; tmp) so that 'value' can be re-used
  ## freely, multiple times. This is frequently required and such a builtin would also be
  ## handy to have in macros.nim. The value that can be reused is 'result.lastSon'!
  result = newNodeIT(nkStmtListExpr, value.info, value.typ)
  var temp = newSym(skTemp, getIdent(g.cache, genPrefix), owner, value.info, g.config.options)
  temp.typ = skipTypes(value.typ, abstractInst)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkLetSection, value.info)
  let tempAsNode = newSymNode(temp)
  v.addVar(tempAsNode)
  result.add(v)
  result.add newAsgnStmt(tempAsNode, value)
  result.add tempAsNode

proc newTupleAccessRaw*(tup: PNode, i: int): PNode =
  result = newNodeI(nkBracketExpr, tup.info)
  addSon(result, copyTree(tup))
  var lit = newNodeI(nkIntLit, tup.info)
  lit.intVal = i
  addSon(result, lit)

proc newTryFinally*(body, final: PNode): PNode =
  result = newTree(nkHiddenTryStmt, body, newTree(nkFinally, final))

proc lowerTupleUnpackingForAsgn*(g: ModuleGraph; n: PNode; owner: PSym): PNode =
  let value = n.lastSon
  result = newNodeI(nkStmtList, n.info)

  var temp = newSym(skTemp, getIdent(g.cache, "_"), owner, value.info, owner.options)
  var v = newNodeI(nkLetSection, value.info)
  let tempAsNode = newSymNode(temp) #newIdentNode(getIdent(genPrefix & $temp.id), value.info)

  var vpart = newNodeI(nkIdentDefs, tempAsNode.info, 3)
  vpart.sons[0] = tempAsNode
  vpart.sons[1] = newNodeI(nkEmpty, value.info)
  vpart.sons[2] = value
  addSon(v, vpart)
  result.add(v)

  let lhs = n.sons[0]
  for i in 0 .. lhs.len-1:
    result.add newAsgnStmt(lhs.sons[i], newTupleAccessRaw(tempAsNode, i))

proc lowerSwap*(g: ModuleGraph; n: PNode; owner: PSym): PNode =
  result = newNodeI(nkStmtList, n.info)
  # note: cannot use 'skTemp' here cause we really need the copy for the VM :-(
  var temp = newSym(skVar, getIdent(g.cache, genPrefix), owner, n.info, owner.options)
  temp.typ = n.sons[1].typ
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, n.info)
  let tempAsNode = newSymNode(temp)

  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = tempAsNode
  vpart.sons[1] = newNodeI(nkEmpty, v.info)
  vpart.sons[2] = n[1]
  addSon(v, vpart)

  result.add(v)
  result.add newFastAsgnStmt(n[1], n[2])
  result.add newFastAsgnStmt(n[2], tempAsNode)

proc createObj*(g: ModuleGraph; owner: PSym, info: TLineInfo; final=true): PType =
  result = newType(tyObject, owner)
  if final:
    rawAddSon(result, nil)
    incl result.flags, tfFinal
  else:
    rawAddSon(result, getCompilerProc(g, "RootObj").typ)
  result.n = newNodeI(nkRecList, info)
  let s = newSym(skType, getIdent(g.cache, "Env_" & toFilename(g.config, info)),
                  owner, info, owner.options)
  incl s.flags, sfAnon
  s.typ = result
  result.sym = s

proc rawAddField*(obj: PType; field: PSym) =
  assert field.kind == skField
  field.position = sonsLen(obj.n)
  addSon(obj.n, newSymNode(field))
  propagateToOwner(obj, field.typ)

proc rawIndirectAccess*(a: PNode; field: PSym; info: TLineInfo): PNode =
  # returns a[].field as a node
  assert field.kind == skField
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.skipTypes(abstractInst).sons[0]
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc rawDirectAccess*(obj, field: PSym): PNode =
  # returns a.field as a node
  assert field.kind == skField
  result = newNodeI(nkDotExpr, field.info)
  addSon(result, newSymNode obj)
  addSon(result, newSymNode field)
  result.typ = field.typ

proc lookupInRecord(n: PNode, id: int): PSym =
  result = nil
  case n.kind
  of nkRecList:
    for i in 0 ..< sonsLen(n):
      result = lookupInRecord(n.sons[i], id)
      if result != nil: return
  of nkRecCase:
    if n.sons[0].kind != nkSym: return
    result = lookupInRecord(n.sons[0], id)
    if result != nil: return
    for i in 1 ..< sonsLen(n):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        result = lookupInRecord(lastSon(n.sons[i]), id)
        if result != nil: return
      else: discard
  of nkSym:
    if n.sym.id == -abs(id): result = n.sym
  else: discard

proc addField*(obj: PType; s: PSym; cache: IdentCache) =
  # because of 'gensym' support, we have to mangle the name with its ID.
  # This is hacky but the clean solution is much more complex than it looks.
  var field = newSym(skField, getIdent(cache, s.name.s & $obj.n.len), s.owner, s.info,
                     s.options)
  field.id = -s.id
  let t = skipIntLit(s.typ)
  field.typ = t
  assert t.kind != tyTyped
  propagateToOwner(obj, t)
  field.position = sonsLen(obj.n)
  addSon(obj.n, newSymNode(field))

proc addUniqueField*(obj: PType; s: PSym; cache: IdentCache): PSym {.discardable.} =
  result = lookupInRecord(obj.n, s.id)
  if result == nil:
    var field = newSym(skField, getIdent(cache, s.name.s & $obj.n.len), s.owner, s.info,
                       s.options)
    field.id = -s.id
    let t = skipIntLit(s.typ)
    field.typ = t
    assert t.kind != tyTyped
    propagateToOwner(obj, t)
    field.position = sonsLen(obj.n)
    addSon(obj.n, newSymNode(field))
    result = field

proc newDotExpr*(obj, b: PSym): PNode =
  result = newNodeI(nkDotExpr, obj.info)
  let field = lookupInRecord(obj.typ.n, b.id)
  assert field != nil, b.name.s
  addSon(result, newSymNode(obj))
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess*(a: PNode, b: int, info: TLineInfo): PNode =
  # returns a[].b as a node
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.skipTypes(abstractInst).sons[0]
  var t = deref.typ.skipTypes(abstractInst)
  var field: PSym
  while true:
    assert t.kind == tyObject
    field = lookupInRecord(t.n, b)
    if field != nil: break
    t = t.sons[0]
    if t == nil: break
    t = t.skipTypes(skipPtrs)
  #if field == nil:
  #  echo "FIELD ", b
  #  debug deref.typ
  assert field != nil
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess*(a: PNode, b: string, info: TLineInfo; cache: IdentCache): PNode =
  # returns a[].b as a node
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.skipTypes(abstractInst).sons[0]
  var t = deref.typ.skipTypes(abstractInst)
  var field: PSym
  let bb = getIdent(cache, b)
  while true:
    assert t.kind == tyObject
    field = getSymFromList(t.n, bb)
    if field != nil: break
    t = t.sons[0]
    if t == nil: break
    t = t.skipTypes(skipPtrs)
  #if field == nil:
  #  echo "FIELD ", b
  #  debug deref.typ
  assert field != nil
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc getFieldFromObj*(t: PType; v: PSym): PSym =
  assert v.kind != skField
  var t = t
  while true:
    assert t.kind == tyObject
    result = lookupInRecord(t.n, v.id)
    if result != nil: break
    t = t.sons[0]
    if t == nil: break
    t = t.skipTypes(skipPtrs)

proc indirectAccess*(a: PNode, b: PSym, info: TLineInfo): PNode =
  # returns a[].b as a node
  result = indirectAccess(a, b.id, info)

proc indirectAccess*(a, b: PSym, info: TLineInfo): PNode =
  result = indirectAccess(newSymNode(a), b, info)

proc genAddrOf*(n: PNode): PNode =
  result = newNodeI(nkAddr, n.info, 1)
  result.sons[0] = n
  result.typ = newType(tyPtr, n.typ.owner)
  result.typ.rawAddSon(n.typ)

proc genDeref*(n: PNode; k = nkHiddenDeref): PNode =
  result = newNodeIT(k, n.info,
                     n.typ.skipTypes(abstractInst).sons[0])
  result.add n

proc callCodegenProc*(g: ModuleGraph; name: string;
                      info: TLineInfo = unknownLineInfo();
                      arg1, arg2, arg3, optionalArgs: PNode = nil): PNode =
  result = newNodeI(nkCall, info)
  let sym = magicsys.getCompilerProc(g, name)
  if sym == nil:
    localError(g.config, info, "system module needs: " & name)
  else:
    result.add newSymNode(sym)
    if arg1 != nil: result.add arg1
    if arg2 != nil: result.add arg2
    if arg3 != nil: result.add arg3
    if optionalArgs != nil:
      for i in 1..optionalArgs.len-3:
        result.add optionalArgs[i]
    result.typ = sym.typ.sons[0]

proc newIntLit*(g: ModuleGraph; info: TLineInfo; value: BiggestInt): PNode =
  result = nkIntLit.newIntNode(value)
  result.typ = getSysType(g, info, tyInt)

proc genHigh*(g: ModuleGraph; n: PNode): PNode =
  if skipTypes(n.typ, abstractVar).kind == tyArray:
    result = newIntLit(g, n.info, lastOrd(g.config, skipTypes(n.typ, abstractVar)))
  else:
    result = newNodeI(nkCall, n.info, 2)
    result.typ = getSysType(g, n.info, tyInt)
    result.sons[0] = newSymNode(getSysMagic(g, n.info, "high", mHigh))
    result.sons[1] = n

proc genLen*(g: ModuleGraph; n: PNode): PNode =
  if skipTypes(n.typ, abstractVar).kind == tyArray:
    result = newIntLit(g, n.info, lastOrd(g.config, skipTypes(n.typ, abstractVar)) + 1)
  else:
    result = newNodeI(nkCall, n.info, 2)
    result.typ = getSysType(g, n.info, tyInt)
    result.sons[0] = newSymNode(getSysMagic(g, n.info, "len", mLengthSeq))
    result.sons[1] = n

proc hoistExpr*(varSection, expr: PNode, name: PIdent, owner: PSym): PSym =
  result = newSym(skLet, name, owner, varSection.info, owner.options)
  result.flags.incl sfHoisted
  result.typ = expr.typ

  var varDef = newNodeI(nkIdentDefs, varSection.info, 3)
  varDef.sons[0] = newSymNode(result)
  varDef.sons[1] = newNodeI(nkEmpty, varSection.info)
  varDef.sons[2] = expr

  varSection.add varDef
