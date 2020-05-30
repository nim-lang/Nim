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

for i in 0 .. 4: main()
