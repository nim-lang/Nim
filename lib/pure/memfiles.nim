#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Authors: Zahary Karadjov, Andreas Rumpf
##
## This module provides support for `memory mapped files`:idx:
## (Posix's `mmap`:idx:) on the different operating systems.
##
## It also provides some fast iterators over lines in text files (or
## other "line-like", variable length, delimited records).

when defined(windows):
  import winlean
elif defined(posix):
  import posix
else:
  {.error: "the memfiles module is not supported on your operating system!".}

import os, streams

proc newEIO(msg: string): ref IOError =
  new(result)
  result.msg = msg

type
  MemFile* = object      ## represents a memory mapped file
    mem*: pointer        ## a pointer to the memory mapped file. The pointer
                         ## can be used directly to change the contents of the
                         ## file, if it was opened with write access.
    size*: int           ## size of the memory mapped file

    when defined(windows):
      fHandle*: Handle   ## **Caution**: Windows specific public field to allow
                         ## even more low level trickery.
      mapHandle*: Handle ## **Caution**: Windows specific public field.
      wasOpened*: bool   ## **Caution**: Windows specific public field.
    else:
      handle*: cint      ## **Caution**: Posix specific public field.
      flags: cint        ## **Caution**: Platform specific private field.

proc mapMem*(m: var MemFile, mode: FileMode = fmRead,
             mappedSize = -1, offset = 0, mapFlags = cint(-1)): pointer =
  ## returns a pointer to a mapped portion of MemFile `m`
  ##
  ## `mappedSize` of `-1` maps to the whole file, and
  ## `offset` must be multiples of the PAGE SIZE of your OS
  if mode == fmAppend:
    raise newEIO("The append mode is not supported.")

  var readonly = mode == fmRead
  when defined(windows):
    result = mapViewOfFileEx(
      m.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_READ or FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      WinSizeT(if mappedSize == -1: 0 else: mappedSize),
      nil)
    if result == nil:
      raiseOSError(osLastError())
  else:
    assert mappedSize > 0

    m.flags = if mapFlags == cint(-1): MAP_SHARED else: mapFlags
    #Ensure exactly one of MAP_PRIVATE cr MAP_SHARED is set
    if int(m.flags and MAP_PRIVATE) == 0:
      m.flags = m.flags or MAP_SHARED

    result = mmap(
      nil,
      mappedSize,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      m.flags,
      m.handle, offset)
    if result == cast[pointer](MAP_FAILED):
      raiseOSError(osLastError())


proc unmapMem*(f: var MemFile, p: pointer, size: int) =
  ## unmaps the memory region `(p, <p+size)` of the mapped file `f`.
  ## All changes are written back to the file system, if `f` was opened
  ## with write access.
  ##
  ## `size` must be of exactly the size that was requested
  ## via `mapMem`.
  when defined(windows):
    if unmapViewOfFile(p) == 0: raiseOSError(osLastError())
  else:
    if munmap(p, size) != 0: raiseOSError(osLastError())


