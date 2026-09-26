discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/[net, os]

block: # send to a peer that disconnected returns instead of retrying forever
  let server = newSocket()
  server.bindAddr(Port(0), "localhost")
  server.listen()
  let port = server.getLocalAddr()[1]
  let client = newSocket()
  client.connect("localhost", port)
  var peer: Socket
  server.accept(peer)
  client.close()
  sleep(50)
  # the first send can still succeed; later ones fail with a disconnection
  # error, which SafeDisconn ignores
  for _ in 0 ..< 3:
    peer.send("data")
    sleep(10)
  peer.close()
  server.close()
