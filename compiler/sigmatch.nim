#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the signature matching for resolving
## the call to overloaded procs, generic procs and operators.

import 
  intsets, ast, astalgo, semdata, types, msgs, renderer, lookups, semtypinst, 
  magicsys, condsyms, idents, lexer, options

type
  TCandidateState* = enum 
    csEmpty, csMatch, csNoMatch

  TCandidate* {.final.} = object 
    exactMatches*: int
    subtypeMatches: int
    intConvMatches: int      # conversions to int are not as expensive
    convMatches: int
    genericMatches: int
    state*: TCandidateState
    callee*: PType           # may not be nil!
    calleeSym*: PSym         # may be nil
    calleeScope: int         # may be -1 for unknown scope
    call*: PNode             # modified call
    bindings*: TIdTable      # maps types to types
    baseTypeMatch: bool      # needed for conversions from T to openarray[T]
                             # for example
    proxyMatch*: bool        # to prevent instantiations
    inheritancePenalty: int  # to prefer closest father object type
  
  TTypeRelation* = enum      # order is important!
    isNone, isConvertible,
    isIntConv,
    isSubtype,
    isSubrange,              # subrange of the wanted type; no type conversion
                             # but apart from that counts as ``isSubtype``
    isGeneric,
    isFromIntLit,            # conversion *from* int literal; proven safe
    isEqual
    
proc markUsed*(n: PNode, s: PSym)

proc initCandidateAux(c: var TCandidate, callee: PType) {.inline.} = 
  c.exactMatches = 0
  c.subtypeMatches = 0
  c.convMatches = 0
  c.intConvMatches = 0
  c.genericMatches = 0
  c.state = csEmpty
  c.callee = callee
  c.call = nil
  c.baseTypeMatch = false
  c.inheritancePenalty = 0

proc initCandidate*(c: var TCandidate, callee: PType) = 
  initCandidateAux(c, callee)
  c.calleeSym = nil
  initIdTable(c.bindings)

proc put(t: var TIdTable, key, val: PType) {.inline.} =
  IdTablePut(t, key, val)

proc initCandidate*(c: var TCandidate, callee: PSym, binding: PNode, 
                    calleeScope = -1) =
  initCandidateAux(c, callee.typ)
  c.calleeSym = callee
  c.calleeScope = calleeScope
  initIdTable(c.bindings)
  if binding != nil and callee.kind in RoutineKinds:
    var typeParams = callee.ast[genericParamsPos]
    for i in 1..min(sonsLen(typeParams), sonsLen(binding)-1):
      var formalTypeParam = typeParams.sons[i-1].typ
      #debug(formalTypeParam)
      put(c.bindings, formalTypeParam, binding[i].typ)

proc copyCandidate(a: var TCandidate, b: TCandidate) = 
  a.exactMatches = b.exactMatches
  a.subtypeMatches = b.subtypeMatches
  a.convMatches = b.convMatches
  a.intConvMatches = b.intConvMatches
  a.genericMatches = b.genericMatches
  a.state = b.state
  a.callee = b.callee
  a.calleeSym = b.calleeSym
  a.call = copyTree(b.call)
  a.baseTypeMatch = b.baseTypeMatch
  copyIdTable(a.bindings, b.bindings)

proc cmpCandidates*(a, b: TCandidate): int =
  result = a.exactMatches - b.exactMatches
  if result != 0: return
  result = a.genericMatches - b.genericMatches
  if result != 0: return
  result = a.subtypeMatches - b.subtypeMatches
  if result != 0: return
  result = a.intConvMatches - b.intConvMatches
  if result != 0: return
  result = a.convMatches - b.convMatches
  if result != 0: return
  if (a.calleeScope != -1) and (b.calleeScope != -1):
    result = a.calleeScope - b.calleeScope
  if result != 0: return
  # the other way round because of other semantics:
  result = b.inheritancePenalty - a.inheritancePenalty

proc writeMatches*(c: TCandidate) = 
  Writeln(stdout, "exact matches: " & $c.exactMatches)
  Writeln(stdout, "subtype matches: " & $c.subtypeMatches)
  Writeln(stdout, "conv matches: " & $c.convMatches)
  Writeln(stdout, "intconv matches: " & $c.intConvMatches)
  Writeln(stdout, "generic matches: " & $c.genericMatches)

