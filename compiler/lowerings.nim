#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements common simple lowerings.

const
  genPrefix* = ":tmp"         # prefix for generated names

import ast, astalgo, types, idents, magicsys, msgs, options

proc newTupleAccess*(tup: PNode, i: int): PNode =
  result = newNodeIT(nkBracketExpr, tup.info, tup.typ.skipTypes(
                     abstractInst).sons[i])
  addSon(result, copyTree(tup))
  var lit = newNodeIT(nkIntLit, tup.info, getSysType(tyInt))
  lit.intVal = i
  addSon(result, lit)

proc addVar*(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = v
  vpart.sons[1] = ast.emptyNode
  vpart.sons[2] = ast.emptyNode
  addSon(father, vpart)

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newFastAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkFastAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc lowerTupleUnpacking*(n: PNode; owner: PSym): PNode =
  assert n.kind == nkVarTuple
  let value = n.lastSon
  result = newNodeI(nkStmtList, n.info)

  var temp = newSym(skTemp, getIdent(genPrefix), owner, value.info)
  temp.typ = skipTypes(value.typ, abstractInst)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, value.info)
  v.addVar(newSymNode(temp))
  result.add(v)
  
  result.add newAsgnStmt(newSymNode(temp), value)
  for i in 0 .. n.len-3:
    result.add newAsgnStmt(n.sons[i], newTupleAccess(value, i))

proc createObj*(owner: PSym, info: TLineInfo): PType =
  result = newType(tyObject, owner)
  rawAddSon(result, nil)
  incl result.flags, tfFinal
  result.n = newNodeI(nkRecList, info)

proc addField*(obj: PType; s: PSym) =
  # because of 'gensym' support, we have to mangle the name with its ID.
  # This is hacky but the clean solution is much more complex than it looks.
  var field = newSym(skField, getIdent(s.name.s & $s.id), s.owner, s.info)
  let t = skipIntLit(s.typ)
  field.typ = t
  assert t.kind != tyStmt
  field.position = sonsLen(obj.n)
  addSon(obj.n, newSymNode(field))

proc newDotExpr(obj, b: PSym): PNode =
  result = newNodeI(nkDotExpr, obj.info)
  let field = getSymFromList(obj.typ.n, getIdent(b.name.s & $b.id))
  assert field != nil, b.name.s
  addSon(result, newSymNode(obj))
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess*(a: PNode, b: PSym, info: TLineInfo): PNode = 
  # returns a[].b as a node
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.sons[0]
  assert deref.typ.kind == tyObject
  let field = getSymFromList(deref.typ.n, getIdent(b.name.s & $b.id))
  assert field != nil, b.name.s
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess*(a, b: PSym, info: TLineInfo): PNode =
  result = indirectAccess(newSymNode(a), b, info)

proc genAddrOf*(n: PNode): PNode =
  result = newNodeI(nkAddr, n.info, 1)
  result.sons[0] = n
  result.typ = newType(tyPtr, n.typ.owner)
  result.typ.rawAddSon(n.typ)

proc callCodegenProc*(name: string, arg1: PNode; 
                      arg2, arg3: PNode = nil): PNode =
  result = newNodeI(nkCall, arg1.info)
  let sym = magicsys.getCompilerProc(name)
  if sym == nil:
    localError(arg1.info, errSystemNeeds, name)
  else:
    result.add newSymNode(sym)
    result.add arg1
    if arg2 != nil: result.add arg2
    if arg3 != nil: result.add arg3

proc createWrapperProc(f: PNode; threadParam, argsParam: PSym;
                       varSection, call, barrier: PNode): PSym =
  var body = newNodeI(nkStmtList, f.info)
  body.add varSection
  if barrier != nil:
    body.add callCodeGenProc("barrierEnter", barrier)
  body.add callCodeGenProc("nimArgsPassingDone", newSymNode(threadParam))
  body.add call
  if barrier != nil:
    body.add callCodeGenProc("barrierLeave", barrier)

  var params = newNodeI(nkFormalParams, f.info)
  params.add emptyNode
  params.add threadParam.newSymNode
  params.add argsParam.newSymNode

  var t = newType(tyProc, threadParam.owner)
  t.rawAddSon nil
  t.rawAddSon threadParam.typ
  t.rawAddSon argsParam.typ
  t.n = newNodeI(nkFormalParams, f.info)
  t.n.add newNodeI(nkEffectList, f.info)
  t.n.add threadParam.newSymNode
  t.n.add argsParam.newSymNode

  let name = (if f.kind == nkSym: f.sym.name.s else: genPrefix) & "Wrapper"
  result = newSym(skProc, getIdent(name), argsParam.owner, f.info)
  result.ast = newProcNode(nkProcDef, f.info, body, params, newSymNode(result))
  result.typ = t

