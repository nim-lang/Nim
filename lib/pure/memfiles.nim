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

import os

type
  MemFile* = object  ## represents a memory mapped file
    mem*: pointer    ## a pointer to the memory mapped file. The pointer
                     ## can be used directly to change the contents of the
                     ## file, if it was opened with write access.
    size*: int       ## size of the memory mapped file

    when defined(windows):
      fHandle: Handle
      mapHandle: Handle
      wasOpened: bool   ## only close if wasOpened
    else:
      handle: cint

proc mapMem*(m: var MemFile, mode: FileMode = fmRead,
             mappedSize = -1, offset = 0): pointer =
  ## returns a pointer to a mapped portion of MemFile `m`
  ##
  ## ``mappedSize`` of ``-1`` maps to the whole file, and
  ## ``offset`` must be multiples of the PAGE SIZE of your OS
  var readonly = mode == fmRead
  when defined(windows):
    result = mapViewOfFileEx(
      m.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)
    if result == nil:
      raiseOSError(osLastError())
  else:
    assert mappedSize > 0
    result = mmap(
      nil,
      mappedSize,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: (MAP_PRIVATE or MAP_POPULATE) else: (MAP_SHARED or MAP_POPULATE),
      m.handle, offset)
    if result == cast[pointer](MAP_FAILED):
      raiseOSError(osLastError())


proc unmapMem*(f: var MemFile, p: pointer, size: int) =
  ## unmaps the memory region ``(p, <p+size)`` of the mapped file `f`.
  ## All changes are written back to the file system, if `f` was opened
  ## with write access.
  ##
  ## ``size`` must be of exactly the size that was requested
  ## via ``mapMem``.
  when defined(windows):
    if unmapViewOfFile(p) == 0: raiseOSError(osLastError())
  else:
    if munmap(p, size) != 0: raiseOSError(osLastError())


proc open*(filename: string, mode: FileMode = fmRead,
           mappedSize = -1, offset = 0, newFileSize = -1,
           allowRemap = false): MemFile =
  ## opens a memory mapped file. If this fails, ``EOS`` is raised.
  ##
  ## ``newFileSize`` can only be set if the file does not exist and is opened
  ## with write access (e.g., with fmReadWrite).
  ##
  ##``mappedSize`` and ``offset``
  ## can be used to map only a slice of the file.
  ##
  ## ``offset`` must be multiples of the PAGE SIZE of your OS
  ## (usually 4K or 8K but is unique to your OS)
  ##
  ## ``allowRemap`` only needs to be true if you want to call ``mapMem`` on
  ## the resulting MemFile; else file handles are not kept open.
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
  assert newFileSize == -1 or mode != fmRead
  var readonly = mode == fmRead

  template rollback =
    result.mem = nil
    result.size = 0

  when defined(windows):
    template fail(errCode: OSErrorCode, msg: untyped) =
      rollback()
      if result.fHandle != 0: discard closeHandle(result.fHandle)
      if result.mapHandle != 0: discard closeHandle(result.mapHandle)
      raiseOSError(errCode)
      # return false
      #raise newException(EIO, msg)

    template callCreateFile(winApiProc, filename): untyped =
      winApiProc(
        filename,
        # GENERIC_ALL != (GENERIC_READ or GENERIC_WRITE)
        if readonly: GENERIC_READ else: GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ,
        nil,
        if newFileSize != -1: CREATE_ALWAYS else: OPEN_EXISTING,
        if readonly: FILE_ATTRIBUTE_READONLY else: FILE_ATTRIBUTE_TEMPORARY,
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
        sizeLow  = int32(newFileSize and 0xffffffff)

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
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
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

    var flags = if readonly: O_RDONLY else: O_RDWR

    if newFileSize != -1:
      flags = flags or O_CREAT or O_TRUNC
      var permissions_mode = S_IRUSR or S_IWUSR
      result.handle = open(filename, flags, permissions_mode)
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

    result.mem = mmap(
      nil,
      result.size,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: (MAP_PRIVATE or MAP_POPULATE) else: (MAP_SHARED or MAP_POPULATE),
      result.handle,
      offset)

    if result.mem == cast[pointer](MAP_FAILED):
      fail(osLastError(), "file mapping failed")

    if not allowRemap and result.handle != -1:
      if close(result.handle) == 0:
        result.handle = -1

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

type MemSlice* = object  ## represent slice of a MemFile for iteration over delimited lines/records
  data*: pointer
  size*: int

proc `==`*(x, y: MemSlice): bool =
  ## Compare a pair of MemSlice for strict equality.
  proc memcmp(a, b: pointer, n:int):int {.importc: "memcmp",header: "string.h".}
  result = (x.size == y.size and memcmp(x.data, y.data, x.size) == 0)

proc `$`*(ms: MemSlice): string {.inline.} =
  ## Return a Nim string built from a MemSlice.
  var buf = newString(ms.size)
  copyMem(addr(buf[0]), ms.data, ms.size)
  buf[ms.size] = '\0'
  result = buf

iterator memSlices*(mfile: MemFile, delim='\l', eat='\r'): MemSlice {.inline.} =
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
       importc: "memchr", header: "<string.h>" .}
  proc `-!`(p, q: pointer): int {.inline.} = return cast[int](p) -% cast[int](q)
  var ms: MemSlice
  var ending: pointer
  ms.data = mfile.mem
  var remaining = mfile.size
  while remaining > 0:
    ending = c_memchr(ms.data, delim, remaining)
    if ending == nil:                               # unterminated final slice
      ms.size = remaining                           # Weird case..check eat?
      yield ms
      break
    ms.size = ending -! ms.data                     # delim is NOT included
    if eat != '\0' and ms.size > 0 and cast[cstring](ms.data)[ms.size - 1] == eat:
      dec(ms.size)                                  # trim pre-delim char
    yield ms
    ms.data = cast[pointer](cast[int](ending) +% 1)     # skip delim
    remaining = mfile.size - (ms.data -! mfile.mem)

iterator lines*(mfile: MemFile, buf: var TaintedString, delim='\l', eat='\r'): TaintedString {.inline.} =
  ## Replace contents of passed buffer with each new line, like
  ## `readLine(File) <system.html#readLine,File,TaintedString>`_.
  ## `delim`, `eat`, and delimiting logic is exactly as for
  ## `memSlices <#memSlices>`_, but Nim strings are returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var buffer: TaintedString = ""
  ##   for line in lines(memfiles.open("foo"), buffer):
  ##     echo line

  for ms in memSlices(mfile, delim, eat):
    buf.setLen(ms.size)
    copyMem(addr(buf[0]), ms.data, ms.size)
    buf[ms.size] = '\0'
    yield buf

iterator lines*(mfile: MemFile, delim='\l', eat='\r'): TaintedString {.inline.} =
  ## Return each line in a file as a Nim string, like
  ## `lines(File) <system.html#lines.i,File>`_.
  ## `delim`, `eat`, and delimiting logic is exactly as for
  ## `memSlices <#memSlices>`_, but Nim strings are returned.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   for line in lines(memfiles.open("foo")):
  ##     echo line

  var buf = TaintedString(newStringOfCap(80))
  for line in lines(mfile, buf, delim, eat):
    yield buf
