##[
internal API for now, API subject to change
]##

import std/os

proc actionRetry*(maxRetry: int, backoffDuration: float, action: proc(): bool): bool =
  ## retry `action` up to `maxRetry` times with exponential backoff and initial
  ## duraton of `backoffDuration` seconds
  var t = backoffDuration
  for i in 0..<maxRetry:
    if action(): return true
    if i == maxRetry - 1: break
    sleep(int(t * 1000))
    t = t * 2 # exponential backoff
  return false

when isMainModule:
  block:
    var msg: string
    let ok = actionRetry(maxRetry = 2, backoffDuration = 0.1):
      (proc(): bool = msg = "Package not found"; false)
    doAssert "Package not found" == msg
    doAssert not ok
