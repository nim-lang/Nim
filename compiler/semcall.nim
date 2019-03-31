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
      # candidates around so we cannot implement that for now. So in order
      # to avoid subtle problems, the call remains ambiguous and needs to
      # be disambiguated by the programmer; this way the right generic is
      # instantiated.

proc determineType(c: PContext, s: PSym)

proc initCandidateSymbols(c: PContext, headSymbol: PNode,
                          initialBinding: PNode,
                          filter: TSymKinds,
                          best, alt: var TCandidate,
                          o: var TOverloadIter,
                          diagnostics: bool): seq[tuple[s: PSym, scope: int]] =
  result = @[]
  var symx = initOverloadIter(o, c, headSymbol)
  while symx != nil:
    if symx.kind in filter:
      result.add((symx, o.lastOverloadScope))
    symx = nextOverloadIter(o, c, headSymbol)
  if result.len > 0:
    initCandidate(c, best, result[0].s, initialBinding,
                  result[0].scope, diagnostics)
    initCandidate(c, alt, result[0].s, initialBinding,
                  result[0].scope, diagnostics)
    best.state = csNoMatch

proc pickBestCandidate(c: PContext, headSymbol: PNode,
                       n, orig: PNode,
                       initialBinding: PNode,
                       filter: TSymKinds,
                       best, alt: var TCandidate,
                       errors: var CandidateErrors,
                       diagnosticsFlag: bool,
                       errorsEnabled: bool) =
  var o: TOverloadIter
  var sym = initOverloadIter(o, c, headSymbol)
  var scope = o.lastOverloadScope
  # Thanks to the lazy semchecking for operands, we need to check whether
  # 'initCandidate' modifies the symbol table (via semExpr).
  # This can occur in cases like 'init(a, 1, (var b = new(Type2); b))'
  let counterInitial = c.currentScope.symbols.counter
  var syms: seq[tuple[s: PSym, scope: int]]
  var noSyms = true
  var nextSymIndex = 0
  while sym != nil:
    if sym.kind in filter:
      # Initialise 'best' and 'alt' with the first available symbol
      initCandidate(c, best, sym, initialBinding, scope, diagnosticsFlag)
      initCandidate(c, alt, sym, initialBinding, scope, diagnosticsFlag)
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
    initCandidate(c, z, sym, initialBinding, scope, diagnosticsFlag)
    if c.currentScope.symbols.counter == counterInitial or syms.len != 0:
      matches(c, n, orig, z)
      if z.state == csMatch:
        #if sym.name.s == "==" and (n.info ?? "temp3"):
        #  echo typeToString(sym.typ)
        #  writeMatches(z)

        # little hack so that iterators are preferred over everything else:
        if sym.kind == skIterator: inc(z.exactMatches, 200)
        case best.state
        of csEmpty, csNoMatch: best = z
        of csMatch:
          var cmp = cmpCandidates(best, z)
          if cmp < 0: best = z   # x is better than the best so far
          elif cmp == 0: alt = z # x is as good as the best so far
      elif errorsEnabled or z.diagnosticsEnabled:
        errors.add(CandidateError(
          sym: sym,
          unmatchedVarParam: int z.mutabilityProblem,
          firstMismatch: z.firstMismatch,
          diagnostics: z.diagnostics))
    else:
      # Symbol table has been modified. Restart and pre-calculate all syms
      # before any further candidate init and compare. SLOW, but rare case.
      syms = initCandidateSymbols(c, headSymbol, initialBinding, filter,
                                  best, alt, o, diagnosticsFlag)
      noSyms = false
    if noSyms:
      sym = nextOverloadIter(o, c, headSymbol)
      scope = o.lastOverloadScope
    elif nextSymIndex < syms.len:
      # rare case: retrieve the next pre-calculated symbol
      sym = syms[nextSymIndex].s
      scope = syms[nextSymIndex].scope
      nextSymIndex += 1
    else:
      break

