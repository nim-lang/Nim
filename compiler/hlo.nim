#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include implements the high level optimization pass.

proc hlo(c: PContext, n: PNode): PNode

proc evalPattern(c: PContext, n, orig: PNode): PNode =
  internalAssert c.config, n.kind == nkCall and n[0].kind == nkSym
  # we need to ensure that the resulting AST is semchecked. However, it's
  # awful to semcheck before macro invocation, so we don't and treat
  # templates and macros as immediate in this context.
  var rule: string
  if c.config.hasHint(hintPattern):
    rule = renderTree(n, {renderNoComments})
  let s = n[0].sym
  case s.kind
  of skMacro:
    result = semMacroExpr(c, n, orig, s)
  of skTemplate:
    result = semTemplateExpr(c, n, s, {efFromHlo})
  else:
    result = semDirectOp(c, n, {})
  if c.config.hasHint(hintPattern):
    message(c.config, orig.info, hintPattern, rule & " --> '" &
      renderTree(result, {renderNoComments}) & "'")

proc applyPatterns(c: PContext, n: PNode): PNode =
  result = n
  # we apply the last pattern first, so that pattern overriding is possible;
  # however the resulting AST would better not trigger the old rule then
  # anymore ;-)
  for i in countdown(c.patterns.len-1, 0):
    let pattern = c.patterns[i]
    if not isNil(pattern):
      let x = applyRule(c, pattern, result)
      if not isNil(x):
        assert x.kind in {nkStmtList, nkCall}
        # better be safe than sorry, so check evalTemplateCounter too:
        inc(c.config.evalTemplateCounter)
        if c.config.evalTemplateCounter > evalTemplateLimit:
          globalError(c.config, n.info, "template instantiation too nested")
        # deactivate this pattern:
        c.patterns[i] = nil
        if x.kind == nkStmtList:
          assert x.len == 3
          x[1] = evalPattern(c, x[1], result)
          result = flattenStmts(x)
        else:
          result = evalPattern(c, x, result)
        dec(c.config.evalTemplateCounter)
        # activate this pattern again:
        c.patterns[i] = pattern

proc hlo(c: PContext, n: PNode): PNode =
  inc(c.hloLoopDetector)
  # simply stop and do not perform any further transformations:
  if c.hloLoopDetector > 300: return n
  case n.kind
  of nkMacroDef, nkTemplateDef, procDefs:
    # already processed (special cases in semstmts.nim)
    result = n
  else:
    if n.kind in {nkFastAsgn, nkAsgn, nkIdentDefs, nkVarTuple} and
        n[0].kind == nkSym and
        {sfGlobal, sfPure} * n[0].sym.flags == {sfGlobal, sfPure}:
      # do not optimize 'var g {.global} = re(...)' again!
      return n
    result = applyPatterns(c, n)
    if result == n:
      # no optimization applied, try subtrees:
      for i in 0..<result.safeLen:
        let a = result[i]
        let h = hlo(c, a)
        if h != a: result[i] = h
    else:
      # perform type checking, so that the replacement still fits:
      if isEmptyType(n.typ) and isEmptyType(result.typ):
        discard
      else:
        result = fitNode(c, n.typ, result, n.info)
      # optimization has been applied so check again:
      result = commonOptimizations(c.graph, c.idgen, c.module, result)
      result = hlo(c, result)
      result = commonOptimizations(c.graph, c.idgen, c.module, result)

proc hloBody(c: PContext, n: PNode): PNode =
  # fast exit:
  if c.patterns.len == 0 or optTrMacros notin c.config.options: return n
  c.hloLoopDetector = 0
  result = hlo(c, n)

proc hloStmt(c: PContext, n: PNode): PNode =
  # fast exit:
  if c.patterns.len == 0 or optTrMacros notin c.config.options: return n
  c.hloLoopDetector = 0
  result = hlo(c, n)
