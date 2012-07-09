#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file implements lambda lifting for the transformator.
# included from transf.nim

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
  declarativeDefs* = {nkProcDef, nkMethodDef, nkIteratorDef, nkConverterDef}
  procDefs* = nkLambdaKinds + declarativeDefs
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
    closure: PSym   # if != nil it is a used environment
    capturedVars: seq[PSym] # captured variables in this environment
    deps: seq[TDep] # dependencies
    up: PEnv
    tup: PType
  
  TInnerContext {.final.} = object
    fn: PSym
    closureParam: PSym
    localsToAccess: TIdNodeTable
    
  TOuterContext {.final.} = object
    fn: PSym
    currentEnv: PEnv
    capturedVars, processed: TIntSet
    localsToEnv: TIdTable # PSym->PEnv mapping
    localsToAccess: TIdNodeTable
    lambdasToEnv: TIdTable # PSym->PEnv mapping
    up: POuterContext

proc newOuterContext(fn: PSym, up: POuterContext = nil): POuterContext =
  new(result)
  result.fn = fn
  result.capturedVars = initIntSet()
  result.processed = initIntSet()
  initIdNodeTable(result.localsToAccess)
  initIdTable(result.localsToEnv)
  initIdTable(result.lambdasToEnv)
  
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

proc addField(tup: PType, s: PSym) =
  var field = newSym(skField, s.name, s.owner)
  let t = skipIntLit(s.typ)
  field.typ = t
  field.position = sonsLen(tup)
  addSon(tup.n, newSymNode(field))
  rawAddSon(tup, t)
  
proc addCapturedVar(e: PEnv, v: PSym) =
  for x in e.capturedVars:
    if x == v: return
  e.capturedVars.add(v)
  addField(e.tup, v)
  
proc addDep(e, d: PEnv, owner: PSym): PSym =
  for x, field in items(e.deps):
    if x == d: return field
  var pos = sonsLen(e.tup)
  result = newSym(skField, getIdent(upName & $pos), owner)
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

proc addHiddenParam(routine: PSym, param: PSym) =
  var params = routine.ast.sons[paramsPos]
  param.position = params.len
  addSon(params, newSymNode(param))
  #echo "produced environment: ", param.id, " for ", routine.name.s

proc isInnerProc(s, outerProc: PSym): bool {.inline.} =
  result = s.kind in {skProc, skIterator, skMethod, skConverter} and
    s.owner == outerProc and not isGenericRoutine(s)
  #s.typ.callConv == ccClosure

proc addClosureParam(i: PInnerContext, e: PEnv) =
  var cp = newSym(skParam, getIdent(paramname), i.fn)
  cp.info = i.fn.info
  incl(cp.flags, sfFromGeneric)
  cp.typ = newType(tyRef, i.fn)
  rawAddSon(cp.typ, e.tup)
  i.closureParam = cp
  addHiddenParam(i.fn, i.closureParam)
  #echo "closure param added for ", i.fn.name.s, " ", i.fn.id

proc dummyClosureParam(o: POuterContext, i: PInnerContext) =
  var e = o.currentEnv
  if IdTableGet(o.lambdasToEnv, i.fn) == nil:
    IdTablePut(o.lambdasToEnv, i.fn, e)
  if i.closureParam == nil: addClosureParam(i, e)

proc captureVar(o: POuterContext, i: PInnerContext, local: PSym, 
                info: TLineInfo) =
  # for inlined variables the owner is still wrong, so it can happen that it's
  # not a captured variable at all ... *sigh* 
  var it = PEnv(IdTableGet(o.localsToEnv, local))
  if it == nil: return

  # we need to remember which inner most closure belongs to this lambda:
  var e = o.currentEnv
  if IdTableGet(o.lambdasToEnv, i.fn) == nil:
    IdTablePut(o.lambdasToEnv, i.fn, e)

  # variable already captured:
  if IdNodeTableGet(i.localsToAccess, local) != nil: return
  if i.closureParam == nil: addClosureParam(i, e)
  
  # check which environment `local` belongs to:
  var access = newSymNode(i.closureParam)
  addCapturedVar(it, local)
  if it == e:
    # common case: local directly in current environment:
    nil
  else:
    # it's in some upper environment:
    access = indirectAccess(access, addDep(e, it, i.fn), info)
  access = indirectAccess(access, local, info)
  incl(o.capturedVars, local.id)
  IdNodeTablePut(i.localsToAccess, local, access)

