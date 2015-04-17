discard """
  file: "tasynceverror.nim"
  exitcode: 1
  outputsub: "Error: unhandled exception: Connection reset by peer [Exception]"
"""

import
    asyncdispatch,
    asyncnet,
    rawsockets,
    os


const
    testHost = "127.0.0.1"
    testPort = Port(17357)


when defined(windows) or defined(nimdoc):
    discard
else:
    proc createListenSocket(host: string, port: Port): TAsyncFD =
        result = newAsyncRawSocket()

        SocketHandle(result).setSockOptInt(SOL_SOCKET, SO_REUSEADDR, 1)

        var aiList = getAddrInfo(host, port, AF_INET)
        if SocketHandle(result).bindAddr(aiList.ai_addr, aiList.ai_addrlen.Socklen) < 0'i32:
          dealloc(aiList)
          raiseOSError(osLastError())
        dealloc(aiList)

        if SocketHandle(result).listen(1) < 0'i32:
            raiseOSError(osLastError())


    proc testAsyncSend() {.async.} =
        var
            ls = createListenSocket(testHost, testPort)
            s = newAsyncSocket()

        await s.connect(testHost, testPort)
        
        var ps = await ls.accept()
        SocketHandle(ls).close()

        await ps.send("test 1", flags={})
        s.close()
        # This send should raise EPIPE
        await ps.send("test 2", flags={})
        SocketHandle(ps).close()


    # The bug was, when the poll function handled EvError for us,
    # our callbacks may never get executed, thus making the event
    # loop block indefinitely. This is a timer to keep everything
    # rolling. 400 ms is an arbitrary value, should be enough though.
    proc timer() {.async.} =
        await sleepAsync(400)
        echo("Timer expired.")
        quit(2)


    asyncCheck(testAsyncSend())
    waitFor(timer())
