discard """
  disabled: "win"
  disabled: "freertos"
  targets: "c"
  matrix: "-d:threadsafe --threads:on"
  timeout: 10
  output: "started\nstopped\nquit\n"
"""
# PURPOSE
#   Test setting and unsetting non-blocking IO mode on stdin, stdout, and stderr.
#   Test the exception handing behavior.
# DESIGN
#   Create a parent process.
#   Parent tries setting an invalid file handle to non-blocking and then catches the error.
#   Parent creates child process.
#   Parent waits on child's non-blocking stdout and stderr.
#   Child waits on non-blocking stdin.
#   Parent sends `start` command to child on stdin.
#   Child responds by writing `started` to its stdout and then waits on blocking stdin.
#   Parent reads `started` on child's stdout and responds with `stop` on stdin and then closes stdin.
#   Child catches IO exception from closed stdin and responds with `stopped` on stdout and quits.
#   Parent gets signaled of quit, prints `quit` and quits.
when not (compileOption("threads") and defined(threadsafe)):
  {.error: "-d:threadsafe --threads:on needed".}

import std/[selectors, osproc, streams, os, posix]

type
  Handler = proc() {.closure.}
  ErrorHandler = proc(code: OSErrorCode) {.closure.}
  Handlers = tuple[process, stdout, stderr: tuple[handle: int, onEvent: Handler, onError: ErrorHandler]]
  Monitor = enum
    StdIn, StdOut, StdErr, Quit

const blockIndefinitely = -1

proc drain(f: File): string =
  while not f.endOfFile:
    result &= f.readChar

proc drain(f: Stream): string =
  while not f.atEnd:
    result &= f.readChar

proc monitor(arg: Handlers) {.thread.} =
  var watcher = newSelector[Monitor]()
  let processSignal = watcher.registerProcess(arg.process.handle, Quit)
  watcher.registerHandle(arg.stdout.handle, {Event.Read}, StdOut)
  watcher.registerHandle(arg.stderr.handle, {Event.Read}, StdErr)
  {.gcsafe.}:
    block running:
      while true:
        let events = watcher.select(blockIndefinitely)
        for ready in events.items:
          var kind: Monitor = watcher.getData(ready.fd)
          case kind:
          of StdIn: discard
          of StdOut:
            if Event.Read in ready.events:
              arg.stdout.onEvent()
            if Event.Error in ready.events:
              if ready.errorCode.int == ECONNRESET:
                watcher.unregister(ready.fd)
              else:
                arg.stderr.onError(ready.errorCode)
                break running
          of StdErr:
            if Event.Read in ready.events:
              arg.stderr.onEvent()
            if Event.Error in ready.events:
              if ready.errorCode.int == ECONNRESET:
                watcher.unregister(ready.fd)
              else:
                arg.stderr.onError(ready.errorCode)
                break running
          of Quit:
            arg.process.onEvent()
            break running
  watcher.unregister(processSignal)
  watcher.close

proc parent =
  try:
    # test that exception is thrown
    setNonBlocking(-1)
    doAssert(false, "setNonBlocking should raise exception for invalid input")
  except:
    discard
  var child = startProcess(
    getAppFilename(),
    args = ["child"],
    options = {}
  )
  var thread: Thread[Handlers]
  setNonBlocking(child.outputHandle)
  setNonBlocking(child.errorHandle)
  proc onEvent() =
    let output = child.outputStream.drain
    stdout.write output
    if output == "started\n":
      child.inputStream.write "stop"
      child.inputStream.close
  proc onError(code: OSErrorCode) {.closure.} =
    doAssert(false, "error " & $code)
  proc onQuit() {.closure.} =
    echo "quit"
  createThread(thread, monitor, (
    (child.processID.int, onQuit, onError),
    (child.outputHandle.int, onEvent, onError),
    (child.errorHandle.int, onEvent, onError)))
  child.inputStream.write "start"
  child.inputStream.flush
  doAssert(child.waitForExit == 0)
  joinThread(thread)

proc child =
  var watcher = newSelector[Monitor]()
  watcher.registerHandle(stdin.getOsFileHandle.int, {Event.Read}, StdIn)
  setNonBlocking(stdin)
  block running:
    while true:
      let events = watcher.select(blockIndefinitely)
      for ready in events.items:
        var kind: Monitor = watcher.getData(ready.fd)
        case kind:
        of StdIn:
          if stdin.drain == "start": # this would normally block
            echo "started" # piped to parent
            break running
        else: discard
  watcher.close
  setNonBlocking(stdin, false)
  try:
    # this line ensures the above setNonBlocking call is distinguisable from
    # a no-op; "stopped" would never be sent
    if not stdin.endOfFile:
      echo stdin.readAll
  except: # this will raise when stdin is closed by the parent
    doAssert(osLastError().int == EAGAIN)
    echo "stopped" # piped to parent

proc main =
  if paramCount() > 0:
    child()
  else:
    parent()

main()
