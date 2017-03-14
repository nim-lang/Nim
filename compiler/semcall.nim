#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements semantic checking for calls.
# included from sem.nim

proc sameMethodDispatcher(a, b: PSym): bool =
  result = false
  if a.kind == skMethod and b.kind == skMethod:
    var aa = lastSon(a.ast)
    var bb = lastSon(b.ast)
    if aa.kind == nkSym and bb.kind == nkSym:
      if aa.sym == bb.sym:
        result = true
    else:
      discard
      # generics have no dispatcher yet, so we need to compare the method
      # names; however, the names are equal anyway because otherwise we
      # wouldn't even consider them to be overloaded. But even this does
      # not work reliably! See tmultim6 for an example:
      # method collide[T](a: TThing, b: TUnit[T]) is instantiated and not
      # method collide[T](a: TUnit[T], b: TThing)! This means we need to
      # *instantiate* every candidate! However, we don't keep more than 2-3
      # candidated around so we cannot implement that for now. So in order
      # to avoid subtle problems, the call remains ambiguous and needs to
      # be disambiguated by the programmer; this way the right generic is
      # instantiated.

proc determineType(c: PContext, s: PSym)

proc initCandidateSymbols(c: PContext, headSymbol: PNode,
                       initialBinding: PNode,
                       filter: TSymKinds,
                       best, alt: var TCandidate,
                       o: var TOverloadIter): seq[tuple[s: PSym, scope: int]] =
  result = @[]
  var symx = initOverloadIter(o, c, headSymbol)
  while symx != nil:
    if symx.kind in filter:
      result.add((symx, o.lastOverloadScope))
      symx = nextOverloadIter(o, c, headSymbol)
  if result.len > 0:
    initCandidate(c, best, result[0].s, initialBinding, result[0].scope)
    initCandidate(c, alt, result[0].s, initialBinding, result[0].scope)
    best.state = csNoMatch

proc pickBestCandidate(c: PContext, headSymbol: PNode,
                       n, orig: PNode,
                       initialBinding: PNode,
                       filter: TSymKinds,
                       best, alt: var TCandidate,
                       errors: var CandidateErrors) =
  var o: TOverloadIter
  var sym = initOverloadIter(o, c, headSymbol)
  var scope = o.lastOverloadScope
  # Thanks to the lazy semchecking for operands, we need to check whether
  # 'initCandidate' modifies the symbol table (via semExpr).
  # This can occur in cases like 'init(a, 1, (var b = new(Type2); b))'
  let counterInitial = c.currentScope.symbols.counter
  var syms: seq[tuple[s: PSym, scope: int]]
  var nextSymIndex = 0
  while sym != nil:
    if sym.kind in filter:
      # Initialise 'best' and 'alt' with the first available symbol
      initCandidate(c, best, sym, initialBinding, scope)
      initCandidate(c, alt, sym, initialBinding, scope)
      best.state = csNoMatch
      break
    else:
      sym = nextOverloadIter(o, c, headSymbol)
      scope = o.lastOverloadScope
  var z: TCandidate
  while sym != nil:
    if sym.kind notin filter:
      sym = nextOverloadIter(o, c, headSymbol)
      scope = o.lastOverloadScope
      continue
    determineType(c, sym)
    initCandidate(c, z, sym, initialBinding, scope)
    if c.currentScope.symbols.counter == counterInitial or syms != nil:
      matches(c, n, orig, z)
      if errors != nil:
        errors.safeAdd((sym, int z.mutabilityProblem))
        if z.errors != nil:
          for err in z.errors:
            errors.add(err)
      if z.state == csMatch:
        # little hack so that iterators are preferred over everything else:
        if sym.kind == skIterator: inc(z.exactMatches, 200)
        case best.state
        of csEmpty, csNoMatch: best = z
        of csMatch:
          var cmp = cmpCandidates(best, z)
          if cmp < 0: best = z   # x is better than the best so far
          elif cmp == 0: alt = z # x is as good as the best so far
    else:
      # Symbol table has been modified. Restart and pre-calculate all syms
      # before any further candidate init and compare. SLOW, but rare case.
      syms = initCandidateSymbols(c, headSymbol, initialBinding, filter, best, alt, o)
    if syms == nil:
      sym = nextOverloadIter(o, c, headSymbol)
      scope = o.lastOverloadScope
    elif nextSymIndex < syms.len:
      # rare case: retrieve the next pre-calculated symbol
      sym = syms[nextSymIndex].s
      scope = syms[nextSymIndex].scope
      nextSymIndex += 1
    else:
      break