proc NotFoundError*(c: PContext, n: PNode) =
  # Gives a detailed error message; this is separated from semOverloadedCall,
  # as semOverlodedCall is already pretty slow (and we need this information
  # only in case of an error).
  if c.InCompilesContext > 0: 
    # fail fast:
    GlobalError(n.info, errTypeMismatch, "")
  var result = msgKindToString(errTypeMismatch)
  for i in countup(1, sonsLen(n) - 1): 
    #debug(n.sons[i].typ)
    if n.sons[i].kind == nkExprEqExpr: 
      add(result, renderTree(n.sons[i].sons[0]))
      add(result, ": ")
    let nt = n.sons[i].typ
    if nt.kind == tyError: return
    add(result, typeToString(nt))
    if i != sonsLen(n) - 1: add(result, ", ")
  add(result, ')')
  var candidates = ""
  var o: TOverloadIter
  var sym = initOverloadIter(o, c, n.sons[0])
  while sym != nil:
    if sym.kind in RoutineKinds:
      add(candidates, getProcHeader(sym))
      add(candidates, "\n")
      #debug(sym.typ)
    sym = nextOverloadIter(o, c, n.sons[0])
  if candidates != "": 
    add(result, "\n" & msgKindToString(errButExpected) & "\n" & candidates)
  LocalError(n.Info, errGenerated, result)
  
proc typeRel(c: var TCandidate, f, a: PType): TTypeRelation
proc concreteType(c: TCandidate, t: PType): PType = 
  case t.kind
  of tyArrayConstr: 
    # make it an array
    result = newType(tyArray, t.owner)
    addSonSkipIntLit(result, t.sons[0]) # XXX: t.owner is wrong for ID!
    addSonSkipIntLit(result, t.sons[1]) # XXX: semantic checking for the type?
  of tyNil:
    result = nil              # what should it be?
  of tyGenericParam: 
    result = t
    while true: 
      result = PType(idTableGet(c.bindings, t))
      if result == nil:
        break # it's ok, no match
        # example code that triggers it:
        # proc sort[T](cmp: proc(a, b: T): int = cmp)
      if result.kind != tyGenericParam: break
  of tyGenericInvokation:
    InternalError("cannot resolve type: " & typeToString(t))
    result = t
  else:
    result = t                # Note: empty is valid here
  
proc handleRange(f, a: PType, min, max: TTypeKind): TTypeRelation = 
  if a.kind == f.kind: 
    result = isEqual
  else:
    let ab = skipTypes(a, {tyRange})
    let k = ab.kind
    if k == f.kind: result = isSubrange
    elif k == tyInt and f.kind in {tyRange, tyInt8..tyInt64, 
                                   tyUInt..tyUInt64} and
        isIntLit(ab) and ab.n.intVal >= firstOrd(f) and
                         ab.n.intVal <= lastOrd(f):
      # integer literal in the proper range; we want ``i16 + 4`` to stay an
      # ``int16`` operation so we declare the ``4`` pseudo-equal to int16
      result = isFromIntLit
    elif f.kind == tyInt and k in {tyInt8..tyInt32}:
      result = isIntConv
    elif k >= min and k <= max: 
      result = isConvertible
    elif a.kind == tyRange and a.sons[0].kind in {tyInt..tyInt64, 
                                                  tyUInt8..tyUInt32} and
                         a.n[0].intVal >= firstOrd(f) and
                         a.n[1].intVal <= lastOrd(f):
      result = isConvertible
    else: result = isNone
    #elif f.kind == tyInt and k in {tyInt..tyInt32}: result = isIntConv
    #elif f.kind == tyUInt and k in {tyUInt..tyUInt32}: result = isIntConv

proc isConvertibleToRange(f, a: PType): bool =
  # be less picky for tyRange, as that it is used for array indexing:
  if f.kind in {tyInt..tyInt64, tyUInt..tyUInt64} and
     a.kind in {tyInt..tyInt64, tyUInt..tyUInt64}:
    result = true
  elif f.kind in {tyFloat..tyFloat128} and
       a.kind in {tyFloat..tyFloat128}:
    result = true

proc handleFloatRange(f, a: PType): TTypeRelation = 
  if a.kind == f.kind: 
    result = isEqual
  else: 
    let ab = skipTypes(a, {tyRange})
    var k = ab.kind
    if k == f.kind: result = isSubrange
    elif isIntLit(ab): result = isConvertible
    elif k >= tyFloat and k <= tyFloat128: result = isConvertible
    else: result = isNone
  
