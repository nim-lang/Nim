##[
internal API for now, API subject to change
]##

# xxx move other git utilities here; candidate for stdlib.

import std/[os, osproc, strutils]

const commitHead* = "HEAD"

template retryCall*(maxRetry = 3, backoffDuration = 1.0, call: untyped): bool =
  ## Retry `call` up to `maxRetry` times with exponential backoff and initial
  ## duraton of `backoffDuration` seconds.
  ## This is in particular useful for network commands that can fail.
  runnableExamples:
    doAssert not retryCall(maxRetry = 2, backoffDuration = 0.1, false)
    var i = 0
    doAssert: retryCall(maxRetry = 3, backoffDuration = 0.1, (i.inc; i >= 3))
    doAssert retryCall(call = true)
  var result = false
  var t = backoffDuration
  for i in 0..<maxRetry:
    if call:
      result = true
      break
    if i == maxRetry - 1: break
    sleep(int(t * 1000))
    t = t * 2 # exponential backoff
  result

proc isGitRepo*(dir: string): bool =
  ## This command is used to get the relative path to the root of the repository.
  ## Using this, we can verify whether a folder is a git repository by checking
  ## whether the command success and if the output is empty.
  let (output, status) = execCmdEx("git rev-parse --show-cdup", workingDir = dir)
  # On Windows there will be a trailing newline on success, remove it.
  # The value of a successful call typically won't have a whitespace (it's
  # usually a series of ../), so we know that it's safe to unconditionally
  # remove trailing whitespaces from the result.
  result = status == 0 and output.strip() == ""
