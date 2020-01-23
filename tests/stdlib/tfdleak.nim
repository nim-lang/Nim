discard """
  exitcode: 0
  output: ""
"""

import os, osproc, strutils, nativesockets, net, selectors
when defined(windows):
  import winlean
else:
  import posix

proc leakCheck(f: int | FileHandle | SocketHandle, msg: string, expectLeak = false) =
  discard startProcess(
    getAppFilename(),
    args = @[$f.int, msg, $expectLeak],
    options = {poParentStreams}
  ).waitForExit -1

proc isValidHandle(f: int): bool =
  ## Check if a handle is valid. Requires OS-native handles.
  when defined(windows):
    var flags: DWORD
    result = getHandleInformation(f.Handle, addr flags) != 0
  else:
    result = fcntl(f.cint, F_GETFD) != -1

proc main() =
  if paramCount() == 0:
    # Parent process
    let f = open("__test_fdleak", fmReadWrite)
    defer: close f

    leakCheck(f.getOsFileHandle, "open(string)")

    doAssert f.reopen("__test_fdleak2", fmReadWrite), "reopen failed"

    leakCheck(f.getOsFileHandle, "reopen")

    let sock = createNativeSocket()
    defer: close sock
    leakCheck(sock, "createNativeSocket()")
    if sock.setInheritable(true):
      leakCheck(sock, "createNativeSocket()", true)
    else:
      raiseOSError osLastError()

    let server = newSocket()
    defer: close server
    server.bindAddr()
    server.listen()
    let (_, port) = server.getLocalAddr

    leakCheck(server.getFd, "newSocket()")

    let client = newSocket()
    defer: close client
    client.connect("127.0.0.1", port)

    var input: Socket
    server.accept(input)

    leakCheck(input.getFd, "accept()")

    # ioselectors_select doesn't support returning a handle.
    when not defined(windows):
      let selector = newSelector[int]()
      leakCheck(selector.getFd, "selector()")
  else:
    let
      fd = parseInt(paramStr 1)
      expectLeak = parseBool(paramStr 3)
      msg = (if expectLeak: "not " else: "") & "leaked " & paramStr 2
    if expectLeak xor fd.isValidHandle:
      echo msg

when isMainModule: main()
