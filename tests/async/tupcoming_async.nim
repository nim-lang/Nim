discard """
  output: '''
OK
OK
OK
OK
'''
"""

when defined(upcoming):
  import asyncdispatch, times, osproc, streams

  const supportedPlatform = defined(linux) or defined(freebsd) or
                            defined(netbsd) or defined(openbsd) or
                            defined(macosx)

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

  proc delayedSet(ev: AsyncEvent, timeout: int): Future[void] {.async.} =
    await waitTimer(timeout)
    ev.setEvent()

  proc timerTest() =
    var timeout = 200
    var errorRate = 10.0
    var start = epochTime()
    waitFor(waitTimer(200))
    var finish = epochTime()
    var lowlimit = float(timeout) - float(timeout) * errorRate / 100.0
    var highlimit = float(timeout) + float(timeout) * errorRate / 100.0
    var elapsed = (finish - start) * 1_000 # convert to milliseconds
    if elapsed >= lowlimit and elapsed < highlimit:
      echo "OK"
    else:
      echo "timerTest: Timeout = " & $(elapsed) & ", but must be inside of [" &
                                   $lowlimit & ", " & $highlimit & ")"

  proc eventTest() =
    var event = newAsyncEvent()
    var fut = waitEvent(event)
    asyncCheck(delayedSet(event, 500))
    waitFor(fut or waitTimer(1000))
    if fut.finished:
      echo "OK"
    else:
      echo "eventTest: Timeout expired before event received!"

  proc processTest() =
    when defined(windows):
      var process = startProcess("ping.exe", "",
                                 ["127.0.0.1", "-n", "2", "-w", "100"], nil,
                                 {poStdErrToStdOut, poUsePath, poInteractive,
                                 poDemon})
    else:
      var process = startProcess("/bin/sleep", "", ["1"], nil,
                                 {poStdErrToStdOut, poUsePath})
    var fut = waitProcess(process)
    waitFor(fut or waitTimer(2000))
    if fut.finished and process.peekExitCode() == 0:
      echo "OK"
    else:
      echo "processTest: Timeout expired before process exited!"

  when supportedPlatform:
    import posix

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
      if fut.finished:
        echo "OK"
      else:
        echo "signalTest: Timeout expired before signal received!"

  when supportedPlatform:
    timerTest()
    eventTest()
    processTest()
    signalTest()
  elif defined(windows):
    timerTest()
    eventTest()
    processTest()
    echo "OK"
  else:
    eventTest()
    echo "OK\nOK\nOK"
else:
  echo "OK\nOK\nOK\nOK"
