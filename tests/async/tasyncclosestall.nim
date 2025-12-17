discard """
  disabled: "windows"
  outputsub: "send has errored. As expected. All good!"
  exitcode: 0
"""
import asyncdispatch, asyncnet

when defined(windows):
  from winlean import ERROR_NETNAME_DELETED
else:
  from posix import EBADF, ECONNRESET, EPIPE

# This reproduces a case where a socket remains stuck waiting for writes
# even when the socket is closed.
const
  timeout = 8000
var port = Port(0)

var sent = 0

proc isExpectedDisconnectionError(errCode: int32): bool =
  ## Check if an error code indicates an expected disconnection.
  ## On POSIX systems, the error code depends on timing:
  ## - EBADF: Socket was closed locally before kernel detected remote state
  ## - ECONNRESET: Remote peer sent RST packet (detected first)
  ## - EPIPE: Socket is no longer connected (broken pipe)
  ## All three are valid disconnection errors for this test scenario.
  when defined(windows):
    errCode == ERROR_NETNAME_DELETED
  else:
    errCode == EBADF or errCode == ECONNRESET or errCode == EPIPE

proc keepSendingTo(c: AsyncSocket) {.async.} =
  while true:
    # This write will eventually get stuck because the client is not reading
    # its messages.
    let sendFut = c.send("Foobar" & $sent & "\n", flags = {})
    var sendTimedOut = false
    try:
      # On some platforms (notably macOS ARM64), the kernel may return
      # ECONNRESET immediately when detecting a non-responsive connection,
      # rather than letting the send stall. We catch this case here.
      sendTimedOut = not await withTimeout(sendFut, timeout)
    except OSError as e:
      if isExpectedDisconnectionError(e.errorCode):
        echo("send has errored. As expected. All good!")
        quit(QuitSuccess)
      else:
        raise

    if sendTimedOut:
      # The write is stuck. Let's simulate a scenario where the socket
      # does not respond to PING messages, and we close it. The above future
      # should complete after the socket is closed, not continue stalling.
      echo("Socket has stalled, closing it")
      c.close()

      let timeoutFut = withTimeout(sendFut, timeout)
      yield timeoutFut
      if timeoutFut.failed:
        let errCode = ((ref OSError)(timeoutFut.error)).errorCode
        # The behaviour differs across platforms. On Windows ERROR_NETNAME_DELETED
        # is raised which we classif as a "diconnection error", hence we overwrite
        # the flags above in the `send` call so that this error is raised.
        #
        # This means that by default the behaviours will differ between Windows
        # and POSIX. I think this is fine though, it makes sense mainly because
        # Windows doesn't use a IO readiness model. We can fix this later if
        # necessary to reclassify ERROR_NETNAME_DELETED as not a "disconnection
        # error" (TODO)
        if isExpectedDisconnectionError(errCode):
          echo("send has errored. As expected. All good!")
          quit(QuitSuccess)
        else:
          raise newException(ValueError, "Test failed. Send failed with code " & $errCode)

      # The write shouldn't succeed and also shouldn't be stalled.
      if timeoutFut.read():
        raise newException(ValueError, "Test failed. Send was expected to fail.")
      else:
        raise newException(ValueError, "Test failed. Send future is still stalled.")
    sent.inc(1)

proc startClient() {.async.} =
  let client = newAsyncSocket()
  await client.connect("localhost", port)
  echo("Connected")

  let firstLine = await client.recvLine()
  echo("Received first line as a client: ", firstLine)
  echo("Now not reading anymore")
  while true: await sleepAsync(1000)

proc debug() {.async.} =
  while true:
    echo("Sent ", sent)
    await sleepAsync(1000)

proc server() {.async.} =
  var s = newAsyncSocket()
  s.setSockOpt(OptReuseAddr, true)
  s.bindAddr(port)
  s.listen()
  let (addr2, port2) = s.getLocalAddr
  port = port2

  # We're now ready to accept connections, so start the client
  asyncCheck startClient()
  asyncCheck debug()

  while true:
    let client = await accept(s)
    asyncCheck keepSendingTo(client)

when isMainModule:
  waitFor server()
