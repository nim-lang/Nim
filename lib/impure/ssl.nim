#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides an easy to use sockets-style 
## nim interface to the OpenSSL library.

{.deprecated.}

import openssl, strutils, os

type
  TSecureSocket* = object
    ssl: SslPtr
    bio: BIO

proc connect*(sock: var TSecureSocket, address: string, 
    port: int): int =
  ## Connects to the specified `address` on the specified `port`.
  ## Returns the result of the certificate validation.
  SslLoadErrorStrings()
  ERR_load_BIO_strings()
  
  if SSL_library_init() != 1:
    raiseOSError(osLastError())
  
  var ctx = SSL_CTX_new(SSLv23_client_method())
  if ctx == nil:
    ERR_print_errors_fp(stderr)
    raiseOSError(osLastError())
    
  #if SSL_CTX_load_verify_locations(ctx, 
  #   "/tmp/openssl-0.9.8e/certs/vsign1.pem", NIL) == 0:
  #  echo("Failed load verify locations")
  #  ERR_print_errors_fp(stderr)
  
  sock.bio = BIO_new_ssl_connect(ctx)
  if BIO_get_ssl(sock.bio, addr(sock.ssl)) == 0:
    raiseOSError(osLastError())

  if BIO_set_conn_hostname(sock.bio, address & ":" & $port) != 1:
    raiseOSError(osLastError())
  
  if BIO_do_connect(sock.bio) <= 0:
    ERR_print_errors_fp(stderr)
    raiseOSError(osLastError())
  
  result = SSL_get_verify_result(sock.ssl)

proc recvLine*(sock: TSecureSocket, line: var TaintedString): bool =
  ## Acts in a similar fashion to the `recvLine` in the sockets module.
  ## Returns false when no data is available to be read.
  ## `Line` must be initialized and not nil!
  setLen(line.string, 0)
  while true:
    var c: array[0..0, char]
    var n = BIO_read(sock.bio, c, c.len.cint)
    if n <= 0: return false
    if c[0] == '\r':
      n = BIO_read(sock.bio, c, c.len.cint)
      if n > 0 and c[0] == '\L':
        return true
      elif n <= 0:
        return false
    elif c[0] == '\L': return true
    add(line.string, c)


proc send*(sock: TSecureSocket, data: string) =
  ## Writes `data` to the socket.
  if BIO_write(sock.bio, data, data.len.cint) <= 0:
    raiseOSError(osLastError())

proc close*(sock: TSecureSocket) =
  ## Closes the socket
  if BIO_free(sock.bio) <= 0:
    ERR_print_errors_fp(stderr)
    raiseOSError(osLastError())

when isMainModule:
  var s: TSecureSocket
  echo connect(s, "smtp.gmail.com", 465)
  
  #var buffer: array[0..255, char]
  #echo BIO_read(bio, buffer, buffer.len)
  var buffer: string = ""
  
  echo s.recvLine(buffer)
  echo buffer 
  echo buffer.len
  