proc effectProblem(f, a: PType; result: var string) =
  if f.kind == tyProc and a.kind == tyProc:
    if tfThread in f.flags and tfThread notin a.flags:
      result.add "\n  This expression is not GC-safe. Annotate the " &
          "proc with {.gcsafe.} to get extended error information."
    elif tfNoSideEffect in f.flags and tfNoSideEffect notin a.flags:
      result.add "\n  This expression can have side effects. Annotate the " &
          "proc with {.noSideEffect.} to get extended error information."

proc renderNotLValue(n: PNode): string =
  result = $n
  let n = if n.kind == nkHiddenDeref: n[0] else: n
  if n.kind == nkHiddenCallConv and n.len > 1:
    result = $n[0] & "(" & result & ")"
  elif n.kind in {nkHiddenStdConv, nkHiddenSubConv} and n.len == 2:
    result = typeToString(n.typ.skipTypes(abstractVar)) & "(" & result & ")"

proc presentFailedCandidates(c: PContext, n: PNode, errors: CandidateErrors):
                            (TPreferedDesc, string) =
  var prefer = preferName
  # to avoid confusing errors like:
  #   got (SslPtr, SocketHandle)
  #   but expected one of:
  #   openssl.SSL_set_fd(ssl: SslPtr, fd: SocketHandle): cint
  # we do a pre-analysis. If all types produce the same string, we will add
  # module information.
  let proto = describeArgs(c, n, 1, preferName)
  for err in errors:
    var errProto = ""
    let n = err.sym.typ.n
    for i in countup(1, n.len - 1):
      var p = n.sons[i]
      if p.kind == nkSym:
        add(errProto, typeToString(p.sym.typ, preferName))
        if i != n.len-1: add(errProto, ", ")
      # else: ignore internal error as we're already in error handling mode
    if errProto == proto:
      prefer = preferModuleInfo
      break

  # we pretend procs are attached to the type of the first
  # argument in order to remove plenty of candidates. This is
  # comparable to what C# does and C# is doing fine.
  var filterOnlyFirst = false
  if optShowAllMismatches notin c.config.globalOptions:
    for err in errors:
      if err.firstMismatch > 1:
        filterOnlyFirst = true
        break

  var candidates = ""
  var skipped = 0
  for err in errors:
    if filterOnlyFirst and err.firstMismatch == 1:
      inc skipped
      continue
    if err.sym.kind in routineKinds and err.sym.ast != nil:
      add(candidates, renderTree(err.sym.ast,
            {renderNoBody, renderNoComments, renderNoPragmas}))
    else:
      add(candidates, getProcHeader(c.config, err.sym, prefer))
    add(candidates, "\n")
    if err.firstMismatch != 0 and n.len > 1:
      let cond = n.len > 2
      if cond:
        candidates.add("  first type mismatch at position: " & $abs(err.firstMismatch))
        if err.firstMismatch >= 0: candidates.add("\n  required type: ")
        else: candidates.add("\n  unknown named parameter: " & $n[-err.firstMismatch][0])
      var wanted, got: PType = nil
      if err.firstMismatch < 0:
        discard
      elif err.firstMismatch < err.sym.typ.len:
        wanted = err.sym.typ.sons[err.firstMismatch]
        if cond: candidates.add typeToString(wanted)
      else:
        if cond: candidates.add "none"
      if err.firstMismatch > 0 and err.firstMismatch < n.len:
        if cond:
          candidates.add "\n  but expression '"
          candidates.add renderTree(n[err.firstMismatch])
          candidates.add "' is of type: "
        got = n[err.firstMismatch].typ
        if cond: candidates.add typeToString(got)
      if wanted != nil and got != nil:
        effectProblem(wanted, got, candidates)
      if cond: candidates.add "\n"
    if err.unmatchedVarParam != 0 and err.unmatchedVarParam < n.len:
      candidates.add("  for a 'var' type a variable needs to be passed, but '" &
                      renderNotLValue(n[err.unmatchedVarParam]) &
                      "' is immutable\n")
    for diag in err.diagnostics:
      candidates.add(diag & "\n")
  if skipped > 0:
    candidates.add($skipped & " other mismatching symbols have been " &
        "suppressed; compile with --showAllMismatches:on to see them\n")
  result = (prefer, candidates)

