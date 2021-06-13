import macros

# Necessary code to update the AST on a symbol across module boundaries when
# processed by a type macro. Used by a test of a corresponding name of this
# file.

macro eexport(n: typed): untyped =
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
proc bar() {.eexport.} = discard

proc foooof*() {.unexport, eexport, unexport.} = discard
proc barrab() {.eexport, unexport, eexport.} = discard

macro eexportMulti(n: typed): untyped =
  # use the call version of `eexport` macro for one or more decls
  result = copyNimTree(n)
  for i in 0..<result.len:
    result[i] = newCall(ident"eexport", result[i])

macro unexportMulti(n: typed): untyped =
  # use the call version of `unexport` macro for one or more decls
  result = copyNimTree(n)
  for i in 0..<result.len:
    result[i] = newCall(ident"unexport", result[i])

unexportMulti:
  proc oof*() = discard

eexportMulti:
  proc rab() = discard
  proc baz*() = discard