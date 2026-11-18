discard """
  matrix: "-d:ssl"
"""

import std/[asyncdispatch, asyncnet, net, strutils, assertions]
from stdtest/testutils import disableSSLTesting

when not disableSSLTesting():
  const
    localhostCert = "tests/stdlib/thttpclient_ssl_cert.pem" # CN=localhost
    localhostKey = "tests/stdlib/thttpclient_ssl_key.pem"
    wrongCert = "tests/stdlib/tasyncnet_ssl_wrong_cert.pem" # CN=wrong.example
    ipCert = "tests/stdlib/tasyncnet_ssl_ip_cert.pem" # IP SAN 127.0.0.1

  proc serveOnce(server: AsyncSocket, ctx: SslContext) {.async.} =
    try:
      let peer = await server.accept()
      ctx.wrapConnectedSocket(peer, handshakeAsServer)
      await peer.send("hello")
      peer.close()
    except CatchableError:
      discard # the client rejects the certificate and drops the connection

  proc newServer(): AsyncSocket =
    result = newAsyncSocket()
    result.bindAddr(Port(0), "127.0.0.1")
    result.listen()

  proc trusting(certFile: string): SslContext =
    newContext(verifyMode = CVerifyPeer, caFile = certFile)

  proc viaConnect(ctx: SslContext, certFile, keyFile: string,
                  host = "localhost"): Future[string] {.async.} =
    let server = newServer()
    let served = serveOnce(server, newContext(certFile = certFile, keyFile = keyFile))
    let client = newAsyncSocket()
    defer:
      client.close()
      server.close()
    ctx.wrapSocket(client)
    await client.connect(host, server.getLocalAddr()[1])
    result = await client.recv(5)
    await served

  proc viaWrapConnected(ctx: SslContext, hostname: string): Future[string] {.async.} =
    let server = newServer()
    let served = serveOnce(server, newContext(certFile = localhostCert, keyFile = localhostKey))
    let client = newAsyncSocket()
    defer:
      client.close()
      server.close()
    await client.connect("127.0.0.1", server.getLocalAddr()[1])
    ctx.wrapConnectedSocket(client, handshakeAsClient, hostname)
    result = await client.recv(5)
    await served

  proc rejected(fut: Future[string]): bool =
    try:
      discard waitFor fut
    except SslError as e:
      result = "SSL Certificate check failed" in e.msg

  block matching_certificate_connect:
    doAssert waitFor(viaConnect(trusting(localhostCert), localhostCert, localhostKey)) == "hello"

  block mismatched_certificate_connect:
    doAssert rejected(viaConnect(trusting(wrongCert), wrongCert, wrongCert))

  block mismatched_certificate_connect_verify_none:
    let ctx = newContext(verifyMode = CVerifyNone)
    doAssert waitFor(viaConnect(ctx, wrongCert, wrongCert)) == "hello"

  block matching_certificate_wrap_connected:
    doAssert waitFor(viaWrapConnected(trusting(localhostCert), "localhost")) == "hello"

  block mismatched_certificate_wrap_connected:
    doAssert rejected(viaWrapConnected(trusting(localhostCert), "wrong.example"))

  block ip_address_not_in_certificate:
    # a certificate for "localhost" is not valid for the address 127.0.0.1
    doAssert rejected(viaConnect(trusting(localhostCert), localhostCert, localhostKey, "127.0.0.1"))

  block ip_address_in_certificate:
    doAssert waitFor(viaConnect(trusting(ipCert), ipCert, ipCert, "127.0.0.1")) == "hello"

  block ip_address_other_certificate:
    doAssert rejected(viaConnect(trusting(wrongCert), wrongCert, wrongCert, "127.0.0.1"))

  block ip_address_wrap_connected:
    doAssert rejected(viaWrapConnected(trusting(localhostCert), "127.0.0.1"))

  block ip_address_verify_none:
    let ctx = newContext(verifyMode = CVerifyNone)
    doAssert waitFor(viaConnect(ctx, localhostCert, localhostKey, "127.0.0.1")) == "hello"

  block mismatched_certificate_wrap_connected_verify_none:
    let ctx = newContext(verifyMode = CVerifyNone)
    doAssert waitFor(viaWrapConnected(ctx, "wrong.example")) == "hello"
