import macros

# Necessary code to update the AST on a symbol across module boundaries when
# processed by a type macro. Used by a test of a corresponding name of this
# file.

macro rename(n: typed): untyped =
  result = copyNimTree(n)
  # turn exported nnkSym -> nnkPostfix(*, nnkIdent), forcing re-sem
  result[0] = nnkPostfix.newTree(ident"*").add:
    n.name.strVal.ident

macro unexport(n: typed): untyped =
  result = copyNimTree(n)
  # turn nnkSym -> nnkIdent, forcing re-sem and dropping any exported-ness
  # that might be present
  result[0] = n.name.strVal.ident

proc foo*() {.unexport.} = discard
proc bar() {.rename.} = discard