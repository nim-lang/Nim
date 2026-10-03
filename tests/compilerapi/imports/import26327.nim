import std/[macrocache, macros]

const Tbl = CacheTable"standD"

macro reg(name: static[string]; path: static[string]): untyped =
  Tbl[name] = newTree(
    nnkImportStmt, newTree(nnkInfix, ident"as", newLit(path), ident(name))
  )
  result = newStmtList()

reg("myalias", "/tmp/opencode/standD/helper")