const
  errTypeMismatch = "type mismatch: got <"
  errButExpected = "but expected one of: "
  errUndeclaredField = "undeclared field: '$1'"
  errUndeclaredRoutine = "attempting to call undeclared routine: '$1'"
  errBadRoutine = "attempting to call routine: '$1'$2"
  errAmbiguousCallXYZ = "ambiguous call; both $1 and $2 match for: $3"

proc notFoundError*(c: PContext, n: PNode, errors: CandidateErrors) =
  # Gives a detailed error message; this is separated from semOverloadedCall,
  # as semOverlodedCall is already pretty slow (and we need this information
  # only in case of an error).
  if c.config.m.errorOutputs == {}:
    # fail fast:
    globalError(c.config, n.info, "type mismatch")
    return
  if errors.len == 0:
    localError(c.config, n.info, "expression '$1' cannot be called" % n[0].renderTree)
    return

  let (prefer, candidates) = presentFailedCandidates(c, n, errors)
  var result = errTypeMismatch
  add(result, describeArgs(c, n, 1, prefer))
  add(result, '>')
  if candidates != "":
    add(result, "\n" & errButExpected & "\n" & candidates)
  localError(c.config, n.info, result & "\nexpression: " & $n)

proc bracketNotFoundError(c: PContext; n: PNode) =
  var errors: CandidateErrors = @[]
  var o: TOverloadIter
  let headSymbol = n[0]
  var symx = initOverloadIter(o, c, headSymbol)
  while symx != nil:
    if symx.kind in routineKinds:
      errors.add(CandidateError(sym: symx,
                                unmatchedVarParam: 0, firstMismatch: 0,
                                diagnostics: @[],
                                enabled: false))
    symx = nextOverloadIter(o, c, headSymbol)
  if errors.len == 0:
    localError(c.config, n.info, "could not resolve: " & $n)
  else:
    notFoundError(c, n, errors)

proc getMsgDiagnostic(c: PContext, flags: TExprFlags, n, f: PNode): string =
  if c.compilesContextId > 0:
    # we avoid running more diagnostic when inside a `compiles(expr)`, to
    # errors while running diagnostic (see test D20180828T234921), and
    # also avoid slowdowns in evaluating `compiles(expr)`.
    discard
  else:
    var o: TOverloadIter
    var sym = initOverloadIter(o, c, f)
    while sym != nil:
      proc toHumanStr(kind: TSymKind): string =
        result = $kind
        assert result.startsWith "sk"
        result = result[2..^1].toLowerAscii
      result &= "\n  found '$1' of kind '$2'" % [getSymRepr(c.config, sym), sym.kind.toHumanStr]
      sym = nextOverloadIter(o, c, n)

  let ident = considerQuotedIdent(c, f, n).s
  if nfDotField in n.flags and nfExplicitCall notin n.flags:
    let sym = n.sons[1].typ.sym
    var typeHint = ""
    if sym == nil:
      # Perhaps we're in a `compiles(foo.bar)` expression, or
      # in a concept, eg:
      #   ExplainedConcept {.explain.} = concept x
      #     x.foo is int
      # We coudl use: `(c.config $ n.sons[1].info)` to get more context.
      discard
    else:
      typeHint = " for type " & getProcHeader(c.config, sym)
    result = errUndeclaredField % ident & typeHint & " " & result
  else:
    if result.len == 0: result = errUndeclaredRoutine % ident
    else: result = errBadRoutine % [ident, result]

