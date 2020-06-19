import asyncdispatch
import std/unittest

proc task() {.async.} =
  const tSleep = 40
  await sleepAsync(tSleep)

proc main() =
  var counter = 0
  var f = task()
  while not f.finished:
    inc(counter)
    poll(10)

  const slack = 1
    # because there is overhead in `async` + `sleepAsync`
    # as can be seen by increasing `tSleep` from 40 to 49, which increases the number
    # of failures.
  check counter <= 4 + slack

for i in 0 .. 10: main()