proc open*(filename: string, mode: FileMode = fmRead,
           mappedSize = -1, offset = 0, newFileSize = -1,
           allowRemap = false, mapFlags = cint(-1)): MemFile =
  ## opens a memory mapped file. If this fails, `OSError` is raised.
  ##
  ## `newFileSize` can only be set if the file does not exist and is opened
  ## with write access (e.g., with fmReadWrite).
  ##
  ##`mappedSize` and `offset`
  ## can be used to map only a slice of the file.
  ##
  ## `offset` must be multiples of the PAGE SIZE of your OS
  ## (usually 4K or 8K but is unique to your OS)
  ##
  ## `allowRemap` only needs to be true if you want to call `mapMem` on
  ## the resulting MemFile; else file handles are not kept open.
  ##
  ## `mapFlags` allows callers to override default choices for memory mapping
  ## flags with a bitwise mask of a variety of likely platform-specific flags
  ## which may be ignored or even cause `open` to fail if misspecified.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var
  ##     mm, mm_full, mm_half: MemFile
  ##
  ##   mm = memfiles.open("/tmp/test.mmap", mode = fmWrite, newFileSize = 1024)    # Create a new file
  ##   mm.close()
  ##
  ##   # Read the whole file, would fail if newFileSize was set
  ##   mm_full = memfiles.open("/tmp/test.mmap", mode = fmReadWrite, mappedSize = -1)
  ##
  ##   # Read the first 512 bytes
  ##   mm_half = memfiles.open("/tmp/test.mmap", mode = fmReadWrite, mappedSize = 512)

  # The file can be resized only when write mode is used:
  if mode == fmAppend:
    raise newEIO("The append mode is not supported.")

  assert newFileSize == -1 or mode != fmRead
  var readonly = mode == fmRead

  template rollback =
    result.mem = nil
    result.size = 0

  when defined(windows):
    let desiredAccess = GENERIC_READ
    let shareMode = FILE_SHARE_READ
    let flags = FILE_FLAG_RANDOM_ACCESS

    template fail(errCode: OSErrorCode, msg: untyped) =
      rollback()
      if result.fHandle != 0: discard closeHandle(result.fHandle)
      if result.mapHandle != 0: discard closeHandle(result.mapHandle)
      raiseOSError(errCode)
      # return false
      #raise newException(IOError, msg)

    template callCreateFile(winApiProc, filename): untyped =
      winApiProc(
        filename,
        # GENERIC_ALL != (GENERIC_READ or GENERIC_WRITE)
        if readonly: desiredAccess else: desiredAccess or GENERIC_WRITE,
        if readonly: shareMode else: shareMode or FILE_SHARE_WRITE,
        nil,
        if newFileSize != -1: CREATE_ALWAYS else: OPEN_EXISTING,
        if readonly: FILE_ATTRIBUTE_READONLY or flags
        else: FILE_ATTRIBUTE_NORMAL or flags,
        0)

    when useWinUnicode:
      result.fHandle = callCreateFile(createFileW, newWideCString(filename))
    else:
      result.fHandle = callCreateFile(createFileA, filename)

    if result.fHandle == INVALID_HANDLE_VALUE:
      fail(osLastError(), "error opening file")

    if newFileSize != -1:
      var
        sizeHigh = int32(newFileSize shr 32)
        sizeLow = int32(newFileSize and 0xffffffff)

      var status = setFilePointer(result.fHandle, sizeLow, addr(sizeHigh),
                                  FILE_BEGIN)
      let lastErr = osLastError()
      if (status == INVALID_SET_FILE_POINTER and lastErr.int32 != NO_ERROR) or
          (setEndOfFile(result.fHandle) == 0):
        fail(lastErr, "error setting file size")

    # since the strings are always 'nil', we simply always call
    # CreateFileMappingW which should be slightly faster anyway:
    result.mapHandle = createFileMappingW(
      result.fHandle, nil,
      if readonly: PAGE_READONLY else: PAGE_READWRITE,
      0, 0, nil)

    if result.mapHandle == 0:
      fail(osLastError(), "error creating mapping")

    result.mem = mapViewOfFileEx(
      result.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_READ or FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)

    if result.mem == nil:
      fail(osLastError(), "error mapping view")

    var hi, low: int32
    low = getFileSize(result.fHandle, addr(hi))
    if low == INVALID_FILE_SIZE:
      fail(osLastError(), "error getting file size")
    else:
      var fileSize = (int64(hi) shl 32) or int64(uint32(low))
      if mappedSize != -1: result.size = min(fileSize, mappedSize).int
      else: result.size = fileSize.int

    result.wasOpened = true
    if not allowRemap and result.fHandle != INVALID_HANDLE_VALUE:
      if closeHandle(result.fHandle) == 0:
        result.fHandle = INVALID_HANDLE_VALUE

  else:
    template fail(errCode: OSErrorCode, msg: string) =
      rollback()
      if result.handle != -1: discard close(result.handle)
      raiseOSError(errCode)

    var flags = (if readonly: O_RDONLY else: O_RDWR) or O_CLOEXEC

    if newFileSize != -1:
      flags = flags or O_CREAT or O_TRUNC
      var permissionsMode = S_IRUSR or S_IWUSR
      result.handle = open(filename, flags, permissionsMode)
    else:
      result.handle = open(filename, flags)

    if result.handle == -1:
      # XXX: errno is supposed to be set here
      # Is there an exception that wraps it?
      fail(osLastError(), "error opening file")

    if newFileSize != -1:
      if ftruncate(result.handle, newFileSize) == -1:
        fail(osLastError(), "error setting file size")

    if mappedSize != -1:
      result.size = mappedSize
    else:
      var stat: Stat
      if fstat(result.handle, stat) != -1:
        # XXX: Hmm, this could be unsafe
        # Why is mmap taking int anyway?
        result.size = int(stat.st_size)
      else:
        fail(osLastError(), "error getting file size")

    result.flags = if mapFlags == cint(-1): MAP_SHARED else: mapFlags
    #Ensure exactly one of MAP_PRIVATE cr MAP_SHARED is set
    if int(result.flags and MAP_PRIVATE) == 0:
      result.flags = result.flags or MAP_SHARED

    result.mem = mmap(
      nil,
      result.size,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      result.flags,
      result.handle,
      offset)

    if result.mem == cast[pointer](MAP_FAILED):
      fail(osLastError(), "file mapping failed")

    if not allowRemap and result.handle != -1:
      if close(result.handle) == 0:
        result.handle = -1

