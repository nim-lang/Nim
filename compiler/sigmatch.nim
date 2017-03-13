#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the signature matching for resolving
## the call to overloaded procs, generic procs and operators.

import
  intsets, ast, astalgo, semdata, types, msgs, renderer, lookups, semtypinst,
  magicsys, condsyms, idents, lexer, options, parampatterns, strutils, trees,
  nimfix.pretty

when not defined(noDocgen):
  import docgen

type
  TCandidateState* = enum
    csEmpty, csMatch, csNoMatch

  CandidateErrors* = seq[(PSym,int)]
  TCandidate* = object
    c*: PContext
    exactMatches*: int       # also misused to prefer iters over procs
    genericMatches: int      # also misused to prefer constraints
    subtypeMatches: int
    intConvMatches: int      # conversions to int are not as expensive
    convMatches: int
    state*: TCandidateState
    callee*: PType           # may not be nil!
    calleeSym*: PSym         # may be nil
    calleeScope*: int        # scope depth:
                             # is this a top-level symbol or a nested proc?
    call*: PNode             # modified call
    bindings*: TIdTable      # maps types to types
    magic*: TMagic           # magic of operation
    baseTypeMatch: bool      # needed for conversions from T to openarray[T]
                             # for example
    fauxMatch*: TTypeKind    # the match was successful only due to the use
                             # of error or wildcard (unknown) types.
                             # this is used to prevent instantiations.
    genericConverter*: bool  # true if a generic converter needs to
                             # be instantiated
    coerceDistincts*: bool   # this is an explicit coercion that can strip away
                             # a distrinct type
    typedescMatched*: bool
    isNoCall*: bool          # misused for generic type instantiations C[T]
    mutabilityProblem*: uint8 # tyVar mismatch
    inheritancePenalty: int  # to prefer closest father object type
    errors*: CandidateErrors # additional clarifications to be displayed to the
                             # user if overload resolution fails

  TTypeRelation* = enum      # order is important!
    isNone, isConvertible,
    isIntConv,
    isSubtype,
    isSubrange,              # subrange of the wanted type; no type conversion
                             # but apart from that counts as ``isSubtype``
    isBothMetaConvertible    # generic proc parameter was matched against
                             # generic type, e.g., map(mySeq, x=>x+1),
                             # maybe recoverable by rerun if the parameter is
                             # the proc's return value
    isInferred,              # generic proc was matched against a concrete type
    isInferredConvertible,   # same as above, but requiring proc CC conversion
    isGeneric,
    isFromIntLit,            # conversion *from* int literal; proven safe
    isEqual

const
  isNilConversion = isConvertible # maybe 'isIntConv' fits better?

proc markUsed*(info: TLineInfo, s: PSym; usageSym: var PSym)

template hasFauxMatch*(c: TCandidate): bool = c.fauxMatch != tyNone

proc initCandidateAux(ctx: PContext,
                      c: var TCandidate, callee: PType) {.inline.} =
  c.c = ctx
  c.exactMatches = 0
  c.subtypeMatches = 0
  c.convMatches = 0
  c.intConvMatches = 0
  c.genericMatches = 0
  c.state = csEmpty
  c.callee = callee
  c.call = nil
  c.baseTypeMatch = false
  c.genericConverter = false
  c.inheritancePenalty = 0

proc initCandidate*(ctx: PContext, c: var TCandidate, callee: PType) =
  initCandidateAux(ctx, c, callee)
  c.calleeSym = nil
  initIdTable(c.bindings)

proc put(c: var TCandidate, key, val: PType) {.inline.} =
  idTablePut(c.bindings, key, val.skipIntLit)

proc initCandidate*(ctx: PContext, c: var TCandidate, callee: PSym,
                    binding: PNode, calleeScope = -1) =
  initCandidateAux(ctx, c, callee.typ)
  c.calleeSym = callee
  if callee.kind in skProcKinds and calleeScope == -1:
    if callee.originatingModule == ctx.module:
      c.calleeScope = 2
      var owner = callee
      while true:
        owner = owner.skipGenericOwner
        if owner.kind == skModule: break
        inc c.calleeScope
    else:
      c.calleeScope = 1
  else:
    c.calleeScope = calleeScope
  c.magic = c.calleeSym.magic
  initIdTable(c.bindings)
  c.errors = nil
  if binding != nil and callee.kind in routineKinds:
    var typeParams = callee.ast[genericParamsPos]
    for i in 1..min(sonsLen(typeParams), sonsLen(binding)-1):
      var formalTypeParam = typeParams.sons[i-1].typ
      var bound = binding[i].typ
      internalAssert bound != nil
      if formalTypeParam.kind == tyTypeDesc:
        if bound.kind != tyTypeDesc:
          bound = makeTypeDesc(ctx, bound)
      else:
        bound = bound.skipTypes({tyTypeDesc})
      put(c, formalTypeParam, bound)

proc newCandidate*(ctx: PContext, callee: PSym,
                   binding: PNode, calleeScope = -1): TCandidate =
  initCandidate(ctx, result, callee, binding, calleeScope)

proc newCandidate*(ctx: PContext, callee: PType): TCandidate =
  initCandidate(ctx, result, callee)

proc copyCandidate(a: var TCandidate, b: TCandidate) =
  a.c = b.c
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

proc sumGeneric(t: PType): int =
  var t = t
  var isvar = 1
  while true:
    case t.kind
    of tyGenericInst, tyArray, tyRef, tyPtr, tyDistinct,
        tyOpenArray, tyVarargs, tySet, tyRange, tySequence, tyGenericBody:
      t = t.lastSon
      inc result
    of tyVar:
      t = t.sons[0]
      inc result
      inc isvar
    of tyTypeDesc:
      t = t.lastSon
      if t.kind == tyEmpty: break
      inc result
    of tyGenericInvocation, tyTuple, tyProc:
      result += ord(t.kind == tyGenericInvocation)
      for i in 0 .. <t.len:
        if t.sons[i] != nil:
          result += t.sons[i].sumGeneric
      break
    of tyGenericParam, tyExpr, tyStatic, tyStmt: break
    of tyAlias: t = t.lastSon
    of tyBool, tyChar, tyEnum, tyObject, tyPointer,
        tyString, tyCString, tyInt..tyInt64, tyFloat..tyFloat128,
        tyUInt..tyUInt64, tyCompositeTypeClass:
      return isvar
    else:
      return 0

#var ggDebug: bool

proc complexDisambiguation(a, b: PType): int =
  # 'a' matches better if *every* argument matches better or equal than 'b'.
  var winner = 0
  for i in 1 .. <min(a.len, b.len):
    let x = a.sons[i].sumGeneric
    let y = b.sons[i].sumGeneric
    #if ggDebug:
    #  echo "came her ", typeToString(a.sons[i]), " ", typeToString(b.sons[i])
    if x != y:
      if winner == 0:
        if x > y: winner = 1
        else: winner = -1
      elif x > y:
        if winner != 1:
          # contradiction
          return 0
      else:
        if winner != -1:
          return 0
  result = winner
  when false:
    var x, y: int
    for i in 1 .. <a.len: x += a.sons[i].sumGeneric
    for i in 1 .. <b.len: y += b.sons[i].sumGeneric
    result = x - y

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
  # the other way round because of other semantics:
  result = b.inheritancePenalty - a.inheritancePenalty
  if result != 0: return
  # prefer more specialized generic over more general generic:
  result = complexDisambiguation(a.callee, b.callee)
  # only as a last resort, consider scoping:
  if result != 0: return
  result = a.calleeScope - b.calleeScope

proc writeMatches*(c: TCandidate) =
  writeLine(stdout, "exact matches: " & $c.exactMatches)
  writeLine(stdout, "generic matches: " & $c.genericMatches)
  writeLine(stdout, "subtype matches: " & $c.subtypeMatches)
  writeLine(stdout, "intconv matches: " & $c.intConvMatches)
  writeLine(stdout, "conv matches: " & $c.convMatches)
  writeLine(stdout, "inheritance: " & $c.inheritancePenalty)

proc argTypeToString(arg: PNode; prefer: TPreferedDesc): string =
  if arg.kind in nkSymChoices:
    result = typeToString(arg[0].typ, prefer)
    for i in 1 .. <arg.len:
      result.add(" | ")
      result.add typeToString(arg[i].typ, prefer)
  elif arg.typ == nil:
    result = "void"
  else:
    result = arg.typ.typeToString(prefer)

