##[
internal API for now, API subject to change
]##

import std/[os,osproc,sugar,strutils]

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

proc nimbleInstall*(name: string, message: var string): bool =
  let cmd = "nimble install -y " & name
  let (outp, status) = execCmdEx(cmd)
  if status != 0:
    message = "'$1' failed:\n$2" % [cmd, outp]
    result = false
  else: result = true

when isMainModule:
  block:
    var msg: string
    let ok = actionRetry(maxRetry = 2, backoffDuration = 0.1):
      (proc(): bool = nimbleInstall("nonexistant", msg))
    doAssert "Package not found" in msg
    doAssert not ok
