discard """
  joinable: false
  disabled: "freebsd"
  disabled: "openbsd"
"""
# disabled: pending bug #15713
import std/[net, nativesockets, assertions]

when defined(posix): import os, posix
else:
  import winlean
  const SD_SEND = 1

when not defined(ssl):
  {.error: "This test must be compiled with -d:ssl".}

const DummyData = "dummy data\n"

proc createSocket(): Socket =
  result = newSocket(buffered = false)
  result.setSockOpt(OptReuseAddr, true)
  result.setSockOpt(OptReusePort, true)

proc createServer(serverContext: SslContext): (Socket, Port) =
  var server = createSocket()
  serverContext.wrapSocket(server)
  server.bindAddr(address = "localhost")
  let (_, port) = server.getLocalAddr()
  server.listen()
  return (server, port)

proc abruptShutdown(port: Port) {.thread.} =
  let clientContext = newContext(verifyMode = CVerifyNone)
  var client = createSocket()
  clientContext.wrapSocket(client)
  client.connect("localhost", port)

  discard client.recvLine()
  client.getFd.close()

proc notifiedShutdown(port: Port) {.thread.} =
  let clientContext = newContext(verifyMode = CVerifyNone)
  var client = createSocket()
  clientContext.wrapSocket(client)
  client.connect("localhost", port)

  discard client.recvLine()
  client.close()

proc main() =
  when defined(posix):
    var
      ignoreAction = Sigaction(sa_handler: SIG_IGN)
      oldSigPipeHandler: Sigaction
    if sigemptyset(ignoreAction.sa_mask) == -1:
      raiseOSError(osLastError(), "Couldn't create an empty signal set")
    if sigaction(SIGPIPE, ignoreAction, oldSigPipeHandler) == -1:
      raiseOSError(osLastError(), "Couldn't ignore SIGPIPE")

  let serverContext = newContext(verifyMode = CVerifyNone,
                                 certFile = "tests/testdata/mycert.pem",
                                 keyFile = "tests/testdata/mycert.pem")

  block peer_close_during_write_without_shutdown:
    var (server, port) = createServer(serverContext)
    var clientThread: Thread[Port]
    createThread(clientThread, abruptShutdown, port)

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
      server.close()

  when defined(posix):
    if sigaction(SIGPIPE, oldSigPipeHandler, nil) == -1:
      raiseOSError(osLastError(), "Couldn't restore SIGPIPE handler")

  block peer_close_before_received_shutdown:
    var (server, port) = createServer(serverContext)
    var clientThread: Thread[Port]
    createThread(clientThread, abruptShutdown, port)

    var peer: Socket
    try:
      server.accept(peer)
      peer.send(DummyData)

      joinThread clientThread

      # Tell the OS to close off the write side so shutdown attempts will
      # be met with SIGPIPE.
      when defined(posix):
        discard peer.getFd.shutdown(SHUT_WR)
      else:
        discard peer.getFd.shutdown(SD_SEND)
    finally:
      peer.close()
      server.close()

  block peer_close_after_received_shutdown:
    var (server, port) = createServer(serverContext)
    var clientThread: Thread[Port]
    createThread(clientThread, notifiedShutdown, port)

    var peer: Socket
    try:
      server.accept(peer)
      peer.send(DummyData)

      doAssert peer.recv(1024) == "" # Get the shutdown notification
      joinThread clientThread

      # Tell the OS to close off the write side so shutdown attempts will
      # be met with SIGPIPE.
      when defined(posix):
        discard peer.getFd.shutdown(SHUT_WR)
      else:
        discard peer.getFd.shutdown(SD_SEND)
    finally:
      peer.close()
      server.close()

when isMainModule: main()
