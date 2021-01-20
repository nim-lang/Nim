discard """
  output: "OK"
"""

import asyncdispatch
import std/asyncfutures

proc recursiveWaiter2() {.async.} =
  try:
    await sleepAsync(500)
    await sleepAsync(500)
  except FutureCancelledError:
    discard
  await sleepAsync(500)

proc recursiveWaiter1() {.async.} =
  try:
    await recursiveWaiter2()
    await sleepAsync(1200)
  except FutureCancelledError:
    discard
  await sleepAsync(1200)

proc main() {.async.} =
  var fut = recursiveWaiter1()
  await sleepAsync(500)
  fut.complete()
  await fut
  await sleepAsync(2000)

try:
  waitFor(main())
  echo "OK"
except FutureError as e:
  echo "NOT OK " & e.msg
except FutureCancelledError:
  echo "CANCELLED"
