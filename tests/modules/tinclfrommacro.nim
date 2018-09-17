import macros

# bug #8038
macro incM(): untyped =
  result = newTree(nnkIncludeStmt, newStrLitNode("definitions.nim"))
incM()

# bug #7466
macro inpM(): untyped =
  result = newTree(nnkImportStmt, newStrLitNode("definitions"))
inpM()