proc describeArgs*(c: PContext, n: PNode, startIdx = 1;
                   prefer: TPreferedDesc = preferName): string =
  result = ""
  for i in countup(startIdx, n.len - 1):
    var arg = n.sons[i]
    if n.sons[i].kind == nkExprEqExpr:
      add(result, renderTree(n.sons[i].sons[0]))
      add(result, ": ")
      if arg.typ.isNil and arg.kind notin {nkStmtList, nkDo}:
        # XXX we really need to 'tryExpr' here!
        arg = c.semOperand(c, n.sons[i].sons[1])
        n.sons[i].typ = arg.typ
        n.sons[i].sons[1] = arg
    else:
      if arg.typ.isNil and arg.kind notin {nkStmtList, nkDo}:
        arg = c.semOperand(c, n.sons[i])
        n.sons[i] = arg
    if arg.typ != nil and arg.typ.kind == tyError: return
    add(result, argTypeToString(arg, prefer))
    if i != sonsLen(n) - 1: add(result, ", ")

proc typeRel*(c: var TCandidate, f, aOrig: PType, doBind = true): TTypeRelation
proc concreteType(c: TCandidate, t: PType): PType =
  case t.kind
  of tyNil:
    result = nil              # what should it be?
  of tyTypeDesc:
    if c.isNoCall: result = t
    else: result = nil
  of tySequence, tySet:
    if t.sons[0].kind == tyEmpty: result = nil
    else: result = t
  of tyGenericParam, tyAnything:
    result = t
    while true:
      result = PType(idTableGet(c.bindings, t))
      if result == nil:
        break # it's ok, no match
        # example code that triggers it:
        # proc sort[T](cmp: proc(a, b: T): int = cmp)
      if result.kind != tyGenericParam: break
  of tyGenericInvocation:
    internalError("cannot resolve type: " & typeToString(t))
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
    elif isFloatLit(ab): result = isFromIntLit
    elif isIntLit(ab): result = isConvertible
    elif k >= tyFloat and k <= tyFloat128:
      # conversion to "float32" is not as good:
      if f.kind == tyFloat32: result = isConvertible
      else: result = isIntConv
    else: result = isNone

proc isObjectSubtype(c: var TCandidate; a, f, fGenericOrigin: PType): int =
  var t = a
  assert t.kind == tyObject
  var depth = 0
  var last = a
  while t != nil and not sameObjectTypes(f, t):
    assert t.kind == tyObject
    t = t.sons[0]
    if t == nil: break
    last = t
    t = skipTypes(t, skipPtrs)
    inc depth
  if t != nil:
    if fGenericOrigin != nil and last.kind == tyGenericInst and
        last.len-1 == fGenericOrigin.len:
      for i in countup(1, sonsLen(fGenericOrigin) - 1):
        let x = PType(idTableGet(c.bindings, fGenericOrigin.sons[i]))
        if x == nil:
          put(c, fGenericOrigin.sons[i], last.sons[i])
    result = depth
  else:
    result = -1

type
  SkippedPtr = enum skippedNone, skippedRef, skippedPtr

proc skipToObject(t: PType; skipped: var SkippedPtr): PType =
  var r = t
  # we're allowed to skip one level of ptr/ref:
  var ptrs = 0
  while r != nil:
    case r.kind
    of tyGenericInvocation:
      r = r.sons[0]
    of tyRef:
      inc ptrs
      skipped = skippedRef
      r = r.lastSon
    of tyPtr:
      inc ptrs
      skipped = skippedPtr
      r = r.lastSon
    of tyGenericBody, tyGenericInst, tyAlias:
      r = r.lastSon
    else:
      break
  if r.kind == tyObject and ptrs <= 1: result = r

proc isGenericSubtype(a, f: PType, d: var int): bool =
  assert f.kind in {tyGenericInst, tyGenericInvocation, tyGenericBody}
  var askip = skippedNone
  var fskip = skippedNone
  var t = a.skipToObject(askip)
  let r = f.skipToObject(fskip)
  if r == nil: return false
  var depth = 0
  # XXX sameObjectType can return false here. Need to investigate
  # why that is but sameObjectType does way too much work here anyway.
  while t != nil and r.sym != t.sym and askip == fskip:
    t = t.sons[0]
    if t != nil: t = t.skipToObject(askip)
    else: break
    inc depth
  if t != nil and askip == fskip:
    d = depth
    result = true

proc minRel(a, b: TTypeRelation): TTypeRelation =
  if a <= b: result = a
  else: result = b

proc recordRel(c: var TCandidate, f, a: PType): TTypeRelation =
  result = isNone
  if sameType(f, a):
    result = isEqual
  elif sonsLen(a) == sonsLen(f):
    result = isEqual
    let firstField = if f.kind == tyTuple: 0
                     else: 1
    for i in countup(firstField, sonsLen(f) - 1):
      var m = typeRel(c, f.sons[i], a.sons[i])
      if m < isSubtype: return isNone
      result = minRel(result, m)
    if f.n != nil and a.n != nil:
      for i in countup(0, sonsLen(f.n) - 1):
        # check field names:
        if f.n.sons[i].kind != nkSym: internalError(f.n.info, "recordRel")
        elif a.n.sons[i].kind != nkSym: internalError(a.n.info, "recordRel")
        else:
          var x = f.n.sons[i].sym
          var y = a.n.sons[i].sym
          if f.kind == tyObject and typeRel(c, x.typ, y.typ) < isSubtype:
            return isNone
          if x.name.id != y.name.id: return isNone

proc allowsNil(f: PType): TTypeRelation {.inline.} =
  result = if tfNotNil notin f.flags: isSubtype else: isNone

proc inconsistentVarTypes(f, a: PType): bool {.inline.} =
  result = f.kind != a.kind and (f.kind == tyVar or a.kind == tyVar)

proc procParamTypeRel(c: var TCandidate, f, a: PType): TTypeRelation =
  ## For example we have:
  ## .. code-block:: nim
  ##   proc myMap[T,S](sIn: seq[T], f: proc(x: T): S): seq[S] = ...
  ##   proc innerProc[Q,W](q: Q): W = ...
  ## And we want to match: myMap(@[1,2,3], innerProc)
  ## This proc (procParamTypeRel) will do the following steps in
  ## three different calls:
  ## - matches f=T to a=Q. Since f is metatype, we resolve it
  ##    to int (which is already known at this point). So in this case
  ##    Q=int mapping will be saved to c.bindings.
  ## - matches f=S to a=W. Both of these metatypes are unknown, so we
  ##    return with isBothMetaConvertible to ask for rerun.
  ## - matches f=S to a=W. At this point the return type of innerProc
  ##    is known (we get it from c.bindings). We can use that value
  ##    to match with f, and save back to c.bindings.
  var
    f = f
    a = a

  if a.isMetaType:
    let aResolved = PType(idTableGet(c.bindings, a))
    if aResolved != nil:
      a = aResolved
  if a.isMetaType:
    if f.isMetaType:
      # We are matching a generic proc (as proc param)
      # to another generic type appearing in the proc
      # signature. There is a change that the target
      # type is already fully-determined, so we are
      # going to try resolve it
      f = generateTypeInstance(c.c, c.bindings, c.call.info, f)
      if f == nil or f.isMetaType:
        # no luck resolving the type, so the inference fails
        return isBothMetaConvertible
    # Note that this typeRel call will save a's resolved type into c.bindings
    let reverseRel = typeRel(c, a, f)
    if reverseRel >= isGeneric:
      result = isInferred
      #inc c.genericMatches
  else:
    # Note that this typeRel call will save f's resolved type into c.bindings
    # if f is metatype.
    result = typeRel(c, f, a)

  if result <= isSubtype or inconsistentVarTypes(f, a):
    result = isNone

  #if result == isEqual:
  #  inc c.exactMatches

proc procTypeRel(c: var TCandidate, f, a: PType): TTypeRelation =
  case a.kind
  of tyProc:
    if sonsLen(f) != sonsLen(a): return
    result = isEqual      # start with maximum; also correct for no
                          # params at all

    template checkParam(f, a) =
      result = minRel(result, procParamTypeRel(c, f, a))
      if result == isNone: return

    # Note: We have to do unification for the parameters before the
    # return type!
    for i in 1 .. <f.sonsLen:
      checkParam(f.sons[i], a.sons[i])

    if f.sons[0] != nil:
      if a.sons[0] != nil:
        checkParam(f.sons[0], a.sons[0])
      else:
        return isNone
    elif a.sons[0] != nil:
      return isNone

    if tfNoSideEffect in f.flags and tfNoSideEffect notin a.flags:
      return isNone
    elif tfThread in f.flags and a.flags * {tfThread, tfNoSideEffect} == {} and
        optThreadAnalysis in gGlobalOptions:
      # noSideEffect implies ``tfThread``!
      return isNone
    elif f.flags * {tfIterator} != a.flags * {tfIterator}:
      return isNone
    elif f.callConv != a.callConv:
      # valid to pass a 'nimcall' thingie to 'closure':
      if f.callConv == ccClosure and a.callConv == ccDefault:
        result = if result == isInferred: isInferredConvertible
                 elif result == isBothMetaConvertible: isBothMetaConvertible
                 else: isConvertible
      else:
        return isNone
    when useEffectSystem:
      if compatibleEffects(f, a) != efCompat: return isNone

  of tyNil:
    result = f.allowsNil
  else: discard

