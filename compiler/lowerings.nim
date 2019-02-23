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

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc newFastAsgnStmt(le, ri: PNode): PNode =
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

proc newTupleAccessRaw*(tup: PNode, i: int): PNode =
  result = newNodeI(nkBracketExpr, tup.info)
  addSon(result, copyTree(tup))
  var lit = newNodeI(nkIntLit, tup.info)
  lit.intVal = i
  addSon(result, lit)

proc newTryFinally*(body, final: PNode): PNode =
  result = newTree(nkTryStmt, body, newTree(nkFinally, final))

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
    for i in countup(0, sonsLen(n) - 1):
      result = lookupInRecord(n.sons[i], id)
      if result != nil: return
  of nkRecCase:
    if n.sons[0].kind != nkSym: return
    result = lookupInRecord(n.sons[0], id)
    if result != nil: return
    for i in countup(1, sonsLen(n) - 1):
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
  assert t.kind != tyStmt
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
    assert t.kind != tyStmt
    field.position = sonsLen(obj.n)
    addSon(obj.n, newSymNode(field))
    result = field

proc newDotExpr(obj, b: PSym): PNode =
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

proc indirectAccess(a: PNode, b: string, info: TLineInfo; cache: IdentCache): PNode =
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

proc genDeref*(n: PNode): PNode =
  result = newNodeIT(nkHiddenDeref, n.info,
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

proc callProc(a: PNode): PNode =
  result = newNodeI(nkCall, a.info)
  result.add a
  result.typ = a.typ.sons[0]

# we have 4 cases to consider:
# - a void proc --> nothing to do
# - a proc returning GC'ed memory --> requires a flowVar
# - a proc returning non GC'ed memory --> pass as hidden 'var' parameter
# - not in a parallel environment --> requires a flowVar for memory safety
type
  TSpawnResult* = enum
    srVoid, srFlowVar, srByVar
  TFlowVarKind = enum
    fvInvalid # invalid type T for 'FlowVar[T]'
    fvGC      # FlowVar of a GC'ed type
    fvBlob    # FlowVar of a blob type

proc spawnResult*(t: PType; inParallel: bool): TSpawnResult =
  if t.isEmptyType: srVoid
  elif inParallel and not containsGarbageCollectedRef(t): srByVar
  else: srFlowVar

proc flowVarKind(t: PType): TFlowVarKind =
  if t.skipTypes(abstractInst).kind in {tyRef, tyString, tySequence}: fvGC
  elif containsGarbageCollectedRef(t): fvInvalid
  else: fvBlob

proc typeNeedsNoDeepCopy(t: PType): bool =
  var t = t.skipTypes(abstractInst)
  # for the tconvexhull example (and others) we're a bit lax here and pretend
  # seqs and strings are *by value* only and 'shallow' doesn't exist!
  if t.kind == tyString: return true
  # note that seq[T] is fine, but 'var seq[T]' is not, so we need to skip 'var'
  # for the stricter check and likewise we can skip 'seq' for a less
  # strict check:
  if t.kind in {tyVar, tyLent, tySequence}: t = t.lastSon
  result = not containsGarbageCollectedRef(t)

proc hoistExpr*(varSection, expr: PNode, name: PIdent, owner: PSym): PSym =
  result = newSym(skLet, name, owner, varSection.info, owner.options)
  result.flags.incl sfHoisted
  result.typ = expr.typ

  var varDef = newNodeI(nkIdentDefs, varSection.info, 3)
  varDef.sons[0] = newSymNode(result)
  varDef.sons[1] = newNodeI(nkEmpty, varSection.info)
  varDef.sons[2] = expr

  varSection.add varDef

proc addLocalVar(g: ModuleGraph; varSection, varInit: PNode; owner: PSym; typ: PType;
                 v: PNode; useShallowCopy=false): PSym =
  result = newSym(skTemp, getIdent(g.cache, genPrefix), owner, varSection.info,
                  owner.options)
  result.typ = typ
  incl(result.flags, sfFromGeneric)

  var vpart = newNodeI(nkIdentDefs, varSection.info, 3)
  vpart.sons[0] = newSymNode(result)
  vpart.sons[1] = newNodeI(nkEmpty, varSection.info)
  vpart.sons[2] = if varInit.isNil: v else: vpart[1]
  varSection.add vpart
  if varInit != nil:
    if useShallowCopy and typeNeedsNoDeepCopy(typ):
      varInit.add newFastAsgnStmt(newSymNode(result), v)
    else:
      let deepCopyCall = newNodeI(nkCall, varInit.info, 3)
      deepCopyCall.sons[0] = newSymNode(getSysMagic(g, varSection.info, "deepCopy", mDeepCopy))
      deepCopyCall.sons[1] = newSymNode(result)
      deepCopyCall.sons[2] = v
      varInit.add deepCopyCall

discard """
We generate roughly this:

proc f_wrapper(thread, args) =
  barrierEnter(args.barrier)  # for parallel statement
  var a = args.a # thread transfer; deepCopy or shallowCopy or no copy
                 # depending on whether we're in a 'parallel' statement
  var b = args.b
  var fv = args.fv

  fv.owner = thread # optional
  nimArgsPassingDone() # signal parent that the work is done
  #
  args.fv.blob = f(a, b, ...)
  nimFlowVarSignal(args.fv)

  # - or -
  f(a, b, ...)
  barrierLeave(args.barrier)  # for parallel statement

stmtList:
  var scratchObj
  scratchObj.a = a
  scratchObj.b = b

  nimSpawn(f_wrapper, addr scratchObj)
  scratchObj.fv # optional

"""

proc createWrapperProc(g: ModuleGraph; f: PNode; threadParam, argsParam: PSym;
                       varSection, varInit, call, barrier, fv: PNode;
                       spawnKind: TSpawnResult): PSym =
  var body = newNodeI(nkStmtList, f.info)
  body.flags.incl nfTransf # do not transform further

  var threadLocalBarrier: PSym
  if barrier != nil:
    var varSection2 = newNodeI(nkVarSection, barrier.info)
    threadLocalBarrier = addLocalVar(g, varSection2, nil, argsParam.owner,
                                     barrier.typ, barrier)
    body.add varSection2
    body.add callCodegenProc(g, "barrierEnter", threadLocalBarrier.info,
      threadLocalBarrier.newSymNode)
  var threadLocalProm: PSym
  if spawnKind == srByVar:
    threadLocalProm = addLocalVar(g, varSection, nil, argsParam.owner, fv.typ, fv)
  elif fv != nil:
    internalAssert g.config, fv.typ.kind == tyGenericInst
    threadLocalProm = addLocalVar(g, varSection, nil, argsParam.owner, fv.typ, fv)
  body.add varSection
  body.add varInit
  if fv != nil and spawnKind != srByVar:
    # generate:
    #   fv.owner = threadParam
    body.add newAsgnStmt(indirectAccess(threadLocalProm.newSymNode,
      "owner", fv.info, g.cache), threadParam.newSymNode)

  body.add callCodegenProc(g, "nimArgsPassingDone", threadParam.info,
    threadParam.newSymNode)
  if spawnKind == srByVar:
    body.add newAsgnStmt(genDeref(threadLocalProm.newSymNode), call)
  elif fv != nil:
    let fk = fv.typ.sons[1].flowVarKind
    if fk == fvInvalid:
      localError(g.config, f.info, "cannot create a flowVar of type: " &
        typeToString(fv.typ.sons[1]))
    body.add newAsgnStmt(indirectAccess(threadLocalProm.newSymNode,
      if fk == fvGC: "data" else: "blob", fv.info, g.cache), call)
    if fk == fvGC:
      let incRefCall = newNodeI(nkCall, fv.info, 2)
      incRefCall.sons[0] = newSymNode(getSysMagic(g, fv.info, "GCref", mGCref))
      incRefCall.sons[1] = indirectAccess(threadLocalProm.newSymNode,
                                          "data", fv.info, g.cache)
      body.add incRefCall
    if barrier == nil:
      # by now 'fv' is shared and thus might have beeen overwritten! we need
      # to use the thread-local view instead:
      body.add callCodegenProc(g, "nimFlowVarSignal", threadLocalProm.info,
        threadLocalProm.newSymNode)
  else:
    body.add call
  if barrier != nil:
    body.add callCodegenProc(g, "barrierLeave", threadLocalBarrier.info,
      threadLocalBarrier.newSymNode)

  var params = newNodeI(nkFormalParams, f.info)
  params.add newNodeI(nkEmpty, f.info)
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
  result = newSym(skProc, getIdent(g.cache, name), argsParam.owner, f.info,
                  argsParam.options)
  let emptyNode = newNodeI(nkEmpty, f.info)
  result.ast = newProcNode(nkProcDef, f.info, body = body,
      params = params, name = newSymNode(result), pattern = emptyNode,
      genericParams = emptyNode, pragmas = emptyNode,
      exceptions = emptyNode)
  result.typ = t

proc createCastExpr(argsParam: PSym; objType: PType): PNode =
  result = newNodeI(nkCast, argsParam.info)
  result.add newNodeI(nkEmpty, argsParam.info)
  result.add newSymNode(argsParam)
  result.typ = newType(tyPtr, objType.owner)
  result.typ.rawAddSon(objType)

proc setupArgsForConcurrency(g: ModuleGraph; n: PNode; objType: PType; scratchObj: PSym,
                             castExpr, call,
                             varSection, varInit, result: PNode) =
  let formals = n[0].typ.n
  let tmpName = getIdent(g.cache, genPrefix)
  for i in 1 ..< n.len:
    # we pick n's type here, which hopefully is 'tyArray' and not
    # 'tyOpenArray':
    var argType = n[i].typ.skipTypes(abstractInst)
    if i < formals.len and formals[i].typ.kind in {tyVar, tyLent}:
      localError(g.config, n[i].info, "'spawn'ed function cannot have a 'var' parameter")
    #elif containsTyRef(argType):
    #  localError(n[i].info, "'spawn'ed function cannot refer to 'ref'/closure")

    let fieldname = if i < formals.len: formals[i].sym.name else: tmpName
    var field = newSym(skField, fieldname, objType.owner, n.info, g.config.options)
    field.typ = argType
    objType.addField(field, g.cache)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n[i])

    let temp = addLocalVar(g, varSection, varInit, objType.owner, argType,
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

proc setupArgsForParallelism(g: ModuleGraph; n: PNode; objType: PType; scratchObj: PSym;
                             castExpr, call,
                             varSection, varInit, result: PNode) =
  let formals = n[0].typ.n
  let tmpName = getIdent(g.cache, genPrefix)
  # we need to copy the foreign scratch object fields into local variables
  # for correctness: These are called 'threadLocal' here.
  for i in 1 ..< n.len:
    let n = n[i]
    let argType = skipTypes(if i < formals.len: formals[i].typ else: n.typ,
                            abstractInst)
    #if containsTyRef(argType):
    #  localError(n.info, "'spawn'ed function cannot refer to 'ref'/closure")

    let fieldname = if i < formals.len: formals[i].sym.name else: tmpName
    var field = newSym(skField, fieldname, objType.owner, n.info, g.config.options)

    if argType.kind in {tyVarargs, tyOpenArray}:
      # important special case: we always create a zero-copy slice:
      let slice = newNodeI(nkCall, n.info, 4)
      slice.typ = n.typ
      slice.sons[0] = newSymNode(createMagic(g, "slice", mSlice))
      slice.sons[0].typ = getSysType(g, n.info, tyInt) # fake type
      var fieldB = newSym(skField, tmpName, objType.owner, n.info, g.config.options)
      fieldB.typ = getSysType(g, n.info, tyInt)
      objType.addField(fieldB, g.cache)

      if getMagic(n) == mSlice:
        let a = genAddrOf(n[1])
        field.typ = a.typ
        objType.addField(field, g.cache)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)

        var fieldA = newSym(skField, tmpName, objType.owner, n.info, g.config.options)
        fieldA.typ = getSysType(g, n.info, tyInt)
        objType.addField(fieldA, g.cache)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldA), n[2])
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), n[3])

        let threadLocal = addLocalVar(g, varSection,nil, objType.owner, fieldA.typ,
                                      indirectAccess(castExpr, fieldA, n.info),
                                      useShallowCopy=true)
        slice.sons[2] = threadLocal.newSymNode
      else:
        let a = genAddrOf(n)
        field.typ = a.typ
        objType.addField(field, g.cache)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
        result.add newFastAsgnStmt(newDotExpr(scratchObj, fieldB), genHigh(g, n))

        slice.sons[2] = newIntLit(g, n.info, 0)
      # the array itself does not need to go through a thread local variable:
      slice.sons[1] = genDeref(indirectAccess(castExpr, field, n.info))

      let threadLocal = addLocalVar(g, varSection,nil, objType.owner, fieldB.typ,
                                    indirectAccess(castExpr, fieldB, n.info),
                                    useShallowCopy=true)
      slice.sons[3] = threadLocal.newSymNode
      call.add slice
    elif (let size = computeSize(g.config, argType); size < 0 or size > 16) and
        n.getRoot != nil:
      # it is more efficient to pass a pointer instead:
      let a = genAddrOf(n)
      field.typ = a.typ
      objType.addField(field, g.cache)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), a)
      let threadLocal = addLocalVar(g, varSection,nil, objType.owner, field.typ,
                                    indirectAccess(castExpr, field, n.info),
                                    useShallowCopy=true)
      call.add(genDeref(threadLocal.newSymNode))
    else:
      # boring case
      field.typ = argType
      objType.addField(field, g.cache)
      result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n)
      let threadLocal = addLocalVar(g, varSection, varInit,
                                    objType.owner, field.typ,
                                    indirectAccess(castExpr, field, n.info),
                                    useShallowCopy=true)
      call.add(threadLocal.newSymNode)

