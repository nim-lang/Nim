include "system/helpers"

when not declared(sysFatal):
  include "system/fatal"


proc raiseAssert*(msg: string) {.noinline, noReturn.} =
  sysFatal(AssertionError, msg)

proc failedAssertImpl*(msg: string) {.raises: [], tags: [].} =
  # trick the compiler to not list ``AssertionError`` when called
  # by ``assert``.
  type Hide = proc (msg: string) {.noinline, raises: [], noSideEffect,
                                    tags: [].}
  Hide(raiseAssert)(msg)

template assertImpl(cond: bool, msg: string, expr: string, enabled: static[bool]) =
  const loc = $instantiationInfo(-1, true)
  bind instantiationInfo
  mixin failedAssertImpl
  when enabled:
    # for stacktrace; fixes #8928 ; Note: `fullPaths = true` is correct
    # here, regardless of --excessiveStackTrace
    {.line: instantiationInfo(fullPaths = true).}:
      if not cond:
        failedAssertImpl(loc & " `" & expr & "` " & msg)

template assert*(cond: untyped, msg = "") =
  ## Raises ``AssertionError`` with `msg` if `cond` is false. Note
  ## that ``AssertionError`` is hidden from the effect system, so it doesn't
  ## produce ``{.raises: [AssertionError].}``. This exception is only supposed
  ## to be caught by unit testing frameworks.
  ##
  ## The compiler may not generate any code at all for ``assert`` if it is
  ## advised to do so through the ``-d:release`` or ``--assertions:off``
  ## `command line switches <nimc.html#command-line-switches>`_.
  const expr = astToStr(cond)
  assertImpl(cond, msg, expr, compileOption("assertions"))

template doAssert*(cond: untyped, msg = "") =
  ## same as ``assert`` but is always turned on regardless of ``--assertions``
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

template doAssertRaises*(exception: typedesc, code: untyped): typed =
  ## Raises ``AssertionError`` if specified ``code`` does not raise the
  ## specified exception. Example:
  ##
  ## .. code-block:: nim
  ##  doAssertRaises(ValueError):
  ##    raise newException(ValueError, "Hello World")
  var wrong = false
  when Exception is exception:
    try:
      if true:
        code
      wrong = true
    except Exception:
      discard
  else:
    try:
      if true:
        code
      wrong = true
    except exception:
      discard
    except Exception:
      raiseAssert(astToStr(exception) &
                  " wasn't raised, another error was raised instead by:\n"&
                  astToStr(code))
  if wrong:
    raiseAssert(astToStr(exception) & " wasn't raised by:\n" & astToStr(code))
