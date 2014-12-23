#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This is an internal module to share code between net and asyncnet.

import openssl, os

proc handleSyscallError*(sslReturn: int, onSSLError: proc(errorMsg: string)) =
  ## handles an openssl syscall error, calling ``onSSLError`` with an appropiate
  ## error message or raising an `OSError` if the error occured at the OS level.
  var errStr = "IO error has occured "
  let sslErr = ErrPeekLastError()
  if sslErr == 0 and sslReturn == 0:
    errStr.add "because an EOF was observed that violates the protocol"
  elif sslErr == 0 and sslReturn == -1:
    errStr.add "in the BIO layer"
  else:
    let errStr = $ErrErrorString(sslErr, nil)
    onSSLError(errStr & ": " & errStr)
  let osMsg = osErrorMsg osLastError()
  if osMsg != "":
    errStr.add ". The OS reports: " & osMsg
  raise newException(OSError, errStr)

template ifSSLEnabledOn*(socket: expr, body: stmt) {.immediate.} =
  when defined(ssl):
    if socket.isSSL:
      body

proc SSLWantToErrMsg(sslGetErr: cint): string =
  case sslGetErr:
  of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT, SSL_ERROR_WANT_WRITE,
    SSL_ERROR_WANT_READ:
    result = "Not enough data on socket."
  of SSL_ERROR_WANT_X509_LOOKUP:
    result = "I/O function should be called again later as callback set by " &
      "SSL_CTX_set_client_cert_cb has requested to be called again"
  else:
    result = "Unknown SSL error"

proc defaultSSLErrorHandler*(sslReturn: int, sslErr: cint,
  onSSLError: proc(errorMsg: string = "")) {.nimcall.} =
  ## Checks for ssl errors: if an error condition occured `onSSLError`` will be
  ## called with an appropiate error message. The idea is filter the errors you
  ## are interested in and call this for the rest.
  ##
  ## ``sslReturn`` should be the return code from the openssl function call
  ## ``sslErr` should be the return code from `SSLGetError`
  case sslErr
  of SSL_ERROR_ZERO_RETURN:
    onSSLError("TLS/SSL connection failed to initiate, socket closed prematurely.")
  of SSL_ERROR_WANT_CONNECT, SSL_ERROR_WANT_ACCEPT, SSL_ERROR_WANT_WRITE,
    SSL_ERROR_WANT_READ, SSL_ERROR_WANT_X509_LOOKUP:
    onSSLError(SSLWantToErrMsg(sslErr))
  of SSL_ERROR_SYSCALL:
    handleSyscallError(sslReturn, onSSLError)
  of SSL_ERROR_SSL:
    onSSLError()
  else: onSSLError("Unknown Error")

proc shutdownSSL*(sslHandle: SSLptr, onError: proc(res: cint)) =
  # Performs unidirectional shutdown of SSL connection
  ErrClearError()
  # As we are closing the underlying socket immediately afterwards,
  # it is valid, under the TLS standard, to perform a unidirectional
  # shutdown i.e not wait for the peers "close notify" alert with a second
  # call to SSLShutdown
  let res = SSLShutdown(sslHandle)
  if res == 0:
    discard
  elif res != 1:
    onError(res)


