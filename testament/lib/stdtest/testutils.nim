import std/private/miscdollars
import std/strutils

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
  iterator splitLinesLhs(): string {.closure.} =
    for line in splitLines(lhs.strip):
      yield line

  var lhsIter = splitLinesLhs
  var currentLhs: string = strip(lhsIter())

  while currentLhs.len == 0 and not lhsIter.finished:
    currentLhs = strip(lhsIter())

  if lhsIter.finished:
    return true

  var rhs = rhs
  var pos = find(rhs, currentLhs)
  if pos < 0:
    return false
  else:
    inc(pos, currentLhs.len)
    rhs = rhs[pos .. ^1]

  iterator splitLinesRhs(): string {.closure.} =
    for line in splitLines(rhs.strip):
      yield line

  var rhsIter = splitLinesRhs

  var currentLine = strip(rhsIter())

  for line in lhsIter():
    let line = line.strip
    if line.len != 0:
      while line != currentLine:
        currentLine = strip(rhsIter())
        if rhsIter.finished:
          return false

    if rhsIter.finished:
      return false
  return true
