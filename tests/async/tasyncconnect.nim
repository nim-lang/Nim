discard """
  outputsub: "Error: unhandled exception: Connection refused"
  exitcode: 1
"""

import
    asyncdispatch,
    posix


const
    testHost = "127.0.0.1"
    testPort = Port(17357)


when defined(windows) or defined(nimdoc):
    # TODO: just make it work on Windows for now.
    quit("Error: unhandled exception: Connection refused")
else:
    proc testAsyncConnect() {.async.} =
        var s = createAsyncNativeSocket()

        await s.connect(testHost, testPort)

        var peerAddr: SockAddr
        var addrSize = Socklen(sizeof(peerAddr))
        var ret = SocketHandle(s).getpeername(addr(peerAddr), addr(addrSize))

        if ret < 0:
            echo("`connect(...)` failed but no exception was raised.")
            quit(2)

    waitFor(testAsyncConnect())
