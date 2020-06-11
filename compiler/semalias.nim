import "."/[ast,options]

{.emit: "NIM_EXTERNC".} # for bootstrapping; remove after 0.21, refs #12144
proc isMacroRealGeneric*(s: PSym): bool {.exportc.} =
  if s.kind != skMacro: return false
  if s.ast == nil: return false
  let n = s.ast
  if n[genericParamsPos].kind == nkEmpty: return false
  for ai in n[genericParamsPos]:
    if ai.typ.kind == tyAliasSym:
      return true

proc resolveAliasSym*(n: PNode, forceResolve = false): PNode =
  #[
  `fun(arg)` where return type is tyAliasSym
  if it returns a template `bar()` where bar is an iterator, it'd have no type if expanded
  ]#
  result = n
  if result!=nil and result.typ != nil and result.typ.kind == tyAliasSym:
    case result.kind
    of {nkStmtListExpr, nkBlockExpr}:
      # allows defining things like lambdaIter, lambdaIt, a~>a*2 sugar
      let typ = result.typ
      result = newSymNode(typ.n.sym)
      result.info = typ.n.info
      result.typ = typ
    of nkSym:
      if result.sym.kind == skAliasGroup:
        if forceResolve: result = result.sym.nodeAliasGroup
      elif result.sym.kind == skResult:
        discard
    else: # the alias is resolved
      doAssert result.typ.n != nil
      # nil would mean a aliasSem param was not instantiated; for macros, this
      # requires macro instantiation
      result = result.typ.n.sym.nodeAliasGroup