proc isObjectSubtype(a, f: PType): int =
  var t = a
  assert t.kind == tyObject
  var depth = 0
  while t != nil and not sameObjectTypes(f, t): 
    assert t.kind == tyObject
    t = t.sons[0]
    if t == nil: break
    t = skipTypes(t, {tyGenericInst})
    inc depth
  if t != nil:
    result = depth

proc minRel(a, b: TTypeRelation): TTypeRelation = 
  if a <= b: result = a
  else: result = b
  
proc tupleRel(c: var TCandidate, f, a: PType): TTypeRelation =
  result = isNone
  if sameType(f, a):
    result = isEqual
  elif sonsLen(a) == sonsLen(f):
    result = isEqual
    for i in countup(0, sonsLen(f) - 1):
      var m = typeRel(c, f.sons[i], a.sons[i])
      if m < isSubtype: return isNone
      result = minRel(result, m)
    if f.n != nil and a.n != nil:
      for i in countup(0, sonsLen(f.n) - 1):
        # check field names:
        if f.n.sons[i].kind != nkSym: InternalError(f.n.info, "tupleRel")
        elif a.n.sons[i].kind != nkSym: InternalError(a.n.info, "tupleRel")
        else:
          var x = f.n.sons[i].sym
          var y = a.n.sons[i].sym
          if x.name.id != y.name.id: return isNone

proc matchTypeClass(c: var TCandidate, f, a: PType): TTypeRelation =
  for i in countup(0, f.sonsLen - 1):
    let son = f.sons[i]
    var match = son.kind == skipTypes(a, {tyRange, tyGenericInst}).kind

    if not match:
      case son.kind
      of tyGenericBody:
        if a.kind == tyGenericInst and a.sons[0] == son:
          match = true
          put(c.bindings, f, a)
      of tyTypeClass:
        match = matchTypeClass(c, son, a) == isGeneric
      else: nil

    if tfAny in f.flags:
      if match:
        return isGeneric
    else:
      if not match:
        return isNone

  # if the loop finished without returning, either all constraints matched
  # or none of them matched.
  result = if tfAny in f.flags: isNone else: isGeneric
  
proc procTypeRel(c: var TCandidate, f, a: PType): TTypeRelation =
  proc inconsistentVarTypes(f, a: PType): bool {.inline.} =
    result = f.kind != a.kind and (f.kind == tyVar or a.kind == tyVar)

  case a.kind
  of tyNil: result = isSubtype
  of tyProc:
    if sonsLen(f) != sonsLen(a): return
    # Note: We have to do unification for the parameters before the
    # return type!
    result = isEqual      # start with maximum; also correct for no
                          # params at all
    for i in countup(1, sonsLen(f)-1):
      var m = typeRel(c, f.sons[i], a.sons[i])
      if m <= isSubtype or inconsistentVarTypes(f.sons[i], a.sons[i]):
        return isNone
      else: result = minRel(m, result)
    if f.sons[0] != nil:
      if a.sons[0] != nil:
        var m = typeRel(c, f.sons[0], a.sons[0])
        # Subtype is sufficient for return types!
        if m < isSubtype or inconsistentVarTypes(f.sons[0], a.sons[0]):
          result = isNone
        elif m == isSubtype: result = isConvertible
        else: result = minRel(m, result)
      else:
        result = isNone
    elif a.sons[0] != nil:
      result = isNone
    if tfNoSideEffect in f.flags and tfNoSideEffect notin a.flags:
      result = isNone
    elif tfThread in f.flags and a.flags * {tfThread, tfNoSideEffect} == {}:
      # noSideEffect implies ``tfThread``! XXX really?
      result = isNone
    elif f.callconv != a.callconv:
      # valid to pass a 'nimcall' thingie to 'closure':
      if f.callconv == ccClosure and a.callconv == ccDefault:
        result = isConvertible
      else:
        result = isNone
  else: nil