proc notFoundError*(c: PContext, n: PNode, errors: CandidateErrors) =
  # Gives a detailed error message; this is separated from semOverloadedCall,
  # as semOverlodedCall is already pretty slow (and we need this information
  # only in case of an error).
  if c.compilesContextId > 0 and optReportConceptFailures notin gGlobalOptions:
    # fail fast:
    globalError(n.info, errTypeMismatch, "")
  if errors.isNil or errors.len == 0:
    localError(n.info, errExprXCannotBeCalled, n[0].renderTree)
    return

  # to avoid confusing errors like:
  #   got (SslPtr, SocketHandle)
  #   but expected one of:
  #   openssl.SSL_set_fd(ssl: SslPtr, fd: SocketHandle): cint
  # we do a pre-analysis. If all types produce the same string, we will add
  # module information.
  let proto = describeArgs(c, n, 1, preferName)

  var prefer = preferName
  for err, mut in items(errors):
    var errProto = ""
    let n = err.typ.n
    for i in countup(1, n.len - 1):
      var p = n.sons[i]
      if p.kind == nkSym:
        add(errProto, typeToString(p.sym.typ, preferName))
        if i != n.len-1: add(errProto, ", ")
      # else: ignore internal error as we're already in error handling mode
    if errProto == proto:
      prefer = preferModuleInfo
      break

  # now use the information stored in 'prefer' to produce a nice error message:
  var result = msgKindToString(errTypeMismatch)
  add(result, describeArgs(c, n, 1, prefer))
  add(result, ')')
  var candidates = ""
  for err, mut in items(errors):
    if err.kind in routineKinds and err.ast != nil:
      add(candidates, renderTree(err.ast,
            {renderNoBody, renderNoComments,renderNoPragmas}))
    else:
      add(candidates, err.getProcHeader(prefer))
    add(candidates, "\n")
    if mut != 0 and mut < n.len:
      add(candidates, "for a 'var' type a variable needs to be passed, but '" & renderTree(n[mut]) & "' is immutable\n")
  if candidates != "":
    add(result, "\n" & msgKindToString(errButExpected) & "\n" & candidates)
  if c.compilesContextId > 0 and optReportConceptFailures in gGlobalOptions:
    globalError(n.info, errGenerated, result)
  else:
    localError(n.info, errGenerated, result)

proc bracketNotFoundError(c: PContext; n: PNode) =
  var errors: CandidateErrors = @[]
  var o: TOverloadIter
  let headSymbol = n[0]
  var symx = initOverloadIter(o, c, headSymbol)
  while symx != nil:
    if symx.kind in routineKinds:
      errors.add((symx, 0))
    symx = nextOverloadIter(o, c, headSymbol)
  if errors.len == 0:
    localError(n.info, "could not resolve: " & $n)
  else:
    notFoundError(c, n, errors)

