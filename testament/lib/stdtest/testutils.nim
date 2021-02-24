import std/private/miscdollars
import std/strutils
from std/os import getEnv

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

proc greedyOrderedSubsetLines*(lhs, rhs: string): bool =
  ## returns true if each stripped line in `lhs` appears in rhs, using a greedy matching.
  let rhs = rhs.strip
  var currentPos = 0
  for line in lhs.strip.splitLines:
    currentPos = rhs.find(line.strip, currentPos)
    if currentPos < 0:
      return false
  return true

template enableRemoteNetworking*: bool =
  ## Allows contolling whether to run some test at a statement-level granularity.
  ## Using environment variables simplifies propagating this all the way across
  ## process calls, e.g. `testament all` calls itself, which in turns invokes
  ## a `nim` invocation (possibly via additional intermediate processes).
  getEnv("NIM_TESTAMENT_REMOTE_NETWORKING") == "1"

template whenRuntimeJs*(bodyIf, bodyElse) =
  ##[
  Behaves as `when defined(js) and not nimvm` (which isn't legal yet).
  pending improvements to `nimvm`, this sugar helps; use as follows:

  whenRuntimeJs:
    doAssert defined(js)
    when nimvm: doAssert false
    else: discard
  do:
    discard
  ]##
  when nimvm: bodyElse
  else:
    when defined(js): bodyIf
    else: bodyElse

template whenVMorJs*(bodyIf, bodyElse) =
  ## Behaves as: `when defined(js) or nimvm`
  when nimvm: bodyIf
  else:
    when defined(js): bodyIf
    else: bodyElse
