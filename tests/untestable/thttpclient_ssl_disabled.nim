#
#            Nim - SSL integration tests
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Warning: this test performs external networking.
## Compile and run with:
## ./bin/nim c -d:nimDisableCertificateValidation -d:ssl -r -p:. tests/untestable/thttpclient_ssl_disabled.nim

import httpclient,
  net,
  unittest,
  os

from strutils import contains

const expired = "https://expired.badssl.com/"

doAssert defined(nimDisableCertificateValidation)

suite "SSL certificate check - disabled":

  test "httpclient in insecure mode":
    var ctx = newContext(verifyMode = CVerifyPeer)
    var client = newHttpClient(sslContext = ctx)
    let a = $client.getContent(expired)

  test "httpclient in insecure mode":
    var ctx = newContext(verifyMode = CVerifyPeerUseEnvVars)
    var client = newHttpClient(sslContext = ctx)
    let a = $client.getContent(expired)

  test "net socket in insecure mode":
    var sock = newSocket()
    var ctx = newContext(verifyMode = CVerifyPeerUseEnvVars)
    ctx.wrapSocket(sock)
    sock.connect("expired.badssl.com", 443.Port)
    sock.close
