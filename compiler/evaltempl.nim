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
      case s.kind
      of skParam:
        handleParam actual.sons[s.position]
      of skGenericParam:
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

proc evalTemplateArgs(n: PNode, s: PSym): PNode =
  # if the template has zero arguments, it can be called without ``()``
  # `n` is then a nkSym or something similar
  var totalParams = case n.kind
    of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit: <n.len
    else: 0

  var
    genericParams = s.ast[genericParamsPos].len
    expectedRegularParams = <s.typ.len
    givenRegularParams = totalParams - genericParams

  if totalParams > expectedRegularParams + genericParams:
    globalError(n.info, errWrongNumberOfArguments)

  result = newNodeI(nkArgList, n.info)
  for i in 1 .. givenRegularParams:
    result.addSon n.sons[i]

  for i in givenRegularParams+1 .. expectedRegularParams:
    let default = s.typ.n.sons[i].sym.ast
    if default.kind == nkEmpty:
      localError(n.info, errWrongNumberOfArguments)
    result.addSon default.copyTree

  for i in 1 .. genericParams:
    result.addSon n.sons[givenRegularParams + i]
  
var evalTemplateCounter* = 0
  # to prevent endless recursion in templates instantiation

proc evalTemplate*(n: PNode, tmpl, genSymOwner: PSym): PNode =
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    globalError(n.info, errTemplateInstantiationTooNested)
    result = n

  # replace each param by the corresponding node:
  var args = evalTemplateArgs(n, tmpl)
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
      globalError(result.info, errIllFormedAstX,
                  renderTree(result, {renderNoComments}))
  else:
    result = copyNode(body)
    ctx.instLines = body.kind notin {nkStmtList, nkStmtListExpr,
                                     nkBlockStmt, nkBlockExpr}
    if ctx.instLines: result.info = n.info
    for i in countup(0, safeLen(body) - 1):
      evalTemplateAux(body.sons[i], args, ctx, result)
  
  dec(evalTemplateCounter)
