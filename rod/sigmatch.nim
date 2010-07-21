#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the signature matching for resolving
# the call to overloaded procs, generic procs and operators.

type 
  TCandidateState = enum 
    csEmpty, csMatch, csNoMatch
  TCandidate{.final.} = object 
    exactMatches*: int
    subtypeMatches*: int
    intConvMatches*: int      # conversions to int are not as expensive
    convMatches*: int
    genericMatches*: int
    state*: TCandidateState
    callee*: PType            # may not be nil!
    calleeSym*: PSym          # may be nil
    call*: PNode              # modified call
    bindings*: TIdTable       # maps sym-ids to types
    baseTypeMatch*: bool      # needed for conversions from T to openarray[T]
                              # for example
  
  TTypeRelation = enum        # order is important!
    isNone, isConvertible, isIntConv, isSubtype, isGeneric, isEqual

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

proc initCandidate(c: var TCandidate, callee: PType) = 
  initCandidateAux(c, callee)
  c.calleeSym = nil
  initIdTable(c.bindings)

proc initCandidate(c: var TCandidate, callee: PSym, binding: PNode) = 
  initCandidateAux(c, callee.typ)
  c.calleeSym = callee
  initIdTable(c.bindings)
  if binding != nil:
    var typeParams = callee.ast[genericParamsPos]
    for i in 1..min(sonsLen(typeParams), sonsLen(binding)-1):
      var formalTypeParam = typeParams.sons[i-1].typ
      #debug(formalTypeParam)
      IdTablePut(c.bindings, formalTypeParam, binding[i].typ)

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

proc cmpCandidates(a, b: TCandidate): int = 
  result = a.exactMatches - b.exactMatches
  if result != 0: return 
  result = a.genericMatches - b.genericMatches
  if result != 0: return 
  result = a.subtypeMatches - b.subtypeMatches
  if result != 0: return 
  result = a.intConvMatches - b.intConvMatches
  if result != 0: return 
  result = a.convMatches - b.convMatches

proc writeMatches(c: TCandidate) = 
  Writeln(stdout, "exact matches: " & $(c.exactMatches))
  Writeln(stdout, "subtype matches: " & $(c.subtypeMatches))
  Writeln(stdout, "conv matches: " & $(c.convMatches))
  Writeln(stdout, "intconv matches: " & $(c.intConvMatches))
  Writeln(stdout, "generic matches: " & $(c.genericMatches))

proc getNotFoundError(c: PContext, n: PNode): string = 
  # Gives a detailed error message; this is seperated from semDirectCall,
  # as semDirectCall is already pretty slow (and we need this information only
  # in case of an error).
  result = msgKindToString(errTypeMismatch)
  for i in countup(1, sonsLen(n) - 1): 
    #debug(n.sons[i].typ);
    add(result, typeToString(n.sons[i].typ))
    if i != sonsLen(n) - 1: add(result, ", ")
  add(result, ')')
  var candidates = ""
  var o: TOverloadIter  
  var sym = initOverloadIter(o, c, n.sons[0])
  while sym != nil: 
    if sym.kind in {skProc, skMethod, skIterator, skConverter}: 
      add(candidates, getProcHeader(sym))
      add(candidates, "\n")
    sym = nextOverloadIter(o, c, n.sons[0])
  if candidates != "": 
    add(result, "\n" & msgKindToString(errButExpected) & "\n" & candidates)
  
proc typeRel(mapping: var TIdTable, f, a: PType): TTypeRelation
proc concreteType(mapping: TIdTable, t: PType): PType = 
  case t.kind
  of tyArrayConstr: 
    # make it an array
    result = newType(tyArray, t.owner)
    addSon(result, t.sons[0]) # XXX: t.owner is wrong for ID!
    addSon(result, t.sons[1]) # XXX: semantic checking for the type?
  of tyNil: 
    result = nil              # what should it be?
  of tyGenericParam: 
    result = t
    while true: 
      result = PType(idTableGet(mapping, t))
      if result == nil: InternalError("lookup failed")
      if result.kind != tyGenericParam: break 
  else: 
    result = t                # Note: empty is valid here
  
