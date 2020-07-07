when not declared(sysFatal):
  include "system/fatal"

import std/private/miscdollars
# ---------------------------------------------------------------------------
# helpers

type InstantiationInfo = tuple[filename: string, line: int, column: int]

proc `$`(x: int): string {.magic: "IntToStr", noSideEffect.}
proc `$`(info: InstantiationInfo): string =
  # The +1 is needed here
  # instead of overriding `$` (and changing its meaning), consider explicit name.
  result = ""
  result.toLocation(info.filename, info.line, info.column+1)

# ---------------------------------------------------------------------------

when not defined(nimHasSinkInference):
  {.pragma: nosinks.}

proc raiseAssert*(msg: string) {.noinline, noreturn, nosinks.} =
  sysFatal(AssertionDefect, msg)

proc failedAssertImpl*(msg: string) {.raises: [], tags: [], noinline.} =
  # trick the compiler to not list ``AssertionDefect`` when called
  # by ``assert``.
  type Hide = proc (msg: string) {.noinline, raises: [], noSideEffect,
                                    tags: [].}
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
        # this could take into account `when nimvm`
        when defined(nimDisableAssertMsgs):
          # see bug #14905
          # minor point: for some reason "?" gives better performance than ""
          # which cgen's to `NIM_NIL` but this may need further investigation.
          # This generates a single function in cgen regardless of which assert
          # it came from.
          failedAssertImpl("?")
        elif defined(nimDisableAssertComputedMsgs):
          # only disable computed messages, so that we can simply call a function
          # with no arguments, which puts low pressure on IR cache. Note that
          # this still can incur some cost because each assert generates its own
          # C function in this case, but at least hot spots should not be affected
          # as much.
          const msg2 = ploc & " `" & expr & "` " & (when msg is static: msg else: "<ommitted>")
          (proc(){.noinline.}=failedAssertImpl(msg2))()
        else:
          failedAssertImpl(ploc & " `" & expr & "` " & msg)

template assert*(cond: untyped, msg = "") =
  ## Raises ``AssertionDefect`` with `msg` if `cond` is false. Note
  ## that ``AssertionDefect`` is hidden from the effect system, so it doesn't
  ## produce ``{.raises: [AssertionDefect].}``. This exception is only supposed
  ## to be caught by unit testing frameworks.
  ##
  ## The compiler may not generate any code at all for ``assert`` if it is
  ## advised to do so through the ``-d:danger`` or ``--assertions:off``
  ## `command line switches <nimc.html#compiler-usage-commandminusline-switches>`_.
  ##
  ## .. code-block:: nim
  ##   static: assert 1 == 9, "This assertion generates code when not built with -d:danger or --assertions:off"
  const expr = astToStr(cond)
  assertImpl(cond, msg, expr, compileOption("assertions"))

template doAssert*(cond: untyped, msg = "") =
  ## Similar to ``assert`` but is always turned on regardless of ``--assertions``.
  ##
  ## .. code-block:: nim
  ##   static: doAssert 1 == 9, "This assertion generates code when built with/without -d:danger or --assertions:off"
  const expr = astToStr(cond)
  assertImpl(cond, msg, expr, true)

template onFailedAssert*(msg, code: untyped): untyped {.dirty.} =
  ## Sets an assertion failure handler that will intercept any assert
  ## statements following `onFailedAssert` in the current module scope.
  ##
  ## .. code-block:: nim
  ##  # module-wide policy to change the failed assert
  ##  # exception type in order to include a lineinfo
  ##  onFailedAssert(msg):
  ##    var e = new(TMyError)
  ##    e.msg = msg
  ##    e.lineinfo = instantiationInfo(-2)
  ##    raise e
  ##
  template failedAssertImpl(msgIMPL: string): untyped {.dirty.} =
    let msg = msgIMPL
    code

template doAssertRaises*(exception: typedesc, code: untyped) =
  ## Raises ``AssertionDefect`` if specified ``code`` does not raise `exception`.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  doAssertRaises(ValueError):
  ##    raise newException(ValueError, "Hello World")
  var wrong = false
  const begin = "expected raising '" & astToStr(exception) & "', instead"
  const msgEnd = " by: " & astToStr(code)
  template raisedForeign = raiseAssert(begin & " raised foreign exception" & msgEnd)
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
    except Exception as e: raiseAssert(begin & " raised '" & $e.name & "'" & msgEnd)
    except: raisedForeign()
  if wrong:
    raiseAssert(begin & " nothing was raised" & msgEnd)
