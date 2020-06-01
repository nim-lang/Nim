import std/private/miscdollars

template flakyAssert*(cond: untyped, msg = "", notifySuccess = true) =
  ## API to deal with flaky or failing tests. This avoids disabling entire tests
  ## altogether so that at least the parts that are working are kept being
  ## tested. This also avoids making CI fail periodically for tests known to
  ## be flaky. Finally, for known failures, passing `notifySuccess = true` will
  ## log that the test succeeded, which may indicate that a bug was fixed
  ## "by accident" and should be looked into.
  const info = instantiationInfo(-1, true)
  const expr = astToStr(cond)
  if cond and not notifySuccess:
    discard # silent success
  else:
    var msg2 = ""
    toLocation(msg2, info.filename, info.line, info.column)
    if cond:
      # a flaky test is failing, we still report it but we don't fail CI
      msg2.add " FLAKY_SUCCESS "
    else:
      # a previously failing test is now passing, a pre-existing bug might've been
      # fixed by accidend
      msg2.add " FLAKY_FAILURE "
    msg2.add $expr & " " & msg
    echo msg2

import macros

template doAssertParserRaises*(exception: typedesc, s: static string) =
  # xxx not sure if there's a simpler way to pass a type (not as NimNode) to a macro
  # but this works. Note: generic macros would solve this and other issues
  # cleanly.
  block:
    macro doAssertParserRaises2(s2: static string): void =
      doAssertRaises(exception): discard parseExpr(s2)
    doAssertParserRaises2(s)
