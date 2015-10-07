#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements lambda lifting for the transformator.

import
  intsets, strutils, lists, options, ast, astalgo, trees, treetab, msgs, os,
  idents, renderer, types, magicsys, rodread, lowerings

discard """
  The basic approach is that captured vars need to be put on the heap and
  that the calling chain needs to be explicitly modelled. Things to consider:

  proc a =
    var v = 0
    proc b =
      var w = 2

      for x in 0..3:
        proc c = capture v, w, x
        c()
    b()

    for x in 0..4:
      proc d = capture x
      d()

  Needs to be translated into:

  proc a =
    var cl: *
    new cl
    cl.v = 0

    proc b(cl) =
      var bcl: *
      new bcl
      bcl.w = 2
      bcl.up = cl

      for x in 0..3:
        var bcl2: *
        new bcl2
        bcl2.up = bcl
        bcl2.up2 = cl
        bcl2.x = x

        proc c(cl) = capture cl.up2.v, cl.up.w, cl.x
        c(bcl2)

      c(bcl)

    b(cl)

    for x in 0..4:
      var acl2: *
      new acl2
      acl2.x = x
      proc d(cl) = capture cl.x
      d(acl2)

  Closures as interfaces:

  proc outer: T =
    var captureMe: TObject # value type required for efficiency
    proc getter(): int = result = captureMe.x
    proc setter(x: int) = captureMe.x = x

    result = (getter, setter)

  Is translated to:

  proc outer: T =
    var cl: *
    new cl

    proc getter(cl): int = result = cl.captureMe.x
    proc setter(cl: *, x: int) = cl.captureMe.x = x

    result = ((cl, getter), (cl, setter))


  For 'byref' capture, the outer proc needs to access the captured var through
  the indirection too. For 'bycopy' capture, the outer proc accesses the var
  not through the indirection.

  Possible optimizations:

  1) If the closure contains a single 'ref' and this
  reference is not re-assigned (check ``sfAddrTaken`` flag) make this the
  closure. This is an important optimization if closures are used as
  interfaces.
  2) If the closure does not escape, put it onto the stack, not on the heap.
  3) Dataflow analysis would help to eliminate the 'up' indirections.
  4) If the captured var is not actually used in the outer proc (common?),
  put it into an inner proc.

"""

# Important things to keep in mind:
# * Don't base the analysis on nkProcDef et al. This doesn't work for
#   instantiated (formerly generic) procs. The analysis has to look at nkSym.
#   This also means we need to prevent the same proc is processed multiple
#   times via the 'processed' set.
# * Keep in mind that the owner of some temporaries used to be unreliable.
# * For closure iterators we merge the "real" potential closure with the
#   local storage requirements for efficiency. This means closure iterators
#   have slightly different semantics from ordinary closures.


const
  upName* = ":up" # field name for the 'up' reference
  paramName* = ":envP"
  envName* = ":env"

type
  POuterContext = ref TOuterContext

  TIter = object
    fn, closureParam, state, resultSym: PSym # most are only valid if
                                             # fn.kind == skClosureIterator
    obj: PType

  PEnv = ref TEnv
  TEnv {.final.} = object of RootObj
    attachedNode, replacementNode: PNode
    createdVar: PNode        # if != nil it is a used environment; for closure
                             # iterators this can be 'envParam.env'
    createdVarComesFromIter: bool
    capturedVars: seq[PSym] # captured variables in this environment
    up, next: PEnv          # outer scope and next to keep all in a list
    upField: PSym        # if != nil the dependency to the outer scope is used
    obj: PType
    fn: PSym                # function that belongs to this scope;
                            # if up.fn != fn then we cross function boundaries.
                            # This is an important case to consider.
    vars: IntSet           # variables belonging to this environment

  TOuterContext = object
    fn: PSym # may also be a module!
    head: PEnv
    capturedVars, processed: IntSet
    localsToAccess: TIdNodeTable
    lambdasToEnv: TIdTable # PSym->PEnv mapping

proc getStateType(iter: PSym): PType =
  var n = newNodeI(nkRange, iter.info)
  addSon(n, newIntNode(nkIntLit, -1))
  addSon(n, newIntNode(nkIntLit, 0))
  result = newType(tyRange, iter)
  result.n = n
  var intType = nilOrSysInt()
  if intType.isNil: intType = newType(tyInt, iter)
  rawAddSon(result, intType)

proc createStateField(iter: PSym): PSym =
  result = newSym(skField, getIdent(":state"), iter, iter.info)
  result.typ = getStateType(iter)

proc createEnvObj(owner: PSym): PType =
  # YYY meh, just add the state field for every closure for now, it's too
  # hard to figure out if it comes from a closure iterator:
  result = createObj(owner, owner.info)
  rawAddField(result, createStateField(owner))

