##[
common git utilities to avoid re-implementing the same thing in different modules.
Eventually can migrate to stdlib or fusion once stabilizes.

internal API for now, API subject to change
]##

# xxx move other git utilities here; candidate for stdlib.

runnableExamples("-r:off"):
  ## not a test, just examples
  template test() = 
    let dir = "."
    template fn(a): untyped =
      echo astToStr(a) & ": " & $a
    fn getGitHash(dir)
    fn getGitDirty(dir, ignoreUntracked = true)
    fn getGitDirty(dir, ignoreUntracked = false)
    fn getGitHashHuman(dir)
  test()
  static: test()

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

proc stripLineEnd2(a: string): string =
  result = a
  stripLineEnd(result)

proc execCmdEx2(cmd: string, dir = "."): (string, int) =
  when nimvm:
    doAssert dir == "." # PRTEMP: this needs adjustment
    # consider using `{.experimental: "vmopsDanger".}` once it can be pushed
    result = gorgeEx(cmd)
  else:
    result = execCmdEx(cmd, workingDir = dir)
  # when (NimMajor, NimMinor, NimPatch) >= (1,5,1):
  when defined(nimHasCustomLiterals):
    result[0].stripLineEnd

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

proc getGitHash*(dir = "."): string =
  # `git rev-parse` is plumbing, preferable for scripting to `git log -n 1 --format=%H`
  # which is porcelain, and may change with user gitconfig
  let (outp, status) = execCmdEx2("git rev-parse HEAD", dir = dir)
  if status == 0: result = outp

proc getGitDirty*(dir = ".", ignoreUntracked: bool): bool =
  if ignoreUntracked:
    let (outp, status) = execCmdEx2("git diff --no-ext-diff --quiet", dir = dir)
    result = status != 0
  else:
    let (outp, status) = execCmdEx2("git status --porcelain --ignore-submodules -unormal", dir = dir)
    result = outp.len > 0

proc getGitHashHuman*(dir = "."): string =
  ## dirty bit helps when considering reproducibility
  result = getGitHash(dir)
  if result.len > 0:
    if getGitDirty(dir, ignoreUntracked = false):
      result.add "-dirty"
  else:
    result = "unknown"
