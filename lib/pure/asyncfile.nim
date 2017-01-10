#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements asynchronous file reading and writing.
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

# TODO: Fix duplication introduced by PR #4683.

when defined(windows) or defined(nimdoc):
  import winlean
else:
  import posix

type
  AsyncFile* = ref object
    fd: AsyncFd
    offset: int64

when defined(windows) or defined(nimdoc):
  proc getDesiredAccess(mode: FileMode): int32 =
    case mode
    of fmRead:
      result = GENERIC_READ
    of fmWrite, fmAppend:
      result = GENERIC_WRITE
    of fmReadWrite, fmReadWriteExisting:
      result = GENERIC_READ or GENERIC_WRITE

  proc getCreationDisposition(mode: FileMode, filename: string): int32 =
    case mode
    of fmRead, fmReadWriteExisting:
      OPEN_EXISTING
    of fmAppend, fmReadWrite, fmWrite:
      if fileExists(filename):
        OPEN_EXISTING
      else:
        CREATE_NEW
else:
  proc getPosixFlags(mode: FileMode): cint =
    case mode
    of fmRead:
      result = O_RDONLY
    of fmWrite:
      result = O_WRONLY or O_CREAT
    of fmAppend:
      result = O_WRONLY or O_CREAT or O_APPEND
    of fmReadWrite:
      result = O_RDWR or O_CREAT
    of fmReadWriteExisting:
      result = O_RDWR
    result = result or O_NONBLOCK

proc getFileSize(f: AsyncFile): int64 =
  ## Retrieves the specified file's size.
  when defined(windows) or defined(nimdoc):
    var high: DWord
    let low = getFileSize(f.fd.Handle, addr high)
    if low == INVALID_FILE_SIZE:
      raiseOSError(osLastError())
    return (high shl 32) or low

proc openAsync*(filename: string, mode = fmRead): AsyncFile =
  ## Opens a file specified by the path in ``filename`` using
  ## the specified ``mode`` asynchronously.
  new result
  when defined(windows) or defined(nimdoc):
    let flags = FILE_FLAG_OVERLAPPED or FILE_ATTRIBUTE_NORMAL
    let desiredAccess = getDesiredAccess(mode)
    let creationDisposition = getCreationDisposition(mode, filename)
    when useWinUnicode:
      result.fd = createFileW(newWideCString(filename), desiredAccess,
          FILE_SHARE_READ,
          nil, creationDisposition, flags, 0).AsyncFd
    else:
      result.fd = createFileA(filename, desiredAccess,
          FILE_SHARE_READ,
          nil, creationDisposition, flags, 0).AsyncFd

    if result.fd.Handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError())

    register(result.fd)

    if mode == fmAppend:
      result.offset = getFileSize(result)

  else:
    let flags = getPosixFlags(mode)
    # RW (Owner), RW (Group), R (Other)
    let perm = S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP or S_IROTH
    result.fd = open(filename, flags, perm).AsyncFD
    if result.fd.cint == -1:
      raiseOSError(osLastError())

    register(result.fd)