proc handleRange(f, a: PType, min, max: TTypeKind): TTypeRelation = 
  if a.kind == f.kind: 
    result = isEqual
  else: 
    var k = skipTypes(a, {tyRange}).kind
    if k == f.kind: result = isSubtype
    elif (f.kind == tyInt) and (k in {tyInt..tyInt32}): result = isIntConv
    elif (k >= min) and (k <= max): result = isConvertible
    else: result = isNone
  
proc handleFloatRange(f, a: PType): TTypeRelation = 
  if a.kind == f.kind: 
    result = isEqual
  else: 
    var k = skipTypes(a, {tyRange}).kind
    if k == f.kind: result = isSubtype
    elif (k >= tyFloat) and (k <= tyFloat128): result = isConvertible
    else: result = isNone
  
proc isObjectSubtype(a, f: PType): bool = 
  var t = a
  while (t != nil) and (t.id != f.id): t = base(t)
  result = t != nil

proc minRel(a, b: TTypeRelation): TTypeRelation = 
  if a <= b: result = a
  else: result = b
  
proc tupleRel(mapping: var TIdTable, f, a: PType): TTypeRelation = 
  result = isNone
  if sonsLen(a) == sonsLen(f): 
    result = isEqual
    for i in countup(0, sonsLen(f) - 1): 
      var m = typeRel(mapping, f.sons[i], a.sons[i])
      if m < isSubtype: return isNone
      result = minRel(result, m)
    if f.n != nil and a.n != nil: 
      for i in countup(0, sonsLen(f.n) - 1): 
        # check field names:
        if f.n.sons[i].kind != nkSym: InternalError(f.n.info, "tupleRel")
        if a.n.sons[i].kind != nkSym: InternalError(a.n.info, "tupleRel")
        var x = f.n.sons[i].sym
        var y = a.n.sons[i].sym
        if x.name.id != y.name.id: return isNone