proc createCastExpr(argsParam: PSym; objType: PType): PNode =
  result = newNodeI(nkCast, argsParam.info)
  result.add emptyNode
  result.add newSymNode(argsParam)
  result.typ = newType(tyPtr, objType.owner)
  result.typ.rawAddSon(objType)

proc wrapProcForSpawn*(owner: PSym; n: PNode; barrier: PNode = nil): PNode =
  result = newNodeI(nkStmtList, n.info)
  if n.kind notin nkCallKinds or not n.typ.isEmptyType:
    localError(n.info, "'spawn' takes a call expression of type void")
    return
  if optThreadAnalysis in gGlobalOptions:
    if {tfThread, tfNoSideEffect} * n[0].typ.flags == {}:
      localError(n.info, "'spawn' takes a GC safe call expression")
  var
    threadParam = newSym(skParam, getIdent"thread", owner, n.info)
    argsParam = newSym(skParam, getIdent"args", owner, n.info)
  block:
    let ptrType = getSysType(tyPointer)
    threadParam.typ = ptrType
    argsParam.typ = ptrType
    argsParam.position = 1

  var objType = createObj(owner, n.info)
  incl(objType.flags, tfFinal)
  let castExpr = createCastExpr(argsParam, objType)

  var scratchObj = newSym(skVar, getIdent"scratch", owner, n.info)
  block:
    scratchObj.typ = objType
    incl(scratchObj.flags, sfFromGeneric)
    var varSectionB = newNodeI(nkVarSection, n.info)
    varSectionB.addVar(scratchObj.newSymNode)
    result.add varSectionB

  var call = newNodeI(nkCall, n.info)
  var fn = n.sons[0]
  # templates and macros are in fact valid here due to the nature of
  # the transformation:
  if not (fn.kind == nkSym and fn.sym.kind in {skProc, skTemplate, skMacro,
                                               skMethod, skConverter}):
    # for indirect calls we pass the function pointer in the scratchObj
    var argType = n[0].typ.skipTypes(abstractInst)
    var field = newSym(skField, getIdent"fn", owner, n.info)
    field.typ = argType
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n[0])
    fn = indirectAccess(castExpr, field, n.info)
  elif fn.kind == nkSym and fn.sym.kind in {skClosureIterator, skIterator}:
    localError(n.info, "iterator in spawn environment is not allowed")
  elif fn.typ.callConv == ccClosure:
    localError(n.info, "closure in spawn environment is not allowed")

  call.add(fn)
  var varSection = newNodeI(nkVarSection, n.info)
  let formals = n[0].typ.n
  let tmpName = getIdent(genPrefix)
  for i in 1 .. <n.len:
    # we pick n's type here, which hopefully is 'tyArray' and not
    # 'tyOpenArray':
    var argType = n[i].typ.skipTypes(abstractInst)
    if i < formals.len and formals[i].typ.kind == tyVar:
      localError(n[i].info, "'spawn'ed function cannot have a 'var' parameter")
    elif containsTyRef(argType):
      localError(n[i].info, "'spawn'ed function cannot refer to 'ref'/closure")

    let fieldname = if i < formals.len: formals[i].sym.name else: tmpName
    var field = newSym(skField, fieldname, owner, n.info)
    field.typ = argType
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n[i])

    var temp = newSym(skTemp, tmpName, owner, n.info)
    temp.typ = argType
    incl(temp.flags, sfFromGeneric)

    var vpart = newNodeI(nkIdentDefs, n.info, 3)
    vpart.sons[0] = newSymNode(temp)
    vpart.sons[1] = ast.emptyNode
    vpart.sons[2] = indirectAccess(castExpr, field, n.info)
    varSection.add vpart

    call.add(newSymNode(temp))

  var barrierAsExpr: PNode = nil
  if barrier != nil:
    let typ = newType(tyPtr, owner)
    typ.rawAddSon(magicsys.getCompilerProc("Barrier").typ)
    var field = newSym(skField, getIdent"barrier", owner, n.info)
    field.typ = typ
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), barrier)
    barrierAsExpr = indirectAccess(castExpr, field, n.info)

  let wrapper = createWrapperProc(fn, threadParam, argsParam, varSection, call,
                                  barrierAsExpr)
  result.add callCodeGenProc("nimSpawn", wrapper.newSymNode,
                             genAddrOf(scratchObj.newSymNode))
