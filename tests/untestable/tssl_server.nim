discard """
  cmd: "nim $target --threads:on -d:ssl $options $file"
"""

#            Nim - Basic SSL integration tests
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Runs a simple HTTPS server
## Used by .github/workflows/ci_ssl.yml
##
## Warning: this test performs local networking.
## Test with:
## nim c -d:ssl -p:. -d:sync -d:danger -r tests/untestable/tssl_server.nim
## testssl --ip=127.0.0.1 --csvfile testssl.csv --severity LOW https://127.0.0.1:8333

# testssl --parallel https://localhost:8333

import times

# bogus self-signed certificate
const
  reply = "HTTP/1.0 200 OK\r\nServer: Nimtest\r\nContent-type: text/html\r\nContent-Length: 0\r\nStrict-Transport-Security: max-age=63072000; includeSubDomains\r\n\r\n"
  certFile = "tests/stdlib/thttpclient_ssl_cert.pem"
  keyFile = "tests/stdlib/thttpclient_ssl_key.pem"

proc log(msg: string) =
  echo "    [" & $epochTime() & "] " & msg


when not defined(windows) and defined(sync):

  from net import Port, newContext
  import
    net,
    openssl

  from ssl_config import CiphersIntermediate

  when defined(multithread):
    import threadpool

  when not defined(multithread):
    var ctx = newContext(protVersion = protSSLv23, verifyMode = CVerifyPeer,
                 certFile = certFile, keyFile = keyFile, cipherList = CiphersIntermediate)

  proc handleClient(client: Socket) =
    when defined(multithread):
      var ctx = newContext(protVersion = protSSLv23, verifyMode = CVerifyPeer,
                   certFile = certFile, keyFile = keyFile, cipherList = CiphersIntermediate)

    var ssl: SslPtr = SSL_new(ctx.context)
    doAssert SSL_set_fd(ssl, client.getFd()) == 1
    if SSL_accept(ssl) <= 0:
      ERR_print_errors_fp(stdout)
      log "server: error"
    else:
      discard SSL_write(ssl, reply.cstring, reply.len)
    SSL_free(ssl)
    close(client)

  proc runServer(port: Port) =
    ## Run a trivial HTTPS server
    var socket = newSocket()
    socket.setSockOpt(OptReuseAddr, true)
    socket.bindAddr(port)
    socket.listen()
    log "server: ready"
    while true:
      var client: Socket
      socket.accept(client)
      when defined(multithread):
        spawn handleClient(client)
      else:
        handleClient(client)

  when isMainModule:
    runServer(8333.Port)


when not defined(windows) and defined(async):

  from net import Port, newContext
  import asyncnet,
    asyncdispatch,
    openssl

  proc runServer(port: Port) {.async.} =
    ## Run a trivial HTTPS server in a {.thread.}
    var socket = newAsyncSocket()
    socket.setSockOpt(OptReuseAddr, true)
    socket.bindAddr(port)
    socket.listen()
    log "server: ready"
    while true:
      let client = await socket.accept()
      log "server: incoming connection"
      var ctx = newContext(certFile = certFile, keyFile = keyFile)
      var ssl: SslPtr = SSL_new(ctx.context)
      doAssert SSL_set_fd(ssl, client.getFd()) == 1
      if SSL_accept(ssl) <= 0:
        ERR_print_errors_fp(stderr)
        log "error!"
      else:
        echo SSL_write(ssl, reply.cstring, reply.len)

      close(client)
      SSL_free(ssl)

    log "closing"
    close(socket)
    log "server: exited"


  when isMainModule:
    asyncCheck runServer(8333.Port)
    runForever()
