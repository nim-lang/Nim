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
# - a proc returning GC'ed memory --> requires a promise
# - a proc returning non GC'ed memory --> pass as hidden 'var' parameter
# - not in a parallel environment --> requires a promise for memory safety
type
  TSpawnResult = enum
    srVoid, srPromise, srByVar
  TPromiseKind = enum
    promInvalid # invalid type T for 'Promise[T]'
    promGC      # Promise of a GC'ed type
    promBlob    # Promise of a blob type

proc spawnResult(t: PType; inParallel: bool): TSpawnResult =
  if t.isEmptyType: srVoid
  elif inParallel and not containsGarbageCollectedRef(t): srByVar
  else: srPromise

proc promiseKind(t: PType): TPromiseKind =
  if t.skipTypes(abstractInst).kind in {tyRef, tyString, tySequence}: promGC
  elif containsGarbageCollectedRef(t): promInvalid
  else: promBlob

proc addLocalVar(varSection: PNode; owner: PSym; typ: PType; v: PNode): PSym =
  result = newSym(skTemp, getIdent(genPrefix), owner, varSection.info)
  result.typ = typ
  incl(result.flags, sfFromGeneric)

  var vpart = newNodeI(nkIdentDefs, varSection.info, 3)
  vpart.sons[0] = newSymNode(result)
  vpart.sons[1] = ast.emptyNode
  vpart.sons[2] = v
  varSection.add vpart

discard """
We generate roughly this:

proc f_wrapper(args) =
  barrierEnter(args.barrier)  # for parallel statement
  var a = args.a # thread transfer; deepCopy or shallowCopy or no copy
                 # depending on whether we're in a 'parallel' statement
  var b = args.b

  args.prom = nimCreatePromise(thread, sizeof(T)) # optional
  nimPromiseCreateCondVar(args.prom)  # optional
  nimArgsPassingDone() # signal parent that the work is done
  # 
  args.prom.blob = f(a, b, ...)
  nimPromiseSignal(args.prom)
  
  # - or -
  f(a, b, ...)
  barrierLeave(args.barrier)  # for parallel statement

stmtList:
  var scratchObj
  scratchObj.a = a
  scratchObj.b = b

  nimSpawn(f_wrapper, addr scratchObj)
  scratchObj.prom # optional

"""

proc createNimCreatePromiseCall(prom, threadParam: PNode): PNode =
  let size = newNodeIT(nkCall, prom.info, getSysType(tyInt))
  size.add newSymNode(createMagic("sizeof", mSizeOf))
  assert prom.typ.kind == tyGenericInst
  size.add newNodeIT(nkType, prom.info, prom.typ.sons[1])

  let castExpr = newNodeIT(nkCast, prom.info, prom.typ)
  castExpr.add emptyNode
  castExpr.add callCodeGenProc("nimCreatePromise", threadParam, size)
  result = castExpr