proc typeRangeRel(f, a: PType): TTypeRelation {.noinline.} =
  let
    a0 = firstOrd(a)
    a1 = lastOrd(a)
    f0 = firstOrd(f)
    f1 = lastOrd(f)
  if a0 == f0 and a1 == f1:
    result = isEqual
  elif a0 >= f0 and a1 <= f1:
    result = isConvertible
  elif a0 <= f1 and f0 <= a1:
    # X..Y and C..D overlap iff (X <= D and C <= Y)
    result = isConvertible
  else:
    result = isNone

proc matchUserTypeClass*(c: PContext, m: var TCandidate,
                         ff, a: PType): TTypeRelation =
  var body = ff.skipTypes({tyUserTypeClassInst})
  if c.inTypeClass > 4:
    localError(body.n[3].info, $body.n[3] & " too nested for type matching")
    return isNone

  openScope(c)
  inc c.inTypeClass

  defer:
    dec c.inTypeClass
    closeScope(c)

  if ff.kind == tyUserTypeClassInst:
    for i in 1 .. <(ff.len - 1):
      var
        typeParamName = ff.base.sons[i-1].sym.name
        typ = ff.sons[i]
        param: PSym

      template paramSym(kind): untyped =
        newSym(kind, typeParamName, body.sym, body.sym.info)

      case typ.kind
      of tyStatic:
        param = paramSym skConst
        param.typ = typ.base
        param.ast = typ.n
      of tyUnknown:
        param = paramSym skVar
        param.typ = typ
      else:
        param = paramSym skType
        param.typ = makeTypeDesc(c, typ)

      addDecl(c, param)
      #echo "A ", param.name.s, " ", typeToString(param.typ), " ", param.kind

  for param in body.n[0]:
    var
      dummyName: PNode
      dummyType: PType

    if param.kind == nkVarTy:
      dummyName = param[0]
      dummyType = if a.kind != tyVar: makeVarType(c, a) else: a
    else:
      dummyName = param
      dummyType = a

    internalAssert dummyName.kind == nkIdent
    var dummyParam = newSym(skVar, dummyName.ident, body.sym, body.sym.info)
    dummyParam.typ = dummyType
    addDecl(c, dummyParam)
    #echo "B ", dummyName.ident.s, " ", typeToString(dummyType), " ", dummyparam.kind

  var checkedBody = c.semTryExpr(c, body.n[3].copyTree)
  if checkedBody == nil: return isNone
  return isGeneric

proc shouldSkipDistinct(rules: PNode, callIdent: PIdent): bool =
  if rules.kind == nkWith:
    for r in rules:
      if r.considerQuotedIdent == callIdent: return true
    return false
  else:
    for r in rules:
      if r.considerQuotedIdent == callIdent: return false
    return true

proc maybeSkipDistinct(t: PType, callee: PSym): PType =
  if t != nil and t.kind == tyDistinct and t.n != nil and
     shouldSkipDistinct(t.n, callee.name):
    result = t.base
  else:
    result = t

proc tryResolvingStaticExpr(c: var TCandidate, n: PNode): PNode =
  # Consider this example:
  #   type Value[N: static[int]] = object
  #   proc foo[N](a: Value[N], r: range[0..(N-1)])
  # Here, N-1 will be initially nkStaticExpr that can be evaluated only after
  # N is bound to a concrete value during the matching of the first param.
  # This proc is used to evaluate such static expressions.
  let instantiated = replaceTypesInBody(c.c, c.bindings, n, nil)
  result = c.c.semExpr(c.c, instantiated)

template subtypeCheck() =
  if result <= isSubrange and f.lastSon.skipTypes(abstractInst).kind in {tyRef, tyPtr, tyVar}:
    result = isNone

