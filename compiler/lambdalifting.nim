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
        bcl2.x = x
      
        proc c(cl) = capture cl.up.up.v, cl.up.w, cl.x
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
  envName* = ":env"

type
  TLLShared {.final.} = object
    upField: PSym
  
  PInnerContext = ref TInnerContext
  POuterContext = ref TOuterContext
  PLLShared = ref TLLShared
  PBlock = ref TBlock
  
  TBlock {.final.} = object
    body: PNode
    closure: PSym
    used: bool
  
  TInnerContext {.final.} = object
    fn: PSym
    closureParam: PSym
    localsToAccess: TIdNodeTable
    up: POuterContext         # used for chaining
    levelsUp: int             # counts how many "up levels" are accessed
    tup: PType
    
  TOuterContext {.final.} = object
    fn: PSym
    currentBlock: PNode
    capturedVars: TIntSet
    localsToEnclosingScope: TIdNodeTable
    localsToAccess: TIdNodeTable
    lambdasToEnclosingScope: TIdNodeTable
  
    shared: PLLShared
    up: POuterContext

proc newOuterContext(fn: PSym, shared: PLLShared, 
                     up: POuterContext = nil): POuterContext =
  new(result)
  result.fn = fn
  result.shared = shared
  result.capturedVars = initIntSet()
  initIdNodeTable(result.localsToAccess)
  initIdNodeTable(result.localsToEnclosingScope)
  initIdNodeTable(result.lambdasToEnclosingScope)
  
proc newInnerContext(fn: PSym, outer: POuterContext): PInnerContext =
  new(result)
  result.up = outer
  result.fn = fn
  initIdNodeTable(result.localsToAccess)
  
proc indirectAccess(a: PNode, b: PSym, info: TLineInfo): PNode = 
  # returns a[].b as a node
  let x = a
  var deref = newNodeI(nkHiddenDeref, info)
  deref.typ = x.typ.sons[0]
  
  let field = getSymFromList(deref.typ.n, b.name)
  if field == nil:
    echo b.name.s
    assert false
  addSon(deref, x)
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

proc addField(tup: PType, s: PSym) =
  var field = newSym(skField, s.name, s.owner)
  field.typ = s.typ
  field.position = sonsLen(tup)
  addSon(tup.n, newSymNode(field))
  addSon(tup, s.typ)

proc addHiddenParam(routine: PSym, param: PSym) =
  var params = routine.ast.sons[paramsPos]
  param.position = params.len
  addSon(params, newSymNode(param))
  #echo "produced environment: ", param.id, " for ", routine.name.s

proc isInnerProc(s, outerProc: PSym): bool {.inline.} =
  result = s.kind in {skProc, skIterator, skMethod, skConverter} and
    s.owner == outerProc and not isGenericRoutine(s)
  #s.typ.callConv == ccClosure

proc captureVar(o: POuterContext, i: PInnerContext, local: PSym,
                info: TLineInfo) =
  discard """
    Consider:
      var x = 0
      var y = 2
      capture x, y
      
      block:
        var z = 3
        capture z
      
    We need to merge x, y into a closure, but not z! 
  """
  # we need to remember which outer closure belongs to this lambda; we also
  # use this check to prevent multiple runs over the same inner proc:
  if IdNodeTableGet(o.lambdasToEnclosingScope, i.fn) != nil: return
  IdNodeTablePut(o.lambdasToEnclosingScope, i.fn, o.currentBlock)

  if IdNodeTableGet(i.localsToAccess, local) != nil: return
  if i.closureParam == nil:
    var cp = newSym(skParam, getIdent(upname), i.fn)
    cp.info = i.fn.info
    incl(cp.flags, sfFromGeneric)
    i.tup = newType(tyTuple, i.fn)
    i.tup.n = newNodeI(nkRecList, i.fn.info)
    cp.typ = newType(tyRef, i.fn)
    addSon(cp.typ, i.tup)
    i.closureParam = cp
    addHiddenParam(i.fn, i.closureParam)
  addField(i.tup, local)
  var it = i.up
  var access = newSymNode(i.closureParam)
  var levelsUp = 0
  while it.fn.id != local.owner.id:
    assert false
    access = indirectAccess(access, o.shared.upField, info)
    it = it.up
    assert it != nil
    inc levelsUp
  i.levelsUp = max(i.levelsUp, levelsUp)
  access = indirectAccess(access, local, info)
  IdNodeTablePut(i.localsToAccess, local, access)
  incl(o.capturedVars, local.id)

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
      #echo "captured: ", s.name.s
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
    if n.sym == i.fn: 
      # recursive calls go through (lambda, hiddenParam):
      assert i.closureParam != nil
      result = makeClosure(n.sym, i.closureParam, n.info)
    else:
      # captured symbol?
      result = IdNodeTableGet(i.localsToAccess, n.sym)
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
     nkIteratorDef, nkLambdaKinds:
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
    if isInnerProc(n.sym, o.fn):
      var inner = newInnerContext(n.sym, o)
      let body = n.sym.getBody
      gatherVars(o, inner, body)
      let ti = transformInnerProc(o, inner, body)
      if ti != nil: n.sym.ast.sons[bodyPos] = ti
  of nkWhileStmt, nkForStmt, nkParForStmt, nkBlockStmt:
    # some nodes open a new scope, so they are candidates for the insertion
    # of closure creation; however for simplicity we merge closures between
    # branches, in fact, only loops bodies are of interest here as only they 
    # yield observable changes in semantics. For Zahary we also
    # include ``nkBlock``.
    var body = n.len-1
    for i in countup(0, body - 1): searchForInnerProcs(o, n.sons[i])
    # special handling for the loop body:
    let oldBlock = o.currentBlock
    let ex = closureCreationPoint(n.sons[body])
    o.currentBlock = ex
    searchForInnerProcs(o, n.sons[body])
    n.sons[body] = ex
    o.currentBlock = oldBlock
  of nkVarSection, nkLetSection:
    # we need to compute a mapping var->declaredBlock. Note: The definition
    # counts, not the block where it is captured!
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkCommentStmt: nil
      elif it.kind == nkIdentDefs:
        if it.sons[0].kind != nkSym: InternalError(it.info, "transformOuter")
        #echo "set: ", it.sons[0].sym.name.s, " ", o.currentBlock == nil
        IdNodeTablePut(o.localsToEnclosingScope, it.sons[0].sym, o.currentBlock)
      elif it.kind == nkVarTuple:
        var L = sonsLen(it)
        for j in countup(0, L-3):
          #echo "set: ", it.sons[j].sym.name.s, " ", o.currentBlock == nil
          IdNodeTablePut(o.localsToEnclosingScope, it.sons[j].sym, 
                         o.currentBlock)
      else:
        InternalError(it.info, "transformOuter")
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef, nkLambdaKinds: 
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

