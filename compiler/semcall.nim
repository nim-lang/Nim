#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
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
    if aa.kind == nkSym and bb.kind == nkSym and aa.sym == bb.sym: 
      result = true
  
proc resolveOverloads(c: PContext, n, orig: PNode, 
                      filter: TSymKinds): TCandidate =
  var initialBinding: PNode
  var f = n.sons[0]
  if f.kind == nkBracketExpr:
    # fill in the bindings:
    initialBinding = f
    f = f.sons[0]
  else:
    initialBinding = nil
  
  var
    o: TOverloadIter
    alt, z: TCandidate

  template best: expr = result
  #Message(n.info, warnUser, renderTree(n))
  var sym = initOverloadIter(o, c, f)
  var symScope = o.lastOverloadScope
  
  if sym == nil: return
  initCandidate(best, sym, initialBinding, symScope)
  initCandidate(alt, sym, initialBinding, symScope)

  while sym != nil:
    if sym.kind in filter:
      initCandidate(z, sym, initialBinding, o.lastOverloadScope)
      z.calleeSym = sym
      matches(c, n, orig, z)
      if z.state == csMatch:
        # little hack so that iterators are preferred over everything else:
        if sym.kind == skIterator: inc(z.exactMatches, 200)
        case best.state
        of csEmpty, csNoMatch: best = z
        of csMatch:
          var cmp = cmpCandidates(best, z)
          if cmp < 0: best = z   # x is better than the best so far
          elif cmp == 0: alt = z # x is as good as the best so far
          else: nil
    sym = nextOverloadIter(o, c, f)

  if best.state == csEmpty:
    # no overloaded proc found
    # do not generate an error yet; the semantic checking will check for
    # an overloaded () operator
  elif alt.state == csMatch and cmpCandidates(best, alt) == 0 and
      not sameMethodDispatcher(best.calleeSym, alt.calleeSym):
    if best.state != csMatch:
      InternalError(n.info, "x.state is not csMatch")
    #writeMatches(best)
    #writeMatches(alt)
    if c.inCompilesContext > 0: 
      # quick error message for performance of 'compiles' built-in:
      LocalError(n.Info, errAmbiguousCallXYZ, "")
    else:
      var args = "("
      for i in countup(1, sonsLen(n) - 1):
        if i > 1: add(args, ", ")
        add(args, typeToString(n.sons[i].typ))
      add(args, ")")

      LocalError(n.Info, errGenerated, msgKindToString(errAmbiguousCallXYZ) % [
        getProcHeader(best.calleeSym), getProcHeader(alt.calleeSym),
        args])

proc semResolvedCall(c: PContext, n: PNode, x: TCandidate): PNode =
  assert x.state == csMatch
  var finalCallee = x.calleeSym
  markUsed(n, finalCallee)
  if finalCallee.ast == nil:
    internalError(n.info, "calleeSym.ast is nil") # XXX: remove this check!
  if finalCallee.ast.sons[genericParamsPos].kind != nkEmpty:
    # a generic proc!
    finalCallee = generateInstance(c, x.calleeSym, x.bindings, n.info)

  result = x.call
  result.sons[0] = newSymNode(finalCallee)
  result.typ = finalCallee.typ.sons[0]

proc semOverloadedCall(c: PContext, n, nOrig: PNode,
                       filter: TSymKinds): PNode =
  var r = resolveOverloads(c, n, nOrig, filter)
  if r.state == csMatch: result = semResolvedCall(c, n, r)
    
proc explicitGenericInstError(n: PNode): PNode =
  LocalError(n.info, errCannotInstantiateX, renderTree(n))
  result = n

proc explicitGenericSym(c: PContext, n: PNode, s: PSym): PNode =
  var x: TCandidate
  initCandidate(x, s, n)
  var newInst = generateInstance(c, s, x.bindings, n.info)
  markUsed(n, s)
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
      return explicitGenericInstError(n)
    result = explicitGenericSym(c, n, s)
  elif a.kind == nkSymChoice:
    # choose the generic proc with the proper number of type parameters.
    # XXX I think this could be improved by reusing sigmatch.ParamTypesMatch.
    # It's good enough for now.
    result = newNodeI(nkSymChoice, n.info)
    for i in countup(0, len(a)-1): 
      var candidate = a.sons[i].sym
      if candidate.kind in {skProc, skMethod, skConverter, skIterator}: 
        # if suffices that the candidate has the proper number of generic 
        # type parameters:
        if safeLen(candidate.ast.sons[genericParamsPos]) == n.len-1:
          result.add(explicitGenericSym(c, n, candidate))
    # get rid of nkSymChoice if not ambiguous:
    if result.len == 1: result = result[0]
    # candidateCount != 1: return explicitGenericInstError(n)
  else:
    result = explicitGenericInstError(n)

