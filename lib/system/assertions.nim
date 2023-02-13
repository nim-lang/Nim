## This module provides various assertion utilities.
##
## **Note:** This module is reexported by `system` and thus does not need to be
## imported directly (with `system/assertions`).

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

template assertImpl(cond: bool, msg: string, expr: string, enabled: static[bool]) =
  when enabled:
    const
      loc = instantiationInfo(fullPaths = compileOption("excessiveStackTrace"))
      ploc = $loc
    bind instantiationInfo
    mixin failedAssertImpl
    {.line: loc.}:
      if not cond:
        failedAssertImpl(ploc & " `" & expr & "` " & msg)

template assert*(cond: untyped, msg = "") =
  ## Raises `AssertionDefect` with `msg` if `cond` is false. Note
  ## that `AssertionDefect` is hidden from the effect system, so it doesn't
  ## produce `{.raises: [AssertionDefect].}`. This exception is only supposed
  ## to be caught by unit testing frameworks.
  ##
  ## No code will be generated for `assert` when passing `-d:danger` (implied by `--assertions:off`).
  ## See `command line switches <nimc.html#compiler-usage-commandminusline-switches>`_.
  runnableExamples: assert 1 == 1
  runnableExamples("--assertions:off"):
    assert 1 == 2 # no code generated, no failure here
  runnableExamples("-d:danger"): assert 1 == 2 # ditto
  assertImpl(cond, msg, astToStr(cond), compileOption("assertions"))

template doAssert*(cond: untyped, msg = "") =
  ## Similar to `assert <#assert.t,untyped,string>`_ but is always turned on regardless of `--assertions`.
  runnableExamples:
    doAssert 1 == 1 # generates code even when built with `-d:danger` or `--assertions:off`
  assertImpl(cond, msg, astToStr(cond), true)

template onFailedAssert*(msg, code: untyped): untyped {.dirty.} =
  ## Sets an assertion failure handler that will intercept any assert
  ## statements following `onFailedAssert` in the current scope.
  runnableExamples:
    type MyError = object of CatchableError
      lineinfo: tuple[filename: string, line: int, column: int]
    # block-wide policy to change the failed assert exception type in order to
    # include a lineinfo
    onFailedAssert(msg):
      raise (ref MyError)(msg: msg, lineinfo: instantiationInfo(-2))
    doAssertRaises(MyError): doAssert false
  template failedAssertImpl(msgIMPL: string): untyped {.dirty.} =
    let msg = msgIMPL
    code

template doAssertRaises*(exception: typedesc, code: untyped) =
  ## Raises `AssertionDefect` if specified `code` does not raise `exception`.
  runnableExamples:
    doAssertRaises(ValueError): raise newException(ValueError, "Hello World")
    doAssertRaises(CatchableError): raise newException(ValueError, "Hello World")
    doAssertRaises(AssertionDefect): doAssert false
  var wrong = false
  const begin = "expected raising '" & astToStr(exception) & "', instead"
  const msgEnd = " by: " & astToStr(code)
  template raisedForeign = raiseAssert(begin & " raised foreign exception" & msgEnd)
  {.warning[BareExcept]:off.}
  when Exception is exception:
    try:
      if true:
        code
      wrong = true
    except Exception as e: discard
    except: raisedForeign()
  else:
    try:
      if true:
        code
      wrong = true
    except exception:
      discard
    except Exception as e:
      mixin `$` # alternatively, we could define $cstring in this module
      raiseAssert(begin & " raised '" & $e.name & "'" & msgEnd)
    except: raisedForeign()
  {.warning[BareExcept]:on.}
  if wrong:
    raiseAssert(begin & " nothing was raised" & msgEnd)
