discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
0
inner handled: outer
1
ok
true
start
ok async
true
'''
"""

# bug #26291: nested try/except with a yield inside an except branch,
# followed by another yield, crashed with SIGSEGV in popCurrentException.

iterator it(): int {.closure.} =
  try:
    raise newException(IOError, "outer")
  except IOError:
    try:
      yield 0
      raise newException(IOError, "inner")
    except IOError:
      discard
    echo "inner handled: ", getCurrentExceptionMsg()
    yield 1
    doAssert getCurrentExceptionMsg() == "outer"
  echo "ok"

for x in it(): echo x
echo getCurrentException() == nil

import std/asyncdispatch

proc work(fail: bool) {.async.} =
  await sleepAsync(1)
  if fail: raise newException(IOError, "retry failed")

proc pump() {.async.} =
  try:
    raise newException(IOError, "lost")
  except CatchableError:
    echo "start"
    var attempt = 0
    while attempt < 2:
      try:
        await work(attempt == 0)
        break
      except CatchableError:
        discard
      inc attempt
    doAssert getCurrentExceptionMsg() == "lost"
  echo "ok async"

waitFor pump()
echo getCurrentException() == nil
