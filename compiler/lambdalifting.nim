#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements lambda lifting for the transformator.

import 
  intsets, strutils, lists, options, ast, astalgo, trees, treetab, msgs, os, 
  idents, renderer, types, magicsys, rodread

discard """
  The basic approach is that captured vars need to be put on the heap and
  that the calling chain needs to be explicitely modelled. Things to consider:
  
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

const
  upName* = ":up" # field name for the 'up' reference
  paramName* = ":env"
  envName* = ":env"

type
  PInnerContext = ref TInnerContext
  POuterContext = ref TOuterContext

  PEnv = ref TEnv
  TDep = tuple[e: PEnv, field: PSym]
  TEnv {.final.} = object of TObject
    attachedNode: PNode
    createdVar: PSym        # if != nil it is a used environment
    createdVarComesFromIter: bool
    capturedVars: seq[PSym] # captured variables in this environment
    deps: seq[TDep]         # dependencies
    up: PEnv
    tup: PType
  
  TInnerContext {.final.} = object
    fn: PSym
    closureParam: PSym
    localsToAccess: TIdNodeTable
    
  TOuterContext {.final.} = object
    fn: PSym # may also be a module!
    currentEnv: PEnv
    isIter: bool   # first class iterator?
    capturedVars, processed: TIntSet
    localsToEnv: TIdTable # PSym->PEnv mapping
    localsToAccess: TIdNodeTable
    lambdasToEnv: TIdTable # PSym->PEnv mapping
    up: POuterContext

    closureParam, state, resultSym: PSym # only if isIter
    tup: PType # only if isIter


proc getStateType(iter: PSym): PType =
  var n = newNodeI(nkRange, iter.info)
  addSon(n, newIntNode(nkIntLit, -1))
  addSon(n, newIntNode(nkIntLit, 0))
  result = newType(tyRange, iter)
  result.n = n
  rawAddSon(result, getSysType(tyInt))

proc createStateField(iter: PSym): PSym =
  result = newSym(skField, getIdent(":state"), iter, iter.info)
  result.typ = getStateType(iter)

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
  var params = routine.ast.sons[paramsPos]
  # -1 is correct here as param.position is 0 based but we have at position 0
  # some nkEffect node:
  param.position = params.len-1
  addSon(params, newSymNode(param))
  incl(routine.typ.flags, tfCapturesEnv)
  #echo "produced environment: ", param.id, " for ", routine.name.s

proc getHiddenParam(routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  assert hidden.kind == nkSym
  result = hidden.sym

proc getEnvParam(routine: PSym): PSym =
  let params = routine.ast.sons[paramsPos]
  let hidden = lastSon(params)
  if hidden.kind == nkSym and hidden.sym.name.s == paramName:
    result = hidden.sym
    
proc addField(tup: PType, s: PSym) =
  var field = newSym(skField, s.name, s.owner, s.info)
  let t = skipIntLit(s.typ)
  field.typ = t
  field.position = sonsLen(tup)
  addSon(tup.n, newSymNode(field))
  rawAddSon(tup, t)

proc initIterContext(c: POuterContext, iter: PSym) =
  c.fn = iter
  c.capturedVars = initIntSet()

  var cp = getEnvParam(iter)
  if cp == nil:
    c.tup = newType(tyTuple, iter)
    c.tup.n = newNodeI(nkRecList, iter.info)

    cp = newSym(skParam, getIdent(paramName), iter, iter.info)
    incl(cp.flags, sfFromGeneric)
    cp.typ = newType(tyRef, iter)
    rawAddSon(cp.typ, c.tup)
    addHiddenParam(iter, cp)

    c.state = createStateField(iter)
    addField(c.tup, c.state)
  else:
    c.tup = cp.typ.sons[0]
    assert c.tup.kind == tyTuple
    if c.tup.len > 0:
      c.state = c.tup.n[0].sym
    else:
      c.state = createStateField(iter)
      addField(c.tup, c.state)

  c.closureParam = cp
  if iter.typ.sons[0] != nil:
    c.resultSym = newIterResult(iter)
    #iter.ast.add(newSymNode(c.resultSym))

proc newOuterContext(fn: PSym, up: POuterContext = nil): POuterContext =
  new(result)
  result.fn = fn
  result.capturedVars = initIntSet()
  result.processed = initIntSet()
  initIdNodeTable(result.localsToAccess)
  initIdTable(result.localsToEnv)
  initIdTable(result.lambdasToEnv)
  result.isIter = fn.kind == skClosureIterator
  if result.isIter: initIterContext(result, fn)

proc newInnerContext(fn: PSym): PInnerContext =
  new(result)
  result.fn = fn
  initIdNodeTable(result.localsToAccess)

proc newEnv(outerProc: PSym, up: PEnv, n: PNode): PEnv =
  new(result)
  result.deps = @[]
  result.capturedVars = @[]
  result.tup = newType(tyTuple, outerProc)
  result.tup.n = newNodeI(nkRecList, outerProc.info)
  result.up = up
  result.attachedNode = n

proc addCapturedVar(e: PEnv, v: PSym) =
  for x in e.capturedVars:
    if x == v: return
  # XXX meh, just add the state field for every closure for now, it's too
  # hard to figure out if it comes from a closure iterator:
  if e.tup.len == 0: addField(e.tup, createStateField(v.owner))
  e.capturedVars.add(v)
  addField(e.tup, v)
  
proc addDep(e, d: PEnv, owner: PSym): PSym =
  for x, field in items(e.deps):
    if x == d: return field
  var pos = sonsLen(e.tup)
  result = newSym(skField, getIdent(upName & $pos), owner, owner.info)
  result.typ = newType(tyRef, owner)
  result.position = pos
  assert d.tup != nil
  rawAddSon(result.typ, d.tup)
  addField(e.tup, result)
  e.deps.add((d, result))
  
proc indirectAccess(a: PNode, b: PSym, info: TLineInfo): PNode = 
  # returns a[].b as a node
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = a.typ.sons[0]
  assert deref.typ.kind == tyTuple
  let field = getSymFromList(deref.typ.n, b.name)
  assert field != nil, b.name.s
  addSon(deref, a)
  result = newNodeI(nkDotExpr, info)
  addSon(result, deref)
  addSon(result, newSymNode(field))
  result.typ = field.typ

proc indirectAccess(a, b: PSym, info: TLineInfo): PNode =
  result = indirectAccess(newSymNode(a), b, info)

proc newCall(a, b: PSym): PNode =
  result = newNodeI(nkCall, a.info)
  result.add newSymNode(a)
  result.add newSymNode(b)

proc isInnerProc(s, outerProc: PSym): bool {.inline.} =
  result = s.kind in {skProc, skMethod, skConverter, skClosureIterator} and
           s.skipGenericOwner == outerProc
  #s.typ.callConv == ccClosure

proc addClosureParam(i: PInnerContext, e: PEnv) =
  var cp = getEnvParam(i.fn)
  if cp == nil:
    cp = newSym(skParam, getIdent(paramName), i.fn, i.fn.info)
    incl(cp.flags, sfFromGeneric)
    cp.typ = newType(tyRef, i.fn)
    rawAddSon(cp.typ, e.tup)
    addHiddenParam(i.fn, cp)
  else:
    e.tup = cp.typ.sons[0]
    assert e.tup.kind == tyTuple
  i.closureParam = cp
  #echo "closure param added for ", i.fn.name.s, " ", i.fn.id

proc dummyClosureParam(o: POuterContext, i: PInnerContext) =
  var e = o.currentEnv
  if idTableGet(o.lambdasToEnv, i.fn) == nil:
    idTablePut(o.lambdasToEnv, i.fn, e)
  if i.closureParam == nil: addClosureParam(i, e)

proc illegalCapture(s: PSym): bool {.inline.} =
  result = skipTypes(s.typ, abstractInst).kind in 
                   {tyVar, tyOpenArray, tyVarargs} or
      s.kind == skResult

proc captureVar(o: POuterContext, i: PInnerContext, local: PSym, 
                info: TLineInfo) =
  # for inlined variables the owner is still wrong, so it can happen that it's
  # not a captured variable at all ... *sigh* 
  var it = PEnv(idTableGet(o.localsToEnv, local))
  if it == nil: return
  
  if illegalCapture(local) or o.fn.id != local.owner.id or 
      i.fn.typ.callConv notin {ccClosure, ccDefault}:
    # Currently captures are restricted to a single level of nesting:
    localError(info, errIllegalCaptureX, local.name.s)
  i.fn.typ.callConv = ccClosure
  #echo "captureVar ", i.fn.name.s, i.fn.id, " ", local.name.s, local.id

  incl(i.fn.typ.flags, tfCapturesEnv)

  # we need to remember which inner most closure belongs to this lambda:
  var e = o.currentEnv
  if idTableGet(o.lambdasToEnv, i.fn) == nil:
    idTablePut(o.lambdasToEnv, i.fn, e)

  # variable already captured:
  if idNodeTableGet(i.localsToAccess, local) != nil: return
  if i.closureParam == nil: addClosureParam(i, e)
  
  # check which environment `local` belongs to:
  var access = newSymNode(i.closureParam)
  addCapturedVar(it, local)
  if it == e:
    # common case: local directly in current environment:
    discard
  else:
    # it's in some upper environment:
    access = indirectAccess(access, addDep(e, it, i.fn), info)
  access = indirectAccess(access, local, info)
  incl(o.capturedVars, local.id)
  idNodeTablePut(i.localsToAccess, local, access)

proc interestingVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar, skParam, skResult} and
    sfGlobal notin s.flags

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

proc gatherVars(o: POuterContext, i: PInnerContext, n: PNode) = 
  # gather used vars for closure generation
  if n == nil: return
  case n.kind
  of nkSym:
    var s = n.sym
    if interestingVar(s) and i.fn.id != s.owner.id:
      captureVar(o, i, s, n.info)
    elif s.kind in {skProc, skMethod, skConverter} and
            s.skipGenericOwner == o.fn and 
            tfCapturesEnv in s.typ.flags and s != i.fn:
      # call to some other inner proc; we need to track the dependencies for
      # this:
      let env = PEnv(idTableGet(o.lambdasToEnv, i.fn))
      if env == nil: internalError(n.info, "no environment computed")
      if o.currentEnv != env:
        discard addDep(o.currentEnv, env, i.fn)
        internalError(n.info, "too complex environment handling required")
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit, nkClosure: discard
  else:
    for k in countup(0, sonsLen(n) - 1): 
      gatherVars(o, i, n.sons[k])

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

proc makeClosure(prc, env: PSym, info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  if env == nil:
    result.add(newNodeIT(nkNilLit, info, getSysType(tyNil)))
  else:
    result.add(newSymNode(env))

proc transformInnerProc(o: POuterContext, i: PInnerContext, n: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: discard
  of nkSym:
    let s = n.sym
    if s == i.fn: 
      # recursive calls go through (lambda, hiddenParam):
      assert i.closureParam != nil, i.fn.name.s
      result = makeClosure(s, i.closureParam, n.info)
    elif isInnerProc(s, o.fn) and s.typ.callConv == ccClosure:
      # ugh: call to some other inner proc; 
      assert i.closureParam != nil
      # XXX this is not correct in general! may also be some 'closure.upval'
      result = makeClosure(s, i.closureParam, n.info)
    else:
      # captured symbol?
      result = idNodeTableGet(i.localsToAccess, n.sym)
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      result = transformInnerProc(o, i, n.sons[namePos])
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
      nkClosure:
    # don't recurse here:
    discard
  else:
    for j in countup(0, sonsLen(n) - 1):
      let x = transformInnerProc(o, i, n.sons[j])
      if x != nil: n.sons[j] = x

proc closureCreationPoint(n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  result.add(emptyNode)
  result.add(n)

proc searchForInnerProcs(o: POuterContext, n: PNode) =
  if n == nil: return
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    discard
  of nkSym:
    if isInnerProc(n.sym, o.fn) and not containsOrIncl(o.processed, n.sym.id):
      var inner = newInnerContext(n.sym)
      let body = n.sym.getBody
      gatherVars(o, inner, body)
      # dummy closure param needed?
      if inner.closureParam == nil and n.sym.typ.callConv == ccClosure:
        #assert tfCapturesEnv notin n.sym.typ.flags
        dummyClosureParam(o, inner)
      # only transform if it really needs a closure:
      if inner.closureParam != nil:
        let ti = transformInnerProc(o, inner, body)
        if ti != nil: n.sym.ast.sons[bodyPos] = ti
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      searchForInnerProcs(o, n.sons[namePos])
  of nkWhileStmt, nkForStmt, nkParForStmt, nkBlockStmt:
    # some nodes open a new scope, so they are candidates for the insertion
    # of closure creation; however for simplicity we merge closures between
    # branches, in fact, only loop bodies are of interest here as only they 
    # yield observable changes in semantics. For Zahary we also
    # include ``nkBlock``.
    var body = n.len-1
    for i in countup(0, body - 1): searchForInnerProcs(o, n.sons[i])
    # special handling for the loop body:
    let oldEnv = o.currentEnv
    let ex = closureCreationPoint(n.sons[body])
    o.currentEnv = newEnv(o.fn, oldEnv, ex)
    searchForInnerProcs(o, n.sons[body])
    n.sons[body] = ex
    o.currentEnv = oldEnv
  of nkVarSection, nkLetSection:
    # we need to compute a mapping var->declaredBlock. Note: The definition
    # counts, not the block where it is captured!
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkCommentStmt: discard
      elif it.kind == nkIdentDefs:
        var L = sonsLen(it)
        if it.sons[0].kind != nkSym: internalError(it.info, "transformOuter")
        #echo "set: ", it.sons[0].sym.name.s, " ", o.currentBlock == nil
        idTablePut(o.localsToEnv, it.sons[0].sym, o.currentEnv)
        searchForInnerProcs(o, it.sons[L-1])
      elif it.kind == nkVarTuple:
        var L = sonsLen(it)
        for j in countup(0, L-3):
          #echo "set: ", it.sons[j].sym.name.s, " ", o.currentBlock == nil
          idTablePut(o.localsToEnv, it.sons[j].sym, o.currentEnv)
        searchForInnerProcs(o, it.sons[L-1])
      else:
        internalError(it.info, "transformOuter")
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkClosure:
    # don't recurse here:
    # XXX recurse here and setup 'up' pointers
    discard
  else:
    for i in countup(0, sonsLen(n) - 1):
      searchForInnerProcs(o, n.sons[i])

proc newAsgnStmt(le, ri: PNode, info: TLineInfo): PNode = 
  # Bugfix: unfortunately we cannot use 'nkFastAsgn' here as that would
  # mean to be able to capture string literals which have no GC header.
  # However this can only happen if the capture happens through a parameter,
  # which is however the only case when we generate an assignment in the first
  # place.
  result = newNodeI(nkAsgn, info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc addVar*(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info)
  addSon(vpart, v)
  addSon(vpart, ast.emptyNode)
  addSon(vpart, ast.emptyNode)
  addSon(father, vpart)

proc newClosureCreationVar(o: POuterContext; e: PEnv): PSym =
  result = newSym(skVar, getIdent(envName), o.fn, e.attachedNode.info)
  incl(result.flags, sfShadowed)
  result.typ = newType(tyRef, o.fn)
  result.typ.rawAddSon(e.tup)

proc getClosureVar(o: POuterContext; e: PEnv): PSym =
  if e.createdVar == nil:
    result = newClosureCreationVar(o, e)
    e.createdVar = result
  else:
    result = e.createdVar

proc rawClosureCreation(o: POuterContext, scope: PEnv; env: PSym): PNode =
  result = newNodeI(nkStmtList, env.info)
  var v = newNodeI(nkVarSection, env.info)
  addVar(v, newSymNode(env))
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
  # add support for 'up' references:
  for e, field in items(scope.deps):
    # add ``env.up = env2``
    result.add(newAsgnStmt(indirectAccess(env, field, env.info),
               newSymNode(getClosureVar(o, e)), env.info))
  
proc generateClosureCreation(o: POuterContext, scope: PEnv): PNode =
  var env = getClosureVar(o, scope)
  result = rawClosureCreation(o, scope, env)

proc generateIterClosureCreation(o: POuterContext; env: PEnv;
                                 scope: PNode): PSym =
  if env.createdVarComesFromIter or env.createdVar.isNil:
    # we have to create a new closure:
    result = newClosureCreationVar(o, env)
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

proc transformOuterProc(o: POuterContext, n: PNode): PNode

proc transformYield(c: POuterContext, n: PNode): PNode =
  inc c.state.typ.n.sons[1].intVal
  let stateNo = c.state.typ.n.sons[1].intVal

  var stateAsgnStmt = newNodeI(nkAsgn, n.info)
  stateAsgnStmt.add(indirectAccess(newSymNode(c.closureParam),c.state,n.info))
  stateAsgnStmt.add(newIntTypeNode(nkIntLit, stateNo, getSysType(tyInt)))

  var retStmt = newNodeI(nkReturnStmt, n.info)
  if n.sons[0].kind != nkEmpty:
    var a = newNodeI(nkAsgn, n.sons[0].info)
    var retVal = transformOuterProc(c, n.sons[0])
    addSon(a, newSymNode(c.resultSym))
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

proc transformReturn(c: POuterContext, n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  var stateAsgnStmt = newNodeI(nkAsgn, n.info)
  stateAsgnStmt.add(indirectAccess(newSymNode(c.closureParam),c.state,n.info))
  stateAsgnStmt.add(newIntTypeNode(nkIntLit, -1, getSysType(tyInt)))
  result.add(stateAsgnStmt)
  result.add(n)

proc outerProcSons(o: POuterContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1):
    let x = transformOuterProc(o, n.sons[i])
    if x != nil: n.sons[i] = x

proc liftIterSym*(n: PNode): PNode =
  # transforms  (iter)  to  (let env = newClosure[iter](); (iter, env)) 
  let iter = n.sym
  assert iter.kind == skClosureIterator

  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  
  var env = copySym(getHiddenParam(iter))
  env.kind = skLet
  var v = newNodeI(nkVarSection, n.info)
  addVar(v, newSymNode(env))
  result.add(v)
  # add 'new' statement:
  result.add(newCall(getSysSym"internalNew", env))
  result.add makeClosure(iter, env, n.info)

proc transformOuterProc(o: POuterContext, n: PNode): PNode =
  if n == nil: return nil
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: discard
  of nkSym:
    var local = n.sym

    if o.isIter and interestingIterVar(local) and o.fn.id == local.owner.id:
      if not containsOrIncl(o.capturedVars, local.id): addField(o.tup, local)
      return indirectAccess(newSymNode(o.closureParam), local, n.info)

    var closure = PEnv(idTableGet(o.lambdasToEnv, local))

    if local.kind == skClosureIterator:
      # consider: [i1, i2, i1]  Since we merged the iterator's closure
      # with the captured owning variables, we need to generate the
      # closure generation code again:
      if local == o.fn: message(n.info, errRecursiveDependencyX, local.name.s)
      # XXX why doesn't this work?
      if closure.isNil:
        return liftIterSym(n)
      else:
        let createdVar = generateIterClosureCreation(o, closure,
                                                     closure.attachedNode)
        return makeClosure(local, createdVar, n.info)

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
    var env = PEnv(idTableGet(o.localsToEnv, local))
    if env == nil: return
    var scope = env.attachedNode
    assert scope.kind == nkStmtList
    if scope.sons[0].kind == nkEmpty:
      # change the empty node to contain the closure construction:
      scope.sons[0] = generateClosureCreation(o, env)
    
    # change 'local' to 'closure.local', unless it's a 'byCopy' variable:
    # if sfByCopy notin local.flags:
    result = idNodeTableGet(o.localsToAccess, local)
    assert result != nil, "cannot find: " & local.name.s
    # else it is captured by copy and this means that 'outer' should continue
    # to access the local as a local.
  of nkLambdaKinds, nkIteratorDef:
    if n.typ != nil:
      result = transformOuterProc(o, n.sons[namePos])
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
      nkClosure:
    # don't recurse here:
    discard
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    let x = transformOuterProc(o, n.sons[1])
    if x != nil: n.sons[1] = x
    result = transformOuterConv(n)
  of nkYieldStmt:
    if o.isIter: result = transformYield(o, n)
    else: outerProcSons(o, n)
  of nkReturnStmt:
    if o.isIter: result = transformReturn(o, n)
    else: outerProcSons(o, n)
  else:
    outerProcSons(o, n)

proc liftIterator(c: POuterContext, body: PNode): PNode =
  let iter = c.fn
  result = newNodeI(nkStmtList, iter.info)
  var gs = newNodeI(nkGotoState, iter.info)
  gs.add(indirectAccess(newSymNode(c.closureParam), c.state, iter.info))
  result.add(gs)
  var state0 = newNodeI(nkState, iter.info)
  state0.add(newIntNode(nkIntLit, 0))
  result.add(state0)
  
  let newBody = transformOuterProc(c, body)
  if newBody != nil:
    result.add(newBody)
  else:
    result.add(body)

  var stateAsgnStmt = newNodeI(nkAsgn, iter.info)
  stateAsgnStmt.add(indirectAccess(newSymNode(c.closureParam),
                    c.state,iter.info))
  stateAsgnStmt.add(newIntTypeNode(nkIntLit, -1, getSysType(tyInt)))
  result.add(stateAsgnStmt)

proc liftLambdas*(fn: PSym, body: PNode): PNode =
  # XXX gCmd == cmdCompileToJS does not suffice! The compiletime stuff needs
  # the transformation even when compiling to JS ...
  if body.kind == nkEmpty or gCmd == cmdCompileToJS:
    # ignore forward declaration:
    result = body
  else:
    var o = newOuterContext(fn)
    let ex = closureCreationPoint(body)
    o.currentEnv = newEnv(fn, nil, ex)
    # put all params into the environment so they can be captured:
    let params = fn.typ.n
    for i in 1.. <params.len: 
      if params.sons[i].kind != nkSym:
        internalError(params.info, "liftLambdas: strange params")
      let param = params.sons[i].sym
      idTablePut(o.localsToEnv, param, o.currentEnv)
    # put the 'result' into the environment so it can be captured:
    let ast = fn.ast
    if resultPos < sonsLen(ast) and ast.sons[resultPos].kind == nkSym:
      idTablePut(o.localsToEnv, ast.sons[resultPos].sym, o.currentEnv)
    searchForInnerProcs(o, body)
    if o.isIter:
      result = liftIterator(o, ex)
    else:
      discard transformOuterProc(o, body)
      result = ex

proc liftLambdasForTopLevel*(module: PSym, body: PNode): PNode =
  if body.kind == nkEmpty or gCmd == cmdCompileToJS:
    result = body
  else:
    var o = newOuterContext(module)
    let ex = closureCreationPoint(body)
    o.currentEnv = newEnv(module, nil, ex)
    searchForInnerProcs(o, body)
    discard transformOuterProc(o, body)
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
  # --> When to create the closure? --> for the (count) occurence!
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
  internalAssert body.kind == nkForStmt and body[L-2].kind in nkCallKinds
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
    result.add(newCall(getSysSym"internalNew", env))
  
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
    call.sons[0] = makeClosure(call.sons[0].sym, env, body.info)
  addSon(vpart, call)
  addSon(v2, vpart)

  loopBody.sons[0] = v2
  var bs = newNodeI(nkBreakState, body.info)
  #if not env.isNil:
  #  bs.addSon(indirectAccess(env, 
  #    newSym(skField, getIdent":state", env, env.info), body.info))
  #else:
  bs.addSon(call.sons[0])
  loopBody.sons[1] = bs
  loopBody.sons[2] = body[L-1]
