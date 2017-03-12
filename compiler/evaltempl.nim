#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Template evaluation engine. Now hygienic.

import
  strutils, options, ast, astalgo, msgs, os, idents, wordrecg, renderer,
  rodread

type
  TemplCtx {.pure, final.} = object
    owner, genSymOwner: PSym
    instLines: bool   # use the instantiation lines numbers
    mapping: TIdTable # every gensym'ed symbol needs to be mapped to some
                      # new symbol

proc copyNode(ctx: TemplCtx, a, b: PNode): PNode =
  result = copyNode(a)
  if ctx.instLines: result.info = b.info

proc evalTemplateAux(templ, actual: PNode, c: var TemplCtx, result: PNode) =
  template handleParam(param) =
    let x = param
    if x.kind == nkArgList:
      for y in items(x): result.add(y)
    else:
      result.add copyTree(x)

  case templ.kind
  of nkSym:
    var s = templ.sym
    if s.owner.id == c.owner.id:
      if s.kind == skParam and sfGenSym notin s.flags:
        handleParam actual.sons[s.position]
      elif s.kind == skGenericParam or
           s.kind == skType and s.typ != nil and s.typ.kind == tyGenericParam:
        handleParam actual.sons[s.owner.typ.len + s.position - 1]
      else:
        internalAssert sfGenSym in s.flags
        var x = PSym(idTableGet(c.mapping, s))
        if x == nil:
          x = copySym(s, false)
          x.owner = c.genSymOwner
          idTablePut(c.mapping, s, x)
        result.add newSymNode(x, if c.instLines: actual.info else: templ.info)
    else:
      result.add copyNode(c, templ, actual)
  of nkNone..nkIdent, nkType..nkNilLit: # atom
    result.add copyNode(c, templ, actual)
  else:
    var res = copyNode(c, templ, actual)
    for i in countup(0, sonsLen(templ) - 1):
      evalTemplateAux(templ.sons[i], actual, c, res)
    result.add res

proc evalTemplateArgs(n: PNode, s: PSym; fromHlo: bool): PNode =
  # if the template has zero arguments, it can be called without ``()``
  # `n` is then a nkSym or something similar
  var totalParams = case n.kind
    of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit: n.len-1
    else: 0

  var
    # XXX: Since immediate templates are not subject to the
    # standard sigmatching algorithm, they will have a number
    # of deficiencies when it comes to generic params:
    # Type dependencies between the parameters won't be honoured
    # and the bound generic symbols won't be resolvable within
    # their bodies. We could try to fix this, but it may be
    # wiser to just deprecate immediate templates and macros
    # now that we have working untyped parameters.
    genericParams = if sfImmediate in s.flags or fromHlo: 0
                    else: s.ast[genericParamsPos].len
    expectedRegularParams = <s.typ.len
    givenRegularParams = totalParams - genericParams
  if givenRegularParams < 0: givenRegularParams = 0

  if totalParams > expectedRegularParams + genericParams:
    globalError(n.info, errWrongNumberOfArguments)

  if totalParams < genericParams:
    globalError(n.info, errMissingGenericParamsForTemplate,
                n.renderTree)

  result = newNodeI(nkArgList, n.info)
  for i in 1 .. givenRegularParams:
    result.addSon n.sons[i]

  # handle parameters with default values, which were
  # not supplied by the user
  for i in givenRegularParams+1 .. expectedRegularParams:
    let default = s.typ.n.sons[i].sym.ast
    if default.isNil or default.kind == nkEmpty:
      localError(n.info, errWrongNumberOfArguments)
      addSon(result, ast.emptyNode)
    else:
      addSon(result, default.copyTree)

  # add any generic paramaters
  for i in 1 .. genericParams:
    result.addSon n.sons[givenRegularParams + i]

var evalTemplateCounter* = 0
  # to prevent endless recursion in templates instantiation

proc wrapInComesFrom*(info: TLineInfo; res: PNode): PNode =
  when true:
    result = res
    result.info = info
    if result.kind in {nkStmtList, nkStmtListExpr} and result.len > 0:
      result.lastSon.info = info
    when false:
      # this hack is required to
      var x = result
      while x.kind == nkStmtListExpr: x = x.lastSon
      if x.kind in nkCallKinds:
        for i in 1..<x.len:
          if x[i].kind in nkCallKinds:
            x.sons[i].info = info
  else:
    result = newNodeI(nkPar, info)
    result.add res

proc evalTemplate*(n: PNode, tmpl, genSymOwner: PSym; fromHlo=false): PNode =
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    globalError(n.info, errTemplateInstantiationTooNested)
    result = n

  # replace each param by the corresponding node:
  var args = evalTemplateArgs(n, tmpl, fromHlo)
  var ctx: TemplCtx
  ctx.owner = tmpl
  ctx.genSymOwner = genSymOwner
  initIdTable(ctx.mapping)

  let body = tmpl.getBody
  if isAtom(body):
    result = newNodeI(nkPar, body.info)
    evalTemplateAux(body, args, ctx, result)
    if result.len == 1: result = result.sons[0]
    else:
      localError(result.info, errIllFormedAstX,
                  renderTree(result, {renderNoComments}))
  else:
    result = copyNode(body)
    #ctx.instLines = body.kind notin {nkStmtList, nkStmtListExpr,
    #                                 nkBlockStmt, nkBlockExpr}
    #if ctx.instLines: result.info = n.info
    for i in countup(0, safeLen(body) - 1):
      evalTemplateAux(body.sons[i], args, ctx, result)
  result = wrapInComesFrom(n.info, result)
  dec(evalTemplateCounter)
