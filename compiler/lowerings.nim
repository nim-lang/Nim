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
from guards import createMagic
from trees import getMagic

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

proc indirectAccess*(a: PNode, b: string, info: TLineInfo): PNode = 
  # returns a[].b as a node
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.skipTypes(abstractInst).sons[0]
  var t = deref.typ
  var field: PSym
  while true:
    assert t.kind == tyObject
    field = getSymFromList(t.n, getIdent(b))
    if field != nil: break
    t = t.sons[0]
    if t == nil: break
  assert field != nil, b
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess*(a: PNode, b: PSym, info: TLineInfo): PNode = 
  # returns a[].b as a node
  result = indirectAccess(a, b.name.s & $b.id, info)

proc indirectAccess*(a, b: PSym, info: TLineInfo): PNode =
  result = indirectAccess(newSymNode(a), b, info)

proc genAddrOf*(n: PNode): PNode =
  result = newNodeI(nkAddr, n.info, 1)
  result.sons[0] = n
  result.typ = newType(tyPtr, n.typ.owner)
  result.typ.rawAddSon(n.typ)

proc genDeref*(n: PNode): PNode =
  result = newNodeIT(nkHiddenDeref, n.info, 
                     n.typ.skipTypes(abstractInst).sons[0])
  result.add n

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
    result.typ = sym.typ.sons[0]

# we have 4 cases to consider:
# - a void proc --> nothing to do
# - a proc returning GC'ed memory --> requires a future
# - a proc returning non GC'ed memory --> pass as hidden 'var' parameter
# - not in a parallel environment --> requires a future for memory safety
type
  TSpawnResult = enum
    srVoid, srFuture, srByVar
  TFutureKind = enum
    futInvalid # invalid type T for 'Future[T]'
    futGC      # Future of a GC'ed type
    futBlob    # Future of a blob type

proc spawnResult(t: PType; inParallel: bool): TSpawnResult =
  if t.isEmptyType: srVoid
  elif inParallel and not containsGarbageCollectedRef(t): srByVar
  else: srFuture

proc futureKind(t: PType): TFutureKind =
  if t.skipTypes(abstractInst).kind in {tyRef, tyString, tySequence}: futGC
  elif containsGarbageCollectedRef(t): futInvalid
  else: futBlob

discard """
We generate roughly this:

proc f_wrapper(args) =
  barrierEnter(args.barrier)  # for parallel statement
  var a = args.a # copy strings/seqs; thread transfer; not generated for
                 # the 'parallel' statement
  var b = args.b

  args.fut = nimCreateFuture(thread, sizeof(T)) # optional
  nimFutureCreateCondVar(args.fut)  # optional
  nimArgsPassingDone() # signal parent that the work is done
  # 
  args.fut.blob = f(a, b, ...)
  nimFutureSignal(args.fut)
  
  # - or -
  f(a, b, ...)
  barrierLeave(args.barrier)  # for parallel statement

stmtList:
  var scratchObj
  scratchObj.a = a
  scratchObj.b = b

  nimSpawn(f_wrapper, addr scratchObj)
  scratchObj.fut # optional

"""

proc createNimCreateFutureCall(fut, threadParam: PNode): PNode =
  let size = newNodeIT(nkCall, fut.info, getSysType(tyInt))
  size.add newSymNode(createMagic("sizeof", mSizeOf))
  assert fut.typ.kind == tyGenericInst
  size.add newNodeIT(nkType, fut.info, fut.typ.sons[1])

  let castExpr = newNodeIT(nkCast, fut.info, fut.typ)
  castExpr.add emptyNode
  castExpr.add callCodeGenProc("nimCreateFuture", threadParam, size)
  result = newFastAsgnStmt(fut, castExpr)

proc createWrapperProc(f: PNode; threadParam, argsParam: PSym;
                       varSection, call, barrier, fut: PNode): PSym =
  var body = newNodeI(nkStmtList, f.info)
  body.add varSection
  if barrier != nil:
    body.add callCodeGenProc("barrierEnter", barrier)
  if fut != nil:
    body.add createNimCreateFutureCall(fut, threadParam.newSymNode)
    if barrier == nil:
      body.add callCodeGenProc("nimFutureCreateCondVar", fut)

  body.add callCodeGenProc("nimArgsPassingDone", threadParam.newSymNode)
  if fut != nil:
    let fk = fut.typ.sons[1].futureKind
    if fk == futInvalid:
      localError(f.info, "cannot create a future of type: " & 
        typeToString(fut.typ.sons[1]))
    body.add newAsgnStmt(indirectAccess(fut,
      if fk == futGC: "data" else: "blob", fut.info), call)
    if barrier == nil:
      body.add callCodeGenProc("nimFutureSignal", fut)
  else:
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

proc setupArgsForConcurrency(n: PNode; objType: PType; scratchObj: PSym, 
                             castExpr, call, varSection, result: PNode) =
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
    var field = newSym(skField, fieldname, objType.owner, n.info)
    field.typ = argType
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n[i])

    var temp = newSym(skTemp, tmpName, objType.owner, n.info)
    temp.typ = argType
    incl(temp.flags, sfFromGeneric)

    var vpart = newNodeI(nkIdentDefs, n.info, 3)
    vpart.sons[0] = newSymNode(temp)
    vpart.sons[1] = ast.emptyNode
    vpart.sons[2] = indirectAccess(castExpr, field, n.info)
    varSection.add vpart
    
    call.add(newSymNode(temp))

