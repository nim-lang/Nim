discard """
  exitcode: 0
  disabled: "windows"
  output: "Matched"
"""
import asyncdispatch, strutils

# Tests to ensure our exception trace backs are friendly.

# --- Simple test. ---
#
# What does this look like when it's synchronous?
#
# tasync_traceback.nim(23) tasync_traceback
# tasync_traceback.nim(21) a
# tasync_traceback.nim(18) b
# Error: unhandled exception: b failure [OSError]
#
# Good (not quite ideal, but gotta work within constraints) traceback,
# when exception is unhandled:
#
# <traceback for the unhandled exception>
# <very much a bunch of noise>
# <would be ideal to customise this>
# <(the code responsible is in excpt:raiseExceptionAux)>
# Error: unhandled exception: b failure
# ===============
# Async traceback
# ===============
#
# tasync_traceback.nim(23) tasync_traceback
#
# tasync_traceback.nim(21) a
# tasync_traceback.nim(18) b

var result = ""

proc b(): Future[int] {.async.} =
  if true:
    raise newException(OSError, "b failure")

proc a(): Future[int] {.async.} =
  return await b()

let aFut = a()
try:
  discard waitFor aFut
except Exception as exc:
  result.add(exc.msg & "\n")
result.add("\n")

# From #6803
proc bar(): Future[string] {.async.} =
  await sleepAsync(100)
  if true:
    raise newException(OSError, "bar failure")

proc foo(): Future[string] {.async.} = return await bar()

try:
  result.add(waitFor(foo()) & "\n")
except Exception as exc:
  result.add(exc.msg & "\n")
result.add("\n")

# Use re to parse the result
import re
const expected = """
b failure
Async traceback:
  tasync_traceback\.nim\(\d+?\)\s+?tasync_traceback
  asyncmacro\.nim\(\d+?\)\s+?a
  asyncmacro\.nim\(\d+?\)\s+?aNimAsyncContinue
    ## Resumes an async procedure
  tasync_traceback\.nim\(\d+?\)\s+?aIter
  asyncmacro\.nim\(\d+?\)\s+?b
  asyncmacro\.nim\(\d+?\)\s+?bNimAsyncContinue
    ## Resumes an async procedure
  tasync_traceback\.nim\(\d+?\)\s+?bIter
  #\[
    tasync_traceback\.nim\(\d+?\)\s+?tasync_traceback
    asyncmacro\.nim\(\d+?\)\s+?a
    asyncmacro\.nim\(\d+?\)\s+?aNimAsyncContinue
      ## Resumes an async procedure
    asyncmacro\.nim\(\d+?\)\s+?aIter
    asyncfutures\.nim\(\d+?\)\s+?read
  \]#
Exception message: b failure


bar failure
Async traceback:
  tasync_traceback\.nim\(\d+?\)\s+?tasync_traceback
  asyncdispatch\.nim\(\d+?\)\s+?waitFor
  asyncdispatch\.nim\(\d+?\)\s+?poll
    ## Processes asynchronous completion events
  asyncdispatch\.nim\(\d+?\)\s+?runOnce
  asyncdispatch\.nim\(\d+?\)\s+?processPendingCallbacks
    ## Executes pending callbacks
  asyncmacro\.nim\(\d+?\)\s+?barNimAsyncContinue
    ## Resumes an async procedure
  tasync_traceback\.nim\(\d+?\)\s+?barIter
  #\[
    tasync_traceback\.nim\(\d+?\)\s+?tasync_traceback
    asyncdispatch\.nim\(\d+?\)\s+?waitFor
    asyncdispatch\.nim\(\d+?\)\s+?poll
      ## Processes asynchronous completion events
    asyncdispatch\.nim\(\d+?\)\s+?runOnce
    asyncdispatch\.nim\(\d+?\)\s+?processPendingCallbacks
      ## Executes pending callbacks
    asyncmacro\.nim\(\d+?\)\s+?fooNimAsyncContinue
      ## Resumes an async procedure
    asyncmacro\.nim\(\d+?\)\s+?fooIter
    asyncfutures\.nim\(\d+?\)\s+?read
  \]#
Exception message: bar failure

"""

# TODO: is asyncmacro good enough location for fooIter traceback/debugging? just put the callsite info for all?

let resLines = splitLines(result.strip)
let expLines = splitLines(expected.strip)

if resLines.len != expLines.len:
  echo("Not matched! Wrong number of lines!")
  echo expLines.len
  echo resLines.len
  echo("Expected: -----------")
  echo expected
  echo("Gotten: -------------")
  echo result
  echo("---------------------")
  quit(QuitFailure)

var ok = true
for i in 0 ..< resLines.len:
  if not resLines[i].match(re(expLines[i])):
    echo "Not matched! Line ", i + 1
    echo "Expected:"
    echo expLines[i]
    echo "Actual:"
    echo resLines[i]
    ok = false

if ok:
  echo("Matched")
else:
  quit(QuitFailure)
