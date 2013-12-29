#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module does the instantiation of generic types.

import ast, astalgo, msgs, types, magicsys, semdata, renderer

proc checkPartialConstructedType(info: TLineInfo, t: PType) =
  if tfAcyclic in t.flags and skipTypes(t, abstractInst).kind != tyObject:
    localError(info, errInvalidPragmaX, "acyclic")
  elif t.kind == tyVar and t.sons[0].kind == tyVar:
    localError(info, errVarVarTypeNotAllowed)

proc checkConstructedType*(info: TLineInfo, typ: PType) =
  var t = typ.skipTypes({tyDistinct})
  if t.kind in tyTypeClasses: nil
  elif tfAcyclic in t.flags and skipTypes(t, abstractInst).kind != tyObject: 
    localError(info, errInvalidPragmaX, "acyclic")
  elif t.kind == tyVar and t.sons[0].kind == tyVar: 
    localError(info, errVarVarTypeNotAllowed)
  elif computeSize(t) == szIllegalRecursion:
    localError(info, errIllegalRecursionInTypeX, typeToString(t))
  when false:
    if t.kind == tyObject and t.sons[0] != nil:
      if t.sons[0].kind != tyObject or tfFinal in t.sons[0].flags: 
        localError(info, errInheritanceOnlyWithNonFinalObjects)

proc searchInstTypes*(key: PType): PType =
  let genericTyp = key.sons[0]
  internalAssert genericTyp.kind == tyGenericBody and
                 key.sons[0] == genericTyp and
                 genericTyp.sym != nil

  if genericTyp.sym.typeInstCache == nil:
    return

  for inst in genericTyp.sym.typeInstCache:
    if inst.id == key.id: return inst
    if inst.sons.len < key.sons.len:
      # XXX: This happens for prematurely cached
      # types such as TChannel[empty]. Why?
      # See the notes for PActor in handleGenericInvokation
      return
    block matchType:
      for j in 1 .. high(key.sons):
        # XXX sameType is not really correct for nested generics?
        if not compareTypes(inst.sons[j], key.sons[j],
                            flags = {ExactGenericParams}):
          break matchType
       
      return inst

proc cacheTypeInst*(inst: PType) =
  # XXX: add to module's generics
  #      update the refcount
  let genericTyp = inst.sons[0]
  genericTyp.sym.typeInstCache.safeAdd(inst)

type
  TReplTypeVars* {.final.} = object 
    c*: PContext
    typeMap*: TIdTable        # map PType to PType
    symMap*: TIdTable         # map PSym to PSym
    info*: TLineInfo
    allowMetaTypes*: bool     # allow types such as seq[Number]
                              # i.e. the result contains unresolved generics

proc replaceTypeVarsT*(cl: var TReplTypeVars, t: PType): PType
proc replaceTypeVarsS(cl: var TReplTypeVars, s: PSym): PSym
proc replaceTypeVarsN(cl: var TReplTypeVars, n: PNode): PNode

proc prepareNode(cl: var TReplTypeVars, n: PNode): PNode =
  result = copyNode(n)
  result.typ = replaceTypeVarsT(cl, n.typ)
  if result.kind == nkSym: result.sym = replaceTypeVarsS(cl, n.sym)
  for i in 0 .. safeLen(n)-1: 
    # XXX HACK: ``f(a, b)``, avoid to instantiate `f` 
    if i == 0: result.add(n[i])
    else: result.add(prepareNode(cl, n[i]))

proc replaceTypeVarsN(cl: var TReplTypeVars, n: PNode): PNode =
  if n == nil: return
  result = copyNode(n)
  result.typ = replaceTypeVarsT(cl, n.typ)
  case n.kind
  of nkNone..pred(nkSym), succ(nkSym)..nkNilLit:
    discard
  of nkSym:
    result.sym = replaceTypeVarsS(cl, n.sym)
  of nkRecWhen:
    var branch: PNode = nil              # the branch to take
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it == nil: illFormedAst(n)
      case it.kind
      of nkElifBranch:
        checkSonsLen(it, 2)
        var cond = prepareNode(cl, it.sons[0])
        var e = cl.c.semConstExpr(cl.c, cond)
        if e.kind != nkIntLit:
          internalError(e.info, "ReplaceTypeVarsN: when condition not a bool")
        if e.intVal != 0 and branch == nil: branch = it.sons[1]
      of nkElse:
        checkSonsLen(it, 1)
        if branch == nil: branch = it.sons[0]
      else: illFormedAst(n)
    if branch != nil:
      result = replaceTypeVarsN(cl, branch)
    else:
      result = newNodeI(nkRecList, n.info)
  else:
    var length = sonsLen(n)
    if length > 0:
      newSons(result, length)
      for i in countup(0, length - 1):
        result.sons[i] = replaceTypeVarsN(cl, n.sons[i])
  
proc replaceTypeVarsS(cl: var TReplTypeVars, s: PSym): PSym = 
  if s == nil: return nil
  result = PSym(idTableGet(cl.symMap, s))
  if result == nil: 
    result = copySym(s, false)
    incl(result.flags, sfFromGeneric)
    idTablePut(cl.symMap, s, result)
    result.typ = replaceTypeVarsT(cl, s.typ)
    result.owner = s.owner
    result.ast = replaceTypeVarsN(cl, s.ast)

proc lookupTypeVar(cl: TReplTypeVars, t: PType): PType = 
  result = PType(idTableGet(cl.typeMap, t))
  if result == nil:
    if cl.allowMetaTypes or tfRetType in t.flags: return
    localError(t.sym.info, errCannotInstantiateX, typeToString(t))
    result = errorType(cl.c)
  elif result.kind == tyGenericParam and not cl.allowMetaTypes:
    internalError(cl.info, "substitution with generic parameter")
 