proc getRoot*(n: PNode): PSym =
  ## ``getRoot`` takes a *path* ``n``. A path is an lvalue expression
  ## like ``obj.x[i].y``. The *root* of a path is the symbol that can be
  ## determined as the owner; ``obj`` in the example.
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet, skForVar}:
      result = n.sym
  of nkDotExpr, nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = getRoot(n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = getRoot(n.sons[1])
  of nkCallKinds:
    if getMagic(n) == mSlice: result = getRoot(n.sons[1])
  else: discard

proc newIntLit(value: BiggestInt): PNode =
  result = nkIntLit.newIntNode(value)
  result.typ = getSysType(tyInt)

proc genHigh(n: PNode): PNode =
  if skipTypes(n.typ, abstractVar).kind in {tyArrayConstr, tyArray}:
    result = newIntLit(lastOrd(skipTypes(n.typ, abstractVar)))
  else:
    result = newNodeI(nkCall, n.info, 2)
    result.typ = getSysType(tyInt)
    result.sons[0] = newSymNode(createMagic("high", mHigh))
    result.sons[1] = n

proc setupArgsForParallelism(n: PNode; objType: PType; scratchObj: PSym;
                             castExpr, call, result: PNode) =
  let formals = n[0].typ.n
  let tmpName = getIdent(genPrefix)
  for i in 1 .. <n.len:
    let n = n[i]
    let argType = skipTypes(if i < formals.len: formals[i].typ else: n.typ,
                            abstractInst)
    if containsTyRef(argType):
      localError(n.info, "'spawn'ed function cannot refer to 'ref'/closure")

    let fieldname = if i < formals.len: formals[i].sym.name else: tmpName
    var field = newSym(skField, fieldname, objType.owner, n.info)

    if argType.kind in {tyVarargs, tyOpenArray}:
      # important special case: we always create a zero-copy slice:
      let slice = newNodeI(nkCall, n.info, 4)
      slice.typ = n.typ
      slice.sons[0] = newSymNode(createMagic("slice", mSlice))
      var fieldB = newSym(skField, tmpName, objType.owner, n.info)
      fieldB.typ = getSysType(tyInt)
      objType.addField(fieldB)
      
      if getMagic(n) == mSlice:
        let a = genAddrOf(n[0])
        field.typ = a.typ
        objType.addField(field)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)

        var fieldA = newSym(skField, tmpName, objType.owner, n.info)
        fieldA.typ = getSysType(tyInt)
        objType.addField(fieldA)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldA), n[2])
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), n[3])

        slice.sons[2] = indirectAccess(castExpr, fieldA, n.info)
      else:
        let a = genAddrOf(n)
        field.typ = a.typ
        objType.addField(field)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), genHigh(n))

        slice.sons[2] = newIntLit(0)
        
      slice.sons[1] = genDeref(indirectAccess(castExpr, field, n.info))
      slice.sons[3] = indirectAccess(castExpr, fieldB, n.info)
      call.add slice
    elif (let size = computeSize(argType); size < 0 or size > 16) and
        n.getRoot != nil:
      # it is more efficient to pass a pointer instead:
      let a = genAddrOf(n)
      field.typ = a.typ
      objType.addField(field)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
      call.add(genDeref(indirectAccess(castExpr, field, n.info)))
    else:
      # boring case
      field.typ = argType
      objType.addField(field)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n)
      call.add(indirectAccess(castExpr, field, n.info))

proc wrapProcForSpawn*(owner: PSym; n: PNode; retType: PType; 
                       barrier, dest: PNode = nil): PNode =
  # if 'barrier' != nil, then it is in a 'parallel' section and we
  # generate quite different code
  let spawnKind = spawnResult(retType, barrier!=nil)
  case spawnKind
  of srVoid:
    internalAssert dest == nil
    result = newNodeI(nkStmtList, n.info)
  of srFuture:
    internalAssert dest == nil
    result = newNodeIT(nkStmtListExpr, n.info, retType)
  of srByVar:
    if dest == nil: localError(n.info, "'spawn' must not be discarded")
    result = newNodeI(nkStmtList, n.info)
  
  if n.kind notin nkCallKinds:
    localError(n.info, "'spawn' takes a call expression")
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

  var call = newNodeIT(nkCall, n.info, n.typ)
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
  if barrier.isNil:
    setupArgsForConcurrency(n, objType, scratchObj, castExpr, call, varSection, result)
  else: 
    setupArgsForParallelism(n, objType, scratchObj, castExpr, call, result)

  var barrierAsExpr: PNode = nil
  if barrier != nil:
    let typ = newType(tyPtr, owner)
    typ.rawAddSon(magicsys.getCompilerProc("Barrier").typ)
    var field = newSym(skField, getIdent"barrier", owner, n.info)
    field.typ = typ
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), barrier)
    barrierAsExpr = indirectAccess(castExpr, field, n.info)

  var futField, futAsExpr: PNode = nil
  if spawnKind == srFuture:
    var field = newSym(skField, getIdent"fut", owner, n.info)
    field.typ = retType
    objType.addField(field)
    futField = newDotExpr(scratchObj, field)
    futAsExpr = indirectAccess(castExpr, field, n.info)

  let wrapper = createWrapperProc(fn, threadParam, argsParam, varSection, call,
                                  barrierAsExpr, futAsExpr)
  result.add callCodeGenProc("nimSpawn", wrapper.newSymNode,
                             genAddrOf(scratchObj.newSymNode))

  if spawnKind == srFuture: result.add futField
