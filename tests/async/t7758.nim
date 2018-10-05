discard """
  file: "t7758.nim"
  exitcode: 0
"""
import asyncdispatch

proc task() {.async.} =
  await sleepAsync(40)

proc main() =
  var counter = 0
  var f = task()
  while not f.finished:
    inc(counter)
    poll(10)

  doAssert counter <= 4

for i in 0 .. 10: main()