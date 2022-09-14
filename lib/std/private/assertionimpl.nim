when not declared(sysFatal):
  include "system/fatal"

import std/private/miscdollars
# ---------------------------------------------------------------------------
# helpers

type InstantiationInfo = tuple[filename: string, line: int, column: int]

proc `$`(info: InstantiationInfo): string =
  # The +1 is needed here
  # instead of overriding `$` (and changing its meaning), consider explicit name.
  result = ""
  result.toLocation(info.filename, info.line, info.column + 1)

# ---------------------------------------------------------------------------

when not defined(nimHasSinkInference):
  {.pragma: nosinks.}

proc raiseAssert*(msg: string) {.noinline, noreturn, nosinks.} =
  ## Raises an `AssertionDefect` with `msg`.
  sysFatal(AssertionDefect, msg)

proc failedAssertImpl*(msg: string) {.raises: [], tags: [].} =
  ## Raises an `AssertionDefect` with `msg`, but this is hidden
  ## from the effect system. Called when an assertion failed.
  # trick the compiler to not list `AssertionDefect` when called
  # by `assert`.
  # xxx simplify this pending bootstrap >= 1.4.0, after which cast not needed
  # anymore since `Defect` can't be raised.
  type Hide = proc (msg: string) {.noinline, raises: [], noSideEffect, tags: [].}
  cast[Hide](raiseAssert)(msg)

template assertImpl*(cond: bool, msg: string, expr: string, enabled: static[bool]) =
  when enabled:
    const
      loc = instantiationInfo(fullPaths = compileOption("excessiveStackTrace"))
      ploc = $loc
    bind instantiationInfo
    mixin failedAssertImpl
    {.line: loc.}:
      if not cond:
        failedAssertImpl(ploc & " `" & expr & "` " & msg)
