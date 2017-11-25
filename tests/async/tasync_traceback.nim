discard """
  exitcode: 0
  output: '''
b failure
Async traceback:
  tasync_traceback.nim(49) tasync_traceback
  tasync_traceback.nim(47) a
  tasync_traceback.nim(44) b
Exception message: b failure
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