proc typeRel(c: var TCandidate, f, aOrig: PType, doBind = true): TTypeRelation =
  # typeRel can be used to establish various relationships between types:
  #
  # 1) When used with concrete types, it will check for type equivalence
  # or a subtype relationship.
  #
  # 2) When used with a concrete type against a type class (such as generic
  # signature of a proc), it will check whether the concrete type is a member
  # of the designated type class.
  #
  # 3) When used with two type classes, it will check whether the types
  # matching the first type class are a strict subset of the types matching
  # the other. This allows us to compare the signatures of generic procs in
  # order to give preferrence to the most specific one:
  #
  # seq[seq[any]] is a strict subset of seq[any] and hence more specific.

  result = isNone
  assert(f != nil)

  if f.kind == tyExpr:
    if aOrig != nil: put(c, f, aOrig)
    return isGeneric

  assert(aOrig != nil)

  # var and static arguments match regular modifier-free types
  let a = aOrig.skipTypes({tyStatic, tyVar}).maybeSkipDistinct(c.calleeSym)
  # XXX: Theoretically, maybeSkipDistinct could be called before we even
  # start the param matching process. This could be done in `prepareOperand`
  # for example, but unfortunately `prepareOperand` is not called in certain
  # situation when nkDotExpr are rotated to nkDotCalls

  if a.kind in {tyGenericInst, tyAlias} and
      skipTypes(f, {tyVar}).kind notin {
        tyGenericBody, tyGenericInvocation,
        tyGenericInst, tyGenericParam} + tyTypeClasses:
    return typeRel(c, f, lastSon(a))

  template bindingRet(res) =
    if doBind:
      let bound = aOrig.skipTypes({tyRange}).skipIntLit
      put(c, f, bound)
    return res

  template considerPreviousT(body: untyped) =
    var prev = PType(idTableGet(c.bindings, f))
    if prev == nil: body
    else: return typeRel(c, prev, a)

  case a.kind
  of tyOr:
    # seq[int|string] vs seq[number]
    # both int and string must match against number
    # but ensure that '[T: A|A]' matches as good as '[T: A]' (bug #2219):
    result = isGeneric
    for branch in a.sons:
      let x = typeRel(c, f, branch, false)
      if x == isNone: return isNone
      if x < result: result = x

  of tyAnd:
    # seq[Sortable and Iterable] vs seq[Sortable]
    # only one match is enough
    for branch in a.sons:
      let x = typeRel(c, f, branch, false)
      if x != isNone:
        return if x >= isGeneric: isGeneric else: x
    result = isNone

  of tyNot:
    case f.kind
    of tyNot:
      # seq[!int] vs seq[!number]
      # seq[float] matches the first, but not the second
      # we must turn the problem around:
      # is number a subset of int?
      return typeRel(c, a.lastSon, f.lastSon)

    else:
      # negative type classes are essentially infinite,
      # so only the `any` type class is their superset
      return if f.kind == tyAnything: isGeneric
             else: isNone

  of tyAnything:
    return if f.kind == tyAnything: isGeneric
           else: isNone

  of tyUserTypeClass, tyUserTypeClassInst:
    # consider this: 'var g: Node' *within* a concept where 'Node'
    # is a concept too (tgraph)
    let x = typeRel(c, a, f, false)
    if x >= isGeneric:
      return isGeneric
  else: discard

  case f.kind
  of tyEnum:
    if a.kind == f.kind and sameEnumTypes(f, a): result = isEqual
    elif sameEnumTypes(f, skipTypes(a, {tyRange})): result = isSubtype
  of tyBool, tyChar:
    if a.kind == f.kind: result = isEqual
    elif skipTypes(a, {tyRange}).kind == f.kind: result = isSubtype
  of tyRange:
    if a.kind == f.kind:
      if f.base.kind == tyNone: return isGeneric
      result = typeRel(c, base(f), base(a))
      # bugfix: accept integer conversions here
      #if result < isGeneric: result = isNone
      if result notin {isNone, isGeneric}:
        # resolve any late-bound static expressions
        # that may appear in the range:
        for i in 0..1:
          if f.n[i].kind == nkStaticExpr:
            f.n.sons[i] = tryResolvingStaticExpr(c, f.n[i])
        result = typeRangeRel(f, a)
    else:
      if skipTypes(f, {tyRange}).kind == a.kind:
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
    if aOrig.kind == tyVar: result = typeRel(c, f.base, aOrig.base)
    else: result = typeRel(c, f.base, aOrig)
    subtypeCheck()
  of tyArray:
    case a.kind
    of tyArray:
      var fRange = f.sons[0]
      if fRange.kind == tyGenericParam:
        var prev = PType(idTableGet(c.bindings, fRange))
        if prev == nil:
          put(c, fRange, a.sons[0])
          fRange = a
        else:
          fRange = prev
      result = typeRel(c, f.sons[1], a.sons[1])
      if result < isGeneric: return isNone
      if rangeHasStaticIf(fRange):
        if tfUnresolved in fRange.flags:
          # This is a range from an array instantiated with a generic
          # static param. We must extract the static param here and bind
          # it to the size of the currently supplied array.
          var
            rangeStaticT = fRange.getStaticTypeFromRange
            replacementT = newTypeWithSons(c.c, tyStatic, @[tyInt.getSysType])
            inputUpperBound = a.sons[0].n[1].intVal
          # we must correct for the off-by-one discrepancy between
          # ranges and static params:
          replacementT.n = newIntNode(nkIntLit, inputUpperBound + 1)
          put(c, rangeStaticT, replacementT)
          return isGeneric

        let len = tryResolvingStaticExpr(c, fRange.n[1])
        if len.kind == nkIntLit and len.intVal+1 == lengthOrd(a):
          return # if we get this far, the result is already good
        else:
          return isNone
      elif lengthOrd(fRange) != lengthOrd(a):
        result = isNone
    else: discard
  of tyOpenArray, tyVarargs:
    # varargs[expr] is special too but handled earlier. So we only need to
    # handle varargs[stmt] which is the same as varargs[typed]:
    if f.kind == tyVarargs:
      if tfOldSchoolExprStmt in f.sons[0].flags:
        if f.sons[0].kind == tyExpr: return
      elif f.sons[0].kind == tyStmt: return
    case a.kind
    of tyOpenArray, tyVarargs:
      result = typeRel(c, base(f), base(a))
      if result < isGeneric: result = isNone
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
    of tyString:
      if f.kind == tyOpenArray:
        if f.sons[0].kind == tyChar:
          result = isConvertible
        elif f.sons[0].kind == tyGenericParam and a.len > 0 and
            typeRel(c, base(f), base(a)) >= isGeneric:
          result = isConvertible
    else: discard
  of tySequence:
    case a.kind
    of tySequence:
      if (f.sons[0].kind != tyGenericParam) and (a.sons[0].kind == tyEmpty):
        result = isSubtype
      else:
        result = typeRel(c, f.sons[0], a.sons[0])
        if result < isGeneric: result = isNone
        elif tfNotNil in f.flags and tfNotNil notin a.flags:
          result = isNilConversion
    of tyNil: result = f.allowsNil
    else: discard
  of tyOrdinal:
    if isOrdinalType(a):
      var x = if a.kind == tyOrdinal: a.sons[0] else: a
      if f.sons[0].kind == tyNone:
        result = isGeneric
      else:
        result = typeRel(c, f.sons[0], x)
        if result < isGeneric: result = isNone
    elif a.kind == tyGenericParam:
      result = isGeneric
  of tyForward: internalError("forward type in typeRel()")
  of tyNil:
    if a.kind == f.kind: result = isEqual
  of tyTuple:
    if a.kind == tyTuple: result = recordRel(c, f, a)
  of tyObject:
    if a.kind == tyObject:
      if sameObjectTypes(f, a):
        result = isEqual
        # elif tfHasMeta in f.flags: result = recordRel(c, f, a)
      else:
        var depth = isObjectSubtype(c, a, f, nil)
        if depth > 0:
          inc(c.inheritancePenalty, depth)
          result = isSubtype
  of tyDistinct:
    if a.kind == tyDistinct:
      if sameDistinctTypes(f, a): result = isEqual
      elif f.base.kind == tyAnything: result = isGeneric
      elif c.coerceDistincts: result = typeRel(c, f.base, a)
    elif a.kind == tyNil and f.base.kind in NilableTypes:
      result = f.allowsNil
    elif c.coerceDistincts: result = typeRel(c, f.base, a)
  of tySet:
    if a.kind == tySet:
      if f.sons[0].kind != tyGenericParam and a.sons[0].kind == tyEmpty:
        result = isSubtype
      else:
        result = typeRel(c, f.sons[0], a.sons[0])
        if result <= isConvertible:
          result = isNone     # BUGFIX!
  of tyPtr, tyRef:
    if a.kind == f.kind:
      # ptr[R, T] can be passed to ptr[T], but not the other way round:
      if a.len < f.len: return isNone
      for i in 0..f.len-2:
        if typeRel(c, f.sons[i], a.sons[i]) == isNone: return isNone
      result = typeRel(c, f.lastSon, a.lastSon)
      subtypeCheck()
      if result <= isConvertible: result = isNone
      elif tfNotNil in f.flags and tfNotNil notin a.flags:
        result = isNilConversion
    elif a.kind == tyNil: result = f.allowsNil
    else: discard
  of tyProc:
    result = procTypeRel(c, f, a)
    if result != isNone and tfNotNil in f.flags and tfNotNil notin a.flags:
      result = isNilConversion
  of tyPointer:
    case a.kind
    of tyPointer:
      if tfNotNil in f.flags and tfNotNil notin a.flags:
        result = isNilConversion
      else:
        result = isEqual
    of tyNil: result = f.allowsNil
    of tyProc:
      if a.callConv != ccClosure: result = isConvertible
    of tyPtr:
      # 'pointer' is NOT compatible to regionized pointers
      # so 'dealloc(regionPtr)' fails:
      if a.len == 1: result = isConvertible
    of tyCString: result = isConvertible
    else: discard
  of tyString:
    case a.kind
    of tyString:
      if tfNotNil in f.flags and tfNotNil notin a.flags:
        result = isNilConversion
      else:
        result = isEqual
    of tyNil: result = f.allowsNil
    else: discard
  of tyCString:
    # conversion from string to cstring is automatic:
    case a.kind
    of tyCString:
      if tfNotNil in f.flags and tfNotNil notin a.flags:
        result = isNilConversion
      else:
        result = isEqual
    of tyNil: result = f.allowsNil
    of tyString: result = isConvertible
    of tyPtr:
      # ptr[Tag, char] is not convertible to 'cstring' for now:
      if a.len == 1 and a.sons[0].kind == tyChar: result = isConvertible
    of tyArray:
      if (firstOrd(a.sons[0]) == 0) and
          (skipTypes(a.sons[0], {tyRange}).kind in {tyInt..tyInt64}) and
          (a.sons[1].kind == tyChar):
        result = isConvertible
    else: discard

  of tyEmpty, tyVoid:
    if a.kind == f.kind: result = isEqual

  of tyGenericInst, tyAlias:
    result = typeRel(c, lastSon(f), a)

  of tyGenericBody:
    considerPreviousT:
      if a.kind == tyGenericInst and a.sons[0] == f:
        bindingRet isGeneric
      let ff = lastSon(f)
      if ff != nil:
        result = typeRel(c, ff, a)

  of tyGenericInvocation:
    var x = a.skipGenericAlias
    var depth = 0
    if x.kind == tyGenericInvocation or f.sons[0].kind != tyGenericBody:
      #InternalError("typeRel: tyGenericInvocation -> tyGenericInvocation")
      # simply no match for now:
      discard
    elif x.kind == tyGenericInst and
          ((f.sons[0] == x.sons[0]) or isGenericSubtype(x, f, depth)) and
          (sonsLen(x) - 1 == sonsLen(f)):
      for i in countup(1, sonsLen(f) - 1):
        if x.sons[i].kind == tyGenericParam:
          internalError("wrong instantiated type!")
        elif typeRel(c, f.sons[i], x.sons[i]) <= isSubtype:
          # Workaround for regression #4589
          if f.sons[i].kind != tyTypeDesc: return
      c.inheritancePenalty += depth
      result = isGeneric
    else:
      let genericBody = f.sons[0]
      var askip = skippedNone
      var fskip = skippedNone
      let aobj = x.skipToObject(askip)
      let fobj = genericBody.lastSon.skipToObject(fskip)
      var depth = -1
      if fobj != nil and aobj != nil and askip == fskip:
        depth = isObjectSubtype(c, aobj, fobj, f)
      result = typeRel(c, genericBody, x)
      if result != isNone:
        # see tests/generics/tgeneric3.nim for an example that triggers this
        # piece of code:
        #
        # proc internalFind[T,D](n: PNode[T,D], key: T): ref TItem[T,D]
        # proc internalPut[T,D](ANode: ref TNode[T,D], Akey: T, Avalue: D,
        #                       Oldvalue: var D): ref TNode[T,D]
        # var root = internalPut[int, int](nil, 312, 312, oldvalue)
        # var it1 = internalFind(root, 312) # cannot instantiate: 'D'
        #
        # we steal the generic parameters from the tyGenericBody:
        for i in countup(1, sonsLen(f) - 1):
          let x = PType(idTableGet(c.bindings, genericBody.sons[i-1]))
          if x == nil:
            discard "maybe fine (for eg. a==tyNil)"
          elif x.kind in {tyGenericInvocation, tyGenericParam}:
            internalError("wrong instantiated type!")
          else:
            put(c, f.sons[i], x)

      if depth >= 0:
        c.inheritancePenalty += depth
        # bug #4863: We still need to bind generic alias crap, so
        # we cannot return immediately:
        result = if depth == 0: isGeneric else: isSubtype
  of tyAnd:
    considerPreviousT:
      result = isEqual
      for branch in f.sons:
        let x = typeRel(c, branch, aOrig)
        if x < isSubtype: return isNone
        # 'and' implies minimum matching result:
        if x < result: result = x
      if result > isGeneric: result = isGeneric
      bindingRet result

  of tyOr:
    considerPreviousT:
      result = isNone
      for branch in f.sons:
        let x = typeRel(c, branch, aOrig)
        # 'or' implies maximum matching result:
        if x > result: result = x
      if result >= isSubtype:
        if result > isGeneric: result = isGeneric
        bindingRet result
      else:
        result = isNone

  of tyNot:
    considerPreviousT:
      for branch in f.sons:
        if typeRel(c, branch, aOrig) != isNone:
          return isNone

      bindingRet isGeneric

  of tyAnything:
    considerPreviousT:
      var concrete = concreteType(c, a)
      if concrete != nil and doBind:
        put(c, f, concrete)
      return isGeneric

  of tyBuiltInTypeClass:
    considerPreviousT:
      let targetKind = f.sons[0].kind
      if targetKind == a.skipTypes({tyRange, tyGenericInst, tyBuiltInTypeClass, tyAlias}).kind or
         (targetKind in {tyProc, tyPointer} and a.kind == tyNil):
        put(c, f, a)
        return isGeneric
      else:
        return isNone

  of tyUserTypeClass, tyUserTypeClassInst:
    considerPreviousT:
      result = matchUserTypeClass(c.c, c, f, aOrig)
      if result == isGeneric:
        put(c, f, a)

  of tyCompositeTypeClass:
    considerPreviousT:
      let roota = a.skipGenericAlias
      let rootf = f.lastSon.skipGenericAlias
      if a.kind == tyGenericInst and roota.base == rootf.base:
        for i in 1 .. rootf.sonsLen-2:
          let ff = rootf.sons[i]
          let aa = roota.sons[i]
          result = typeRel(c, ff, aa)
          if result == isNone: return
          if ff.kind == tyRange and result != isEqual: return isNone
      else:
        result = typeRel(c, rootf.lastSon, a)
      if result != isNone:
        put(c, f, a)
        result = isGeneric
  of tyGenericParam:
    var x = PType(idTableGet(c.bindings, f))
    if x == nil:
      if c.callee.kind == tyGenericBody and
         f.kind == tyGenericParam and not c.typedescMatched:
        # XXX: The fact that generic types currently use tyGenericParam for
        # their parameters is really a misnomer. tyGenericParam means "match
        # any value" and what we need is "match any type", which can be encoded
        # by a tyTypeDesc params. Unfortunately, this requires more substantial
        # changes in semtypinst and elsewhere.
        if tfWildcard in a.flags:
          result = isGeneric
        elif a.kind == tyTypeDesc:
          if f.sonsLen == 0:
            result = isGeneric
          else:
            internalAssert a.sons != nil and a.sons.len > 0
            c.typedescMatched = true
            var aa = a
            while aa.kind in {tyTypeDesc, tyGenericParam} and
                aa.len > 0:
              aa = lastSon(aa)
            result = typeRel(c, f.base, aa)
            if result > isGeneric: result = isGeneric
        else:
          result = isNone
      else:
        if f.sonsLen > 0 and f.sons[0].kind != tyNone:
          result = typeRel(c, f.lastSon, a)
          if doBind and result notin {isNone, isGeneric}:
            let concrete = concreteType(c, a)
            if concrete == nil: return isNone
            put(c, f, concrete)
        else:
          result = isGeneric

      if result == isGeneric:
        var concrete = a
        if tfWildcard in a.flags:
          a.sym.kind = skType
          a.flags.excl tfWildcard
        else:
          concrete = concreteType(c, a)
          if concrete == nil:
            return isNone
        if doBind:
          put(c, f, concrete)
      elif result > isGeneric:
        result = isGeneric
    elif a.kind == tyEmpty:
      result = isGeneric
    elif x.kind == tyGenericParam:
      result = isGeneric
    else:
      result = typeRel(c, x, a) # check if it fits
      if result > isGeneric: result = isGeneric

  of tyStatic:
    let prev = PType(idTableGet(c.bindings, f))
    if prev == nil:
      if aOrig.kind == tyStatic:
        result = typeRel(c, f.lastSon, a)
        if result != isNone and f.n != nil:
          if not exprStructuralEquivalent(f.n, aOrig.n):
            result = isNone
        if result != isNone: put(c, f, aOrig)
      else:
        result = isNone
    elif prev.kind == tyStatic:
      if aOrig.kind == tyStatic:
        result = typeRel(c, prev.lastSon, a)
        if result != isNone and prev.n != nil:
          if not exprStructuralEquivalent(prev.n, aOrig.n):
            result = isNone
      else: result = isNone
    else:
      # XXX endless recursion?
      #result = typeRel(c, prev, aOrig)
      result = isNone
  of tyTypeDesc:
    var prev = PType(idTableGet(c.bindings, f))
    if prev == nil:
      # proc foo(T: typedesc, x: T)
      # when `f` is an unresolved typedesc, `a` could be any
      # type, so we should not perform this check earlier
      if a.kind != tyTypeDesc: return isNone

      if f.base.kind == tyNone:
        result = isGeneric
      else:
        result = typeRel(c, f.base, a.base)

      if result != isNone:
        put(c, f, a)
    else:
      if tfUnresolved in f.flags:
        result = typeRel(c, prev.base, a)
      elif a.kind == tyTypeDesc:
        result = typeRel(c, prev.base, a.base)
      else:
        result = isNone

  of tyStmt:
    if aOrig != nil and tfOldSchoolExprStmt notin f.flags:
      put(c, f, aOrig)
    result = isGeneric

  of tyProxy:
    result = isEqual

  of tyFromExpr:
    # fix the expression, so it contains the already instantiated types
    if f.n == nil or f.n.kind == nkEmpty: return isGeneric
    let reevaluated = tryResolvingStaticExpr(c, f.n)
    case reevaluated.typ.kind
    of tyTypeDesc:
      result = typeRel(c, a, reevaluated.typ.base)
    of tyStatic:
      result = typeRel(c, a, reevaluated.typ.base)
      if result != isNone and reevaluated.typ.n != nil:
        if not exprStructuralEquivalent(aOrig.n, reevaluated.typ.n):
          result = isNone
    else:
      localError(f.n.info, errTypeExpected)
      result = isNone

  of tyNone:
    if a.kind == tyNone: result = isEqual
  else:
    internalError " unknown type kind " & $f.kind

