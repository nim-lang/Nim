discard """
  outputsub: "Error: unhandled exception: foobar"
  exitcode: 1
"""
import asyncdispatch

# Note: This is a test case for a bug.

proc accept(): Future[int] {.async.} =
  await sleepAsync(100)
  result = 4

proc recvLine(fd: int): Future[string] {.async.} =
  await sleepAsync(100)
  return "get"

proc processClient(fd: int) {.async.} =
  # these finish synchronously, we need some async delay to emulate this bug.
  var line = await recvLine(fd)
  var foo = line[0]
  if foo == 'g':
    raise newException(Exception, "foobar")

proc serve() {.async.} =

  while true:
    var fut = await accept()
    await processClient(fut)

when true:
  proc main =
    var fut = serve()
    fut.callback =
      proc () =
        if fut.failed:
          # This test ensures that this exception crashes the application
          # as it is not handled.
          raise fut.error
    runForever()
  main()
