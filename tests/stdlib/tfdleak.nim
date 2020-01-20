discard """
  exitcode: 0
  output: ""
"""

import os, osproc, strutils, nativesockets, net

proc leakCheck(f: File, msg: string) =
  discard startProcess(
    getAppFilename(),
    args = @["file", $f.getOsFileHandle, msg],
    options = {poParentStreams}
  ).waitForExit -1

proc leakCheck(s: SocketHandle, msg: string) =
  discard startProcess(
    getAppFilename(),
    args = @["sock", $s.FileHandle, msg],
    options = {poParentStreams}
  ).waitForExit -1

when defined(windows):
  proc openOsfHandle(handle: FileHandle, flags: cint): cint {.
    importc: "_open_osfhandle", header: "<io.h>".}

proc main() =
  if paramCount() == 0:
    # Parent process
    let f = open("__test_fdleak", fmReadWrite)
    defer: close f

    leakCheck(f, "open(string)")

    doAssert f.reopen("__test_fdleak2", fmReadWrite), "reopen failed"

    leakCheck(f, "reopen")

    var f2: File
    defer: close f2
    doAssert open(f2, f.getFileHandle), "open with FileHandle failed"

    leakCheck(f2, "open(FileHandle)")

    let sock = createNativeSocket()
    defer: close sock
    leakCheck(sock, "createNativeSocket()")

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
  else:
    let
      ops = paramStr 1
      fd = parseInt(paramStr 2)
      msg = "leaked " & paramStr 3
    case ops
    of "file":
      when defined(posix):
        var f: File
        if open(f, fd.FileHandle):
          echo msg
      else:
        if openOsfHandle(fd.FileHandle, 0) != -1:
          echo msg
    of "sock":
      try:
        discard getSockDomain(fd.SocketHandle)
        echo msg
      except:
        discard

when isMainModule: main()
