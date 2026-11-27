discard """
  matrix: "-d:ssl --threads:on"
"""

# The peer certificate is checked against the address when the TLS peer is
# given as an IP address, see also tasyncnet_ssl.nim.

import std/[net, assertions, typedthreads]
from stdtest/testutils import disableSSLTesting

when not disableSSLTesting():
  const
    localhostCert = "tests/stdlib/thttpclient_ssl_cert.pem"
    localhostKey = "tests/stdlib/thttpclient_ssl_key.pem"
    ipCert = "tests/stdlib/tasyncnet_ssl_ip_cert.pem"

  proc serve(args: (Socket, string, string)) {.thread.} =
    let (server, c, k) = args
    var peer: Socket
    server.accept(peer)
    try:
      newContext(certFile = c, keyFile = k).wrapConnectedSocket(peer, handshakeAsServer)
      peer.send("hello")
    except CatchableError: discard
    peer.close()

  proc attempt(c, k, host: string; mode = CVerifyPeer; wrap = false): string =
    let server = newSocket()
    server.bindAddr(Port(0), "127.0.0.1"); server.listen()
    var th: Thread[(Socket, string, string)]
    createThread(th, serve, (server, c, k))
    let ctx = newContext(verifyMode = mode, caFile = c)
    let client = newSocket()
    try:
      if wrap:
        client.connect("127.0.0.1", server.getLocalAddr()[1])
        ctx.wrapConnectedSocket(client, handshakeAsClient, host)
      else:
        ctx.wrapSocket(client)
        client.connect(host, server.getLocalAddr()[1])
      result = client.recv(5)
    except SslError as e: result = e.msg
    client.close(); joinThread(th); server.close()


  const failed = "SSL Certificate check failed."
  doAssert attempt(localhostCert, localhostKey, "127.0.0.1") == failed
  doAssert attempt(localhostCert, localhostKey, "127.0.0.1", wrap = true) == failed
  doAssert attempt(ipCert, ipCert, "127.0.0.1") == "hello"
  doAssert attempt(ipCert, ipCert, "127.0.0.1", wrap = true) == "hello"
  doAssert attempt(localhostCert, localhostKey, "127.0.0.1", CVerifyNone) == "hello"
  doAssert attempt(localhostCert, localhostKey, "localhost") == "hello"
