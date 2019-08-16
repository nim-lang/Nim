
import macros

macro translateEnum*(selector: string; x: typedesc[enum]): untyped =
  result = newTree(nnkCaseStmt, selector)
  let t = getType(getType(x))
  expectKind(t, nnkBracketExpr)
  expectKind(t[1], nnkEnumTy)
  let enumType = t[1]
  for j in 1..<enumType.len:
    let i = enumType[j]
    template asgni(i) {.dirty.} = result = i
    result.add newTree(nnkOfBranch, newLit("n" & $i), getAst(asgni(i)))

  template errorCase(selector) {.dirty.} =
    internalError(c.config, c.debug[pc], "invalid kind: " & selector)

  result.add newTree(nnkElse, getAst(errorCase(selector)))

when isMainModule:
  import ast

  var x = "nnkObjConstr"
  var result: TNodeKind
  translateEnum(x, TNodeKind)
  echo result
