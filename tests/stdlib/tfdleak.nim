discard """
  exitcode: 0
  output: ""
  matrix: "; -d:nimInheritHandles"
"""

import os, osproc, strutils, nativesockets, net, selectors, memfiles,
       asyncdispatch, asyncnet
when defined(windows):
  import winlean
else:
  import posix

proc leakCheck(f: AsyncFD | int | FileHandle | SocketHandle, msg: string,
               expectLeak = defined(nimInheritHandles)) =
  discard startProcess(
    getAppFilename(),
    args = @[$f.int, msg, $expectLeak],
    options = {poParentStreams}
  ).waitForExit -1

proc isValidHandle(f: int): bool =
  ## Check if a handle is valid. Requires OS-native handles; buggy on windows.
  when defined(windows):
    #[
    bug:
    this has false positives, see `mfdleakIssue14090`.
    It seems the handle gets reused in the child but that doesn't mean the file
    is opened in the child; indeed modifying the code and trying to use the file to
    read some open file would fail.

    The best resource2 on this topic I found is:
    * https://docs.microsoft.com/en-us/windows/win32/procthread/inheritance
    * https://wiki.sei.cmu.edu/confluence/display/c/WIN03-C.+Understand+HANDLE+inheritance
    Handle inheritance involves specifying whether a handle is inheritable (via BOOL
    or SECURITY_DESCRIPTOR parameter), and then specifying in `CreateProcess`
    whether the spawned process will inherit handles previously flagged as inheritable.

    `system` seems different also, and a windows specific "N" flag given to `fopen`
    controls inheritence.
    
    The article also mentions instead using `GetFileInformationByHandle`

    * see also: https://github.com/python/cpython/blob/master/Python/fileutils.c
    ]#
    var flags: DWORD
    # maybe `GetFileInformationByHandle` is more suitable
    result = getHandleInformation(f.Handle, addr flags) != 0
  else:
    result = fcntl(f.cint, F_GETFD) != -1

proc main() =
  if paramCount() == 0:
    # Parent process
    let f = system.open("__test_fdleak", fmReadWrite)
    defer: close f

    leakCheck(f.getOsFileHandle, "system.open()")

    doAssert f.reopen("__test_fdleak2", fmReadWrite), "reopen failed"

    leakCheck(f.getOsFileHandle, "reopen")

    let sock = createNativeSocket()
    defer: close sock
    leakCheck(sock, "createNativeSocket()")
    if sock.setInheritable(not defined(nimInheritHandles)):
      leakCheck(sock, "createNativeSocket()", not defined(nimInheritHandles))
    else:
      raiseOSError osLastError()

    let server = newSocket()
    defer: close server
    server.bindAddr(address = "127.0.0.1")
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
      leakCheck(selector.getFd, "selector()", false)

    var mf = memfiles.open("__test_fdleak3", fmReadWrite, newFileSize = 1)
    defer: close mf
    when defined(windows):
      leakCheck(mf.fHandle, "memfiles.open().fHandle", false)
      leakCheck(mf.mapHandle, "memfiles.open().mapHandle", false)
    else:
      leakCheck(mf.handle, "memfiles.open().handle", false)

    let sockAsync = createAsyncNativeSocket()
    defer: closeSocket sockAsync
    leakCheck(sockAsync, "createAsyncNativeSocket()")
    if sockAsync.setInheritable(not defined(nimInheritHandles)):
      leakCheck(sockAsync, "createAsyncNativeSocket()", not defined(nimInheritHandles))
    else:
      raiseOSError osLastError()

    let serverAsync = newAsyncSocket()
    defer: close serverAsync
    serverAsync.bindAddr(address = "127.0.0.1")
    serverAsync.listen()
    let (_, portAsync) = serverAsync.getLocalAddr

    leakCheck(serverAsync.getFd, "newAsyncSocket()")

    let clientAsync = newAsyncSocket()
    defer: close clientAsync
    waitFor clientAsync.connect("127.0.0.1", portAsync)

    let inputAsync = waitFor serverAsync.accept()

    leakCheck(inputAsync.getFd, "accept() async")
  else:
    let
      fd = parseInt(paramStr 1)
      expectLeak = parseBool(paramStr 3)
      msg = (if expectLeak: "not " else: "") & "leaked " & paramStr 2
    template fn() =
      if expectLeak xor fd.isValidHandle:
        echo (msg, fd, expectLeak, defined(nimInheritHandles))

    when defined windows:
      # `isValidHandle` has false positives on windows
      if expectLeak: fn()
    else: fn()

when isMainModule: main()
