##[
internal API for now, API subject to change
]##

#[
PRTEMP: was: actionRetry 621384b8efce7def08faeb9bc63289a4a88c3a59
]#

import std/[os]

proc retryCall*(maxRetry = 3, backoffDuration = 1.0, call: proc(): bool): bool =
  ## retry `call` up to `maxRetry` times with exponential backoff and initial
  ## duraton of `backoffDuration` seconds
  runnableExamples:
    doAssert not retryCall(maxRetry = 2, backoffDuration = 0.1, proc(): bool = false)
    var i = 0
    doAssert retryCall(maxRetry = 3, backoffDuration = 0.1, proc(): bool = (i.inc; i >= 3))
    doAssert retryCall(call = proc(): bool = true)

  var t = backoffDuration
  for i in 0..<maxRetry:
    if call(): return true
    if i == maxRetry - 1: break
    sleep(int(t * 1000))
    t = t * 2 # exponential backoff
  return false