proc interestingVar(s: PSym): bool {.inline.} =
  result = s.kind in {skVar, skLet, skTemp, skForVar, skParam, skResult} and
    sfGlobal notin s.flags

proc gatherVars(o: POuterContext, i: PInnerContext, n: PNode) = 
  # gather used vars for closure generation
  case n.kind
  of nkSym:
    var s = n.sym
    if interestingVar(s) and i.fn.id != s.owner.id:
      captureVar(o, i, s, n.info)
    elif isInnerProc(s, o.fn) and s.typ.callConv == ccClosure and s != i.fn:
      # call to some other inner proc; we need to track the dependencies for
      # this:
      let env = PEnv(IdTableGet(o.lambdasToEnv, i.fn))
      if env == nil: InternalError(n.info, "no environment computed")
      if o.currentEnv != env:
        discard addDep(o.currentEnv, env, i.fn)
        InternalError(n.info, "too complex enviroment handling required")
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  else:
    for k in countup(0, sonsLen(n) - 1): 
      gatherVars(o, i, n.sons[k])

proc makeClosure(prc, env: PSym, info: TLineInfo): PNode =
  result = newNodeIT(nkClosure, info, prc.typ)
  result.add(newSymNode(prc))
  if env == nil:
    result.add(newNodeIT(nkNilLit, info, getSysType(tyNil)))
  else:
    result.add(newSymNode(env))