proc generateClosureCreation(o: POuterContext, scope: PNode): PNode =
  # add assignment if it's a parameter that has been captured:
  var env = newSym(skVar, getIdent(envName), o.fn)
  incl(env.flags, sfShadowed)
  env.info = scope.info
  env.typ = newType(tyRef, o.fn)
  var tup = newType(tyTuple, o.fn)
  tup.n = newNodeI(nkRecList, scope.info)
  env.typ.addSon(tup)

  result = newNodeI(nkStmtList, env.info)
  var v = newNodeI(nkVarSection, env.info)
  addVar(v, newSymNode(env))
  result.add(v)
  # add 'new' statement:
  result.add(newCall(getSysSym"internalNew", env))
  
  # add assignment statements:
  for v, scope2 in pairs(o.localsToEnclosingScope):
    if scope2 == scope:
      let local = PSym(v)
      addField(tup, local)
      let fieldAccess = indirectAccess(env, local, env.info)
      if sfByCopy in local.flags or local.kind == skParam:
        # add ``env.param = param``
        result.add(newAsgnStmt(fieldAccess, newSymNode(local)))
      IdNodeTablePut(o.localsToAccess, local, fieldAccess)
  # XXX add support for 'up' references!

proc transformOuterProc(o: POuterContext, n: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkSym), succ(nkSym)..nkNilLit: nil
  of nkSym:
    var local = n.sym
    var envBlock = IdNodeTableGet(o.lambdasToEnclosingScope, local)
    if envBlock != nil:
      # we need to replace the lambda with '(lambda, env)': 
      let a = envBlock.sons[0]
      assert a.kind == nkStmtList
      assert a.sons[0].kind == nkVarSection
      assert a.sons[0].sons[0].kind == nkIdentDefs
      var env = a.sons[0].sons[0].sons[0].sym
      return makeClosure(local, env, n.info)
  
    if not o.capturedVars.contains(local.id): return
    var scope = IdNodeTableGet(o.localsToEnclosingScope, local)
    if scope == nil: return
    
    assert scope.kind == nkStmtList
    if scope.sons[0].kind == nkEmpty:
      # change the empty node to contain the closure construction; we need to
      # gather all variables here that belong to the closure which is a bit
      # expensive:
      scope.sons[0] = generateClosureCreation(o, scope)
    
    # change 'local' to 'closure.local', unless it's a 'byCopy' variable:
    if sfByCopy notin local.flags:
      result = IdNodeTableGet(o.localsToAccess, local)
      assert result != nil, "cannot find: " & local.name.s
    # else it is captured by copy and this means that 'outer' should continue
    # to access the local as a local.
  of nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, 
     nkIteratorDef, nkLambdaKinds: 
    # don't recurse here:
    nil
  else:
    for i in countup(0, sonsLen(n) - 1):
      let x = transformOuterProc(o, n.sons[i])
      if x != nil: n.sons[i] = x

proc liftLambdas(fn: PSym, shared: PLLShared, body: PNode): PNode =
  if body.kind == nkEmpty:
    # ignore forward declaration:
    result = body
  elif not containsNode(body, procDefs) and fn.typ.callConv != ccClosure:
    # fast path: no inner procs, so no closure needed:
    result = body
  else:
    var o = newOuterContext(fn, shared)
    let ex = closureCreationPoint(body)
    o.currentBlock = ex
    searchForInnerProcs(o, body)
    let a = transformOuterProc(o, body)
    result = ex
    #echo renderTree(result)
  
# XXX should 's' be replaced by a tuple ('s', env)?

proc liftLambdas*(n: PNode): PNode =
  assert n.kind in procDefs
  var s = n.sons[namePos].sym
  var shared: ref TLLShared
  new shared
  shared.upField = newSym(skField, upName.getIdent, s)
  result = liftLambdas(s, shared, s.getBody)
