discard """
  output: '''
1
2
'''
"""

# bug #13171: the current exception was reset to nil inside an `except`
import std/asyncdispatch
proc y(): Future[void] {.async.} =
  discard
proc x(): Future[void] {.async.} =
  try:
    await y()
  except Exception:
    discard
try:
  raise newException(Exception, "")
except Exception:
  asyncCheck x()
  echo 1
echo 2