proc createWrapperProc(f: PNode; threadParam, argsParam: PSym;
                       varSection, call, barrier, prom: PNode;
                       spawnKind: TSpawnResult): PSym =
  var body = newNodeI(nkStmtList, f.info)
  if barrier != nil:
    body.add callCodeGenProc("barrierEnter", barrier)
  var threadLocalProm: PSym
  if spawnKind == srByVar:
    threadLocalProm = addLocalVar(varSection, argsParam.owner, prom.typ, prom)
  elif prom != nil:
    internalAssert prom.typ.kind == tyGenericInst
    threadLocalProm = addLocalVar(varSection, argsParam.owner, prom.typ, 
      createNimCreatePromiseCall(prom, threadParam.newSymNode))
    
  body.add varSection
  if prom != nil and spawnKind != srByVar:
    body.add newFastAsgnStmt(prom, threadLocalProm.newSymNode)
    if barrier == nil:
      body.add callCodeGenProc("nimPromiseCreateCondVar", prom)

  body.add callCodeGenProc("nimArgsPassingDone", threadParam.newSymNode)
  if spawnKind == srByVar:
    body.add newAsgnStmt(genDeref(threadLocalProm.newSymNode), call)
  elif prom != nil:
    let fk = prom.typ.sons[1].promiseKind
    if fk == promInvalid:
      localError(f.info, "cannot create a promise of type: " & 
        typeToString(prom.typ.sons[1]))
    body.add newAsgnStmt(indirectAccess(threadLocalProm.newSymNode,
      if fk == promGC: "data" else: "blob", prom.info), call)
    if barrier == nil:
      # by now 'prom' is shared and thus might have beeen overwritten! we need
      # to use the thread-local view instead:
      body.add callCodeGenProc("nimPromiseSignal", threadLocalProm.newSymNode)
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

    let temp = addLocalVar(varSection, objType.owner, argType,
                           indirectAccess(castExpr, field, n.info))    
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
                             castExpr, call, varSection, result: PNode) =
  let formals = n[0].typ.n
  let tmpName = getIdent(genPrefix)
  # we need to copy the foreign scratch object fields into local variables
  # for correctness: These are called 'threadLocal' here.
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
        let a = genAddrOf(n[1])
        field.typ = a.typ
        objType.addField(field)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)

        var fieldA = newSym(skField, tmpName, objType.owner, n.info)
        fieldA.typ = getSysType(tyInt)
        objType.addField(fieldA)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldA), n[2])
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), n[3])

        let threadLocal = addLocalVar(varSection, objType.owner, fieldA.typ,
                                      indirectAccess(castExpr, fieldA, n.info))
        slice.sons[2] = threadLocal.newSymNode
      else:
        let a = genAddrOf(n)
        field.typ = a.typ
        objType.addField(field)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), genHigh(n))

        slice.sons[2] = newIntLit(0)
      # the array itself does not need to go through a thread local variable:
      slice.sons[1] = genDeref(indirectAccess(castExpr, field, n.info))

      let threadLocal = addLocalVar(varSection, objType.owner, fieldB.typ,
                                    indirectAccess(castExpr, fieldB, n.info))
      slice.sons[3] = threadLocal.newSymNode
      call.add slice
    elif (let size = computeSize(argType); size < 0 or size > 16) and
        n.getRoot != nil:
      # it is more efficient to pass a pointer instead:
      let a = genAddrOf(n)
      field.typ = a.typ
      objType.addField(field)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
      let threadLocal = addLocalVar(varSection, objType.owner, field.typ,
                                    indirectAccess(castExpr, field, n.info))
      call.add(genDeref(threadLocal.newSymNode))
    else:
      # boring case
      field.typ = argType
      objType.addField(field)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n)
      let threadLocal = addLocalVar(varSection, objType.owner, field.typ,
                                    indirectAccess(castExpr, field, n.info))
      call.add(threadLocal.newSymNode)

proc wrapProcForSpawn*(owner: PSym; n: PNode; retType: PType; 
                       barrier, dest: PNode = nil): PNode =
  # if 'barrier' != nil, then it is in a 'parallel' section and we
  # generate quite different code
  let spawnKind = spawnResult(retType, barrier!=nil)
  case spawnKind
  of srVoid:
    internalAssert dest == nil
    result = newNodeI(nkStmtList, n.info)
  of srPromise:
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
    setupArgsForParallelism(n, objType, scratchObj, castExpr, call, varSection, result)

  var barrierAsExpr: PNode = nil
  if barrier != nil:
    let typ = newType(tyPtr, owner)
    typ.rawAddSon(magicsys.getCompilerProc("Barrier").typ)
    var field = newSym(skField, getIdent"barrier", owner, n.info)
    field.typ = typ
    objType.addField(field)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), barrier)
    barrierAsExpr = indirectAccess(castExpr, field, n.info)

  var promField, promAsExpr: PNode = nil
  if spawnKind == srPromise:
    var field = newSym(skField, getIdent"prom", owner, n.info)
    field.typ = retType
    objType.addField(field)
    promField = newDotExpr(scratchObj, field)
    promAsExpr = indirectAccess(castExpr, field, n.info)
  elif spawnKind == srByVar:
    var field = newSym(skField, getIdent"prom", owner, n.info)
    field.typ = newType(tyPtr, objType.owner)
    field.typ.rawAddSon(retType)
    objType.addField(field)
    promAsExpr = indirectAccess(castExpr, field, n.info)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), genAddrOf(dest))

  let wrapper = createWrapperProc(fn, threadParam, argsParam, varSection, call,
                                  barrierAsExpr, promAsExpr, spawnKind)
  result.add callCodeGenProc("nimSpawn", wrapper.newSymNode,
                             genAddrOf(scratchObj.newSymNode))

  if spawnKind == srPromise: result.add promField