proc typeRel(c: var TCandidate, f, a: PType): TTypeRelation = 
  # is a subtype of f?
  result = isNone
  assert(f != nil)
  assert(a != nil)
  if a.kind == tyGenericInst and
      skipTypes(f, {tyVar}).kind notin {
        tyGenericBody, tyGenericInvokation,
        tyGenericParam, tyTypeClass}:
    return typeRel(c, f, lastSon(a))
  if a.kind == tyVar and f.kind != tyVar:
    return typeRel(c, f, a.sons[0])
  case f.kind
  of tyEnum: 
    if a.kind == f.kind and sameEnumTypes(f, a): result = isEqual
    elif sameEnumTypes(f, skipTypes(a, {tyRange})): result = isSubtype
  of tyBool, tyChar: 
    if a.kind == f.kind: result = isEqual
    elif skipTypes(a, {tyRange}).kind == f.kind: result = isSubtype
  of tyRange:
    if a.kind == f.kind:
      result = typeRel(c, base(f), base(a))
      # bugfix: accept integer conversions here
      #if result < isGeneric: result = isNone
    elif skipTypes(f, {tyRange}).kind == a.kind:
      result = isIntConv
    elif isConvertibleToRange(skipTypes(f, {tyRange}), a):
      result = isConvertible  # a convertible to f
  of tyInt:      result = handleRange(f, a, tyInt8, tyInt32)
  of tyInt8:     result = handleRange(f, a, tyInt8, tyInt8)
  of tyInt16:    result = handleRange(f, a, tyInt8, tyInt16)
  of tyInt32:    result = handleRange(f, a, tyInt8, tyInt32)
  of tyInt64:    result = handleRange(f, a, tyInt, tyInt64)
  of tyUInt:     result = handleRange(f, a, tyUInt8, tyUInt32)
  of tyUInt8:    result = handleRange(f, a, tyUInt8, tyUInt8)
  of tyUInt16:   result = handleRange(f, a, tyUInt8, tyUInt16)
  of tyUInt32:   result = handleRange(f, a, tyUInt8, tyUInt32)
  of tyUInt64:   result = handleRange(f, a, tyUInt, tyUInt64)
  of tyFloat:    result = handleFloatRange(f, a)
  of tyFloat32:  result = handleFloatRange(f, a)
  of tyFloat64:  result = handleFloatRange(f, a)
  of tyFloat128: result = handleFloatRange(f, a)
  of tyVar: 
    if a.kind == f.kind: result = typeRel(c, base(f), base(a))
    else: result = typeRel(c, base(f), a)
  of tyArray, tyArrayConstr: 
    # tyArrayConstr cannot happen really, but
    # we wanna be safe here
    case a.kind
    of tyArray: 
      result = minRel(typeRel(c, f.sons[0], a.sons[0]), 
                      typeRel(c, f.sons[1], a.sons[1]))
      if result < isGeneric: result = isNone
    of tyArrayConstr: 
      result = typeRel(c, f.sons[1], a.sons[1])
      if result < isGeneric: 
        result = isNone
      else: 
        if (result != isGeneric) and (lengthOrd(f) != lengthOrd(a)): 
          result = isNone
        elif f.sons[0].kind in GenericTypes: 
          result = minRel(result, typeRel(c, f.sons[0], a.sons[0]))
    else: nil
  of tyOpenArray, tyVarargs:
    case a.Kind
    of tyOpenArray, tyVarargs:
      result = typeRel(c, base(f), base(a))
      if result < isGeneric: result = isNone
    of tyArrayConstr: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[1].kind == tyEmpty): 
        result = isSubtype    # [] is allowed here
      elif typeRel(c, base(f), a.sons[1]) >= isGeneric: 
        result = isSubtype
    of tyArray: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[1].kind == tyEmpty): 
        result = isSubtype
      elif typeRel(c, base(f), a.sons[1]) >= isGeneric: 
        result = isConvertible
    of tySequence: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty): 
        result = isConvertible
      elif typeRel(c, base(f), a.sons[0]) >= isGeneric: 
        result = isConvertible
    else: nil
  of tySequence: 
    case a.Kind
    of tyNil: 
      result = isSubtype
    of tySequence: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty): 
        result = isSubtype
      else: 
        result = typeRel(c, f.sons[0], a.sons[0])
        if result < isGeneric: result = isNone
    else: nil
  of tyOrdinal:
    if isOrdinalType(a):
      var x = if a.kind == tyOrdinal: a.sons[0] else: a
      result = typeRel(c, f.sons[0], x)
      if result < isGeneric: result = isNone
  of tyForward: InternalError("forward type in typeRel()")
  of tyNil:
    if a.kind == f.kind: result = isEqual
  of tyTuple: 
    if a.kind == tyTuple: result = tupleRel(c, f, a)
  of tyObject:
    if a.kind == tyObject:
      if sameObjectTypes(f, a): result = isEqual
      else:
        var depth = isObjectSubtype(a, f)
        if depth > 0:
          inc(c.inheritancePenalty, depth)
          result = isSubtype
  of tyDistinct:
    if (a.kind == tyDistinct) and sameDistinctTypes(f, a): result = isEqual
  of tySet: 
    if a.kind == tySet: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty): 
        result = isSubtype
      else: 
        result = typeRel(c, f.sons[0], a.sons[0])
        if result <= isConvertible: 
          result = isNone     # BUGFIX!
  of tyPtr: 
    case a.kind
    of tyPtr: 
      result = typeRel(c, base(f), base(a))
      if result <= isConvertible: result = isNone
    of tyNil: result = isSubtype
    else: nil
  of tyRef: 
    case a.kind
    of tyRef: 
      result = typeRel(c, base(f), base(a))
      if result <= isConvertible: result = isNone
    of tyNil: result = isSubtype
    else: nil
  of tyProc: 
    result = procTypeRel(c, f, a)
  of tyPointer: 
    case a.kind
    of tyPointer: result = isEqual
    of tyNil: result = isSubtype
    of tyProc:
      if a.callConv != ccClosure: result = isConvertible
    of tyPtr, tyCString: result = isConvertible
    else: nil
  of tyString: 
    case a.kind
    of tyString: result = isEqual
    of tyNil: result = isSubtype
    else: nil
  of tyCString: 
    # conversion from string to cstring is automatic:
    case a.Kind
    of tyCString: result = isEqual
    of tyNil: result = isSubtype
    of tyString: result = isConvertible
    of tyPtr: 
      if a.sons[0].kind == tyChar: result = isConvertible
    of tyArray: 
      if (firstOrd(a.sons[0]) == 0) and
          (skipTypes(a.sons[0], {tyRange}).kind in {tyInt..tyInt64}) and
          (a.sons[1].kind == tyChar): 
        result = isConvertible
    else: nil
  of tyEmpty: 
    if a.kind == tyEmpty: result = isEqual
  of tyGenericInst: 
    result = typeRel(c, lastSon(f), a)
  of tyGenericBody: 
    let ff = lastSon(f)
    if ff != nil: result = typeRel(c, ff, a)
  of tyGenericInvokation:
    assert(f.sons[0].kind == tyGenericBody)
    if a.kind == tyGenericInvokation: 
      #InternalError("typeRel: tyGenericInvokation -> tyGenericInvokation")
      # simply no match for now:
      nil
    elif a.kind == tyGenericInst and 
          (f.sons[0].containerID == a.sons[0].containerID) and
          (sonsLen(a) - 1 == sonsLen(f)): 
      assert(a.sons[0].kind == tyGenericBody)
      for i in countup(1, sonsLen(f) - 1): 
        if a.sons[i].kind == tyGenericParam: 
          InternalError("wrong instantiated type!")
        elif typeRel(c, f.sons[i], a.sons[i]) <= isSubtype: return 
      result = isGeneric
    else:
      result = typeRel(c, f.sons[0], a)
      if result != isNone:
        # we steal the generic parameters from the tyGenericBody:
        for i in countup(1, sonsLen(f) - 1):
          var x = PType(idTableGet(c.bindings, f.sons[0].sons[i - 1]))
          if x == nil or x.kind in {tyGenericInvokation, tyGenericParam}:
            InternalError("wrong instantiated type!")
          put(c.bindings, f.sons[i], x)
  of tyGenericParam, tyTypeClass:
    var x = PType(idTableGet(c.bindings, f))
    if x == nil:
      result = matchTypeClass(c, f, a)
      if result == isGeneric:
        var concrete = concreteType(c, a)
        if concrete == nil:
          result = isNone
        else:
          put(c.bindings, f, concrete)
    elif a.kind == tyEmpty:
      result = isGeneric
    elif x.kind == tyGenericParam:
      result = isGeneric
    else:
      result = typeRel(c, x, a) # check if it fits
  of tyTypeDesc:
    if a.kind == tyTypeDesc:
      if f.sonsLen == 0:
        result = isGeneric
      else:
        result = matchTypeClass(c, f, a.sons[0])
      if result == isGeneric: put(c.bindings, f, a)
    else:
      result = isNone
  of tyExpr, tyStmt:
    result = isGeneric
  of tyProxy:
    result = isEqual
  else: internalError("typeRel: " & $f.kind)
  
