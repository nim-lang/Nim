import macros

macro signature*(name, body: untyped): untyped =
  doAssert name.kind == nnkPostfix
  result = quote do:
    type `name` = object
      value*: int

signature Thing*:
  discard

signature Spaced* :
  discard

signature SpacedBeforeStar * :
  discard

macro signatureWithFlag*(flag, name, body: untyped): untyped =
  doAssert flag.eqIdent("public")
  doAssert name.kind == nnkPostfix
  result = quote do:
    type `name` = object
      value*: int

signatureWithFlag public, Other*:
  discard

macro takesInfix*(arg, body: untyped): untyped =
  doAssert arg.kind == nnkInfix
  doAssert arg[0].eqIdent("*")
  result = newStmtList()

takesInfix 2 * 3:
  discard

macro takesIdentInfix*(arg: untyped): untyped =
  doAssert arg.kind == nnkInfix
  doAssert arg[0].eqIdent("*")
  doAssert arg[1].eqIdent("left")
  doAssert arg[2].eqIdent("right")
  result = newStmtList()

takesIdentInfix left*right
takesIdentInfix left * right

macro takesGStrLit*(arg: untyped): untyped =
  doAssert arg.kind == nnkCallStrLit
  doAssert arg[0].eqIdent("tag")
  result = newStmtList()

takesGStrLit tag"1"

macro takesMulAssign*(arg: untyped): untyped =
  doAssert arg.kind == nnkInfix
  doAssert arg[0].eqIdent("*=")
  result = newStmtList()

takesMulAssign value *= 2

macro takesPragma*(arg: untyped): untyped =
  doAssert arg.kind == nnkPragmaExpr
  result = newStmtList()

takesPragma value {.commandParamPragma.}

macro module*(args: varargs[untyped]): untyped =
  doAssert args.len == 1
  let alias = args[0]
  doAssert alias.kind == nnkExprEqExpr
  doAssert alias[0].kind == nnkPostfix
  doAssert alias[0][0].eqIdent("*")
  doAssert alias[0][1].eqIdent("UserIdSet") or
    alias[0][1].eqIdent("SpacedAlias")
  doAssert alias[1].kind == nnkCurlyExpr
  let name = alias[0]
  result = quote do:
    type `name` = object
      value*: int

module UserIdSet* = SortedSet{UserById}
module SpacedAlias * = SortedSet{UserById}
