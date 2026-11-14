discard """
  output: '''
finally: ok
defer: ok
nested: ok
'''
"""

# bug #26623: an exception passing through a `finally`/`defer` was lost when the
# cleanup called a routine (directly or indirectly) that contains a `try/except`.

proc cleanupQuiet() =
  try:
    discard
  except CatchableError:
    discard

proc cleanupNested() =
  cleanupQuiet()

proc viaFinally() =
  try:
    raise newException(ValueError, "outer")
  finally:
    cleanupQuiet()

proc viaDefer() =
  defer: cleanupQuiet()
  raise newException(ValueError, "outer")

proc viaNested() =
  try:
    raise newException(ValueError, "outer")
  finally:
    cleanupNested()

for (name, p) in [("finally", viaFinally), ("defer", viaDefer), ("nested", viaNested)]:
  try:
    p()
    echo name, ": BUG, outer exception lost"
  except ValueError:
    echo name, ": ok"
