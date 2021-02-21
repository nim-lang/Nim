discard """
  output: '''
OK
'''
"""

when defined(upcoming):
  import asyncdispatch, times, streams, posix
  from ioselectors import ioselSupportedPlatform

  proc delayedSet(ev: AsyncEvent, timeout: int): Future[void] {.async.} =
    await sleepAsync(timeout)
    ev.trigger()

  proc waitEvent(ev: AsyncEvent, closeEvent = false): Future[void] =
    var retFuture = newFuture[void]("waitEvent")
    proc cb(fd: AsyncFD): bool =
      retFuture.complete()
      if closeEvent:
        return true
      else:
        return false
    addEvent(ev, cb)
    return retFuture

  proc eventTest() =
    var event = newAsyncEvent()
    var fut = waitEvent(event)
    asyncCheck(delayedSet(event, 500))
    waitFor(fut or sleepAsync(1000))
    if not fut.finished:
      echo "eventTest: Timeout expired before event received!"

  proc eventTest5304() =
    # Event should not be signaled if it was uregistered,
    # even in case, when poll() was not called yet.
    # Issue #5304.
    var unregistered = false
    let e = newAsyncEvent()
    addEvent(e) do (fd: AsyncFD) -> bool:
      assert(not unregistered)
    e.trigger()
    e.unregister()
    unregistered = true
    poll()

  proc eventTest5298() =
    # Event must raise `AssertionDefect` if event was unregistered twice.
    # Issue #5298.
    let e = newAsyncEvent()
    var eventReceived = false
    addEvent(e) do (fd: AsyncFD) -> bool:
      eventReceived = true
      return true
    e.trigger()
    while not eventReceived:
      poll()
    try:
      e.unregister()
    except AssertionDefect:
      discard
    e.close()

  proc eventTest5331() =
    # Event must not raise any exceptions while was unregistered inside of
    # own callback.
    # Issue #5331.
    let e = newAsyncEvent()
    addEvent(e) do (fd: AsyncFD) -> bool:
      e.unregister()
      e.close()
    e.trigger()
    poll()

  when ioselSupportedPlatform or defined(windows):

    import osproc

    proc waitTimer(timeout: int): Future[void] =
      var retFuture = newFuture[void]("waitTimer")
      proc cb(fd: AsyncFD): bool =
        retFuture.complete()
      addTimer(timeout, true, cb)
      return retFuture

    proc waitProcess(p: Process): Future[void] =
      var retFuture = newFuture[void]("waitProcess")
      proc cb(fd: AsyncFD): bool =
        retFuture.complete()
      addProcess(p.processID(), cb)
      return retFuture

    proc timerTest() =
      waitFor(waitTimer(200))

    proc processTest() =
      when defined(windows):
        var process = startProcess("ping.exe", "",
                                   ["127.0.0.1", "-n", "2", "-w", "100"], nil,
                                   {poStdErrToStdOut, poUsePath, poInteractive,
                                   poDaemon})
      else:
        var process = startProcess("sleep", "", ["1"], nil,
                                   {poStdErrToStdOut, poUsePath})
      var fut = waitProcess(process)
      waitFor(fut or waitTimer(2000))
      if fut.finished and process.peekExitCode() == 0:
        discard
      else:
        echo "processTest: Timeout expired before process exited!"

  when ioselSupportedPlatform:

    proc waitSignal(signal: int): Future[void] =
      var retFuture = newFuture[void]("waitSignal")
      proc cb(fd: AsyncFD): bool =
        retFuture.complete()
      addSignal(signal, cb)
      return retFuture

    proc delayedSignal(signal: int, timeout: int): Future[void] {.async.} =
      await waitTimer(timeout)
      var pid = posix.getpid()
      discard posix.kill(pid, signal.cint)

    proc signalTest() =
      var fut = waitSignal(posix.SIGINT)
      asyncCheck(delayedSignal(posix.SIGINT, 500))
      waitFor(fut or waitTimer(1000))
      if not fut.finished:
        echo "signalTest: Timeout expired before signal received!"

  when ioselSupportedPlatform:
    timerTest()
    eventTest()
    eventTest5304()
    eventTest5298()
    eventTest5331()
    processTest()
    signalTest()
    echo "OK"
  elif defined(windows):
    timerTest()
    eventTest()
    eventTest5304()
    eventTest5298()
    eventTest5331()
    processTest()
    echo "OK"
  else:
    eventTest()
    eventTest5304()
    eventTest5298()
    eventTest5331()
    echo "OK"
else:
  echo "OK"
