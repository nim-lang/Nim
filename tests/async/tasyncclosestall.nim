discard """
  disabled: "windows"
  outputsub: "send has errored. As expected. All good!"
  exitcode: 0
"""
import asyncdispatch, asyncnet

when defined(windows):
  from winlean import ERROR_NETNAME_DELETED
else:
  from posix import EBADF

# This reproduces a case where a socket remains stuck waiting for writes
# even when the socket is closed.
const
  timeout = 8000
var port = Port(0)

var sent = 0

proc keepSendingTo(c: AsyncSocket) {.async.} =
  while true:
    # This write will eventually get stuck because the client is not reading
    # its messages.
    let sendFut = c.send("Foobar" & $sent & "\n", flags = {})
    if not await withTimeout(sendFut, timeout):
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
        # On Linux the EBADF error code is raised, this is because the socket
        # is closed.
        #
        # This means that by default the behaviours will differ between Windows
        # and Linux. I think this is fine though, it makes sense mainly because
        # Windows doesn't use a IO readiness model. We can fix this later if
        # necessary to reclassify ERROR_NETNAME_DELETED as not a "disconnection
        # error" (TODO)
        when defined(windows):
          if errCode == ERROR_NETNAME_DELETED:
            echo("send has errored. As expected. All good!")
            quit(QuitSuccess)
          else:
            raise newException(ValueError, "Test failed. Send failed with code " & $errCode)
        else:
          if errCode == EBADF:
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
