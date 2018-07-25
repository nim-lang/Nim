#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Genode synchronous TCP+UDP/IP stack

import asyncdispatch, genode/asynctcpip
  # Just a wrapper over the async stack.

export
  Port, Domain, SockType, Protocol, SocketFlag, SslContext,
  BufferSize, MaxLineLength, osInvalidSocket

type
  Socket* = ref SocketObj
  SocketObj = distinct object of AsyncSocketObj
    placeholder: int

  SslContext* = void

proc newSocket*(domain: Domain = AF_INET, sockType: SockType = SOCK_STREAM,
                protocol: Protocol = IPPROTO_TCP, buffered = true): Socket =
  ## Creates a new socket.
  raiseAssert: "Not implemented"

proc dial*(address: string, port: Port,
           protocol = IPPROTO_TCP, buffered = true): Socket =
  raiseAssert: "Not implemented"

proc close*(socket: Socket) =
  ## Closes a socket.
  raiseAssert: "Not implemented"

proc connect*(socket: Socket, address: string, port = Port(0)) =
  raiseAssert: "Not implemented"
  
proc connect*(socket: Socket, address: string, port = Port(0),
    timeout: int) =
  raiseAssert: "Not implemented"

proc recv*(socket: Socket, data: pointer, size: int): int =
  raiseAssert: "Not implemented"

proc recv*(socket: Socket, data: pointer, size: int, timeout: int): int =
  ## overload with a ``timeout`` parameter in milliseconds.
  raiseAssert: "Not implemented"

proc recv*(socket: Socket, size: int, timeout = -1,
           flags = {SocketFlag.SafeDisconn}): string {.inline.} =
  raiseAssert: "Not implemented"


proc recv*(socket: Socket, data: var string, size: int, timeout = -1,
           flags = {SocketFlag.SafeDisconn}): int =
  raiseAssert: "Not implemented"

proc skip*(socket: Socket, size: int, timeout = -1) =
  raiseAssert: "Not implemented"

proc send*(socket: Socket, data: pointer, size: int): int =
  raiseAssert: "Not implemented"

proc send*(socket: Socket, data: string,
           flags = {SocketFlag.SafeDisconn}) =
  raiseAssert: "Not implemented"


proc recvLine*(socket: Socket, timeout = -1,
               flags = {SocketFlag.SafeDisconn},
               maxLength = MaxLineLength): TaintedString =
  raiseAssert: "Not implemented"

proc readLine*(socket: Socket, line: var TaintedString, timeout = -1,
               flags = {SocketFlag.SafeDisconn}, maxLength = MaxLineLength) {.
  tags: [ReadIOEffect, TimeEffect].} =
  raiseAssert: "Not implemented"
