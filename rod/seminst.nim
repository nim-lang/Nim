#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module does the instantiation of generic procs and types.

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable,
                      info: TLineInfo): PSym
  # generates an instantiated proc
proc searchInstTypes(tab: TIdTable, key: PType): PType = 
  # returns nil if we need to declare this type
  result = PType(IdTableGet(tab, key))
  if (result == nil) and (tab.counter > 0): 
    # we have to do a slow linear search because types may need
    # to be compared by their structure:
    for h in countup(0, high(tab.data)): 
      var t = PType(tab.data[h].key)
      if t != nil: 
        if key.containerId == t.containerID: 
          var match = true
          for j in countup(0, sonsLen(t) - 1): 
            # XXX sameType is not really correct for nested generics?
            if not sameType(t.sons[j], key.sons[j]): 
              match = false
              break 
          if match: 
            return PType(tab.data[h].val)

proc containsGenericTypeIter(t: PType, closure: PObject): bool = 
  result = t.kind in GenericTypes

proc containsGenericType(t: PType): bool = 
  result = iterOverType(t, containsGenericTypeIter, nil)

proc instantiateGenericParamList(c: PContext, n: PNode, pt: TIdTable) = 
  if (n.kind != nkGenericParams): 
    InternalError(n.info, "instantiateGenericParamList; no generic params")
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind != nkSym: 
      InternalError(a.info, "instantiateGenericParamList; no symbol")
    var q = a.sym
    if not (q.typ.kind in {tyTypeDesc, tyGenericParam}): continue 
    var s = newSym(skType, q.name, getCurrOwner())
    var t = PType(IdTableGet(pt, q.typ))
    if t == nil: 
      LocalError(a.info, errCannotInstantiateX, s.name.s)
      break
    if (t.kind == tyGenericParam): 
      InternalError(a.info, "instantiateGenericParamList: " & q.name.s)
    s.typ = t
    addDecl(c, s)

proc GenericCacheGet(c: PContext, genericSym, instSym: PSym): PSym = 
  result = nil
  for i in countup(0, sonsLen(c.generics) - 1): 
    if c.generics.sons[i].kind != nkExprEqExpr: 
      InternalError(genericSym.info, "GenericCacheGet")
    var a = c.generics.sons[i].sons[0].sym
    if genericSym.id == a.id: 
      var b = c.generics.sons[i].sons[1].sym
      if equalParams(b.typ.n, instSym.typ.n) == paramsEqual: 
        #if gVerbosity > 0 then 
        #  MessageOut('found in cache: ' + getProcHeader(instSym));
        return b

proc GenericCacheAdd(c: PContext, genericSym, instSym: PSym) = 
  var n = newNode(nkExprEqExpr)
  addSon(n, newSymNode(genericSym))
  addSon(n, newSymNode(instSym))
  addSon(c.generics, n)

proc generateInstance(c: PContext, fn: PSym, pt: TIdTable, 
                      info: TLineInfo): PSym = 
  # generates an instantiated proc
  var 
    oldPrc, oldMod: PSym
    oldP: PProcCon
    n: PNode
  if c.InstCounter > 1000: InternalError(fn.ast.info, "nesting too deep")
  inc(c.InstCounter)
  oldP = c.p # restore later
  # NOTE: for access of private fields within generics from a different module
  # and other identifiers we fake the current module temporarily!
  oldMod = c.module
  c.module = getModule(fn)
  result = copySym(fn, false)
  incl(result.flags, sfFromGeneric)
  result.owner = getCurrOwner().owner
  n = copyTree(fn.ast)
  result.ast = n
  pushOwner(result)
  openScope(c.tab)
  if (n.sons[genericParamsPos].kind == nkEmpty): 
    InternalError(n.info, "generateInstance")
  n.sons[namePos] = newSymNode(result)
  pushInfoContext(info)
  instantiateGenericParamList(c, n.sons[genericParamsPos], pt)
  n.sons[genericParamsPos] = ast.emptyNode
  # semantic checking for the parameters:
  if n.sons[paramsPos].kind != nkEmpty: 
    semParamList(c, n.sons[ParamsPos], nil, result)
    addParams(c, result.typ.n)
  else: 
    result.typ = newTypeS(tyProc, c)
    addSon(result.typ, nil)
  result.typ.callConv = fn.typ.callConv
  oldPrc = GenericCacheGet(c, fn, result)
  if oldPrc == nil: 
    # add it here, so that recursive generic procs are possible:
    GenericCacheAdd(c, fn, result)
    addDecl(c, result)
    if n.sons[codePos].kind != nkEmpty: 
      c.p = newProcCon(result)
      if result.kind in {skProc, skMethod, skConverter}: 
        addResult(c, result.typ.sons[0], n.info)
        addResultNode(c, n)
      n.sons[codePos] = semStmtScope(c, n.sons[codePos])
  else: 
    result = oldPrc
  popInfoContext()
  closeScope(c.tab)           # close scope for parameters
  popOwner()
  c.p = oldP                  # restore
  c.module = oldMod
  dec(c.InstCounter)