proc resolveOverloads(c: PContext, n, orig: PNode,
                      filter: TSymKinds, flags: TExprFlags,
                      errors: var CandidateErrors,
                      errorsEnabled: bool): TCandidate =
  var initialBinding: PNode
  var alt: TCandidate
  var f = n.sons[0]
  if f.kind == nkBracketExpr:
    # fill in the bindings:
    semOpAux(c, f)
    initialBinding = f
    f = f.sons[0]
  else:
    initialBinding = nil

  template pickBest(headSymbol) =
    pickBestCandidate(c, headSymbol, n, orig, initialBinding,
                      filter, result, alt, errors, efExplain in flags,
                      errorsEnabled)
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
      internalAssert c.config, f.kind == nkIdent and n.len >= 2

      # leave the op head symbol empty,
      # we are going to try multiple variants
      n.sons[0..1] = [nil, n[1], f]
      orig.sons[0..1] = [nil, orig[1], f]

      template tryOp(x) =
        let op = newIdentNode(getIdent(c.cache, x), n.info)
        n.sons[0] = op
        orig.sons[0] = op
        pickBest(op)

      if nfExplicitCall in n.flags:
        tryOp ".()"

      if result.state in {csEmpty, csNoMatch}:
        tryOp "."

    elif nfDotSetter in n.flags and f.kind == nkIdent and n.len == 3:
      # we need to strip away the trailing '=' here:
      let calleeName = newIdentNode(getIdent(c.cache, f.ident.s[0..f.ident.s.len-2]), n.info)
      let callOp = newIdentNode(getIdent(c.cache, ".="), n.info)
      n.sons[0..1] = [callOp, n[1], calleeName]
      orig.sons[0..1] = [callOp, orig[1], calleeName]
      pickBest(callOp)

    if overloadsState == csEmpty and result.state == csEmpty:
      if efNoUndeclared notin flags: # for tests/pragmas/tcustom_pragma.nim
        localError(c.config, n.info, getMsgDiagnostic(c, flags, n, f))
      return
    elif result.state != csMatch:
      if nfExprCall in n.flags:
        localError(c.config, n.info, "expression '$1' cannot be called" %
                   renderTree(n, {renderNoComments}))
      else:
        if {nfDotField, nfDotSetter} * n.flags != {}:
          # clean up the inserted ops
          n.sons.delete(2)
          n.sons[0] = f
      return
  if alt.state == csMatch and cmpCandidates(result, alt) == 0 and
      not sameMethodDispatcher(result.calleeSym, alt.calleeSym):
    internalAssert c.config, result.state == csMatch
    #writeMatches(result)
    #writeMatches(alt)
    if c.config.m.errorOutputs == {}:
      # quick error message for performance of 'compiles' built-in:
      globalError(c.config, n.info, errGenerated, "ambiguous call")
    elif c.config.errorCounter == 0:
      # don't cascade errors
      var args = "("
      for i in countup(1, sonsLen(n) - 1):
        if i > 1: add(args, ", ")
        add(args, typeToString(n.sons[i].typ))
      add(args, ")")

      localError(c.config, n.info, errAmbiguousCallXYZ % [
        getProcHeader(c.config, result.calleeSym),
        getProcHeader(c.config, alt.calleeSym),
        args])

proc instGenericConvertersArg*(c: PContext, a: PNode, x: TCandidate) =
  let a = if a.kind == nkHiddenDeref: a[0] else: a
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
    for i in 1 ..< n.len:
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
    typeMismatch(c.config, arg.info, formal, arg.typ)
    # error correction:
    result = copyTree(arg)
    result.typ = formal

proc updateDefaultParams(call: PNode) =
  # In generic procs, the default parameter may be unique for each
  # instantiation (see tlateboundgenericparams).
  # After a call is resolved, we need to re-assign any default value
  # that was used during sigmatch. sigmatch is responsible for marking
  # the default params with `nfDefaultParam` and `instantiateProcType`
  # computes correctly the default values for each instantiation.
  let calleeParams = call[0].sym.typ.n
  for i in 1..<call.len:
    if nfDefaultParam in call[i].flags:
      let def = calleeParams[i].sym.ast
      if nfDefaultRefsParam in def.flags: call.flags.incl nfDefaultRefsParam
      call[i] = def

