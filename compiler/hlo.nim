#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include implements the high level optimization pass.

proc hlo(c: PContext, n: PNode): PNode

proc evalPattern(c: PContext, n, orig: PNode): PNode =
  internalAssert n.kind == nkCall and n.sons[0].kind == nkSym
  # we need to ensure that the resulting AST is semchecked. However, it's
  # aweful to semcheck before macro invocation, so we don't and treat
  # templates and macros as immediate in this context.
  var rule: string
  if optHints in gOptions and hintPattern in gNotes:
    rule = renderTree(n, {renderNoComments})
  let s = n.sons[0].sym
  case s.kind
  of skMacro:
    result = semMacroExpr(c, n, orig, s)
  of skTemplate:
    result = semTemplateExpr(c, n, s)
  else:
    result = semDirectOp(c, n, {})
  if optHints in gOptions and hintPattern in gNotes:
    message(orig.info, hintPattern, rule & " --> '" & 
      renderTree(result, {renderNoComments}) & "'")

proc applyPatterns(c: PContext, n: PNode): PNode =
  result = n
  # we apply the last pattern first, so that pattern overriding is possible;
  # however the resulting AST would better not trigger the old rule then
  # anymore ;-)
  for i in countdown(<c.patterns.len, 0):
    let pattern = c.patterns[i]
    if not isNil(pattern):
      let x = applyRule(c, pattern, result)
      if not isNil(x):
        assert x.kind in {nkStmtList, nkCall}
        # better be safe than sorry, so check evalTemplateCounter too:
        inc(evalTemplateCounter)
        if evalTemplateCounter > 100:
          globalError(n.info, errTemplateInstantiationTooNested)
        # deactivate this pattern:
        c.patterns[i] = nil
        if x.kind == nkStmtList:
          assert x.len == 3
          x.sons[1] = evalPattern(c, x.sons[1], result)
          result = flattenStmts(x)
        else:
          result = evalPattern(c, x, result)
        dec(evalTemplateCounter)
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
        n.sons[0].kind == nkSym and sfGlobal in n.sons[0].sym.flags:
      # do not optimize 'var g {.global} = re(...)' again!
      return n
    result = applyPatterns(c, n)
    if result == n:
      # no optimization applied, try subtrees:
      for i in 0 .. < safeLen(result):
        let a = result.sons[i]
        let h = hlo(c, a)
        if h != a: result.sons[i] = h
    else:
      # perform type checking, so that the replacement still fits:
      if isEmptyType(n.typ) and isEmptyType(result.typ):
        nil
      else:
        result = fitNode(c, n.typ, result)
      # optimization has been applied so check again:
      result = commonOptimizations(c.module, result)
      result = hlo(c, result)
      result = commonOptimizations(c.module, result)

proc hloBody(c: PContext, n: PNode): PNode =
  # fast exit:
  if c.patterns.len == 0 or optPatterns notin gOptions: return n
  c.hloLoopDetector = 0
  result = hlo(c, n)

proc hloStmt(c: PContext, n: PNode): PNode =
  # fast exit:
  if c.patterns.len == 0 or optPatterns notin gOptions: return n
  c.hloLoopDetector = 0
  result = hlo(c, n)