proc transformInnerProc(o: POuterContext, i: PInnerContext, n: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
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
      result = IdNodeTableGet(i.localsToAccess, n.sym)
  of nkLambdaKinds:
    result = transformInnerProc(o, i, n.sons[namePos])
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
     nkIteratorDef:
    # don't recurse here:
    nil
  else:
    for j in countup(0, sonsLen(n) - 1):
      let x = transformInnerProc(o, i, n.sons[j])
      if x != nil: n.sons[j] = x

proc closureCreationPoint(n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  result.add(emptyNode)
  result.add(n)

proc searchForInnerProcs(o: POuterContext, n: PNode) =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: 
    nil
  of nkSym:
    if isInnerProc(n.sym, o.fn) and not containsOrIncl(o.processed, n.sym.id):
      var inner = newInnerContext(n.sym)
      let body = n.sym.getBody
      gatherVars(o, inner, body)
      # dummy closure param needed?
      if inner.closureParam == nil and n.sym.typ.callConv == ccClosure:
        dummyClosureParam(o, inner)
      # only transform if it really needs a closure:
      if inner.closureParam != nil:
        let ti = transformInnerProc(o, inner, body)
        if ti != nil: n.sym.ast.sons[bodyPos] = ti
  of nkLambdaKinds:
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
      if it.kind == nkCommentStmt: nil
      elif it.kind == nkIdentDefs:
        var L = sonsLen(it)
        if it.sons[0].kind != nkSym: InternalError(it.info, "transformOuter")
        #echo "set: ", it.sons[0].sym.name.s, " ", o.currentBlock == nil
        IdTablePut(o.localsToEnv, it.sons[0].sym, o.currentEnv)
        searchForInnerProcs(o, it.sons[L-1])
      elif it.kind == nkVarTuple:
        var L = sonsLen(it)
        for j in countup(0, L-3):
          #echo "set: ", it.sons[j].sym.name.s, " ", o.currentBlock == nil
          IdTablePut(o.localsToEnv, it.sons[j].sym, o.currentEnv)
        searchForInnerProcs(o, it.sons[L-1])
      else:
        InternalError(it.info, "transformOuter")
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef:
    # don't recurse here:
    # XXX recurse here and setup 'up' pointers
    nil
  else:
    for i in countup(0, sonsLen(n) - 1):
      searchForInnerProcs(o, n.sons[i])

proc newAsgnStmt(le, ri: PNode): PNode = 
  result = newNodeI(nkFastAsgn, ri.info)
  result.add(le)
  result.add(ri)

proc addVar*(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info)
  addSon(vpart, v)
  addSon(vpart, ast.emptyNode)
  addSon(vpart, ast.emptyNode)
  addSon(father, vpart)

proc getClosureVar(o: POuterContext, e: PEnv): PSym =
  if e.closure == nil:
    result = newSym(skVar, getIdent(envName), o.fn)
    incl(result.flags, sfShadowed)
    result.info = e.attachedNode.info
    result.typ = newType(tyRef, o.fn)
    result.typ.rawAddSon(e.tup)
    e.closure = result
  else:
    result = e.closure

proc generateClosureCreation(o: POuterContext, scope: PEnv): PNode =
  var env = getClosureVar(o, scope)

  result = newNodeI(nkStmtList, env.info)
  var v = newNodeI(nkVarSection, env.info)
  addVar(v, newSymNode(env))
  result.add(v)
  # add 'new' statement:
  result.add(newCall(getSysSym"internalNew", env))
  
  # add assignment statements:
  for local in scope.capturedVars:
    let fieldAccess = indirectAccess(env, local, env.info)
    if sfByCopy in local.flags or local.kind == skParam:
      # add ``env.param = param``
      result.add(newAsgnStmt(fieldAccess, newSymNode(local)))
    IdNodeTablePut(o.localsToAccess, local, fieldAccess)
  # add support for 'up' references:
  for e, field in items(scope.deps):
    # add ``env.up = env2``
    result.add(newAsgnStmt(indirectAccess(env, field, env.info),
               newSymNode(getClosureVar(o, e))))

proc transformOuterProc(o: POuterContext, n: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  of nkSym:
    var local = n.sym
    var closure = PEnv(IdTableGet(o.lambdasToEnv, local))
    if closure != nil:
      # we need to replace the lambda with '(lambda, env)': 
      let a = closure.closure
      if a != nil:
        return makeClosure(local, a, n.info)
      else:
        # can happen for dummy closures:
        var scope = closure.attachedNode
        assert scope.kind == nkStmtList
        if scope.sons[0].kind == nkEmpty:
          # change the empty node to contain the closure construction:
          scope.sons[0] = generateClosureCreation(o, closure)
        let x = closure.closure
        assert x != nil
        return makeClosure(local, x, n.info)
    
    if not contains(o.capturedVars, local.id): return
    var env = PEnv(IdTableGet(o.localsToEnv, local))
    if env == nil: return
    var scope = env.attachedNode
    assert scope.kind == nkStmtList
    if scope.sons[0].kind == nkEmpty:
      # change the empty node to contain the closure construction:
      scope.sons[0] = generateClosureCreation(o, env)
    
    # change 'local' to 'closure.local', unless it's a 'byCopy' variable:
    if sfByCopy notin local.flags:
      result = IdNodeTableGet(o.localsToAccess, local)
      assert result != nil, "cannot find: " & local.name.s
    # else it is captured by copy and this means that 'outer' should continue
    # to access the local as a local.
  of nkLambdaKinds:
    result = transformOuterProc(o, n.sons[namePos])
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef: 
    # don't recurse here:
    nil
  else:
    for i in countup(0, sonsLen(n) - 1):
      let x = transformOuterProc(o, n.sons[i])
      if x != nil: n.sons[i] = x

proc liftLambdas(fn: PSym, body: PNode): PNode =
  if body.kind == nkEmpty:
    # ignore forward declaration:
    result = body
  elif not containsNode(body, procDefs) and fn.typ.callConv != ccClosure:
    # fast path: no inner procs, so no closure needed:
    result = body
  else:
    var o = newOuterContext(fn)
    let ex = closureCreationPoint(body)
    o.currentEnv = newEnv(fn, nil, ex)
    # put all params into the environment so they can be captured:
    let params = fn.typ.n
    for i in 1.. <params.len: 
      if params.sons[i].kind != nkSym:
        InternalError(params.info, "liftLambdas: strange params")
      let param = params.sons[i].sym
      IdTablePut(o.localsToEnv, param, o.currentEnv)
    searchForInnerProcs(o, body)
    let a = transformOuterProc(o, body)
    result = ex
  
# XXX should 's' be replaced by a tuple ('s', env)?

proc liftLambdas*(n: PNode): PNode =
  assert n.kind in procDefs
  var s = n.sons[namePos].sym
  if gCmd == cmdCompileToEcmaScript: return s.getBody
  result = liftLambdas(s, s.getBody)