proc readBuffer*(f: AsyncFile, buf: pointer, size: int): Future[int] =
  ## Read ``size`` bytes from the specified file asynchronously starting at
  ## the current position of the file pointer.
  ##
  ## If the file pointer is past the end of the file then zero is returned
  ## and no bytes are read into ``buf``
  var retFuture = newFuture[int]("asyncfile.readBuffer")

  when defined(windows) or defined(nimdoc):
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: f.fd, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            assert bytesCount > 0
            assert bytesCount <= size
            f.offset.inc bytesCount
            retFuture.complete(bytesCount)
          else:
            if errcode.int32 == ERROR_HANDLE_EOF:
              retFuture.complete(0)
            else:
              retFuture.fail(newException(OSError, osErrorMsg(errcode)))
    )
    ol.offset = DWord(f.offset and 0xffffffff)
    ol.offsetHigh = DWord(f.offset shr 32)

    # According to MSDN we're supposed to pass nil to lpNumberOfBytesRead.
    let ret = readFile(f.fd.Handle, buf, size.int32, nil,
                       cast[POVERLAPPED](ol))
    if not ret.bool:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        GC_unref(ol)
        if err.int32 == ERROR_HANDLE_EOF:
          # This happens in Windows Server 2003
          retFuture.complete(0)
        else:
          retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      # Request completed immediately.
      var bytesRead: DWord
      let overlappedRes = getOverlappedResult(f.fd.Handle,
          cast[POverlapped](ol), bytesRead, false.WinBool)
      if not overlappedRes.bool:
        let err = osLastError()
        if err.int32 == ERROR_HANDLE_EOF:
          retFuture.complete(0)
        else:
          retFuture.fail(newException(OSError, osErrorMsg(osLastError())))
      else:
        assert bytesRead > 0
        assert bytesRead <= size
        f.offset.inc bytesRead
        retFuture.complete(bytesRead)
  else:
    proc cb(fd: AsyncFD): bool =
      result = true
      let res = read(fd.cint, cast[cstring](buf), size.cint)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 != EAGAIN:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      elif res == 0:
        # EOF
        retFuture.complete(0)
      else:
        f.offset.inc(res)
        retFuture.complete(res)

    if not cb(f.fd):
      addRead(f.fd, cb)

  return retFuture

proc read*(f: AsyncFile, size: int): Future[string] =
  ## Read ``size`` bytes from the specified file asynchronously starting at
  ## the current position of the file pointer.
  ##
  ## If the file pointer is past the end of the file then an empty string is
  ## returned.
  var retFuture = newFuture[string]("asyncfile.read")

  when defined(windows) or defined(nimdoc):
    var buffer = alloc0(size)

    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: f.fd, cb:
      proc (fd: AsyncFD, bytesCount: Dword, errcode: OSErrorCode) =
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
    let ret = readFile(f.fd.Handle, buffer, size.int32, nil,
                       cast[POVERLAPPED](ol))
    if not ret.bool:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        if buffer != nil:
          dealloc buffer
          buffer = nil
        GC_unref(ol)

        if err.int32 == ERROR_HANDLE_EOF:
          # This happens in Windows Server 2003
          retFuture.complete("")
        else:
          retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      # Request completed immediately.
      var bytesRead: DWord
      let overlappedRes = getOverlappedResult(f.fd.Handle,
          cast[POverlapped](ol), bytesRead, false.WinBool)
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
  else:
    var readBuffer = newString(size)

    proc cb(fd: AsyncFD): bool =
      result = true
      let res = read(fd.cint, addr readBuffer[0], size.cint)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 != EAGAIN:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      elif res == 0:
        # EOF
        retFuture.complete("")
      else:
        readBuffer.setLen(res)
        f.offset.inc(res)
        retFuture.complete(readBuffer)

    if not cb(f.fd):
      addRead(f.fd, cb)

  return retFuture

proc readLine*(f: AsyncFile): Future[string] {.async.} =
  ## Reads a single line from the specified file asynchronously.
  result = ""
  while true:
    var c = await read(f, 1)
    if c[0] == '\c':
      c = await read(f, 1)
      break
    if c[0] == '\L' or c == "":
      break
    else:
      result.add(c)

proc getFilePos*(f: AsyncFile): int64 =
  ## Retrieves the current position of the file pointer that is
  ## used to read from the specified file. The file's first byte has the
  ## index zero.
  f.offset

proc setFilePos*(f: AsyncFile, pos: int64) =
  ## Sets the position of the file pointer that is used for read/write
  ## operations. The file's first byte has the index zero.
  f.offset = pos
  when not defined(windows) and not defined(nimdoc):
    let ret = lseek(f.fd.cint, pos, SEEK_SET)
    if ret == -1:
      raiseOSError(osLastError())

proc readAll*(f: AsyncFile): Future[string] {.async.} =
  ## Reads all data from the specified file.
  result = ""
  while true:
    let data = await read(f, 4000)
    if data.len == 0:
      return
    result.add data

