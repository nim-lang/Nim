##[
internal API for now, API subject to change
]##

# xxx move other git utilities here; candidate for stdlib.

import std/[os, osproc, strutils, tempfiles]

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

proc diffStrings*(a, b: string): string =
  runnableExamples:
    let a = "ok1\nok2\nok3"
    let b = "ok1\nok2 alt\nok3"
    let c = diffStrings(a, b)
    echo c
    let c2 = diffStrings(a, a)
    echo c2

  template tmpFileImpl(prefix, str): auto =
    # pending https://github.com/nim-lang/Nim/pull/17889
    # let (fd, path) = createTempFile(prefix, "")
    let path = genTempPath(prefix, "")
    writeFile(path, str)
    path
  let patha = tmpFileImpl("diffStrings_a_", a)
  let pathb = tmpFileImpl("diffStrings_b_", b)
  defer:
    removeFile(patha)
    removeFile(pathb)
  # could be customized, e.g. non-git diff with `diff -uNdr`, or with git diff options.
  var status = 0
  (result, status) = execCmdEx("git diff --no-index $1 $2" % [patha.quoteShell, pathb.quoteShell])
  echo status
