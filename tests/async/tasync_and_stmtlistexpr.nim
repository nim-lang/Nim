discard """
  exitcode: 0
"""
# Regression test: variables declared via template/macro expansion in the
# second operand of `and`/`or` inside an async proc must be accessible in
# the enclosing `if` body. Previously `lowerStmtListExprs` in closureiters.nim
# placed those statements in `ifBody` (nested scope) instead of the outer
# `result`, causing "use of undeclared identifier" C errors.
import std/asyncdispatch, std/options

template bindOpt(name: untyped; expr: untyped): bool =
  let opt = expr
  let name {.inject.} = if opt.isSome: opt.get() else: 0
  opt.isSome

proc test() {.async.} =
  proc getA(): Future[Option[int]] {.async.} = return some(1)
  proc getB(): Option[int] = some(2)

  if bindOpt(a, await getA()) and bindOpt(b, getB()):
    doAssert a == 1
    doAssert b == 2
  else:
    doAssert false, "bindings should have succeeded"

waitFor test()

proc testAndShortCircuit() {.async.} =
  # When the second operand of `and` is a plain call (not a stmtListExpr),
  # it must still be short-circuited when the first operand is false.
  var called = false
  proc sideEffect(): bool =
    called = true
    return true

  proc getA(): Future[Option[int]] {.async.} = return none(int)

  if bindOpt(a, await getA()) and sideEffect():
    doAssert false, "first operand failed, should not enter branch"

  doAssert not called, "plain non-stmtListExpr second operand must be short-circuited (and)"

waitFor testAndShortCircuit()

proc testOrShortCircuit() {.async.} =
  # When the second operand of `or` is a plain call (not a stmtListExpr),
  # it must still be short-circuited when the first operand is true.
  var called = false
  proc sideEffect(): bool =
    called = true
    return false

  proc getA(): Future[Option[int]] {.async.} = return some(1)

  if bindOpt(a, await getA()) or sideEffect():
    doAssert a == 1
  else:
    doAssert false, "first operand succeeded, should enter branch"

  doAssert not called, "plain non-stmtListExpr second operand must be short-circuited (or)"

waitFor testOrShortCircuit()