proc getCallLineInfo(n: PNode): TLineInfo =
  case n.kind
  of nkAccQuoted, nkBracketExpr, nkCall, nkCommand: getCallLineInfo(n.sons[0])
  of nkDotExpr: getCallLineInfo(n.sons[1])
  else: n.info

proc semResolvedCall(c: PContext, x: TCandidate,
                     n: PNode, flags: TExprFlags): PNode =
  assert x.state == csMatch
  var finalCallee = x.calleeSym
  let info = getCallLineInfo(n)
  markUsed(c.config, info, finalCallee, c.graph.usageSym)
  onUse(info, finalCallee)
  assert finalCallee.ast != nil
  if x.hasFauxMatch:
    result = x.call
    result.sons[0] = newSymNode(finalCallee, getCallLineInfo(result.sons[0]))
    if containsGenericType(result.typ) or x.fauxMatch == tyUnknown:
      result.typ = newTypeS(x.fauxMatch, c)
      if result.typ.kind == tyError: incl result.typ.flags, tfCheckedForDestructor
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
          internalAssert c.config, false

  result = x.call
  instGenericConvertersSons(c, result, x)
  result[0] = newSymNode(finalCallee, getCallLineInfo(result[0]))
  result.typ = finalCallee.typ.sons[0]
  updateDefaultParams(result)

proc canDeref(n: PNode): bool {.inline.} =
  result = n.len >= 2 and (let t = n[1].typ;
    t != nil and t.skipTypes({tyGenericInst, tyAlias, tySink}).kind in {tyPtr, tyRef})

proc tryDeref(n: PNode): PNode =
  result = newNodeI(nkHiddenDeref, n.info)
  result.typ = n.typ.skipTypes(abstractInst).sons[0]
  result.addSon(n)

proc semOverloadedCall(c: PContext, n, nOrig: PNode,
                       filter: TSymKinds, flags: TExprFlags): PNode =
  var errors: CandidateErrors = @[] # if efExplain in flags: @[] else: nil
  var r = resolveOverloads(c, n, nOrig, filter, flags, errors, efExplain in flags)
  if r.state == csMatch:
    # this may be triggered, when the explain pragma is used
    if errors.len > 0:
      let (_, candidates) = presentFailedCandidates(c, n, errors)
      message(c.config, n.info, hintUserRaw,
              "Non-matching candidates for " & renderTree(n) & "\n" &
              candidates)
    result = semResolvedCall(c, r, n, flags)
  elif implicitDeref in c.features and canDeref(n):
    # try to deref the first argument and then try overloading resolution again:
    #
    # XXX: why is this here?
    # it could be added to the long list of alternatives tried
    # inside `resolveOverloads` or it could be moved all the way
    # into sigmatch with hidden conversion produced there
    #
    n.sons[1] = n.sons[1].tryDeref
    var r = resolveOverloads(c, n, nOrig, filter, flags, errors, efExplain in flags)
    if r.state == csMatch: result = semResolvedCall(c, r, n, flags)
    else:
      # get rid of the deref again for a better error message:
      n.sons[1] = n.sons[1].sons[0]
      #notFoundError(c, n, errors)
      if efExplain notin flags:
        # repeat the overload resolution,
        # this time enabling all the diagnostic output (this should fail again)
        discard semOverloadedCall(c, n, nOrig, filter, flags + {efExplain})
      elif efNoUndeclared notin flags:
        notFoundError(c, n, errors)
  else:
    if efExplain notin flags:
      # repeat the overload resolution,
      # this time enabling all the diagnostic output (this should fail again)
      discard semOverloadedCall(c, n, nOrig, filter, flags + {efExplain})
    elif efNoUndeclared notin flags:
      notFoundError(c, n, errors)

proc explicitGenericInstError(c: PContext; n: PNode): PNode =
  localError(c.config, getCallLineInfo(n), errCannotInstantiateX % renderTree(n))
  result = n

