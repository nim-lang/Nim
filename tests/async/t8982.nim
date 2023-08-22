discard """
output: '''
timeout
runForever should throw ValueError, this is expected
'''
"""


import asyncdispatch

proc failingAwaitable(p: int) {.async.} =
  await sleepAsync(500)
  if p > 0:
    raise newException(Exception, "my exception")

proc main() {.async.} =
  let fut = failingAwaitable(1)
  try:
    await fut or sleepAsync(100)
    if fut.finished:
      echo "finished"
    else:
      echo "timeout"
  except:
    echo "failed"


# Previously this would raise "An attempt was made to complete a Future more than once."
try:
  asyncCheck main()
  runForever()
except ValueError:
  echo "runForever should throw ValueError, this is expected"