proc wrapProcForSpawn*(g: ModuleGraph; owner: PSym; spawnExpr: PNode; retType: PType;
                       barrier, dest: PNode = nil): PNode =
  # if 'barrier' != nil, then it is in a 'parallel' section and we
  # generate quite different code
  let n = spawnExpr[^2]
  let spawnKind = spawnResult(retType, barrier!=nil)
  case spawnKind
  of srVoid:
    internalAssert g.config, dest == nil
    result = newNodeI(nkStmtList, n.info)
  of srFlowVar:
    internalAssert g.config, dest == nil
    result = newNodeIT(nkStmtListExpr, n.info, retType)
  of srByVar:
    if dest == nil: localError(g.config, n.info, "'spawn' must not be discarded")
    result = newNodeI(nkStmtList, n.info)

  if n.kind notin nkCallKinds:
    localError(g.config, n.info, "'spawn' takes a call expression")
    return
  if optThreadAnalysis in g.config.globalOptions:
    if {tfThread, tfNoSideEffect} * n[0].typ.flags == {}:
      localError(g.config, n.info, "'spawn' takes a GC safe call expression")
  var
    threadParam = newSym(skParam, getIdent(g.cache, "thread"), owner, n.info, g.config.options)
    argsParam = newSym(skParam, getIdent(g.cache, "args"), owner, n.info, g.config.options)
  block:
    let ptrType = getSysType(g, n.info, tyPointer)
    threadParam.typ = ptrType
    argsParam.typ = ptrType
    argsParam.position = 1

  var objType = createObj(g, owner, n.info)
  incl(objType.flags, tfFinal)
  let castExpr = createCastExpr(argsParam, objType)

  var scratchObj = newSym(skVar, getIdent(g.cache, "scratch"), owner, n.info, g.config.options)
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
  if fn.kind == nkClosure:
    localError(g.config, n.info, "closure in spawn environment is not allowed")
  if not (fn.kind == nkSym and fn.sym.kind in {skProc, skTemplate, skMacro,
                                               skFunc, skMethod, skConverter}):
    # for indirect calls we pass the function pointer in the scratchObj
    var argType = n[0].typ.skipTypes(abstractInst)
    var field = newSym(skField, getIdent(g.cache, "fn"), owner, n.info, g.config.options)
    field.typ = argType
    objType.addField(field, g.cache)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), n[0])
    fn = indirectAccess(castExpr, field, n.info)
  elif fn.kind == nkSym and fn.sym.kind == skIterator:
    localError(g.config, n.info, "iterator in spawn environment is not allowed")
  elif fn.typ.callConv == ccClosure:
    localError(g.config, n.info, "closure in spawn environment is not allowed")

  call.add(fn)
  var varSection = newNodeI(nkVarSection, n.info)
  var varInit = newNodeI(nkStmtList, n.info)
  if barrier.isNil:
    setupArgsForConcurrency(g, n, objType, scratchObj, castExpr, call,
                            varSection, varInit, result)
  else:
    setupArgsForParallelism(g, n, objType, scratchObj, castExpr, call,
                            varSection, varInit, result)

  var barrierAsExpr: PNode = nil
  if barrier != nil:
    let typ = newType(tyPtr, owner)
    typ.rawAddSon(magicsys.getCompilerProc(g, "Barrier").typ)
    var field = newSym(skField, getIdent(g.cache, "barrier"), owner, n.info, g.config.options)
    field.typ = typ
    objType.addField(field, g.cache)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), barrier)
    barrierAsExpr = indirectAccess(castExpr, field, n.info)

  var fvField, fvAsExpr: PNode = nil
  if spawnKind == srFlowVar:
    var field = newSym(skField, getIdent(g.cache, "fv"), owner, n.info, g.config.options)
    field.typ = retType
    objType.addField(field, g.cache)
    fvField = newDotExpr(scratchObj, field)
    fvAsExpr = indirectAccess(castExpr, field, n.info)
    # create flowVar:
    result.add newFastAsgnStmt(fvField, callProc(spawnExpr[^1]))
    if barrier == nil:
      result.add callCodegenProc(g, "nimFlowVarCreateSemaphore", fvField.info,
        fvField)

  elif spawnKind == srByVar:
    var field = newSym(skField, getIdent(g.cache, "fv"), owner, n.info, g.config.options)
    field.typ = newType(tyPtr, objType.owner)
    field.typ.rawAddSon(retType)
    objType.addField(field, g.cache)
    fvAsExpr = indirectAccess(castExpr, field, n.info)
    result.add newFastAsgnStmt(newDotExpr(scratchObj, field), genAddrOf(dest))

  let wrapper = createWrapperProc(g, fn, threadParam, argsParam,
                                  varSection, varInit, call,
                                  barrierAsExpr, fvAsExpr, spawnKind)
  result.add callCodegenProc(g, "nimSpawn" & $spawnExpr.len, wrapper.info,
    wrapper.newSymNode, genAddrOf(scratchObj.newSymNode), nil, spawnExpr)

  if spawnKind == srFlowVar: result.add fvField