proc checkConstructedType(info: TLineInfo, t: PType) = 
  if (tfAcyclic in t.flags) and (skipTypes(t, abstractInst).kind != tyObject): 
    LocalError(info, errInvalidPragmaX, "acyclic")
  elif computeSize(t) < 0: 
    LocalError(info, errIllegalRecursionInTypeX, typeToString(t))
  elif (t.kind == tyVar) and (t.sons[0].kind == tyVar): 
    LocalError(info, errVarVarTypeNotAllowed)
  
type 
  TReplTypeVars{.final.} = object 
    c*: PContext
    typeMap*: TIdTable        # map PType to PType
    symMap*: TIdTable         # map PSym to PSym
    info*: TLineInfo


proc ReplaceTypeVarsT(cl: var TReplTypeVars, t: PType): PType
proc ReplaceTypeVarsS(cl: var TReplTypeVars, s: PSym): PSym
proc ReplaceTypeVarsN(cl: var TReplTypeVars, n: PNode): PNode = 
  if n != nil: 
    result = copyNode(n)
    result.typ = ReplaceTypeVarsT(cl, n.typ)
    case n.kind
    of nkNone..pred(nkSym), succ(nkSym)..nkNilLit: 
      nil
    of nkSym: 
      result.sym = ReplaceTypeVarsS(cl, n.sym)
    else: 
      var length = sonsLen(n)
      if length > 0: 
        newSons(result, length)
        for i in countup(0, length - 1): 
          result.sons[i] = ReplaceTypeVarsN(cl, n.sons[i])
  
proc ReplaceTypeVarsS(cl: var TReplTypeVars, s: PSym): PSym = 
  if s == nil: return nil
  result = PSym(idTableGet(cl.symMap, s))
  if result == nil: 
    result = copySym(s, false)
    incl(result.flags, sfFromGeneric)
    idTablePut(cl.symMap, s, result)
    result.typ = ReplaceTypeVarsT(cl, s.typ)
    result.owner = s.owner
    result.ast = ReplaceTypeVarsN(cl, s.ast)

proc lookupTypeVar(cl: TReplTypeVars, t: PType): PType = 
  result = PType(idTableGet(cl.typeMap, t))
  if result == nil: 
    GlobalError(t.sym.info, errCannotInstantiateX, typeToString(t))
  elif result.kind == tyGenericParam: 
    InternalError(cl.info, "substitution with generic parameter")
  
proc ReplaceTypeVarsT(cl: var TReplTypeVars, t: PType): PType = 
  var body, newbody, x, header: PType
  result = t
  if t == nil: return 
  case t.kind
  of tyGenericParam: 
    result = lookupTypeVar(cl, t)
  of tyGenericInvokation: 
    body = t.sons[0]
    if body.kind != tyGenericBody: InternalError(cl.info, "no generic body")
    header = nil
    for i in countup(1, sonsLen(t) - 1): 
      if t.sons[i].kind == tyGenericParam: 
        x = lookupTypeVar(cl, t.sons[i])
        if header == nil: header = copyType(t, t.owner, false)
        header.sons[i] = x
      else: 
        x = t.sons[i]
      idTablePut(cl.typeMap, body.sons[i - 1], x)
    if header == nil: header = t
    result = searchInstTypes(gInstTypes, header)
    if result != nil: return 
    result = newType(tyGenericInst, t.sons[0].owner)
    for i in countup(0, sonsLen(t) - 1): 
      # if one of the params is not concrete, we cannot do anything
      # but we already raised an error!
      addSon(result, header.sons[i])
    idTablePut(gInstTypes, header, result)
    newbody = ReplaceTypeVarsT(cl, lastSon(body))
    newbody.n = ReplaceTypeVarsN(cl, lastSon(body).n)
    addSon(result, newbody)   
    #writeln(output, ropeToStr(Typetoyaml(newbody)));
    checkConstructedType(cl.info, newbody)
  of tyGenericBody: 
    InternalError(cl.info, "ReplaceTypeVarsT: tyGenericBody")
    result = ReplaceTypeVarsT(cl, lastSon(t))
  else: 
    if containsGenericType(t): 
      result = copyType(t, t.owner, false)
      for i in countup(0, sonsLen(result) - 1): 
        result.sons[i] = ReplaceTypeVarsT(cl, result.sons[i])
      result.n = ReplaceTypeVarsN(cl, result.n)
      if result.Kind in GenericTypes: 
        LocalError(cl.info, errCannotInstantiateX, TypeToString(t, preferName))
        #writeln(output, ropeToStr(Typetoyaml(result)))
        #checkConstructedType(cl.info, result)
  
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType = 
  var cl: TReplTypeVars
  InitIdTable(cl.symMap)
  InitIdTable(cl.typeMap)
  cl.info = n.info
  cl.c = c
  result = ReplaceTypeVarsT(cl, header)

proc generateTypeInstance(p: PContext, pt: TIdTable, arg: PNode, 
                          t: PType): PType = 
  var cl: TReplTypeVars
  InitIdTable(cl.symMap)
  copyIdTable(cl.typeMap, pt)
  cl.info = arg.info
  cl.c = p
  pushInfoContext(arg.info)
  result = ReplaceTypeVarsT(cl, t)
  popInfoContext()

