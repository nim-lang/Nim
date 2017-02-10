discard """
  file: "tfuturestream.nim"
  exitcode: 0
  output: '''
0
1
2
3
4
5
Done
Finished
'''
"""
import asyncdispatch

var fs = newFutureStream[string]()

proc alpha() {.async.} =
  for i in 0 .. 5:
    await sleepAsync(1000)
    fs.put($i)

  fs.complete("Done")

proc beta() {.async.} =
  while not fs.finished:
    echo(await fs.takeAsync())

  echo("Finished")

asyncCheck alpha()
waitFor beta()

