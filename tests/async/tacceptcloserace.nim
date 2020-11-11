discard """
  exitcode: 0
  output: ""
"""

import asyncdispatch, net, os, nativesockets

# bug: https://github.com/nim-lang/Nim/issues/5279

proc setupServerSocket(hostname: string, port: Port): AsyncFD =
  let fd = createNativeSocket()
  if fd == osInvalidSocket:
    raiseOSError(osLastError())
  setSockOptInt(fd, SOL_SOCKET, SO_REUSEADDR, 1)
  var aiList = getAddrInfo(hostname, port)
  if bindAddr(fd, aiList.ai_addr, aiList.ai_addrlen.Socklen) < 0'i32:
    freeAddrInfo(aiList)
    raiseOSError(osLastError())
  freeAddrInfo(aiList)
  if listen(fd) != 0:
    raiseOSError(osLastError())
  setBlocking(fd, false)
  result = fd.AsyncFD
  register(result)

const port = Port(5614)
for i in 0..100:
  let serverFd = setupServerSocket("localhost", port)
  serverFd.accept().callback = proc(fut: Future[AsyncFD]) =
    if not fut.failed:
      fut.read().closeSocket()

  var fd = createAsyncNativeSocket()
  waitFor fd.connect("localhost", port)
  serverFd.closeSocket()
  fd.closeSocket()
