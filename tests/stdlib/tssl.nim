discard """
  joinable: false
"""

import net, nativesockets

when defined(posix): import posix

const DummyData = "dummy data\n"

when defined(ssl):
  let serverContext = newContext(verifyMode = CVerifyNone,
                                 certFile = "tests/testdata/mycert.pem",
                                 keyFile = "tests/testdata/mycert.pem")

  when defined(posix):
    signal(SIGPIPE, SIG_IGN)

  proc connector(port: Port) {.thread.} =
    let clientContext = newContext(verifyMode = CVerifyNone)
    var client = newSocket(buffered = false)
    clientContext.wrapSocket(client)
    client.connect("localhost", port)

    discard client.recvLine()
    client.getFd.close()

  block:
    var server = newSocket(buffered = false)
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
    except:
      discard
    finally:
      peer.close()

    server.close()