proc resolveOverloads(c: PContext, n, orig: PNode,
                      filter: TSymKinds;
                      errors: var CandidateErrors): TCandidate =
  var initialBinding: PNode
  var alt: TCandidate
  var f = n.sons[0]
  if f.kind == nkBracketExpr:
    # fill in the bindings:
    initialBinding = f
    f = f.sons[0]
  else:
    initialBinding = nil

  template pickBest(headSymbol) =
    pickBestCandidate(c, headSymbol, n, orig, initialBinding,
                      filter, result, alt, errors)
  pickBest(f)

  let overloadsState = result.state
  if overloadsState != csMatch:
    if c.p != nil and c.p.selfSym != nil:
      # we need to enforce semchecking of selfSym again because it
      # might need auto-deref:
      var hiddenArg = newSymNode(c.p.selfSym)
      hiddenArg.typ = nil
      n.sons.insert(hiddenArg, 1)
      orig.sons.insert(hiddenArg, 1)

      pickBest(f)

      if result.state != csMatch:
        n.sons.delete(1)
        orig.sons.delete(1)
        excl n.flags, nfExprCall
      else: return

    if nfDotField in n.flags:
      internalAssert f.kind == nkIdent and n.sonsLen >= 2
      let calleeName = newStrNode(nkStrLit, f.ident.s).withInfo(n.info)

      # leave the op head symbol empty,
      # we are going to try multiple variants
      n.sons[0..1] = [nil, n[1], calleeName]
      orig.sons[0..1] = [nil, orig[1], calleeName]

      template tryOp(x) =
        let op = newIdentNode(getIdent(x), n.info)
        n.sons[0] = op
        orig.sons[0] = op
        pickBest(op)

      if nfExplicitCall in n.flags:
        tryOp ".()"

      if result.state in {csEmpty, csNoMatch}:
        tryOp "."

    elif nfDotSetter in n.flags:
      internalAssert f.kind == nkIdent and n.sonsLen == 3
      let calleeName = newStrNode(nkStrLit,
        f.ident.s[0..f.ident.s.len-2]).withInfo(n.info)
      let callOp = newIdentNode(getIdent".=", n.info)
      n.sons[0..1] = [callOp, n[1], calleeName]
      orig.sons[0..1] = [callOp, orig[1], calleeName]
      pickBest(callOp)

    if overloadsState == csEmpty and result.state == csEmpty:
      if nfDotField in n.flags and nfExplicitCall notin n.flags:
        localError(n.info, errUndeclaredField, considerQuotedIdent(f).s)
      else:
        localError(n.info, errUndeclaredRoutine, considerQuotedIdent(f).s)
      return
    elif result.state != csMatch:
      if nfExprCall in n.flags:
        localError(n.info, errExprXCannotBeCalled,
                   renderTree(n, {renderNoComments}))
      else:
        if {nfDotField, nfDotSetter} * n.flags != {}:
          # clean up the inserted ops
          n.sons.delete(2)
          n.sons[0] = f

        errors = @[]
        pickBest(f)
        #notFoundError(c, n, errors)

      return
  if alt.state == csMatch and cmpCandidates(result, alt) == 0 and
      not sameMethodDispatcher(result.calleeSym, alt.calleeSym):
    internalAssert result.state == csMatch
    #writeMatches(result)
    #writeMatches(alt)
    if c.compilesContextId > 0:
      # quick error message for performance of 'compiles' built-in:
      globalError(n.info, errGenerated, "ambiguous call")
    elif gErrorCounter == 0:
      # don't cascade errors
      var args = "("
      for i in countup(1, sonsLen(n) - 1):
        if i > 1: add(args, ", ")
        add(args, typeToString(n.sons[i].typ))
      add(args, ")")

      localError(n.info, errGenerated, msgKindToString(errAmbiguousCallXYZ) % [
        getProcHeader(result.calleeSym), getProcHeader(alt.calleeSym),
        args])


proc instGenericConvertersArg*(c: PContext, a: PNode, x: TCandidate) =
  if a.kind == nkHiddenCallConv and a.sons[0].kind == nkSym:
    let s = a.sons[0].sym
    if s.ast != nil and s.ast[genericParamsPos].kind != nkEmpty:
      let finalCallee = generateInstance(c, s, x.bindings, a.info)
      a.sons[0].sym = finalCallee
      a.sons[0].typ = finalCallee.typ
      #a.typ = finalCallee.typ.sons[0]

proc instGenericConvertersSons*(c: PContext, n: PNode, x: TCandidate) =
  assert n.kind in nkCallKinds
  if x.genericConverter:
    for i in 1 .. <n.len:
      instGenericConvertersArg(c, n.sons[i], x)

