discard """
  action: run
  output: '''

[Suite] send with SafeDisconn returns on a disconnected peer
'''
"""

# issue #23455: `net.send` with the (default) `SafeDisconn` flag swallowed
# the disconnection error inside its retry loop without advancing `written`,
# live-locking at 100% CPU against a peer that had closed or reset the
# connection. Before the fix this suite never returned (a testament timeout
# fails it); with the fix the send stops and returns promptly once the
# kernel reports EPIPE/ECONNRESET.

import std/[net, nativesockets, strutils, os, unittest]

suite "send with SafeDisconn returns on a disconnected peer":

  test "string send against a closed peer terminates":
    var server = newSocket()
    defer: server.close()
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(0))
    server.listen()
    let (_, port) = server.getLocalAddr()

    var client = newSocket()
    client.connect("127.0.0.1", port)
    var peer: Socket
    server.accept(peer)
    defer: peer.close()

    # Closing the client makes the kernel answer the server's subsequent
    # writes with RST, so send() fails with EPIPE/ECONNRESET.
    client.close()

    # Hammer until the RST lands; every send must either succeed or stop.
    # The unfixed loop spins forever inside the first failing send.
    var i = 0
    while i < 500:
      peer.send("x".repeat(1024))
      inc i
      sleep(1)
    check true

  test "string send resumes from the first unsent byte":
    # issue #21154: a partial write used to resend the whole buffer from
    # offset 0. We cannot force a partial write deterministically, but the
    # offset arithmetic is exercised by any multi-buffer send; assert the
    # data a real peer receives byte-for-byte.
    var server = newSocket()
    defer: server.close()
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(0))
    server.listen()
    let (_, port) = server.getLocalAddr()

    var client = newSocket()
    client.connect("127.0.0.1", port)
    var peer: Socket
    server.accept(peer)
    defer: peer.close()

    let payload = "0123456789abcdef".repeat(4096) # 64 KiB: spans partial writes
    peer.send(payload)

    var got = ""
    while got.len < payload.len:
      let chunk = client.recv(payload.len - got.len)
      if chunk.len == 0: break
      got.add chunk
    client.close()
    check got == payload