proc cmpTypes*(c: PContext, f, a: PType): TTypeRelation =
  var m: TCandidate
  initCandidate(c, m, f)
  result = typeRel(m, f, a)

proc getInstantiatedType(c: PContext, arg: PNode, m: TCandidate,
                         f: PType): PType =
  result = PType(idTableGet(m.bindings, f))
  if result == nil:
    result = generateTypeInstance(c, m.bindings, arg, f)
  if result == nil:
    internalError(arg.info, "getInstantiatedType")
    result = errorType(c)

proc implicitConv(kind: TNodeKind, f: PType, arg: PNode, m: TCandidate,
                  c: PContext): PNode =
  result = newNodeI(kind, arg.info)
  if containsGenericType(f):
    if not m.hasFauxMatch:
      result.typ = getInstantiatedType(c, arg, m, f)
    else:
      result.typ = errorType(c)
  else:
    result.typ = f
  if result.typ == nil: internalError(arg.info, "implicitConv")
  addSon(result, ast.emptyNode)
  addSon(result, arg)

proc userConvMatch(c: PContext, m: var TCandidate, f, a: PType,
                   arg: PNode): PNode =
  result = nil
  for i in countup(0, len(c.converters) - 1):
    var src = c.converters[i].typ.sons[1]
    var dest = c.converters[i].typ.sons[0]
    # for generic type converters we need to check 'src <- a' before
    # 'f <- dest' in order to not break the unification:
    # see tests/tgenericconverter:
    let srca = typeRel(m, src, a)
    if srca notin {isEqual, isGeneric}: continue

    let destIsGeneric = containsGenericType(dest)
    if destIsGeneric:
      dest = generateTypeInstance(c, m.bindings, arg, dest)
    let fdest = typeRel(m, f, dest)
    if fdest in {isEqual, isGeneric}:
      markUsed(arg.info, c.converters[i], c.graph.usageSym)
      var s = newSymNode(c.converters[i])
      s.typ = c.converters[i].typ
      s.info = arg.info
      result = newNodeIT(nkHiddenCallConv, arg.info, dest)
      addSon(result, s)
      addSon(result, copyTree(arg))
      inc(m.convMatches)
      m.genericConverter = srca == isGeneric or destIsGeneric
      return result