proc flush*(f: var MemFile; attempts: Natural = 3) =
  ## Flushes `f`'s buffer for the number of attempts equal to `attempts`.
  ## If were errors an exception `OSError` will be raised.
  var res = false
  var lastErr: OSErrorCode
  when defined(windows):
    for i in 1..attempts:
      res = flushViewOfFile(f.mem, 0) != 0
      if res:
        break
      lastErr = osLastError()
      if lastErr != ERROR_LOCK_VIOLATION.OSErrorCode:
        raiseOSError(lastErr)
  else:
    for i in 1..attempts:
      res = msync(f.mem, f.size, MS_SYNC or MS_INVALIDATE) == 0
      if res:
        break
      lastErr = osLastError()
      if lastErr != EBUSY.OSErrorCode:
        raiseOSError(lastErr, "error flushing mapping")

when defined(posix) or defined(nimdoc):
  proc resize*(f: var MemFile, newFileSize: int) {.raises: [IOError, OSError].} =
    ## resize and re-map the file underlying an `allowRemap MemFile`.
    ## **Note**: this assumes the entire file is mapped read-write at offset zero.
    ## Also, the value of `.mem` will probably change.
    ## **Note**: This is not (yet) available on Windows.
    when defined(posix):
      if f.handle == -1:
        raise newException(IOError,
                            "Cannot resize MemFile opened with allowRemap=false")
      if ftruncate(f.handle, newFileSize) == -1:
        raiseOSError(osLastError())
      when defined(linux): #Maybe NetBSD, too?
        #On Linux this can be over 100 times faster than a munmap,mmap cycle.
        proc mremap(old: pointer; oldSize, newSize: csize; flags: cint):
            pointer {.importc: "mremap", header: "<sys/mman.h>".}
        let newAddr = mremap(f.mem, csize(f.size), csize(newFileSize), cint(1))
        if newAddr == cast[pointer](MAP_FAILED):
          raiseOSError(osLastError())
      else:
        if munmap(f.mem, f.size) != 0:
          raiseOSError(osLastError())
        let newAddr = mmap(nil, newFileSize, PROT_READ or PROT_WRITE,
                           f.flags, f.handle, 0)
        if newAddr == cast[pointer](MAP_FAILED):
          raiseOSError(osLastError())
      f.mem = newAddr
      f.size = newFileSize

