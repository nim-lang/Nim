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

var fs = newFutureStream[int]()

proc alpha() {.async.} =
  for i in 0 .. 5:
    await sleepAsync(1000)
    await fs.write(i)

  echo("Done")
  fs.complete()

proc beta() {.async.} =
  while not fs.finished:
    let (hasValue, value) = await fs.read()
    if hasValue:
      echo(value)

  echo("Finished")

asyncCheck alpha()
waitFor beta()

# TODO: Something like this should work eventually.
# proc delta(): FutureStream[string] {.async.} =
#   for i in 0 .. 5:
#     await sleepAsync(1000)
#     result.put($i)

#   return ""

# proc omega() {.async.} =
#   let fut = delta()
#   while not fut.finished():
#     echo(await fs.takeAsync())

#   echo("Finished")

# waitFor omega()