proc localConvMatch(c: PContext, m: var TCandidate, f, a: PType,
                    arg: PNode): PNode =
  # arg.typ can be nil in 'suggest':
  if isNil(arg.typ): return nil

  # sem'checking for 'echo' needs to be re-entrant:
  # XXX we will revisit this issue after 0.10.2 is released
  if f == arg.typ and arg.kind == nkHiddenStdConv: return arg

  var call = newNodeI(nkCall, arg.info)
  call.add(f.n.copyTree)
  call.add(arg.copyTree)
  result = c.semExpr(c, call)
  if result != nil:
    if result.typ == nil: return nil
    # resulting type must be consistent with the other arguments:
    var r = typeRel(m, f.sons[0], result.typ)
    if r < isGeneric: return nil
    if result.kind == nkCall: result.kind = nkHiddenCallConv
    inc(m.convMatches)
    if r == isGeneric:
      result.typ = getInstantiatedType(c, arg, m, base(f))
    m.baseTypeMatch = true

proc incMatches(m: var TCandidate; r: TTypeRelation; convMatch = 1) =
  case r
  of isConvertible, isIntConv: inc(m.convMatches, convMatch)
  of isSubtype, isSubrange: inc(m.subtypeMatches)
  of isGeneric, isInferred, isBothMetaConvertible: inc(m.genericMatches)
  of isFromIntLit: inc(m.intConvMatches, 256)
  of isInferredConvertible:
    inc(m.convMatches)
  of isEqual: inc(m.exactMatches)
  of isNone: discard

proc paramTypesMatchAux(m: var TCandidate, f, argType: PType,
                        argSemantized, argOrig: PNode): PNode =
  var
    fMaybeStatic = f.skipTypes({tyDistinct})
    arg = argSemantized
    argType = argType
    c = m.c

  if tfHasStatic in fMaybeStatic.flags:
    # XXX: When implicit statics are the default
    # this will be done earlier - we just have to
    # make sure that static types enter here

    # XXX: weaken tyGenericParam and call it tyGenericPlaceholder
    # and finally start using tyTypedesc for generic types properly.
    if argType.kind == tyGenericParam and tfWildcard in argType.flags:
      argType.assignType(f)
      # put(m.bindings, f, argType)
      return argSemantized

    if argType.kind == tyStatic:
      if m.callee.kind == tyGenericBody and
         argType.n == nil and
         tfGenericTypeParam notin argType.flags:
        return newNodeIT(nkType, argOrig.info, makeTypeFromExpr(c, arg))
    else:
      var evaluated = c.semTryConstExpr(c, arg)
      if evaluated != nil:
        arg.typ = newTypeS(tyStatic, c)
        arg.typ.sons = @[evaluated.typ]
        arg.typ.n = evaluated
        argType = arg.typ

  var a = argType
  var r = typeRel(m, f, a)

  if r != isNone and m.calleeSym != nil and
     m.calleeSym.kind in {skMacro, skTemplate}:
    # XXX: duplicating this is ugly, but we cannot (!) move this
    # directly into typeRel using return-like templates
    incMatches(m, r)
    if f.kind == tyStmt:
      return arg
    elif f.kind == tyTypeDesc:
      return arg
    elif f.kind == tyStatic:
      return arg.typ.n
    else:
      return argSemantized # argOrig

  # If r == isBothMetaConvertible then we rerun typeRel.
  # bothMetaCounter is for safety to avoid any infinite loop,
  #  I don't have any example when it is needed.
  # lastBindingsLenth is used to check whether m.bindings remains the same,
  #  because in that case there is no point in continuing.
  var bothMetaCounter = 0
  var lastBindingsLength = -1
  while r == isBothMetaConvertible and
      lastBindingsLength != m.bindings.counter and
      bothMetaCounter < 100:
    lastBindingsLength = m.bindings.counter
    inc(bothMetaCounter)
    if arg.kind in {nkProcDef, nkIteratorDef} + nkLambdaKinds:
      result = c.semInferredLambda(c, m.bindings, arg)
    elif arg.kind != nkSym:
      return nil
    else:
      let inferred = c.semGenerateInstance(c, arg.sym, m.bindings, arg.info)
      result = newSymNode(inferred, arg.info)
    inc(m.convMatches)
    arg = result
    r = typeRel(m, f, arg.typ)

  case r
  of isConvertible:
    inc(m.convMatches)
    result = implicitConv(nkHiddenStdConv, f, arg, m, c)
  of isIntConv:
    # I'm too lazy to introduce another ``*matches`` field, so we conflate
    # ``isIntConv`` and ``isIntLit`` here:
    inc(m.intConvMatches)
    result = implicitConv(nkHiddenStdConv, f, arg, m, c)
  of isSubtype:
    inc(m.subtypeMatches)
    if f.kind == tyTypeDesc:
      result = arg
    else:
      result = implicitConv(nkHiddenSubConv, f, arg, m, c)
  of isSubrange:
    inc(m.subtypeMatches)
    if f.kind == tyVar:
      result = arg
    else:
      result = implicitConv(nkHiddenStdConv, f, arg, m, c)
  of isInferred, isInferredConvertible:
    if arg.kind in {nkProcDef, nkIteratorDef} + nkLambdaKinds:
      result = c.semInferredLambda(c, m.bindings, arg)
    elif arg.kind != nkSym:
      return nil
    else:
      let inferred = c.semGenerateInstance(c, arg.sym, m.bindings, arg.info)
      result = newSymNode(inferred, arg.info)
    if r == isInferredConvertible:
      inc(m.convMatches)
      result = implicitConv(nkHiddenStdConv, f, result, m, c)
    else:
      inc(m.genericMatches)
  of isGeneric:
    inc(m.genericMatches)
    if arg.typ == nil:
      result = arg
    elif skipTypes(arg.typ, abstractVar-{tyTypeDesc}).kind == tyTuple:
      result = implicitConv(nkHiddenSubConv, f, arg, m, c)
    elif arg.typ.isEmptyContainer:
      result = arg.copyTree
      result.typ = getInstantiatedType(c, arg, m, f)
    else:
      result = arg
  of isBothMetaConvertible:
    # This is the result for the 101th time.
    result = nil
  of isFromIntLit:
    # too lazy to introduce another ``*matches`` field, so we conflate
    # ``isIntConv`` and ``isIntLit`` here:
    inc(m.intConvMatches, 256)
    result = implicitConv(nkHiddenStdConv, f, arg, m, c)
  of isEqual:
    inc(m.exactMatches)
    result = arg
    if skipTypes(f, abstractVar-{tyTypeDesc}).kind in {tyTuple}:
      result = implicitConv(nkHiddenSubConv, f, arg, m, c)
  of isNone:
    # do not do this in ``typeRel`` as it then can't infer T in ``ref T``:
    if a.kind in {tyProxy, tyUnknown}:
      inc(m.genericMatches)
      m.fauxMatch = a.kind
      return arg
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
          if result != nil: m.baseTypeMatch = true

