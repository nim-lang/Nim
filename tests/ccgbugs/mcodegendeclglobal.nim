var codegenDeclGlobal* {.codegenDecl: "$# /* custom declaration */ $#".} = 123

proc readCodegenDeclGlobal*(): int {.inline.} =
  codegenDeclGlobal