proc typeRel(mapping: var TIdTable, f, a: PType): TTypeRelation = 
  var 
    x, concrete: PType
    m: TTypeRelation
  # is a subtype of f?
  result = isNone
  assert(f != nil)
  assert(a != nil)
  if a.kind == tyGenericInst and
      skipTypes(f, {tyVar}).kind notin {tyGenericBody, tyGenericInvokation}: 
    return typeRel(mapping, f, lastSon(a))
  if a.kind == tyVar and f.kind != tyVar: 
    return typeRel(mapping, f, a.sons[0])
  case f.kind
  of tyEnum: 
    if a.kind == f.kind and a.id == f.id: result = isEqual
    elif skipTypes(a, {tyRange}).id == f.id: result = isSubtype
  of tyBool, tyChar: 
    if a.kind == f.kind: result = isEqual
    elif skipTypes(a, {tyRange}).kind == f.kind: result = isSubtype
  of tyRange: 
    if a.kind == f.kind: 
      result = typeRel(mapping, base(a), base(f))
      if result < isGeneric: result = isNone
    elif skipTypes(f, {tyRange}).kind == a.kind: 
      result = isConvertible  # a convertible to f
  of tyInt:      result = handleRange(f, a, tyInt8, tyInt32)
  of tyInt8:     result = handleRange(f, a, tyInt8, tyInt8)
  of tyInt16:    result = handleRange(f, a, tyInt8, tyInt16)
  of tyInt32:    result = handleRange(f, a, tyInt, tyInt32)
  of tyInt64:    result = handleRange(f, a, tyInt, tyInt64)
  of tyFloat:    result = handleFloatRange(f, a)
  of tyFloat32:  result = handleFloatRange(f, a)
  of tyFloat64:  result = handleFloatRange(f, a)
  of tyFloat128: result = handleFloatRange(f, a)
  of tyVar: 
    if (a.kind == f.kind): result = typeRel(mapping, base(f), base(a))
    else: result = typeRel(mapping, base(f), a)
  of tyArray, tyArrayConstr: 
    # tyArrayConstr cannot happen really, but
    # we wanna be safe here
    case a.kind
    of tyArray: 
      result = minRel(typeRel(mapping, f.sons[0], a.sons[0]), 
                      typeRel(mapping, f.sons[1], a.sons[1]))
      if result < isGeneric: result = isNone
    of tyArrayConstr: 
      result = typeRel(mapping, f.sons[1], a.sons[1])
      if result < isGeneric: 
        result = isNone
      else: 
        if (result != isGeneric) and (lengthOrd(f) != lengthOrd(a)): 
          result = isNone
        elif f.sons[0].kind in GenericTypes: 
          result = minRel(result, typeRel(mapping, f.sons[0], a.sons[0]))
    else: nil
  of tyOpenArray: 
    case a.Kind
    of tyOpenArray: 
      result = typeRel(mapping, base(f), base(a))
      if result < isGeneric: result = isNone
    of tyArrayConstr: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[1].kind == tyEmpty): 
        result = isSubtype    # [] is allowed here
      elif typeRel(mapping, base(f), a.sons[1]) >= isGeneric: 
        result = isSubtype
    of tyArray: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[1].kind == tyEmpty): 
        result = isSubtype
      elif typeRel(mapping, base(f), a.sons[1]) >= isGeneric: 
        result = isConvertible
    of tySequence: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty): 
        result = isConvertible
      elif typeRel(mapping, base(f), a.sons[0]) >= isGeneric: 
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
        result = typeRel(mapping, f.sons[0], a.sons[0])
        if result < isGeneric: result = isNone
    else: nil
  of tyOrdinal: 
    if isOrdinalType(a): 
      if a.kind == tyOrdinal: x = a.sons[0]
      else: x = a
      result = typeRel(mapping, f.sons[0], x)
      if result < isGeneric: result = isNone
  of tyForward: InternalError("forward type in typeRel()")
  of tyNil: 
    if a.kind == f.kind: result = isEqual
  of tyTuple: 
    if a.kind == tyTuple: result = tupleRel(mapping, f, a)
  of tyObject: 
    if a.kind == tyObject: 
      if a.id == f.id: result = isEqual
      elif isObjectSubtype(a, f): result = isSubtype
  of tyDistinct: 
    if (a.kind == tyDistinct) and (a.id == f.id): result = isEqual
  of tySet: 
    if a.kind == tySet: 
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty): 
        result = isSubtype
      else: 
        result = typeRel(mapping, f.sons[0], a.sons[0])
        if result <= isConvertible: 
          result = isNone     # BUGFIX!
  of tyPtr: 
    case a.kind
    of tyPtr: 
      result = typeRel(mapping, base(f), base(a))
      if result <= isConvertible: result = isNone
    of tyNil: result = isSubtype
    else: nil
  of tyRef: 
    case a.kind
    of tyRef: 
      result = typeRel(mapping, base(f), base(a))
      if result <= isConvertible: result = isNone
    of tyNil: result = isSubtype
    else: nil
  of tyProc: 
    case a.kind
    of tyNil: result = isSubtype
    of tyProc: 
      if (sonsLen(f) == sonsLen(a)) and (f.callconv == a.callconv): 
        # Note: We have to do unification for the parameters before the
        # return type!
        result = isEqual      # start with maximum; also correct for no
                              # params at all
        for i in countup(1, sonsLen(f) - 1): 
          m = typeRel(mapping, f.sons[i], a.sons[i])
          if (m == isNone) and
              (typeRel(mapping, a.sons[i], f.sons[i]) == isSubtype): 
            # allow ``f.son`` as subtype of ``a.son``!
            result = isConvertible
          elif m < isSubtype: 
            return isNone
          else: 
            result = minRel(m, result)
        if f.sons[0] != nil: 
          if a.sons[0] != nil: 
            m = typeRel(mapping, f.sons[0], a.sons[0]) 
            # Subtype is sufficient for return types!
            if m < isSubtype: result = isNone
            elif m == isSubtype: result = isConvertible
            else: result = minRel(m, result)
          else: 
            result = isNone
        elif a.sons[0] != nil: 
          result = isNone
        if (tfNoSideEffect in f.flags) and not (tfNoSideEffect in a.flags): 
          result = isNone
    else: nil
  of tyPointer: 
    case a.kind
    of tyPointer: result = isEqual
    of tyNil: result = isSubtype
    of tyPtr, tyProc, tyCString: result = isConvertible
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
    result = typeRel(mapping, lastSon(f), a)
  of tyGenericBody: 
    result = typeRel(mapping, lastSon(f), a)
  of tyGenericInvokation: 
    assert(f.sons[0].kind == tyGenericBody)
    if a.kind == tyGenericInvokation: 
      InternalError("typeRel: tyGenericInvokation -> tyGenericInvokation")
    if (a.kind == tyGenericInst): 
      if (f.sons[0].containerID == a.sons[0].containerID) and
          (sonsLen(a) - 1 == sonsLen(f)): 
        assert(a.sons[0].kind == tyGenericBody)
        for i in countup(1, sonsLen(f) - 1): 
          if a.sons[i].kind == tyGenericParam: 
            InternalError("wrong instantiated type!")
          if typeRel(mapping, f.sons[i], a.sons[i]) < isGeneric: return 
        result = isGeneric
    else: 
      result = typeRel(mapping, f.sons[0], a)
      if result != isNone: 
        # we steal the generic parameters from the tyGenericBody:
        for i in countup(1, sonsLen(f) - 1): 
          x = PType(idTableGet(mapping, f.sons[0].sons[i - 1]))
          if (x == nil) or (x.kind == tyGenericParam): 
            InternalError("wrong instantiated type!")
          idTablePut(mapping, f.sons[i], x)
  of tyGenericParam: 
    x = PType(idTableGet(mapping, f))
    if x == nil: 
      if sonsLen(f) == 0: 
        # no constraints
        concrete = concreteType(mapping, a)
        if concrete != nil: 
          #MessageOut('putting: ' + f.sym.name.s);
          idTablePut(mapping, f, concrete)
          result = isGeneric
      else: 
        InternalError(f.sym.info, "has constraints: " & f.sym.name.s) 
        # check constraints:
        for i in countup(0, sonsLen(f) - 1): 
          if typeRel(mapping, f.sons[i], a) >= isSubtype: 
            concrete = concreteType(mapping, a)
            if concrete != nil: 
              idTablePut(mapping, f, concrete)
              result = isGeneric
            break 
    elif a.kind == tyEmpty: 
      result = isGeneric
    elif x.kind == tyGenericParam: 
      result = isGeneric
    else: 
      result = typeRel(mapping, x, a) # check if it fits
  of tyExpr, tyStmt, tyTypeDesc: 
    if a.kind == f.kind: 
      result = isEqual
    else: 
      case a.kind
      of tyExpr, tyStmt, tyTypeDesc: result = isGeneric
      of tyNil: result = isSubtype
      else: nil
  else: internalError("typeRel(" & $f.kind & ')')
  