proc explicitGenericSym(c: PContext, n: PNode, s: PSym): PNode =
  var m: TCandidate
  # binding has to stay 'nil' for this to work!
  initCandidate(c, m, s, nil)

  for i in 1..sonsLen(n)-1:
    let formal = s.ast.sons[genericParamsPos].sons[i-1].typ
    var arg = n[i].typ
    # try transforming the argument into a static one before feeding it into
    # typeRel
    if formal.kind == tyStatic and arg.kind != tyStatic:
      let evaluated = c.semTryConstExpr(c, n[i])
      if evaluated != nil:
        arg = newTypeS(tyStatic, c)
        arg.sons = @[evaluated.typ]
        arg.n = evaluated
    let tm = typeRel(m, formal, arg)
    if tm in {isNone, isConvertible}: return nil
  var newInst = generateInstance(c, s, m.bindings, n.info)
  newInst.typ.flags.excl tfUnresolved
  let info = getCallLineInfo(n)
  markUsed(c.config, info, s, c.graph.usageSym)
  onUse(info, s)
  result = newSymNode(newInst, info)

proc explicitGenericInstantiation(c: PContext, n: PNode, s: PSym): PNode =
  assert n.kind == nkBracketExpr
  for i in 1..sonsLen(n)-1:
    let e = semExpr(c, n.sons[i])
    if e.typ == nil:
      localError(c.config, e.info, "expression has no type")
    else:
      n.sons[i].typ = e.typ.skipTypes({tyTypeDesc})
  var s = s
  var a = n.sons[0]
  if a.kind == nkSym:
    # common case; check the only candidate has the right
    # number of generic type parameters:
    if safeLen(s.ast.sons[genericParamsPos]) != n.len-1:
      let expected = safeLen(s.ast.sons[genericParamsPos])
      localError(c.config, getCallLineInfo(n), errGenerated, "cannot instantiate: '" & renderTree(n) &
         "'; got " & $(n.len-1) & " type(s) but expected " & $expected)
      return n
    result = explicitGenericSym(c, n, s)
    if result == nil: result = explicitGenericInstError(c, n)
  elif a.kind in {nkClosedSymChoice, nkOpenSymChoice}:
    # choose the generic proc with the proper number of type parameters.
    # XXX I think this could be improved by reusing sigmatch.paramTypesMatch.
    # It's good enough for now.
    result = newNodeI(a.kind, getCallLineInfo(n))
    for i in countup(0, len(a)-1):
      var candidate = a.sons[i].sym
      if candidate.kind in {skProc, skMethod, skConverter,
                            skFunc, skIterator}:
        # it suffices that the candidate has the proper number of generic
        # type parameters:
        if safeLen(candidate.ast.sons[genericParamsPos]) == n.len-1:
          let x = explicitGenericSym(c, n, candidate)
          if x != nil: result.add(x)
    # get rid of nkClosedSymChoice if not ambiguous:
    if result.len == 1 and a.kind == nkClosedSymChoice:
      result = result[0]
    elif result.len == 0: result = explicitGenericInstError(c, n)
    # candidateCount != 1: return explicitGenericInstError(c, n)
  else:
    result = explicitGenericInstError(c, n)

proc searchForBorrowProc(c: PContext, startScope: PScope, fn: PSym): PSym =
  # Searchs for the fn in the symbol table. If the parameter lists are suitable
  # for borrowing the sym in the symbol table is returned, else nil.
  # New approach: generate fn(x, y, z) where x, y, z have the proper types
  # and use the overloading resolution mechanism:
  var call = newNodeI(nkCall, fn.info)
  var hasDistinct = false
  call.add(newIdentNode(fn.name, fn.info))
  for i in 1..<fn.typ.n.len:
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
    var resolved = semOverloadedCall(c, call, call, {fn.kind}, {})
    if resolved != nil:
      result = resolved.sons[0].sym
      if not compareTypes(result.typ.sons[0], fn.typ.sons[0], dcEqIgnoreDistinct):
        result = nil
      elif result.magic in {mArrPut, mArrGet}:
        # cannot borrow these magics for now
        result = nil