proc cmpTypes*(f, a: PType): TTypeRelation = 
  var c: TCandidate
  InitCandidate(c, f)
  result = typeRel(c, f, a)

proc getInstantiatedType(c: PContext, arg: PNode, m: TCandidate, 
                         f: PType): PType = 
  result = PType(idTableGet(m.bindings, f))
  if result == nil: 
    result = generateTypeInstance(c, m.bindings, arg, f)
  if result == nil:
    InternalError(arg.info, "getInstantiatedType")
    result = errorType(c)
  
proc implicitConv(kind: TNodeKind, f: PType, arg: PNode, m: TCandidate, 
                  c: PContext): PNode = 
  result = newNodeI(kind, arg.info)
  if containsGenericType(f):
    if not m.proxyMatch:
      result.typ = getInstantiatedType(c, arg, m, f)
    else:
      result.typ = errorType(c)
  else:
    result.typ = f
  if result.typ == nil: InternalError(arg.info, "implicitConv")
  addSon(result, ast.emptyNode)
  addSon(result, arg)

proc userConvMatch(c: PContext, m: var TCandidate, f, a: PType, 
                   arg: PNode): PNode = 
  result = nil
  for i in countup(0, len(c.converters) - 1): 
    var src = c.converters[i].typ.sons[1]
    var dest = c.converters[i].typ.sons[0]
    if (typeRel(m, f, dest) == isEqual) and
        (typeRel(m, src, a) == isEqual):
      markUsed(arg, c.converters[i])
      var s = newSymNode(c.converters[i])
      s.typ = c.converters[i].typ
      s.info = arg.info
      result = newNodeIT(nkHiddenCallConv, arg.info, s.typ.sons[0])
      addSon(result, s)
      addSon(result, copyTree(arg))
      inc(m.convMatches)
      return