proc cmpTypes(f, a: PType): TTypeRelation = 
  var mapping: TIdTable
  InitIdTable(mapping)
  result = typeRel(mapping, f, a)

proc getInstantiatedType(c: PContext, arg: PNode, m: TCandidate, 
                         f: PType): PType = 
  result = PType(idTableGet(m.bindings, f))
  if result == nil: 
    result = generateTypeInstance(c, m.bindings, arg, f)
  if result == nil: InternalError(arg.info, "getInstantiatedType")
  
proc implicitConv(kind: TNodeKind, f: PType, arg: PNode, m: TCandidate, 
                  c: PContext): PNode = 
  result = newNodeI(kind, arg.info)
  if containsGenericType(f): result.typ = getInstantiatedType(c, arg, m, f)
  else: result.typ = f
  if result.typ == nil: InternalError(arg.info, "implicitConv")
  addSon(result, nil)
  addSon(result, arg)

proc userConvMatch(c: PContext, m: var TCandidate, f, a: PType, 
                   arg: PNode): PNode = 
  result = nil
  for i in countup(0, len(c.converters) - 1): 
    var src = c.converters[i].typ.sons[1]
    var dest = c.converters[i].typ.sons[0]
    if (typeRel(m.bindings, f, dest) == isEqual) and
        (typeRel(m.bindings, src, a) == isEqual): 
      var s = newSymNode(c.converters[i])
      s.typ = c.converters[i].typ
      s.info = arg.info
      result = newNodeIT(nkHiddenCallConv, arg.info, s.typ.sons[0])
      addSon(result, s)
      addSon(result, copyTree(arg))
      inc(m.convMatches)
      return 