proc newIterResult(iter: PSym): PSym =
  if resultPos < iter.ast.len:
    result = iter.ast.sons[resultPos].sym
  else:
    # XXX a bit hacky:
    result = newSym(skResult, getIdent":result", iter, iter.info)
    result.typ = iter.typ.sons[0]
    incl(result.flags, sfUsed)
    iter.ast.add newSymNode(result)

proc addHiddenParam(routine: PSym, param: PSym) =
  assert param.kind == skParam
  var params = routine.ast.sons[paramsPos]
  # -1 is correct here as param.position is 0 based but we have at position 0
  # some nkEffect node:
  param.position = routine.typ.n.len-1
  addSon(params, newSymNode(param))
  incl(routine.typ.flags, tfCapturesEnv)
  assert sfFromGeneric in param.flags
  #echo "produced environment: ", param.id, " for ", routine.name.s

proc getHiddenParam(routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  internalAssert hidden.kind == nkSym and hidden.sym.kind == skParam
  result = hidden.sym
  assert sfFromGeneric in result.flags

proc getEnvParam(routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  if hidden.kind == nkSym and hidden.sym.name.s == paramName:
    result = hidden.sym
    assert sfFromGeneric in result.flags

proc initIter(iter: PSym): TIter =
  result.fn = iter
  if iter.kind == skClosureIterator:
    var cp = getEnvParam(iter)
    if cp == nil:
      result.obj = createEnvObj(iter)

      cp = newSym(skParam, getIdent(paramName), iter, iter.info)
      incl(cp.flags, sfFromGeneric)
      cp.typ = newType(tyRef, iter)
      rawAddSon(cp.typ, result.obj)
      addHiddenParam(iter, cp)
    else:
      result.obj = cp.typ.sons[0]
      assert result.obj.kind == tyObject
    internalAssert result.obj.n.len > 0
    result.state = result.obj.n[0].sym
    result.closureParam = cp
    if iter.typ.sons[0] != nil:
      result.resultSym = newIterResult(iter)
      #iter.ast.add(newSymNode(c.resultSym))

proc newOuterContext(fn: PSym): POuterContext =
  new(result)
  result.fn = fn
  result.capturedVars = initIntSet()
  result.processed = initIntSet()
  initIdNodeTable(result.localsToAccess)
  initIdTable(result.lambdasToEnv)

proc newEnv(o: POuterContext; up: PEnv, n: PNode; owner: PSym): PEnv =
  new(result)
  result.capturedVars = @[]
  result.up = up
  result.attachedNode = n
  result.fn = owner
  result.vars = initIntSet()
  result.next = o.head
  o.head = result
  if owner.kind != skModule and (up == nil or up.fn != owner):
    let param = getEnvParam(owner)
    if param != nil:
      result.obj = param.typ.sons[0]
      assert result.obj.kind == tyObject
  if result.obj.isNil:
    result.obj = createEnvObj(owner)

proc addCapturedVar(e: PEnv, v: PSym) =
  for x in e.capturedVars:
    if x == v: return
  e.capturedVars.add(v)
  addField(e.obj, v)

proc newCall(a: PSym, b: PNode): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add b

proc isInnerProc(s, outerProc: PSym): bool =
  if s.kind in {skProc, skMethod, skConverter, skClosureIterator}:
    var owner = s.skipGenericOwner
    while true:
      if owner.isNil: return false
      if owner == outerProc: return true
      owner = owner.owner
  #s.typ.callConv == ccClosure

proc addClosureParam(fn: PSym; e: PEnv) =
  var cp = getEnvParam(fn)
  if cp == nil:
    cp = newSym(skParam, getIdent(paramName), fn, fn.info)
    incl(cp.flags, sfFromGeneric)
    cp.typ = newType(tyRef, fn)
    rawAddSon(cp.typ, e.obj)
    addHiddenParam(fn, cp)
    #else:
    #cp.typ.sons[0] = e.obj
    #assert e.obj.kind == tyObject

proc illegalCapture(s: PSym): bool {.inline.} =
  result = skipTypes(s.typ, abstractInst).kind in
                   {tyVar, tyOpenArray, tyVarargs} or
      s.kind == skResult

proc interestingVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar, skParam, skResult} and
    sfGlobal notin s.flags

proc nestedAccess(top: PEnv; local: PSym): PNode =
  # Parts after the transformation are in []:
  #
  #  proc main =
  #    var [:env.]foo = 23
  #    proc outer(:paramO) =
  #      [var :envO; createClosure(:envO); :envO.up = paramO]
  #      proc inner(:paramI) =
  #        echo [:paramI.up.]foo
  #      inner([:envO])
  #    outer([:env])
  if not interestingVar(local) or top.fn == local.owner:
    return nil
  # check it's in fact a captured variable:
  var it = top
  while it != nil:
    if it.vars.contains(local.id): break
    it = it.up
  if it == nil: return nil
  let envParam = top.fn.getEnvParam
  internalAssert(not envParam.isNil)
  var access = newSymNode(envParam)
  it = top.up
  while it != nil:
    if it.vars.contains(local.id):
      access = indirectAccess(access, local, local.info)
      return access
    internalAssert it.upField != nil
    access = indirectAccess(access, it.upField, local.info)
    it = it.up
  when false:
    # Type based expression construction works too, but turned out to hide
    # other bugs:
    while true:
      let obj = access.typ.sons[0]
      let field = getFieldFromObj(obj, local)
      if field != nil:
        return rawIndirectAccess(access, field, local.info)
      let upField = lookupInRecord(obj.n, getIdent(upName))
      if upField == nil: break
      access = rawIndirectAccess(access, upField, local.info)
  return nil

proc createUpField(obj, fieldType: PType): PSym =
  let pos = obj.n.len
  result = newSym(skField, getIdent(upName), obj.owner, obj.owner.info)
  result.typ = newType(tyRef, obj.owner)
  result.position = pos
  rawAddSon(result.typ, fieldType)
  #rawAddField(obj, result)
  addField(obj, result)

proc captureVar(o: POuterContext; top: PEnv; local: PSym;
                info: TLineInfo): bool =
  # first check if we should be concerned at all:
  var it = top
  while it != nil:
    if it.vars.contains(local.id): break
    it = it.up
  if it == nil: return false
  # yes, so mark every 'up' pointer as taken:
  if illegalCapture(local) or top.fn.typ.callConv notin {ccClosure, ccDefault}:
    localError(info, errIllegalCaptureX, local.name.s)
  it = top
  while it != nil:
    if it.vars.contains(local.id): break
    # keep in mind that the first element of the chain belong to top.fn itself
    # and these don't need any upFields
    if it.upField == nil and it.up != nil and it.fn != top.fn:
      it.upField = createUpField(it.obj, it.up.obj)

    if it.fn != local.owner:
      it.fn.typ.callConv = ccClosure
      incl(it.fn.typ.flags, tfCapturesEnv)

      var u = it.up
      while u != nil and u.fn == it.fn: u = u.up
      addClosureParam(it.fn, u)

      if idTableGet(o.lambdasToEnv, it.fn) == nil:
        if u != nil: idTablePut(o.lambdasToEnv, it.fn, u)

    it = it.up
  # don't do this: 'top' might not require a closure:
  #if idTableGet(o.lambdasToEnv, it.fn) == nil:
  #  idTablePut(o.lambdasToEnv, it.fn, top)

  # mark as captured:
  #if top.iter != nil:
  #  if not containsOrIncl(o.capturedVars, local.id):
  #    #addField(top.iter.obj, local)
  #    addCapturedVar(it, local)
  #else:
  incl(o.capturedVars, local.id)
  addCapturedVar(it, local)
  result = true

proc semCaptureSym*(s, owner: PSym) =
  if interestingVar(s) and owner.id != s.owner.id and s.kind != skResult:
    if owner.typ != nil and not isGenericRoutine(owner):
      # XXX: is this really safe?
      # if we capture a var from another generic routine,
      # it won't be consider captured.
      owner.typ.callConv = ccClosure
    #echo "semCaptureSym ", owner.name.s, owner.id, " ", s.name.s, s.id
    # since the analysis is not entirely correct, we don't set 'tfCapturesEnv'
    # here

proc gatherVars(o: POuterContext; e: PEnv; n: PNode): int =
  # gather used vars for closure generation; returns number of captured vars
  if n == nil: return 0
  case n.kind
  of nkSym:
    var s = n.sym
    if interestingVar(s) and e.fn != s.owner:
      if captureVar(o, e, s, n.info): result = 1
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit, nkClosure, nkProcDef,
     nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, nkTypeSection:
    discard
  else:
    for k in countup(0, sonsLen(n) - 1):
      result += gatherVars(o, e, n.sons[k])

proc generateThunk(prc: PNode, dest: PType): PNode =
  ## Converts 'prc' into '(thunk, nil)' so that it's compatible with
  ## a closure.

  # we cannot generate a proper thunk here for GC-safety reasons (see internal
  # documentation):
  if gCmd == cmdCompileToJS: return prc
  result = newNodeIT(nkClosure, prc.info, dest)
  var conv = newNodeIT(nkHiddenStdConv, prc.info, dest)
  conv.add(emptyNode)
  conv.add(prc)
  result.add(conv)
  result.add(newNodeIT(nkNilLit, prc.info, getSysType(tyNil)))

proc transformOuterConv(n: PNode): PNode =
  # numeric types need range checks:
  var dest = skipTypes(n.typ, abstractVarRange)
  var source = skipTypes(n.sons[1].typ, abstractVarRange)
  if dest.kind == tyProc:
    if dest.callConv == ccClosure and source.callConv == ccDefault:
      result = generateThunk(n.sons[1], dest)

proc makeClosure(prc: PSym; env: PNode; info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  if env == nil:
    result.add(newNodeIT(nkNilLit, info, getSysType(tyNil)))
  else:
    result.add(env)

proc newClosureCreationVar(e: PEnv): PNode =
  var v = newSym(skVar, getIdent(envName), e.fn, e.attachedNode.info)
  incl(v.flags, sfShadowed)
  v.typ = newType(tyRef, e.fn)
  v.typ.rawAddSon(e.obj)
  if e.fn.kind == skClosureIterator:
    let it = initIter(e.fn)
    addUniqueField(it.obj, v)
    result = indirectAccess(newSymNode(it.closureParam), v, v.info)
  else:
    result = newSymNode(v)

proc getClosureVar(e: PEnv): PNode =
  if e.createdVar == nil:
    result = newClosureCreationVar(e)
    e.createdVar = result
  else:
    result = e.createdVar

proc findEnv(o: POuterContext; s: PSym): PEnv =
  var env = o.head
  while env != nil:
    if env.fn == s: break
    env = env.next
  internalAssert env != nil and env.up != nil
  result = env.up
  while result.fn == s: result = result.up

proc transformInnerProc(o: POuterContext; e: PEnv, n: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: discard
  of nkSym:
    let s = n.sym
    if s == e.fn:
      # recursive calls go through (lambda, hiddenParam):
      result = makeClosure(s, getEnvParam(s).newSymNode, n.info)
    elif isInnerProc(s, o.fn) and s.typ.callConv == ccClosure:
      # ugh: call to some other inner proc;
      result = makeClosure(s, findEnv(o, s).getClosureVar, n.info)
    else:
      # captured symbol?
      result = nestedAccess(e, n.sym)
      #result = idNodeTableGet(i.localsToAccess, n.sym)
    #of nkLambdaKinds, nkIteratorDef:
    #  if n.typ != nil:
    #    result = transformInnerProc(o, e, n.sons[namePos])
    #of nkClosure:
    #  let x = transformInnerProc(o, e, n.sons[0])
    #  if x != nil: n.sons[0] = x
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
     nkLambdaKinds, nkIteratorDef, nkClosure:
    # don't recurse here:
    discard
  else:
    for j in countup(0, sonsLen(n) - 1):
      let x = transformInnerProc(o, e, n.sons[j])
      if x != nil: n.sons[j] = x

proc closureCreationPoint(n: PNode): PNode =
  if n.kind == nkStmtList and n.len >= 1 and n[0].kind == nkEmpty:
    # we already have a free slot
    result = n
  else:
    result = newNodeI(nkStmtList, n.info)
    result.add(emptyNode)
    result.add(n)
  #result.flags.incl nfLL

proc addParamsToEnv(fn: PSym; env: PEnv) =
  let params = fn.typ.n
  for i in 1.. <params.len:
    if params.sons[i].kind != nkSym:
      internalError(params.info, "liftLambdas: strange params")
    let param = params.sons[i].sym
    env.vars.incl(param.id)
  # put the 'result' into the environment so it can be captured:
  let ast = fn.ast
  if resultPos < sonsLen(ast) and ast.sons[resultPos].kind == nkSym:
    env.vars.incl(ast.sons[resultPos].sym.id)

proc searchForInnerProcs(o: POuterContext, n: PNode, env: PEnv) =
  if n == nil: return
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit:
    discard
  of nkSym:
    let fn = n.sym
    if isInnerProc(fn, o.fn) and not containsOrIncl(o.processed, fn.id):
      let body = fn.getBody

      # handle deeply nested captures:
      let ex = closureCreationPoint(body)
      let envB = newEnv(o, env, ex, fn)
      addParamsToEnv(fn, envB)
      searchForInnerProcs(o, body, envB)
      fn.ast.sons[bodyPos] = ex

      let capturedCounter = gatherVars(o, envB, body)
      # dummy closure param needed?
      if capturedCounter == 0 and fn.typ.callConv == ccClosure:
        #assert tfCapturesEnv notin n.sym.typ.flags
        if idTableGet(o.lambdasToEnv, fn) == nil:
          idTablePut(o.lambdasToEnv, fn, env)
        addClosureParam(fn, env)

      elif fn.getEnvParam != nil:
        # only transform if it really needs a closure:
        let ti = transformInnerProc(o, envB, body)
        if ti != nil: fn.ast.sons[bodyPos] = ti
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      searchForInnerProcs(o, n.sons[namePos], env)
  of nkWhileStmt, nkForStmt, nkParForStmt, nkBlockStmt:
    # some nodes open a new scope, so they are candidates for the insertion
    # of closure creation; however for simplicity we merge closures between
    # branches, in fact, only loop bodies are of interest here as only they
    # yield observable changes in semantics. For Zahary we also
    # include ``nkBlock``. We don't do this for closure iterators because
    # 'yield' can produce wrong code otherwise (XXX show example):
    if env.fn.kind != skClosureIterator:
      var body = n.len-1
      for i in countup(0, body - 1): searchForInnerProcs(o, n.sons[i], env)
      # special handling for the loop body:
      let ex = closureCreationPoint(n.sons[body])
      searchForInnerProcs(o, n.sons[body], newEnv(o, env, ex, env.fn))
      n.sons[body] = ex
    else:
      for i in countup(0, sonsLen(n) - 1):
        searchForInnerProcs(o, n.sons[i], env)
  of nkVarSection, nkLetSection:
    # we need to compute a mapping var->declaredBlock. Note: The definition
    # counts, not the block where it is captured!
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkCommentStmt: discard
      elif it.kind == nkIdentDefs:
        var L = sonsLen(it)
        if it.sons[0].kind == nkSym:
          # this can be false for recursive invocations that already
          # transformed it into 'env.varName':
          env.vars.incl(it.sons[0].sym.id)
        searchForInnerProcs(o, it.sons[L-1], env)
      elif it.kind == nkVarTuple:
        var L = sonsLen(it)
        for j in countup(0, L-3):
          #echo "set: ", it.sons[j].sym.name.s, " ", o.currentBlock == nil
          if it.sons[j].kind == nkSym:
            env.vars.incl(it.sons[j].sym.id)
        searchForInnerProcs(o, it.sons[L-1], env)
      else:
        internalError(it.info, "searchForInnerProcs")
  of nkClosure:
    searchForInnerProcs(o, n.sons[0], env)
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
     nkTypeSection:
    # don't recurse here:
    discard
  else:
    for i in countup(0, sonsLen(n) - 1):
      searchForInnerProcs(o, n.sons[i], env)

proc newAsgnStmt(le, ri: PNode, info: TLineInfo): PNode =
  # Bugfix: unfortunately we cannot use 'nkFastAsgn' here as that would
  # mean to be able to capture string literals which have no GC header.
  # However this can only happen if the capture happens through a parameter,
  # which is however the only case when we generate an assignment in the first
  # place.
  result = newNodeI(nkAsgn, info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc rawClosureCreation(o: POuterContext, scope: PEnv; env: PNode): PNode =
  result = newNodeI(nkStmtList, env.info)
  if env.kind == nkSym:
    var v = newNodeI(nkVarSection, env.info)
    addVar(v, env)
    result.add(v)
  # add 'new' statement:
  result.add(newCall(getSysSym"internalNew", env))

  # add assignment statements:
  for local in scope.capturedVars:
    let fieldAccess = indirectAccess(env, local, env.info)
    if local.kind == skParam:
      # maybe later: (sfByCopy in local.flags)
      # add ``env.param = param``
      result.add(newAsgnStmt(fieldAccess, newSymNode(local), env.info))
    # it can happen that we already captured 'local' in some other environment
    # then we capture by copy for now. This is not entirely correct but better
    # than nothing:
    let existing = idNodeTableGet(o.localsToAccess, local)
    if existing.isNil:
      idNodeTablePut(o.localsToAccess, local, fieldAccess)
    else:
      result.add(newAsgnStmt(fieldAccess, existing, env.info))
  if scope.upField != nil:
    # "up" chain has been used:
    if scope.up.fn != scope.fn:
      # crosses function boundary:
      result.add(newAsgnStmt(indirectAccess(env, scope.upField, env.info),
                 newSymNode(getEnvParam(scope.fn)), env.info))
    else:
      result.add(newAsgnStmt(indirectAccess(env, scope.upField, env.info),
                 getClosureVar(scope.up), env.info))

proc generateClosureCreation(o: POuterContext, scope: PEnv): PNode =
  var env = getClosureVar(scope)
  result = rawClosureCreation(o, scope, env)

proc generateIterClosureCreation(o: POuterContext; env: PEnv;
                                 scope: PNode): PNode =
  if env.createdVarComesFromIter or env.createdVar.isNil:
    # we have to create a new closure:
    result = newClosureCreationVar(env)
    let cc = rawClosureCreation(o, env, result)
    var insertPoint = scope.sons[0]
    if insertPoint.kind == nkEmpty: scope.sons[0] = cc
    else:
      assert cc.kind == nkStmtList and insertPoint.kind == nkStmtList
      for x in cc: insertPoint.add(x)
    if env.createdVar == nil: env.createdVar = result
  else:
    result = env.createdVar
  env.createdVarComesFromIter = true

proc interestingIterVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar} and sfGlobal notin s.flags

proc transformOuterProc(o: POuterContext, n: PNode, it: TIter): PNode

proc transformYield(c: POuterContext, n: PNode, it: TIter): PNode =
  assert it.state != nil
  assert it.state.typ != nil
  assert it.state.typ.n != nil
  inc it.state.typ.n.sons[1].intVal
  let stateNo = it.state.typ.n.sons[1].intVal

  var stateAsgnStmt = newNodeI(nkAsgn, n.info)
  stateAsgnStmt.add(rawIndirectAccess(newSymNode(it.closureParam),
                    it.state, n.info))
  stateAsgnStmt.add(newIntTypeNode(nkIntLit, stateNo, getSysType(tyInt)))

  var retStmt = newNodeI(nkReturnStmt, n.info)
  if n.sons[0].kind != nkEmpty:
    var a = newNodeI(nkAsgn, n.sons[0].info)
    var retVal = transformOuterProc(c, n.sons[0], it)
    addSon(a, newSymNode(it.resultSym))
    addSon(a, if retVal.isNil: n.sons[0] else: retVal)
    retStmt.add(a)
  else:
    retStmt.add(emptyNode)

  var stateLabelStmt = newNodeI(nkState, n.info)
  stateLabelStmt.add(newIntTypeNode(nkIntLit, stateNo, getSysType(tyInt)))

  result = newNodeI(nkStmtList, n.info)
  result.add(stateAsgnStmt)
  result.add(retStmt)
  result.add(stateLabelStmt)

proc transformReturn(c: POuterContext, n: PNode, it: TIter): PNode =
  result = newNodeI(nkStmtList, n.info)
  var stateAsgnStmt = newNodeI(nkAsgn, n.info)
  stateAsgnStmt.add(rawIndirectAccess(newSymNode(it.closureParam), it.state,
                    n.info))
  stateAsgnStmt.add(newIntTypeNode(nkIntLit, -1, getSysType(tyInt)))
  result.add(stateAsgnStmt)
  result.add(n)

proc outerProcSons(o: POuterContext, n: PNode, it: TIter) =
  for i in countup(0, sonsLen(n) - 1):
    let x = transformOuterProc(o, n.sons[i], it)
    if x != nil: n.sons[i] = x

proc liftIterSym(n: PNode; owner: PSym): PNode =
  # transforms  (iter)  to  (let env = newClosure[iter](); (iter, env))
  let iter = n.sym
  assert iter.kind == skClosureIterator

  result = newNodeIT(nkStmtListExpr, n.info, n.typ)

  let hp = getHiddenParam(iter)
  let env = newSym(skLet, iter.name, owner, n.info)
  env.typ = hp.typ
  env.flags = hp.flags
  var v = newNodeI(nkVarSection, n.info)
  addVar(v, newSymNode(env))
  result.add(v)
  # add 'new' statement:
  let envAsNode = env.newSymNode
  result.add newCall(getSysSym"internalNew", envAsNode)
  result.add makeClosure(iter, envAsNode, n.info)

when false:
  proc transformRemainingLocals(n: PNode; it: TIter): PNode =
    assert it.fn.kind == skClosureIterator
    result = n
    case n.kind
    of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: discard
    of nkSym:
      let local = n.sym
      if interestingIterVar(local) and it.fn == local.owner:
        addUniqueField(it.obj, local)
        result = indirectAccess(newSymNode(it.closureParam), local, n.info)
    else:
      result = newNodeI(n.kind, n.info, n.len)
      for i in 0.. <n.safeLen:
        result.sons[i] = transformRemainingLocals(n.sons[i], it)

template envActive(env): expr =
  (env.capturedVars.len > 0 or env.upField != nil)

# We have to split up environment creation in 2 steps:
# 1. Generate it and store it in env.replacementNode
# 2. Insert replacementNode into its forseen slot.
# This split is necessary so that assignments belonging to closure
# creation like 'env.param = param' are not transformed
# into 'env.param = env.param'.
proc createEnvironments(o: POuterContext) =
  var env = o.head
  while env != nil:
    if envActive(env):
      var scope = env.attachedNode
      assert scope.kind == nkStmtList
      if scope.sons[0].kind == nkEmpty:
        # prepare for closure construction:
        env.replacementNode = generateClosureCreation(o, env)
    env = env.next

proc finishEnvironments(o: POuterContext) =
  var env = o.head
  while env != nil:
    if env.replacementNode != nil:
      var scope = env.attachedNode
      assert scope.kind == nkStmtList
      if scope.sons[0].kind == nkEmpty:
        # change the empty node to contain the closure construction:
        scope.sons[0] = env.replacementNode
        when false:
          if env.fn.kind == skClosureIterator:
            scope.sons[0] = transformRemainingLocals(env.replacementNode,
                                                     initIter(env.fn))
          else:
            scope.sons[0] = env.replacementNode
    env = env.next

proc transformOuterProcBody(o: POuterContext, n: PNode; it: TIter): PNode =
  if nfLL in n.flags:
    result = nil
  elif it.fn.kind == skClosureIterator:
    # unfortunately control flow is still convoluted and we can end up
    # multiple times here for the very same iterator. We shield against this
    # with some rather primitive check for now:
    if n.kind == nkStmtList and n.len > 0:
      if n.sons[0].kind == nkGotoState: return nil
      if n.len > 1 and n[1].kind == nkStmtList and n[1].len > 0 and
          n[1][0].kind == nkGotoState:
        return nil
    result = newNodeI(nkStmtList, it.fn.info)
    var gs = newNodeI(nkGotoState, it.fn.info)
    assert it.closureParam != nil
    assert it.state != nil
    gs.add(rawIndirectAccess(newSymNode(it.closureParam), it.state, it.fn.info))
    result.add(gs)
    var state0 = newNodeI(nkState, it.fn.info)
    state0.add(newIntNode(nkIntLit, 0))
    result.add(state0)

    let newBody = transformOuterProc(o, n, it)
    if newBody != nil:
      result.add(newBody)
    else:
      result.add(n)

    var stateAsgnStmt = newNodeI(nkAsgn, it.fn.info)
    stateAsgnStmt.add(rawIndirectAccess(newSymNode(it.closureParam),
                      it.state, it.fn.info))
    stateAsgnStmt.add(newIntTypeNode(nkIntLit, -1, getSysType(tyInt)))
    result.add(stateAsgnStmt)
    result.flags.incl nfLL
  else:
    result = transformOuterProc(o, n, it)
    if result != nil: result.flags.incl nfLL

proc transformOuterProc(o: POuterContext, n: PNode; it: TIter): PNode =
  if n == nil or nfLL in n.flags: return nil
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: discard
  of nkSym:
    var local = n.sym

    if isInnerProc(local, o.fn) and o.processed.contains(local.id):
      o.processed.excl(local.id)
      let body = local.getBody
      let newBody = transformOuterProcBody(o, body, initIter(local))
      if newBody != nil:
        local.ast.sons[bodyPos] = newBody

    if it.fn.kind == skClosureIterator and interestingIterVar(local) and
        it.fn == local.owner:
      # every local goes through the closure:
      #if not containsOrIncl(o.capturedVars, local.id):
      #  addField(it.obj, local)
      if contains(o.capturedVars, local.id):
        # change 'local' to 'closure.local', unless it's a 'byCopy' variable:
        # if sfByCopy notin local.flags:
        result = idNodeTableGet(o.localsToAccess, local)
        assert result != nil, "cannot find: " & local.name.s
        return result
      else:
        addUniqueField(it.obj, local)
        return indirectAccess(newSymNode(it.closureParam), local, n.info)

    if local.kind == skClosureIterator:
      # bug #3354; allow for
      #iterator iter(): int {.closure.}=
      #  s.add(iter)
      #  yield 1

      #if local == o.fn or local == it.fn:
      #  message(n.info, errRecursiveDependencyX, local.name.s)

      # consider: [i1, i2, i1]  Since we merged the iterator's closure
      # with the captured owning variables, we need to generate the
      # closure generation code again:
      # XXX why doesn't this work?
      var closure = PEnv(idTableGet(o.lambdasToEnv, local))
      if closure.isNil:
        return liftIterSym(n, o.fn)
      else:
        let createdVar = generateIterClosureCreation(o, closure,
                                                     closure.attachedNode)
        let lpt = getHiddenParam(local).typ
        if lpt != createdVar.typ:
          assert lpt.kind == tyRef and createdVar.typ.kind == tyRef
          # fix bug 'tshallowcopy_closures' but report if this gets any weirder:
          if createdVar.typ.sons[0].len == 1 and lpt.sons[0].len >= 1:
            createdVar.typ = lpt
            if createdVar.kind == nkSym: createdVar.sym.typ = lpt
            closure.obj = lpt.sons[0]
          else:
            internalError(n.info, "environment computation failed")
        return makeClosure(local, createdVar, n.info)

    var closure = PEnv(idTableGet(o.lambdasToEnv, local))
    if closure != nil:
      # we need to replace the lambda with '(lambda, env)':
      let a = closure.createdVar
      if a != nil:
        return makeClosure(local, a, n.info)
      else:
        # can happen for dummy closures:
        var scope = closure.attachedNode
        assert scope.kind == nkStmtList
        if scope.sons[0].kind == nkEmpty:
          # change the empty node to contain the closure construction:
          scope.sons[0] = generateClosureCreation(o, closure)
        let x = closure.createdVar
        assert x != nil
        return makeClosure(local, x, n.info)

    if not contains(o.capturedVars, local.id): return
    # change 'local' to 'closure.local', unless it's a 'byCopy' variable:
    # if sfByCopy notin local.flags:
    result = idNodeTableGet(o.localsToAccess, local)
    assert result != nil, "cannot find: " & local.name.s
    # else it is captured by copy and this means that 'outer' should continue
    # to access the local as a local.
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      result = transformOuterProc(o, n.sons[namePos], it)
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef:
    # don't recurse here:
    discard
  of nkClosure:
    if n.sons[0].kind == nkSym:
      var local = n.sons[0].sym
      if isInnerProc(local, o.fn) and o.processed.contains(local.id):
        o.processed.excl(local.id)
        let body = local.getBody
        let newBody = transformOuterProcBody(o, body, initIter(local))
        if newBody != nil:
          local.ast.sons[bodyPos] = newBody
    when false:
      if n.sons[1].kind == nkSym:
        var local = n.sons[1].sym
        if it.fn.kind == skClosureIterator and interestingIterVar(local) and
            it.fn == local.owner:
          # every local goes through the closure:
          addUniqueField(it.obj, local)
          n.sons[1] = indirectAccess(newSymNode(it.closureParam), local, n.info)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    let x = transformOuterProc(o, n.sons[1], it)
    if x != nil: n.sons[1] = x
    result = transformOuterConv(n)
  of nkYieldStmt:
    if it.fn.kind == skClosureIterator: result = transformYield(o, n, it)
    else: outerProcSons(o, n, it)
  of nkReturnStmt:
    if it.fn.kind == skClosureIterator: result = transformReturn(o, n, it)
    else: outerProcSons(o, n, it)
  else:
    outerProcSons(o, n, it)

proc liftLambdas*(fn: PSym, body: PNode): PNode =
  # XXX gCmd == cmdCompileToJS does not suffice! The compiletime stuff needs
  # the transformation even when compiling to JS ...

  # However we can do lifting for the stuff which is *only* compiletime.
  let isCompileTime = sfCompileTime in fn.flags or fn.kind == skMacro

  if body.kind == nkEmpty or (gCmd == cmdCompileToJS and not isCompileTime) or
      fn.skipGenericOwner.kind != skModule:
    # ignore forward declaration:
    result = body
  else:
    #if fn.name.s == "sort":
    #  echo rendertree(fn.ast, {renderIds})
    var o = newOuterContext(fn)
    let ex = closureCreationPoint(body)
    let env = newEnv(o, nil, ex, fn)
    addParamsToEnv(fn, env)
    searchForInnerProcs(o, body, env)
    createEnvironments(o)
    if fn.kind == skClosureIterator:
      result = transformOuterProcBody(o, body, initIter(fn))
    else:
      discard transformOuterProcBody(o, body, initIter(fn))
      result = ex
    finishEnvironments(o)
    #if fn.name.s == "parseLong":
    #  echo rendertree(result, {renderIds})

proc liftLambdasForTopLevel*(module: PSym, body: PNode): PNode =
  if body.kind == nkEmpty or gCmd == cmdCompileToJS:
    result = body
  else:
    var o = newOuterContext(module)
    let ex = closureCreationPoint(body)
    let env = newEnv(o, nil, ex, module)
    searchForInnerProcs(o, body, env)
    createEnvironments(o)
    discard transformOuterProc(o, body, initIter(module))
    finishEnvironments(o)
    result = ex

# ------------------- iterator transformation --------------------------------

proc liftForLoop*(body: PNode): PNode =
  # problem ahead: the iterator could be invoked indirectly, but then
  # we don't know what environment to create here:
  #
  # iterator count(): int =
  #   yield 0
  #
  # iterator count2(): int =
  #   var x = 3
  #   yield x
  #   inc x
  #   yield x
  #
  # proc invoke(iter: iterator(): int) =
  #   for x in iter(): echo x
  #
  # --> When to create the closure? --> for the (count) occurrence!
  discard """
      for i in foo(): ...

    Is transformed to:

      cl = createClosure()
      while true:
        let i = foo(cl)
        nkBreakState(cl.state)
        ...
    """
  var L = body.len
  if not (body.kind == nkForStmt and body[L-2].kind in nkCallKinds):
    localError(body.info, "ignored invalid for loop")
    return body
  var call = body[L-2]

  result = newNodeI(nkStmtList, body.info)

  # static binding?
  var env: PSym
  if call[0].kind == nkSym and call[0].sym.kind == skClosureIterator:
    # createClosure()
    let iter = call[0].sym
    assert iter.kind == skClosureIterator
    env = copySym(getHiddenParam(iter))

    var v = newNodeI(nkVarSection, body.info)
    addVar(v, newSymNode(env))
    result.add(v)
    # add 'new' statement:
    result.add(newCall(getSysSym"internalNew", env.newSymNode))

  var loopBody = newNodeI(nkStmtList, body.info, 3)
  var whileLoop = newNodeI(nkWhileStmt, body.info, 2)
  whileLoop.sons[0] = newIntTypeNode(nkIntLit, 1, getSysType(tyBool))
  whileLoop.sons[1] = loopBody
  result.add whileLoop

  # setup loopBody:
  # gather vars in a tuple:
  var v2 = newNodeI(nkLetSection, body.info)
  var vpart = newNodeI(if L == 3: nkIdentDefs else: nkVarTuple, body.info)
  for i in 0 .. L-3:
    assert body[i].kind == nkSym
    body[i].sym.kind = skLet
    addSon(vpart, body[i])

  addSon(vpart, ast.emptyNode) # no explicit type
  if not env.isNil:
    call.sons[0] = makeClosure(call.sons[0].sym, env.newSymNode, body.info)
  addSon(vpart, call)
  addSon(v2, vpart)

  loopBody.sons[0] = v2
  var bs = newNodeI(nkBreakState, body.info)
  bs.addSon(call.sons[0])
  loopBody.sons[1] = bs
  loopBody.sons[2] = body[L-1]