proc localConvMatch(c: PContext, m: var TCandidate, f, a: PType, 
                    arg: PNode): PNode = 
  var call = newNodeI(nkCall, arg.info)
  call.add(f.n.copyTree)
  call.add(arg.copyTree)
  result = c.semOverloadedCall(c, call, call, RoutineKinds)
  if result != nil:
    # resulting type must be consistent with the other arguments:
    var r = typeRel(m, f.sons[0], result.typ)
    if r < isGeneric: return nil
    if result.kind == nkCall: result.kind = nkHiddenCallConv
    inc(m.convMatches)
    if r == isGeneric:
      result.typ = getInstantiatedType(c, arg, m, base(f))
    m.baseTypeMatch = true

proc ParamTypesMatchAux(c: PContext, m: var TCandidate, f, a: PType, 
                        arg, argOrig: PNode): PNode =
  var r: TTypeRelation
  if f.kind == tyExpr:
    if f.sonsLen == 0:
      r = isGeneric
    else:
      let match = matchTypeClass(m, f, a)
      if match != isGeneric: r = isNone
      else:
        # XXX: Ideally, this should happen much earlier somewhere near 
        # semOpAux, but to do that, we need to be able to query the 
        # overload set to determine whether compile-time value is expected
        # for the param before entering the full-blown sigmatch algorithm.
        # This is related to the immediate pragma since querying the
        # overload set could help there too.
        var evaluated = c.semConstExpr(c, arg)
        if evaluated != nil:
          r = isGeneric
          arg.typ = newTypeS(tyExpr, c)
          arg.typ.n = evaluated
        
    if r == isGeneric:
      put(m.bindings, f, arg.typ)
  else:
    r = typeRel(m, f, a)
  
  case r
  of isConvertible: 
    inc(m.convMatches)
    result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isIntConv:
    # I'm too lazy to introduce another ``*matches`` field, so we conflate
    # ``isIntConv`` and ``isIntLit`` here:
    inc(m.intConvMatches)
    result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isSubtype: 
    inc(m.subtypeMatches)
    result = implicitConv(nkHiddenSubConv, f, copyTree(arg), m, c)
  of isSubrange:
    inc(m.subtypeMatches)
    result = copyTree(arg)
  of isGeneric:
    inc(m.genericMatches)
    if m.calleeSym != nil and m.calleeSym.kind in {skMacro, skTemplate}:
      result = argOrig
    else:
      result = copyTree(arg)
      result.typ = getInstantiatedType(c, arg, m, f) 
      # BUG: f may not be the right key!
      if skipTypes(result.typ, abstractVar).kind in {tyTuple}:
        result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c) 
        # BUGFIX: use ``result.typ`` and not `f` here
  of isFromIntLit:
    # too lazy to introduce another ``*matches`` field, so we conflate
    # ``isIntConv`` and ``isIntLit`` here:
    inc(m.intConvMatches, 256)
    result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isEqual: 
    inc(m.exactMatches)
    result = copyTree(arg)
    if skipTypes(f, abstractVar).kind in {tyTuple}: 
      result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isNone:
    # do not do this in ``typeRel`` as it then can't infere T in ``ref T``:
    if a.kind == tyProxy:
      inc(m.genericMatches)
      m.proxyMatch = true
      return copyTree(arg)
    result = userConvMatch(c, m, f, a, arg) 
    # check for a base type match, which supports varargs[T] without []
    # constructor in a call:
    if result == nil and f.kind == tyVarargs:
      if f.n != nil:
        result = localConvMatch(c, m, f, a, arg)
      else:
        r = typeRel(m, base(f), a)
        if r >= isGeneric:
          inc(m.convMatches)
          result = copyTree(arg)
          if r == isGeneric:
            result.typ = getInstantiatedType(c, arg, m, base(f))
          m.baseTypeMatch = true
        else:
          result = userConvMatch(c, m, base(f), a, arg)