proc ParamTypesMatchAux(c: PContext, m: var TCandidate, f, a: PType, 
                        arg: PNode): PNode = 
  var r = typeRel(m.bindings, f, a)
  case r
  of isConvertible: 
    inc(m.convMatches)
    result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isIntConv: 
    inc(m.intConvMatches)
    result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isSubtype: 
    inc(m.subtypeMatches)
    result = implicitConv(nkHiddenSubConv, f, copyTree(arg), m, c)
  of isGeneric: 
    inc(m.genericMatches)
    result = copyTree(arg)
    result.typ = getInstantiatedType(c, arg, m, f) 
    # BUG: f may not be the right key!
    if (skipTypes(result.typ, abstractVar).kind in {tyTuple, tyOpenArray}): 
      result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c) 
      # BUGFIX: use ``result.typ`` and not `f` here
  of isEqual: 
    inc(m.exactMatches)
    result = copyTree(arg)
    if (skipTypes(f, abstractVar).kind in {tyTuple, tyOpenArray}): 
      result = implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c)
  of isNone: 
    result = userConvMatch(c, m, f, a, arg) 
    # check for a base type match, which supports openarray[T] without []
    # constructor in a call:
    if (result == nil) and (f.kind == tyOpenArray): 
      r = typeRel(m.bindings, base(f), a)
      if r >= isGeneric: 
        inc(m.convMatches)
        result = copyTree(arg)
        if r == isGeneric: result.typ = getInstantiatedType(c, arg, m, base(f))
        m.baseTypeMatch = true
      else: 
        result = userConvMatch(c, m, base(f), a, arg)
  
proc ParamTypesMatch(c: PContext, m: var TCandidate, f, a: PType, 
                     arg: PNode): PNode = 
  if (arg == nil) or (arg.kind != nkSymChoice): 
    result = ParamTypesMatchAux(c, m, f, a, arg)
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
    var best = - 1
    for i in countup(0, sonsLen(arg) - 1): 
      # iterators are not first class yet, so ignore them
      if arg.sons[i].sym.kind in {skProc, skMethod, skConverter}: 
        copyCandidate(z, m)
        var r = typeRel(z.bindings, f, arg.sons[i].typ)
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
            else: 
              nil
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
      result = ParamTypesMatchAux(c, m, f, arg.sons[best].typ, arg.sons[best])

proc IndexTypesMatch(c: PContext, f, a: PType, arg: PNode): PNode = 
  var m: TCandidate
  initCandidate(m, f)
  result = paramTypesMatch(c, m, f, a, arg)

proc setSon(father: PNode, at: int, son: PNode) = 
  if sonsLen(father) <= at: setlen(father.sons, at + 1)
  father.sons[at] = son

