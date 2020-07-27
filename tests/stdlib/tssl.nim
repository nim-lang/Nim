discard """
  joinable: false
"""

import net, nativesockets

when defined(posix): import os, posix

when not defined(ssl):
  {.error: "This test must be compiled with -d:ssl".}

const DummyData = "dummy data\n"

proc connector(port: Port) {.thread.} =
  let clientContext = newContext(verifyMode = CVerifyNone)
  var client = newSocket(buffered = false)
  clientContext.wrapSocket(client)
  client.connect("localhost", port)

  discard client.recvLine()
  client.getFd.close()

proc main() =
  let serverContext = newContext(verifyMode = CVerifyNone,
                                 certFile = "tests/testdata/mycert.pem",
                                 keyFile = "tests/testdata/mycert.pem")

  when defined(posix):
    var
      ignoreAction = SigAction(sa_handler: SIG_IGN)
      oldSigPipeHandler: SigAction
    if sigemptyset(ignoreAction.sa_mask) == -1:
      raiseOSError(osLastError(), "Couldn't create an empty signal set")
    if sigaction(SIGPIPE, ignoreAction, oldSigPipeHandler) == -1:
      raiseOSError(osLastError(), "Couldn't ignore SIGPIPE")

  block peer_close_without_shutdown:
    var server = newSocket(buffered = false)
    defer: server.close()
    serverContext.wrapSocket(server)
    server.bindAddr(address = "localhost")
    let (_, port) = server.getLocalAddr()
    server.listen()

    var clientThread: Thread[Port]
    createThread(clientThread, connector, port)

    var peer: Socket
    try:
      server.accept(peer)
      peer.send(DummyData)

      joinThread clientThread

      while true:
        # Send data until we get EPIPE.
        peer.send(DummyData, {})
    except OSError:
      discard
    finally:
      peer.close()
