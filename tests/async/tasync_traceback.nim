discard """
  exitcode: 0
  output: '''
b failure
Async traceback:
  tasync_traceback.nim(75) tasync_traceback
  asyncmacro.nim(393)      a
  asyncmacro.nim(43)       cb0
  └─Resumes an async procedure
  asyncfutures.nim(211)    callback=
  asyncfutures.nim(190)    addCallback
  asyncfutures.nim(53)     callSoon
  asyncmacro.nim(34)       cb0
  └─Resumes an async procedure
  asyncmacro.nim(0)        aIter
  asyncfutures.nim(355)    read
  tasync_traceback.nim(73) a
  tasync_traceback.nim(70) b
Exception message: b failure
Exception type:

bar failure
Async traceback:
  tasync_traceback.nim(91) tasync_traceback
  asyncdispatch.nim(1204)  waitFor
  asyncdispatch.nim(1253)  poll
  └─Processes asynchronous completion events
  asyncdispatch.nim(181)   processPendingCallbacks
  └─Executes pending callbacks
  asyncmacro.nim(34)       cb0
  └─Resumes an async procedure
  asyncmacro.nim(0)        fooIter
  asyncfutures.nim(355)    read
  tasync_traceback.nim(86) barIter
Exception message: bar failure
Exception type:'''
"""
import asyncdispatch

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

proc b(): Future[int] {.async.} =
  if true:
    raise newException(OSError, "b failure")

proc a(): Future[int] {.async.} =
  return await b()

let aFut = a()
try:
  discard waitFor aFut
except Exception as exc:
  echo exc.msg
echo()

# From #6803
proc bar(): Future[string] {.async.} =
  await sleepAsync(100)
  if true:
    raise newException(OSError, "bar failure")

proc foo(): Future[string] {.async.} = return await bar()

try:
  echo waitFor(foo())
except Exception as exc:
  echo exc.msg
echo()