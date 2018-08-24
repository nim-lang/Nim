discard """
  file: "t7758.nim"
  exitcode: 0
  disabled: true
"""
import asyncdispatch

proc task() {.async.} =
  await sleepAsync(1000)

when isMainModule:
  var counter = 0
  var f = task()
  while not f.finished:
    inc(counter)
    poll()

doAssert counter == 2