proc indexTypesMatch(c: PContext, f, a: PType, arg: PNode): PNode =
  var m: TCandidate
  initCandidate(c, m, f)
  result = paramTypesMatch(m, f, a, arg, nil)
  if m.genericConverter and result != nil:
    instGenericConvertersArg(c, result, m)

proc inferWithMetatype(c: PContext, formal: PType,
                       arg: PNode, coerceDistincts = false): PNode =
  var m: TCandidate
  initCandidate(c, m, formal)
  m.coerceDistincts = coerceDistincts
  result = paramTypesMatch(m, formal, arg.typ, arg, nil)
  if m.genericConverter and result != nil:
    instGenericConvertersArg(c, result, m)
  if result != nil:
    # This almost exactly replicates the steps taken by the compiler during
    # param matching. It performs an embarrassing amount of back-and-forth
    # type jugling, but it's the price to pay for consistency and correctness
    result.typ = generateTypeInstance(c, m.bindings, arg.info,
                                      formal.skipTypes({tyCompositeTypeClass}))
  else:
    typeMismatch(arg.info, formal, arg.typ)
    # error correction:
    result = copyTree(arg)
    result.typ = formal

proc semResolvedCall(c: PContext, n: PNode, x: TCandidate): PNode =
  assert x.state == csMatch
  var finalCallee = x.calleeSym
  markUsed(n.sons[0].info, finalCallee, c.graph.usageSym)
  styleCheckUse(n.sons[0].info, finalCallee)
  assert finalCallee.ast != nil
  if x.hasFauxMatch:
    result = x.call
    result.sons[0] = newSymNode(finalCallee, result.sons[0].info)
    if containsGenericType(result.typ) or x.fauxMatch == tyUnknown:
      result.typ = newTypeS(x.fauxMatch, c)
    return
  let gp = finalCallee.ast.sons[genericParamsPos]
  if gp.kind != nkEmpty:
    if x.calleeSym.kind notin {skMacro, skTemplate}:
      if x.calleeSym.magic in {mArrGet, mArrPut}:
        finalCallee = x.calleeSym
      else:
        finalCallee = generateInstance(c, x.calleeSym, x.bindings, n.info)
    else:
      # For macros and templates, the resolved generic params
      # are added as normal params.
      for s in instantiateGenericParamList(c, gp, x.bindings):
        case s.kind
        of skConst:
          x.call.add s.ast
        of skType:
          x.call.add newSymNode(s, n.info)
        else:
          internalAssert false

  result = x.call
  instGenericConvertersSons(c, result, x)
  result.sons[0] = newSymNode(finalCallee, result.sons[0].info)
  result.typ = finalCallee.typ.sons[0]

proc canDeref(n: PNode): bool {.inline.} =
  result = n.len >= 2 and (let t = n[1].typ;
    t != nil and t.skipTypes({tyGenericInst, tyAlias}).kind in {tyPtr, tyRef})

proc tryDeref(n: PNode): PNode =
  result = newNodeI(nkHiddenDeref, n.info)
  result.typ = n.typ.skipTypes(abstractInst).sons[0]
  result.addSon(n)

proc semOverloadedCall(c: PContext, n, nOrig: PNode,
                       filter: TSymKinds): PNode =
  var errors: CandidateErrors

  var r = resolveOverloads(c, n, nOrig, filter, errors)
  if r.state == csMatch: result = semResolvedCall(c, n, r)
  elif experimentalMode(c) and canDeref(n):
    # try to deref the first argument and then try overloading resolution again:
    n.sons[1] = n.sons[1].tryDeref
    var r = resolveOverloads(c, n, nOrig, filter, errors)
    if r.state == csMatch: result = semResolvedCall(c, n, r)
    else:
      # get rid of the deref again for a better error message:
      n.sons[1] = n.sons[1].sons[0]
      notFoundError(c, n, errors)
  else:
    notFoundError(c, n, errors)
  # else: result = errorNode(c, n)

proc explicitGenericInstError(n: PNode): PNode =
  localError(n.info, errCannotInstantiateX, renderTree(n))
  result = n