proc writeBuffer*(f: AsyncFile, buf: pointer, size: int): Future[void] =
  ## Writes ``size`` bytes from ``buf`` to the file specified asynchronously.
  ##
  ## The returned Future will complete once all data has been written to the
  ## specified file.
  var retFuture = newFuture[void]("asyncfile.writeBuffer")
  when defined(windows) or defined(nimdoc):
    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: f.fd, cb:
      proc (fd: AsyncFD, bytesCount: DWord, errcode: OSErrorCode) =
        if not retFuture.finished:
          if errcode == OSErrorCode(-1):
            assert bytesCount == size.int32
            f.offset.inc(size)
            retFuture.complete()
          else:
            retFuture.fail(newException(OSError, osErrorMsg(errcode)))
    )
    ol.offset = DWord(f.offset and 0xffffffff)
    ol.offsetHigh = DWord(f.offset shr 32)

    # According to MSDN we're supposed to pass nil to lpNumberOfBytesWritten.
    let ret = writeFile(f.fd.Handle, buf, size.int32, nil,
                       cast[POVERLAPPED](ol))
    if not ret.bool:
      let err = osLastError()
      if err.int32 != ERROR_IO_PENDING:
        GC_unref(ol)
        retFuture.fail(newException(OSError, osErrorMsg(err)))
    else:
      # Request completed immediately.
      var bytesWritten: DWord
      let overlappedRes = getOverlappedResult(f.fd.Handle,
          cast[POverlapped](ol), bytesWritten, false.WinBool)
      if not overlappedRes.bool:
        retFuture.fail(newException(OSError, osErrorMsg(osLastError())))
      else:
        assert bytesWritten == size.int32
        f.offset.inc(size)
        retFuture.complete()
  else:
    var written = 0

    proc cb(fd: AsyncFD): bool =
      result = true
      let remainderSize = size-written
      var cbuf = cast[cstring](buf)
      let res = write(fd.cint, addr cbuf[written], remainderSize.cint)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 != EAGAIN:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      else:
        written.inc res
        f.offset.inc res
        if res != remainderSize:
          result = false # We still have data to write.
        else:
          retFuture.complete()

    if not cb(f.fd):
      addWrite(f.fd, cb)
  return retFuture

proc write*(f: AsyncFile, data: string): Future[void] =
  ## Writes ``data`` to the file specified asynchronously.
  ##
  ## The returned Future will complete once all data has been written to the
  ## specified file.
  var retFuture = newFuture[void]("asyncfile.write")
  var copy = data
  when defined(windows) or defined(nimdoc):
    var buffer = alloc0(data.len)
    copyMem(buffer, addr copy[0], data.len)

    var ol = PCustomOverlapped()
    GC_ref(ol)
    ol.data = CompletionData(fd: f.fd, cb:
      proc (fd: AsyncFD, bytesCount: DWord, errcode: OSErrorCode) =
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
    let ret = writeFile(f.fd.Handle, buffer, data.len.int32, nil,
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
      let overlappedRes = getOverlappedResult(f.fd.Handle,
          cast[POverlapped](ol), bytesWritten, false.WinBool)
      if not overlappedRes.bool:
        retFuture.fail(newException(OSError, osErrorMsg(osLastError())))
      else:
        assert bytesWritten == data.len.int32
        f.offset.inc(data.len)
        retFuture.complete()
  else:
    var written = 0

    proc cb(fd: AsyncFD): bool =
      result = true
      let remainderSize = data.len-written
      let res = write(fd.cint, addr copy[written], remainderSize.cint)
      if res < 0:
        let lastError = osLastError()
        if lastError.int32 != EAGAIN:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
        else:
          result = false # We still want this callback to be called.
      else:
        written.inc res
        f.offset.inc res
        if res != remainderSize:
          result = false # We still have data to write.
        else:
          retFuture.complete()

    if not cb(f.fd):
      addWrite(f.fd, cb)
  return retFuture

proc close*(f: AsyncFile) =
  ## Closes the file specified.
  unregister(f.fd)
  when defined(windows) or defined(nimdoc):
    if not closeHandle(f.fd.Handle).bool:
      raiseOSError(osLastError())
  else:
    if close(f.fd.cint) == -1:
      raiseOSError(osLastError())

