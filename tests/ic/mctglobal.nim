# Helper module for tcompiletimeglobal.nim (not a test itself; no `discard`).
#
# Exercises `{.compileTime.}` module-level globals across the NIF boundary: under
# `nim ic` this module is compiled to its own NIF and *loaded* (not semchecked)
# by the importer, so its compile-time globals must be eagerly initialized at
# load time. A macro that splices such a global into a `quote do:` otherwise
# reads a nil VM slot.

import macros

let injectedName {.compileTime.} = ident "ctgValue"

proc genAssign*(): NimNode =
  ## The order-fragile case: the CT global is read inside a proc that the macro
  ## calls, not in the macro's own `quote`. The lazy VM init attaches to the
  ## first vmgen'd reference, which need not be the first one executed.
  result = quote do:
    `injectedName` = 42

macro defineCtgValue*(): untyped =
  result = newStmtList()
  # Read the global via the helper proc FIRST, then via the macro's own quote,
  # so the proc's reference executes before the macro's: only eager init at load
  # time makes both see the initialized value.
  let assign = genAssign()
  result.add quote do:
    var `injectedName`: int
  result.add assign