proc explicitGenericSym(c: PContext, n: PNode, s: PSym): PNode =
  var m: TCandidate
  # binding has to stay 'nil' for this to work!
  initCandidate(c, m, s, nil)

  for i in 1..sonsLen(n)-1:
    let formal = s.ast.sons[genericParamsPos].sons[i-1].typ
    let arg = n[i].typ
    let tm = typeRel(m, formal, arg, true)
    if tm in {isNone, isConvertible}: return nil
  var newInst = generateInstance(c, s, m.bindings, n.info)
  newInst.typ.flags.excl tfUnresolved
  markUsed(n.info, s, c.graph.usageSym)
  styleCheckUse(n.info, s)
  result = newSymNode(newInst, n.info)

proc explicitGenericInstantiation(c: PContext, n: PNode, s: PSym): PNode =
  assert n.kind == nkBracketExpr
  for i in 1..sonsLen(n)-1:
    n.sons[i].typ = semTypeNode(c, n.sons[i], nil)
  var s = s
  var a = n.sons[0]
  if a.kind == nkSym:
    # common case; check the only candidate has the right
    # number of generic type parameters:
    if safeLen(s.ast.sons[genericParamsPos]) != n.len-1:
      let expected = safeLen(s.ast.sons[genericParamsPos])
      localError(n.info, errGenerated, "cannot instantiate: " & renderTree(n) &
         "; got " & $(n.len-1) & " type(s) but expected " & $expected)
      return n
    result = explicitGenericSym(c, n, s)
    if result == nil: result = explicitGenericInstError(n)
  elif a.kind in {nkClosedSymChoice, nkOpenSymChoice}:
    # choose the generic proc with the proper number of type parameters.
    # XXX I think this could be improved by reusing sigmatch.paramTypesMatch.
    # It's good enough for now.
    result = newNodeI(a.kind, n.info)
    for i in countup(0, len(a)-1):
      var candidate = a.sons[i].sym
      if candidate.kind in {skProc, skMethod, skConverter,
                            skIterator}:
        # it suffices that the candidate has the proper number of generic
        # type parameters:
        if safeLen(candidate.ast.sons[genericParamsPos]) == n.len-1:
          let x = explicitGenericSym(c, n, candidate)
          if x != nil: result.add(x)
    # get rid of nkClosedSymChoice if not ambiguous:
    if result.len == 1 and a.kind == nkClosedSymChoice:
      result = result[0]
    elif result.len == 0: result = explicitGenericInstError(n)
  else:
    result = explicitGenericInstError(n)

proc searchForBorrowProc(c: PContext, startScope: PScope, fn: PSym): PSym =
  # Searchs for the fn in the symbol table. If the parameter lists are suitable
  # for borrowing the sym in the symbol table is returned, else nil.
  # New approach: generate fn(x, y, z) where x, y, z have the proper types
  # and use the overloading resolution mechanism:
  var call = newNodeI(nkCall, fn.info)
  var hasDistinct = false
  call.add(newIdentNode(fn.name, fn.info))
  for i in 1.. <fn.typ.n.len:
    let param = fn.typ.n.sons[i]
    let t = skipTypes(param.typ, abstractVar-{tyTypeDesc, tyDistinct})
    if t.kind == tyDistinct or param.typ.kind == tyDistinct: hasDistinct = true
    var x: PType
    if param.typ.kind == tyVar:
      x = newTypeS(tyVar, c)
      x.addSonSkipIntLit t.baseOfDistinct
    else:
      x = t.baseOfDistinct
    call.add(newNodeIT(nkEmpty, fn.info, x))
  if hasDistinct:
    var resolved = semOverloadedCall(c, call, call, {fn.kind})
    if resolved != nil:
      result = resolved.sons[0].sym
      if not compareTypes(result.typ.sons[0], fn.typ.sons[0], dcEqIgnoreDistinct):
        result = nil
      elif result.magic in {mArrPut, mArrGet}:
        # cannot borrow these magics for now
        result = nil

