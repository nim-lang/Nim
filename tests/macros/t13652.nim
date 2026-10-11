# bug #13652: getAst of a macro without result type used to crash
import std/macros

macro foo = discard

static:
  let list = newStmtList()
  list.add(getAst(foo()))
  doAssert list.len == 1
