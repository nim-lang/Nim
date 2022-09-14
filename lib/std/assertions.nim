#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements extended assertion support.

import std/private/assertionimpl

export raiseAssert, failedAssertImpl

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
  when not defined(nimHasTemplateRedefinitionPragma):
    {.pragma: redefine.}
  template failedAssertImpl(msgIMPL: string): untyped {.dirty, redefine.} =
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
  template raisedForeign {.gensym.} = raiseAssert(begin & " raised foreign exception" & msgEnd)
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
  if wrong:
    raiseAssert(begin & " nothing was raised" & msgEnd)