proc handleGenericInvokation(cl: var TReplTypeVars, t: PType): PType = 
  # tyGenericInvokation[A, tyGenericInvokation[A, B]]
  # is difficult to handle: 
  var body = t.sons[0]
  if body.kind != tyGenericBody: internalError(cl.info, "no generic body")
  var header: PType = nil
  # search for some instantiation here:
  result = searchInstTypes(t)
  if result != nil: return
  for i in countup(1, sonsLen(t) - 1):
    var x = t.sons[i]
    if x.kind == tyGenericParam:
      x = lookupTypeVar(cl, x)
      if x != nil:
        if header == nil: header = copyType(t, t.owner, false)
        header.sons[i] = x
        propagateToOwner(header, x)
  
  if header != nil:
    # search again after first pass:
    result = searchInstTypes(header)
    if result != nil: return
  else:
    header = copyType(t, t.owner, false)
  # ugh need another pass for deeply recursive generic types (e.g. PActor)
  # we need to add the candidate here, before it's fully instantiated for
  # recursive instantions:
  result = newType(tyGenericInst, t.sons[0].owner)
  result.rawAddSon(header.sons[0])
  if not cl.allowMetaTypes:
    cacheTypeInst(result)

  for i in countup(1, sonsLen(t) - 1):
    var x = replaceTypeVarsT(cl, t.sons[i])
    assert x.kind != tyGenericInvokation
    header.sons[i] = x
    propagateToOwner(header, x)
    idTablePut(cl.typeMap, body.sons[i-1], x)
  
  for i in countup(1, sonsLen(t) - 1): 
    # if one of the params is not concrete, we cannot do anything
    # but we already raised an error!
    rawAddSon(result, header.sons[i])
 
  var newbody = replaceTypeVarsT(cl, lastSon(body))
  newbody.flags = newbody.flags + t.flags + body.flags
  result.flags = result.flags + newbody.flags
  newbody.callConv = body.callConv
  # This type may be a generic alias and we want to resolve it here.
  # One step is enough, because the recursive nature of
  # handleGenericInvokation will handle the alias-to-alias-to-alias case
  if newbody.isGenericAlias: newbody = newbody.skipGenericAlias
  rawAddSon(result, newbody)
  checkPartialConstructedType(cl.info, newbody)

proc normalizeProcType(t: PType) =
  if t.sons[0] != nil and t.sons[0].kind == tyEmpty:
    t.sons[0] = nil
  
  for i in 1 .. <t.sonsLen:
    if t.sons[i].kind == tyEmpty:
      # the nested loops are here in order to avoid
      # touching any memory and callign setLen unless
      # it's really necessary
      var pos = i
      for j in i+1 .. <t.sonsLen:
        if t.sons[j].kind != tyEmpty:
          t.sons[pos] = t.sons[j]
          t.n.sons[pos] = t.n.sons[j]
          inc pos
      setLen t.sons, pos
      setLen t.n.sons, pos
      return

proc replaceTypeVarsT*(cl: var TReplTypeVars, t: PType): PType = 
  result = t
  if t == nil: return
  if t.kind == tyStatic and t.sym != nil and t.sym.kind == skGenericParam:
    let s = lookupTypeVar(cl, t)
    return if s != nil: s else: t

  case t.kind
  of tyGenericParam, tyTypeClasses:
    let lookup = lookupTypeVar(cl, t)
    if lookup != nil:
      result = lookup
      if result.kind == tyGenericInvokation:
        result = handleGenericInvokation(cl, result)
  of tyGenericInvokation:
    result = handleGenericInvokation(cl, t)
  of tyGenericBody:
    internalError(cl.info, "ReplaceTypeVarsT: tyGenericBody" )
    result = replaceTypeVarsT(cl, lastSon(t))
  of tyInt:
    result = skipIntLit(t)
    # XXX now there are also float literals
  of tyTypeDesc:
    let lookup = PType(idTableGet(cl.typeMap, t)) # lookupTypeVar(cl, t)
    if lookup != nil:
      result = lookup
      if tfUnresolved in t.flags: result = result.base
  of tyGenericInst:
    result = copyType(t, t.owner, true)
    for i in 1 .. <result.sonsLen:
      result.sons[i] = ReplaceTypeVarsT(cl, result.sons[i])
  else:
    if t.kind == tyArray:
      let idxt = t.sons[0]
      if idxt.kind == tyStatic and 
         idxt.sym != nil and idxt.sym.kind == skGenericParam:
        let value = lookupTypeVar(cl, idxt).n
        t.sons[0] = makeRangeType(cl.c, 0, value.intVal - 1, value.info)
    if containsGenericType(t):
      result = copyType(t, t.owner, false)
      incl(result.flags, tfFromGeneric)
      result.size = -1 # needs to be recomputed
      for i in countup(0, sonsLen(result) - 1):
        result.sons[i] = replaceTypeVarsT(cl, result.sons[i])
      result.n = replaceTypeVarsN(cl, result.n)
      if result.kind in GenericTypes:
        localError(cl.info, errCannotInstantiateX, typeToString(t, preferName))
      if result.kind == tyProc: normalizeProcType(result)

proc generateTypeInstance*(p: PContext, pt: TIdTable, info: TLineInfo,
                           t: PType): PType =
  var cl: TReplTypeVars
  initIdTable(cl.symMap)
  copyIdTable(cl.typeMap, pt)
  cl.info = info
  cl.c = p
  pushInfoContext(info)
  result = replaceTypeVarsT(cl, t)
  popInfoContext()

template generateTypeInstance*(p: PContext, pt: TIdTable, arg: PNode,
                               t: PType): expr =
  generateTypeInstance(p, pt, arg.info, t)

