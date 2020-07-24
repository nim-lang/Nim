discard """
  cmd: "nim $target --threads:on -d:ssl $options $file"
  disabled: "openbsd"
"""

#            Nim - Basic SSL integration tests
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Warning: this test performs local networking.
## Test with:
## ./bin/nim c -d:ssl -p:. --threads:on -r tests/stdlib/thttpclient_ssl_alpn.nim

when not defined(windows):
  # Disabled on Windows due to old OpenSSL version

  import
    httpclient,
    net,
    openssl,
    os,
    strutils,
    threadpool,
    times,
    unittest

  # self-signed certificate with a root ca to setup
  const
    certFile = "tests/stdlib/certs/localhost.crt"
    keyFile = "tests/stdlib/certs/localhost.key"
    caFile = "tests/stdlib/certs/myCA.pem"

  proc log(msg: string) =
    when defined(ssldebug):
      echo "    [" & $epochTime() & "] " & msg
    # FIXME
    echo "    [" & $epochTime() & "] " & msg
    discard

  alpnAccept(www_alpn, @["h2", "http/1.1"])

  proc runServer(port: Port): bool {.thread.} =
    ## Run a trivial HTTPS server in a {.thread.}
    ## Exit after serving one request

    var socket = newSocket()
    socket.setSockOpt(OptReusePort, true)
    socket.bindAddr(port)

    var ctx = newContext(
      certFile=certFile,
      keyFile=keyFile,
      caFile=caFile,
      verifyMode=CVerifyPeer)
    discard ctx.context.setAlpnSelectCallback(www_alpn)
    ##  Handle one connection
    socket.listen()

    var client: Socket
    var address = ""

    log "server: ready"
    socket.acceptAddr(client, address)
    log "server: incoming connection"

    ctx.wrapConnectedSocket(client, handshakeAsServer)
    log "server: ssl alpn protocol =>" & client.getAlpnProtocol()
    log "server: receiving a line"
    let line = client.recvLine()

    log "server: received $# bytes" % $line.len
    var alpnProtocol = client.getAlpnProtocol()
    if alpnProtocol == "":
      alpnProtocol = "empty"

    let alpn = "selected alpn protocol is " & alpnProtocol
    let reply = "HTTP/1.0 200 OK\r\nServer: test\r\nContent-type: text/html\r\nContent-Length: " & $(alpn.len) & "\r\n\r\n" & alpn
    discard client.send(reply.cstring, reply.len)
    log "server: closing"
    #SSL_free(ssl)
    close(client)
    close(socket)
    log "server: exited"

  suite "SSL self signed certificate check":

    test "HttpClient with alpn: protcol == http/1.1":
      const port = 12351.Port
      let _ = spawn runServer(port)
      sleep(100)

      let ctx = newContext(
        certFile=certFile, caFile=caFile,
        verifyMode=CVerifyPeer
      )
      discard ctx.context.setAlpnProtocols(@["http/1.1", "h2"])

      var client = newHttpClient(sslContext=ctx)

      log "client: connect"
      let content = client.getContent("https://localhost:12351")
      check content == "selected alpn protocol is http/1.1"

    test "HttpClient with alpn: protcol == h2":
      const port = 12352.Port
      let _ = spawn runServer(port)
      sleep(100)

      let ctx = newContext(
        certFile=certFile, caFile=caFile,
        verifyMode=CVerifyPeer
      )
      discard ctx.context.setAlpnProtocols(@["h2", "http/1.1"])

      var client = newHttpClient(sslContext=ctx)

      log "client: connect"
      let content = client.getContent("https://localhost:12352")
      check content == "selected alpn protocol is h2"

    test "HttpClient with different alpn protcol":
      const port = 12353.Port
      let _ = spawn runServer(port)
      sleep(100)

      let ctx = newContext(
        certFile=certFile, caFile=caFile,
        verifyMode=CVerifyPeer
      )
      discard ctx.context.setAlpnProtocols(@["h3", "http/1.3"])

      var client = newHttpClient(sslContext=ctx)

      log "client: connect"
      let content = client.getContent("https://localhost:12353")
      check content == "selected alpn protocol is empty"
