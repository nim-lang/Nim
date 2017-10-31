#
#
#            Nim - SSL integration tests
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## Warning: this test performs external networking.
## Compile with:
## ./bin/nim c -d:ssl -p:. tests/untestable/thttpclient_ssl_env_var.nim
##
## Test with:
##  NIM_SSL_CERT_VALIDATION=insecure tests/untestable/thttpclient_ssl_env_var
##  SSL_CERT_FILE=BogusInexistentFileName tests/untestable/thttpclient_ssl_env_var
##  SSL_CERT_DIR=BogusInexistentDirName tests/untestable/thttpclient_ssl_env_var

import httpclient, unittest, ospaths
from net import newSocket, newContext, wrapSocket, connect, close, Port, CVerifyPeerUseEnvVars
from strutils import contains

const
  expired = "https://expired.badssl.com/"
  good = "https://google.com/"


suite "SSL certificate check":

  if existsEnv("NIM_SSL_CERT_VALIDATION"):
    if getEnv("NIM_SSL_CERT_VALIDATION") == "insecure":
      test "httpclient in insecure mode":
        var ctx = newContext(verifyMode=CVerifyPeerUseEnvVars)
        var client = newHttpClient(sslContext=ctx)
        let a = $client.getContent(expired)

      test "net socket in insecure mode":
        var sock = newSocket()
        var ctx = newContext(verifyMode=CVerifyPeerUseEnvVars)
        ctx.wrapSocket(sock)
        sock.connect("expired.badssl.com", 443.Port)
        sock.close

    else:
      echo "ERROR: unexpected env variable value"
      quit(1)

  if existsEnv("SSL_CERT_FILE"):
    if getEnv("SSL_CERT_FILE") == "BogusInexistentFileName":
      test "httpclient with inexistent file":
        var ctx = newContext(verifyMode=CVerifyPeerUseEnvVars)
        var client = newHttpClient(sslContext=ctx)
        try:
          let a = $client.getContent(good)
          echo "Connection should have failed"
          fail()
        except:
          check getCurrentExceptionMsg().contains("certificate verify failed")

      test "net socket with inexistent file":
        var sock = newSocket()
        var ctx = newContext(verifyMode=CVerifyPeerUseEnvVars)
        ctx.wrapSocket(sock)
        try:
          sock.connect("expired.badssl.com", 443.Port)
          fail()
        except:
          sock.close
          check getCurrentExceptionMsg().contains("certificate verify failed")

    else:
      echo "ERROR: unexpected env variable value"
      quit(1)

  if existsEnv("SSL_CERT_DIR"):
    if getEnv("SSL_CERT_DIR") == "BogusInexistentDirName":
      test "httpclient with inexistent directory":
        try:
          var client = newHttpClient()
          echo "Should have raised 'No SSL/TLS CA certificates found.'"
          fail()
        except:
          check getCurrentExceptionMsg() ==
            "No SSL/TLS CA certificates found."

      test "net socket with inexistent directory":
        var sock = newSocket()
        try:
          var ctx = newContext(verifyMode=CVerifyPeerUseEnvVars) # raises here
          fail()
        except:
          check getCurrentExceptionMsg() ==
            "No SSL/TLS CA certificates found."

    else:
      echo "ERROR: unexpected env variable value"
      quit(1)