proc close*(f: var MemFile) =
  ## closes the memory mapped file `f`. All changes are written back to the
  ## file system, if `f` was opened with write access.

  var error = false
  var lastErr: OSErrorCode

  when defined(windows):
    if f.wasOpened:
      error = unmapViewOfFile(f.mem) == 0
      if not error:
        error = closeHandle(f.mapHandle) == 0
        if not error and f.fHandle != INVALID_HANDLE_VALUE:
          discard closeHandle(f.fHandle)
          f.fHandle = INVALID_HANDLE_VALUE
      if error:
        lastErr = osLastError()
  else:
    error = munmap(f.mem, f.size) != 0
    lastErr = osLastError()
    if f.handle != -1:
      error = (close(f.handle) != 0) or error

  f.size = 0
  f.mem = nil

  when defined(windows):
    f.fHandle = 0
    f.mapHandle = 0
    f.wasOpened = false
  else:
    f.handle = -1

  if error: raiseOSError(lastErr)

type MemSlice* = object ## represent slice of a MemFile for iteration over delimited lines/records
  data*: pointer
  size*: int

proc `==`*(x, y: MemSlice): bool =
  ## Compare a pair of MemSlice for strict equality.
  result = (x.size == y.size and equalMem(x.data, y.data, x.size))

proc `$`*(ms: MemSlice): string {.inline.} =
  ## Return a Nim string built from a MemSlice.
  result.setLen(ms.size)
  copyMem(addr(result[0]), ms.data, ms.size)

iterator memSlices*(mfile: MemFile, delim = '\l', eat = '\r'): MemSlice {.inline.} =
  ## Iterates over [optional `eat`] `delim`-delimited slices in MemFile `mfile`.
  ##
  ## Default parameters parse lines ending in either Unix(\\l) or Windows(\\r\\l)
  ## style on on a line-by-line basis.  I.e., not every line needs the same ending.
  ## Unlike readLine(File) & lines(File), archaic MacOS9 \\r-delimited lines
  ## are not supported as a third option for each line.  Such archaic MacOS9
  ## files can be handled by passing delim='\\r', eat='\\0', though.
  ##
  ## Delimiters are not part of the returned slice.  A final, unterminated line
  ## or record is returned just like any other.
  ##
  ## Non-default delimiters can be passed to allow iteration over other sorts
  ## of "line-like" variable length records.  Pass eat='\\0' to be strictly
  ## `delim`-delimited. (Eating an optional prefix equal to '\\0' is not
  ## supported.)
  ##
  ## This zero copy, memchr-limited interface is probably the fastest way to
  ## iterate over line-like records in a file.  However, returned (data,size)
  ## objects are not Nim strings, bounds checked Nim arrays, or even terminated
  ## C strings.  So, care is required to access the data (e.g., think C mem*
  ## functions, not str* functions).
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var count = 0
  ##   for slice in memSlices(memfiles.open("foo")):
  ##     if slice.size > 0 and cast[cstring](slice.data)[0] != '#':
  ##       inc(count)
  ##   echo count

  proc c_memchr(cstr: pointer, c: char, n: csize): pointer {.
       importc: "memchr", header: "<string.h>".}
  proc `-!`(p, q: pointer): int {.inline.} = return cast[int](p) -% cast[int](q)
  var ms: MemSlice
  var ending: pointer
  ms.data = mfile.mem
  var remaining = mfile.size
  while remaining > 0:
    ending = c_memchr(ms.data, delim, remaining)
    if ending == nil: # unterminated final slice
      ms.size = remaining # Weird case..check eat?
      yield ms
      break
    ms.size = ending -! ms.data # delim is NOT included
    if eat != '\0' and ms.size > 0 and cast[cstring](ms.data)[ms.size - 1] == eat:
      dec(ms.size) # trim pre-delim char
    yield ms
    ms.data = cast[pointer](cast[int](ending) +% 1) # skip delim
    remaining = mfile.size - (ms.data -! mfile.mem)