proc matches(c: PContext, n: PNode, m: var TCandidate) = 
  var f = 1 # iterates over formal parameters
  var a = 1 # iterates over the actual given arguments
  m.state = csMatch           # until proven otherwise
  m.call = newNodeI(nkCall, n.info)
  m.call.typ = base(m.callee) # may be nil
  var formalLen = sonsLen(m.callee.n)
  addSon(m.call, copyTree(n.sons[0]))
  var marker: TIntSet
  IntSetInit(marker)
  var container: PNode = nil # constructed container
  var formal: PSym = nil
  while a < sonsLen(n): 
    if n.sons[a].kind == nkExprEqExpr: 
      # named param
      # check if m.callee has such a param:
      if n.sons[a].sons[0].kind != nkIdent: 
        liMessage(n.sons[a].info, errNamedParamHasToBeIdent)
        m.state = csNoMatch
        return 
      formal = getSymFromList(m.callee.n, n.sons[a].sons[0].ident, 1)
      if formal == nil: 
        # no error message!
        m.state = csNoMatch
        return 
      if IntSetContainsOrIncl(marker, formal.position): 
        # already in namedParams:
        liMessage(n.sons[a].info, errCannotBindXTwice, formal.name.s)
        m.state = csNoMatch
        return 
      m.baseTypeMatch = false
      var arg = ParamTypesMatch(c, m, formal.typ, 
                                      n.sons[a].typ, n.sons[a].sons[1])
      if (arg == nil): 
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
          var arg = ParamTypesMatch(c, m, formal.typ, n.sons[a].typ, n.sons[a])
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
        formal = m.callee.n.sons[f].sym
        if IntSetContainsOrIncl(marker, formal.position): 
          # already in namedParams:
          liMessage(n.sons[a].info, errCannotBindXTwice, formal.name.s)
          m.state = csNoMatch
          return 
        m.baseTypeMatch = false
        var arg = ParamTypesMatch(c, m, formal.typ, n.sons[a].typ, n.sons[a])
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
  f = 1
  while f < sonsLen(m.callee.n): 
    formal = m.callee.n.sons[f].sym
    if not IntSetContainsOrIncl(marker, formal.position): 
      if formal.ast == nil: 
        if formal.typ.kind == tyOpenArray:
          container = newNodeI(nkBracket, n.info)
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

proc sameMethodDispatcher(a, b: PSym): bool = 
  result = false
  if a.kind == skMethod and b.kind == skMethod: 
    var aa = lastSon(a.ast)
    var bb = lastSon(b.ast)
    if aa.kind == nkSym and bb.kind == nkSym and aa.sym == bb.sym: 
      result = true
  
proc semDirectCallWithBinding(c: PContext, n, f: PNode, filter: TSymKinds,
                              initialBinding: PNode): PNode = 
  var
    o: TOverloadIter
    x, y, z: TCandidate
  #liMessage(n.info, warnUser, renderTree(n));
  var sym = initOverloadIter(o, c, f)
  result = nil
  if sym == nil: return 
  initCandidate(x, sym, initialBinding)
  initCandidate(y, sym, initialBinding)
  while sym != nil: 
    if sym.kind in filter: 
      initCandidate(z, sym, initialBinding)
      z.calleeSym = sym
      matches(c, n, z)
      if z.state == csMatch: 
        case x.state
        of csEmpty, csNoMatch: x = z
        of csMatch: 
          var cmp = cmpCandidates(x, z)
          if cmp < 0: x = z # z is better than x
          elif cmp == 0: y = z # z is as good as x
          else: nil
    sym = nextOverloadIter(o, c, f)
  if x.state == csEmpty: 
    # no overloaded proc found
    # do not generate an error yet; the semantic checking will check for
    # an overloaded () operator
  elif y.state == csMatch and cmpCandidates(x, y) == 0 and
      not sameMethodDispatcher(x.calleeSym, y.calleeSym): 
    if x.state != csMatch: 
      InternalError(n.info, "x.state is not csMatch") #writeMatches(x);
                                                      #writeMatches(y);
    liMessage(n.Info, errGenerated, msgKindToString(errAmbiguousCallXYZ) % [
      getProcHeader(x.calleeSym), getProcHeader(y.calleeSym), 
      x.calleeSym.Name.s])
  else: 
    # only one valid interpretation found:
    markUsed(n, x.calleeSym)
    if x.calleeSym.ast == nil: 
      internalError(n.info, "calleeSym.ast is nil") # XXX: remove this check!
    if x.calleeSym.ast.sons[genericParamsPos] != nil: 
      # a generic proc!
      x.calleeSym = generateInstance(c, x.calleeSym, x.bindings, n.info)
      x.callee = x.calleeSym.typ
    result = x.call
    result.sons[0] = newSymNode(x.calleeSym)
    result.typ = x.callee.sons[0]
        
proc semDirectCall(c: PContext, n: PNode, filter: TSymKinds): PNode = 
  # process the bindings once:
  var initialBinding: PNode
  var f = n.sons[0]
  if f.kind == nkBracketExpr:
    # fill in the bindings:
    initialBinding = f
    f = f.sons[0]
  else: 
    initialBinding = nil
  result = semDirectCallWithBinding(c, n, f, filter, initialBinding)