proc paramTypesMatch*(m: var TCandidate, f, a: PType,
                      arg, argOrig: PNode): PNode =
  if arg == nil or arg.kind notin nkSymChoices:
    result = paramTypesMatchAux(m, f, a, arg, argOrig)
  else:
    # CAUTION: The order depends on the used hashing scheme. Thus it is
    # incorrect to simply use the first fitting match. However, to implement
    # this correctly is inefficient. We have to copy `m` here to be able to
    # roll back the side effects of the unification algorithm.
    let c = m.c
    var x, y, z: TCandidate
    initCandidate(c, x, m.callee)
    initCandidate(c, y, m.callee)
    initCandidate(c, z, m.callee)
    x.calleeSym = m.calleeSym
    y.calleeSym = m.calleeSym
    z.calleeSym = m.calleeSym
    var best = -1
    for i in countup(0, sonsLen(arg) - 1):
      if arg.sons[i].sym.kind in {skProc, skMethod, skConverter, skIterator}:
        copyCandidate(z, m)
        z.callee = arg.sons[i].typ
        if tfUnresolved in z.callee.flags: continue
        z.calleeSym = arg.sons[i].sym
        #if arg.sons[i].sym.name.s == "cmp":
        #  ggDebug = true
        #  echo "CALLLEEEEEEEE A ", typeToString(z.callee)
        # XXX this is still all wrong: (T, T) should be 2 generic matches
        # and  (int, int) 2 exact matches, etc. Essentially you cannot call
        # typeRel here and expect things to work!
        let r = typeRel(z, f, arg.sons[i].typ)
        incMatches(z, r, 2)
        #if arg.sons[i].sym.name.s == "cmp": # and arg.info.line == 606:
        #  echo "M ", r, " ", arg.info, " ", typeToString(arg.sons[i].sym.typ)
        #  writeMatches(z)
        if r != isNone:
          z.state = csMatch
          case x.state
          of csEmpty, csNoMatch:
            x = z
            best = i
          of csMatch:
            let cmp = cmpCandidates(x, z)
            if cmp < 0:
              best = i
              x = z
            elif cmp == 0:
              y = z           # z is as good as x
    if x.state == csEmpty:
      result = nil
    elif y.state == csMatch and cmpCandidates(x, y) == 0:
      if x.state != csMatch:
        internalError(arg.info, "x.state is not csMatch")
      # ambiguous: more than one symbol fits!
      # See tsymchoice_for_expr as an example. 'f.kind == tyExpr' should match
      # anyway:
      if f.kind == tyExpr: result = arg
      else: result = nil
    else:
      # only one valid interpretation found:
      markUsed(arg.info, arg.sons[best].sym, m.c.graph.usageSym)
      styleCheckUse(arg.info, arg.sons[best].sym)
      result = paramTypesMatchAux(m, f, arg.sons[best].typ, arg.sons[best],
                                  argOrig)


proc setSon(father: PNode, at: int, son: PNode) =
  let oldLen = father.len
  if oldLen <= at:
    setLen(father.sons, at + 1)
  father.sons[at] = son
  # insert potential 'void' parameters:
  #for i in oldLen ..< at:
  #  father.sons[i] = newNodeIT(nkEmpty, son.info, getSysType(tyVoid))

# we are allowed to modify the calling node in the 'prepare*' procs:
proc prepareOperand(c: PContext; formal: PType; a: PNode): PNode =
  if formal.kind == tyExpr and formal.len != 1:
    # {tyTypeDesc, tyExpr, tyStmt, tyProxy}:
    # a.typ == nil is valid
    result = a
  elif a.typ.isNil:
    # XXX This is unsound! 'formal' can differ from overloaded routine to
    # overloaded routine!
    let flags = {efDetermineType, efAllowStmt}
                #if formal.kind == tyIter: {efDetermineType, efWantIterator}
                #else: {efDetermineType, efAllowStmt}
                #elif formal.kind == tyStmt: {efDetermineType, efWantStmt}
                #else: {efDetermineType}
    result = c.semOperand(c, a, flags)
  else:
    result = a
    considerGenSyms(c, result)

proc prepareOperand(c: PContext; a: PNode): PNode =
  if a.typ.isNil:
    result = c.semOperand(c, a, {efDetermineType})
  else:
    result = a
    considerGenSyms(c, result)

proc prepareNamedParam(a: PNode) =
  if a.sons[0].kind != nkIdent:
    var info = a.sons[0].info
    a.sons[0] = newIdentNode(considerQuotedIdent(a.sons[0]), info)

proc arrayConstr(c: PContext, n: PNode): PType =
  result = newTypeS(tyArray, c)
  rawAddSon(result, makeRangeType(c, 0, 0, n.info))
  addSonSkipIntLit(result, skipTypes(n.typ, {tyGenericInst, tyVar, tyOrdinal}))

proc arrayConstr(c: PContext, info: TLineInfo): PType =
  result = newTypeS(tyArray, c)
  rawAddSon(result, makeRangeType(c, 0, -1, info))
  rawAddSon(result, newTypeS(tyEmpty, c)) # needs an empty basetype!

proc incrIndexType(t: PType) =
  assert t.kind == tyArray
  inc t.sons[0].n.sons[1].intVal

template isVarargsUntyped(x): untyped =
  x.kind == tyVarargs and x.sons[0].kind == tyExpr and
    tfOldSchoolExprStmt notin x.sons[0].flags

proc matchesAux(c: PContext, n, nOrig: PNode,
                m: var TCandidate, marker: var IntSet) =
  template checkConstraint(n: untyped) {.dirty.} =
    if not formal.constraint.isNil:
      if matchNodeKinds(formal.constraint, n):
        # better match over other routines with no such restriction:
        inc(m.genericMatches, 100)
      else:
        m.state = csNoMatch
        return
    if formal.typ.kind == tyVar:
      if not n.isLValue:
        m.state = csNoMatch
        m.mutabilityProblem = uint8(f-1)
        return

  var
    # iterates over formal parameters
    f = if m.callee.kind != tyGenericBody: 1
        else: 0
    # iterates over the actual given arguments
    a = 1

  m.state = csMatch # until proven otherwise
  m.call = newNodeI(n.kind, n.info)
  m.call.typ = base(m.callee) # may be nil
  var formalLen = m.callee.n.len
  addSon(m.call, copyTree(n.sons[0]))
  var container: PNode = nil # constructed container
  var formal: PSym = if formalLen > 1: m.callee.n.sons[1].sym else: nil

  while a < n.len:
    if a >= formalLen-1 and formal != nil and formal.typ.isVarargsUntyped:
      incl(marker, formal.position)
      if container.isNil:
        container = newNodeIT(nkBracket, n.sons[a].info, arrayConstr(c, n.info))
        setSon(m.call, formal.position + 1, container)
      else:
        incrIndexType(container.typ)
      addSon(container, n.sons[a])
    elif n.sons[a].kind == nkExprEqExpr:
      # named param
      # check if m.callee has such a param:
      prepareNamedParam(n.sons[a])
      if n.sons[a].sons[0].kind != nkIdent:
        localError(n.sons[a].info, errNamedParamHasToBeIdent)
        m.state = csNoMatch
        return
      formal = getSymFromList(m.callee.n, n.sons[a].sons[0].ident, 1)
      if formal == nil:
        # no error message!
        m.state = csNoMatch
        return
      if containsOrIncl(marker, formal.position):
        # already in namedParams, so no match
        # we used to produce 'errCannotBindXTwice' here but see
        # bug #3836 of why that is not sound (other overload with
        # different parameter names could match later on):
        when false: localError(n.sons[a].info, errCannotBindXTwice, formal.name.s)
        m.state = csNoMatch
        return
      m.baseTypeMatch = false
      n.sons[a].sons[1] = prepareOperand(c, formal.typ, n.sons[a].sons[1])
      n.sons[a].typ = n.sons[a].sons[1].typ
      var arg = paramTypesMatch(m, formal.typ, n.sons[a].typ,
                                n.sons[a].sons[1], n.sons[a].sons[1])
      if arg == nil:
        m.state = csNoMatch
        return
      checkConstraint(n.sons[a].sons[1])
      if m.baseTypeMatch:
        #assert(container == nil)
        container = newNodeIT(nkBracket, n.sons[a].info, arrayConstr(c, arg))
        addSon(container, arg)
        setSon(m.call, formal.position + 1, container)
        if f != formalLen - 1: container = nil
      else:
        setSon(m.call, formal.position + 1, arg)
      inc f
    else:
      # unnamed param
      if f >= formalLen:
        # too many arguments?
        if tfVarargs in m.callee.flags:
          # is ok... but don't increment any counters...
          # we have no formal here to snoop at:
          n.sons[a] = prepareOperand(c, n.sons[a])
          if skipTypes(n.sons[a].typ, abstractVar-{tyTypeDesc}).kind==tyString:
            addSon(m.call, implicitConv(nkHiddenStdConv, getSysType(tyCString),
                                        copyTree(n.sons[a]), m, c))
          else:
            addSon(m.call, copyTree(n.sons[a]))
        elif formal != nil and formal.typ.kind == tyVarargs:
          # beware of the side-effects in 'prepareOperand'! So only do it for
          # varargs matching. See tests/metatype/tstatic_overloading.
          m.baseTypeMatch = false
          incl(marker, formal.position)
          n.sons[a] = prepareOperand(c, formal.typ, n.sons[a])
          var arg = paramTypesMatch(m, formal.typ, n.sons[a].typ,
                                    n.sons[a], nOrig.sons[a])
          if arg != nil and m.baseTypeMatch and container != nil:
            addSon(container, arg)
            incrIndexType(container.typ)
            checkConstraint(n.sons[a])
          else:
            m.state = csNoMatch
            return
        else:
          m.state = csNoMatch
          return
      else:
        if m.callee.n.sons[f].kind != nkSym:
          internalError(n.sons[a].info, "matches")
          return
        formal = m.callee.n.sons[f].sym
        if containsOrIncl(marker, formal.position) and container.isNil:
          # already in namedParams: (see above remark)
          when false: localError(n.sons[a].info, errCannotBindXTwice, formal.name.s)
          m.state = csNoMatch
          return

        if formal.typ.isVarargsUntyped:
          if container.isNil:
            container = newNodeIT(nkBracket, n.sons[a].info, arrayConstr(c, n.info))
            setSon(m.call, formal.position + 1, container)
          else:
            incrIndexType(container.typ)
          addSon(container, n.sons[a])
        else:
          m.baseTypeMatch = false
          n.sons[a] = prepareOperand(c, formal.typ, n.sons[a])
          var arg = paramTypesMatch(m, formal.typ, n.sons[a].typ,
                                    n.sons[a], nOrig.sons[a])
          if arg == nil:
            m.state = csNoMatch
            return
          if m.baseTypeMatch:
            #assert(container == nil)
            if container.isNil:
              container = newNodeIT(nkBracket, n.sons[a].info, arrayConstr(c, arg))
            else:
              incrIndexType(container.typ)
            addSon(container, arg)
            setSon(m.call, formal.position + 1,
                   implicitConv(nkHiddenStdConv, formal.typ, container, m, c))
            #if f != formalLen - 1: container = nil

            # pick the formal from the end, so that 'x, y, varargs, z' works:
            f = max(f, formalLen - n.len + a + 1)
          else:
            setSon(m.call, formal.position + 1, arg)
            inc(f)
            container = nil
        checkConstraint(n.sons[a])
    inc(a)

