#[
MOVE here:
  proc evalAux(): PNode =
]#

import compiler/ast
import compiler/options

proc isMacroRealGeneric*(s: PSym): bool {.exportc.} =
  if s.kind != skMacro: return false
  if s.ast == nil: return false
  let n = s.ast
  if n[genericParamsPos].kind == nkEmpty: return false
  for ai in n[genericParamsPos]:
    if ai.typ.kind == tyAliasSym:
      return true
proc resolveAliasSym*(n: PNode): PNode =
  #[
  `fun(arg)` where return type is tyAliasSym
  if it returns a template `bar()` where bar is an iterator, it'd have no type if expanded
  ]#
  result = n
  if result!=nil and result.typ != nil and result.typ.kind == tyAliasSym:
    case result.kind
    of {nkStmtListExpr,nkBlockExpr}:
      # simplify node
      # CHECKME
      let typ = result.typ
      # result = newSymNode(sym2)
      result = newSymNode(typ.n.sym)
      # CHECKME
      # result.info = n.info
      result.info = typ.n.info
      result.typ = typ
    of nkSym:
      # `nkStmtListExpr` reserved to declare lambda helper syntaxes
      if result.sym.kind == skAliasGroup: # TODO: instead assert result.sym.kind == skAliasGroup
        discard
      elif result.sym.kind == skResult:
        # D20190816T205304
        discard
    else: # the alias is resolved
      # TODO: fold in qualifiedLookUp?
      doAssert result.typ.n != nil
      # nil would mean a aliasSem param was not instantiated; for macros, this requires macro instantiation
      result = result.typ.n.sym.nodeAliasGroup
