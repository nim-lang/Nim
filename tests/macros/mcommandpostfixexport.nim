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

macro takesPragma*(arg: untyped): untyped =
  doAssert arg.kind == nnkPragmaExpr
  result = newStmtList()

takesPragma value {.commandParamPragma.}