proc semFinishOperands*(c: PContext, n: PNode) =
  # this needs to be called to ensure that after overloading resolution every
  # argument has been sem'checked:
  for i in 1 .. <n.len:
    n.sons[i] = prepareOperand(c, n.sons[i])

proc partialMatch*(c: PContext, n, nOrig: PNode, m: var TCandidate) =
  # for 'suggest' support:
  var marker = initIntSet()
  matchesAux(c, n, nOrig, m, marker)

proc matches*(c: PContext, n, nOrig: PNode, m: var TCandidate) =
  if m.magic in {mArrGet, mArrPut}:
    m.state = csMatch
    m.call = n
    return
  var marker = initIntSet()
  matchesAux(c, n, nOrig, m, marker)
  if m.state == csNoMatch: return
  # check that every formal parameter got a value:
  var f = 1
  while f < sonsLen(m.callee.n):
    var formal = m.callee.n.sons[f].sym
    if not containsOrIncl(marker, formal.position):
      if formal.ast == nil:
        if formal.typ.kind == tyVarargs:
          var container = newNodeIT(nkBracket, n.info, arrayConstr(c, n.info))
          setSon(m.call, formal.position + 1,
                 implicitConv(nkHiddenStdConv, formal.typ, container, m, c))
        else:
          # no default value
          m.state = csNoMatch
          break
      else:
        # use default value:
        var def = copyTree(formal.ast)
        if def.kind == nkNilLit:
          def = implicitConv(nkHiddenStdConv, formal.typ, def, m, c)
        setSon(m.call, formal.position + 1, def)
    inc(f)

proc argtypeMatches*(c: PContext, f, a: PType): bool =
  var m: TCandidate
  initCandidate(c, m, f)
  let res = paramTypesMatch(m, f, a, ast.emptyNode, nil)
  #instantiateGenericConverters(c, res, m)
  # XXX this is used by patterns.nim too; I think it's better to not
  # instantiate generic converters for that
  result = res != nil

proc instTypeBoundOp*(c: PContext; dc: PSym; t: PType; info: TLineInfo;
                      op: TTypeAttachedOp; col: int): PSym {.procvar.} =
  var m: TCandidate
  initCandidate(c, m, dc.typ)
  if col >= dc.typ.len:
    localError(info, errGenerated, "cannot instantiate '" & dc.name.s & "'")
    return nil
  var f = dc.typ.sons[col]
  if op == attachedDeepCopy:
    if f.kind in {tyRef, tyPtr}: f = f.lastSon
  else:
    if f.kind == tyVar: f = f.lastSon
  if typeRel(m, f, t) == isNone:
    localError(info, errGenerated, "cannot instantiate '" & dc.name.s & "'")
  else:
    result = c.semGenerateInstance(c, dc, m.bindings, info)
    assert sfFromGeneric in result.flags

include suggest

when not declared(tests):
  template tests(s: untyped) = discard

tests:
  var dummyOwner = newSym(skModule, getIdent("test_module"), nil, UnknownLineInfo())

  proc `|` (t1, t2: PType): PType =
    result = newType(tyOr, dummyOwner)
    result.rawAddSon(t1)
    result.rawAddSon(t2)

  proc `&` (t1, t2: PType): PType =
    result = newType(tyAnd, dummyOwner)
    result.rawAddSon(t1)
    result.rawAddSon(t2)

  proc `!` (t: PType): PType =
    result = newType(tyNot, dummyOwner)
    result.rawAddSon(t)

  proc seq(t: PType): PType =
    result = newType(tySequence, dummyOwner)
    result.rawAddSon(t)

  proc array(x: int, t: PType): PType =
    result = newType(tyArray, dummyOwner)

    var n = newNodeI(nkRange, UnknownLineInfo())
    addSon(n, newIntNode(nkIntLit, 0))
    addSon(n, newIntNode(nkIntLit, x))
    let range = newType(tyRange, dummyOwner)

    result.rawAddSon(range)
    result.rawAddSon(t)

  suite "type classes":
    let
      int = newType(tyInt, dummyOwner)
      float = newType(tyFloat, dummyOwner)
      string = newType(tyString, dummyOwner)
      ordinal = newType(tyOrdinal, dummyOwner)
      any = newType(tyAnything, dummyOwner)
      number = int | float

    var TFoo = newType(tyObject, dummyOwner)
    TFoo.sym = newSym(skType, getIdent"TFoo", dummyOwner, UnknownLineInfo())

    var T1 = newType(tyGenericParam, dummyOwner)
    T1.sym = newSym(skType, getIdent"T1", dummyOwner, UnknownLineInfo())
    T1.sym.position = 0

    var T2 = newType(tyGenericParam, dummyOwner)
    T2.sym = newSym(skType, getIdent"T2", dummyOwner, UnknownLineInfo())
    T2.sym.position = 1

    setup:
      var c: TCandidate
      initCandidate(nil, c, nil)

    template yes(x, y) =
      test astToStr(x) & " is " & astToStr(y):
        check typeRel(c, y, x) == isGeneric

    template no(x, y) =
      test astToStr(x) & " is not " & astToStr(y):
        check typeRel(c, y, x) == isNone

    yes seq(any), array(10, int) | seq(any)
    # Sure, seq[any] is directly included

    yes seq(int), seq(any)
    yes seq(int), seq(number)
    # Sure, the int sequence is certainly
    # part of the number sequences (and all sequences)

    no seq(any), seq(float)
    # Nope, seq[any] includes types that are not seq[float] (e.g. seq[int])

    yes seq(int|string), seq(any)
    # Sure

    yes seq(int&string), seq(any)
    # Again

    yes seq(int&string), seq(int)
    # A bit more complicated
    # seq[int&string] is not a real type, but it's analogous to
    # seq[Sortable and Iterable], which is certainly a subset of seq[Sortable]

    no seq(int|string), seq(int|float)
    # Nope, seq[string] is not included in not included in
    # the seq[int|float] set

    no seq(!(int|string)), seq(string)
    # A sequence that is neither seq[int] or seq[string]
    # is obviously not seq[string]

    no seq(!int), seq(number)
    # Now your head should start to hurt a bit
    # A sequence that is not seq[int] is not necessarily a number sequence
    # it could well be seq[string] for example

    yes seq(!(int|string)), seq(!string)
    # all sequnece types besides seq[int] and seq[string]
    # are subset of all sequence types that are not seq[string]

    no seq(!(int|string)), seq(!(string|TFoo))
    # Nope, seq[TFoo] is included in the first set, but not in the second

    no seq(!string), seq(!number)
    # Nope, seq[int] in included in the first set, but not in the second

    yes seq(!number), seq(any)
    yes seq(!int), seq(any)
    no seq(any), seq(!any)
    no seq(!int), seq(!any)

    yes int, ordinal
    no  string, ordinal

