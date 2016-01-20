
# This is a regression of the new lambda lifting; detected by Aporia
import asyncio, sockets
import os

type
  Window = object
    oneInstSock*: PAsyncSocket
    IODispatcher*: PDispatcher

var
  win: Window

proc initSocket() =
  win.oneInstSock = asyncSocket()
  #win.oneInstSock.handleAccept =
  proc test(s: PAsyncSocket) =
    var client: PAsyncSocket
    proc dummy(c: PAsyncSocket) {.closure.} =
      discard
    client.handleRead = dummy
  test(win.oneInstSock)