proc ParamTypesMatch(c: PContext, m: var TCandidate, f, a: PType, 
                     arg, argOrig: PNode): PNode = 
  if arg == nil or arg.kind != nkClosedSymChoice:
    result = ParamTypesMatchAux(c, m, f, a, arg, argOrig)
  else: 
    # CAUTION: The order depends on the used hashing scheme. Thus it is
    # incorrect to simply use the first fitting match. However, to implement
    # this correctly is inefficient. We have to copy `m` here to be able to
    # roll back the side effects of the unification algorithm.
    var x, y, z: TCandidate
    initCandidate(x, m.callee)
    initCandidate(y, m.callee)
    initCandidate(z, m.callee)
    x.calleeSym = m.calleeSym
    y.calleeSym = m.calleeSym
    z.calleeSym = m.calleeSym
    var best = -1
    for i in countup(0, sonsLen(arg) - 1): 
      # iterators are not first class yet, so ignore them
      if arg.sons[i].sym.kind in {skProc, skMethod, skConverter}: 
        copyCandidate(z, m)
        var r = typeRel(z, f, arg.sons[i].typ)
        if r != isNone: 
          case x.state
          of csEmpty, csNoMatch: 
            x = z
            best = i
            x.state = csMatch
          of csMatch: 
            var cmp = cmpCandidates(x, z)
            if cmp < 0: 
              best = i
              x = z
            elif cmp == 0: 
              y = z           # z is as good as x
    if x.state == csEmpty: 
      result = nil
    elif (y.state == csMatch) and (cmpCandidates(x, y) == 0): 
      if x.state != csMatch: 
        InternalError(arg.info, "x.state is not csMatch") 
      # ambiguous: more than one symbol fits
      result = nil
    else: 
      # only one valid interpretation found:
      markUsed(arg, arg.sons[best].sym)
      result = ParamTypesMatchAux(c, m, f, arg.sons[best].typ, arg.sons[best],
                                  argOrig)

proc IndexTypesMatch*(c: PContext, f, a: PType, arg: PNode): PNode = 
  var m: TCandidate
  initCandidate(m, f)
  result = paramTypesMatch(c, m, f, a, arg, nil)

proc ConvertTo*(c: PContext, f: PType, n: PNode): PNode = 
  var m: TCandidate
  initCandidate(m, f)
  result = paramTypesMatch(c, m, f, n.typ, n, nil)

proc argtypeMatches*(c: PContext, f, a: PType): bool = 
  var m: TCandidate
  initCandidate(m, f)
  result = paramTypesMatch(c, m, f, a, ast.emptyNode, nil) != nil  

proc setSon(father: PNode, at: int, son: PNode) = 
  if sonsLen(father) <= at: setlen(father.sons, at + 1)
  father.sons[at] = son