iterator lines*(mfile: MemFile, buf: var string, delim = '\l',
    eat = '\r'): string {.inline.} =
  ## Replace contents of passed buffer with each new line, like
  ## `readLine(File) <io.html#readLine,File,string>`_.
  ## `delim`, `eat`, and delimiting logic is exactly as for `memSlices
  ## <#memSlices.i,MemFile,char,char>`_, but Nim strings are returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var buffer: string = ""
  ##   for line in lines(memfiles.open("foo"), buffer):
  ##     echo line

  for ms in memSlices(mfile, delim, eat):
    setLen(buf, ms.size)
    if ms.size > 0:
      copyMem(addr buf[0], ms.data, ms.size)
    yield buf

iterator lines*(mfile: MemFile, delim = '\l', eat = '\r'): string {.inline.} =
  ## Return each line in a file as a Nim string, like
  ## `lines(File) <io.html#lines.i,File>`_.
  ## `delim`, `eat`, and delimiting logic is exactly as for `memSlices
  ## <#memSlices.i,MemFile,char,char>`_, but Nim strings are returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   for line in lines(memfiles.open("foo")):
  ##     echo line

  var buf = newStringOfCap(80)
  for line in lines(mfile, buf, delim, eat):
    yield buf

type
  MemMapFileStream* = ref MemMapFileStreamObj ## a stream that encapsulates a `MemFile`
  MemMapFileStreamObj* = object of Stream
    mf: MemFile
    mode: FileMode
    pos: ByteAddress

proc mmsClose(s: Stream) =
  MemMapFileStream(s).pos = -1
  close(MemMapFileStream(s).mf)

proc mmsFlush(s: Stream) = flush(MemMapFileStream(s).mf)

proc mmsAtEnd(s: Stream): bool = (MemMapFileStream(s).pos >= MemMapFileStream(s).mf.size) or
                                  (MemMapFileStream(s).pos < 0)

proc mmsSetPosition(s: Stream, pos: int) =
  if pos > MemMapFileStream(s).mf.size or pos < 0:
    raise newEIO("cannot set pos in stream")
  MemMapFileStream(s).pos = pos

proc mmsGetPosition(s: Stream): int = MemMapFileStream(s).pos

proc mmsPeekData(s: Stream, buffer: pointer, bufLen: int): int =
  let startAddress = cast[ByteAddress](MemMapFileStream(s).mf.mem)
  let p = cast[ByteAddress](MemMapFileStream(s).pos)
  let l = min(bufLen, MemMapFileStream(s).mf.size - p)
  moveMem(buffer, cast[pointer](startAddress + p), l)
  result = l

proc mmsReadData(s: Stream, buffer: pointer, bufLen: int): int =
  result = mmsPeekData(s, buffer, bufLen)
  inc(MemMapFileStream(s).pos, result)

proc mmsWriteData(s: Stream, buffer: pointer, bufLen: int) =
  if MemMapFileStream(s).mode == fmRead:
    raise newEIO("cannot write to read-only stream")
  let size = MemMapFileStream(s).mf.size
  if MemMapFileStream(s).pos + bufLen > size:
    raise newEIO("cannot write to stream")
  let p = cast[ByteAddress](MemMapFileStream(s).mf.mem) +
          cast[ByteAddress](MemMapFileStream(s).pos)
  moveMem(cast[pointer](p), buffer, bufLen)
  inc(MemMapFileStream(s).pos, bufLen)

proc newMemMapFileStream*(filename: string, mode: FileMode = fmRead,
    fileSize: int = -1): MemMapFileStream =
  ## creates a new stream from the file named `filename` with the mode `mode`.
  ## Raises ## `OSError` if the file cannot be opened. See the `system
  ## <system.html>`_ module for a list of available FileMode enums.
  ## `fileSize` can only be set if the file does not exist and is opened
  ## with write access (e.g., with fmReadWrite).
  var mf: MemFile = open(filename, mode, newFileSize = fileSize)
  new(result)
  result.mode = mode
  result.mf = mf
  result.closeImpl = mmsClose
  result.atEndImpl = mmsAtEnd
  result.setPositionImpl = mmsSetPosition
  result.getPositionImpl = mmsGetPosition
  result.readDataImpl = mmsReadData
  result.peekDataImpl = mmsPeekData
  result.writeDataImpl = mmsWriteData
  result.flushImpl = mmsFlush
