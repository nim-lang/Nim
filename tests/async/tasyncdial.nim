discard """
  output: '''
OK AF_INET
OK AF_INET6
'''
"""

import
  nativesockets, os, asyncdispatch

proc setupServerSocket(hostname: string, port: Port, domain: Domain): AsyncFD =
  ## Creates a socket, binds it to the specified address, and starts listening for connections.
  ## Registers the descriptor with the dispatcher of the current thread
  ## Raises OSError in case of an error.
  let fd = createNativeSocket(domain)
  setSockOptInt(fd, SOL_SOCKET, SO_REUSEADDR, 1)
  var aiList = getAddrInfo(hostname, port, domain)
  if bindAddr(fd, aiList.ai_addr, aiList.ai_addrlen.Socklen) < 0'i32:
    freeAddrInfo(aiList)
    raiseOSError(osLastError())
  freeAddrInfo(aiList)
  if listen(fd) != 0:
    raiseOSError(osLastError())
  setBlocking(fd, false)
  result = fd.AsyncFD
  register(result)

proc doTest(domain: static[Domain]) {.async.} =
  const
    testHost = when domain == Domain.AF_INET6: "::1" else: "127.0.0.1"
    testPort = Port(17384)
  let serverFd = setupServerSocket(testHost, testPort, domain)
  let acceptFut = serverFd.accept()
  let clientFdFut = dial(testHost, testPort)

  let serverClientFd = await acceptFut
  serverFd.closeSocket()

  let clientFd = await clientFdFut

  let recvFut = serverClientFd.recv(2)
  await clientFd.send("Hi")
  let msg = await recvFut

  serverClientFd.closeSocket()
  clientFd.closeSocket()

  if msg == "Hi":
    echo "OK ", domain

waitFor(doTest(Domain.AF_INET))
waitFor(doTest(Domain.AF_INET6))
