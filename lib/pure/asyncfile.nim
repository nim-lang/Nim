#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements asynchronous file handling.
##
## .. code-block:: Nim
##    import asyncfile, asyncdispatch, os
##
##    proc main() {.async.} =
##      var file = openAsync(getTempDir() / "foobar.txt", fmReadWrite)
##      await file.write("test")
##      file.setFilePos(0)
##      let data = await file.readAll()
##      doAssert data == "test"
##      file.close()
##
##    waitFor main()

import asyncdispatch, os

when defined(windows):
  import winlean
else:
  import posix
  {.fatal: "Posix not yet supported".}

type
  AsyncFile = ref object
    fd: TAsyncFd
    offset: int64

when defined(windows):
  proc getDesiredAccess(mode: TFileMode): int32 =
    case mode
    of fmRead:
      result = GENERIC_READ
    of fmWrite, fmAppend:
      result = GENERIC_WRITE
    of fmReadWrite, fmReadWriteExisting:
      result = GENERIC_READ or GENERIC_WRITE

  proc getCreationDisposition(mode: TFileMode, filename: string): int32 =
    case mode
    of fmRead, fmReadWriteExisting:
      OPEN_EXISTING
    of fmAppend, fmReadWrite, fmWrite:
      if fileExists(filename):
        OPEN_EXISTING
      else:
        CREATE_NEW
else:
  proc getPosixFlags(mode: TFileMode): cint =
    case mode
    of fmRead:
      result = O_RDONLY
    of fmWrite, fmAppend:
      result = O_WRONLY or O_CREAT
    of fmReadWrite:
      result = O_RDWR or O_CREAT
    of fmReadWriteExisting:
      result = O_RDWR

proc getFileSize*(f: AsyncFile): int64 =
  ## Retrieves the specified file's size.
  when defined(windows):
    var high: DWord
    let low = getFileSize(f.fd.THandle, addr high)
    if low == INVALID_FILE_SIZE:
      raiseOSError()
    return (high shl 32) or low

proc openAsync*(filename: string, mode = fmRead): AsyncFile =
  ## Opens a file specified by the path in ``filename`` using
  ## the specified ``mode`` asynchronously.
  new result
  when defined(windows):
    let flags = FILE_FLAG_OVERLAPPED or FILE_ATTRIBUTE_NORMAL
    let desiredAccess = getDesiredAccess(mode)
    let creationDisposition = getCreationDisposition(mode, filename)
    when useWinUnicode:
      result.fd = createFileW(newWideCString(filename), desiredAccess,
          FILE_SHARE_READ,
          nil, creationDisposition, flags, 0).TAsyncFd
    else:
      result.fd = createFileA(filename, desiredAccess,
          FILE_SHARE_READ,
          nil, creationDisposition, flags, 0).TAsyncFd

    if result.fd.THandle == INVALID_HANDLE_VALUE:
      raiseOSError()

    register(result.fd)

    if mode == fmAppend:
      result.offset = getFileSize(result)

  else:
    let flags = getPosixFlags(mode)

proc read*(f: AsyncFile, size: int): Future[string] =
  ## Read ``size`` bytes from the specified file asynchronously starting at
  ## the current position of the file pointer.
  ##
  ## If the file pointer is past the end of the file then an empty string is
  ## returned.
  var retFuture = newFuture[string]("asyncfile.read")

  when defined(windows):
    var buffer = alloc0(size)

    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = TCompletionData(sock: f.fd, cb:
      proc (fd: TAsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            assert bytesCount > 0
            assert bytesCount <= size
            var data = newString(bytesCount)
            copyMem(addr data[0], buffer, bytesCount)
            f.offset.inc bytesCount
            retFuture.complete($data)
          else:
            if errcode.int32 == ERROR_HANDLE_EOF:
              retFuture.complete("")
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
        if buffer != nil:
          dealloc buffer
          buffer = nil
    )
    ol.offset = DWord(f.offset and 0xffffffff)
    ol.offsetHigh = DWord(f.offset shr 32)

    # According to MSDN we're supposed to pass nil to lpNumberOfBytesRead.
    let ret = readFile(f.fd.THandle, buffer, size.int32, nil,
                       cast[POVERLAPPED](ol))
    if not ret.bool:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        if buffer != nil:
          dealloc buffer
          buffer = nil
        GC_unref(ol)
        retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      # Request completed immediately.
      var bytesRead: DWord
      let overlappedRes = getOverlappedResult(f.fd.THandle,
          cast[POverlapped](ol)[], bytesRead, false.WinBool)
      if not overlappedRes.bool:
        let err = osLastError()
        if err.int32 == ERROR_HANDLE_EOF:
          retFuture.complete("")
        else:
          retFuture.fail(newException(OSError, osErrorMsg(osLastError())))
      else:
        assert bytesRead > 0
        assert bytesRead <= size
        var data = newString(bytesRead)
        copyMem(addr data[0], buffer, bytesRead)
        f.offset.inc bytesRead
        retFuture.complete($data)
  return retFuture

proc getFilePos*(f: AsyncFile): int64 =
  ## Retrieves the current position of the file pointer that is
  ## used to read from the specified file. The file's first byte has the
  ## index zero.
  f.offset

proc setFilePos*(f: AsyncFile, pos: int64) =
  ## Sets the position of the file pointer that is used for read/write
  ## operations. The file's first byte has the index zero. 
  f.offset = pos

proc readAll*(f: AsyncFile): Future[string] {.async.} =
  ## Reads all data from the specified file.
  result = ""
  while true:
    let data = await read(f, 4000)
    if data.len == 0:
      return
    result.add data

proc write*(f: AsyncFile, data: string): Future[void] =
  ## Writes ``data`` to the file specified asynchronously.
  ##
  ## The returned Future will complete once all data has been written to the
  ## specified file.
  var retFuture = newFuture[void]("asyncfile.write")
  var copy = data
  when defined(windows):
    var buffer = alloc0(data.len)
    copyMem(buffer, addr copy[0], data.len)

    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = TCompletionData(sock: f.fd, cb:
      proc (fd: TAsyncFD, bytesCount: DWord, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            assert bytesCount == data.len.int32
            f.offset.inc(data.len)
            retFuture.complete()
          else:
            retFuture.fail(newException(OSError, osErrorMsg(errcode)))
        if buffer != nil:
          dealloc buffer
          buffer = nil
    )
    ol.offset = DWord(f.offset and 0xffffffff)
    ol.offsetHigh = DWord(f.offset shr 32)

    # According to MSDN we're supposed to pass nil to lpNumberOfBytesWritten.
    let ret = writeFile(f.fd.THandle, buffer, data.len.int32, nil,
                       cast[POVERLAPPED](ol))
    if not ret.bool:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        if buffer != nil:
          dealloc buffer
          buffer = nil
        GC_unref(ol)
        retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      # Request completed immediately.
      var bytesWritten: DWord
      let overlappedRes = getOverlappedResult(f.fd.THandle,
          cast[POverlapped](ol)[], bytesWritten, false.WinBool)
      if not overlappedRes.bool:
        retFuture.fail(newException(OSError, osErrorMsg(osLastError())))
      else:
        assert bytesWritten == data.len.int32
        f.offset.inc(data.len)
        retFuture.complete()
  return retFuture

proc close*(f: AsyncFile) =
  ## Closes the file specified.
  when defined(windows):
    if not closeHandle(f.fd.THandle).bool:
      raiseOSError()