proc matchesAux*(c: PContext, n, nOrig: PNode,
                 m: var TCandidate, marker: var TIntSet) = 
  var f = 1 # iterates over formal parameters
  var a = 1 # iterates over the actual given arguments
  m.state = csMatch           # until proven otherwise
  m.call = newNodeI(n.kind, n.info)
  m.call.typ = base(m.callee) # may be nil
  var formalLen = sonsLen(m.callee.n)
  addSon(m.call, copyTree(n.sons[0]))
  var container: PNode = nil # constructed container
  var formal: PSym = nil
  while a < n.len:
    if n.sons[a].kind == nkExprEqExpr:
      # named param
      # check if m.callee has such a param:
      if n.sons[a].sons[0].kind != nkIdent: 
        LocalError(n.sons[a].info, errNamedParamHasToBeIdent)
        m.state = csNoMatch
        return 
      formal = getSymFromList(m.callee.n, n.sons[a].sons[0].ident, 1)
      if formal == nil: 
        # no error message!
        m.state = csNoMatch
        return 
      if ContainsOrIncl(marker, formal.position): 
        # already in namedParams:
        LocalError(n.sons[a].info, errCannotBindXTwice, formal.name.s)
        m.state = csNoMatch
        return 
      m.baseTypeMatch = false
      var arg = ParamTypesMatch(c, m, formal.typ, n.sons[a].typ,
                                n.sons[a].sons[1], nOrig.sons[a].sons[1])
      if arg == nil: 
        m.state = csNoMatch
        return 
      if m.baseTypeMatch: 
        assert(container == nil)
        container = newNodeI(nkBracket, n.sons[a].info)
        addSon(container, arg)
        setSon(m.call, formal.position + 1, container)
        if f != formalLen - 1: container = nil
      else: 
        setSon(m.call, formal.position + 1, arg)
    else: 
      # unnamed param
      if f >= formalLen: 
        # too many arguments?
        if tfVarArgs in m.callee.flags: 
          # is ok... but don't increment any counters...
          if skipTypes(n.sons[a].typ, abstractVar).kind == tyString: 
            addSon(m.call, implicitConv(nkHiddenStdConv, getSysType(tyCString), 
                                        copyTree(n.sons[a]), m, c))
          else: 
            addSon(m.call, copyTree(n.sons[a]))
        elif formal != nil:
          m.baseTypeMatch = false
          var arg = ParamTypesMatch(c, m, formal.typ, n.sons[a].typ,
                                    n.sons[a], nOrig.sons[a])
          if (arg != nil) and m.baseTypeMatch and (container != nil): 
            addSon(container, arg)
          else: 
            m.state = csNoMatch
            return 
        else: 
          m.state = csNoMatch
          return 
      else: 
        if m.callee.n.sons[f].kind != nkSym: 
          InternalError(n.sons[a].info, "matches")
          return
        formal = m.callee.n.sons[f].sym
        if ContainsOrIncl(marker, formal.position): 
          # already in namedParams:
          LocalError(n.sons[a].info, errCannotBindXTwice, formal.name.s)
          m.state = csNoMatch
          return 
        m.baseTypeMatch = false
        var arg = ParamTypesMatch(c, m, formal.typ, n.sons[a].typ,
                                  n.sons[a], nOrig.sons[a])
        if arg == nil: 
          m.state = csNoMatch
          return 
        if m.baseTypeMatch: 
          assert(container == nil)
          container = newNodeI(nkBracket, n.sons[a].info)
          addSon(container, arg)
          setSon(m.call, formal.position + 1, 
                 implicitConv(nkHiddenStdConv, formal.typ, container, m, c))
          if f != formalLen - 1: container = nil
        else: 
          setSon(m.call, formal.position + 1, arg)
    inc(a)
    inc(f)

proc partialMatch*(c: PContext, n, nOrig: PNode, m: var TCandidate) =
  # for 'suggest' support:
  var marker = initIntSet()
  matchesAux(c, n, nOrig, m, marker)

proc matches*(c: PContext, n, nOrig: PNode, m: var TCandidate) =
  var marker = initIntSet()
  matchesAux(c, n, nOrig, m, marker)
  if m.state == csNoMatch: return
  # check that every formal parameter got a value:
  var f = 1
  while f < sonsLen(m.callee.n):
    var formal = m.callee.n.sons[f].sym
    if not ContainsOrIncl(marker, formal.position): 
      if formal.ast == nil:
        if formal.typ.kind == tyVarargs:
          var container = newNodeI(nkBracket, n.info)
          addSon(m.call, implicitConv(nkHiddenStdConv, formal.typ,
                                      container, m, c))
        else:
          # no default value
          m.state = csNoMatch
          break
      else:
        # use default value:
        setSon(m.call, formal.position + 1, copyTree(formal.ast))
    inc(f)

include suggest
