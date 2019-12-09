discard """
  disabled: true
"""

# This is a regression of the new lambda lifting; detected by Aporia
import asyncio, sockets
import os

type
  Window = object
    oneInstSock*: AsyncSocket
    IODispatcher*: Dispatcher

var
  win: Window

proc initSocket() =
  win.oneInstSock = asyncSocket()
  #win.oneInstSock.handleAccept =
  proc test(s: AsyncSocket) =
    var client: AsyncSocket
    proc dummy(c: AsyncSocket) {.closure.} =
      discard
    client.handleRead = dummy
  test(win.oneInstSock)
